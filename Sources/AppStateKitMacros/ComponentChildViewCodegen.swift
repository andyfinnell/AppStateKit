import SwiftSyntax
import SwiftSyntaxBuilder

struct ComponentChildViewCodegen {
    static func codegen(from component: Component) -> [DeclSyntax] {
        component.compositions.compactMap {
            codegen(from: $0.composition, translateCompositionMethodNames: component.translateCompositionMethodNames)
        } + component.compositions.compactMap {
            codegenForEach(from: $0.composition, translateCompositionMethodNames: component.translateCompositionMethodNames)
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
    
    static func generateOptionalIfLet(_ composition: Composition, content: (String?) -> String) -> (body: String, isOptional: Bool) {
        let dereferenceGenerator = DereferenceGenerator(
            keyName: "key",
            indexName: "index", 
            idName: "id",
            stateName: "engine.state"
        )
        let dereference = dereferenceGenerator.generate(for: composition)
        let (innerStateExtract, stateNeedsCopy) = dereferenceGenerator.generateStateExtraction(for: dereference)

        if stateNeedsCopy {
            let code = """
            if let innerState = \(innerStateExtract) {
            \(content("innerState"))
            }
            """
            return (body: code, isOptional: true)
        } else {
            return (body: content(nil), isOptional: false)
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

    static func generateOutputCompositionClosure(for translateMethod: ComponentMethod, extraction: Extraction) -> String {
        let compositionClosure: String
        if extraction.accessors.isEmpty {
            compositionClosure = translateMethod.name
        } else {
            let arguments = ["$0"] + extraction.accessors.map {
                switch $0 {
                case .index:
                    return "index"
                case .key:
                    return "key"
                case .id:
                    return "id"
                }
            }
            compositionClosure = "{ \(ComponentMethodCodegen.codegenCall(to: translateMethod, usingArguments: arguments)) }"
        }
        return compositionClosure
    }

    static func generateCallToChildView(
        composition: Composition,
        extraction: Extraction,
        fallbackState: String?,
        translateCompositionMethodNames: [String: ComponentMethod]
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
        if let translateMethod = translateCompositionMethodNames[componentName] {
            let translateClosure = generateOutputCompositionClosure(
                for: translateMethod,
                extraction: extraction
            )
            template = """
                \(extraction.componentType).EngineView(
                    engine: engine.map(
                        state: { \(innerStateExtract) },
                        action: \(actionClosure),
                        translate: \(translateClosure)
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
    
    static func codegen(from composition: Composition, translateCompositionMethodNames: [String: ComponentMethod]) -> DeclSyntax? {
        guard let extraction = extract(composition) else {
            return nil
        }
        let parameterList = generateParameterList(extraction)
                
        let (body, isOptional) = generateOptionalIfLet(composition) { fallbackState in
            generateCallToChildView(
                composition: composition,
                extraction: extraction,
                fallbackState: fallbackState, 
                translateCompositionMethodNames: translateCompositionMethodNames
            )
        }
        let returnType = isOptional ? "\(extraction.componentType).EngineView?" : "\(extraction.componentType).EngineView"
        let viewDecl = """
            @MainActor
            @ViewBuilder
            private static func \(extraction.name)(_ engine: ViewEngine<State, Action, Output>\(parameterList)) -> \(returnType) {
            \(body)
            }
            """
        
        return DeclSyntax(stringLiteral: viewDecl)
    }

    static func generateArgumentList(_ extraction: Extraction) -> String {
        let arguments = ["engine"]
        + extraction.accessors.map { accessor in
            switch accessor {
            case .index:
                "at: index"
            case .key:
                "forKey: key"
            case .id:
                "byID: id"
            }
        }
        return arguments.joined(separator: ", ")
    }

    static func generateElementFunctionCall(_ extraction: Extraction, inComposition composition: Composition) -> String {
        let dereferenceGenerator = DereferenceGenerator(
            keyName: "key",
            indexName: "index",
            idName: "id",
            stateName: "engine.state"
        )
        let dereference = dereferenceGenerator.generate(for: composition)
        let isOptional = dereference.contains(where: {
            $0.typeKind == .optional || $0.typeKind == .dictionary || $0.typeKind == .identifiableArray
        })
        let baseCall = "\(extraction.name)(\(generateArgumentList(extraction)))"

        if isOptional {
            let code = """
            \(baseCall).map { content($0) }
            """
            return code
        } else {
            let code = """
            content(\(baseCall))
            """
            return code
        }
    }
    
    static func generateForEach(
        for accessor: Accessor,
        inCollection collectionName: String,
        body: String
    ) -> String {
        switch accessor {
        case .key:
            """
            ForEach(\(collectionName).keys.sorted(), id: \\.self) { key in
                \(body)
            }
            """
        case .index:
            """
            ForEach(\(collectionName).indices, id: \\.self) { index in
                \(body)
            }
            """
        case .id:
            """
            ForEach(\(collectionName).map { $0.id }, id: \\.self) { id in
                \(body)
            }
            """
        }
    }

    static func generateForEachCollectionName(
        for accessor: Accessor,
        startingWith collectionName: String
    ) -> String {
        switch accessor {
        case .key:
            "\(collectionName)[key]"
        case .index:
            "\(collectionName)[index]"
        case .id:
            "\(collectionName)[byID: id]"
        }
    }

    static func generateForEachCollectionNames(
        for accessors: [Accessor],
        startingWith collectionName: String
    ) -> [String] {
        var collectionNames = [collectionName]
        var current = collectionName
        for accessor in accessors {
            let name = generateForEachCollectionName(for: accessor, startingWith: current)
            collectionNames.append(name)
            current = name
        }
        return collectionNames
    }
    
    static func codegenForEach(from composition: Composition, translateCompositionMethodNames: [String: ComponentMethod]) -> DeclSyntax? {
        guard let extraction = extract(composition), !extraction.accessors.isEmpty else {
            return nil
        }
        
        var body = generateElementFunctionCall(extraction, inComposition: composition)
        let collectionNames = generateForEachCollectionNames(
            for: extraction.accessors,
            startingWith: "engine.\(extraction.name)"
        )
        for (collectionName, accessor) in zip(collectionNames, extraction.accessors.reversed()) {
            body = generateForEach(
                for: accessor,
                inCollection: collectionName,
                body: body
            )
        }
        
        let viewDecl = """
            @MainActor
            @ViewBuilder
            private static func forEach\(extraction.name.uppercaseFirstLetter())(
                _ engine: ViewEngine<State, Action, Output>,
                @ViewBuilder content: @escaping (\(extraction.componentType).EngineView) -> some View = { $0 }
            ) -> some View {
                \(body)
            }
            """
        
        return DeclSyntax(stringLiteral: viewDecl)
    }

    static func codegen(from detachment: DetachmentRef) -> DeclSyntax? {
        let viewDecl: DeclSyntax = """
            @MainActor
            @ViewBuilder
            private static func \(raw: detachment.methodName)(
                _ engine: ViewEngine<State, Action, Output>,
                inject: @escaping (DependencyScope) -> Void = { _ in }
            ) -> some View {
                \(raw: detachment.typename).view(engine, inject: inject)
            }
            """
        
        return viewDecl
    }

    static func componentName(from composition: Composition) -> String {
        composition.componentName
    }
}
