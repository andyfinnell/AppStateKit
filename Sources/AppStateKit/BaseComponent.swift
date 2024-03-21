import Foundation

public protocol BaseComponent {
    associatedtype State
    associatedtype Action
    
    static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>)
}
