import Foundation
import AppStateKit

struct LoadAtIndexEffect: Dependable {
    static func makeDefault(with space: DependencyScope) -> Effect<String, Never, Int> {
        Effect { index in
            Result.success("loaded index \(index)")
        }
    }
}

extension DependencyScope {
    var loadAtIndex: LoadAtIndexEffect.T {
        self[LoadAtIndexEffect.self]
    }
}

struct SaveEffect: Dependable {
    static func makeDefault(with space: DependencyScope) -> Effect<Void, Never, Int, String> {
        Effect { index, content in
            // nop
            Result.success(())
        }
    }
}

extension DependencyScope {
    var save: SaveEffect.T {
        self[SaveEffect.self]
    }
}

struct UpdateEffect: Dependable {
    static func makeDefault(with space: DependencyScope) -> Effect<String, Never, Int, String> {
        Effect { index, content in
            Result.success("update \(content) to \(index)")
        }
    }
}

extension DependencyScope {
    var update: UpdateEffect.T {
        self[UpdateEffect.self]
    }
}

struct TimerEffect: Dependable {
    private actor CancelToken {
        private(set) var isCancelled = false
        
        func cancel() {
            isCancelled = true
        }
    }
    
    static func makeDefault(with space: DependencyScope) -> Effect<AsyncStream<TimeInterval>, Never, TimeInterval, Int> {
        Effect { delay, count in
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

            return Result.success(stream)
        }
    }
}

extension DependencyScope {
    var timer: TimerEffect.T {
        self[TimerEffect.self]
    }
}
