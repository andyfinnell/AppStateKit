import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum JSONStorageEffectsMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let model = parseArguments(arguments) else {
            return []
        }
        
        let decls = JSONStorageCodegen.codegen(from: model)
        
        return decls.compactMap { $0 }
    }
}

private extension JSONStorageEffectsMacro {
    static func parseArguments(_ arguments: LabeledExprListSyntax) -> JSONStorageModel? {
        guard arguments.count >= 1 && arguments.count <= 2,
            let nameArgument = arguments.first,
            let typename = parseName(nameArgument.expression) else {
            return nil
        }
        
        var defaultValueExpr: ExprSyntax?
        if arguments.count > 1, let exprArgument = arguments.last {
            defaultValueExpr = exprArgument.expression
        }
        
        return JSONStorageModel(
            typename: typename,
            defaultValueExpression: defaultValueExpr
        )
    }

    static func parseName(_ expression: ExprSyntax) -> String? {
        guard let access = expression.as(MemberAccessExprSyntax.self),
              let ref = access.base?.as(DeclReferenceExprSyntax.self) else {
            return nil
        }
        return ref.baseName.text
    }

}
