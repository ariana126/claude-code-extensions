# Chapter 5: Using Objects

## Core Idea
Every method follows the same five-part skeleton: **clear the table before starting the work.** Reject bad arguments, handle failures you can recognize, do the actual job, optionally verify, return. And exceptions come in exactly two flavors, distinguished by one question: could you have known from the argument alone?

## Frameworks Introduced

- **The method template** — the chapter's spine:
  ```
  [scope] function methodName(type name, ...): void|[return-type]
  {
      [precondition checks]
      [failure scenarios]
      [happy path]
      [postcondition checks]
      [return void|specific-return-type]
  }
  ```
  - When to use: every method you write.
  - Note the ordering is deliberate — everything that can go wrong is dealt with *before* the happy path, so the happy path reads as pure intent. If your methods are small, the happy path is often the shortest section.

- **The two-exception rule**:
  - **`InvalidArgumentException`** (and `LogicException`) — *the client made a programming mistake*. You could tell just by inspecting the argument. Fail hard; don't recover.
  - **`RuntimeException`** — *an external condition broke the method*. The argument looked fine; the world didn't cooperate. Recoverable, translatable to user-facing messages.
  - **The test**: *Could you know this is wrong by looking only at the value provided?* Negative integer where positive was required → `InvalidArgumentException`. File not found → `RuntimeException`.

- **Exception naming templates**:
  - Logic/argument errors: fill in **"Invalid …"** → `InvalidEmailAddress`, `InvalidTargetPosition`, `InvalidStateTransition`.
  - Runtime errors: finish the sentence **"Sorry, [I] …"** → `CouldNotFindProduct`, `CouldNotStoreFile`, `CouldNotConnect`.
  - Class names do **not** need to end in "Exception."

- **When a custom exception class is justified** (three cases only):
  1. You want to `catch` that specific type higher up.
  2. There are multiple ways to instantiate one type of failure.
  3. You want named constructors so the message is assembled inside the exception, not at the call site.

- **Replace primitive with object** (Fowler/Beck refactoring, applied to preconditions): move an assertion from every method that takes the primitive into the constructor of a new type — the precondition then disappears from all of them.

## Key Concepts
- **Precondition check**: An assertion at the top of a method verifying the arguments are usable. Superficial by design — it only catches obvious issues.
- **Failure scenario**: A condition the method *itself* recognizes as failure after arguments passed inspection (record not found, service unreachable).
- **Happy path**: The part where nothing is wrong and the method just does its job.
- **Postcondition check**: A "this should never happen" safety check on the result before returning.
- **Return early**: As soon as you know what you'll return — or that you must throw — do it. Don't carry the value through more `if` clauses.

## Mental Models
- **Bubble up what isn't yours.** Downstream methods throw their own exceptions. Your method only handles the failure scenarios *it* can recognize; the rest belong to a higher-level error handler.
- **A named constructor makes the throw site read like a sentence**: `throw CouldNotFindProduct.withId(productId)` — "could not find product with ID." The message lives with the exception, not scattered across call sites.
- **Strong types delete postcondition checks.** If the return type is an object, it cannot be in an invalid state — the check is already made. Postconditions earn their keep mainly in legacy code with implicit casts and no assertions.
- **Eliminate `else`.** Restructure so the failure case throws or returns at the top.

## Anti-patterns
- **Custom exception classes for invalid arguments** (repeating Ch 3): an invalid argument is a bug to fix, not a condition to catch.
- **Assembling exception messages at the call site**: duplicated, drifts, and clutters the throwing method. Use a named constructor.
- **Wrapping the happy path in the `if` and throwing in the `else`**: inverts the template. Check for failure first, then fall through to the work.
- **Adding postcondition checks reflexively**: if you have tests, you already know the method returns the right value.
- **Not checking for `null`** in languages that permit it despite a declared type — this is the `NullPointerException` waiting to happen. Make it compiler-assisted where possible (e.g. Java's Checker Framework).

## Code Examples

The template, populated — precondition, failure scenario, happy path:

```php
public function getRowById(int id): array
{
    // precondition — knowable from the argument alone → InvalidArgumentException
    Assertion.greaterThan(id, 0, 'ID should be greater than 0');

    record = this.db.find(id);       // may throw its own exceptions; let them bubble up

    // failure scenario — argument was fine, the world wasn't → RuntimeException
    if (record == null) {
        throw new RuntimeException('Could not find record with ID "{id}"');
    }

    return record;                   // happy path
}
```
- **What it demonstrates**: The same method throws both exception categories, for structurally different reasons.

Custom exception with multiple named constructors:

```php
final class CouldNotPersistObject extends RuntimeException
{
    public static function becauseDatabaseIsNotAvailable(): CouldNotPersistObject {
        return new CouldNotPersistObject(/* ... */);
    }

    public static function becauseMappingConfigurationIsInvalid(): CouldNotPersistObject {
        return new CouldNotPersistObject(/* ... */);
    }
}

final class CouldNotFindProduct extends RuntimeException
{
    public static function withId(ProductId productId): CouldNotFindProduct {
        return new CouldNotFindProduct('Could not find a product with ID "{productId}"');
    }
}

throw CouldNotFindProduct.withId(productId);
```
- **What it demonstrates**: `because…` names the *reason*; `with…` names the *ingredients*. One class covers several failure modes without a class explosion.

## Reference Tables

| Situation | Exception | Recoverable? |
|---|---|---|
| Negative int where positive required | `InvalidArgumentException` | No — fix the bug |
| Value not in allowed set | `InvalidArgumentException` | No |
| Illegal state transition | `LogicException` | No |
| File not found | `RuntimeException` | Yes |
| Database unavailable | `RuntimeException` | Yes |
| Record ID doesn't exist | `RuntimeException` | Yes |

| Method section | Throws | Usually needed? |
|---|---|---|
| Precondition checks | `InvalidArgumentException` | Yes — unless types made it impossible |
| Failure scenarios | `RuntimeException` | Yes, where the method can recognize failure |
| Happy path | — | Yes (often the shortest part) |
| Postcondition checks | `RuntimeException` / assertion | Rarely — mostly legacy code |

## Worked Example

**Fixing the statement arrangement in `pop()`** — the chapter's exercise, and the template in miniature:

```php
// Before — happy path nested inside the if, failure in the else
public function pop(): Element
{
    if (count(this.elements) > 0) {
        lastElement = array_pop(this.elements);
        return lastElement;
    } else {
        throw new RuntimeException('There are no more elements');
    }
}

// After — failure check first, then fall through to the work
public function pop(): Element
{
    if (count(this.elements) == 0) {
        throw new RuntimeException('There are no more elements');
    }

    lastElement = array_pop(this.elements);
    return lastElement;
}
```

Two rules applied at once: **move failure conditions to the top**, and **always look for a way to remove the `else`**. Note the exception type — an empty stack isn't something the caller could have seen in an argument, so it's a `RuntimeException`.

**And the precondition-elimination move**, from §5.1.1:

```php
// Before — every method taking an email address repeats the assertion
public function sendConfirmationEmail(string emailAddress): void {
    Assertion.email(emailAddress);
    // ...
}

// After — the assertion moves once, into a type
final class EmailAddress {
    private string emailAddress;
    public function __construct(string emailAddress) {
        Assertion.email(emailAddress);
        this.emailAddress = emailAddress;
    }
}

public function sendConfirmationEmail(EmailAddress emailAddress): void {
    // no validation needed here, or in any other method that takes one
}
```

## Key Takeaways
1. Every method follows: preconditions → failure scenarios → happy path → postconditions → return.
2. `InvalidArgumentException` when the value itself is wrong; `RuntimeException` when the world is. That single question settles every case.
3. Name logic exceptions "Invalid…"; name runtime exceptions by finishing "Sorry, I …" → "CouldNot…". Drop the "Exception" suffix.
4. Create a custom exception class only to catch it specifically, to cover multiple failure reasons, or to get named constructors.
5. Named constructors put message assembly inside the exception class — `throw CouldNotFindProduct.withId(id)`.
6. Return early and throw early; restructure to eliminate `else`.
7. Delete preconditions by introducing types; delete postconditions by returning objects instead of primitives.
8. Let other methods' exceptions bubble up to a higher-level handler — handle only the failures your method can recognize.

## Connects To
- **Ch 3 §3.7**: assertions and the "don't collect exceptions" rule; §3.3's ban on custom invalid-argument classes gets its counterpart here
- **Ch 4 §4.11**: `LogicException` for invalid state transitions is a precondition check on a modifier
- **Ch 6 & 7**: the return-value and command halves of the template split into query methods and command methods
- **Design by Contract** (Meyer): preconditions/postconditions are borrowed directly
- **Refactoring** (Fowler/Beck): "replace primitive with object"
