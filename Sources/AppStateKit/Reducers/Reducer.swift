import Foundation

public protocol Reducer<State, Action, Effects> {
    associatedtype State
    associatedtype Action
    associatedtype Effects
    
    func reduce(_ state: inout State, action: Action, effects: Effects) -> SideEffects<Action>
}
