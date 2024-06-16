import Foundation
import SwiftUI

@MainActor
public protocol Component: BaseComponent {
    associatedtype ComponentView: View
        
    @ViewBuilder
    static func view(_ engine: ViewEngine<State, Action, Output>) -> ComponentView
}
