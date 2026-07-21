# Chapter 4: Architecture

## Core Idea
DDD does not dictate an architecture; it survives inside many of them. Introduce each architectural style only at the moment a real force demands it — and prefer Hexagonal (Ports and Adapters) as the foundation that all the others (SOA, REST, CQRS, EDA, Event Sourcing, Data Fabric) can be layered onto.

## Frameworks Introduced

- **Layers Architecture** [Buschmann et al.]: partition the program into User Interface, Application, Domain, and Infrastructure layers; each layer couples only to itself and below.
  - When to use: single application tier plus a central database; simple client-server or classic N-tier Web/desktop systems.
  - How:
    1. Put view/request concerns only in the User Interface — no domain logic (fine-grained input validation is fine; coarse-grained business validation belongs in the model).
    2. Put use cases in the Application Layer as thin **Application Services**: no business logic, only transaction control, security, and coordination.
    3. Keep all business logic in the Domain Layer.
    4. Put persistence, messaging, SMTP/SMS, frameworks in Infrastructure at the bottom.
    5. Choose **Strict Layers** (couple only to the layer directly below) or **Relaxed Layers** (couple to any layer below) — most real systems are Relaxed.
    6. Let lower layers reach upward only via **Observer** or **Mediator**, never a direct reference.
  - Failure mode: Repository interfaces defined in Domain need Infrastructure implementations, and Infrastructure sits *below* Domain — so honoring Layers either forces implementations into the Application Layer or into `…domain.model.product.impl` implementation Modules. Both are distasteful, and the code is hard to test. That pain is what DIP solves.

- **Dependency Inversion Principle (DIP)** [Martin]: "High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend upon details. Details should depend upon abstractions."
  - When to use: as soon as testability or swappable persistence matters — stub the UI and Infrastructure, test Application + Domain in isolation.
  - How: define Repository and technical Domain Service *interfaces* in the domain model; implement them in Infrastructure; move Infrastructure to the *top* so it implements interfaces for all layers below; acquire implementations by **Dependency Injection**, **Service Factory** (e.g. `DomainRegistry`), or **Plug In**.
  - Why it works: with both high- and low-level concerns depending only on abstractions, the stack topples — there are arguably no layers left, which is exactly where Hexagonal begins.

- **Hexagonal / Ports and Adapters Architecture** [Cockburn]: symmetry between all inputs and outputs; an *outside* of Adapters and an *inside* of application API plus domain model.
  - When to use: many disparate client types, several output mechanisms (RDBMS, NoSQL, cache, messaging), or cloud/mobile expansion; also on greenfield as the overarching style.
  - How:
    1. Design the inside per **functional requirements** — the inner hexagon is the use case boundary, sized by use cases, never by the number of clients.
    2. Publish the inside as a set of **Application Services**; they remain the domain model's only direct client.
    3. For each client protocol add an Adapter (JAX-RS resource, servlet, AMQP message listener) that translates input into API parameters. You normally don't implement the Port itself — HTTP or the messaging mechanism *is* the Port.
    4. Treat Repository implementations as output Adapters; add a separate messaging Adapter on its own Port for outbound Domain Events.
    5. Build in-memory Repositories and test Adapters first — test the whole application before any client or storage technology exists.
  - Why it works: nothing inside leaks outside, so clients and storage become interchangeable late decisions.

- **Service-Oriented Architecture (SOA)**: one Hexagonal Bounded Context exposes multiple technical service endpoints (REST resources, SOAP interfaces, message types) that together form part of a *business* service.
  - When to use: enterprise integration and data migration across many systems; when business strategy must drive technology.
  - How: honor the SOA Manifesto priorities — **business value over technical strategy**, **strategic goals over project-specific benefits**; let linguistic drivers, not endpoint counts, size the Bounded Context.

- **REST** (Fielding): an architectural style, not "XML over HTTP."
  - How: (1) expose meaningful things as **resources**, each with one URI, each with **representations**; (2) stateless communication with self-descriptive messages — no server-side session; (3) a **fixed uniform interface** — GET/PUT/POST/DELETE, with GET safe/cacheable and GET, PUT, DELETE **idempotent** — which is *not* CRUD; (4) **HATEOAS**: embed links so the client discovers state transitions, starting from one well-known URI.
  - REST and DDD: never expose the domain model directly. Either (a) create a separate Bounded Context for the system interface model, driven by use cases and built from Core Domain Aggregates — preferred for specialized solutions; or (b) model standard **media types** (e.g. `ical`) as their own domain model — a **Shared Kernel** or **Published Language** — preferred when the solution is generally reusable.

- **CQRS (Command-Query Responsibility Segregation)**: push Meyer's command-query separation up to an architecture pattern by splitting the model in two.
  - When to use: only when views legitimately cut across many Aggregate types and instances and Repository finders/DTO assembly have become unworkable. "CQRS is the right choice when it removes a risk that has a high probability of causing failure if ignored." Otherwise it is accidental complexity.
  - How:
    1. **Command model (write model)**: Aggregates keep only command methods (void, no getters); Repositories keep only `add()`/`save()` and a single `fromId()`.
    2. **Query model (read model)**: a denormalized store, one table per user interface view, with database *table views* per security role (a manager's view, a normal user's view). Prefer `SELECT * FROM vw_usr_product WHERE id = ?` — primary-key-only selects.
    3. The client submits an explicit **command** — a serialized method invocation — which demands an inductive, task-driven UI design.
    4. Handle commands in one of three styles: **categorized** (several handlers in one Application Service; simplest), **dedicated** (one class, one method; independently redeployable and scalable), **messaging** (asynchronous, dedicated-style; adopt only when scalability demands it). Never let one handler depend on another.
    5. Every command method publishes a Domain Event; a special subscriber uses those Events to update the query model.
    6. Update synchronously (same database/transaction, fully consistent, slower) or asynchronously (eventually consistent, meets SLAs).
  - Failure mode: an eventually consistent query model shows stale data. Mitigate by echoing the just-submitted command parameters in the UI, by displaying the query model record's last-update timestamp so users can request fresher data, or by Comet/Ajax Push or Distributed Cache event subscriptions.

- **Event-Driven Architecture (EDA)**: systems publish and subscribe to Domain Events through dedicated input/output Ports (e.g. AMQP), decoupling everything except the messaging mechanism and the Event types subscribed to.

- **Pipes and Filters**: chain message handlers so each Filter subscribes to an Event, processes it, and publishes a new Event, forming a pipeline. Use it to break a large distributed problem into small steps each system does well. A Filter need not actually filter — it may enrich or merely process.

- **Long-Running Processes (Sagas)**: parallel, distributed, Event-driven processing tracked to completion by an executive.
  - When to use: multi-step distributed work that would time out a user, high-latency legacy integration, or parallelism across nodes.
  - How:
    1. Choose a design: (a) composite task tracked by an **executive** with a persistent state object; (b) **partner Aggregates** that collaborate and hold the state themselves [Helland]; (c) stateless — each handler enriches the outgoing Event with progress.
    2. **Assign a unique Process identity** (e.g. a UUID, or the identity of the initiating Event) carried by every associated Domain Event.
    3. Create an Aggregate-like state tracker at Process start, holding the Process id and an inception timestamp.
    4. On each completion Event, load the tracker by Process id, record the step, and check `isCompleted()`; publish a final Domain Event when true.
    5. De-duplicate: if the completion indicator is already set, ignore-but-acknowledge the duplicate — or design the state object to be **idempotent**.
    6. Handle time-outs **passively** (`hasTimedOut()` checked on each Event; may hang if an Event never arrives) or **actively** (external timer, e.g. JMX `TimerMBean`; costs resources and risks a race).
  - Why it works: it buys distribution and parallelism without distributed transactions — but every participant is inconsistent until final completion, so compensation logic may exceed the complexity of the success path.

- **Event Sourcing**: every operational command on an Aggregate publishes at least one Domain Event; Events are appended to an **Event Store** in order, and the Repository reconstitutes the Aggregate by replaying them oldest-to-newest.
  - When to use: the business requires full change tracking, compliance/audit of every change, temporal models, or extreme write throughput.
  - How: append Events on write; replay on read; take **snapshots** in the background (serialize in-memory state at a point in Event Store history, e.g. every 50–100 Events) and replay only newer Events after the snapshot. Because Events are binary and Aggregates have no getters, pair Event Sourcing with CQRS for querying.
  - Business payoff: patch the Event Store with corrective Events (with a built-in audit trail), undo/redo by replaying different Event sets, and answer "what if?" questions by replaying real history against experimental Aggregates.

- **Data Fabric / Grid-Based Distributed Computing**: an in-memory, replicated, map-based cache acting as an **Aggregate Store** — key = globally unique Aggregate identity, value = serialized Aggregate state.
  - When to use: big data, colossal scale, when a traditional database is the bottleneck.
  - How: use a cache-per-Aggregate strategy behind each Repository; configure primary/secondary node **replication** with fail-over (also guaranteeing Event delivery); publish Domain Events into a dedicated Event region and remove each entry once all subscribers acknowledge; register **Continuous Queries** so UI views are pushed CQRS query model updates just in time; run Long-Running Processes as a GemFire **Function** or Coherence **Entry Processor** executing in parallel across the grid with a result aggregator.

## Key Concepts
- **Strict vs. Relaxed Layers**: strict couples only to the layer directly below; relaxed couples to any layer below.
- **Application Service**: a thin, transaction-controlling client of the domain model expressing one use case; contains no business logic.
- **Port**: a category of input or output channel (HTTP, AMQP, persistence) — a deliberately flexible concept, usually supplied by a container or framework.
- **Adapter**: the translator that converts a client protocol into the application API, or application results into an output mechanism's format.
- **Command model / query model**: the write-side behavioral model versus the denormalized read-side model optimized for display.
- **HATEOAS**: hypermedia as the engine of application state — the server embeds links so the client discovers valid next transitions.
- **Filter**: a message handler that receives an Event, processes it, and publishes the next Event in a pipeline.
- **Process state tracker**: an Aggregate holding the unique Process identity, per-step completion flags, and an inception timestamp.
- **Snapshot**: a serialized image of an Aggregate's state at a point in Event Store history, used to bound replay cost.
- **Accidental complexity**: complexity added by a pattern that the problem did not require — the standing risk of CQRS, DTO assemblers, and Event Sourcing.

## Mental Models
- Think of the inner hexagon as the **use case boundary**: if adding a new client type changes the inside, the boundary has leaked.
- Use DIP when the question "where do I put the Hibernate Repository?" has no comfortable answer — the discomfort *is* the signal that dependencies point the wrong way.
- Think of a Long-Running Process as **eventual consistency with a receipt**: nothing is consistent until the executive's tracker says `isCompleted()`.
- Adopt an architectural style at the moment a business force appears (mobile → REST; disparate clients → Hexagonal; sophisticated dashboards → CQRS; regulated change tracking → Event Sourcing), never because it sounds impressive.

## Anti-patterns
- **Fat Application Services**: if an Application Service grows beyond fetch-Aggregate-and-invoke, domain logic is leaking out and the model is becoming anemic.
- **Domain objects coupled to Infrastructure**: core model classes must never reference persistence or messaging technology.
- **Letting service endpoints size Bounded Contexts**: one REST resource or SOAP interface per Context yields hundreds of miniature Contexts and fragments the Ubiquitous Language.
- **Exposing the domain model directly over REST**: every `Task` structure change breaks clients over details irrelevant to the outside world.
- **CQRS as résumé-building**: for a UI that rarely spans Aggregates, CQRS adds accidental, not necessary, complexity.
- **Coupled Command Handlers**: a handler that calls another handler cannot be redeployed or scaled independently.
- **Untracked parallel completion Events**: without a unique Process identity, out-of-order completions merge the wrong results — trivial in a demo, disastrous in a business domain.

## Code Examples

```java
@Transactional
public void commitBacklogItemToSprint(
    String aTenantId, String aBacklogItemId, String aSprintId) {

    TenantId tenantId = new TenantId(aTenantId);

    BacklogItem backlogItem =
        backlogItemRepository.backlogItemOfId(
                tenantId, new BacklogItemId(aBacklogItemId));

    Sprint sprint = sprintRepository.sprintOfId(
                tenantId, new SprintId(aSprintId));

    backlogItem.commitTo(sprint);
}
```
- **What it demonstrates**: the canonical thin Application Service / Command Handler — obtain Aggregates via Repositories, invoke one command method, hold the transaction, hold zero business logic.

```java
public class BacklogItem extends ConcurrencySafeEntity {
    ...
    public void commitTo(Sprint aSprint) {
        ...
        DomainEventPublisher
            .instance()
            .publish(new BacklogItemCommitted(
                    this.tenant(),
                    this.backlogItemId(),
                    this.sprintId()));
    }
    ...
}
```
- **What it demonstrates**: the command model completes each behavior by publishing a Domain Event — the linchpin that keeps the CQRS query model fresh and, under Event Sourcing, persists the Aggregate itself.

## Reference Tables

| Style | Problem it solves | Reach for it when | Main cost |
|---|---|---|---|
| **Layers** | Separating concerns in a single-tier + database system | Simple client-server; team comfort matters | Infrastructure at the bottom makes Domain interfaces awkward to implement and hard to test |
| **Dependency Inversion Principle** | Domain depending on technical details | You need testability, in-memory persistence, or deferred technology choices | Requires DI/Service Factory wiring discipline |
| **Hexagonal (Ports and Adapters)** | Many disparate clients and output mechanisms | New client types, NoSQL/messaging/cloud, greenfield foundations | A mindset shift; Adapters must be written per protocol |
| **SOA** | Aligning business services with technical endpoints across the enterprise | Enterprise integration, data migration, multiple consumers over REST/SOAP/messaging | "Service-oriented ambiguity"; risk of fragmenting Bounded Contexts |
| **REST** | Loosely coupled, scalable, evolvable distributed interfaces | Mobile and browser clients; many independent, cacheable entry points | Requires a separate interface model or media-type model — never the domain model itself |
| **CQRS** | Views that cut across many Aggregate types and instances | The UI is genuinely sophisticated and Repository finders/DTOs have failed | Two models, two stores, eventual consistency in the UI |
| **Event-Driven Architecture** | Coupling between collaborating systems | Cross-Bounded-Context integration via Domain Events | Only the messaging mechanism and Event types remain shared |
| **Pipes and Filters** | One large distributed problem needing decomposition | Sequential multi-system processing steps | Reordering the pipeline means reconfiguring Event subscriptions |
| **Long-Running Process (Saga)** | Long or parallel distributed work that must not block the user | Time-outs threaten; legacy latency; parallel branches must merge | Eventual consistency plus possibly costly compensation logic |
| **Event Sourcing** | Full historical change tracking and very high write throughput | Regulatory audit of every change; temporal models; "what if?" analysis | Binary Events can't be queried — forces CQRS alongside it |
| **Data Fabric / Grid** | Database as scalability bottleneck | Big data, elastic scale, near-zero impedance mismatch for Aggregates | Framework coupling (e.g. Events subclassing `EntryEvent`); replication tuning |

## Worked Example
Vernon frames the whole chapter as an interview with SaaSOvation's CIO ten years on, and it doubles as a decision log — each style is adopted only when a specific force arrives:

1. **Desktop app persisting to a central database** → **Layers**. One application tier plus a database; nothing more was warranted.
2. **Complexity grows; unit and feature testing needed** → **DIP**. "Turned Layers on its ear." The team stubbed the UI and Infrastructure and tested Application + Domain. Because they already used Aggregates and Repositories, they developed against in-memory persistence behind Repository interfaces and deferred the persistence-technology decision.
3. **Mobile explodes** → **REST** endpoints alongside desktop browsers.
4. **Federated identity, security, BI dashboards, new persistence and messaging needs** → **Hexagonal**. Ports and Adapters let them add client types and output types "almost ad hoc" — NoSQL, messaging, cloud.
5. **Migrating legacy corporate collaboration data for hundreds of new tenants monthly** → **SOA**, aggregating data with Mule's Collection Aggregator sitting on the service boundary, still atop Hexagonal.
6. **Product Owner dashboards spanning all products and defects, per-tenant preferred views, plus mobile** → **CQRS**, once there was "a valid reason to ease the friction between the command and query universes."
7. **Features requiring a series of distributed processes too slow to make a user wait** → **EDA** with **Pipes and Filters**.
8. **Acquisition brings a user base that stresses ProjectOvation** → distribute and parallelize the pipeline with **Long-Running Processes (Sagas)**.
9. **New regulation requires tracking every change to a project** → **Event Sourcing**, which makes compliance a natural part of the domain model.

The lesson Vernon draws: DDD never obstructed any of these moves — choosing DDD early is what let each architectural addition be taken in stride.

## Key Takeaways
1. Introduce an architectural style at the moment a concrete force demands it, not because it is fashionable; each SaaSOvation step was triggered by a business event.
2. Keep Application Services thin — they express use cases, control transactions and security, and coordinate Aggregates; if they grow complex, your model is going anemic.
3. Use DIP to define Repository and technical Service interfaces in the domain model and implement them in Infrastructure; this is what makes in-memory testing and deferred persistence decisions possible.
4. Prefer Hexagonal as the overarching style — it can host SOA, REST, EDA, CQRS, Event Sourcing, and a Data Fabric without changing the inside.
5. Size the application inside by use cases and the Bounded Context by linguistic drivers, never by the count of clients or service endpoints.
6. Never expose the domain model over REST; put a use-case-driven system interface model (or a standard media-type model as Published Language) in between.
7. Adopt CQRS only to remove a high-probability risk; then split into command and query models joined by Domain Events, and explicitly design for the eventual consistency lag in the UI.
8. Give every Long-Running Process a unique Process identity carried by all its Events, a persistent state tracker with `isCompleted()`, de-duplication, and a time-out policy.

## Connects To
- **ch01**: Ubiquitous Language — fragmenting Bounded Contexts along technical service endpoints fragments the Language.
- **ch02**: Bounded Contexts and Subdomains — architecture must not dictate model size; one business service spans several Contexts.
- **ch03**: Context Maps — Shared Kernel and Published Language are the DDD names for media-type-centric REST models.
- **ch07**: Domain Services — stateless domain operations invoked by Application Services; technical implementations supplied via DIP.
- **ch08**: Domain Events, Domain Event Publisher, and the Event Store underpinning EDA, CQRS synchronization, and Event Sourcing.
- **ch09**: Modules — implementation Modules (`…domain.model.product.impl`) hide technical classes under strict Layers.
- **ch10**: Aggregates — the transactional unit committed by each command, and the value stored in a Data Fabric cache.
- **ch11**: Factories — used by Application Services to instantiate new Aggregates.
- **ch12**: Repositories — output Adapters in Hexagonal; in-memory implementations enable early testing.
- **ch13**: Open Host Service and Integrating Bounded Contexts — the published API side of SOA and REST.
- **ch14**: Application Services and Presentation Model — the API of the inner hexagon and the UI's shield from domain objects.
- **Appendix A**: implementing Aggregates with Event Sourcing and projecting CQRS views.
- **Fielding's REST dissertation / HTTP 1.1**: the authoritative definition of resources, uniform interface, and HATEOAS.
- **SOA Manifesto and Erl's service design principles**: the value priorities that align SOA with strategic DDD.
