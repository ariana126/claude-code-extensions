# Anti-Patterns and Test Smells — Full Reference

This file expands on the anti-patterns summarized in SKILL.md. Read this when
reviewing existing tests for quality issues or when a test feels "off" but you
can't pinpoint why.

## 1. Multi-Line Act Section

**Symptom**: The Act portion of a test has two or more statements.

**Why it's bad**: This usually means the API requires multiple steps to
accomplish something that should be a single operation. The test is exposing
a design flaw in the production code.

**Fix**: Refactor the production API so the operation is a single call. The
test should then have a one-liner Act section.

## 2. Testing Private Methods Directly

**Symptom**: A test uses reflection, `@VisibleForTesting`, `internal` access,
or friend classes to call a private method.

**Why it's bad**: Private methods are implementation details. Testing them
directly couples the test to the current structure, creating fragile tests
that break on refactors.

**Fix**: Test the behavior through the public API. If the private method is
too complex to reach through public methods, extract it into its own class
with a public interface and test that class directly.

## 3. Exposing Internal State for Testing

**Symptom**: A getter, property, or field is made public solely so that tests
can read it.

**Why it's bad**: This breaks encapsulation. The internal state is not part
of the observable behavior contract; it's an implementation artifact.

**Fix**: Assert on observable outputs (return values, published events,
side effects on dependencies) rather than internal state.

## 4. Implementation Details in Assertions

**Symptom**: Assertions check *how* the code works rather than *what* it
produces — for example, verifying the exact SQL generated, the order of
internal method calls, or the specific data structure used.

**Why it's bad**: These tests are false-positive magnets. Any refactor that
preserves behavior but changes internals will break them.

**Fix**: Assert on the *outcome* — the returned value, the state of the
database after the operation, the message sent to the external system.

## 5. Production Code Existing Only for Tests

**Symptom**: Code paths like `if (Environment.IsTest)`, feature flags that
are only toggled in tests, or factory methods that are only called from test
assemblies.

**Why it's bad**: Production code should serve production purposes. Test-only
branches add complexity, risk accidental activation, and make the codebase
harder to reason about.

**Fix**: Use proper dependency injection or configuration to vary behavior
between environments. If a seam is needed for testing, it should be a real
abstraction that could have other implementations.

## 6. Static Time Dependencies

**Symptom**: Production code calls `DateTime.Now`, `Date.now()`,
`System.currentTimeMillis()`, or similar static time accessors.

**Why it's bad**: Tests cannot control time, leading to flaky tests (race
conditions around midnight, timezone issues) and inability to test
time-dependent logic deterministically.

**Fix**: Inject time as a value. Pass a `DateTimeOffset`, `Instant`, or
similar value into the method or constructor. In tests, supply a fixed value.

## 7. Over-Mocking (London School Trap)

**Symptom**: Every collaborator is mocked, even in-process classes that the
SUT owns. Tests verify a long chain of mock interactions.

**Why it's bad**: These tests mirror the implementation graph. Rename a
method or restructure collaborators and every test breaks — even if behavior
is unchanged.

**Fix**: Follow the classic school — only mock unmanaged out-of-process
dependencies. Let in-process collaborators be real objects.

## 8. Shared Mutable State Between Tests

**Symptom**: Tests share a static field, singleton, or database state that
one test modifies and another reads.

**Why it's bad**: Test order becomes significant. Tests pass individually
but fail when run together, or fail on CI but pass locally.

**Fix**: Each test should set up its own state. For database tests, begin
with a cleanup phase. For in-memory state, use fresh instances per test.

## 9. Testing Trivial Code

**Symptom**: Tests for simple property getters/setters, data transfer
objects, or single-line delegation methods.

**Why it's bad**: These tests add maintenance cost without catching real
bugs. They score near zero on the "bug detection" dimension.

**Fix**: Don't test code that has no meaningful logic, no domain
significance, and no collaboration between components. Save the effort
for code where bugs can actually hide.

## 10. Mock Chains

**Symptom**: A mock configured to return another mock, which returns another
mock, two or three layers deep before the test can reach the value it needs.

**Why it's bad**: Each link encodes a fact about the implementation's object
graph. The test now fails not only when behavior changes, but whenever anyone
reshapes the path between two collaborators — and the setup is long enough that
nobody reads it. This is the single largest driver of unmaintainable suites.

**Fix**: The depth is the message: the SUT is reaching too far. Pass in the value
it actually needs rather than the object that can produce the object that can
produce it. If the chain crosses into an out-of-process dependency, restructure
so the data is gathered before the call (see `testing-styles.md`).

## 11. Substituting an In-Memory Database

**Symptom**: Tests run against SQLite, H2, or an in-memory fake while production
runs Postgres, MySQL, or SQL Server.

**Why it's bad**: The substitute is not functionally consistent with the real
database. Type coercion, constraint enforcement, transaction semantics, and
dialect-specific SQL all differ. You get false positives from behavior that only
breaks in the fake, and false negatives from bugs it cannot reproduce — so the
protection you think you bought never existed.

**Fix**: Use the same DBMS vendor as production; version or edition may differ.
If the motivation was speed, the real levers are a local instance per developer,
cleanup at the start of the test, and pushing logic out of the database layer so
fewer tests need it at all. See `database-testing.md`.

## 12. Testing Repositories Directly

**Symptom**: A dedicated test class per repository, verifying that `save()`
saves and `findById()` finds.

**Why it's bad**: Repositories sit in the controllers quadrant — barely any
complexity, one out-of-process dependency. So these tests carry the full cost of
an integration test while the regressions they catch are already caught by the
integration tests covering the business operations that use them.

**Fix**: Cover repositories incidentally, through the tests for the operations
they serve. Where a repository holds real complexity, extract that into a
self-contained algorithm and unit test it separately.

## 13. Reimplementing the Algorithm in the Test

**Symptom**: The test computes its expected value using the same logic as the
production code — looping over the same collection, applying the same formula.

**Why it's bad**: The test agrees with the implementation by construction, so it
passes even when both are wrong. It also breaks whenever the implementation is
refactored, giving you the worst of both pillars: no protection *and* no
resistance to refactoring.

**Fix**: Hardcode results calculated outside the SUT — by hand, from the
specification, or from a known good source. If hardcoding feels impractical
because there are too many cases, that's a signal to use a parameterized test
with a handful of worked examples rather than to generate expectations in code.

## 14. Business Logic Fragmentation

**Symptom**: A domain check migrates into the controller or application service
because it was easier to write there — a status guard, a validity condition, a
state precondition.

**Why it's bad**: The domain object can no longer enforce its own invariants, so
it becomes possible to perform the operation without the check by calling the
object from anywhere else. Meanwhile the controller accumulates conditions and
drifts toward the overcomplicated quadrant, where every branch demands an
expensive integration test.

**Fix**: Keep decisions in the domain layer. Where the controller needs to know
the outcome of a decision, use the CanExecute/Execute pattern — see
`code-classification.md`. Genuine exceptions exist (checks needing
out-of-process data, such as uniqueness across the system), and those belong in
the controller with integration coverage.
