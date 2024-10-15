import SwiftSyntax

indirect enum Composition {
    case property(String, Composition)
    case optional(Composition)
    case array(Composition)
    case identifiableArray(id: TypeSyntax, value: Composition)
    case dictionary(key: TypeSyntax, value: Composition)
    case named(TypeSyntax)
}

extension Composition {
    var componentName: String {
        switch self {
        case let .property(_, value):
            return value.componentName
        case let .optional(value):
            return value.componentName
        case let .array(value):
            return value.componentName
        case let .identifiableArray(id: _, value: value):
            return value.componentName
        case let .dictionary(key: _, value: value):
            return value.componentName
        case let .named(namedType):
            return namedType.description
        }
    }
}

struct ComponentComposition {
    let composition: Composition
    let passthroughOutput: Bool
}

struct Parameter {
    let label: String?
    let type: TypeSyntax
}

enum AutogeneratedImplementation {
    case updateStateProperty(String, shouldOutputExpr: ExprSyntax?)
    case passthroughOutput(String)
}

struct Action {
    let label: String
    let parameters: [Parameter]
    let composition: Composition?
    let implementation: AutogeneratedImplementation?
}

struct DetachmentRef {
    let typename: String
    let methodName: String
}

struct ComponentOutputComposition {
    let componentName: String
    let passthroughAction: Action
    let translateOutputMethod: ComponentMethod
}

struct ComponentOutput {
    let label: String
    let parameters: [Parameter]
    let composition: ComponentOutputComposition?
}

struct ComponentMethod {
    let name: String
    let parameters: [Parameter]
    let returnType: TypeSyntax?
}

struct Component {
    let name: String
    let compositions: [ComponentComposition]
    let actions: [Action]
    let detachments: [DetachmentRef]
    let hasDefinedOutput: Bool
    let isOutputNever: Bool
    let translateCompositionMethodNames: [String: ComponentMethod]
    let outputs: [ComponentOutput]
}
