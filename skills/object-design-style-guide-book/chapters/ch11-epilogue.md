# Chapter 11: Epilogue

## Core Idea
The book's rules are a *foundation*, not a complete theory of design — they say how classes and methods should be declared, not which objects you need. Noback points at three areas that supply the rest: architectural patterns, testing strategy, and domain-driven design. Along the way he gives the single sharpest testing rule in the book.

## Frameworks Introduced

- **Class testing vs. object testing** — the chapter's most actionable distinction:
  - **Class test (white box)**: tests one method of one class with *all* dependencies replaced by test doubles. You end up verifying that method calls were made, adding getters to extract state, and coupling the test to the implementation.
  - **Object test (black box)**: tests behavior as perceived from outside. Instantiate the object with test doubles **only for things that cross a system boundary** — everything else is real. Exercises a larger unit as a whole.
  - Why it matters: class tests change every time the class does. Object tests survive refactoring and are therefore more useful over time.

- **The testing rule**: *Write your tests so that as many implementation details as possible could change before the test code itself has to change.*
  - This is the criterion behind nearly every testing recommendation elsewhere in the book — no getters for tests (Ch 3, Ch 4), no asserting on query calls (Ch 6), `assertContains` over `assertEquals` on event lists (Ch 4).

- **Top-down feature development**: Start with the bigger picture, not the building blocks.
  - The failure mode it prevents: you collect all the ingredients first — repository, database table, entity — then discover when wiring them together that your assumptions were wrong and the pieces don't fit. That work is wasted.
  - How: describe user scenarios and sketch the interaction; specify the application's high-level behavior *as a black box* before descending. High-level tests stay red until the lower-level tests pass.

- **On bending the rules**: Noback explicitly permits it — when quality genuinely doesn't matter (short-lived code), or when applying every rule costs more than the benefit. But he immediately narrows it: *"don't be too quick to judge. I'd estimate that in 95% of real-world scenarios, there really isn't a case for taking shortcuts."*
  - He also notes many of these rules are **statically analyzable** — a tool could flag methods that both change state and return something, or services whose behavior changes after construction.

## Key Concepts
- **Hexagonal architecture / ports and adapters**: Structuring around the ways an application communicates with the outside world, separating that communication code from the core.
- **Domain-first approach**: Learn the problem domain, reflect it in the domain model — pulling focus away from infrastructural details like tables and columns.
- **DDD strategic vs. tactical**: Strategic is fascinating; **tactical** is where the object design payoff is (entities, value objects, and related types).

## Mental Models
- **Rules you follow without thinking free up mental energy.** Noback's stated reason for internalizing them: because the style guide is automatic for him, there's more room to experiment with the things that actually require thought.
- **Test doubles mark system boundaries, nothing else.** If you're stubbing something that lives entirely in memory, you've slipped from object testing into class testing.
- **Nested TDD cycles.** A high-level cycle closes only after several low-level cycles have closed inside it.

## Anti-patterns
- **Testing classes instead of objects**: produces tests too close to the implementation, and drives getters into production code that no real client wants.
- **Bottom-up feature development**: building components before knowing how they'll be used, then reworking them when they don't fit.
- **Treating "you may bend the rules" as broad license**: the escape hatch covers roughly 5% of cases.

## Reference Tables

| | Class test (white box) | Object test (black box) |
|---|---|---|
| Scope | One method of one class | An object and its real collaborators |
| Test doubles for | Every dependency | Only system-boundary crossings |
| Verifies | Method calls, internal state | Behavior observable from outside |
| Stability | Changes with every implementation change | Survives refactoring |
| Verdict | Avoid | **Prefer** |

**Where Noback points next:**

| Topic | Source |
|---|---|
| Hexagonal architecture | Vernon, *Implementing DDD*, ch. 4; Noback's "Layers, ports & adapters" parts 2–3; "When to add an interface to a class" |
| Test-guided design | Freeman & Pryce, *Growing Object-Oriented Software, Guided by Tests* |
| Specification by example / BDD | Adzic, *Specification by Example* and *Bridging the Communication Gap*; Nagy & Rose, *Discovery* |
| DDD (tactical especially) | Evans, *Domain-Driven Design*; Vernon, *Implementing Domain-Driven Design* |

## Key Takeaways
1. The style guide covers *how* to declare classes and methods — not which objects you need or what their responsibilities are.
2. Test objects, not classes. Use test doubles only where you cross a system boundary.
3. The governing test rule: maximize the implementation changes possible before test code must change.
4. Work top-down — specify high-level behavior first, then descend. Bottom-up building wastes rework.
5. Bending the rules is allowed but rare; assume ~95% of the time there's no real case for a shortcut.
6. Many of these rules could be enforced by static analysis.
7. For "which objects should exist," go to DDD's tactical patterns. For "how does the application meet the outside world," go to hexagonal architecture.

## Connects To
- **Ch 1 §1.10**: unit-testing basics; here they're reframed as object vs. class testing
- **Ch 3 §3.12 / Ch 4 §4.12**: "don't test constructors" and "use recorded events" are consequences of the black-box rule
- **Ch 6 §6.6 / Ch 7 §7.7**: the stub/fake vs. mock/spy split follows from testing objects rather than classes
- **Ch 10 §10.8**: the layering described there *is* hexagonal architecture, named here
