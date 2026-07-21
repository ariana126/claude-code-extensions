---
name: clean-code-book
description: "Knowledge base from \"Clean Code: A Handbook of Agile Software Craftsmanship\" by Robert C. Martin. Use when applying Martin's frameworks for naming, function design, comments, error handling, unit tests/TDD, classes and SRP, boundaries, concurrency, refactoring, and the code smells and heuristics catalog, studying the book, or referencing its concepts."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, heuristic code (e.g. G30), or chapter number] -->

# Clean Code: A Handbook of Agile Software Craftsmanship
**Author**: Robert C. Martin (with Brett L. Schuchert) | **Pages**: ~180 | **Chapters**: 17 + Appendix A | **Generated**: 2026-07-21

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `naming`, `function size`, `error handling`, `concurrency`; I find and read the relevant chapter
- **With a heuristic code** — ask for `G30` or `N5`; the full catalog lives in [ch17](chapters/ch17-smells-and-heuristics.md)
- **With a chapter** — ask for `ch05`; I load that specific chapter
- **Browse** — ask "what chapters do you have?"

When you ask about a topic not covered in Core Frameworks below, I will read the relevant chapter file before answering.

---

## Core Frameworks & Mental Models

**The Boy Scout Rule** — Leave the campground cleaner than you found it. Every check-in, one small cleanup: rename a variable, split a function, kill one duplication. This is the engine of the whole book; large cleanups never get scheduled.

**LeBlanc's Law** — *Later equals never.* When tempted to defer cleanup, treat the deferral as permanent, because the pressure never abates. Schedule pressure is not a reason to make a mess: the mess slows you down *immediately*, so cleanliness is the only way to hit the date.

**The reading:writing ratio is well over 10:1** — Therefore optimize for reading, always. When easier-to-write conflicts with easier-to-read, read wins.

**Four Rules of Simple Design** (Kent Beck's priority order — earlier rules win conflicts):
1. Runs all the tests
2. Contains no duplication
3. Expresses the intent of the programmer
4. Minimizes the number of classes and methods

Never trade tests, duplication removal, or expressiveness for a lower class count.

**Functions: Small! and Do One Thing** — Functions should hardly ever be 20 lines; blocks inside `if`/`else`/`while` are one line — a function call. Indent level no more than one or two. The test for "one thing": every statement sits exactly one level below the function's name (the **TO paragraph** test — "TO *X*, we do these steps…"). If you can extract a function whose name isn't a restatement of its implementation, the original did more than one thing.

**The Stepdown Rule** — Every function is followed by those at the next level of abstraction, so the file reads top-down like prose.

**Command Query Separation** — A function either changes state or answers a question, never both.

**Arguments**: 0 > 1 > 2; avoid 3; 4+ needs special justification and still shouldn't be used. **Never pass a flag argument** — a boolean proves the function does two things; split it into two named functions.

**Meaningful Names** — If a name requires a comment, the name failed. Name length tracks scope length. Classes are noun phrases (never `Manager`/`Processor`/`Data`/`Info`); methods are verb phrases. Pick one word per concept and don't pun. Leave interfaces unadorned (`ShapeFactory`, not `IShapeFactory`). No Hungarian notation, no `m_`.

**Comments are always failures** — Before writing one, try a function name, then an explanatory variable; keep the comment only if both fail. Don't comment bad code — rewrite it. Comments that say **WHY** survive; comments that say **WHAT** rot. Delete commented-out code on sight.

**Data/Object Anti-Symmetry** — Objects hide data and expose behavior; data structures expose data and have no behavior. Objects make adding new *types* easy and new *functions* hard; data structures the reverse. Choose by which axis of change dominates. Never build a hybrid.

**The Law of Demeter** — Method `f` of class `C` may call methods only on `C`, on objects `f` creates, on `f`'s arguments, and on `C`'s instance variables — never on objects *returned* by those. When you find a train wreck (`a.getB().getC()`), ask what the value was for and push that intent onto the outer object. Demeter doesn't apply to data structures.

**Error Handling** — Use exceptions, not return codes. Write the try-catch-finally first, driven by a test that expects the exception. Prefer **unchecked** exceptions in application development (checked exceptions violate OCP and cascade through signatures). Define exceptions in terms of a caller's needs. **Never return null; never pass null** — use a Special Case object or an empty collection.

**Boundaries** — Wrap third-party APIs behind your own type and never pass boundary interfaces around the system. Write **learning tests** to check your understanding of a library; they cost nothing and become release-compatibility checks.

**The Three Laws of TDD** — (1) No production code until a failing test exists; (2) no more test than is sufficient to fail; (3) no more production code than passes the current test. Cycle ≈ 30 seconds.

**F.I.R.S.T.** — Tests must be **F**ast, **I**ndependent, **R**epeatable, **S**elf-validating, **T**imely. One *concept* per test is the firm rule; one assert per test is a guideline. Test code is as important as production code — dirty tests are equal to or worse than none.

**Classes: SRP and Cohesion** — Measure class size in *responsibilities*, not lines. If you can't derive a concise class name, it's too large; if the ~25-word description needs "and", it has too many responsibilities. When cohesion is lost (instance variables serving only a subset of methods), split. Apply **OCP** (extend by subclassing) and **DIP** (depend on abstractions).

**Separate Constructing a System from Using It** — Move all construction to `main` or a DI container; write the rest of the system assuming objects are already wired. `if (x == null) x = new Impl()` in runtime code is the tell. Postpone decisions to the last possible moment.

**Concurrency: SRP for threads** — Keep concurrency code separate; it has its own life cycle and failure modes. Severely limit shared data; prefer copies. Keep synchronized sections as small as the true critical section. Know your library and your execution models (Producer-Consumer, Readers-Writers, Dining Philosophers). Choose exactly one of Client-Based Locking, Server-Based Locking, or Adapted Server.

**Successive Refinement** — To write clean code, first write dirty code, then clean it. When you can see the next feature would leave an unfixable mess, stop adding features and refactor now. Never make massive structural changes — make a large number of very tiny changes, each keeping all tests green. Judge a refactor by the cost of the *next* change.

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-clean-code.md) | Clean Code | Boy Scout Rule, LeBlanc's Law, Primal Conundrum, Grand Redesign in the Sky |
| [ch02](chapters/ch02-meaningful-names.md) | Meaningful Names | Intention-Revealing Names, Avoid Disinformation, Searchable Names, One Word per Concept |
| [ch03](chapters/ch03-functions.md) | Functions | Small!, Do One Thing, Stepdown Rule, Command Query Separation, Argument Objects |
| [ch04](chapters/ch04-comments.md) | Comments | Good/Bad Comments taxonomies, Explain Yourself in Code |
| [ch05](chapters/ch05-formatting.md) | Formatting | Newspaper Metaphor, Vertical Distance, Vertical Ordering, Team Rules |
| [ch06](chapters/ch06-objects-and-data-structures.md) | Objects and Data Structures | Data Abstraction, Data/Object Anti-Symmetry, Law of Demeter |
| [ch07](chapters/ch07-error-handling.md) | Error Handling | Try-Catch-Finally First, Unchecked Exceptions, Special Case Pattern, Define Normal Flow |
| [ch08](chapters/ch08-boundaries.md) | Boundaries | Wrapping, Learning Tests, The Interface We Wish We Had, ADAPTER |
| [ch09](chapters/ch09-unit-tests.md) | Unit Tests | Three Laws of TDD, F.I.R.S.T., BUILD-OPERATE-CHECK, Single Concept per Test |
| [ch10](chapters/ch10-classes.md) | Classes | Single Responsibility Principle, Cohesion, OCP, DIP, Class Organization |
| [ch11](chapters/ch11-systems.md) | Systems | Separate Constructing from Using, Dependency Injection, Cross-Cutting Concerns, AOP, DSLs |
| [ch12](chapters/ch12-emergence.md) | Emergence | Four Rules of Simple Design, Template Method, refactoring discipline |
| [ch13](chapters/ch13-concurrency.md) | Concurrency | SRP for threads, Execution Models, Client/Server-Based Locking, Testing Threaded Code |
| [ch14](chapters/ch14-successive-refinement.md) | Successive Refinement | Successive Refinement, On Incrementalism, ArgumentMarshaler extraction |
| [ch15](chapters/ch15-junit-internals.md) | JUnit Internals | Heuristic-cited refactoring, explanatory predicates, temporal coupling |
| [ch16](chapters/ch16-refactoring-serialdate.md) | Refactoring SerialDate | First Make It Work Then Make It Right, coverage-driven refactoring, Enum absorption |
| [ch17](chapters/ch17-smells-and-heuristics.md) | Smells and Heuristics | **Full catalog: C1–C5, E1–E2, F1–F4, G1–G36, J1–J3, N1–N7, T1–T9** |
| [appA](chapters/appendix-a-concurrency-ii.md) | Appendix A: Concurrency II | Locking strategies, atomicity/bytecode interleaving, Executor, Future, CAS |

## Topic Index

- **Abstraction levels** → ch03, ch17 (G34, G6)
- **Aspects / AOP** → ch11
- **Arguments (function)** → ch03, ch17 (F1)
- **Boundaries / third-party code** → ch08
- **Boy Scout Rule** → ch01, ch15
- **Classes / class size** → ch10, ch16
- **Code smells catalog** → ch17
- **Cohesion** → ch10, ch12
- **Comments** → ch04, ch17 (C1–C5)
- **Concurrency** → ch13, appA
- **Coverage tools** → ch16, ch17 (T2)
- **Deadlock / livelock / starvation** → ch13, appA
- **Dependency Injection** → ch11
- **Dependency Inversion Principle** → ch10, ch12
- **Duplication / DRY** → ch03, ch12, ch17 (G5)
- **Encapsulation** → ch06, ch10
- **Enums** → ch16, ch17 (J3)
- **Error handling / exceptions** → ch07, ch03
- **Formatting / file length / line width** → ch05
- **Four Rules of Simple Design** → ch12, ch01
- **Functions** → ch03, ch17 (F1–F4, G30, G34)
- **Law of Demeter** → ch06, ch17 (G36)
- **Learning tests** → ch08
- **Naming** → ch02, ch17 (N1–N7)
- **Null handling** → ch07
- **Objects vs data structures** → ch06
- **Open-Closed Principle** → ch10, ch07
- **Polymorphism vs switch** → ch03, ch17 (G23)
- **Refactoring (case studies)** → ch14, ch15, ch16
- **Single Responsibility Principle** → ch10, ch13, ch12
- **Special Case Pattern** → ch07
- **Systems / architecture** → ch11
- **TDD** → ch09, ch12, ch14
- **Template Method** → ch12
- **Testing** → ch09, ch17 (T1–T9), ch16
- **Threading models** → ch13, appA
- **Train wrecks** → ch06, ch17 (G36)

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions and chapter references
- [patterns.md](patterns.md) — every concrete technique, executable step by step
- [cheatsheet.md](cheatsheet.md) — thresholds, decision rules, and a tells-and-smells table

---

## Scope & Limits

Covers the book's content only. Examples are Java (2008-era); the principles generalize, but idioms like checked-exception advice and `java.util.concurrent` specifics are language- and version-bound. For applying these to a specific codebase, combine with project tooling. Martin's stricter positions (function length, comment avoidance, checked exceptions) are opinions from the Object Mentor school, not universal consensus — apply judgment.
