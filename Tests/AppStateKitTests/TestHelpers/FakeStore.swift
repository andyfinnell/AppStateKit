import Foundation
import Combine
import AppStateKit

final class FakeStore<State, Action>: Storable {
    let currentState: CurrentValueSubject<State, Never>
    var state: State { currentState.value }
    var statePublisher: AnyPublisher<State, Never> { currentState.eraseToAnyPublisher() }
    private(set) var appliedActions = [Action]()
    
    @MainActor
    func apply(_ action: Action) {
        appliedActions.append(action)
    }
    
    init(state: State) {
        currentState = CurrentValueSubject(state)
    }
}
