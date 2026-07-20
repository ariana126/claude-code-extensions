# Chapter 3: The Anatomy of a Unit Test

## Core Idea
Every unit test follows **arrange, act, assert** — and the *shape* of those sections is a diagnostic for your production code. A two-line act section signals broken encapsulation; a bloated assert section signals a missing abstraction. Name tests as plain-English facts a domain expert would recognize, never with a rigid `Method_Scenario_Result` policy.

## Frameworks Introduced

- **The AAA (3A) Pattern**: split every test into three parts.
  - **Arrange** — bring the SUT and its dependencies to the desired state.
  - **Act** — call methods on the SUT, pass the prepared dependencies, capture the output.
  - **Assert** — verify the outcome (return value, final state of SUT/collaborators, or methods called on collaborators).
  - Why it works: uniformity. Once you internalize the structure you can read any test in the suite instantly, which directly lowers maintenance cost.
  - **Given-When-Then** is the same pattern with more readable labels — prefer it for tests shared with non-technical people.

- **Section Size as a Design Signal** — the chapter's most valuable reusable idea:
  | Section | Expected size | What a violation means |
  |---|---|---|
  | Arrange | Largest; up to act + assert combined | If much bigger, extract to private factory methods (or Object Mother / Test Data Builder) |
  | Act | **One line** | More than one line = the SUT's API lets a client leave the system inconsistent → **encapsulation breach** |
  | Assert | Multiple assertions are fine | Too many = missing abstraction in production code (e.g. add proper equality members instead of asserting field by field) |
  - Caveat: the one-line act rule holds for business-logic code, less so for utility/infrastructure code. Examine each exception rather than declaring "never."

- **Plain-English Test Naming**: three guidelines.
  1. **Don't follow a rigid naming policy** — you can't fit a high-level description of complex behavior into a narrow box. Allow freedom of expression.
  2. **Name the test as if describing the scenario to a non-programmer familiar with the problem domain** (a domain expert or business analyst).
  3. **Separate words with underscores** — improves readability in long names. (Not needed for class names, which stay short: `CalculatorTests`.)
  - Plus a corollary elevated to its own rule: **don't include the method under test in the test's name.** You test behavior, not code — renaming `IsDeliveryValid` to `IsDeliveryCorrect` shouldn't force a test rename. Exception: utility code with no business meaning.

- **Parameterized Tests (`[Theory]` + `[InlineData]`)**: group similar facts into one method to cut test code.
  - Trade-off rule: **keep positive and negative cases together only when the input parameters make it self-evident which is which.** Otherwise extract the positive case to its own descriptively named test. If the behavior is complex, skip parameterization entirely.

## Key Concepts

- **Test fixture** — (1) an object the test runs against, which must be in a known *fixed* state before each run; or (2) in NUnit, the `[TestFixture]` attribute. This book uses meaning (1).
- **Invariant violation** — an inconsistency in application state that shouldn't be possible (e.g. customer acquires product but store inventory isn't reduced).
- **Encapsulation** — the act of protecting your code against potential inconsistencies. The remedy for invariant violations: eliminate any course of action that could lead to one.
- **Fact vs. Theory** — in xUnit, `[Fact]` marks a single atomic scenario about the domain; `[Theory]` marks a bunch of facts grouped by parameters.
- **Object Mother / Test Data Builder** — the two popular patterns for reusing arrange-section code.
- **Teardown** — an optional fourth phase (close connections, delete files). Not part of AAA in this book; most unit tests don't need it, since they don't touch out-of-process dependencies.

## Mental Models

- **Read your act section as a design review.** If the client must remember to call a second method to finish one business operation, the API is wrong — not the test. From the business's view a successful purchase has two outcomes (customer acquires product, store inventory drops); both must happen together, so one public method must do both.
- **Think of `[Fact]` literally.** It's called `Fact`, not `Test`, because each test is an atomic fact about the problem domain, and a passing test proves the fact holds. If it fails, either the story is no longer valid or the system needs fixing.
- **Write tests as stories, not as an enumeration of what production code does.** Assertion libraries help because human stories follow `[Subject] [action] [object]` — *"Bob opened the door."* `result.Should().Be(30)` fits that pattern; `Assert.Equal(30, result)` doesn't.
- **Start with the assert section when doing TDD.** You don't yet know the feature's behavior, so formalize the objective first, then figure out how to satisfy it. When writing the test *after* the code, start with arrange — you already know what to expect.
- **Cryptic names impose a cognitive tax on everyone, programmers included.** It compounds quietly into suite-wide maintenance cost, especially when returning to a feature you've forgotten or reading a colleague's test.

## Anti-patterns

- **Multiple arrange/act/assert sections in a unit test**: the test verifies several units of behavior — it's an integration test now. Extract each act into its own test. *Exception*: acceptable in integration tests that are already slow, especially when one act naturally arranges the next.
- **`if` statements in tests**: a test should be a simple sequence of steps with no branching. Unlike multiple AAA sections, there is **no exception for integration tests** — branching buys nothing and costs readability.
- **Initializing fixtures in the test constructor / `[SetUp]`**: the most important anti-pattern in this chapter. It (a) **couples all tests to each other** — changing `AddInventory(Shampoo, 10)` to `15` breaks unrelated tests — and (b) **destroys readability**, since you can no longer see the full picture from the test itself. Violates the guideline *a modification of one test should not affect other tests*. (Distinct from Ch 2's independent *execution*; both matter.)
- **The `[MethodUnderTest]_[Scenario]_[ExpectedResult]` convention**: encourages focusing on implementation details instead of behavior. `Sum_TwoNumbers_ReturnsSum` — why does "Sum" appear twice, and where is it returned *to*?
- **`should be` in test names**: a test states a fact; there's no place for wish or desire. Use `is`.
- **One assertion per test**: rooted in the mistaken "smallest piece of code" premise. A single unit of behavior can have multiple outcomes; verify them all.

## Code Examples

**The two-line act section that reveals an encapsulation breach:**

```csharp
// Act  — BAD: two calls to perform one business operation
bool success = customer.Purchase(store, Product.Shampoo, 5);
store.RemoveInventory(success, Product.Shampoo, 5);
```
- **What it demonstrates**: If client code calls the first but not the second, the customer gets the product while inventory stays untouched. Once that inconsistency reaches the database you can't fix it by restarting — you're reconciling corrupted data and calling customers. `Customer.Purchase` must remove the inventory itself.

**The correct way to reuse fixtures — private factory methods:**

```csharp
public class CustomerTests
{
    [Fact]
    public void Purchase_succeeds_when_enough_inventory()
    {
        Store store = CreateStoreWithInventory(Product.Shampoo, 10);
        Customer sut = CreateCustomer();

        bool success = sut.Purchase(store, Product.Shampoo, 5);

        Assert.True(success);
        Assert.Equal(5, store.GetInventory(Product.Shampoo));
    }

    private Store CreateStoreWithInventory(Product product, int quantity)
    {
        Store store = new Store();
        store.AddInventory(product, quantity);
        return store;
    }

    private static Customer CreateCustomer() => new Customer();
}
```
- **What it demonstrates**: Shortens tests while keeping full context. The test *states* it wants 10 units of shampoo — readable without opening the factory, and reusable because it's parameterized rather than hardcoded.

**The one legitimate constructor exception — a base class for integration tests:**

```csharp
public class CustomerTests : IntegrationTests
{
    [Fact]
    public void Purchase_succeeds_when_enough_inventory()
    {
        /* use _database here */
    }
}

public abstract class IntegrationTests : IDisposable
{
    protected readonly Database _database;

    protected IntegrationTests() => _database = new Database();
    public void Dispose() => _database.Dispose();
}
```
- **What it demonstrates**: You may instantiate in a constructor when *all or almost all* tests use the fixture (a DB connection). Even then, put it in a base class, not individual test classes — `CustomerTests` stays constructor-less.

**Parameterized tests, and the `[MemberData]` escape hatch:**

```csharp
[InlineData(-1, false)]
[InlineData(0, false)]
[InlineData(1, false)]
[InlineData(2, true)]
[Theory]
public void Can_detect_an_invalid_delivery_date(int daysFromNow, bool expected)
{
    DeliveryService sut = new DeliveryService();
    DateTime deliveryDate = DateTime.Now.AddDays(daysFromNow);
    Delivery delivery = new Delivery { Date = deliveryDate };

    bool isValid = sut.IsDeliveryValid(delivery);

    Assert.Equal(expected, isValid);
}
```

You can't pass `DateTime.Now.AddDays(-1)` to `[InlineData]` — C# evaluates attribute contents at **compile time**, permitting only constants, literals, and `typeof()` expressions. Use `[MemberData]`:

```csharp
[Theory]
[MemberData(nameof(Data))]
public void Can_detect_an_invalid_delivery_date(DateTime deliveryDate, bool expected) { /* ... */ }

public static List<object[]> Data()
{
    return new List<object[]>
    {
        new object[] { DateTime.Now.AddDays(-1), false },
        new object[] { DateTime.Now,             false },
        new object[] { DateTime.Now.AddDays(1),  false },
        new object[] { DateTime.Now.AddDays(2),  true  }
    };
}
```

## Reference Tables

| xUnit | NUnit equivalent | Notes |
|---|---|---|
| `[Fact]` | `[Test]` | Named *Fact* deliberately — one atomic domain fact |
| `[Theory]` + `[InlineData]` | `[TestCase]` | A theory = a bunch of facts |
| `[MemberData(nameof(M))]` | `[TestCaseSource]` | For runtime-computed data |
| Constructor | `[SetUp]` | xUnit uses language constructs over attributes |
| `IDisposable.Dispose()` | `[TearDown]` | |
| *(any public class)* | `[TestFixture]` | xUnit relies on convention |

**Framework choice**: xUnit (preferred — cleaner, more concise) ≈ NUnit (on par) > MSTest (not recommended; less flexible — even the ASP.NET Core team uses xUnit).

**AAA comments — keep or drop?**
- **Drop** section comments when the test follows AAA and you can separate sections with single blank lines and no extra blank lines inside arrange/assert.
- **Keep** them otherwise — typically large integration tests with multi-stage setup.

## Worked Example

**Renaming a test, one guideline at a time.** Start with the rigid-policy version:

```csharp
public void IsDeliveryValid_InvalidDate_ReturnsFalse()
```

1. **Rewrite in plain English** → `Delivery_with_invalid_date_should_be_considered_invalid()`
   Two things changed: a non-programmer can now read it, and the method name `IsDeliveryValid` dropped out — a natural consequence that's easy to overlook but important enough to be its own guideline.
2. **Be specific about what "invalid" means.** The test shows an invalid date is a past date → `Delivery_with_past_date_should_be_considered_invalid()`
3. **Trim the verbosity** — `considered` adds nothing → `Delivery_with_past_date_should_be_invalid()`
4. **Replace `should be` with `is`** — a test states a fact, not a wish → `Delivery_with_past_date_is_invalid()`
5. **Don't avoid basic grammar**; articles make it read flawlessly → `Delivery_with_a_past_date_is_invalid()`

The final name is a straight-to-the-point statement of fact describing one aspect of the application's behavior.

**Then the trade-off when the behavior grows.** Say the soonest allowed delivery is two days out. You now need four facts (past, today, tomorrow, day-after). Parameterizing all four into `Can_detect_an_invalid_delivery_date(int daysFromNow, bool expected)` cuts the code — but you can no longer tell what the facts *are*, and it gets worse with more parameters. The compromise: parameterize the negative cases and give the positive case a descriptive name of its own, which also lets you drop the `expected` boolean:

```csharp
[InlineData(-1)] [InlineData(0)] [InlineData(1)]
[Theory]
public void Detects_an_invalid_delivery_date(int daysFromNow) { /* ... */ }

[Fact]
public void The_soonest_delivery_date_is_two_days_from_now() { /* ... */ }
```

Descriptive naming is preserved exactly where it matters most: at the boundary distinguishing valid from invalid.

## Key Takeaways

1. **Follow AAA everywhere.** Multiple act sections mean multiple units of behavior — split the test (except in already-slow integration tests).
2. **A multi-line act section is a production-code smell**, not a test smell. It usually means missing encapsulation and a possible invariant violation.
3. **Name the SUT `sut`** so it's distinguishable from its dependencies at a glance.
4. **Reuse fixtures via private factory methods, never the constructor.** Constructors couple tests together and hide context. Exception: a base class for fixtures used by nearly all tests.
5. **Name tests in plain English, underscore-separated, without the method under test.** State facts (`is`), not wishes (`should be`).
6. **Never put `if` statements in tests** — no exceptions.
7. **Parameterize similar facts, but watch the readability trade-off.** Extract positive cases when the parameters don't speak for themselves.
8. **Use a fluent assertion library** (e.g. Fluent Assertions) to make assertions read as `[Subject] [action] [object]`.

## Connects To
- **Ch 2**: Where "unit of behavior, not unit of code" is established — the premise behind both the naming guidelines and rejecting one-assertion-per-test.
- **Ch 5**: Why naming tests after the method under test couples tests to implementation details.
- **Ch 7**: Encapsulation and invariant protection developed fully, as the foundation of good domain-model design.
- **Part 3 / Ch 10**: Proper teardown and database cleanup for integration tests.
- **Given-When-Then / BDD**: the non-programmer-readable framing of AAA — the bridge to executable specifications.
