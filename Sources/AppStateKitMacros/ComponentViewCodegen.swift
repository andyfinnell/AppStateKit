import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentViewCodegen {
    static func codegen(from component: Component) -> DeclSyntax? {
        let decl: DeclSyntax = """
            struct EngineView: View {
                @SwiftUI.State var engine: ViewEngine<State, Action, Output>
            
                var body: some View {
                    view(engine)
                }
            }
            """
        
        return decl
    }
}
