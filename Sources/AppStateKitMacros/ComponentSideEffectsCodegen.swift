import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentSideEffectsCodegen {
    static func codegen(from component: Component) -> [DeclSyntax] {
        let outputDecl: DeclSyntax = """
            typealias SideEffects = AnySideEffects<Action, Output>
            """
        return [outputDecl]
    }
}
