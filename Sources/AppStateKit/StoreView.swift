import Foundation
import SwiftUI

public struct StoreView<State, Action, Content: View>: View {
    @ObservedObject private var viewStore: ViewStore<State, Action>
    private let content: (ViewStore<State, Action>) -> Content
    
    public init<S: Storable>(_ store: S,
                             removeDuplicatesBy removeDuplicates: @escaping (State, State) -> Bool,
                             @ViewBuilder content: @escaping (ViewStore<State, Action>) -> Content) where S.State == State, S.Action == Action {
        viewStore = ViewStore(store: store, removeDuplicatesBy: removeDuplicates)
        self.content = content
    }

    public init<S: Storable>(_ store: S,
                             @ViewBuilder content: @escaping (ViewStore<State, Action>) -> Content) where S.State == State, S.Action == Action, S.State: Equatable {
        viewStore = ViewStore(store: store, removeDuplicatesBy: ==)
        self.content = content
    }

    public var body: Content {
        content(viewStore)
    }
}
