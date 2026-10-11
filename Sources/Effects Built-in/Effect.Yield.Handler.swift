public import Effects
public import Witness

extension Effect.Yield {

    public struct Handler: Effect.Handler.`Protocol`, Sendable, Witness.`Protocol` {
        private let _handle: @Sendable () async -> Void

        public init(_ handle: @escaping @Sendable () async -> Void) {
            self._handle = handle
        }
    }
}

extension Effect.Yield.Handler {

    public func handle(
        _ effect: borrowing Effect.Yield,
        continuation: consuming Effect.Continuation.One<Void, Never>
    ) async {
        await _handle()
        await continuation.resume()
    }
}

extension Effect.Yield.Handler {

    public static let live = Effect.Yield.Handler {
        await Task.yield()
    }
}
