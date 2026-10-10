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

## Full compliance gate

The candidate in this branch is the reference for the complete 124-rule
`institute` bundle, not just the local linter's default three rules. The policy
pins all six tool repositories, the resolved tool graph, Swift/Xcode versions,
and the macOS 27 compiler target. One existing typed-catch suppression is
explicitly reviewed and bound to its complete source file. New findings,
unmeasured source, and changed suppression context fail the gate.

Requirements: macOS 27 on Apple Silicon, full Xcode 27.1 with Swift 6.4, Python
3.9+, Git, and network access for the initial dependency downloads. These are
local candidate commits; they have not been published as production releases.
Clone this candidate and the delivered `swift-linter` candidate into any new
directory, using their local Git paths as clone sources until published:

```sh
git clone --no-local /path/to/delivered/swift-effects swift-effects
git clone --no-local /path/to/delivered/swift-linter swift-linter
cd swift-linter
# Check out the engine commit recorded in ../swift-effects/compliance-policy.json.
git checkout --detach "$(python3 -c 'import json; print(json.load(open("../swift-effects/compliance-policy.json"))["sources"]["swift-linter"])')"
./scripts/lint-local setup --policy ../swift-effects/compliance-policy.json \
  --source-repositories /path/to/source-repositories.json
cd ../swift-effects
./scripts/check-compliance ../swift-linter
```

`source-repositories.json` maps all five non-engine checkout names to Git URLs
or local Git paths; use the delivered corrected rules checkout for
`swift-institute-linter-rules`. Use this explicit mapping (replace the local path):

```json
{
  "swift-institute-linter-rules": "/path/to/delivered/swift-institute-linter-rules",
  "swift-primitives-linter-rules": "https://github.com/swift-molecules/swift-primitives-linter-rules.git",
  "swift-standards-linter-rules": "https://github.com/swift-standards/swift-standards-linter-rules.git",
  "swift-linter-rules": "https://github.com/swift-compositions/swift-linter-rules.git",
  "swift-lint": "https://github.com/swift-molecules/swift-lint.git"
}
```

See `swift-linter/scripts/README.md` for additional setup options. Existing checkouts are verified, never reset. Once every
policy commit is reachable upstream, the source-repositories option can be
omitted. Ordinary edit/check cycles need no publishing or cache deletion.

**Everyday command, from this package:**

```sh
./scripts/check-compliance ../swift-linter
```

This runs the full pinned lint policy, then builds and runs the package tests
against the committed `Package.resolved`. Exit 0 means both passed; 1 is lint
violations or suppression review failure, 2 is incomplete measurement, 3 is
setup/build/test failure, and invalid linter arguments/policy return 64. For a
quick lint-only iteration, run `../swift-linter/scripts/lint-local check .
--policy compliance-policy.json` as one line. Pass `--config /path/to/config.json`
to the gate if using a custom tool configuration.

For **rule development**, edit the local rule checkout and run ordinary
`lint-local check` or `report` without `--policy`, then run its regression tests.
The compliance gate intentionally rejects uncommitted tool changes. Review,
commit and test a rule change before updating the pinned policy; never accept
new findings or suppressions merely to make the gate pass.
