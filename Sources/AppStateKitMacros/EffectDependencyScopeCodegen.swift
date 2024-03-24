import SwiftSyntax
import SwiftSyntaxBuilder

struct EffectDependancyScopeCodegen {
    static func codegen(from effect: Effect) -> DeclSyntax? {
        let decl: DeclSyntax = """
            extension DependencyScope {
                var \(raw: effect.methodName): \(raw: effect.typename).T {
                    self[\(raw: effect.typename).self]
                }
            }
            """
        return decl
    }
}
