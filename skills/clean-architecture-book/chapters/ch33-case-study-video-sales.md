# Chapter 33: Case Study: Video Sales

## Core Idea
A worked architecture for a video-sales website, built by partitioning along two independent dimensions at once: **by actor** (Single Responsibility Principle) and **by level of policy** (the Dependency Rule) — so that components that change for different reasons, and at different rates, are separated.

## Frameworks Introduced
- **Two Dimensions of Separation**: Structure the component architecture along two axes simultaneously — actors (different *reasons* to change) and policy level (different *rates* of change).
  - When to use: at the start of any system, once actors and use cases are known.
  - How: (1) identify the actors; (2) enumerate the use cases per actor; (3) partition the system so a change serving one actor cannot affect another actor; (4) within each actor's slice, split by architectural role — view, presenter, interactor, controller; (5) point all cross-boundary dependencies toward higher-level policy; (6) treat the resulting component set as a *build* structure, keeping deployment grouping free.
  - Why it works: the SRP axis isolates the sources of change (each actor is a source), and the Dependency Rule axis isolates the rates of change (policy is stable, details are volatile). Failure mode: partitioning on one axis only — pure layering ignores actors, pure feature slicing ignores policy level.
- **Use Case Analysis with Abstract Use Cases**: Begin architecture by identifying actors and use cases; factor near-identical use cases into an abstract parent that sets general policy the concrete ones flesh out.
  - When to use: when two use cases are *so similar* that the similarity is worth recognizing and unifying early in the analysis.
  - How: draw the concrete use cases, then extract the shared general policy into a dashed (abstract) use case that both inherit from. Realize it as abstract view and presenter classes in their own components, with the actor-specific components inheriting from them.

## Key Concepts
- **Actor**: A group with a single reason to change the system; per the SRP, each actor is a primary source of change and gets its own partition.
- **Abstract use case**: A use case that sets a general policy which another use case fleshes out (Martin draws these dashed; he prefers his own notation to a UML `<<abstract>>` stereotype).
- **Architectural boundary**: Drawn as double lines in the component diagram; every crossing obeys the Dependency Rule.
- **Controller / Interactor / Presenter / View**: The four architectural roles; input arrives at controllers, interactors process it into results, presenters format results, views display presentations.
- **Component**: A potential `.jar` or `.dll` holding the views, presenters, interactors, and controllers allocated to it.
- **Dependency normal vs. dependency inverted**: *Using* relationships (open arrows) point *with* the flow of control; *inheritance* relationships (closed arrows) point *against* it — the Open–Closed Principle at work.
- **Deployment grouping**: The independent choice of how many deliverables the components are bundled into — a decision kept open and revisable.

## Mental Models
- Think of actors as the *reasons* for change and policy levels as the *rates* of change. A good component structure separates both at once.
- Use the build/deploy split: design the compile and build environment so you *could* ship every component independently, then reserve the right to combine them. Structure is a commitment; packaging is not.
- Think of the arrows as two populations: flow of control runs right to left (controllers → interactors → presenters → views), but most dependency arrows point left to right, toward higher-level policy. When the two disagree, an inheritance relationship is doing the inverting.

## Worked Example

**The product.** A website selling videos (modeled on cleancoders.com). Videos sell to individuals and to businesses. Individuals pay one price to stream and a higher price to download and own permanently. Business licenses are streaming-only, purchased in batches with quantity discounts. Individuals typically act as both viewer and purchaser; businesses often have people who buy videos that *other* people watch. Authors supply video files, written descriptions, and ancillary files (exams, problems, solutions, source code). Administrators add video series, add and delete videos within series, and set prices for the various licenses.

**Step 1 — Use case analysis (Figure 33.1).** Four main actors emerge:

| Actor | Representative use cases |
|---|---|
| Viewer | View Catalog as Viewer, Watch Video |
| Purchaser | View Catalog as Purchaser, Purchase Video |
| Author | Add Video, Add Description, Add Problems, Add Solutions |
| Administrator | Add Series, Delete Series, Add Video to Series, Delete Video, Set License Prices |

The list is deliberately incomplete — log-in and log-out are omitted purely to keep the problem book-sized. The two catalog use cases are so similar that both inherit from an abstract **View Catalog** use case (drawn dashed). That abstraction was not strictly necessary, but recognizing the similarity early was judged wise.

**Step 2 — Component architecture (Figure 33.2).** Double lines mark architectural boundaries. Each of the four roles — Views, Presenters, Interactors, Controllers — is broken up *again* by actor:

| Role \ Actor | Viewer | Purchaser | Author | Administrator | Shared abstraction |
|---|---|---|---|---|---|
| View | Viewer View | Purchaser View | Author View | Admin View | **Catalog View** (abstract) |
| Presenter | Viewer Presenter | Purchaser Presenter | Author Presenter | Admin Presenter | **Catalog Presenter** (abstract) |
| Interactor | Viewer Interactor | Purchaser Interactor | Author Interactor | Admin Interactor | — |
| Controller | Viewer Controller | Purchaser Controller | Author Controller | Admin Controller | — |
| — | | | | | Utilities |

The special **Catalog View** and **Catalog Presenter** components are how the abstract *View Catalog* use case is realized: abstract classes live in those components, and the actor-specific view and presenter classes inherit from them.

**Step 3 — Dependency management.** Flow of control runs right to left: input at the controllers, processed to a result by the interactors, formatted by the presenters, displayed by the views. Most dependency arrows point the *other* way — left to right — because all dependencies crossing a boundary point toward the components containing higher-level policy. Using relationships (open arrows) go with the flow of control; inheritance relationships (closed arrows) go against it, which is the Open–Closed Principle ensuring changes to low-level details don't ripple up into high-level policy.

**Step 4 — Deployment, kept open.** Would you really ship all of these as separate `.jar`/`.dll` files? *Yes and no.* Certainly structure the compile and build environment this way so you *could*. Then choose a grouping:
- Five deliverables: one each for views, presenters, interactors, controllers, utilities.
- Two deliverables: views + presenters in one; interactors, controllers, utilities in the other.
- Two deliverables (most primitive): views + presenters in one; everything else in the other.

Keeping the options open lets deployment adapt as the system changes.

## Key Takeaways
1. Start architecture by identifying actors and use cases — the actors *are* the primary sources of change, per the SRP.
2. Partition so that a change serving one actor cannot affect any other actor.
3. Cut the system on two axes: by actor (different reasons to change) and by policy level (different rates of change).
4. Factor genuinely near-identical use cases into an abstract use case early, and realize it as abstract view/presenter components the concrete ones inherit from.
5. Build for maximum component independence; decide the deployment grouping separately and keep it revisable.
6. Using relationships follow the flow of control; inheritance relationships oppose it. That inversion is the Open–Closed Principle keeping details from rippling upward.

## Connects To
- **Ch 7 (SRP)**: The actor axis of the partitioning is the SRP applied at component scale.
- **Ch 8 (OCP)**: The inheritance arrows pointing against the flow of control.
- **Ch 22 (The Clean Architecture)**: Views, presenters, interactors, and controllers are the circles being made concrete here.
- **Ch 12 (Components)**: Independent deployability is the property the component structure preserves.
- **Ch 34 (The Missing Chapter)**: How to actually organize this in packages so the compiler enforces the boundaries.
- **Conway's Law**: Actor-aligned components tend to align with the teams serving those actors.
