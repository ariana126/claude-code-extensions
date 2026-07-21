# Chapter 4: Isolating the Domain

## Core Idea
Domain code is a small fraction of a system but disproportionately important; it must live in its own layer, free of UI, application, and infrastructure concerns, or a MODEL-DRIVEN DESIGN is simply not achievable. The honest alternative for simple projects is the SMART UI — a different road entirely, not a lesser version of the same one.

## Frameworks Introduced

- **LAYERED ARCHITECTURE**:
  > Partition a complex program into layers. Develop a design within each layer that is cohesive and that depends only on the layers below. Follow standard architectural patterns to provide loose coupling to the layers above. Concentrate all the code related to the domain model in one layer and isolate it from the user interface, application, and infrastructure code.
  - When to use: any project committing to MODEL-DRIVEN DESIGN. **DDD requires only one particular layer to exist — the domain layer.**
  - How — the four conventional layers:

    | Layer | Responsibility |
    |---|---|
    | **User Interface (Presentation)** | Show information to the user; interpret their commands. The "user" may be another computer system. |
    | **Application** | Define the jobs the software does; direct domain objects to work out problems. **Kept thin.** No business rules or knowledge. No state reflecting the business situation — only state reflecting *progress of a task*. |
    | **Domain (Model)** | Represent business concepts, business situation, and business rules. Holds the state that reflects the business situation (storage delegated downward). **The heart of business software.** |
    | **Infrastructure** | Generic technical capabilities supporting higher layers: message sending, persistence, widget drawing; may also supply the architectural framework relating the layers. |

  - Essential principle: *any element of a layer depends only on other elements in the same layer or on elements of layers beneath it.* Upward communication must go through an indirect mechanism.
  - Why it works: layers evolve at different rates and answer different needs, so isolated layers are cheaper to maintain; separation also allows flexible placement across servers/clients (Fowler 1996).
  - Failure mode: mixing UI/DB code into business objects because it's the fastest thing in the short run — then superficial UI changes alter business logic, and changing a rule requires tracing UI and database code.

- **Relating the layers** — the connection mechanisms:
  - Downward: straightforward — call public interfaces, hold references.
  - Upward (a lower object needs to communicate beyond answering a query): callbacks or **OBSERVER** (Gamma et al. 1995).
  - UI↔application/domain: **MODEL-VIEW-CONTROLLER** (Smalltalk, 1970s) is the grandfather; see Fowler 2002 for variations; Larman 1998's **MODEL-VIEW SEPARATION** and **APPLICATION COORDINATOR**.
  - Rule of thumb: any approach is fine *as long as domain objects can be designed without simultaneously thinking about the UI*.
  - Infrastructure normally does **not** initiate action in the domain layer and has no specific knowledge of the domain it serves; it is usually offered as **SERVICES** the higher layers call. Benefit: the application layer knows *when* to send a message, and is not burdened with *how*.

- **SMART UI (the "anti-pattern")** — the deliberate opposite fork:
  > Put all the business logic into the user interface. Chop the application into small functions and implement them as separate user interfaces, embedding the business rules into them. Use a relational database as a shared repository of the data. Use the most automated UI building and visual programming tools available.
  - When to use: simple functionality dominated by data entry and display, few business rules, staff not composed of advanced object modelers, short timelines and modest expectations.
  - Why Evans includes it: it is a *legitimate pattern in some contexts*, called an anti-pattern only relative to DDD. Naming it clarifies when the harder path is warranted.

## Key Concepts
- **LAYERED ARCHITECTURE** — dependencies flow only downward; domain code concentrated in one layer.
- **Domain layer** — the manifestation of the model and all directly related design elements; where the business logic's design and implementation live.
- **Application layer** — thin coordinator; task progress state only, never business state.
- **Architectural framework** — intrusive infrastructure that dictates how other layers are implemented (subclassing framework classes, structured method signatures).
- **SMART UI** — business logic embedded in the UI, integration via a shared relational database.
- **TRANSACTION SCRIPT** (Fowler 2002) — a middle ground: separates UI from application but provides no object model.

## Mental Models
- **Think of domain objects as needing to see each other as a system**, not to be picked out of a larger mix "like trying to identify constellations in the night sky."
- **Use the layer test on any rule**: "Every credit has a matching debit" belongs in the *domain* layer, not the application layer. If the application layer knows a business rule, the layering has leaked.
- **Judge decoupling by replaceability of the trigger, not by the plan to replace it.** A UI replaceable by an XML wire request isn't valuable because you'll do it — it's valuable because the separation keeps each layer understandable.
- **Note which class reflects more knowledge of the other**, not which subclasses which — a subclass of a framework class legitimately sits in a higher layer.
- **The architecture test**: *if the architecture isolates domain-related code such that a cohesive domain design is loosely coupled to the rest of the system, it can probably support domain-driven design.* The specific scheme matters less than that property.

## Anti-patterns
- **Business logic diffused through UI widgets and database scripts**: makes coherent model-driven objects impractical, automated testing awkward, and reasoning about the domain nearly impossible.
- **One-size-fits-all framework adoption**: early J2EE apps implemented *all* domain objects as entity beans, bogging down both performance and development pace. Best practice became: framework for larger-grain objects, most business logic in plain Java objects. Apply frameworks selectively to hard problems; minimalism keeps business objects readable and reduces later coupling.
- **Half-committing to a sophisticated design approach** — taking on the overhead without carrying it through.
- **Industrial-strength infrastructure on a project that doesn't need it** — the mirror mistake.
- **Hedging with a flexible language on a SMART UI project**: "Just using a flexible language doesn't create a flexible system, but it may well produce an expensive one." If you choose SMART UI, choose 4GL-style tools geared to it. **Don't bother hedging your bet.**
- **Starting SMART UI and planning to migrate**: you can't migrate except by replacing entire applications. First tentative steps must be MODEL-DRIVEN with an isolated domain layer, or the project is stuck.

## Worked Example — Partitioning Online Banking into Layers

Feature: **funds transfer**. The user picks two account numbers and an amount, then initiates a transfer. (Evans omits security and simplifies the domain; realistic complexity would only *increase* the need for layering.)

Consider what one trivial user act — selecting a cargo's destination from a list of cities — actually requires: (1) draw a widget, (2) query the database for possible cities, (3) interpret and validate input, (4) associate the selected city with the cargo, (5) commit the change. **Only step 4 is about the business of shipping.**

Layered assignment for the transfer:
- **UI** — entry fields for account numbers and amount, command buttons.
- **Application** — receives the request, coordinates the transfer task, controls the transaction. Makes **no assumption about the source of the request** — the UI could be swapped for an XML wire request with no change to it or anything below.
- **Domain** — owns the fundamental business rule *"Every credit has a matching debit."* Explicitly **not** the application layer.
- **Infrastructure** — persistence, transaction machinery.

**Evans' self-critique of his own figure:** because everything from request through transaction control had to fit on one page, the domain layer had to be *dumbed down* to keep the interaction followable. Had the isolated domain layer been the focus, there would have been room — on the page and in our heads — for ledgers, credit and debit objects, or monetary transaction objects. The figure demonstrates the very problem it illustrates.

## SMART UI Trade-off Table

| Advantages | Disadvantages |
|---|---|
| High, immediate productivity on simple applications | Integration between applications only through the database |
| Less capable developers can work this way with little training | No reuse of behavior, no abstraction; rules duplicated per operation |
| Weak requirements analysis is survivable — ship a prototype, change it fast | Rapid prototyping hits a natural limit; no abstraction ⇒ few refactoring options |
| Applications decoupled; small-module delivery dates are predictable | Complexity buries you quickly |
| Relational databases work well; integration at the data level | Growth path is only "more simple applications" — no graceful path to richer behavior |
| 4GL tools work well | Migration to another approach requires replacing entire applications |
| Maintenance programmers can redo confusing portions locally | |

## Key Takeaways
1. Concentrate all domain-model code in one layer that depends on nothing above it — this isolation is a *prerequisite* for domain-driven design, not an optimization.
2. Keep the application layer thin: it holds task-progress state, never business state, and never business rules.
3. Put fundamental business rules in the domain layer even when the application layer is the obvious place to type them.
4. Let infrastructure be called as SERVICES from above; it should not know the domain or initiate domain action.
5. Apply architectural frameworks selectively — use only the features that solve hard problems, to keep business objects readable and later choices open.
6. Choose SMART UI *consciously and completely* for simple, rule-light, data-entry projects with inexperienced teams — and then buy tools built for it.
7. DDD pays off best on ambitious projects and requires strong skills; not every project is ambitious and not every team can muster them.
8. Judge any candidate architecture by one criterion: does it let a cohesive domain design stay loosely coupled to the rest of the system?

## Connects To
- **Ch 3 (Model-Driven Design)**: isolating the domain implementation is what makes literal model↔code correspondence practical.
- **Ch 5 (A Model Expressed in Software)**: what goes *inside* the domain layer — Entities, Value Objects, Services, Modules.
- **Ch 6 (Life Cycle of a Domain Object)**: Repositories and Factories, which mediate between the domain layer and infrastructure.
- **Ch 14 (Maintaining Model Integrity)**: other corrupting influences — other teams' models, unintegrated domain components — handled by BOUNDED CONTEXT and ANTICORRUPTION LAYER.
- **Ch 15 (Distillation)**: making distinctions *within* the domain layer once it becomes unwieldy on its own.
- **MVC / Model-View Separation / Application Coordinator** (Fowler 2002, Larman 1998), **OBSERVER** (Gamma et al. 1995), **TRANSACTION SCRIPT** (Fowler 2002).
