import Async
public import Cardinal
public import Effects
import Kernel_Clock

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

    internal func record<E: Effect.`Protocol`>(
        _ effect: E,
        outcome: Invocation.Outcome
    ) where E: Sendable {
        let invocation = Invocation(
            type: E.self,
            effect: effect,
            timestamp: Clock.Continuous.now,
            outcome: outcome
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

    public func count<E: Effect.`Protocol`>(of type: E.Type) -> Cardinal {
        _invocations.withLock {
            $0.reduce(Cardinal.zero) { count, invocation in
                invocation.effect is E ? count + .one : count
            }
        }
    }
}

extension Effect.Test.Recorder {

    public func handler<E: Effect.`Protocol`>(
        wrapping inner: Effect.Test.Handler<E>
    ) -> Handler<E> where E: Sendable, E.Value: Copyable & Sendable {
        Handler(recorder: self, inner: inner)
    }

    public func handler<E: Effect.`Protocol`>(
        returning value: E.Value
    ) -> Handler<E>
    where E: Sendable, E.Value: Copyable & Sendable, E.Failure == Never {
        Handler(recorder: self, inner: Effect.Test.Handler(returning: value))
    }
}
