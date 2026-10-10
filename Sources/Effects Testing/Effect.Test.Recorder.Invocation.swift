public import Clocks
public import Effect

extension Effect.Test.Recorder {

    public struct Invocation: Sendable {

        public let type: any Effect.`Protocol`.Type

        public let effect: any Effect.`Protocol` & Sendable

        public let timestamp: Clock.Continuous.Instant

        public let status: Status

        public init<Recorded: Effect.`Protocol`, Performed: Effect.`Protocol` & Sendable>(
            type: Recorded.Type,
            effect: Performed,
            timestamp: Clock.Continuous.Instant,
            status: Status
        ) {
            self.type = type
            self.effect = effect
            self.timestamp = timestamp
            self.status = status
        }
    }

}

extension Effect.Test.Recorder.Invocation {
    public var succeeded: Bool { status == .success }
}
