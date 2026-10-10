# Compliance reference verification

Candidate work is local and unreleased. Production consumers were not changed.
The supported profile is macOS 27 on Apple Silicon, Xcode 27.1 (27A9269),
Apple Swift 6.4 (swiftlang-6.4.0.34.1), native SwiftPM, with every Swift compiler
invocation explicitly targeting arm64-apple-macosx27.0.

## What the reference establishes

The full `institute` bundle has 124 rules. The corrected reference's 29 Swift
files yielded zero findings and zero unmeasured observations, with one existing
suppression explicitly reviewed in `compliance-policy.json`. This is different
from the ordinary local linter's default three-rule selection. The committed
`scripts/check-compliance` runs this full policy and the package's locked tests.

Reference source changes include explicit imports/dependencies, canonical file
and type layout, namespaced handler/test APIs, and using the existing
`Process.Exit.normal` implementation for live exit. All original 11 tests were
retained; two recorder regressions and two real process-exit tests were added.
The process tests assert exact successful/nonzero exit statuses rather than
accepting a trap. The candidate API migration is in README.

Three rule defects were repaired with retained counterexamples: leading `./`
was mistaken for a hidden directory; required Dependency.Key witnesses and
adjacent nonempty suppression REASON metadata needed precise handling; escaped
Swift identifiers needed unescaping when deriving file names. The corrected
rules commit is 2b7f6345e632. The full rule suite passed 1,952 tests across 19
targets. No suppression was added to obtain the reference result.

The engine also now treats parser-recovered malformed Swift as unmeasured,
retains its findings, and withholds repairs. A recovered AST is not evidence
that a file was completely analyzed. A regression fixture preserves this case.

## Reproduction and retained evidence

Follow README for a new checkout. Evidence directories are retained outside
these source repositories under the developer's `compliance-development`
directory; commands use the delivered candidate checkouts, not production.

| Verification | Command / evidence | Result |
|---|---|---|
| Reference runtime behavior | `swift test`; `effects-exit-regressions.log` | 15 tests passed |
| Rules and counterexamples | `swift test` in the corrected rules checkout; `rules-escaped-path-green.log` | 1,952 passed |
| Downstream stores candidate | `swift test` with verified local effects binding; `stores-local-effects-commands.json` | 26 passed; candidate 8987dfa |
| Downstream test-application candidate | `swift test` with verified local effects binding; `test-application-final-effects-command.json` | 28 passed; candidate 2dd4ced |
| Fresh policy setup | `lint-local setup --policy ... --source-repositories ...`; `fresh-uniform-setup.*` | Exit 0; new source clones, private resolve/build state, path with spaces |
| Full policy failure contract | `python3 scripts/tests/policy_integration.py --linter . --config .local-linter/config.json --policy /path/to/compliance-policy.json --package /path/to/swift-effects --output .local-linter`; `fresh-uniform-policy-workflow.log` | All 11 cases passed |
| Audit/tool Python contracts | `python3 -m unittest discover -s scripts/tests -p 'test_*.py'`; `final-tool-contract-tests.log` | 45 passed |

The fresh policy workflow checks clean0 → real violation1 → fix0,
malformed-source2 → fix0, changed suppression context1, omitted rule2,
wrong engine revision3, invalid policy64, setup failure3, and final clean0.
It retains each exact command and outcome in `commands.json`.

The initial fresh setup and contract workflow used engine0b595cc. Subsequent
engine changes correct local dependency identities when the checkout directory
has a different name; they do not change the rule bundle. Revisions for each
run are recorded in its receipt. Failed intermediate experiments are retained
and must not be counted as passing tests.

## Scope of ecosystem results

The ecosystem audit applies the same pinned tool graph and explicit rule-bundle
mapping to isolated working-source snapshots. It reports lint-clean, measured
debt, and unmeasured separately. A debt baseline does not waive findings and
cannot excuse incomplete measurement. Source dependency edges order work and
group cycles; they are declared edges, not a resolved SwiftPM build graph.
Package builds, tests and downstream compatibility still require package-level
verification before promoting another compliance reference.

Additional verified routes:

- Engine at fa7c11c: `lint-local --config /path/to/policy-linter-config.json test`
  passed all 150 tests in 119 suites, including both spawned executables.
  Run `20261010T133625Z-b7d05837`; complete output in `tests.log`.
- Fresh ordinary edit loop: `python3 scripts/tests/integration.py` passed all
  17 cases, including real local rule mutation/restoration and compiler failure.
  `fresh-local-edit-workflow-final.log` retains the evidence directory.
- Fresh Xcode workspace: both explicit scheme resolution and executable build
  returned 0. Exact argument arrays are in `fresh-workspace-commands.json`.
  The resolve log shows all six local bindings. Build command:
  `xcodebuild -workspace .local-linter/Linter.xcworkspace -scheme swift-linter
  -derivedDataPath .local-linter/DerivedData -destination platform=macOS
  MACOSX_DEPLOYMENT_TARGET=27.0 build` (one line). Upstream dependency warnings
  remain recorded; Xcode-native tests are not the verified test route.
- Locked reference test command: `swift test --force-resolved-versions
  --build-system native -Xswiftc -target -Xswiftc arm64-apple-macosx27.0`
  passed all 15 tests, including exit statuses 0 and 37.
