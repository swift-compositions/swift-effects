public import Effects

extension Effect.Yield.Handler {

    public struct Key {}
}

extension Effect.Yield.Handler.Key: Dependency.Key {
    public typealias Value = Effect.Yield.Handler

    public static var liveValue: Effect.Yield.Handler { .live }
    public static var testValue: Effect.Yield.Handler { .live }
}
