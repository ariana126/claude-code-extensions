# Chapter 11: Unit Testing Anti-patterns

## Core Idea
An **anti-pattern** is a common solution to a recurring problem that looks appropriate on the surface but leads to problems down the road. Every anti-pattern here reduces to one root cause: **giving tests special privileges the production code doesn't have** — exposing private methods or state, duplicating the algorithm, or adding production code that exists only for tests. All of them destroy resistance to refactoring.

## Frameworks Introduced

- **Don't Unit Test Private Methods** — test them **indirectly**, as part of the overarching observable behavior. When a private method resists that, there are exactly **two diagnoses**:
  1. **Dead code** — if the uncovered code isn't used, it's likely leftover from a refactoring. **Delete it.**
  2. **A missing abstraction** — if the private method is too complex to test through the public API, extract it into a **separate class**.

- **The Rare Exception — private methods that *are* observable behavior**: methods implementing a **non-public contract between the class and an ORM or a factory**. A private ORM constructor still fulfills a real contract — the ORM couldn't restore objects from the database without it — and the fact that it's private doesn't make that contract less important.
  - Two acceptable resolutions: **make the constructor public** (this arguably brings the API *closer* to well-designed — just ensure it contains all preconditions needed to maintain encapsulation), or **instantiate via reflection in tests** if you want to keep the public surface minimal. The reflection route "looks like a hack," but you're only doing what the ORM already does behind the scenes.

- **The Special-Privileges Rule**: ***your tests should interact with the SUT exactly the same way as the production code and shouldn't have any special privileges.*** This single principle generates the private-method and private-state guidelines.
  - The diagnostic move for private state: **look at how the production code uses the class.** If production doesn't care about a field, it wouldn't be public — so tests shouldn't care either. Verify what production *does* care about.
  - The rule is dynamic: **if the production code later starts using a field, it officially becomes observable behavior**, and tests may couple to it then.
  - *Widening the public API surface for the sake of testability is a bad practice.*

- **Don't Leak Domain Knowledge to Tests**: ***don't imply any specific implementation when writing tests.*** Instead of duplicating the algorithm, **hard-code its expected results**.
  - **The critical qualifier**: precalculate the hardcoded values **using something other than the SUT** — ideally with a domain expert. When refactoring a legacy application, you can have the legacy code produce the expected values.
  - Why the duplication is fatal: such tests score **almost zero on resistance to refactoring** and *have no chance of differentiating legitimate failures from false positives*. When the algorithm changes and the test fails, the team will simply copy the new algorithm into the test without investigating — understandably, since the test was a duplicate to begin with.

- **Code Pollution** — *adding production code that's only needed for testing.* It mixes test and production code and inflates production's maintenance cost. Usually takes the form of **switches** (e.g. `new Logger(isTestEnvironment: true)`).
  - The fix: introduce an interface with a real implementation (production) and a fake one (test code).
  - **The subtle point**: `ILogger` is *arguably* code pollution too — it lives in production but exists for testing. But its pollution is **less damaging and easier to deal with**: you **can't accidentally invoke a code path not intended for production**, and **you can't have bugs in interfaces** since they're contracts with no code. Boolean switches add surface area for bugs; interfaces don't.

- **Mocking Concrete Classes Is an SRP Violation**: *the necessity to mock a concrete class in order to preserve part of its functionality is a result of violating the Single Responsibility principle.*
  - The tell: you reach for `new Mock<T> { CallBase = true }` with a `virtual` method, because you want to stub *one* method while keeping the rest intact.
  - The fix: **split the class in two** — one holding domain logic, one communicating with the out-of-process dependency (backed by an interface you can mock properly). This is the **Humble Object pattern** (Ch 7).

- **Working with Time — three options, ranked**:
  1. **Ambient context** (`DateTimeServer.Init(() => ...)` with a static field) — **an anti-pattern**. It pollutes production code, makes testing harder, and the **static field introduces a dependency shared between tests**, transitioning them into integration testing.
  2. **Inject time as a service** (`IDateTimeServer`) — acceptable.
  3. **Inject time as a plain value** (`DateTime`) — **preferred**. Easier to work with in production and easier to stub in tests.
  - **The practical compromise**: dependency injection frameworks don't play well with value objects, so **inject the time as a service at the start of a business operation and pass it as a value through the remainder**. (The controller accepts `IDateTimeServer`; it passes a `DateTime` to the `Inquiry` domain class.)
  - Why any of this is needed: time-dependent functionality produces false positives, because *the time during the act phase might not be the same as in the assert*.

## Key Concepts

- **Anti-pattern** — a common solution to a recurring problem that looks appropriate on the surface but leads to problems further down the road.
- **`CallBase = true`** — a Moq setting telling the mock to preserve the base class's behavior unless explicitly overridden. Enables partial substitution — and signals an SRP violation.

## Mental Models

- **Testing private methods isn't bad in and of itself** — it's bad because private methods are a **proxy for implementation details**, and testing implementation details is what causes brittleness. Once you see a genuinely private-but-contractual method (an ORM constructor), the prohibition dissolves.
- **The publicity/purpose grid still governs everything.** Public + observable behavior = good. Public + implementation detail = bad. Private + implementation detail = good. Private + observable behavior = "N/A" — *except* in the rare ORM/factory case, which is why the marking isn't entirely correct.
- **Hardcoding expected results feels counterintuitive but is good practice.** The test's job is to be an independent check, not a second implementation. (Same reasoning as Ch 9's "don't rely on production code when making assertions.")
- **When a test can't reach something, ask what production does** rather than how to grant the test more access.

## Anti-patterns

*(This chapter is the anti-pattern catalogue; the complete list, with the reason each fails:)*

- **Exposing private methods for testing** → couples tests to implementation details, destroying resistance to refactoring.
- **Exposing private state for testing** → same, plus it violates the special-privileges rule.
- **Leaking domain knowledge to tests** (recomputing the algorithm in the arrange section) → near-zero resistance to refactoring; can't distinguish real failures from false positives.
- **Code pollution** (test-environment booleans, ambient contexts) → mixes test and production code, raising production maintenance costs and adding bug surface.
- **Mocking concrete classes with `CallBase = true`** → masks a Single Responsibility violation.
- **Time as an ambient context** → pollution *plus* a shared static dependency that breaks test isolation.

## Code Examples

**Missing abstraction — extract the complex private method:**

```csharp
// BEFORE — a simple public method hiding complex, business-critical private logic
public class Order
{
    private Customer _customer;
    private List<Product> _products;

    public string GenerateDescription()
    {
        return $"Customer name: {_customer.Name}, " +
            $"total number of products: {_products.Count}, " +
            $"total price: {GetPrice()}";
    }

    private decimal GetPrice()      // needs thorough testing, unreachable through the API
    {
        decimal basePrice = /* Calculate based on _products */;
        decimal discounts = /* Calculate based on _customer */;
        decimal taxes = /* Calculate based on _products */;
        return basePrice - discounts + taxes;
    }
}
```

```csharp
// AFTER — the abstraction made explicit
public class Order
{
    public string GenerateDescription()
    {
        var calc = new PriceCalculator();
        return $"Customer name: {_customer.Name}, " +
            $"total number of products: {_products.Count}, " +
            $"total price: {calc.Calculate(_customer, _products)}";
    }
}

public class PriceCalculator
{
    public decimal Calculate(Customer customer, List<Product> products)
    {
        decimal basePrice = /* Calculate based on products */;
        decimal discounts = /* Calculate based on customer */;
        decimal taxes = /* Calculate based on products */;
        return basePrice - discounts + taxes;
    }
}
```
- **What it demonstrates**: `PriceCalculator` is now testable independently *and* has no hidden inputs or outputs — so you can use **output-based testing** (Ch 6), the highest-quality style.

**The private-but-observable constructor:**

```csharp
public class Inquiry
{
    public bool IsApproved { get; private set; }
    public DateTime? TimeApproved { get; private set; }

    private Inquiry(bool isApproved, DateTime? timeApproved)   // ORM contract
    {
        if (isApproved && !timeApproved.HasValue)
            throw new Exception();       // the precondition that preserves encapsulation

        IsApproved = isApproved;
        TimeApproved = timeApproved;
    }

    public void Approve(DateTime now)
    {
        if (IsApproved) return;
        IsApproved = true;
        TimeApproved = now;
    }
}
```

**Private state — test the discount, not the status:**

```csharp
public class Customer
{
    private CustomerStatus _status = CustomerStatus.Regular;

    public void Promote() => _status = CustomerStatus.Preferred;

    public decimal GetDiscount() =>
        _status == CustomerStatus.Preferred ? 0.05m : 0m;
}
```
Don't make `_status` public. Production code doesn't use it (or it would already be public) — it only cares about the discount. So verify: **a newly created customer has no discount**, and **after promotion the discount is 5%**.

**Domain knowledge leakage, and the fix:**

```csharp
// WRONG — the test reimplements the algorithm
[Theory]
[InlineData(1, 3)]
[InlineData(11, 33)]
[InlineData(100, 500)]
public void Adding_two_numbers(int value1, int value2)
{
    int expected = value1 + value2;      // the leakage
    int actual = Calculator.Add(value1, value2);
    Assert.Equal(expected, actual);
}
```

```csharp
// RIGHT — results hardcoded, precalculated independently of the SUT
[Theory]
[InlineData(1, 3, 4)]
[InlineData(11, 33, 44)]
[InlineData(100, 500, 600)]
public void Adding_two_numbers(int value1, int value2, int expected)
{
    int actual = Calculator.Add(value1, value2);
    Assert.Equal(expected, actual);
}
```

**Code pollution — replace the switch with an interface:**

```csharp
// WRONG — a test-environment flag in production code
public class Logger
{
    private readonly bool _isTestEnvironment;

    public Logger(bool isTestEnvironment) => _isTestEnvironment = isTestEnvironment;

    public void Log(string text)
    {
        if (_isTestEnvironment) return;   // the switch
        /* Log the text */
    }
}
```

```csharp
// RIGHT — production logger stays simple; the fake lives in test code
public interface ILogger { void Log(string text); }

public class Logger : ILogger            // production code
{
    public void Log(string text) { /* Log the text */ }
}

public class FakeLogger : ILogger        // test code
{
    public void Log(string text) { /* Do nothing */ }
}
```

**Mocking a concrete class — the tell and the cure:**

```csharp
// THE TELL — partial mocking to keep Calculate() while stubbing GetDeliveries()
[Fact]
public void Customer_with_no_deliveries()
{
    var stub = new Mock<StatisticsCalculator> { CallBase = true };
    stub.Setup(x => x.GetDeliveries(1))          // GetDeliveries must be made virtual
        .Returns(new List<DeliveryRecord>());
    var sut = new CustomerController(stub.Object);

    string result = sut.GetStatistics(1);

    Assert.Equal("Total weight delivered: 0. Total cost: 0", result);
}
```

```csharp
// THE CURE — split the two responsibilities
public class DeliveryGateway : IDeliveryGateway
{
    public List<DeliveryRecord> GetDeliveries(int customerId)
    {
        /* Call an out-of-process dependency */
    }
}

public class StatisticsCalculator
{
    public (double totalWeight, double totalCost) Calculate(List<DeliveryRecord> records)
    {
        double totalWeight = records.Sum(x => x.Weight);
        double totalCost = records.Sum(x => x.Cost);
        return (totalWeight, totalCost);
    }
}

public class CustomerController
{
    public CustomerController(
        StatisticsCalculator calculator,   // pure logic — concrete class
        IDeliveryGateway gateway)          // out-of-process — interface, mockable
    { /* ... */ }
}
```
- **What it demonstrates**: `Calculate()` was the domain logic; `GetDeliveries()` merely gathered its inputs. Splitting them is the Humble Object pattern, and it removes the need for partial mocking entirely.

**Time — anti-pattern vs. preferred:**

```csharp
// ANTI-PATTERN — ambient context with a shared static field
public static class DateTimeServer
{
    private static Func<DateTime> _func;
    public static DateTime Now => _func();
    public static void Init(Func<DateTime> func) => _func = func;
}
```

```csharp
// PREFERRED — service at the boundary, plain value inside
public interface IDateTimeServer { DateTime Now { get; } }
public class DateTimeServer : IDateTimeServer { public DateTime Now => DateTime.Now; }

public class InquiryController
{
    private readonly IDateTimeServer _dateTimeServer;

    public InquiryController(IDateTimeServer dateTimeServer)   // injected as a service
        => _dateTimeServer = dateTimeServer;

    public void ApproveInquiry(int id)
    {
        Inquiry inquiry = GetById(id);
        inquiry.Approve(_dateTimeServer.Now);                  // passed as a plain value
        SaveInquiry(inquiry);
    }
}
```

## Reference Tables

| | Observable behavior | Implementation detail |
|---|---|---|
| **Public** | Good | Bad |
| **Private** | N/A* | Good |

\* *Except the rare ORM/factory contract case — which is exactly why this cell isn't quite accurate.*

| Anti-pattern | Root cause | Fix |
|---|---|---|
| Testing private methods | Proxy for implementation details | Test via observable behavior; extract missing abstractions |
| Exposing private state | Tests granted special privileges | Verify what production code actually uses |
| Leaking domain knowledge | Test duplicates the algorithm | Hardcode results precalculated elsewhere |
| Code pollution | Test concerns in production code | Interface + separate fake in test code |
| Mocking concrete classes | SRP violation | Split logic from out-of-process communication |
| Time as ambient context | Pollution + shared static state | Inject as service at the boundary, value within |

| Time approach | Verdict |
|---|---|
| Ambient context (static) | Anti-pattern |
| Injected as a service | Acceptable |
| Injected as a plain value | **Preferred** |

## Worked Example

**The credit-inquiry system — when "never test private methods" meets reality.**

The system bulk-loads new credit inquiries into the database once a day; administrators then review and approve them one by one. The `Inquiry` class has a **private constructor**, because the class is restored from the database by an ORM. The ORM doesn't need a public constructor — it works fine with a private one — and the system itself doesn't need one either, since it isn't responsible for creating inquiries.

This produces a genuine dilemma. The **approval logic is clearly important and must be unit tested**, but you can't instantiate the object, and making the constructor public would violate the rule against exposing private methods.

Khorikov's resolution: **this constructor is both private and part of observable behavior.** It fulfills a contract with the ORM, and privacy doesn't diminish that contract's importance — without it, the ORM couldn't restore inquiries at all. So making it public **won't lead to test brittleness here**; it arguably improves the API. The one requirement: **the constructor must contain all the preconditions needed to maintain encapsulation** — in this case, that every approved inquiry has an approval time:

```csharp
if (isApproved && !timeApproved.HasValue)
    throw new Exception();
```

If you'd rather keep the public surface minimal, **instantiate via reflection in tests** instead. It looks like a hack, but you're just doing what the ORM does.

The general shape of the rule: **private methods that belong to observable behavior are those implementing a non-public contract between the class and an ORM or a factory.** Outside that narrow case, the prohibition stands.

## Key Takeaways

1. **Test private methods indirectly.** If that's impossible, you have either dead code (delete it) or a missing abstraction (extract it).
2. **Rare exception**: private methods implementing an ORM/factory contract are observable behavior — make them public with proper preconditions, or use reflection.
3. **Tests get no special privileges.** Never expose private state; verify what the production code actually consumes.
4. **Never reimplement the algorithm in the test.** Hardcode results precalculated by a domain expert, or by legacy code during a refactoring.
5. **Keep test code out of production.** Prefer an interface plus a test-side fake over a production-side boolean switch — interfaces can't harbor bugs or accidental production code paths.
6. **Needing `CallBase = true` means the class does two jobs.** Split domain logic from out-of-process communication.
7. **Inject time explicitly** — as a value where possible, as a service at the operation boundary otherwise. Never as an ambient context.

## Connects To
- **Ch 4**: The four pillars, especially resistance to refactoring — the metric every anti-pattern here damages — and the black-box/white-box distinction behind "don't leak domain knowledge."
- **Ch 5**: Observable behavior vs. implementation details, and the publicity/purpose grid this chapter revisits and qualifies.
- **Ch 6**: Output-based testing, enabled once `PriceCalculator` is extracted; code pollution first named there.
- **Ch 7**: The Humble Object pattern — the general form of the `StatisticsCalculator` split.
- **Ch 8**: Ambient context first identified as an anti-pattern, in the logging discussion.
- **Ch 9**: "Don't rely on production code when making assertions" — the same independence principle as hardcoding expected results.
- **Author's resources**: enterprisecraftsmanship.com (blog, code reviews, Q&A), unittestingcourse.com (online course), @vkhorikov.
