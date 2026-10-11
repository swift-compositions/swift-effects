public import Effects

extension Effect.Exit.Handler {

    public struct Key: Dependency.Key {}
}

extension Effect.Exit.Handler.Key {

    public static var liveValue: Effect.Exit.Handler { .live }

    public static var testValue: Effect.Exit.Handler {
        Effect.Exit.Handler { _ in
            let (suspension, continuation) = AsyncStream<Never>.makeStream()
            for await _ in suspension {}
            continuation.finish()
            await withCheckedContinuation { (_: CheckedContinuation<Never, Never>) in }
        }
    }
}
