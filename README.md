# swift-effects

Use this package when you describe a side effect as a value and want to perform it from ordinary async code, with the handler picked by the surrounding `Effect.Context` so a test can swap it. Conform the effect to `EffectWithHandler`, point its `HandlerKey` at a handler, and call `Effect.perform(_:)`. The Effects Built-in product adds `Effect.Exit` and `Effect.Yield`. For tests, the Effects Testing product has `Effect.Test.Handler<E>` for canned answers, `Effect.Test.Spy<E>` to watch one effect type and `Effect.Test.Recorder` to watch several on one timeline. If you only need the effect, handler and continuation vocabulary without performing through a context, use swift-effect.

## Laws

- `Effect.perform(_:)` reads the handler from `Effect.Context.current` under the effect's `HandlerKey` when it is called, so the innermost scope that sets that key wins.
- The handler runs in a new task, not in the caller's task. Cancelling the caller cancels that task, even when cancellation arrives before that task exists.
- Cancellation never ends a perform by itself. `Effect.perform(_:)` returns only when the handler resumes its continuation, so a handler that ignores cancellation keeps the caller waiting.
- `Effect.Exit.Handler.live` ends the process normally with the effect's `code`. The test value of `Effect.Exit.Handler.Key` suspends for ever and never returns, even when cancelled.
- `Effect.Yield.Handler.live` calls `Task.yield()`, and it is the test value as well.
- `Effect.Test.Spy<E>` and `Effect.Test.Recorder` record an invocation when the handler resumes its continuation, not when it is called. Invocations are kept in that order, timestamped with the continuous clock at that moment. A handler that never resumes leaves no record.
- `Effect.Test.Recorder.Invocation.Outcome` keeps only whether the handler succeeded or failed. `Effect.Test.Spy.Invocation` keeps the full `Effect.Outcome`.
