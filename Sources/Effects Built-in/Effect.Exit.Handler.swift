public import Effects
internal import Process
public import Witness

extension Effect.Exit {

    public struct Handler: Effect.Handler.`Protocol`, Sendable, Witness.`Protocol` {
        private let _handle: @Sendable (Int32) async -> Never

        public init(_ handle: @escaping @Sendable (Int32) async -> Never) {
            self._handle = handle
        }
    }
}

extension Effect.Exit.Handler {

    public func handle(
        _ effect: borrowing Effect.Exit,
        continuation: consuming Effect.Continuation.One<Never, Never>
    ) async {

        _ = consume continuation
        await _handle(effect.code)
    }
}

extension Effect.Exit.Handler {

    public static let live = Effect.Exit.Handler { code in
        Process.Exit.normal(code)
    }
}
