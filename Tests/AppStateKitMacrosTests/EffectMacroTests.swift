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

    func testExtendDependencyScope() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @ExtendDependencyScope(with: LoadAtIndexEffect)
            extension DependencyScope {
            
            }
            """,
            expandedSource: """
            
            extension DependencyScope {
            
                var loadAtIndex: LoadAtIndexEffect.T {
                    self [LoadAtIndexEffect.self]
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
            @ExtendSideEffects(with: LoadAtIndexEffect, (index: Int) async throws -> String)
            extension AnySideEffects {
            
            }
            """,
            expandedSource: """
            
            extension AnySideEffects {
            
                func loadAtIndex(
                    index p0: Int,
                    transform: @escaping (String) async -> Action,
                    onFailure: @escaping (Error) async -> Action
                ) {
                    tryPerform(\\.loadAtIndex, with: p0, transform: transform, onFailure: onFailure)
                }

                func subscribeToLoadAtIndex(
                    index p0: Int,
                    transform: @escaping (String, (Action) async -> Void) async throws -> Void,
                    onFailure: @escaping (Error) async -> Action
                ) -> SubscriptionID {
                    trySubscribe(\\.loadAtIndex, with: p0, transform: transform, onFailure: onFailure)
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
            @ExtendSideEffects(with: ImportURLEffect, (URL) async throws -> String)
            extension AnySideEffects {
            
            }
            """,
            expandedSource: """
            
            extension AnySideEffects {
            
                func importURL(
                    _ p0: URL,
                    transform: @escaping (String) async -> Action,
                    onFailure: @escaping (Error) async -> Action
                ) {
                    tryPerform(\\.importURL, with: p0, transform: transform, onFailure: onFailure)
                }

                func subscribeToImportURL(
                    _ p0: URL,
                    transform: @escaping (String, (Action) async -> Void) async throws -> Void,
                    onFailure: @escaping (Error) async -> Action
                ) -> SubscriptionID {
                    trySubscribe(\\.importURL, with: p0, transform: transform, onFailure: onFailure)
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
