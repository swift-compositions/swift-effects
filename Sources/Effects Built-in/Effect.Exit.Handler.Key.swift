public import Effect
public import Dependency

extension Effect.Exit.Handler {

    public struct Key {}
}

extension Effect.Exit.Handler.Key: Dependency.Key {
    public typealias Value = Effect.Exit.Handler

    public static var liveValue: Effect.Exit.Handler { .live }

    public static var testValue: Effect.Exit.Handler {
        Effect.Exit.Handler { _ in

            while !Task.isCancelled {
                await Task.yield()

                // swift-linter:disable:next do throws for typed catch
                // REASON: Task.sleep(for:) throws untyped `any Error`, so there is no `E` to name.
                do {
                    try await Task.sleep(for: .seconds(3600))
                } catch {}
            }
            await withCheckedContinuation { (_: CheckedContinuation<Never, Never>) in }
        }
    }
}
