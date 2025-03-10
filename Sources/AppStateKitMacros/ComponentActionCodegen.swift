import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentActionCodegen {
    static func codegen(from component: Component) -> [DeclSyntax] {
        let caseDecls = component.actions.map { action in
            generateActionCase(from: action)
        }.joined(separator: "\n")
        
        let actionDecl: DeclSyntax = """
            enum Action: Equatable {
                \(raw: caseDecls)
            }
            """
        let implementations = component.actions.map {
            generateActionImplementation(from: $0, inComponent: component)
        }
        
        let decls = [actionDecl] + implementations
        return decls.compactMap { $0 }
    }
}

private extension ComponentActionCodegen {
    static func generateActionImplementation(
        from action: Action,
        inComponent component: Component
    ) -> DeclSyntax? {
        guard let impl = action.implementation else {
            return nil
        }
        
        let parameters = generateImplementationParameters(from: action)
        let body = generateImplementationBody(
            from: action,
            implementation: impl,
            inComponent: component
        )
        let decl: DeclSyntax = """
            @MainActor
            private static func \(raw: action.label)(_ state: inout State, sideEffects: SideEffects\(raw: parameters)) {
                \(raw: body)
            }
            """
        
        return decl
    }
    
    static func generateImplementationBody(
        from action: Action,
        implementation: AutogeneratedImplementation,
        inComponent component: Component
    ) -> String {
        switch implementation {
        case let .updateStateProperty(propertyName, shouldOutputExpr: shouldOutputExpr):
            if let parameterName = implementationParameterName(from: action, at: 0) {
                let assign = "state.\(propertyName) = \(parameterName)"
                var outputCode = ""
                if let shouldOutputExpr {
                    outputCode = """
                        
                        if \(shouldOutputExpr) {
                            sideEffects.signal(.updated\(propertyName.uppercaseFirstLetter())(\(parameterName)))
                        }
                        """
                }
                return assign + outputCode
            } else {
                return "" // TODO: failure state
            }

        case let .batchUpdateStateProperty(propertyName, shouldOutputExpr: shouldOutputExpr):
            if let parameterName = implementationParameterName(from: action, at: 0) {
                let assign = """
                    for i in 0..<state.\(propertyName).count {
                        state.\(propertyName)[i] = \(parameterName)
                    }
                    """
                var outputCode = ""
                if let shouldOutputExpr {
                    outputCode = """
                        
                        if \(shouldOutputExpr) {
                            sideEffects.signal(.updated\(propertyName.uppercaseFirstLetter())(\(parameterName)))
                        }
                        """
                }
                return assign + outputCode
            } else {
                return "" // TODO: failure state
            }

        case let .passthroughOutput(outputName):
            let code = """
                sideEffects.signal(.\(outputName)\(implementationArgumentsInCall(from: action)))
                """
            return code
            
        case .componentInit:
            return component.subscriptions.map { subscriptionCode(for: $0) }
                .joined(separator: "\n")
        }
    }
    
    static func subscriptionCode(for subscription: Subscription) -> String {
        """
        if state.\(subscription.propertyName) == nil {
            state.\(subscription.propertyName) = sideEffects.\(subscription.subscribeMethodName) { stream, send in
                for await value in stream {
                    await send(\(subscription.convertToActionExpr)(value))
                }
            }
        }
        """
    }
    
    static func implementationArgumentsInCall(from action: Action) -> String {
        guard !action.parameters.isEmpty else {
            return ""
        }
        
        let arguments = action.parameters.enumerated().map { i, parameter in
            if let label = parameter.label {
                return "\(label): \(label)"
            } else {
                return "p\(i)"
            }
        }.joined(separator: ", ")
        return "(\(arguments))"
    }
    
    static func implementationParameterName(from action: Action, at index: Int) -> String? {
        guard index >= action.parameters.startIndex && index < action.parameters.endIndex else {
            return nil
        }
        let parameter = action.parameters[index]
        if let label = parameter.label {
            return label
        } else {
            return "p\(index)"
        }
    }
    
    static func generateImplementationParameters(from action: Action) -> String {
        guard !action.parameters.isEmpty else {
            return ""
        }
        
        var text = ", "
        text += action.parameters.enumerated().map {
            generateImplementationParameter(from: $1, index: $0)
        }.joined(separator: ", ")
        return text
    }
    
    static func generateImplementationParameter(from parameter: Parameter, index: Int) -> String {
        if let label = parameter.label {
            return "\(label): \(parameter.type)"
        } else {
            return "_ p\(index): \(parameter.type)"
        }
    }

    static func generateActionCase(from action: Action) -> String {
        var text = "case \(action.label)"
        if !action.parameters.isEmpty {
            text += "("
            text += action.parameters.map {
                generateActionParameter(from: $0)
            }.joined(separator: ", ")
            text += ")"
        }
        return text
    }
    
    static func generateActionParameter(from parameter: Parameter) -> String {
        var text = parameter.label.map { "\($0): " } ?? ""
        text += "\(parameter.type)"
        return text
    }

}
