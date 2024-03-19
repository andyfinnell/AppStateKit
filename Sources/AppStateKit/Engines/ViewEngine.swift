import Foundation
import SwiftUI

@Observable
@dynamicMemberLookup
public final class ViewEngine<State, Action>: Engine {
    private let sendThunk: @MainActor (Action) -> Void
    private let stateThunk: () -> State
    public private(set) var state: State
    
    public init<E: Engine>(engine: E) where E.State == State, E.Action == Action {
        // Intentionally holding parent in memory
        sendThunk = { @MainActor action in
            engine.send(action)
        }
        stateThunk = {
            engine.state
        }
        state = stateThunk() // initialize
        
        stateDidChange()
    }
    
    @MainActor
    public func send(_ action: Action) {
        sendThunk(action)
    }
    
    @MainActor
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }
    
    @MainActor
    public func binding<T>(_ keyPath: KeyPath<State, T>, send: @escaping (T) -> Action) -> Binding<T> {
        Binding<T>(get: {
            self.state[keyPath: keyPath]
        }, set: { [weak self] newValue, transaction in
            let action = send(newValue)
            self?.send(action, transaction: transaction)
        })
    }
    
    @MainActor
    public func binding<T>(get: @escaping (State) -> T, send: @escaping (T) -> Action) -> Binding<T> {
        Binding<T>(get: {
            get(self.state)
        }, set: { [weak self] newValue, transaction in
            let action = send(newValue)
            self?.send(action, transaction: transaction)
        })
    }
    
    @MainActor
    public func binding<T>(get: @escaping (State) -> T) -> Binding<T> {
        Binding<T>(get: {
            get(self.state)
        }, set: { _ in
            // nop
        })
    }
}

private extension ViewEngine {
    func stateDidChange() {
        startObserving(stateThunk, onChange: { [weak self] newState in
            self?.state = newState
        })
    }
    
    @MainActor
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
    func view() -> ViewEngine<State, Action> {
        ViewEngine(engine: self)
    }
}
