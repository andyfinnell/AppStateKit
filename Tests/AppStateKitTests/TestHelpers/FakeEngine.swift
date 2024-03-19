import Foundation
import Combine
import AppStateKit
import Observation

@Observable
final class FakeEngine<State, Action>: Engine {
    var state: State
    var sentActions = [Action]()
    
    init(state: State) {
        self.state = state
    }
    
    func send(_ action: Action) {
        sentActions.append(action)
    }
}
