# Chapter 9: Conclusion (Part I)

## Core Idea
All of Part I reduces to two principles: **use dependency injection and inversion everywhere**, and **make use cases independent of their input's delivery mechanism**. Do both and infrastructure code gets pushed to the sides, leaving portable, object-pure core code in the middle.

## Frameworks Introduced

- **The two-principle strategy** — everything in Part I, compressed:
  > 1. "Use dependency injection everywhere, let services depend on abstractions only"
  > 2. "Make use cases independent of the delivery mechanism of their input"
  - Result: "none of the core code depends on infrastructure code on either side. At the same time, any infrastructure code would be able to call core code."
  - The two map exactly onto the two actor types: principle 1 decouples from **secondary** actors, principle 2 from **primary** actors.

- **Primary vs. secondary actors** (Jacobson, Cockburn) — the bigger-picture framing of core vs. infrastructure:
  - **Primary actors** act upon our system (a person's browser sending an HTTP `POST`).
  - **Secondary / supporting actors** are acted upon by our system (the database receiving an `INSERT`).
  - "To decouple from primary actors we have to make our use cases **universally invokable**… To decouple from secondary actors we have to apply **dependency inversion**."

- **The defragmentation model** — the chapter's central image, in three diagrams:
  1. User code sits in the middle, infrastructure code on both sides.
  2. In practice user code is a *mix* — bits of infrastructure scattered through it.
  3. Push those bits to the sides, "where they belong… because infrastructure code is the code that connects core code to the outside world so it might as well live as close to the outside world as possible." What remains is pure core.

- **Dependency injection vs. dependency inversion** — two distinct things, named precisely:
  - **Injection**: "services will get everything they depend on (other services, as well as configuration values) injected as constructor arguments."
  - **Inversion**: "services depend on abstractions, instead of concrete classes."
  - The "inversion" is literal — the arrow flips. Before: `EbookOrderService → OrderRepositoryUsingSql`. After: `EbookOrderService → OrderRepository ← OrderRepositoryUsingSql`.
  - The architectural test: **every dependency arrow either stays inside the core, or points from infrastructure into the core. Never the reverse.**

- **Object-pure code** — the object-oriented analogue of a pure function.
  - A pure function's return value "completely depends on the arguments provided to it."
  - An object is pure when it relies only on method arguments and constructor-injected **abstract** dependencies. Rephrased: **deterministic**.
  - "Because they only rely on method arguments and constructor-injected abstract dependencies the client has full control over the object."

- **The two ways to make an impure method pure** — the second is unique to objects:
  1. **Push the impurity out to the caller** — add a `$currentTimestamp` parameter.
  2. **Inject an abstraction** — but note the trap: injecting a concrete `Timer` class is *not* enough. "Although the call to `time()` now only happens inside `Timer`, calling `Stopwatch::secondsPassed()` will inevitably call `Timer::currentTimestamp()`, which is impure. This indirectly makes `Stopwatch::secondsPassed()` impure as well." Only turning `Timer` into an **interface** completes the job.

## Key Concepts
- **User code** — "what makes your application special: *what things can you do with your application?*… Frameworks, libraries, and PHP extensions could never help you with this kind of code, because it's domain-specific: it's your business logic."
- **Primary actor / secondary (supporting) actor** — who acts on the system vs. what the system acts on.
- **Universally invokable** — a use case reachable from any delivery mechanism.
- **Portable** — the combined result of both principles.
- **Pure / impure function** — return value fully determined by arguments, or not.
- **Object-pure** — deterministic object; all dependencies explicit and abstracted.
- **Legacy code** — Michael Feathers: "legacy code is simply code without tests."
- **Sprint Zero** — the up-front period spent choosing and configuring infrastructure; something this approach lets you skip.
- **Functional test** — invokes the application through all layers of the stack; the wrong tool for domain feedback.

## Mental Models
- **The test suite is just another infrastructure.** "The application's test suite will essentially be an alternative infrastructure for our core code as well. It will provide input for the use cases, and verify the outcomes of invoking them." That's why testability and architecture are the same problem.
- **Domain knowledge and tool knowledge decay at different rates.** "The tools (frameworks, libraries, protocols, and so on) have a much shorter life expectancy than the business domain itself… You'll want to get rid of everything, but you don't want to throw away the domain knowledge that is represented by your code." Mixing them means neither can evolve at its own speed.
- **Isolated core code buys you decision deferral.** "You won't have to spend an entire *Sprint Zero* on choosing and setting up all the infrastructure. You won't have to find out that you've built the wrong thing when most of the development budget has already been spent. You won't regret that you chose MongoDB instead of MySQL because you don't have to decide on day 1."
- **Tests are the asymmetric asset** (Robert Martin): "If somehow all your production code got deleted, but you had a backup of your tests, then you'd be able to recreate the production system with a little work." The reverse isn't true. "If you only have production code, then it will be really hard to write tests for it."
- **"If it hurts, do it more often" — but sharpened.** Fowler calls it "frequency reduces difficulty." Noback's version: "It's not just the repetition that makes it easier. The real trick is that repetition will automatically make you look for better ways of doing it. In other words, I think the rule should be: **'if testing isn't easy, make it easy'.**"
- **Low-level purity produces high-level architecture for free.** "When you start at a low level, the level of classes and methods, and you aim to write as much object-pure code as possible… you will end up with a much better design at a higher level too. Which is why I've started this book focusing only on core versus infrastructure instead of architectural concepts like layering, and ports and adapters… **The big win is separating core from infrastructure code. All the rest is nice-to-have, and you will get the rest more or less for free.**"

## Anti-patterns
- **Hiding use cases in controllers**: "Although the controller depends on an abstraction provided by the core, the use case itself is sadly part of the infrastructure. This means we can't easily invoke it, without also setting up and running other infrastructure code."
- **Injecting a concrete class and calling it dependency inversion**: only the *interface* breaks the impurity chain.
- **Testing core behavior with a functional test**: "You shouldn't be forced to test core behavior with a *functional test*, which invokes the application including all layers of the stack." Design feedback needs a fast loop.
- **Code without tests**: legacy by definition; needs special techniques, and "changing anything about it will be a very scary thing to do."
- **Refactoring without a test harness**: Fowler — "The tests are essential because even though I will follow refactorings structured to avoid most of the opportunities for introducing bugs, I'm still human and still make mistakes."
- **Mixing infrastructural details into the domain model**: "it'll be really hard to let both evolve in different directions, or at a different speed."

## Code Examples

Pure and impure, at their simplest:

```php
function sum(int $a, int $b): int
{
    return $a + $b;                        // pure
}

function secondsPassed(int $previousTimestamp): int
{
    return time() - $previousTimestamp;    // impure — depends on the clock
}
```

Fix 1 — push the impurity out to the caller:

```php
function secondsPassed(int $currentTimestamp, int $previousTimestamp): int
{
    return $currentTimestamp - $previousTimestamp;
}
```

Fix 2 — the object-oriented route, done **wrong** first:

```php
final class Timer                          // concrete class
{
    public function currentTimestamp(): int
    {
        return time();
    }
}

final class Stopwatch
{
    private Timer $timer;

    public function secondsPassed(int $previousTimestamp): int
    {
        // Still impure: this inevitably calls time()
        return $this->timer->currentTimestamp() - $previousTimestamp;
    }
}
```

…and then **right**, by inverting the dependency:

```php
interface Timer
{
    public function currentTimestamp(): int;
}

final class TimerUsesSystemClock implements Timer
{
    public function currentTimestamp(): int
    {
        return time();
    }
}

final class Stopwatch
{
    private Timer $timer;

    public function __construct(Timer $timer)
    {
        $this->timer = $timer;
    }

    public function secondsPassed(int $previousTimestamp): int
    {
        return $this->timer->currentTimestamp() - $previousTimestamp;
    }
}

final class FakeTimer implements Timer
{
    private int $timestamp;

    public function __construct(int $timestamp)
    {
        $this->timestamp = $timestamp;
    }

    public function currentTimestamp(): int
    {
        return $this->timestamp;
    }
}

$stopwatch = new Stopwatch(new FakeTimer(1562845845));
```

- **What it demonstrates**: `Stopwatch`'s *code* depends only on the `Timer` interface; at *runtime* it uses `TimerUsesSystemClock`, "without being aware of that." The DI container wires it up. Two perspectives — compile-time and runtime — and only the compile-time one determines purity.

## Reference Tables

**Decoupling, by actor type**

| Actor type | Example | Principle | Mechanism | Result |
|---|---|---|---|---|
| **Primary** (acts on us) | Browser, CLI, cron, API client | Make use cases independent of delivery mechanism | Application service taking primitives (Ch 4) | Universally invokable |
| **Secondary** (we act on it) | Database, VAT API, clock, mailer | Dependency injection + inversion | Interface + implementation (Ch 2, 5, 6, 7) | Replaceable infrastructure |

**Dependency arrow rules**

| From | To | Allowed? |
|---|---|---|
| Core → core | `EbookOrderService` → `OrderRepository` | Yes |
| Infrastructure → core | `OrderRepositoryUsingSql` → `OrderRepository` | Yes |
| Core → infrastructure | `EbookOrderService` → `OrderRepositoryUsingSql` | **No** |

**Purity of the `Stopwatch` variants**

| Version | Pure? | Why |
|---|---|---|
| Calls `time()` directly | No | Depends on the system clock |
| Takes `$currentTimestamp` as an argument | Yes | Fully determined by arguments |
| Injects concrete `Timer` class | **No** | Calling it inevitably calls `time()` |
| Injects `Timer` **interface** | Yes | Client has full control via the implementation |

## Worked Example

**Two diagrams that explain the entire book's shape.**

**The problem, in three pictures.** Start with the honest picture of a request: browser → web server → framework → *your code* → ORM → PDO → database. "Most of the time between the primary actor sending an HTTP request to your server, and the database storing the modified data, will be spent by running infrastructure code." Your code is a thin band in the middle — and it's the only part frameworks can't write for you, "because it's domain-specific: it's your business logic."

Zoom into that band and it isn't clean. It's *mixed*: "A use case may be inseparable from the web controller that invokes it. The use of service locators and the likes prevents code from running in isolation… Calls to external services require the external service to be available when we want to locally test our code."

The move is spatial: **push the infrastructure fragments outward to the edges they belong to.** After defragmenting, the middle is pure core — "code that can be executed without relying on any actual infrastructure… No network, no database, no file system."

**The `Stopwatch` sequence, and the trap in it.** The purity discussion is where the chapter earns its length, because Noback deliberately walks into a mistake.

`Stopwatch::secondsPassed()` calls `time()`. Impure. The functional fix is obvious — take the timestamp as a parameter.

The object-oriented fix looks equally obvious: extract a `Timer` class with `currentTimestamp()`, inject it. This is appealing because "clients won't have to provide the current timestamp themselves" — the method signature stays clean. And every call to `time()` is now in one place.

**It doesn't work.** "Although the call to `time()` now only happens inside `Timer`, calling `Stopwatch::secondsPassed()` will inevitably call `Timer::currentTimestamp()`, which is impure. This indirectly makes `Stopwatch::secondsPassed()` impure as well."

Impurity is transitive through concrete dependencies. Moving a `time()` call to a neighbor doesn't remove it from your call graph — it only hides it.

The fix is dependency **inversion**, not extraction: make `Timer` an interface, provide `TimerUsesSystemClock` for production and `FakeTimer` for tests. Now `Stopwatch`'s code depends only on the interface, and the client decides what actually gets called.

This is the same move as Ch 6's rejected "extract an interface from `VatApi`" — but arriving from the opposite direction, which is what makes the pair instructive. In Ch 6, an interface at the wrong *level of abstraction* bought nothing. Here, a concrete extraction at the right level also buys nothing. **You need both: the right abstraction, expressed as an interface.**

**Where this lands.** Noback closes by explaining the book's structure. He deliberately spent all of Part I on core-vs-infrastructure rather than opening with layers and hexagonal architecture, because:

> "When you start at a low level, the level of classes and methods, and you aim to write as much object-pure code as possible, while pushing all the infrastructure-related things to the sides, you will end up with a much better design at a higher level too… The big win is separating core from infrastructure code. **All the rest is nice-to-have, and you will get the rest more or less for free.**"

Read Part II knowing its author considers it optional.

## Key Takeaways
1. Two principles cover all of Part I: dependency injection + inversion everywhere, and use cases independent of their delivery mechanism.
2. They correspond to the two actor types — inversion decouples from secondary actors, universal invokability from primary actors.
3. The architectural invariant: dependency arrows stay within the core or point inward from infrastructure. Never outward.
4. Injecting a *concrete* dependency does not make code pure. Impurity propagates transitively; only an interface stops it.
5. Object-pure means deterministic: behavior determined by method arguments and constructor-injected abstractions, nothing else.
6. Your test suite is an alternative infrastructure for your core. That's why architecture and testability are one problem.
7. Domain knowledge outlives tool knowledge by years. Keep them in separate code so they can evolve at different speeds.
8. Isolated core code lets you defer infrastructure decisions — no Sprint Zero, no premature database commitment, and early feedback on whether you're building the right thing.
9. Legacy code is code without tests (Feathers). Tests preserve the *why*; code alone cannot.
10. "If testing isn't easy, make it easy" — repetition helps mainly because it pushes you to find a better way.
11. Separating core from infrastructure is the big win. Layering and ports-and-adapters largely follow for free.

## Connects To
- **Ch 1**: the original definitions of core and infrastructure code, now restated in terms of actors and use cases.
- **Ch 2, 5, 6, 7**: the dependency-inversion half of the strategy, applied to the database, service locators, external services, and system devices.
- **Ch 4**: the universal-invokability half.
- **Ch 7**: `Timer` here is `Clock` there — the same abstraction, arrived at by a different route.
- **Ch 10–15 (Part II)**: layering, the pattern catalog, and ports and adapters — explicitly framed as the nice-to-have that follows.
- **Ch 14**: the testing strategy this chapter's argument sets up.
- **Ivar Jacobson / Alistair Cockburn**: primary and supporting actors.
- **Michael Feathers, "Working Effectively with Legacy Code"**: legacy code = code without tests.
- **Martin Fowler, "Refactoring"**: tests as a prerequisite; "frequency reduces difficulty."
- **Robert C. Martin**: the tests-vs-production-code asymmetry.
