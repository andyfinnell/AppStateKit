import SwiftSyntax
import SwiftSyntaxBuilder

struct JSONStorageEffectsCodegen {
    static func codegen(from jsonStorage: JSONStorageModel) -> [DeclSyntax] {
        let fetchSideEffect = SideEffect(
            methodName: "fetch\(jsonStorage.typename)",
            subscribeName: "subscribeToFetch\(jsonStorage.typename)",
            parameters: [],
            returnType: "AsyncStream<\(jsonStorage.typename)>",
            isThrowing: false,
            isAsync: true,
            effectReference: .typename("\(jsonStorage.typename).FetchEffect"),
            isImmediate: false
        )

        let saveSideEffect = SideEffect(
            methodName: "save\(jsonStorage.typename)",
            subscribeName: "subscribeToSave\(jsonStorage.typename)",
            parameters: [
                SideEffectParameter(label: nil, type: jsonStorage.typename)
            ],
            returnType: "Void",
            isThrowing: true,
            isAsync: true,
            effectReference: .typename("\(jsonStorage.typename).SaveEffect"),
            isImmediate: false
        )

        return [
            ExtendSideEffectsCodegen.codegenMethod(from: fetchSideEffect),
            ExtendSideEffectsCodegen.codegenSubscribeMethod(from: fetchSideEffect),
            ExtendSideEffectsCodegen.codegenMethod(from: saveSideEffect),
            ExtendSideEffectsCodegen.codegenSubscribeMethod(from: saveSideEffect),
        ].compactMap { $0 }
    }
}
