import Async
internal import Clocks
public import Effects

extension Effect.Test {

    public final class Recorder: Sendable {
        private let _invocations: Async.Mutex<[Invocation]> = Async.Mutex([])

        public init() {}
    }
}


extension Effect.Test.Recorder {

    public var invocations: [Invocation] {
        _invocations.withLock { $0 }
    }

    public var count: Int {
        _invocations.withLock { $0.count }
    }

    internal func record<E: Effect.`Protocol`>(_ effect: E, succeeded: Bool) where E: Sendable {
        let invocation = Invocation(
            effectType: E.self,
            effect: effect,
            timestamp: Clock.Continuous.now,
            succeeded: succeeded
        )
        _invocations.withLock { $0.append(invocation) }
    }

    public func reset() {
        _invocations.withLock { $0.removeAll() }
    }

    public func invocations<E: Effect.`Protocol`>(of type: E.Type) -> [E] {
        _invocations.withLock {
            $0.compactMap { $0.effect as? E }
        }
    }

    public func count<E: Effect.`Protocol`>(of type: E.Type) -> Int {
        _invocations.withLock {
            $0.filter { $0.effect is E }.count
        }
    }
}

extension Effect.Test.Recorder {

    public func handler<E: Effect.`Protocol`>(
        wrapping inner: Effect.Test.Handler<E>
    ) -> RecordingHandler<E> where E: Sendable, E.Value: Copyable & Sendable {
        RecordingHandler(recorder: self, inner: inner)
    }

    public func handler<E: Effect.`Protocol`>(
        returning value: E.Value
    ) -> RecordingHandler<E>
    where E: Sendable, E.Value: Copyable & Sendable, E.Failure == Never {
        RecordingHandler(recorder: self, inner: Effect.Test.Handler(returning: value))
    }


}
