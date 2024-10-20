import Foundation
import AppStateKit
import BaseKit

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
    
    private actor Counter {
        var lastTime: TimeInterval = 0.0
        var iteration = 0

        func next(delay: TimeInterval) -> TimeInterval {
            let v = lastTime
            lastTime += delay
            iteration += 1
            return v
        }
    }
    
    static func perform(dependencies: DependencyScope, delay: TimeInterval, count: Int) -> AsyncStream<TimeInterval> {
        let cancelToken = CancelToken()
        let counter = Counter()
        let stream = AsyncStream { () -> TimeInterval? in
            guard await !cancelToken.isCancelled, await counter.iteration < count else {
                return nil
            }
            return await counter.next(delay: delay)
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

struct TestModel: Codable, Equatable {
    let name: String
    let score: Int
    
    @Sendable
    static func defaultValue() -> TestModel {
        TestModel(name: "Bob", score: 42)
    }
}

@JSONStorageEffects(for: TestModel.self, defaultValue: TestModel.defaultValue())
extension AnySideEffects {}

struct TestSettings: Codable, Equatable {
    let name: String
    let score: Int
}

@JSONStorageEffects(for: TestSettings.self)
extension AnySideEffects {}

@Effect
enum GenerateNames {
    private actor CancelToken {
        private(set) var isCancelled = false
        
        func cancel() {
            isCancelled = true
        }
    }
    
    private actor NameList {
        private let names = ["Alice", "Bob", "Ethel", "Jim"]

        func next() -> String {
            names.randomElement() ?? "Spanish Inquisition"
        }
    }
    
    static func perform(dependencies: DependencyScope) -> AsyncStream<String> {
        let cancelToken = CancelToken()
        let nameList = NameList()
        let stream = AsyncStream { () -> String? in
            guard await !cancelToken.isCancelled else {
                return nil
            }
            do {
                try await Task.sleep(nanoseconds: 500 * UInt64(1e6))
            } catch {
                return nil
            }
            return await nameList.next()
        } onCancel: {
            Task {
                await cancelToken.cancel()
            }
        }
        return stream
    }
}

@ExtendDependencyScope(with: GenerateNames)
extension DependencyScope {}

@ExtendSideEffects(with: GenerateNames, () -> AsyncStream<String>)
extension AnySideEffects {}
