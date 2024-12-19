import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class BindElementsMacroTests: XCTestCase {
    func testBasicBind() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            #bindElements(engine, \\.value)
            """,
            expandedSource: """
            engine.binding(\\.value, send: {
                    .updateValue($0, index: $1)
                })
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
    
    func testLongBind() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            #bindElements(engine, \\State.value)
            """,
            expandedSource: """
            engine.binding(\\State.value, send: {
                    .updateValue($0, index: $1)
                })
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
