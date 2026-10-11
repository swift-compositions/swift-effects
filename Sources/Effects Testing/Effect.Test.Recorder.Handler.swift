public import Effects

extension Effect.Test.Recorder {

    public struct Handler<E: Effect.`Protocol`>: Effect.Handler.`Protocol`, Sendable
    where E: Sendable, E.Value: Copyable & Sendable {
        private let recorder: Effect.Test.Recorder
        private let inner: Effect.Test.Handler<E>

        internal init(recorder: Effect.Test.Recorder, inner: Effect.Test.Handler<E>) {
            self.recorder = recorder
            self.inner = inner
        }
    }
}

extension Effect.Test.Recorder.Handler {

    public func handle(
        _ effect: borrowing E,
        continuation: consuming Effect.Continuation.One<E.Value, E.Failure>
    ) async {

        let recordedEffect = copy effect
        let wrapped = continuation.onResume { [recorder] result in
            recorder.record(
                recordedEffect,
                outcome: Effect.Test.Recorder.Invocation.Outcome(result)
            )
        }

        await inner.handle(effect, continuation: wrapped)
    }
}
