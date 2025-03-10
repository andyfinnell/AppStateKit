import SwiftSyntax

struct DetachmentParser {
    static func parse(_ decl: EnumDeclSyntax) -> Detachment? {
        var componentName: String?
        var hasActionToUpdateStateMethod = false
        var translateMethodName: String?
        
        for member in decl.memberBlock.members {
            guard let functionDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }
            
            if componentName == nil {
                componentName = parseInitialStateMethod(functionDecl)
            }
            if isActionToUpdateStateMethod(functionDecl) {
                hasActionToUpdateStateMethod = true
            } else if let translateMethod = parseTranslateMethod(functionDecl) {
                translateMethodName = translateMethod
            }
        }
        
        guard let componentName else {
            return nil
        }

        return Detachment(
            name: decl.name.text,
            componentName: componentName,
            hasActionToUpdateState: hasActionToUpdateStateMethod,
            translateMethodName: translateMethodName
        )
    }
}

private extension DetachmentParser {
    static func parseInitialStateMethod(_ functionDecl: FunctionDeclSyntax) -> String? {
        guard functionDecl.name.text == "initialState" else {
            return nil
        }
        // needs to be static
        // needs to take State as parameter
        // needs to have Component.State return
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let parameter = functionDecl.signature.parameterClause.parameters.first,
              let returnClause = functionDecl.signature.returnClause,
              functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier == nil
                && isStatic else {
            return nil
        }
        
        guard isType(parameter.type, named: "State") else {
            return nil
        }
        
        let (componentName, isState) = isTypeScoped(returnClause.type, named: "State")
        guard let componentName, isState else {
            return nil
        }
        return componentName
    }
    
    static func isActionToUpdateStateMethod(_ functionDecl: FunctionDeclSyntax) -> Bool {
        guard functionDecl.name.text == "actionToUpdateState" else {
            return false
        }
        // needs to be static
        // needs to take State as parameter
        // needs to have Component.Action? return
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let parameter = functionDecl.signature.parameterClause.parameters.first,
              let returnClause = functionDecl.signature.returnClause,
              functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier == nil
                && isStatic else {
            return false
        }
        
        guard isType(parameter.type, named: "State") else {
            return false
        }
        
        let (_, isAction) = isOptionalTypeScoped(returnClause.type, named: "Action")
        
        return isAction
    }
    
    static func parseTranslateMethod(_ functionDecl: FunctionDeclSyntax) -> String? {
        // needs to be static
        // needs to take Component.Output as parameter
        // needs to have Action? return
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let parameter = functionDecl.signature.parameterClause.parameters.first,
              let returnClause = functionDecl.signature.returnClause,
              functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier == nil
                && isStatic else {
            return nil
        }
        
        guard doesType(returnClause.type, haveName: "TranslateResult", withTypeParameters: "Action", "Output") else {
            return nil
        }
        
        let (_, isAction) = isTypeScoped(parameter.type, named: "Output")
        guard isAction else {
            return nil
        }
        
        return functionDecl.name.text
    }

}
