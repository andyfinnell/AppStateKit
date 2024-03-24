import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(AppStateKitMacros)
import AppStateKitMacros

let testMacros: [String: Macro.Type] = [
    "Component": ComponentMacro.self,
    "AppComponent": AppComponentMacro.self,
    "Effect": EffectMacro.self,
    "ExtendDependencyScope": ExtendDependencyScopeMacro.self,
    "ExtendSideEffects": ExtendSideEffectsMacro.self,
]
#endif
