# Chapter 21: Screaming Architecture

## Core Idea
Your top-level directory structure should scream what the system *does* — "Health Care System," "Accounting System" — not what framework it was built with. Architectures support use cases; frameworks are tools to be used, not architectures to be conformed to.

## Frameworks Introduced
- **Screaming Architecture (the blueprint test)**: look at the top-level directory and the source files in the highest-level package, and ask what they announce.
  - When to use: at project inception, and at every review of the repository layout; especially when onboarding a new programmer, whose first impression is the measurement.
  - How:
    1. Open the source repository's top level. Read only the names.
    2. If the names are `controllers/`, `models/`, `views/`, `helpers/`, `config/` — the architecture screams "Rails." If they are `Spring`, `Hibernate`, `ASP` idioms, it screams the framework.
    3. Rename/restructure so the highest-level packages are named after the *use cases* of the system.
    4. Push the framework's structures down into a subordinate, replaceable region.
    5. Verify: a new programmer should be able to learn all the use cases of the system while still not knowing how the system is delivered.
  - Why it works: a building's plans scream HOME or LIBRARY because the plan is organized around what happens inside. Software organized around use cases lets an architect describe the supporting structures without committing to frameworks, tools, and environments.
  - Failure mode: if your architecture is based on frameworks, then it *cannot* be based on your use cases — the two organizing principles compete for the same top-level slots.

- **Use Case Driven Architecture (Jacobson)**: from *Object Oriented Software Engineering: A Use Case Driven Approach*. Software architectures are structures that support the use cases of the system.
  - How: center the architecture on use cases; treat frameworks, databases, web servers, and other environmental issues as decisions to be deferred and delayed.

- **The framework-skepticism strategy**: look at each framework with a jaded eye.
  - How: for each candidate framework, ask (a) how should I use it? (b) how should I protect myself from it? (c) what does it cost? Then develop an explicit strategy that prevents the framework from taking over the architecture.

## Key Concepts
- **Delivery mechanism**: the channel by which the system reaches users — the web is one, and it is an IO device, a detail.
- **Options left open**: frameworks, databases, web servers are choices a good architecture lets you defer until much later in the project, and change your mind about afterward.
- **Peripheral concerns**: everything the use cases are decoupled *from* — UI, persistence, transport, tooling.
- **Testable architecture**: a structure in which all use cases can be unit-tested with no framework, no web server, and no database connected.
- **Entity object (as used here)**: a plain old object with no dependencies on frameworks, databases, or other complications.
- **Use case object**: the object that coordinates Entity objects to accomplish one application behavior.
- **Framework true believer**: an author or team taking the all-encompassing, all-pervading, let-the-framework-do-everything position — the position you do *not* want to take.

## Mental Models
- Think of your repo's top-level listing as a **building blueprint**: a single-family residence shows a foyer, living room, kitchen, dinette; a library shows a check-in desk, reading areas, and gallery after gallery of shelves. Neither screams "brick."
- Use the **house-materials analogy** when someone demands an early framework decision: the architect's first concern is that the house be *usable*, and they take pains to let the homeowner choose brick, stone, or cedar later.
- Think of the web as **an IO device**. You should be able to deliver the same system as a console app, a web app, a thick client, or a web service without undue complication or change to the fundamental architecture.
- Use "**can I run the use case tests with the server down and the database disconnected?**" as the fastest proxy for whether the architecture actually screams use cases.

## Anti-patterns
- **Framework-shaped top-level packages**: an architecture supplied by the framework can never be based on your use cases.
- **Letting the web dictate structure**: treating a delivery mechanism as an architecture makes the system unable to be delivered any other way.
- **Deciding on Rails/Spring/Hibernate/Tomcat/MySQL up front**: burns options that a good architecture would have kept open until much later.
- **Reading framework docs as architecture guidance**: the examples are written from a true believer's point of view and assume the framework does everything.
- **Business rules that need a running server or a live database to test**: proof the frameworks were not kept at arm's length.

## Worked Example
**Two buildings, then two repositories.**

Look at plans showing a front entrance, a foyer leading to a living room, a dining room, a kitchen nearby, a dinette next to it, a family room close to that. There is no question: the architecture screams "HOME." Now look at plans with a grand entrance, an area for check-in/out clerks, reading areas, small conference rooms, and gallery after gallery of bookshelves. That architecture screams "LIBRARY." In neither case do the plans scream about the exterior material.

Apply the same reading to a health care system's repository. If the top-level package list is `controllers`, `models`, `views`, `config`, the architecture screams "Rails" — the reader learns the delivery framework and nothing about health care. Reorganize so the top-level names are the use cases: admitting a patient, scheduling a procedure, adjudicating a claim. Now a new programmer's first impression is "Oh, this is a health care system," and they can learn every use case without discovering how it is delivered.

They will come to you and say: *"We see some things that look like models — but where are the views and controllers?"* And the correct answer is: *"Oh, those are details that needn't concern us at the moment. We'll decide about them later."*

## Key Takeaways
1. Judge an architecture by what its top-level directory screams to a stranger — the use cases, or the framework.
2. Architectures are not, and should not be, supplied by frameworks; frameworks are tools to be used, not architectures to be conformed to.
3. The first concern is that the system be usable, not what it is made of — keep frameworks as options left open.
4. The web is a delivery mechanism, an IO device, and a detail; the same fundamental architecture should be deliverable as console, web, thick client, or web service.
5. Adopt frameworks skeptically: always ask how to protect yourself from the one you adopt.
6. Testability is the proof: if the use cases can be unit-tested with no web server, no database, and no framework, the decoupling is real.

## Connects To
- **Ch 22 (The Clean Architecture)**: this chapter states the goal; the concentric circles and the Dependency Rule are the mechanism that achieves it.
- **Ch 17 (Boundaries)**: the framework-protection strategy is a boundary drawn around a third-party component.
- **Ch 20 (Business Rules)**: Entities and use case objects are the things the top-level structure should name.
- **Ch 34 (The Missing Chapter)**: package-by-layer vs. package-by-feature vs. package-by-component is the concrete follow-through on the "what does the directory scream?" test.
- **Ivar Jacobson, *Object Oriented Software Engineering: A Use Case Driven Approach***: the origin of use-case-driven architecture.
- **Hexagonal Architecture / Ports and Adapters**: the same instinct — delivery mechanisms live outside, plugged into the application.
