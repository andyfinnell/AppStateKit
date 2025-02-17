
public enum TranslateResult<Action: Sendable, Output> {
    case perform(Action)
    case passThrough(Output)
    case drop
}
