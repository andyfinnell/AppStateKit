import SwiftUI

@attached(member, names: named(Action), named(reduce), named(EngineView), arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: Component, BaseComponent)
public macro Component() = #externalMacro(module: "AppStateKitMacros", type: "ComponentMacro")

@attached(member, names: named(Action), named(reduce), named(MainApp), arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: AppComponent)
public macro AppComponent() = #externalMacro(module: "AppStateKitMacros", type: "AppComponentMacro")

@attached(extension, conformances: Dependable, names: named(makeDefault(with:)))
public macro Effect() = #externalMacro(module: "AppStateKitMacros", type: "EffectMacro")

@attached(memberAttribute)
@attached(extension, conformances: Dependable, names: named(makeDefault(with:)))
public macro ImmediateEffect() = #externalMacro(module: "AppStateKitMacros", type: "ImmediateEffectMacro")

@attached(member, names: arbitrary)
public macro ExtendDependencyScope<T>(with t: T) = #externalMacro(module: "AppStateKitMacros", type: "ExtendDependencyScopeMacro")

@attached(member, names: arbitrary)
public macro ExtendSideEffects<N, T>(with name: N, _ expr: T) = #externalMacro(module: "AppStateKitMacros", type: "ExtendSideEffectsMacro")

@attached(member, names: arbitrary)
public macro ExtendImmediateSideEffects<N, T>(with name: N, _ expr: T) = #externalMacro(module: "AppStateKitMacros", type: "ExtendImmediateSideEffectsMacro")

@attached(extension, conformances: Detachment, names: named(DetachedAction))
@attached(member, names: named(actionToUpdateState(from:)), named(translate(from:)), named(view(_:inject:)))
public macro Detachment() = #externalMacro(module: "AppStateKitMacros", type: "DetachmentMacro")

@attached(peer)
public macro Updatable(output: Bool = false) = #externalMacro(module: "AppStateKitMacros", type: "UpdatableMacro")

@attached(peer)
public macro BatchUpdatable(output: Bool = false) = #externalMacro(module: "AppStateKitMacros", type: "BatchUpdatableMacro")

@attached(peer)
public macro PassthroughOutput() = #externalMacro(module: "AppStateKitMacros", type: "PassthroughOutputMacro")

@attached(member, names: arbitrary)
public macro JSONStorageEffects<T: Codable>(for type: T.Type) = #externalMacro(module: "AppStateKitMacros", type: "JSONStorageEffectsMacro")

@attached(member, names: arbitrary)
public macro JSONStorable(hasDefault: Bool) = #externalMacro(module: "AppStateKitMacros", type: "JSONStorableMacro")

@attached(member, names: arbitrary)
public macro JSONStorable() = #externalMacro(module: "AppStateKitMacros", type: "JSONStorableMacro")

@attached(peer)
public macro Subscribe<E: Dependable, T>(to effect: E.Type) = #externalMacro(module: "AppStateKitMacros", type: "SubscribeMacro") where E.T == Effect<AsyncStream<T>, Never>

@attached(peer)
public macro SubscribeToJSONStorage<T: Codable & Equatable>(for type: T.Type) = #externalMacro(module: "AppStateKitMacros", type: "SubscribeToJSONStorageMacro")

