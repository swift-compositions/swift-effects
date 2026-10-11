public import Effects

extension Effect {

    public struct Exit: Effect.`Protocol`, EffectWithHandler, Sendable {

        public let code: Int32

        public init(code: Int32) {
            self.code = code
        }
    }
}

extension Effect.Exit {
    public typealias Value = Never
    public typealias Failure = Never
    public typealias HandlerKey = Handler.Key
}

extension Effect.Exit {

    @inlinable
    public static func perform(code: Int32) async -> Never {
        await Effect.perform(Effect.Exit(code: code))
    }
}
