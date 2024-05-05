import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class BindIfPresentMacroTests: XCTestCase {
    func testBasicBind() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            #bindIfPresent(engine, \\.value)
            """,
            expandedSource: """
            engine.binding(
                get: {
                    $0 [keyPath: \\.value] != nil
                },
                send: {
                    $0 ? nil : .updateValue(nil)
                }
            )
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
