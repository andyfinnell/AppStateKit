import Foundation
import Combine
import SwiftUI

@MainActor
@dynamicMemberLookup
public final class ViewStore<State, Action>: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let applyThunk: (Action) async -> Void
    private let stateSubject: CurrentValueSubject<State, Never>
    @Published public private(set) var state: State
    
    public init<S: Storable>(store: S, removeDuplicatesBy isDuplicate: @escaping (S.State, S.State) -> Bool) where S.State == State, S.Action == Action {
        state = store.state
        stateSubject = CurrentValueSubject(store.state)
        // Intentionally holding parent in memory
        applyThunk = { action in
            await store.apply(action)
        }
        store.statePublisher.removeDuplicates(by: isDuplicate).sink { [weak self] state in
            self?.state = state
            self?.stateSubject.value = state
        }.store(in: &cancellables)
    }
    
    public func apply(_ action: Action) async {
        await applyThunk(action)
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }
    
    public func binding<T>(_ keyPath: KeyPath<State, T>, apply: @escaping (T) -> Action) -> Binding<T> {
        Binding<T>(get: {
            self.state[keyPath: keyPath]
        }, set: { [weak self] newValue, transaction in
            let action = apply(newValue)
            self?.apply(action, transaction: transaction)
        })
    }
    
    public func binding<T>(get: @escaping (State) -> T, apply: @escaping (T) -> Action) -> Binding<T> {
        Binding<T>(get: {
            get(self.state)
        }, set: { [weak self] newValue, transaction in
            let action = apply(newValue)
            self?.apply(action, transaction: transaction)
        })
    }
    
    public func binding<T>(get: @escaping (State) -> T) -> Binding<T> {
        Binding<T>(get: {
            get(self.state)
        }, set: { _ in
            // nop
        })
    }
}

extension ViewStore: Storable {
    public var statePublisher: AnyPublisher<State, Never> { stateSubject.eraseToAnyPublisher() }
}

private extension ViewStore {
    func apply(_ action: Action, transaction: Transaction) {
        if transaction.animation != nil {
            withTransaction(transaction) {
                apply(action)
            }
        } else {
            apply(action)
        }
    }
}

public extension Storable {
    @MainActor
    func forView(removeDuplicatesBy isDuplicate: @escaping (State, State) -> Bool) -> ViewStore<State, Action> {
        ViewStore(store: self, removeDuplicatesBy: isDuplicate)
    }
}

public extension Storable where State: Equatable {
    @MainActor
    func forView() -> ViewStore<State, Action> {
        ViewStore(store: self)
    }
}

public extension ViewStore where State: Equatable {
    convenience init<S: Storable>(store: S) where S.State == State, S.Action == Action {
        self.init(store: store, removeDuplicatesBy: ==)
    }
}
