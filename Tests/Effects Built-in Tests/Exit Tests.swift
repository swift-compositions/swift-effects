import Effect
import Effects_Built_in
import Testing

@Test
func `exit effect has correct code`() {
    let effect = Effect.Exit(code: 42)
    #expect(effect.code == 42)
}

@Test
func `exit effect zero code`() {
    let effect = Effect.Exit(code: 0)
    #expect(effect.code == 0)
}

@Test
func `live exit preserves successful process status`() async {
    await #expect(processExitsWith: .exitCode(0)) {
        await Effect.Exit.perform(code: 0)
    }
}

@Test
func `live exit preserves nonzero process status`() async {
    await #expect(processExitsWith: .exitCode(37)) {
        await Effect.Exit.perform(code: 37)
    }
}
