import Foundation

@MainActor
public protocol BaseComponent {
    associatedtype State
    associatedtype Action: Sendable
    associatedtype Output
    
    static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>)
}
