# Chapter 6: Retrieving Information

## Core Idea
A query method returns information and has **no side effects** — so it's safe to call any number of times, including zero. Keep return types single and specific, expose as little internal state as possible, and put an interface in front of any question the application can't answer from memory.

## Frameworks Introduced

- **Command/Query Separation (CQS)** (Fowler/Meyer): every method is *either* a command (side effect, `void`) *or* a query (returns information, no side effects) — never both.
  - When to use: default for every method.
  - The alternative route to the same guarantee: **make the object immutable**. Then `increment(): void` becomes `incremented(): Counter`, a modifier returning a copy — no state changes, nothing to separate.
  - **When to deviate**: concurrency. `EntityRepository.nextIdentity()` must return an ID *and* mark it used, or two clients get the same one. Noback's position is explicit — no programming rule should be inviolable; follow CQS almost always, break it when following it would badly complicate the code.

- **Query methods should have single-type return values**: No `string|bool`. And treat `null` as a burden shifted onto every caller.
  - Four alternatives to returning `null`, in rough order of preference:
    1. **Throw an exception** — when the client legitimately expects the thing to exist (`getById()` was given the ID).
    2. **Return a null object** — `EmptyPage` instead of `null`; the type is satisfied, so no client check is needed.
    3. **Return the empty case of the type** — `[]` for arrays, `0` for ints, `''` or `'N/A'` for strings.
    4. **Wrap the nullable method in a stricter one** — `getOneByType()` wraps `findOneByType()` and throws.
  - **Naming carries the uncertainty**: `get…` promises to return or throw; `find…` may come back empty-handed.

- **Avoid query methods that expose internal state**: Watch what clients *do* with a getter's return value; that work usually belongs inside the object.
  - Two moves: **make the method smarter** (adapt it to what clients actually need), or **move the call inside the object** (let it decide for itself).
  - Payoff: internals stay private, logic isn't duplicated across call sites, and it changes and gets tested in one place.

- **Two-step abstraction for system boundaries**: An abstraction requires *both* steps or it isn't one.
  1. **Use a service interface instead of a service class.**
  2. **Leave out the implementation details** — pick a name at the right level.
  - Test: `HttpClient` passes step 1 but fails step 2 — it still leaks that this is an HTTP call. `ExchangeRates` / `ExchangeRateProvider` passes both; a local database implementation would fit it too.
  - When to apply: any time you cross a system boundary — network, filesystem, system clock, database.

- **Not every question deserves its own service**: escalation ladder — (1) better variable names, (2) extract a private method, (3) a new class *only* if the method grows large, needs separate testing, or crosses a system boundary.

## Key Concepts
- **Query method**: Returns information, produces no side effects, has a specific (non-`void`) return type.
- **Getter**: The simplest query method — returns a property directly. Named without a `get` prefix: `discountPercentage()`, not `getDiscountPercentage()`.
- **Null object**: An object of the right type representing the empty case.
- **Stub**: A test double returning hardcoded values.
- **Fake**: A test double with somewhat complicated, working behavior — configurable, in-memory.
- **Integration test**: Tests an object against the outside thing it relies on; not a unit test.

## Mental Models
- **An object has boundaries.** Rather than letting clients reach across them for data, define explicitly which data and behaviors are available.
- **Query method names are nouns; command method names are verbs.** This resolves the ambiguity of words like `count` and `name` — the CQS context tells the reader which reading applies.
- **Every question deserves a method; every answer deserves a type.** Writing the question in code produced both `exchangeRateFor()` and the `ExchangeRate` class.
- **Never assert on calls to query methods.** They're side-effect free, so call count and order are implementation details. Asserting on them couples the test to the implementation. (Commands are the exact opposite — Ch 7.)

## Anti-patterns
- **Methods that both change and return** (`increment(): int`): the object changes even when the client only wanted to look at it.
- **JavaBean conventions**: zero-argument constructor + getter/setter per property. Noback states plainly that *every* rule in the book is incompatible with it — invalid starting states, invalid intermediate states, and internals so exposed you can't change them without breaking clients. DTOs are the only objects that may look like this.
- **Mixed return types** (`@return string|bool`).
- **`get`-prefixed getters**: `getItemCount()` reads as an instruction; `itemCount()` reads as an aspect of the object.
- **Clients calling a getter to decide which other method to call**: move the decision inside (`calculateNetAmount()`).
- **Abstracting only the transport** (`HttpClient`): swapping HTTP libraries becomes easy, swapping data *sources* does not.
- **Mocking frameworks for stubs and fakes**: they save boilerplate at the cost of readable, refactorable tests — method names as strings defeat rename tooling, and they encourage asserting on query calls. Use them for dummies only, if at all.
- **A query method calling a command method**: hides a side effect behind something that looks safe.

## Code Examples

The abstraction, done in two steps — and why one isn't enough:

```php
// Step 1 only — an interface, but the name still leaks the mechanism
interface HttpClient { public function get(url): Response; }
final class CurlHttpClient implements HttpClient { /* ... */ }
// You can now swap HTTP libraries. You cannot swap to a local rates table.

// Steps 1 + 2 — the interface names the QUESTION, not the transport
interface ExchangeRates
{
    public function exchangeRateFor(Currency from, Currency to): ExchangeRate;
}

final class FixerApi implements ExchangeRates
{
    private HttpClient httpClient;
    public function __construct(HttpClient httpClient) { this.httpClient = httpClient; }

    public function exchangeRateFor(Currency from, Currency to): ExchangeRate {
        response = this.httpClient.get(/* ... */);
        decoded  = json_decode(response.getBody());
        rate     = (float)decoded.data.rate;
        return ExchangeRate.from(from, to, rate);
    }
}

final class CurrencyConverter
{
    private ExchangeRates exchangeRates;
    public function __construct(ExchangeRates exchangeRates) {
        this.exchangeRates = exchangeRates;      // depends on the abstraction, not FixerApi
    }
}
```
- **What it demonstrates**: This is the Dependency Inversion Principle. Two payoffs: swap providers without touching `CurrencyConverter`, and unit-test it without a network.

Writing your own fake instead of reaching for a mocking framework:

```php
final class ExchangeRatesFake implements ExchangeRates
{
    private array rates = [];

    public function setExchangeRate(Currency from, Currency to, float rate): void {
        this.rates[from.asString()][to.asString()] = ExchangeRate.from(from, to, rate);
    }

    public function exchangeRateFor(Currency from, Currency to): ExchangeRate {
        if (!isset(this.rates[from.asString()][to.asString()])) {
            throw new RuntimeException('Could not determine exchange rate ...');
        }
        return this.rates[from.asString()][to.asString()];
    }
}

/** @test */
public function it_converts_an_amount_using_the_exchange_rate(): void
{
    exchangeRates = new ExchangeRatesFake();
    exchangeRates.setExchangeRate(new Currency('USD'), new Currency('EUR'), 0.8);

    currencyConverter = new CurrencyConverter(exchangeRates);
    converted = currencyConverter.convert(new Money(1000, new Currency('USD')));

    assertEquals(new Money(800, new Currency('EUR')), converted);
}
```
- **What it demonstrates**: The test now covers only `convert()`'s logic — no network, no JSON parsing, deterministic and fast. Note the **snake_case test method name**: test names describe behaviors, so they should read as sentences. Start with `it_`, `when_`, or `if_`.

## Reference Tables

| Test double | Behavior | Assert on calls? |
|---|---|---|
| Stub | Hardcoded return values | **No** |
| Fake | Working, configurable, in-memory | **No** |
| Dummy | Nothing meaningful; fills a parameter | No |
| Mock | Records calls | Yes — commands only (Ch 7) |

| Instead of returning `null`… | Use when |
|---|---|
| Throw an exception | Client supplied the identifier and expects existence |
| Null object (`EmptyPage`) | An "empty" instance is meaningful to clients |
| Empty value (`[]`, `0`, `''`) | The return type has a natural empty case |
| Wrapper method that throws | You can't change the existing nullable method |

## Worked Example

**Pulling logic back inside `Order` and `Line`** — the chapter's exercise, and the clearest demonstration of "don't expose internal state":

```php
// Before — Order exposes its lines; Line exposes quantity and tariff;
// the calculation lives at every call site.
final class Line {
    private int quantity;
    private Money tariff;
    public function quantity(): int { return this.quantity; }
    public function tariff(): Money { return this.tariff; }
}

final class Order {
    private array lines = [];
    public function lines(): array { return this.lines; }
}

totalAmount = new Money(0);
foreach (order.lines() as line) {
    totalAmount = totalAmount.add(new Money(line.quantity() * line.tariff()));
}

// After — each object answers the question it's actually being asked
final class Line {
    public function amount(): Money {
        return new Money(this.quantity * this.tariff);
    }
}

final class Order {
    public function totalAmount(): Money {
        totalAmount = new Money(0);
        foreach (this.lines as line) {
            totalAmount = totalAmount.add(line.amount());
        }
        return totalAmount;
    }
}

totalAmount = order.totalAmount();
```

Now `quantity()`, `tariff()`, and `lines()` can all be **deleted** — the `lines` array and the `Line` objects become fully private. That's the tell that the refactoring worked: the getters weren't just wrapped, they became unnecessary.

**And the CQS-violating controller**, split into command and query halves:

```php
// Problem: a controller must return an HTTP response, but registering a user is a command.
public function execute(Request request): Response
{
    userId = this.userRepository.nextIdentifier();      // get the ID up front
    this.registerUser.register(userId, request.get('username'));   // pure command, void
    newUser = this.userReadModelRepository.getById(userId);        // pure query
    return new Response(200, json_encode(newUser));
}
```

Determining the ID *before* the command lets `register()` stay a true `void` command method. The controller still technically violates CQS — Noback accepts this as unavoidable at the application edge.

## Key Takeaways
1. Query = returns information, no side effects, callable any number of times. Command = side effect, `void`. Never both.
2. Immutability gives you CQS for free — a modifier returning a copy has nothing to separate.
3. One return type, always. Reach for an exception, a null object, or an empty value before returning `null`.
4. `get…` promises; `find…` might come back empty. Encode the uncertainty in the name.
5. Watch what clients do with getters — that logic belongs inside the object. Success looks like being able to delete the getter.
6. Abstraction = interface **plus** implementation-free naming. `HttpClient` fails; `ExchangeRates` passes.
7. Write your own stubs and fakes; don't generate them with mocking tools.
8. Never assert on calls to query methods — count and order are implementation details.
9. Escalate deliberately: variable name → private method → new class. Only cross to a new class for size, testability, or a system boundary.

## Connects To
- **Ch 3 §3.8**: the `Money`/`ExchangeRate` design tension over exposing internals resurfaces here as a general rule
- **Ch 4 §4.12**: recorded events are the alternative to getters for entities; §6.3 is the alternative for everyone else
- **Ch 7**: the command half — abstractions for commands, and mocks (where asserting on calls *is* correct)
- **Ch 8**: read models exist precisely so query needs stop deforming the write model
- **Dependency Inversion Principle** (Martin): §6.5 is DIP applied to queries
