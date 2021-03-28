import Foundation
import Combine

public final class SideEffect<Effect> {
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
    
    func combine<LocalEffect>(_ localEffects: SideEffect<LocalEffect>, using toGlobalEffect: (LocalEffect) -> Effect) {
        let newEffects = localEffects.effects.map { localSerial in
            Serial(effects: localSerial.effects.map { toGlobalEffect($0) })
        }
        effects.append(contentsOf: newEffects)
    }
    
    func apply<Action>(using sideEffectHandler: @escaping (Effect) -> AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> {
        Publishers.MergeMany(effects.map { $0.apply(using: sideEffectHandler) }).eraseToAnyPublisher()
    }
}

