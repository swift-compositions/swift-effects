public import Clocks
public import Effects

extension Effect.Test.Spy {
    public struct Invocation: Sendable {

        public let effect: E

        public let timestamp: Clock.Continuous.Instant

        public let outcome: Effect.Outcome<E.Value, E.Failure>

        public init(
            effect: E,
            timestamp: Clock.Continuous.Instant,
            outcome: Effect.Outcome<E.Value, E.Failure>
        ) {
            self.effect = effect
            self.timestamp = timestamp
            self.outcome = outcome
        }
    }
}
