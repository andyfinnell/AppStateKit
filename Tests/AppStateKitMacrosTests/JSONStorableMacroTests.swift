import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class JSONStorableMacroTests: XCTestCase {
    func testExpansionWithDefaultValue() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @JSONStorable(hasDefault: true)
            extension TestModel {}
            """,
            expandedSource: """
            
            extension TestModel {

                struct StoreDependency: Dependable {
                    static var isGlobal: Bool {
                        true
                    }
            
                    static func makeDefault(with space: DependencyScope) -> any CodableStorage<TestModel> {
                        JSONStorage<TestModel>(filename: "TestModel", defaultValue: { @Sendable in
                                TestModel.defaultValue()
                            })
                    }
                }

                enum FetchEffect: Dependable {
                    static func perform(dependencies: DependencyScope) async -> AsyncStream<TestModel> {
                        await dependencies[TestModel.StoreDependency.self].makeStream()
                    }

                    static func makeDefault(with space: DependencyScope) -> Effect<AsyncStream<TestModel>, Never> {
                        Effect {
                            return await Result<AsyncStream<TestModel>, Never>.success(perform(dependencies: space))
                        }
                    }
                }

                enum SaveEffect: Dependable {
                    static func perform(dependencies: DependencyScope, _ state: TestModel) async throws {
                        try await dependencies[TestModel.StoreDependency.self].store(state)
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
            @JSONStorable
            extension TestModel {}
            """,
            expandedSource: """
            
            extension TestModel {

                struct StoreDependency: Dependable {
                    static var isGlobal: Bool {
                        true
                    }
            
                    static func makeDefault(with space: DependencyScope) -> any CodableStorage<TestModel> {
                        JSONStorage<TestModel>(filename: "TestModel")
                    }
                }

                enum FetchEffect: Dependable {
                    static func perform(dependencies: DependencyScope) async -> AsyncStream<TestModel> {
                        await dependencies[TestModel.StoreDependency.self].makeStream()
                    }

                    static func makeDefault(with space: DependencyScope) -> Effect<AsyncStream<TestModel>, Never> {
                        Effect {
                            return await Result<AsyncStream<TestModel>, Never>.success(perform(dependencies: space))
                        }
                    }
                }

                enum SaveEffect: Dependable {
                    static func perform(dependencies: DependencyScope, _ state: TestModel) async throws {
                        try await dependencies[TestModel.StoreDependency.self].store(state)
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
            }
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
