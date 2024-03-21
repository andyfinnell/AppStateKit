import SwiftSyntax
import SwiftSyntaxBuilder

struct AppComponentMainCodegen {
    static func codegen(from component: Component) -> DeclSyntax? {
        let decl: DeclSyntax = """
            static func main() {
                MainApp.main()
            }
            """
        
        return decl
    }
}
