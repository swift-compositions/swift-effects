public import Effects

extension Effect {

    public struct Yield: Sendable {
        public init() {}
    }
}

extension Effect.Yield: Effect.`Protocol`, EffectWithHandler {
    public typealias Value = Void
    public typealias Failure = Never
    public typealias HandlerKey = Handler.Key
}

extension Effect.Yield {

    @inlinable
    public static func perform() async {
        await Effect.perform(Effect.Yield())
    }
}
