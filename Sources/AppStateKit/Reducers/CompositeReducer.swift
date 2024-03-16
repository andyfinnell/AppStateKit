import Foundation

public protocol CompositeReducer: Reducer {
    associatedtype Body: Reducer<State, Action>
    
    @ReducerBuilder
    var body: Body { get }
}

public extension CompositeReducer {
    func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>)  {
        body.reduce(&state, action: action, sideEffects: sideEffects)
    }
}
