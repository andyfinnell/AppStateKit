import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum DetachmentMacro: MemberMacro {
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
        
        guard let detachment = DetachmentParser.parse(enumDecl) else {
            return []
        }
        
        let decls = DetachmentCodegen.codegen(from: detachment)
        
        return decls
    }
}
