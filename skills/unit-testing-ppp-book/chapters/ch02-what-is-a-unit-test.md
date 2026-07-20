# Chapter 2: What Is a Unit Test?

## Core Idea
A unit test **verifies a single unit of behavior, quickly, in isolation from other tests**. The word "isolation" is the fault line: the London school isolates the *class under test* from its collaborators (mock everything mutable), the classical school isolates the *tests* from each other (mock only shared dependencies). Khorikov argues for the classical school, because London-style tests couple to implementation details.

## Frameworks Introduced

- **The Three Attributes of a Unit Test** (refined over the chapter):
  - Initial form: verifies a small piece of code (a unit), does it quickly, does it in an isolated manner.
  - Final (classical) form: **verifies a single unit of behavior, does it quickly, does it in isolation from other tests.**
  - When to use: to classify any test you encounter. An **integration test is any test that fails at least one of these three criteria.**

- **The Two Schools of Unit Testing**: Every downstream disagreement flows from the single word *isolation*.
  - **London school** (a.k.a. *mockist*; Freeman & Pryce, *Growing Object-Oriented Software, Guided by Tests*): isolate the SUT from collaborators using test doubles. Unit = a class. Drives **outside-in TDD**.
  - **Classical school** (a.k.a. *Detroit*, *classicist*; Kent Beck, *Test-Driven Development: By Example*): isolate tests from each other. Unit = a class *or a set of classes*. Drives **inside-out TDD**, starting from the domain model.
  - When to use: pick classical by default. Reach for London-style isolation only where a dependency is genuinely shared.

- **The Dependency Hierarchy** — the classification that decides what to substitute:
  - A dependency is **shared** or **private**.
  - A private dependency is **mutable** or **immutable**; immutable ones are **value objects**.
  - All shared dependencies are mutable, but a mutable dependency is only shared if tests actually reuse it.
  - How to apply: substitute shared dependencies (classical). Substitute all mutable dependencies (London). Never substitute value objects — in either school.

- **Units of Behavior, Not Units of Code**: The chapter's central corrective. "Tests shouldn't verify *units of code*. Rather, they should verify *units of behavior*: something meaningful for the problem domain and, ideally, something a business person can recognize as useful. The number of classes it takes to implement such a unit of behavior is irrelevant."
  - How: after writing a test, state what it verifies as a sentence a non-programmer would understand. If you can't, you're testing code, not behavior.

## Key Concepts

- **Test double** — an object that looks and behaves like its release-intended counterpart but is a simplified version that reduces complexity and facilitates testing. Umbrella term (Meszaros, *xUnit Test Patterns*); named after a movie stunt double.
- **Mock** — a *kind* of test double that lets you examine interactions between the SUT and its collaborators. A subset of test doubles, not a synonym.
- **SUT (system under test)** — the class being verified. **MUT (method under test)** — the specific method the test calls. SUT = class, MUT = method.
- **Shared dependency** — shared between *tests*, providing a means for them to affect each other's outcome. E.g. a static mutable field, a database.
- **Private dependency** — not shared. Can be given a fresh instance per test.
- **Out-of-process dependency** — runs outside the application's process; a proxy to data not yet in memory. *Usually* shared, but not always.
- **Volatile dependency** — a dependency that either (a) requires setting up a runtime environment beyond a developer's default machine install, or (b) behaves nondeterministically (RNG, clock). Overlaps with *shared* but isn't identical.
- **Value object / value** — an immutable object with no individual identity, identified solely by its content; two with equal content are interchangeable.
- **Collaborator** — a dependency that is either shared or mutable. Value objects are dependencies but *not* collaborators.
- **Object graph** — the web of communicating classes solving the same problem, each with its own dependencies, potentially circular.
- **Over-specification** — coupling tests to the SUT's implementation details. The biggest problem with the London school.
- **End-to-end test** — a subset of integration tests covering all or nearly all out-of-process dependencies, from the end user's point of view. *UI tests*, *GUI tests*, *functional tests* are loose synonyms.

## Mental Models

- **Use the shared/private + mutable/immutable grid to decide what to mock.** You don't mock the number `5`, and for the same reason you don't mock a `Product` enum — immutability makes substitution pointless.
- **Think of a test as telling a story a non-programmer can follow.** *"When I call my dog, he comes right to me"* is a unit of behavior. *"When I call my dog, he moves his front left leg first, then the front right leg, his head turns, the tail starts wagging…"* is a unit of code — and you can no longer tell whether the dog is coming or running away.
- **A hard-to-set-up arrange phase is a design signal, not a mocking problem.** If a large object graph makes testing painful, don't reach for mocks to hide it — fix the graph. Mocks suppress the symptom the negative indicator was giving you (Ch 1).
- **Cascading test failures carry information.** If one bug fails many tests, that code is load-bearing. Fixing one failure fixes them all, and you usually know the cause anyway — it's what you edited last.
- **Shared ≠ out-of-process.** A singleton or static field is shared but in-process. A read-only API, or a database launched fresh in a Docker container per run, is out-of-process but *not* shared. (In practice the book uses the terms interchangeably, since the exceptions are rare.)

## Code Examples

**Classical style** — real collaborator, assert on final state:

```csharp
[Fact]
public void Purchase_succeeds_when_enough_inventory()
{
    // Arrange
    var store = new Store();
    store.AddInventory(Product.Shampoo, 10);
    var customer = new Customer();

    // Act
    bool success = customer.Purchase(store, Product.Shampoo, 5);

    // Assert
    Assert.True(success);
    Assert.Equal(5, store.GetInventory(Product.Shampoo));  // state verified
}
```

**London style** — mocked collaborator, assert on interactions:

```csharp
[Fact]
public void Purchase_succeeds_when_enough_inventory()
{
    // Arrange
    var storeMock = new Mock<IStore>();
    storeMock
        .Setup(x => x.HasEnoughInventory(Product.Shampoo, 5))
        .Returns(true);
    var customer = new Customer();

    // Act
    bool success = customer.Purchase(
        storeMock.Object, Product.Shampoo, 5);

    // Assert
    Assert.True(success);
    storeMock.Verify(
        x => x.RemoveInventory(Product.Shampoo, 5),
        Times.Once);   // interaction verified
}
```
- **What it demonstrates**: The arrange phase stops building real state and starts scripting responses; the assert phase stops checking *what happened* and starts checking *which call was made*. Note `Product.Shampoo` and `5` are left real in both — they're immutable value objects. Note also that London style requires introducing an `IStore` interface (mocking a concrete class is an anti-pattern — Ch 11).

## Reference Tables

| | Isolation of | A *unit* is | Uses test doubles for |
|---|---|---|---|
| **London school** | Units | A class | All but immutable dependencies |
| **Classical school** | Unit tests | A class or a set of classes | Shared dependencies |

| Dependency | Shared? | Out-of-process? | Substitute in classical tests? |
|---|---|---|---|
| Database | Yes | Yes | Yes |
| File system | Yes | Yes | Yes (not *volatile* — it's installed everywhere and deterministic) |
| Static mutable field / reused singleton | Yes | No | Yes |
| Read-only API (product catalog) | No | Yes | Usually — for speed, not isolation |
| DB in a fresh Docker container per run | No | Yes | Not required for isolation |
| Injected config object (new instance per test) | No | No | No |
| Random number generator | No (volatile) | No | Not for isolation; yes for determinism |
| `Product.Shampoo`, `5` (value objects) | No | No | Never |

| Test type | Criteria |
|---|---|
| Unit | Single unit of behavior + fast + isolated from other tests |
| Integration | Fails ≥1 unit-test criterion (shared dep, slow, or multiple units of behavior) |
| End-to-end | Integration test covering all/nearly all out-of-process dependencies |

## Worked Example

**Evaluating the London school's three selling points.** Khorikov takes each claimed benefit seriously, then shows why it doesn't survive scrutiny:

1. **"Better granularity — tests check one class at a time."**
   Rejected as a *misplaced goal*. Granularity below a unit of behavior actively damages tests: it becomes harder to understand what they verify. Coming from OO, developers treat classes as atomic building blocks and assume tests should follow — "understandable but misleading." A good test checks a single unit of behavior, however many classes that spans.

2. **"Easier to test a large graph of interconnected classes."**
   True but *aimed at the wrong problem*. Instead of finding ways to test a large, complicated graph, focus on not having one. A large class graph is usually a code-design problem, and the painful arrange phase is the good negative indicator from Ch 1 doing its job. Mocks hide the problem rather than tackling the root cause.

3. **"If a test fails, you know exactly which functionality broke."**
   Valid but *minor*. With classical tests, a bug in `Store` fails `Customer`'s tests too — a ripple effect across the suite. But if you run tests after each change, you already know the cause: it's what you edited last. Fixing one failure fixes the rest. And the cascade itself is informative: broad failure means the broken code is depended on by the whole system.

**Which out-of-process dependencies go in which test?** Suppose your app uses a database, the file system, and a payment gateway. A typical *integration* test includes the database and file system (you fully control them and can reach the required state easily) and replaces the payment gateway with a test double — using the real gateway would mean contacting the payment processor for a test account and periodically cleaning up leftover charges by hand. An *end-to-end* test would include the gateway too. Because e2e tests are the most expensive to maintain, run them late in the build, after unit and integration tests pass — possibly only on the build server.

## Key Takeaways

1. **A unit test verifies a single unit of behavior, quickly, in isolation from other tests.** An integration test is one that violates any of the three.
2. **The schools differ on one word — isolation — and everything else follows** from that: what a unit is, and which dependencies get substituted.
3. **Prefer the classical school.** The decisive reason is fragility: mock-heavy tests couple to implementation details (over-specification), which is the enemy of sustainable growth.
4. **Substitute shared dependencies, keep private ones real.** Never substitute value objects in either school.
5. **Test behavior, not classes.** A test should tell a cohesive story meaningful to a non-programmer.
6. **A painful arrange phase is a design defect, not a mocking opportunity.** Fix the object graph instead of hiding it.
7. **London leads to outside-in TDD; classical leads to inside-out TDD** starting from the domain model.

## Connects To
- **Ch 3**: The AAA (arrange–act–assert) structure used by both examples here.
- **Ch 5**: Mocks and test fragility — the full argument for why over-specification is the London school's fatal flaw, and how to tell observable behavior from implementation details.
- **Ch 8**: Working with interfaces, and why interfaces-for-mocking deserves scrutiny.
- **Ch 11**: Mocking concrete classes as an anti-pattern.
- **Part 3**: Integration testing in depth.
- **Kent Beck, *TDD: By Example*** (classical) · **Freeman & Pryce, *GOOS*** (London) · **van Deursen & Seemann, *Dependency Injection: Principles, Practices, Patterns*** (dependency management) · **Meszaros, *xUnit Test Patterns*** (test doubles).
