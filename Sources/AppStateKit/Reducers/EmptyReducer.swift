import Foundation

public struct EmptyReducer<State, Action>: Reducer {
    public func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
        // nop
    }
}
