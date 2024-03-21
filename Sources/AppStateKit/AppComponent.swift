import Foundation
import SwiftUI

public protocol AppComponent: BaseComponent {
    associatedtype ComponentScene: Scene
        
    static func initialState() -> State
    static func dependencies() -> DependencyScope
    
    @MainActor
    @SceneBuilder
    static func scene(_ engine: ViewEngine<State, Action>) -> ComponentScene
}

public extension AppComponent {
    static func dependencies() -> DependencyScope {
        DependencyScope()
    }
}
