import SwiftSyntax
import SwiftSyntaxBuilder

struct DetachmentCodegen {
    static func codegen(from detachment: Detachment) -> [DeclSyntax] {
        let defaultActionToUpdateState: DeclSyntax = """
            
            static func actionToUpdateState(from state: State) -> \(raw: detachment.componentName).Action? {
                nil
            }
            """
        
        // TODO: if Output is never, don't put `nil`
        let defaultTranslate: DeclSyntax = """
            
            static func translate(from output: \(raw: detachment.componentName).Output) -> TranslateResult<Action, Output> {
                .drop
            }
            """

        let translateMethodName = detachment.translateMethodName ?? "translate"
        
        let viewMethod: DeclSyntax = """
            @MainActor
            static func view<E: Engine>(
                _ engine: E,
                inject: @escaping (DependencyScope) -> Void
            ) -> \(raw: detachment.componentName).EngineView where E.State == State, E.Action == Action, E.Output == Output {
                 \(raw: detachment.componentName).EngineView(
                     engine: engine.detach(
                         component: \(raw: detachment.componentName).self,
                         initialState: initialState,
                         actionToUpdateState: actionToUpdateState,
                         translate: self.\(raw: translateMethodName),
                         detachment: \(raw: detachment.name).self,
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
