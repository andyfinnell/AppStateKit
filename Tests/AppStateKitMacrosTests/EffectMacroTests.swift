import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class EffectMacroTests: XCTestCase {
    func testBasicEffect() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Effect
            enum LoadEffect {
               static func perform(dependencies: DependencyScope, name: String, index: Int) async throws -> String {
                   try await dependencies.myAPI.load(name, at: index)
               }
            }
            """,
            expandedSource: """
            
            enum LoadEffect {
               static func perform(dependencies: DependencyScope, name: String, index: Int) async throws -> String {
                   try await dependencies.myAPI.load(name, at: index)
               }
            }

            extension LoadEffect: Dependable {
                static func makeDefault(with dependencies: DependencyScope) -> Effect<String , Error, String, Int> {
                    Effect { name, index in
                        do {
                            return try await Result<String , Error>.success(perform(dependencies: dependencies, name: name, index: index))
                        } catch {
                            return Result<String , Error>.failure(error)
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

    func testExtendSideEffects() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @ExtendSideEffects(with: LoadAtIndexEffect.self, ((index: Int) async throws -> String).self)
            extension AnySideEffects {
            
            }
            """,
            expandedSource: """
            
            extension AnySideEffects {
            
                func loadAtIndex(
                    index p0: Int,
                    transform: @Sendable @escaping (String) async -> Action,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) {
                    tryPerform(LoadAtIndexEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }

                func subscribeToLoadAtIndex(
                    index p0: Int,
                    transform: @Sendable @escaping (String, (Action) async -> Void) async throws -> Void,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) -> SubscriptionID {
                    trySubscribe(LoadAtIndexEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }

            }
            
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testExtendSideEffectsPart2() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @ExtendSideEffects(with: ImportURLEffect.self, ((URL) async throws -> String).self)
            extension AnySideEffects {
            
            }
            """,
            expandedSource: """
            
            extension AnySideEffects {
            
                func importURL(
                    _ p0: URL,
                    transform: @Sendable @escaping (String) async -> Action,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) {
                    tryPerform(ImportURLEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }

                func subscribeToImportURL(
                    _ p0: URL,
                    transform: @Sendable @escaping (String, (Action) async -> Void) async throws -> Void,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) -> SubscriptionID {
                    trySubscribe(ImportURLEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }

            }
            
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testEscapingEffectParameter() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @Effect
            enum FilterEffect {
               static func perform(dependencies: DependencyScope, including predicate: @escaping (String) -> Bool) async -> Int {
                    models.filter { predicate($0.name) }.count
               }
            }
            """,
            expandedSource: """
            
            enum FilterEffect {
               static func perform(dependencies: DependencyScope, including predicate: @escaping (String) -> Bool) async -> Int {
                    models.filter { predicate($0.name) }.count
               }
            }

            extension FilterEffect: Dependable {
                static func makeDefault(with dependencies: DependencyScope) -> Effect<Int , Never, (String) -> Bool> {
                    Effect { predicate in
                        return await Result<Int , Never>.success(perform(dependencies: dependencies, including: predicate))
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

    func testExtendSideEffectsWithEscapingParameter() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @ExtendSideEffects(with: FilterEffect.self, ((including: @escaping (String) -> Bool) async -> Int).self)
            extension AnySideEffects {
            
            }
            """,
            expandedSource: """
            
            extension AnySideEffects {
            
                func filter(
                    including p0: @escaping (String) -> Bool,
                    transform: @Sendable @escaping (Int) async -> Action
                ) {
                    perform(FilterEffect.self, with: p0, transform: transform)
                }

                func subscribeToFilter(
                    including p0: @escaping (String) -> Bool,
                    transform: @Sendable @escaping (Int, (Action) async -> Void) async throws -> Void
                ) -> SubscriptionID {
                    subscribe(FilterEffect.self, with: p0, transform: transform)
                }

            }
            
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    // TODO: test passing a closure with escaping through as a parameter to an effect
}
