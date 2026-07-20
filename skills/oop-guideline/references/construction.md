# Object Construction — Full Reference

Read this when designing a new class from scratch, when a constructor has grown
awkward, or when deciding whether a primitive deserves to become a type.

## Contents

1. [Constructor Injection](#1-constructor-injection)
2. [Null Object](#2-null-object)
3. [Replace Primitive with Object](#3-replace-primitive-with-object)
4. [Composite Values](#4-composite-values)
5. [Named Constructors](#5-named-constructors)
6. [Assertions and Preconditions](#6-assertions-and-preconditions)
7. [The Clock and Other System Calls](#7-the-clock-and-other-system-calls)
8. [DTOs — The Deliberate Exception](#8-dtos--the-deliberate-exception)
9. [Providing a Service to a Non-Service Object](#9-providing-a-service-to-a-non-service-object)
10. [Testing Construction](#10-testing-construction)

---

## 1. Constructor Injection

**Use for**: every service dependency and every configuration value, always.

**How**: all required constructor arguments, no defaults, no setters. The body
validates, then assigns — nothing else.

A long constructor is not a rule violation. Argument count doesn't affect
immutability, so a long list is a *signal* that the class has taken on too much,
and it's a signal you want to be able to see. This is the main reason a service
locator is banned: it hides three dependencies behind one and removes the
pressure that would have made you notice.

The **assignment-order test** is the cheap way to check you haven't smuggled
work into the constructor: if reordering the property assignments changes the
behavior, something in there is doing more than assigning.

When a constructor genuinely needs setup to happen — a directory created, a
connection opened — push it **outward** into a factory or the application's
bootstrap phase, not inward into a lazy private method. Instantiating an object
should never leave side effects behind, especially when the object may never be
used.

**Inject specific values, not configuration objects.** `AppConfig` as a
constructor argument tells you nothing about what the class actually reads;
`string cacheDirectory` does. The exception is values with genuine cohesion — a
username and password belong together in a `Credentials` object, because they're
one concept rather than two unrelated settings.

## 2. Null Object

**Use for**: eliminating an "optional" dependency, or a query that would
otherwise return `null`.

**How**: an implementation of the interface that does nothing (`NullLogger`,
`NoOpEventDispatcher`) or represents the empty case (`EmptyPage`).

**Why it beats an optional argument**: the alternative is
`if (this.logger !== null)` repeated in every method that logs — a check that
must be maintained forever, and that will eventually be forgotten in one place.
With a null object, the type is always satisfied and no client ever checks.

**Trade-off Noback names**: a silent no-op can hide a misconfiguration. In
practice that's far cheaper than guards scattered throughout, but it does mean a
missing logger fails quietly rather than loudly.

For configuration rather than collaborators, the equivalent move is a named
default factory: `Configuration.createDefault()`. The client gets the
convenience; the class keeps its required argument.

## 3. Replace Primitive with Object

**Use when**: the same validation appears in two places, or the answer to
*"would any string/int be acceptable here?"* is no.

**How**: a new class, validation in the constructor, named for the concept
rather than its validity.

```
// Before — the same check in two places, and `string` means nothing
class User {
  constructor(private emailAddress: string) {
    if (!isValidEmail(emailAddress)) throw new InvalidArgumentException(...)
  }
  changeEmailAddress(emailAddress: string): void {
    if (!isValidEmail(emailAddress)) throw new InvalidArgumentException(...)  // again
    this.emailAddress = emailAddress
  }
}

// After — validity is guaranteed by the type itself
class EmailAddress {
  constructor(private value: string) {
    if (!isValidEmail(value)) throw new InvalidArgumentException(...)
  }
}

class User {
  constructor(private emailAddress: EmailAddress) {}
  changeEmailAddress(emailAddress: EmailAddress): void {
    this.emailAddress = emailAddress    // no check needed, ever
  }
}
```

**Name it `EmailAddress`, not `ValidEmailAddress`.** If a `ValidEmailAddress` can
exist then so can an invalid one, which is precisely what construction just
forbade. All objects are valid by construction, so "valid" in a class name is
redundant at best and misleading at worst.

**What you're actually doing** is extending the type system with domain concepts.
Every method that used to take the primitive now takes the type, and its
precondition check *disappears* — the compiler enforces it instead of you.

**Trade-off**: more classes and more typing, in exchange for guaranteed-valid
data, a home for related behavior, and compiler enforcement. The behavior part
matters more than it first appears: once `Title` exists, `abbreviated()` has an
obvious place to live. Value objects act as attractors for behavior that would
otherwise sit in a service or, worse, at a call site.

## 4. Composite Values

**Tell**: the same two or three parameters keep appearing side by side in method
signatures, and return types get ambiguous. `convert(...): Amount` — in which
currency?

**Fix**: values that always travel together become one type. `amount` +
`currency` → `Money`. The ambiguity in the return type disappears along with the
parameter pairing.

## 5. Named Constructors

**Use for**: any non-service object, and custom exceptions.

**How**: `public static` factory methods, with the regular constructor `private`
so nothing can bypass them. Named constructors can touch private properties
because scoping is class-based, not instance-based.

Three distinct jobs:

1. **Build from primitives** — `Date.fromString()`, `DecimalValue.fromInt()`.
2. **Speak the domain** — a sales order is *placed*, not constructed, so
   `SalesOrder.place()`. This is where ubiquitous language enters the code.
3. **Offer several construction paths** funnelling through one guarded private
   constructor:

```
class DecimalValue {
  private constructor(private value: int, private precision: int) {
    assertGreaterOrEqual(precision, 0)          // the only gate
  }
  static fromInt(value: int, precision: int): DecimalValue { ... }
  static fromFloat(value: float, precision: int): DecimalValue { ... }
  static fromString(value: string): DecimalValue { ... }
}
```

Three entry points, one place where invariants are enforced.

**Caution**: don't reflexively add `toString()` / `toInt()` for symmetry. Wait
for a proven need — every accessor you add is one you may later want to delete.

## 6. Assertions and Preconditions

The `if (somethingIsWrong()) throw` pattern at the top of a method, ideally
through an assertion library (`assertBetween`, `assertGreaterThan`,
`assertAllInstanceOf`).

**Order matters**: validate each argument on its own first, then check invariants
that span several arguments (`numberOfRooms > numberOfAdults + numberOfChildren`).
Place each single-argument check directly above the assignment it guards, so the
relationship reads clearly.

**But before writing a cross-argument check, ask whether a redesign removes the
need.** Two escape hatches:

- **Derive it.** A `Deal` that receives amount, discount *and* total has to
  validate that the total is consistent. A `Deal` that computes `totalAmount()`
  has nothing to validate.
- **Split it.** Validating `isDotted` against `distanceBetweenDots` means you
  have two construction paths pretending to be one: `Line.dotted(distance)` and
  `Line.solid()`.

**Never collect assertion failures into a list.** Assertions are for the
programmer; validation errors are for the user. These are different mechanisms
serving different audiences, and they belong on different objects — assertions on
entities and value objects, collected errors on DTOs.

**Validate only what would actually break behavior.** A `Router` tolerates an
empty controllers array; it does not tolerate non-string keys. Don't add checks
for the sake of thoroughness.

## 7. The Clock and Other System Calls

**Use for**: any implicit call to the outside world — current time, filesystem,
randomness.

```
interface Clock { currentTime(): DateTime }
class SystemClock implements Clock { currentTime() { return new Date() } }
class FixedClock implements Clock {
  constructor(private now: DateTime) {}
  currentTime() { return this.now }
}
```

Without this, a test's result depends on the day it runs and will eventually
fail on its own.

**But Noback's own revision matters**: passing `now` as a *method* argument is
often better still. "The current time" is contextual task data, not a
collaborator — it fails the batch test. Reach for the `Clock` interface when the
time is needed deep inside a service that clients shouldn't have to know about;
pass the value when the caller naturally has it.

## 8. DTOs — The Deliberate Exception

DTOs live at the application's edge and carry outside data inward. They invert
every rule above, on purpose:

|                     | Entity / Value Object          | DTO                          |
|---------------------|--------------------------------|------------------------------|
| Construction        | Named constructor, all data    | Regular constructor, stepwise|
| Properties          | Private                        | Public, all exposed          |
| Invalid data        | Throws immediately             | Collects validation errors   |
| Property fillers    | Never                          | Allowed                      |
| Contents            | Values, value objects          | Primitives, DTOs, arrays     |
| Purpose             | Protect domain invariants      | Carry outside data inward    |

A **property filler** — a `fromArray()` that copies raw data into properties — is
banned on entities and value objects because it hands the object's internals to
the outside world. On a DTO it's exactly right.

The reason DTOs collect errors rather than throwing is the audience: a user
filling in a form needs to see everything wrong at once, whereas a programmer
passing a negative latitude needs to be stopped immediately.

## 9. Providing a Service to a Non-Service Object

Non-service objects don't get services injected — not through the constructor,
not through a setter, and not through a global or static accessor. When
`Money.convert()` needs an exchange rate, there are three shapes:

```
// A — pass the service as a method argument. Allowed, but it feels off.
money.convert(exchangeRateProvider, targetCurrency)

// B — pass the RESULT of the service, not the service.
const rate = exchangeRateProvider.getRateFor(money.currency(), target)
const converted = money.convert(rate)

// C — the behavior wanted to be a service all along.
class ExchangeService {
  constructor(private rates: ExchangeRates) {}
  convert(money: Money, target: Currency): Money { ... }
}
```

Noback doesn't declare a winner; he names the trade-off. **How close you want
behavior to data, versus how much you're willing to expose.** B exposes only
`currency()`. C exposes `currency()` *and* `amount()` but keeps `Money` entirely
ignorant of exchange rates.

His hint is the useful part: **needing to pass services as method arguments
often means the behavior belongs in a service.** If option A is where you landed,
try C before settling.

## 10. Testing Construction

**Only test how a constructor should fail.** The happy path is covered
implicitly by every behavior test that builds the object.

| Check                                                   | Unit-test it? |
|---------------------------------------------------------|---------------|
| Type-shaped check a better type system could catch       | No            |
| Range, count, relationship, or domain rule               | Yes           |
| The constructor's happy path                             | No            |
| The constructor's failure paths                          | Yes           |

The test question is *"could the language runtime theoretically catch this?"* If
yes, skip it.

**Never add a getter just to test construction.** It leaks internal state for no
client's benefit, and it's the beginning of the anemic-model slide. If you need
to observe that something happened inside an entity, record a domain event and
assert on that instead.

**Assert on a keyword from the exception message, not only the exception
class.** A test that checks only the class can pass while covering an entirely
different branch — which is exactly the failure mode that makes people distrust
a suite.
