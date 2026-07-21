---
name: ddd-book
description: "Knowledge base from \"Domain-Driven Design: Tackling Complexity in the Heart of Software\" by Eric Evans. Use when applying Evans' frameworks for domain modeling, ubiquitous language, aggregates, bounded contexts, repositories, supple design, or strategic distillation — studying the book, or referencing its concepts."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, pattern name, or chapter number] -->

# Domain-Driven Design: Tackling Complexity in the Heart of Software
**Author**: Eric Evans (2003, Addison-Wesley) | **Chapters**: 17 in 4 Parts | **Generated**: 2026-07-21

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `aggregates`, `bounded context`, `ubiquitous language`, `specification`, `distillation`; I find and read the relevant chapter
- **With a chapter** — ask for `ch10`; I load that chapter file
- **Browse** — ask "what chapters do you have?" for the full index

When you ask about a topic not covered below, I will read the relevant chapter file before answering.

---

## Core Frameworks & Mental Models

### The three foundations (Part I)
- **UBIQUITOUS LANGUAGE** — use the model as the backbone of one language in speech, writing, diagrams, and code, for developers *and* domain experts. **A change in the LANGUAGE is a change to the model.** When a phrase is awkward to say, the model is wrong: try alternative expressions (= alternative models), then refactor code to the winner. Never split the language between developers and experts — technical and domain jargon are *extensions*, not rival vocabularies. Test: *if sophisticated domain experts don't understand the model, there is something wrong with the model.*
- **MODEL-DRIVEN DESIGN** — demand **one** model that serves analysis and design equally. Reject any model impractical to implement; reject any that doesn't express the domain. Modeling, design, and coding are a single iterative loop, not phases. Separate "analysis models" guarantee the model decays into a data structure.
- **HANDS-ON MODELERS** — anyone contributing to the model must touch code; anyone changing code must learn to express the model in it. *"Programmers are modelers, whether anyone likes it or not."*
- **Knowledge crunching** — walk concrete scenarios with experts, sketch live, let them correct your vocabulary, and close the loop with a crude prototype (no UI, no persistence). Drop concepts as deliberately as you add them.

### Building blocks (Part II)
- **LAYERED ARCHITECTURE** — UI → Application (thin; task-progress state only, never business rules) → **Domain** (the heart) → Infrastructure. DDD requires exactly one layer to exist: the domain layer. The alternative fork is **SMART UI** — a legitimate choice for simple, rule-light projects, with **no migration path except replacing entire applications**.
- **ENTITY vs. VALUE OBJECT** — "Does the user *care* if it's the same one?" ENTITIES are defined by identity and continuity; keep them spare. VALUE OBJECTS are defined by attributes; **make them immutable by default**, which makes copying, sharing, FLYWEIGHT, and denormalization free technical choices. The same real-world thing flips category by context (`Address` is a VALUE for mail-order, an ENTITY for the postal service).
- **SERVICE** — a stateless standalone operation named for an activity (verb, not noun), when a process fits no ENTITY or VALUE. *But the common mistake is giving up too early and sliding toward procedural programming.*
- **AGGREGATE** — a cluster treated as a unit for data changes, with one root ENTITY. Only the root is externally referenceable and directly queryable; internal references are handed out transiently only; deletes take the whole boundary; **all invariants hold at every commit**. Cross-AGGREGATE consistency is eventual by design. Find boundaries by **loosening high-contention relationships and tightening the ones carrying strict invariants**.
- **FACTORY / REPOSITORY** — *"The FACTORY makes new objects; the REPOSITORY finds old objects."* Creation must be atomic and invariant-enforcing. Provide REPOSITORIES **only for AGGREGATE roots that need direct access**, and leave transaction control to the client. Avoid "find or create."
- **MODULE** — cognitive overload, not technical metrics, is the motivation. Choose MODULES that tell the story of the system; name them into the LANGUAGE. When conceptual clarity conflicts with technical coupling, **take conceptual clarity**.

### Refactoring toward deeper insight (Part III)
- **Digging out concepts** — listen to language; scrutinize awkwardness; contemplate contradictions; read the book. A term the experts use that isn't in the design is an opportunity; a term in the design the experts *don't* use is a concept you invented.
- **SPECIFICATION** — a predicate-like VALUE OBJECT answering `isSatisfiedBy()`, keeping a rule in the domain layer and unifying **validation, selection, and building-to-order** under one concept. Combine with and/or/not; implement only AND if that's all you need.
- **Supple design** — **INTENTION-REVEALING INTERFACES** (name for effect and purpose, never means; write the test first in the shape you wish the API had) · **SIDE-EFFECT-FREE FUNCTIONS** (segregate commands from queries, then move complex logic into an immutable VALUE) · **ASSERTIONS** (state post-conditions and invariants; they describe *state*, so they're easy to test) · **CONCEPTUAL CONTOURS** (decompose along the domain's real divisions — localized refactorings mean it fits) · **STANDALONE CLASSES** (every dependency suspect until proven essential) · **CLOSURE OF OPERATIONS** (return type matches argument type).
- **Breakthrough** — returns from refactoring are not linear. Persistent unexpected requirements and stubborn numeric bugs mean a **wrong model**, not a hard problem. When the model suddenly looks inadequate, that means the team just got smarter. Evaluate with: time to parity? solvable otherwise? cost of delay once there's an installed base? do *we* think it's right?
- **When to refactor** — when the design doesn't express the team's current understanding, when concepts are implicit and you see how to surface them, or when suppleness is within reach. **"If you wait until you can make a complete justification for a change, you've waited too long."** Never toward a "deep model" you couldn't convince a domain expert to use.

### Strategic design (Part IV)
- **BOUNDED CONTEXT** — *"Total unification of the domain model for a large system will not be feasible or cost-effective."* Define each model's context in terms of team organization, application usage, and physical artifacts. Watch for **duplicate concepts** and **false cognates**; the earliest warning is confusion of language, not failing code.
- **CONTEXT MAP** — name every context into the LANGUAGE and describe every point of contact. **Map the terrain as it is; change reality before you change the map.**
- **Relationship patterns**, from most to least cooperative: CONTINUOUS INTEGRATION → SHARED KERNEL → CUSTOMER/SUPPLIER → CONFORMIST → ANTICORRUPTION LAYER → SEPARATE WAYS. Plus OPEN HOST SERVICE / PUBLISHED LANGUAGE for many consumers. **Choose CONFORMIST more often than feels comfortable**; remember the Great Wall — isolation is protective and potentially bankrupting.
- **CORE DOMAIN** — make it **small**, make it easily distinguishable, apply top talent, and justify every other investment by how it supports it. You almost certainly cannot buy it. Factor out **GENERIC SUBDOMAINS** (no trace of your specialties — and **do not design them for reusability**) and **COHESIVE MECHANISMS** (*"a model proposes; a COHESIVE MECHANISM disposes"*).
- **Large-scale structure** — a language for discussing the system in broad strokes. **EVOLVING ORDER**: let it evolve, possibly into a different kind entirely. **An ill-fitting structure is worse than none; less is more.** RESPONSIBILITY LAYERS (Potential · Operations · Decision Support · Policy · Commitment) are the workhorse; keep to 4–5 and signal upward with events, never dependencies.
- **Who sets strategy** — decisions must reach everyone, absorb feedback, and allow evolution; architecture teams must not siphon off the best designers; minimalism and humility are required (*"almost everything gets in the way of something"*); and **objects are specialists, developers are generalists.** Beware the master plan: *"too precise in the totality, not precise enough in the details."*

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-crunching-knowledge.md) | Crunching Knowledge | Knowledge Crunching, Five Ingredients of Effective Modeling, Deep Model |
| [ch02](chapters/ch02-ubiquitous-language.md) | Communication and the Use of Language | UBIQUITOUS LANGUAGE, Modeling Out Loud, One Team One Language, Explanatory Model |
| [ch03](chapters/ch03-model-driven-design.md) | Binding Model and Implementation | MODEL-DRIVEN DESIGN, HANDS-ON MODELERS, Letting the Bones Show |
| [ch04](chapters/ch04-isolating-the-domain.md) | Isolating the Domain | LAYERED ARCHITECTURE, SMART UI |
| [ch05](chapters/ch05-model-expressed-in-software.md) | A Model Expressed in Software | ENTITY, VALUE OBJECT, SERVICE, MODULE, constrained associations |
| [ch06](chapters/ch06-life-cycle-of-a-domain-object.md) | The Life Cycle of a Domain Object | AGGREGATE, FACTORY, REPOSITORY |
| [ch07](chapters/ch07-extended-example-cargo.md) | Using the Language: An Extended Example | All Part II patterns combined; ANTICORRUPTION LAYER, ENTERPRISE SEGMENT |
| [ch08](chapters/ch08-breakthrough.md) | Breakthrough | Levels of Refactoring, Deep Model, Share Pie story |
| [ch09](chapters/ch09-making-implicit-concepts-explicit.md) | Making Implicit Concepts Explicit | Digging out concepts, Explicit Constraints, SPECIFICATION |
| [ch10](chapters/ch10-supple-design.md) | Supple Design | INTENTION-REVEALING INTERFACES, SIDE-EFFECT-FREE FUNCTIONS, ASSERTIONS, CONCEPTUAL CONTOURS, STANDALONE CLASSES, CLOSURE OF OPERATIONS |
| [ch11](chapters/ch11-applying-analysis-patterns.md) | Applying Analysis Patterns | Analysis Patterns, Account/Entry, Posting Rules, firing modes |
| [ch12](chapters/ch12-design-patterns-in-the-model.md) | Relating Design Patterns to the Model | STRATEGY/POLICY, COMPOSITE, why not FLYWEIGHT |
| [ch13](chapters/ch13-refactoring-toward-deeper-insight.md) | Refactoring Toward Deeper Insight | Exploration Teams, Prior Art, Timing, Crisis as Opportunity |
| [ch14](chapters/ch14-maintaining-model-integrity.md) | Maintaining Model Integrity | BOUNDED CONTEXT, CONTEXT MAP, CONTINUOUS INTEGRATION, and the seven relationship patterns |
| [ch15](chapters/ch15-distillation.md) | Distillation | CORE DOMAIN, GENERIC SUBDOMAIN, DOMAIN VISION STATEMENT, HIGHLIGHTED CORE, COHESIVE MECHANISM, SEGREGATED CORE, ABSTRACT CORE |
| [ch16](chapters/ch16-large-scale-structure.md) | Large-Scale Structure | EVOLVING ORDER, SYSTEM METAPHOR, RESPONSIBILITY LAYERS, KNOWLEDGE LEVEL, PLUGGABLE COMPONENT FRAMEWORK |
| [ch17](chapters/ch17-bringing-the-strategy-together.md) | Bringing the Strategy Together | Assessment checklist, Six Essentials for Strategic Design, Beware the Master Plan |

## Topic Index

- **Aggregates, invariants, transaction scope** → ch06, ch07
- **Analysis patterns, published models** → ch11, ch15
- **Anticorruption layer, legacy integration** → ch07, ch14, ch17
- **Assertions, design by contract** → ch10, ch09
- **Bounded context, context map** → ch14, ch17
- **Breakthroughs, deep models** → ch08, ch13, ch01
- **Cohesive mechanisms** → ch15, ch09
- **Conceptual contours, granularity** → ch10
- **Continuous integration** → ch14
- **Core domain, distillation** → ch15, ch17
- **Databases, object-relational mapping** → ch06, ch05, ch09
- **Design patterns in the domain (Strategy, Composite, Flyweight)** → ch12, ch10
- **Documents and diagrams** → ch02, ch15
- **Entities and value objects** → ch05, ch07
- **Factories** → ch06, ch07
- **Frameworks, when they hurt** → ch04, ch05, ch06, ch15, ch17
- **Generic subdomains** → ch15
- **Knowledge crunching** → ch01, ch09, ch13
- **Knowledge level, reflection** → ch16
- **Large-scale structure, responsibility layers** → ch16, ch17
- **Layered architecture** → ch04, ch05
- **Modules and packaging** → ch05, ch07, ch15
- **Refactoring: when, what, how much** → ch13, ch08, ch15
- **Repositories and queries** → ch06, ch09, ch07
- **Services** → ch05, ch09, ch14
- **Smart UI** → ch04
- **Specification** → ch09, ch10, ch06
- **Strategic decision making, team organization** → ch17, ch14, ch15
- **Supple design** → ch10, ch13
- **Team relationship patterns (shared kernel, conformist, separate ways…)** → ch14
- **Ubiquitous language** → ch02, ch01, ch14, ch16
- **Worked example: cargo shipping** → ch07, ch09, ch12, ch14, ch15, ch16
- **Worked example: syndicated loans / Share Pie** → ch08, ch10
- **Worked example: interest and accruals** → ch09, ch10, ch11

## Supporting Files

- [glossary.md](glossary.md) — every significant term with a one-line definition and chapter reference
- [patterns.md](patterns.md) — all ~35 patterns with when-to-use / how / trade-offs
- [cheatsheet.md](cheatsheet.md) — decision rules, thresholds, layer-placement table, tells and smells

---

## Scope & Limits

This skill covers the book's content (2003). It does not cover later DDD developments — domain events, CQRS, event sourcing, or Vaughn Vernon's *Implementing DDD* — nor does it prescribe how to apply these patterns to a specific codebase. For that, combine with project-specific analysis.
