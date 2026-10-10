import Effect
import Effects_Testing
import Testing

struct Entry: Effect.`Protocol` {
    let id: Int
}

extension Entry {
    typealias Value = Int
    typealias Failure = Never
}

@Test
func `spy records invocations`() async {
    let spy = Effect.Test.Spy<Entry>(returning: 100)

    #expect(spy.invocations.count == 0)

    let cont1 = Effect.Continuation.one {
        @Sendable (_: Result<Int, Never>) async in
    }
    await spy.handle(Entry(id: 1), continuation: cont1)

    let cont2 = Effect.Continuation.one {
        @Sendable (_: Result<Int, Never>) async in
    }
    await spy.handle(Entry(id: 2), continuation: cont2)

    #expect(spy.invocations.count == 2)
    #expect(spy.invocations[0].effect.id == 1)
    #expect(spy.invocations[1].effect.id == 2)
}

@Test
func `spy reset`() async {
    let spy = Effect.Test.Spy<Entry>(returning: 100)

    let cont = Effect.Continuation.one {
        @Sendable (_: Result<Int, Never>) async in
    }
    await spy.handle(Entry(id: 1), continuation: cont)

    #expect(spy.invocations.count == 1)

    spy.reset()

    #expect(spy.invocations.count == 0)
    #expect(spy.invocations.isEmpty)
}
