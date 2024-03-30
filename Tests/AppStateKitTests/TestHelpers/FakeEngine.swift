import Foundation
import Combine
@testable import AppStateKit
import Observation

@Observable
final class FakeEngine<State, Action>: Engine {
    var internals = Internals(dependencyScope: DependencyScope())
    var state: State
    var sentActions = [Action]()
    
    init(state: State) {
        self.state = state
    }
    
    func send(_ action: Action) {
        sentActions.append(action)
    }
}
