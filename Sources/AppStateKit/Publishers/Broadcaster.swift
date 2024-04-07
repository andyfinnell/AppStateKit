
final class Broadcaster<Output> {
    private var refs = [Ref]()
    
    init() {
    }
    
    func didChange(to newState: Output) {
        compact()
        for ref in refs {
            ref.didChange(newState)
        }
    }
    
    func subscribe(_ sink: Sink<Output>) {
        compact()
        refs.append(Ref(sink: sink))
    }
}

private extension Broadcaster {
    final class Ref {
        private weak var sink: Sink<Output>?
        
        init(sink: Sink<Output>) {
            self.sink = sink
        }
        
        func didChange(_ state: Output) {
            sink?.onChange(state)
        }
        
        var isInvalid: Bool { sink == nil }
    }
    
    func compact() {
        refs.removeAll { $0.isInvalid }
    }
}

