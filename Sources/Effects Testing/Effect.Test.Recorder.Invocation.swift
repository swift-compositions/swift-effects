public import Clocks
public import Effects

extension Effect.Test.Recorder {

    public struct Invocation: Sendable {

        public let effectType: any Effect.`Protocol`.Type

        public let effect: any Effect.`Protocol` & Sendable

        public let timestamp: Clock.Continuous.Instant

        public let succeeded: Bool

        public init<Recorded: Effect.`Protocol`, Performed: Effect.`Protocol` & Sendable>(
            effectType: Recorded.Type,
            effect: Performed,
            timestamp: Clock.Continuous.Instant,
            succeeded: Bool
        ) {
            self.effectType = effectType
            self.effect = effect
            self.timestamp = timestamp
            self.succeeded = succeeded
        }
    }

}
