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
            codegenMethod(from: effect),
            codegenSubscribeMethod(from: effect),
        ]
        
        return decls.compactMap { $0 }
    }
}

private extension ExtendSideEffectsMacro {
    struct Parameter {
        let label: String?
        let type: String
    }
    
    struct Effect {
        let methodName: String
        let subscribeName: String
        let parameters: [Parameter]
        let returnType: String
        let isThrowing: Bool
        let isAsync: Bool
    }
    
    static func parseArguments(_ arguments: LabeledExprListSyntax) -> Effect? {
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
    ) -> Effect? {
        if let functionType = expression.as(FunctionTypeSyntax.self) {
            return parseClosureType(functionType, withMethodName: methodName, subscribeName: subscribeName)
        } else if let infixOperator = expression.as(InfixOperatorExprSyntax.self) {
            return parseClosureType(infixOperator, withMethodName: methodName, subscribeName: subscribeName)
        } else {
            return nil
        }
    }

    static func parseClosureType(
        _ infixOperation: InfixOperatorExprSyntax,
        withMethodName name: String,
        subscribeName: String
    ) -> Effect? {
        guard let arrowExpr = infixOperation.operator.as(ArrowExprSyntax.self),
              let parametersExpr = infixOperation.leftOperand.as(TupleExprSyntax.self) else {
            return nil
        }
        
        let parameters = parametersExpr.elements.map {
            Parameter(label: $0.label?.text, type: "\($0.expression)")
        }
        
        let isThrowing = arrowExpr.effectSpecifiers?.throwsSpecifier != nil
        let isAsync = arrowExpr.effectSpecifiers?.asyncSpecifier != nil
        let returnType = "\(infixOperation.rightOperand)"
        
        return Effect(
            methodName: name, 
            subscribeName: subscribeName,
            parameters: parameters,
            returnType: returnType,
            isThrowing: isThrowing,
            isAsync: isAsync
        )
    }
    
    // TODO: is this still needed?
    static func parseClosureType(
        _ closureType: FunctionTypeSyntax,
        withMethodName methodName: String,
        subscribeName: String
    ) -> Effect? {
        let parameters = closureType.parameters.map {
            Parameter(label: $0.firstName?.text, type: "\($0.type)")
        }
        let isThrowing = closureType.effectSpecifiers?.throwsSpecifier != nil
        let isAsync = closureType.effectSpecifiers?.asyncSpecifier != nil
        let returnType = closureType.returnClause.type
        
        return Effect(
            methodName: methodName,
            subscribeName: subscribeName,
            parameters: parameters,
            returnType: "\(returnType)",
            isThrowing: isThrowing,
            isAsync: isAsync
        )
    }
    
    static func codegenMethod(from effect: Effect) -> DeclSyntax? {
        let parameters = codegenParameters(from: effect)
        let body = codegenBody(from: effect)
        let decl: DeclSyntax = """
            func \(raw: effect.methodName)(
                \(raw: parameters)
            ) {
                \(raw: body)
            }
            """
        
        return decl
    }
    
    static func codegenParameters(from effect: Effect) -> String {
        var parameters = effect.parameters.enumerated().map { i, parameter in
            if let label = parameter.label {
                return "\(label) p\(i): \(parameter.type)"
            } else {
                return "_ p\(i): \(parameter.type)"
            }
        }
        
        parameters.append("transform: @escaping (\(effect.returnType)) async -> Action")
        if effect.isThrowing {
            parameters.append("onFailure: @escaping (Error) async -> Action")
        }
        return parameters.joined(separator: ",\n")
    }
    
    static func codegenBody(from effect: Effect) -> String {
        let arguments = (0..<effect.parameters.count).map { "p\($0)" }
            .joined(separator: ", ")
        if arguments.isEmpty {
            if effect.isThrowing {
                return "tryPerform(\\.\(effect.methodName), transform: transform, onFailure: onFailure)"
            } else {
                return "perform(\\.\(effect.methodName), transform: transform)"
            }
        } else {
            if effect.isThrowing {
                return "tryPerform(\\.\(effect.methodName), with: \(arguments), transform: transform, onFailure: onFailure)"
            } else {
                return "perform(\\.\(effect.methodName), with: \(arguments), transform: transform)"
            }
        }
    }
    
    static func codegenSubscribeMethod(from effect: Effect) -> DeclSyntax? {
        let parameters = codegenSubscribeParameters(from: effect)
        let body = codegenSubscribeBody(from: effect)
        let decl: DeclSyntax = """
            func \(raw: effect.subscribeName)(
                \(raw: parameters)
            ) -> SubscriptionID {
                \(raw: body)
            }
            """
        
        return decl
    }

    static func codegenSubscribeParameters(from effect: Effect) -> String {
        var parameters = effect.parameters.enumerated().map { i, parameter in
            if let label = parameter.label {
                return "\(label) p\(i): \(parameter.type)"
            } else {
                return "_ p\(i): \(parameter.type)"
            }
        }
        
        parameters.append("transform: @escaping (\(effect.returnType), (Action) async -> Void) async throws -> Void")
        return parameters.joined(separator: ",\n")
    }

    static func codegenSubscribeBody(from effect: Effect) -> String {
        let arguments = (0..<effect.parameters.count).map { "p\($0)" }
            .joined(separator: ", ")
        if arguments.isEmpty {
            return "subscribe(\\.\(effect.methodName), transform: transform)"
        } else {
            return "subscribe(\\.\(effect.methodName), with: \(arguments), transform: transform)"
        }
    }
}
