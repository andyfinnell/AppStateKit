import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class DetachmentMacroTests: XCTestCase {
    func testBasicDetachment() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var score: Int
                }
            
                @Detachment
                enum Subfeature {
                    static func initialState(_ state: State) -> Subfeature.State {
                        Subfeature.State(score: state.score)
                    }
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
                enum Subfeature {
                    static func initialState(_ state: State) -> Subfeature.State {
                        Subfeature.State(score: state.score)
                    }

                    static func actionToUpdateState(from state: State) -> Subfeature.Action? {
                        nil
                    }

                    static func translate(from output: Subfeature.Output) -> TranslateResult<Action, Output> {
                        .drop
                    }

                    @MainActor
                    static func view<E: Engine>(
                        _ engine: E,
                        inject: @escaping (DependencyScope) -> Void
                    ) -> Subfeature.EngineView where E.State == State, E.Action == Action, E.Output == Output {
                         Subfeature.EngineView(
                             engine: engine.detach(
                                 component: Subfeature.self,
                                 initialState: initialState,
                                 actionToUpdateState: actionToUpdateState,
                                 translate: self.translate,
                                 detachment: Subfeature.self,
                                 inject: inject
                             ).view()
                         )
                    }
                }
                @MainActor
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
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
            
                @MainActor
                @ViewBuilder
                private static func subfeature(
                    _ engine: ViewEngine<State, Action, Output>,
                    inject: @escaping (DependencyScope) -> Void = { _ in
                    }
                ) -> some View {
                    Subfeature.view(engine, inject: inject)
                }
            }
            
            extension Subfeature: Detachment {
                typealias DetachedAction = Subfeature.Action
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
    
    func testDetachmentWithActionToUpdateState() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var score: Int
                }
            
                @Detachment
                enum Subfeature {
                    static func initialState(_ state: State) -> Subfeature.State {
                        Subfeature.State(score: state.score)
                    }
            
                    static func actionToUpdateState(from state: State) -> Subfeature.Action? {
                        .updateScore(state.score)
                    }
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
                enum Subfeature {
                    static func initialState(_ state: State) -> Subfeature.State {
                        Subfeature.State(score: state.score)
                    }

                    static func actionToUpdateState(from state: State) -> Subfeature.Action? {
                        .updateScore(state.score)
                    }

                    static func translate(from output: Subfeature.Output) -> TranslateResult<Action, Output> {
                        .drop
                    }

                    @MainActor
                    static func view<E: Engine>(
                        _ engine: E,
                        inject: @escaping (DependencyScope) -> Void
                    ) -> Subfeature.EngineView where E.State == State, E.Action == Action, E.Output == Output {
                         Subfeature.EngineView(
                             engine: engine.detach(
                                 component: Subfeature.self,
                                 initialState: initialState,
                                 actionToUpdateState: actionToUpdateState,
                                 translate: self.translate,
                                 detachment: Subfeature.self,
                                 inject: inject
                             ).view()
                         )
                    }
                }
                @MainActor
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
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
            
                @MainActor
                @ViewBuilder
                private static func subfeature(
                    _ engine: ViewEngine<State, Action, Output>,
                    inject: @escaping (DependencyScope) -> Void = { _ in
                    }
                ) -> some View {
                    Subfeature.view(engine, inject: inject)
                }
            }
            
            extension Subfeature: Detachment {
                typealias DetachedAction = Subfeature.Action
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

    func testDetachmentWithActionToPassUp() throws {
        #if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Component
            enum MyFeature {
                struct State {
                    var name: String
                    var score: Int
                }
            
                @Detachment
                enum Subfeature {
                    static func initialState(_ state: State) -> Subfeature.State {
                        Subfeature.State(score: state.score)
                    }
            
                    static func translateFromSubfeature(from output: Subfeature.Output) -> TranslateResult<Action, Output> {
                        .perform(.increase)
                    }
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
                enum Subfeature {
                    static func initialState(_ state: State) -> Subfeature.State {
                        Subfeature.State(score: state.score)
                    }

                    static func translateFromSubfeature(from output: Subfeature.Output) -> TranslateResult<Action, Output> {
                        .perform(.increase)
                    }

                    static func actionToUpdateState(from state: State) -> Subfeature.Action? {
                        nil
                    }

                    @MainActor
                    static func view<E: Engine>(
                        _ engine: E,
                        inject: @escaping (DependencyScope) -> Void
                    ) -> Subfeature.EngineView where E.State == State, E.Action == Action, E.Output == Output {
                         Subfeature.EngineView(
                             engine: engine.detach(
                                 component: Subfeature.self,
                                 initialState: initialState,
                                 actionToUpdateState: actionToUpdateState,
                                 translate: self.translateFromSubfeature,
                                 detachment: Subfeature.self,
                                 inject: inject
                             ).view()
                         )
                    }
                }
                @MainActor
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
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
            
                @MainActor
                @ViewBuilder
                private static func subfeature(
                    _ engine: ViewEngine<State, Action, Output>,
                    inject: @escaping (DependencyScope) -> Void = { _ in
                    }
                ) -> some View {
                    Subfeature.view(engine, inject: inject)
                }
            }
            
            extension Subfeature: Detachment {
                typealias DetachedAction = Subfeature.Action
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
