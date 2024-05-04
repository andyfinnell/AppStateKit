import Foundation
import SwiftUI

/// Introduce some FocusState that can be sync'd to Component.State using
/// a binding.
///
/// Example:
///
/// ```
/// static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
///     WithFocusState(#bind(engine, \.focusedField)) { focusedField in
///         TextField("Title", text: #bind(engine, \.title))
///             .focused(focusedField, equals: .title)
///     }
/// }
/// ```
public struct WithFocusState<Value: Hashable, Content: View>: View {
    @FocusState private var focusedValue: Value?
    private var binding: Binding<Value?>
    private let content: (FocusState<Value?>.Binding) -> Content
    
    public init(
        _ binding: Binding<Value?>,
        @ViewBuilder content: @escaping (FocusState<Value?>.Binding) -> Content
    ) {
        self.binding = binding
        self.content = content
    }
    
    public var body: some View {
        content($focusedValue)
            .onChange(of: binding.wrappedValue) { _, nowValue in
                focusedValue = nowValue
            }
            .onChange(of: focusedValue) { _, nowValue in
                binding.wrappedValue = nowValue
            }
    }
}

