# Patterns & Techniques — Khorikov, Unit Testing

## AAA (Arrange-Act-Assert)
**When to use**: every test, always.
**How**: Arrange — bring SUT and dependencies to the desired state. Act — one line calling the SUT. Assert — verify return value, final state, or collaborator calls. Name the SUT `sut`. Separate sections with blank lines; keep `// Arrange` comments only when large setups force extra blank lines inside a section.
**Trade-offs**: Multiple act sections mean multiple units of behavior — split, except in already-slow integration tests. Never use `if` statements (no exceptions). Section sizes are a *design signal*: a >1-line act section means broken encapsulation; a bloated assert means a missing abstraction.

## Humble Object
**When to use**: code is hard to test because it's coupled to a difficult dependency (out-of-process communication, UI, async execution).
**How**: Extract the testable logic into a separate class. What remains is a thin wrapper that glues the dependency to the extracted component — so humble it needs no tests.
**Trade-offs**: More classes, but it's the same pattern underlying hexagonal architecture, functional architecture, MVC/MVP, and DDD aggregates. Improves maintainability independently of testing.

## Functional Architecture (functional core + mutable shell)
**When to use**: complex, business-important code where you want output-based testing.
**How**: Split code into decisions (functional core — mathematical functions, no collaborators) and actions (mutable shell — gathers input, applies side effects). Order: shell reads → core decides → shell acts. Decision objects must carry enough information that the shell needs no branching of its own.
**Trade-offs**: Concedes **performance** (all inputs must be read up front, even unneeded ones) and initial **code size** for maintainability. Not worth it in simple or business-unimportant projects. Impossible when you must query a dependency mid-decision.

## CanExecute/Execute
**When to use**: a business rule would otherwise force a decision point into the controller, fragmenting business logic.
**How**: Add a `CanDo()` returning an error (or null) for each `Do()`, and make `CanDo() == null` a **precondition** of `Do()`. The controller calls `CanDo()`, returns early on error, then calls `Do()`.
**Trade-offs**: The controller keeps an `if`, but you don't need to test it — the precondition makes it impossible to skip the check. `CanDo()` can bundle many validations, all encapsulated away from the controller.

## Domain Events
**When to use**: you must inform external systems of what happened, but tracking that in the controller would overcomplicate it — especially when a side effect should fire only conditionally.
**How**: Define an immutable class named in the **past tense** carrying the notification data. Domain classes accumulate events during the operation; the controller (or an `EventDispatcher`) converts them into calls to unmanaged dependencies afterward.
**Trade-offs**: More types, plus an event-dispatch mechanism. In return, unit tests can verify the *event* instead of mocking out-of-process dependencies — *it's easier to test abstractions than the things they abstract*.

## Object Mother
**When to use**: reusing arrange-section setup across tests.
**How**: Private factory methods with **default argument values**, so each test specifies only the arguments relevant to its scenario. Start in the test class; move to a helper class only when duplication becomes significant. Never put them in the base class.
**Trade-offs**: Preferred over **Test Data Builder** (`new UserBuilder().WithEmail(...).Build()`), which reads slightly better but requires too much boilerplate — at least in languages with optional arguments.

## Private Factory Methods (instead of constructor setup)
**When to use**: shared fixture setup between tests.
**How**: `CreateStoreWithInventory(Product.Shampoo, 10)` — parameterized so each test states what it wants.
**Trade-offs**: The alternative (constructor / `[SetUp]`) couples all tests together and hides context. **Exception**: initialize in a constructor when nearly all tests need the fixture (a DB connection) — and then put it in a *base class*, not the test class.

## Spy (handwritten mock) with a Fluent Interface
**When to use**: verifying interactions with an unmanaged dependency at the system's edge.
**How**: Implement the edge interface manually, capture the calls, and expose chainable assertion methods (`ShouldSendNumberOfMessages(1).WithEmailChangedMessage(...)`). Consider naming it `BusMock` — most programmers don't know the term *spy*.
**Trade-offs**: Manual code to maintain. In return: reusable assertions, shorter tests, and — crucially — **an independent checkpoint**, because the spy is test code while a wrapper like `MessageBus` is production code. Tests are auditors; they shouldn't take the auditee's word.

## Mocking at System Edges
**When to use**: any unmanaged dependency.
**How**: Follow the chain from controller to external system (`EventDispatcher` → `IMessageBus` → `IBus` → the bus) and mock the **last** link. Verify the actual payload (the text message), not a call to your own class.
**Trade-offs**: Maximizes both protection against regressions (more code executes) and resistance to refactoring (pinned to the contract, not your class structure). **Skip it** when exact structure doesn't matter — logging is the standard exception; mock `IDomainLogger`, not `ILogger`.

## Adapters over Third-Party Libraries ("mock only types you own")
**When to use**: any library providing access to an **unmanaged** dependency.
**How**: Write your own interface expressing the library's capability in your domain language, expose only what you need, and mock that.
**Trade-offs**: An extra layer. It pays for itself on library upgrades: without it, a breaking change ripples across the code base; with it, the ripple stops at the adapter. **Doesn't apply** to in-process or managed dependencies — don't wrap a date/time API or an ORM over your own database.

## Repositories + Unit of Work
**When to use**: any business operation mutating data across multiple entities.
**How**: Split "what to update" (short-lived repositories enlisting into the current transaction) from "whether to keep the updates" (a long-lived transaction). The controller calls `Commit()` / `SaveChanges()` at the very end so any early return prevents the commit; the infrastructure layer calls `Dispose()`.
**Trade-offs**: A unit of work defers updates to the end, shortening the database transaction and reducing congestion — usually free, since ORMs implement it (`DbContext`, `ISession`). Guarantees the database changes only on happy paths.

## Migration-Based Database Delivery
**When to use**: any project past its first production release.
**How**: Store explicit migrations (Flyway, Liquibase, FluentMigrator) in source control, including reference data. Never edit a committed migration — write a new one instead, unless the bad migration risks data loss.
**Trade-offs**: State becomes implicit (assemble it from migrations) and merge conflicts get harder — but it's the only approach that handles **data motion**, because data is context-dependent and no comparison tool can infer domain-specific transformations.

## Clean-at-Start Data Cleanup
**When to use**: every integration test suite touching a real database.
**How**: A base `IntegrationTests` class whose constructor runs a hand-written `DELETE` script in foreign-key order. Remove all regular data, never reference data.
**Trade-offs**: Beats restoring backups (too slow), cleaning at the end (skipped on crashes or debugger stops), and uncommitted transactions (diverges from production). Removes the need for a teardown phase entirely.

## Decorator Method for Act Sections
**When to use**: every integration-test act section, which must create its own database context.
**How**: `Execute(x => x.ChangeEmail(userId, email), messageBus, logger)` — a method taking a delegate and wrapping the controller call in context creation.
**Trade-offs**: Adds a database context per call, so the test creates more transactions. Khorikov takes the trade: minor speed cost, substantial maintainability gain.

## Fluent Assertions via Extension Methods
**When to use**: shrinking bloated assert sections.
**How**: Extension methods returning the object: `userFromDb.ShouldExist().WithEmail("new@gmail.com").WithType(UserType.Customer)`.
**Trade-offs**: Reads as plain English, matching the `[Subject] [action] [object]` story pattern. For value-like classes, defining equality members achieves the same with even less code — but only when the class *is* inherently a value; otherwise it's code pollution.

## Parameterized Tests
**When to use**: several similar facts about one behavior.
**How**: `[Theory]` + `[InlineData]`. Use `[MemberData(nameof(Data))]` when values must be computed at runtime (C# evaluates attributes at compile time, permitting only constants, literals, and `typeof()`).
**Trade-offs**: Less code, less readable names. **Rule**: keep positive and negative cases together only when the parameters make it self-evident which is which; otherwise extract the positive case to its own descriptively named test. Skip parameterization entirely for complex behavior.

## Hardcoded Expected Values
**When to use**: testing any algorithm.
**How**: Compute the expected results **outside the SUT** — with a domain expert, or from legacy code during a refactoring — and hardcode them.
**Trade-offs**: Feels counterintuitive, but recomputing the algorithm in the test makes it a duplicate that can't distinguish real failures from false positives.

## Interface + Test-Side Fake (instead of a production switch)
**When to use**: you need different behavior in tests (e.g. a silent logger).
**How**: `ILogger` in production with a real `Logger`; `FakeLogger` lives in the test project.
**Trade-offs**: The interface is arguably still code pollution, but a benign kind — you can't accidentally hit a non-production code path, and interfaces are contracts with no code, so they can't harbor bugs. A boolean switch adds real bug surface.

## Time as an Injected Value
**When to use**: any time-dependent behavior (the act and assert phases may otherwise see different times).
**How**: Inject `IDateTimeServer` as a service at the start of the business operation, then pass a plain `DateTime` value through the rest of it.
**Trade-offs**: Plain values are preferred but DI frameworks handle them poorly — hence the service-at-the-boundary compromise. Never use an ambient static context: it pollutes production code and its shared static state pushes tests into integration territory.
