@MainActor
final class DetachedSender {
    private var refs = [ObjectIdentifier: [any DetachedRef]]()
    
    init() {}
    
    func attach<D: Detachment>(_ sender: some ActionSender<D.DetachedAction>, at key: D.Type) {
        compact()
        refs[ObjectIdentifier(D.self), default: []].append(Ref(sender: sender))
    }

    func send<D: Detachment>(_ action: D.DetachedAction, to key: D.Type) {
        compact()
        guard let refs = self.refs[ObjectIdentifier(D.self)] else {
            return
        }
        for ref in refs {
            ref.send(action)
        }
    }
}

@MainActor
private protocol DetachedRef {
    var isValid: Bool { get }
    
    func send<A: Sendable>(_ action: A)
}

private extension DetachedSender {
    @MainActor
    struct Ref<Action: Sendable>: DetachedRef {
        weak var sender: (any ActionSender<Action>)?
                
        var isValid: Bool {
            sender != nil
        }
        
        func send<A: Sendable>(_ action: A) {
            guard let realAction = action as? Action else {
                return
            }
            sender?.send(realAction)
        }
    }
    
    func compact() {
        refs = refs.compactMapValues { value in
            let newValue = value.filter { $0.isValid }
            return newValue.isEmpty ? nil : newValue
        }
    }
}
