import Foundation
import Combine

@resultBuilder
public struct SideEffectsBuider {
    public static func buildBlock<ReturnType>(_ components: FutureEffect<ReturnType>...) -> SideEffects<ReturnType> {
        SideEffects(effects: components)
    }
}

public struct SideEffects<ReturnType> {
    private let effects: [FutureEffect<ReturnType>]
    
    init(effects: [FutureEffect<ReturnType>]) {
        self.effects = effects
    }
    
    public init(@SideEffectsBuider _ builder: () -> SideEffects<ReturnType>) {
        self.effects = builder().effects
    }
    
    public static var none: SideEffects<ReturnType> {
        SideEffects(effects: [])
    }
    
    func appending<FromAction>(_ other: SideEffects<FromAction>, using transform: @escaping (FromAction) -> ReturnType) -> SideEffects<ReturnType> {
        let transformedEffects = other.effects.map { $0.map(transform) }
        return SideEffects(effects: effects + transformedEffects)
    }
    
    func map<ToAction>(_ transform: @escaping (ReturnType) -> ToAction) -> SideEffects<ToAction> {
        SideEffects<ToAction>(effects: effects.map { $0.map(transform) })
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

    static func +(lhs: SideEffects, rhs: SideEffects) -> SideEffects {
        SideEffects(effects: lhs.effects + rhs.effects)
    }
}
