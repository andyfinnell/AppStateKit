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

@attached(member, names: arbitrary)
public macro ExtendDependencyScope<T>(with t: T) = #externalMacro(module: "AppStateKitMacros", type: "ExtendDependencyScopeMacro")

@attached(member, names: arbitrary)
public macro ExtendSideEffects<N, T>(with name: N, _ expr: T) = #externalMacro(module: "AppStateKitMacros", type: "ExtendSideEffectsMacro")

@attached(member, names: named(actionToUpdateState(from:)), named(translate(from:)), named(view(_:inject:)))
public macro Detachment() = #externalMacro(module: "AppStateKitMacros", type: "DetachmentMacro")

@freestanding(expression)
public macro bind<State, Action, Output, P>(_ engine: ViewEngine<State, Action, Output>, _ keyPath: KeyPath<State, P>) -> Binding<P> = #externalMacro(module: "AppStateKitMacros", type: "BindMacro")

@freestanding(expression)
public macro bindIfPresent<State, Action, Output, P>(_ engine: ViewEngine<State, Action, Output>, _ keyPath: KeyPath<State, P?>) -> Binding<Bool> = #externalMacro(module: "AppStateKitMacros", type: "BindIfPresentMacro")

@attached(peer)
public macro Updatable(output: Bool = false) = #externalMacro(module: "AppStateKitMacros", type: "UpdatableMacro")

@attached(peer)
public macro PassthroughOutput() = #externalMacro(module: "AppStateKitMacros", type: "PassthroughOutputMacro")

@attached(member, names: arbitrary)
public macro JSONStorageEffects<T>(for type: T.Type, defaultValue expr: T) = #externalMacro(module: "AppStateKitMacros", type: "JSONStorageEffectsMacro")

@attached(member, names: arbitrary)
public macro JSONStorageEffects<T: Codable>(for type: T.Type) = #externalMacro(module: "AppStateKitMacros", type: "JSONStorageEffectsMacro")

@attached(peer)
public macro Subscribe<E: Dependable, T>(to effect: E.Type) = #externalMacro(module: "AppStateKitMacros", type: "SubscribeMacro") where E.T == Effect<AsyncStream<T>, Never>

@attached(peer)
public macro SubscribeToJSONStorage<T: Codable & Equatable>(for type: T.Type) = #externalMacro(module: "AppStateKitMacros", type: "SubscribeToJSONStorageMacro")

