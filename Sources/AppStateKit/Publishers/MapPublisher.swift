
final class MapPublisher<Output>: Publisher {
    private let broadcaster = Broadcaster<Output>()
    private var sink: AnySink? = nil // keep connection alive
    
    init<Input>(upstream: some Publisher<Input>, transform: @escaping (Input) -> Output) {
        sink = upstream.sink { [weak self] input in
            let output = transform(input)
            self?.broadcaster.didChange(to: output)
        }
    }
    
    func sink(_ handler: @escaping (Output) -> Void) -> Sink<Output> {
        let sink = Sink(upstream: self, handler: handler)
        broadcaster.subscribe(sink)
        return sink
    }
}
