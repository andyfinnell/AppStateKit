import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import BaseKit

public enum WithBindingMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let engineExpr = node.arguments.at(0)?.expression,
              let keyPathExpr = node.arguments.at(1)?.expression,
              let contentExpr = node.arguments.at(2)?.expression else {
            throw BindError.missingArguments
        }
        let actionName = try BindParser.parseActionNameFromKeyPath(keyPathExpr)
        let expr: ExprSyntax = """
            WithBinding(engine: \(engineExpr), keyPath: \(keyPathExpr), autosend: { .\(raw: actionName)($0) }, content: \(contentExpr))
            """
        return expr
    }
}

extension LabeledExprListSyntax {
    func at(_ i: Int) -> Element? {
        let elementIndex = index(startIndex, offsetBy: i)
        guard elementIndex >= startIndex && elementIndex < endIndex else {
            return nil
        }
        return self[elementIndex]
    }
}

private extension WithBindingMacro {
}
