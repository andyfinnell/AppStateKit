import Foundation
import XCTest
@testable import AppStateKit

@MainActor
@Observable
final class FakeEngine<State, Action: Sendable, Output>: Engine {
    var internals = Internals(dependencyScope: DependencyScope())
    var state: State {
        didSet {
            statePublisherFake.send(state)
        }
    }
    var sentActions = [Action]()
    
    var statePublisherFake = FakePublisher<State>()
    var statePublisher: any Publisher<State> { statePublisherFake }
    
    init(state: State) {
        self.state = state
    }
    
    var sendExpectation: XCTestExpectation?
    func send(_ action: Action) {
        sentActions.append(action)
        sendExpectation?.fulfill()
    }
    
    var signaledOutput = [Output]()
    var signalExpectation: XCTestExpectation?
    func signal(_ output: Output) {
        signaledOutput.append(output)
        signalExpectation?.fulfill()
    }
    
    let detachedSender = DetachedSender()
    func attach<D: Detachment>(_ sender: some ActionSender<D.DetachedAction>, at key: D.Type) {
        detachedSender.attach(sender, at: key)
    }
}
