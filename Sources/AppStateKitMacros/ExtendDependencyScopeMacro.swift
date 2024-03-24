import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ExtendDependencyScopeMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let typenameArgument = node.arguments?.as(LabeledExprListSyntax.self)?.first,
              let referenceExpression = typenameArgument.expression.as(DeclReferenceExprSyntax.self) else {
            return []
        }
        let typename = referenceExpression.baseName.text
        let methodName = EffectParser.parseEffectName(typename)
        
        let decl: DeclSyntax = """
            var \(raw: methodName): \(raw: typename).T {
                self[\(raw: typename).self]
            }
            """
        
        return [decl].compactMap { $0 }
    }
}
