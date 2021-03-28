import Foundation
import Combine

public final class SerialPublisher<Input, Output, Failure: Error>: Publisher {
    private let input: [Input]
    private let factory: (Input) -> AnyPublisher<Output, Failure>
    
    public init(input: [Input], factory: @escaping (Input) -> AnyPublisher<Output, Failure>) {
        self.input = input
        self.factory = factory
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = SerialSubscription(subscriber: subscriber,
                                              input: input,
                                              factory: factory)
        
        subscriber.receive(subscription: subscription)
    }
}

fileprivate final class SerialSubscription<S: Subscriber, Input, Output>: Subscription where Output == S.Input {
    private var subscriber: S?
    private var cancellable: AnyCancellable?
    private var input: [Input]
    private let factory: (Input) -> AnyPublisher<Output, S.Failure>

    init(subscriber: S, input: [Input], factory: @escaping (Input) -> AnyPublisher<Output, S.Failure>)  {
        self.subscriber = subscriber
        self.input = input
        self.factory = factory
        
        runNext()
    }
    
    func request(_ demand: Subscribers.Demand) {
        // act like a "hot" observable
    }
    
    func cancel() {
        subscriber = nil
        cancellable?.cancel()
        cancellable = nil
    }
    
    private func runNext() {
        guard let next = input.first else {
            complete()
            return
        }
        input.removeFirst()
        
        cancellable = factory(next).sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case let .failure(error):
                self?.fail(with: error)
            case .finished:
                self?.runNext()
            }
        }, receiveValue: { [weak self] value in
            _ = self?.subscriber?.receive(value)
        })
    }
    
    private func complete() {
        subscriber?.receive(completion: .finished)
        subscriber = nil
        cancellable = nil
    }
    
    private func fail(with error: S.Failure) {
        input = []
        subscriber?.receive(completion: .failure(error))
        subscriber = nil
        cancellable = nil
    }
}
