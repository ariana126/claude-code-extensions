# Chapter 3: Creating Other Objects

## Core Idea
Non-service objects (entities and value objects) must be **complete and valid the moment they exist**. Require the minimum data needed to behave consistently, reject data that isn't meaningful, and push repeated validation into new value object types — which extends your type system with domain concepts. DTOs are the one deliberate exception.

## Frameworks Introduced

- **Domain invariant**: Something that is always true about a concept, derived from domain knowledge. Constructors exist to protect them.
  - When to use: Every time you design a non-service object.
  - How: State the invariant in a sentence first ("A position has both an x and a y"; "Latitude is between −90 and 90 inclusive"), then encode it as a constructor check, then cover it with a unit test.

- **Require the minimum amount of data needed to behave consistently**: No setters for essential data; all of it goes in the constructor.
  - Failure mode it prevents: An object that exists but can't answer questions yet — `new Position(); position.distanceTo(other)` before `setX()`/`setY()` gives a meaningless answer.

- **Require data that is meaningful**: Type-correct isn't enough. Validate ranges, relationships, and combinations.
  - How: Validate each argument on its own; then check invariants that span arguments (`numberOfRooms > numberOfAdults + numberOfChildren`). Place each check directly above its property assignment so the relationship reads clearly.
  - **But first ask whether a redesign removes the need.** Two escape hatches: (a) derive the redundant argument (`Deal` computes `totalAmount()` instead of validating it); (b) split into named constructors (`Line.dotted(distance)` / `Line.solid()` instead of validating `isDotted` against `distanceBetweenDots`).

- **Extract new objects to prevent domain invariants from being verified in multiple places**: When the same validation appears twice, introduce a type.
  - When to use: The guiding question — **"Would any `string`/`int` be acceptable here?"** If no, make a class.
  - How: Name it for the concept, not its validity — `EmailAddress`, not `ValidEmailAddress`, because *all* objects are valid by construction.
  - Why it works: You're extending the type system. Wherever an `EmailAddress` appears, validation is already guaranteed, and the compiler enforces it for you.

- **Extract new objects to represent composite values**: Values that always travel together become one type. `Amount` + `Currency` → `Money`.
  - Tell: the same two-or-three parameters keep appearing side by side in method signatures, and return types get ambiguous (`convert(...): Amount` — in which currency?).

- **Named constructors**: `public static` methods returning an instance, with a `private` regular constructor so clients can't bypass them.
  - Three uses: (1) build from primitive values — `Date.fromString()`, `DecimalValue.fromInt/fromFloat/fromString`; (2) introduce domain vocabulary — a sales order is **placed**, not constructed, so `SalesOrder.place()`; (3) offer several construction paths while a private constructor enforces the invariants for all of them.
  - Caution: don't add `toString()`/`toInt()` reflexively for symmetry — only when there's a proven need.

- **Assertions (precondition checks)**: The `if (somethingIsWrong()) throw` pattern at the top of a method, ideally via an assertion library (`Assertion.greaterThan`, `Assertion.between`, `Assertion.allIsInstanceOf`).
  - **Test rule**: *"Could the language runtime theoretically catch this?"* If yes (a type check the language can't express), skip the unit test. If no (a range, a count, a domain rule), write the test.
  - Never collect assertion exceptions into a list — assertions are for the programmer, not the user. Fail immediately.

## Key Concepts
- **Value object**: A wrapped, validated value with meaningful behavior; replaceable and anonymous.
- **Entity**: An identifiable object that tracks changes (detailed in Ch 4).
- **DTO (data transfer object)**: Lives at the application's edge; carries outside data inward. Public properties, no constructor required, no exceptions, primitive values only.
- **Property filler**: A method like `fromArray()` that copies raw data into properties. Banned for entities/value objects, allowed for DTOs.
- **Named constructor**: A `public static` factory method on the class itself.

## Mental Models
- **Objects are types you're adding to the language.** Every value object you extract gives the compiler another rule it can enforce for you.
- **"Valid" is redundant in a class name.** If a `ValidEmailAddress` can exist, so can an invalid one — which is exactly what you've forbidden.
- **When two arguments must be validated together, suspect the design.** Either one is derivable, or you actually have two different construction paths.
- **Assertions are for programmers; validation errors are for users.** These are different mechanisms with different objects (entity vs. DTO).

## Anti-patterns
- **Setters for essential data** (`new Money(); setAmount(); setCurrency()`): the object exists in an inconsistent state in between.
- **Custom exception classes for invalid arguments**: an invalid argument is a programming mistake — fail hard and fix it, don't catch and recover. (Custom `RuntimeException` subclasses *are* justified — see Ch 5.)
- **Asserting only the exception class in a failure test**: a test can pass while covering the wrong branch. Always assert a keyword from the message too.
- **Property fillers on entities/value objects**: hands the object's internals to the outside world.
- **Injecting services into non-service objects** — via constructor, setter, *or* a global/static accessor. Pass as a method argument if truly needed.
- **Putting data in an object "just in case"** (fat event objects): add data on a need-to-know basis, driven by tests.
- **Adding getters to test the constructor**: leaks internal state for no client's benefit.

## Code Examples

Extracting a value object to kill duplicated validation:

```php
// Before — the same check in two places, and String is not a type that means anything
final class User {
    private string emailAddress;
    public function __construct(string emailAddress) {
        if (!is_valid_email_address(emailAddress)) {
            throw new InvalidArgumentException('Invalid email address');
        }
        this.emailAddress = emailAddress;
    }
    public function changeEmailAddress(string emailAddress): void {
        if (!is_valid_email_address(emailAddress)) {          // duplicated
            throw new InvalidArgumentException('Invalid email address');
        }
        this.emailAddress = emailAddress;
    }
}

// After — validity is guaranteed by the type
final class EmailAddress {
    private string emailAddress;
    public function __construct(string emailAddress) {
        if (!is_valid_email_address(emailAddress)) {
            throw new InvalidArgumentException('Invalid email address');
        }
        this.emailAddress = emailAddress;
    }
}

final class User {
    private EmailAddress emailAddress;
    public function __construct(EmailAddress emailAddress) { this.emailAddress = emailAddress; }
    public function changeEmailAddress(EmailAddress emailAddress): void {
        this.emailAddress = emailAddress;                     // no check needed, ever
    }
}
```
- **What it demonstrates**: Validation moves from *every call site* to *the type itself*, once.

Multiple named constructors funnelling through one private constructor:

```php
final class DecimalValue {
    private int value;
    private int precision;

    private function __construct(int value, int precision) {   // private: the only gate
        this.value = value;
        Assertion.greaterOrEqualThan(precision, 0);
        this.precision = precision;
    }

    public static function fromInt(int value, int precision): DecimalValue {
        return new DecimalValue(value, precision);
    }

    public static function fromFloat(float value, int precision): DecimalValue {
        return new DecimalValue((int)round(value * pow(10, precision)), precision);
    }

    public static function fromString(string value): DecimalValue {
        result = preg_match('/^(\d+)\.(\d+)/', value, matches);
        if (result == 0) { throw new InvalidArgumentException(/* ... */); }
        return new DecimalValue((int)(matches[1] . matches[2]), strlen(matches[2]));
    }
}
```
- **What it demonstrates**: Three entry points, one place where invariants are enforced. Named constructors can touch private properties because scoping is class-based, not instance-based.

## Reference Tables

| | Entity / Value Object | DTO |
|---|---|---|
| Construction | Named constructor, all required data | Regular constructor, filled stepwise |
| Properties | Private, protected | Public, all exposed |
| Invalid data | Throws immediately | Collects validation errors |
| Property fillers | Never | Allowed (as a named constructor) |
| Contents | Values, value objects | Primitives, other DTOs, arrays of DTOs |
| Purpose | Protect domain invariants | Carry outside data inward |

| Should I unit-test this check? | |
|---|---|
| Type-shaped check a better type system could catch (`allIsInstanceOf`) | No |
| Range, count, relationship, domain rule | Yes |
| The constructor's happy path | No — behavior tests cover it implicitly |
| The constructor's failure paths | Yes — this is the *only* constructor test you write |

## Worked Example

**Providing a service to a non-service object** — Noback works through four options for `Money.convert()` and lands somewhere unexpected.

```php
// Option A — pass the service as a METHOD argument (allowed, but feels odd)
final class Money {
    public function convert(
        ExchangeRateProvider exchangeRateProvider,
        Currency targetCurrency
    ): Money {
        exchangeRate = exchangeRateProvider.getRateFor(this.currency, targetCurrency);
        return exchangeRate.convert(this.amount);
    }
}

// Option B — pass the RESULT of the service, not the service
final class Money {
    public function convert(ExchangeRate exchangeRate): Money {
        Assertion.equals(this.currency, exchangeRate.fromCurrency());
        return new Money(
            exchangeRate.rate().applyTo(this.amount),
            exchangeRate.targetCurrency()
        );
    }
}
exchangeRate = exchangeRateProvider.getRateFor(money.currency(), targetCurrency);
converted    = money.convert(exchangeRate);

// Option C — the behavior wanted to be a service all along
final class ExchangeService {
    private ExchangeRateProvider exchangeRateProvider;
    public function __construct(ExchangeRateProvider p) { this.exchangeRateProvider = p; }

    public function convert(Money money, Currency targetCurrency): Money {
        exchangeRate = this.exchangeRateProvider.getRateFor(money.currency(), targetCurrency);
        return new Money(exchangeRate.rate().applyTo(money.amount()), targetCurrency);
    }
}
```

Noback doesn't declare a winner — he names the trade-off: **how close you want behavior to data, versus how much you're willing to expose**. Option B exposes only `currency()`; Option C exposes `currency()` *and* `amount()` but keeps `Money` ignorant of exchange rates. His hint: *needing to pass services as method arguments often means the behavior belongs in a service.*

## Key Takeaways
1. A constructor's job is to protect domain invariants — state the invariant in words first, then encode it.
2. Type-correct ≠ meaningful. Validate ranges and cross-argument relationships, but check first whether a redesign removes the need.
3. When a primitive wouldn't accept "any string/int," introduce a value object. This is how you extend the type system.
4. Use generic `InvalidArgumentException`, not custom classes — and distinguish cases in tests by asserting on the message.
5. Use named constructors for non-service objects, with a private regular constructor guarding all paths.
6. Only test constructors for **how they should fail**. Never add getters just to test construction.
7. Add data to an object only when a test proves you need it — especially event objects.
8. DTOs invert every rule above on purpose: public properties, incremental filling, collected validation errors, property fillers welcome.

## Connects To
- **Ch 2**: the mirror ruleset — services get dependencies, other objects get values
- **Ch 4**: entities vs. value objects vs. DTOs, and the mutability rules for each
- **Ch 5**: precondition checks become part of the full method template; custom `RuntimeException`s get their justification
- **Ch 6 §6.3**: the "how much internal state to expose" tension raised by the `Money.convert()` example
- **Domain-Driven Design**: domain invariants, value objects, entities, ubiquitous language in named constructors
