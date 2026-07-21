# Chapter 9: Modules

## Core Idea
Modules are named containers for highly cohesive domain objects, and their names are first-class terms of the Ubiquitous Language — not mechanical storage compartments. This is a short chapter; its weight is in naming conventions and in the rule to reach for a Module before creating a new Bounded Context.

## Frameworks Introduced
- **Module as First-Class Model Citizen**: Give Modules as much meaning and naming consideration as you give Entities, Value Objects, Services, and Domain Events.
  - When to use: every time you place a new concept in the model, and every time contemporary insight makes an existing Module name stale.
  - How:
    1. Choose Modules that tell the story of the system and hold a cohesive set of concepts.
    2. Aim for low coupling between classes in different Modules; if coupling stays high, change the *model* to disentangle the concepts rather than shuffling classes.
    3. Name Modules from the Ubiquitous Language, not from mechanical properties (`placesettings`, not `pronged`/`scooping`/`blunt`).
    4. Rename existing Modules as aggressively as you name new ones — refactor Modules with due diligence as the Context evolves.
    5. Keep dependencies acyclic where you can; relax the rule only between a parent Module and its own children.
  - Why it works / failure mode: mechanical grouping (all fragile things together, all sturdy things together) forces developers to *remember* where things live, which stifles modeling creativity and hides missing concepts.

- **Module Naming Convention for the Model**: `<org-reverse-domain>.<boundedcontext>.domain.model[.<concept>]`
  - When to use: naming any package/namespace inside a domain model.
  - How:
    1. Start with the organization's Internet domain, top-level first: `com.saasovation` (Java) / `SaaSOvation` (C#) — prevents collisions with third-party Modules.
    2. Next segment names the **Bounded Context**, not the product brand: `com.saasovation.agilepm`, not `com.saasovation.projectovation`. Brands change; Contexts are what the team talks about.
    3. Keep the Context segment terse: `identityaccess` over `identityandaccess`; `agilepm` over `agileprojectmanagement`.
    4. Add `.domain` to mark the inside of a Layers or Hexagonal Architecture.
    5. Add `.model` beneath it — you never build a domain, you build a *model of* a domain. Reserve `.domain.service` as a peer if you place Domain Services outside the model.
    6. Below `domain.model`, add concept Modules (`tenant`, `team`, `product`, `product.backlogitem`).

- **Module before Bounded Context**: When the linguistics are fuzzy and it is unclear whether a contextual boundary is justified, keep the concepts together and separate them with the *thinner* boundary of a Module rather than the *thicker* boundary of a Bounded Context.
  - When to use: any time you are tempted to split a model because it feels large, rather than because the Language demands it.
  - How:
    1. Listen for the linguistics: does the same term genuinely mean different things to different experts?
    2. If yes, the Bounded Context split is justified — do it.
    3. If the terminology is fuzzy, default to keeping one model and modularizing inside it.
    4. Never use Bounded Contexts as a substitute for Modules.

## Key Concepts
- **Module**: A named container for domain objects that are highly cohesive with one another and loosely coupled to those in other Modules.
- **Cohesion / coupling test**: Cohesive Modules naturally yield low inter-Module coupling; persistent high coupling signals a modeling flaw, not a packaging flaw.
- **Deployment modularity**: Versioned packaging units (OSGi bundles, Java 8 Jigsaw modules) — different from DDD Modules but complementary; loosely coupled DDD Modules make good bundle boundaries.
- **`domain.model` vs `domain.service`**: Peer sub-Modules; placing all Services in `domain.service` risks an Anemic Domain Model.
- **Acyclic dependency**: A one-directional Module reference (e.g., everything depends on `tenant`, `tenant` depends on nothing).
- **Layer Modules**: Non-model packages named per architecture layer — `…​.resources`, `…​.resources.view`, `…​.application.<service-area>`, `…​.infrastructure.<tech>`.

## Mental Models
- Think of Modules as **the kitchen drawer test**: silverware in one drawer, tools in the garage, cups in an obvious nearby cabinet. If you have to memorize where something is, the Module scheme is mechanical and wrong.
- Use **"does it read naturally in the Language?"** as the naming check — `product`, `product.backlogitem`, `product.release`, `product.sprint` read as "product," "product backlog item," "product release," "product sprint."
- When a Module would hold ~60 classes, **choose organization over cross-Module coupling purity** — sub-Modules under a parent may legitimately have bidirectional dependencies with it (Product is a Factory for BacklogItem, so `product` and `product.backlogitem` reference each other).

## Anti-patterns
- **Mechanical Module names**: Grouping by technical trait (`pronged`, `scooping`, `blunt`; all fragile things together) destroys the Language and forces memorization.
- **Product/brand names as Module names**: `idovation`, `collabovation`, `projectovation` have little mapping to their Bounded Contexts, and become obsolete the moment marketing rebrands.
- **Dropping `domain.model` for `domain.<concept>`**: Saves one level now, then blocks you from adding a clean `domain.service` peer later.
- **Generic identity types to loosen coupling**: Declaring every id as `Identity` decouples Modules but destroys type safety — `productId`, `teamId`, and `tenantId` become indistinguishable and bug-prone.
- **Bounded Context as an oversized Module**: Splitting cohesive objects into separate models because they feel numerous, without linguistic justification.

## Code Examples
```java
package com.saasovation.agilepm.domain.model.product.backlogitem;

import com.saasovation.agilepm.domain.model.tenant.TenantId;

public class BacklogItem extends ConcurrencySafeEntity {
    private BacklogItemId backlogItemId;
    private ProductId productId;
    private TeamId teamId;
    private TenantId tenantId;
    ...
}
```
- **What it demonstrates**: Specific identity Value types (not a generic `Identity`) crossing Module boundaries — `tenant` is depended on by everything and depends on nothing, while `product`/`backlogitem` accept a bidirectional parent-child dependency.

## Reference Tables

| Layer | Module convention | Notes |
|---|---|---|
| User Interface (REST) | `com.saasovation.agilepm.resources` + `.resources.view` | Resources produce bland XML/JSON/HTML; presentation lives in `view` (or `presentation`) |
| Application | `com.saasovation.agilepm.application.<area>` | Split per service type only when you exceed ~half a dozen services; otherwise keep one `…​.application` |
| Domain | `com.saasovation.<context>.domain.model[.<concept>]` | `domain.model` may hold reusable base types: `Entity`, `ConcurrencySafeEntity`, `DomainEvent`, `DomainEventPublisher`, `IdentifiedValueObject` |
| Domain (optional) | `com.saasovation.<context>.domain.service` | Only if you treat Domain Services as a ring around the model; watch for Anemic Domain Model |
| Infrastructure | `com.saasovation.<context>.infrastructure.<tech>` | Technical implementations of domain-declared interfaces |

## Worked Example
The ProjectOvation team modeled the Agile Project Management Context with three top-level Modules under `com.saasovation.agilepm.domain.model`:

- `tenant` — one Value Object, `TenantId`, originating in the Identity and Access Context. Everything depends on it; it depends on nothing (acyclic).
- `team` — `MemberService` (a Domain Service front-ending an Anticorruption Layer that eventually-consistently syncs members from Identity and Access), plus `ProductOwner`, `Team`, and `TeamMember` Aggregate Roots.
- `product` — `Product`, with three child Modules `product.backlogitem`, `product.release`, `product.sprint` holding `BacklogItem`, `Release`, `Sprint`.

With only four Aggregates, why not put them all in `product`? Because the Aggregate *parts* — `ProductBacklogItem`, `Task`, `ScheduledBacklogItem`, `CommittedBacklogItem`, other Entities, Value Objects, and published Domain Events — total nearly 60 classes. One busy Module reads as disorganization. The team accepted the parent-child coupling (each `Product` acts as a Factory for `BacklogItem`, `Release`, and `Sprint`, so the dependency is bidirectional) in exchange for organizational clarity, and rejected the alternative of typing all ids as a generic `Identity` because indistinguishable id types invite bugs.

## Key Takeaways
1. Name Modules from the Ubiquitous Language; a Module name is a modeling decision, not a filing decision.
2. Name the Bounded Context, never the product brand, in the Module path — brands change, Contexts are what the team says out loud.
3. Keep `domain.model` even when it looks redundant, so `domain.service` remains available later.
4. Rename and refactor Modules as aggressively as you create them; stale Module names lie about the model.
5. Prefer specific identity Value types over a generic `Identity` — type safety beats theoretical decoupling.
6. Reach for a Module before reaching for a new Bounded Context; only linguistic divergence justifies the thicker boundary.
7. Let cohesive DDD Modules drive your OSGi/Jigsaw deployment bundles — the loose coupling you designed for is what makes bundling possible.

## Connects To
- **ch02**: Bounded Context and Core Domain — Module-before-Bounded-Context is the sizing rule between them.
- **ch03**: Anticorruption Layer — `MemberService` in the `team` Module fronts one.
- **ch04**: Layers and Hexagonal Architecture — `domain` marks the "inside"; each layer gets its own Module conventions.
- **ch05 / ch06 / ch07 / ch08**: Entities, Value Objects, Services, Domain Events — the citizens Modules contain; `domain.model` holds their shared base types.
- **ch10**: Aggregates — why `Product`, `BacklogItem`, `Release`, and `Sprint` are separate Aggregates in separate sub-Modules.
- **ch14**: Application and User Interface layers — `resources`, `resources.view`, `application.<area>` conventions.
- **Java/C# package and namespace standards**: reverse-domain naming to avoid third-party collisions.
- **OSGi bundles / Java 8 Jigsaw**: versioned deployment modularity that complements, but is not the same as, DDD Modules.
