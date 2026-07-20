---
name: test-guideline
description: >
  Use this skill when writing, reviewing, or refactoring tests in any codebase.
  Triggers include: writing unit, integration, or end-to-end tests; reviewing
  test quality or coverage; deciding what to mock or stub; naming test cases;
  setting up database tests; refactoring complex code to make it testable;
  deciding which parts of a codebase deserve tests at all; or evaluating whether
  a test is worth keeping. Also use when the user mentions "test pyramid", "test
  smells", "mocking strategy", "humble object pattern", "functional core",
  "black-box testing", "AAA pattern", "SUT", "observable behavior", "coverage
  target", or "in-memory database for tests". Use this skill even if the user
  just says "write tests for this", "this code is hard to test", or "add test
  coverage" without naming a methodology — this skill provides the methodology.
license: MIT
metadata:
  version: "1.1"
  author: ariana.maghsoudi82@gmail.com
  sources: 
    - "Unit Testing Principles, Practices, and Patterns book by Vladimir Khorikov"
---

# Test Guideline Skill

This skill encodes a team's testing philosophy based on the **classic school of
testing** (as opposed to the London school). The classic school minimizes
coupling to implementation details and avoids tests that break on every
refactor (false positives). The foundational reference is *Unit Testing
Principles, Practices, and Patterns* by Vladimir Khorikov.

## Testing Philosophy at a Glance

Prefer **black-box testing** over white-box. Tests should verify *observable
behavior*, not internal mechanics. A test that breaks when you rename a private
method is a liability, not an asset.

The goal of testing is **sustainable growth of the project** — not finding bugs,
not hitting a coverage number, not proving the design is good. Test code is
code, and code is a liability.

**It is better to have no test than a test that provides little or no value.**

## Observable Behavior vs. Implementation Details

This distinction is the root of nearly every testing problem, so it is worth
getting exactly right. Code is part of **observable behavior** only if it does
one of two things:

- Exposes an **operation** that helps the client achieve one of its **goals**.
- Exposes **state** that helps the client achieve one of its goals.

Everything else is an implementation detail. Note that this **depends on who the
client is**. For a domain class, the client is the application service calling
it. For an application service, the client is the external caller. The same
method can be observable behavior from one vantage point and an implementation
detail from another.

Think of the system as onion layers: **test each layer from the point of view of
the layer outside it**, disregarding how it talks to the layers beneath. As you
peel inward, what was an implementation detail becomes observable behavior,
covered by a different set of tests.

**False positives have exactly one cause: coupling to implementation details.**
The cure is always the same — verify the end result, never the steps taken to
produce it.

A useful design signal falls out of this: if the client needs to call **more
than one operation** to achieve a single goal, the class is probably leaking
implementation details. Fix the production API rather than teaching the test to
perform the dance.

## Unit vs. Integration Test

A test qualifies as a **unit test** only if it meets *all* of:

1. **Single behavior** — it verifies one discrete unit of behavior.
2. **Fast** — it executes quickly (milliseconds, not seconds).
3. **Isolated from other tests** — it can run in parallel or in any order.

If any criterion is missing, the test is an **integration test**. End-to-end
tests are a subset of integration tests that span more components.

Test **units of behavior, not units of code**. A test should tell a story that
means something to a non-programmer: *"when I call my dog, he comes right to
me"* — not a description of which legs moved. One unit of behavior may span
several classes, and that is fine.

## Test Pyramid Strategy

Follow this distribution:

- **Unit tests** — as many as reasonably possible, covering domain and
  application layers.
- **Integration tests** — fewer, typically one happy-path per use case.
- **End-to-end tests** — only a handful, covering critical user journeys.

## Evaluating Whether a Test Is Worth Writing

Score each test on four dimensions (0 to 1), then multiply:

| Dimension              | What it measures                                        |
|------------------------|---------------------------------------------------------|
| Protection against regressions | How much production code is actually exercised, and how significant it is |
| Resistance to refactoring | Whether the test avoids false positives          |
| Fast feedback          | How quickly it runs                                      |
| Maintainability        | Setup complexity and readability                         |

A test scoring near zero on *any* dimension drags the product to zero —
delete or rewrite it rather than keeping it around.

Two things about this model matter more than the model itself:

**The first three are mutually exclusive.** Like CAP, you get two of three. A
test that exercises a lot of significant code cannot also be instant, and
staying immune to refactoring costs you reach. Accept the trade; don't pretend
you can win all three.

**Resistance to refactoring is non-negotiable.** Unlike the others it is
effectively **binary** — a test either survives behavior-preserving refactors or
it doesn't. You cannot concede "just a little" of it, because the moment a test
produces false alarms the team starts ignoring failures, and the whole suite
stops being a signal. So: max out resistance to refactoring and maintainability,
and slide the trade-off between protection and speed.

## Where to Spend Testing Effort

Not all code repays testing equally. Classify production code on two independent
axes — **complexity or domain significance**, and **number of collaborators** —
and let the quadrant decide the strategy:

|                                 | Few collaborators                          | Many collaborators                     |
|---------------------------------|--------------------------------------------|----------------------------------------|
| **High complexity/significance**| **Domain model & algorithms** → unit test heavily; best return | **Overcomplicated** → refactor it out of existence |
| **Low complexity/significance** | **Trivial code** → don't test               | **Controllers** → brief integration tests |

The top-left wins because complexity and domain significance buy protection
against regressions, while few collaborators keep maintenance cheap — valuable
*and* inexpensive. The top-right is the trap: expensive to test and expensive to
maintain, so the answer is never "write more tests for it," it's **split it**.

The governing rule: **the more important or complex the code, the fewer
collaborators it should have.** Code can be *deep* (complex) or *wide* (many
collaborators), never both.

A collaborator is any **mutable or out-of-process dependency**, whether passed in
explicitly or reached implicitly through a static call or singleton — if you have
to set it up, it counts. **Immutable values don't count**, however many there
are.

**Read `references/code-classification.md`** when you find code in the
overcomplicated quadrant and need to split it — it covers the Humble Object
pattern, the CanExecute/Execute pattern, domain events, and the trade-offs
involved in each.

## Choosing a Testing Style

Three styles, in order of preference:

| Style | You verify | Refactoring resistance | Maintainability |
|-------|------------|------------------------|-----------------|
| **Output-based** | The value returned for a given input | High | High |
| **State-based** | The state of the system afterward | Medium | Medium |
| **Communication-based** | That the SUT called its collaborators correctly | Low | Low |

Protection against regressions and speed are roughly equal across all three —
they depend on how much code runs, not on style. The ranking is entirely about
the other two pillars.

Output-based tests win because they couple to nothing but the method's signature.
But the style is only available on code with **no hidden inputs or outputs** —
no side effects, no reliance on internal or external state, no exceptions
carrying meaning. You cannot choose it for arbitrary code; you earn it by
structuring the code so it qualifies.

So when a test feels awkward, ask which style it is stuck in and whether the
production code could be reshaped to allow a better one. That reshaping is
usually worth more than any change to the test.

**Read `references/testing-styles.md`** when deciding how to restructure code to
make output-based testing possible — it covers what makes a function pure,
functional core / mutable shell, and importantly when *not* to apply it.

## How to Structure a Test

### AAA Pattern (Arrange-Act-Assert)

Every test follows three sections:

```
// Arrange — set up the SUT and its dependencies
// Act    — invoke the behavior under test (one line only)
// Assert — verify the observable outcome
```

**The Act section must be a single line.** Multiple lines in Act often signal
an encapsulation problem or a poorly designed API — fix the production code,
not the test. A bloated Assert section is a different signal: usually a missing
abstraction, often a value object waiting to be extracted.

### Naming the System Under Test

Always assign the object being tested to a variable named `sut` (or `SUT`
depending on language convention). This makes it immediately clear what is
under test.

### Test Naming

Name tests as if describing the scenario to a non-programmer who understands
the domain. Use underscores to separate words.

- **Do**: `delivery_with_past_date_is_invalid`
- **Don't**: `Test_DeliveryService_ValidateDeliveryDate_ReturnsFalse`

Rules:
- Do not embed the method name under test in the test name.
- Avoid rigid naming templates — clarity matters more than consistency.
- Prefer `is` over `should be`. A test states a fact about the domain.

### Never Reimplement the Algorithm in the Test

If the test computes its expected value using the same logic as the production
code, it will agree with the implementation even when both are wrong, and it
will break whenever the implementation is refactored. Hardcode results
calculated **outside** the SUT — by hand, from a specification, or from a known
good source.

### Reuse Setup via Factory Methods, Not Constructors

Sharing fixtures through the test class's constructor or a `beforeEach` couples
every test in the file to one arrangement, so a change made for one test
silently reshapes the others. Private factory methods with sensible defaults
give the same reuse without the coupling — and letting each test override only
the arguments it cares about makes the relevant detail obvious to the reader.

## Mocking Guidelines

Mocks exist to verify interactions with **unmanaged, out-of-process
dependencies** — things your system does not own (third-party APIs, message
brokers, SMTP servers).

| Dependency type                        | What to use in tests             |
|----------------------------------------|----------------------------------|
| Unmanaged out-of-process (3rd-party)   | Mocks or spies                   |
| Managed out-of-process (own database)  | Real instances (integration test) |
| In-process collaborators               | Real instances                    |

The reason for the split is backward compatibility. Communications with an
**unmanaged** dependency are visible to other systems, so they are part of your
observable behavior and their shape must not change silently — that is worth
asserting on. Communications with a **managed** dependency are invisible to
anyone but you, which makes them implementation details; only the resulting
**final state** matters, so verify that instead.

Further rules that follow from this:

- **Never assert interactions with stubs.** A stub call is a means, not an end.
  Mocks map to commands, stubs to queries; only commands are worth verifying.
- **Mock the last type in the chain** before the call leaves your application,
  so you verify the actual payload going out rather than a call to your own
  wrapper.
- **Mocks belong in integration tests.** A mock in a unit test means your domain
  model is touching something it shouldn't — treat it as a design signal.
- **Never mock calls between your own domain classes.** Those are implementation
  details from every client's perspective.

When mocking at the system boundary, verify both:
- The mock received the **expected calls**.
- The mock received **no unexpected calls**.

## Database Testing

Three rules carry most of the value:

1. **Use the same DBMS vendor as production.** Swapping Postgres for SQLite or
   an in-memory fake makes tests faster and worthless — the substitute is not
   functionally consistent with the real thing, so you get false positives and,
   far worse, false negatives. Version or edition may differ; the vendor must
   not.
2. **Clean data at the *start* of each test**, not the end. End-of-test cleanup
   gets skipped whenever a run crashes or someone stops in the debugger, and the
   leftovers poison the next run.
3. **Use a separate transaction or unit of work for each AAA section.** Sharing
   one across the test means the Assert section may read the ORM's cache rather
   than what actually landed in the database — which is the one thing the test
   exists to check.

**Read `references/database-testing.md`** when setting up a suite against a real
database — it covers migrations, reference data, cleanup scripts, Object Mother,
and why repositories should not be tested directly.

## Handling Complex or Overcomplicated Code

When code tangles business logic with orchestration, apply the **humble object
pattern**:

1. Extract pure domain logic into a standalone class — unit-test it heavily.
2. Leave the orchestration layer thin — integration-test it with one happy path.

This lets you get high coverage without fighting infrastructure concerns.

Be aware that merely **extracting an interface** for the awkward dependency and
injecting it is *not* the fix. The logic still sits next to an out-of-process
call, still needs mock machinery, and mocking a database still produces fragile
tests. The dependency has to move out of the logic entirely.

## What NOT to Test

- **Trivial code** — simple property accessors, data containers, or code
  with no meaningful logic, domain significance, or collaboration.
- **Private methods** — verify their behavior through the public API. If a
  private method is complex enough to "need its own tests," that is a signal
  to extract it into a separate class.
- **Preconditions without domain significance** — a guard like `data.length >= 3`
  protects against programmer error; a guard like `employeeCount + delta >= 0`
  encodes a business invariant. Test the second kind only.

### On coverage numbers

Coverage is a **good negative indicator and a bad positive one**. Low coverage
reliably tells you something is untested; high coverage tells you almost
nothing, since a test can execute a line without asserting anything meaningful
about it.

**Never mandate a coverage number.** The moment a percentage becomes a target,
the cheapest way to hit it is to write the worthless tests this whole guideline
exists to prevent. Use coverage to find gaps and then judge each gap on its
merits.

## Anti-Patterns and Test Smells

Read `references/ANTI_PATTERNS.md` for the full catalogue of test smells, and
consult it whenever reviewing existing tests or when a test feels "off" but you
can't pinpoint why. Key ones to watch for:

- **Multi-line Act section** — likely an encapsulation violation.
- **Exposing state for testing** — never make internals public just so a test
  can assert on them.
- **Implementation details in assertions** — assert on *outcomes*, not *how*
  the code got there.
- **Production code that exists only for tests** — e.g., `if (isRunningInTest)`
  branches. Remove these.
- **Static time dependencies** — always inject time as a value or parameter,
  never call `DateTime.Now` or `Date.now()` inside production code.
- **Mock chains** — a mock returning a mock returning a mock. The clearest sign
  that the test has been welded to the implementation graph.

## Quick Checklist Before Merging a Test

- [ ] Does the code under test belong in a quadrant worth testing at all?
- [ ] Does it verify one behavior, described in domain language?
- [ ] Is the Act section a single line?
- [ ] Is the SUT clearly named?
- [ ] Does it assert on observable behavior rather than internal mechanics?
- [ ] Is it using the best style available — output-based where possible?
- [ ] Are the expected values hardcoded rather than recomputed by the test?
- [ ] Are mocks used only for unmanaged out-of-process dependencies?
- [ ] Would this test survive a refactor that preserves behavior?
- [ ] Does the test actually provide value (score > 0 on all four dimensions)?
