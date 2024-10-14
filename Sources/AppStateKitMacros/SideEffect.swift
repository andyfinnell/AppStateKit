struct SideEffectParameter {
    let label: String?
    let type: String
}

enum SideEffectReference {
    case keyPath(String)
    case typename(String)
}

struct SideEffect {
    let methodName: String
    let subscribeName: String
    let parameters: [SideEffectParameter]
    let returnType: String
    let isThrowing: Bool
    let isAsync: Bool
    let effectReference: SideEffectReference
}
