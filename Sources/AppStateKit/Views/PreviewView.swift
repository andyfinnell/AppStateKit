import SwiftUI

@MainActor
struct PreviewView<C: Component>: View {
    enum PreviewComponent: Component {
        typealias State = C.State
        typealias Action = C.Action
        typealias Output = Never

        @MainActor
        static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action, Output>) {
            C.reduce(&state, action: action, sideEffects: sideEffects.map({
                        $0
                    }, translate: { _ in
                        nil
                    }))
        }

        @MainActor
        @ViewBuilder
        static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
            C.view(engine.map(state: {
                        $0
                    }, action: {
                        $0
                    }, translate: { _ in
                        nil
                    }).view())
        }
    }

    @LazyState private var engine: MainEngine<C.State, C.Action>

    init(state: C.State, dependencyScope: DependencyScope) {
        _engine = LazyState(wrappedValue: MainEngine(dependencies: dependencyScope, state: state, component: PreviewComponent.self))
    }

    var body: some View {
        PreviewComponent.view(engine.view())
    }
}

@MainActor
public func preview<C: Component>(_ type: C.Type, withState state: C.State, dependencyScope: DependencyScope = DependencyScope()) -> some View {
    PreviewView<C>(state: state, dependencyScope: dependencyScope)
}
