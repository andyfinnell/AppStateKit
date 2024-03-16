import Foundation

public struct ActionBinding<FromAction, ToAction> {
    let toAction: (FromAction) -> ToAction?
    let fromAction: (ToAction) -> FromAction
    
    public init(from: @escaping (ToAction) -> FromAction,
                to: @escaping (FromAction) -> ToAction?) {
        toAction = to
        fromAction = from
    }
}
