import Foundation
import Combine

@resultBuilder
public struct SideEffectsBuider {
    static func buildBlock<ReturnType>(_ components: FutureEffect<ReturnType>...) -> SideEffects2<ReturnType> {
        SideEffects2(effects: components)
    }
}

public struct SideEffects2<ReturnType> {
    private let effects: [FutureEffect<ReturnType>]
    
    init(effects: [FutureEffect<ReturnType>]) {
        self.effects = effects
    }
    
    public init(@SideEffectsBuider _ builder: () -> SideEffects2<ReturnType>) {
        self.effects = builder().effects
    }
    
    public static func none() -> SideEffects2<ReturnType> {
        SideEffects2(effects: [])
    }
    
    func appending<FromAction>(_ other: SideEffects2<FromAction>, using transform: @escaping (FromAction) -> ReturnType) -> SideEffects2<ReturnType> {
        let transformedEffects = other.effects.map { $0.map(transform) }
        return SideEffects2(effects: effects + transformedEffects)
    }
    
    func map<ToAction>(_ transform: @escaping (ReturnType) -> ToAction) -> SideEffects2<ToAction> {
        SideEffects2<ToAction>(effects: effects.map { $0.map(transform) })
    }

    func apply(using send: @escaping (ReturnType) async -> Void) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for effect in effects {
                taskGroup.addTask {
                    let action = await effect.call()
                    await send(action)
                }
            }
        }
    }

    static func +(lhs: SideEffects2, rhs: SideEffects2) -> SideEffects2 {
        SideEffects2(effects: lhs.effects + rhs.effects)
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

