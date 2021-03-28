import Foundation
import Combine
import SwiftUI

@dynamicMemberLookup
public final class ViewStore<State, Action, Effect, Environment>: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let applyThunk: (Action) -> Void
    @Published public private(set) var state: State
    
    public init(store: Store<State, Action, Effect, Environment>, removeDuplicatesBy isDuplicate: @escaping (State, State) -> Bool) {
        state = store.state
        applyThunk = { [weak store] action in
            store?.apply(action)
        }
        store.$state.removeDuplicates(by: isDuplicate).sink { [weak self] state in
            self?.state = state
        }.store(in: &cancellables)
    }
 
    public func apply(_ action: Action) {
        applyThunk(action)
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }
    
    public func binding<T>(_ keyPath: KeyPath<State, T>, apply: @escaping (T) -> Action) -> Binding<T> {
        Binding<T>(get: { self.state[keyPath: keyPath] }, set: { [weak self] newValue in
            let action = apply(newValue)
            self?.apply(action)
        })
    }
    
    // TODO: eventually will need bindings
}

public extension ViewStore where State: Equatable {
    convenience init(store: Store<State, Action, Effect, Environment>) {
        self.init(store: store, removeDuplicatesBy: ==)
    }
}
