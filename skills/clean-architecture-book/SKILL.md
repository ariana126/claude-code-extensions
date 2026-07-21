---
name: clean-architecture-book
description: "Knowledge base from \"Clean Architecture: A Craftsman's Guide to Software Structure and Design\" by Robert C. Martin. Use when applying Martin's frameworks for SOLID principles, component cohesion and coupling, architectural boundaries, the Dependency Rule, entities and use cases, plugin architecture, or deciding what belongs in the core versus what is a detail — and when studying or referencing the book's chapters."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, or chapter number] -->

# Clean Architecture: A Craftsman's Guide to Software Structure and Design
**Author**: Robert C. Martin (with guest chapters by Simon Brown and James Grenning) | **Chapters**: 34 + Appendix A | **Parts**: 7 | **Generated**: 2026-07-22

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `boundaries`, `SRP`, `component coupling`, `microservices`, `packaging`; I find and read the relevant chapter
- **With a chapter** — ask for `ch22`; I load that specific chapter file
- **Browse** — ask "what chapters do you have?" for the full index

When you ask about a topic not covered in Core Frameworks below, I will read the
relevant chapter file before answering.

---

## Core Frameworks & Mental Models

### The Dependency Rule — the rule everything reduces to
> **Source code dependencies must point only inward, toward higher-level policies.**

Nothing in an inner circle may name anything in an outer circle — not a class, not a function, not a data format. The four circles, outermost to innermost: **Frameworks & Drivers** → **Interface Adapters** → **Use Cases** → **Entities**. Outer circles are mechanisms; inner circles are policies. Cross a boundary by having the inner circle declare an interface and the outer circle implement it, and pass only simple isolated data structures — never an Entity, a DB row, or a framework type. (Ch22)

### Architecture is about deferring decisions
**Good architecture maximizes the number of decisions not yet made.** Its job is to support development, deployment, operation, and maintenance — and to keep options open for as long as possible. The database, the web, the UI, the framework, and the service topology are all **details**; if you cannot build and test the whole system without choosing them, the boundaries are in the wrong place. (Ch15, Part VI)

### The two values, and which one to fight for
Software gives stakeholders **behavior** and **structure**. Behavior is urgent but rarely important; structure is important but never urgent. Business will always push you into the urgent — that is the developer's job to resist. Use the Eisenhower matrix: architecture belongs in the *important* row, and a system that is easy to change is worth more than one that works today. *"The only way to go fast, is to go well."* (Ch1, Ch2)

### SOLID, stated precisely
- **SRP** — A module should be responsible to **one, and only one, actor**. Not "does one thing." The symptoms of violation are accidental duplication and merge conflicts; the fix is splitting by actor, optionally behind a Facade. (Ch7)
- **OCP** — Extend without modifying. Arrange the component hierarchy so a new requirement means *adding* code, and so that high-level components are protected from changes in low-level ones. This is the principle that produces architecture. (Ch8)
- **LSP** — Subtypes must be substitutable. Violation shows up as an `if (type == X)` at the call site, and at architectural scale as special-casing one provider's API. (Ch9)
- **ISP** — Don't depend on modules carrying baggage you don't use; the baggage drags its recompiles and redeployments onto you. (Ch10)
- **DIP** — Refer only to abstract interfaces. The thing to avoid is depending on the **concrete and volatile**; depending on the concrete-but-stable (`String`) is fine. Every system has at least one concrete component — push all concrete dependencies into `Main`. (Ch11)

### Component cohesion — a tension, not a checklist
**REP** (the granule of reuse is the granule of release), **CCP** (things that change together belong together), and **CRP** (don't make users depend on what they don't need) pull against each other; you cannot satisfy all three. Favor **CCP** early, when developability matters more than reuse, and drift toward **REP/CRP** as external consumers appear. Position on the tension diagram is a lifecycle decision. (Ch13)

### Component coupling — measurable
- **ADP** — no cycles in the component graph. Break one with DIP, or by extracting a shared component.
- **SDP** — depend in the direction of stability: `I = Fan-out / (Fan-in + Fan-out)` must *decrease* along each dependency.
- **SAP** — a stable component should be abstract: `A = Na / Nc`. Stable and concrete is rigid.
- **Main Sequence** — `D = |A + I − 1|`. Aim for the endpoints; investigate high `D`. The **Zone of Pain** (concrete, heavily depended on, e.g. a DB schema) hurts only when volatile; the **Zone of Uselessness** is dead abstraction. (Ch14)

### Where to draw a boundary
Draw a line between things that change at different rates or for different actors — and *always* between business rules and details. Boundaries are expensive and require guessing the future, so both over- and under-engineering cost real money; when uncertain, build a **partial boundary** (Skip the Last Step, One-Dimensional Boundary, or Facade) and upgrade it later. Choose the cheapest decoupling mode that works — source, then deployment, then service — and **defer that choice as long as possible, keeping it reversible**. (Ch17, Ch24, Ch25, Ch16)

### Services are not architecture
Services are neither inherently decoupled nor inherently independently developable — they are just an expensive way to draw a boundary. If a new cross-cutting feature forces edits to every service (the taxi-aggregator "kitty problem"), the boundaries were drawn on the wrong dimension. The fix is component-based services: a clean architecture *inside* each service, so the architectural boundary need not coincide with the process boundary. (Ch27)

### Testability is a structural property
Tests are part of the system and obey the same rules. Testing through the GUI produces the **Fragile Tests Problem**; the answer is the **Humble Object Pattern** (push all behavior into a testable half, leave the untestable half trivially dumb) and a **Testing API** that decouples tests from the app's structure. Keep that API out of production. (Ch23, Ch28)

### Screaming Architecture
Your top-level directory structure should announce **what the system does**, not what framework it was built with. If it reads `controllers/ models/ views/`, it is screaming Rails. The web is a delivery mechanism; the framework is a detail whose author's agenda is not yours. (Ch21, Ch32)

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-what-is-design-and-architecture.md) | What Is Design and Architecture? | The signature of a mess, "go fast by going well" |
| [ch02](chapters/ch02-a-tale-of-two-values.md) | A Tale of Two Values | Behavior vs structure, Eisenhower matrix, fight for the architecture |
| [ch03](chapters/ch03-paradigm-overview.md) | Paradigm Overview | The three paradigms as three subtractions |
| [ch04](chapters/ch04-structured-programming.md) | Structured Programming | Functional decomposition, tests prove incorrectness |
| [ch05](chapters/ch05-object-oriented-programming.md) | Object-Oriented Programming | Polymorphism, dependency inversion, plugin architecture |
| [ch06](chapters/ch06-functional-programming.md) | Functional Programming | Immutability, segregation of mutability, event sourcing |
| [ch07](chapters/ch07-srp-single-responsibility.md) | SRP: Single Responsibility | One actor, accidental duplication, Facade split |
| [ch08](chapters/ch08-ocp-open-closed.md) | OCP: Open-Closed | Directional control, information hiding, protection hierarchy |
| [ch09](chapters/ch09-lsp-liskov-substitution.md) | LSP: Liskov Substitution | Square/Rectangle, LSP at architectural scale |
| [ch10](chapters/ch10-isp-interface-segregation.md) | ISP: Interface Segregation | Dependency baggage, static vs dynamic languages |
| [ch11](chapters/ch11-dip-dependency-inversion.md) | DIP: Dependency Inversion | Stable abstractions, Abstract Factory, concrete component rule |
| [ch12](chapters/ch12-components.md) | Components | Units of deployment, the road to plugins |
| [ch13](chapters/ch13-component-cohesion.md) | Component Cohesion | REP, CCP, CRP, the tension diagram |
| [ch14](chapters/ch14-component-coupling.md) | Component Coupling | ADP, SDP, SAP, I/A/D metrics, Main Sequence |
| [ch15](chapters/ch15-what-is-architecture.md) | What Is Architecture? | Keeping options open, device independence |
| [ch16](chapters/ch16-independence.md) | Independence | Decoupling layers vs use cases, true vs accidental duplication, decoupling modes |
| [ch17](chapters/ch17-boundaries-drawing-lines.md) | Boundaries: Drawing Lines | The plugin argument, FitNesse case study |
| [ch18](chapters/ch18-boundary-anatomy.md) | Boundary Anatomy | Boundary crossing cost ladder, monolith/process/service |
| [ch19](chapters/ch19-policy-and-level.md) | Policy and Level | Level = distance from I/O |
| [ch20](chapters/ch20-business-rules.md) | Business Rules | Critical vs application-specific rules, request/response models |
| [ch21](chapters/ch21-screaming-architecture.md) | Screaming Architecture | Use cases over frameworks, the web as delivery mechanism |
| [ch22](chapters/ch22-the-clean-architecture.md) | The Clean Architecture | **The Dependency Rule**, the four circles, crossing boundaries |
| [ch23](chapters/ch23-presenters-and-humble-objects.md) | Presenters and Humble Objects | Humble Object Pattern, Database Gateways, Data Mappers |
| [ch24](chapters/ch24-partial-boundaries.md) | Partial Boundaries | Skip the Last Step, One-Dimensional Boundary, Facade |
| [ch25](chapters/ch25-layers-and-boundaries.md) | Layers and Boundaries | Hunt the Wumpus, the cost of guessing boundaries |
| [ch26](chapters/ch26-the-main-component.md) | The Main Component | Main as the ultimate detail and initial plugin |
| [ch27](chapters/ch27-services-great-and-small.md) | Services: Great and Small | Service decoupling myths, the kitty problem, component-based services |
| [ch28](chapters/ch28-the-test-boundary.md) | The Test Boundary | Fragile Tests Problem, design for testability, Testing API |
| [ch29](chapters/ch29-clean-embedded-architecture.md) | Clean Embedded Architecture | Target hardware bottleneck, HAL, OSAL |
| [ch30](chapters/ch30-the-database-is-a-detail.md) | The Database Is a Detail | Data model vs database, "what if there were no disk?" |
| [ch31](chapters/ch31-the-web-is-a-detail.md) | The Web Is a Detail | The oscillating UI, abstraction of I/O |
| [ch32](chapters/ch32-frameworks-are-details.md) | Frameworks Are Details | The asymmetric marriage, keeping frameworks behind a boundary |
| [ch33](chapters/ch33-case-study-video-sales.md) | Case Study: Video Sales | Actors × use cases, component architecture by actor |
| [ch34](chapters/ch34-the-missing-chapter.md) | The Missing Chapter | Package by Layer/Feature/Component, Ports and Adapters, encapsulation |
| [appA](chapters/appendix-a-architecture-archaeology.md) | Architecture Archaeology | Recurring lessons across 40 years of systems |

## Topic Index

- **Abstract Factory** → ch11, ch26
- **Actors** → ch07, ch33
- **ADP / dependency cycles** → ch14
- **Boundaries** → ch17, ch18, ch24, ch25
- **Business rules** → ch19, ch20
- **CCP / CRP / REP** → ch13
- **Component metrics (I, A, D)** → ch14
- **Database** → ch30, ch23
- **Dependency Rule** → ch22
- **Deployment** → ch12, ch15, ch16, ch18
- **Duplication (true vs accidental)** → ch16
- **Embedded / firmware / HAL** → ch29
- **Entities** → ch20, ch22
- **Event sourcing / immutability** → ch06
- **Frameworks** → ch32, ch21
- **Humble Object** → ch23, ch28
- **Levels / policy** → ch19
- **Main component** → ch26, ch11
- **Microservices / services** → ch27, ch18
- **OCP** → ch08
- **Packaging / code organization** → ch34, ch21
- **Partial boundaries** → ch24
- **Plugin architecture** → ch05, ch11, ch17, ch26
- **Polymorphism** → ch05
- **Presenters / UI** → ch23, ch31
- **SOLID** → ch07, ch08, ch09, ch10, ch11
- **Testing** → ch28, ch23, ch04
- **Use cases** → ch20, ch21, ch22, ch33
- **Web / UI** → ch31, ch21

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions and chapter references
- [patterns.md](patterns.md) — every technique with when / how / trade-offs
- [cheatsheet.md](cheatsheet.md) — decision rules, metric formulas, tells & smells

---

## Scope & Limits

This skill covers the book's content only. Martin writes from an OO, statically typed,
enterprise perspective and is deliberately skeptical of microservices and frameworks —
treat those positions as arguments to weigh, not settled fact. For applying these ideas
to a specific codebase, combine with project tooling; for topics beyond the book, ask
directly.
