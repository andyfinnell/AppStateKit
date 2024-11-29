import Foundation

public protocol Detachment<DetachedAction> {
    associatedtype DetachedAction: Sendable
}

@MainActor
public protocol ActionSender<Action>: AnyObject {
    associatedtype Action: Sendable
    
    func send(_ action: Action)
}

@MainActor
public protocol DetachmentContainer: AnyObject {
    func attach<D: Detachment>(_ sender: some ActionSender<D.DetachedAction>, at key: D.Type)
}

@MainActor
public protocol Engine: ActionSender, DetachmentContainer {
    associatedtype State
    associatedtype Output
    
    var state: State { get }
    var statePublisher: any Publisher<State> { get }
    var internals: Internals { get }
        
    func signal(_ output: Output)
}

