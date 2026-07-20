# Cheatsheet — Noback's decision rules

## Is this core or infrastructure code?

Both rules must pass, or it's infrastructure:

| See this | Verdict |
|---|---|
| `new PDO`, `curl_init`, `file_get_contents`, `Uuid::uuid4()`, `new DateTimeImmutable('now')` | Infrastructure (Rule 1) |
| Interface mentioning tables/rows/endpoints (`insert($table, $data)`) | Infrastructure (Rule 1) |
| `$_SERVER`, `Zend_Registry::get()`, `php_sapi_name()`, `ContainerInterface` | Infrastructure (Rule 2) |
| `RequestInterface` / `ResponseInterface` in the signature | Infrastructure (Rule 2) |
| Column names or ORM annotations inside an entity | **Core** — re-check the rules, don't guess |

**Not a valid test**: "can I mock it?" / "is it in `/vendor`?" / "does it have an interface?"

## Where does this input go?

| Input | Goes as |
|---|---|
| Service dependency (`Mailer`, `OrderRepository`, `EventDispatcher`) | Constructor argument |
| Configuration value (API key, sender address) | Constructor argument **+ an assertion** |
| Contextual info — the word "current" is the tell | Method argument |
| Job-specific data (`EbookId`, a command object) | Method argument |

## Where does this class go?

**Interfaces inward, implementations outward.** That one rule generates most of the table.

| Class | Layer |
|---|---|
| Entity, value object, domain event, domain service, write-model repo **interface** | Domain |
| Application service, command DTO, event subscriber, view-model repo **interface**, view model | Application |
| Controller, CLI command, any repo **implementation**, service container, clock/random services | Infrastructure |

Dependency rule: Infra → App → Domain. Never outward. Enforce with `deptrac`.

## Which test do I write?

| What you're proving | Test |
|---|---|
| An entity protects an invariant / records an event | Unit test |
| A value object's behavior | Unit test |
| A use case's effect ("paying produces an invoice") | Use case test |
| `save()` then `getById()` round-trips | Contract test (adapter) |
| `POST /x` calls `ApplicationInterface::y()` | Driving test (adapter) |
| The real API / real mailer actually works | Adapter test |
| Everything is wired together in production | End-to-end (only a few) |

**Never unit-test**: controllers, application services, event subscribers, repository implementations.
**Rule**: "A test is not a unit test if it invokes infrastructure code."

## Have I found the right abstraction?

**Ask**: "Would this interface still be useful if the implementation changed *radically*?"
**Don't ask**: "Can I create a test double for it?" — true of any interface, including bad ones.

| Tell | Diagnosis |
|---|---|
| Method name matches a vendor endpoint | Wrong level — extracted from the implementation |
| Return type is vendor-shaped (`VatRateCheckResult`) | Wrong level — should be `VatRate` |
| A parameter only one vendor understands (`$filter`) | Leaky — encode it in the method name instead |
| Call site reads in your domain's words | Right level |

## Validation: where does each check live?

| Check | Where |
|---|---|
| A value is well-formed | Value object constructor → throws |
| An entity is complete/consistent | Entity constructor + every mutator → throws |
| A related entity exists | Application service, via `getById()` |
| A rule needing outside state (stock) | Application service → `UserErrorMessage` |
| Friendly, translated, per-field errors | Controller, reusing the same value objects |
| The user *couldn't* have gotten it wrong (hidden field, `<select>`) | **Don't validate.** Rely on entity protection + `400 Bad Request` |

**Rule**: only validate with **pure** functions. Impure query (stock levels) → fuzzy comparison, deferred processing, or accept-and-recover.

**Should this exception reach the user?** Ask what could cause it. Only "a bug" or "an attacker" → no.

## Smells and what they mean

| You see | It means | Do |
|---|---|---|
| A getter on an entity | You loaded it just to read | Introduce a read model |
| Setters + an external validator | Entity is never safe to use | Make it self-validating |
| `save()` returns `int` | Auto-increment leaking | Add `nextIdentity()`, return `void` |
| Framework types in a service constructor | Infrastructure in core | Interface named after the *step* |
| Constructor sprouting dependencies when you move code in | Wrong home for that step | Abstract it, or move to an event subscriber |
| Service → abstraction → class → abstraction → class | "Jumpy" code, too many elements | Delete pass-throughs; let infra call infra |
| `ApplicationInterface` growing large | App is doing too much | Split into modules, or use a command bus |
| Entity-level exceptions in production logs | Abuse, **or** a UI that permits mistakes | Usually fix the UI |
| A test that mirrors production code | Hidden dependencies | Make them explicit |
| Two objects that must be used in a fixed order | Bad coupling | Merge the responsibility |

## Thresholds and defaults

- Unit test method: aim for **3 statements**; hide setup in named factories (`aPaidOrder()`).
- Application service: **one entity saved per call**. Everything else → domain events.
- Dispatch events **after** persisting, never before.
- Relations between entities: **by ID**, never by object reference. Passing a *read model* is fine.
- Incoming adapter tests: verify ~**80%** programmatically; a handful of end-to-end tests for the rest.
- Legacy work: improve **a little every day** — never hours or days in a row, never many changes at once.
- Abstractions cost **2–3 elements** each (interface, implementation, sometimes a return type). Worth it — worth counting.

## Should this project be decoupled?

| Signal | Answer |
|---|---|
| Small, purely infrastructural script | No |
| Genuinely generatable from a config file (true CRUD) | No |
| **Absolutely certain** it dies in 2 years | Probably not — but still write tests |
| Might outlive its purpose (every POC that succeeds) | **Yes** |
| Has actions, state transitions, or invariants | **Yes** |
| Legacy, actively worked in | Partially, in the parts you touch |
| Legacy, rarely touched | Leave it |

Automated testing is **never** optional; only the *type* is a choice.

## The escalation ladder for testing an external service

Real service → vendor sandbox → your fake server → library's mock client → mock of the HTTP interface.
Go as far up as stability allows. **"Don't mock an interface whose contract is bigger than the interface itself can describe."**

## Feature workflow (top-down)

Discuss → Gherkin → process modelling → test-driven core (test doubles as adapters) → **feature works with no controller, route, template or table** → wrap infrastructure → adapter tests → a few end-to-end runs of the same scenarios against a different `Context`.
