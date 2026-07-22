# Chapter 7: The Scope of Architectural Characteristics

## Core Idea
The old assumption that one set of architecture characteristics covers the whole system is a fatal flaw; the **architecture quantum** gives architects a unit of scope — the smallest independently deployable, functionally cohesive, loosely coupled part of a system — at which characteristics are actually defined.

## Frameworks Introduced

- **Architecture Quantum** — *"the smallest part of the system that runs independently."* Formally, an architecture quantum:
  1. **Establishes the scope for a set of architectural characteristics** — a boundary delineating characteristics, especially operational ones. A useful measure of architecture modularity.
  2. **Is independently deployable** — includes everything needed to function apart from the rest of the architecture. **If an application uses a database, that database is part of the quantum.** Consequence: virtually all legacy systems deployed against a single database are, by definition, a **quantum of one**. Microservices, where each service owns its database, create *multiple* quanta.
  3. **Has high functional cohesion** — the quantum does something purposeful. Meaningless in a monolith (cohesion is the whole system); central in distributed architectures, where each service is designed to match a single workflow — a **bounded context**.
  4. **Has low external implementation static coupling** — derived from DDD's low coupling between bounded contexts. Quanta sit one abstraction level above components and often overlap service boundaries.
  5. **Communicates synchronously with other quanta** — synchronous calls bind operational characteristics across the boundary.
  - When to use: to decide monolith vs. distributed, to set service granularity, and to know where a characteristic actually applies.
  - Why it existed: while writing *Building Evolutionary Architectures*, the authors needed to measure structural evolvability. Code-level metrics reveal low-level detail but can't evaluate dependent components outside the code base — like databases — that dominate operational characteristics. *No amount of effort designing a performant code base succeeds if the database doesn't match.*
  - Latin note: one quantum, many **quanta** (like *datum*/*data*).

- **The Four Types of Coupling** — the vocabulary the quantum definition rests on:

  | Type | Definition | Architect's leverage |
  |---|---|---|
  | **Semantic coupling** | The natural coupling of the problem being solved — an order-processing app inherently couples inventory, catalogs, carts, customers, sales | **Almost none.** A change to the domain is a change to the requirements; no architecture pattern prevents it from rippling |
  | **Implementation coupling** | How the team decides to implement dependencies — one database or several? monolith or distributed? | **Full control.** Barely affects semantic coupling but dominates architecture decisions |
  | **Static coupling** | The "wiring" — how services depend on one another. Two services sharing a coupling point are in the same quantum | Defines **scope** dependencies |
  | **Dynamic coupling** | The forces when quanta must communicate at runtime to form workflows | Determines runtime trade-offs (Ch 15) |

  - The one-line test: **two things are coupled if changing one might break the other.**

- **The Coupling/Scope Rule**: *"Higher coupling is allowed for narrower scopes; the broader the scope, the looser the coupling should be."*
  - Tight coupling is *desirable* where high cohesion is required — inside a service or subsystem.
  - An architecture is **brittle** when one implementation change causes unexpected rippling side effects across ostensibly unrelated things. Renaming a field from `State` to `StateCode` expecting one caller, then discovering many broken dependencies, is the canonical experience.

- **The Scoping Decision Tree** — using characteristic scope to choose an architecture style:
  1. **Does the system need one set of characteristics, or more than one group?**
     - One set → **monolithic architecture** (fewer subsequent choices).
     - More than one → **distributed architecture**.
  2. *(Distributed only)* **Determine the quantum boundaries** — granularity guidelines in Ch 18.
  3. **Choose a persistence mechanism.**
     - Monolith → a single monolithic database; architecture and database developed and deployed in lockstep. Done — move on to picking a monolithic style.
     - Distributed → either a single database (common in event-driven architectures) or data partitioned along service granularity (microservices).
  4. *(Distributed only)* **Choose synchronous or asynchronous communication** between quanta (Ch 15). Note: choosing synchronous communication can *change* the quantum boundaries established through static coupling — the two coupling types interact frequently.

- **Domain-Driven Design's Bounded Context** (Eric Evans, *Domain-Driven Design*, 2003) — a region where everything related to a portion of the domain is visible internally but **opaque** to other bounded contexts.
  - Why it displaced holistic reuse: architects used to seek organization-wide reuse of common entities, but shared artifacts caused tight coupling, harder coordination, and increased complexity.
  - The move: instead of one unified `Customer` class across the organization, **each problem domain creates its own `Customer` and reconciles differences at the communication points.**

## Mental Models

- **Scope is what code metrics cannot see.** Ch 3's metrics analyze the code base; the quantum analyzes everything the code base depends on to run.
- **The database is inside the quantum.** This single rule collapses most "we have microservices" claims — shared database means one quantum, hence one set of characteristics, hence no independent scaling.
- **Synchronous communication is unforgiving.** Asynchronous messaging has less impact because the queue buffers mismatched characteristics — until the producer sustainedly outpaces the consumer and overflows it. Queues absorb *bursts*, not permanent mismatches.
- **Clusters of characteristics are service boundaries.** When characteristics analysis groups naturally, those groups are your first, best guess at quantum boundaries.
- **Cloud shifts the trade-offs, not the job.** Elasticity was hard-won by the previous generation on physical systems and is now a configuration setting — replaced by new concerns like provider availability and heightened security. "The details of software architecture change a lot, but the job of analyzing trade-offs remains constant."

## Worked Example

**Kata: Going Green**

> Going Green (GG) recycles and resells old electronics like cell phones. Users interact through public kiosks *and* a website, both running the same system. A user uploads a device model number and condition; GG bids for it. On acceptance, the user deposits it in a kiosk or GG mails them a box. On receipt, GG assesses the device and pays the user, then estimates its value and either recycles or resells it. The system also produces reports and analytics.

**Characteristics analysis yields three distinct clusters:**

| Cluster | Characteristics | Why |
|---|---|---|
| **Public-facing** (kiosks + website) | Scalability, availability, agility | Customer-visible surface with variable, high load |
| **Back office** | Security, data integrity, auditability | Payments and records |
| **Assessment** | Maintainability, deployability, testability (= **agility**) | GG's business model depends on reselling the highest-value used electronics, and new models ship constantly. The faster they update device assessments, the more newer — hence more valuable — devices they capture |

**Could one system deliver all eight characteristics** (scalability, availability, security, data integrity, auditability, maintainability, deployability, testability)? *Possible, but difficult* — they counteract each other. Fast deployability is harder when you're also prioritizing back-office auditability, and the UI needs a vastly different level of scalability than the rest.

**The move**: stop trying. Use the **clusters as the guide to separating quanta** — draw the quantum boundary around each cluster. Using characteristic scope as a guide to service granularity is a good first step toward the most beneficial set of trade-offs.

**Note the source of the third cluster**: the assessment quantum exists because of a *business driver*, not a technical one. This is how business concerns intersect architecture.

## Scoping and the Cloud
Cloud resources encapsulate many operational characteristics. Two scenarios to distinguish:
- **Cloud as container host** — the cloud is an alternate operations center running and orchestrating containers. Analyze the characteristics of the *containers* plus the constraints introduced by the orchestration tool (e.g. Kubernetes).
- **Cloud-provider resources as system components** — the application is assembled from provider building blocks (triggered functions, managed databases). Analyze the capabilities the provider *advertises and maintains* for that context.

## Key Concepts

- **Architecture quantum** — independently deployable, functionally cohesive, low external static coupling, synchronous communication with other quanta.
- **Functional cohesion** — the semantic binding created by business concepts, not just component-level coupling.
- **Bounded context** — DDD's opaque domain boundary; the philosophy driving per-service databases in microservices.
- **Brittle architecture** — one where a single implementation change ripples unexpectedly.

## Anti-patterns

- **Assuming one set of characteristics for the entire system** — the fatal flaw of outdated frameworks. Sometimes still true, but modern architectures like microservices have different characteristics at the service and system levels.
- **Holistic entity reuse** — one `Customer` class organization-wide. Causes tight coupling, harder coordination, increased complexity.
- **Claiming microservices while sharing a relational database** — several services on the same relational database are one quantum, not many.
- **Designing one system to satisfy mutually antagonistic characteristic clusters** rather than splitting quanta.

## Key Takeaways
1. Define characteristics at the **quantum level**, not the system level.
2. Count the database as part of the quantum — it decides whether you actually have independent deployability.
3. Separate semantic coupling (you can't control it) from implementation coupling (you can) before blaming the architecture.
4. Remember the one-line test: two things are coupled if changing one might break the other.
5. Allow tight coupling in narrow scopes; demand loose coupling as scope broadens.
6. Run the decision tree in order: one characteristic set or many → quantum boundaries → persistence → sync or async.
7. Let clusters of characteristics propose your service boundaries; if the clusters antagonize each other, that's the split.
8. Prefer asynchronous communication between quanta with mismatched operational characteristics — the queue buffers bursts, though never a sustained mismatch.

## Connects To
- **Ch 3**: connascence *locality* is the same insight DDD reintroduced as bounded context.
- **Ch 4**: characteristics being scoped; operational characteristics dominate quantum analysis.
- **Ch 5**: the clustering that emerges from characteristics analysis becomes quantum boundaries.
- **Ch 9**: foundations — monolithic vs. distributed architecture families.
- **Ch 15**: dynamic coupling; synchronous vs. asynchronous communication in event-driven architecture.
- **Ch 18**: microservices, bounded context in depth, and granularity guidelines.
- **Ch 19**: choosing the appropriate architecture style — this decision tree is the entry point.
