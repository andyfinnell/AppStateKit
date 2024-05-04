import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
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
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text(engine.name)
            
                        Text("\\(engine.score)")
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var score: Int
                }
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text(engine.name)
            
                        Text("\\(engine.score)")
                    }
                }

                enum Action: Equatable {
                    case increase
                    case updateName(newName: String)
                }
            
                typealias Output = Never

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case .increase:
                        increase(&state, sideEffects: sideEffects)
            
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            }
            
            extension MyFeature: Component {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBasicComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum CounterComponent {
                struct State: Equatable {
                    var count: Int
                    var countText: String
                }
                
                private static func decrement(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
                    state.count -= 1
                    state.countText = "\\(state.count)"
                }
                
                private static func increment(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
                    state.count += 1
                    state.countText = "\\(state.count)"
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text("Count:")
            
                        Text(engine.countText)
                    }
                }
            }
            """,
            expandedSource: """
            
            enum CounterComponent {
                struct State: Equatable {
                    var count: Int
                    var countText: String
                }
                
                private static func decrement(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
                    state.count -= 1
                    state.countText = "\\(state.count)"
                }
                
                private static func increment(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
                    state.count += 1
                    state.countText = "\\(state.count)"
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text("Count:")
            
                        Text(engine.countText)
                    }
                }
            
                enum Action: Equatable {
                    case decrement
                    case increment
                }
            
                typealias Output = Never

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case .decrement:
                        decrement(&state, sideEffects: sideEffects)
            
                    case .increment:
                        increment(&state, sideEffects: sideEffects)

                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            }
            
            extension CounterComponent: Component {
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
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }

                enum Action: Equatable {
                    case updateName(newName: String)
                    case child(ChildFeature.Action)
                }
            
                typealias Output = Never

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .child(innerAction):
            
                        let innerSideEffects = sideEffects.map(Action.child, translate: { (_: ChildFeature.Output) in
                            nil
                        })
                        ChildFeature.reduce(
                            &state.child,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    ChildFeature.EngineView(
                        engine: engine.map(
                            state: {
                                $0.child
                            },
                            action: Action.child
                        ).view()
                    )
                }
            }
            
            extension MyFeature: Component {
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
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        ForEach(engine.children.indices) { i in
                            children(engine, at: i)
                        }
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var children: [ChildFeature.State]
                }
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        ForEach(engine.children.indices) { i in
                            children(engine, at: i)
                        }
                    }
                }

                enum Action: Equatable {
                    case updateName(newName: String)
                    case children(ChildFeature.Action, index: Int)
                }
            
                typealias Output = Never

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .children(innerAction, index: innerIndex):
                        guard innerIndex >= state.children.startIndex, innerIndex < state.children.endIndex else {
                            return
                        }
                        let innerSideEffects = sideEffects.map({
                            Action.children($0, index: innerIndex)
                        }
                        , translate: { (_: ChildFeature.Output) in
                            nil
                        })
                        ChildFeature.reduce(
                            &state.children[innerIndex],
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func children(_ engine: ViewEngine<State, Action, Output>, at index: Int) -> some View {
                    ChildFeature.EngineView(
                        engine: engine.map(
                            state: {
                                $0.children[index]
                            },
                            action: {
                                Action.children($0, index: index)
                            }
                        ).view()
                    )
                }
            }
            
            extension MyFeature: Component {
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
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        ForEach(engine.children.keys.sorted(), id: \\.self) { key in
                            children(engine, forKey: key)
                        }
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var children: [String: ChildFeature.State]
                }
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        ForEach(engine.children.keys.sorted(), id: \\.self) { key in
                            children(engine, forKey: key)
                        }
                    }
                }

                enum Action: Equatable {
                    case updateName(newName: String)
                    case children(ChildFeature.Action, key: String)
                }
            
                typealias Output = Never

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .children(innerAction, key: innerKey):
                        guard var innerState = state.children[innerKey] else {
                            return
                        }
                        let innerSideEffects = sideEffects.map({
                            Action.children($0, key: innerKey)
                        }
                        , translate: { (_: ChildFeature.Output) in
                            nil
                        })
                        ChildFeature.reduce(
                            &innerState,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
                        state.children[innerKey] = innerState
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func children(_ engine: ViewEngine<State, Action, Output>, forKey key: String) -> some View {
                    if let innerState = engine.state.children[key] {
                        ChildFeature.EngineView(
                            engine: engine.map(
                                state: {
                                    $0.children[key] ?? innerState
                                },
                                action: {
                                    Action.children($0, key: key)
                                }
                            ).view()
                        )
                    }
                }
            }
            
            extension MyFeature: Component {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testChildIdentifiableArrayPropertyComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var children: IdentifiableArray<ChildFeature.State>
                }
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        ForEach(engine.children.map({ $0.id }), id: \\.self) { id in
                            children(engine, byID: id)
                        }
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var children: IdentifiableArray<ChildFeature.State>
                }
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        ForEach(engine.children.map({ $0.id }), id: \\.self) { id in
                            children(engine, byID: id)
                        }
                    }
                }

                enum Action: Equatable {
                    case updateName(newName: String)
                    case children(ChildFeature.Action, id: ChildFeature.State.ID)
                }
            
                typealias Output = Never

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .children(innerAction, id: innerID):
                        guard var innerState = state.children[byID: innerID] else {
                            return
                        }
                        let innerSideEffects = sideEffects.map({
                            Action.children($0, id: innerID)
                        }
                        , translate: { (_: ChildFeature.Output) in
                            nil
                        })
                        ChildFeature.reduce(
                            &innerState,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
                        state.children[byID: innerID] = innerState
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func children(_ engine: ViewEngine<State, Action, Output>, byID id: ChildFeature.State.ID) -> some View {
                    if let innerState = engine.state.children[byID: id] {
                        ChildFeature.EngineView(
                            engine: engine.map(
                                state: {
                                    $0.children[byID: id] ?? innerState
                                },
                                action: {
                                    Action.children($0, id: id)
                                }
                            ).view()
                        )
                    }
                }
            }
            
            extension MyFeature: Component {
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
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State?
                }
                
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }

                enum Action: Equatable {
                    case updateName(newName: String)
                    case child(ChildFeature.Action)
                }
            
                typealias Output = Never

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .child(innerAction):
                        guard var innerState = state.child else {
                            return
                        }
                        let innerSideEffects = sideEffects.map(Action.child, translate: { (_: ChildFeature.Output) in
                            nil
                        })
                        ChildFeature.reduce(
                            &innerState,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
                        state.child = innerState
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    if let innerState = engine.state.child {
                        ChildFeature.EngineView(
                            engine: engine.map(
                                state: {
                                    $0.child ?? innerState
                                },
                                action: Action.child
                            ).view()
                        )
                    }
                }
            }
            
            extension MyFeature: Component {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testChildPropertyWithOutputComponent() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                
                private static func translateChild(from output: ChildFeature.Output) -> Action? {
                    .updateName(newName: "bob")
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                
                private static func translateChild(from output: ChildFeature.Output) -> Action? {
                    .updateName(newName: "bob")
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }
            
                enum Action: Equatable {
                    case updateName(newName: String)
                    case child(ChildFeature.Action)
                }
            
                typealias Output = Never
            
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .child(innerAction):
            
                        let innerSideEffects = sideEffects.map(Action.child, translate: translateChild)
                        ChildFeature.reduce(
                            &state.child,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            
                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    ChildFeature.EngineView(
                        engine: engine.map(
                            state: {
                                $0.child
                            },
                            action: Action.child,
                            translate: translateChild
                        ).view()
                    )
                }
            }
            
            extension MyFeature: Component {
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    func testOutputChildPropertyComponent() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                
                enum Output {
                    case letParentKnow
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                
                enum Output {
                    case letParentKnow
                }

                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, newName: String) {
                    state.name = newName
                }
                @MainActor
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }
            
                enum Action: Equatable {
                    case updateName(newName: String)
                    case child(ChildFeature.Action)
                }
            
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    case let .child(innerAction):
            
                        let innerSideEffects = sideEffects.map(Action.child, translate: { (_: ChildFeature.Output) in
                            nil
                        })
                        ChildFeature.reduce(
                            &state.child,
                            action: innerAction,
                            sideEffects: innerSideEffects
                        )
            
                    }
                }
            
                struct EngineView: View {
                    @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            
                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    ChildFeature.EngineView(
                        engine: engine.map(
                            state: {
                                $0.child
                            },
                            action: Action.child
                        ).view()
                    )
                }
            }
            
            extension MyFeature: Component {
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
