import Foundation
import SwiftUI

public protocol Component: BaseComponent {
    associatedtype ComponentView: View
        
    @MainActor
    @ViewBuilder
    static func view(_ engine: ViewEngine<State, Action>) -> ComponentView
}
