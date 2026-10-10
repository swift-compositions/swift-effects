public import Effects
public import Effect

extension Effect {

    public struct Yield: Sendable {
        public init() {}
    }
}

extension Effect.Yield: Effect.`Protocol`, Effect.Handled.`Protocol` {
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
