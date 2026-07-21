---
name: design-patterns-book
description: "Knowledge base from \"Design Patterns: Elements of Reusable Object-Oriented Software\" by Gamma, Helm, Johnson & Vlissides (the Gang of Four). Use when choosing or applying a design pattern, refactoring toward one, reasoning about object composition vs inheritance, decoupling classes, or referencing any of the 23 GoF patterns and their trade-offs."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [pattern name, topic, or chapter number] -->

# Design Patterns: Elements of Reusable Object-Oriented Software
**Authors**: Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides | **Pages**: ~395 | **Patterns**: 23 | **Generated**: 2026-07-22

## How to Use This Skill

- **Without arguments** — load the core design principles and the pattern-selection tables below
- **With a pattern name** — ask about `Visitor` or `Flyweight`; I read that pattern's file
- **With a topic** — `undo`, `platform independence`, `class explosion`; I use the Topic Index
- **With a chapter** — `ch01`, `ch02`, `ch06` for the narrative chapters
- **Browse** — ask "what patterns do you have?"

When you ask about something not covered below, I read the relevant chapter file first.

---

## Core Principles

**1. Program to an interface, not an implementation.**
Declare variables as the abstract type. Clients stay unaware of the concrete classes and of the classes implementing them. Creational patterns exist to keep the one place that *must* name a concrete class contained.

**2. Favor object composition over class inheritance.**
Inheritance is *white-box reuse* — fixed at compile time, breaks encapsulation, and a subclass explosion is its failure mode. Composition is *black-box reuse* — assembled at run time, keeps each class focused. Most of the catalog is composition escaping an inheritance trap.

**3. Encapsulate what varies.** Every pattern isolates one axis of change. Identify the axis first; the pattern follows from it (see the table in `cheatsheet.md`).

**4. Design for change, not for the current requirements.** Redesign is triggered by specific causes — naming concrete classes at construction, depending on a specific operation, platform, representation, or algorithm, tight coupling, extension-by-subclassing, and unmodifiable classes. Each maps to patterns; see the Redesign table in `cheatsheet.md`.

**5. Don't apply a pattern until you need the flexibility.** Patterns buy variation with **indirection**, paid for in complexity and often performance. Read **Applicability** and **Consequences** before committing — those sections, not the structure diagram, are the pattern's real content.

## Classification: Purpose × Scope

|  | Creational | Structural | Behavioral |
|---|---|---|---|
| **Class** *(inheritance, compile-time)* | Factory Method | Adapter (class) | Interpreter, Template Method |
| **Object** *(composition, run-time)* | Abstract Factory, Builder, Prototype, Singleton | Adapter (object), Bridge, Composite, Decorator, Facade, Flyweight, Proxy | Chain of Responsibility, Command, Iterator, Mediator, Memento, Observer, State, Strategy, Visitor |

**Creational** — defer and abstract *which class gets instantiated*.
**Structural** — compose classes and objects into larger structures.
**Behavioral** — assign responsibility and encode the flow of control between objects.

## Selecting a Pattern — three routes

1. **By what varies** — the single most useful table in the book (Table 1.2, reproduced in `cheatsheet.md`). Name the aspect you want free to change; it names the pattern.
2. **By cause of redesign** — start from the change you fear, not the structure you want.
3. **By intent** — scan the Intent lines; then check *Related Patterns* to see the neighbors you're choosing against.

## Distinctions That Matter Most

- **Adapter vs. Bridge** — retrofitting an existing interface vs. designing two hierarchies to vary independently from the start.
- **Composite vs. Decorator vs. Proxy** — all recursive composition over one interface, but: aggregate for uniform treatment / add responsibilities / control access.
- **Decorator vs. Strategy** — change the **skin** vs. change the **guts**.
- **State vs. Strategy** — behavior tied to internal state, with transitions, vs. an algorithm the client picks.
- **Template Method vs. Strategy** — vary steps by **inheritance** vs. vary the whole algorithm by **delegation**.
- **Facade vs. Mediator** — unidirectional simplification (subsystem doesn't know) vs. bidirectional coordination (colleagues talk back).
- **Factory Method vs. Abstract Factory vs. Prototype** — a new Creator subclass / a new factory object / a `Clone()` on the product.
- **Visitor vs. Iterator** — vary *what you do at each node* vs. vary *how you traverse*.

## Applying a Pattern (§1.8)
Read it (Applicability + Consequences first) → study Structure/Participants/Collaborations → study Sample Code → rename participants for your domain but keep the pattern name visible (`TeXLayoutStrategy`) → define classes and inheritance → name operations from responsibilities, consistently (`Create-` prefix for factory methods) → implement using the Implementation hints.

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-introduction.md) | Introduction | Four essential elements, Purpose×Scope classification, program to an interface, favor composition, causes of redesign, toolkit vs framework, delegation |
| [ch02](chapters/ch02-case-study-lexi.md) | A Case Study: Designing a Document Editor (Lexi) | Glyph/recursive composition, transparent enclosure, 7 design problems → 8 patterns |
| **Ch 3** | **Creational Patterns** | |
| [ch03a](chapters/ch03a-abstract-factory.md) | Abstract Factory | Kit, product families, extensible factories |
| [ch03b](chapters/ch03b-builder.md) | Builder | Director/Builder, step-by-step construction |
| [ch03c](chapters/ch03c-factory-method.md) | Factory Method | Virtual Constructor, parameterized factory method |
| [ch03d](chapters/ch03d-prototype.md) | Prototype | Clone, prototype manager, deep vs shallow copy |
| [ch03e](chapters/ch03e-singleton.md) | Singleton | Instance operation, registry of singletons |
| **Ch 4** | **Structural Patterns** | |
| [ch04a](chapters/ch04a-adapter.md) | Adapter | Wrapper, class vs object adapter, two-way adapter |
| [ch04b](chapters/ch04b-bridge.md) | Bridge | Handle/Body, abstraction vs implementor hierarchies |
| [ch04c](chapters/ch04c-composite.md) | Composite | Part-whole hierarchy, transparency vs safety |
| [ch04d](chapters/ch04d-decorator.md) | Decorator | Transparent enclosure, dynamic responsibilities |
| [ch04e](chapters/ch04e-facade.md) | Facade | Subsystem interface, layering |
| [ch04f](chapters/ch04f-flyweight.md) | Flyweight | Intrinsic vs extrinsic state, flyweight pool |
| [ch04g](chapters/ch04g-proxy.md) | Proxy | Remote / virtual / protection / smart reference |
| **Ch 5** | **Behavioral Patterns** | |
| [ch05a](chapters/ch05a-chain-of-responsibility.md) | Chain of Responsibility | Successor link, implicit receiver |
| [ch05b](chapters/ch05b-command.md) | Command | Undo/redo history, MacroCommand |
| [ch05c](chapters/ch05c-interpreter.md) | Interpreter | Abstract syntax tree, one class per grammar rule |
| [ch05d](chapters/ch05d-iterator.md) | Iterator | External vs internal, robust iterators, IteratorPtr |
| [ch05e](chapters/ch05e-mediator.md) | Mediator | DialogDirector, colleague decoupling |
| [ch05f](chapters/ch05f-memento.md) | Memento | Wide vs narrow interface, incremental mementos |
| [ch05g](chapters/ch05g-observer.md) | Observer | Push vs pull, ChangeManager, MVC |
| [ch05h](chapters/ch05h-state.md) | State | State objects, transition ownership |
| [ch05i](chapters/ch05i-strategy.md) | Strategy | Algorithm family, eliminating conditionals |
| [ch05j](chapters/ch05j-template-method.md) | Template Method | Hook operations, Hollywood Principle |
| [ch05k](chapters/ch05k-visitor.md) | Visitor | Double dispatch, Accept/Visit |
| [ch06](chapters/ch06-conclusion.md) | Conclusion | Common design vocabulary, patterns as refactoring targets, lifecycle phases |

## Topic Index

- **Abstract coupling** → ch01, ch03a, ch04b
- **Algorithm variation** → ch05i, ch05j, ch03b, ch05d, ch05k
- **Callbacks / functors** → ch05b
- **Class explosion / subclass proliferation** → ch01, ch04b, ch04d, ch05i
- **Composition vs inheritance** → ch01, ch06
- **Conditional logic, eliminating** → ch05h, ch05i
- **Copying objects (deep/shallow)** → ch03d, ch05f
- **Delegation** → ch01, ch04b, ch05h, ch05i
- **Double dispatch** → ch05k
- **Framework design / inversion of control** → ch01, ch05j, ch03c
- **Global access / single instance** → ch03e
- **Grammar / parsing / DSL** → ch05c
- **GUI look-and-feel** → ch02, ch03a
- **Interface mismatch / legacy integration** → ch04a
- **Lazy initialization / on-demand creation** → ch03e, ch04g
- **Memory / storage optimization** → ch04f, ch04g
- **MVC** → ch01, ch05g
- **Object creation, decoupling** → ch03a, ch03b, ch03c, ch03d
- **Part-whole hierarchies / trees** → ch04c, ch02, ch05c
- **Platform independence / portability** → ch01, ch03a, ch04b
- **Recursive composition** → ch02, ch04c, ch04d
- **Refactoring** → ch06, ch01
- **Remote objects / distribution** → ch04g
- **Request handling, decoupling sender from receiver** → ch05a, ch05b
- **Snapshot / checkpoint state** → ch05f
- **Subsystem simplification / layering** → ch04e
- **Traversal** → ch05d, ch05k, ch04c
- **Undo / redo** → ch05b, ch05f
- **White-box vs black-box reuse** → ch01, ch06

## Supporting Files

- [cheatsheet.md](cheatsheet.md) — **start here for selection**: what-varies table, redesign-cause table, disambiguation matrix, tells and smells
- [patterns.md](patterns.md) — all 23 patterns as When / How / Trade-offs
- [glossary.md](glossary.md) — Appendix A terms plus catalog role names

---

## Scope & Limits

**Source caveat**: this skill was built from an EPUB in which the code listings, figures,
and Tables 1.1/1.2/2.1–2.3 are **images**, so they did not extract as text. The prose,
Intent, Applicability, Consequences, Implementation, Known Uses, and Related Patterns
sections are faithful to the source. The C++/Smalltalk snippets in the chapter files were
**reconstructed from the surrounding prose**, not transcribed — treat them as illustrative
of the mechanism, not as verbatim book code. Check the book for exact listings.

Covers the 1994 GoF book only. Examples are C++ and Smalltalk; the *structural* advice
translates directly, but some patterns (Iterator, Command, Strategy, Prototype, Singleton)
have first-class language support today — check whether your language already provides it
before hand-rolling the pattern. The book predates generics-heavy, functional, and
concurrent idioms; it says nothing about thread safety. For pattern-directed refactoring
of existing code, pair with Fowler's *Refactoring*.
