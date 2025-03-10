import Foundation
import AppStateKit
import SwiftUI
import BaseKit

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
        forEachCounters(engine)
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
        }
    }
}

@Component
enum CounterDictionaryComponent {
    struct State {
        var name: String
        var counters: [String: CounterComponent.State]
    }
        
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        forEachCounters(engine)
    }
}

@Component
enum CounterIdentifiableComponent {
    struct State {
        var name: String
        var counters: IdentifiableArray<CounterComponent.State>
    }
        
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        forEachCounters(engine)
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
            forEachScores(engine)
        }
    }
}

@Component
enum NamedComponent {
    struct State: Equatable {
        var name: String
        @Subscribe(to: GenerateNames.self)
        var nameSubscription: SubscriptionID? = nil
    }
        
    private static func nameSubscriptionUpdate(_ state: inout State, sideEffects: SideEffects, _ name: String) {
        state.name = name
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        HStack {
            Text(engine.name)
        }
    }
}

@Component
enum TestSettingsComponent {
    struct State: Equatable {
        var name: String
        var score: Int
        
        @SubscribeToJSONStorage(for: TestSettings.self)
        var testSettingsSubscription: SubscriptionID? = nil
    }
    
    private static func testSettingsSubscriptionUpdate(_ state: inout State, sideEffects: SideEffects, _ settings: TestSettings) {
        state.name = settings.name
        state.score = settings.score
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        HStack {
            Text(engine.name)
            
            Spacer()
            
            Text("\(engine.score)")
        }
    }

}

@Component
enum SimpleScoreboardComponent {
    struct State: Equatable {
        @BatchUpdatable(output: true) var scores: [Int]
    }
    
    enum ExtraOutput: Equatable {
        case beginEditing
        case endEditing
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        VStack {
            ForEach(engine.scores.indices, id: \.self) {
                Text("\($0)")
            }
        }
    }
}

@Component
enum NewBindingsComponent {
    struct State: Equatable {
        @Updatable var counter: Int = 0
        @Updatable var message: String = "Hi"
    }
    
    static func view(_ engine: ViewEngine<State, Action, Output>) -> some View {
        VStack {
            Text(engine.message)
        }
    }
}
