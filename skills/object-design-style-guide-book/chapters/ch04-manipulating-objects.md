# Chapter 4: Manipulating Objects

## Core Idea
Default to immutable. Entities are the deliberate exception — they're mutable because tracking change *is* their job. The naming convention tells clients which kind they're holding: **imperative name + `void`** means the object mutated; **declarative name + returns its own type** means you got a modified copy.

## Frameworks Introduced

- **The three object kinds and their mutability**:
  - **Entity** — identifiable, mutable, tracks changes, records domain events. Gets an identifier at construction so a repository can save and re-fetch it.
  - **Value object** — replaceable, anonymous, immutable. No identity; you never track what happened to one, you just make a new one.
  - **DTO** — public properties, few rules; design quality matters less because it holds no invariants.

- **Command method** (for mutable objects): imperative name, `void` return type, allowed to change internal state.
  - Examples: `addLine()`, `finalize()`, `moveLeft()`, `cancel()`.
  - How to spot mutability in a body: an assignment to `this.someProperty` plus a `void` signature.

- **Declarative modifier** (for immutable objects): returns a modified copy, typed as the class itself.
  - **The naming template**: fill in *"I want this …, but …"*. "I want this position, but n steps to the left" → `toTheLeft(steps)`. Produces `with…` names and past-tense participles: `withDiscountApplied()`, `withDenominator()`, `toTheLeft()`.
  - Aim domain-specific, not technical: `toTheLeft()` over `withXDecreasedBy()`.

- **Two templates for building the copy**:
  1. **Through the constructor** — `return new Fraction(this.numerator, newDenominator)`. **Prefer this**: you get the constructor's assertions for free.
  2. **Via `clone`** — useful for objects with many properties, but you must repeat the validation yourself, which is exactly how bugs creep in.

- **Use internally recorded events to verify changes on mutable objects**: Instead of adding getters so tests can peek inside, have the entity append event value objects to a private list and expose `recordedEvents()`.
  - When to use: testing any state change on an entity.
  - Why it works: the same event log that makes the entity testable is the domain-event stream that event listeners, read models, and search indexes consume later (Ch 8). You get it once and use it twice.
  - You may skip recording when nothing actually changed (`moveLeft(0)` → return early, no exception, no event).

## Key Concepts
- **Domain event**: A small value object recording that something happened inside an entity — `SalesInvoiceFinalized`, `PlayerMoved`.
- **State transition**: A change that unlocks or forecloses future operations (delivered → can't cancel; cancelled → can't deliver).
- **Fluent interface**: Modifier methods returning `this`, enabling chaining.
- **Equality vs. sameness**: Equality compares contained data; sameness compares memory references.

## Mental Models
- **Immutable objects behave like integers.** `i++` doesn't change the number 1 — it puts a different number in `i`. Same with `year = year.next()`. Forgetting to reassign is the classic mistake.
- **"Replace values, don't modify them."** A mutable object holding immutable values changes by swapping the value out: `this.position = this.position.toTheLeft(steps)`.
- **Immutability is only as deep as your weakest property.** Returning an internal mutable `Collection` from a getter makes the whole object indirectly mutable, no matter how careful the modifiers are.
- **If a test passes but the code is wrong, the test is what's broken.** When `moveLeft()` records an event without updating `position` and the test still passes, either write the test that forces the update — or delete the `position` property, since no observable behavior depends on it.

## Anti-patterns
- **Fluent interfaces on mutable objects**: `QueryBuilder.where()` returns `this` after mutating. Signatures look immutable, so clients reuse "intermediate stages" and get silently corrupted results. (Noback names the real culprit: Doctrine DBAL's `QueryBuilder`.)
- **Mixed naming signals**: `setPrice(Money): Product` — imperative name with a non-void return; `withPassword(...): void` — declarative name with void. The reader can't tell what happens without opening the implementation.
- **Modifier methods that mutate a shared object** (`Appointment.reminderTime()` calling `this.time.modify()`): asking for the reminder time silently changes the appointment time.
- **Getters added only so a test can check a change**: use recorded events instead.
- **Returning the new state from a command method** to make it testable: violates the void rule, *and* the test still passes against an implementation that never assigns.
- **Assertions in some modifiers but not others**: `Range.withMaximum()` checks max > min, `withMinimum()` doesn't — so `minimum` can exceed `maximum`.
- **`assertSame()` on value objects**: identity is meaningless for them; always `assertEquals()`.

## Code Examples

Both modifier templates side by side:

```php
// Template 1 — through the constructor. Validation is reused automatically.
final class Fraction {
    private int numerator;
    private int denominator;

    public function __construct(int numerator, int denominator) {
        Assertion.notEq(denominator, 0, 'The denominator of a fraction cannot be 0');
        this.numerator = numerator;
        this.denominator = denominator;
    }

    public function withDenominator(newDenominator): Fraction {
        return new Fraction(this.numerator, newDenominator);   // assertion runs again
    }
}

// Template 2 — clone. You must re-assert yourself.
final class TotalDistanceTraveled {
    private int totalDistance = 0;

    public function add(int distance): TotalDistanceTraveled {
        Assertion.greaterOrEqualThan(distance, 0, 'You cannot add a negative distance');
        copy = clone this;
        copy.totalDistance += distance;
        return copy;
    }
}
```
- **What it demonstrates**: Template 1 is why Noback says routing through the constructor "can be a good reason not to use `clone`."

Making a modifier smarter instead of setter-like:

```php
// Weak — client does the math, and has to know about x
public function withX(int x): Position { copy = clone this; copy.x = x; return copy; }
nextPosition = position.withX(position.x() - 4);      // "move 4 steps left", awkwardly

// Better — the object does the math, and x stays private
public function toTheLeft(int steps): Position {
    copy = clone this;
    copy.x = copy.x - steps;
    return copy;
}
nextPosition = position.toTheLeft(4);
```
- **What it demonstrates**: Look at how clients *use* a modifier to discover the method it should have been. A `withX()` that forces callers to compute the new value is a setter wearing a disguise.

## Reference Tables

| | Entity | Value object | DTO |
|---|---|---|---|
| Identifiable | Yes (ID at construction) | No | No |
| Mutable | Yes | No | Yes |
| Modifier style | Command: imperative + `void` | Declarative + returns own type | Direct property assignment |
| Exposes change via | Recorded domain events | N/A (replaced, not changed) | N/A |
| Fluent interface | **Never** | Free — it emerges naturally | N/A |

| Signature | Object is… |
|---|---|
| `setPassword(string): void` | Mutable (command method) |
| `withPassword(string): User` | Immutable (modified copy) |
| `withPassword(string): void` | Mutable — but badly named; declarative name, void return |
| `setPrice(Money): Product` | Confused — imperative name, non-void return |

| Comparing objects | Use |
|---|---|
| Value objects in a **test** | `assertEquals()` — recursive data comparison |
| Value objects in **production code** | A custom `equals(Position other): bool` — but only if a non-test client needs it |
| The same injected instance | `assertSame()` is acceptable |

## Worked Example

**Testing `Player.moveLeft()`** — Noback walks through four approaches and rejects three:

```php
// Attempt 1 — a getter, added purely for the test
player.moveLeft(4);
assertEquals(new Position(6, 20), player.currentPosition());
// Rejected: forces a getter no other client wants.

// Attempt 2 — compare the whole object
assertEquals(new Player(new Position(6, 20)), player);
// Rejected: covers too much ground; any new constructor argument breaks this test.

// Attempt 3 — make the command method return the new state
public function moveLeft(): Position {
    this.position = this.position.toTheLeft(steps);
    return this.position;
}
// Rejected twice over: violates "command methods return void", AND this
// broken implementation passes the same test:
public function moveLeft(): Position { return this.position.toTheLeft(steps); }

// Attempt 4 — record an event. Accepted.
final class Player {
    private Position position;
    private array events = [];

    public function __construct(Position initialPosition) { this.position = initialPosition; }

    public function moveLeft(int steps): void {
        nextPosition = this.position.toTheLeft(steps);
        this.position = nextPosition;
        this.events[] = new PlayerMoved(nextPosition);
    }

    public function recordedEvents(): array { return this.events; }
}

player.moveLeft(4);
assertEquals([new PlayerMoved(new Position(6, 20))], player.recordedEvents());
```

**The follow-on problem Noback raises against himself**: once the constructor also records `PlayerTookInitialPosition`, that `assertEquals` on the whole list breaks. Loosening it to `assertContains(...)` fixes the brittleness — but now an implementation that records the event *without updating `position`* also passes.

His resolution is the sharpest methodological point in the chapter: **that implementation isn't broken; the test suite is incomplete.** Either write a test that forces `position` to be updated, or — if you can't think of a reason such a test should exist — delete the `position` property entirely. Nothing observable changes.

## Key Takeaways
1. Default to immutable. Services: immutable. Entities: mutable by design. Everything else: immutable.
2. Mutable modifiers are command methods — imperative name, `void`, no return value. No exceptions.
3. Immutable modifiers get declarative names from *"I want this …, but …"*, and return a modified copy of their own type.
4. Build copies through the constructor when you can, so validation is reused automatically.
5. Every modifier must leave a valid object: validate the arguments **and** verify the state transition is legal. Repeat calls can usually be ignored rather than thrown on.
6. Never give a mutable object a fluent interface; immutable objects get one for free.
7. Test entity changes through recorded domain events, not added getters.
8. Compare value objects by equality, never by reference; add `equals()` only when production code needs it.
9. Immutability is transitive — a getter returning a mutable collection undoes it.

## Connects To
- **Ch 3**: constructors protect invariants at creation; modifier methods protect them at every change afterward
- **Ch 6**: how to get information out of an entity that only exposes an event log
- **Ch 7**: command methods get their full treatment — scope, exceptions, mocks
- **Ch 8**: recorded domain events become the mechanism for building read models
- **Event Sourcing / CQRS**: `recordedEvents()` is the entry point to both
