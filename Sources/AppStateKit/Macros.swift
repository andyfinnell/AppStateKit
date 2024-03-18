
@attached(member, names: arbitrary)
public macro BindableAction() = #externalMacro(module: "AppStateKitMacros", type: "BindableActionMacro")

@attached(member, names: arbitrary)
public macro Component() = #externalMacro(module: "AppStateKitMacros", type: "ComponentMacro")
