import Foundation
import Combine

public final class FixtureStore<State, Action>: Storable {
    public let stateSubject: CurrentValueSubject<State, Never>
    public var state: State { stateSubject.value }
    public var statePublisher: AnyPublisher<State, Never> { stateSubject.eraseToAnyPublisher() }
    
    public init(_ initialState: State) {
        stateSubject = CurrentValueSubject(initialState)
    }
    
    public func apply(_ action: Action) {
        // nop
    }
}
