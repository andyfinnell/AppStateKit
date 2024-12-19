import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum BindBatchError: Error {
    case missingArguments
    case unexpectedKeyPathExpression
}

public enum BindBatchMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let engineExpr = node.arguments.first?.expression,
              let keyPathExpr = node.arguments.last?.expression else {
            throw BindBatchError.missingArguments
        }
        let actionName = try actionNameFromKeyPath(keyPathExpr)
        let expr: ExprSyntax = """
            \(engineExpr).binding(\(keyPathExpr), send: { .\(raw: actionName)($0) })
            """
        return expr
    }
}

private extension BindBatchMacro {
    static func actionNameFromKeyPath(_ expr: ExprSyntax) throws -> String {
        // Grab the last segment, prepend "update"
        guard let keyPathExpr = expr.as(KeyPathExprSyntax.self) else {
            throw BindBatchError.unexpectedKeyPathExpression
        }
        
        let lastPathComponent = keyPathExpr.components
            .compactMap { $0.component.as(KeyPathPropertyComponentSyntax.self) }
            .last
        guard let lastPathComponent else {
            throw BindBatchError.unexpectedKeyPathExpression
        }
        
        return "update\(lastPathComponent.declName.baseName.text.uppercaseFirstLetter())"
    }
}
