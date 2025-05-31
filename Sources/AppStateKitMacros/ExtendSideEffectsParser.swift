import SwiftSyntax

enum ExtendSideEffectsParser {
    static func parseArguments(_ arguments: LabeledExprListSyntax, isImmediate: Bool) -> SideEffect? {
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
            subscribeName: subscribeName,
            typename: typename,
            isImmediate: isImmediate
        )
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

private extension ExtendSideEffectsParser {
    static func parseName(_ expression: ExprSyntax) -> String? {
        var baseExpression = expression
        // If it's appended with `.self`, strip off `.self`
        if let member = baseExpression.as(MemberAccessExprSyntax.self),
           let memberBaseExpr = member.base,
            member.declName.baseName.text == "self" {
            baseExpression = memberBaseExpr
        }

        guard let ref = baseExpression.as(DeclReferenceExprSyntax.self) else {
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
        subscribeName: String,
        typename: String,
        isImmediate: Bool
    ) -> SideEffect? {
        var baseExpression = expression
        // If it's appended with `.self`, strip off `.self`
        if let member = baseExpression.as(MemberAccessExprSyntax.self),
           let memberBaseExpr = member.base,
            member.declName.baseName.text == "self" {
            baseExpression = memberBaseExpr
        }

        // If were wrapped in ().self then unwrap that tuple
        if let tuple = baseExpression.as(TupleExprSyntax.self),
           let labeledExpr = tuple.elements.first {
            baseExpression = labeledExpr.expression
        }
        
        if let infixOperator = baseExpression.as(InfixOperatorExprSyntax.self) {
            return parseClosureType(
                infixOperator,
                withMethodName: methodName,
                subscribeName: subscribeName,
                typename: typename,
                isImmediate: isImmediate
            )
        } else {
            return nil
        }
    }

    static func parseClosureType(
        _ infixOperation: InfixOperatorExprSyntax,
        withMethodName name: String,
        subscribeName: String,
        typename: String,
        isImmediate: Bool
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
            effectReference: .typename(typename),
            isImmediate: isImmediate
        )
    }

}
