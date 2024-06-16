import SwiftSyntax
import SwiftSyntaxBuilder

struct AppComponentMainCodegen {
    static func codegen(from component: Component) -> DeclSyntax? {
        let decl: DeclSyntax = """
            @MainActor
            static func main() {
                MainApp.main()
            }
            """
        
        return decl
    }
}
