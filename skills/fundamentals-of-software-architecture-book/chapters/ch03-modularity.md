# Chapter 3: Modularity

## Core Idea
Modularity is an implicit architecture characteristic that must be actively maintained against entropy; architects measure it with **cohesion**, **coupling**, and **connascence** — the last being a precise *language* for describing coupling and a guide for refactoring it.

## Frameworks Introduced

- **Modularity vs. Granularity** — *"Embrace modularity, but beware of granularity."* (Mark Richards)
  - **Modularity** = breaking systems into smaller pieces (monolith → microservices).
  - **Granularity** = the *size* of those pieces.
  - When to use: when a decomposition is going wrong, diagnose granularity, not modularity. Granularity is where architects and developers get into trouble — it drives coupling between services and produces Spaghetti Architecture, Distributed Monoliths, and the Big Ball of Distributed Mud.

- **The Cohesion Scale** (best → worst), from computer science:

  | Level | Meaning |
  |---|---|
  | **Functional** | Every part relates to the others; the module contains everything it needs |
  | **Sequential** | One module's output is the other's input |
  | **Communicational** | Two modules form a chain, each operating on / contributing to some output (e.g. one adds a DB record, the other emails about it) |
  | **Procedural** | Two modules must execute in a particular order |
  | **Temporal** | Related only by timing (e.g. a list of unrelated startup initializations) |
  | **Logical** | Data related logically but not functionally (e.g. `StringUtils` — static methods on `String` that are otherwise unrelated) |
  | **Coincidental** | Elements unrelated except for sharing a source file. The worst form |

  - Constraint (Larry Constantine, *Structured Design*): *"Attempting to divide a cohesive module would only result in increased coupling and decreased readability."*

- **Coupling metrics** (Yourdon & Constantine, *Structured Design*, 1979) — based on graph theory over the call graph:
  - **Afferent coupling** = *incoming* connections to a code artifact.
  - **Efferent coupling** = *outgoing* connections to other artifacts.
  - Mnemonics: `a` precedes `e` as *incoming* precedes *outgoing*; `e` in **e**fferent matches **e**xit.

- **Martin's derived metrics** (Robert C. Martin):
  - **Abstractness** `A = Σmₐ / (Σmₐ + Σm_c)` — ratio of abstract artifacts to all artifacts. A 5,000-line `main()` scores ~0.
  - **Instability** `I = Ce / (Ce + Ca)` — efferent over total coupling. Measures **volatility**: high instability breaks more easily when changed.
  - **Distance from the Main Sequence** `D = |A + I − 1|` — the one holistic structural metric. Both inputs are 0–1, so the ideal relationship is a line; distance from it measures balance.
    - **Zone of Uselessness** (upper right): too abstract to use.
    - **Zone of Pain** (lower left): too much implementation, not enough abstraction — brittle and hard to maintain.
  - When to use: analyzing an unfamiliar code base, preparing a migration, or assessing technical debt.

- **LCOM (Lack of Cohesion in Methods)** — from the **Chidamber and Kemerer Object-Oriented Metrics Suite**.
  - Best plain-English definition: *"the sum of sets of methods not shared via sharing fields."*
  - How to read: a class with private fields `a` and `b` where many methods touch only `a` and many touch only `b` scores high LCOM → poor cohesion; the field/method pairs could each be their own class.
  - Use: finds **incidentally coupled** classes that should never have been one class — especially shared utility classes, a notorious headache during migrations.
  - Limitation: it detects only *structural* lack of cohesion; it cannot judge whether pieces belong together logically. (Second Law again: *why* is more important than *how*.)

- **Connascence** (Meilir Page-Jones, *What Every Programmer Should Know about Object-Oriented Design*, 1996) — **not a metric but a language**. Two components are connascent if a change in one requires the other to change to preserve system correctness.

  **Static connascence** (source-code level), weakest → strongest:

  | Type | Definition | Typical smell |
  |---|---|---|
  | **Connascence of Name** | Components must agree on an entity's name | Most common *and most desirable* — modern refactoring tools make renames trivial |
  | **Connascence of Type** | Components must agree on an entity's type | Static typing; also selective typing (Clojure Spec) |
  | **Connascence of Meaning** (a.k.a. Convention) | Components must agree on the meaning of values | Hardcoded numbers instead of constants — `int TRUE = 1; int FALSE = 0` |
  | **Connascence of Position** | Components must agree on the *order* of values | `updateSeat("14D", "Ford, N")` against `updateSeat(String name, String seatLocation)` — types correct, semantics wrong |
  | **Connascence of Algorithm** | Components must agree on a particular algorithm | A security hash that must produce identical results on client and server |

  **Dynamic connascence** (runtime), weakest → strongest:

  | Type | Definition | Typical smell |
  |---|---|---|
  | **Connascence of Execution** | Order of execution matters | Calling `email.send()` before `email.setSubject()` |
  | **Connascence of Timing** | Timing of execution matters | Race condition between two threads |
  | **Connascence of Values** | Several values must change together | Four corner points of a rectangle; a value spanning separate databases in a distributed transaction |
  | **Connascence of Identity** | Components must reference the *same* entity | Two components sharing and updating a distributed queue |

- **The three connascence properties** — use these to judge severity:
  - **Strength**: how easily a developer can refactor the coupling. Prefer **static over dynamic** (static is visible to source analysis and trivially improved by tooling).
  - **Locality**: how proximal the modules are. Strong connascence *inside* one module is far less damaging than the same connascence across modules. (Page-Jones anticipated DDD's **bounded context** — limit implementation coupling scope, Ch 7.)
  - **Degree**: the size of the blast radius — few classes or many. High dynamic connascence across few modules is survivable; code bases grow, so small problems become big ones.
  - *Always consider strength and locality together.*

- **Page-Jones's three guidelines** for improving modularity:
  1. Minimize overall connascence by breaking the system into encapsulated elements.
  2. Minimize any remaining connascence that crosses encapsulation boundaries.
  3. Maximize connascence *within* encapsulation boundaries.

- **Jim Weirich's two rules** (from *"Connascence Examined"*, 2012):
  - **Rule of Degree**: convert strong forms of connascence into weaker forms.
  - **Rule of Locality**: as the distance between software elements increases, use weaker forms of connascence.

## Key Concepts

- **Modularity** — a *logical* grouping of related code (classes, functions, package, namespace). Logical, not necessarily physical, separation.
- **Granularity** — the size of a decomposed piece.
- **Cohesion** — the extent to which a module's parts belong in the same module.
- **Namespace** — a mechanism giving software assets precise, fully qualified names to avoid conflicts.
- **Essential complexity** — the code is complex because the problem is complex.
- **Accidental complexity** — the code is more complex than it needs to be.
- **Component** — what most architects call a module; the key building block of software architecture (Ch 8).
- **Ubiquitous language** — DDD's practice of agreeing on shared terminology, recommended as the antidote to the industry's ambiguous vocabulary.

## Mental Models

- **Software tends toward entropy; order requires energy.** Systems model complex systems, which tend toward disorder. Structural soundness *never happens by accident* — architects must constantly spend energy on it.
- **Modularity is the archetypal implicit characteristic.** Virtually no requirements document asks for good modular distinction, yet sustainable code bases require it.
- **Connascence is to coupling what design patterns are to design** — a compressed vocabulary. In a code review, "You have Connascence of Meaning; refactor it to Connascence of Name" is faster and more precise than "don't put a magic string in the middle of a method."
- **Refactor down the connascence ladder.** Every improvement is a move toward a weaker form: magic value (Meaning) → named constant (Name).
- **Metrics need interpretation.** Cyclomatic Complexity can't distinguish essential from accidental complexity. Establish *baselines* so you can tell which kind your code base has, then enforce them with fitness functions (Ch 6).

## Worked Example

**Is `Customer Maintenance` cohesive?** Consider a module:

```
Customer Maintenance
  add customer
  update customer
  get customer
  notify customer
  get customer orders
  cancel customer orders
```

Should the last two live here, or split out?

```
Customer Maintenance          Order Maintenance
  add customer                  get customer orders
  update customer               cancel customer orders
  get customer
  notify customer
```

*Which is correct?* **It depends** — resolve it with three questions:

1. **Are these the only two operations for `Order Maintenance`?** If so, collapse them back into `Customer Maintenance` — a two-operation module isn't worth the boundary.
2. **Is `Customer Maintenance` expected to grow much larger?** If so, look for behavior to extract now.
3. **Does `Order Maintenance` need so much `Customer` knowledge that separating them requires a high degree of coupling to stay functional?** If yes, don't split — this is Constantine's warning: dividing a cohesive module only increases coupling and decreases readability.

**The lesson**: cohesion is a *less precise* metric than coupling and often comes down to architect discretion. These three questions are the trade-off analysis at the heart of the job.

## Anti-patterns

- **Spaghetti Architecture, Distributed Monolith, Big Ball of Distributed Mud** — all granularity failures, not modularity failures. Avoid by watching granularity and the overall coupling level between services and components.
- **Coincidental cohesion** — elements share a source file and nothing else.
- **Shared utility classes** (`StringUtils`-style grab bags) — logically cohesive at best, incidentally coupled at worst; the classic blocker when splitting an architecture. Find them with LCOM.
- **Loose partitioning inside a monolith** — lumping classes together is convenient until you need to break the monolith apart, at which point the encouraged coupling blocks you.
- **Over-abstraction** (`AbstractSingletonProxyFactoryBean`) — the Zone of Uselessness; too many layers and an ambiguous name.

## Historical Context (why so many separation schemes exist)
Dijkstra's *"Go To Statement Considered Harmful"* (CACM, March 1968) ushered in **structured** languages (Pascal, C) in the mid-1970s. Developers found no good way to group things logically, producing the short **modular** era of the mid-1980s (Modula, Ada) — packages/namespaces without classes. Object-oriented languages then displaced it, but language designers kept modules as packages and namespaces. Modern languages therefore carry overlapping paradigms (Java has modular, OO, and functional scoping rules, each with quirks). *Backward compatibility here is of how developers think, not of code.*

## Key Takeaways
1. Treat modularity as an implicit characteristic you must actively defend; entropy is the default.
2. Diagnose failed decompositions as *granularity* problems and check coupling levels between the pieces.
3. Use LCOM to find incidentally coupled classes before a migration — especially shared utility classes.
4. Track Distance from the Main Sequence to keep code out of the Zone of Pain and the Zone of Uselessness.
5. Adopt connascence as your vocabulary for coupling; it turns vague code-review advice into a named refactoring.
6. Apply Weirich's rules: convert strong connascence to weak (Degree), and use weaker forms as elements get further apart (Locality).
7. Maximize connascence *inside* boundaries, minimize it *across* them.
8. Never read a metric without interpreting it; establish baselines instead.

## Connects To
- **Ch 1**: modularity as an implicit architecture characteristic; the Second Law explains LCOM's limits.
- **Ch 6**: governance and fitness functions — automating metric baselines (Cyclomatic Complexity, ArchUnit).
- **Ch 7**: DDD's bounded context — the modern restatement of connascence *locality*.
- **Ch 8**: from modules to components; deriving components from the problem domain.
- **Ch 18**: microservices — where granularity mistakes become distributed monoliths.
