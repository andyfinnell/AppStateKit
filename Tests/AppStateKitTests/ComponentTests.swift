import Foundation
import AppStateKit
import SwiftUI

@Component
enum CounterComponent {
    struct State: Equatable, Identifiable {
        let id: UUID
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
        
    static func view(_ engine: ViewEngine<State, Action>) -> some View {
        ForEach(engine.counters.keys.sorted(), id: \.self) { key in
            counters(engine, forKey: key)
        }
    }
}

@Component
enum CounterIdentifiableComponent {
    struct State {
        var name: String
        var counters: IdentifiableArray<CounterComponent.State>
    }
        
    static func view(_ engine: ViewEngine<State, Action>) -> some View {
        ForEach(engine.counters.map { $0.id }, id: \.self) { id in
            counters(engine, byID: id)
        }
    }
}

@AppComponent
enum MyApp {
    struct State {
        var counters: CounterListComponent.State
    }
    
    static func initialState() -> State {
        State(counters: .init(
            name: "Main",
            counters: [
                .init(id: UUID(), count: 1, countText: "1"),
                .init(id: UUID(), count: 0, countText: "0"),
            ]
        ))
    }
    
    @Detachment
    enum Counter {
        static func initialState(_ state: State) -> CounterComponent.State {
            CounterComponent.State(id: UUID(), count: 0, countText: "0")
        }
    }
    
    static func scene(_ engine: ViewEngine<State, Action>) -> some Scene {
        WindowGroup {
            counters(engine)
        }
    }
}
