import Foundation
import AppStateKit

protocol LoadAtIndexEffect {
    func callAsFunction(index: Int) -> FutureEffect<String>
}

protocol SaveEffect {
    func callAsFunction(index: Int, content: String) -> FutureEffect<Void>
}

protocol UpdateEffect {
    func callAsFunction(index: Int, content: String) -> FutureEffect<String>
}

struct LoadAtIndexEffectHandler: LoadAtIndexEffect {
    func callAsFunction(index: Int) -> FutureEffect<String> {
        .init {
            "loaded index \(index)"
        }
    }
}

struct SaveEffectHandler: SaveEffect {
    func callAsFunction(index: Int, content: String) -> FutureEffect<Void> {
        .init {
            // nop
        }
    }
}

struct UpdateEffectHandler: UpdateEffect {
    func callAsFunction(index: Int, content: String) -> FutureEffect<String> {
        .init {
            "update \(content) to \(index)"
        }
    }
}
