import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum BindError: Error {
    case missingArguments
    case unexpectedKeyPathExpression
}

public enum BindMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let engineExpr = node.arguments.first?.expression,
              let keyPathExpr = node.arguments.last?.expression else {
            throw BindError.missingArguments
        }
        let actionName = try BindParser.parseActionNameFromKeyPath(keyPathExpr)
        let expr: ExprSyntax = """
            \(engineExpr).binding(\(keyPathExpr), send: { .\(raw: actionName)($0) })
            """
        return expr
    }
}

