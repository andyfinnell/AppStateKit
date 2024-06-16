import SwiftSyntax

struct ComponentParser {
    static func parse(_ decl: EnumDeclSyntax) -> Component {
        var actions = [Action]()
        var compositions = [Composition]()
        var detachments = [DetachmentRef]()
        var translateCompositionMethodNames = [String: String]()
        var hasDefinedOutput = false
        
        for member in decl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                if let action = computeActionFromFunction(funcDecl) {
                    actions.append(action)
                } else if let outputTranslation = computeOutputTranslationFromFunction(funcDecl) {
                    translateCompositionMethodNames[outputTranslation.componentName] = outputTranslation.translateMethod
                }
            } else if let structDecl = member.decl.as(StructDeclSyntax.self) {
                let (stateCompositions, stateActions) = computeCompositionAndActionsFromStateStruct(structDecl)
                compositions.append(contentsOf: stateCompositions)
                actions.append(contentsOf: stateActions)
            } else if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
                if let detachmentRef = parseDetachment(enumDecl) {
                    detachments.append(detachmentRef)
                }
            }
            
            if !hasDefinedOutput {
                hasDefinedOutput = isOutputDefinition(member.decl)
            }
        }
        
        let compositionActions = compositions.compactMap {
            actionFromComposition($0)
        }
        
        return Component(
            name: decl.name.text,
            compositions: compositions,
            actions: actions + compositionActions,
            detachments: detachments, 
            hasDefinedOutput: hasDefinedOutput, 
            translateCompositionMethodNames: translateCompositionMethodNames
        )
    }
    
    static func isUserDefinedActionMethod(_ member: some DeclSyntaxProtocol) -> Bool {
        if let funcDecl = member.as(FunctionDeclSyntax.self) {
            return computeActionFromFunction(funcDecl) != nil
        } else {
            return false
        }
    }
    
    static func isViewMethod(_ member: some DeclSyntaxProtocol) -> Bool {
        guard let functionDecl = member.as(FunctionDeclSyntax.self),
              functionDecl.name.text == "view" else {
            return false
        }
        // needs to be static
        // needs to take ViewEngine<State, Action, Output> as  parameter
        // needs to have View return
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let parameter = functionDecl.signature.parameterClause.parameters.first,
              functionDecl.signature.returnClause != nil,
              functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsSpecifier == nil
                && isStatic else {
            return false
        }
        
        guard doesType(
            parameter.type,
            haveName: "ViewEngine",
            withOneTypeParameters: "State", "Action", "Output"
        ) else {
            return false
        }
        
        return true
    }
    
    static func isSceneMethod(_ member: some DeclSyntaxProtocol) -> Bool {
        guard let functionDecl = member.as(FunctionDeclSyntax.self),
              functionDecl.name.text == "scene" else {
            return false
        }
        // needs to be static
        // needs to take ViewEngine<State, Action, Output> as  parameter
        // needs to have View return
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let parameter = functionDecl.signature.parameterClause.parameters.first,
              functionDecl.signature.returnClause != nil,
              functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsSpecifier == nil
                && isStatic else {
            return false
        }
        
        guard doesType(
            parameter.type,
            haveName: "ViewEngine",
            withOneTypeParameters: "State", "Action", "Output"
        ) else {
            return false
        }
        
        return true
    }

}

private extension ComponentParser {
    struct OutputTranslation {
        let componentName: String
        let translateMethod: String
    }
    
    static func computeOutputTranslationFromFunction(_ functionDecl: FunctionDeclSyntax) -> OutputTranslation? {
        // needs to be static
        // needs to take from output: Foo.Output as inout as first parameter
        // needs to have Action return
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard let returnClause = functionDecl.signature.returnClause,
              let parameter = functionDecl.signature.parameterClause.parameters.first,
              let componentName = extractComponentNameFromOutput(parameter.type),
              functionDecl.signature.parameterClause.parameters.count == 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsSpecifier == nil
                && isStatic
                && optionalTypeName(returnClause.type) == "Action" else {
            // TODO: should this be a warning if everything else matches?
            return nil
        }
        
        return OutputTranslation(
            componentName: componentName,
            translateMethod: functionDecl.name.text
        )
    }
    
    static func optionalTypeName(_ typeSyntax: TypeSyntax) -> String? {
        guard let optionalType = typeSyntax.as(OptionalTypeSyntax.self),
              let identifier = optionalType.wrappedType.as(IdentifierTypeSyntax.self) else {
            return nil
        }
        return identifier.name.text
    }
    
    static func extractComponentNameFromOutput(_ typeSyntax: TypeSyntax) -> String? {
        guard let memberSyntax = typeSyntax.as(MemberTypeSyntax.self),
              memberSyntax.name.text == "Output" else {
            return nil
        }
        return memberSyntax.baseType.description
    }
    
    static func isOutputDefinition(_ decl: DeclSyntax) -> Bool {
        if let structDecl = decl.as(StructDeclSyntax.self) {
            return structDecl.name.text == "Output"
        } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
            return enumDecl.name.text == "Output"
        } else if let typealiasDecl = decl.as(TypeAliasDeclSyntax.self) {
            return typealiasDecl.name.text == "Output"
        } else {
            return false
        }
    }
    
    static func actionFromComposition(_ composition: Composition) -> Action? {
        // Should only have a property at this level
        switch composition {
        case let .property(name, innerComposition):
            return Action(
                label: name,
                parameters: parametersFromComposition(innerComposition),
                composition: composition, 
                implementation: nil
            )
            
        case .array, .dictionary, .named, .optional, .identifiableArray:
            return nil
        }
    }

    static func parametersFromComposition(_ composition: Composition) -> [Parameter] {
        switch composition {
        case .property:
            // Shouldn't get property at this level
            return []
        case let .named(typeDecl):
            return [Parameter(label: nil, type: memberType("Action", of: typeDecl))]
        case let .array(elementComposition):
            return parametersFromComposition(elementComposition) + [
                Parameter(label: "index", type: identifierType("Int"))
            ]
        case let .identifiableArray(id: id, value: valueComposition):
            return parametersFromComposition(valueComposition) + [
                Parameter(label: "id", type: id)
            ]
        case let .dictionary(key: key, value: valueComposition):
            return parametersFromComposition(valueComposition) + [
                Parameter(label: "key", type: key)
            ]
        case let .optional(wrapped):
            return parametersFromComposition(wrapped)
        }
    }
    
    static func identifierType(_ name: String) -> TypeSyntax {
        TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: name)))
    }
    
    static func memberType(_ name: String, of baseType: TypeSyntax) -> TypeSyntax {
        TypeSyntax(MemberTypeSyntax(baseType: baseType, name: TokenSyntax(stringLiteral: name)))
    }

    static func computeCompositionAndActionsFromStateStruct(_ structDecl: StructDeclSyntax) -> ([Composition], [Action]) {
        guard structDecl.name.text == "State" else {
            return ([], [])
        }
        
        var compositions = [Composition]()
        var actions = [Action]()
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            compositions.append(contentsOf: computeComposition(from: varDecl))
            actions.append(contentsOf: computeActions(from: varDecl))
        }
        return (compositions, actions)
    }
    
    static func computeComposition(from varDecl: VariableDeclSyntax) -> [Composition] {
        var compositions = [Composition]()
        for binding in varDecl.bindings {
            guard let typeDecl = binding.typeAnnotation?.type else {
                continue // Only interested where explicitly declared
            }
            
            guard let composition = computeComposition(from: typeDecl) else {
                continue
            }
            guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            let propertyComposition = Composition.property(identifierPattern.identifier.text, composition)
            compositions.append(propertyComposition)
            
        }
        return compositions
    }

    static func computeActions(from varDecl: VariableDeclSyntax) -> [Action] {
        let isUpdatable = varDecl.attributes.contains { attribute in
            guard case let .attribute(attr) = attribute,
                let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self) else {
                return false
            }
            return identifierType.name.text == "Updatable"
        }
        guard isUpdatable else {
            return []
        }

        var actions = [Action]()
        for binding in varDecl.bindings {
            guard let typeDecl = binding.typeAnnotation?.type,
                  let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            
            let actionName = "update" + identifierPattern.identifier.text.uppercaseFirstLetter()
            let implementation = AutogeneratedImplementation.updateStateProperty(identifierPattern.identifier.text)
            let action = Action(
                label: actionName,
                parameters: [
                    Parameter(label: nil, type: typeDecl)
                ],
                composition: nil,
                implementation: implementation
            )
            actions.append(action)
        }
        return actions
    }

    static func computeComposition(from typeDecl: TypeSyntax) -> Composition? {
        if let identifierType = typeDecl.as(IdentifierTypeSyntax.self) {
            if let elementType = extractParameterType(identifierType, ifTypeEquals: "IdentifiableArray"),
               let wrapped = computeComposition(from: elementType) {
                let idType = memberType("ID", of: elementType)
                return .identifiableArray(id: idType, value: wrapped)
            } else {
                return nil
            }
        } else if let memberType = typeDecl.as(MemberTypeSyntax.self) {
            if memberType.name.text == "State" {
                return .named(memberType.baseType)
            } else {
                return nil
            }
        } else if let optionalType = typeDecl.as(OptionalTypeSyntax.self) {
            if let wrapped = computeComposition(from: optionalType.wrappedType) {
                return .optional(wrapped)
            } else {
                return nil
            }
        } else if let arrayType = typeDecl.as(ArrayTypeSyntax.self) {
            if let wrapped = computeComposition(from: arrayType.element) {
                return .array(wrapped)
            } else {
                return nil
            }
        } else if let dictionaryType = typeDecl.as(DictionaryTypeSyntax.self) {
            if let wrapped = computeComposition(from: dictionaryType.value) {
                return .dictionary(key: dictionaryType.key, value: wrapped)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    static func computeActionFromFunction(_ functionDecl: FunctionDeclSyntax) -> Action? {
        // needs to be static
        // needs to take State as inout as first parameter
        // needs to take SideEffects<Action> as second parameter
        // needs to have Void return
        // can take any number of parameters after 2nd
        
        let isStatic = functionDecl.modifiers.contains { declModifier in
            declModifier.name.text == "static"
        }
        guard functionDecl.signature.parameterClause.parameters.count >= 2
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsSpecifier == nil
                && functionDecl.signature.returnClause == nil
                && isStatic else {
            // TODO: should this be a warning if everything else matches?
            return nil
        }
        
        var parameters = [Parameter]()
        for (i, parameter) in functionDecl.signature.parameterClause.parameters.enumerated() {
            switch i {
            case 0:
                if !isInOutState(parameter) {
                    return nil
                }
            case 1:
                if !isSideEffects(parameter) {
                    return nil
                }
            default:
                let parameterLabel = parameter.firstName.text == "_" ? nil : parameter.firstName.text
                parameters.append(Parameter(
                    label: parameterLabel,
                    type: parameter.type
                ))
            }
        }
        
        return Action(
            label: functionDecl.name.text,
            parameters: parameters,
            composition: nil, 
            implementation: nil
        )
    }
    
    static func isInOutState(_ parameter: FunctionParameterSyntax) -> Bool {
        // Expect: _ state: inout State
        guard parameter.firstName.text == "_" else {
            return false
        }
        guard let attributed = parameter.type.as(AttributedTypeSyntax.self),
              let specifier = attributed.specifier,
              specifier.text == "inout" else {
            return false
        }
        guard let identifier = attributed.baseType.as(IdentifierTypeSyntax.self),
              identifier.name.text == "State" else {
            return false
        }
        return true
    }
    
    static func isSideEffects(_ parameter: FunctionParameterSyntax) -> Bool {
        // Expect: sideEffects: AnySideEffects<Action, Output> OR SideEffects
        guard parameter.firstName.text == "sideEffects" else {
            return false
        }
        
        return doesType(
            parameter.type,
            haveName: "AnySideEffects",
            withOneTypeParameters: "Action", "Output"
        ) || doesType(parameter.type, haveName: "SideEffects")
    }

    static func extractParameterType(_ identifier: IdentifierTypeSyntax, ifTypeEquals typename: String) -> TypeSyntax? {
        guard let generics = identifier.genericArgumentClause,
              let firstArgument = generics.arguments.first,
              generics.arguments.count == 1,
              identifier.name.text == typename else {
            return nil
        }

        return firstArgument.argument
    }
        
    static func doesType(_ type: TypeSyntax, haveName typename: String, withOneTypeParameters parameterTypenames: String...) -> Bool {
        guard let identifier = type.as(IdentifierTypeSyntax.self),
              identifier.name.text == typename else {
            return false
        }

        guard let generics = identifier.genericArgumentClause,
              generics.arguments.count == parameterTypenames.count else {
            return false
        }
        
        for (argument, parameterTypename) in zip(generics.arguments, parameterTypenames) {
            guard let argumentIdentifier = argument.argument.as(IdentifierTypeSyntax.self),
                  argumentIdentifier.name.text == parameterTypename else {
                return false
            }
        }
        
        return true
    }

    static func doesType(_ type: TypeSyntax, haveName typename: String) -> Bool {
        guard let identifier = type.as(IdentifierTypeSyntax.self),
              identifier.name.text == typename else {
            return false
        }

        return identifier.genericArgumentClause == nil
    }

    static func parseDetachment(_ enumDecl: EnumDeclSyntax) -> DetachmentRef? {
        let isDetachment = enumDecl.attributes.contains { attribute in
            guard case let .attribute(attr) = attribute,
                let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self) else {
                return false
            }
            return identifierType.name.text == "Detachment"
        }
        guard isDetachment else {
            return nil
        }
        
        return DetachmentRef(
            typename: enumDecl.name.text,
            methodName: enumDecl.name.text.lowercasedFirstWord()
        )
    }
}
