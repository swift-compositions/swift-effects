public import Clocks
public import Effects

extension Effect.Test.Recorder {

    public struct Invocation: Sendable {

        public let type: any Effect.`Protocol`.Type

        public let effect: any Effect.`Protocol` & Sendable

        public let timestamp: Clock.Continuous.Instant

        public let outcome: Outcome

        public init<Recorded: Effect.`Protocol`, Performed: Effect.`Protocol` & Sendable>(
            type: Recorded.Type,
            effect: Performed,
            timestamp: Clock.Continuous.Instant,
            outcome: Outcome
        ) {
            self.type = type
            self.effect = effect
            self.timestamp = timestamp
            self.outcome = outcome
        }
    }
}
