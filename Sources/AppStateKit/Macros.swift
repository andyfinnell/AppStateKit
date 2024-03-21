
@attached(member, names: named(Action), named(reduce), named(EngineView), arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: Component)
public macro Component() = #externalMacro(module: "AppStateKitMacros", type: "ComponentMacro")

@attached(member, names: named(Action), named(reduce), named(MainApp), arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: AppComponent)
public macro AppComponent() = #externalMacro(module: "AppStateKitMacros", type: "AppComponentMacro")
