import SwiftSyntax
import SwiftSyntaxBuilder

enum BindParser {
    static func parseActionNameFromKeyPath(_ expr: ExprSyntax) throws -> String {
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
