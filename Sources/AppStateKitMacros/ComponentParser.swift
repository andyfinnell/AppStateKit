import SwiftSyntax

struct ComponentParser {
    static func parse(_ decl: EnumDeclSyntax) -> Component {
        var actions = [Action]()
        var compositions = [Composition]()
        
        for member in decl.memberBlock.members {
            if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
               let action = computeActionFromFunction(funcDecl) {
                actions.append(action)
            } else if let structDecl = member.decl.as(StructDeclSyntax.self) {
                compositions.append(contentsOf: computeCompositionFromStateStruct(structDecl))
            }
        }
        
        let compositionActions = compositions.compactMap {
            actionFromComposition($0)
        }
        
        return Component(
            compositions: compositions,
            actions: actions + compositionActions
        )
    }
}

private extension ComponentParser {
    
    static func actionFromComposition(_ composition: Composition) -> Action? {
        // Should only have a property at this level
        switch composition {
        case let .property(name, innerComposition):
            return Action(
                label: name,
                parameters: parametersFromComposition(innerComposition),
                composition: composition)
            
        case .array, .dictionary, .named, .optional:
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

    static func computeCompositionFromStateStruct(_ structDecl: StructDeclSyntax) -> [Composition] {
        guard structDecl.name.text == "State" else {
            return []
        }
        
        var compositions = [Composition]()
        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            compositions.append(contentsOf: computeComposition(from: varDecl))
        }
        return compositions
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
    
    static func computeComposition(from typeDecl: TypeSyntax) -> Composition? {
        if let memberType = typeDecl.as(MemberTypeSyntax.self) {
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
            composition: nil
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
        // Expect: sideEffects: SideEffects<Action>
        guard parameter.firstName.text == "sideEffects" else {
            return false
        }
        
        guard let identifier = parameter.type.as(IdentifierTypeSyntax.self),
              identifier.name.text == "SideEffects" else {
            return false
        }

        guard let generics = identifier.genericArgumentClause,
              let firstArgument = generics.arguments.first,
              generics.arguments.count == 1 else {
            return false
        }
        
        guard let argumentIdentifier = firstArgument.argument.as(IdentifierTypeSyntax.self),
              argumentIdentifier.name.text == "Action" else {
            return false
        }
        
        return true
    }

}
