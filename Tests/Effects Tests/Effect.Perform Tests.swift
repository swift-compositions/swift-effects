import Dependency
import Effects
import Effects_Testing
import Testing

enum `Effect.Perform Tests` {}

extension `Effect.Perform Tests` {
    @Suite struct Test {
        struct Unit {}
    }
}

extension `Effect.Perform Tests`.Test {
    enum Constant {}
    enum Probe {}
}

extension `Effect.Perform Tests`.Test.Constant {
    struct Infallible: Effect.`Protocol`, EffectWithHandler {}
    struct Fallible: Effect.`Protocol`, EffectWithHandler {}
}

extension `Effect.Perform Tests`.Test.Constant.Infallible {
    typealias Value = Int
    typealias Failure = Never
    typealias HandlerKey = Key

    struct Key: Dependency.Key {}
}

extension `Effect.Perform Tests`.Test.Constant.Infallible.Key {
    static var liveValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Constant.Infallible> {
        Effect.Test.Handler(returning: 0)
    }
    static var testValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Constant.Infallible> { liveValue }
}

extension `Effect.Perform Tests`.Test.Constant.Fallible {
    typealias Value = Int
    typealias HandlerKey = Key

    struct Failure: Swift::Error, Equatable {}
    struct Key: Dependency.Key {}
}

extension `Effect.Perform Tests`.Test.Constant.Fallible.Key {
    static var liveValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Constant.Fallible> {
        Effect.Test.Handler(throwing: `Effect.Perform Tests`.Test.Constant.Fallible.Failure())
    }
    static var testValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Constant.Fallible> { liveValue }
}

extension `Effect.Perform Tests`.Test.Probe {
    struct Infallible: Effect.`Protocol`, EffectWithHandler {}
    struct Fallible: Effect.`Protocol`, EffectWithHandler {}

    static func observe<E: Effect.`Protocol`>(
        _ effect: E.Type
    ) -> Effect.Test.Handler<E> where E: Sendable, E.Value == Bool {
        Effect.Test.Handler { _ in
            for _ in 0..<500 {
                if Task.isCancelled { return .success(true) }
                do {
                    try await Task.sleep(for: .milliseconds(10))
                } catch {
                    return .success(true)
                }
            }
            return .success(false)
        }
    }
}

extension `Effect.Perform Tests`.Test.Probe.Infallible {
    typealias Value = Bool
    typealias Failure = Never
    typealias HandlerKey = Key

    struct Key: Dependency.Key {}
}

extension `Effect.Perform Tests`.Test.Probe.Infallible.Key {
    static var liveValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Probe.Infallible> { testValue }
    static var testValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Probe.Infallible> {
        `Effect.Perform Tests`.Test.Probe.observe(`Effect.Perform Tests`.Test.Probe.Infallible.self)
    }
}

extension `Effect.Perform Tests`.Test.Probe.Fallible {
    typealias Value = Bool
    typealias HandlerKey = Key

    struct Failure: Swift::Error, Equatable {}
    struct Key: Dependency.Key {}
}

extension `Effect.Perform Tests`.Test.Probe.Fallible.Key {
    static var liveValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Probe.Fallible> { testValue }
    static var testValue: Effect.Test.Handler<`Effect.Perform Tests`.Test.Probe.Fallible> {
        `Effect.Perform Tests`.Test.Probe.observe(`Effect.Perform Tests`.Test.Probe.Fallible.self)
    }
}

extension `Effect.Perform Tests`.Test.Unit {

    @Test
    func `perform returns handler value`() async {
        let handler = Effect.Test.Handler<`Effect.Perform Tests`.Test.Constant.Infallible>(returning: 42)

        let result = await Effect.Context.with(
            { handlers in
                handlers[`Effect.Perform Tests`.Test.Constant.Infallible.Key.self] = handler
            },
            operation: {
                await Effect.perform(`Effect.Perform Tests`.Test.Constant.Infallible())
            }
        )

        #expect(result == 42)
    }

    @Test
    func `perform throws handler error`() async {
        let handler = Effect.Test.Handler<`Effect.Perform Tests`.Test.Constant.Fallible>(
            throwing: `Effect.Perform Tests`.Test.Constant.Fallible.Failure()
        )

        do throws(`Effect.Perform Tests`.Test.Constant.Fallible.Failure) {
            _ = try await Effect.Context.with(
                { handlers in
                    handlers[`Effect.Perform Tests`.Test.Constant.Fallible.Key.self] = handler
                },
                operation: { () async throws(`Effect.Perform Tests`.Test.Constant.Fallible.Failure) -> Int in
                    try await Effect.perform(`Effect.Perform Tests`.Test.Constant.Fallible())
                }
            )
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error == `Effect.Perform Tests`.Test.Constant.Fallible.Failure())
        }
    }

    @Test
    func `infallible perform propagates caller cancellation to the handler dispatch task`() async {
        let task = Task {
            await Effect.Context.with(
                { handlers in
                    handlers[`Effect.Perform Tests`.Test.Probe.Infallible.Key.self] = `Effect.Perform Tests`.Test.Probe.Infallible.Key.testValue
                },
                operation: { await Effect.perform(`Effect.Perform Tests`.Test.Probe.Infallible()) }
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
                    handlers[`Effect.Perform Tests`.Test.Probe.Fallible.Key.self] = `Effect.Perform Tests`.Test.Probe.Fallible.Key.testValue
                },
                operation: { () async -> Bool in
                    do throws(`Effect.Perform Tests`.Test.Probe.Fallible.Failure) {
                        return try await Effect.perform(`Effect.Perform Tests`.Test.Probe.Fallible())
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
