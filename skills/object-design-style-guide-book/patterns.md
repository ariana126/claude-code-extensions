# Patterns & Techniques — Object Design Style Guide

## Constructor Injection
**When to use**: Every service dependency and configuration value, always.
**How**: All required constructor arguments, no defaults, no setters. Validate, then assign — nothing else.
**Trade-offs**: Long constructors surface real complexity rather than hiding it. Argument count doesn't affect immutability, so a long list is a design signal, not a rule violation.

## Null Object
**When to use**: You want to eliminate an "optional" dependency, or a query would otherwise return `null`.
**How**: An implementation of the interface that does nothing (`NullLogger`, `EventDispatcherDummy`) or represents the empty case (`EmptyPage`).
**Trade-offs**: Silent no-ops can hide misconfiguration — but far cheaper than `if (x instanceof Y)` guards throughout.

## Replace Primitive with Object (Value Object Extraction)
**When to use**: The same validation appears twice, or the answer to *"would any string/int be acceptable here?"* is no.
**How**: New class, validation in the constructor, named for the concept not its validity (`EmailAddress`, not `ValidEmailAddress`). Every method taking the primitive now takes the type, and its precondition check disappears.
**Trade-offs**: More typing and more classes; in exchange you get guaranteed-valid data, a home for related behavior, and compiler enforcement.

## Named Constructor
**When to use**: Any non-service object; also custom exceptions.
**How**: `public static` factory methods; make the regular constructor `private` so nothing bypasses them. Three uses: build from primitives (`fromString`), speak the domain (`SalesOrder.place()`), offer multiple paths through one guarded private constructor.
**Trade-offs**: Don't reflexively add `toString()`/`toInt()` for symmetry — wait for a proven need.

## Modified Copy (Immutable Modifier)
**When to use**: Changing anything about an immutable object.
**How**: Declarative name from *"I want this …, but …"*; return the object's own type. **Prefer routing through the constructor** over `clone` — you reuse the validation for free.
**Trade-offs**: Callers must reassign (`year = year.next()`); forgetting is a silent no-op.

## Internally Recorded Domain Events
**When to use**: Testing state changes on an entity, and later building read models.
**How**: Private `events` array, appended by command methods, exposed via `recordedEvents()`. Optionally skip recording when nothing actually changed.
**Trade-offs**: `assertEquals` on the whole list is brittle; `assertContains` is looser but can pass against a broken implementation. Noback's resolution: that means the test suite is incomplete, or the property nobody observes should be deleted.

## Clock (Explicit System Call)
**When to use**: Any implicit call to the outside world — current time, filesystem, randomness.
**How**: `interface Clock` with `SystemClock` for production and `FixedClock` for tests.
**Trade-offs**: Often better still to pass the value as a method argument — "the current time" is contextual data, not a dependency.

## Method Template
**When to use**: Every method.
**How**: preconditions → failure scenarios → happy path → postconditions → return. Failure checks at the top; eliminate `else`; return early.
**Trade-offs**: Strong types delete preconditions; tests delete postconditions. The template shrinks as the design improves.

## Exception Design
**When to use**: Any failure.
**How**: `InvalidArgumentException` if knowable from the argument alone; `RuntimeException` otherwise. Name logic errors "Invalid…"; name runtime errors by finishing "Sorry, I …" → "CouldNot…". Drop the "Exception" suffix. Custom class only to catch specifically, to cover multiple failure reasons, or to get named constructors that assemble the message.
**Trade-offs**: Fewer exception classes means distinguishing cases in tests by message keyword rather than type — which is exactly what Noback recommends.

## Abstraction for System Boundaries
**When to use**: Crossing to a network, filesystem, database, clock, or queue.
**How**: Two steps, both required — (1) an interface instead of a class, (2) a name with no implementation details. `ExchangeRates`, not `HttpClient`.
**Trade-offs**: Escalate deliberately: better variable name → private method → new class. Only cross to a class for size, testability, or a boundary.

## Repository
**When to use**: Retrieving and persisting entities.
**How**: One interface in the domain layer (`getById()`, `save()`, `nextIdentity()`), implementation in infrastructure. Save and retrieve together is the legitimate exception to CQS at object level.
**Trade-offs**: The natural resolution when injecting `UserRepository` seems to require `EntityManager` too — redistribute the responsibility rather than injecting both.

## Read Model + Read Model Repository (CQRS at object level)
**When to use**: Any client that only reads an entity.
**How**: One read model per use case, named for it. Build it (in ascending cost) from the write model → **directly from the data source** → from domain events.
**Trade-offs**: Data-source-direct is the default — cheapest in runtime *and* maintenance. Event-built read models win only when the write model changes often, raw data needs interpretation, or recomputation is genuinely too expensive; they cost more moving parts, harder event evolution, and operational tooling for failed listeners.

## Composition of Abstractions
**When to use**: Combining several implementations into richer behavior.
**How**: A class implementing the interface, holding a collection of that interface (`MultipleLoaders` dispatching by file extension).
**Trade-offs**: Writing every implementation up front is "generalization before it's needed." Introduce the abstraction early; add implementations on demand.

## Decorator
**When to use**: Cross-cutting concerns — caching, logging, retries, value substitution.
**How**: Implement the same interface, hold an instance of it, add behavior around the delegated call. To decorate at a finer grain you may need to *extract* an object first (e.g. `LineImporter` out of `CsvFileImporter`).
**Trade-offs**: Noback's own caveat — removing a few log statements this way costs a lot of code. Consider AOP tooling when before/after hooks are the only goal.

## Event Listener vs. Notification Object
**When to use**: Adding behavior to existing services without modifying them.
**How**: Generic `EventDispatcher` with event classes and listeners; or a domain-named interface (`ImportNotifications` with `whenHeaderImported()` etc.).
**Trade-offs**: The dispatcher lets anyone add a listener later, but `dispatch()` is opaque and listeners are hard to trace. The named interface is explicit and eliminates event/listener/registration boilerplate, but adding a notification means changing the interface. Always dispatch **explicitly** either way.

## Template Method → Composition Conversion
**When to use**: Any time you find or are tempted by template method.
**How**: Promote the `abstract protected` method to a regular `public` method on an injected object; mark the class `final` again.
**Trade-offs**: None worth mentioning — Noback's claim is that everything template method does, composition does, plus composability and decoration.

## Trait for Entity Code Reuse
**When to use**: Shared implementation across entities/value objects, which can't use dependency injection.
**How**: Interface declaring the contract (`RecordsEvents`) plus a trait supplying the implementation (`EventRecordingCapabilities`).
**Trade-offs**: A trait is compiler-level copy/paste — deliberately *not* inheritance, so the name never enters the type hierarchy.

## Test Double Selection
**When to use**: Every unit test with a dependency.
**How**: Command methods → **mock** (framework-verified) or **spy** (hand-written, ordinary assertion). Query methods → **dummy**, **stub**, or **fake**. Write stubs and fakes by hand; use mocking tools sparingly, ideally only for dummies.
**Trade-offs**: Mocking frameworks save boilerplate at the cost of readability and refactorability — method names as strings defeat rename tooling.
