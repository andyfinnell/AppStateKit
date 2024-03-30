import SwiftSyntax

struct DetachmentParser {
    static func parse(_ decl: EnumDeclSyntax) -> Detachment? {
        var componentName: String?
        var hasActionToUpdateStateMethod = false
        var hasActionToPassUpMethod = false
        
        for member in decl.memberBlock.members {
            guard let functionDecl = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }
            
            if componentName == nil {
                componentName = parseInitialStateMethod(functionDecl)
            }
            if isActionToUpdateStateMethod(functionDecl) {
                hasActionToUpdateStateMethod = true
            } else if isActionToPassUpMethod(functionDecl) {
                hasActionToPassUpMethod = true
            }
        }
        
        guard let componentName else {
            return nil
        }

        return Detachment(
            componentName: componentName,
            hasActionToUpdateState: hasActionToUpdateStateMethod,
            hasActionToPassUp: hasActionToPassUpMethod
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
                && functionDecl.signature.effectSpecifiers?.throwsSpecifier == nil
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
                && functionDecl.signature.effectSpecifiers?.throwsSpecifier == nil
                && isStatic else {
            return false
        }
        
        guard isType(parameter.type, named: "State") else {
            return false
        }
        
        let (_, isAction) = isOptionalTypeScoped(returnClause.type, named: "Action")
        
        return isAction
    }
    
    static func isActionToPassUpMethod(_ functionDecl: FunctionDeclSyntax) -> Bool {
        guard functionDecl.name.text == "actionToPassUp" else {
            return false
        }
        // needs to be static
        // needs to take Component.Action as parameter
        // needs to have Action return
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let parameter = functionDecl.signature.parameterClause.parameters.first,
              let returnClause = functionDecl.signature.returnClause,
              functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsSpecifier == nil
                && isStatic else {
            return false
        }
        
        guard isOptionalType(returnClause.type, named: "Action") else {
            return false
        }
        
        let (_, isAction) = isTypeScoped(parameter.type, named: "Action")
        
        return isAction
    }

    static func isType(_ typeSyntax: TypeSyntax, named name: String) -> Bool {
        if let identifierType = typeSyntax.as(IdentifierTypeSyntax.self),
           identifierType.name.text == name {
            return true
        } else {
            return false
        }
    }
    
    static func isTypeScoped(_ typeSyntax: TypeSyntax, named name: String) -> (String?, Bool) {
        if let memberType = typeSyntax.as(MemberTypeSyntax.self.self),
            memberType.name.text == name {
            if let identifierType = memberType.baseType.as(IdentifierTypeSyntax.self) {
                return (identifierType.name.text, true)
            } else {
                return (nil, true)
            }
        } else {
            return (nil, false)
        }
    }
    
    static func isOptionalTypeScoped(_ typeSyntax: TypeSyntax, named name: String) -> (String?, Bool) {
        guard let optionalType = typeSyntax.as(OptionalTypeSyntax.self) else {
            return (nil, false)
        }
        return isTypeScoped(optionalType.wrappedType, named: name)
    }
    
    static func isOptionalType(_ typeSyntax: TypeSyntax, named name: String) -> Bool {
        guard let optionalType = typeSyntax.as(OptionalTypeSyntax.self) else {
            return false
        }
        return isType(optionalType.wrappedType, named: name)
    }
}
