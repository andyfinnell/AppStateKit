import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class JSONStorageMacroTests: XCTestCase {
    func testExpansionWithDefaultValue() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @JSONStorageEffects(for: TestModel.self, defaultValue: TestModel.defaultValue())
            extension AnySideEffects {}
            """,
            expandedSource: """
            
            extension AnySideEffects {

                private struct TestModelStoreDependency: Dependable {
                    static var isGlobal: Bool {
                        true
                    }
            
                    static func makeDefault(with space: DependencyScope) -> any CodableStorage<TestModel> {
                        JSONStorage<TestModel>(filename: "TestModel", defaultValue: { @Sendable in
                                TestModel.defaultValue()
                            })
                    }
                }

                private enum FetchTestModelEffect: Dependable {
                    static func perform(dependencies: DependencyScope) async -> AsyncStream<TestModel> {
                        await dependencies[TestModelStoreDependency.self].makeStream()
                    }

                    static func makeDefault(with space: DependencyScope) -> Effect<AsyncStream<TestModel>, Never> {
                        Effect {
                            return await Result<AsyncStream<TestModel>, Never>.success(perform(dependencies: space))
                        }
                    }
                }

                private enum SaveTestModelEffect: Dependable {
                    static func perform(dependencies: DependencyScope, _ state: TestModel) async throws {
                        try await dependencies[TestModelStoreDependency.self].store(state)
                    }

                    static func makeDefault(with space: DependencyScope) -> Effect<Void, Error, TestModel> {
                        Effect { state in
                            do {
                                return try await Result<Void, Error>.success(perform(dependencies: space, state))
                            } catch {
                                return Result<Void, Error>.failure(error)
                            }
                        }
                    }
                }

                func fetchTestModel(
                    transform: @Sendable @escaping (AsyncStream<TestModel>) async -> Action
                ) {
                    perform(FetchTestModelEffect.self, transform: transform)
                }

                func subscribeToFetchTestModel(
                    transform: @Sendable @escaping (AsyncStream<TestModel>, (Action) async -> Void) async throws -> Void
                ) -> SubscriptionID {
                    subscribe(FetchTestModelEffect.self, transform: transform)
                }

                func saveTestModel(
                    _ p0: TestModel,
                    transform: @Sendable @escaping () async -> Action,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) {
                    tryPerform(SaveTestModelEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }

                func subscribeToSaveTestModel(
                    _ p0: TestModel,
                    transform: @Sendable @escaping (Void, (Action) async -> Void) async throws -> Void,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) -> SubscriptionID {
                    trySubscribe(SaveTestModelEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    func testExpansionNoDefaultValue() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @JSONStorageEffects(for: TestModel.self)
            extension AnySideEffects {}
            """,
            expandedSource: """
            
            extension AnySideEffects {

                private struct TestModelStoreDependency: Dependable {
                    static var isGlobal: Bool {
                        true
                    }
            
                    static func makeDefault(with space: DependencyScope) -> any CodableStorage<TestModel> {
                        JSONStorage<TestModel>(filename: "TestModel")
                    }
                }

                private enum FetchTestModelEffect: Dependable {
                    static func perform(dependencies: DependencyScope) async -> AsyncStream<TestModel> {
                        await dependencies[TestModelStoreDependency.self].makeStream()
                    }

                    static func makeDefault(with space: DependencyScope) -> Effect<AsyncStream<TestModel>, Never> {
                        Effect {
                            return await Result<AsyncStream<TestModel>, Never>.success(perform(dependencies: space))
                        }
                    }
                }

                private enum SaveTestModelEffect: Dependable {
                    static func perform(dependencies: DependencyScope, _ state: TestModel) async throws {
                        try await dependencies[TestModelStoreDependency.self].store(state)
                    }

                    static func makeDefault(with space: DependencyScope) -> Effect<Void, Error, TestModel> {
                        Effect { state in
                            do {
                                return try await Result<Void, Error>.success(perform(dependencies: space, state))
                            } catch {
                                return Result<Void, Error>.failure(error)
                            }
                        }
                    }
                }

                func fetchTestModel(
                    transform: @Sendable @escaping (AsyncStream<TestModel>) async -> Action
                ) {
                    perform(FetchTestModelEffect.self, transform: transform)
                }

                func subscribeToFetchTestModel(
                    transform: @Sendable @escaping (AsyncStream<TestModel>, (Action) async -> Void) async throws -> Void
                ) -> SubscriptionID {
                    subscribe(FetchTestModelEffect.self, transform: transform)
                }

                func saveTestModel(
                    _ p0: TestModel,
                    transform: @Sendable @escaping () async -> Action,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) {
                    tryPerform(SaveTestModelEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }

                func subscribeToSaveTestModel(
                    _ p0: TestModel,
                    transform: @Sendable @escaping (Void, (Action) async -> Void) async throws -> Void,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) -> SubscriptionID {
                    trySubscribe(SaveTestModelEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
