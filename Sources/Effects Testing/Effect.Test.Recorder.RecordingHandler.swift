public import Effects

extension Effect.Test.Recorder {
    public struct RecordingHandler<E: Effect.`Protocol`>: Sendable
    where E: Sendable, E.Value: Copyable & Sendable {
        private let recorder: Effect.Test.Recorder
        private let inner: Effect.Test.Handler<E>

        internal init(recorder: Effect.Test.Recorder, inner: Effect.Test.Handler<E>) {
            self.recorder = recorder
            self.inner = inner
        }


    }
}

extension Effect.Test.Recorder.RecordingHandler: Effect.Handler.`Protocol` {
    public typealias Handled = E
    public func handle(
        _ effect: borrowing E,
        continuation: consuming Effect.Continuation.One<E.Value, E.Failure>
    ) async {

        let recordedEffect = copy effect
        let wrapped = continuation.onResume { [recorder] result in
            let succeeded: Bool
            switch result {
            case .success: succeeded = true
            case .failure: succeeded = false
            }
            recorder.record(recordedEffect, succeeded: succeeded)
        }

        await inner.handle(effect, continuation: wrapped)
    }
}
