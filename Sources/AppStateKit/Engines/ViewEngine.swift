import Foundation
import SwiftUI

@MainActor
@Observable
@dynamicMemberLookup
public final class ViewEngine<State, Action: Sendable, Output>: Engine {
    private let isEqual: (State, State) -> Bool
    private let sendThunk: @MainActor (Action) -> Void
    private let signalThunk: @MainActor (Output) -> Void
    private let internalsThunk: () -> Internals
    private let _statePublisher = MainPublisher<State>()
    private var sink: AnySink?
    
    public private(set) var state: State
    public var statePublisher: any Publisher<State> { _statePublisher }
    public var internals: Internals { internalsThunk() }
    
    public init<E: Engine>(
        engine: E,
        isEqual: @escaping (State, State) -> Bool
    ) where E.State == State, E.Action == Action, E.Output == Output {
        // Intentionally holding parent in memory
        sendThunk = { @MainActor action in
            engine.send(action)
        }
        signalThunk = { @MainActor output in
            engine.signal(output)
        }
        internalsThunk = {
            engine.internals
        }
        state = engine.state // initialize
        self.isEqual = isEqual
        
        sink = engine.statePublisher.sink { [weak self] newState in
            self?.setState(newState)
        }
    }
    
    public func send(_ action: Action) {
        sendThunk(action)
    }
    
    public func signal(_ output: Output) {
        signalThunk(output)
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }
    
    public func binding<T>(_ keyPath: KeyPath<State, T>, send: @escaping (T) -> Action?) -> Binding<T> {
        Binding<T>(get: {
            self.state[keyPath: keyPath]
        }, set: { [weak self] newValue, transaction in
            guard let action = send(newValue) else {
                return
            }
            self?.send(action, transaction: transaction)
        })
    }
    
    public func binding<T>(get: @escaping (State) -> T, send: @escaping (T) -> Action?) -> Binding<T> {
        Binding<T>(get: {
            get(self.state)
        }, set: { [weak self] newValue, transaction in
            guard let action = send(newValue) else {
                return
            }
            self?.send(action, transaction: transaction)
        })
    }
    
    public func binding<T>(get: @escaping (State) -> T) -> Binding<T> {
        Binding<T>(get: {
            get(self.state)
        }, set: { _ in
            // nop
        })
    }
}

private extension ViewEngine {
    func setState(_ state: State) {
        guard !isEqual(self.state, state) else {
            return
        }
        self.state = state
        _statePublisher.didChange(to: state)
    }

    func send(_ action: Action, transaction: Transaction) {
        if transaction.animation != nil {
            withTransaction(transaction) {
                send(action)
            }
        } else {
            send(action)
        }
    }
}

public extension Engine {
    func view() -> ViewEngine<State, Action, Output> where State: Equatable {
        ViewEngine(
            engine: self,
            isEqual: ==
        )
    }

    func view() -> ViewEngine<State, Action, Output> {
        ViewEngine(
            engine: self,
            isEqual: { _, _ in false }
        )
    }
}
