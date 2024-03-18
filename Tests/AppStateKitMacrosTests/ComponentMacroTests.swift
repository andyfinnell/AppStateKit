import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros

let testMacros: [String: Macro.Type] = [
    "Component": ComponentMacro.self,
]
#endif

final class ComponentMacroTests: XCTestCase {
    func testBasicLeafComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var score: Int
                }
            
                private static func increase(_ state: inout State, sideEffects: SideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var score: Int
                }
            
                private static func increase(_ state: inout State, sideEffects: SideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            
                enum Action {
                    case increase
                    case updateName(newName: String)
                }
            
                static func reduce(_ state: inout State, action: Action, sideEffects: SideEffects<Action>) {
                    switch action {
                    case .increase:
                        increase(&state, sideEffects: sideEffects)
            
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testChildPropertyComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            
                enum Action {
                    case updateName(newName: String)
                    case child(ChildFeature.Action)
                }
            
                static func reduce(_ state: inout State, action: Action, sideEffects: SideEffects<Action>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .child(innerAction):
            
                        let innerSideEffects = sideEffects.map(Action.child)
                        ChildFeature.reduce(
                            &state.child,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
            
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testChildArrayPropertyComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var children: [ChildFeature.State]
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var children: [ChildFeature.State]
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            
                enum Action {
                    case updateName(newName: String)
                    case children(ChildFeature.Action, index: Int)
                }
            
                static func reduce(_ state: inout State, action: Action, sideEffects: SideEffects<Action>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .children(innerAction, index: innerIndex):
                        guard innerIndex >= state.children.startIndex, innerIndex < state.children.endIndex else {
                            return
                        }
                        let innerSideEffects = sideEffects.map {
                            Action.children($0, index: innerIndex)
                        }
            
                        ChildFeature.reduce(
                            &state.children[innerIndex],
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
            
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testChildDictionaryPropertyComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var children: [String: ChildFeature.State]
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var children: [String: ChildFeature.State]
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            
                enum Action {
                    case updateName(newName: String)
                    case children(ChildFeature.Action, key: String)
                }
            
                static func reduce(_ state: inout State, action: Action, sideEffects: SideEffects<Action>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .children(innerAction, key: innerKey):
                        guard let innerState = state.children[innerKey] else {
                            return
                        }
                        let innerSideEffects = sideEffects.map {
                            Action.children($0, key: innerKey)
                        }
            
                        ChildFeature.reduce(
                            &innerState,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
                        state.children[innerKey] = innerState
            
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testChildOptionalPropertyComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State?
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State?
                }
                
                private static func updateName(_ state: inout State, sideEffects: SideEffects<Action>, newName: String) {
                    state.name = newName
                }
            
                enum Action {
                    case updateName(newName: String)
                    case child(ChildFeature.Action)
                }
            
                static func reduce(_ state: inout State, action: Action, sideEffects: SideEffects<Action>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .child(innerAction):
                        guard let innerState = state.child else {
                            return
                        }
                        let innerSideEffects = sideEffects.map(Action.child)
                        ChildFeature.reduce(
                            &innerState,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
                        state.child = innerState
            
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}
