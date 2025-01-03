import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ExtendSideEffectsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let effect = ExtendSideEffectsParser.parseArguments(arguments, isImmediate: false) else {
            return []
        }
        
        let decls = [
            ExtendSideEffectsCodegen.codegenMethod(from: effect),
            ExtendSideEffectsCodegen.codegenSubscribeMethod(from: effect),
        ]
        
        return decls.compactMap { $0 }
    }
}
