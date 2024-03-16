import Foundation
import AppStateKit
import SwiftUI

struct CounterModule: Module {
    struct State: Equatable {
        var count: Int
        var countText: String
    }
    
    enum Action: Equatable {
        case increment
        case decrement
    }
    
    struct Effects {}
    
    @StateObject var store: ViewStore<State, Action>
        
    var body: some View {
        VStack {
            HStack {
                Text("Count")
                
                Text(store.countText)
            }
            
            HStack {
                Button("Decrement") {
                    store.apply(.decrement)
                }
                
                Button("Increment") {
                    store.apply(.increment)
                }
            }
            
            Spacer()
        }
    }
    
    func reduce(_ state: inout State, action: Action, effects: Effects, sideEffects: AnySideEffects<Action>) {
        switch action {
        case .decrement:
            state.count -= 1
            state.countText = "\(state.count)"
            
        case .increment:
            state.count += 1
            state.countText = "\(state.count)"
        }
    }
}
