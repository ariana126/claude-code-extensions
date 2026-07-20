# Code Classification and Refactoring Toward Testable Code

Read this when code resists testing and you suspect the problem is the code
rather than the test — particularly when something lands in the
**overcomplicated** quadrant and needs splitting.

## The Two Axes

Classify every piece of production code on two independent axes.

**Complexity or domain significance.** Complexity is roughly cyclomatic
complexity: `1 + number of branching points`. Note that `if (a && b)` counts as
two branching points, since it is equivalent to nested ifs. But complexity is not
the whole axis — a price calculation with a single code path may be trivial to
execute and still be the most business-critical line in the system. Either
property alone qualifies code for this axis.

**Number of collaborators.** A collaborator is a **mutable or out-of-process
dependency**. Two things about this definition trip people up:

- It counts **implicit** dependencies too. It makes no difference whether the
  code takes a database as a constructor argument or reaches it through a static
  call — you still have to set it up before the code will run, so it still costs
  you.
- **Immutable dependencies do not count.** A value or value object passed in is
  free; you can have a dozen without hurting testability. The distinction is
  whether the thing is a *proxy to data not yet in memory* (a collaborator) or
  *the data itself* (a value).

Out-of-process collaborators are effectively disqualifying inside a domain
model. They force mock machinery and demand constant vigilance against
fragility.

## The Four Quadrants

|                                 | Few collaborators                          | Many collaborators                     |
|---------------------------------|--------------------------------------------|----------------------------------------|
| **High complexity/significance**| **Domain model & algorithms** → unit test heavily | **Overcomplicated** → refactor away |
| **Low complexity/significance** | **Trivial code** → don't test               | **Controllers** → brief integration tests |

| Quadrant | Why it lands there | What to do |
|---|---|---|
| Domain model & algorithms | High protection, low maintenance cost | Unit test heavily — the best return available |
| Trivial code | Nothing can hide in it | Don't test; the test costs more than the bug it might catch |
| Controllers | Cheap logic, expensive setup | One or two integration tests per use case, happy path |
| Overcomplicated | Expensive to test *and* expensive to maintain | Split it — never "just write more tests" |

The governing rule: **the more important or complex the code, the fewer
collaborators it should have.** Code can be deep or wide, never both.

## The Humble Object Pattern

When code is hard to test because it is welded to a difficult dependency —
out-of-process communication, asynchronous execution, a UI framework — extract
the testable logic into its own class and leave behind a wrapper so thin, so
*humble*, that it needs no tests of its own.

The extracted logic goes to the top-left quadrant. The wrapper goes to the
bottom-right. The overcomplicated quadrant empties out.

This pattern is more familiar than it sounds — it is the same move underneath:

| Where you've seen it | Humble part | Logic part |
|---|---|---|
| Hexagonal architecture | Application services | Domain model |
| Functional architecture | Mutable shell | Functional core |
| MVC / MVP | Controller / Presenter | Model |
| DDD | The boundary around an aggregate | The aggregate's invariants |

It is also just the Single Responsibility Principle applied where one of the
responsibilities is always "business logic."

### Extracting an interface is not the same thing

The tempting half-measure is to define an interface for the awkward dependency,
inject it, and mock it in tests. This does not move the code out of the
overcomplicated quadrant. The dependency is still out-of-process, still a proxy
to data not in memory, still needs setup in every test — and mocking a database
in particular produces tests that break on every schema refactor. Making an
implicit dependency explicit is an improvement in readability, not in
testability. The dependency has to leave the logic entirely.

## The Three-Attribute Trade-off

Once you push out-of-process work out of the domain model, conditional logic
that depends on external data becomes awkward. There are three properties you
want and can only have two:

1. **Domain model testability** — a function of how many collaborators the domain
   classes have, and of what kind.
2. **Controller simplicity** — whether the controller contains decision points.
3. **Performance** — the number of calls to out-of-process dependencies.

| Option | Testability | Controller simplicity | Performance |
|---|---|---|---|
| Push all external reads/writes to the edges | yes | yes | no |
| Inject out-of-process dependencies into the domain model | no | yes | yes |
| Split decision-making into granular steps | yes | no | yes |

**Prefer the third**, then mitigate the controller complexity using the two
patterns below. The second option is the one to avoid outright — it drags the
code straight back into the overcomplicated quadrant, which is the problem you
started with.

## The CanExecute/Execute Pattern

For each `doSomething()`, introduce a `canDoSomething()` that returns the reason
it cannot (or nothing, if it can) — and make its success a **precondition** of
`doSomething()`.

```
// Controller — orchestration only
error = user.canChangeEmail()
if (error) return error

user.changeEmail(newEmail, company)
```

```
// Domain — the precondition makes the check unskippable
changeEmail(newEmail, company):
    require(user.canChangeEmail() == null)
    ...
```

Two things this buys you:

- The controller needs to know **nothing** about the rules. `canChangeEmail()`
  may bundle a dozen validations; they all stay encapsulated in the domain.
- The precondition guarantees the operation can never run unchecked.

The consequence worth internalizing: **although the controller still contains an
`if`, you do not need to test that `if`.** Unit-testing the precondition in the
domain class is sufficient, because the controller has no option not to check.
This is how you keep decision-making in the domain without the controller's
branches multiplying your integration tests.

## Domain Events

A domain event describes **something meaningful to domain experts that has
already happened** — which is what distinguishes it from a UI event like a button
click. Name them in the past tense, and make them immutable values: two events
with the same contents are interchangeable.

The mechanism: the domain class **accumulates events** during the operation
instead of performing side effects, and the controller converts them into
out-of-process calls afterward.

```
// Domain — record the fact, don't act on it
if (emailActuallyChanged):
    this.events.add(EmailChanged(userId, newEmail))
```

```
// Controller — turn facts into side effects
for (event in user.events):
    messageBus.publish(event)
```

Why this matters for testing: **it is easier to test abstractions than the
things they abstract.** Asserting that a domain object recorded an
`EmailChanged` event is a plain in-memory equality check. Asserting that a
message reached a bus requires a mock. Keeping side effects in memory until the
very end of the operation is what allows almost all verification to be
output-based or state-based.

Note the deliberate asymmetry it enables. You can persist to your own database
unconditionally — those communications are implementation details, so only the
final state matters. But messages to an external bus are observable behavior, so
the contract requires sending them **only on real changes**. Domain events let
you express that difference without fragmenting the logic.

## Business Logic Fragmentation

The most common way this refactoring goes wrong is by moving a domain check into
the controller because it is convenient there — for instance hoisting an
`isEmailConfirmed` guard out of the domain object and into the calling service.

This costs you twice. The domain model's encapsulation weakens: it is now
possible to change the email without checking the flag, because the check lives
somewhere the object cannot enforce. And the controller drifts toward the
overcomplicated quadrant, one condition at a time.

Keep decisions in the domain layer. Use CanExecute/Execute when the controller
needs to know a decision's outcome.

### Where fragmentation is genuinely unavoidable

Two cases where the logic honestly cannot live in the domain layer:

- **Checks requiring out-of-process data**, such as verifying an email address is
  unique across the system. You cannot do this without a database, and the
  database cannot go into the domain model.
- **Handling failures of out-of-process dependencies** that change the course of
  the operation. The domain layer isn't what calls them, so it can't decide what
  to do when they fail.

Put that logic in controllers and cover it with integration tests. The
separation is still worth having for everything else.

## A Note on What This Buys Beyond Tests

A testable design is a maintainable design. Separating business logic from
orchestration attacks code complexity directly, and that matters for a project's
growth whether or not anyone ever writes a test. If a refactoring in this file
seems to be "for the tests," it is worth noticing that it is usually the change
you would want anyway.
