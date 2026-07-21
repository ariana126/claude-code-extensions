# Clean Architecture — Patterns & Techniques

Every concrete technique in the book, with when/how/trade-offs. Chapter references in parentheses.

## The Clean Architecture (Ch22)
**When to use**: as the default target structure for any system with non-trivial business rules that must outlive its delivery mechanism.
**How**: four concentric circles — Entities → Use Cases → Interface Adapters → Frameworks & Drivers. Enforce the Dependency Rule: source code dependencies point only inward. Cross boundaries with the Dependency Inversion Principle: the inner circle declares an interface, the outer circle implements it. Pass only simple, isolated data structures across a boundary — never an Entity, a DB row, or a framework type.
**Trade-offs**: more indirection and more classes than a layered CRUD app. The payoff is deferral: DB, web, and framework decisions stay open. Not worth it for a system that is genuinely just a thin CRUD skin over a schema.

## Plugin Architecture (Ch5, Ch11, Ch17, Ch26)
**When to use**: whenever a volatile mechanism (DB, UI, device, third-party service) must be replaceable, and always to protect business rules.
**How**: invert the dependency so the volatile component is the plugin and the business rules are the host. The business rule owns the interface; the plugin implements and registers itself. `Main` wires the plugins in.
**Trade-offs**: an interface + a factory per plugin point. Buys independent deployability and testability; costs a layer of indirection at every crossing.

## Humble Object Pattern (Ch23)
**When to use**: at any boundary where behavior is hard to test — GUIs, databases, message listeners, hardware.
**How**: split the module in two. The **humble** half holds only what is hard to test and is kept as dumb as possible (the View: move this text to this field). The testable half holds all the behavior (the Presenter: format the date, decide the button state, build the View Model).
**Trade-offs**: two objects where there was one. In exchange, essentially all logic becomes unit-testable without the untestable substrate. Applies symmetrically to Database Gateways, Data Mappers, and Service Listeners.

## Partial Boundaries — Skip the Last Step (Ch24)
**When to use**: you suspect a boundary will be needed but can't justify the full cost yet.
**How**: do all the design work — separate interfaces, independent components, inverted dependencies — but compile and deploy them as a single component. The seam exists; the deployment split does not.
**Trade-offs**: near the full design cost, none of the deployment benefit — but upgrading later is cheap. The most common and most defensible partial boundary.

## Partial Boundaries — One-Dimensional Boundary / Strategy (Ch24)
**When to use**: a boundary you want cheap and one-directional.
**How**: a service interface implemented by a client, injected from above (the Strategy pattern applied structurally).
**Trade-offs**: cheap, but nothing prevents someone from taking a backchannel around it. Degrades quietly.

## Partial Boundaries — Facade (Ch24)
**When to use**: the cheapest possible boundary; you mainly want a single point of access.
**How**: a Facade class listing all the services as methods and routing calls to them.
**Trade-offs**: cheapest of the three, but the client still depends transitively on every service class, and there is no dependency inversion at all. Weakest protection.

## Abstract Factory (Ch11)
**When to use**: an inner (high-level) component must create an instance of an outer (concrete) type without depending on it.
**How**: the inner circle declares a factory interface; the concrete factory lives outside and is implemented by the detail layer. `Main` supplies it.
**Trade-offs**: the standard remedy for the "creation violates DIP" problem. Adds a factory interface per created family.

## Main as the Ultimate Detail (Ch26)
**When to use**: always — every system has exactly one.
**How**: `Main` is the dirtiest, lowest-level component. It creates the factories, strategies, and global facilities, injects them, and hands control to the high-level policy. It is the initial plugin to the application.
**Trade-offs**: intentionally ugly. Concentrating all the dirt in one place is the point — no other component has to know a concrete name.

## Breaking Dependency Cycles (Ch14, ADP)
**When to use**: the moment the component dependency graph acquires a cycle.
**How**: two options. (1) Apply DIP: invert one edge — the depended-upon component declares an interface the other implements. (2) Extract a new component that both cyclic components depend on.
**Trade-offs**: option 2 grows the component count and makes the structure "jitter" as it evolves; that jitter is normal and should be managed, not prevented.

## Component Metrics / Main Sequence Analysis (Ch14)
**When to use**: periodic architectural health checks on a large codebase.
**How**: compute `I = Fan-out / (Fan-in + Fan-out)`, `A = Na / Nc`, and `D = |A + I − 1|` per component. Plot A against I. Investigate anything with high `D`, and anything in the Zone of Pain (concrete + heavily depended on) that is also volatile.
**Trade-offs**: measures structure, not correctness. A high-`D` component may be justified; the metric flags candidates, not defects.

## Testing API (Ch28)
**When to use**: your test suite is coupled to the application's structure and breaks whenever the app is refactored (the Fragile Tests Problem).
**How**: give tests a dedicated API that bypasses security, expensive resources, and the UI, and speaks in terms of *what* is verified rather than *how* the app is built. Tests depend on the API; the API depends on the app.
**Trade-offs**: a superpower for decoupling — and a security hole if it ships. Keep the testing API and its dangerous implementation in a separate, independently deployable component that never reaches production.

## Hardware / OS Abstraction Layer (Ch29)
**When to use**: embedded work, or any system where a specific processor, board, or OS would otherwise leak everywhere.
**How**: define a HAL that expresses *services the software needs*, not the chip's register map, and an OSAL above it. Program to those interfaces so hardware becomes substitutable and the software is testable off-target. Never let processor headers or `#ifdef BOARD_V2` spread into application code.
**Trade-offs**: an extra indirection layer in a domain that counts cycles. Buys escape from the target hardware bottleneck — the ability to test without the board.

## Package by Component (Ch34, Simon Brown)
**When to use**: as the default code organization inside a service or monolith.
**How**: one package per coarse-grained component, exposing a public interface and keeping the implementation, repository, and internal types package-private. Contrast with Package by Layer (horizontal slices), Package by Feature (vertical slices), and Ports and Adapters (domain + inside/outside).
**Trade-offs**: gives real encapsulation the compiler enforces, rather than an organization the diagram merely asserts. Requires discipline about access modifiers — making everything `public` destroys it regardless of package structure.

## Segregation of Mutability / Event Sourcing (Ch6)
**When to use**: concurrency and consistency problems traceable to mutable shared state.
**How**: partition the system into immutable components and the smallest possible mutable ones; push as much processing as possible into the immutable side. Taken to its limit: store transactions rather than state, and derive state by replaying them (CR, not CRUD).
**Trade-offs**: requires storage and compute proportional to history; snapshotting bounds it. Removes whole classes of race and update anomaly.

## Facade over an Actor Split (Ch7, SRP)
**When to use**: an SRP fix has split one class into several and callers now need a single entry point.
**How**: move each actor's methods into its own class over a shared data structure, then provide a Facade that instantiates and delegates to them.
**Trade-offs**: callers keep one dependency; the Facade must stay thin, or it becomes the god class you just removed.
