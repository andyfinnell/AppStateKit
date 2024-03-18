import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Parse out the parameters
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // TODO: emit error that it must be an enum (as namespace)
            return []
        }
                
        let component = ComponentParser.parse(enumDecl)
        let decls: [DeclSyntax?] = [
            ComponentActionCodegen.codegen(from: component),
            ComponentReducerCodegen.codegen(from: component),
        ]
        
        return decls.compactMap { $0 }
    }
}
