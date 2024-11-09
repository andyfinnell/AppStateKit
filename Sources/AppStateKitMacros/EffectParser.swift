import SwiftSyntax

struct EffectParser {
    static func parse(_ decl: EnumDeclSyntax, isImmediate: Bool) -> Effect? {
        let effectName = parseEffectName(decl)
        let performMethods = decl.memberBlock.members.compactMap {
            $0.decl.as(FunctionDeclSyntax.self)
        }.compactMap {
            parsePerformMethod(
                $0,
                withMethodName: effectName,
                typename: decl.name.text,
                isImmediate: isImmediate
            )
        }
        return performMethods.first
    }
    
    static func parseEffectName(_ typename: String) -> String {
        var basename = typename
        if basename.hasSuffix("Effect") {
            basename = String(basename.dropLast("Effect".count))
        }
        return basename.lowercasedFirstWord()
    }
    
    static func isImmediatePerformMethod(_ member: some DeclSyntaxProtocol) -> Bool {
        guard let functionDecl = member.as(FunctionDeclSyntax.self),
              functionDecl.name.text == "perform" else {
            return false
        }
        // needs to be static
        // needs to take dependencies: DependencyScope as first parameter
        // it is not async
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let parameter = functionDecl.signature.parameterClause.parameters.first,
              functionDecl.signature.parameterClause.parameters.count >= 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && isStatic
                && isDependencyScope(parameter) else {
            return false
        }
        
        return true
    }

}

private extension EffectParser {
    static func parseEffectName(_ decl: EnumDeclSyntax) -> String {
        parseEffectName(decl.name.text)
    }
    
    static func parsePerformMethod(
        _ functionDecl: FunctionDeclSyntax,
        withMethodName methodName: String,
        typename: String,
        isImmediate: Bool
    ) -> Effect? {
        // needs to be static
        // needs to take DependencyScope as first parameter
        // parse return type
        // check if throws
        // check if async
        // can take any number of parameters after 1st
        guard functionDecl.name.text == "perform" else {
            return nil
        }
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard functionDecl.signature.parameterClause.parameters.count >= 1
                && isStatic else {
            return nil
        }
        
        var parameters = [EffectParameter]()
        for (i, parameter) in functionDecl.signature.parameterClause.parameters.enumerated() {
            switch i {
            case 0:
                if !isDependencyScope(parameter) {
                    return nil
                }
                
            default:
                let parameterLabel = parameter.firstName.text == "_" ? nil : parameter.firstName.text
                parameters.append(EffectParameter(
                    label: parameterLabel,
                    name: parameter.secondName?.text ?? parameter.firstName.text,
                    type: parameter.type
                ))
            }
        }
        
        let isAsync = functionDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrowing = functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
        let returnType = functionDecl.signature.returnClause?.type

        return Effect(
            typename: typename,
            methodName: methodName,
            parameters: parameters,
            returnType: returnType,
            isThrowing: isThrowing,
            isAsync: isAsync,
            isImmediate: isImmediate
        )
    }
    
    static func isDependencyScope(_ parameter: FunctionParameterSyntax) -> Bool {
        // Expect: dependencies: DependencyScope
        guard parameter.firstName.text == "dependencies" else {
            return false
        }
        guard let identifier = parameter.type.as(IdentifierTypeSyntax.self),
              identifier.name.text == "DependencyScope" else {
            return false
        }
        return true
    }
}
