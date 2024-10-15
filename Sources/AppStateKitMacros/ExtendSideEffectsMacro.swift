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
              let effect = parseArguments(arguments) else {
            return []
        }
        
        let decls = [
            ExtendSideEffectsCodegen.codegenMethod(from: effect),
            ExtendSideEffectsCodegen.codegenSubscribeMethod(from: effect),
        ]
        
        return decls.compactMap { $0 }
    }
    
    static func parseSubscribeToMethodName(from exprSyntax: ExprSyntax) -> String? {
        var baseExpression = exprSyntax
        // If it's appended with `.self`, strip off `.self`
        if let member = baseExpression.as(MemberAccessExprSyntax.self),
           let memberBaseExpr = member.base,
            member.declName.baseName.text == "self" {
            baseExpression = memberBaseExpr
        }

        guard let typename = parseName(baseExpression) else {
            return nil
        }
        return parseSubscribeName(typename)
    }
}

private extension ExtendSideEffectsMacro {    
    static func parseArguments(_ arguments: LabeledExprListSyntax) -> SideEffect? {
        guard arguments.count == 2,
            let nameArgument = arguments.first,
            let closureTypeArgument = arguments.last,
            let typename = parseName(nameArgument.expression) else {
            return nil
        }
        
        let methodName = EffectParser.parseEffectName(typename)
        let subscribeName = parseSubscribeName(typename)
        return parseClosureType(
            closureTypeArgument.expression,
            withMethodName: methodName,
            subscribeName: subscribeName
        )
    }
    
    static func parseName(_ expression: ExprSyntax) -> String? {
        guard let ref = expression.as(DeclReferenceExprSyntax.self) else {
            return nil
        }
        return ref.baseName.text
    }

    static func parseSubscribeName(_ typename: String) -> String {
        var basename = typename
        if basename.hasSuffix("Effect") {
            basename = String(basename.dropLast("Effect".count))
        }
        return "subscribeTo\(basename)"
    }

    static func parseClosureType(
        _ expression: ExprSyntax,
        withMethodName methodName: String,
        subscribeName: String
    ) -> SideEffect? {
        if let infixOperator = expression.as(InfixOperatorExprSyntax.self) {
            return parseClosureType(infixOperator, withMethodName: methodName, subscribeName: subscribeName)
        } else {
            return nil
        }
    }

    static func parseClosureType(
        _ infixOperation: InfixOperatorExprSyntax,
        withMethodName name: String,
        subscribeName: String
    ) -> SideEffect? {
        guard let arrowExpr = infixOperation.operator.as(ArrowExprSyntax.self),
              let parametersExpr = infixOperation.leftOperand.as(TupleExprSyntax.self) else {
            return nil
        }
        
        let parameters = parametersExpr.elements.map {
            SideEffectParameter(label: $0.label?.text, type: "\($0.expression)")
        }
        
        let isThrowing = arrowExpr.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
        let isAsync = arrowExpr.effectSpecifiers?.asyncSpecifier != nil
        let returnType = "\(infixOperation.rightOperand)"
        
        return SideEffect(
            methodName: name, 
            subscribeName: subscribeName,
            parameters: parameters,
            returnType: returnType,
            isThrowing: isThrowing,
            isAsync: isAsync,
            effectReference: .keyPath(name)
        )
    }
        
}
