
@attached(member, names: arbitrary)
public macro BindableAction() = #externalMacro(module: "AppStateKitMacros", type: "BindableActionMacro")

@attached(member, names: named(Action), named(reduce), named(ComponentView), arbitrary)
@attached(extension, conformances: Component)
public macro Component() = #externalMacro(module: "AppStateKitMacros", type: "ComponentMacro")
