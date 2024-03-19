
@attached(member, names: named(Action), named(reduce), named(ComponentView), arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: Component)
public macro Component() = #externalMacro(module: "AppStateKitMacros", type: "ComponentMacro")
