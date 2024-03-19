import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentActionCodegen {
    static func codegen(from component: Component) -> DeclSyntax? {
        let caseDecls = component.actions.map { action in
            generateActionCase(from: action)
        }.joined(separator: "\n")
        
        let actionDecl = """
            enum Action: Equatable {
                \(caseDecls)
            }
            """
        return DeclSyntax(stringLiteral: actionDecl)
    }
}

private extension ComponentActionCodegen {
    
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
