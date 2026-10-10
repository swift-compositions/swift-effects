import Cardinal
import Effect
import Effects_Testing
import Testing

struct Fallible {}

extension Fallible: Effect.`Protocol` {
    typealias Value = Int
    typealias Failure = Fault
}

enum Fault: Swift::Error {
    case expected
}

@Test
func `recorder captures typed counts and successful outcomes then resets`() async throws {
    let recorder = Effect.Test.Recorder()
    let handler: Effect.Test.Recorder.Handler<Entry> = recorder.handler(returning: 42)
    let continuation = Effect.Continuation.one {
        @Sendable (result: Result<Int, Never>) async in
        switch result {
        case .success(let value): #expect(value == 42)
        }
    }
    await handler.handle(Entry(id: 7), continuation: continuation)
    #expect(recorder.count == 1)
    #expect(recorder.count(of: Entry.self) == 1)
    let invocation = try #require(recorder.invocations.first)
    #expect(ObjectIdentifier(invocation.type) == ObjectIdentifier(Entry.self))
    #expect(invocation.status == .success)
    #expect(invocation.succeeded)
    #expect(recorder.invocations(of: Entry.self).first?.id == 7)
    recorder.reset()
    #expect(recorder.count == 0)
    #expect(recorder.invocations.isEmpty)
}

@Test
func `recorder preserves failed outcomes`() async throws {
    let recorder = Effect.Test.Recorder()
    let handler = recorder.handler(wrapping: Effect.Test.Handler<Fallible>(throwing: .expected))
    let continuation = Effect.Continuation.one {
        @Sendable (result: Result<Int, Fault>) async in
        switch result {
        case .success: Issue.record("Expected the original handler failure")
        case .failure(let failure): #expect(failure == .expected)
        }
    }
    await handler.handle(Fallible(), continuation: continuation)
    let invocation = try #require(recorder.invocations.first)
    #expect(invocation.status == .failure)
    #expect(!invocation.succeeded)
    #expect(recorder.count(of: Entry.self) == 0)
    #expect(recorder.count(of: Fallible.self) == 1)
}
