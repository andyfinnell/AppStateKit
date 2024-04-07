
final class MainPublisher<Output>: Publisher {
    private let broadcaster = Broadcaster<Output>()
    
    init() {
    }
    
    func didChange(to newState: Output) {
        broadcaster.didChange(to: newState)
    }
    
    func sink(_ handler: @escaping (Output) -> Void) -> Sink<Output> {
        let sink = Sink(upstream: self, handler: handler)
        broadcaster.subscribe(sink)
        return sink
    }
}
