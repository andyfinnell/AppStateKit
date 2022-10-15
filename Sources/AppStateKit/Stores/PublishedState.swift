import Foundation
import Combine

@propertyWrapper
public final class PublishedState<State> {
    private let stateSubject: CurrentValueSubject<State, Never>
    
    public init(wrappedValue: State) {
        stateSubject = CurrentValueSubject(wrappedValue)
    }
    
    public var wrappedValue: State {
        get {
            stateSubject.value
        }
        set {
            stateSubject.value = newValue
        }
    }
    
    public var projectedValue: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
}
