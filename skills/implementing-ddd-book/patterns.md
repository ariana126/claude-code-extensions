# Patterns & Techniques — Implementing Domain-Driven Design

## Ubiquitous Language Capture (Ch 1)
**When to use**: From the first modeling session in any Bounded Context.
**How**: Draw physical/concept diagrams with experts; write a glossary of terms *and* the scenarios that use them; speak the Language aloud; encode it directly as class, method, and Event names. Reject any term with no linguistic association to the Context.
**Trade-offs**: Requires sustained expert access. Without it, tactical patterns degrade into DDD-Lite.

## DDD Scorecard (Ch 1)
**When to use**: Deciding whether a project deserves the DDD investment.
**How**: Score the project against the weighted criteria; a total of **7 or higher** means seriously consider DDD.
**Trade-offs**: Decide early — complexity commitments become unchangeable a few use cases in.

## Subdomain Classification (Ch 2)
**When to use**: Mapping the problem space before choosing solutions.
**How**: Classify each Subdomain as Core Domain (must excel — build it, staff it best), Supporting (essential and specialized — build or contract), or Generic (required but unremarkable — buy or outsource).
**Trade-offs**: Misclassifying Generic as Core is the most expensive mistake available.

## Context Mapping Relationships (Ch 3)
**When to use**: Before integrating, to record the terrain that actually exists.
**How**: Draw each Bounded Context and label the relationship and direction (U/D):
- **Partnership** — succeed or fail together; coordinated planning
- **Shared Kernel** — jointly owned model subset; changes need agreement
- **Customer-Supplier** — upstream genuinely plans around downstream
- **Conformist** — downstream adopts the upstream model with no translation
- **Anticorruption Layer** — downstream translates defensively
- **Open Host Service** — upstream publishes a protocol for many integrators
- **Published Language** — a documented shared exchange language
- **Separate Ways** — no integration; duplicate instead
- **Big Ball of Mud** — mixed models, boundaries unenforced

**Trade-offs**: Assuming Customer-Supplier where the reality is Conformist kills projects late.

## Anticorruption Layer (Ch 3, Ch 13)
**When to use**: Any time a foreign Context's representation enters your model — even when the upstream offers OHS/PL.
**How**: Separated Interface in the domain model → Adapter (owns HTTP/messaging/JSON) → Translator (produces a local domain type). The model never sees foreign vocabulary.
**Trade-offs**: More classes; pays for itself the first time the upstream changes.

## Hexagonal Architecture / Ports and Adapters (Ch 4)
**When to use**: When new client types and output mechanisms keep arriving.
**How**: Size the inner hexagon by use cases, not by clients. Each Port is a channel category; Adapters absorb all protocol variation.
**Trade-offs**: Supports SOA, REST, and Event-Driven on top; keeps the model architecturally neutral.

## CQRS (Ch 4)
**When to use**: Only after Repository finders and DTOs have genuinely failed a UI that cuts across many Aggregate types.
**How**: Split into a command model (command-only Aggregates, no getters) and a denormalized query model shaped per view; sync via Domain Events.
**Trade-offs**: Removes a real failure risk but adds accidental complexity if adopted speculatively.

## Unique Identity Creation Strategies (Ch 5)
**When to use**: Designing every Aggregate Root.
**How**: Choose user-provided, application-generated (`repository.nextIdentity()`), persistence-store-generated, or another-Bounded-Context-assigned. Prefer **early** generation when Events publish at construction or Entities enter a `Set`.
**Trade-offs**: Late generation leaves Events without valid identity and makes unsaved Entities compare equal.

## Validator as Specification/Strategy (Ch 5)
**When to use**: When validation logic would otherwise sit inside an Entity.
**How**: Extract a Validator into the same Module; pass a `ValidationNotificationHandler` so all failures are collected rather than throwing on the first.
**Trade-offs**: Validation changes at a different pace than the Entity — separating them is the point.

## Value Object Design (Ch 6)
**When to use**: Whenever a concept measures, quantifies, or describes rather than *is* a thing.
**How**: Apply the checklist — Measures/Quantifies/Describes, Immutable, Conceptual Whole, Replaceability, Value Equality, Side-Effect-Free Behavior. Replace, never mutate. Route constructors through private guarded setters (self-delegation).
**Trade-offs**: Cheaper to develop, test, and maintain; keep the model a Value even when the ORM forces its own table.

## Domain Service (Ch 7)
**When to use**: A significant business process, a transformation, or a calculation drawing on more than one Aggregate.
**How**: Model a stateless Service named in the Ubiquitous Language. Skip Separated Interface when there is exactly one domain-specific implementation.
**Trade-offs**: The urge to write a static method on an Aggregate Root is the smell that calls for this. Overuse produces an Anemic Domain Model.

## Domain Events + Publish-Subscribe (Ch 8)
**When to use**: Experts say "When…", "If that happens…", or "Notify me if…".
**How**: Name the Event in past tense after the causing command; make it immutable; publish via a lightweight thread-bound `DomainEventPublisher`; subscribers filter on `subscribedToEventType()`.
**Trade-offs**: Eliminates catch-up batch queries; requires discipline about Event immutability.

## Event Store + Notification Log Forwarding (Ch 8)
**When to use**: Events must reach remote Bounded Contexts.
**How**: Store Events in the model's *own* persistence store (one local transaction, no XA), then forward out-of-band — either as cacheable RESTful `NotificationLog` pages (fixed-size current + immutable archived) or through messaging middleware with a `PublishedMessageTracker`.
**Trade-offs**: REST logs let HTTP caching absorb polling and let clients track their own position; middleware is lower latency but couples availability.

## Aggregate Rules of Thumb (Ch 10)
**When to use**: Every Aggregate design decision.
**How**: (1) Model true invariants in consistency boundaries; (2) design small Aggregates; (3) reference other Aggregates by identity; (4) use eventual consistency outside the boundary. Break them only for UI batch convenience, missing async mechanisms, mandated global transactions, or measured query performance.
**Trade-offs**: One Aggregate instance per transaction; violations signal a wrong boundary or a missing concept.

## Factory Method on Aggregate Root (Ch 11)
**When to use**: Experts phrase creation as a behavior of an existing Aggregate.
**How**: Put a Language-named creation method on the Root; declare the target constructor `protected`; have the Root supply state the client must not provide (TenantId, parent identity).
**Trade-offs**: A constructor name cannot carry the Ubiquitous Language. For cross-Context creation, use a Domain Service as the Factory instead.

## Repository Style Selection (Ch 12)
**When to use**: Designing persistence for each Aggregate type (one Repository per Aggregate).
**How**: Change-tracking mechanisms (Hibernate, TopLink, JPA) → collection-oriented (`add`/`remove`, no `save`). Key-value stores, Data Fabrics, or a possible future swap → persistence-oriented (`save`/`saveAll`).
**Trade-offs**: Manage transactions in an Application Layer Facade; the Domain Layer must never know about them.

## Long-Running Process with Time-Out Tracking (Ch 13)
**When to use**: A cross-Context workflow that must complete or be compensated.
**How**: Give every Event a unique Process identity; keep a `TimeConstrainedProcessTracker` with bounded retries and `isCompleted()`; emit `ProcessTimedOut` and compensate on full time-out. Make the receiving operation find-then-create first.
**Trade-offs**: Retries against non-idempotent receivers only produce misleading errors.

## Application Service Output Decoupling (Ch 14)
**When to use**: Multiple disparate clients need the same use case.
**How**: Pass a client-supplied `Data Transformer`, or make the method `void` and write to a named output Port with per-client adapters.
**Trade-offs**: Decouples the Application Layer from every client data type at the cost of indirection.

## A+ES Concurrency Resolution (App A)
**When to use**: Event-sourced Aggregates under contention.
**How**: If re-executing the behavior is cheap, reload the Stream and re-run the lambda-captured delegate. If re-execution is expensive (payments, order placement), use per-Root Event conflict resolution — same-type Events conflict, different-type Events do not.
**Trade-offs**: Plan for CQRS; Event Streams are hard to query. Only pays off on complex, competitive-advantage models.
