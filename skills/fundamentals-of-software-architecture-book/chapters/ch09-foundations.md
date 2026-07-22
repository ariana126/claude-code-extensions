# Chapter 9: Foundations

## Core Idea
Before comparing architecture styles you need the shared vocabulary: what a **style** is (versus a pattern), the choice between **technical and domain top-level partitioning**, the monolithic/distributed split, and the **eleven fallacies of distributed computing** that every distributed architecture must pay for.

## Frameworks Introduced

- **What an Architecture Style Describes** — five dimensions, compressed into one name:
  1. **Component topology** — how components and dependencies are organized (layered organizes by technical capability; modular monolith organizes by domain).
  2. **Physical architecture** — monolithic or distributed (a modular monolith is monolithic with a single database; event-driven is *always* distributed).
  3. **Deployment** — granularity and frequency. Monoliths deploy as a single unit with a single relational database; agile distributed styles feature automated integration, provisioning, sometimes automated deployment, and deploy in pieces at a faster cadence.
  4. **Communication style** — method calls inside a monolith; network protocols (REST, message queues) in distributed styles.
  5. **Data topology** — monolithic database vs. separated data, depending on the style's philosophy.
  - **Style vs. pattern**: a *pattern* captures a contextualized solution; a *style* is architecture-specific and describes the topology plus assumed and default characteristics, both beneficial and detrimental.

- **Where styles come from**: no cabal in an ivory tower. An architect notices a new ecosystem capability that solves a nagging problem, combines it with other things new and old, others copy it, and it becomes common enough that naming it eases discussion. **Microservices** is the example: DevOps capabilities + reliable open source operating systems + the DDD philosophy. *Microservices is a label, not a description* — not a commandment to build the smallest possible services, but a reaction to the era's large services and extensive orchestration.

- **Top-Level Partitioning** — the single component arrangement with outsized impact, and one of the first decisions an architect makes:

  | | **Technical partitioning** (layered monolith) | **Domain partitioning** (modular monolith, microservices) |
  |---|---|---|
  | Organized by | Technical capabilities: presentation, business rules, services, persistence | Domains / workflows, inspired by Eric Evans's *Domain-Driven Design* |
  | Organizing principle | **Separation of technical concerns** — changes in persistence potentially affect only adjacent layers | Independent, decoupled domains |
  | Finding code | Easy to find a *category* of code (all persistence in one layer) | Easy to find a *workflow* |
  | Where a workflow lives | **Smeared across all the layers** — `CatalogCheckout` code appears in every layer | Contained in one top-level component, which may still have layers inside |
  | Matches | Model-View-Controller; the default architecture in many organizations | How most real change requests arrive |
  - Industry trend over recent years: **decidedly toward domain partitioning**, for both monolithic and distributed architectures.
  - Neither is more correct (First Law). But top-level partitioning also determines whether the architect initially identifies components technically or by domain.

- **Conway's Law** (Melvin Conway, late 1960s): *"Organizations which design systems…are constrained to produce designs which are copies of the communication structures of these organizations."*
  - Consequence: with a layered architecture it "makes sense" to seat all backend developers together, DBAs in another department, the presentation team in another — an artificial separation of common concerns that can hamper collaboration.
  - **Inverse Conway Maneuver** (Jonny Leroy, Thoughtworks): evolve team and organization structures together to *promote* the desired architecture. Now universally known as **team topologies**.

- **Team Topologies** (Matthew Skelton & Manuel Pais, IT Revolution Press, 2019) — four team types that intersect with architecture:
  - **Stream-aligned teams** — a *stream* is a stream of work scoped to a business domain or capability. These teams focus narrowly on one product, service, or feature set, and move as fast as possible delivering discrete value. **Every other team type exists to reduce friction for them.**
  - **Enabling teams** — bridge a capability gap; a home for research, learning, and other **important but not urgent** work. Supply specialized knowledge to stream-aligned teams. Good ones are highly collaborative and proactive.
  - **Complicated-subsystem teams** — fully understand a complex subsystem or domain and help stream-aligned teams apply it. Goal: **reduce other teams' cognitive load**.
  - **Platform teams** — per Evan Botcher, a platform is *"a foundation of self-service APIs, tools, services, knowledge and support which are arranged as a compelling internal product. Autonomous delivery teams can make use of the platform to deliver product features at a higher pace, with reduced coordination."* They remove needless friction while providing governance around quality and security.

- **The Fallacies of Distributed Computing** — first listed by L. Peter Deutsch and colleagues at Sun Microsystems, 1994. A *fallacy* is something false that someone assumes to be true. All eight still apply; the authors add three more.

  | # | Fallacy | What it costs you |
  |---|---|---|
  | 1 | **The network is reliable** | Service B may be healthy while Service A can't reach it — or A's request is processed with no response returned. This is why **timeouts and circuit breakers** exist. The more a system relies on the network, the more unreliable it can be |
  | 2 | **Latency is zero** | A local method call is nanoseconds/microseconds; the same call over REST/messaging/RPC is **milliseconds** |
  | 3 | **Bandwidth is infinite** | Irrelevant in a monolith; dominant once the system splits into services. Slows the network, worsening #2 and #1 |
  | 4 | **The network is secure** | Every endpoint of every deployment unit must be secured against unknown or bad requests — including interservice calls. The threat surface increases *by magnitudes*, and the extra security is part of why synchronous distributed styles perform slower |
  | 5 | **The topology never changes** | Routers, hubs, switches, firewalls, networks, appliances — all change constantly |
  | 6 | **There is only one administrator** | A typical large company has dozens of network administrators. Who do you ask about latency or a topology change? |
  | 7 | **Transport cost is zero** | Not latency — actual **money**. Distributed architectures cost significantly more: hardware, servers, gateways, firewalls, new subnets, proxies |
  | 8 | **The network is homogeneous** | Most infrastructures have multiple network-hardware vendors, and not all situations, loads, and circumstances have been tested. Lost packets feed back into every other fallacy |
  | 9 | **Versioning is easy** *(authors' addition)* | See trade-offs below |
  | 10 | **Compensating updates always work** *(authors' addition)* | See below |
  | 11 | **Observability is optional** *(authors' addition)* | Logging is *useful* in monoliths and **critical** in distributed architectures, which have many communication failure modes that are hard to debug without comprehensive interaction logs |

  - **Fallacy #2 in practice**: do you know the **average round-trip latency for a RESTful call in your production environment**? 60 ms? 500 ms? At 100 ms average, chaining 10 service calls for one business function adds **1,000 ms**. More important than the average is the **95th–99th percentile**: an average of 60 ms with a 95th percentile of 400 ms is normal, and it is this **"long tail" latency that kills performance in a distributed architecture.** Knowing the average is *the only way* to determine whether a distributed architecture is feasible.
  - **Fallacy #9 trade-offs**: version at the individual service level or the whole system? How far must versioning reach — what portion of the architecture supports it? How many versions to support at once (some teams accidentally honor dozens)? Deprecate at system level or service by service?
  - **Fallacy #10**: *compensating updates* is a pattern where an Orchestrator ensures several related services update jointly, and issues a reversing operation if they don't. Architects blithely assume it always works. **What happens when the compensating update itself fails?** Design for the normal compensation workflow *and* for recovery when both the update and (part of) the compensation fail.

- **Stamp coupling** — passing far more data than the consumer needs.
  - Example: `Service A` (wish lists) needs only the customer name (200 bytes) from `Service B` (customer profiles), but B returns 45 attributes totaling 500 KB. At 2,000 wish-list requests per second, each interservice call consumes **1 GBps of bandwidth**. Returning only the 200 bytes needed uses **400 Kbps**.
  - **Fixes**: private RESTful API endpoints · field selectors in contracts · GraphQL to decouple contracts · value-driven contracts with consumer-driven contracts · internal messaging endpoints.
  - **Underlying rule**: ensure services transmit only the necessary data.

## Worked Example

**Kata: Silicon Sandwiches — partitioning the same problem two ways.**

*Option A — Domain partitioning*: discrete top-level components for `Purchase`, `Promotion`, `MakeOrder`, `ManageInventory`, `Recipes`, `Delivery`, and `Location`. Within many of these sit subcomponents handling both **common** and **local** customization.

*Option B — Technical partitioning*: `Common` and `Local` become top-level components (isolating customization), with `Purchase` and `Delivery` remaining to handle workflow.

**Which is better? It depends.**

| | Domain partitioning | Technical partitioning |
|---|---|---|
| **Advantages** | Modeled on how the business functions rather than an implementation detail · easier to build cross-functional teams around domains · aligns with modular monolith and microservices · **message flow matches the problem domain** · easy to migrate data and components to a distributed architecture | Clearly separates customization code · aligns with the layered architecture pattern |
| **Disadvantages** | Customization code appears in multiple places | Higher **global coupling** — changes to `Common` or `Local` likely affect all other components · developers may duplicate domain concepts in both layers · **higher coupling at the data level** — application and data architects would likely build a single database spanning customization and domains, making the data relationships hard to untangle if they later want to migrate to a distributed system |

**The decisive asymmetry**: technical partitioning's data-level coupling is what forecloses future options. Domain partitioning's cost (duplicated customization code) is local and recoverable.

## Key Concepts

- **Unitary architecture** — computer and software as a single entity. Few exist outside embedded systems and highly constrained environments; systems accrue functionality and must separate concerns to maintain operational characteristics.
- **Client/server (two-tier)** — separates frontend from backend. Three historical flavors: **desktop + database server** (rich Windows client, presentation on the desktop, heavy computation on the database server); **browser + web server** (even thinner client, wider distribution inside and outside firewalls; still called two-tier because web and database servers run on one class of machine in the operations center); **single-page JavaScript applications** (a return to the rich client, written in JavaScript in the browser).
- **Three-tier architecture** — popular in the late 1990s with Java/.NET application servers: database tier, application tier, generated-HTML frontend. Corresponded with **CORBA** and **DCOM**. Today's architects don't worry about that plumbing — the capabilities exist as tools (message queues) or patterns (event-driven architecture).
- **Observability** — the ability to observe each service's interactions with other services and the ecosystem via monitors or logs.
- **Monolithic architecture** — a single deployment unit for all code.
- **Distributed architecture** — multiple deployment units connected through remote access protocols.

**Styles covered in Part II**: *Monolithic* — layered (Ch 10), pipeline (Ch 12), microkernel (Ch 13). *Distributed* — service-based (Ch 14), event-driven (Ch 15), space-based (Ch 16), service-oriented (Ch 17), microservices (Ch 18). Note: the modular monolith (Ch 11) is the fourth monolithic style.

## Mental Models

- **Each style has a "sweet spot."** Learn the styles and their underlying philosophies to know when each works best — or least worst.
- **Long-term design implications elude us.** Java's designers baked **serialization** into the language because three-tier computing was assumed to be permanent. Every Java object implements an interface requiring serialization support. The style came and went; virtually nobody uses serialization, yet new Java features must still support it for backward compatibility, greatly frustrating language designers. **The perpetual advice to favor simple designs is in many ways a future-proofing strategy.**
- **Learn the fallacies from the list, not the hard way.** Every architect learns them one of two ways.

## Anti-patterns

- **Big Ball of Mud** (Brian Foote & Joseph Yoder, 1997, Patterns Languages of Programs conference) — *"a haphazardly structured, sprawling, sloppy, duct-tape-and-baling-wire, spaghetti-code jungle… Information is shared promiscuously among distant elements of the system, often to the point where nearly all the important information becomes global or duplicated."* The structure may never have been well defined, or may have eroded beyond recognition.
  - Modern form: a scripting application with event handlers wired directly to database calls. Many trivial applications start this way and become unwieldy as they grow.
  - Cost: no structure means change gets increasingly difficult, plus problems with deployment, testability, scalability, and performance. Because everything is coupled to everything, changes have hard-to-predict rippling side effects — reaching a critical point where developers spend **all** their time chasing bugs and side effects instead of building features.
  - Cause: rarely intentional; usually **a lack of governance around code quality and structure** (→ Ch 6 fitness functions).
- **Stamp coupling** — see above.
- **Seating teams by technical capability** — Conway's Law turns the org chart into the architecture.

## Key Takeaways
1. Name the style and you've compressed five decisions: component topology, physical architecture, deployment, communication, data topology.
2. Choose top-level partitioning — technical or domain — early; it is one of the first and most consequential decisions.
3. Prefer domain partitioning unless you have a specific reason not to; it matches how change actually arrives and preserves the option to distribute later.
4. Know your production latency **average and 95th–99th percentile** before committing to a distributed architecture. Long-tail latency is what kills you.
5. Budget real money for distributed architecture — hardware, gateways, firewalls, subnets, proxies (Fallacy #7).
6. Transmit only necessary data; hunt stamp coupling with field selectors, GraphQL, or consumer-driven contracts.
7. Treat observability as mandatory, not optional, the moment you distribute.
8. Design the failure path for compensating updates, not just the happy path.
9. Use the Inverse Conway Maneuver: shape teams to promote the architecture you want.
10. Prevent Big Ball of Mud with governance, not intention — nobody sets out to build one.

## Connects To
- **Ch 1**: the First Law governs the partitioning choice.
- **Ch 6**: fitness functions are the governance whose absence produces a Big Ball of Mud.
- **Ch 7**: monolithic vs. distributed follows from architecture quantum analysis.
- **Ch 10–18**: every style chapter revisits partitioning, quanta, and the fallacies.
- **Ch 15**: event-driven architecture as the modern descendant of three-tier messaging.
- **Ch 24**: making teams effective — team topologies in depth.
