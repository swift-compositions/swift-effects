public import Effects

extension Effect.Test {

    public struct Handler<E: Effect.`Protocol`>: Sendable
    where E: Sendable, E.Value: Copyable & Sendable {
        @usableFromInline
        internal let _handle: @Sendable (E) async -> Result<E.Value, E.Failure>

        public init(_ handle: @escaping @Sendable (E) async -> Result<E.Value, E.Failure>) {
            self._handle = handle
        }


    }
}

extension Effect.Test.Handler where E.Failure == Never {

    public init(returning value: E.Value) {
        self._handle = { _ in .success(value) }
    }

    public init(returning value: @escaping @Sendable (E) async -> E.Value) {
        self._handle = { effect in .success(await value(effect)) }
    }
}

extension Effect.Test.Handler {

    public init(throwing error: E.Failure) {
        self._handle = { _ in .failure(error) }
    }
}

extension Effect.Test.Handler where E.Value == Void, E.Failure == Never {

    public init() {
        self._handle = { _ in .success(()) }
    }
}

extension Effect.Test.Handler: Effect.Handler.`Protocol` {
    public typealias Handled = E

    public func handle(
        _ effect: borrowing E,
        continuation: consuming Effect.Continuation.One<E.Value, E.Failure>
    ) async {
        let result = await _handle(effect)
        await continuation.resume(with: result)
    }
}
