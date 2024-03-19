import Foundation

public protocol Engine: AnyObject {
    associatedtype State
    associatedtype Action
    
    var state: State { get }
    
    @MainActor
    func send(_ action: Action)
}

