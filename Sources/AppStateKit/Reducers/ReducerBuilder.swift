import Foundation

@resultBuilder
public struct ReducerBuilder {
    public static func buildBlock<S, A, E>() -> EmptyReducer<S, A, E> {
        EmptyReducer()
    }
    
    public static func buildBlock<R0: Reducer>(_ reducer: R0) -> R0 {
        reducer
    }
    
    public static func buildBlock<R0: Reducer, R1: Reducer>(
        _ r0: R0, _ r1: R1
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }
    
    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer, R3: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects,
          R0.State == R3.State, R0.Action == R3.Action, R0.Effects == R3.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r3.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer, R3: Reducer, R4: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects,
          R0.State == R3.State, R0.Action == R3.Action, R0.Effects == R3.Effects,
          R0.State == R4.State, R0.Action == R4.Action, R0.Effects == R4.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r3.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r4.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer, R3: Reducer, R4: Reducer, R5: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects,
          R0.State == R3.State, R0.Action == R3.Action, R0.Effects == R3.Effects,
          R0.State == R4.State, R0.Action == R4.Action, R0.Effects == R4.Effects,
          R0.State == R5.State, R0.Action == R5.Action, R0.Effects == R5.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r3.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r4.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r5.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer, R3: Reducer, R4: Reducer, R5: Reducer, R6: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects,
          R0.State == R3.State, R0.Action == R3.Action, R0.Effects == R3.Effects,
          R0.State == R4.State, R0.Action == R4.Action, R0.Effects == R4.Effects,
          R0.State == R5.State, R0.Action == R5.Action, R0.Effects == R5.Effects,
          R0.State == R6.State, R0.Action == R6.Action, R0.Effects == R6.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r3.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r4.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r5.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r6.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer, R3: Reducer, R4: Reducer, R5: Reducer, R6: Reducer, R7: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6, _ r7: R7
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects,
          R0.State == R3.State, R0.Action == R3.Action, R0.Effects == R3.Effects,
          R0.State == R4.State, R0.Action == R4.Action, R0.Effects == R4.Effects,
          R0.State == R5.State, R0.Action == R5.Action, R0.Effects == R5.Effects,
          R0.State == R6.State, R0.Action == R6.Action, R0.Effects == R6.Effects,
          R0.State == R7.State, R0.Action == R7.Action, R0.Effects == R7.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r3.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r4.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r5.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r6.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r7.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer, R3: Reducer, R4: Reducer, R5: Reducer, R6: Reducer, R7: Reducer, R8: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6, _ r7: R7, _ r8: R8
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects,
          R0.State == R3.State, R0.Action == R3.Action, R0.Effects == R3.Effects,
          R0.State == R4.State, R0.Action == R4.Action, R0.Effects == R4.Effects,
          R0.State == R5.State, R0.Action == R5.Action, R0.Effects == R5.Effects,
          R0.State == R6.State, R0.Action == R6.Action, R0.Effects == R6.Effects,
          R0.State == R7.State, R0.Action == R7.Action, R0.Effects == R7.Effects,
          R0.State == R8.State, R0.Action == R8.Action, R0.Effects == R8.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r3.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r4.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r5.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r6.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r7.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r8.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

    public static func buildBlock<R0: Reducer, R1: Reducer, R2: Reducer, R3: Reducer, R4: Reducer, R5: Reducer, R6: Reducer, R7: Reducer, R8: Reducer, R9: Reducer>(
        _ r0: R0, _ r1: R1, _ r2: R2, _ r3: R3, _ r4: R4, _ r5: R5, _ r6: R6, _ r7: R7, _ r8: R8, _ r9: R9
    ) -> AnonymousReducer<R0.State, R0.Action, R0.Effects>
    where R0.State == R1.State, R0.Action == R1.Action, R0.Effects == R1.Effects,
          R0.State == R2.State, R0.Action == R2.Action, R0.Effects == R2.Effects,
          R0.State == R3.State, R0.Action == R3.Action, R0.Effects == R3.Effects,
          R0.State == R4.State, R0.Action == R4.Action, R0.Effects == R4.Effects,
          R0.State == R5.State, R0.Action == R5.Action, R0.Effects == R5.Effects,
          R0.State == R6.State, R0.Action == R6.Action, R0.Effects == R6.Effects,
          R0.State == R7.State, R0.Action == R7.Action, R0.Effects == R7.Effects,
          R0.State == R8.State, R0.Action == R8.Action, R0.Effects == R8.Effects,
          R0.State == R9.State, R0.Action == R9.Action, R0.Effects == R9.Effects {
        AnonymousReducer { state, action, effects, sideEffects in
            r0.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r1.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r2.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r3.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r4.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r5.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r6.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r7.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r8.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
            r9.reduce(&state, action: action, effects: effects, sideEffects: sideEffects)
        }
    }

}
