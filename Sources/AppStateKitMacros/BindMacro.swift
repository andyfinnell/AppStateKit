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
        guard let engineExpr = node.argumentList.first?.expression,
              let keyPathExpr = node.argumentList.last?.expression else {
            throw BindError.missingArguments
        }
        let actionName = try actionNameFromKeyPath(keyPathExpr)
        let expr: ExprSyntax = """
            \(engineExpr).binding(\(keyPathExpr), send: { .\(raw: actionName)($0) })
            """
        return expr
    }
}

private extension BindMacro {
    static func actionNameFromKeyPath(_ expr: ExprSyntax) throws -> String {
        // Grab the last segment, append "DidChange"
        guard let keyPathExpr = expr.as(KeyPathExprSyntax.self) else {
            throw BindError.unexpectedKeyPathExpression
        }
        
        let lastPathComponent = keyPathExpr.components
            .compactMap { $0.component.as(KeyPathPropertyComponentSyntax.self) }
            .last
        guard let lastPathComponent else {
            throw BindError.unexpectedKeyPathExpression
        }
        
        return "\(lastPathComponent.declName.baseName)DidChange"
    }
}
