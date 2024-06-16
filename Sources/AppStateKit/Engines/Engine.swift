import Foundation

@MainActor
public protocol Engine: AnyObject {
    associatedtype State
    associatedtype Action: Sendable
    associatedtype Output
    
    var state: State { get }
    var statePublisher: any Publisher<State> { get }
    var internals: Internals { get }
    
    func send(_ action: Action)
    
    func signal(_ output: Output)
}

