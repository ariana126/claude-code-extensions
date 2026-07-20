# Chapter 7: Refactoring Toward Valuable Unit Tests

## Core Idea
Categorize all production code on two axes — **complexity/domain significance** and **number of collaborators** — producing four quadrants. Unit test the **domain model and algorithms** quadrant only; skip trivial code; cover controllers briefly with integration tests; and **eliminate overcomplicated code** by splitting it into algorithms and controllers using the **Humble Object pattern**. The guiding rule: *the more important or complex the code, the fewer collaborators it should have.*

## Frameworks Introduced

- **The Four Types of Code** — the chapter's organizing diagram.

  | | Few collaborators | Many collaborators |
  |---|---|---|
  | **High complexity / domain significance** | **Domain model & algorithms** → unit test heavily; best ROI | **Overcomplicated code** (fat controllers) → refactor away entirely |
  | **Low complexity / domain significance** | **Trivial code** (one-line properties, param-less constructors) → don't test at all | **Controllers** → test briefly with integration tests |

  - Why the top-left wins: high complexity/significance ⇒ great **protection against regressions**; few collaborators ⇒ low **maintenance cost**. Valuable *and* cheap.
  - The two axes are independent: a price-calculation method can have cyclomatic complexity 1 yet be worth testing because it's business-critical.
  - **What counts as a collaborator**: mutable or out-of-process dependencies — **both implicit and explicit**. It doesn't matter whether the SUT takes it as an argument or reaches it via a static method; you still must set it up. **Immutable dependencies (values/value objects) don't count.**
  - **Out-of-process collaborators are a no-go in the domain model.** They force complicated mock machinery and demand extra prudence to avoid fragility.

- **Cyclomatic Complexity** = `1 + <number of branching points>`. Equivalently: the number of independent paths from entry to exit, or the number of tests needed for 100% branch coverage. `IF c1 AND c2` counts as two branching points (complexity 3), since it's equivalent to nested ifs.

- **The Humble Object Pattern** (Meszaros): when code is hard to test because it's coupled to a difficult dependency (async execution, UI, out-of-process communication), **extract the testable logic into a separate class**, leaving behind a thin *humble* wrapper containing little or no logic — so humble it doesn't need testing.
  - **This pattern is everywhere**: hexagonal architecture (domain vs. application services), functional architecture (core vs. shell), MVP/MVC (Presenter and Controller are humble objects gluing View and Model), and DDD's **Aggregate pattern** (clusters that are highly connected inside but loosely coupled between, reducing total connectivity and thus improving testability).
  - It's also a form of the **Single Responsibility Principle** — one responsibility is always business logic.

- **Code Depth vs. Code Width**: *your code can be either deep (complex or important) or wide (works with many collaborators), but never both.* Controllers orchestrate many dependencies but aren't complex; domain classes are the reverse.

- **The Three-Attribute Trade-off** for handling conditional logic in controllers — pick **two of three**:
  1. **Domain model testability** — a function of the number and type of collaborators in domain classes.
  2. **Controller simplicity** — depends on the presence of decision-making points in the controller.
  3. **Performance** — defined by the number of calls to out-of-process dependencies.

  | Option | Testability | Controller simplicity | Performance |
  |---|---|---|---|
  | Push all external reads/writes to the edges | ✅ | ✅ | ❌ |
  | Inject out-of-process deps into the domain model | ❌ | ✅ | ✅ |
  | **Split decision-making into granular steps** | ✅ | ❌ | ✅ |

  **Khorikov's recommendation: the third option**, mitigated by the two patterns below. Option 2 is explicitly to be avoided — it drags code back into the overcomplicated quadrant.

- **The CanExecute/Execute Pattern**: introduce a `CanDo()` for each `Do()` method and make its successful execution a **precondition** of `Do()`.
  - Two benefits: (1) the controller needs to know nothing about the process — `CanChangeEmail()` can bundle many validations, all encapsulated; (2) the precondition guarantees the operation can never run unchecked.
  - Key consequence: **although the controller still contains an `if` calling `CanChangeEmail()`, you don't need to test that `if`.** Unit testing the precondition in the domain class is enough — the controller has no option *not* to check.

- **Domain Events**: a class describing *an event meaningful to domain experts* (that's what separates it from a button-click event), used to inform external applications of important changes.
  - **Always name them in the past tense** — they represent things that already happened. **Domain events are values**: immutable and interchangeable.
  - How: the domain class accumulates events during the operation; the controller converts them into calls to out-of-process dependencies afterward. This removes the tracking responsibility from the controller.

## Key Concepts

- **Active Record pattern** — a domain class that retrieves and persists itself to the database. Works in simple/short-lived projects but fails to scale, precisely because it lacks separation between business logic and out-of-process communication.
- **Precondition** — a safeguard activated only in exceptional cases (usually bugs), letting software **fail fast** before an error spreads into the database where it's much harder to deal with.
- **Reconstruction logic** — mapping raw database rows into domain objects. Complex but **without domain significance** — it isn't related to the client's goal. Belongs in an ORM mapping or a factory, not a controller.

## Mental Models

- **Think "it's better to not write a test at all than to write a bad test."** You won't reach 100% coverage this way, and you shouldn't want to. The goal is a suite where **every test adds significant value**.
- **Think of observable behavior and implementation details as onion layers.** Test each layer *from the outer layer's point of view*, disregarding how it talks to the layers beneath. As you peel layers, perspective switches: what was an implementation detail becomes observable behavior, covered by another set of tests.
- **Only the first call down the stack is observable.** The controller→`User` call is an implementation detail from the external client's perspective; the `User`→`Company` calls are implementation details from the controller's perspective. **Never mock these.**
- **"It's easier to test abstractions than the things they abstract."** Domain events abstract upcoming bus messages; changes in domain classes abstract upcoming database modifications. Keeping side effects in memory until the very end of the operation is what makes plain unit tests sufficient.
- **A testable design is also a maintainable design.** Separating business logic from orchestration tackles code complexity, which matters for project growth independently of testing.
- **Complexity hides in libraries.** `UserFactory.Create()` has one visible branching point, yet indexing `data[0]` and casting `object`→`int` each involve internal .NET decisions about whether to throw. These hidden branches make it test-worthy despite the apparent simplicity.

## Anti-patterns

- **Fat controllers**: the canonical overcomplicated code — controllers that don't delegate complex work and do everything themselves.
- **Merely making implicit dependencies explicit** (extracting `IDatabase`/`IMessageBus` interfaces and injecting them into the domain class): **this is not enough.** From the diagram's perspective it doesn't matter whether the domain model reaches out-of-process dependencies directly or via an interface — they're still proxies to data not in memory, still need mock machinery, and mocking the database leads to fragility (Ch 8).
- **Business logic fragmentation**: moving a check like `IsEmailConfirmed` from the domain class to the controller. It makes it possible to change the email without verifying the flag, **diminishing the domain model's encapsulation**, and pushes the controller toward the overcomplicated zone.
- **A domain method returning data that isn't its own** (`User.ChangeEmail()` returning the updated employee count): a misplaced responsibility, which is itself a sign of a **missing abstraction** — here, the `Company` class.
- **Testing preconditions without domain significance**: `data.Length >= 3` in a factory carries no domain meaning; don't test it.
- **Mocking calls between domain classes**: even when a domain class legitimately has one to three collaborators, don't verify those interactions — they aren't observable behavior.

## Code Examples

**Before — overcomplicated `User` (Active Record + business logic + two out-of-process collaborators):**

```csharp
public void ChangeEmail(int userId, string newEmail)
{
    object[] data = Database.GetUserById(userId);          // implicit collaborator
    UserId = userId;
    Email = (string)data[1];
    Type = (UserType)data[2];

    if (Email == newEmail) return;

    object[] companyData = Database.GetCompany();
    string companyDomainName = (string)companyData[0];
    int numberOfEmployees = (int)companyData[1];

    string emailDomain = newEmail.Split('@')[1];
    bool isEmailCorporate = emailDomain == companyDomainName;
    UserType newType = isEmailCorporate ? UserType.Employee : UserType.Customer;

    if (Type != newType)
    {
        int delta = newType == UserType.Employee ? 1 : -1;
        Database.SaveCompany(numberOfEmployees + delta);
    }

    Email = newEmail;
    Type = newType;

    Database.SaveUser(this);
    MessageBus.SendEmailChangedMessage(UserId, newEmail);  // implicit collaborator
}
```

**After — `User` with zero out-of-process collaborators, delegating to `Company`:**

```csharp
public void ChangeEmail(string newEmail, Company company)
{
    Precondition.Requires(CanChangeEmail() == null);

    if (Email == newEmail) return;

    UserType newType = company.IsEmailCorporate(newEmail)
        ? UserType.Employee
        : UserType.Customer;

    if (Type != newType)
    {
        int delta = newType == UserType.Employee ? 1 : -1;
        company.ChangeNumberOfEmployees(delta);
    }

    Email = newEmail;
    Type = newType;
    EmailChangedEvents.Add(new EmailChangedEvent(UserId, newEmail));
}
```

**The new `Company` class — tell-don't-ask in action:**

```csharp
public class Company
{
    public string DomainName { get; private set; }
    public int NumberOfEmployees { get; private set; }

    public void ChangeNumberOfEmployees(int delta)
    {
        Precondition.Requires(NumberOfEmployees + delta >= 0);   // domain-significant
        NumberOfEmployees += delta;
    }

    public bool IsEmailCorporate(string email)
    {
        string emailDomain = email.Split('@')[1];
        return emailDomain == DomainName;
    }
}
```
- **What it demonstrates**: `User` *tells* the company to change its employee count or judge an email; it doesn't *ask* for raw data and compute on its own.

**The final humble controller:**

```csharp
public string ChangeEmail(int userId, string newEmail)
{
    object[] userData = _database.GetUserById(userId);
    User user = UserFactory.Create(userData);

    string error = user.CanChangeEmail();
    if (error != null) return error;

    object[] companyData = _database.GetCompany();
    Company company = CompanyFactory.Create(companyData);

    user.ChangeEmail(newEmail, company);

    _database.SaveCompany(company);
    _database.SaveUser(user);
    foreach (var ev in user.EmailChangedEvents)
    {
        _messageBus.SendEmailChangedMessage(ev.UserId, ev.NewEmail);
    }

    return "OK";
}
```
- **What it demonstrates**: Pure orchestration. The `if (error != null)` is **not** an increase in complexity — it belongs to the *acting* phase, not decision-making. All decisions live in `User`.

**Testing the result — plain in-memory state and events:**

```csharp
[Fact]
public void Changing_email_from_corporate_to_non_corporate()
{
    var company = new Company("mycorp.com", 1);
    var sut = new User(1, "user@mycorp.com", UserType.Employee, false);

    sut.ChangeEmail("new@gmail.com", company);

    company.NumberOfEmployees.Should().Be(0);
    sut.Email.Should().Be("new@gmail.com");
    sut.Type.Should().Be(UserType.Customer);
    sut.EmailChangedEvents.Should().Equal(
        new EmailChangedEvent(1, "new@gmail.com"));   // asserts size AND element
}
```

## Reference Tables

**Where the sample project lands after refactoring:**

| | Few collaborators | Many collaborators |
|---|---|---|
| **High complexity / domain significance** | `User.ChangeEmail(newEmail, company)`; `Company.ChangeNumberOfEmployees(delta)`; `Company.IsEmailCorporate(email)`; `UserFactory.Create(data)`; `CompanyFactory.Create(data)` | *(empty — the goal)* |
| **Low complexity / domain significance** | Constructors in `User` and `Company` | `UserController.ChangeEmail(userId, newEmail)` |

**Testing decisions by quadrant:**

| Quadrant | How to test |
|---|---|
| Domain model & algorithms | Unit test heavily — best cost/benefit |
| Trivial code | Don't test |
| Controllers | Brief integration tests (Ch 8) |
| Overcomplicated | Refactor it out of existence |

**Preconditions:** test them **if they have domain significance** (`NumberOfEmployees + delta >= 0` is part of `Company`'s invariants). Don't test those that don't (`data.Length >= 3`).

## Worked Example

**Four takes on the CRM.** The system changes a user's email under three business rules: (1) a company-domain email marks the user an employee, otherwise a customer; (2) the company's employee count must track type changes; (3) an email change must notify external systems via a message bus.

**Take 1 — make implicit dependencies explicit.** Extract `IDatabase`/`IMessageBus`, inject, mock in tests. **Rejected**: still out-of-process, still needs mock machinery, and mocking the database causes fragility. Cleaner for the domain model not to depend on out-of-process collaborators *at all* — directly or via an interface.

**Take 2 — introduce an application service.** `UserController` now fetches data and calls `user.ChangeEmail(newEmail, companyDomainName, numberOfEmployees)`. `User` moves into the domain-model quadrant with *no* collaborators. But four issues remain: dependencies are instantiated rather than injected (a problem for integration tests); the controller reconstructs `User` from raw data (complex logic that doesn't belong in orchestration); `User` awkwardly returns the updated employee count; and the controller persists and notifies unconditionally. `UserController` nearly crosses into overcomplicated.

**Take 3 — extract the reconstruction logic.** Move it to an ORM mapping, or a factory:

```csharp
public class UserFactory
{
    public static User Create(object[] data)
    {
        Precondition.Requires(data.Length >= 3);
        return new User((int)data[0], (string)data[1], (UserType)data[2]);
    }
}
```
(`Precondition.Requires` exists for succinctness and **condition inversion** — affirmative statements read better than negative ones. `data.Length >= 3` beats `if (data.Length < 3) throw new Exception();`.)

**Take 4 — introduce `Company`.** The awkward return value was a **missing abstraction**. Bundling company data with company operations fixes it, and `User` becomes much cleaner. `User` shifts slightly right on the diagram (it now has one collaborator, `Company`) — slightly less testable, but not much. `UserController` now stands firmly in the controllers quadrant; all complexity has moved into the factories.

**Comparison to functional architecture (Ch 6)**: neither the audit system's functional core nor the CRM's domain layer talks to out-of-process dependencies; in both, the application services layer reads raw data, passes it to the logic, and persists results. **The difference is side effects**: the functional core incurs none at all, whereas the CRM's domain model does — but they stay *inside* the domain model (changed email, changed employee count) and only cross the boundary when the controller persists. Containing side effects in memory until the last moment is what allows all verification to be output-based and state-based.

**Why domain events were needed.** The controller sent a bus message even when the email hadn't changed. Moving the sameness check to the controller would fragment the business logic, and it can't go in `CanChangeEmail()` because an unchanged email isn't an error. Domain events solve it: `User` records `EmailChangedEvent` only when the change actually happens, and the controller iterates the events.

Note the deliberate asymmetry: **`Company` and `User` are still persisted unconditionally**, while messages are conditional. Assuming no other application touches the database, DB communications are **implementation details** — only the final state matters, not the number of calls. Bus communications **are observable behavior**, so the contract requires messages only on real changes. The performance cost is minor (the new email rarely equals the old one after validation, and most ORMs skip the round trip when nothing changed).

**Where fragmentation is unavoidable.** Two examples Khorikov concedes: **verifying email uniqueness** can't be done outside the controller without putting out-of-process dependencies in the domain model; and **failures in out-of-process dependencies that alter the course of the operation** can't be decided in the domain layer, because the domain layer isn't what calls them. Put that logic in controllers and cover it with integration tests — the separation is still worth it.

## Key Takeaways

1. **Classify code on complexity/domain-significance × collaborators.** Test the top-left quadrant heavily; delete the top-right quadrant by refactoring.
2. **The more important or complex the code, the fewer collaborators it should have.**
3. **Use the Humble Object pattern** to split overcomplicated code — it underlies hexagonal architecture, functional architecture, MVC/MVP, and DDD aggregates.
4. **Extracting interfaces for out-of-process dependencies isn't enough.** The domain model should not depend on them at all.
5. **You get two of three: domain model testability, controller simplicity, performance.** Choose splitting the decision-making into granular steps, then mitigate the controller complexity.
6. **Use CanExecute/Execute** to consolidate decisions in the domain layer — then the controller's `if` doesn't need testing.
7. **Use domain events** to abstract upcoming out-of-process calls, so you can test them as in-memory state.
8. **Test preconditions only when they carry domain significance.**
9. **Don't mock calls between domain classes.** Test each onion layer from the outer layer's perspective.

## Connects To
- **Ch 1**: Fulfills the second and third success attributes — targeting the most important parts of the code base, and *writing* (not just recognizing) valuable tests.
- **Ch 4**: The four pillars justify why the top-left quadrant gives the best cost/benefit.
- **Ch 5**: Observable behavior, encapsulation, tell-don't-ask, and the hexagonal architecture that the Humble Object pattern generalizes.
- **Ch 6**: Functional architecture as the extreme case of this refactoring; the same three-way trade-off appears there.
- **Ch 8**: How to test the controllers quadrant with integration tests — and why mocking the database is fragile.
- **Meszaros, *xUnit Test Patterns*** (Humble Object) · **Evans, *Domain-Driven Design*** (Aggregate) · **Martin & Martin, *Agile Principles, Patterns, and Practices in C#*** (SRP).
