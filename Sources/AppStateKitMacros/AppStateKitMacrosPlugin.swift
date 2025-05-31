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
        ExtendSideEffectsMacro.self,
        DetachmentMacro.self,
        UpdatableMacro.self,
        BatchUpdatableMacro.self,
        JSONStorageEffectsMacro.self,
        JSONStorableMacro.self,
        PassthroughOutputMacro.self,
        SubscribeMacro.self,
        SubscribeToJSONStorageMacro.self,
        ImmediateEffectMacro.self,
        ExtendImmediateSideEffectsMacro.self,
    ]
}
