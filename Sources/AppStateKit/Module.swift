import Foundation
import SwiftUI

public protocol Module: Reducer, View {
    typealias Store = ViewStore<State, Action>
    
    var store: ViewStore<State, Action> { get }
    
}

