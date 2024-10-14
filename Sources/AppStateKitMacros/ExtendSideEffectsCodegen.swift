import SwiftSyntax
import SwiftSyntaxBuilder

enum ExtendSideEffectsCodegen {
    static func codegenMethod(from effect: SideEffect) -> DeclSyntax? {
        let parameters = codegenParameters(from: effect)
        let body = codegenBody(from: effect)
        let decl: DeclSyntax = """
            func \(raw: effect.methodName)(
                \(raw: parameters)
            ) {
                \(raw: body)
            }
            """
        
        return decl
    }

    static func codegenSubscribeMethod(from effect: SideEffect) -> DeclSyntax? {
        let parameters = codegenSubscribeParameters(from: effect)
        let body = codegenSubscribeBody(from: effect)
        let decl: DeclSyntax = """
            func \(raw: effect.subscribeName)(
                \(raw: parameters)
            ) -> SubscriptionID {
                \(raw: body)
            }
            """
        
        return decl
    }
}

private extension ExtendSideEffectsCodegen {
    
    static func codegenParameters(from effect: SideEffect) -> String {
        var parameters = effect.parameters.enumerated().map { i, parameter in
            if let label = parameter.label {
                return "\(label) p\(i): \(parameter.type)"
            } else {
                return "_ p\(i): \(parameter.type)"
            }
        }
        
        if effect.returnType == "Void" {
            parameters.append("transform: @Sendable @escaping () async -> Action")
        } else {
            parameters.append("transform: @Sendable @escaping (\(effect.returnType)) async -> Action")
        }
        if effect.isThrowing {
            parameters.append("onFailure: @Sendable @escaping (Error) async -> Action")
        }
        return parameters.joined(separator: ",\n")
    }
    
    static func codegenBody(from effect: SideEffect) -> String {
        let arguments = (0..<effect.parameters.count).map { "p\($0)" }
            .joined(separator: ", ")
        if arguments.isEmpty {
            if effect.isThrowing {
                return "tryPerform(\(codegenEffectReference(effect.effectReference)), transform: transform, onFailure: onFailure)"
            } else {
                return "perform(\(codegenEffectReference(effect.effectReference)), transform: transform)"
            }
        } else {
            if effect.isThrowing {
                return "tryPerform(\(codegenEffectReference(effect.effectReference)), with: \(arguments), transform: transform, onFailure: onFailure)"
            } else {
                return "perform(\(codegenEffectReference(effect.effectReference)), with: \(arguments), transform: transform)"
            }
        }
    }
    
    static func codegenEffectReference(_ effectReference: SideEffectReference) -> String {
        switch effectReference {
        case let .keyPath(keyPath):
            return "\\.\(keyPath)"
        case let .typename(typename):
            return "\(typename).self"
        }
    }
    
    static func codegenSubscribeParameters(from effect: SideEffect) -> String {
        var parameters = effect.parameters.enumerated().map { i, parameter in
            if let label = parameter.label {
                return "\(label) p\(i): \(parameter.type)"
            } else {
                return "_ p\(i): \(parameter.type)"
            }
        }
        
        parameters.append("transform: @Sendable @escaping (\(effect.returnType), (Action) async -> Void) async throws -> Void")
        if effect.isThrowing {
            parameters.append("onFailure: @Sendable @escaping (Error) async -> Action")
        }
        return parameters.joined(separator: ",\n")
    }

    static func codegenSubscribeBody(from effect: SideEffect) -> String {
        let arguments = (0..<effect.parameters.count).map { "p\($0)" }
            .joined(separator: ", ")
        if arguments.isEmpty {
            if effect.isThrowing {
                return "trySubscribe(\(codegenEffectReference(effect.effectReference)), transform: transform, onFailure: onFailure)"
            } else {
                return "subscribe(\(codegenEffectReference(effect.effectReference)), transform: transform)"
            }
        } else {
            if effect.isThrowing {
                return "trySubscribe(\(codegenEffectReference(effect.effectReference)), with: \(arguments), transform: transform, onFailure: onFailure)"
            } else {
                return "subscribe(\(codegenEffectReference(effect.effectReference)), with: \(arguments), transform: transform)"
            }
        }
    }

}
