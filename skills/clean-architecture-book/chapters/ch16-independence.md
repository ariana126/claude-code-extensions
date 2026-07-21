# Chapter 16: Independence

## Core Idea
A good architecture supports the use cases, operation, development, and deployment of the system simultaneously, and it does so by decoupling — horizontally into layers and vertically into use cases — while leaving the *decoupling mode* (source, deployment, or service level) itself as an option to be decided as late as possible.

## Frameworks Introduced

- **The Four Supports (use cases and operation, maintenance, development, deployment)**: the architecture must support the intent of the system first.
  - When to use: as the evaluation checklist for any candidate architecture.
  - How:
    - **Use cases**: architecture cannot do much about *behavior*, but it can clarify and expose it. A shopping cart application with a good architecture *looks* like a shopping cart application; use cases are first-class elements at the top level with names that describe their function, so developers never hunt for behaviors.
    - **Operation**: if the system must handle 100,000 customers per second, or query big data cubes in milliseconds, the structure must permit it — as parallel services across servers, lightweight threads sharing one address space, a few isolated processes, or a plain monolith. Which one is *an option a good architect leaves open*.
    - **Development**: Conway's law — "Any organization that designs a system will produce a design whose structure is a copy of the organization's communication structure." Partition into well-isolated, independently developable components allocated to teams.
    - **Deployment**: the goal is *immediate deployment* — deployable straight after build, with no dozens of configuration scripts, property-file tweaks, or hand-made directories.
  - Failure mode: a system written as a monolith that *depends* on being monolithic cannot be upgraded to processes, threads, or services when the operational need arrives.

- **Decoupling Layers (horizontal)**: apply the Single Responsibility Principle and the Common Closure Principle to separate what changes for different reasons.
  - When to use: from the start, when you know the system's intent but not its full use-case list.
  - How: split UI from business rules; split *application-specific* business rules (e.g. input field validation) from *application-independent* ones tied to the domain (e.g. interest calculation, inventory counting), because they change at different rates for different reasons; split database, query language, and schema out as technical details. Result: decoupled horizontal layers — UI, application-specific rules, application-independent rules, database.

- **Decoupling Use Cases (vertical)**: use cases are narrow vertical slices cutting through the horizontal layers.
  - When to use: alongside layering — the two partitions are simultaneous, not alternatives.
  - How: add-order and delete-order change at different rates and for different reasons, so separate their UI from each other, their business rules from each other, and their database usage from each other, all the way down the vertical height of the system. Each use case then uses a different aspect of the UI and database.
  - Why it works: new use cases can be added without interfering with old ones, and teams working on `addOrder` and `deleteOrder` do not collide.

- **Decoupling Mode**: the level at which components are separated — and one of the options a good architecture keeps open.
  - When to use: revisit continuously; the optimal mode changes as the project matures.
  - How: pick from source level, deployment level, or service level (see the table below), and push the decision late.
  - Preferred strategy: **push the decoupling to the point where a service *could* be formed should it become necessary, but leave the components in the same address space as long as possible.** Start at source level; escalate to deployment level if deployment or development issues arise; carefully choose which deployable units become services as pressure grows — and slide back down when operational needs decline.
  - Failure mode of the popular alternative (service level by default): it is expensive in development time and in system resources, and it encourages coarse-grained decoupling — no matter how "micro" the micro-services get, the decoupling is unlikely to be fine-grained enough. Memory and cycles are cheap; development time is not.

- **True vs. False (Accidental) Duplication**: architects fall into a trap that hinges on fear of duplication.
  - When to use: every time the urge to unify two similar-looking things appears during vertical or horizontal separation.
  - How: ask whether **every change to one instance necessitates the same change to every other**. If yes, it is *true duplication* and you are honor-bound as a professional to eliminate it. If the two sections evolve along different paths — changing at different rates and for different reasons — they are *not true duplicates*; return in a few years and they will look nothing alike.
  - Why it works: unifying accidentally-duplicated code is easy now and very hard to undo later; the cost is asymmetric, so bias toward leaving it separate until proven true.

## Key Concepts
- **Conway's law**: any organization that designs a system will produce a design whose structure is a copy of the organization's communication structure.
- **Immediate deployment**: a system that is deployable right after build, without configuration scripts, property tweaks, or manual file arrangement.
- **Application-specific business rules**: rules tied to this application — e.g. validating input fields.
- **Application-independent business rules**: rules belonging to the domain — e.g. calculating interest, counting inventory — that change more slowly and for different reasons.
- **True duplication**: duplication where a change to one instance forces the identical change to every copy.
- **False / accidental duplication**: code that merely looks alike now but changes at different rates and for different reasons.
- **View model**: a separate data structure mirroring a screen's shape, copied from the database record rather than passing the record up to the UI.
- **Decoupling mode**: the level (source, deployment, or service) at which components are separated.
- **Independent develop-ability / independent deployability**: the property that decoupled layers and use cases let teams work and ship without interference — ideally hot-swapping layers and use cases in a running system, adding a use case by dropping in a few jar files or services.

## Mental Models
- **Think of layers and use cases as a grid, not a stack.** You are cutting horizontally into layers and vertically into use-case slices at the same time; every cell is a place a change can be contained.
- **Use "will every change here force the same change there?" as the duplication test** — not "do these look the same?"
- **Think of the decoupling mode as a dial you can turn both ways.** A good architecture lets a system be born as a monolith in a single file, grow into independently deployable units, grow again into services and micro-services, and then slide all the way back down.
- **Use team shape as an architectural constraint, via Conway.** If teams must act independently, the components must already be isolated enough to permit it.

## Reference Tables

| Decoupling mode | Unit of separation | Address space | Communication | Example |
|---|---|---|---|---|
| **Source level** | Source code modules; dependencies controlled so a change doesn't force recompilation of others | Single — one executable in memory ("monolithic structure") | Simple function calls | Ruby Gems |
| **Deployment level** | Independently deployable binaries; source change in one doesn't force others to be rebuilt/redeployed | Many components share one; others in separate processes on the same processor | Function calls; also IPC, sockets, shared memory | jar files, DLLs, Gem files, shared libraries |
| **Service level** | Execution units entirely independent of others' source and binary changes; dependencies reduced to data structures | Separate, location-independent | Network packets only | Services / micro-services |

## Worked Example

**Order entry, decoupled both ways.** Start with the system's known intent (order processing) even though the full use-case list is unknown.

1. *Horizontally*, SRP/CCP separate: UI; application-specific rules (field validation on the order form); application-independent rules (inventory counting); and the database with its schema and query language. Each changes for its own reasons.
2. *Vertically*, split `addOrder` from `deleteOrder` — separate UI, separate business rules, separate database usage — because they change at different rates.
3. The temptation arrives: the add-order and delete-order screens have very similar structure, and the order database record looks just like the order screen's view. Both are almost certainly **accidental** duplication. Do not share the screen code; do not pass the database record up to the UI. Build the separate view model and copy the fields across — cheap now, and it keeps the layers decoupled.
4. Operations benefit for free: because UI, rules, and database are already separated, high-throughput parts can be replicated onto their own servers — *if* the decoupling mode allows it, which is why the components must not assume a shared address space.
5. Mode: start at source level. If deployment or development friction appears, promote some boundaries to deployment level. Only under real development/deployment/operational pressure promote selected deployable units to services.

## Key Takeaways
1. Balance use cases, operation, development, and deployment with one component structure — and accept that you will not know all four sets of requirements, and they will change anyway.
2. Make the use cases visible: the architecture should look like what the system does.
3. Decouple horizontally into layers *and* vertically into use cases; separate what changes for different reasons (SRP, CCP).
4. Never commit knee-jerk elimination of duplication — verify it is true duplication first, because untangling accidental unification later is expensive.
5. Build the view model instead of passing database records to the UI; the resemblance is accidental.
6. Push the decoupling mode decision as late as possible: decouple far enough that a service *could* be extracted, but keep components in one address space as long as you can.
7. Service-by-default is expensive in development time and forces coarse granularity; it is a destination, not a starting point.

## Connects To
- **Ch 15 (What Is Architecture?)**: supplies the four concerns and the "leave options open" strategy that this chapter operationalizes.
- **Ch 17 (Boundaries: Drawing Lines)**: where the lines that make this decoupling real get drawn — and the sad stories of premature service- and tier-level decoupling.
- **Ch 18 (Boundary Anatomy)**: the runtime cost and mechanics of each decoupling mode.
- **Ch 21 (Screaming Architecture)**: makes the "a shopping cart app looks like a shopping cart app" point in full.
- **Single Responsibility Principle / Common Closure Principle**: the tools used to decide what goes on each side of a layer or use-case split.
- **Conway's Law**: the organizational force acting on component structure.
