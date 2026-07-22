# Architecture Styles — Full Reference

Read this when comparing styles, sizing an architecture quantum, designing
communication between distributed pieces, or checking a style's known failure
modes before committing to it.

For the chapter-length treatment of any single style, use the
`fundamentals-of-software-architecture-book` skill. This file is the decision
layer, not the tutorial.

## Contents

1. [The Selection Sequence](#1-the-selection-sequence)
2. [The Ratings Table](#2-the-ratings-table)
3. [Monolithic Styles](#3-monolithic-styles)
4. [Distributed Styles](#4-distributed-styles)
5. [The Architecture Quantum](#5-the-architecture-quantum)
6. [Distributed Communication](#6-distributed-communication)
7. [Data Topology and Caching](#7-data-topology-and-caching)
8. [Thresholds](#8-thresholds)

---

## 1. The Selection Sequence

**Do not start here.** Characteristics come first, boundaries second, style third.
A style chosen before the characteristics exist is a style chosen for you by
fashion.

The first fork carries almost all the weight:

**Does one set of architecture characteristics suffice for the whole system?**

- **Yes → monolithic.**
  - Changes mostly **technical** (replace the UI, replace the database) → **Layered**
  - Changes mostly **domain**-shaped, or you're doing DDD → **Modular monolith**
  - Distinct, ordered, **deterministic one-way** processing steps → **Pipeline**
  - Domain requires **customisation** per client, location, or jurisdiction → **Microkernel**
- **No → distributed.**
  - Want distributed benefits at low cost; **ACID** transactions needed; unsure how
    far to decompose → **Service-based** *(also the stepping stone)*
  - System **reacts to things that happened**; needs extreme responsiveness and
    evolvability → **Event-driven**
  - Need **>10,000 concurrent users** or unpredictable spikes, with the database as
    the ceiling → **Space-based**
  - Need **different operational characteristics per service**, plus maximum
    scalability and evolvability → **Microservices**
  - Integration-heavy legacy/modern mix → **ESB as an integration architecture
    only**, never as the whole architecture

**Then, in order:** determine quantum boundaries → decide persistence → choose
communication, **synchronous by default and asynchronous only when necessary**.

Two prior questions worth asking out loud:

- **"Is a monolith disqualified?"** If nobody can name the characteristic that
  rules it out, it isn't. Default to a modular monolith with clean source-level
  boundaries and promote under measured pressure.
- **"Is this a sacrificial architecture?"** A deliberately simple design you
  expect to replace is a legitimate choice, and naming it as such prevents the
  team from over-investing in something that's meant to be thrown away.

---

## 2. The Ratings Table

★ = weak, ★★★★★ = signature strength.

| Style | Cost | Simplicity | Deploy | Test | Scale | Elastic | Fault tol. | Perf/Resp | Evolve |
|---|---|---|---|---|---|---|---|---|---|
| **Layered** | ★★★★★ | ★★★★★ | ★ | ★★ | ★ | ★ | ★ | ★★★ | ★ |
| **Modular monolith** | ★★★★★ | ★★★★★ | ★★ | ★★ | ★ | ★ | ★ | ★★ | ★★★ |
| **Pipeline** | ★★★★★ | ★★★★★ | ★★★ | ★★★ | ★ | ★ | ★ | ★★ | ★★★ |
| **Microkernel** | ★★★★★ | ★★★★★ | ★★★ | ★★★ | ★ | ★ | ★ | ★★★ | ★★★ |
| **Service-based** | ★★★★ | ★★★★ | ★★★★ | ★★★★ | ★★★ | ★★ | ★★★★ | ★★★ | ★★★★ |
| **Event-driven** | ★★★ | ★★ | ★★★ | ★★ | ★★★★ | ★★★★ | ★★★★ | ★★★★ | ★★★★★ |
| **Space-based** | ★ | ★ | ★★★ | ★ | ★★★★★ | ★★★★★ | ★★★ | ★★★★★ | ★★★ |
| **Orchestration SOA** | ★ | ★ | ★ | ★ | ★★★ | ★★★ | ★★★ | ★★ | ★ |
| **Microservices** | ★ | ★ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★★ | ★ | ★★★★★ |

Read the **cost** and **simplicity** columns first. They are where teams
consistently under-estimate, and microservices scoring ★ on both is the entire
reason service-based exists as a stepping stone.

Note microservices scoring ★ on performance and responsiveness. Every network hop
costs, and a system whose driving characteristic is latency is choosing the wrong
style by picking microservices.

---

## 3. Monolithic Styles

### Layered

**Topology:** presentation → business → persistence → database, technically
partitioned. **Quantum:** one.

**Choose when** the system is small, the budget is small, or changes are mostly
technical. It is the default starting point and the cheapest thing that works.

**Avoid when** the domain is the axis of change — every domain feature then cuts
across every layer, and each change touches four places.

**Key mechanism: layers of isolation.** Closed layers mean a request must pass
through each one; that is what makes a layer replaceable. Insert an **open** layer
when you want to enforce an access restriction structurally. Document which layers
are open and closed **and why** — an undocumented open layer becomes a Fast-Lane
Reader, where presentation reaches straight into the database and the isolation is
gone.

**Signature failure: the architecture sinkhole.** Requests that pass through
layers performing no business logic. Up to ~20% is acceptable and normal. At 80%
you have chosen the wrong style. The tempting fix — opening all the layers — fixes
throughput and destroys change management.

### Modular Monolith

**Topology:** single deployment unit, domain-partitioned into modules. **Quantum:** one.

**Choose when** changes are domain-shaped, you're doing DDD, or you want a
credible path toward services later without paying for them now. This is the right
answer far more often than teams expect, and it is the honest alternative when
someone proposes microservices with no characteristic to justify them.

**Avoid when** you genuinely need different operational characteristics per module
— that's a distributed requirement, and no amount of module discipline provides it.

**Governance is the whole game**, because nothing structurally prevents a module
from reaching into another's internals:

1. Namespace-prefix compliance checks.
2. A numeric cap on afferent + efferent **coupling points per module** — pick a
   number, five is a reasonable default, and enforce it.
3. Explicit forbidden-dependency rules via ArchUnit or equivalent.

Without these it becomes an **unstructured monolith** — code so interdependent it
cannot be unraveled — and then a rewrite is the only exit.

A **mediator** can decouple modules by orchestrating requests, so only the mediator
knows each module's API. Note honestly that this *simplifies* coupling rather than
eliminating it: every module is now coupled to the mediator.

### Pipeline

**Topology:** pipes and filters. Each filter does one task; types are producer,
transformer, tester, consumer. **Quantum:** one.

**Choose when** processing is a distinct, ordered, deterministic one-way sequence
— ETL, log processing, compilation, media transcoding.

**Avoid when** the flow needs branching, cycles, or human interaction.

**Governance:** tag each filter with its type via annotations or attributes. This
won't stop a determined developer, but it supplies context at the point of
temptation, which fitness functions cannot easily do here.

### Microkernel (Plugin Architecture)

**Topology:** a minimal core system plus plug-in components. **Quantum:** one
(usually).

**Choose when** the domain requires **customisation** — per client, per country,
per jurisdiction, per device. Tax software, IDEs, insurance rating engines,
browsers. The signal is a core workflow that is stable while the variations
multiply.

**Avoid when** there is no genuine variation axis; then it is indirection with
nothing to spend it on.

**Mechanism:** a registry maps a key to each plug-in reference — point-to-point, a
queue, or a REST URL. Define a standard contract per plug-in domain, and **adapt
third-party contracts** rather than special-casing the core. Runtime plug-ins need
OSGi, Jigsaw, or Prism; compile-time plug-ins are simpler but require full
redeployment.

This is Martin's plugin architecture under a different name, and the two agree: the
core should not know its plug-ins exist.

---

## 4. Distributed Styles

Before any of these, accept the **fallacies of distributed computing**: the network
is reliable, latency is zero, bandwidth is infinite, the network is secure,
topology doesn't change, there is one administrator, transport cost is zero, the
network is homogeneous — plus the authors' additions: versioning is easy,
compensating updates always work, and observability is optional. Every distributed
style pays for all of these.

### Service-Based

**Topology:** a handful (typically 4–12) of coarse-grained domain services, usually
over a shared or logically partitioned database, with a user interface in front.
**Quantum:** usually one, because of the shared database.

**Choose when** you want distributed benefits cheaply, still need **ACID**
transactions, or don't yet know how far to decompose. **This is the default answer
when someone says "microservices" without a characteristic to justify them**, and
it is the designed stepping stone: decompose further later, from a position of
knowledge.

**Data governance:** logically partition the database and mirror it with
**per-domain entity-object libraries**. Lock `common` entity objects in version
control so only the database team may change them. A single all-entities shared
library is an antipattern — every schema change forces every service to redeploy.

### Event-Driven

**Topology:** broker (choreographed) or mediator (orchestrated) event processors.
**Quantum:** varies; asynchronous communication permits multiple quanta.

**Choose when** the system reacts to things that have already happened, and needs
responsiveness plus evolvability. Its evolvability rating is the highest of any
style.

**Avoid when** you need synchronous certainty, straightforward error handling, or
simple debugging. Its simplicity and testability ratings are the worst of the
non-extreme styles for good reason.

**Error handling — the workflow event pattern.** The consumer delegates the error
immediately and moves to the next message; a workflow processor repairs the data
programmatically and resubmits, or routes it to a human dashboard. Repaired
messages then process **out of order** — mitigate by queueing subsequent messages
for the same context (the same account, the same order) in FIFO until the error
clears.

**Preventing data loss** takes three mechanisms together: persisted queues plus
synchronous send (producer → broker), client acknowledge mode (broker → consumer),
and an ACID commit with last participant support (consumer → database). Each one
costs responsiveness and can degrade consistency.

**Known failure modes:** the **swarm of gnats** (too many fine-grained derived
events), **poison events** (a derived event looping forever between services),
**anemic events** (payloads missing the context downstream needs), and **dynamic
quantum entanglement** (two quanta that communicate synchronously have collapsed
into one).

### Space-Based

**Topology:** processing units containing application logic plus an in-memory data
grid, coordinated by virtualised middleware (messaging grid, data grid, processing
grid, deployment manager), with an asynchronous data pump to the database.
**Quantum:** typically one.

**Choose when** you have **more than ~10,000 concurrent users**, unpredictable
spikes, and the **database is the ceiling**. Its scalability, elasticity, and
performance ratings are the best available; its cost, simplicity, and testability
ratings are the worst.

**Avoid** otherwise. This is the most expensive style in the book, and the one most
often adopted for problems a read replica would have solved.

**Watch:** data collisions when the update rate exceeds replication latency
(`Collision Rate = (N × UR²) / S × RL`; plan on **100 ms** replication latency).
Use a **data abstraction layer** with readers and writers carrying transformation
logic, so cache schemas can differ from database schemas — not a data *access*
layer, which couples processing units to database structure.

### Orchestration-Driven SOA

**Topology:** business services, enterprise services, application services,
infrastructure services, tied together by an orchestration engine.

**Use as an integration architecture only** — an ESB connecting a legacy and modern
estate is legitimate. Letting it become the whole architecture is **Accidental
SOA**, and its ratings are the worst across almost every column. It is included
here mainly so you can recognise and stop it.

### Microservices

**Topology:** fine-grained, independently deployable services, each with its own
database, communicating via protocol-aware heterogeneous interoperability.
**Quantum:** many — that's the point.

**Choose when** you need genuinely **different operational characteristics per
service**, plus maximum scalability, elasticity, fault tolerance, deployability,
testability, and evolvability. Six ★★★★★ ratings.

**Avoid when** the driving characteristic is performance or responsiveness (★),
cost (★), or simplicity (★), or when transactions are a dominant feature.

**Granularity is the decision that kills projects.** Too fine gives you **grains of
sand** and a distributed transaction for every use case; too coarse gives you
service-based architecture with extra network hops. Drivers *toward* finer
granularity: differing characteristics, independent scaling, isolated fault
domains. Drivers *toward* coarser: shared transactions, heavy inter-service
chatter, shared data.

**Reuse:** cross-cutting operational concerns go into a per-service **sidecar**,
and sidecars connected by a service plane (Istio) form a **service mesh**. Note the
costs: one sidecar implementation per platform, sidecars that grow large, and drift
between independent teams.

**Never make the API gateway a mediator or orchestrator.** It routes and handles
cross-cutting concerns. A nominally choreographed service that grows into a complex
mediator is the **Front Controller** antipattern.

---

## 5. The Architecture Quantum

**An architecture quantum is the smallest part of a system that can run
independently.** Four conditions, all required:

1. Independently deployable.
2. High functional cohesion.
3. Low external implementation static coupling.
4. Synchronous communication with other quanta within its bounds.

**The database is inside the quantum.** This is the rule that settles most
"are we really microservices?" arguments: six services sharing one database are
**one quantum**, regardless of how many repositories, pipelines, or Kubernetes
deployments exist. One deployment risk, one scaling ceiling, one failure domain.

Two coupling types apply to quanta:

- **Static coupling** — the "wiring": how services depend on one another,
  including operating system, frameworks, and shared databases. Determines quantum
  boundaries.
- **Dynamic coupling** — the forces involved when quanta communicate at runtime.
  Determines whether they stay separate under load.

**Semantic coupling** is the natural coupling of the problem domain, and the
architect has almost no leverage over it. **Implementation coupling** is how the
team chose to implement dependencies, and is fully under the architect's control.
Spend your effort where you have leverage: you cannot make an inherently
interconnected domain into an independent one by deploying it separately.

---

## 6. Distributed Communication

### Synchronous by default

Async buys responsiveness and pays with error handling, ordering guarantees,
debuggability, and testability. Choose it deliberately, per interaction, and record
the reason.

Note the trap: **two quanta communicating synchronously in a required path have
collapsed into one quantum**. If service A cannot answer without a live call to
service B, they deploy, scale, and fail together whatever the org chart says.

### Orchestration versus choreography

| You need | Choose |
|---|---|
| State, error handling, recoverability, restart | **Orchestration** |
| Responsiveness, scalability, decoupling, parallelism | **Choreography** |

Orchestration's costs, stated plainly: a throughput bottleneck, a single point of
failure, fewer parallelism opportunities, and tighter coupling. Choreography's
cost is that nobody owns the workflow, so state and error recovery become
everyone's problem.

For mixed workloads, the **mediator delegation model** classifies events as simple,
hard, or complex and routes everything through a simple mediator (Camel, Mule)
that either handles it or forwards to a BPEL or BPM engine. Camel handling
long-running human-interaction workflows is unmaintainable; a BPM engine handling
simple flows wastes months.

### Event payload: data-based versus key-based

| Criterion | Data-based | Key-based |
|---|---|---|
| Performance & scalability | **Good** | Bad |
| Contract management | Bad | **Good** |
| Stamp coupling | Bad | **Good** |
| Bandwidth | Bad | **Good** |
| Restricted DB access | **Good** | Bad |
| System fragility | Bad | **Good** |

**Decide per event, not per system.** Extreme scale pushes toward data-based;
frequently changing data pushes toward key-based. For updates, include **prior
values** or downstream consumers cannot interpret the change — that's an anemic
event. Passing far more data than the consumer needs is **stamp coupling**, and it
turns every payload change into a coordinated release.

### Request-reply

When an event processor needs an immediate response, use a **correlation ID** — the
reply's CID equals the request's message ID, consumed via a message selector. The
alternative, a temporary queue per request, is simpler but makes the broker create
and delete a queue per request, which hurts badly at volume.

Remember that request-reply merges the two processors into one quantum.

### Broker topology

| | Single broker | Domain broker |
|---|---|---|
| Discovery | Centralised, easy | Harder |
| Infrastructure | Least | More, costlier |
| Fault tolerance | Single point of failure | Isolated per domain |
| Throughput | Ceiling | Scales with domains |
| Boundary fit | Generic | Matches domain partitioning |

---

## 7. Data Topology and Caching

### Database type by read/write priority

- **Write-heavy** → columnar
- **Read-heavy** → key-value, document, graph
- **Balanced** → relational, NewSQL

Amplify the scalability and elasticity styles (microservices, event-driven,
space-based) with key-value or columnar stores.

### Replicated versus distributed caching

| Criterion | Replicated | Distributed |
|---|---|---|
| Optimises | **Performance** | **Consistency** |
| Cache size | <100 MB | >500 MB |
| Data type | Relatively static | Highly dynamic |
| Update frequency | Low | High |
| Fault tolerance | **High** | Low |

Mix both across processing units. **Never use a near-cache** — an unsynchronised
front cache in front of a full backing cache produces inconsistent data and
inconsistent responsiveness, which is the worst of both.

---

## 8. Thresholds

| Metric | Value |
|---|---|
| Cyclomatic complexity | **<5** preferred (industry <10); **>50** unrecoverable by coverage |
| Architecture sinkhole requests | ≤20% acceptable; **80% = wrong style** |
| Domain services on one database | **≤12** |
| Microservices sharing one database | **≤5–6** |
| Modular monolith coupling points per module | **≤5** (pick a number and enforce it) |
| Replicated cache size | **<100 MB**; >500 MB → distributed |
| Replication latency (planning default) | **100 ms** |
| Space-based use threshold | **>10,000 concurrent users** |
| Large team / small team | **>12** / **≤5** |

These are defaults for reasoning, not laws. What matters is that you picked a
number, wrote down why, and made a fitness function enforce it.
