import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ComponentMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Parse out the parameters
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // TODO: emit error that it must be an enum (as namespace)
            return []
        }
                
        let component = ComponentParser.parse(enumDecl)
        let decls: [DeclSyntax?] = [
            ComponentActionCodegen.codegen(from: component),
            ComponentReducerCodegen.codegen(from: component),
            ComponentViewCodegen.codegen(from: component),
        ] + ComponentChildViewCodegen.codegen(from: component)
        
        return decls.compactMap { $0 }
    }
}

extension ComponentMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            // TODO: emit error that it must be an enum (as namespace)
            return []
        }

        let decl: DeclSyntax = """
            extension \(raw: enumDecl.name.text): Component {}
            """
        
        // TODO: can we extend things like ViewEngine to make Actions look like methods?
        
        return [
            decl.as(ExtensionDeclSyntax.self)
        ].compactMap { $0 }
    }
}

extension ComponentMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard ComponentParser.isViewMethod(member) else {
            return []
        }
        
        let attr: AttributeSyntax = """
            @MainActor
            """
        
        return [
            attr
        ]
    }
    
    
}
