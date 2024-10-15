import SwiftSyntax

enum ComponentMethodCodegen {
    static func codegenCall(to method: ComponentMethod, usingArguments arguments: [String]) -> String {
        let labelsAndArguments = zip(method.parameters, arguments).map { parameter, argument in
            if let label = parameter.label {
                "\(label): \(argument)"
            } else {
                argument
            }
        }.joined(separator: ", ")
        return "\(method.name)(\(labelsAndArguments))"
    }
    
    static func codegenSignature(for method: ComponentMethod) -> (signature: String, parameterNames: [String]) {
        let parameters = method.parameters.enumerated().map { i, p -> (label: String?, name: String, type: TypeSyntax) in
            if let label = p.label {
                (label: nil, name: label, type: p.type)
            } else {
                (label: "_", name: "p\(i)", type: p.type)
            }
        }
        
        let parametersString = parameters.map { parameter in
            if let label = parameter.label {
                "\(label) \(parameter.name): \(parameter.type)"
            } else {
                "\(parameter.name): \(parameter.type)"
            }
        }.joined(separator: ", ")
        
        let returnTypeString = method.returnType.map { " -> \($0)" } ?? ""
        let signature = "func \(method.name)(\(parametersString))\(returnTypeString)"
        
        let namesOnly = parameters.map { $0.name }
        
        return (signature: signature, parameterNames: namesOnly)
    }
}
