import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum EffectMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self),
              let effect = EffectParser.parse(enumDecl) else {
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
