import SwiftSyntax
import SwiftSyntaxBuilder

struct DetachmentCodegen {
    static func codegen(from detachment: Detachment) -> [DeclSyntax] {
        let defaultActionToUpdateState: DeclSyntax = """
            static func actionToUpdateState(from state: State) -> \(raw: detachment.componentName).Action? {
                nil
            }
            """
        
        let defaultTranslate: DeclSyntax = """
            static func translate(from output: \(raw: detachment.componentName).Output) -> Action? {
                nil
            }
            """

        let translateMethodName = detachment.translateMethodName ?? "translate"
        
        let viewMethod: DeclSyntax = """
            
            static func view<E: Engine>(
                _ engine: E,
                inject: (DependencyScope) -> Void
            ) -> some View where E.State == State, E.Action == Action {
                 \(raw: detachment.componentName).EngineView(
                     engine: engine.scope(
                         component: \(raw: detachment.componentName).self,
                         initialState: initialState,
                         actionToUpdateState: actionToUpdateState,
                         translate: self.\(raw: translateMethodName),
                         inject: inject
                     ).view()
                 )
            }
            """

        let decls = [
            detachment.hasActionToUpdateState ? nil : defaultActionToUpdateState,
            detachment.translateMethodName == nil ? defaultTranslate : nil,
            viewMethod
        ]
        return decls.compactMap { $0 }
    }
}
