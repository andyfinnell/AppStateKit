import SwiftSyntax

struct EffectParameter {
    let label: String?
    let name: String
    let type: TypeSyntax
}

struct Effect {
    let typename: String
    let methodName: String
    let parameters: [EffectParameter]
    let returnType: TypeSyntax?
    let isThrowing: Bool
    let isAsync: Bool
}
