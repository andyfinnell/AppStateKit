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
