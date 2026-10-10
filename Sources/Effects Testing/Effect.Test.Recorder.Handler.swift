public import Effect

extension Effect.Test.Recorder {
    public struct Handler<E: Effect.`Protocol`>: Sendable
    where E: Sendable, E.Value: Copyable & Sendable {
        private let recorder: Effect.Test.Recorder
        private let inner: Effect.Test.Handler<E>

        internal init(recorder: Effect.Test.Recorder, inner: Effect.Test.Handler<E>) {
            self.recorder = recorder
            self.inner = inner
        }


    }
}

extension Effect.Test.Recorder.Handler: Effect.Handler.`Protocol` {
    public typealias Handled = E
    public func handle(
        _ effect: borrowing E,
        continuation: consuming Effect.Continuation.One<E.Value, E.Failure>
    ) async {

        let recordedEffect = copy effect
        let wrapped = continuation.onResume { [recorder] result in
            let status: Effect.Test.Recorder.Invocation.Status
            switch result {
            case .success: status = .success
            case .failure: status = .failure
            }
            recorder.record(recordedEffect, status: status)
        }

        await inner.handle(effect, continuation: wrapped)
    }
}
