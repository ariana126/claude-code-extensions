# Chapter 16: Space-Based Architecture Style

## Core Idea
Named for **tuple space** (multiple parallel processors communicating through shared memory), this style **removes the central database as a synchronous constraint** by keeping application data in replicated in-memory data grids and pumping updates to the database asynchronously — the only style that maximizes responsiveness, scalability, *and* elasticity simultaneously.

## The Problem It Solves

The typical web request flow — browser → web server → application server → database server — develops bottlenecks as concurrent load rises, in that order. Scaling out web servers is easy and inexpensive, and sometimes works; usually it just **moves the bottleneck to the application server**, which is more complex and expensive to scale, which moves it to the **database**, which is hardest and most expensive of all. The result is a **triangle-shaped topology** with web servers at the wide end and the database at the point.

**In any high-volume application, the database is usually the final limiting factor.** *"It's often better to solve extreme and variable scalability architecturally, rather than try to scale out a database or retrofit caching technologies into an architecture that can't scale as well."*

## Topology — Nine Artifacts

| Artifact | Role |
|---|---|
| **Processing units** | Contain the application functionality |
| **Virtualized middleware** | The collection of infrastructure artifacts managing and coordinating the processing units |
| **Messaging grid** | Manages input requests and session state |
| **Data grid** | Manages synchronization and replication of data between processing units |
| **Processing grid** | *(Optional)* Manages request orchestration across multiple processing units |
| **Deployment manager** | Starts and tears down processing-unit instances as load changes |
| **Data pumps** | Asynchronously send updated data to the database |
| **Data writers** | Perform the updates from the data pumps |
| **Data readers** | Read database data and deliver it to processing units on startup |

- **Processing unit** — contains application logic including web components and backend business logic. Small applications deploy into a single unit; larger ones split by functional area. It can also contain small, single-purpose services (much like microservices). It contains the **in-memory data grid and replication engine**, usually implemented with **Hazelcast**, **Apache Ignite**, or **Oracle Coherence**.
- **Virtualized middleware** — no single product performs all its functions; it's assembled from third-party web servers, caching tools, load balancers, service orchestrators, and deployment managers. Architects can add security, metrics gathering for observability, and so on.
- **Messaging grid** — determines which active processing units can receive an incoming request and forwards it. Complexity ranges from simple **round-robin** to a **next-available** algorithm tracking which unit is most available. Usually implemented with a load-balancing web server (**HA Proxy**, **Nginx**).
- **Processing grid** — mediates when a request requires coordination across processing-unit types (an order-processing unit and a payment-processing unit). **Most modern implementations use separate, fine-grained *orchestration processing units* rather than one coarse-grained orchestration engine**, each handling a single major workflow (an `Order Placement Orchestrator` coordinating `Order Placement`, `Payment`, and `Inventory Adjustment`, with separate orchestrators for returns and stock replenishment).
- **Deployment manager** — continually monitors response times and user loads, starting and stopping units. **Critical to achieving elasticity.** Handled by most cloud infrastructures and by orchestration products like Kubernetes.
- **Partitioning**: technically partitioned — any domain is represented by different technical components (processing units, data pumps, readers/writers, database).
- **Quanta**: variable. **Because processing units don't communicate synchronously with the database, the database is not part of the quantum equation.** Quanta are delineated by the associations between UIs and processing units; **processing units that communicate synchronously — with each other or through the processing grid — are in the same quantum.**

## Frameworks Introduced

- **Replicated vs. Distributed vs. Near-Cache**:

  **Table 16-1. Distributed versus replicated caching**

  | Decision criteria | Replicated cache | Distributed cache |
  |---|---|---|
  | **Optimization** | Performance | Consistency |
  | **Cache size** | Small (<100 MB) | Large (>500 MB) |
  | **Type of data** | Relatively static | Highly dynamic |
  | **Update frequency** | Relatively low | High update rate |
  | **Fault tolerance** | High | Low |

  - **Replicated caching** — each processing unit holds its own in-memory data grid, synchronized across all units sharing that named cache. **Extremely fast and highly fault tolerant — no central server holding the cache means no single point of failure.** The standard model for this style.
    - *Breaks down when*: internal caches grow beyond **100 MB** (each unit consumes so much memory it limits how many instances can start, since units deploy in VMs or containers with fixed memory), or when **cache data updates too frequently** for the data grid to keep up (see Data Collisions).
  - **Distributed caching** — an external server or service holds a centralized cache; processing units store nothing internally and access data via a proprietary protocol. **High data consistency** because data lives in one place and isn't replicated. **But** performance suffers from remote access latency, and **fault tolerance is an issue**: if the cache server goes down, no unit can access or update data. Mirroring mitigates this but can create consistency problems if the primary fails before data reaches the mirror.
  - **The choosing rule**: when cache size is small and update rate low enough for replication to keep up, the decision is **data consistency versus performance and fault tolerance**. Often the deciding factor is the **type** of data: **highly consistent data (inventory counts of available products) → distributed cache**; **infrequently changing reference data (name/value pairs, product codes, descriptions) → replicated cache for quick lookup**.
  - **Both models are usually applicable — and different processing units can use different models.** *Rather than compromising on one consistent caching model, leverage each for its strengths*: distributed for the current-inventory unit, replicated for the customer-profile unit.
  - **Near-cache** — a hybrid bridging in-memory grids with a distributed cache. The distributed cache is the **full backing cache**; each unit's in-memory grid is a **front cache** holding a smaller subset, with an **eviction policy**: *most recently used*, *most frequently used*, or *random replacement* (a good choice when there's no clear analysis justifying either of the others).
    - **The authors do not recommend near-cache in space-based architecture**: front caches are synced with the backing cache but **not with each other**, so multiple units sharing the same data context (a customer profile) will likely hold *different* data — creating inconsistencies in performance and responsiveness between units.

- **Data pumps** — always **asynchronous**, providing eventual consistency between cache and database. When a unit receives a request and updates its cache, **that unit becomes the owner of the update** and is responsible for sending it through the pump. Usually implemented with messaging, which supplies asynchronous communication, **guaranteed delivery, message persistence, and message order via FIFO queuing** — and decouples the unit from the data writer, so an unavailable writer doesn't interrupt processing.
  - Most architectures have **multiple pumps**, usually one per domain or subdomain (customer, inventory), but possibly per cache type (`CustomerProfile`, `CustomerWishlist`) or per processing-unit domain.
  - Pumps have **contracts** including an action (add, delete, update) — JSON schema, XML schema, an object, or a **value-driven message** (a map message of name-value pairs). **For updates the payload usually contains only the new values**: a changed phone number sends just the new number, the customer ID, and the update action.

- **Data writers** — accept pump messages and update the database. Implemented as services, applications, or data hubs (e.g. **Ab Initio**). Two granularities:
  - **Domain-based data writer** — contains all database logic for a domain regardless of how many pumps feed it. Four processing units and four pumps (`Profile`, `WishList`, `Wallet`, `Preferences`) feeding **one** customer data writer.
  - **Dedicated data writer per processing unit** — each writer paired to one pump, containing only that unit's database logic. Produces many components **but gives better scalability and agility because it aligns the processing unit, data pump, and data writer.**

- **Data readers** — read from the database and send data to processing units via a **reverse data pump**. **Invoked in only three situations**: (1) all instances of the same named cache crash, (2) all units of the same named cache are redeployed, (3) archive data not in the replicated cache must be retrieved.
  - **The cold-start flow**: as instances come back up, each tries to grab a lock on the cache. The first to get it becomes **temporary cache owner**; the others wait. The temporary owner sends a message to a queue requesting data; the `Data Reader` performs the query and sends results to the **reverse data pump** queue, which delivers to the temporary owner. Once loaded, the owner releases the lock, all other instances synchronize, and processing begins.

- **Data abstraction layer vs. data access layer** — the readers and writers together form one of these. The difference is **how much the processing units know about the database schema**:
  - **Data access layer**: units are coupled to the underlying data structures, accessing the database indirectly.
  - **Data abstraction layer**: units are **decoupled** from the schemas via separate contracts.
  - **Space-based architecture generally relies on the data abstraction model**, so the replicated cache schema in each unit can differ from the database schema — meaning **incremental database changes don't necessarily affect the processing units**. Readers and writers contain **transformation logic**; if a column type changes or a column/table is dropped, they can **buffer the database change** until the unit caches are updated.

- **The Data Collision formula**:
  ```
  Collision Rate = (N × UR²) / S × RL
  ```
  where **N** = number of service instances using the same named cache, **UR** = update rate in milliseconds (squared), **S** = cache size in rows, **RL** = the caching product's **replication latency** in milliseconds.
  - **Relationships**: N is directly proportional · UR is directly proportional (squared) · **RL is directly proportional** · **S is the only factor inversely proportional — as cache size decreases, collision rates increase.**
  - **On RL**: it depends on network type and physical distance between processing units, must be derived from actual production measurements, and is therefore **rarely published**. **Use 100 ms as a planning number when the actual RL is unavailable.**
  - **Recommendation**: most systems don't have consistent update rates over a long period. **Understand your maximum update rate during peak usage and calculate minimum, normal, and peak collision rates.**

## Code Examples

**Creating a named replicated data grid with Hazelcast** — all processing units needing customer-profile data include this:
```java
HazelcastInstance hz = Hazelcast.newHazelcastInstance();
Map<String, CustomerProfile> profileCache =
	hz.getReplicatedMap("CustomerProfile");
```
When any unit updates the `CustomerProfile` cache, the data grid replicates to **all other units containing that same named cache**. A unit can hold as many named replicated caches as it needs. Alternatively a unit can remotely ask another unit for data (**choreography**) or use the processing grid (**orchestration**).

**Member lists** — each instance holds the IPs and ports of all instances sharing the named cache. With one instance:
```
Instance 1:
Members {size:1, ver:1} [
	Member [172.19.248.89]:5701 - 04a6f863-... this
]
```
As instances join, both lists update:
```
Instance 1:
Members {size:2, ver:2} [
	Member [172.19.248.89]:5701 - 04a6f863-... this
	Member [172.19.248.90]:5702 - ea9e4dd5-...
]
```
And when instance 2 goes down, the caching product **immediately updates the remaining member lists** to remove it (`{size:2, ver:4}`).

**How a new instance joins without touching the database**: it broadcasts a request through the caching provider to join others with the same named cache. Once they acknowledge and connect, **one of them (usually the first to connect) sends the cache data** to the new instance. *This is why additional instances can start without reading from the database — as long as at least one instance holds the named replicated cache.*

## Worked Example

**Data collision — two order-placement instances selling blue widgets.**

A collision occurs when data is updated in cache A and, during replication to cache B, the same data is updated by B. This happens with replicated caching in an **active/active state** — multiple units updating the same data simultaneously — and specifically when **the update rate exceeds the replication latency**.

1. Current inventory: **500 units** in both instances.
2. Instance A receives a purchase for 10 units → updates its cache to **490**.
3. **Before A's data replicates**, instance B receives a purchase for 5 units → updates its cache to **495**.
4. Instance B's cache is overwritten to **490** by A's replication.
5. Instance A's cache is overwritten to **495** by B's replication.
6. **Both caches are wrong and out of sync. The correct answer is 485 in both.**

**Now quantify it.** Baseline: UR = 20 updates/sec, N = 5 instances, S = 50,000 rows, RL = 100 ms.

| Scenario | Change | Updates/hour | Collisions/hour | Percentage | Verdict |
|---|---|---|---|---|---|
| **Base** | — | 72,000 | 14.4 | **0.02%** | Replication is viable |
| **Lower latency** | RL 100 ms → **1 ms** | 72,000 | 0.1 | **0.0002%** | Dramatically better |
| **Fewer instances** | N 5 → **2** | 72,000 | 5.8 | **0.008%** | Directly proportional |
| **Smaller cache** | S 50,000 → **10,000 rows** | 72,000 | **72.0** | **0.1%** | **Worse** — inverse relationship |

**The lesson**: the intuitive lever (shrink the cache) makes collisions *worse*. The real levers are replication latency and instance count. And the calculation tells you *before you build* whether replicated caching is feasible for your data.

## Reference Tables

**Characteristics ratings**

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Elasticity** | ★★★★★ | The driving characteristic — in-memory caching removes the database constraint |
| **Scalability** | ★★★★★ | Can process **millions of concurrent users** |
| **Performance** | ★★★★★ | Same |
| **Simplicity** | ★ | Very complicated: caching, eventual consistency, and many moving parts |
| **Testability** | ★ | **Simulating hundreds of thousands of concurrent users at peak load is very complicated and expensive**, so most high-volume testing occurs **in production** with actual extreme load — incurring significant risk to normal operations |
| **Cost** | ★ | Overall complexity, **licensing fees for caching products**, and the cloud/on-prem resource utilization needed for high scalability and elasticity |

## Common Risks

- **Frequent reads from the database** — the style's benefits depend on caching *all* transactional data. Reads should occur in only two scenarios: **reading archived data** (order history, past bank statements) or **cold-starting** a processing unit. *"If the cached data volumes are so high that most data needs to be archived and retrieved from the backing database, or if processing units crash or are redeployed frequently, this might not be the right architecture for the problem domain."*
- **Data synchronization and consistency** — data is **always eventually consistent**. Because this style is used at very high concurrency, **bottlenecks in the data pump are common**, significantly delaying data reaching the database — a significant risk if downstream systems need updated data quickly.
- **Data loss in the data pump** — mitigate with **persisted queues** (stored on disk as well as in memory) and **client-acknowledgment mode** in the data writers (the message stays in the queue until the writer acknowledges completion, and the broker ensures no other writer reads the in-process message). **These techniques also slow overall responsiveness and degrade data consistency.**
- **High data volumes** — all transactional memory is cached in the units, so volumes must stay relatively low, **particularly as more instances are added**. Watch the in-memory cache size to avoid a unit running out of memory and crashing.
- **Data collisions** — see the worked example.

## Governance
Proper governance is **critical** given the many moving parts. Recommended continuous fitness functions:
1. **Memory consumption** — have each processing-unit instance periodically make its current memory usage observable. Since all instances of a unit share the same replicated cache, this function only needs to report the unit *name*; use a **separate fitness function to record the instance count**, so you can calculate total memory consumption per processing unit.
2. **Synchronization time** — how long a cache update takes to reach the database. **Have each processing unit stream the request ID of an update with a timestamp, and each data writer stream the same request ID with a timestamp after the database commit.** A fitness function associates the IDs and subtracts the timestamps. Track atomically per unit or holistically by averaging. *Analyzing these trends shows whether architecture changes are making synchronization better or worse, and whether the business's timing goals are being met.*
3. **Data pump bottlenecks** — track the **queue depth** of the pump queues. Data pumps act as a backpressure point and **database writes take longer than cache writes**, so they bottleneck. Too much bottleneck increases synchronization time (hurting consistency) and **increases the chances of data loss and data collisions**, particularly at high concurrency.
4. **Read frequency** (requests to data readers) — affects scalability, elasticity, responsiveness.
5. **Scalability, elasticity, and responsiveness themselves** — *since these are the main reasons to use this style, it makes sense to track and measure them.*

## Cloud Considerations
A **unique, powerful feature not found in other architecture styles**: the entire system can be deployed in the cloud, on-premises, **or in both at once**. In the hybrid topology, **applications (processing units and virtualized middleware) run in managed cloud environments while the physical databases and data stay on-prem.** The asynchronous data pumps and eventual consistency model make this work: **transactional processing happens in dynamic, elastic cloud environments while physical data management, reporting, and analytics stay in secure on-prem environments.**

## Data Topologies
Because units don't touch the database directly, this style is **tremendously flexible** in database topology and type — request processing is largely independent of the database. The primary deciding factor is **how the system will use the backing database**:
- **Reporting and data analytics are important** → a monolithic database topology may be more effective — *unless* done through a **data mesh**, in which case domain-based is better.
- **Throughput and domain-based consistency** → a single monolithic database can bottleneck during synchronization, slowing sync time and hurting consistency; **domain-based offers better sync time and consistency if the data can be cleanly domain partitioned.**
- **Downstream systems need the database for further processing** → monolithic may fit better.

## Team Topology Considerations
Technically partitioned, and **most effective with technically partitioned teams aligned to its technical areas** (functionality, data pumps, readers/writers, backend database management) — though it can work with domain-aligned teams.
- **Stream-aligned**: may **struggle**. A stream-based change might touch one or more processing units, data pumps, readers, writers, cache contracts, orchestrators, *and* the backing database — a lot for one team, especially when those artifacts are shared. **The larger and more complex the system, the less effective stream-aligned teams will be.**
- **Enabling**: **a good fit**, because several artifacts (data pumps, readers, writers, virtualized middleware) are shared or cross-cutting. Dedicating a team to one artifact lets them experiment on efficiency independently of the team building primary functionality.
- **Complicated-subsystem**: leverage the technical partitioning to focus on one part (the data grid, the data pumps). **Dealing with data collisions and asynchronous synchronization errors in the data writers is quite complex — a great example of a complicated subsystem that domain-based teams shouldn't have to think about.**
- **Platform**: benefit especially if the infrastructure parts (data pumps, virtualized middleware) are treated as platform-related.

## When to Use
Applications with **high spikes in user or request volume** and **throughput in excess of 10,000 concurrent users**; **variable and unpredictable** concurrent user volumes.

**Concert ticketing system** — concurrent volume stays low until a popular concert is announced, then spikes from several hundred to tens of thousands, all competing for good seats, with tickets selling out in minutes. Only a fixed number of tickets exist regardless of seating preference, so **availability must update continually and as fast as possible** — something a typical database cannot do through standard transactions at that scale and update frequency. **The deployment manager recognizes the surge and starts many processing units; optimally, configure it to start the necessary units shortly *before* tickets go on sale so they're on standby.**

**Online auction system** — same unpredictable spikes; when an auction starts there is no way to know how many people will join or how many concurrent bids will occur per asking price. Units are created as load rises and destroyed as the auction winds down. **Individual processing units can be devoted to each auction, ensuring consistency in the bidding data**, and the asynchronous pumps send bid data to bid history, analytics, and auditing without much latency.

## Key Takeaways
1. Solve extreme scalability **architecturally** — don't retrofit caching into an architecture that can't scale.
2. Default to replicated caching; switch to distributed when the cache exceeds ~100 MB or updates outpace replication. **Mix both in one system, per processing unit.**
3. Avoid near-cache here — unsynchronized front caches create inconsistent data and responsiveness across units.
4. Run the collision-rate formula before committing to replicated caching, using RL = 100 ms if you have no production measurement. Remember cache size is *inversely* related to collisions.
5. Keep readers on the cold-start/archive path only; frequent database reads mean this is the wrong style.
6. Use a data **abstraction** layer with transformation logic in the readers/writers, so schema changes can be buffered rather than forced through to every cache.
7. Instrument memory consumption, synchronization time, and data-pump queue depth as continuous fitness functions — this style is too complex to govern by inspection.
8. Exploit the hybrid cloud/on-prem deployment: elastic transactional processing in the cloud, secure data and analytics on-prem.

## Connects To
- **Ch 7**: architecture quantum — the database is excluded here because communication with it is asynchronous.
- **Ch 6**: fitness functions — this style depends on them more than any other.
- **Ch 15**: EDA's four-star scalability, held back by the database — this chapter is the five-star version. Also preventing data loss (persisted queues, client acknowledge mode).
- **Ch 20**: orchestration versus choreography.
- **Ch 19**: choosing the appropriate architecture style — this is a **specialized** style for maximizing responsiveness, scalability, and elasticity.
