---
name: test-guideline
description: >
  Use this skill when writing, reviewing, or refactoring tests in any codebase.
  Triggers include: writing unit tests, integration tests, or end-to-end tests;
  reviewing test quality or test coverage; deciding what to mock or stub;
  structuring test files; naming test cases; setting up database tests;
  refactoring complex code to make it testable; evaluating whether a test is
  worth keeping; or applying the Arrange-Act-Assert pattern. Also use when the
  user mentions "test pyramid", "test smells", "mocking strategy", "test naming",
  "humble object pattern", "black-box testing", "AAA pattern", "SUT", or asks
  whether something should be unit-tested or integration-tested. Use this skill
  even if the user just says "write tests for this" or "add test coverage" without
  specifying a methodology — this skill provides the methodology.
license: MIT
metadata:
  version: "1.0"
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

**It is better to have no test than a test that provides little or no value.**

## Unit vs. Integration Test

A test qualifies as a **unit test** only if it meets *all* of:

1. **Single behavior** — it verifies one discrete unit of behavior.
2. **Fast** — it executes quickly (milliseconds, not seconds).
3. **Isolated from other tests** — it can run in parallel or in any order.

If any criterion is missing, the test is an **integration test**. End-to-end
tests are a subset of integration tests that span more components.

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
| Bug detection          | How much production code is actually exercised           |
| Refactoring resistance | Whether the test avoids false positives (binary: 0 or 1)|
| Execution speed        | How quickly it runs                                      |
| Maintainability        | Setup complexity and readability                         |

A test scoring near zero on *any* dimension drags the product to zero —
delete or rewrite it rather than keeping it around.

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
not the test.

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

## Mocking Guidelines

Mocks exist to verify interactions with **unmanaged, out-of-process
dependencies** — things your system does not own (third-party APIs, message
brokers, external services).

| Dependency type                        | What to use in tests             |
|----------------------------------------|----------------------------------|
| Unmanaged out-of-process (3rd-party)   | Mocks or spies                   |
| Managed out-of-process (own database)  | Real instances (integration test) |
| In-process collaborators               | Real instances                    |

When mocking at the system boundary, verify both:
- The mock received the **expected calls**.
- The mock received **no unexpected calls**.

This catches regressions *and* preserves backward compatibility.

## Database Testing

- Use a **separate transaction or unit of work** for each section of AAA
  (Arrange, Act, Assert) when interacting with the database.
- Start each test with a **cleanup phase** to remove leftover data — this
  keeps tests fast and order-independent.

## Handling Complex or Overcomplicated Code

When code tangles business logic with orchestration, apply the **humble object
pattern**:

1. Extract pure domain logic into a standalone class — unit-test it heavily.
2. Leave the orchestration layer thin — integration-test it with one happy path.

This lets you get high coverage without fighting infrastructure concerns.

## What NOT to Test

- **Trivial code** — simple property accessors, data containers, or code
  with no meaningful logic, domain significance, or collaboration.
- **Private methods** — verify their behavior through the public API. If a
  private method is complex enough to "need its own tests," that is a signal
  to extract it into a separate class.

## Anti-Patterns and Test Smells

Read `references/ANTI_PATTERNS.md` for the full catalogue of test smells.
Key ones to watch for:

- **Multi-line Act section** — likely an encapsulation violation.
- **Exposing state for testing** — never make internals public just so a test
  can assert on them.
- **Implementation details in assertions** — assert on *outcomes*, not *how*
  the code got there.
- **Production code that exists only for tests** — e.g., `if (isRunningInTest)`
  branches. Remove these.
- **Static time dependencies** — always inject time as a value or parameter,
  never call `DateTime.Now` or `Date.now()` inside production code.

## Quick Checklist Before Merging a Test

- [ ] Does it verify one behavior?
- [ ] Is the Act section a single line?
- [ ] Is the SUT clearly named?
- [ ] Does the test name describe the scenario in domain language?
- [ ] Are mocks used only for unmanaged out-of-process dependencies?
- [ ] Is the test black-box (no coupling to implementation)?
- [ ] Would this test survive a refactor that preserves behavior?
- [ ] Does the test actually provide value (score > 0 on all four dimensions)?
