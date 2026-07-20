# Chapter 6: Styles of Unit Testing

## Core Idea
There are three testing styles — **output-based, state-based, communication-based** — and they rank in exactly that order. Output-based testing wins because it only works on **mathematical functions** (no hidden inputs or outputs), which are inherently the most testable code. So the way to get better tests is to restructure production code toward **functional architecture**: a functional core that makes decisions, wrapped in a mutable shell that acts on them.

## Frameworks Introduced

- **The Three Styles of Unit Testing** — you can use one, two, or all three in a single test.
  - **Output-based** (a.k.a. *functional*): feed an input to the SUT, check the returned output. Only applicable to code with no global/internal state change.
  - **State-based**: verify the state of the system after an operation completes — the SUT's own state, a collaborator's, or an out-of-process dependency's.
  - **Communication-based**: substitute collaborators with mocks and verify the SUT calls them correctly.
  - School alignment: **classical prefers state-based; London prefers communication-based; both use output-based.**

- **Functional Programming = Programming with Mathematical Functions**: A **mathematical function (pure function)** has **no hidden inputs or outputs** — everything is expressed in the method signature (name, arguments, return type). It produces the same output for a given input no matter how many times it's called.
  - **The three kinds of hidden inputs/outputs to hunt for:**
    1. **Side effects** — an output not in the signature: mutating a class instance's state, updating a file on disk.
    2. **Exceptions** — create a path bypassing the contract established by the signature; catchable anywhere in the call stack, so an additional output the signature doesn't convey.
    3. **A reference to internal or external state** — `DateTime.Now`, a database query, a private mutable field. Hidden *inputs*.
  - **The test for purity — referential transparency**: can you replace a call to the method with its return value without changing program behavior? `int y = Increment(4);` ≡ `int y = 5;` → pure. A method incrementing a field and returning it → not pure; the mutation is a hidden output.

- **Functional Architecture** — *maximizes the amount of code written in a purely functional (immutable) way, while minimizing code that deals with side effects.*
  - The goal is **not to eliminate side effects** (an app with no side effects is useless) but to **separate business logic from side effects by pushing side effects to the edges of a business operation.**
  - Two code categories: **code that makes a decision** (no side effects needed → mathematical functions) and **code that acts upon that decision** (converts decisions into visible bits — DB changes, bus messages).
  - **Functional core** (a.k.a. immutable core) makes decisions. **Mutable shell** supplies inputs and applies side effects.
  - **The cooperation loop**: shell gathers all inputs → core generates decisions → shell converts decisions into side effects.
  - **Key discipline**: the decision objects must contain enough information for the shell to act *without additional decision-making*. **The mutable shell should be as dumb as possible** — no branching, no `if` statements. Cover the core extensively with output-based tests; leave the shell to a much smaller number of integration tests.

- **Functional Architecture as a Subset of Hexagonal**: Both separate concerns and enforce a one-way dependency flow (core/domain doesn't depend on shell/app services). **The difference is the treatment of side effects.**
  - Hexagonal is fine with side effects made by the domain layer, as long as they stay *within* that layer — a domain class can change its own state, and an application service picks that up and persists it.
  - Functional architecture pushes **all** side effects out of the core. *"Functional architecture is hexagonal architecture taken to an extreme."*

## Key Concepts

- **Mock chains** — mocks or stubs returning other mocks, several layers deep. The main driver of communication-based tests' poor maintainability.
- **Code pollution** — polluting the production code base with code whose sole purpose is to enable or simplify unit testing. (Full treatment in Ch 11.)
- **Immutable / mutable** — immutable means unchangeable: once created, state can't be modified.
- **Collaborator vs. value, revisited** — `_maxEntriesPerFile` is a hidden-looking dependency but is actually a **value**: derivable from the constructor signature and immutable between construction and the call. `IDatabase` is a **collaborator** (a proxy to data not yet in memory), which is why it breaks purity. ***A class from the functional core should work not with a collaborator, but with the product of its work — a value.***

## Mental Models

- **Michael Feathers' framing**: *"Object-oriented programming makes code understandable by encapsulating moving parts. Functional programming makes code understandable by minimizing moving parts."*
- **Immutability makes encapsulation unnecessary.** Encapsulation protects against state corruption by reducing the modification surface and scrutinizing what's left. Immutability solves the same problem differently: *you can't corrupt something that can't be changed*. Validate once at construction, then pass it around freely — the entire class of lack-of-encapsulation problems vanishes.
- **Think "read–decide–act."** The shell reads everything, the core decides, the shell acts. If your flow can't gather all inputs up front, functional architecture may not fit.
- **The decisions a functional core produces are always values.** Two instances with matching contents are interchangeable — which is exactly what lets you compress multi-line assertions into one equality check.
- **Prefer output-based, but don't chase purity.** *"The goal of this chapter is not to incite you to transition all your tests toward the output-based style; the goal is to transition as many of them as reasonably possible."* In an OOP language you'll end up with a mix, and that's fine.

## Anti-patterns

- **Overusing communication-based testing** → **shallow tests** that verify a thin slice of code and mock out everything else. (Not intrinsic to the style — an extreme case of abuse.)
- **Exposing private state purely to enable state-based testing**: the brittleness trap of the state-based style.
- **Converting a class to a value object when it isn't inherently a value**: leads to code pollution.
- **Passing a collaborator (`IDatabase`) into a functional-core method**: introduces a hidden input, kills purity, and rules out output-based testing.
- **Making the domain model depend on the database** to resolve the above: explicitly called out as *not a good idea*.
- **Applying functional architecture everywhere**: in simple or business-unimportant code bases the initial investment never pays off.

## Code Examples

**The three styles side by side:**

```csharp
// OUTPUT-BASED — the only outcome is the return value
public decimal CalculateDiscount(params Product[] products)
{
    decimal discount = products.Length * 0.01m;
    return Math.Min(discount, 0.2m);
}

[Fact]
public void Discount_of_two_products()
{
    var sut = new PriceEngine();
    decimal discount = sut.CalculateDiscount(
        new Product("Hand wash"), new Product("Shampoo"));
    Assert.Equal(0.02m, discount);
}
```

```csharp
// STATE-BASED — the outcome is a change to the order's state
[Fact]
public void Adding_a_product_to_an_order()
{
    var product = new Product("Hand wash");
    var sut = new Order();

    sut.AddProduct(product);

    Assert.Equal(1, sut.Products.Count);
    Assert.Equal(product, sut.Products[0]);
}
```

```csharp
// COMMUNICATION-BASED — the outcome is a call to a collaborator
[Fact]
public void Sending_a_greetings_email()
{
    var emailGatewayMock = new Mock<IEmailGateway>();
    var sut = new Controller(emailGatewayMock.Object);

    sut.GreetUser("user@email.com");

    emailGatewayMock.Verify(
        x => x.SendGreetingsEmail("user@email.com"), Times.Once);
}
```

**Shrinking a bloated state-based assertion — two mitigations:**

```csharp
// Four assertion lines for one comment...
Assert.Equal(1, sut.Comments.Count);
Assert.Equal(text, sut.Comments[0].Text);
Assert.Equal(author, sut.Comments[0].Author);
Assert.Equal(now, sut.Comments[0].DateCreated);

// (1) Helper methods — only worth it if reused across many tests
sut.ShouldContainNumberOfComments(1).WithComment(text, author, now);

// (2) Turn Comment into a value object + Fluent Assertions
sut.Comments.Should().BeEquivalentTo(comment);   // also removes the count check
```
- **What it demonstrates**: Both work only occasionally, and even then state-based tests stay larger than output-based ones. Helper methods cost real effort to write and maintain; value-object conversion only applies when the class *is* inherently a value.

## Reference Tables

| | Output-based | State-based | Communication-based |
|---|---|---|---|
| **Due diligence to maintain resistance to refactoring** | Low | Medium | Medium |
| **Maintainability costs** | Low | Medium | High |

*Protection against regressions and fast feedback are roughly equal across all three styles* — protection depends on code volume/complexity/domain significance, not style; speed differs only negligibly (mocks add slight runtime latency, irrelevant below tens of thousands of tests).

**Why the resistance-to-refactoring ranking:** output-based tests couple only to the method under test (the sole failure mode being that the method *is itself* an implementation detail). State-based tests additionally touch the class's state — a larger API surface, hence more chances to hit a leaking detail. Communication-based tests are most vulnerable: *always* wrong for stubs, and right for mocks only across the application boundary.

## Worked Example

**Refactoring an audit system through three versions.** The system appends `visitorName;timeOfVisit` to the most recent `audit_{index}.txt`, creating a new file when the entry limit is reached.

**Version 1 — direct filesystem access.** `AuditManager.AddRecord()` calls `Directory.GetFiles()`, `File.ReadAllLines()`, `File.WriteAllText()` directly. Tests must plant files, then read/check/clear them. The filesystem is a *shared dependency*, so tests can't be parallelized without significant maintenance cost. These aren't even unit tests — they fail the "quickly" and "in isolation" criteria.

| | Initial |
|---|---|
| Protection against regressions | Good |
| Resistance to refactoring | Good |
| Fast feedback | **Bad** |
| Maintainability | **Bad** |

**Version 2 — mock the filesystem.** Extract `IFileSystem` (`GetFiles`, `WriteAllText`, `ReadAllLines`), inject it via the constructor, mock it in tests:

```csharp
[Fact]
public void A_new_file_is_created_when_the_current_file_overflows()
{
    var fileSystemMock = new Mock<IFileSystem>();
    fileSystemMock.Setup(x => x.GetFiles("audits"))
        .Returns(new[] { @"audits\audit_1.txt", @"audits\audit_2.txt" });
    fileSystemMock.Setup(x => x.ReadAllLines(@"audits\audit_2.txt"))
        .Returns(new List<string>
        {
            "Peter; 2019-04-06T16:30:00",
            "Jane; 2019-04-06T16:40:00",
            "Jack; 2019-04-06T17:00:00"
        });
    var sut = new AuditManager(3, "audits", fileSystemMock.Object);

    sut.AddRecord("Alice", DateTime.Parse("2019-04-06T18:00:00"));

    fileSystemMock.Verify(x => x.WriteAllText(
        @"audits\audit_3.txt", "Alice;2019-04-06T18:00:00"));
}
```

Note this is a **legitimate** use of mocks: the files are visible to end users (read via other software or notepad), so filesystem communications are part of observable behavior. Fast feedback goes Good; maintainability only reaches *Moderate* — the setups are convoluted.

**Version 3 — functional architecture.** Move side effects out of `AuditManager` entirely. It now receives `FileContent[]` and *returns an instruction* rather than performing the write:

```csharp
public FileUpdate AddRecord(
    FileContent[] files, string visitorName, DateTime timeOfVisit)
{
    (int index, FileContent file)[] sorted = SortByIndex(files);
    string newRecord = visitorName + ';' + timeOfVisit;

    if (sorted.Length == 0)
        return new FileUpdate("audit_1.txt", newRecord);

    (int currentFileIndex, FileContent currentFile) = sorted.Last();
    List<string> lines = currentFile.Lines.ToList();

    if (lines.Count < _maxEntriesPerFile)
    {
        lines.Add(newRecord);
        return new FileUpdate(currentFile.FileName, string.Join("\r\n", lines));
    }
    else
    {
        int newIndex = currentFileIndex + 1;
        return new FileUpdate($"audit_{newIndex}.txt", newRecord);
    }
}
```

`Persister` becomes the mutable shell — and notice **it has no branching at all**; all complexity lives in the core:

```csharp
public class Persister
{
    public FileContent[] ReadDirectory(string directoryName) =>
        Directory.GetFiles(directoryName)
            .Select(x => new FileContent(Path.GetFileName(x), File.ReadAllLines(x)))
            .ToArray();

    public void ApplyUpdate(string directoryName, FileUpdate update) =>
        File.WriteAllText(
            Path.Combine(directoryName, update.FileName), update.NewContent);
}
```

`ApplicationService` glues them together in the read–decide–act order and provides the external entry point. In hexagonal taxonomy: `ApplicationService` and `Persister` are the application services layer; `AuditManager` is the domain model.

The test becomes plain inputs and outputs:

```csharp
[Fact]
public void A_new_file_is_created_when_the_current_file_overflows()
{
    var sut = new AuditManager(3);
    var files = new FileContent[]
    {
        new FileContent("audit_1.txt", new string[0]),
        new FileContent("audit_2.txt", new string[]
        {
            "Peter; 2019-04-06T16:30:00",
            "Jane; 2019-04-06T16:40:00",
            "Jack; 2019-04-06T17:00:00"
        })
    };

    FileUpdate update = sut.AddRecord(
        files, "Alice", DateTime.Parse("2019-04-06T18:00:00"));

    Assert.Equal("audit_3.txt", update.FileName);
    Assert.Equal("Alice;2019-04-06T18:00:00", update.NewContent);
}
```

Make `FileUpdate` a value object (a `struct` or custom equality members) and it compresses further:

```csharp
update.Should().Be(new FileUpdate("audit_3.txt", "Alice;2019-04-06T18:00:00"));
```

| | Initial | With mocks | Output-based |
|---|---|---|---|
| Protection against regressions | Good | Good | Good |
| Resistance to refactoring | Good | Good | Good |
| Fast feedback | Bad | Good | Good |
| Maintainability | Bad | Moderate | **Good** |

**A design rule that falls out of this**: keep `FileContent`/`FileUpdate` as close as possible to the framework's built-in file commands, and do all parsing in the functional core so the shell stays trivial. If .NET only had `File.ReadAllText()` (returning one string) rather than `ReadAllLines()`, you'd store `string Text` in `FileContent` and parse inside `AuditManager`.

**Where it breaks — and the two escape hatches.** Suppose the system must check a visitor's access level (stored in a DB) when their 24-hour visit count exceeds a threshold. You *cannot* pass `IDatabase` into `AddRecord()` — that's a hidden input, and the method stops being a mathematical function. Two options:
1. **Gather the access level up front** in the application service, alongside the directory content. Cost: performance — you query the DB unconditionally, even when unneeded. Benefit: separation stays fully intact; all decision-making remains in `AuditManager`.
2. **Add `IsAccessLevelCheckRequired()`** to `AuditManager`; the service calls it first and only fetches from the DB if `true`. Cost: a degree of separation — the decision to call the DB now lives in the application service.

## Key Takeaways

1. **Prefer output-based testing over everything else**, then state-based, then communication-based — but the constraint is that output-based only works on purely functional code.
2. **A mathematical function has no hidden inputs or outputs.** Side effects and exceptions are hidden outputs; references to internal/external state are hidden inputs.
3. **Use referential transparency as the purity test**: can you swap the call for its return value?
4. **Functional architecture separates deciding from acting.** The core decides and returns values; the dumb shell gathers inputs and applies side effects.
5. **Functional architecture is hexagonal taken to an extreme** — the difference is whether the domain layer may produce side effects at all.
6. **Immutability substitutes for encapsulation.** Validate once at construction; corruption becomes impossible rather than merely guarded against.
7. **The trade-off is real**: functional architecture concedes **performance** (more calls to out-of-process dependencies, since you must read everything up front) and **initial code size** for maintainability. Apply it strategically based on system complexity and importance.
8. **Don't chase purity.** Aim for a mix weighted toward output-based, not a total conversion.

## Connects To
- **Ch 4**: The four pillars used as the scoring rubric for comparing the three styles.
- **Ch 5**: Hexagonal architecture, observable behavior, and the mocking rules that explain communication-based testing's poor showing. The audit-system mock is validated by Ch 5's inter-system rule.
- **Ch 2**: The collaborator/value distinction, which decides whether a dependency breaks functional purity.
- **Ch 7**: Balancing performance against separation of concerns; the Humble Object pattern generalizes the core/shell split.
- **Ch 11**: Code pollution and exposing private state, both flagged here.
- **Scott Wlaschin, fsharpforfunandprofit.com** — recommended for a deeper dive into functional programming.
