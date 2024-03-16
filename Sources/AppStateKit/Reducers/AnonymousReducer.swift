import Foundation

public struct AnonymousReducer<State, Action>: Reducer {
    private let closure: (inout State, Action, AnySideEffects<Action>) -> Void
    
    public init(_ closure: @escaping (inout State, Action, AnySideEffects<Action>) -> Void) {
        self.closure = closure
    }
    
    public func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
        closure(&state, action, sideEffects)
    }
}
