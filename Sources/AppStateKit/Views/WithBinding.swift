import SwiftUI

public struct WithBinding<Content: View, Value: Equatable & Sendable>: View {
    private let content: (Binding<Value>) -> Content
    
    @State private var value: EngineBinding<Value>
    
    public init<E: Engine & Sendable>(
        engine: E,
        keyPath: KeyPath<E.State, Value> & Sendable,
        send: @escaping (Value) -> Void,
        @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) {
        self._value = State(initialValue: engine.bind(keyPath, send: send))
        self.content = content
    }

    public init<E: Engine & Sendable>(
        engine: E,
        keyPath: KeyPath<E.State, Value> & Sendable,
        autosend: @escaping @MainActor (Value) -> E.Action?,
        @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) {
        self._value = State(initialValue: engine.bind(keyPath, send: autosend))
        self.content = content
    }

    public var body: some View {
        // TODO: debounce in both directions?
        content($value.value)
    }
}
