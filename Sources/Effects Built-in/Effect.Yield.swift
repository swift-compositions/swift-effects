#if EffectsBuiltin
    public import Effects

    extension Effect {

        public struct Yield: Effect.`Protocol`, EffectWithHandler, Sendable {
            public init() {}
        }
    }

    extension Effect.Yield {
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
#endif
