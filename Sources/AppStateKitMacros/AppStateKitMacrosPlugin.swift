import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct AppStateKitMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ComponentMacro.self,
        AppComponentMacro.self,
        EffectMacro.self,
        ExtendDependencyScopeMacro.self,
        ExtendSideEffectsMacro.self,
        DetachmentMacro.self,
        BindMacro.self,
        BindIfPresentMacro.self,
        UpdatableMacro.self,
        JSONStorageEffectsMacro.self,
        PassthroughOutputMacro.self,
        SubscribeMacro.self,
        SubscribeToJSONStorageMacro.self,
    ]
}
