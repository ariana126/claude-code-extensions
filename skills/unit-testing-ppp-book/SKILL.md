---
name: unit-testing-ppp-book
description: "Knowledge base from \"Unit Testing Principles, Practices, and Patterns\" by Vladimir Khorikov. Use when applying Khorikov's frameworks for test quality evaluation, mocking decisions, observable behavior vs implementation details, integration testing, database testing, functional architecture, or unit testing anti-patterns."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, or chapter number] -->

# Unit Testing Principles, Practices, and Patterns
**Author**: Vladimir Khorikov | **Publisher**: Manning, 2020 | **Chapters**: 11 (4 parts) | **Generated**: 2026-07-20

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `mocking`, `four pillars`, `functional architecture`, or another indexed topic; I find and read the relevant chapter
- **With a chapter** — ask for `ch05`; I load that specific chapter
- **Browse** — ask "what chapters do you have?" to see the full index

When you ask about a topic not covered in Core Frameworks below, I will read the relevant chapter file before answering.

---

## Core Frameworks & Mental Models

### The Four Pillars of a Good Unit Test (Ch 4) — the frame of reference for everything
Score any automated test on four attributes, then **multiply** them: `Value = [0..1] × [0..1] × [0..1] × [0..1]`. A zero anywhere zeroes the test.

1. **Protection against regressions** — how well it indicates the *presence* of bugs. Guards against false negatives. A function of how much code executes, its complexity, and its domain significance.
2. **Resistance to refactoring** — how well it survives refactoring without failing. Guards against false positives.
3. **Fast feedback** — execution speed.
4. **Maintainability** — how hard it is to understand (size) and to run (out-of-process dependencies).

**The first three are mutually exclusive — you get two of three, like CAP.** But **resistance to refactoring is non-negotiable**: it's essentially binary, so you can't concede a little, you lose it all. Max out resistance to refactoring and maintainability; slide the trade-off between protection and speed.

*Eradicating brittleness (false positives) is the first priority on the path to a robust test suite.*

### Observable Behavior vs. Implementation Details (Ch 5) — the root cause of brittleness
Code is part of **observable behavior** only if it does one of these:
- Exposes an **operation** that helps the client achieve one of its **goals**
- Exposes **state** that helps the client achieve one of its goals

Everything else is an implementation detail. **This depends on who the client is** — for a domain class the client is an application service; for an application service it's the external caller.

**False positives have exactly one cause: coupling to implementation details.** The cure is to verify the *end result*, never the steps taken to produce it.

- *Well-designed code*: observable behavior = public API; implementation details are private.
- **Rule of thumb**: if the client needs more than one operation to achieve a single goal, the class is likely leaking implementation details.
- **Think in onion layers**: test each layer from the outer layer's point of view, disregarding how it talks to layers beneath.

### The Mocking Decision (Ch 5, 8, 9)
**Mock unmanaged dependencies only, at the very edges of your system.**

- **Managed dependency** (your own database — nobody else accesses it) → communications are **implementation details** → use the **real instance**, verify **final state**.
- **Unmanaged dependency** (message bus, SMTP, third-party API) → communications are **observable behavior** requiring backward compatibility → **mock it**, verify **interactions**.
- **Intra-system** (class ↔ class inside your app) → **never mock**.
- **Never assert interactions with stubs** — a stub call is a means, not an end.
- **Mock the last type in the chain** before the call leaves your application, so you verify the actual payload rather than a call to your own class.
- **Mocks belong in integration tests only.** A mock in a unit test means your domain model touched something it shouldn't.
- Verify **both** the existence of expected calls and the absence of unexpected ones.

Mocks and stubs map onto CQS: **commands → mocks**, **queries → stubs**.

### The Four Types of Code (Ch 7) — where to spend testing effort
Classify on **complexity/domain significance** × **number of collaborators**:

| | Few collaborators | Many collaborators |
|---|---|---|
| **High complexity/significance** | **Domain model & algorithms** → unit test heavily | **Overcomplicated** → refactor out of existence |
| **Low complexity/significance** | Trivial code → don't test | Controllers → integration tests, briefly |

**The more important or complex the code, the fewer collaborators it should have.** Code can be *deep* (complex) or *wide* (many collaborators), never both. Split overcomplicated code using the **Humble Object pattern**: extract the logic, leaving a wrapper so humble it needs no tests.

### Definitions That Drive Everything (Ch 1, 2)
- **The goal of unit testing is to enable sustainable growth of the software project.** Not finding bugs, not better design.
- **A unit test verifies a single unit of behavior, does it quickly, and does it in isolation from other tests.** An integration test is any test failing one of those.
- **Test units of behavior, not units of code.** A test should tell a story meaningful to a non-programmer. *"When I call my dog, he comes right to me"* — not a description of which legs moved.
- **Code is a liability, not an asset** — and test code is code.
- **Testability and coverage are good negative indicators and bad positive ones.** Low coverage reliably signals trouble; high coverage means nothing. **Never mandate a coverage number.**

### Testing Styles, in Preference Order (Ch 6)
**Output-based** (feed input, check output) > **state-based** (verify final state) > **communication-based** (verify mock interactions). Output-based only works on **mathematical functions** — methods with no hidden inputs or outputs (side effects, exceptions, and references to internal/external state are all hidden).

Get more code into that category with **functional architecture**: a **functional core** that makes decisions (pure, no collaborators) wrapped in a **mutable shell** that gathers inputs and applies side effects. Read → decide → act. *Functional architecture is hexagonal architecture taken to an extreme* — the difference is whether the domain layer may produce side effects at all.

**The cost is real**: functional architecture concedes performance (you must read everything up front) and initial code size for maintainability. Apply it strategically.

### Writing Tests Well (Ch 3, 11)
- **AAA everywhere.** A >1-line act section signals broken encapsulation; a bloated assert signals a missing abstraction.
- **Name tests as plain-English facts** a domain expert would recognize. No rigid `Method_Scenario_Result` policy, no method-under-test in the name, `is` rather than `should be`.
- **Reuse fixtures via private factory methods**, never the constructor (which couples every test in the class).
- **Tests get no special privileges.** Never expose private methods or state for testing. If a private method resists indirect testing, you have dead code or a missing abstraction.
- **Never reimplement the algorithm in the test.** Hardcode results precalculated outside the SUT.
- **Write black-box, analyze white-box.** If you can't trace a test to a business requirement, it's brittle.

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-goal-of-unit-testing.md) | The Goal of Unit Testing | Sustainable growth, cost–benefit analysis, good negative indicator, successful suite attributes |
| [ch02](chapters/ch02-what-is-a-unit-test.md) | What Is a Unit Test? | Three attributes of a unit test, classical vs. London schools, dependency hierarchy, units of behavior |
| [ch03](chapters/ch03-anatomy-of-a-unit-test.md) | The Anatomy of a Unit Test | AAA, section size as design signal, plain-English naming, parameterized tests |
| [ch04](chapters/ch04-four-pillars.md) | The Four Pillars of a Good Unit Test | Four pillars, multiplication rule, accuracy matrix, Test Pyramid, black-box vs. white-box |
| [ch05](chapters/ch05-mocks-and-test-fragility.md) | Mocks and Test Fragility | Mocks vs. stubs, CQS, observable behavior definition, hexagonal architecture, intra/inter-system |
| [ch06](chapters/ch06-styles-of-unit-testing.md) | Styles of Unit Testing | Three testing styles, mathematical functions, referential transparency, functional architecture |
| [ch07](chapters/ch07-refactoring-toward-valuable-tests.md) | Refactoring Toward Valuable Unit Tests | Four types of code, Humble Object, CanExecute/Execute, domain events, three-attribute trade-off |
| [ch08](chapters/ch08-why-integration-testing.md) | Why Integration Testing? | Managed vs. unmanaged dependencies, Fail Fast, YAGNI on interfaces, support vs. diagnostic logging |
| [ch09](chapters/ch09-mocking-best-practices.md) | Mocking Best Practices | Verify at system edges, spies, mock only types you own, verifying call counts |
| [ch10](chapters/ch10-testing-the-database.md) | Testing the Database | Migration-based delivery, unit of work, per-section contexts, clean-at-start, Object Mother |
| [ch11](chapters/ch11-unit-testing-anti-patterns.md) | Unit Testing Anti-patterns | Private methods/state, domain knowledge leakage, code pollution, mocking concrete classes, time |

## Topic Index

- **AAA / Arrange-Act-Assert** → ch03
- **Ambient context** → ch08, ch11
- **Anti-patterns** → ch11
- **Black-box vs. white-box testing** → ch04
- **CanExecute/Execute** → ch07
- **Classical vs. London schools** → ch02, ch05, ch06
- **Code pollution** → ch06, ch11
- **Collaborators vs. values** → ch02, ch06, ch07
- **Coverage metrics** → ch01
- **CQS (command query separation)** → ch05
- **Cyclomatic complexity** → ch07
- **Database testing** → ch08, ch10
- **Domain events** → ch07, ch08
- **Encapsulation** → ch03, ch05, ch06
- **End-to-end tests** → ch02, ch04, ch08
- **Fail Fast principle** → ch08
- **False positives / negatives** → ch04
- **Four pillars** → ch04, ch06
- **Functional architecture** → ch06, ch07
- **Hexagonal architecture** → ch05, ch06
- **Humble Object pattern** → ch07, ch11
- **Integration tests** → ch02, ch04, ch08, ch10
- **Interfaces (when to introduce)** → ch08, ch09, ch11
- **Logging** → ch08, ch09
- **Managed vs. unmanaged dependencies** → ch08, ch09, ch10
- **Mathematical functions / pure functions** → ch06
- **Migrations (database)** → ch10
- **Mocks vs. stubs** → ch05
- **Mocking best practices** → ch05, ch08, ch09
- **Naming tests** → ch03
- **Object Mother / Test Data Builder** → ch03, ch10
- **Observable behavior** → ch04, ch05, ch07
- **Over-specification** → ch02, ch05
- **Parameterized tests** → ch03
- **Preconditions** → ch07, ch08
- **Private methods / private state** → ch11
- **Refactoring (definition)** → ch04
- **Repositories** → ch10
- **Resistance to refactoring** → ch04, ch05, ch09
- **Shared vs. private dependencies** → ch02
- **Spies** → ch05, ch09
- **Structured logging** → ch08
- **Styles of unit testing** → ch06
- **Sustainable growth** → ch01
- **Tell-don't-ask** → ch05, ch07
- **Test doubles (five types)** → ch02, ch05
- **Test fixtures** → ch03, ch10
- **Test Pyramid** → ch04, ch08
- **Time (testing with)** → ch11
- **Trivial tests / tautology tests** → ch04
- **Types of code (four quadrants)** → ch07, ch08, ch10
- **Unit of behavior** → ch02, ch03, ch09
- **Unit of work** → ch10
- **Value objects** → ch02, ch06
- **YAGNI** → ch08

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions and chapter references
- [patterns.md](patterns.md) — every technique and design pattern, with when/how/trade-offs
- [cheatsheet.md](cheatsheet.md) — decision trees, thresholds, tells & smells, trade-off matrices

---

## Scope & Limits

This skill covers the book's content only. Code examples are C#/.NET (xUnit, Moq, Fluent Assertions, Entity Framework), but Khorikov states the concepts are non-language-specific and apply to any object-oriented language. For hands-on implementation in your codebase, combine with project-specific tools. The book predates 2020, so specific library APIs may have moved on; the principles have not.
