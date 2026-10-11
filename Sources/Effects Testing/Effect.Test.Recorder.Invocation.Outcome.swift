public import Effects

extension Effect.Test.Recorder.Invocation {

    public enum Outcome: Sendable, Hashable {
        case success
        case failure
    }
}

extension Effect.Test.Recorder.Invocation.Outcome {

    internal init<Value, Failure>(_ result: Result<Value, Failure>) {
        self =
            switch result {
            case .success: .success
            case .failure: .failure
            }
    }
}
