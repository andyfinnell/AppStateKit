import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum JSONStorableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let name = parseName(declaration),
              let model = parseArguments(node.arguments?.as(LabeledExprListSyntax.self), withName: name) else {
            return []
        }
        
        let decls = JSONStorableCodegen.codegen(from: model)
        
        return decls.compactMap { $0 }
    }
}

private extension JSONStorableMacro {
    static func parseName(_ declaration: some DeclGroupSyntax) -> String? {
        if let a = declaration.as(ActorDeclSyntax.self) {
            return a.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let c = declaration.as(ClassDeclSyntax.self) {
            return c.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let e = declaration.as(EnumDeclSyntax.self) {
            return e.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let e = declaration.as(ExtensionDeclSyntax.self) {
            return "\(e.extendedType)".trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let s = declaration.as(StructDeclSyntax.self) {
            return s.name.text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return nil
        }
    }

    static func parseArguments(_ arguments: LabeledExprListSyntax?, withName name: String) -> JSONStorageModel? {
        var defaultValueExpr: ExprSyntax?
        if let arguments, arguments.count > 0,
           let exprArgument = arguments.first,
           let boolLiteral = exprArgument.expression.as(BooleanLiteralExprSyntax.self),
           boolLiteral.literal.text == "true" {
            defaultValueExpr = """
                \(raw: name).defaultValue()
                """
        }
        
        return JSONStorageModel(
            typename: name,
            defaultValueExpression: defaultValueExpr
        )
    }
}
