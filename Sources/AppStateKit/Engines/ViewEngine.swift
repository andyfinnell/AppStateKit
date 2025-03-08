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
    private let detachmentContainer: any DetachmentContainer
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
        detachmentContainer = engine
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

    public func attach<D: Detachment>(_ sender: some ActionSender<D.DetachedAction>, at key: D.Type) {
        detachmentContainer.attach(sender, at: key)
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }
        
}

extension ViewEngine: Equatable {
    nonisolated public static func ==(lhs: ViewEngine<State, Action, Output>, rhs: ViewEngine<State, Action, Output>) -> Bool {
        lhs === rhs
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
