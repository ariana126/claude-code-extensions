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
