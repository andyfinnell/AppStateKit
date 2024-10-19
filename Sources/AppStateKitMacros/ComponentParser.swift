import SwiftSyntax

struct ComponentParser {
    static func parse(_ decl: EnumDeclSyntax) -> Component {
        var actions = [Action]()
        var outputs = [ComponentOutput]()
        var compositions = [ComponentComposition]()
        var detachments = [DetachmentRef]()
        var translateCompositionMethodNames = [String: ComponentMethod]()
        var hasDefinedOutput = false
        var outputTypealias: String? = nil
        var subscriptions = [Subscription]()
        
        for member in decl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
                if let action = computeActionFromFunction(funcDecl) {
                    actions.append(action)
                } else if let outputTranslation = computeOutputTranslationFromFunction(funcDecl) {
                    translateCompositionMethodNames[outputTranslation.componentName] = outputTranslation.translateMethod
                }
            } else if let structDecl = member.decl.as(StructDeclSyntax.self) {
                let (stateCompositions, stateActions, stateOutputs, stateSubscriptions) = computeCompositionAndActionsFromStateStruct(structDecl)
                compositions.append(contentsOf: stateCompositions)
                actions.append(contentsOf: stateActions)
                outputs.append(contentsOf: stateOutputs)
                subscriptions.append(contentsOf: stateSubscriptions)
            } else if let enumDecl = member.decl.as(EnumDeclSyntax.self) {
                if let detachmentRef = parseDetachment(enumDecl) {
                    detachments.append(detachmentRef)
                }
            }
            
            if !hasDefinedOutput {
                (hasDefinedOutput, outputTypealias) = isOutputDefinition(member.decl)
            }
        }
        
        let compositionActions = compositions.flatMap {
            actionsFromComposition($0)
        }
        let compositionOutputs = compositions.flatMap {
            outputsFromComposition($0)
        }

        updateTranslateCompositionMethodNames(
            &translateCompositionMethodNames,
            withCompositions: compositions
        )
        
        var subscriptionActions = [Action]()
        if !subscriptions.isEmpty {
            subscriptionActions.append(
                Action(
                    label: "componentInit",
                    parameters: [],
                    composition: nil,
                    implementation: .componentInit
                )
            )
        }
        
        return Component(
            name: decl.name.text,
            compositions: compositions,
            actions: actions + compositionActions + subscriptionActions,
            detachments: detachments,
            hasDefinedOutput: hasDefinedOutput,
            isOutputNever: !hasDefinedOutput || outputTypealias == "Never", 
            translateCompositionMethodNames: translateCompositionMethodNames,
            outputs: outputs + compositionOutputs,
            subscriptions: subscriptions
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
                && functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier == nil
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
                && functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier == nil
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
        let translateMethod: ComponentMethod
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
              functionDecl.signature.parameterClause.parameters.count >= 1
                && functionDecl.signature.effectSpecifiers?.asyncSpecifier == nil
                && functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier == nil
                && isStatic
                && optionalTypeName(returnClause.type) == "Action" else {
            // TODO: should this be a warning if everything else matches?
            return nil
        }
        
        let methodParameters = functionDecl.signature.parameterClause.parameters.map { parameter in
            Parameter(
                label: parameter.firstName.text == "_" ? nil : parameter.firstName.text,
                type: parameter.type
            )
        }
        let method = ComponentMethod(
            name: functionDecl.name.text,
            parameters: methodParameters,
            returnType: returnClause.type
        )
        return OutputTranslation(
            componentName: componentName,
            translateMethod: method
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
    
    static func isOutputDefinition(_ decl: DeclSyntax) -> (Bool, String?) {
        if let structDecl = decl.as(StructDeclSyntax.self) {
            return (structDecl.name.text == "Output", nil)
        } else if let enumDecl = decl.as(EnumDeclSyntax.self) {
            return (enumDecl.name.text == "Output", nil)
        } else if let typealiasDecl = decl.as(TypeAliasDeclSyntax.self) {
            var realTypename: String?
            if let backingType = typealiasDecl.initializer.value.as(IdentifierTypeSyntax.self) {
                realTypename = backingType.name.text
            }
            return (typealiasDecl.name.text == "Output", realTypename)
        } else {
            return (false, nil)
        }
    }
    
    static func actionsFromComposition(_ composition: ComponentComposition) -> [Action] {
        // Should only have a property at this level
        switch composition.composition {
        case let .property(name, innerComposition):
            var actions = [
                Action(
                    label: name,
                    parameters: parametersFromComposition(innerComposition),
                    composition: composition.composition,
                    implementation: nil
                )
            ]
            if composition.passthroughOutput {
                actions.append(
                    passthroughActionForOutputComposition(propertyName: name, innerComposition: innerComposition)
                )
            }
            return actions
            
        case .array, .dictionary, .named, .optional, .identifiableArray:
            return []
        }
    }

    static func passthroughActionForOutputComposition(propertyName name: String, innerComposition: Composition) -> Action {
        Action(
            label: "passthrough\(name.uppercaseFirstLetter())Output",
            parameters: outputParametersFromComposition(innerComposition),
            composition: nil,
            implementation: .passthroughOutput(name)
        )
    }
    
    static func outputsFromComposition(_ composition: ComponentComposition) -> [ComponentOutput] {
        // Should only have a property at this level
        switch composition.composition {
        case let .property(name, innerComposition):
            if composition.passthroughOutput {
                let passthroughAction = passthroughActionForOutputComposition(propertyName: name, innerComposition: innerComposition)
                let translateMethod = translateOutputToActionMethod(propertyName: name, innerComposition: innerComposition)
                return [
                    ComponentOutput(
                        label: name,
                        parameters: outputParametersFromComposition(innerComposition),
                        composition: ComponentOutputComposition(
                            componentName: composition.composition.componentName,
                            passthroughAction: passthroughAction,
                            translateOutputMethod: translateMethod
                        )
                    )
                ]
            } else {
                return []
            }
            
        case .array, .dictionary, .named, .optional, .identifiableArray:
            return []
        }
    }
    
    static func updateTranslateCompositionMethodNames(
        _ translateCompositionMethodNames: inout [String: ComponentMethod],
        withCompositions compositions: [ComponentComposition]
    ) {
        for composition in compositions {
            updateTranslateCompositionMethodNames(
                &translateCompositionMethodNames,
                withComposition: composition
            )
        }
    }
    
    static func updateTranslateCompositionMethodNames(
        _ translateCompositionMethodNames: inout [String: ComponentMethod],
        withComposition composition: ComponentComposition
    ) {
        guard case let .property(name, innerComposition) = composition.composition, composition.passthroughOutput else {
            return
        }
        let method = translateOutputToActionMethod(propertyName: name, innerComposition: innerComposition)
        translateCompositionMethodNames[composition.composition.componentName] = method
    }
    
    static func translateOutputToActionMethod(propertyName name: String, innerComposition: Composition) -> ComponentMethod {
        ComponentMethod(
            name: "translate\(name.uppercaseFirstLetter())OutputToAction",
            parameters: outputParametersFromComposition(innerComposition),
            returnType: optionalType(of: identifierType("Action"))
        )
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

    static func outputParametersFromComposition(_ composition: Composition) -> [Parameter] {
        switch composition {
        case .property:
            // Shouldn't get property at this level
            return []
        case let .named(typeDecl):
            return [Parameter(label: nil, type: memberType("Output", of: typeDecl))]
        case let .array(elementComposition):
            return outputParametersFromComposition(elementComposition) + [
                Parameter(label: "index", type: identifierType("Int"))
            ]
        case let .identifiableArray(id: id, value: valueComposition):
            return outputParametersFromComposition(valueComposition) + [
                Parameter(label: "id", type: id)
            ]
        case let .dictionary(key: key, value: valueComposition):
            return outputParametersFromComposition(valueComposition) + [
                Parameter(label: "key", type: key)
            ]
        case let .optional(wrapped):
            return outputParametersFromComposition(wrapped)
        }
    }

    static func optionalType(of baseType: TypeSyntax) -> TypeSyntax {
        TypeSyntax(OptionalTypeSyntax(wrappedType: baseType))
    }
    
    static func identifierType(_ name: String) -> TypeSyntax {
        TypeSyntax(IdentifierTypeSyntax(name: TokenSyntax(stringLiteral: name)))
    }
    
    static func memberType(_ name: String, of baseType: TypeSyntax) -> TypeSyntax {
        TypeSyntax(MemberTypeSyntax(baseType: baseType, name: TokenSyntax(stringLiteral: name)))
    }

    static func computeCompositionAndActionsFromStateStruct(
        _ structDecl: StructDeclSyntax
    ) -> ([ComponentComposition], [Action], [ComponentOutput], [Subscription]) {
        guard structDecl.name.text == "State" else {
            return ([], [], [], [])
        }
        
        var compositions = [ComponentComposition]()
        var actions = [Action]()
        var outputs = [ComponentOutput]()
        var subscriptions = [Subscription]()
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            compositions.append(contentsOf: computeComposition(from: varDecl))
            let (varActions, varOutputs) = computeActions(from: varDecl)
            actions.append(contentsOf: varActions)
            outputs.append(contentsOf: varOutputs)
            subscriptions.append(contentsOf: computeSubscriptions(from: varDecl))
        }
        return (compositions, actions, outputs, subscriptions)
    }
    
    static func computeComposition(from varDecl: VariableDeclSyntax) -> [ComponentComposition] {
        var compositions = [ComponentComposition]()
        let shouldPassthroughOutput = varDecl.attributes.contains { attribute in
            guard case let .attribute(attr) = attribute,
                let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifierType.name.text == "PassthroughOutput" else {
                return false
            }
            return true
        }
        
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
            compositions.append(
                ComponentComposition(
                    composition: propertyComposition,
                    passthroughOutput: shouldPassthroughOutput
                )
            )
            
        }
        return compositions
    }

    static func computeActions(from varDecl: VariableDeclSyntax) -> ([Action], [ComponentOutput]) {
        let updatableAttribute = varDecl.attributes.compactMap { attribute -> AttributeSyntax? in
            guard case let .attribute(attr) = attribute,
                let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifierType.name.text == "Updatable" else {
                return nil
            }
            return attr
        }.first
        guard let updatableAttribute else {
            return ([], [])
        }
        
        var shouldOutputExpr: ExprSyntax?
        if let args = updatableAttribute.arguments?.as(LabeledExprListSyntax.self),
           let firstArg = args.first, firstArg.label?.text == "output" {
            shouldOutputExpr = firstArg.expression
        }

        var actions = [Action]()
        var outputs = [ComponentOutput]()
        for binding in varDecl.bindings {
            guard let typeDecl = binding.typeAnnotation?.type,
                  let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            
            let actionName = "update" + identifierPattern.identifier.text.uppercaseFirstLetter()
            let implementation = AutogeneratedImplementation.updateStateProperty(
                identifierPattern.identifier.text,
                shouldOutputExpr: shouldOutputExpr
            )
            let action = Action(
                label: actionName,
                parameters: [
                    Parameter(label: nil, type: typeDecl)
                ],
                composition: nil,
                implementation: implementation
            )
            actions.append(action)
            
            if shouldOutputExpr != nil {
                let outputName = "updated" + identifierPattern.identifier.text.uppercaseFirstLetter()
                let output = ComponentOutput(
                    label: outputName,
                    parameters: [
                        Parameter(label: nil, type: typeDecl)
                    ],
                    composition: nil
                )
                outputs.append(output)
            }
        }
        return (actions, outputs)
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
    
    static func parseSubscribeAttribute(from varDecl: VariableDeclSyntax) -> String? {
        let subscriptionAttribute = varDecl.attributes.compactMap { attribute -> AttributeSyntax? in
            guard case let .attribute(attr) = attribute,
                let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifierType.name.text == "Subscribe" else {
                return nil
            }
            return attr
        }.first
        guard let subscriptionAttribute,
              let args = subscriptionAttribute.arguments?.as(LabeledExprListSyntax.self),
              let effectType = args.first, effectType.label?.text == "to",
              args.count == 1 else {
            return nil
        }
        
        return ExtendSideEffectsMacro.parseSubscribeToMethodName(from: effectType.expression)
    }

    static func parseSubscribeToJSONStorageAttribute(from varDecl: VariableDeclSyntax) -> String? {
        let subscriptionAttribute = varDecl.attributes.compactMap { attribute -> AttributeSyntax? in
            guard case let .attribute(attr) = attribute,
                let identifierType = attr.attributeName.as(IdentifierTypeSyntax.self),
                  identifierType.name.text == "SubscribeToJSONStorage" else {
                return nil
            }
            return attr
        }.first
        
        guard let subscriptionAttribute,
              let args = subscriptionAttribute.arguments?.as(LabeledExprListSyntax.self),
              let effectType = args.first, effectType.label?.text == "for",
              args.count == 1 else {
            return nil
        }
        guard let typename = JSONStorageEffectsMacro.parseName(effectType.expression) else {
            return nil
        }
        return "subscribeToFetch\(typename)"
    }

    static func computeSubscriptions(from varDecl: VariableDeclSyntax) -> [Subscription] {
        if let subscribeToMethodName = parseSubscribeAttribute(from: varDecl) {
            return computeSubscriptions(
                from: varDecl,
                subscribeToMethodName: subscribeToMethodName
            )
        } else if let subscribeToMethodName = parseSubscribeToJSONStorageAttribute(from: varDecl) {
            return computeSubscriptions(
                from: varDecl,
                subscribeToMethodName: subscribeToMethodName
            )
        } else {
            return []
        }
    }
    
    static func computeSubscriptions(
        from varDecl: VariableDeclSyntax,
        subscribeToMethodName: String
    ) -> [Subscription] {
        var subscriptions = [Subscription]()
        for binding in varDecl.bindings {
            guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }
            
            let propertyName = identifierPattern.identifier.text
            let convertToActionExpr = ".\(propertyName)Update"
            let subscription = Subscription(
                propertyName: propertyName,
                subscribeMethodName: subscribeToMethodName,
                convertToActionExpr: convertToActionExpr
            )
            subscriptions.append(subscription)
        }
        return subscriptions
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
                && functionDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier == nil
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
        guard let attributed = parameter.type.as(AttributedTypeSyntax.self) else {
            return false
        }
        
        let specifiers = attributed.specifiers.compactMap { element -> SimpleTypeSpecifierSyntax? in
            if case let .simpleTypeSpecifier(specifier) = element {
                return specifier
            } else {
                return nil
            }
        }
            
        guard specifiers.contains(where: { $0.specifier.text == "inout" }) else {
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
