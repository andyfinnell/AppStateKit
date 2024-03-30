import SwiftSyntax
import SwiftSyntaxBuilder

struct DetachmentCodegen {
    static func codegen(from detachment: Detachment) -> [DeclSyntax] {
        let defaultActionToUpdateState: DeclSyntax = """
            static func actionToUpdateState(from state: State) -> \(raw: detachment.componentName).Action? {
                nil
            }
            """
        
        let defaultActionToPassUp: DeclSyntax = """
            static func actionToPassUp(from action: \(raw: detachment.componentName).Action) -> Action? {
                nil
            }
            """

        let viewMethod: DeclSyntax = """
            @MainActor
            static func view<E: Engine>(
                _ engine: E,
                inject: (DependencyScope) -> Void
            ) -> some View where E.State == State, E.Action == Action {
                 \(raw: detachment.componentName).EngineView(
                     engine: engine.scope(
                         component: \(raw: detachment.componentName).self,
                         initialState: initialState,
                         actionToUpdateState: actionToUpdateState,
                         actionToPassUp: actionToPassUp,
                         inject: inject
                     ).view()
                 )
            }
            """

        let decls = [
            detachment.hasActionToUpdateState ? nil : defaultActionToUpdateState,
            detachment.hasActionToPassUp ? nil : defaultActionToPassUp,
            viewMethod
        ]
        return decls.compactMap { $0 }
    }
}
