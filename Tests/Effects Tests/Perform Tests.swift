import Dependency
import Effects
import Effect
import Effects_Testing
import Testing

@Test
func `perform returns handler value`() async {

    let handler = Effect.Test.Handler<Fixture.Value>(returning: 42)

    let result = await Effect.Context.with(
        { handlers in
            handlers[Fixture.Value.Key.self] = handler
        },
        operation: {
            await Effect.perform(Fixture.Value())
        }
    )

    #expect(result == 42)
}

@Test
func `perform throws handler error`() async throws {
    let handler = Effect.Test.Handler<Fixture.Throwing>(throwing: Fixture.Failure())

    do throws(Fixture.Failure) {
        _ = try await Effect.Context.with(
            { handlers in
                handlers[Fixture.Throwing.Key.self] = handler
            },
            operation: { () async throws(Fixture.Failure) -> Int in
                try await Effect.perform(Fixture.Throwing())
            }
        )
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error == Fixture.Failure())
    }
}
