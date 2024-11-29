@MainActor
struct FutureDetachedAction: Sendable {
    private let callThunk: @MainActor (DetachedSender) -> Void
    
    init<D: Detachment>(action: D.DetachedAction, target: D.Type) {
        callThunk = { sender in
            sender.send(action, to: target)
        }
    }
    
    func call(with sender: DetachedSender) {
        callThunk(sender)
    }
}
