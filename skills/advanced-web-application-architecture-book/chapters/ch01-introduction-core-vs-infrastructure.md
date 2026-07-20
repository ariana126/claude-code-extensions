# Chapter 1: Introduction (Core vs. Infrastructure)

## Core Idea
Every class in your application is either **core code** or **infrastructure code**, and the two must never live in the same class. Core code runs anywhere with nothing but memory; infrastructure code connects that core to databases, HTTP, the clock, and the file system.

## Frameworks Introduced

- **The Two Rules for Core Code** — the book's foundational test. Code is *core* only if it passes **both** rules. Anything failing either rule is infrastructure code.
  - When to use: every time you open a class and need to decide where it belongs, or whether a refactoring has actually separated concerns.
  - How: apply Rule 1, then Rule 2. Both must pass.

- **Rule no. 1: No dependencies on external systems** — "Core code doesn't directly depend on external systems, nor does it depend on code written for interacting with a specific type of external system."
  - When to use: checking whether a class can be instantiated and exercised in isolation.
  - How: ask "can I run this method with nothing but PHP and memory?" If it needs a database, an internet connection, a responsive API, or a file at a specific path — infrastructure.
  - Note the second clause is the subtle one: depending on an *interface* isn't enough. A `Connection` interface with `insert(string $table, array $data)` is still infrastructure, because the signature only makes sense for relational databases.

- **Rule no. 2: No special context needed** — "Core code doesn't need a specific environment to run in, nor does it have dependencies that are designed to run in a specific context only."
  - When to use: catching code that is technically instantiable anywhere but was clearly built for one runtime.
  - How: look for global state (`$_SERVER`), static service locators (`Zend_Registry::get()`), context probes (`php_sapi_name() !== 'cli'`), and framework types in signatures (`RequestInterface`, `ResponseInterface`).

- **The Two-Step Abstraction Recipe** — how to actually remove an external-system dependency.
  - When to use: whenever Rule 1 fails and you need to invert the dependency.
  - How:
    1. **Introduce an interface.**
    2. **Communicate *purpose* instead of implementation details.**
  - Step 2 is where most attempts fail. `Connection::insert($table, $data)` → `Repository::save(Member $member)`. Same indirection, but the second one names *why* you're calling it, not *how* it's stored.
  - Why it works: an interface that leaks storage vocabulary re-couples the core to the storage mechanism even though a compiler-visible dependency is gone. Purpose-shaped interfaces survive a switch from SQL to a document store; implementation-shaped ones don't.

## Key Concepts
- **Core code** — code executable in any context, with no special setup and no external systems available.
- **Infrastructure code** — code that needs external systems, special setup, or was designed for one specific runtime context.
- **External system** — anything living outside your application: database, remote web service, system clock, file system, randomness source.
- **Abstraction** — an interface plus purpose-oriented naming; the go-to solution for removing external-system dependencies.
- **Special context** — an assumed environment (an HTTP request in flight, a pre-configured registry, a CLI invocation) that must exist before code can run.
- **Domain-first development** — designing from the business model outward, which separating core from infrastructure makes technically possible.

## Mental Models
- **Think of core as the center and infrastructure as the shell around it.** The shell does two jobs at once: it *protects* the core from external change and it *connects* the core to external systems and users.
- **Use testability as the proxy signal.** If a test needs a database, fixtures, an internet connection, or a bootstrapped framework, you're testing infrastructure code — regardless of what the class is named.
- **Directory location proves nothing.** Most of `/vendor` is infrastructure (frameworks, ORMs), but some of it is genuinely core. The rules are about what code *does* and what it *needs*, never about where it sits.
- **Both kinds of code are equally important.** The goal isn't to minimize infrastructure code — it's to stop it from sharing a class with core code.

## Anti-patterns
- **Interface-shaped infrastructure**: introducing an interface but keeping storage vocabulary in the method signature (`insert()`, `query()`, `getRow()`). You get the indirection cost without the decoupling benefit.
- **Global state reads**: `$_SERVER['HTTP_HOST']` inside domain logic silently binds the class to a live HTTP request.
- **Static service locators**: `Zend_Registry::get('Zend_Translator')` makes the dependency invisible and requires the registry to be configured before the method runs (see Ch 5).
- **Context probes**: `if (php_sapi_name() !== 'cli') { return; }` — the method now behaves differently depending on how the process was started.
- **Framework types in core signatures**: accepting a `RequestInterface` and returning a `ResponseInterface` designs the class for web-only use, even though it's technically instantiable anywhere.

## Code Examples

Infrastructure code — fails Rule 1 (needs an actual database):

```php
public function useTheDatabase(): void
{
    $pdo = new PDO('...');
    $statement = $pdo->prepare('INSERT INTO orders ...');
    $statement->execute();
}
```

Still infrastructure — the interface leaks relational-database vocabulary:

```php
interface Connection
{
    public function insert(string $table, array $data): void;
}

final class UserRegistration
{
    private Connection $connection;

    public function registerUser(string $username, string $plainTextPassword): void
    {
        $this->connection->insert('users', [
            'username' => $username,
            'password' => $plainTextPassword
        ]);
    }
}
```

Core code — the interface communicates purpose, not storage:

```php
interface MemberRepository
{
    public function save(Member $member): void;
}

final class MemberService
{
    private MemberRepository $memberRepository;

    public function requestAccess(string $emailAddress, string $purchaseId): void
    {
        $member = Member::requestAccess(
            EmailAddress::fromString($emailAddress),
            PurchaseId::fromString($purchaseId)
        );

        $this->memberRepository->save($member);
    }
}
```

- **What it demonstrates**: the only structural difference between the second and third listings is the *vocabulary* of the interface. That alone moves the class from infrastructure to core.

## Reference Tables

| Signal in the code | Rule violated | Verdict |
|---|---|---|
| `new PDO(...)`, `curl_init(...)`, `file_get_contents(...)` | Rule 1 (direct) | Infrastructure |
| `Connection::insert($table, $data)` | Rule 1 (specific-system interface) | Infrastructure |
| `$_SERVER['HTTP_HOST']` | Rule 2 (global state) | Infrastructure |
| `Zend_Registry::get(...)` | Rule 2 (static locator) | Infrastructure |
| `php_sapi_name() !== 'cli'` | Rule 2 (context probe) | Infrastructure |
| `RequestInterface` / `ResponseInterface` in signature | Rule 2 (designed for web) | Infrastructure |
| `MemberRepository::save(Member $member)` | none | Core |
| `EmailAddress::fromString(...)` with self-validation | none | Core |

## Worked Example

**The `ConnectionDummy` trap.** The book walks through a tempting but incomplete refactoring, and it's the most instructive moment in the chapter.

Start with `UserRegistration` depending on a `Connection` interface. To prove it's decoupled, write a fake:

```php
final class ConnectionDummy implements Connection
{
    private array $records;

    public function insert(string $table, array $data): void
    {
        $this->records[$table][] = $data;
    }
}
```

This *works*. `registerUser()` now runs with no database. The test is fast and isolated. By the usual "did I remove the hard dependency?" standard, the refactoring succeeded.

Noback rejects it anyway. The `Connection` interface "is specifically designed to communicate with relational databases, as the `insert()` method signature itself reveals." The class still knows it lives in a world of tables and rows. Swap the storage for a document database or an event store and `UserRegistration` has to change.

The fix isn't more indirection — it's better naming. Replace `Connection` + `insert()` with `Repository` + `save()`. Now the core says *"persist this member"* and stays silent on how. That refactoring is worked out in full in Ch 2.

**The takeaway to carry forward**: "can I test it without a database?" is a necessary check, not a sufficient one. The sufficient check is "does this interface mention anything only one kind of external system would care about?"

## Key Takeaways
1. Apply **both** rules, always. Passing Rule 1 while failing Rule 2 (or vice versa) still means infrastructure code.
2. An interface alone does not create core code. The interface must communicate **purpose**, not implementation details — that's step 2 of the abstraction recipe, and it's the step people skip.
3. Isolation is the payoff: core code needs no database, no fixtures, no internet, no bootstrapping — just memory. That makes test-first development practical.
4. Separating core from infrastructure also **protects the core from external change** — major framework upgrades, database vendor switches, moving from web to CLI.
5. Judge code by what it *does* and what it *needs*, never by where it lives. `/vendor` is mostly infrastructure but not by definition.
6. The rules are not arbitrary: they align exactly with the Domain and Application layers defined later. All domain code and all use cases must be core code.
7. Each chapter in Part I follows the same shape — show mixed legacy code, name the problem, refactor it apart. Six iterations cover every technique you need.

## Connects To
- **Ch 2**: works the `Connection` → `Repository` refactoring out in full, decoupling the domain model from the database.
- **Ch 5**: attacks the Rule 2 violations — service locators and global state.
- **Ch 6**: applies the two-step abstraction recipe to remote services.
- **Ch 7**: applies it to the clock and randomness, the external systems people forget are external.
- **Ch 9**: the full argument for *why* this separation is worth it (deferred deliberately from this chapter).
- **Ch 12**: architectural layers — the Domain and Application layers are formalized versions of "core code".
- **Hexagonal Architecture / Ports and Adapters** (Ch 13): the same core/shell picture, given a standard vocabulary.
- **Dependency Inversion Principle**: the mechanism behind the abstraction recipe.
