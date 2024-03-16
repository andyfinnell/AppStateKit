import Foundation
import SwiftUI

// TODO: primary problem is that Action isn't in a relationship with anything
//  else, and can be anything.
//  However, to be generally usable, we don't want the Action in the type
//  until it gets down into a reducer.


// TODO: pass dependencies through Components, Effects wrap dependencies to make reducer testing simpler

// TODO: maybe EffectSpace? EffectIsolation? EffectsEnvironment?
final class EffectSink<Action> {
//    private let effects: Effects
    var futures = [FutureEffect<Action>]()
    
//    init(effects: Effects) {
//        self.effects = effects
//    }
//    
//    func callAsFunction(_ factory: (Effects) async -> Action) {
//        let effects = self.effects
//        let future = FutureEffect {
//            await factory(effects)
//        }
//        futures.append(future)
//    }
    
    func perform<each ParameterType, ReturnType, Failure: Error>(
        _ effect: Effect<ReturnType, Failure, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action,
        onFailure: @escaping (Failure) async -> Action) {
        let future = FutureEffect {
            switch await effect.perform(repeat each parameters) {
            case let .success(value):
                return await transform(value)
            case let .failure(error):
                return await onFailure(error)
            }
        }
        futures.append(future)
    }
    
    func perform<each ParameterType, ReturnType>(
        _ effect: Effect<ReturnType, Never, repeat each ParameterType>,
        with parameters: repeat each ParameterType,
        transform: @escaping (ReturnType) async -> Action) {
        let future = FutureEffect {
            switch await effect.perform(repeat each parameters) {
            case let .success(value):
                return await transform(value)
            }
        }
        futures.append(future)
    }

}

// TODO: really just want Effects to be a kind of dependency
struct UpdateNameEffect: Dependable {
    static func makeDefault(with space: DependencyScope) -> Effect<Void, Never, String> {
        Effect { (newName: String) -> Result<Void, Never> in
            
            return Result.success(())
        }
    }
}

enum TheLeafFeature {
    struct State: Identifiable {
        var id: String { name }
        var name: String
        var isOn: Bool
    }
    
    static func updateName(
        _ state: inout State,
        newName: String,
        updateName: Effect<Void, Never, String>,
        effects: EffectSink<Action>
    ) {
        state.name = newName
        
        effects.perform(updateName, with: newName) { _ in
            .nameUpdated
        }
    }
    
    static func nameUpdated(_ state: inout State) {
        
    }
    
    static func toggleOn(_ state: inout State) {
        state.isOn = true
    }
    
    static func toggleOff(_ state: inout State) {
        state.isOn = false
    }
    
    // TODO: in the real it'd be a Store
    @ViewBuilder
    static func view(_ state: State) -> some View {
        VStack {
            Text(state.name)
            
            Toggle(isOn: Binding(get: { state.isOn }, set: { _ in })) {
                Text("Is on")
            }
        }
    }
    
    // BEGIN: generated
    enum Action: Equatable {
        case updateName(newName: String)
        case toggleOn
        case toggleOff
        case nameUpdated
    }
    
    // TODO: how are we constructing Effects? want off dependencies, but how?
    struct Effects {
        let updateName: Effect<Void, Never, String>

        init(dependencies: DependencyScope) {
            updateName = UpdateNameEffect.makeDefault(with: dependencies)
        }
    }
    
    static func reduce(_ state: inout State, action: Action, dependencies: Effects, effects: EffectSink<Action>) {
        switch action {
        case let .updateName(newName: newName):
            updateName(&state, newName: newName, updateName: dependencies.updateName, effects: effects)
            
        case .toggleOn:
            toggleOn(&state)
            
        case .toggleOff:
            toggleOff(&state)
            
        case .nameUpdated:
            nameUpdated(&state)
        }
    }
    // END
    
}

// TODO: TheComposedFeature

enum TheComposedFeature {
    struct State {
        var leaves: [TheLeafFeature.State]
    }
    
    // TODO: in the real it'd be a Store
    @ViewBuilder
    static func view(_ state: State) -> some View {
        VStack {
            List(state.leaves) { leaf in
                // TODO: how to compose out a store?
                Text("huh")
            }
        }
    }
    
    // BEGIN: generated
    enum Action: Equatable {
        case leaves(TheLeafFeature.Action, at: Int)
    }
    
    struct Effects {
        let leaves: TheLeafFeature.Effects
    }
    
//    var reduce: some Reducer {
//        ArrayReducer(state: \State.leaves,
//                     action: ActionBinding(\Action.leaves),
//                     effects: \Effects.leaves) {
//            
//        }
//
//    }
    
    // END

}
