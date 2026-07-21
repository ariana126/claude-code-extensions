---
name: implementing-ddd-book
description: "Knowledge base from \"Implementing Domain-Driven Design\" by Vaughn Vernon. Use when applying Vernon's frameworks for bounded contexts, context maps, aggregates, domain events, entities, value objects, repositories, hexagonal architecture, CQRS, and event sourcing, studying the book, or referencing its concepts."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, or chapter number] -->

# Implementing Domain-Driven Design
**Author**: Vaughn Vernon | **Pages**: ~371 | **Chapters**: 14 + Appendix A | **Generated**: 2026-07-21

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `aggregates`, `context maps`, `eventual consistency`, or any indexed topic; I find and read the relevant chapter
- **With a chapter** — ask for `ch10`; I load that specific chapter
- **Browse** — ask "what chapters do you have?" to see the full index

When you ask about a topic not covered in Core Frameworks below, I will read the
relevant chapter file before answering.

---

## Core Frameworks & Mental Models

### The spine of the book
Strategically, model **a clean Ubiquitous Language inside an explicitly Bounded Context**. Everything else serves that. Tactically, model *inside* a Bounded Context with Aggregates, Entities, Value Objects, Services, Events, and Modules. Keep models architecturally neutral — architectural influences come and go; the domain model endures.

### Strategic design
- **Ubiquitous Language** — the team's rigorous shared language, valid within exactly one Bounded Context. Encode it directly as class, method, and Event names. If a concept has no linguistic association to the Context, move it out; modularization can't fix linguistic misalignment.
- **Bounded Context** — size it by the domain experts' Language, not by architecture or task distribution. Two teams in one Context produce a divergent Language: split the Context or merge the teams.
- **Problem space vs solution space** — Subdomains (Core / Supporting / Generic) describe the problem; Bounded Contexts implement the solution. Apply the tactical patterns and your best developers to the **Core Domain**; buy or outsource Generic Subdomains.
- **Context Mapping** — draw the terrain that actually exists *before* integrating: Partnership, Shared Kernel, Customer-Supplier, Conformist, Anticorruption Layer, Open Host Service, Published Language, Separate Ways, Big Ball of Mud. Assuming Customer-Supplier where reality is Conformist kills projects late.
- **Anticorruption Layer** — put one downstream even when the upstream offers OHS/PL. Structure: Separated Interface (in the model) → Adapter (HTTP/messaging/JSON) → Translator (local domain type). Local concepts stay local.

### Aggregates — the four rules of thumb (Ch 10, the book's center of gravity)
1. **Model True Invariants in Consistency Boundaries** — an Aggregate *is* a transactional consistency boundary. Say the candidate rule aloud in the Language; if experts don't recognize it, it's a **false invariant**.
2. **Design Small Aggregates** — Root Entity plus Value-typed properties; "the correct minimum is however many are necessary, and no more." If a part can be *completely replaced* rather than must change, it's a Value Object.
3. **Reference Other Aggregates by Identity** — hold `ProductId`, not `Product`. Resolve collaborators in the Application Service and pass them in; or double-dispatch a Domain Service into the command method. This enables almost-infinite scalability through repartitioning.
4. **Use Eventual Consistency Outside the Boundary** — modify **exactly one Aggregate instance per transaction**. Anything spanning Aggregates gets a Domain Event plus async subscribers, with a delay negotiated explicitly with domain experts.

**Ask Whose Job It Is** — when transactional vs eventual is unclear, ask whether it's *this* user's job to make the data consistent. Yes → transactional. Another user's or the system's job → eventual. Never decide by house style.

Break these rules only for: UI batch convenience, lack of async mechanisms, mandated global transactions, or *measured* query performance.

### Tactical building blocks
- **Entity** — uniquely identified and mutable. Generate identity **early** (`repository.nextIdentity()`) when Events publish at construction or Entities enter a `Set`. Hide ORM surrogate identity behind a Layer Supertype. Extract validation to a Validator (Specification/Strategy) that collects all failures rather than throwing on the first.
- **Value Object** — prefer it. Checklist: Measures/Quantifies/Describes, Immutable, Conceptual Whole, Replaceability, Value Equality, Side-Effect-Free Behavior. Replace, never mutate. Keep it a Value in the model even when the ORM forces its own table — the data model serves the domain model, never the reverse.
- **Domain Service** — for a significant business process, a transformation, or a calculation spanning Aggregates. The urge to write a *static method on an Aggregate Root* is the smell that calls for one. Overuse yields an Anemic Domain Model.
- **Domain Event** — model one whenever experts say "When…", "If that happens…", or "Notify me if…". Past-tense, named after the causing command, immutable. Store Events in the model's own persistence store so model and Event commit in one local transaction (no XA), then forward out-of-band.
- **Module** — name it from the Ubiquitous Language, not mechanically. When terminology is fuzzy and a boundary unclear, separate with a Module, not a Bounded Context — the thinner boundary is reversible.
- **Factory** — use a Factory Method on the Root when experts phrase creation as that Aggregate's behavior; declare the target constructor `protected`. Let the Root supply state clients must not provide (TenantId, parent identity).
- **Repository** — one per Aggregate type. Collection-oriented (`add`/`remove`, no `save`) for change-tracking ORMs; persistence-oriented (`save`) for key-value stores. Transactions live in an Application Layer Facade, never the Domain Layer.

### Architecture & application
- **Hexagonal (Ports and Adapters)** is the default host for a Bounded Context; size the inner hexagon by *use cases*, not clients. It supports SOA, REST, and Event-Driven on top.
- **Dependency Inversion** — Repository interfaces in the domain model, implementations in Infrastructure.
- **CQRS** only after Repository finders and DTOs have genuinely failed a cross-Aggregate UI. Adopted speculatively it's accidental complexity.
- **Application Service** — thin: guard, delegate, own the transaction. Anything more belongs in a Domain Service. Remote presentation → DTO + Assembler; single VM → Domain Payload Object (DTOs there are YAGNI).

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-getting-started-with-ddd.md) | Getting Started with DDD | DDD Scorecard, Ubiquitous Language, Anemic Domain Model check |
| [ch02](chapters/ch02-domains-subdomains-bounded-contexts.md) | Domains, Subdomains, and Bounded Contexts | Problem/Solution Space, Subdomain Classification, Segregated Core |
| [ch03](chapters/ch03-context-maps.md) | Context Maps | The nine Context Mapping relationships, Translation Map |
| [ch04](chapters/ch04-architecture.md) | Architecture | Layers, DIP, Hexagonal, SOA, REST, CQRS, EDA, Event Sourcing |
| [ch05](chapters/ch05-entities.md) | Entities | Identity creation strategies, Surrogate Identity, Validator, Deferred Validation |
| [ch06](chapters/ch06-value-objects.md) | Value Objects | Value Characteristics checklist, Standard Types, five ORM strategies |
| [ch07](chapters/ch07-services.md) | Services | Domain Service, Separated Interface, Transformation Services |
| [ch08](chapters/ch08-domain-events.md) | Domain Events | DomainEventPublisher, Event Store, NotificationLog, Idempotent Receiver |
| [ch09](chapters/ch09-modules.md) | Modules | Module naming conventions, Module before Bounded Context |
| [ch10](chapters/ch10-aggregates.md) | Aggregates | The four Rules of Thumb, Ask Whose Job It Is, Reasons to Break the Rules |
| [ch11](chapters/ch11-factories.md) | Factories | Factory Method on Aggregate Root, Factory on Service |
| [ch12](chapters/ch12-repositories.md) | Repositories | Collection- vs Persistence-Oriented, nextIdentity(), Repository vs DAO |
| [ch13](chapters/ch13-integrating-bounded-contexts.md) | Integrating Bounded Contexts | Anticorruption Layer, OHS via REST, Long-Running Processes |
| [ch14](chapters/ch14-application.md) | Application | DTO vs DPO, Command Handlers, Output Ports, Application Services |
| [ch15](chapters/ch15-appendix-a-aggregates-event-sourcing.md) | Appendix A: Aggregates and Event Sourcing (A+ES) | Event Store implementation, Read Model Projections, Given-When-Expect |

## Topic Index

- **Aggregate design** → ch10, ch11, ch12
- **Anemic Domain Model** → ch01, ch07
- **Anticorruption Layer** → ch03, ch13
- **Application Services** → ch04, ch07, ch14
- **Architecture styles** → ch04
- **Bounded Context** → ch02, ch03, ch09
- **Command Handlers / Commands** → ch14, ch15
- **Consistency (transactional vs eventual)** → ch10, ch13
- **Context Mapping** → ch03, ch13
- **Core Domain** → ch01, ch02
- **CQRS** → ch04, ch15
- **Dependency Inversion** → ch04, ch14
- **Domain Events** → ch08, ch10, ch13
- **Domain Services** → ch07, ch10, ch11
- **Entities** → ch05, ch10
- **Event Sourcing** → ch04, ch08, ch15
- **Event Store** → ch08, ch15
- **Eventual consistency** → ch10, ch13
- **Factories** → ch11, ch05
- **Hexagonal Architecture** → ch04
- **Identity (unique, surrogate)** → ch05, ch12
- **Idempotency** → ch08, ch13
- **Integration / messaging** → ch08, ch13
- **Invariants** → ch10
- **Long-Running Processes (Sagas)** → ch04, ch13
- **Modules** → ch09
- **NotificationLog / REST notifications** → ch08, ch13
- **Optimistic concurrency** → ch10, ch15
- **Open Host Service / Published Language** → ch03, ch13
- **Problem space vs solution space** → ch02
- **Read Model Projections** → ch15
- **Repositories** → ch12, ch10
- **REST** → ch04, ch13
- **Subdomains** → ch02
- **Testing** → ch05, ch06, ch12, ch15
- **Ubiquitous Language** → ch01, ch02, ch09
- **User Interface / rendering** → ch14
- **Validation** → ch05
- **Value Objects** → ch06, ch10

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions and chapter references
- [patterns.md](patterns.md) — every technique and design pattern, with when/how/trade-offs
- [cheatsheet.md](cheatsheet.md) — decision rules, thresholds, and tells & smells

---

## Scope & Limits

Covers the book's content only. Vernon's examples are Java (with some C#) against the
SaaSOvation sample domains — Collaboration, Identity and Access, and Agile Project
Management. Several of the book's tables are images in the source EPUB, so the DDD
Scorecard's individual row weights are not reproduced; the chapters capture its
mechanism and the ≥ 7 threshold stated in prose. For hands-on implementation in your
codebase, combine with project-specific tools; for Evans' original pattern language,
consult *Domain-Driven Design* directly.
