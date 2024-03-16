import Foundation

public protocol Reducer<State, Action> {
    associatedtype State
    associatedtype Action
    
    func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>)
}
