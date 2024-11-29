import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class JSONStorageEffectsMacroTests: XCTestCase {
    func testBasicExpansion() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            @JSONStorageEffects(for: TestModel.self)
            extension AnySideEffects {}
            """,
            expandedSource: """
            
            extension AnySideEffects {

                func fetchTestModel(
                    transform: @Sendable @escaping (AsyncStream<TestModel>) async -> Action
                ) {
                    perform(TestModel.FetchEffect.self, transform: transform)
                }

                func subscribeToFetchTestModel(
                    transform: @Sendable @escaping (AsyncStream<TestModel>, (Action) async -> Void) async throws -> Void
                ) -> SubscriptionID {
                    subscribe(TestModel.FetchEffect.self, transform: transform)
                }

                func saveTestModel(
                    _ p0: TestModel,
                    transform: @Sendable @escaping () async -> Action,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) {
                    tryPerform(TestModel.SaveEffect.self, with: p0, transform: transform, onFailure: onFailure)
                }

                func subscribeToSaveTestModel(
                    _ p0: TestModel,
                    transform: @Sendable @escaping (Void, (Action) async -> Void) async throws -> Void,
                    onFailure: @Sendable @escaping (Error) async -> Action
                ) -> SubscriptionID {
                    trySubscribe(TestModel.SaveEffect.self, with: p0, transform: transform, onFailure: onFailure)
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
