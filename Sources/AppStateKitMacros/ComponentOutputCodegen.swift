import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentOutputCodegen {
    static func codegen(from component: Component) -> DeclSyntax? {
        guard !component.hasDefinedOutput else {
            return nil
        }
        
        let outputDecl: DeclSyntax = """
            typealias Output = Never
            """
        return outputDecl
    }
}
