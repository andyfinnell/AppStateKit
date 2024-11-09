import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ImmediateEffectMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self),
              let effect = EffectParser.parse(enumDecl, isImmediate: true) else {
            // TODO: emit error that it must be enum
            return []
        }

        let decls = [
            EffectDependableCodegen.codegen(from: effect),
        ]
        return decls.compactMap {
            $0?.as(ExtensionDeclSyntax.self)
        }
    }
}

extension ImmediateEffectMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard EffectParser.isImmediatePerformMethod(member) else {
            return []
        }
        
        let attr: AttributeSyntax = """
            @MainActor
            """
        
        return [
            attr
        ]
    }
}
