import Foundation

public protocol Engine: AnyObject {
    associatedtype State
    associatedtype Action
    associatedtype Output
    
    var state: State { get }
    var statePublisher: any Publisher<State> { get }
    var internals: Internals { get }
    
    @MainActor
    func send(_ action: Action)
    
    @MainActor
    func signal(_ output: Output)
}

