import Async
internal import Clocks
public import Effects

extension Effect.Test {

    public final class Spy<E: Effect.`Protocol`>: Sendable
    where E: Sendable, E.Value: Copyable & Sendable {

        private let _invocations: Async.Mutex<[Invocation]> = Async.Mutex([])
        private let inner: Effect.Test.Handler<E>

        public init(wrapping inner: Effect.Test.Handler<E>) {
            self.inner = inner
        }

        public init(_ handle: @escaping @Sendable (E) async -> Swift::Result<E.Value, E.Failure>) {
            self.inner = Effect.Test.Handler(handle)
        }


    }
}

extension Effect.Test.Spy: Effect.Handler.`Protocol` {
    public typealias Handled = E

    public func handle(
        _ effect: borrowing E,
        continuation: consuming Effect.Continuation.One<E.Value, E.Failure>
    ) async {

        let recordedEffect = copy effect
        let wrapped = continuation.onResume { [weak self] result in
            let outcome = Effect.Outcome(result)
            self?.record(effect: recordedEffect, outcome: outcome)
        }

        await inner.handle(effect, continuation: wrapped)
    }
}

extension Effect.Test.Spy where E.Failure == Never {

    public convenience init(returning value: E.Value) {
        self.init(wrapping: Effect.Test.Handler(returning: value))
    }
}

extension Effect.Test.Spy {

    public convenience init(throwing error: E.Failure) {
        self.init(wrapping: Effect.Test.Handler(throwing: error))
    }
}

extension Effect.Test.Spy where E.Value == Void, E.Failure == Never {

    public convenience init() {
        self.init(wrapping: Effect.Test.Handler())
    }
}

extension Effect.Test.Spy {
    public var invocations: [Invocation] {
        _invocations.withLock { $0 }
    }

    public var callCount: Int {
        _invocations.withLock { $0.count }
    }

    public var lastInvocation: Invocation? {
        _invocations.withLock { $0.last }
    }

    public var firstInvocation: Invocation? {
        _invocations.withLock { $0.first }
    }

    private func record(effect: E, outcome: Effect.Outcome<E.Value, E.Failure>) {
        let invocation = Invocation(
            effect: effect,
            timestamp: Clock.Continuous.now,
            outcome: outcome
        )
        _invocations.withLock { $0.append(invocation) }
    }

    public func reset() {
        _invocations.withLock { $0.removeAll() }
    }
}
