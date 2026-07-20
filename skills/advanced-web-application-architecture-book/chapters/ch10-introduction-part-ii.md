# Chapter 10: Introduction (Part II — Organizing principles)

## Core Idea
Separating core from infrastructure is necessary but not sufficient. "After some time though, maintaining these large buckets of code is still going to be a trouble." Part II adds three organizing principles that give those buckets internal structure.

## Frameworks Introduced

- **The three organizing principles** — what Part II delivers, in order. Combined, they result in an application that:
  1. **Is built around a standardized, recognizable catalog of object types** (Ch 11) — so every class has a known kind, and you recognize what you're looking at.
  2. **Uses layers for separating concerns at a higher level, which assist the developer in deciding where to put things** (Ch 12) — layering as a *decision aid*, not bureaucracy.
  3. **Decouples application use cases from the way clients connect to the application, using an architectural pattern called Ports and Adapters** (Ch 13).

- **The framing to carry into Part II**: these principles are described as "some more detailed organizing principles… which have proven to be very effective." Read alongside Ch 9's closing verdict — "the big win is separating core from infrastructure code. All the rest is nice-to-have, and you will get the rest more or less for free" — Part II is refinement, not foundation.

## Key Concepts
- **Organizing principle** — a rule for structuring code beyond the core/infrastructure split.
- **Framework-independent object types** — the catalog in Ch 11; classes named for what they *are* in your design, not for what framework base class they extend.
- **Architectural layering** — grouping the catalog's object types into layers (Ch 12).
- **Hexagonal architecture / Ports and Adapters** — the overlay on top of layering (Ch 13).

## Mental Models
- **The problem Part II solves is navigational, not structural.** Part I gets the infrastructure out of your core. Part II answers "where does this new class go?" — layers "assist the developer in deciding where to put things."
- **The three principles build on each other in sequence.** The catalog (Ch 11) names the object types; layers (Ch 12) group those named types; ports and adapters (Ch 13) sits over the layers as "a kind of overlay."
- **These are derived, not imposed.** Ch 11 is explicitly "a catalog of the design patterns that we derived in Part I" — every pattern in it was arrived at by refactoring, not chosen up front.

## Key Takeaways
1. Core/infrastructure separation alone leaves you with two large undifferentiated buckets. That becomes a maintenance problem on its own.
2. Part II's three principles are: a catalog of object types, architectural layers, and ports and adapters — in that order, each building on the last.
3. Layers exist to help you decide where code goes. Treat them as a decision aid.
4. Everything in Part II was derived from Part I's refactorings rather than adopted as a framework.

## Connects To
- **Ch 9**: the conclusion that Part II is largely "free" once core and infrastructure are separated.
- **Ch 11**: the catalog of design patterns derived in Part I.
- **Ch 12**: architectural layers.
- **Ch 13**: ports and adapters as an overlay on the layered architecture.
- **Ch 14**: the testing strategy that these organizing principles enable.
- **Ch 15**: the book's conclusion, including when this approach is over-engineering.
