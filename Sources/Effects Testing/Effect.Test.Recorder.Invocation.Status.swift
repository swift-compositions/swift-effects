public import Effect

extension Effect.Test.Recorder.Invocation {
    public enum Status: Sendable, Equatable {
        case success
        case failure
    }
}
