# Core and Infrastructure — Full Reference

Read this when placing a class in a layer, designing a port, wrapping an external
service, introducing read models, deciding where a validation rule lives, or
working out which test proves a given claim.

For class-level mechanics — command/query separation, value object construction,
constructor rules, exception types, pattern selection — use `oop-guideline`. This
file stops at the boundary and points there.

## Contents

1. [Is This Core or Infrastructure?](#1-is-this-core-or-infrastructure)
2. [Where Does This Class Go?](#2-where-does-this-class-go)
3. [Ports and Adapters](#3-ports-and-adapters)
4. [Finding the Right Abstraction](#4-finding-the-right-abstraction)
5. [External Services and the Anticorruption Layer](#5-external-services-and-the-anticorruption-layer)
6. [Aggregates and Repositories](#6-aggregates-and-repositories)
7. [Application Services](#7-application-services)
8. [Read Models, View Models, and CQRS](#8-read-models-view-models-and-cqrs)
9. [Where Does Each Validation Rule Live?](#9-where-does-each-validation-rule-live)
10. [Domain Events](#10-domain-events)
11. [The Composition Root](#11-the-composition-root)
12. [The Testing Strategy This Implies](#12-the-testing-strategy-this-implies)

---

## 1. Is This Core or Infrastructure?

Noback's two rules. **Both must pass, or it's infrastructure:**

1. **No dependency on an external system** — nor on code written for interacting
   with a specific *type* of external system.
2. **No special context required** — nor a dependency designed for one context
   only.

| You see | Verdict |
|---|---|
| `new PDO`, `curl_init`, `file_get_contents`, `Uuid::uuid4()`, `new Date()` | Infrastructure (Rule 1) |
| An interface mentioning tables, rows, or endpoints — `insert(table, data)` | Infrastructure (Rule 1) |
| `$_SERVER`, a registry, a container interface, `php_sapi_name()` | Infrastructure (Rule 2) |
| `Request` or `Response` types in the signature | Infrastructure (Rule 2) |
| Column names or ORM annotations inside an entity | **Core** — but re-check the rules, don't guess |

That last row is the one people get wrong. An entity carrying ORM annotations is
still core code — it just has a Rule 1 violation you should fix. Being annotated
doesn't relocate it to infrastructure; it means the mapping should move out.

**Invalid tests**, all of which sound reasonable and prove nothing: "can I mock
it?", "is it in `vendor/`?", "does it have an interface?".

**The CLI thought experiment** is the cheapest real test: *if the business ran from
the command line, would the application still need this?* No → it was justifiably
infrastructure. Yes → decouple it.

### Should this project be decoupled at all?

| Signal | Answer |
|---|---|
| Small, purely infrastructural script | No |
| Genuinely generatable from a config file (true CRUD) | No |
| **Absolutely certain** it dies in two years | Probably not — but still write tests |
| Might outlive its stated purpose (every POC that succeeds) | **Yes** |
| Has actions, state transitions, or invariants | **Yes** |
| Legacy, actively worked in | Partially — in the parts you touch |
| Legacy, rarely touched | Leave it |

Automated testing is never the optional part; only the *type* of test is a choice.
For legacy work, improve **a little every day** — never hours in a row, never many
changes at once.

---

## 2. Where Does This Class Go?

**Interfaces inward, implementations outward.** That single rule generates most of
the table.

| Class | Layer |
|---|---|
| Entity, value object, domain event, domain service, write-model repository **interface** | **Domain** |
| Application service, command object, event subscriber, read model, read-model repository **interface** | **Application** |
| Controller, CLI command, any repository **implementation**, the service container, clock and random services | **Infrastructure** |

Dependencies run **Infrastructure → Application → Domain**, never outward. Enforce
with a build-time tool (deptrac, ArchUnit, NetArchTest, PyTestArch, TSArch), not a
document.

Be honest about what this buys: **the Domain/Application split does not improve
testability.** Keep it for legibility. The Infrastructure boundary is the one that
carries the testability benefit.

### The judgment calls, from Evans

| Question | Answer |
|---|---|
| "Every credit has a matching debit" | **Domain** — never the application layer |
| Deciding *when* to send a notification | **Application** |
| Knowing *how* to send it | **Infrastructure** |
| Which account to debit for a transfer | **Domain service** — "funds transfer" is meaningful banking language |
| Exporting transactions to a spreadsheet | **Application service** — "file format" has no domain meaning |
| State reflecting the business situation | **Domain** |
| State reflecting a task's progress | **Application** |
| A technical service | It should **lack any business meaning at all** |

The general test for a domain service: could a domain expert recognise the name as
something their business does? "Funds transfer" yes; "transaction exporter" no.

### Martin's version of the same question

| Question | Layer |
|---|---|
| Would this rule be true even with no computer? | **Entities** (critical business rules) |
| Is it a rule that exists only because the app is automated? | **Use cases** |
| Does it convert data between use-case form and an external form? | **Interface adapters** |
| Is it something you didn't write, or a device? | **Frameworks & drivers** |

When you can't answer, ask **"how far is this from the I/O?"** Farther means higher
level, which means further inward.

---

## 3. Ports and Adapters

Size the inner hexagon **by use cases, not by clients**. Each port is a *category*
of channel; adapters absorb all the protocol variation within it.

**Name ports by completing "for …"** — *for saving orders*, *for notifying
customers*, *for looking up exchange rates*.

- **Driven (outgoing) adapters implement the port interface.** The repository
  implementation, the mailer, the HTTP client.
- **Driving (incoming) adapters use it.** Controllers, CLI commands, message
  consumers, all calling into an application interface or a command bus.

The incoming side tends to accumulate a method per use case. **Treat that growth as
design feedback** rather than as noise: when the application interface gets large,
the application is doing too much, and the response is to split into modules or
move to a command bus.

**One caution.** Hexagonal treats the database as a pluggable adapter, which
conflicts with the microservices position that the database is inside the bounded
context and inside the quantum. Both are defensible; what you cannot do is claim
both at once. Inside a service, hexagonal applies; between services, the database
is not pluggable — it's part of the thing.

---

## 4. Finding the Right Abstraction

**The two-step recipe**, and the second step is the one people skip:

1. Introduce an interface.
2. Make it communicate **purpose** rather than implementation detail.

`Connection.insert(table, data)` → `Repository.save(member)`. Skipping step 2 buys
indirection with no decoupling whatsoever.

**Ask:** *would this interface still be useful if the implementation changed
radically?*
**Don't ask:** *can I create a test double for it?* — true of every interface,
including bad ones.

| Tell | Diagnosis |
|---|---|
| A method name matching a vendor endpoint | Wrong level — extracted *from* the implementation |
| A vendor-shaped return type (`VatRateCheckResult`) | Wrong level — should be `VatRate` |
| A parameter only one vendor understands (`filter`) | Leaky — encode it in the method name instead |
| The call site reads in your domain's words | Right level |

**"Act as if it already exists"** is the discovery technique: write the call site as
though the collaborator existed, read off the implied interface, then name it after
whatever it turned out to be. This is how repositories, providers, and read models
get found rather than designed.

**Abstract early, generalise late.** Introducing the interface at the first
implementation is right. Writing three implementations before anyone asks is
generalising on a guess, and the interface will be shaped wrong.

**Count the cost honestly.** Each abstraction costs about two to three elements —
interface, implementation, sometimes a return type. That's usually worth it, and
it's always worth counting. Watch for the opposite failure: service → abstraction →
class → abstraction → class produces "jumpy" code. **Delete pass-throughs and let
infrastructure call infrastructure directly.**

---

## 5. External Services and the Anticorruption Layer

Use **two layers** for any external API:

1. A **façade** wrapping the vendor's API. Methods mirror the vendor's endpoints.
   The API key is a constructor argument. This layer speaks the vendor's language,
   and that's fine — it's infrastructure.
2. An **interface phrased in your domain's words**, whose implementation consumes
   the façade.

**Extracting an interface directly from the façade achieves nothing** — the
vendor's vocabulary survives into your domain, which was the entire thing you were
trying to prevent.

That upper interface is an anticorruption layer. In the DDD framing it has three
parts: the separated interface in your model, the adapter owning the protocol, and
the translator producing your local type. Use one **any time a foreign
representation would enter your model** — including when the upstream offers an
Open Host Service, because a good published language is still someone else's
language.

**Own your value objects.** Wrap third-party types (`DateTimeImmutable`, `Uuid`) in
your own. Use them internally for the heavy lifting; never expose them. Beyond API
control, this removes hidden I/O — `DateTimeImmutable` silently fills missing date
parts from the real system clock.

**The clock is the canonical hidden dependency.** `interface Clock {
currentTime(): DateTime }`, a system implementation, and a controllable fake for
tests. Note that Noback kept the `Clock` abstraction and *deleted* its siblings
(`UuidFactory`, `Calendar`) as pass-throughs. The rule isn't "wrap everything" —
it's "wrap what core code needs to be independent of".

---

## 6. Aggregates and Repositories

### Aggregates

**The aggregate is the consistency boundary.** Four rules of thumb:

1. Model true invariants inside the boundary.
2. Design **small** aggregates. Roughly 70% should be a single root plus value
   objects; the rest have two or three entities.
3. **Reference other aggregates by identity**, never by object reference.
4. Use **eventual consistency outside** the boundary.

**Modify exactly one aggregate per transaction.** When you can't, you have a wrong
boundary or a missing concept — not a reason to widen the transaction. The only
four sanctioned exceptions: UI convenience when batch-creating aggregates with no
shared invariant; a genuine lack of async mechanisms (safer under user-aggregate
affinity, and don't retreat to large clusters); an externally mandated global
transaction; and *measured* query performance.

**Verify the invariant is real.** Say it aloud in the ubiquitous language. If the
experts don't recognise it as a rule, it's a false invariant — usually
developer-authored, usually phrased as "we must not allow X to be removed". The
symptom is unrelated operations colliding on the same root's optimistic-concurrency
version.

The related Evans case is worth remembering: two users editing different parts of
one invariant means the boundary is wrong. Locking a line item let both saves
violate the purchase-order limit, and nobody found out.

**When the relationship is high-contention and the rule is soft, loosen it** —
copy the value in. Copying the price into a line item gives you correct history
*and* removes the contention; live coupling gave you neither.

### Repositories

**One repository per aggregate type**, and only for aggregate roots that need one.
Repositories for anything else muddy the distinctions that matter.

| Your persistence mechanism | Style | Interface |
|---|---|---|
| Implicit change tracking (Hibernate, JPA, TopLink) | Collection-oriented | `add` / `remove`, **no** `save` |
| Key-value store, data fabric, or a possible future swap | Persistence-oriented | `save` / `saveAll` |

**Transactions belong to an application-layer facade, never the domain layer.**

**Use `nextIdentity()` rather than auto-increment.** Get the ID, construct the
entity, save it. This gives events a valid identity at construction time, stops
unsaved entities comparing equal in a set, and lets `save()` return `void` — which
satisfies command/query separation. A `save()` that returns an `int` is
auto-increment leaking through the abstraction.

**Don't offer "find or create".** The distinction between new and existing almost
always matters in the domain.

**When use-case-optimal repository queries start piling up**, that's a smell: the
repository is masking aggregate mis-design. One or two are fine; a pattern of them
is feedback.

---

## 7. Application Services

An application service is **guard and delegate**. It takes a command object,
fetches the aggregate, calls one method on it, saves, and dispatches the resulting
events. Anything beyond that — real decision-making — is domain logic that has
leaked out of the model and belongs in the entity or a domain service.

**One entity saved per call.** Everything else becomes a domain event.

Extract one from a fat controller mechanically: Extract Variable → Extract Class →
Inline Variable → Introduce Parameter Object, in that order. Extract Variable first
is what makes Extract Class mechanical rather than a rewrite.

**Command objects** carry the input. Name them after the intention (`CreateOrder`).
Populate via a `fromRequestData()` factory that casts types and fills defaults and
**never throws**; give them accessors that return value objects. Yes, those
accessors can throw domain exceptions from inside the controller — in practice this
doesn't get in the way.

**Never unit-test an application service.** It invokes infrastructure by
definition. Use case tests cover it (§12).

When multiple disparate clients need the same use case, decouple the output: pass a
client-supplied data transformer, or make the method `void` and write to a named
output port with per-client adapters.

---

## 8. Read Models, View Models, and CQRS

**Never hand a modifiable entity to a client that only reads.** Even if it doesn't
modify it today, one day it will, and finding out what happened is hard.

- A **read model** is shaped by one use case, immutable, and often shares the
  entity's name in a different namespace. It returns **value objects**.
- A **view model** crosses the application boundary to users or external systems.
  Derive its getters from the consuming template, and return **primitives only**,
  with all formatting done inside. The inconsistency with read models is
  deliberate: different clients, different contracts.

**Three ways to build a read model**, in order of preference:

1. **Directly from the data source** — one query. The default: cheapest at runtime
   *and* in maintenance.
2. **From the write model** — a stopgap that doesn't actually achieve the goal,
   since you still loaded the entity.
3. **From domain events** — the expensive option, justified only when the write
   model changes often, raw data needs interpretation, or recomputation is genuinely
   too costly.

**Two signals tell you the split is done:** you can delete the write model's
getters without breaking a write-model client, and the reading client stops
transforming what it received. If the controller still loops and reshapes, the read
model isn't matched to the use case yet.

**When one module needs data owned by another module or an external system**, the
*consuming* module owns both the read model and its repository interface. That is
the dependency inversion principle applied to models, and it means you can replace
the entire upstream system by rewriting one repository implementation.

### CQRS

Adopt it **only after repository finders and DTOs have genuinely failed** a UI that
cuts across many aggregate types, or when read and write volumes diverge sharply,
or when reads need isolation for security. Then: a command model with command-only
aggregates and no getters, and a denormalised query model shaped per view,
synchronised via domain events.

It removes a real failure risk and adds accidental complexity when adopted
speculatively. **Event sourcing is a separate and much larger commitment** — CQRS
does not require it, and A+ES only pays off on complex, competitive-advantage
models. If you adopt event sourcing, plan for CQRS, because event streams are hard
to query.

---

## 9. Where Does Each Validation Rule Live?

| Check | Where |
|---|---|
| A value is well-formed | Value object constructor → throws |
| An entity is complete and consistent | Entity constructor and every mutator → throws |
| A related entity exists | Application service, via `getById()` |
| A rule needing outside state (stock levels) | Application service → a user-facing error message |
| Friendly, translated, per-field errors | Controller, **reusing the same value objects** |
| The user *couldn't* have gotten it wrong (hidden field, `<select>`) | **Don't validate.** Rely on entity protection and return 400 |

**Validate only with pure functions.** If a check depends on impure state — stock
levels, remote availability — exact comparison is a race by construction. Prefer a
fuzzy comparison, deferred processing, or accept-and-recover. Recovery often beats
prevention for user experience anyway.

**Should this exception reach the user?** Ask what could cause it. If the only
answers are "a bug" or "an attacker", no.

Entity-level exceptions appearing in production logs mean either abuse or a UI that
permits mistakes. Usually it's the UI, and usually the UI is what to fix.

**Where validation collects rather than throws:** a validator extracted as a
specification or strategy, taking a notification handler so all failures accumulate.
Vernon's reason for extracting it is worth keeping: validation changes at a
different pace than the entity, which is why it doesn't live inside it.

---

## 10. Domain Events

Experts saying **"when…", "if that happens…", or "notify me if…"** is the signal.

Name the event in **past tense**, after the causing command. Make it immutable. The
entity records events on state change; the application service saves, **then**
dispatches. **Dispatch after persisting, never before** — an event for a change
that didn't commit is worse than no event.

**Subscriber placement:** the class name says *what* (`CreateInvoice`), the method
name says *when* (`whenOrderFullyDelivered`). Put the subscriber in the module where
the **effect lands**, not where the cause originated. That's what keeps module
dependencies pointing downstream.

Application-level subscribers delegate to application services. Infrastructure-level
subscribers (logging, queueing) do their own work directly.

**For events that must reach remote bounded contexts**, store them in the model's
own persistence store — one local transaction, no distributed transaction — then
forward out-of-band, either as cacheable REST notification-log pages (fixed-size
current page, immutable archived pages) or through messaging middleware with a
published-message tracker. REST logs let HTTP caching absorb the polling and let
clients track their own position; middleware is lower latency but couples
availability.

Recorded events also let tests verify state changes without adding getters — see
`oop-guideline` for that technique.

---

## 11. The Composition Root

Every concrete dependency gets pushed down into one place: `Main`, the ultimate
detail. It is the only component that knows every concrete type, and it is
therefore the only one allowed to be a plugin-wiring mess.

**Fetching from the container inside a controller is fine** — that's the
composition root. Fetching from it inside the service that controller calls is
service location, and it hides the real dependency count. Making controllers
themselves services pushes the root one level further up, which is optional.

Everywhere else: constructor injection. Dependencies and configuration values go in
the constructor; contextual information and job-specific data go as method
arguments. See `oop-guideline` for the full rules.

---

## 12. The Testing Strategy This Implies

The architecture determines which test is even possible, so this table is a
consequence of the layering rather than a separate decision.

| What you're proving | Test |
|---|---|
| An entity protects an invariant, or records an event | Unit test |
| A value object's behavior | Unit test |
| A use case's effect ("paying produces an invoice") | Use case test |
| `save()` then `getById()` round-trips | Contract test |
| `POST /x` calls the right application method | Driving test |
| The real API or mailer actually works | Adapter test |
| Everything is wired together in production | End-to-end — only a few |

**Never unit-test** controllers, application services, event subscribers, or
repository implementations. **A test is not a unit test if it invokes
infrastructure code.**

- **Use case test** — a hand-written test container wiring real core services with
  in-memory repositories and spies. Prefer **spies to mocks**: they capture
  arguments and keep you out of framework-specific mocking APIs. It proves the
  mailer was *called*, never that email was *sent* — that's an adapter test's job.
- **Contract test** — data-provide the entities, generate every implementation of
  the port, loop and assert. Real database, **no test doubles**, interface methods
  only. Useless where the contract is merely "returns the right type".
- **Driving test** — mock the application interface, run through the real framework,
  assert the right call was made. Covers about 80% of the assumptions; a handful of
  end-to-end tests cover the rest.

**Testing external services — the escalation ladder**, best to worst: the real
service → the vendor's sandbox → your own fake server → the library's mock client →
a mock of the HTTP interface. Go as far up as stability allows, and remember:
**don't mock an interface whose contract is bigger than the interface itself can
describe.**

**If you can't write a fast test for a piece of business logic, that is
architectural feedback**, not a testing problem. The logic is on the wrong side of a
boundary.

Use `test-guideline` for test structure, naming, mocking rules, and what not to
test at all.

### The feature workflow this enables

Discuss → Gherkin scenarios → process modelling → test-driven core using test
doubles as adapters → **the feature works with no controller, route, template, or
database table** → wrap the infrastructure → adapter tests → a few end-to-end runs
of the same scenarios against a different context.

Reaching a working, tested feature before writing a controller is the observable
proof that the core is genuinely decoupled.
