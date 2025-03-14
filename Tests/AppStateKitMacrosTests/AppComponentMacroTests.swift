import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class AppComponentMacroTests: XCTestCase {
    func testBasicAppComponent() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @AppComponent
            enum MyApp {
                struct State {
                    var counters: CounterListComponent.State
                }
                
                static func initialState() -> State {
                    State(counters: .init(
                        name: "Main",
                        counters: [
                            .init(id: UUID(), count: 1, countText: "1"),
                            .init(id: UUID(), count: 0, countText: "0"),
                        ]
                    ))
                }
                
                static func scene(_ engine: ViewEngine<State, Action, Output>) -> some Scene {
                    WindowGroup {
                        counters(engine)
                    }
                }
            }
            """,
            expandedSource: """
            
            enum MyApp {
                struct State {
                    var counters: CounterListComponent.State
                }
                
                static func initialState() -> State {
                    State(counters: .init(
                        name: "Main",
                        counters: [
                            .init(id: UUID(), count: 1, countText: "1"),
                            .init(id: UUID(), count: 0, countText: "0"),
                        ]
                    ))
                }
                @MainActor
                
                static func scene(_ engine: ViewEngine<State, Action, Output>) -> some Scene {
                    WindowGroup {
                        counters(engine)
                    }
                }

                enum Action: Equatable {
                    case counters(CounterListComponent.Action)
                }
            
                typealias Output = Never

                typealias SideEffects = AnySideEffects<Action, Output>

                @MainActor
                private static func counters(_ state: inout State, sideEffects: AnySideEffects<Action, Output>, action innerAction: CounterListComponent.Action) {

                    let innerSideEffects = sideEffects.map(Action.counters, translate: { (_: CounterListComponent.Output) -> TranslateResult<Action, Output> in
                        })
                    CounterListComponent.reduce(
                        &state.counters,
                        action: innerAction,
                        sideEffects: innerSideEffects
                    )

                }

                @MainActor
                static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                    switch action {
                    case let .counters(innerAction):
                        counters(&state, sideEffects: sideEffects, action: innerAction)
                    }
                }

                @MainActor
                struct MainApp: App {
                    @LazyState var engine = MainEngine<State, Action>(
                        dependencies: dependencies(),
                        state: initialState(),
                        component: MyApp.self
                    )

                    var body: some Scene {
                        scene(engine.view())
                    }
                }

                @MainActor
                static func main() {
                    MainApp.main()
                }

                @MainActor
                @ViewBuilder
                private static func counters(_ engine: ViewEngine<State, Action, Output>) -> CounterListComponent.EngineView {
                    CounterListComponent.EngineView(
                        engine: engine.map(
                            state: {
                                $0.counters
                            },
                            action: Action.counters
                        ).view()
                    )
                }
            }
            
            extension MyApp: AppComponent {
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
}
