import Foundation
import AppStateKit
import SwiftUI

@Component
enum CounterComponent {
    struct State: Equatable {
        var count: Int
        var countText: String
    }
    
    private static func decrement(_ state: inout State, sideEffects: AnySideEffects<Action>) {
        state.count -= 1
        state.countText = "\(state.count)"
    }
    
    private static func increment(_ state: inout State, sideEffects: AnySideEffects<Action>) {
        state.count += 1
        state.countText = "\(state.count)"
    }

    @MainActor
    static func view(_ engine: ViewEngine<State, Action>) -> some View {
        VStack {
            HStack {
                Text("Count")
                
                Text(engine.countText)
            }
            
            HStack {
                Button("Decrement") {
                    engine.send(.decrement)
                }
                
                Button("Increment") {
                    engine.send(.increment)
                }
            }
            
            Spacer()
        }
    }
    
}

@Component
enum CounterListComponent {
    struct State {
        var name: String
        var counters: [CounterComponent.State]
    }
        
    @MainActor
    static func view(_ engine: ViewEngine<State, Action>) -> some View {
        ForEach(0..<engine.counters.count) { i in
            counters(engine, at: i)
        }
    }
}


@Component
enum CounterDictionaryComponent {
    struct State {
        var name: String
        var counters: [String: CounterComponent.State]
    }
        
    @MainActor
    static func view(_ engine: ViewEngine<State, Action>) -> some View {
        ForEach(engine.counters.keys.sorted(), id: \.self) { key in
            counters(engine, forKey: key)
        }
    }
}

