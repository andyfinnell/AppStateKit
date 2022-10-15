import Foundation
import SwiftUI

public struct IfLetView<State, Action, Content: View>: View {
    private let store: MapStore<State?, Action>
    private let ifContent: (MapStore<State, Action>) -> Content
    
    public init(_ store: MapStore<State?, Action>,
                @ViewBuilder ifContent: @escaping (MapStore<State, Action>) -> Content) {
        self.store = store
        self.ifContent = ifContent
    }
    
    public var body: some View {
        StoreView(store, removeDuplicatesBy: { ($0 == nil) == ($1 == nil) }) { viewStore in
            if let state = viewStore.state {
                ifContent(store.map(state: { $0 ?? state }, action: { $0 }))
            }
        }
    }
}

public struct IfLetElseView<State, Action, IfContent: View, ElseContent: View>: View {
    private let store: MapStore<State?, Action>
    private let ifContent: (MapStore<State, Action>) -> IfContent
    private let elseContent: () -> ElseContent
    
    public init(_ store: MapStore<State?, Action>,
                @ViewBuilder ifContent: @escaping (MapStore<State, Action>) -> IfContent,
                @ViewBuilder elseContent: @escaping () -> ElseContent) {
        self.store = store
        self.ifContent = ifContent
        self.elseContent = elseContent
    }
    
    public var body: some View {
        StoreView(store, removeDuplicatesBy: { ($0 == nil) == ($1 == nil) }) { viewStore in
            if let state = viewStore.state {
                ifContent(store.map(state: { $0 ?? state }, action: { $0 }))
            } else {
                elseContent()
            }
        }
    }
}
