#if EffectsBuiltin
    public import Effects

    extension Effect.Yield.Handler {

        public struct Key: Dependency.Key {}
    }

    extension Effect.Yield.Handler.Key {

        public static var liveValue: Effect.Yield.Handler { .live }
        public static var testValue: Effect.Yield.Handler { .live }
    }
#endif
