# Chapter 18: Microservices Architecture

## Core Idea
The physical embodiment of DDD's **bounded context**: each service owns everything it needs — code, schema, and database — and **favors duplication over reuse**, because reuse is achieved through coupling. **Granularity is the key to success**, and the word *micro* describes *what a service does*, not how big it is.

**Unusual origin**: most styles are named after the fact when architects notice a recurring pattern. Microservices was named early — **Martin Fowler and James Lewis** popularized it in a famous **2014 blog post** that shaped the definition and helped architects understand the underlying philosophy.

## Topology

- **Distributed**: each service runs in its own process, in a virtual machine or container. Services are **much smaller** than in orchestration-driven SOA (Ch 17), EDA (Ch 15), or service-based architecture (Ch 14). **Each service includes all parts necessary to operate independently, including databases and other dependent components.**
- **Why process isolation matters**: multitenant infrastructure (an application server hosting multiple applications) gives operational reuse of network bandwidth, memory, and disk — but **as the supported applications grow, some shared resource inevitably becomes constrained**, plus there's improper isolation between shared applications. Separating each service into its own process solves all sharing problems. *Before freely available open source operating systems and automated machine provisioning, per-domain infrastructure was impractical; cloud resources and containers made extreme decoupling feasible at both the domain and operational level.*
- **The performance cost**: network calls take much longer than method calls, and **security verifications at every endpoint add processing time** — forcing architects to think carefully about granularity.
- **Partitioning**: **decidedly domain-partitioned** — microservices takes domain partitioning to the extreme. **Quanta**: *"the most distinct quanta of any modern architecture — in many ways, it exemplifies what the quantum measure evaluates."*

## Frameworks Introduced

- **Bounded context as physical architecture.** Each service models a particular function, subdomain, or workflow, and includes **everything necessary to operate within it** — logical components and classes, database schemas, and the database itself. Internal parts can be coupled to each other, but are **never** coupled to anything outside the context. This is why microservices is sometimes called a **"share nothing" architecture**.
  - **The concrete consequence**: in a monolith, developers share a common `Address` class across disparate parts of the application. In microservices, **you duplicate `Address` rather than couple to it** — keeping *all* code within the bounded context.
  - **The reasoning**: *"While reuse is generally beneficial, remember the First Law? Everything's a trade-off. The downside of reuse is that achieving it usually requires increasing the system's coupling, either by inheritance or composition. If the architect's goal is a highly decoupled system, they will favor duplication over reuse."*

- **The Three Granularity Guidelines** — how to find appropriate service boundaries:

  | Guideline | Test |
  |---|---|
  | **Purpose** | The most obvious boundary: the **problem domain**. Each microservice should be **functionally cohesive**, contributing one significant behavior on behalf of the overall application |
  | **Transactions** | Bounded contexts are business workflows, and **entities that must cooperate in a transaction suggest a good service boundary**. Because transactions cause issues in distributed architectures, **designing to avoid them tends to produce better designs** |
  | **Choreography** | A set of services may offer excellent domain isolation **but require extensive communication to function** — consider bundling them back into a larger service to avoid the communication overhead |

  - **"The term *microservice* is a label, not a description."** (Martin Fowler) The originators needed a name to contrast with the dominant style circa 2007, **service-oriented architecture — which could have been called "gigantic services."** Many developers take *microservices* as a commandment rather than a description and build services that are far too fine-grained.
  - **"Iteration is the only way to ensure good service design."** Architects rarely discover the perfect granularity, data dependencies, and communication styles on their first pass.

- **Operational reuse via the Sidecar pattern and service mesh** — the answer to "microservices prefers duplication, so how do we handle the parts that genuinely benefit from coupling?" **Traditional SOA reused everything, domain and operational alike; microservices splits the two concerns.**
  - **The problem**: if each team implements monitoring independently, how do you ensure they all do? And who's responsible for upgrading to a new version of the monitoring tool, and how long will it take?
  - **Sidecar** — common operational concerns (circuit breaker, logging, monitoring) appear inside each service as a separate component owned by individual teams or a shared infrastructure team. **When the monitoring tool needs upgrading, the shared infrastructure team updates the sidecar and every microservice receives the new functionality.**
  - **Service mesh** — when every service includes a common sidecar, the sidecars connect through a **service plane** (integration software, typically a product like **Istio**) to form a consistent operational interface across all microservices. Each service becomes a node in the mesh, and the mesh forms a **console giving teams global control of operational coupling** — monitoring levels, logging, other cross-cutting operational concerns.
  - **Service discovery** — how elasticity is built in. A way of automatically detecting and locating services within a network: rather than invoking a single service, a request goes through a discovery tool that **monitors the number and frequency of requests and spins up new instances** to handle scale or elasticity. Often included in the service mesh, and often hosted in the API layer so UIs and calling systems have a single place to find and create services elastically.

- **The API Layer (API Gateway)** — sits between consumers (UIs or other systems) and the microservices. Implementable as a simple reverse-proxy or a more sophisticated gateway containing cross-cutting concerns.
  - **The critical constraint**: *"they should not be used as mediators or orchestrators."* All interesting business logic must reside inside a bounded context; putting orchestration or business logic in a mediator violates that. **Mediators belong to technically partitioned architectures; microservices is firmly domain partitioned.**
  - **Tip**: only include **request routing and cross-cutting concerns** — security, monitoring, logging. **Be careful to avoid putting any business-related logic in the API layer.**

- **Communication: protocol-aware heterogeneous interoperability**:
  - **Protocol-aware** — because there's no centralized integration hub, each service must know how to call others. Architects commonly **standardize on *how* services call each other** (a certain level of REST, message queues), so services know or discover which protocol to use.
  - **Heterogeneous** — because it's distributed, each service can use a different technology stack. **Microservices fully supports polyglot environments.**
  - **Interoperability** — services calling one another. **Architects discourage transactional method calls**, but services commonly call others over the network to collaborate and exchange information.
  - For asynchronous communication, architects use **events and messages**, as in EDA (Ch 15).

- **Choreography vs. Orchestration**:

  | | **Choreography** | **Orchestration** |
  |---|---|---|
  | How | Each service calls others as needed, **no central mediator** — same communication style as EDA | Build a **localized mediator** (an *orchestration service*) whose sole responsibility is coordinating calls |
  | Example | The user requests another user's wish list; `CustomerWishList` lacks some information, so it calls `CustomerDemographics` and returns the combined result | The user calls the `ReportCustomerInformation` mediator, which calls all necessary services |
  | Preserves | The highly decoupled philosophy — **maximum benefits** | Focuses coordination into a single service, **leaving the others less affected** |
  | Costs | **Error handling and coordination become more complex** | **Creates coupling between services** |
  | Degenerate form | **Front Controller pattern** — a nominally choreographed service becomes a complex mediator for some problem *in addition to* its own domain responsibilities. **The downside is that the service taking on multiple roles adds complexity** | — |

  - **The framing**: *"Domain workflows are often inherently coupled, so the architect's job entails finding a way to represent that coupling that best supports the goals of both the domain and the architecture."*
  - **Performance note**: microservices often prefer choreography **because less coupling allows faster communication and fewer bottlenecks.**

- **Transactions and the Saga pattern**:
  - **The primary advice: don't.** *"Building transactions across service boundaries violates the core decoupling principle of microservices, and also creates the worst kind of dynamic connascence, **Connascence of Values**."* **If you find you need transactions to wire your architecture together, that's a sign your design is too granular. Fix the service granularity instead.**
  - **The exception**: when two services need vastly different architecture characteristics requiring distinct boundaries yet still need transactional coordination.
  - **Saga** — named for the literary epic describing a long sequence of events leading to a heroic conclusion. A service acts as mediator across multiple service calls, calling each part, recording success or failure, and coordinating results.
  - **Compensating transaction framework** — if the first part succeeds and the second fails, the mediator **sends a request to all successful participants telling them to undo the previous request.** Usually implemented by having each request enter a **pending** state until the mediator signals overall success. *"However, juggling asynchronous requests can become complex, especially if new requests appear that are contingent on pending transactional state. Regardless of the protocol used, compensating transactions create a lot of coordination traffic at the network level."*
  - **The threshold**: *"It's sometimes necessary for a few transactions to cross services; however, if it's the dominant feature of the architecture, then microservices is likely not the right choice!"*
  - The authors identify **eight different transactional Saga patterns** in Chapter 12 of *Software Architecture: The Hard Parts*.

- **Frontends** — the original vision included the UI inside the bounded context, faithful to DDD. **The practicalities of web-application partitioning make that difficult**, so two styles are common:
  - **Monolithic frontend** — a single UI calling through the API layer. Could be a rich desktop, mobile, or web application; many web applications now use a JavaScript framework to build one UI.
  - **Micro-frontends** — components at the UI level create **a synchronous level of granularity and isolation in the UI *and* the backend services**, forming relationships between UI components and their corresponding backend services. (See *Building Micro-Frontends*, 2nd Ed., Luca Mezzalira.)

## Reference Tables

**Characteristics ratings**

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Deployability** | ★★★★★ | *"Microservices couldn't exist without the DevOps revolution, with its relentless march toward automating operational concerns"* |
| **Testability** | ★★★★★ | Small scope of change per service |
| **Scalability** | ★★★★★ | *"Some of the most scalable systems ever written have used microservices to great success"* |
| **Elasticity** | ★★★★★ | Relies heavily on automation and intelligent integration with operations |
| **Evolvability** | ★★★★★ | Extremely small, highly decoupled deployment units support a faster rate of change — *"modern businesses move fast, and software development has struggled to keep pace"* |
| **Fault tolerance** | ★★★★★ | The independent, single-purpose, fine-grained nature of services |
| **Performance** | ★ | Many network calls; **security checks to verify identity and access at each endpoint** add latency; plus **data latency** — a request requiring multiple services means multiple database calls |
| **Simplicity** | ★ | — |
| **Cost** | ★ | — |

**Performance mitigations**: intelligent data caching and replication to prevent an excess of network calls; choreography over orchestration.

**Data topologies**

| Topology | Verdict |
|---|---|
| **Monolithic database** | **Not an option.** *"Microservices is the only architectural style that **requires** architects to break apart data."* |
| **Domain database** | Also not viable — suffers the same scalability, connection-pool, availability, and fault-tolerance issues, though less extremely |
| **Database-per-Service** | **The standard.** Each microservice owns its data as tables in a separate database or schema |
| **Shared by a few services** | Possible and sometimes necessary — **but no more than five or six services per database or schema** |

**Why a monolithic database fails with 60 services**:
1. **Change control** — changing a column name or dropping a table requires corresponding changes to all 60 services. *"Imagine trying to coordinate the maintenance, testing, and release of five dozen separately deployed services while at the same time releasing the database changes! This task would be daunting, to say the least, and would likely end in disaster."*
2. **It breaks the entire notion of a physical bounded context** — the biggest issue. The context includes the database and data structures; **if every service shares them, the bounded context goes away.**
3. **Scalability and elasticity** — operational tools automatically adjust service instance counts, but **few databases scale accordingly**, causing responsiveness issues and request timeouts.
4. **Connection exhaustion** — connections live in each service *instance*; as services and instances grow, **services quickly run out of available database connections**, causing connection waits and timeouts.
5. **Availability** — if the database goes down (crash, maintenance, backups), **the entire microservices ecosystem goes down.**

**Database-per-Service benefits**: preserves the bounded context, so change is easier to control. Other services must request data through a **contract**, decoupling them from the internal structure — so **a schema change affects only the owning service, and the architect can even change database type (relational → document) without affecting anyone.** Also gives excellent scalability, elasticity, availability, and fault tolerance, and makes connection management far easier.

**When sharing is legitimate**: two or more services writing the same table, or a service outside the context that **must** query directly for performance reasons. Sharing does **not** mean there's no bounded context — **it means the architect has formed a *broader* bounded context.** Valid examples: breaking payment processing into per-type services (credit card, gift card, PayPal, rewards points) that all update the same data; breaking a shipping service into per-method services that all need the same data. **The primary trade-off is controlling database changes** — a schema change now requires coordinating the change and deployment of multiple services, making changes riskier and less agile.

## Worked Example

**A patient medical-monitoring system.** The system reads inputs from patient-monitoring devices, records vital signs, analyzes them for issues or discrepancies, and alerts a medical professional when it finds problems.

**Why it fits**: each vital sign — heart rate, blood pressure, oxygen levels — **is a separate, independent function that manages its own data**, which maps directly onto the bounded-context concept. Each becomes a separate microservice with **its own data store for readings and historical data**.

**The one exception to independence**: a vital sign like heart rate may need additional information from another (a sleep-monitor service) to analyze its readings for warnings.

**Shared services**: `Alert Staff` (common to all vital-sign services; alerts a nurse or doctor when a service notices something wrong) and `Display Vital Signs` (each service **asynchronously** sends its latest reading to the monitor in the patient's room).

**What this demonstrates:**
- **Fault tolerance** — if one vital-sign service crashes or becomes unresponsive, **all other vital-sign monitoring services remain fully operational.** *Especially important in medical monitoring.*
- **Testability** — maintenance on the blood-pressure service has a **testing scope small enough** to be confident that vital sign is fully tested and that other vital-sign services were unaffected.
- **Evolvability** — **another vital-sign monitor can be added without affecting the other services.**

## Anti-patterns / Common Risks

- **Grains of Sand** (named by Mark Richards, 2016) — making services **too small**, like grains of sand on a beach. Architects then have to build communication links back between services to do useful work, **which negates the point and results in a Big Ball of Distributed Mud.** The *micro* in microservices refers to **what** the service does, not how **big** it is.
- **Too much interservice communication** — the fine-grained nature plus tight bounded contexts means services *will* need to communicate, whether for workflow processing (choreography, AWS Step Functions for serverless) or for another service's data. **Excessive dynamic coupling is usually the result of services being too fine-grained, and is fixed by combining them into coarser-grained microservices.**
- **Going overboard with data sharing** — creates risk to change control, scalability, fault tolerance, and agility — **exactly the things microservices does really well.** *"Know when it's necessary to share data and when to fix data sharing through service consolidation."*
- **Reusing code and sharing functionality** — the **often-overlooked** risk. Sharing common functionality through custom libraries (JAR files, DLLs) means **a part of the bounded context falls apart**: reused code is spread across multiple bounded contexts, so **not all functionality for that subdomain is contained within its context, and a change to shared code could break services in other contexts.** Versioning helps but adds significant complication.
- **The Entity Trap in service design** — *"don't simply model services to resemble single entities in a database."* Architects are accustomed to relational databases unifying values into a single source of truth; **that's no longer an option when distributing data.** Every architect must choose: **identify one domain as the source of truth for a fact and coordinate with it, or distribute information through database replication or caching.**
- **Transactions across service boundaries** — see above.

## Governance
*"Governance within a microservices architecture is largely about avoiding structural decay."* The focus is monitoring and controlling **static and dynamic coupling**.

- **Static coupling** — occurs when services share common custom or third-party libraries, **and in the form of contracts when services communicate**. Contracts matter especially: *"while architects can use asynchronous communication protocols to **dynamically** decouple services, they might nevertheless still be **statically** coupled by the contract used between them."*
  - **Tools**: a software bill of materials, deployment scripts, and dependency-management tools help architects understand and govern shared artifacts. *"While we cannot prescribe exactly how much static coupling is too much, we recommend striving to minimize coupling between services."*
- **Dynamic coupling** — **much more difficult to govern**; gathering metrics requires creativity and consistency. Two techniques:
  1. **Logs** — as services call internal or third-party services, they log the interaction with the service invoked, protocol used, and so on. Fitness functions analyze this to understand dynamic coupling levels. **Requires keen governance to ensure every service logs consistently** — a custom library (JAR/DLL) providing a consistent API that all services bind to at compile time is one way.
  2. **Registry entries** — when the first instance of a service starts, it registers its interservice calls via a contract (e.g. JSON) to a custom configuration service or server such as **Apache ZooKeeper**. The architect queries the server to get **a map of all interservice calls throughout the ecosystem.**

## Cloud Considerations
Deployable on-prem (with Kubernetes, Cloud Foundry), but **so well suited to the cloud that microservices is sometimes called a "cloud-native" architecture.** On-demand provisioning of VMs, containers, and databases plus the services-based approach in cloud environments fits the style well.

**Why serverless isn't a separate architecture style**: *serverless* is a cloud-computing model where functions are triggered on request, allocating machine resources on demand (AWS Lambdas, Google cloud functions, Azure cloud functions). **The authors consider it a *deployment model* of microservices, not a style** — because a microservice is defined as a single-purpose, separately deployed unit that does **one thing** really well, which also describes a serverless function. **Microservices in the cloud need not be serverless**; most cloud vendors have adopted Kubernetes, so containerized microservices deploy just as easily.

## Team Topology Considerations
Domain-partitioned, so it **works best when teams align by domain area** (cross-functional teams with specialization). **Technically partitioned teams (UI, backend, database) do not work well** — assigning domain-based requirements to them requires interteam communication and collaboration that proves difficult in most organizations.
- **Stream-aligned**: work well **if domain boundaries are properly aligned** and streams focus on a specific domain. **Becomes challenging when streams cross multiple bounded contexts and services** — in which case analyze the bounded contexts and granularity and either realign them to the streams or choose a different style.
- **Enabling**: **most effective when they can use shared services for specialized or cross-cutting concerns.** The high modularity lets them work independently from stream-aligned teams without getting in the way. Working with platform teams, they can **help create the sidecar components that make up a service mesh.**
- **Complicated-subsystem**: leverage service-level modularity to focus on complicated domain processing, staying independent of other teams and services.
- **Platform**: often (with enabling teams) **focus on creating and maintaining the cross-cutting operational functionality in sidecars and the service mesh, freeing stream-aligned teams from operational concerns.**

## Enforced Heterogeneity — a Case Study
A well-known pioneer of the style was chief architect at a startup building personal-information management software for mobile devices. Because mobile moves so fast, the architect wanted to ensure **no development team could accidentally create coupling points**. The teams had a wide mix of technical skills, so the architect **mandated that each development team use a *different* technology stack**. If one team used Java and another .NET, **it would be impossible for them to share classes accidentally.**

*"This approach is the polar opposite of most enterprise governance policies, which insist on standardizing on a single technology stack. In the microservices world, the goal isn't to create the most complex ecosystem possible, but to choose the correct scale of technology for the narrow scope of the problem. **Not every service needs an industrial-strength relational database, and forcing one on a small team is more likely to slow them down than to benefit them.**"*

## Key Takeaways
1. Favor **duplication over reuse** — reuse is implemented through coupling, and coupling is what this style exists to eliminate.
2. Size services by **purpose, transaction boundaries, and choreography overhead** — never by the word *micro*.
3. Treat "we need a distributed transaction" as a **granularity defect**, not a technical problem to solve with Sagas.
4. Keep the API layer to routing and cross-cutting concerns; business logic belongs inside a bounded context.
5. Put shared operational concerns in **sidecars** and unify them with a **service mesh** — that's the one place coupling is legitimate.
6. Use Database-per-Service by default; share a database across at most five or six services, and only to form a deliberately **broader** bounded context.
7. Never share business code via custom libraries — that fractures the bounded context and versioning only masks it.
8. Govern static coupling (libraries and contracts) with SBOMs and dependency tools; govern dynamic coupling with consistent interservice logging or a registry map.
9. Prefer choreography for performance and decoupling; introduce a localized orchestration service only when a complex workflow would otherwise force a Front Controller.
10. Iterate on boundaries. Nobody gets granularity right the first time.

## Further Reading
- *Building Microservices*, 2nd Ed., Sam Newman (O'Reilly, 2021)
- *Building Micro-Frontends*, 2nd Ed., Luca Mezzalira (O'Reilly, 2025)
- *Microservices vs. Service-Oriented Architecture*, Mark Richards (O'Reilly, 2016)
- *Microservices AntiPatterns and Pitfalls*, Mark Richards (O'Reilly, 2016)
- *Software Architecture: The Hard Parts*, Ford, Richards, Sadalage & Dehghani (O'Reilly, 2021) — Ch 7 on granularity, Ch 12 on the eight Saga patterns

## Connects To
- **Ch 3**: Connascence of Values — the worst dynamic connascence, created by cross-service transactions.
- **Ch 7**: bounded context and architecture quantum — microservices is the quantum measure's clearest expression.
- **Ch 8**: the Entity Trap, reapplied at service level.
- **Ch 9**: the fallacies of distributed computing, all of which apply in full.
- **Ch 14**: service-based architecture — the coarser-grained stepping stone.
- **Ch 15**: EDA — the asynchronous communication and choreography model.
- **Ch 17**: orchestration-driven SOA — the style microservices was a direct reaction against.
- **Ch 19**: choosing the appropriate architecture style.
