import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros
#endif

final class WithBindingMacroTests: XCTestCase {
    func testBasicBind() throws {
#if canImport(AppStateKitMacros)
        assertMacroExpansion(
            """
            #withBinding(engine, \\.text, {
                TextField("Name", text: $0)
            })
            """,
            expandedSource: """
            WithBinding(engine: engine, keyPath: \\.text, autosend: {
                    .updateText($0)
                }, content: {
                TextField("Name", text: $0)
                })
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }
}
