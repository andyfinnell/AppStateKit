import Foundation
import XCTest
import Combine
@testable import AppStateKit

final class UIModuleValueTests: XCTestCase {
    struct Module1 {
        struct State: Equatable, Updatable, Identifiable {
            var id: String { field1 }
            
            var field1: String
            var field2: Int
        }
        
        struct Environment {
            
        }
        
        enum Action: Hashable {
            case one
            case two
        }
        
        enum Effect: Hashable {
            case one
            case two
        }
    }
        
    func testCombine() {
        let moduleValue1 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.one)
            return state.update(\.field1, to: "next")
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.one).eraseToAnyPublisher()
        })
        
        let moduleValue2 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.two)
            return state.update(\.field2, to: 42)
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.two).eraseToAnyPublisher()
        })

        let subject = UIModuleValue.combine(moduleValue1, moduleValue2)
        
        // Verify the reducer
        let (reducedState, allEffects) = reduce(subject,
                                                state: Module1.State(field1: "start", field2: 1),
                                                action: .one)
        
        XCTAssertEqual(reducedState, Module1.State(field1: "next", field2: 42))
        XCTAssertEqual(allEffects, Set([.one, .two]))
        
        // Verify the sideEffectHandler
        let actionHistory = performSideEffects(subject, effect: .one, environment: Module1.Environment())
        
        XCTAssertEqual(actionHistory, [.one, .two])
    }
    
    func testExternal() {
        let moduleValue1 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.one)
            return state.update(\.field1, to: "next")
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.one).eraseToAnyPublisher()
        })

        enum GlobalAction: Hashable, Extractable {
            case module1(Module1.Action)
        }
        
        enum GlobalEffect: Hashable, Extractable {
            case module1(Module1.Effect)
        }

        let subject = moduleValue1.external(toLocalAction: GlobalAction.extractor(GlobalAction.module1),
                                            fromLocalAction: GlobalAction.module1,
                                            toLocalEffect: GlobalEffect.extractor(GlobalEffect.module1),
                                            fromLocalEffect: GlobalEffect.module1)
        
        
        // Verify the reducer
        let (reducedState, allEffects) = reduce(subject,
                                                state: Module1.State(field1: "start", field2: 1),
                                                action: .module1(.one))
        
        XCTAssertEqual(reducedState, Module1.State(field1: "next", field2: 1))
        XCTAssertEqual(allEffects, Set([.module1(.one)]))
        
        // Verify the sideEffectHandler
        let actionHistory = performSideEffects(subject, effect: .module1(.one), environment: Module1.Environment())
        
        XCTAssertEqual(actionHistory, [.module1(.one)])
    }
    
    func testProperty() {
        struct Module2 {
            struct State: Equatable, Updatable {
                var field: Module1.State
            }
            
            enum Action: Hashable, Extractable {
                case module1(Module1.Action)
            }
            
            enum Effect: Hashable, Extractable {
                case module1(Module1.Effect)
            }
            
            struct Environment {
                
            }
        }

        let moduleValue1 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.one)
            return state.update(\.field1, to: "next")
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.one).eraseToAnyPublisher()
        })

        let subject: UIModuleValue<Module2.State, Module2.Action, Module2.Effect, Module2.Environment>
            = moduleValue1.property(state: \.field,
                                    toLocalAction: Module2.Action.extractor(Module2.Action.module1),
                                    fromLocalAction: Module2.Action.module1,
                                    toLocalEffect: Module2.Effect.extractor(Module2.Effect.module1),
                                    fromLocalEffect: Module2.Effect.module1,
                                    toLocalEnvironment: { _ in Module1.Environment() })
        
        // Verify the reducer
        let (reducedState, allEffects) = reduce(subject,
                                                state: Module2.State(field: Module1.State(field1: "start", field2: 1)),
                                                action: .module1(.one))
        
        XCTAssertEqual(reducedState, Module2.State(field: Module1.State(field1: "next", field2: 1)))
        XCTAssertEqual(allEffects, Set([.module1(.one)]))
        
        // Verify the sideEffectHandler
        let actionHistory = performSideEffects(subject, effect: .module1(.one), environment: Module2.Environment())
        
        XCTAssertEqual(actionHistory, [.module1(.one)])
    }

    func testOptional() {
        let moduleValue1 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.one)
            return state.update(\.field1, to: "next")
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.one).eraseToAnyPublisher()
        })

        let subject = moduleValue1.optional()
        
        // Verify the reducer
        let (reducedState, allEffects) = reduce(subject,
                                                state: Module1.State(field1: "start", field2: 1),
                                                action: .one)
        
        XCTAssertEqual(reducedState, Module1.State(field1: "next", field2: 1))
        XCTAssertEqual(allEffects, Set([.one]))
        
        // Verify the reducer with nil
        let (reducedState2, allEffects2) = reduce(subject,
                                                state: nil,
                                                action: .one)
        
        XCTAssertNil(reducedState2)
        XCTAssertEqual(allEffects2, Set([]))

        // Verify the sideEffectHandler
        let actionHistory = performSideEffects(subject, effect: .one, environment: Module1.Environment())
        
        XCTAssertEqual(actionHistory, [.one])
    }

    func testIndexedArray() {
        struct Module2 {
            struct State: Equatable, Updatable {
                var field: [Module1.State]
            }
            
            enum Action: Hashable, Extractable {
                case module1(Module1.Action, Int)
            }
            
            enum Effect: Hashable, Extractable {
                case module1(Module1.Effect, Int)
            }
            
            struct Environment {
                
            }
        }

        let moduleValue1 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.one)
            return state.update(\.field1, to: "next")
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.one).eraseToAnyPublisher()
        })

        let subject: UIModuleValue<Module2.State, Module2.Action, Module2.Effect, Module2.Environment>
            = moduleValue1.array(state: \.field,
                                    toLocalAction: Module2.Action.extractor(Module2.Action.module1),
                                    fromLocalAction: Module2.Action.module1,
                                    toLocalEffect: Module2.Effect.extractor(Module2.Effect.module1),
                                    fromLocalEffect: Module2.Effect.module1,
                                    toLocalEnvironment: { _ in Module1.Environment() })
        
        // Verify the reducer
        let (reducedState, allEffects) = reduce(subject,
                                                state: Module2.State(field: [
                                                    Module1.State(field1: "start", field2: 1),
                                                    Module1.State(field1: "middle", field2: 2),
                                                    Module1.State(field1: "end", field2: 3)
                                                                        ]),
                                                action: .module1(.one, 1))
        
        XCTAssertEqual(reducedState, Module2.State(field: [
            Module1.State(field1: "start", field2: 1),
            Module1.State(field1: "next", field2: 2),
            Module1.State(field1: "end", field2: 3)]))
        XCTAssertEqual(allEffects, Set([.module1(.one, 1)]))
        
        // Verify the sideEffectHandler
        let actionHistory = performSideEffects(subject, effect: .module1(.one, 1), environment: Module2.Environment())
        
        XCTAssertEqual(actionHistory, [.module1(.one, 1)])
    }

    func testArrayById() {
        struct Module2 {
            struct State: Equatable, Updatable {
                var field: [Module1.State]
            }
            
            enum Action: Hashable, Extractable {
                case module1(Module1.Action, Module1.State.ID)
            }
            
            enum Effect: Hashable, Extractable {
                case module1(Module1.Effect, Module1.State.ID)
            }
            
            struct Environment {
                
            }
        }

        let moduleValue1 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.one)
            return state.update(\.field1, to: "next")
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.one).eraseToAnyPublisher()
        })

        let subject: UIModuleValue<Module2.State, Module2.Action, Module2.Effect, Module2.Environment>
            = moduleValue1.arrayById(state: \.field,
                                    toLocalAction: Module2.Action.extractor(Module2.Action.module1),
                                    fromLocalAction: Module2.Action.module1,
                                    toLocalEffect: Module2.Effect.extractor(Module2.Effect.module1),
                                    fromLocalEffect: Module2.Effect.module1,
                                    toLocalEnvironment: { _ in Module1.Environment() })
        
        // Verify the reducer
        let (reducedState, allEffects) = reduce(subject,
                                                state: Module2.State(field: [
                                                    Module1.State(field1: "start", field2: 1),
                                                    Module1.State(field1: "middle", field2: 2),
                                                    Module1.State(field1: "end", field2: 3)
                                                                        ]),
                                                action: .module1(.one, "middle"))
        
        XCTAssertEqual(reducedState, Module2.State(field: [
            Module1.State(field1: "start", field2: 1),
            Module1.State(field1: "next", field2: 2),
            Module1.State(field1: "end", field2: 3)]))
        XCTAssertEqual(allEffects, Set([.module1(.one, "middle")]))
        
        // Verify the sideEffectHandler
        let actionHistory = performSideEffects(subject, effect: .module1(.one, "middle"), environment: Module2.Environment())
        
        XCTAssertEqual(actionHistory, [.module1(.one, "middle")])
    }

    func testDictionary() {
        struct Module2 {
            struct State: Equatable, Updatable {
                var field: [String: Module1.State]
            }
            
            enum Action: Hashable, Extractable {
                case module1(Module1.Action, String)
            }
            
            enum Effect: Hashable, Extractable {
                case module1(Module1.Effect, String)
            }
            
            struct Environment {
                
            }
        }

        let moduleValue1 = UIModuleValue(reducer: { (state: Module1.State, action: Module1.Action, sideEffects: SideEffects<Module1.Effect>) in
            sideEffects(.one)
            return state.update(\.field1, to: "next")
        }, sideEffectHandler: { (effect: Module1.Effect, env: Module1.Environment) in
            
            return Just(Module1.Action.one).eraseToAnyPublisher()
        })

        let subject: UIModuleValue<Module2.State, Module2.Action, Module2.Effect, Module2.Environment>
            = moduleValue1.dictionary(state: \.field,
                                    toLocalAction: Module2.Action.extractor(Module2.Action.module1),
                                    fromLocalAction: Module2.Action.module1,
                                    toLocalEffect: Module2.Effect.extractor(Module2.Effect.module1),
                                    fromLocalEffect: Module2.Effect.module1,
                                    toLocalEnvironment: { _ in Module1.Environment() })
        
        // Verify the reducer
        let (reducedState, allEffects) = reduce(subject,
                                                state: Module2.State(field: [
                                                    "start": Module1.State(field1: "start", field2: 1),
                                                    "middle": Module1.State(field1: "middle", field2: 2),
                                                    "end": Module1.State(field1: "end", field2: 3)
                                                                        ]),
                                                action: .module1(.one, "middle"))
        
        XCTAssertEqual(reducedState, Module2.State(field: [
                                                    "start": Module1.State(field1: "start", field2: 1),
                                                    "middle": Module1.State(field1: "next", field2: 2),
                                                    "end": Module1.State(field1: "end", field2: 3)]))
        XCTAssertEqual(allEffects, Set([.module1(.one, "middle")]))
        
        // Verify the sideEffectHandler
        let actionHistory = performSideEffects(subject, effect: .module1(.one, "middle"), environment: Module2.Environment())
        
        XCTAssertEqual(actionHistory, [.module1(.one, "middle")])
    }

    private func waitOnActions<Action>(_ actionsPublisher: AnyPublisher<Action, Never>) -> [Action] {
        let finishExpectation = expectation(description: "finish")
        var cancellables = Set<AnyCancellable>()
        var actionHistory = [Action]()
        actionsPublisher.sink(receiveCompletion: { _ in
            finishExpectation.fulfill()
        }, receiveValue: { action in
            actionHistory.append(action)
        }).store(in: &cancellables)
        
        waitForExpectations(timeout: 1, handler: nil)

        return actionHistory
    }
    
    private func performSideEffects<State, Action, Effect, Environment>(_ moduleValue: UIModuleValue<State, Action, Effect, Environment>, effect: Effect, environment: Environment) -> [Action] {
        let actionsPublisher = moduleValue.sideEffectHandler(effect, environment)
        return waitOnActions(actionsPublisher)
    }
    
    private func reduce<State, Action, Effect, Environment>(_ moduleValue: UIModuleValue<State, Action, Effect, Environment>, state: State, action: Action) -> (State, Set<Effect>) {
        let sideEffects = SideEffects<Effect>()
        let newState = moduleValue.reducer(state, action, sideEffects)
        let allEffects = Set(sideEffects.effects.flatMap { $0.effects })

        return (newState, allEffects)
    }
}
