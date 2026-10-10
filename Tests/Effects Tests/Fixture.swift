import Dependency
import Effects
import Effects_Testing

enum Fixture {}

extension Fixture {
    struct Failure {}
}

extension Fixture.Failure: Swift::Error, Equatable {}

extension Fixture {
    enum Cancellation {}
}

extension Fixture {
    struct Value {}
}

extension Fixture.Value: Effect.`Protocol`, EffectWithHandler {
    typealias Value = Int
    typealias Failure = Never
    typealias HandlerKey = Key
}

extension Fixture.Value {
    struct Key {}
}

extension Fixture.Value.Key: Dependency.Key {
    typealias Value = Effect.Test.Handler<Fixture.Value>
    static var liveValue: Value { Effect.Test.Handler(returning: 0) }
    static var testValue: Value { liveValue }
}

extension Fixture {
    struct Throwing {}
}

extension Fixture.Throwing: Effect.`Protocol`, EffectWithHandler {
    typealias Value = Int
    typealias Failure = Fixture.Failure
    typealias HandlerKey = Key
}

extension Fixture.Throwing {
    struct Key {}
}

extension Fixture.Throwing.Key: Dependency.Key {
    typealias Value = Effect.Test.Handler<Fixture.Throwing>
    static var liveValue: Value { Effect.Test.Handler(throwing: Fixture.Failure()) }
    static var testValue: Value { liveValue }
}

extension Fixture.Cancellation {
    struct Infallible {}
}

extension Fixture.Cancellation.Infallible: Effect.`Protocol`, EffectWithHandler {
    typealias Value = Bool
    typealias Failure = Never
    typealias HandlerKey = Key
}

extension Fixture.Cancellation.Infallible {
    struct Key {}
}

extension Fixture.Cancellation.Infallible.Key: Dependency.Key {
    typealias Value = Effect.Test.Handler<Fixture.Cancellation.Infallible>
    static var liveValue: Value { Effect.Test.Handler { _ in
            for _ in 0..<500 {
                if Task.isCancelled { return .success(true) }
                await Task.yield()
            }
            return .success(false)
        } }
    static var testValue: Value { liveValue }
}

extension Fixture.Cancellation {
    struct Fallible {}
}

extension Fixture.Cancellation.Fallible: Effect.`Protocol`, EffectWithHandler {
    typealias Value = Bool
    typealias Failure = Fixture.Failure
    typealias HandlerKey = Key
}

extension Fixture.Cancellation.Fallible {
    struct Key {}
}

extension Fixture.Cancellation.Fallible.Key: Dependency.Key {
    typealias Value = Effect.Test.Handler<Fixture.Cancellation.Fallible>
    static var liveValue: Value { Effect.Test.Handler { _ in
            for _ in 0..<500 {
                if Task.isCancelled { return .success(true) }
                await Task.yield()
            }
            return .success(false)
        } }
    static var testValue: Value { liveValue }
}
