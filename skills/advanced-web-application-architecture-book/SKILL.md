---
name: advanced-web-application-architecture-book
description: "Knowledge base from \"Advanced Web Application Architecture\" by Matthias Noback. Use when separating core from infrastructure code, applying dependency injection and inversion, designing entities, repositories, application services, read and view models, layering an application, applying ports and adapters, or planning a testing strategy for decoupled applications."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, or chapter number] -->

# Advanced Web Application Architecture
**Author**: Matthias Noback | **Words**: ~79,500 | **Chapters**: 15 (Part I: 1–9, Part II: 10–15) | **Generated**: 2026-07-20

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `validation`, `read models`, `ports and adapters`, or anything in the Topic Index; I'll read the relevant chapter
- **With a chapter** — ask for `ch06`; I'll load that chapter file
- **Browse** — ask "what chapters do you have?"

When you ask about a topic not covered below, I will read the relevant chapter file before answering.

---

## Core Frameworks & Mental Models

### The Two Rules for Core Code (Ch 1)
The book's foundation. Code is **core** only if it passes **both**:

1. **No dependencies on external systems** — "nor does it depend on code written for interacting with a specific type of external system."
2. **No special context needed** — "nor does it have dependencies that are designed to run in a specific context only."

Anything else is **infrastructure code**. The second clause of each rule is the subtle one: an interface named `Connection` with `insert(string $table, array $data)` is still infrastructure, because the signature only makes sense for relational databases.

### The Two-Step Abstraction Recipe (Ch 1)
1. Introduce an interface.
2. **Communicate *purpose* instead of implementation details.**

Step 2 is what people skip. `Connection::insert($table, $data)` → `Repository::save(Member $member)`. Same indirection; only the second one decouples.

### The Strategy, in Two Principles (Ch 9)
Everything in Part I reduces to:
1. **Use dependency injection everywhere; let services depend on abstractions only.**
2. **Make use cases independent of the delivery mechanism of their input.**

These map onto the two actor types: (1) decouples from **secondary actors** (database, APIs, clock), (2) from **primary actors** (browser, CLI, cron, tests).

**The architectural invariant**: every dependency arrow stays inside the core, or points from infrastructure *into* the core. Never outward.

### Where Each Input Goes (Ch 5, 11)
- **Dependencies** (services) → constructor arguments
- **Configuration values** → constructor arguments, with an assertion
- **Contextual information** → method arguments (the tell is the word "current")
- **Job-specific data** → method arguments, ideally a command object

Injecting `ContainerInterface` is *not* dependency injection — it passes Rule 1 but fails Rule 2.

### Object-Pure Code (Ch 5, 9)
> "The result of calling a method on an object should be determined by its own implementation logic, and optionally by the behavior of one of its constructor arguments, or the method arguments provided to it; and nothing more."

**Impurity is transitive through concrete dependencies.** Injecting a concrete `Timer` doesn't help — calling it inevitably calls `time()`. Only an *interface* breaks the chain.

### Prefer Protection over Validation (Ch 8)
> "We don't assign a value to a property, then validate it; we protect the object from ending up in an incorrect state."

Objects must prevent **incomplete**, **invalid**, and **inconsistent** state, plus illegal **state transitions**. Push each rule into a value object — then a typed parameter *is* proof that validation happened. Validate with **pure functions only**.

### Write Model / Read Model Separation (Ch 3)
> "A client that needs an object for getting information from should not retrieve the same object as clients that want to make changes to it."

A getter appearing on an entity means you loaded it just to read. **Read models return value objects; view models return render-ready primitives.** Design each backwards from its client — the calling code, or the template.

### The CLI Thought Experiment (Ch 3)
"If the business ran from the command line, would the application still need this functionality?"
- **No** → it was justifiably tied to infrastructure. Leave it.
- **Yes** → it must be decoupled and represented in core code.

### The Abstraction Test (Ch 6)
> "It's a good abstraction if it is still useful when the implementation details change radically."

Explicitly **not** "if you can create a test double for it." Extracting an interface *from* a vendor's API client changes nothing — the vendor's method names, parameters, and return types survive. Find the abstraction by writing the call you *wish* existed, in your own domain's words.

### Design Ownership (Ch 7)
> "The classes you use as dependencies (constructor arguments, method arguments and return types) in your domain model should also be designed by you."

Third-party classes are built for *any* use case. Use them *inside* your value objects for heavy lifting; never in the public API.

### Ports and Adapters (Ch 13)
A **port** is an intention of communication (name it by completing "for …"); an **adapter** is its implementation, including all collaborating code — the ORM, the framework, the web server. **Test code is an adapter.**

The asymmetry: outgoing adapters **implement** the port interface; incoming adapters **use** it (`ApplicationInterface` or a `CommandBus`).

### Layers and the Dependency Rule (Ch 12)
Domain / Application / Infrastructure, with **interfaces inward, implementations outward**. "Source code dependencies should only point inwards." Express layers as namespaces; enforce with `deptrac`.

### The Testing Strategy (Ch 14)
> "A test is not a unit test if it invokes infrastructure code."

- **Unit tests** — entities and value objects only
- **Use case tests** — the hexagon, via a hand-written test container with in-memory repositories and spies
- **Adapter tests** — contract tests (outgoing) and driving tests (incoming)
- **End-to-end tests** — a few, black-box

Never unit-test controllers, application services, subscribers, or repository implementations.

### Just-Right-Engineering (Ch 15)
> "If you feel like core and infrastructure deserve to be apart, doing that extra work can't be considered over-engineering. It's rather *just-right-engineering*."

Most web applications are *under*-engineered. But: small infrastructural scripts and genuine CRUD apps don't need this — and automated testing is never optional regardless.

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-introduction-core-vs-infrastructure.md) | Introduction (Core vs. Infrastructure) | Two rules for core code, two-step abstraction recipe |
| [ch02](chapters/ch02-the-domain-model.md) | The domain model | Entity, Repository, `nextIdentity()`, value object IDs, Data Mapper vs Active Record |
| [ch03](chapters/ch03-read-models-and-view-models.md) | Read models and view models | Write/read separation, view models, CLI thought experiment |
| [ch04](chapters/ch04-application-services.md) | Application services | Application service, command object, the four-refactoring sequence |
| [ch05](chapters/ch05-service-locators.md) | Service locators | Constructor injection, composition root, unit-testability property |
| [ch06](chapters/ch06-external-services.md) | External services | Façade, level of abstraction, integration tests |
| [ch07](chapters/ch07-time-and-randomness.md) | Time and randomness | `Clock`, `FakeClock`, design ownership, "jumpy" code |
| [ch08](chapters/ch08-validation.md) | Validation | Protection vs validation, `UserErrorMessage`, pure-function rule |
| [ch09](chapters/ch09-conclusion-part-i.md) | Conclusion (Part I) | The two-principle strategy, primary/secondary actors, object-purity |
| [ch10](chapters/ch10-introduction-part-ii.md) | Introduction (Part II) | The three organizing principles |
| [ch11](chapters/ch11-key-design-patterns.md) | Key design patterns | The object catalog, entity rules, event subscriber placement, Process Modelling |
| [ch12](chapters/ch12-architectural-layers.md) | Architectural layers | Domain/Application/Infrastructure, Dependency rule, `deptrac` |
| [ch13](chapters/ch13-ports-and-adapters.md) | Ports and adapters | Ports, adapters, `ApplicationInterface`, command bus |
| [ch14](chapters/ch14-a-testing-strategy.md) | A testing strategy | Four test types, contract tests, spies, top-down workflow |
| [ch15](chapters/ch15-conclusion.md) | Conclusion | Objections, trade-offs, just-right-engineering |

## Topic Index

- **Active Record** → ch02
- **Actors (primary/secondary)** → ch09, ch13
- **Adapters** → ch13, ch14
- **Application service** → ch04, ch11, ch12
- **`ApplicationInterface`** → ch13, ch14
- **Assertions** → ch02, ch05, ch08
- **Behat / Gherkin** → ch14
- **Clock / time** → ch07, ch09
- **Command bus** → ch13
- **Command object / DTO** → ch04, ch08, ch11
- **Composition root** → ch05, ch14
- **Contract test** → ch13, ch14
- **Core vs. infrastructure code** → ch01, ch09, ch12
- **CQRS** → ch03, ch04
- **CRUD** → ch15
- **Dependency injection / inversion** → ch05, ch09, ch12
- **Dependency rule** → ch12
- **`deptrac`** → ch12
- **Domain events** → ch03, ch04, ch11
- **Entity** → ch02, ch11, ch12
- **Event subscribers** → ch04, ch11
- **External services / APIs** → ch06
- **Façade** → ch06
- **Hexagonal architecture** → ch13
- **Integration tests** → ch06, ch07, ch14
- **Layers** → ch12, ch13
- **Legacy code** → ch09, ch15
- **Namespaces** → ch12, ch13
- **ORM / Doctrine** → ch02, ch11
- **Over-engineering** → ch02, ch15
- **Ports** → ch13
- **Process Modelling** → ch11
- **Pure functions / object-purity** → ch05, ch08, ch09
- **Randomness / UUID** → ch02, ch07
- **Read models** → ch03, ch11
- **Repository** → ch02, ch11, ch13
- **Service locators** → ch01, ch05
- **Spy / test doubles** → ch13, ch14
- **State machines** → ch11
- **Testing strategy** → ch05, ch14
- **Unit tests** → ch05, ch14
- **Use case tests** → ch14
- **Validation** → ch08
- **Value objects** → ch02, ch03, ch07, ch08
- **View models** → ch03, ch11

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions and chapter references
- [patterns.md](patterns.md) — every technique with when-to-use, how, and trade-offs
- [cheatsheet.md](cheatsheet.md) — decision rules, smell tables, thresholds

---

## Scope & Limits

This skill covers the book's content only. Examples are PHP (Symfony/Laravel/Doctrine idioms), but the principles are language-agnostic. For hands-on implementation in your codebase, combine with project-specific tools. Related skills: `object-design-style-guide-book` (same author, object-level rules), `unit-testing-ppp-book` (test design), `bdd-in-action-book` (scenarios and living documentation).
