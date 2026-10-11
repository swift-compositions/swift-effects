import Dependency
import Effects
import Effects_Testing
import Testing

extension Effect.Perform {
    @Suite struct Test {
        struct Unit {}
    }
}

extension Effect.Perform.Test {
    enum Constant {}
    enum Probe {}
}

extension Effect.Perform.Test.Constant {
    struct Infallible: Effect.`Protocol`, EffectWithHandler {}
    struct Fallible: Effect.`Protocol`, EffectWithHandler {}
}

extension Effect.Perform.Test.Constant.Infallible {
    typealias Value = Int
    typealias Failure = Never
    typealias HandlerKey = Key

    struct Key: Dependency.Key {}
}

extension Effect.Perform.Test.Constant.Infallible.Key {
    static var liveValue: Effect.Test.Handler<Effect.Perform.Test.Constant.Infallible> {
        Effect.Test.Handler(returning: 0)
    }
    static var testValue: Effect.Test.Handler<Effect.Perform.Test.Constant.Infallible> { liveValue }
}

extension Effect.Perform.Test.Constant.Fallible {
    typealias Value = Int
    typealias HandlerKey = Key

    struct Failure: Swift::Error, Equatable {}
    struct Key: Dependency.Key {}
}

extension Effect.Perform.Test.Constant.Fallible.Key {
    static var liveValue: Effect.Test.Handler<Effect.Perform.Test.Constant.Fallible> {
        Effect.Test.Handler(throwing: Effect.Perform.Test.Constant.Fallible.Failure())
    }
    static var testValue: Effect.Test.Handler<Effect.Perform.Test.Constant.Fallible> { liveValue }
}

extension Effect.Perform.Test.Probe {
    struct Infallible: Effect.`Protocol`, EffectWithHandler {}
    struct Fallible: Effect.`Protocol`, EffectWithHandler {}

    static func observe<E: Effect.`Protocol`>(
        _ effect: E.Type
    ) -> Effect.Test.Handler<E> where E: Sendable, E.Value == Bool {
        Effect.Test.Handler { _ in
            for _ in 0..<500 {
                if Task.isCancelled { return .success(true) }
                await Task.yield()
            }
            return .success(false)
        }
    }
}

extension Effect.Perform.Test.Probe.Infallible {
    typealias Value = Bool
    typealias Failure = Never
    typealias HandlerKey = Key

    struct Key: Dependency.Key {}
}

extension Effect.Perform.Test.Probe.Infallible.Key {
    static var liveValue: Effect.Test.Handler<Effect.Perform.Test.Probe.Infallible> { testValue }
    static var testValue: Effect.Test.Handler<Effect.Perform.Test.Probe.Infallible> {
        Effect.Perform.Test.Probe.observe(Effect.Perform.Test.Probe.Infallible.self)
    }
}

extension Effect.Perform.Test.Probe.Fallible {
    typealias Value = Bool
    typealias HandlerKey = Key

    struct Failure: Swift::Error, Equatable {}
    struct Key: Dependency.Key {}
}

extension Effect.Perform.Test.Probe.Fallible.Key {
    static var liveValue: Effect.Test.Handler<Effect.Perform.Test.Probe.Fallible> { testValue }
    static var testValue: Effect.Test.Handler<Effect.Perform.Test.Probe.Fallible> {
        Effect.Perform.Test.Probe.observe(Effect.Perform.Test.Probe.Fallible.self)
    }
}

extension Effect.Perform.Test.Unit {

    @Test
    func `perform returns handler value`() async {
        let handler = Effect.Test.Handler<Effect.Perform.Test.Constant.Infallible>(returning: 42)

        let result = await Effect.Context.with(
            { handlers in
                handlers[Effect.Perform.Test.Constant.Infallible.Key.self] = handler
            },
            operation: {
                await Effect.perform(Effect.Perform.Test.Constant.Infallible())
            }
        )

        #expect(result == 42)
    }

    @Test
    func `perform throws handler error`() async {
        let handler = Effect.Test.Handler<Effect.Perform.Test.Constant.Fallible>(
            throwing: Effect.Perform.Test.Constant.Fallible.Failure()
        )

        do throws(Effect.Perform.Test.Constant.Fallible.Failure) {
            _ = try await Effect.Context.with(
                { handlers in
                    handlers[Effect.Perform.Test.Constant.Fallible.Key.self] = handler
                },
                operation: { () async throws(Effect.Perform.Test.Constant.Fallible.Failure) -> Int in
                    try await Effect.perform(Effect.Perform.Test.Constant.Fallible())
                }
            )
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error == Effect.Perform.Test.Constant.Fallible.Failure())
        }
    }

    @Test
    func `infallible perform propagates caller cancellation to the handler dispatch task`() async {
        let task = Task {
            await Effect.Context.with(
                { handlers in
                    handlers[Effect.Perform.Test.Probe.Infallible.Key.self] = Effect.Perform.Test.Probe.Infallible.Key.testValue
                },
                operation: { await Effect.perform(Effect.Perform.Test.Probe.Infallible()) }
            )
        }

        await Task.yield()
        task.cancel()

        let observedCancellation = await task.value
        #expect(observedCancellation == true)
    }

    @Test
    func `fallible perform propagates caller cancellation to the handler dispatch task`() async {
        let task = Task {
            await Effect.Context.with(
                { handlers in
                    handlers[Effect.Perform.Test.Probe.Fallible.Key.self] = Effect.Perform.Test.Probe.Fallible.Key.testValue
                },
                operation: { () async -> Bool in
                    do throws(Effect.Perform.Test.Probe.Fallible.Failure) {
                        return try await Effect.perform(Effect.Perform.Test.Probe.Fallible())
                    } catch {
                        return false
                    }
                }
            )
        }

        await Task.yield()
        task.cancel()

        let observedCancellation = await task.value
        #expect(observedCancellation == true)
    }
}
