import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentReducerCodegen {
    static func codegen(from component: Component) -> DeclSyntax? {
        let cases = component.actions.map {
            generateReduceAction(
                from: $0,
                translateCompositionMethodNames: component.translateCompositionMethodNames
            )
        }.joined(separator: "\n")
        
        let reduceDecl = """
            @MainActor
            static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
                switch action {
                \(cases)
                }
            }
            """
        
        return DeclSyntax(stringLiteral: reduceDecl)
    }
}

private extension ComponentReducerCodegen {
    static func generateReduceAction(from action: Action, translateCompositionMethodNames: [String: String]) -> String {
        if let composition = action.composition {
            return generateReduceComposedAction(
                from: action,
                with: composition,
                translateCompositionMethodNames: translateCompositionMethodNames
            )
        } else {
            return generateReduceLocalAction(from: action)
        }
    }

    enum Accessor {
        case action
        case index
        case key
        case id
    }
    
    static func actionExtractionParameters(_ composition: Composition) -> [Accessor] {
        var current: Composition? = composition
        var accessors = [Accessor]()
        while let c = current {
            switch c {
            case let .array(element):
                accessors.insert(.index, at: 0)
                current = element
            case let .dictionary(key: _, value: value):
                accessors.insert(.key, at: 0)
                current = value
            case let .identifiableArray(id: _, value: value):
                accessors.insert(.id, at: 0)
                current = value
            case let .property(_, value):
                current = value
            case let .optional(wrapped):
                current = wrapped
            case .named:
                accessors.insert(.action, at: 0)
                current = nil // stop here
            }
        }
        return accessors
    }
        
    static func generateBoundsCheck(for dereference: [Dereference]) -> [String] {
        var hasArray = false
        var derefText = ""
        for (i, segment) in dereference.enumerated() {
            if segment.typeKind == .array {
                hasArray = true
                break
            }

            derefText += segment.segment
            if i != (dereference.count - 1) {
                derefText += segment.join
            }
        }
        
        guard hasArray else {
            return []
        }
        
        return [
            "innerIndex >= \(derefText).startIndex",
            "innerIndex < \(derefText).endIndex",
        ]
    }
        
    static func generateActionCompositionClosure(for action: Action, accessors: [Accessor]) -> String {
        let compositionClosure: String
        if accessors.count == 1 {
            compositionClosure = "Action.\(action.label)"
        } else {
            let tupleValues = accessors.map {
                switch $0 {
                case .action:
                    return "$0"
                case .index:
                    return "index: innerIndex"
                case .key:
                    return "key: innerKey"
                case .id:
                    return "id: innerID"
                }
            }.joined(separator: ", ")
            compositionClosure = "{\n        Action.\(action.label)(\(tupleValues))\n    }\n"
        }
        return compositionClosure
    }

    static func childModuleName(_ composition: Composition) -> String {
        switch composition {
        case let .array(element):
            return childModuleName(element)
        case let .dictionary(key: _, value: value):
            return childModuleName(value)
        case let .identifiableArray(id: _, value: value):
            return childModuleName(value)
        case let .property(_, value):
            return childModuleName(value)
        case let .optional(wrapped):
            return childModuleName(wrapped)
        case let .named(typeDecl):
            return typeDecl.description
        }
    }

    static func generateCaseClauseParameters(parameters: [Parameter], accessors: [Accessor]) -> String {
        zip(parameters, accessors).map { parameter, accessor in
            let valueName: String
            switch accessor {
            case .action:
                valueName = "innerAction"
            case .index:
                valueName = "innerIndex"
            case .key:
                valueName = "innerKey"
            case .id:
                valueName = "innerID"
            }
            if let label = parameter.label {
                return "\(label): \(valueName)"
            } else {
                return valueName
            }
        }.joined(separator: ", ")
    }
    
    static func generateReduceComposedAction(
        from action: Action,
        with composition: Composition,
        translateCompositionMethodNames: [String: String]
    ) -> String {
        let accessors = actionExtractionParameters(composition)
        let caseParameters = generateCaseClauseParameters(parameters: action.parameters, accessors: accessors)
        let dereferenceGenerator = DereferenceGenerator(
            keyName: "innerKey",
            indexName: "innerIndex",
            idName: "innerID",
            stateName: "state"
        )
        let dereference = dereferenceGenerator.generate(for: composition)
        let arrayBoundsCheck = generateBoundsCheck(for: dereference)
        let (innerStateExtract, stateNeedsCopy) = dereferenceGenerator.generateStateExtraction(for: dereference)
        let innerStateLet = stateNeedsCopy ? "var innerState = \(innerStateExtract)" : nil
        let guardClauses = (
            arrayBoundsCheck
            + (innerStateLet.map { [$0] } ?? [])
        ).joined(separator: ", ")
        let guardStatement = guardClauses.isEmpty ? "" : "guard \(guardClauses) else {\n        return\n    }"
        
        let actionComposition = generateActionCompositionClosure(for: action, accessors: accessors)
        let innerStateDeref = stateNeedsCopy ? "innerState" : innerStateExtract
        let copyStateBack = stateNeedsCopy ? "\(innerStateExtract) = innerState\n" : ""
        let childModule = childModuleName(composition)
        let translateMethod: String
        
        if let methodName = translateCompositionMethodNames[childModule] {
            translateMethod = methodName
        } else {
            translateMethod = "{ (_: \(childModule).Output) in nil }"
        }
        
        let definition = """
            case let .\(action.label)(\(caseParameters)):
                \(guardStatement)
                let innerSideEffects = sideEffects.map(\(actionComposition), translate: \(translateMethod))
                \(childModule).reduce(
                    &\(innerStateDeref),
                    action: innerAction,
                    sideEffects: innerSideEffects
                )
                \(copyStateBack)
            """
        
        return definition
    }
    
    static func generateReduceLocalAction(from action: Action) -> String {
        let parameters = action.parameters.enumerated().map { i, parameter in
            if let label = parameter.label {
                return "\(label): \(label)"
            } else {
                return "p\(i)"
            }
        }.joined(separator: ", ")

        var text: String
        if action.parameters.isEmpty {
            text = "case .\(action.label):\n"
        } else {
            text = "case let .\(action.label)(\(parameters)):\n"
        }
        let arguments: String
        if action.parameters.isEmpty {
            arguments = ""
        } else {
            arguments = ", \(parameters)"
        }
        text += "\(action.label)(&state, sideEffects: sideEffects\(arguments))\n"
        return text
    }

}
