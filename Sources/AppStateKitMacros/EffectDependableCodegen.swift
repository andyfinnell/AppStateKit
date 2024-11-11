import SwiftSyntax
import SwiftSyntaxBuilder

struct EffectDependableCodegen {
    static func codegen(from effect: Effect) -> DeclSyntax? {
        let effectTypename = generateEffectTypename(from: effect)
        let closureParameters = generateClosureParameters(from: effect)
        let contents = generateDoCatchIfNecessary(from: effect)
        let effectType = effect.isImmediate ? "ImmediateEffect" : "Effect"
        let decl: DeclSyntax = """
            extension \(raw: effect.typename): Dependable {
                static func makeDefault(with dependencies: DependencyScope) -> \(raw: effectTypename) {
                    \(raw: effectType) { \(raw: closureParameters)
                        \(raw: contents)
                    }
                }
            }
            """
        return decl
    }
}

private extension EffectDependableCodegen {
    static func generateEffectTypename(from effect: Effect) -> String {
        var typename = effect.isImmediate ? "ImmediateEffect<" : "Effect<"
        if let returnType = effect.returnType {
            typename += "\(returnType), "
        } else {
            typename += "Void, "
        }
        if effect.isThrowing {
            typename += "Error"
        } else {
            typename += "Never"
        }
        if !effect.parameters.isEmpty {
            typename += ", "
            typename += effect.parameters.map { "\(stripTypeAttributes(from: $0.type))" }
                .joined(separator: ", ")
        }
        typename += ">"
        return typename
    }
    
    static func stripTypeAttributes(from type: TypeSyntax) -> TypeSyntax {
        guard let attributedType = type.as(AttributedTypeSyntax.self) else {
            return type
        }
        
        let remainingAttributes = attributedType.attributes.filter {
            if case let .attribute(attribute) = $0,
               let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
                return identifier.name.text == "Sendable"
            } else {
                return false
            }
        }
        
        let remainingAttributeList: AttributeListSyntax = remainingAttributes
        let specifiers: TypeSpecifierListSyntax = []
         
        let newAttributedType = AttributedTypeSyntax(
            leadingTrivia: attributedType.leadingTrivia,
            attributedType.unexpectedBeforeSpecifiers,
            specifiers: specifiers,
            attributedType.unexpectedBetweenSpecifiersAndAttributes,
            attributes: remainingAttributeList,
            attributedType.unexpectedBetweenAttributesAndBaseType,
            baseType: attributedType.baseType,
            attributedType.unexpectedAfterBaseType,
            trailingTrivia: attributedType.trailingTrivia
        )
        
        return TypeSyntax(newAttributedType)
    }
    
    static func generateClosureParameters(from effect: Effect) -> String {
        guard !effect.parameters.isEmpty else {
            return ""
        }
        return effect.parameters.map { $0.name }.joined(separator: ", ") + " in"
    }
    
    static func generateDoCatchIfNecessary(from effect: Effect) -> String {
        if effect.isThrowing {
            let template = """
                do {
                                \(generateCallToPerform(from: effect))
                } catch {
                                return Result<\(returnTypename(from: effect)), \(errorTypename(from: effect))>.failure(error)
                }
                """
            return template
        } else {
            return generateCallToPerform(from: effect)
        }
    }
    
    static func generateCallArguments(from effect: Effect) -> String {
        guard !effect.parameters.isEmpty else {
            return ""
        }
        return ", " + effect.parameters.map { parameter in
            if let label = parameter.label {
                return "\(label): \(parameter.name)"
            } else {
                return parameter.name
            }
        }.joined(separator: ", ")
    }

    static func generateCallToPerform(from effect: Effect) -> String {
        var callCode = "return "
        if effect.isThrowing {
            callCode += "try "
        }
        if effect.isAsync {
            callCode += "await "
        }
        callCode += "Result<\(returnTypename(from: effect)), \(errorTypename(from: effect))>.success(perform(dependencies: dependencies"
        callCode += generateCallArguments(from: effect)
        callCode += "))"
        return callCode
    }
    
    static func returnTypename(from effect: Effect) -> String {
        effect.returnType.map { String(describing: $0) } ?? "Void"
    }
    
    static func errorTypename(from effect: Effect) -> String {
        effect.isThrowing ? "Error" : "Never"
    }
}
