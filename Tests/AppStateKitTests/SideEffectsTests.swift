import Foundation
import XCTest
@testable import AppStateKit

final class SideEffectsTests: XCTestCase {
            
    enum Action: Hashable {
        case loaded(String)
        case saved
        case child(ChildAction)
        case onTick(TimeInterval)
    }
        
    enum ChildAction: Hashable {
        case updated(String)
    }
    
    func testParallelEffects() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let sideEffects = subject.eraseToAnySideEffects()
        
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
    
    func testCombinedEffects() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        
        let sideEffects = subject.eraseToAnySideEffects()
        sideEffects.loadAtIndex(index: 4) {
            .loaded($0)
        }
        sideEffects.save(index: 3, content: "my content") {
            .saved
        }

        let childSubject = sideEffects.map { Action.child($0) }
        
        childSubject.update(index: 2, content: "frank") {
            .updated($0)
        }
                
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .loaded("loaded index 4"),
            .saved,
            .child(.updated("update frank to 2"))
        ])
        XCTAssertEqual(actual, expected)
    }
    
    func testSubscription() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        
        let sideEffects = subject.eraseToAnySideEffects()

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
    
    func testImmediateCancel() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        
        let sideEffects = subject.eraseToAnySideEffects()

        let subscriptionID = sideEffects.subscribeToTimer(delay: 1.5, count: 3) { times, yield in
            for await t in times {
                try Task.checkCancellation()
                await yield(.onTick(t))
            }
        }
        sideEffects.cancel(subscriptionID)
        
        XCTAssertEqual(subject.subscriptions.count, 0)
    }
    
    func testLaterCancel() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        
        let sideEffects = subject.eraseToAnySideEffects()
        let subscriptionID = SubscriptionID()
        sideEffects.cancel(subscriptionID)

        XCTAssertEqual(subject.cancellations, Set([subscriptionID]))
    }
    
    func testGeneratedMethods() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let sideEffects = subject.eraseToAnySideEffects()
        
        sideEffects.generate() {
            .loaded($0)
        }
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .loaded("number 9"),
        ])
        XCTAssertEqual(actual, expected)
    }
    
    func testScheduleAction() async {
        let dependencies = DependencyScope()
        let subject = SideEffectsContainer<Action>(dependencyScope: dependencies)
        let sideEffects = subject.eraseToAnySideEffects()
        
        sideEffects.schedule(.saved)
                
        let actual = await testMaterializeEffects(subject)
        let expected = Set<Action>([
            .saved
        ])
        XCTAssertEqual(actual, expected)
    }
}
