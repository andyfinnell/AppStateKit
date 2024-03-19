
enum TypeKind {
    case array
    case dictionary
    case optional
    case property
}

struct Dereference {
    let segment: String
    let join: String
    let typeKind: TypeKind
}

struct DereferenceGenerator {
    let keyName: String
    let indexName: String
    let stateName: String
    
    func generate(for composition: Composition) -> [Dereference] {
        var dereferences = [Dereference]()
        var current: Composition? = composition
        while let c = current {
            switch c {
            case let .array(element):
                dereferences.append(Dereference(
                    segment: "[\(indexName)]",
                    join: "",
                    typeKind: .array
                ))
                current = element
            case let .dictionary(key: _, value: value):
                dereferences.append(Dereference(
                    segment: "[\(keyName)]",
                    join: "?",
                    typeKind: .dictionary
                ))
                current = value
            case let .property(name, value):
                dereferences.append(Dereference(
                    segment: "\(stateName).\(name)",
                    join: "",
                    typeKind: .property
                ))
                current = value
            case let .optional(wrapped):
                dereferences.append(Dereference(
                    segment: "",
                    join: "?",
                    typeKind: .optional
                ))
                current = wrapped
            case .named:
                current = nil // stop here
            }
        }
        return dereferences
    }

    func generateStateExtraction(for dereference: [Dereference]) -> (String, needsCopy: Bool) {
        var needsCopy = false
        var derefText = ""
        for (i, segment) in dereference.enumerated() {
            switch segment.typeKind {
            case .array, .property:
                break
            case .dictionary, .optional:
                needsCopy = true
            }

            derefText += segment.segment
            if i != (dereference.count - 1) {
                derefText += segment.join
            }
        }
        
        return (derefText, needsCopy: needsCopy)
    }

}
