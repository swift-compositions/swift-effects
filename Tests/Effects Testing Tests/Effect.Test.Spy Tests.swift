import Effects
import Effects_Testing
import Testing

struct Tally: Effect.`Protocol` {
    let id: Int
}

extension Tally {
    typealias Value = Int
    typealias Failure = Never
}

@Test
func `spy records invocations`() async {
    let spy = Effect.Test.Spy<Tally>(returning: 100)

    #expect(spy.count == 0)

    let cont1 = Effect.Continuation.one {
        @Sendable (_: Result<Int, Never>) async in
    }
    await spy.handle(Tally(id: 1), continuation: cont1)

    let cont2 = Effect.Continuation.one {
        @Sendable (_: Result<Int, Never>) async in
    }
    await spy.handle(Tally(id: 2), continuation: cont2)

    #expect(spy.count == 2)
    #expect(spy.invocations[0].effect.id == 1)
    #expect(spy.invocations[1].effect.id == 2)
}

@Test
func `spy reset`() async {
    let spy = Effect.Test.Spy<Tally>(returning: 100)

    let cont = Effect.Continuation.one {
        @Sendable (_: Result<Int, Never>) async in
    }
    await spy.handle(Tally(id: 1), continuation: cont)

    #expect(spy.count == 1)

    spy.reset()

    #expect(spy.count == 0)
    #expect(spy.invocations.isEmpty)
}
