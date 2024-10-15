import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentOutputCodegen {
    static func codegen(from component: Component) -> [DeclSyntax] {
        var decls = [DeclSyntax?]()
        
        if !component.hasDefinedOutput {
            if component.outputs.isEmpty {
                let outputDecl: DeclSyntax = """
                typealias Output = Never
                """
                decls.append(outputDecl)
            } else {
                let caseDecls = component.outputs.map { output in
                    generateOutputCase(from: output)
                }.joined(separator: "\n")
                
                let outputDecl: DeclSyntax = """
                enum Output: Equatable {
                    \(raw: caseDecls)
                }
                """
                decls.append(outputDecl)
            }
        }
        
        let funcDecls = component.outputs.compactMap { output -> DeclSyntax? in
            guard let composition = output.composition else {
                return nil
            }
            return generateTranslateMethod(for: output, usingComposition: composition)
        }

        decls.append(contentsOf: funcDecls)
        
        return decls.compactMap { $0 }
    }
}

private extension ComponentOutputCodegen {
    static func generateOutputCase(from output: ComponentOutput) -> String {
        var text = "case \(output.label)"
        if !output.parameters.isEmpty {
            text += "("
            text += output.parameters.map {
                generateOutputParameter(from: $0)
            }.joined(separator: ", ")
            text += ")"
        }
        return text
    }
    
    static func generateOutputParameter(from parameter: Parameter) -> String {
        var text = parameter.label.map { "\($0): " } ?? ""
        text += "\(parameter.type)"
        return text
    }
    
    static func generateTranslateMethod(for output: ComponentOutput, usingComposition composition: ComponentOutputComposition) -> DeclSyntax? {
        let (signature, parameterNames) = ComponentMethodCodegen.codegenSignature(for: composition.translateOutputMethod)
        let funcDecl: DeclSyntax = """
            private static \(raw: signature) {
                .\(raw: composition.passthroughAction.label)\(raw: generateActionArguments(for: composition.passthroughAction, usingArguments: parameterNames))
            }
            """
        return funcDecl
    }
    
    static func generateActionArguments(for action: Action, usingArguments arguments: [String]) -> String {
        guard !action.parameters.isEmpty else {
            return ""
        }
        
        let arguments = zip(action.parameters, arguments).map { parameter, argument in
            if let label = parameter.label {
                return "\(label): \(argument)"
            } else {
                return argument
            }
        }.joined(separator: ", ")
        return "(\(arguments))"
    }
}
