import Foundation
import XCTest
@testable import AppStateKit

final class SideEffectsTests: XCTestCase {
            
    enum Action: Hashable {
        case loaded(String)
        case saved
        case child(ChildAction)
        case onTick(TimeInterval)
        case updated
    }
        
    enum ChildAction: Hashable {
        case updated(String)
    }
    
    enum ChildOutput: Hashable {
        case updateParent
    }
    
    @MainActor
    func testParallelEffects() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)

        sideEffects.loadAtIndex(index: 4) {
            .loaded($0)
        }
        sideEffects.save(index: 3, content: "my content") {
            .saved
        }
                
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .loaded("loaded index 4"),
            .saved
        ])
        XCTAssertEqual(actual, expected)
    }
    
    @MainActor
    func testImmediateEffect() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)

        sideEffects.print("Hello world") {
            .saved
        }
                
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .saved
        ])
        XCTAssertEqual(actual, expected)
    }
    
    @MainActor
    func testCombinedEffects() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)
        sideEffects.loadAtIndex(index: 4) {
            .loaded($0)
        }
        sideEffects.save(index: 3, content: "my content") {
            .saved
        }

        let childSubject = sideEffects.map({ Action.child($0) },
                                           translate: { (_: ChildOutput) in .updated })
        
        childSubject.update(index: 2, content: "frank") {
            .updated($0)
        }
                
        childSubject.signal(.updateParent)
        
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .loaded("loaded index 4"),
            .saved,
            .child(.updated("update frank to 2")),
            .updated
        ])
        XCTAssertEqual(actual, expected)
    }
    
    @MainActor
    func testSubscription() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)

        _ = sideEffects.subscribeToTimer(delay: 1.5, count: 3) { times, yield in
            for await t in times {
                try Task.checkCancellation()
                await yield(.onTick(t))
            }
        }
        
        let actual = await testMaterializeSubscriptions(subject)
        let expected = Set<Action>([
            .onTick(0),
            .onTick(1.5),
            .onTick(3.0),
        ])
        XCTAssertEqual(actual, expected)
    }
    
    @MainActor
    func testImmediateCancel() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)

        let subscriptionID = sideEffects.subscribeToTimer(delay: 1.5, count: 3) { times, yield in
            for await t in times {
                try Task.checkCancellation()
                await yield(.onTick(t))
            }
        }
        sideEffects.cancel(subscriptionID)
        
        XCTAssertEqual(subject.subscriptions.count, 0)
    }
    
    @MainActor
    func testLaterCancel() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)
        let subscriptionID = SubscriptionID()
        sideEffects.cancel(subscriptionID)

        XCTAssertEqual(subject.cancellations, Set([subscriptionID]))
    }
    
    @MainActor
    func testGeneratedMethods() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)

        sideEffects.generate() {
            .loaded($0)
        }
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .loaded("number 9"),
        ])
        XCTAssertEqual(actual, expected)
    }
    
    @MainActor
    func testScheduleAction() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let signal = { (output: Never) -> Void in
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)

        sideEffects.schedule(.saved)
                
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .saved
        ])
        XCTAssertEqual(actual, expected)
    }
    
    @MainActor
    func testSignal() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        var gotOutput: ChildOutput?
        let signal = { (output: ChildOutput) -> Void in
            gotOutput = output
        }
        let sideEffects = subject.eraseToAnySideEffects(signal: signal)

        sideEffects.signal(.updateParent)
                
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([])
        XCTAssertEqual(actual, expected)
        XCTAssertEqual(gotOutput, ChildOutput.updateParent)
    }
}
