import SwiftSyntax
import SwiftSyntaxBuilder

struct JSONStorableCodegen {
    static func codegen(from jsonStorage: JSONStorageModel) -> [DeclSyntax] {
        let storeDependencyDecl: DeclSyntax
        if let defaultValue = jsonStorage.defaultValueExpression {
            storeDependencyDecl = """
            struct StoreDependency: Dependable {
                static var isGlobal: Bool { true }
            
                static func makeDefault(with space: DependencyScope) -> any CodableStorage<\(raw: jsonStorage.typename)> {
                    JSONStorage<\(raw: jsonStorage.typename)>(filename: "\(raw: jsonStorage.typename)", defaultValue: { @Sendable in \(defaultValue) })
                }
            }
            """
        } else {
            storeDependencyDecl = """
            struct StoreDependency: Dependable {
                static var isGlobal: Bool { true }

                static func makeDefault(with space: DependencyScope) -> any CodableStorage<\(raw: jsonStorage.typename)> {
                    JSONStorage<\(raw: jsonStorage.typename)>(filename: "\(raw: jsonStorage.typename)")
                }
            }
            """
        }
        
        let fetchDecl: DeclSyntax = """
            enum FetchEffect: Dependable {
                static func perform(dependencies: DependencyScope) async -> AsyncStream<\(raw: jsonStorage.typename)> {
                    await dependencies[\(raw: jsonStorage.typename).StoreDependency.self].makeStream()
                }

                static func makeDefault(with space: DependencyScope) -> Effect<AsyncStream<\(raw: jsonStorage.typename)>, Never> {
                    Effect {
                        return await Result<AsyncStream<\(raw: jsonStorage.typename)>, Never>.success(perform(dependencies: space))
                    }
                }
            }
            """
        
        let saveDecl: DeclSyntax = """
            enum SaveEffect: Dependable {
                static func perform(dependencies: DependencyScope, _ state: \(raw: jsonStorage.typename)) async throws {
                    try await dependencies[\(raw: jsonStorage.typename).StoreDependency.self].store(state)
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

        return [
            storeDependencyDecl,
            fetchDecl,
            saveDecl,
        ].compactMap { $0 }
    }
}
