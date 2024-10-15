import SwiftSyntax
import SwiftSyntaxBuilder

struct JSONStorageCodegen {
    static func codegen(from jsonStorage: JSONStorageModel) -> [DeclSyntax] {
        let storeDependencyDecl: DeclSyntax
        if let defaultValue = jsonStorage.defaultValueExpression {
            storeDependencyDecl = """
            private struct \(raw: jsonStorage.typename)StoreDependency: Dependable {
                static var isGlobal: Bool { true }
            
                static func makeDefault(with space: DependencyScope) -> any CodableStorage<\(raw: jsonStorage.typename)> {
                    JSONStorage<\(raw: jsonStorage.typename)>(filename: "\(raw: jsonStorage.typename)", defaultValue: { @Sendable in \(defaultValue) })
                }
            }
            """
        } else {
            storeDependencyDecl = """
            private struct \(raw: jsonStorage.typename)StoreDependency: Dependable {
                static var isGlobal: Bool { true }

                static func makeDefault(with space: DependencyScope) -> any CodableStorage<\(raw: jsonStorage.typename)> {
                    JSONStorage<\(raw: jsonStorage.typename)>(filename: "\(raw: jsonStorage.typename)")
                }
            }
            """
        }
        
        let fetchDecl: DeclSyntax = """
            private enum Fetch\(raw: jsonStorage.typename)Effect: Dependable {
                static func perform(dependencies: DependencyScope) async -> AsyncStream<\(raw: jsonStorage.typename)> {
                    await dependencies[\(raw: jsonStorage.typename)StoreDependency.self].makeStream()
                }

                static func makeDefault(with space: DependencyScope) -> Effect<AsyncStream<\(raw: jsonStorage.typename)>, Never> {
                    Effect {
                        return await Result<AsyncStream<\(raw: jsonStorage.typename)>, Never>.success(perform(dependencies: space))
                    }
                }
            }
            """
        
        let saveDecl: DeclSyntax = """
            private enum Save\(raw: jsonStorage.typename)Effect: Dependable {
                static func perform(dependencies: DependencyScope, _ state: \(raw: jsonStorage.typename)) async throws {
                    try await dependencies[\(raw: jsonStorage.typename)StoreDependency.self].store(state)
                }

                static func makeDefault(with space: DependencyScope) -> Effect<Void, Error, \(raw: jsonStorage.typename)> {
                    Effect { state in
                        do {
                            return try await Result<Void, Error>.success(perform(dependencies: space, state))
                        } catch {
                            return Result<Void, Error>.failure(error)
                        }
                    }
                }
            }
            """

        let fetchSideEffect = SideEffect(
            methodName: "fetch\(jsonStorage.typename)",
            subscribeName: "subscribeToFetch\(jsonStorage.typename)",
            parameters: [],
            returnType: "AsyncStream<\(jsonStorage.typename)>",
            isThrowing: false,
            isAsync: true,
            effectReference: .typename("Fetch\(jsonStorage.typename)Effect")
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
            effectReference: .typename("Save\(jsonStorage.typename)Effect")
        )

        return [
            storeDependencyDecl,
            fetchDecl,
            saveDecl,
            ExtendSideEffectsCodegen.codegenMethod(from: fetchSideEffect),
            ExtendSideEffectsCodegen.codegenSubscribeMethod(from: fetchSideEffect),
            ExtendSideEffectsCodegen.codegenMethod(from: saveSideEffect),
            ExtendSideEffectsCodegen.codegenSubscribeMethod(from: saveSideEffect),
        ].compactMap { $0 }
    }
}
