import SwiftSyntax

indirect enum Composition {
    case property(String, Composition)
    case optional(Composition)
    case array(Composition)
    case identifiableArray(id: TypeSyntax, value: Composition)
    case dictionary(key: TypeSyntax, value: Composition)
    case named(TypeSyntax)
}

struct Parameter {
    let label: String?
    let type: TypeSyntax
}

struct Action {
    let label: String
    let parameters: [Parameter]
    let composition: Composition?
}

struct DetachmentRef {
    let typename: String
    let methodName: String
}

struct Component {
    let name: String
    let compositions: [Composition]
    let actions: [Action]
    let detachments: [DetachmentRef]
}
