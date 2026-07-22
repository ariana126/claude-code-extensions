# Chapter 20: Architectural Patterns

## Core Idea
**Styles** are named topologies; **patterns** are contextualized solutions to problems. Identify the *pattern* first, then choose the implementation — and never let a tool's name convince you that you've understood the pattern it encapsulates.

## Frameworks Introduced

- **Three distinctions to hold clearly**:
  - **Style vs. pattern** — styles are distinguished by topology, physical architecture, deployment, communication style, and data topology (Ch 9). **Patterns, inspired by *Design Patterns*, are contextualized solutions to problems.**
  - **Pattern vs. "best practice"** — *"Calling something a 'best practice' implies that the architect has a clear duty, anytime a particular situation arises, to utilize that practice. Calling it a **better** practice would at least brook some argument, but no — we call it the **best** practice, allowing architects to shut off their brains and always follow the same solution."*
  - **Pattern vs. solution** — many tools, frameworks, and libraries encapsulate one or more patterns, **with differing degrees of fidelity and intermingling with other patterns**. *"Focus on identifying the most appropriate pattern first, then choose the most appropriate implementation for it."*

- **Orthogonal coupling** — in mathematics, two lines are **orthogonal** if they intersect at right angles, which also implies **independence**. In software architecture, two parts may be orthogonally coupled: **two distinct purposes that must still intersect to form a complete solution.** Monitoring is necessary but independent from domain behavior like catalog checkout. *"Recognizing orthogonal coupling allows architects to find the intersection points that cause the least entanglement between concerns."*
  - An **Orthogonal Reuse pattern** reuses an aspect represented by one or more concerns **that doesn't fit within the preferred hierarchical organization**. Microservices are organized around domains, but **operational coupling cuts across those domains** — a sidecar isolates those concerns in a cross-cutting but consistent layer.

- **The Reuse pattern — separating domain and operational coupling.** The design goal *"duplication is preferable to coupling"* handles domain concerns: two services passing customer profile information keep private internal representations of `Profile` and exchange loosely coupled name-value pairs in JSON, **so each can change its internal representation — including its technology stack — without breaking the integration.** *"Developers generally frown on duplicating code, which can cause issues with synchronization, semantic drift, and more, but some things are worse than duplication…and in microservices, that includes coupling."*
  - **But what about capabilities that *benefit* from high coupling?** Monitoring, logging, authentication and authorization, circuit breakers. *"Allowing each team to manage these dependencies often descends into chaos."*
  - **The concrete problem**: a company standardizing on one monitoring solution makes each service team responsible for implementing it. **How can the operations team be sure each team actually did? And when the standardized tool needs an organization-wide upgrade, how do the teams coordinate that?**

  **Two implementations of the same pattern**:

  | | **Hexagonal architecture** | **Service Mesh** |
  |---|---|---|
  | Shape | Domain logic in the center, surrounded by **ports and adapters** connected to the rest of the ecosystem | Sidecars per service, connected by a service plane |
  | Fit | **General purpose** | **Well suited to microservices and other distributed architectures** |
  | Data | **Treats the database as just another adapter that can be plugged in** — the fatal flaw | Data stays inside the bounded context |

  - **The Hexagonal naming story**: only four of the hexagon's six sides are used. Creator **Alistair Cockburn** drew it as a hexagon and named it accordingly, then **almost instantly regretted it** — *Ports and Adapters* is more descriptive — but it was too late. *"Too many architects thought 'Hexagonal' sounded cool, so the name stuck."*
  - **The Hexagonal flaw — data fidelity.** Hexagonal predates modern microservices and shares many similarities, with one significant difference: **it didn't include the data schema as business logic, because of the (then-common) misperception that the database was an entirely separate piece of machinery.** **Eric Evans corrected this in *Domain-Driven Design* by recognizing that database schemas must change to reflect the system's business logic, regardless of where they reside.**
  - **Why this makes Hexagonal "a constant source of confusion"**: when someone invokes it, *are they describing the separation of operational and domain concerns, or the literal pattern, which would isolate the data and therefore violate a core microservices design principle?* **Using the name as shorthand for "separation of domain and operational concerns" is fine as long as it isn't misleading in context — but architects today have no need for this implementation.**

- **Sidecar / Service Mesh trade-offs (Table 20-1)**:

  | Advantages | Disadvantages |
  |---|---|
  | Offers a consistent way to create isolated coupling | **Must implement a sidecar per platform** |
  | Allows consistent infrastructure coordination | **Sidecar component may grow large/complex** |
  | Ownership per team, centralized, or some combination | **Implementation "drift" between independent teams** |

- **Orchestration vs. Choreography** — four domain services (A through D) collaborate to form a workflow; in the orchestration case there is also a separate coordinator service, the **orchestrator**. *"While we've described this communication as both **orchestration** and **mediation**, the pattern remains the same. Architects benefit from being able to recognize patterns lurking inside implementations because their trade-offs become more apparent."*

  | | **Orchestration** | **Choreography** |
  |---|---|---|
  | **Centralized workflow** | ✅ As complexity rises, a unified component for **state, behavior, and boundary conditions** helps | ❌ **Distributed workflow** — no owner makes managing errors and boundary conditions harder |
  | **Error handling** | ✅ A **state owner** assists error handling, a major part of many domain workflows | ❌ Harder — **domain services must carry more workflow knowledge** |
  | **Recoverability** | ✅ The orchestrator monitors workflow state, so **retry logic can be added** for short-term outages of domain services | ❌ Harder without an orchestrator to attempt retries and remediation |
  | **State management** | ✅ Workflow state is **queryable**, providing a place for other workflows and transient states | ❌ No centralized state holder hinders ongoing state management |
  | **Responsiveness** | ❌ All communication goes through the orchestrator — **a potential throughput bottleneck** | ✅ **Fewer single chokepoints, more opportunities for parallelism** |
  | **Fault tolerance** | ❌ Enhances recoverability for domain services but **creates a potential single point of failure for the workflow**. Redundancy helps but adds complexity | ✅ Multiple instances enhance fault tolerance. *(You could create multiple orchestrators, but because all communication must go through them, they're more sensitive to the workflow's overall fault tolerance)* |
  | **Scalability** | ❌ **The orchestrator adds coordination points, cutting down potential parallelism** | ✅ Lack of coordination points allows more independent scaling |
  | **Coupling** | ❌ Tighter coupling between orchestrator and domain components — sometimes necessary but **frowned upon in microservices** | ✅ No orchestrator means less coupling |

  - *"Any distributed architecture can use any of these communication patterns, and architects should understand how to evaluate their trade-offs. Remember our Second Law: **you can't just do trade-off analysis once and be done with it.**"* *(Note: the book states this as the Second Law here; in Ch 1 it is Corollary 2 of the First Law.)*

- **CQRS (Command-Query-Responsibility-Segregation)** — appears in many distributed architectures and a few monolithic ones. It **splits a commonly monolithic communication with a database into two.**
  - **Client/server (the alternative)**: the application queries the database and performs transactional writes, using the database as part of the application infrastructure.
  - **CQRS**: **isolates writes into one datastore** (usually a database; sometimes another infrastructure such as a **durable message queue**), which **synchronizes the data to another database — usually asynchronously — that services read requests.**
  - **When to use**: systems with **stark differences between read and write volumes**, or that want to **isolate reads from writes for security and other concerns**.
  - **Why it matters**: separating reads and writes lets architects **isolate different architectural characteristics depending on the data**, and **use different data models for each database if necessary.** *"A good example of a data communication pattern that facilitates differing architectural characteristics for different types of data capabilities, security concerns, or other factors that benefit from physical separation."*

- **Single-Broker vs. Domain-Broker** — infrastructure coupling in event-driven architectures. **Event handlers are implemented by brokers, which are part of the architecture's infrastructure**, and **in EDA the topic or queue is typically owned by the sender** — `Payment` needs to know a topic's address to subscribe to it. So `OrderPlacement` "owns" the broker other processors subscribe to; **the infrastructure required to support this service includes the broker.**

  **Table 20-2. Single-Broker pattern trade-offs**

  | Advantages | Disadvantages |
  |---|---|
  | **Centralized discovery** — a single place each processor "knows" to go, and a single place for logging, monitoring, and governance | **Fault tolerance** — if the single broker goes down, **the entire workflow stops working** |
  | **Least possible infrastructure** | **Throughput limits** — the broker risks being swamped as message volume increases |

  **Table 20-3. Domain-Broker pattern trade-offs** — each group of related services shares a broker, **reflecting the architecture's overall domain partitioning**

  | Advantages | Disadvantages |
  |---|---|
  | **Better isolation** | **More difficult discovery of queues/topics** |
  | **Matches domain boundaries** | **More infrastructure = more expensive** |
  | **More scalable** | **More moving parts to maintain** |

  - *"Neither of these approaches is a 'best practice.' Architects must balance discovery with the need to isolate domains."*

## Worked Example

**Why the Hexagonal/Service Mesh comparison is the chapter's central lesson.**

Both patterns solve the *same* problem: **separating domain concerns from operational concerns**. But an architect who reaches for "Hexagonal architecture" in a microservices context inherits a decision made under a **1990s misperception** — that the database is a pluggable adapter external to business logic.

- **In Hexagonal**, the database is an adapter. Swap it freely; the domain doesn't care.
- **In DDD and microservices**, the database schema **is** part of the bounded context. Eric Evans's correction: *database schemas must change to reflect the system's business logic, regardless of where they reside.*
- Therefore **applying Hexagonal literally in microservices violates a core design principle** — it isolates data outside the service.

**The generalized move this teaches**: when a pattern name is invoked, ask *which* claim is being made — the abstract separation, or the literal structure? *"Using the pattern name as shorthand for 'separation of domain and operational concerns' is fine, as long as it isn't misleading in context."* **The key for architects is to identify the pattern first — separation — and then decide how best to implement it in their architecture.**

## Key Takeaways
1. Identify the **pattern**, then choose the implementation. Tools encapsulate patterns at varying fidelity; don't let the tool define your understanding.
2. Reject the phrase "best practice." It exists to let architects stop thinking.
3. Look for **orthogonal coupling** — concerns that are independent yet must intersect. That's where cross-cutting reuse patterns like the sidecar belong.
4. Duplication beats coupling for **domain** concerns; centralized reuse beats duplication for **operational** concerns. Split the two deliberately.
5. Use Hexagonal's name only as shorthand for domain/operational separation — never as a literal structure in microservices, because it externalizes the schema.
6. Choose orchestration for **state, error handling, and recoverability**; choreography for **responsiveness, scalability, and decoupling**. The four-vs-four trade-off table is the decision.
7. Reach for **CQRS** when read and write volumes diverge sharply or when reads must be isolated for security — then give each side its own characteristics and data model.
8. Match broker granularity to domain granularity when fault tolerance and scale matter; keep a single broker when discovery simplicity and cost matter more.
9. Patterns are common because they solve common problems — **architects commonly implement them without realizing it.** Naming them makes their trade-offs visible.

## Connects To
- **Ch 9**: the style vs. pattern distinction is defined there.
- **Ch 15**: mediated EDA — the orchestration pattern under another name; broker infrastructure.
- **Ch 18**: Sidecar, service mesh, and choreography vs. orchestration in microservices.
- **Ch 19**: the Backends for Frontends (BFF) pattern in the Silicon Sandwiches microkernel design.
- **Ch 21**: "best practices" discussed further in the context of architecture decisions.
- **Ch 26**: architectural intersections — where patterns meet the rest of the ecosystem.
