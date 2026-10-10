import Effect
import Effects_Testing
import Testing

struct Probe: Effect.`Protocol` {
    let input: Int
}

extension Probe {
    typealias Value = String
    typealias Failure = Never
}

@Test
func `handler returns fixed value`() async {
    let handler = Effect.Test.Handler<Probe>(returning: "hello")

    let continuation = Effect.Continuation.one {
        @Sendable (result: Result<String, Never>) async in
        switch result {
        case .success(let value):
            #expect(value == "hello")
        }
    }

    await handler.handle(Probe(input: 42), continuation: continuation)
}

@Test
func `handler returns computed value`() async {
    let handler = Effect.Test.Handler<Probe>(returning: { effect in
        "value: \(effect.input)"
    })

    let continuation = Effect.Continuation.one {
        @Sendable (result: Result<String, Never>) async in
        switch result {
        case .success(let value):
            #expect(value == "value: 42")
        }
    }

    await handler.handle(Probe(input: 42), continuation: continuation)
}
