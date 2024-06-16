import Foundation
import SwiftUI

@MainActor
public protocol AppComponent: BaseComponent {
    associatedtype ComponentScene: Scene
        
    static func initialState() -> State
    static func dependencies() -> DependencyScope
    
    @SceneBuilder
    static func scene(_ engine: ViewEngine<State, Action, Output>) -> ComponentScene
}

public extension AppComponent {
    static func dependencies() -> DependencyScope {
        DependencyScope()
    }
}
