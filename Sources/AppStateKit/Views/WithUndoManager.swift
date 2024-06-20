import Foundation
import SwiftUI

///
/// Example:
///
/// ```
/// static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
///     WithUndoManager { undoManager in
///
///     }
/// }
/// ```
public struct WithUndoManager<E: Engine, Content: View>: View {
    @Environment(\.undoManager) private var undoManager
    private let engine: E
    private let content: () -> Content
    
    public init(
        _ engine: E,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.engine = engine
        self.content = content
    }
    
    public var body: some View {
        content()
            .onChange(of: undoManager, initial: true) { _, newValue in
                engine.internals.dependencyScope.undoManager = newValue
            }
    }
}

struct UndoManagerDependency: Dependable {
    @MainActor
    static func makeDefault(with space: DependencyScope) -> UndoManager? {
        nil
    }
}

extension DependencyScope {
    public var undoManager: UndoManager? {
        get { self[UndoManagerDependency.self] }
        set { self[UndoManagerDependency.self] = newValue }
    }
}
