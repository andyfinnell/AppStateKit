import SwiftSyntax
import SwiftSyntaxBuilder

struct AppComponentAppCodegen {
    static func codegen(from component: Component) -> [DeclSyntax] {
        let decl: DeclSyntax = """
            @MainActor
            struct MainApp: App {
                @LazyState var engine = MainEngine<State, Action>(
                    dependencies: dependencies(),
                    state: initialState(),
                    component: \(raw: component.name).self
                )
            
                var body: some Scene {
                    scene(engine.view())
                }
            }
            """
        
        return [decl]
    }
}
