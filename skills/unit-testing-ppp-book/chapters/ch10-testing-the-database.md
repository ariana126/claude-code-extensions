# Chapter 10: Testing the Database

## Core Idea
Integration tests against a **real** database provide bulletproof protection against regressions — but only if you first do the prep work: **keep the schema in source control, give every developer their own instance, and use migration-based delivery**. Then the operational rules: **a separate unit of work per test section**, **clean data at the start of a test**, **run sequentially**, and **never use an in-memory database**.

## Frameworks Introduced

- **The Three Prerequisites** for testing the database:
  1. **Keep the database in the source control system.** Treat the schema as regular code. A dedicated "model database" instance is an anti-pattern: **no change history** (you can't trace the schema to a past point, which matters when reproducing production bugs) and **no single source of truth** (the model database competes with Git). *No modifications to database structure should be made outside source control.*
  2. **A separate database instance for every developer**, preferably on their own machine to maximize test speed. A shared database means tests interfere with each other and non-backward-compatible changes block other developers.
  3. **Apply the migration-based approach** to delivery.

- **State-based vs. Migration-based Delivery**:
  - **State-based**: SQL scripts describing the desired state live in source control; a comparison tool does all the heavy lifting at deploy time (drop tables, create new ones, rename columns). **Makes the state explicit, migrations implicit.**
  - **Migration-based**: explicit migrations transition the database from one version to another; migrations, not state, are the artifacts in source control. **Makes migrations explicit, state implicit** — you can't view the state directly, you assemble it from migrations.
  - **The trade-off**: explicit state eases **merge conflicts**; explicit migrations tackle **data motion**. **Data motion is far more important in the vast majority of projects** — unless you're pre-release, you always have data you can't discard.
  - **Why comparison tools can't handle data motion**: *the database schema is objective — there's only one way to interpret it — but data is context-dependent.* No tool can make reliable assumptions; you must apply domain-specific rules. (Splitting `Name` into `FirstName`/`LastName` requires a script that splits every existing name, not just DDL.)
  - **Verdict**: state-based is impractical in most projects. You may use it temporarily pre-release (test data is disposable), but switch to migration-based once you ship.
  - **The migration discipline**: *apply every schema modification (including reference data) through migrations. Don't modify migrations once committed — if one is incorrect, create a new migration rather than fixing the old one.* Exception: when the incorrect migration can lead to data loss.

- **Reference Data Is Part of the Schema**: data that must be prepopulated for the application to operate properly (e.g. a `UserType` table backing a foreign key constraint).
  - **The test to distinguish it**: *if your application can modify the data, it's regular data; if not, it's reference data.*
  - Keep it in source control as SQL `INSERT` statements. Reference and regular data can coexist in one table if you add a flag marking the unmodifiable rows and forbid the application from changing them.

- **Repositories + Transaction (or Unit of Work)**: separate two decisions the controller *can't* make simultaneously — **what data to update** and **whether to keep the updates or roll them back**. It only knows the latter after all steps succeed, and it can only take those steps by accessing the database.
  - **Repositories** enable access to and modification of data; **short-lived**, disposable as soon as the call completes, and they *enlist themselves* into the current transaction.
  - **A transaction** commits or rolls back all updates in full; **lives for the whole business operation**.
  - `Commit()` marks the transaction successful — called by the controller, because it requires decision-making, and placed at the very end so any error returns early and prevents commit. `Dispose()` ends the transaction indiscriminately — no decision-making, so delegate it to the infrastructure-layer class that instantiated the controller.
  - **Unit of work** — maintains a list of objects affected by a business operation, then figures out and executes all updates as a single unit. **Advantage over a plain transaction: deferral of updates**, which shortens the underlying database transaction, reduces data congestion, and often reduces the number of database calls. Most ORMs implement it for you (`ISession` in NHibernate, `DbContext` in Entity Framework).

- **The Four Data-Cleanup Options** — ranked:

  | Approach | Verdict |
  |---|---|
  | Restore a database backup before each test | Solves cleanup but **much slower**; even with containers, several seconds per test adds up |
  | Clean up at the **end** of a test | Fast but **susceptible to skipping** — a build-server crash or stopping in the debugger leaves data behind |
  | Wrap each test in an uncommitted transaction | Solves skipping but **creates a setup different from production** — same problem as reusing a unit of work |
  | **Clean up at the beginning of a test** | **Best**: fast, no inconsistent behavior, can't be skipped |

  *There's no need for a separate teardown phase; implement it as part of the arrange section.* Put the deletion script in a base class for all integration tests. **Write the SQL manually** in foreign-key order — sophisticated algorithms to derive table relationships or disabling integrity constraints are unnecessary; manual scripts are simpler and give granular control. **The deletion script must remove all regular data but none of the reference data** — reference data is controlled solely by migrations.

- **Code Reuse by Test Section**:
  - **Arrange** → **Object Mother** (factory methods with default arguments). Preferred over **Test Data Builder** (fluent `new UserBuilder().WithEmail(...).Build()`), which improves readability slightly but *requires too much boilerplate* — at least in C#, where optional arguments are a language feature.
  - **Act** → a **decorator method** taking a delegate for the controller function, wrapping it in database-context creation.
  - **Assert** → a **fluent interface**, implemented in C# via extension methods on the domain classes.
  - **Where to put factory methods**: start simple — same class by default. Move to separate helper classes only when duplication becomes a significant issue. **Don't put them in the base class**; reserve that for code that must run in every test, like data cleanup.

## Key Concepts

- **Data motion** — changing the shape of existing data so it conforms to a new schema.
- **Atomic updates** — executed all-or-nothing; each update must complete in its entirety or have no effect.
- **Model database** (anti-pattern) — a dedicated live instance serving as the reference point for schema changes.

## Mental Models

- **Integration tests must replicate the production environment as closely as possible.** In production each business operation gets an exclusive `CrmContext`, created just before the controller call and disposed right after. A test sharing one context across arrange/act/assert creates an environment the controller never sees in production.
- **Even independent queries aren't independent if they share a context.** The assert section may query the user and company separately from the arrange section, but if they share a `DbContext`, the ORM may serve **cached** data — defeating the whole point of verifying database state independently (Ch 8).
- **Reads and writes have asymmetric stakes.** Mistakes in writes cause data corruption affecting your database *and* external applications. A bug in a read usually doesn't. So **the threshold for testing reads should be higher** — test only the most complex or important ones.
- **Encapsulation is pointless for reads.** Domain modeling exists mainly for encapsulation, and encapsulation is about preserving consistency across *changes*. No changes, no need — so reads need no domain model and no full ORM. **Plain SQL is superior performance-wise**, bypassing unnecessary abstraction layers. And since reads have hardly any abstraction layers, **unit tests are useless there** — if you test reads, use integration tests on a real database.
- **Advocate against premature parallelization, not against Docker.** You *can* run your single per-developer instance in a container; what's not worth it is a container per test.

## Anti-patterns

- **Using a model database instance** as the source of truth for schema.
- **Sharing a database between developers.**
- **Reusing a database transaction or unit of work across test sections**: the setup diverges from production and ORM caching can mask real failures.
- **Parallelizing integration tests**: requires making all test data unique so constraints aren't violated and tests don't pick up each other's input; cleanup gets trickier too. **More practical to run sequentially.** (Disable parallelization for the integration-test collection specifically.)
- **A container per integration test**: too much maintenance burden — maintaining Docker images, ensuring each test gets its own instance, batching tests (you can't create all containers at once), and disposing used-up containers. Only if you *absolutely* must minimize execution time.
- **In-memory databases (SQLite)**: tempting because they need no cleanup, run faster, and can be instantiated per test — but **they aren't functionally consistent with regular databases**. You'll hit false positives or (worse) **false negatives**, never gain good protection, and end up doing a lot of manual regression testing anyway. ***Use the same DBMS in tests as in production — version or edition may differ, but the vendor must not.***
- **Testing repositories directly**: they sit in the **controllers quadrant** (little complexity, an out-of-process dependency), so they carry the full maintenance cost of an integration test while their protection-against-regressions gains largely **overlap** with the regular integration tests. Best course: extract what little complexity they have into a self-contained algorithm and test that (what `UserFactory`/`CompanyFactory` did). **This separation is impossible with an ORM** — you can't test ORM mappings without hitting the database, at least not without compromising resistance to refactoring. So: *don't test repositories directly, only as part of the overarching integration test suite.*
- **Testing `EventDispatcher` separately**: too few regression-protection gains for the cost of maintaining complicated mock machinery.

## Code Examples

**A migration (FluentMigrator):**

```csharp
[Migration(1)]
public class CreateUserTable : Migration
{
    public override void Up()   => Create.Table("Users");
    public override void Down() => Delete.Table("Users");   // for downgrading to reproduce a bug
}
```
Popular plain-SQL alternatives: **Flyway**, **Liquibase**.

**Controller with a unit of work (Entity Framework):**

```csharp
public class UserController
{
    private readonly CrmContext _context;
    private readonly UserRepository _userRepository;
    private readonly CompanyRepository _companyRepository;
    private readonly EventDispatcher _eventDispatcher;

    public UserController(CrmContext context, MessageBus messageBus, IDomainLogger domainLogger)
    {
        _context = context;
        _userRepository = new UserRepository(context);
        _companyRepository = new CompanyRepository(context);
        _eventDispatcher = new EventDispatcher(messageBus, domainLogger);
    }

    public string ChangeEmail(int userId, string newEmail)
    {
        User user = _userRepository.GetUserById(userId);

        string error = user.CanChangeEmail();
        if (error != null) return error;          // early return prevents the commit

        Company company = _companyRepository.GetCompany();
        user.ChangeEmail(newEmail, company);

        _companyRepository.SaveCompany(company);
        _userRepository.SaveUser(user);
        _eventDispatcher.Dispatch(user.DomainEvents);

        _context.SaveChanges();                   // commit at the very end
        return "OK";
    }
}
```
- **What it demonstrates**: `UserFactory` and `CompanyFactory` are **no longer needed** — Entity Framework now maps raw database data to domain objects. Note repositories take the context as a constructor parameter, making it explicit that **a repository can't call the database on its own**.

**The cleanup base class:**

```csharp
public abstract class IntegrationTests
{
    private const string ConnectionString = "...";

    protected IntegrationTests()
    {
        ClearDatabase();
    }

    private void ClearDatabase()
    {
        string query =
            "DELETE FROM dbo.[User];" +
            "DELETE FROM dbo.Company;";

        using (var connection = new SqlConnection(ConnectionString))
        {
            var command = new SqlCommand(query, connection)
            {
                CommandType = CommandType.Text
            };
            connection.Open();
            command.ExecuteNonQuery();
        }
    }
}
```

**Object Mother with defaults:**

```csharp
private User CreateUser(
    string email = "user@mycorp.com",
    UserType type = UserType.Employee,
    bool isEmailConfirmed = false)
{
    using (var context = new CrmContext(ConnectionString))
    {
        var user = new User(0, email, type, isEmailConfirmed);
        new UserRepository(context).SaveUser(user);
        context.SaveChanges();
        return user;
    }
}
```
Defaults let you specify arguments selectively, which **emphasizes which arguments are relevant to the test scenario**.

**Decorator method for the act section:**

```csharp
private string Execute(
    Func<UserController, string> func,
    MessageBus messageBus,
    IDomainLogger logger)
{
    using (var context = new CrmContext(ConnectionString))
    {
        var controller = new UserController(context, messageBus, logger);
        return func(controller);
    }
}
```

**Fluent assertions via extension methods:**

```csharp
public static class UserExtensions
{
    public static User ShouldExist(this User user)
    {
        Assert.NotNull(user);
        return user;
    }

    public static User WithEmail(this User user, string email)
    {
        Assert.Equal(email, user.Email);
        return user;
    }
}
```

## Reference Tables

| | State-based | Migration-based |
|---|---|---|
| Explicit in source control | The state | The migrations |
| Implicit | Migrations (tool-generated) | The state (assembled from migrations) |
| Eases | Merge conflicts | **Data motion** |
| Verdict | Only pre-release | **Preferred** |

| Test section | Reuse technique |
|---|---|
| Arrange | Object Mother (factory methods with default args) |
| Act | Decorator method taking a delegate |
| Assert | Fluent interface via extension methods |

| What to test | Guidance |
|---|---|
| Writes | Test thoroughly — high stakes, data corruption risk |
| Reads | Higher threshold; only the most complex or important; integration tests only |
| Repositories | Never directly — only via the overarching integration suite |
| `EventDispatcher` | Don't test separately |

## Worked Example

**The four-transaction bug, and the fix.**

The original `Database` class opened a new `SqlConnection` per method call, each implicitly starting its own transaction. So a single `ChangeEmail` business operation created **four separate transactions**: `GetUserById`, `GetCompany`, `SaveCompany`, `SaveUser`.

Multiple transactions are fine for **read-only** operations. But when the operation mutates data, all updates must be **atomic**. The concrete failure: the controller successfully persists the company, then fails saving the user due to a connectivity issue — and `Company.NumberOfEmployees` becomes permanently inconsistent with the actual count of `Employee` users.

The fix splits `Database` into **repositories** (what to update) and a **transaction** (whether to keep the updates). All four database calls remain, but the transaction now mediates them so modifications commit or roll back in full. Upgrading further to a **unit of work** (`CrmContext`) defers the updates to the end, shortening the database transaction's life and reducing congestion.

**Refactoring the integration test — from three contexts to five, on purpose.**

The starting test wrapped everything in one `using (var context = new CrmContext(...))`, sharing it across arrange, act, and assert. That's wrong on two counts: the act section shares a context the production controller would own exclusively, and the assert section may read ORM-cached data rather than the true database state. **Guideline: use at least three transactions or units of work — one per section.**

Then extracting the technicalities (Object Mother, decorator, fluent assertions) leaves:

```csharp
public class UserControllerTests : IntegrationTests
{
    [Fact]
    public void Changing_email_from_corporate_to_non_corporate()
    {
        // Arrange
        User user = CreateUser(email: "user@mycorp.com", type: UserType.Employee);
        CreateCompany("mycorp.com", 1);

        var busSpy = new BusSpy();
        var messageBus = new MessageBus(busSpy);
        var loggerMock = new Mock<IDomainLogger>();

        // Act
        string result = Execute(
            x => x.ChangeEmail(user.UserId, "new@gmail.com"),
            messageBus, loggerMock.Object);

        // Assert
        Assert.Equal("OK", result);

        User userFromDb = QueryUser(user.UserId);
        userFromDb
            .ShouldExist()
            .WithEmail("new@gmail.com")
            .WithType(UserType.Customer);

        Company companyFromDb = QueryCompany();
        companyFromDb
            .ShouldExist()
            .WithNumberOfEmployees(0);

        busSpy.ShouldSendNumberOfMessages(1)
            .WithEmailChangedMessage(user.UserId, "new@gmail.com");
        loggerMock.Verify(
            x => x.UserTypeHasChanged(
                user.UserId, UserType.Employee, UserType.Customer),
            Times.Once);
    }
}
```

**The cost**: each helper (`CreateUser`, `CreateCompany`, `Execute`, `QueryUser`, `QueryCompany`) instantiates its own context, so the test now uses **five** units of work instead of three. Khorikov names this explicitly as **another trade-off between fast feedback and maintainability** — and takes maintainability. The performance hit is small, especially with the database on the developer's machine; the maintainability gain is substantial.

**The payoff, stated plainly**: the sample project transitioned to Entity Framework *within this chapter*, and only a couple of lines in the integration test needed changing to confirm the transition worked. *Integration tests working directly with managed dependencies are the most efficient way to protect against bugs resulting from large-scale refactorings* — database refactorings, ORM switches, even changing the database vendor.

## Key Takeaways

1. **Schema (including reference data) belongs in source control**, applied exclusively through migrations that are never edited after commit.
2. **Prefer migration-based delivery** — data motion matters far more than merge conflicts.
3. **One database instance per developer**, ideally local.
4. **Make business operations atomic** via a transaction, and upgrade to a unit of work where possible.
5. **Use at least three units of work per integration test** — one per arrange/act/assert — so the test matches production.
6. **Clean data at the start of the test**, via a base class, with a hand-written deletion script that spares reference data.
7. **Run integration tests sequentially**; skip parallelization and per-test containers.
8. **Never substitute an in-memory database.** Same DBMS vendor as production.
9. **Shorten tests with Object Mother, decorator methods, and fluent assertions** — and accept the extra database contexts as a worthwhile maintainability trade.
10. **Test writes thoroughly, reads selectively, repositories never (directly).**

## Connects To
- **Ch 8**: Managed dependencies included as-is — this chapter is the practical follow-through; also the rule about checking database state independently of input parameters, which the per-section-context rule enforces.
- **Ch 9**: `BusSpy` and its fluent interface, the model for the fluent data assertions here.
- **Ch 7**: The code quadrants that place repositories in the controllers quadrant and justify not testing them directly; `UserFactory`/`CompanyFactory`, now superseded by the ORM.
- **Ch 3**: Object Mother and Test Data Builder, first mentioned as arrange-section reuse patterns.
- **Ch 5 & 6**: Encapsulation as consistency-preservation — the reason reads need no domain model.
- **Ch 4**: The fast-feedback vs. maintainability trade-off, applied twice in this chapter.
- **Domain-Driven Design**: the "don't modify more than one aggregate per business operation" guideline, which serves the same anti-inconsistency goal in document databases where one document = one aggregate.
