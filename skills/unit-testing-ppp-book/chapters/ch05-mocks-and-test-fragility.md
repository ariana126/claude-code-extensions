# Chapter 5: Mocks and Test Fragility

## Core Idea
**Mocking is legitimate only for inter-system communications that cross the application boundary and whose side effects are visible to the external world.** Mocking intra-system communications (class-to-class inside your app) couples tests to implementation details and destroys resistance to refactoring. The chapter builds the machinery to tell the two apart: mocks vs. stubs, observable behavior vs. implementation details, and hexagonal architecture.

## Frameworks Introduced

- **Mocks vs. Stubs — the two-type reduction**: Meszaros lists five test doubles (dummy, stub, spy, mock, fake); they collapse into two.
  - **Mocks** help **emulate *and* examine outcoming interactions** — calls the SUT makes to dependencies **to change their state** (side effects). Example: sending an email.
  - **Stubs** help **emulate incoming interactions** — calls the SUT makes to dependencies **to get input data**. No side effect. Example: reading from a database.
  - The other three are insignificant implementation details: a **spy** is a handwritten mock; a **dummy** is a hardcoded value (null, made-up string) that just satisfies a signature; a **fake** is a stub created to replace a dependency that doesn't exist yet.
  - When a double is both mock and stub, **call it a mock** — being a mock is the more important fact.

- **Never Assert Interactions with Stubs**: the single sharpest rule in the chapter, and the easiest violation to spot.
  - Why: a call to a stub isn't part of the end result — it's only a *means* to produce it. The stub provides input from which the SUT generates output.
  - How to apply: `stub.Verify(...)` is always wrong. `mock.Verify(...)` may be right; check whether the interaction crosses the app boundary.

- **CQS (Command Query Separation)** — maps cleanly onto mocks and stubs.
  - **Commands** produce side effects and return `void`. → substituted by **mocks**.
  - **Queries** are side-effect free and return a value. → substituted by **stubs**.
  - Rule: if a method has a side effect, its return type must be `void`; if it returns a value, it must be side-effect free. *"Asking a question should not change the answer."*
  - Exceptions exist (`stack.Pop()` both mutates and returns), but adhere whenever you can — you can then tell what a method does from its signature alone.

- **The Definition of Observable Behavior** — the load-bearing definition of the whole book. Code is part of observable behavior **only if** it does one of these:
  1. **Exposes an operation that helps the client achieve one of its goals.** (An *operation* is a method that performs a calculation, incurs a side effect, or both.)
  2. **Exposes a state that helps the client achieve one of its goals.** (*State* is the current condition of the system.)
  - Anything else is an **implementation detail**. Crucially, this **depends on who the client is and what its goals are** — for a domain class the client is an application service; for an application service it's the external client.

- **The Two-Dimension Grid of Production Code**: public/private API × observable behavior/implementation detail. **Well-designed code** is code whose observable behavior coincides with the public API and whose implementation details are hidden behind the private API. Code **leaks** implementation details when its public API extends beyond its observable behavior.

- **The One-Operation Rule of Thumb**: *"If the number of operations the client has to invoke on the class to achieve a single goal is greater than one, then that class is likely leaking implementation details. Ideally, any individual goal should be achieved with a single operation."* Examine every violation for a leak. (Holds for business logic; less so for utility code.)

- **Hexagonal Architecture** (Alistair Cockburn) — three guidelines:
  1. **Separation of concerns** between domain and application services. The domain layer holds business logic only; application services orchestrate between the domain layer and the external world. *View the domain layer as the application's domain knowledge (**how-to's**) and the application services layer as business use cases (**what-to's**).*
  2. **One-way flow of dependencies** — application services → domain. Domain classes depend only on each other and are fully isolated from the external world.
  3. **External applications connect through a common interface maintained by the application services layer.** Nobody accesses the domain layer directly. (A hexagon has six sides but the number of connections is arbitrary.)

- **Intra-system vs. Inter-system Communications** — the decision rule for mocking.
  - **Intra-system** (class ↔ class inside your app) = **implementation details**. Mocking these produces fragile tests.
  - **Inter-system** (your app ↔ external applications) = **part of observable behavior**, because separate applications evolve together under **backward compatibility**. Mocking these is legitimate and beneficial.
  - **The critical exception**: *if an out-of-process dependency is only accessible through your application, communications with it are not part of observable behavior.* It effectively acts as part of your application, so don't mock it.

## Key Concepts

- **Mock (the tool) vs. mock (the test double)** — `Mock<IEmailGateway>` is a class from a mocking library (the tool); the *instance* may be either a mock or a stub. Don't conflate them: the same tool creates both types.
- **Over-specification** — verifying things that aren't part of the end result. Most commonly occurs when examining interactions.
- **Invariant** — a condition that should hold true at all times. **Encapsulation** protects against **invariant violations**.
- **Tell-don't-ask** (Martin Fowler) — bundling data with the functions that operate on it. A corollary of encapsulation: hiding implementation details removes internals from clients' eyes; bundling data with operations ensures those operations don't violate invariants.
- **Test isolation** — the ability for tests to run in parallel, sequentially, and in any order.
- **Application database** — a database used only by your application, with no external access. You can modify its schema, or replace the storage mechanism entirely, and no client will notice.

## Mental Models

- **Think of mocking intra-system communication as "deriving a person's behavior by measuring the signals neurons in the brain pass among each other."** Too granular. The client doesn't care which neurons light up when they ask you for help — only the help itself matters. **Mocks verify behavior only when the interaction crosses the application boundary and its side effects are visible externally.**
- **Tests have a fractal structure when each layer's API is well-designed.** An application-service test checks the coarse-grained goal posed by the external client; a domain-class test verifies a subgoal on the way to it. This is *why* every test should be traceable to a business requirement: observable behavior flows inward, so the connection can be traced recursively from the domain layer outward to the external client's needs.
- **A well-designed API and good unit tests are the same problem.** *"By making all implementation details private, you leave your tests no choice other than to verify the code's observable behavior."* Fixing the API automatically improves the tests.
- **Encapsulation exists because you can't trust yourself.** *"You cannot trust yourself to do the right thing all the time — so, eliminate the very possibility of doing the wrong thing."* Without encapsulation you must hold too much in your head to avoid introducing inconsistencies. Encapsulation serves the same ultimate goal as unit testing: sustainable growth.
- **There's no such thing as "leaking observable behavior."** The asymmetry is definitional: hide a method and the client can't use it, so it ceases to have an immediate connection to a client goal — and therefore stops being observable behavior.

## Anti-patterns

- **Asserting interactions with stubs** (`stub.Verify(x => x.GetNumberOfUsers(), Times.Once)`): the flagship anti-pattern. How the SUT gathers its data shouldn't matter as long as the result is correct.
- **Mocking intra-system communication** (`storeMock.Verify(x => x.RemoveInventory(...))`): `RemoveInventory` is an intermediate step toward the client's goal, not the goal itself.
- **Mocking an out-of-process dependency you fully control** (an application database): you don't want tests turning red every time you split a table or change a stored-procedure parameter type. **The database and your application must be treated as one system.**
- **Exposing an operation the client must remember to call** (`NormalizeName`): leaks implementation details *and* breaks encapsulation, letting the client bypass the invariant.
- **Exposing internal collaborators as public state** (`MessageRenderer.SubRenderers`): the exact leak that made Ch 4's brittle test possible.

## Code Examples

**A mock (examines an outcoming interaction):**

```csharp
[Fact]
public void Sending_a_greetings_email()
{
    var mock = new Mock<IEmailGateway>();          // mock (the tool)
    var sut = new Controller(mock.Object);

    sut.GreetUser("user@email.com");

    mock.Verify(                                    // examines the call
        x => x.SendGreetingsEmail("user@email.com"),
        Times.Once);
}
```

**A stub (emulates an incoming interaction) — note the same tool:**

```csharp
[Fact]
public void Creating_a_report()
{
    var stub = new Mock<IDatabase>();               // mock (the tool) → stub (the double)
    stub.Setup(x => x.GetNumberOfUsers()).Returns(10);   // canned answer
    var sut = new Controller(stub.Object);

    Report report = sut.CreateReport();

    Assert.Equal(10, report.NumberOfUsers);
    // stub.Verify(x => x.GetNumberOfUsers(), Times.Once);  ← NEVER do this
}
```

**Leaking implementation details, and the fix:**

```csharp
// BEFORE — NormalizeName is public; the client must remember to call it
public class User
{
    public string Name { get; set; }

    public string NormalizeName(string name)
    {
        string result = (name ?? "").Trim();
        if (result.Length > 50)
            return result.Substring(0, 50);
        return result;
    }
}

public class UserController
{
    public void RenameUser(int userId, string newName)
    {
        User user = GetUserFromDatabase(userId);
        string normalizedName = user.NormalizeName(newName);   // two operations
        user.Name = normalizedName;                            // for one goal
        SaveUserToDatabase(user);
    }
}
```

```csharp
// AFTER — the invariant is enforced by the setter; the client can't bypass it
public class User
{
    private string _name;
    public string Name
    {
        get => _name;
        set => _name = NormalizeName(value);
    }

    private string NormalizeName(string name) { /* trim to 50 chars */ }
}

public class UserController
{
    public void RenameUser(int userId, string newName)
    {
        User user = GetUserFromDatabase(userId);
        user.Name = newName;                                   // one operation
        SaveUserToDatabase(user);
    }
}
```
- **What it demonstrates**: The one-operation rule of thumb in action — two operations dropped to one. `NormalizeName` can't be traced to any client goal (the external client never asked for normalized names; it's an internal restriction), so it's an implementation detail and must be private. Tests should verify it only *through* the `Name` setter.

## Reference Tables

| | Observable behavior | Implementation detail |
|---|---|---|
| **Public** | Good | **Bad** (a leak) |
| **Private** | N/A (impossible) | Good |

| | Emulates | Examines | Interaction | CQS | Example |
|---|---|---|---|---|---|
| **Mock** | ✅ | ✅ | Outcoming (side effect) | Command | `SendGreetingsEmail()` |
| **Stub** | ✅ | ❌ never | Incoming (input data) | Query | `GetNumberOfUsers()` |

| Communication | Kind | Mock it? |
|---|---|---|
| App ↔ SMTP service, message bus, third-party API | Inter-system | ✅ Yes — backward compatibility must be preserved |
| App ↔ its own application database | Inter-system but externally unobservable | ❌ No — treat as one system with the app |
| Domain class ↔ domain class | Intra-system | ❌ No — implementation detail |

## Worked Example

**One business use case, two kinds of communication.** The requirement:

> A customer tries to purchase a product from a store. If there's enough inventory: the inventory is removed from the store, an email receipt is sent to the customer, and a confirmation is returned.

The application is an API with no UI. `CustomerController` is the application service:

```csharp
public class CustomerController
{
    public bool Purchase(int customerId, int productId, int quantity)
    {
        Customer customer = _customerRepository.GetById(customerId);
        Product product = _productRepository.GetById(productId);

        bool isSuccess = customer.Purchase(_mainStore, product, quantity);

        if (isSuccess)
        {
            _emailGateway.SendReceipt(customer.Email, product.Name, quantity);
        }

        return isSuccess;
    }
}
```

Mapped onto the hexagon: the **inter-system** communications are `CustomerController` ↔ the third-party client and `CustomerController` ↔ the email gateway. The **intra-system** communication is `Customer` ↔ `Store`.

**Legitimate mocking** — the SMTP call is a side effect visible to the external world, and the third-party client expects the customer to receive a confirmation email as part of a successful purchase:

```csharp
[Fact]
public void Successful_purchase()
{
    var mock = new Mock<IEmailGateway>();
    var sut = new CustomerController(mock.Object);

    bool isSuccess = sut.Purchase(customerId: 1, productId: 2, quantity: 5);

    Assert.True(isSuccess);
    mock.Verify(
        x => x.SendReceipt("customer@email.com", "Shampoo", 5),
        Times.Once);
}
```
(`isSuccess` is also observable by the external client and needs verification — but by simple value comparison, not mocking.)

**Fragile mocking** — the same syntax, the wrong target:

```csharp
[Fact]
public void Purchase_succeeds_when_enough_inventory()
{
    var storeMock = new Mock<IStore>();
    storeMock.Setup(x => x.HasEnoughInventory(Product.Shampoo, 5)).Returns(true);
    var customer = new Customer();

    bool success = customer.Purchase(storeMock.Object, Product.Shampoo, 5);

    Assert.True(success);
    storeMock.Verify(x => x.RemoveInventory(Product.Shampoo, 5), Times.Once);
}
```

Why this one is wrong: `RemoveInventory()` **doesn't cross the application boundary** — caller and recipient both live inside the app. And it's neither an operation nor a state helping the client achieve its goal. The client of these two domain classes is `CustomerController`, whose goal is making a purchase. Only **two** members connect immediately to that goal: `customer.Purchase()` (initiates it) and `store.GetInventory()` (shows the resulting state). `RemoveInventory()` is an intermediate step — an implementation detail.

**Why the classical school wins, restated.** The London school mocks all but immutable dependencies and **doesn't differentiate intra-system from inter-system communication**, so it checks class-to-class collaboration as readily as app-to-app. Since resistance to refactoring is binary, compromising it renders tests nearly worthless. The classical school is better — it substitutes only shared dependencies, which almost always means out-of-process ones — **but it isn't ideal either**, because it still over-mocks out-of-process dependencies that your application fully controls.

## Key Takeaways

1. **Five test doubles reduce to two.** Mocks examine outcoming interactions (commands); stubs emulate incoming ones (queries).
2. **Never assert interactions with stubs.** This is over-specification and always produces fragile tests.
3. **Code is observable behavior only if it exposes an operation or state that helps a *client* achieve a *goal*.** Everything else is an implementation detail — and the answer depends on who the client is.
4. **Make implementation details private.** A well-designed API leaves tests no choice but to verify observable behavior. Expose the absolute minimum operations and state.
5. **If a client needs more than one operation to achieve one goal, suspect a leak.**
6. **Mock inter-system communications only** — and only when their side effects are visible to the external world.
7. **Don't mock out-of-process dependencies you fully control.** An application database is part of your system; treat them as one.
8. **Encapsulation and unit testing serve the same goal**: sustainable growth. Both work by making the wrong thing impossible rather than merely discouraged.

## Connects To
- **Ch 2**: The London/classical split, revisited and finally adjudicated here.
- **Ch 3**: Encapsulation and invariant violations, introduced via the two-line act section; here they become the theory of API design.
- **Ch 4**: Supplies resistance to refactoring — the metric this whole chapter defends. The `MessageRenderer` brittle test is re-diagnosed here as a leaked-state problem.
- **Ch 6 & 7**: How to test work with a fully controlled out-of-process dependency without sacrificing fast feedback — the open problem this chapter leaves.
- **Ch 8**: Integration testing, where mocking unmanaged dependencies becomes the core technique.
- **Ch 9**: Mocking best practices, building directly on the inter-system rule.
- **Martin Fowler, *Tell-Don't-Ask*** · **Alistair Cockburn, *Hexagonal Architecture*** · **Meszaros, *xUnit Test Patterns***.
