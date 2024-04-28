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
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action>, newName: String) {
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

                    static func translate(from output: Subfeature.Output) -> Action? {
                        nil
                    }

                    @MainActor
                    static func view<E: Engine>(
                        _ engine: E,
                        inject: (DependencyScope) -> Void
                    ) -> some View where E.State == State, E.Action == Action {
                         Subfeature.EngineView(
                             engine: engine.scope(
                                 component: Subfeature.self,
                                 initialState: initialState,
                                 actionToUpdateState: actionToUpdateState,
                                 translate: self.translate,
                                 inject: inject
                             ).view()
                         )
                    }
                }
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action>, newName: String) {
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

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
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
            
                @MainActor
                @ViewBuilder
                private static func subfeature(
                    _ engine: ViewEngine<State, Action, Output>,
                    inject: (DependencyScope) -> Void = { _ in
                    }
                ) -> some View {
                    Subfeature.view(engine, inject: inject)
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
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action>, newName: String) {
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

                    static func translate(from output: Subfeature.Output) -> Action? {
                        nil
                    }

                    @MainActor
                    static func view<E: Engine>(
                        _ engine: E,
                        inject: (DependencyScope) -> Void
                    ) -> some View where E.State == State, E.Action == Action {
                         Subfeature.EngineView(
                             engine: engine.scope(
                                 component: Subfeature.self,
                                 initialState: initialState,
                                 actionToUpdateState: actionToUpdateState,
                                 translate: self.translate,
                                 inject: inject
                             ).view()
                         )
                    }
                }
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action>, newName: String) {
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

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
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
            
                @MainActor
                @ViewBuilder
                private static func subfeature(
                    _ engine: ViewEngine<State, Action, Output>,
                    inject: (DependencyScope) -> Void = { _ in
                    }
                ) -> some View {
                    Subfeature.view(engine, inject: inject)
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
            
                    static func translateFromSubfeature(from output: Subfeature.Output) -> Action? {
                        .increase
                    }
                }
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action>, newName: String) {
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

                    static func translateFromSubfeature(from output: Subfeature.Output) -> Action? {
                        .increase
                    }

                    static func actionToUpdateState(from state: State) -> Subfeature.Action? {
                        nil
                    }

                    @MainActor
                    static func view<E: Engine>(
                        _ engine: E,
                        inject: (DependencyScope) -> Void
                    ) -> some View where E.State == State, E.Action == Action {
                         Subfeature.EngineView(
                             engine: engine.scope(
                                 component: Subfeature.self,
                                 initialState: initialState,
                                 actionToUpdateState: actionToUpdateState,
                                 translate: self.translateFromSubfeature,
                                 inject: inject
                             ).view()
                         )
                    }
                }
            
                private static func increase(_ state: inout State, sideEffects: AnySideEffects<Action>) {
                    state.score += 1
                }
            
                private static func updateName(_ state: inout State, sideEffects: AnySideEffects<Action>, newName: String) {
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

                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>) {
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
            
                @MainActor
                @ViewBuilder
                private static func subfeature(
                    _ engine: ViewEngine<State, Action, Output>,
                    inject: (DependencyScope) -> Void = { _ in
                    }
                ) -> some View {
                    Subfeature.view(engine, inject: inject)
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
