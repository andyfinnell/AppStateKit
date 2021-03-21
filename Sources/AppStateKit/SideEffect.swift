import Foundation
import Combine

public final class SideEffect<Environment, Action> {
    private var actionFactories = [(Environment) -> AnyPublisher<Action, Never>]()
    
    init() {
    }
    
    public func callAsFunction(_ action: Action) {
        actionFactories.append({ _ in Just(action).eraseToAnyPublisher() })
    }
    
    public func callAsFunction(_ factory: @escaping (Environment) -> Action) {
        actionFactories.append({ environment in
            Just(factory(environment)).eraseToAnyPublisher()
        })
    }
    
    public func callAsFunction(_ factory: @escaping (Environment) -> AnyPublisher<Action, Never>) {
        actionFactories.append(factory)
    }
    
    func apply(in environment: Environment) -> AnyPublisher<Action, Never> {
        let publishers = actionFactories.map { $0(environment) }
        return Publishers.MergeMany(publishers).eraseToAnyPublisher()
    }
    
    func combine<LocalEnvironment, LocalAction>(
        _ sideEffect: SideEffect<LocalEnvironment, LocalAction>,
        toLocalEnvironment: @escaping (Environment) -> LocalEnvironment,
        toGlobalAction: @escaping (LocalAction) -> Action) {
        let factory = { (env: Environment) -> AnyPublisher<Action, Never> in
            let localEnv = toLocalEnvironment(env)
            return sideEffect.apply(in: localEnv)
                .map(toGlobalAction)
                .eraseToAnyPublisher()
        }
        actionFactories.append(factory)
    }
    
    func combine<LocalAction>(
        _ sideEffect: SideEffect<Environment, LocalAction>,
        toGlobalAction: @escaping (LocalAction) -> Action) {
        let factory = { (env: Environment) -> AnyPublisher<Action, Never> in
            return sideEffect.apply(in: env)
                .map(toGlobalAction)
                .eraseToAnyPublisher()
        }
        actionFactories.append(factory)
    }

}
