# Patterns & Techniques

## The Two Rules for Core Code
**When to use**: every time you need to decide whether a class is core or infrastructure.
**How**: (1) No dependencies on external systems, *nor on code written for interacting with a specific type of external system*. (2) No special context needed, *nor dependencies designed for one context only*. Both must pass.
**Trade-offs**: no tool can automate this check — it stays a human judgement (Ch 12).

## The Two-Step Abstraction Recipe
**When to use**: whenever Rule 1 fails and you need to invert a dependency.
**How**: (1) Introduce an interface. (2) Communicate **purpose** instead of implementation details. `Connection::insert($table, $data)` → `Repository::save(Member $member)`.
**Trade-offs**: step 2 is the one people skip; skipping it buys indirection with no decoupling.

## "Act As If It Already Exists"
**When to use**: you know what you want to do but not which object should do it.
**How**: write the call site as though the collaborator existed (`$orderSaver->save($order);`), read off the implied interface, then name it after the pattern it turns out to be.
**Trade-offs**: none — it's how `OrderRepository`, `VatRateProvider`, and the `Order` read model were all discovered.

## Entity + Repository (Data Mapper)
**When to use**: any data that must be complete and correct before persisting.
**How**: constructor demands all required values, then asserts on each. Repository interface with `save(): void`, `getById()`, and `nextIdentity()`.
**Trade-offs**: extra elements (interface + implementation), and one open decision — mapping inside or outside the entity. Both beat Active Record's loss of test isolation.

## `nextIdentity()` — Identity Before Construction
**When to use**: always, in preference to auto-increment columns.
**How**: `$id = $repo->nextIdentity(); $order = new Order($id, ...); $repo->save($order);`
**Trade-offs**: naive `SELECT MAX(id)+1` races under concurrency — escalate to a sequence table in a transaction. Bonus: `save()` returning `void` satisfies Command Query Separation.

## Value Object for an Identifier
**When to use**: as soon as a raw ID type (`int`, `UuidInterface`) appears in a signature.
**How**: private constructor + named factory (`OrderId::fromUuid()`), plus `asString()` for serialization boundaries.
**Trade-offs**: things that only accept scalars (sessions) need the explicit conversion.

## Write Model / Read Model Separation
**When to use**: any time you call `getById()` with no intention of changing the result.
**How**: leave the entity alone; create an immutable read model (often same name, different namespace) exposing only what this client needs.
**Trade-offs**: three new elements per query (interface, answer class, implementation). Four documented ways to trim the count, each with its own cost.

## View Model
**When to use**: data crossing the application boundary to users or external systems.
**How**: derive getters from the consuming template; return **primitives only**, with all formatting done inside.
**Trade-offs**: differs deliberately from read models, which return value objects. The inconsistency is the point — different clients, different contracts.

## The CLI Thought Experiment
**When to use**: deciding whether functionality deserves to be core code.
**How**: "If the business ran from the command line, would the application still need this?" No → it was justifiably infrastructure. Yes → decouple it.
**Trade-offs**: none. Cheapest decision tool in the book.

## Application Service Extraction
**When to use**: any controller action doing real work.
**How**: Extract Variable → Extract Class → Inline Variable → Introduce Parameter Object, in that order.
**Trade-offs**: Extract Variable first is what makes Extract Class mechanical rather than a rewrite.

## Command Object
**When to use**: an application service's parameter list is growing, or request data needs shape.
**How**: name it after the intention (`CreateOrder`). Populate via `fromRequestData()` — cast types, fill defaults, **never throw**. Give it accessors returning value objects.
**Trade-offs**: accessors returning value objects can throw domain exceptions from the controller. "In practice I find that this doesn't get in the way."

## Constructor Injection over Service Location
**When to use**: always, except at the composition root.
**How**: dependencies + configuration → constructor. Contextual info + job-specific data → method arguments.
**Trade-offs**: more symbols. Buys compiler-assisted setup, framework-independent tests, and no hidden state.

## Composition Root
**When to use**: resolving "never use the container as a locator" vs. "something must build the first object."
**How**: fetching from the container inside a controller is fine — that's the composition root. Inside the service it calls, it isn't.
**Trade-offs**: controllers-as-services pushes it one level further up. Optional.

## Façade + Domain Abstraction (Two Layers for External Services)
**When to use**: any external API.
**How**: (1) a façade wrapping the vendor's API, methods mirroring endpoints, API key as a constructor argument. (2) an interface phrased in *your* domain's words, whose implementation consumes the façade.
**Trade-offs**: extracting an interface *from* the façade achieves nothing — the vendor's vocabulary survives. Test: "would this interface still be useful if the implementation changed radically?"

## Clock
**When to use**: everywhere `new DateTimeImmutable('now')` would appear.
**How**: `interface Clock { currentTime(): DateTimeImmutable; }` with a system implementation and a mutable `FakeClock` for tests.
**Trade-offs**: one abstraction, kept. Its siblings (`UuidFactory`, `Calendar`) were removed as pass-throughs — infrastructure code can call infrastructure directly.

## Own Your Value Objects
**When to use**: any class appearing in your domain model's arguments or return types.
**How**: wrap third-party types (`DateTimeImmutable`, `Uuid`) in your own. Use them *inside* for heavy lifting; never expose them.
**Trade-offs**: more classes. Buys API control and removes hidden IO — `DateTimeImmutable` silently fills missing date parts from the real clock.

## Self-Validating Entity (Protection)
**When to use**: always, instead of populate-then-validate.
**How**: every method that assigns validates first and throws. Push individual rules into value objects so a typed parameter proves validation happened.
**Trade-offs**: exceptions aren't user-friendly and mustn't reach users. Pair with controller-side validation reusing the same value objects.

## `UserErrorMessage`
**When to use**: a rule the entity can't check alone, where the user can actually act.
**How**: `interface UserErrorMessage extends Throwable { translationKey(): string; }`, a base class, custom exceptions with named constructors. Controller catches and maps to form errors.
**Trade-offs**: not for programming mistakes or tampering. Ask "what could cause this?" — if the answer is only "a bug" or "an attacker", don't surface it.

## Validate Only With Pure Functions
**When to use**: designing any validation step.
**How**: if the check depends on impure state (stock levels), prefer fuzzy comparison, deferred processing, or accept-and-recover.
**Trade-offs**: exact comparison against an impure query is a race by construction. Recovery often beats prevention for UX.

## Domain Events + Event Subscribers
**When to use**: any secondary effect of a primary change.
**How**: entity records events on state change; application service saves, **then** dispatches `releaseEvents()`. Subscribers handle the rest, delegating to application services.
**Trade-offs**: eventual consistency. Infrastructure-level subscribers (logging, queueing) do their own work instead of delegating.

## Upstream/Downstream Subscriber Placement
**When to use**: wiring a subscriber that spans modules.
**How**: class name says *what* (`CreateInvoice`); method says *when* (`whenOrderFullyDelivered`). Put it in the module where the effect lands.
**Trade-offs**: none — it's what keeps module dependencies pointing downstream.

## Read Model as Local Representation of a Remote Entity
**When to use**: one module needs data owned by another module or an external system.
**How**: the *consuming* module owns both the read model and its repository interface.
**Trade-offs**: "the Dependency Inversion Principle applied to models." Replace the entire upstream system by rewriting one repository implementation.

## Architectural Layers + Dependency Rule
**When to use**: deciding where a class goes.
**How**: Domain / Application / Infrastructure as namespaces. Interfaces inward, implementations outward. Enforce with `deptrac`.
**Trade-offs**: the Domain/Application split doesn't improve testability — keep it for legibility.

## Ports and Adapters
**When to use**: organizing every connection to the outside world.
**How**: name ports by completing "for …". Outgoing adapters **implement** the port interface; incoming adapters **use** it (`ApplicationInterface` or `CommandBus`).
**Trade-offs**: `ApplicationInterface` grows a method per use case — treat growth as design feedback, then split into modules or move to a command bus.

## Contract Test
**When to use**: an outgoing port with a specifiable contract (repositories).
**How**: data-provide entities, generate every implementation, loop and assert. Real database, **no test doubles**, interface methods only.
**Trade-offs**: useless where the contract is just "returns the right type" — test the specific implementation instead.

## Driving Test
**When to use**: verifying an incoming adapter.
**How**: mock `ApplicationInterface`, run through the real framework (`WebTestCase`), assert the right call was made.
**Trade-offs**: doesn't hit a real web server, so ~80% of assumptions. Cover the rest with a few end-to-end tests.

## Use Case Test + Hand-Written Test Container
**When to use**: proving the hexagon works.
**How**: a `TestServiceContainer` wiring real core services with in-memory repositories and spies. Prefer **spies** to mocks — they capture arguments and keep you off PHPUnit.
**Trade-offs**: proves the `Mailer` is *called*, never that email is *sent*. That's an adapter test's job.

## Top-Down Development Workflow
**When to use**: starting any feature.
**How**: discuss → Gherkin scenarios → process modelling → test-driven core → wrap infrastructure → a few end-to-end tests reusing the same scenarios against a different `Context`.
**Trade-offs**: you get a working, tested feature before writing a controller, route, template, or migration.
