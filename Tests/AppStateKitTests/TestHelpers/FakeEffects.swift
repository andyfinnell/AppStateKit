import Foundation
import AppStateKit

struct LoadAtIndexEffect: Dependable {
    static func makeDefault(with space: DependencyScope) -> Effect<String, Never, Int> {
        Effect { index in
            Result.success("loaded index \(index)")
        }
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

struct UpdateEffect: Dependable {
    static func makeDefault(with space: DependencyScope) -> Effect<String, Never, Int, String> {
        Effect { index, content in
            Result.success("update \(content) to \(index)")
        }
    }
}
