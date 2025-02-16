import SwiftUI

@MainActor
@Observable
public final class EngineBinding<Value: Equatable> {
    public var value: Value {
        didSet {
            onValueChanged(from: oldValue)
        }
    }
    private var sink: AnySink?
    private let send: (Value) -> Void
    private var isUpdatingCount = 0
    
    init<E: Engine>(
        engine: E,
        keyPath: KeyPath<E.State, Value>,
        autosend: @escaping (Value) -> E.Action?
    )  {
        // Intentionally holding parent in memory
        send = { value in
            guard let action = autosend(value) else {
                return
            }
            engine.send(action)
        }
        value = engine.state[keyPath: keyPath] // initialize
        sink = engine.statePublisher.sink { [weak self] newState in
            self?.isUpdatingCount += 1
            self?.value = newState[keyPath: keyPath]
            self?.isUpdatingCount -= 1
        }
    }
    
    init<E: Engine>(
        engine: E,
        keyPath: KeyPath<E.State, Value>,
        send: @escaping (Value) -> Void
    )  {
        // Intentionally holding parent in memory
        self.send = send
        value = engine.state[keyPath: keyPath] // initialize
        sink = engine.statePublisher.sink { [weak self] newState in
            self?.isUpdatingCount += 1
            self?.value = newState[keyPath: keyPath]
            self?.isUpdatingCount -= 1
        }
    }
}

private extension EngineBinding {
    func onValueChanged(from oldValue: Value) {
        guard oldValue != value && isUpdatingCount == 0 else {
            return
        }
        send(value)
    }
}

public extension Engine {
    func bind<T>(_ keyPath: KeyPath<State, T>, send: @escaping (T) -> Action?) -> EngineBinding<T> {
        EngineBinding(engine: self, keyPath: keyPath, autosend: send)
    }
    
    func bind<T>(_ keyPath: KeyPath<State, T>, send: @escaping (T) -> Void) -> EngineBinding<T> {
        EngineBinding(engine: self, keyPath: keyPath, send: send)
    }
}
