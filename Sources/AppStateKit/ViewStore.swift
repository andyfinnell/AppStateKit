import Foundation
import Combine
import SwiftUI

@dynamicMemberLookup
public final class ViewStore<State, Action>: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let applyThunk: (Action) -> Void
    @Published public private(set) var state: State
    
    public init<S: Storable>(store: S, removeDuplicatesBy isDuplicate: @escaping (S.State, S.State) -> Bool) where S.State == State, S.Action == Action {
        state = store.state
        applyThunk = { [weak store] action in
            store?.apply(action)
        }
        store.statePublisher.removeDuplicates(by: isDuplicate).sink { [weak self] state in
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
}

public extension ViewStore where State: Equatable {
    convenience init<S: Storable>(store: S) where S.State == State, S.Action == Action {
        self.init(store: store, removeDuplicatesBy: ==)
    }
}
