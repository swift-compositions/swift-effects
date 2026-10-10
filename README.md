# swift-effects

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Context-scoped effect handling for Swift concurrency — describe side effects as values, perform them with typed throws, and swap the handler per scope for deterministic tests.

## Key Features

- **Typed throws end-to-end** — `Effect.perform(_:)` returns `E.Value` or throws exactly `E.Failure`; infallible effects (`Failure == Never`) perform without `try`.
- **Context-scoped handlers** — handlers resolve through dependency-context keys, so a scope override changes behavior without touching call sites.
- **Test doubles as a separate product** — `Effect.Test.Handler`, `Effect.Test.Spy`, and `Effect.Test.Recorder` live in the `Effects Testing` product, keeping test-only surface out of production builds.
- **Interceptable built-ins** — `Effect.Exit` and `Effect.Yield` turn process termination and scheduler yields into effects a test can observe instead of suffer.

## Quick Start

An effect is a value describing *what* should happen. The handler deciding *how* is looked up from the current context, so the same call site is non-deterministic in production and fixed in a test scope:

```swift
import Effect
import Effects
import Effects_Testing
import Dependency

struct Roll {}

extension Roll: Effect.`Protocol`, Effect.Handled.Protocol {
    typealias Value = Int
    typealias Failure = Never
    typealias HandlerKey = Key
}

extension Roll {
    struct Key {}
}

extension Roll.Key: Dependency.Key {
    typealias Value = Effect.Test.Handler<Roll>
    static var liveValue: Value { .init(returning: { _ in Int.random(in: 1...6) }) }
    static var testValue: Value { liveValue }
}

// Override the handler for one scope; the perform call site is unchanged.
let roll = await Effect.Context.with({ handlers in
    handlers[Roll.Key.self] = .init(returning: 4)
}) {
    await Effect.perform(Roll())
}
// roll == 4
```

Fallible effects declare a concrete `Failure` type, and `Effect.perform` throws exactly that type — no `any Error` to downcast at the catch site.

## Installation

For development, add these direct dependencies. Pin reviewed revisions for reproducible builds:

```swift
dependencies: [
    .package(url: "https://github.com/swift-compositions/swift-effects.git", branch: "main"),
    .package(url: "https://github.com/swift-atoms/swift-effect.git", branch: "main", traits: ["Dependency"]),
    .package(url: "https://github.com/swift-atoms/swift-dependency.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Effect", package: "swift-effect"),
        .product(name: "Dependency", package: "swift-dependency"),
        .product(name: "Effects", package: "swift-effects")
    ]
),
.testTarget(
    name: "YourTargetTests",
    dependencies: [
        .target(name: "YourTarget"),
        .product(name: "Effect", package: "swift-effect"),
        .product(name: "Dependency", package: "swift-dependency"),
        .product(name: "Effects", package: "swift-effects"),
        .product(name: "Effects Testing", package: "swift-effects")
    ]
)
```

### Requirements

- Swift 6.4
- macOS 27+, iOS 27+, tvOS 27+, watchOS 27+, visionOS 27+

## Architecture

| Product | Module | When to import |
|---|---|---|
| `Effects` | `Effects` | Declaring and performing effects through `Effect.perform` and `Effect.Handled.Protocol`. Import `Effect` and `Dependency` directly when using their declarations. |
| `Effects Built-in` | `Effects_Built_in` | Ready-made `Effect.Exit` and `Effect.Yield`. Import `Effect` for the base namespace. |
| `Effects Testing` | `Effects_Testing` | Test doubles for asserting on performed effects. Test targets only. |

## Built-in Effects

The built-in catalog is deliberately small at this stage:

| Effect | Live behavior | Under test |
|---|---|---|
| `Effect.Exit` | Terminates the process (`Value == Never`). The default live handler calls `Process.Exit.normal` with the requested status code. | The test handler suspends instead of terminating, so a test can observe the exit request and cancel or time out. |
| `Effect.Yield` | Delegates to `Task.yield()`. | A custom `Effect.Yield.Handler` can count or suppress yields for deterministic scheduling tests. |

```swift
import Effect
import Effects_Built_in

await Effect.Exit.perform(code: 1)   // never returns in production
await Effect.Yield.perform()
```

## Testing

The `Effects Testing` product provides three test doubles:

| Type | Purpose |
|---|---|
| `Effect.Test.Handler<E>` | Returns a canned value (`init(returning:)`), a canned error (`init(throwing:)`), or runs a closure per effect. |
| `Effect.Test.Spy<E>` | Wraps a handler and records every invocation — effect value, timestamp, and outcome — for `invocations.count`, `invocations.first`, and outcome assertions. |
| `Effect.Test.Recorder` | Type-erased recorder collecting invocations of *different* effect types into one timeline. |

## Compliance candidate API migration

This checkout makes dependency edges explicit and introduces these source changes. Verify consumers against this checkout before adopting a release.

| Previous surface | Replacement |
|---|---|
| `EffectWithHandler` | `Effect.Handled.Protocol` |
| `Effect.Test.Recorder.RecordingHandler` | `Effect.Test.Recorder.Handler` |
| Spy `callCount`, `firstInvocation`, `lastInvocation` | `invocations.count`, `invocations.first`, `invocations.last` |
| Recorder invocation `effectType` | `type` |
| Invocation initializer `succeeded: Bool` | `status: .success` or `.failure`; the `succeeded` getter remains available |
| Recorder `count` and `count(of:)` returning `Int` | `Cardinal`, preserving nonnegative count semantics |
| Implicit re-exported `Effect` / `Dependency` symbols | Explicit imports and direct product dependencies |

Run `swift test` to exercise cancellation, handler dispatch, spy recording, and recorder success/failure/reset behavior. A full compliance check is separate from compilation and tests.

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public release.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).

## Verification

Run `swift test` from this package directory. The suite includes child-process
checks proving that the live exit effect terminates with both status 0 and status
37, rather than trapping. The cancellation, recorder, and handler assertions run
in the same suite.
