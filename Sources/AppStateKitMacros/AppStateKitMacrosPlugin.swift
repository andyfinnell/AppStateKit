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
        BindElementsMacro.self,
        BindBatchMacro.self,
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
