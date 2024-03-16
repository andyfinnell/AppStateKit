import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum BindableActionMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Parse out the parameters
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return []
        }
        
        let enumName = enumDecl.name.trimmed.text
        
        let childCases = enumDecl.caseElements.compactMap { caseElement -> (label: String, associatedTypes: EnumCaseParameterListSyntax?)? in
            guard let associatedTypes = caseElement.parameterClause?.parameters else {
                return nil
            }
            let label = caseElement.name.text
            return (label: label, associatedTypes: associatedTypes)
        }
        
        let actionBindings = childCases
            .map { label, associatedTypes in
                if let associatedTypes, associatedTypes.count > 1 {
                    let valueNames = (0..<associatedTypes.count)
                        .map { "v\($0)" }
                        .joined(separator: ", ")
                    
                    let codeString = """
                        static let \(label) = ActionBinding(
                            from: \(enumName).\(label),
                            to: {
                               if case let .\(label)(\(valueNames)) = $0 {
                                   return (\(valueNames))
                               } else {
                                   return nil
                               }
                            })
                        """
                    return codeString
                } else if let associatedTypes, associatedTypes.count == 1 {
                    let codeString = """
                        static let \(label) = ActionBinding(
                            from: \(enumName).\(label),
                            to: {
                               if case let .\(label)(v) = $0 {
                                   return v
                               } else {
                                   return nil
                               }
                            })
                        """
                    return codeString
                } else {
                    let codeString = """
                        static let \(label) = ActionBinding(
                            from: \(enumName).\(label),
                            to: {
                               if case .\(label) = self {
                                   return ()
                               } else {
                                   return nil
                               }
                            })
                        """
                    return codeString
                }
                
            }.map {
                DeclSyntax(stringLiteral: $0)
            }
        return actionBindings
    }
}

extension EnumDeclSyntax {
    var caseElements: [EnumCaseElementSyntax] {
        memberBlock.members.flatMap { member in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
                return Array<EnumCaseElementSyntax>()
            }
            
            return Array(caseDecl.elements)
        }
    }
}
