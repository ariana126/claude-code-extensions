# Chapter 8: Why Integration Testing?

## Core Idea
Integration tests cover the **controllers** quadrant; unit tests cover the **domain model**. The single most actionable rule in the chapter: **use real instances of managed dependencies, replace unmanaged dependencies with mocks** — because communications with managed dependencies are implementation details, while communications with unmanaged ones are observable behavior requiring backward compatibility.

## Frameworks Introduced

- **Managed vs. Unmanaged Dependencies** — the chapter's central classification.
  - **Managed**: out-of-process dependencies **you have full control over**, only accessible through your application. Interactions aren't visible externally. Typical example: the application database (external systems reach it through your API, not directly).
  - **Unmanaged**: out-of-process dependencies **other applications can access**. Interactions **are** observable externally. Typical examples: an SMTP server, a message bus.
  - **The rule: use real instances of managed dependencies; replace unmanaged dependencies with mocks.**
  - Why: unmanaged dependencies require **backward compatibility** — mocks guarantee the communication pattern survives any refactoring. Managed dependencies need no such guarantee, since your app is the only caller. Using them for real verifies the final state from the client's point of view and survives database refactorings (renaming a column, or even migrating databases entirely).

- **The Unit/Integration Ratio Guideline**: *check as many of the business scenario's edge cases as possible with unit tests; use integration tests to cover **one happy path**, as well as any edge cases that can't be covered by unit tests.*
  - **Choose the longest happy path** — the one that goes through *all* out-of-process dependencies. If no single path touches them all, write as many additional integration tests as needed to capture communication with **every** external system.
  - **Why the bar is higher for integration tests**: their scores on protection against regressions and resistance to refactoring must be *higher* than a unit test's to offset their worse maintainability and feedback speed.

- **The Fail Fast Principle** — *stop the current operation as soon as any unexpected error occurs*. A **viable alternative to integration testing**.
  - Two benefits: **shortening the feedback loop** (a production bug is orders of magnitude more expensive than one found in development) and **protecting the persistence state** (once corruption reaches the database it's far harder to fix).
  - Implemented with **exceptions**, whose semantics fit perfectly: they interrupt flow and pop to the top of the stack where you can log and shut down or restart.
  - Examples: preconditions (a failing one signals an incorrect assumption about application state — always a bug); reading configuration at startup so the app won't launch with bad config.
  - **The testing consequence**: don't write an integration test for an edge case whose incorrect execution immediately crashes the application. The bug reveals itself on first execution and doesn't corrupt data.

- **Interfaces: The YAGNI Rule** — *don't introduce interfaces for out-of-process dependencies unless you need to mock them out. You only mock unmanaged dependencies, so: **use interfaces for unmanaged dependencies only.*** Inject managed dependencies explicitly too, but as concrete classes.
  - Both standard justifications are misconceptions:
    - **"Interfaces provide loose coupling"** — false. **Interfaces with a single implementation are not abstractions.** *Genuine abstractions are discovered, not invented.* Discovery happens post factum, when the abstraction already exists but isn't yet defined in code. **For an interface to be a genuine abstraction it must have at least two implementations.**
    - **"They let me add functionality without changing existing code (OCP)"** — violates the more foundational **YAGNI** principle. Two reasons: **opportunity cost** (time spent on unneeded features is stolen from needed ones, and by the time the business wants it their view will have evolved anyway) and **the less code, the better** (code introduced *just in case* raises cost of ownership).
  - *"Writing code is an expensive way to solve problems. The less code the solution requires and the simpler that code is, the better."*

- **Support vs. Diagnostic Logging** (Freeman & Pryce) — the framework for deciding whether to test logging.
  - **Support logging** produces messages intended for support staff or system administrators. It's **part of observable behavior** → a business requirement → **must be tested**.
  - **Diagnostic logging** helps developers understand what's going on inside. It's an **implementation detail** → **don't test it**.
  - The deciding question is the same as for everything else: *is logging part of the application's observable behavior, or an implementation detail?* If the side effects are meant to be observed by anyone other than developers, test them.

- **The DomainLogger Pattern**: don't mock `ILogger` directly. Because support logging is a business requirement, **reflect it explicitly in the code base**: create a `DomainLogger` class listing all business-required log entries in domain language, and verify interactions with *that* instead of raw `ILogger`.
  - Then use **domain events** to keep `DomainLogger` out of domain classes (otherwise `User` gains an out-of-process collaborator and slides back into the overcomplicated quadrant). The controller dispatches events into `DomainLogger` calls.
  - Testing then splits cleanly: **unit tests check the `UserTypeChangedEvent` instance; a single integration test mocks `DomainLogger`** to verify the interaction.
  - **Exception**: if the support logging happens in the *controller* rather than a domain class, skip domain events — controllers orchestrate out-of-process dependencies directly, and `DomainLogger` is one of them.

- **Structured Logging** — a technique where **capturing log data is decoupled from rendering it**. `logger.Info("User Id is {UserId}", 12)` hashes the message template (stored in a lookup for space efficiency) and combines it with parameters to form *captured data*, which can then be rendered as a flat file, JSON, CSV, etc. `DomainLogger` isn't structured logging per se but operates in the same spirit: `UserTypeHasChanged()` acts as the template hash, its parameters as the data, and its body as one possible rendering.

## Key Concepts

- **Happy path** — a successful execution of a business scenario. **Edge case** — when execution results in an error.
- **Ambient context** (van Deursen & Seemann) — resolving dependencies via static methods (`LogManager.GetLogger(typeof(User))`). An **anti-pattern**.
- **Circular dependency** — two or more classes that directly or indirectly depend on each other to function.

## Mental Models

- **"It's better to not write a test at all than to write a bad test. A test that doesn't provide significant value is a bad test."** Repeated from Ch 7 and applied here to skip low-value integration tests.
- **David J. Wheeler**: *"All problems in computer science can be solved by another layer of indirection, except for the problem of too many layers of indirection."* When every feature has a representation in every layer, you spend real effort reassembling the pieces into a cohesive picture.
- **Circular dependencies have no starting point.** To understand one class you must understand its whole sibling graph at once. Even a small set of interdependent classes becomes ungraspable.
- **An interface doesn't fix a cycle — it hides it.** Introducing `ICheckOutService` removes the circular dependency at *compile time*, but the cycle persists at *runtime*, and the cognitive load actually **increases** because of the extra interface.
- **Ambient context masks a deeper problem.** If injecting a logger explicitly into a domain class is so inconvenient that you reach for a static, that's a sign you either log too much or have too many layers of indirection. Tackle the root cause.
- **Maximize the logs' signal-to-noise ratio.** The more you log, the harder it is to find relevant information.

## Anti-patterns

- **Mocking a managed dependency** (e.g. the database) because you can't easily run a real one: compromises resistance to refactoring *and* protection against regressions. If the database is your only out-of-process dependency, such tests deliver **no additional protection** over existing unit tests — they only verify which repository methods the controller calls, i.e. three lines of code, in exchange for a lot of plumbing. **If you can't test the database as-is, don't write integration tests at all** — focus on unit testing the domain model.
- **Interfaces with a single implementation for in-process dependencies** (`IUser` backing `User`): *a huge red flag*. The only reason would be to mock domain classes — and you should never verify interactions between domain classes.
- **Using a shared database to integrate systems**: couples the systems and complicates their development. Resort to it only when all other options are exhausted; prefer an API (synchronous) or a message bus (asynchronous).
- **Excessive layers of indirection**: code bases with many layers tend to lack a clear controller/domain boundary and encourage verifying each layer separately, mocking the layer beneath — producing many low-value integration tests with *insufficient protection against regressions combined with low resistance to refactoring*.
- **Circular dependencies**, especially callbacks where the callee notifies the caller of its result.
- **Multiple act sections** (register user → assert → delete user → assert): tempting because states flow naturally, but the test loses focus and bloats.
- **Ambient context for loggers**: the dependency is hidden and hard to change, and testing becomes harder.
- **Excessive diagnostic logging in the domain model**: clutters the code and damages signal-to-noise. Ideally use diagnostic logging **for unhandled exceptions only**, and remove temporary debug logging once you're done.

## Code Examples

**The integration test — real database, mocked bus:**

```csharp
[Fact]
public void Changing_email_from_corporate_to_non_corporate()
{
    // Arrange
    var db = new Database(ConnectionString);
    User user = CreateUser("user@mycorp.com", UserType.Employee, db);
    CreateCompany("mycorp.com", 1, db);

    var messageBusMock = new Mock<IMessageBus>();
    var sut = new UserController(db, messageBusMock.Object);

    // Act
    string result = sut.ChangeEmail(user.UserId, "new@gmail.com");

    // Assert
    Assert.Equal("OK", result);

    object[] userData = db.GetUserById(user.UserId);        // re-read, don't reuse inputs
    User userFromDb = UserFactory.Create(userData);
    Assert.Equal("new@gmail.com", userFromDb.Email);
    Assert.Equal(UserType.Customer, userFromDb.Type);

    object[] companyData = db.GetCompany();
    Company companyFromDb = CompanyFactory.Create(companyData);
    Assert.Equal(0, companyFromDb.NumberOfEmployees);

    messageBusMock.Verify(
        x => x.SendEmailChangedMessage(user.UserId, "new@gmail.com"),
        Times.Once);
}
```
- **What it demonstrates**: The critical technique is **checking database state independently of the input parameters** — query separately, build fresh `userFromDb`/`companyFromDb` instances, then assert. This exercises **both writes to and reads from** the database, maximizing protection against regressions. The reading must use the same code the controller uses internally (`Database`, `UserFactory`, `CompanyFactory`). Note also the `CreateUser`/`CreateCompany` helper methods, reusable across integration tests.

**The asymmetric constructor — the rule made visible:**

```csharp
public class UserController
{
    private readonly Database _database;       // concrete class — managed dependency
    private readonly IMessageBus _messageBus;  // interface — unmanaged dependency

    public UserController(Database database, IMessageBus messageBus)
    {
        _database = database;
        _messageBus = messageBus;
    }
}
```

**Breaking a circular dependency by returning a value:**

```csharp
// BEFORE — callback cycle
public class CheckOutService
{
    public void CheckOut(int orderId)
    {
        var service = new ReportGenerationService();
        service.GenerateReport(orderId, this);   // passes itself
    }
}

// AFTER — the callee returns a plain value
public class CheckOutService
{
    public void CheckOut(int orderId)
    {
        var service = new ReportGenerationService();
        Report report = service.GenerateReport(orderId);
    }
}
```

**Support logging via domain events:**

```csharp
// In User — record an event instead of calling DomainLogger
if (Type != newType)
{
    int delta = newType == UserType.Employee ? 1 : -1;
    company.ChangeNumberOfEmployees(delta);
    AddDomainEvent(new UserTypeChangedEvent(UserId, Type, newType));
}

// In the controller — one dispatch handles both event types
_database.SaveCompany(company);
_database.SaveUser(user);
_eventDispatcher.Dispatch(user.DomainEvents);
```
`EventDispatcher` maps `EmailChangedEvent` → `_messageBus.SendEmailChangedMessage()` and `UserTypeChangedEvent` → `_domainLogger.UserTypeHasChanged()`. Both events implement `IDomainEvent`, so they share one collection.

## Reference Tables

| | Managed dependency | Unmanaged dependency |
|---|---|---|
| Examples | Application database | SMTP server, message bus |
| Externally observable? | No | Yes |
| Communications are… | Implementation details | Observable behavior |
| In integration tests | **Use the real instance** | **Replace with a mock** |
| Needs an interface? | No — use a concrete class | Yes — to enable mocking |
| What to verify | Final state | Interactions |

**The hybrid case — a database other applications can access:** treat the **shared tables as an unmanaged dependency** (they effectively act as a message bus, with rows as messages) — mock them and keep their communication pattern frozen. Treat **the rest as managed** — verify final state. *Don't change how your system interacts with shared tables unless absolutely necessary; you never know how other applications will react.*

**Test Pyramid shape by project type:**

| Project | Shape |
|---|---|
| Normal | Pyramid: many unit, fewer integration, fewest e2e |
| Simple (little domain logic) | Rectangle: equal unit and integration |
| Most trivial | No unit tests at all — integration tests still retain their value |

**Recommended layer count**: three — **domain model**, **application services (controllers)**, **infrastructure** (algorithms outside the domain model, plus database repositories, ORM mappings, SMTP gateways).

## Worked Example

**Deciding what to integration-test in the CRM.**

*Step 1 — pick the scenario.* The longest happy path is **changing from a corporate to a non-corporate email**, which triggers the maximum side effects: the user changes type and email in the database, the company's employee count changes, and a message goes on the bus.

*Step 2 — check the edge cases.* There's exactly one edge case unit tests don't cover: the email can't be changed. **Skip it** — if the controller ever calls `ChangeEmail` without consulting `CanChangeEmail()` first, the precondition crashes the application on first execution. Easy to notice, easy to fix, no data corruption. The precondition in `User` *should* be tested — but with a unit test.

That leaves **exactly one integration test**: `Changing_email_from_corporate_to_non_corporate()`.

*Step 3 — categorize the dependencies.* The database is **managed** (no other system accesses it) → use a real instance: insert user and company, run the scenario, verify state. The message bus is **unmanaged** (its sole purpose is enabling communication with other systems) → mock it and verify the interaction.

*Step 4 — decide about end-to-end tests.* None in this project. An e2e test would run against a deployed, fully functioning API with **no mocks for any out-of-process dependency**; integration tests host the application in-process and mock unmanaged dependencies only. Because managed dependencies are already in the integration scope, integration tests give protection close enough to e2e that you can skip e2e testing. **If you do add one or two as a post-deployment sanity check**: make them go through the longest happy path, check the message bus directly (emulating the external client), but verify the database's state *through the application itself*, never directly.

**The one legitimate exception to single-act tests.** Suppose registering a user creates a bank account in an external banking system, and the bank's sandbox is slow or rate-limits your calls. Then combining multiple acts into one test to reduce interactions with that dependency is justified. **Hard-to-manage out-of-process dependencies are the only legitimate reason** — which is precisely why unit tests must *never* have multiple acts (they don't touch out-of-process dependencies), and why multistep tests almost always turn out to be end-to-end tests.

## Key Takeaways

1. **An integration test is any test that isn't a unit test.** They cover controllers; unit tests cover the domain model. Trivial and overcomplicated code get no tests at all.
2. **Use real managed dependencies; mock unmanaged ones.** This single rule drives most integration-testing decisions.
3. **One happy path (the longest) plus edge cases unit tests can't reach** — and skip even those when Fail Fast already covers them.
4. **Check database state independently of input parameters**, using the same reading code the controller uses.
5. **Interfaces with one implementation are not abstractions.** Use them only to enable mocking, therefore only for unmanaged dependencies. Single-implementation interfaces on domain classes are a red flag.
6. **If you can't use a real database, write no integration tests at all** rather than mocking it.
7. **Keep three layers and no cycles.** Make the domain model boundary explicit — it's what makes unit and integration tests easy to tell apart.
8. **Test support logging, not diagnostic logging.** Route support logging through a `DomainLogger` fed by domain events; keep diagnostic logging sparse and ideally limited to unhandled exceptions.
9. **Always inject dependencies explicitly** — constructor or method argument — including loggers.

## Connects To
- **Ch 2**: The unit-test definition that makes "integration test = everything else" work; also the shared/out-of-process dependency taxonomy that managed/unmanaged refines.
- **Ch 4**: The Test Pyramid and the four pillars that justify the higher bar for integration tests.
- **Ch 5**: Observable behavior vs. implementation details — the reasoning that makes managed dependencies mock-free and unmanaged ones mock-worthy.
- **Ch 7**: The code quadrants that assign integration tests to controllers; domain events and CanExecute/Execute, reused here for logging.
- **Ch 9**: Improving `messageBusMock`'s protection against regressions — mocking best practices.
- **Ch 10**: Database testing best practices, including reducing the assertion section with helper methods.
- **Ch 11**: Mocking concrete classes via virtual methods vs. interfaces.
- **Freeman & Pryce, *GOOS*** (support/diagnostic logging) · **van Deursen & Seemann, *Dependency Injection*** (ambient context).
