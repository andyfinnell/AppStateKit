import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class ImmediateEffectMacroTests: XCTestCase {
    func testBasicEffect() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @ImmediateEffect
            enum LoadEffect {
               static func perform(dependencies: DependencyScope, name: String, index: Int) throws -> String {
                   try dependencies.myAPI.load(name, at: index)
               }
            }
            """,
            expandedSource: """
            
            enum LoadEffect {
               @MainActor
               static func perform(dependencies: DependencyScope, name: String, index: Int) throws -> String {
                   try dependencies.myAPI.load(name, at: index)
               }
            }

            extension LoadEffect: Dependable {
                static func makeDefault(with dependencies: DependencyScope) -> ImmediateEffect<String , Error, String, Int> {
                    ImmediateEffect { name, index in
                        do {
                            return try Result<String , Error>.success(perform(dependencies: dependencies, name: name, index: index))
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
            @ExtendImmediateSideEffects(with: LoadAtIndexEffect, (index: Int) throws -> String)
            extension AnySideEffects {
            
            }
            """,
            expandedSource: """
            
            extension AnySideEffects {
            
                func loadAtIndex(
                    index p0: Int,
                    transform: @Sendable @escaping (String) -> Action,
                    onFailure: @Sendable @escaping (Error) -> Action
                ) {
                    tryPerform(LoadAtIndexEffect.self, with: p0, transform: transform, onFailure: onFailure)
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
