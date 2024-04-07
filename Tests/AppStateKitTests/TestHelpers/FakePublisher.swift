import Foundation
@testable import AppStateKit

final class FakePublisher<Output>: Publisher {
    func send(_ output: Output) {
        for sink in sinks {
            sink.onChange(output)
        }
    }
    
    var sinks = [Sink<Output>]()
    func sink(_ handler: @escaping (Output) -> Void) -> Sink<Output> {
        let sink = Sink(upstream: self, handler: handler)
        sinks.append(sink)
        return sink
    }
}
