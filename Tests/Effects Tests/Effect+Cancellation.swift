import Dependency
import Effects
import Effects_Testing
import Testing

extension Effect {
    enum Cancellation {}
}

extension Effect.Cancellation {
    @Suite struct Test {}
}

extension Effect.Cancellation.Test {

    @Test
    func `infallible perform propagates caller cancellation to the handler dispatch task`() async {
        let task = Task {
            await Effect.Context.with(
                { handlers in handlers[Fixture.Cancellation.Infallible.Key.self] = Fixture.Cancellation.Infallible.Key.testValue },
                operation: { await Effect.perform(Fixture.Cancellation.Infallible()) }
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
                { handlers in handlers[Fixture.Cancellation.Fallible.Key.self] = Fixture.Cancellation.Fallible.Key.testValue },
                operation: {
                    do throws(Fixture.Failure) {
                        return try await Effect.perform(Fixture.Cancellation.Fallible())
                    } catch {
                        Issue.record("Unexpected cancellation probe failure: \(error)")
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
