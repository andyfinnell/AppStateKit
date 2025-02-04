import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum BindIfPresentMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let engineExpr = node.arguments.first?.expression,
              let keyPathExpr = node.arguments.last?.expression else {
            throw BindError.missingArguments
        }
        let actionName = try actionNameFromKeyPath(keyPathExpr)
        let expr: ExprSyntax = """
            \(engineExpr).binding(
                get: { $0[keyPath: \(keyPathExpr)] != nil },
                send: { $0 ? nil : .\(raw: actionName)(nil) }
            )
            """
        return expr
    }
}

private extension BindIfPresentMacro {
    static func actionNameFromKeyPath(_ expr: ExprSyntax) throws -> String {
        // Grab the last segment, prepend "update"
        guard let keyPathExpr = expr.as(KeyPathExprSyntax.self) else {
            throw BindError.unexpectedKeyPathExpression
        }
        
        let lastPathComponent = keyPathExpr.components
            .compactMap { $0.component.as(KeyPathPropertyComponentSyntax.self) }
            .last
        guard let lastPathComponent else {
            throw BindError.unexpectedKeyPathExpression
        }
        
        return "update\(lastPathComponent.declName.baseName.text.uppercaseFirstLetter())"
    }
}
