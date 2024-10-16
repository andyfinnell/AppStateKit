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
    
    private static func decrement(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
        state.count -= 1
        state.countText = "\(state.count)"
    }
    
    private static func increment(_ state: inout State, sideEffects: AnySideEffects<Action, Output>) {
        state.count += 1
        state.countText = "\(state.count)"
    }

    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
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
        
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        ForEach(0..<engine.counters.count) { i in
            counters(engine, at: i)
        }
    }
}

@Component
enum CounterOptionalComponent {
    struct State {
        var name: String
        @Updatable var counter: CounterComponent.State?
    }
        
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        VStack {
            Text("Hello")
        }.sheet(isPresented: #bindIfPresent(engine, \.counter), content: {
            Text("Hellow again")
        })
    }
}

@Component
enum CounterDictionaryComponent {
    struct State {
        var name: String
        var counters: [String: CounterComponent.State]
    }
        
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
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
        
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
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
    
    static func scene(_ engine: ViewEngine<State, Action, Output>) -> some Scene {
        WindowGroup {
            counters(engine)
        }
    }
}

@Component
enum ScoreComponent {
    struct State: Equatable {
        @Updatable(output: true) var score: Int
        @Updatable(output: true) var name: String
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        VStack {
            HStack {
                Text("Name")
                
                Spacer()
                
                Text(engine.name)
            }
            
            HStack {
                Text("Score")
                
                Spacer()
                
                Text("\(engine.score)")
            }
            
            Spacer()
        }
    }
}

@Component
enum PlayerComponent {
    struct State: Equatable {
        @PassthroughOutput var score: ScoreComponent.State
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        VStack {
            score(engine)
        }
    }
}

@Component
enum ScoreboardComponent {
    struct State: Equatable {
        @PassthroughOutput var scores: [ScoreComponent.State]
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        VStack {
            ForEach(engine.scores.indices, id: \.self) {
                scores(engine, at: $0)
            }
        }
    }
}

@Component
enum NamedComponent {
    struct State: Equatable {
        @Updatable var name: String
        @Subscribe(to: GenerateNames.self, sending: ".updateName")
        var nameSubscription: SubscriptionID? = nil
    }
        
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        HStack {
            Text(engine.name)
        }
    }
}
