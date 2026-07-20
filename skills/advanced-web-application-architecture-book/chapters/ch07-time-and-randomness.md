# Chapter 7: Time and randomness

## Core Idea
The system clock and the random device are external systems too. `new DateTimeImmutable('now')` and `Uuid::uuid4()` inside an entity make it infrastructure code — pass time and randomness in as arguments, wrapped in **your own** value objects.

## Frameworks Introduced

- **Time and randomness are service responsibilities, not value-object behavior.**
  - "Even though `Uuid` and `DateTimeImmutable` look like value objects, they really aren't. They could never come up with random data or the current time on their own."
  - The test: imagine writing `DateTimeImmutable`'s constructor or `Uuid::uuid4()` yourself. "At some point you'd have to 'reach out' and ask the host system for some input."
  - Rule: "When an object talks to external systems this object should be a service so it can communicate this clearly. And when we create a service class for something that talks to the outside world, we should always provide an **interface** for it."

- **The `Clock` abstraction** — one place in the entire application where "now" is determined.
  ```php
  interface Clock { public function currentTime(): DateTimeImmutable; }
  ```
  - When to use: rewrite *every* `new DateTimeImmutable()` in the application as a `Clock::currentTime()` call.
  - Why it works: "This gives us a single place to determine the current time, which will be very helpful when we start writing acceptance tests" (Ch 14).

- **The design-ownership rule** — the chapter's most broadly applicable principle:
  > "The classes you use as dependencies (constructor arguments, method arguments and return types) in your domain model should also be designed by you."
  - Why: third-party classes are "designed to be useful in many projects and many different situations… not designed with your specific use case in mind, but with *any* use case in mind." `DateTimeImmutable` drags in `sub()`, `setDate()`, `getTimezone()` — "by introducing the class to your domain model, its behavior now becomes part of your domain."

- **The three rules for value objects** — what you may and may not borrow from third-party libraries:
  1. Value objects shouldn't contain infrastructure code.
  2. Value objects should have no service responsibilities.
  3. Value objects should offer no behavior that hasn't been explicitly enabled and designed for your use case.
  - "You can use value objects from other libraries if they offer the (more or less) exact behaviors you need. If they don't, then you should adapt them by wrapping them inside your own value objects."
  - It's fine to use a third-party class *inside* your value object to do heavy lifting (as `Date` uses `DateTimeImmutable` for validation) — just don't let it into the API.

- **"Jumpy" code as the smell of too many elements** — how to recognize over-abstraction.
  - The tell: "we go from application service to abstraction, to concrete class, to abstraction, to concrete class."
  - Two removal heuristics, applied in opposite directions:
    - **Infrastructure code doesn't need to jump back to core.** `OrderRepositoryUsingSql` is *already* infrastructure, so it can call `Uuid::uuid4()` directly. Delete `UuidFactory` and its implementation.
    - **A pass-through abstraction adds a hop, not a seam.** `CalendarUsingClock` only asks `Clock` for the time and builds a `Date`. Delete `Calendar`; let the application service use `Clock` plus `Date::fromCurrentTime()`.
  - Noback's own caveat: "I don't think it should be your goal to create more elements than needed, but I know that it sometimes happens. That's why I thought it would be useful to show what are signs of too many elements ('jumpy' code), and also how to reduce the number of elements."

- **The `FakeClock`** — a mutable test double that lets time pass.
  - When to use: any test where behavior depends on elapsed time.
  - How: `setCurrentTime()` to pin the moment; `setCurrentTime($t->modify('+1 day'))` to advance it; fall back to real `'now'` when unset.
  - Prefer a named `FakeClock` class over an anonymous class — it "facilitates the process of providing the 'current time' that we want."

## Key Concepts
- **System device** — the clock or the random device; an external dependency reached without an HTTP client. "The system clock and the system's random device are in a sense remote services too."
- **Clock** — the conventional name for a time factory abstraction.
- **Calendar** — a `today(): Date` abstraction; introduced in this chapter and then deliberately removed.
- **`UuidFactory`** — an abstraction over UUID creation; also introduced and then removed.
- **Pure object** — behavior determined solely by constructor arguments, method arguments, and its own logic.
- **Deterministic** — same inputs, same result, every run. The property a unit test needs.
- **Named constructor** — `OrderId::fromString()`, `Date::fromString()`, `Date::fromCurrentTime()`.
- **`nextIdentity()`** — the repository method that produces new IDs (from Ch 2); the natural home for UUID generation.
- **Integration test** — "still tests a single unit of code, but since it uses IO, it can show that your code integrates well with third-party or standard libraries and is able to connect to the relevant system devices."

## Mental Models
- **"Is this core code?" applies to entities too.** An `Order` calling `Uuid::uuid4()` and `new DateTimeImmutable('now')` in its named constructor is infrastructure code, despite being a domain object.
- **A test that can never pass is a design report.** `OrderTest` comparing a freshly created UUID and timestamp against ones made inside the entity is unfixable — because the entity is non-deterministic, not because the test is badly written.
- **Weakening the assertion is not the fix.** You could assert only that the array contains an *instance* of `OrderWasCreated`. "That would make the test pass, but it would still leave us with an unpredictable entity." And it's still an integration test, since it uses IO.
- **Verify your assumptions about third-party date handling.** `new DateTimeImmutable('2019-02-29')` throws no exception — "`DateTimeImmutable`'s constructor simply turns it into `2019-03-01`." And a partial date string silently copies the missing parts from the actual current time, which quietly breaks determinism.
- **"If your team has a rule that every class should have a test? Then get rid of this rule (no joke)."** The chapter then writes the `ClockUsingSystemClock` test anyway, as a fun experiment, and concludes: "this should work, and might be a correct integration test, but I doubt if it's a very useful test."
- **Rename toward the story, not the type.** `Date::fromDateTimeImmutable()` → `Date::fromCurrentTime()`. "This would take away the focus from the data type used, and bring back focus on the story."
- **Abstractions cost two or three elements each** (interface, standard implementation, and sometimes a new return type). Worth it — but "keep trying to limit the number of elements or parts in your application."

## Anti-patterns
- **`new DateTimeImmutable('now')` or `Uuid::uuid4()` inside a domain object**: two hidden external dependencies, and a class that can never be unit-tested.
- **Hard-coding a partial date string in a test**: `new DateTimeImmutable('2020-06-03 09:53')` looks deterministic but "if you don't provide some date parts it will copy the respective values from the *actual current time*." Seconds and microseconds leak in; the test isn't a unit test.
- **Third-party classes in your domain model's API**: their design decisions become your domain's behavior, and "the ideas of the author don't match with your ideas or expectations about the same concept."
- **Type juggling at the call site**: `Date::fromString($clock->currentTime()->format('Y-m-d'))` scatters knowledge of `DateTimeImmutable` and the format string. Move it into `Date` via a named constructor.
- **Pass-through abstractions**: an interface whose only implementation forwards to another abstraction produces jumpy code and buys nothing.
- **Infrastructure code depending on a core abstraction it doesn't need**: `OrderRepositoryUsingSql` reaching for `UuidFactory` when it can just call `Uuid::uuid4()`.
- **"Every class must have a test" as a rule**: produces tests like the `ClockUsingSystemClock` one — correct, hard-won, and near-worthless.
- **Asserting exact timestamp equality across two instantiations**: microseconds always differ; even rounding to seconds fails when the two calls straddle a second boundary.

## Code Examples

The problem — an entity that looks like core code but isn't:

```php
final class Order
{
    public static function create(): self
    {
        $order = new self();
        $order->id = Uuid::uuid4();                       // random device
        $order->orderDate = new DateTimeImmutable('now'); // system clock
        $order->recordThat(new OrderWasCreated($order->id, $order->orderDate));

        return $order;
    }
}
```

The two abstractions:

```php
interface UuidFactory
{
    public function create(): Uuid;
}

final class UuidFactoryUsingRamseyUuid implements UuidFactory
{
    public function create(): Uuid
    {
        return Uuid::uuid4();
    }
}

interface Clock
{
    public function currentTime(): DateTimeImmutable;
}

final class ClockUsingSystemClock implements Clock
{
    public function currentTime(): DateTimeImmutable
    {
        return new DateTimeImmutable('now');
    }
}
```

Your own value objects — no IO, no borrowed API:

```php
final class OrderId
{
    private string $id;

    private function __construct(string $id)
    {
        Assertion::uuid($id);
        $this->id = $id;
    }

    public static function fromString(string $id): self
    {
        return new self($id);
    }
}

final class Date
{
    private const DATE_FORMAT = 'Y-m-d';
    private string $date;

    private function __construct(string $date)
    {
        // Third-party class used *inside* the value object, never in its API
        if (! DateTimeImmutable::createFromFormat(self::DATE_FORMAT, $date)) {
            throw new InvalidArgumentException(sprintf(
                'Invalid date provided: %s. Expected format: %s',
                $date,
                self::DATE_FORMAT
            ));
        }

        $this->date = $date;
    }

    public static function fromString(string $date): self
    {
        return new self($date);
    }

    public static function fromCurrentTime(DateTimeImmutable $currentTime): self
    {
        return new self($currentTime->format(self::DATE_FORMAT));
    }
}
```

A genuine unit test — no IO anywhere:

```php
/** @test */
public function it_can_be_created(): void
{
    $order = new Order(
        OrderId::fromString('77d69702-e3b4-4af5-b40a-c9981d483880'),
        Date::fromString('2019-07-09')
    );
    // ...
}
```

- **What it demonstrates**: generate the UUID once with `uuidgen`, paste it in, and the test is deterministic forever. The full date string means no parts get copied from the real clock.

The final, cleaned-up application service — `Calendar` and `UuidFactory` both gone:

```php
final class EbookOrderService
{
    private Clock $clock;
    private OrderRepository $orderRepository;

    public function create(/* ... */): OrderId
    {
        $order = Order::create(
            $this->orderRepository->nextIdentity(),
            Date::fromCurrentTime($this->clock->currentTime()),
            // ...
        );
        // ...
        return $order->orderId();
    }
}

final class OrderRepositoryUsingSql implements OrderRepository
{
    public function nextIdentity(): OrderId
    {
        // Already infrastructure code — no need to route through UuidFactory
        return OrderId::fromString(Uuid::uuid4()->toString());
    }
}
```

The `FakeClock`, including letting time pass:

```php
final class FakeClock implements Clock
{
    private ?DateTimeImmutable $currentTime;

    public function setCurrentTime(DateTimeImmutable $currentTime): void
    {
        $this->currentTime = $currentTime;
    }

    public function currentTime(): DateTimeImmutable
    {
        if ($this->currentTime === null) {
            return new DateTimeImmutable('now');
        }

        return $this->currentTime;
    }
}

$clock = new FakeClock();
$currentTime = new DateTimeImmutable('2020-06-03 09:53');
$clock->setCurrentTime($currentTime);
// Do something
$clock->setCurrentTime($currentTime->modify('+1 day'));
// Do something else — the code will think it's one day later
```

## Reference Tables

**Which PHP functions make code infrastructure code**

| Function | Infrastructure? | Why |
|---|---|---|
| `time()` | **Yes** | Reads the system clock |
| `date($format)` — timestamp omitted | **Yes** | Defaults to the current time |
| `date($format, $timestamp)` — both args | No | Pure formatting of provided input |
| `checkdate($m, $d, $y)` | No | Pure validation of provided input |
| `mt_rand()` unseeded | **Yes** | Reaches the system's random device |
| `mt_srand($seed)` then `mt_rand()` | No | Seeded → deterministic sequence from the given input |

**The elements, before and after cleanup**

| Element | Kept? | Reason |
|---|---|---|
| `Clock` + `ClockUsingSystemClock` | Kept | Single place to determine "now"; essential for acceptance tests |
| `OrderId`, `Date` (your value objects) | Kept | Design ownership; no IO |
| `UuidFactory` + `UuidFactoryUsingRamseyUuid` | **Removed** | Only consumer was already infrastructure code |
| `Calendar` + `CalendarUsingClock` | **Removed** | Pure pass-through to `Clock`; caused jumpy code |

**Testing a real clock — three attempts**

| Attempt | Result |
|---|---|
| `assertEquals($now, $clock->currentTime())` | Never passes — microseconds always differ |
| Compare `format('U')` (rounded to seconds) | Usually passes; fails across a second boundary |
| `assertEqualsWithDelta(..., 0.1)` on `format('U.u')` | Works — "but I doubt if it's a very useful test" |

## Worked Example

**One test, rewritten five times, each version revealing the next design flaw.**

**Version 1 — the impossible test.**
```php
$order = Order::create();
self::assertEquals(
    [new OrderWasCreated(Uuid::uuid4(), new DateTimeImmutable('now'))],
    $order->releaseEvents()
);
```
It "will never pass." The UUID and timestamp inside the entity can't equal the ones made in the test. And because `Order::create()` uses IO, this was never a unit test to begin with — it's an integration test that happens to be testing a domain object.

**Version 2 — pass them in.** Change `create()` to accept `Uuid $id, DateTimeImmutable $orderDate`. The test generates both, passes them in, asserts against them. It passes. `Order` no longer reaches out.

But the values still come from `Uuid::uuid4()` and `new DateTimeImmutable('now')` — the *test* is doing IO now. And there's a deeper issue: those two classes look like value objects but are secretly services.

**Version 3 — introduce factories.** `UuidFactory` and `Clock`, each with a standard implementation. The test now says `(new ClockUsingSystemClock())->currentTime()`. "Although a bit more verbose, this is definitely a more honest way of showing where the current time and the unique ID come from." Still doing IO, though.

**Version 4 — hard-code the values.** `Uuid::fromString('77d69702-…')` and `new DateTimeImmutable('2020-06-03 09:53')`. No IO, faster suite, full control.

**Except it doesn't work.** `DateTimeImmutable` "has some interesting behavior when you instantiate it with a string argument. If you don't provide some date parts it will copy the respective values from the *actual current time*." No seconds or microseconds in that string means both get taken from the real clock. The test is still non-deterministic — and nothing in the code says so.

This is the pivot. Two separate problems have converged: these classes aren't really value objects, *and* they behave in ways you didn't sign up for. Which generalizes into the design-ownership rule — third-party classes are built for *any* use case, so `DateTimeImmutable` brings `sub()`, `setDate()`, `getTimezone()` into your domain whether you want them or not.

**Version 5 — your own value objects.** `OrderId::fromString()` with `Assertion::uuid()`, and `Date::fromString()` validating via `DateTimeImmutable::createFromFormat()` — the third-party class doing heavy lifting *inside*, never appearing in the API. The test is finally a real unit test: no IO in the subject, no IO in the test.

**Then the chapter reverses course.** Three classes became twelve. Noback reads the dependency diagram for removable parts and finds two, deleting each for an *opposite* reason:

- `UuidFactory` exists so core code needn't create UUIDs. But its only consumer is `OrderRepositoryUsingSql` — already infrastructure. "It doesn't have to jump back to core code." Delete the interface and its implementation.
- `Calendar` is a pure pass-through: ask `Clock`, build a `Date`. That's "jumpy" code. Delete it; the application service uses `Clock` directly with `Date::fromCurrentTime()`.

`Clock` survives — because a single application-wide definition of "now" is what makes `FakeClock` and Ch 14's acceptance tests possible.

**The honest coda.** `ClockUsingSystemClock` now has no test. Noback is "tempted not to write a test for it," then writes one as an experiment — and it takes three attempts (exact equality fails on microseconds, second-rounding fails at boundaries, `assertEqualsWithDelta` on `U.u` finally works). His verdict: "might be a correct integration test, but I doubt if it's a very useful test." Hence: "if your team has a rule that every class should have a test? Then get rid of this rule (no joke)."

## Key Takeaways
1. The clock and the random device are external systems. Any object touching them is infrastructure code, entity or not.
2. Producing time or randomness is a **service** responsibility. Services that talk to the outside world always get an interface.
3. Hard-coding a partial date string does not make a test deterministic — `DateTimeImmutable` fills missing parts from the real clock. Verify your assumptions about third-party date handling.
4. Design ownership: classes appearing in your domain model's constructor arguments, method arguments, and return types should be designed by you.
5. You may use third-party classes *inside* a value object for validation or heavy lifting — never in its public API.
6. Route every `new DateTimeImmutable()` through `Clock`. One definition of "now" makes `FakeClock` and acceptance tests possible.
7. "Jumpy" code — service → abstraction → class → abstraction → class — signals too many elements. Remove pass-through abstractions, and let infrastructure code call infrastructure directly.
8. Each abstraction costs two or three elements. Worth paying, worth counting.
9. Drop any "every class must have a test" rule. Some classes are too thin for a test to say anything useful.
10. Name named-constructors after the story (`fromCurrentTime`), not the data type (`fromDateTimeImmutable`).

## Connects To
- **Ch 1**: the two rules applied to the least obvious external dependencies.
- **Ch 2**: `nextIdentity()` on the repository — the pattern reused here to keep UUID creation out of core code; also the `OrderId` value object.
- **Ch 5**: the "pure object" property (behavior from own logic + constructor args + method args) is the target this chapter aims at; the `Clock` is a dependency, the resulting `Date` is job-specific data.
- **Ch 6**: same interface-plus-implementation shape, plus the integration-test discussion these tests extend.
- **Ch 11**: value objects and entities in the pattern catalog.
- **Ch 14**: the `Clock` abstraction is what makes controlling time in acceptance tests possible.
- **`beberlei/assert`, `ramsey/uuid`**: the libraries used, and kept behind your own types.
