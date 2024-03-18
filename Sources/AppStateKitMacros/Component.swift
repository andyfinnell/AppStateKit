import SwiftSyntax

indirect enum Composition {
    case property(String, Composition)
    case optional(Composition)
    case array(Composition)
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

struct Component {
    let compositions: [Composition]
    let actions: [Action]
}
