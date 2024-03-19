import Foundation
import SwiftUI

public protocol Component {
    associatedtype State
    associatedtype Action
    associatedtype ComponentView: View
    
    static func reduce(_ state: inout State, action: Action, sideEffects: AnySideEffects<Action>)
    
    @MainActor
    @ViewBuilder
    static func view(_ engine: ViewEngine<State, Action>) -> ComponentView
}
