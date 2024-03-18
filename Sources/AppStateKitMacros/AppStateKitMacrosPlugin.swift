import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct AppStateKitMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BindableActionMacro.self,
        ComponentMacro.self,
    ]
}
