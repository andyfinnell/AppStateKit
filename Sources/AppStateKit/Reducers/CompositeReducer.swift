import Foundation

public protocol CompositeReducer: Reducer {
    associatedtype Body: Reducer<State, Action, Effects>
    
    @ReducerBuilder
    var body: Body { get }
}

public extension CompositeReducer {
    func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: SideEffects<Action>)  {
        body.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
    }
}
