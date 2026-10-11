import Cardinal
import Effects
import Effects_Testing
import Testing

struct Ping: Effect.`Protocol` {}

extension Ping {
    typealias Value = Int
    typealias Failure = Never
}

struct Pong: Effect.`Protocol` {}

extension Pong {
    typealias Value = Int
    typealias Failure = Never
}

@Test
func `recorder counts invocations per effect type`() async {
    let recorder = Effect.Test.Recorder()
    let ping = recorder.handler(returning: 1) as Effect.Test.Recorder.Handler<Ping>
    let pong = recorder.handler(returning: 2) as Effect.Test.Recorder.Handler<Pong>

    await ping.handle(Ping(), continuation: Effect.Continuation.one { @Sendable (_: Result<Int, Never>) async in })
    await ping.handle(Ping(), continuation: Effect.Continuation.one { @Sendable (_: Result<Int, Never>) async in })
    await pong.handle(Pong(), continuation: Effect.Continuation.one { @Sendable (_: Result<Int, Never>) async in })

    #expect(recorder.count == 3)
    #expect(recorder.count(of: Ping.self) == 2)
    #expect(recorder.count(of: Pong.self) == 1)
    #expect(recorder.invocations.allSatisfy { $0.outcome == .success })
    #expect(recorder.invocations.first?.type == Ping.self)
}
