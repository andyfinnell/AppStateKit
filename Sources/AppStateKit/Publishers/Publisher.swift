
public protocol Publisher<Output> {
    associatedtype Output
    
    func sink(_ handler: @escaping (Output) -> Void) -> Sink<Output>
    
}

extension Publisher {
    func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> any Publisher<NewOutput> {
        MapPublisher(upstream: self, transform: transform)
    }
}
