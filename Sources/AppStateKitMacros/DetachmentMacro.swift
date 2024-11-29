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

extension DetachmentMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // TODO: emit error that it must be an enum (as namespace)
            return []
        }

        guard let detachment = DetachmentParser.parse(enumDecl) else {
            return []
        }

        let decl: DeclSyntax = """
            extension \(raw: enumDecl.name.text): Detachment {
                typealias DetachedAction = \(raw: detachment.componentName).Action
            }
            """
                
        return [
            decl.as(ExtensionDeclSyntax.self)
        ].compactMap { $0 }
    }
}
