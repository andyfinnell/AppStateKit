import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentChildViewCodegen {
    static func codegen(from component: Component) -> [DeclSyntax] {
        component.compositions.compactMap {
            codegen(from: $0, translateCompositionMethodNames: component.translateCompositionMethodNames)
        } + component.detachments.compactMap {
            codegen(from: $0)
        }
    }
}

private extension ComponentChildViewCodegen {
    enum Accessor {
        case key(TypeSyntax)
        case index
        case id(TypeSyntax)
    }
    
    struct Extraction {
        let name: String
        let accessors: [Accessor]
        let componentType: TypeSyntax
    }
    
    static func extract(_ composition: Composition) -> Extraction? {
        var name: String?
        var accessors = [Accessor]()
        var componentType: TypeSyntax?
        
        var current: Composition? = composition
        while let c = current {
            switch c {
            case let .array(element):
                accessors.insert(.index, at: 0)
                current = element
            case let .dictionary(key: keyType, value: value):
                accessors.insert(.key(keyType), at: 0)
                current = value
            case let .identifiableArray(id: idType, value: value):
                accessors.insert(.id(idType), at: 0)
                current = value
            case let .property(propertyName, value):
                name = propertyName
                current = value
            case let .optional(wrapped):
                current = wrapped
            case let .named(type):
                componentType = type
                current = nil // stop here
            }
        }

        guard let name, let componentType else {
            return nil
        }
        
        return Extraction(name: name, accessors: accessors, componentType: componentType)
    }
    
    static func generateParameterList(_ extraction: Extraction) -> String {
        var parameters = [String]()
        for accessor in extraction.accessors {
            switch accessor {
            case .index:
                parameters.append("at index: Int")
            case let .key(keyType):
                parameters.append("forKey key: \(keyType)")
            case let .id(idType):
                parameters.append("byID id: \(idType)")
            }
        }
        guard !parameters.isEmpty else {
            return ""
        }
        return ", " + parameters.joined(separator: ", ")
    }
    
    static func generateOptionalIfLet(_ composition: Composition, content: (String?) -> String) -> String {
        let dereferenceGenerator = DereferenceGenerator(
            keyName: "key",
            indexName: "index", 
            idName: "id",
            stateName: "engine.state"
        )
        let dereference = dereferenceGenerator.generate(for: composition)
        let (innerStateExtract, stateNeedsCopy) = dereferenceGenerator.generateStateExtraction(for: dereference)

        if stateNeedsCopy {
            return """
            if let innerState = \(innerStateExtract) {
            \(content("innerState"))
            }
            """
        } else {
            return content(nil)
        }
    }
    
    static func generateActionCompositionClosure(extraction: Extraction) -> String {
        let compositionClosure: String
        if extraction.accessors.isEmpty {
            compositionClosure = "Action.\(extraction.name)"
        } else {
            let tupleValues = (["$0"] + extraction.accessors.map {
                switch $0 {
                case .index:
                    return "index: index"
                case .key:
                    return "key: key"
                case .id:
                    return "id: id"
                }
            }).joined(separator: ", ")
            compositionClosure = "{ Action.\(extraction.name)(\(tupleValues)) }"
        }
        return compositionClosure
    }

    static func generateCallToChildView(
        composition: Composition,
        extraction: Extraction,
        fallbackState: String?,
        translateCompositionMethodNames: [String: String]
    ) -> String {
        let dereferenceGenerator = DereferenceGenerator(
            keyName: "key",
            indexName: "index",
            idName: "id",
            stateName: "$0"
        )
        let dereference = dereferenceGenerator.generate(for: composition)
        var (innerStateExtract, _) = dereferenceGenerator.generateStateExtraction(for: dereference)
        if let fallbackState {
            innerStateExtract += " ?? \(fallbackState)"
        }
        
        let actionClosure = generateActionCompositionClosure(
            extraction: extraction
        )
        let componentName = componentName(from: composition)
        let template: String
        if let translateMethodName = translateCompositionMethodNames[componentName] {
            template = """
                \(extraction.componentType).EngineView(
                    engine: engine.map(
                        state: { \(innerStateExtract) },
                        action: \(actionClosure),
                        translate: \(translateMethodName)
                    ).view()
                )
            """
        } else {
            template = """
                \(extraction.componentType).EngineView(
                    engine: engine.map(
                        state: { \(innerStateExtract) },
                        action: \(actionClosure)
                    ).view()
                )
            """
        }
        return template
    }
    
    static func codegen(from composition: Composition, translateCompositionMethodNames: [String: String]) -> DeclSyntax? {
        guard let extraction = extract(composition) else {
            return nil
        }
        let parameterList = generateParameterList(extraction)
                
        let body = generateOptionalIfLet(composition) { fallbackState in
            generateCallToChildView(
                composition: composition,
                extraction: extraction,
                fallbackState: fallbackState, 
                translateCompositionMethodNames: translateCompositionMethodNames
            )
        }
        
        let viewDecl = """
            @ViewBuilder
            private static func \(extraction.name)(_ engine: ViewEngine<State, Action, Output>\(parameterList)) -> some View {
            \(body)
            }
            """
        
        return DeclSyntax(stringLiteral: viewDecl)
    }
    
    static func codegen(from detachment: DetachmentRef) -> DeclSyntax? {
        let viewDecl: DeclSyntax = """
            @ViewBuilder
            private static func \(raw: detachment.methodName)(
                _ engine: ViewEngine<State, Action, Output>,
                inject: (DependencyScope) -> Void = { _ in }
            ) -> some View {
                \(raw: detachment.typename).view(engine, inject: inject)
            }
            """
        
        return viewDecl
    }

    static func componentName(from composition: Composition) -> String {
        switch composition {
        case let .property(_, value):
            return componentName(from: value)
        case let .optional(value):
            return componentName(from: value)
        case let .array(value):
            return componentName(from: value)
        case let .identifiableArray(id: _, value: value):
            return componentName(from: value)
        case let .dictionary(key: _, value: value):
            return componentName(from: value)
        case let .named(namedType):
            return namedType.description
        }
    }
}
