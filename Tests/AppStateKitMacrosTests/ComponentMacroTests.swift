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
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
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
                @MainActor
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
                }
                @MainActor
            
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

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case .increase:
                        increase(&state, sideEffects: sideEffects)
            
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)
            
                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            }
            
            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBasicSubscriptionComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    @Updatable var name: String
                    @Subscribe(to: FetchNameEffect.self) var nameSubscription: SubscriptionID? = nil
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text(engine.name)
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var nameSubscription: SubscriptionID? = nil
                }
                @MainActor

                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text(engine.name)
                    }
                }

                enum Action: Equatable {
                    case updateName(String)
                    case componentInit
                }

                @MainActor
                private static func updateName(_ state: inout State, sideEffects: SideEffects, _ p0: String) {
                    state.name = p0
                }

                @MainActor
                private static func componentInit(_ state: inout State, sideEffects: SideEffects) {
                    if state.nameSubscription == nil {
                    state.nameSubscription = sideEffects.subscribeToFetchName { stream, send in
                        for await value in stream {
                            await send(.nameSubscriptionUpdate(value))
                        }
                    }
                    }
                }

                typealias Output = Never

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(p0):
                        updateName(&state, sideEffects: sideEffects, p0)

                    case .componentInit:
                        componentInit(&state, sideEffects: sideEffects)

                    }
                }

                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>

                    var body: some View {
                        view(engine)
                            .task {
                            engine.send(.componentInit)
                        }

                    }
                }
            }

            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testJSONStorageSubscriptionComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    @Updatable var toolSettings: ToolSettings
                    @SubscribeToJSONStorage(for: ToolSettings.self) 
                    var toolSettingsSubscription: SubscriptionID? = nil
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text("Hello world")
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var toolSettings: ToolSettings
            
                    var toolSettingsSubscription: SubscriptionID? = nil
                }
                @MainActor

                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text("Hello world")
                    }
                }

                enum Action: Equatable {
                    case updateToolSettings(ToolSettings)
                    case componentInit
                }

                @MainActor
                private static func updateToolSettings(_ state: inout State, sideEffects: SideEffects, _ p0: ToolSettings) {
                    state.toolSettings = p0
                }

                @MainActor
                private static func componentInit(_ state: inout State, sideEffects: SideEffects) {
                    if state.toolSettingsSubscription == nil {
                    state.toolSettingsSubscription = sideEffects.subscribeToFetchToolSettings { stream, send in
                        for await value in stream {
                            await send(.toolSettingsSubscriptionUpdate(value))
                        }
                    }
                    }
                }

                typealias Output = Never

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateToolSettings(p0):
                        updateToolSettings(&state, sideEffects: sideEffects, p0)

                    case .componentInit:
                        componentInit(&state, sideEffects: sideEffects)

                    }
                }

                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>

                    var body: some View {
                        view(engine)
                            .task {
                            engine.send(.componentInit)
                        }

                    }
                }
            }

            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBasicUpdatableLeafComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    @Updatable var name: String
                    var score: Int
                }
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
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
                @MainActor
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
                }
                @MainActor
                        
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text(engine.name)
            
                        Text("\\(engine.score)")
                    }
                }

                enum Action: Equatable {
                    case updateName(String)
                    case increase
                }
            
                @MainActor
                private static func updateName(_ state: inout State, sideEffects: SideEffects, _ p0: String) {
                    state.name = p0
                }

                typealias Output = Never

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(p0):
                        updateName(&state, sideEffects: sideEffects, p0)

                    case .increase:
                        increase(&state, sideEffects: sideEffects)

                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            }
            
            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testUpdatableWithOutputComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    @Updatable var name: String
                    @Updatable(output: true) var score: Int
                }
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
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
                @MainActor
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
                }
                @MainActor
                        
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        Text(engine.name)
            
                        Text("\\(engine.score)")
                    }
                }

                enum Action: Equatable {
                    case updateName(String)
                    case updateScore(Int)
                    case increase
                }
            
                @MainActor
                private static func updateName(_ state: inout State, sideEffects: SideEffects, _ p0: String) {
                    state.name = p0
                }

                @MainActor
                private static func updateScore(_ state: inout State, sideEffects: SideEffects, _ p0: Int) {
                    state.score = p0
                    if true {
                        sideEffects.signal(.updatedScore(p0))
                    }
                }

                enum Output: Equatable {
                    case updatedScore(Int)
                }
            
                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(p0):
                        updateName(&state, sideEffects: sideEffects, p0)

                    case let .updateScore(p0):
                        updateScore(&state, sideEffects: sideEffects, p0)

                    case .increase:
                        increase(&state, sideEffects: sideEffects)

                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            }
            
            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBasicBatchUpdatableLeafComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    @BatchUpdatable var names: [String]
                    var score: Int
                }
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
                }
                        
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        ForEach(engine.names, id: \\.self) { name in
                            Text(name)
                        }
                        Text("\\(engine.score)")
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var names: [String]
                    var score: Int
                }
                @MainActor

                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
                }
                @MainActor
                        
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        ForEach(engine.names, id: \\.self) { name in
                            Text(name)
                        }
                        Text("\\(engine.score)")
                    }
                }

                enum Action: Equatable {
                    case updateNames(String)
                    case increase
                }

                @MainActor
                private static func updateNames(_ state: inout State, sideEffects: SideEffects, _ p0: String) {
                    for i in 0 ..< state.names.count {
                    state.names[i] = p0
                    }
                }

                typealias Output = Never

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateNames(p0):
                        updateNames(&state, sideEffects: sideEffects, p0)

                    case .increase:
                        increase(&state, sideEffects: sideEffects)

                    }
                }

                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>

                    var body: some View {
                        view(engine)
                    }
                }
            }

            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBasicBatchUpdatableWithOutputLeafComponent() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    @BatchUpdatable(output: true) var names: [String]
                    var score: Int
                }
            
                enum ExtraOutput: Equatable {
                    case beginEditing
                    case panel(Panel.Action, index: Int)
                }
            
                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
                }
                        
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        ForEach(engine.names, id: \\.self) { name in
                            Text(name)
                        }
                        Text("\\(engine.score)")
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyFeature {
                struct State {
                    var names: [String]
                    var score: Int
                }

                enum ExtraOutput: Equatable {
                    case beginEditing
                    case panel(Panel.Action, index: Int)
                }
                @MainActor

                private static func increase(_ state: inout State, sideEffects: SideEffects) {
                    state.score += 1
                }
                @MainActor
                        
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    HStack {
                        ForEach(engine.names, id: \\.self) { name in
                            Text(name)
                        }
                        Text("\\(engine.score)")
                    }
                }

                enum Action: Equatable {
                    case updateNames(String)
                    case increase
                }

                @MainActor
                private static func updateNames(_ state: inout State, sideEffects: SideEffects, _ p0: String) {
                    for i in 0 ..< state.names.count {
                    state.names[i] = p0
                    }
                    if true {
                        sideEffects.signal(.updatedNames(p0))
                    }
                }

                enum Output: Equatable {
                    case updatedNames(String)
                    case beginEditing
                    case panel(Panel.Action, index: Int)
                }

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateNames(p0):
                        updateNames(&state, sideEffects: sideEffects, p0)

                    case .increase:
                        increase(&state, sideEffects: sideEffects)

                    }
                }

                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>

                    var body: some View {
                        view(engine)
                    }
                }
            }

            extension MyFeature: Component, BaseComponent {
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
                @MainActor
                
                private static func decrement(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
                    state.count -= 1
                    state.countText = "\\(state.count)"
                }
                @MainActor
                
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

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case .decrement:
                        decrement(&state, sideEffects: sideEffects)
            
                    case .increment:
                        increment(&state, sideEffects: sideEffects)

                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            }
            
            extension CounterComponent: Component, BaseComponent {
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
                @MainActor
                
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

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func child(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action) {

                    let innerSideEffects = sideEffects.map(Action.child, translate: { (_: ChildFeature.Output) -> TranslateResult<Action, Output> in
                        })
                    ChildFeature.reduce(
                        &state.child,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)

                    case let .child(innerAction):
                            child(&state, sideEffects: sideEffects, action: innerAction)
                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> ChildFeature.EngineView {
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
            
            extension MyFeature: Component, BaseComponent {
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
                @MainActor
                
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

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func children(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action, index innerIndex: Int) {
                    guard innerIndex >= state.children.startIndex, innerIndex < state.children.endIndex, var innerState = state.children[safetyDance: innerIndex] else {
                        return
                    }
                    let innerSideEffects = sideEffects.map({
                        Action.children($0, index: innerIndex)
                    }
                        , translate: { (_: ChildFeature.Output) -> TranslateResult<Action, Output> in
                        })
                    ChildFeature.reduce(
                        &innerState,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )
                    state.children[safetyDance: innerIndex] = innerState

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)

                    case let .children(innerAction, index: innerIndex):
                            children(&state, sideEffects: sideEffects, action: innerAction, index: innerIndex)
                    }
                }

                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>

                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func children(_ engine: ViewEngine<State, Action, Output>, at index: Int) -> ChildFeature.EngineView? {
                    if let innerState = engine.state.children[safetyDance: index] {
                        ChildFeature.EngineView(
                            engine: engine.map(
                                state: {
                                    $0.children[safetyDance: index] ?? innerState
                                },
                                action: {
                                    Action.children($0, index: index)
                                }
                            ).view()
                        )
                    }
                }

                @MainActor
                @ViewBuilder
                private static func forEachChildren(
                    _ engine: ViewEngine<State, Action, Output>,
                    @ViewBuilder content: @escaping (ChildFeature.EngineView) -> some View = {
                        $0
                    }
                ) -> ForEach<[Int].Indices, Int, (some View)?> {
                    ForEach(engine.children.indices, id: \\.self) { index in
                    children(engine, at: index).map {
                        content($0)
                    }
                    }
                }
            }

            extension MyFeature: Component, BaseComponent {
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
                @MainActor
                
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

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func children(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action, key innerKey: String) {
                    guard var innerState = state.children[innerKey] else {
                        return
                    }
                    let innerSideEffects = sideEffects.map({
                        Action.children($0, key: innerKey)
                    }
                        , translate: { (_: ChildFeature.Output) -> TranslateResult<Action, Output> in
                        })
                    ChildFeature.reduce(
                        &innerState,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )
                    state.children[innerKey] = innerState

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)

                    case let .children(innerAction, key: innerKey):
                            children(&state, sideEffects: sideEffects, action: innerAction, key: innerKey)
                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func children(_ engine: ViewEngine<State, Action, Output>, forKey key: String) -> ChildFeature.EngineView? {
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
            
                @MainActor
                @ViewBuilder
                private static func forEachChildren(
                    _ engine: ViewEngine<State, Action, Output>,
                    @ViewBuilder content: @escaping (ChildFeature.EngineView) -> some View = {
                        $0
                    }
                ) -> ForEach<[String], String, (some View)?> {
                    ForEach(engine.children.keys.sorted(), id: \\.self) { key in
                    children(engine, forKey: key).map {
                        content($0)
                    }
                    }
                }
            }
            
            extension MyFeature: Component, BaseComponent {
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
                @MainActor
                
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

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func children(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action, id innerID: ChildFeature.State.ID) {
                    guard var innerState = state.children[byID: innerID] else {
                        return
                    }
                    let innerSideEffects = sideEffects.map({
                        Action.children($0, id: innerID)
                    }
                        , translate: { (_: ChildFeature.Output) -> TranslateResult<Action, Output> in
                        })
                    ChildFeature.reduce(
                        &innerState,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )
                    state.children[byID: innerID] = innerState

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)

                    case let .children(innerAction, id: innerID):
                            children(&state, sideEffects: sideEffects, action: innerAction, id: innerID)
                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func children(_ engine: ViewEngine<State, Action, Output>, byID id: ChildFeature.State.ID) -> ChildFeature.EngineView? {
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
            
                @MainActor
                @ViewBuilder
                private static func forEachChildren(
                    _ engine: ViewEngine<State, Action, Output>,
                    @ViewBuilder content: @escaping (ChildFeature.EngineView) -> some View = {
                        $0
                    }
                ) -> ForEach<[ChildFeature.State.ID], ChildFeature.State.ID, (some View)?> {
                    ForEach(engine.children.map {
                            $0.id
                        }, id: \\.self) { id in
                    children(engine, byID: id).map {
                        content($0)
                    }
                    }
                }
            }
            
            extension MyFeature: Component, BaseComponent {
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
                @MainActor
                
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

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func child(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action) {
                    guard var innerState = state.child else {
                        return
                    }
                    let innerSideEffects = sideEffects.map(Action.child, translate: { (_: ChildFeature.Output) -> TranslateResult<Action, Output> in
                        })
                    ChildFeature.reduce(
                        &innerState,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )
                    state.child = innerState

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)

                    case let .child(innerAction):
                            child(&state, sideEffects: sideEffects, action: innerAction)
                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> ChildFeature.EngineView? {
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
            
            extension MyFeature: Component, BaseComponent {
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
                
                private static func translateChild(from output: ChildFeature.Output) -> TranslateResult<Action, Output> {
                    .perform(.updateName(newName: "bob"))
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
                
                private static func translateChild(from output: ChildFeature.Output) -> TranslateResult<Action, Output> {
                    .perform(.updateName(newName: "bob"))
                }
                @MainActor
            
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
            
                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func child(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action) {

                    let innerSideEffects = sideEffects.map(Action.child, translate: translateChild)
                    ChildFeature.reduce(
                        &state.child,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)

                    case let .child(innerAction):
                            child(&state, sideEffects: sideEffects, action: innerAction)
                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            
                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> ChildFeature.EngineView {
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
            
            extension MyFeature: Component, BaseComponent {
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
                @MainActor

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
            
                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func child(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action) {

                    let innerSideEffects = sideEffects.map(Action.child, translate: { (_: ChildFeature.Output) in
                            .drop
                        })
                    ChildFeature.reduce(
                        &state.child,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(newName: newName):
                        updateName(&state, sideEffects: sideEffects, newName: newName)

                    case let .child(innerAction):
                            child(&state, sideEffects: sideEffects, action: innerAction)
                    }
                }
            
                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>
            
                    var body: some View {
                        view(engine)
                    }
                }
            
                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> ChildFeature.EngineView {
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
            
            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testChildPropertyWithPassthroughOutputComponent() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    @Updatable(output: true) var name: String
                    @PassthroughOutput var child: ChildFeature.State
                }
            
                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)
            
                        child(engine)
                    }
                }
            }
            """,
            expandedSource:
            """
            
            enum MyFeature {
                struct State {
                    var name: String
                    var child: ChildFeature.State
                }
                @MainActor

                static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
                    VStack {
                        Text(engine.name)

                        child(engine)
                    }
                }

                enum Action: Equatable {
                    case updateName(String)
                    case child(ChildFeature.Action)
                }

                @MainActor
                private static func updateName(_ state: inout State, sideEffects: SideEffects, _ p0: String) {
                    state.name = p0
                    if true {
                        sideEffects.signal(.updatedName(p0))
                    }
                }

                enum Output: Equatable {
                    case updatedName(String)
                    case child(ChildFeature.Output)
                }

                private static func translateChildOutputToAction(_ p0: ChildFeature.Output) -> TranslateResult<Action, Output> {
                    .passThrough(.child(p0))
                }

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func child(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: ChildFeature.Action) {

                    let innerSideEffects = sideEffects.map(Action.child, translate: translateChildOutputToAction)
                    ChildFeature.reduce(
                        &state.child,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .updateName(p0):
                        updateName(&state, sideEffects: sideEffects, p0)

                    case let .child(innerAction):
                            child(&state, sideEffects: sideEffects, action: innerAction)
                    }
                }

                @MainActor
                struct EngineView: View {
                    @LazyState var engine: ViewEngine<State, Action, Output>

                    var body: some View {
                        view(engine)
                    }
                }

                @MainActor
                @ViewBuilder
                private static func child(_ engine: ViewEngine<State, Action, Output>) -> ChildFeature.EngineView {
                    ChildFeature.EngineView(
                        engine: engine.map(
                            state: {
                                $0.child
                            },
                            action: Action.child,
                            translate: translateChildOutputToAction
                        ).view()
                    )
                }
            }

            extension MyFeature: Component, BaseComponent {
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
