# Chapter 9: Mocking Best Practices

## Core Idea
Restricting mocks to unmanaged dependencies gets you **two-thirds of the way** to good mocking. The remaining third: **verify interactions at the very edges of your system** — mock the *last* type in the chain between the controller and the external system, because that's where the actual observable side effect (the text message on the bus) lives.

## Frameworks Introduced

- **Verify Interactions at the System's Edges** — the chapter's headline rule.
  - How: *a call to an unmanaged dependency goes through several stages before it leaves your application. **Pick the last such stage.***
  - Why it improves **protection against regressions**: that metric is a function of how much code executes during the test (Ch 4). Mocking the last type means the integration test traverses more classes.
  - Why it improves **resistance to refactoring**: external systems expect *text messages*, not calls to classes like `MessageBus`. Text messages are the only externally observable side effect; the classes producing them are implementation details. No matter what refactoring happens, the test stays green as long as the message structure is preserved.
  - Same mechanism that gives integration and e2e tests their edge over unit tests: being more detached from the code base, they're less affected by low-level refactorings.

- **Spies (Handwritten Mocks) at System Edges**: **for classes residing at the system's edges, spies are superior to mocks.** They let you reuse assertion code, shrinking tests and improving readability via a fluent interface.
  - **The crucial distinction**: `BusSpy` is **test code**; `MessageBus` is **production code**. *You shouldn't rely on the production code when making assertions in tests.*
  - **Think of tests as auditors.** A good auditor doesn't take the auditee's word at face value — they double-check everything. A spy is an independent checkpoint that raises an alarm when the message structure changes; a mock on `IMessageBus` puts too much trust in production code.
  - Practical tip: **rename `BusSpy` to `BusMock`.** The mock/spy difference is an implementation detail, and most programmers don't know the term *spy* — the rename saves colleagues unnecessary confusion.

- **The Five Mocking Best Practices** (the complete list):
  1. **Apply mocks to unmanaged dependencies only.**
  2. **Verify interactions at the very edges of your system.**
  3. **Use mocks in integration tests only, never unit tests.**
  4. **Always verify the number of calls** — both expected calls' existence and unexpected calls' absence.
  5. **Only mock types that you own.**

- **Mocks Are for Integration Tests Only** — follows from Ch 7's separation of business logic and orchestration. Code either communicates with out-of-process dependencies or is complex, never both. That produces two layers: domain model (unit tests) and controllers (integration tests). Since mocks are for unmanaged dependencies, and only controllers touch those, **mocking belongs exclusively to controller tests.**

- **Verify Both Directions of Compatibility**: backward compatibility must go both ways — your application **shouldn't omit messages external systems expect**, and **shouldn't produce unexpected ones**.
  - `Times.Once` ensures the message is sent exactly once.
  - `VerifyNoOtherCalls()` (Moq) explicitly verifies no other calls were made.
  - `BusSpy.ShouldSendNumberOfMessages(1)` **encompasses both** checks at once.

- **Only Mock Types That You Own** (Freeman & Pryce): always write your own adapters on top of third-party libraries and mock the adapters, not the underlying types.
  - Their reasoning: you often don't deeply understand how third-party code works; even when it ships interfaces, mocking them is risky because you must be sure the mocked behavior matches what the library actually does; and adapters abstract non-essential technical details in your application's terms.
  - Adapters act as an **anti-corruption layer** (Evans, DDD): abstract the library's complexity, expose only the features you need, and do it in your project's domain language.
  - **The upgrade argument**: you never know how third-party code changes when you upgrade. An upgrade could cause a **ripple effect across the whole code base** — the adapter restricts that ripple to one class.
  - **Scope limit**: this guideline **doesn't apply to in-process or managed dependencies.** No need to abstract a date/time API (it reaches no unmanaged dependency) or an ORM (as long as the database isn't visible externally). You *can* wrap any library, but it's rarely worth the effort outside unmanaged dependencies.

## Key Concepts

- **Tautology test** — a test that doesn't verify anything because it contains semantically meaningless assertions. The risk of asserting with production code.
- **The two-wrapper pattern** — `IBus` wraps the vendor SDK (hiding connection credentials and technical details, exposing a clean interface for arbitrary text messages); `IMessageBus` wraps `IBus` (defining domain-specific messages, keeping them in one place, reusable across the app). **Keep them separate** — merging them would be suboptimal because the two responsibilities differ. Exactly parallel to `ILogger` / `IDomainLogger` from Ch 8.

## Mental Models

- **Think of the chain from controller to external system as a series of links, and mock the *last* one.** `EventDispatcher` → `IMessageBus` → `IBus` → the actual bus. Mock `IBus`. Don't mock `EventDispatcher` — it sits even further from the edge than `IMessageBus`.
- **Tests are auditors, not stenographers.** Duplicate literals and constants from production code into tests when necessary; the independence is the point.
- **Not all unmanaged dependencies need the same fidelity of backward compatibility.** With the message bus, *no* change to message structure is acceptable — you never know how external systems will react. With logs, the exact text structure doesn't matter to the intended audience (support staff, sysadmins); what matters is the logs' existence and the information they carry.
- **"One mock per test" is a misconception** rooted in the same error as "one assertion per test" (Ch 2/3): treating a *unit* as a unit of code. **It's irrelevant how many mocks it takes to verify a unit of behavior** — and you don't control the number anyway. It depends solely on how many unmanaged dependencies participate in the operation.

## Anti-patterns

- **Mocking an intermediate wrapper instead of the edge type** (`IMessageBus` rather than `IBus`): less code exercised (weaker regression protection) and coupled to your own class structure rather than the message contract (weaker refactoring resistance).
- **Asserting with production code**: a mock on `IMessageBus` verifies that your code called *your own class* correctly — it never checks the actual text leaving the application. Risks tautology tests.
- **Keeping a single-implementation interface after you stop mocking it**: once the test targets `IBus`, `IMessageBus` has no remaining justification (Ch 8's YAGNI rule) — delete it and use the concrete `MessageBus`.
- **Verifying only that a call happened**, without `Times.Once` / `VerifyNoOtherCalls()`: leaves the "no unexpected messages" half of backward compatibility unchecked.
- **Using mocks in unit tests**: a sign your domain model touches unmanaged dependencies, i.e. that the Ch 7 separation broke down.
- **Mocking third-party interfaces directly**: you may be mocking behavior the library doesn't actually have.

## Code Examples

**The two-wrapper chain — only the last link is at the edge:**

```csharp
public interface IMessageBus                       // intermediate — domain messages
{
    void SendEmailChangedMessage(int userId, string newEmail);
}

public class MessageBus : IMessageBus
{
    private readonly IBus _bus;

    public void SendEmailChangedMessage(int userId, string newEmail)
    {
        _bus.Send("Type: USER EMAIL CHANGED; " +
            $"Id: {userId}; " +
            $"NewEmail: {newEmail}");
    }
}

public interface IBus                              // the edge — wraps the vendor SDK
{
    void Send(string message);
}
```

**Retargeting the test from `IMessageBus` to `IBus`:**

```csharp
[Fact]
public void Changing_email_from_corporate_to_non_corporate()
{
    var busMock = new Mock<IBus>();
    var messageBus = new MessageBus(busMock.Object);   // concrete class, not the interface
    var loggerMock = new Mock<IDomainLogger>();
    var sut = new UserController(db, messageBus, loggerMock.Object);

    /* ... */

    busMock.Verify(
        x => x.Send(
            "Type: USER EMAIL CHANGED; " +
            $"Id: {user.UserId}; " +
            "NewEmail: new@gmail.com"),               // the actual text sent externally
        Times.Once);
}
```

**The spy with a fluent assertion interface:**

```csharp
public class BusSpy : IBus
{
    private List<string> _sentMessages = new List<string>();

    public void Send(string message)
    {
        _sentMessages.Add(message);                   // stores messages locally
    }

    public BusSpy ShouldSendNumberOfMessages(int number)
    {
        Assert.Equal(number, _sentMessages.Count);
        return this;
    }

    public BusSpy WithEmailChangedMessage(int userId, string newEmail)
    {
        string message = "Type: USER EMAIL CHANGED; " +
            $"Id: {userId}; " +
            $"NewEmail: {newEmail}";
        Assert.Contains(_sentMessages, x => x == message);
        return this;
    }
}
```

```csharp
// Usage — chained assertions read almost as plain English
var busSpy = new BusSpy();
var messageBus = new MessageBus(busSpy);
var loggerMock = new Mock<IDomainLogger>();
var sut = new UserController(db, messageBus, loggerMock.Object);

/* ... */

busSpy.ShouldSendNumberOfMessages(1)
    .WithEmailChangedMessage(user.UserId, "new@gmail.com");
```

**Both directions of backward compatibility:**

```csharp
messageBusMock.Verify(
    x => x.SendEmailChangedMessage(user.UserId, "new@gmail.com"),
    Times.Once);              // expected call exists, exactly once
messageBusMock.VerifyNoOtherCalls();   // no unexpected calls
```

## Reference Tables

| Mock target | Distance from edge | Protection against regressions | Resistance to refactoring |
|---|---|---|---|
| `EventDispatcher` | Furthest | Worst | Worst |
| `IMessageBus` | Intermediate | Moderate | Moderate |
| **`IBus`** | **At the edge** | **Best** | **Best** |

| | Mock | Spy |
|---|---|---|
| Created by | Mocking framework | Handwritten |
| Best for | General unmanaged dependencies | Classes at the system's edges |
| Assertion reuse | Repeated per test | Encapsulated in a fluent interface |
| Relationship to production code | May accidentally depend on it | Independent test-code checkpoint |

**When you may skip the "verify at the edges" rule**: when the exact message structure doesn't matter and you only need to confirm the message exists and carries the right information. **The typical example is logging** — mock `IDomainLogger`, not `ILogger`.

## Worked Example

**Why the CRM's integration test wasn't good enough — and the three-step fix.**

The starting point (end of Ch 8) mocked `IMessageBus` and `IDomainLogger`:

```csharp
messageBusMock.Verify(
    x => x.SendEmailChangedMessage(user.UserId, "new@gmail.com"),
    Times.Once);
```

**Step 1 — diagnose.** `IMessageBus` doesn't reside at the system's edge. The chain runs controller → `EventDispatcher` → `IMessageBus` → `IBus` → the bus itself. `IBus` is the last link; `IMessageBus` is merely an intermediate step. So the test verifies *a call to a class we wrote*, not *the text the external system receives*.

**Step 2 — retarget to `IBus`.** Now the assertion checks the literal string `"Type: USER EMAIL CHANGED; Id: 1; NewEmail: new@gmail.com"`. Two gains at once: more classes execute (better regression protection) and the assertion is pinned to the message contract rather than our class structure (better refactoring resistance). A side effect: `IMessageBus` had exactly one implementation and existed only to be mocked — with the mock gone, **delete the interface** and use `MessageBus` directly.

**Step 3 — replace the mock with a spy.** `BusSpy` captures sent messages and exposes `ShouldSendNumberOfMessages()` / `WithEmailChangedMessage()`, letting the assertion chain read as a sentence.

**The obvious objection — didn't we come full circle?** The final assertion

```csharp
busSpy.ShouldSendNumberOfMessages(1)
    .WithEmailChangedMessage(user.UserId, "new@gmail.com");
```

looks a lot like the original

```csharp
messageBusMock.Verify(
    x => x.SendEmailChangedMessage(user.UserId, "new@gmail.com"),
    Times.Once);
```

They *are* similar — both `BusSpy` and `MessageBus` are wrappers over `IBus`. **The crucial difference is which side of the fence each lives on.** `BusSpy` is test code; `MessageBus` is production code. If someone changes the message format inside `MessageBus`, the mock-on-`IMessageBus` version stays green (it never looked at the text), while `BusSpy` fails immediately — its independent copy of the expected string no longer matches.

**Why `IDomainLogger` wasn't retargeted to `ILogger`.** `DomainLogger` wraps `ILogger` exactly as `MessageBus` wraps `IBus`, so symmetry suggests retargeting. **In most projects it isn't necessary.** Both are unmanaged dependencies requiring backward compatibility, but *the required accuracy differs*. Message structure must be frozen because external systems parse it and you can't predict their reaction to a change. Log text structure isn't important to its audience — support staff and sysadmins care that the log exists and carries the right information. Mocking `IDomainLogger` alone gives the necessary protection.

## Key Takeaways

1. **Mock the last type in the chain before the unmanaged dependency.** That's where the externally observable side effect actually is.
2. **Prefer spies over mocks at system edges** — reusable fluent assertions, shorter and more readable tests.
3. **Never make assertions using production code.** Duplicate literals and constants into tests if needed; otherwise you risk tautology tests.
4. **Mocks belong in integration tests only.** Their presence in a unit test means your domain model touched something it shouldn't.
5. **The number of mocks per test is irrelevant** — it's determined by how many unmanaged dependencies the operation involves.
6. **Verify call counts, not just call existence.** Compatibility runs both ways: no missing messages, no surprise messages.
7. **Mock only types you own.** Wrap third-party libraries in adapters (an anti-corruption layer) and mock those — but only for unmanaged dependencies.
8. **Calibrate fidelity to the dependency.** Message buses need exact structural preservation; logs need only existence and content.

## Connects To
- **Ch 4**: Protection against regressions as a function of code executed — the justification for mocking at the edges.
- **Ch 5**: What a mock is, and why only inter-system communications qualify.
- **Ch 7**: The business logic/orchestration separation that confines mocks to controllers, hence to integration tests.
- **Ch 8**: Managed vs. unmanaged dependencies (the two-thirds rule); the `ILogger`/`IDomainLogger` pattern this chapter parallels; the YAGNI rule that justifies deleting `IMessageBus`.
- **Ch 2 / Ch 3**: The unit-of-behavior principle that debunks "one mock per test," mirroring "one assertion per test."
- **Ch 11**: Tautology tests among the anti-patterns.
- **Freeman & Pryce, *GOOS*** (mock only types you own, p. 69) · **Evans, *Domain-Driven Design*** (anti-corruption layer).
