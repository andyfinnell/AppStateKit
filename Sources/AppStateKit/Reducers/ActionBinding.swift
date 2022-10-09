import Foundation

public struct ActionBinding<FromAction, ToAction> {
    let toAction: (FromAction) -> ToAction?
    let fromAction: (ToAction) -> FromAction

    public init(_ fromAction: @escaping (ToAction) -> FromAction) where FromAction: Extractable {
        toAction = FromAction.extractor(fromAction)
        self.fromAction = fromAction
    }
    
    public init(from: @escaping (ToAction) -> FromAction,
                to: @escaping (FromAction) -> ToAction?) {
        toAction = to
        fromAction = from
    }
}
