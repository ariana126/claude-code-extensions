---
name: bdd-in-action-book
description: "Knowledge base from \"BDD in Action: Behavior-Driven Development for the whole software lifecycle, 2nd Edition\" by John Ferguson Smart and Jan Molak. Use when applying BDD frameworks for requirements discovery, Gherkin and executable specifications, Cucumber automation, the Screenplay Pattern, acceptance test design, API and UI test automation, or living documentation."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, or chapter number] -->

# BDD in Action, 2nd Edition
**Authors**: John Ferguson Smart & Jan Molak | **Words**: ~152,000 | **Chapters**: 16 (3 parts) | **Generated**: 2026-07-20

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `example mapping`, `screenplay`, `page objects`, `gherkin anti-patterns`; I find and read the relevant chapter
- **With a chapter** — ask for `ch07`; I load that chapter file
- **Browse** — ask "what chapters do you have?" for the full index

When you ask about a topic not covered in Core Frameworks below, I will read the relevant chapter file before answering.

---

## Core Frameworks & Mental Models

### The BDD Flow — six phases (ch 3)
**Speculate** (goals → features) → **Illustrate** (conversations about examples) → **Formulate** (examples → executable specs) → **Automate** (specs → automated tests) → **Demonstrate** (passing tests as evidence and documentation) → **Validate** (do features deliver the promised value?). Continuous per feature, not a waterfall.

### Diagnose failure on two axes (ch 1)
*Not building the software right* (quality) and *not building the right software* (value) are **independent** failures with different cures. TDD fixes the first and does nothing for the second. ~45% of delivered features are never used.

### The Knowledge Constraint (ch 1)
Your binding constraint is not time, budget, or programmer hours — it's **lack of knowledge** about what to build and how. Signing off requirements after an analysis phase locks in the team's *most ignorant* understanding. Detailed planning has a ~3-month horizon.

### Every feature is a bet (ch 4)
State it as a hypothesis: *"We believe \<capability\> will result in \<outcome\>. We will know this is true when \<measurable result\>."* Then find the cheapest experiment that could disprove it — often with **no software at all**. Be willing to abandon.

### Pop the why stack (ch 4)
Stakeholders bring *solutions*, not problems. Ask why ≈5 times until you reach a business goal in one of four categories: increase revenue, reduce costs, protect revenue, avoid future costs. Two reasons this matters: requesters don't know your technical/UX/cost options — and **if you don't know why a feature exists, you can't tell whether it's still relevant when circumstances change.**

### Real Options + Deliberate Discovery (ch 5)
Options have value; options expire; **never commit early unless you know why.** The universal misreading: this is *not* "always delay." Delay only until you have enough information, **then act as fast as you can.** Meanwhile, Deliberate Discovery says ignorance is the constraint — so **sequence stories by uncertainty, hardest first**, not by ease.

### Executable specifications are an *output* of conversations, not an input (ch 6)
Don't let a BA write scenarios alone and hand them over. Don't write Given/When/Then in the discovery workshop either — it distracts from the bigger picture. Map breadth-first in **Illustrate**; formalize in **Formulate**.

### The five marks of good Gherkin (ch 7)
1. **Declarative, not imperative** — what the user achieves, not which buttons they press. (One team: **80% less time** to write new scenarios after refactoring away from imperative style.)
2. **Does one thing well** — one business rule per scenario; simplest case first.
3. **Meaningful actors** — named personas in third person, never "I" or "the user."
4. **Essential only** — drop columns and steps that don't change the outcome; but stop before it goes vague (*the fish seller*).
5. **Independent** — each scenario sets up its own state.

**Instant smell**: a scenario containing "verify" or "check" is a manual test script in disguise.

### Layers of abstraction (ch 9)
Business Rules (changes when the business changes its mind) → Business Flow (changes when the workflow changes) → Technical (changes when the screen changes). Each layer **orchestrates the one below and never reaches past it**. If a field rename forces a scenario edit, your layers have leaked. Write the top two layers *before the UI exists*.

### Four rules of an industrial-strength acceptance test (ch 9)
Communicates clearly · gives meaningful feedback on failure · is reliable · is maintainable. A well-run suite has only **passing or pending** tests — tolerate one broken test and you'll soon tolerate many, and the suite stops reporting project health at all.

### Use a UI test for exactly four things (ch 10)
Key user journeys · what the UI presents · how it renders · screen-specific logic. **Everything else goes lower and runs faster.** Ask: *"Am I illustrating how the user interacts with the application, or logic independent of the interface?"*

### Page Objects: two roles, one prohibition (ch 11)
Locate elements and report state in business terms. **Never assert inside one**; never expose `WebDriver`/`WebElement`. Model *components*, not whole pages (Fowler). At scale, add Action/Query classes above them — a Page Object–based step can only ever run through the UI.

### Screenplay: interactions are objects, not methods (ch 12)
`actor.attemptsTo(Click.on(...))` instead of `element.click()`. That single structural choice means **you extend by adding classes, never modifying them** — WebDriver has no double-click method, but `DoubleClick.on(...)` is just another class. Five elements: Actors, Interactions, Abilities (adaptors), Questions (assertions), Tasks (composable, reusable).

### Testing *with* APIs, not testing APIs (ch 13)
"The goal is to illustrate a business use case or business rule, **not** to exercise a specific layer. Interacting with the interfaces is just a means to an end." Even whole user journeys are often best automated purely through APIs. API *design* testing (fields, status codes) belongs in unit tests.

### Blended testing via grammatical voice (ch 15)
`Given` + **passive** ("Tracy has signed up") → we only care *that* it's done → **API call**.
`When` + **active** ("Tracy signs up") → we want to *demonstrate how* → **UI**.
Different Cucumber expressions match each, so the split is automatic.

### "End to end" means the ends of the *workflow* (ch 14)
Not "against a fully assembled, deployed system through a browser." Exercise the workflow from beginning to end while freely using APIs and in-memory databases within it.

### Feature readiness ≠ feature coverage (ch 16)
Readiness aggregates scenario results per feature. **Coverage** also counts requirements with *no* tests — because "test results can tell you what features were tested, but they can't tell you which features have no tests at all." All-green at 33% coverage is a real and common state. Feature coverage is not code coverage.

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-building-software-that-makes-a-difference.md) | Building Software That Makes a Difference | Two Axes of Failure, Knowledge Constraint, the BDD flow |
| [ch02](chapters/ch02-introducing-bdd.md) | Introducing BDD | Nine BDD principles, outside-in, "should"-naming, Gherkin primer |
| [ch03](chapters/ch03-bdd-the-whirlwind-tour.md) | BDD: The Whirlwind Tour | Six-phase BDD flow, Impact Mapping, Example Mapping, glue code as API design |
| [ch04](chapters/ch04-speculate-goals-to-features.md) | Speculate: Goals to Prioritized Features | Hypothesis-Driven Development, Impact Mapping, Pirate Canvas, why stack, SMART |
| [ch05](chapters/ch05-describing-and-prioritizing-features.md) | Describing and Prioritizing Features | Capability/feature/story vocabulary, Real Options, Deliberate Discovery |
| [ch06](chapters/ch06-illustrating-features-with-examples.md) | Illustrating Features with Examples | Three Amigos, Example Mapping, Feature Mapping, OOPSI, Kolb's cycle |
| [ch07](chapters/ch07-examples-to-executable-specifications.md) | From Examples to Executable Specifications | Gherkin reference, five marks of good Gherkin, personas, test-script smells |
| [ch08](chapters/ch08-executable-specs-to-automated-tests.md) | Executable Specs → Automated Tests | Step definitions, Cucumber Expressions, `@ParameterType`, hooks, TestContainers |
| [ch09](chapters/ch09-writing-solid-acceptance-tests.md) | Writing Solid Acceptance Tests | Four rules, three layers of abstraction, personas/HOCON, known entities |
| [ch10](chapters/ch10-automating-the-ui-layer.md) | Automating the UI Layer | Four reasons for a UI test, WebDriver locators, waits, testability |
| [ch11](chapters/ch11-ui-test-automation-design-patterns.md) | UI Test Automation Design Patterns | Page Objects, Page Component Objects, Action/Query classes, Fluent Interface |
| [ch12](chapters/ch12-screenplay-pattern.md) | The Screenplay Pattern | Actors, interactions, abilities, questions, tasks; Cast and OnStage |
| [ch13](chapters/ch13-microservices-and-apis.md) | Microservices and APIs | Testing *with* APIs, Rest Assured, JSONPath, partial responses |
| [ch14](chapters/ch14-legacy-systems-with-serenity-js.md) | Existing Systems with Serenity/JS | Journey Mapping, steel thread, three-layer test automation system, HTA |
| [ch15](chapters/ch15-portable-test-automation-serenity-js.md) | Portable Test Automation | Blended testing, task substitution, Lean/Companion Page Objects, portability |
| [ch16](chapters/ch16-living-documentation-and-release-evidence.md) | Living Documentation and Release Evidence | Feature readiness vs. coverage, release evidence, legacy documentation |

**Part 1** (ch 1–3): Why BDD · **Part 2** (ch 4–7): What do I want? Requirements · **Part 3** (ch 8–16): How do I build it? Automation

## Topic Index

- **Abilities (Screenplay)** → ch12, ch14, ch15
- **Acceptance criteria** → ch05, ch06, ch09
- **Action classes** → ch11, ch12
- **Actors / personas** → ch07, ch09, ch12, ch14
- **AJAX / waits** → ch10, ch11, ch12, ch15
- **Anti-patterns (Gherkin)** → ch07
- **API testing** → ch13, ch15
- **Background** → ch07, ch08
- **Blended testing** → ch14, ch15
- **Business goals** → ch04, ch05
- **Cast / OnStage** → ch12, ch14
- **Cucumber Expressions** → ch08
- **Cucumber setup / runners** → ch03, ch08
- **Data tables** → ch06, ch07, ch08
- **Deliberate Discovery** → ch05
- **Docker / TestContainers** → ch08
- **DSL / Fluent Interface** → ch11
- **Example Mapping** → ch03, ch06, ch13
- **Executable specifications** → ch02, ch07, ch13
- **Feature coverage / readiness** → ch16
- **Feature files (organizing)** → ch07, ch08
- **Feature Mapping** → ch06, ch14
- **Feature vs. User Story** → ch05
- **Gherkin syntax** → ch02, ch07
- **Hooks** → ch07, ch08, ch13
- **HOCON / test data** → ch09, ch13, ch14
- **Hypothesis-Driven Development** → ch04
- **Impact Mapping** → ch03, ch04, ch05
- **Journey Mapping** → ch14
- **JSONPath** → ch13
- **Layers of abstraction** → ch09, ch14, ch15
- **Legacy systems** → ch14, ch16
- **Living documentation** → ch01, ch02, ch16
- **Locators** → ch09, ch10, ch11, ch15
- **OOPSI** → ch06
- **Outside-in development** → ch02, ch03, ch15
- **Page Element Query Language** → ch15
- **Page Objects** → ch11, ch15
- **Parallel execution / ThreadLocal** → ch08, ch10
- **Pirate Metrics / Pirate Canvas** → ch04
- **Playwright / WebdriverIO** → ch14, ch15
- **Product Backlog Refinement** → ch05
- **Questions (Screenplay)** → ch12, ch15
- **Real Options** → ch05, ch06
- **Release evidence / reporting** → ch16
- **Rest Assured** → ch13
- **Rule / Example keywords** → ch07
- **Scenario Outline** → ch02, ch07
- **Screenplay Pattern** → ch09, ch11, ch12, ch14, ch15
- **Selenium WebDriver** → ch10, ch11
- **Serenity BDD** → ch03, ch11, ch12
- **Serenity/JS** → ch14, ch15
- **Slicing features** → ch03, ch05, ch14
- **Steel thread** → ch14
- **Step definitions** → ch03, ch08, ch14
- **Tags** → ch07, ch08, ch16
- **Tasks (Screenplay)** → ch12, ch15
- **TDD relationship** → ch02, ch03
- **Three Amigos** → ch06
- **UI testing (when to)** → ch10, ch13
- **Unit tests as documentation** → ch02, ch16
- **Vision statements** → ch04

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions and chapter references
- [patterns.md](patterns.md) — every technique with when-to-use, how, and trade-offs
- [cheatsheet.md](cheatsheet.md) — decision tables, thresholds, and smells for use while working

---

## Scope & Limits

This skill covers the book's content only. Code examples are Java (Cucumber, Serenity BDD, Selenium, Rest Assured) and TypeScript (Cucumber.js, Serenity/JS, Playwright), with occasional C#/.NET (SpecFlow, NSpec) and Python (Behave) references. Tooling details reflect the 2023 edition — verify current library APIs before relying on specific signatures. For applying these patterns in your own codebase, combine with project-specific tools.
