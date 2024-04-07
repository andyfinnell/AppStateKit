import Foundation
import AppStateKit

enum TestError: Error {
    case importFailure
}

@Effect
enum LoadAtIndexEffect {
    static func perform(dependencies: DependencyScope, index: Int) -> String {
        "loaded index \(index)"
    }
}

@ExtendDependencyScope(with: LoadAtIndexEffect)
extension DependencyScope {}

@ExtendSideEffects(with: LoadAtIndexEffect, (index: Int) async -> String)
extension AnySideEffects {}

@Effect
enum SaveEffect {
    static func perform(dependencies: DependencyScope, index: Int, content: String) {
        // nop
    }
}

@ExtendDependencyScope(with: SaveEffect)
extension DependencyScope {}

@ExtendSideEffects(with: SaveEffect, (index: Int, content: String) -> Void)
extension AnySideEffects {}

@Effect
enum UpdateEffect {
    static func perform(dependencies: DependencyScope, index: Int, content: String) -> String {
        "update \(content) to \(index)"
    }
}

@ExtendDependencyScope(with: UpdateEffect)
extension DependencyScope {}

@ExtendSideEffects(with: UpdateEffect, (index: Int, content: String) -> String)
extension AnySideEffects {}

@Effect
enum TimerEffect {
    private actor CancelToken {
        private(set) var isCancelled = false
        
        func cancel() {
            isCancelled = true
        }
    }
    
    static func perform(dependencies: DependencyScope, delay: TimeInterval, count: Int) -> AsyncStream<TimeInterval> {
        var lastTime: TimeInterval = 0.0
        var iteration = 0
        let cancelToken = CancelToken()
        let stream = AsyncStream { () -> TimeInterval? in
            guard await !cancelToken.isCancelled, iteration < count else {
                return nil
            }
            let v = lastTime
            lastTime += delay
            iteration += 1
            return v
        } onCancel: {
            Task {
                await cancelToken.cancel()
            }
        }

        return stream
    }
}

@ExtendDependencyScope(with: TimerEffect)
extension DependencyScope {}

@ExtendSideEffects(with: TimerEffect, (delay: TimeInterval, count: Int) -> AsyncStream<TimeInterval>)
extension AnySideEffects {}

@Effect
enum GenerateEffect {
    static func perform(dependencies: DependencyScope) -> String {
        "number 9"
    }
}

@ExtendDependencyScope(with: GenerateEffect)
extension DependencyScope {}

@ExtendSideEffects(with: GenerateEffect, () -> String)
extension AnySideEffects {}

@Effect
enum ImportURLEffect {
    static func perform(dependencies: DependencyScope, _ url: URL) async throws -> String {
        throw TestError.importFailure
    }
}

@ExtendDependencyScope(with: ImportURLEffect)
extension DependencyScope {}

@ExtendSideEffects(with: ImportURLEffect, (URL) async throws -> String)
extension AnySideEffects {}
