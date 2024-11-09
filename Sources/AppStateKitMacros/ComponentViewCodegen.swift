import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentViewCodegen {
    static func codegen(from component: Component) -> DeclSyntax? {
        let hasComponentInit = !component.subscriptions.isEmpty
        let componentInitCall = hasComponentInit ? "\n            .task { engine.send(.componentInit) }\n" : ""
        let decl: DeclSyntax = """
            @MainActor
            struct EngineView: View {
                @LazyState var engine: ViewEngine<State, Action, Output>
            
                var body: some View {
                    view(engine)\(raw: componentInitCall)
                }
            }
            """
        
        return decl
    }
}
