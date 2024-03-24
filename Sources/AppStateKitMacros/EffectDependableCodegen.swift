import SwiftSyntax
import SwiftSyntaxBuilder

struct EffectDependableCodegen {
    static func codegen(from effect: Effect) -> DeclSyntax? {
        let effectTypename = generateEffectTypename(from: effect)
        let closureParameters = generateClosureParameters(from: effect)
        let contents = generateDoCatchIfNecessary(from: effect)
        let decl: DeclSyntax = """
            extension \(raw: effect.typename): Dependable {
                static func makeDefault(with dependencies: DependencyScope) -> \(raw: effectTypename) {
                    Effect { \(raw: closureParameters)
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
        var typename = "Effect<"
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
            typename += effect.parameters.map { "\($0.type)" }
                .joined(separator: ", ")
        }
        typename += ">"
        return typename
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
                                return Result.failure(error)
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
        var callCode = ""
        if effect.isThrowing {
            callCode = "try "
        }
        if effect.isAsync {
            callCode = "await "
        }
        callCode += "Result.success(perform(dependencies: dependencies"
        callCode += generateCallArguments(from: effect)
        callCode += "))"
        return callCode
    }
}
