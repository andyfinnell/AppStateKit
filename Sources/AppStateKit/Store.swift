import Foundation
import Combine

public final class Store<State, Action, Effect, Environment> {
    private let environment: Environment
    private let actions = PassthroughSubject<Action, Never>()
    private var cancellables = Set<AnyCancellable>()
    @Published public private(set) var state: State
    
    public init(initialState: State, environment: Environment, module: UIModuleValue<State, Action, Effect, Environment>) {
        self.state = initialState
        self.environment = environment
        
        let applySideEffect = { [weak self] (sideEffect: SideEffects<Effect>) -> Void in
            self?.applySideEffects(sideEffect, using: { module.sideEffectHandler($0, environment) })
        }
        
        actions.scan(initialState) { state, action in
            let sideEffects = SideEffects<Effect>()
            let newState = module.reducer(state, action, sideEffects)
            
            applySideEffect(sideEffects)

            return newState
        }
        .receive(on: RunLoop.main)
        .sink { [weak self] value in
            self?.state = value
        }.store(in: &cancellables)
    }
 
    public func apply(_ action: Action) {
        actions.send(action)
    }
}

extension Store: Storable {
    public var statePublisher: AnyPublisher<State, Never> { $state.eraseToAnyPublisher() }
}

private extension Store {
    func applySideEffects(_ sideEffect: SideEffects<Effect>, using sideEffectHandler: @escaping (Effect) -> AnyPublisher<Action, Never>) {
        var cancellable: AnyCancellable?
        cancellable = sideEffect.apply(using: sideEffectHandler)
            // If we don't make this receive on the main run loop, the actions
            //  resulting from the sideEffects will be applied before the initiating
            //  action is appliied.
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                _ = cancellable // silence the compiler warning about not being read

                cancellable = nil // we're done, so let go
            }, receiveValue: { [weak self] action in
                self?.apply(action)
            })
    }
}
