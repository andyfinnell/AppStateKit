
public protocol AnySink: AnyObject {}

public final class Sink<Input>: AnySink {
    private let handler: (Input) -> Void
    private let upstream: any Publisher<Input> // hold in memory
    
    init<P: Publisher>(upstream: P, handler: @escaping (Input) -> Void) where P.Output == Input {
        self.handler = handler
        self.upstream = upstream
    }
    
    func onChange(_ input: Input) {
        handler(input)
    }
}
