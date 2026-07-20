---
name: object-design-style-guide-book
description: "Knowledge base from \"Object Design Style Guide\" by Matthias Noback. Use when applying Noback's rules for object-oriented design, services and value objects, immutability, command/query separation, dependency injection, exceptions, read/write models, or layered architecture — while coding, reviewing, or studying the book."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, or chapter number] -->

# Object Design Style Guide
**Author**: Matthias Noback | **Publisher**: Manning, 2020 | **Chapters**: 11 | **Generated**: 2026-07-20

## How to Use This Skill

- **Without arguments** — load the core rules below
- **With a topic** — ask about `named constructors`, `CQS`, `read models`, `decoration`; I find and read the relevant chapter
- **With a chapter** — ask for `ch04`; I load that file
- **Browse** — ask "what chapters do you have?"

Code samples use the book's language-agnostic pseudo-PHP. The rules apply to any OO language.

---

## Core Frameworks & Mental Models

### The two types of objects
Everything is either a **service** (a do-er: `EventDispatcher`, `UserRepository`) or an **other object** (a material: `User`, `Money`, `Credentials`). They get opposite rulesets. Services receive *dependencies*; other objects receive *values*.

### Service construction (Ch 2)
- **All constructor arguments required.** No optionals, no defaults, no setter injection. Replace an "optional dependency" with a **null object**; replace an optional config value with a `createDefault()` factory.
- **Inject what you need, not where you can get it from.** Never inject a service locator, container, or manager you'd call `.get()` on. Ask: *does the service use this directly, or retrieve the real dependency from it?*
- **A constructor does exactly two things: validate and assign.** If reordering the assignments breaks it, you're doing work in the constructor.
- **Task data and "the current X" are method arguments.** Batch test: *could I run this service in a batch without reinstantiating it?*
- **Make hidden dependencies explicit** — static accessors → injected objects; complex stdlib functions → wrapper objects; system calls (`new DateTime()`) → a `Clock` service, or better, a method argument.
- **Immutable after construction.** No `setLogger()`, no `ignoreErrors()`, no `addListener()`.

### Other-object construction (Ch 3)
- **Require the minimum data needed to behave consistently**, and **require data that is meaningful**. State the domain invariant as a sentence first ("Latitude is between −90 and 90"), then encode it.
- **When two arguments must be validated together, suspect the design.** Either one is derivable (`Deal` computes `totalAmount()`), or you have two construction paths (`Line.dotted()` / `Line.solid()`).
- **Extract a value object when the answer to "would any string/int be acceptable here?" is no.** Name it for the concept, not its validity — `EmailAddress`, never `ValidEmailAddress`, because all objects are valid by construction. You are extending the type system.
- **Use named constructors** (`public static` + `private` regular constructor). Speak the domain: a sales order is **placed**, not constructed.
- **Only test constructors for how they should fail.** Never add getters just to test construction.

### Mutability & modifiers (Ch 4)
- **Default to immutable.** Services immutable, entities mutable by design, everything else immutable. Immutability is **transitive**.
- **Mutable modifier = command method**: imperative name, `void`, changes state.
- **Immutable modifier = declarative name + returns own type.** Name it from *"I want this …, but …"* → `toTheLeft(4)`, `withDiscountApplied()`. Prefer domain names over technical ones (`toTheLeft()`, not `withXDecreasedBy()`).
- **Build copies through the constructor**, not `clone`, so validation is reused.
- **Never give a mutable object a fluent interface**; immutable objects get one free.
- **Verify entity changes via recorded domain events**, not added getters.

### Method template & exceptions (Ch 5)
```
preconditions → failure scenarios → happy path → postconditions → return
```
- **One question decides the exception type**: could you know it's wrong from the argument alone? Yes → `InvalidArgumentException` (a bug — fail hard, no custom subclass). No → `RuntimeException` (the world didn't cooperate — recoverable).
- **Naming**: logic errors fill in "Invalid…"; runtime errors finish "Sorry, I …" → "CouldNot…". Drop the "Exception" suffix.
- **Named constructors on exceptions** put message assembly inside the class: `throw CouldNotFindProduct.withId(productId)`.
- **Return early, throw early, eliminate `else`.**

### Command/Query Separation (Ch 6, Ch 7)
- Every method is **either** a command (`void`, side effect, imperative name) **or** a query (returns information, no side effects, single return type, noun-ish name). Immutability gives you CQS for free.
- **Query chains may not contain commands. Command chains may contain queries.**
- **Avoid query methods that expose internal state.** Watch what clients do with a getter — that logic belongs inside. Success looks like being able to *delete* the getter.
- **No `get` prefix**: `itemCount()`, not `getItemCount()`. `get…` promises; `find…` may come back empty.
- **Avoid returning `null`**: throw, return a null object, or return the empty value.
- **A query-then-command pair on the same object** is a conversation that belongs inside it: `player.evade(obstacle)`, not `if (obstacle.isOnTheRight()) player.moveLeft();`
- **Limit command scope, dispatch events for secondary effects** — and dispatch **explicitly**, so the effect is discoverable.

### Abstraction (Ch 6, 7, 9)
An abstraction is **two things, both required**: (1) an interface, not a class, and (2) a name free of implementation details. `HttpClient` fails the second test; `ExchangeRates` passes.
- Apply whenever you cross a system boundary — network, filesystem, clock, database, queue.
- **Abstract early, generalize late** (~three similar cases). Generalizing early means rewriting the interface and every implementation.
- Escalate deliberately: better variable name → private method → new class only for size, testability, or a boundary.

### Changing behavior (Ch 9)
**Replace parts; don't change them.** Modify the object graph's structure, not a class's code. Ladder: configurable value → replaceable dependency → composition → decoration → notification object / event listener.
- **Never use inheritance to change behavior.** Template method is better than subclassing but strictly weaker than composition — convert by promoting the `abstract protected` method to a `public` method on an injected object.
- **Don't extend third-party classes even when invited to.** Internals change; published APIs don't.
- **`final` and `private` by default** — for every class, including entities and value objects. Sole exception: a genuine type hierarchy.
- Use **traits** (not inheritance) for reuse in entities/value objects.

### Read vs. write models (Ch 8)
**Never hand a modifiable entity to a client that shouldn't modify it.** Split into a write model (commands) and per-use-case read models. Query methods on write models are fine — the rule targets read-*only* clients.
- Build read models: from the write model (stopgap) → **directly from the data source (default)** → from domain events (only when recomputation is genuinely too expensive).
- Event sourcing is **not** required to get any of this.

### Layers (Ch 10)
```
Infrastructure  controllers, repository IMPLEMENTATIONS
Application     application services, command objects, read models,
                read model repository INTERFACES, event listeners
Domain          entities, value objects, write model repository INTERFACES
```
Dependencies point **inward only**. Interfaces go on repositories and anything crossing a boundary — *not* on controllers, application services, entities, value objects, or read models.

### Testing (throughout, Ch 11)
- **Test objects, not classes.** Test doubles only for system-boundary crossings; everything else real.
- **Governing rule**: write tests so that as many implementation details as possible could change before the test must.
- **Mocks/spies for commands; dummies/stubs/fakes for queries.** Never assert on calls to query methods. Write stubs and fakes by hand.
- If a test passes but the code is wrong, **the test suite is what's broken**.

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-programming-with-objects-primer.md) | Programming with Objects: A Primer | vocabulary, scoping, DI vs. service location, polymorphism, test doubles |
| [ch02](chapters/ch02-creating-services.md) | Creating Services | two types of objects, inject-what-you-need, no optional dependencies, explicit dependencies, batch test |
| [ch03](chapters/ch03-creating-other-objects.md) | Creating Other Objects | domain invariants, value object extraction, named constructors, assertions, DTOs |
| [ch04](chapters/ch04-manipulating-objects.md) | Manipulating Objects | entity/value object/DTO, command methods, declarative modifiers, recorded events |
| [ch05](chapters/ch05-using-objects.md) | Using Objects | method template, two-exception rule, exception naming, replace primitive with object |
| [ch06](chapters/ch06-retrieving-information.md) | Retrieving Information | CQS, single return types, don't expose internals, two-step abstraction, stubs & fakes |
| [ch07](chapters/ch07-performing-tasks.md) | Performing Tasks | command methods, events for secondary tasks, reinstantiation test, abstraction-then-generalization, mocks & spies |
| [ch08](chapters/ch08-dividing-responsibilities.md) | Dividing Responsibilities | write vs. read models, use-case read models, three build strategies |
| [ch09](chapters/ch09-changing-behavior-of-services.md) | Changing the Behavior of Services | the escalation ladder, composition, decoration, notification objects, final & private by default |
| [ch10](chapters/ch10-field-guide-to-objects.md) | A Field Guide to Objects | recognition tests for 7 object types, abstract vs. concrete, three layers |
| [ch11](chapters/ch11-epilogue.md) | Epilogue | class vs. object testing, top-down feature development, further reading |

## Topic Index

- **Abstraction** → ch06, ch07, ch09, ch10
- **Application services** → ch10
- **Assertions** → ch03, ch05
- **Command methods** → ch04, ch06, ch07
- **Command/Query Separation** → ch06, ch07
- **Composition** → ch01, ch09
- **Constructor injection** → ch01, ch02
- **Controllers** → ch02, ch06, ch10
- **Decoration** → ch09
- **Dependency injection** → ch01, ch02
- **Domain events** → ch04, ch07, ch08, ch10
- **Domain invariants** → ch03, ch04
- **DTOs** → ch03, ch04, ch10
- **Entities** → ch03, ch04, ch08, ch10
- **Event listeners** → ch07, ch09, ch10
- **Exceptions** → ch03, ch05, ch07
- **`final` / `private` defaults** → ch01, ch09
- **Fluent interfaces** → ch04
- **Generalization** → ch07, ch09
- **Getters** → ch03, ch06
- **Immutability** → ch01, ch04, ch07
- **Inheritance (and why not)** → ch01, ch09
- **Layers / architecture** → ch10, ch11
- **Method template** → ch05
- **Named constructors** → ch03, ch05
- **Null objects** → ch02, ch06
- **Query methods** → ch06
- **Read models** → ch08, ch10
- **Repositories** → ch02, ch08, ch10
- **Service locators** → ch01, ch02
- **State transitions** → ch04
- **System boundaries** → ch02, ch06, ch07
- **Template method pattern** → ch09
- **Test doubles (stub/fake/mock/spy/dummy)** → ch01, ch06, ch07
- **Testing strategy** → ch03, ch04, ch06, ch07, ch11
- **Traits** → ch09
- **Value objects** → ch03, ch04, ch10
- **Write models** → ch08, ch10

## Supporting Files

- [glossary.md](glossary.md) — every key term with its chapter
- [patterns.md](patterns.md) — techniques with when/how/trade-offs
- [cheatsheet.md](cheatsheet.md) — decision rules and signature-reading tables

---

## Scope & Limits

Covers the book only. Noback's own caveat applies: bend the rules when quality genuinely doesn't matter or the effort outweighs the benefit — but he estimates that's under 5% of real cases. The book deliberately does *not* tell you which objects you need or what their responsibilities are; for that he points to domain-driven design (Evans, Vernon) and hexagonal architecture.

Code samples are in the book's fictional pseudo-PHP; the author's own examples occasionally contain typos, which are reproduced faithfully only where they don't obscure the point.
