import Foundation
import Combine

@dynamicMemberLookup
public final class SideEffects2<Effects, Action> {
    private var effects = [AnyCapturedEffect]()
    private let environment: Effects
    
    init(environment: Effects) {
        self.environment = environment
    }
    
    public struct Callable<Parameters> {
        private let closure: (Parameters) -> Void
        
        fileprivate init(_ closure: @escaping (Parameters) -> Void) {
            self.closure = closure
        }
        
        public func callAsFunction(_ parameters: Parameters) {
            closure(parameters)
        }
    }

    public struct CallableWithTransform<Parameters, ReturnType> {
        private let closure: (Parameters, @escaping (ReturnType) -> Action) -> Void
        
        fileprivate init(_ closure: @escaping (Parameters, @escaping (ReturnType) -> Action) -> Void) {
            self.closure = closure
        }
        
        public func callAsFunction(_ parameters: Parameters, _ transform: @escaping (ReturnType) -> Action) {
            closure(parameters, transform)
        }
    }

    public subscript<P>(dynamicMember keyPath: KeyPath<Effects, EffectDecl<P, Action>>) -> Callable<P> {
        Callable { parameters in
            self.effects.append(AnyCapturedEffect(self.environment[keyPath: keyPath](parameters)))
        }
    }

    public subscript<P, R>(dynamicMember keyPath: KeyPath<Effects, EffectDecl<P, R>>) -> CallableWithTransform<P, R> {
        CallableWithTransform { parameters, transform in
            self.effects.append(AnyCapturedEffect(self.environment[keyPath: keyPath](parameters), transform: transform))
        }
    }
    
    func append<FromEffects, FromAction>(_ other: SideEffects2<FromEffects, FromAction>, using transform: @escaping (FromAction) -> Action) {
        let transformedEffects = other.effects.map { AnyCapturedEffect($0, transform: transform) }
        effects.append(contentsOf: transformedEffects)
    }
    
    func apply(using send: @escaping (Action) async -> Void) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for effect in effects {
                taskGroup.addTask {
                    let action = await effect.call()
                    await send(action)
                }
            }
        }
    }
}

private extension SideEffects2 {
    struct AnyCapturedEffect: CapturedEffect {
        typealias ReturnType = Action
        private let thunk: () async -> Action
        
        init<T: CapturedEffect>(_ effect: T) where T.ReturnType == Action {
            thunk = { await effect.call() }
        }
        
        init<T: CapturedEffect>(_ effect: T, transform: @escaping (T.ReturnType) -> Action) {
            thunk = { await transform(effect.call()) }
        }

        func call() async -> Action {
            await thunk()
        }
    }

}

public final class SideEffects<Effect> {
    struct Serial {
        let effects: [Effect]
        
        fileprivate func apply<Action>(using sideEffectHandler: @escaping (Effect) -> AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
            SerialPublisher(input: effects, factory: sideEffectHandler).eraseToAnyPublisher()
        }
    }
    
    private(set) var effects = [Serial]()
    
    init() {
    }
    
    public func callAsFunction(_ effects: Effect...) {
        self.effects.append(Serial(effects: effects))
    }
    
    func combine<LocalEffect>(_ localEffects: SideEffects<LocalEffect>, using toGlobalEffect: (LocalEffect) -> Effect) {
        let newEffects = localEffects.effects.map { localSerial in
            Serial(effects: localSerial.effects.map { toGlobalEffect($0) })
        }
        effects.append(contentsOf: newEffects)
    }
    
    func apply<Action>(using sideEffectHandler: @escaping (Effect) -> AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
        Publishers.MergeMany(effects.map { $0.apply(using: sideEffectHandler) }).eraseToAnyPublisher()
    }
}

