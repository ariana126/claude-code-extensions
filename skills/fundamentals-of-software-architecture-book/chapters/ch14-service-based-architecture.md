# Chapter 14: Service-Based Architecture Style

## Core Idea
A hybrid variant of microservices — coarse-grained **domain services** with a separately deployed UI and (optionally) a shared monolithic database — widely considered **the most pragmatic distributed style**, because it delivers most of the operational benefits without the cost and complexity.

## Topology

- **Basic shape**: a distributed *macro-layered* structure — a separately deployed user interface; separately deployed, remote, **coarse-grained** services; and optionally a monolithic database.
- **Domain services** typically represent a specific domain or subdomain (order fulfillment, order shipping), are independent of each other, and are separately deployed. They deploy much like a monolithic application and **do not require containerization**, though Docker or Kubernetes is an option.
- **Practical service limit: no more than ~12** when using a single monolithic database, to avoid change control, scalability, and fault tolerance issues.
- **Instances**: typically one per domain service. Multiple instances are created when scalability, fault tolerance, or throughput demand it — which then requires **load balancing** between the UI and the service so the UI reaches a healthy, available instance.
- **Access**: remotely from the UI, typically **REST**. Alternatives: messaging, RPC, an API layer with proxy or gateway, or SOAP. The UI usually embeds the **service locator pattern** to access services directly; the locator can also live inside an API Gateway or proxy.
- **Partitioning**: domain-partitioned. **Quanta**: ≥ 1 — a shared UI *and* database makes the whole system one quantum; federating either creates multiple quanta.

## Frameworks Introduced

- **Domain service design — two variants**:
  1. **Layered inside the service**: an API Facade layer, a Business layer, and a Persistence layer.
  2. **Subdomain partitioning inside the service**, similar to the modular monolith (Ch 11).
  - Either way, **a domain service must contain an API access facade** that the UI interacts with, and that facade **takes on the responsibility of orchestrating the business request from the UI**.

- **Internal vs. external orchestration — the defining difference from microservices.** An ecommerce order request arrives at the `OrderService` API access facade, which **internally** orchestrates everything needed: placing the order, generating an order ID, applying payment, updating inventory per product. In microservices the same request orchestrates **many separately deployed, remote, single-purpose services**. *This difference in granularity — internal class-level orchestration versus external service orchestration — is one of the most significant differences between the two styles.*

- **ACID vs. BASE transactions**:
  - Coarse-grained domain services support regular **ACID** (atomicity, consistency, isolation, durability) transactions with standard commits and rollbacks, ensuring database integrity **within a single domain service**.
  - Fine-grained microservices must use **BASE** (basic availability, soft state, eventual consistency), which cannot offer the same integrity.
  - **Service-based architecture leverages ACID transactions better than any other distributed architecture style**, because the transaction scope is a whole domain service.

- **The granularity trade-off**:
  | | Service-based (coarse) | Microservices (fine) |
  |---|---|---|
  | Data integrity | Better — ACID within a service | Weaker — eventual consistency, compensating updates |
  | Change blast radius | Changing order placement in `OrderService` requires testing and redeploying **all** its functionality, including payment processing | Changing `OrderPlacement` requires no testing or deployment of `PaymentService` |
  | Risk of collateral breakage | Higher — more functionality per deployment | Lower — each service has a single responsibility |

- **Data topologies** — this style is **unique among distributed architectures in effectively supporting a monolithic database**. It also permits splitting into separate databases, up to one domain-scoped database per service (like microservices). **If splitting, verify no other domain service needs that data**, or you incur interservice communication. *In this style it is usually preferable to share data rather than call another domain service.*

- **The shared-library partitioning technique** — the mechanism for controlling database change (see worked example).
  - **Tip**: *make the logical partitioning in the database as fine-grained as possible — while still maintaining well-defined data domains.*

- **API Gateway options** — adding a reverse proxy or API Gateway between the UI and services is useful for: exposing domain service functionality to external systems; consolidating shared cross-cutting concerns (metrics, security, auditing, service discovery); and load-balancing services with multiple instances.

- **UI options** — the monolithic UI can be split into separate UIs, up to one per domain service, increasing scalability, fault tolerance, and agility. An ordering system might have a customer-facing UI for placing orders plus separate internal UIs for order packers and customer support.

## Reference Tables

**Characteristics ratings** — notably, *no* five-star ratings, but high marks across many vital areas.

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Agility** | ★★★★ | Separately deployed domain services allow faster change |
| **Testability** | ★★★★ | Modularity based on domain scoping gives better test coverage |
| **Deployability** | ★★★★ | Deploy more frequently with less risk than a monolith. *(These three together produce better time to market)* |
| **Fault tolerance** | ★★★★ | Services are usually self-contained and — thanks to code and database sharing — typically avoid interservice communication. If one domain service goes down, the others are unaffected |
| **Availability** | ★★★★ | Same reasoning |
| **Simplicity** | ★★★★ | Differentiator versus microservices, EDA, and space-based |
| **Cost** | ★★★★ | One of the easiest and most cost-effective distributed architectures to implement |
| **Scalability** | ★★★ | Coarse-grained services replicate more functionality than fine-grained ones — less cost-effective and less efficient in machine resources |
| **Elasticity** | ★★ | Same reason, more acutely |

**The governing trade-off**: *the higher the cost and complexity, the better the four-star characteristics (scalability, elasticity, fault tolerance) become.*

## Worked Example

**Going Green — an electronics recycling system.** (Introduced in Ch 7, revisited in Ch 13.)

**The processing flow → the domain services:**

| Step | Domain |
|---|---|
| Customer asks (via website or kiosk) how much Going Green will pay for an old device | **Quoting** |
| If satisfied, customer sends the device in | **Receiving** |
| Going Green assesses the device's condition | **Assessment** |
| If in good working condition, Going Green pays the customer | **Accounting** |
| Customer checks item status on the website at any time | **Item Status** |
| Device is safely destroyed and parts recycled, or resold on a third-party platform (Facebook Marketplace, eBay) | **Recycling** |
| Periodic financial and operational reports on recycling activity | **Reporting** |

**Scaling decision**: only the customer-facing `Quoting` and `ItemStatus` services need higher throughput, so only they get multiple instances. The rest run as single instances — **which makes in-memory caching and database-connection pooling easy to support**.

**UI split**: three UIs — `Customer Facing`, `Receiving`, and `Recycling and Accounting`. This gives fault tolerance at the UI level, scalability, and **security**: external customers have no network path to internal functionality.

**Database split and the quantum boundary**: two separate physical databases — one for external customer-facing operations, one for internal. This puts internal data and operations in a **separate network zone**, giving better security-access restrictions and data protection, and constituting **a separate architecture quantum**. **One-way access through the firewall** lets internal services read and update customer-facing information, but not the reverse. (Alternative: internal table mirroring and external table synchronization to keep the two databases in sync.)

Result: **two quanta** — (1) the customer-facing portion with its own UI, database, and services (`Quoting`, `Item Status`); (2) internal operations for receiving, assessing, and recycling. Note the second quantum contains separately deployed services **and two separate UIs**, but they all share one database — so they are still a single quantum.

**The agility payoff**: the `Assessment` service changes constantly as new products arrive on the market. Service-based architecture isolates those frequent changes to one domain service.

---

**Controlling database change with partitioned shared libraries.**

In this style, the shared class files representing database table schemas — **entity objects** — normally live in a custom shared library (JAR, DLL) used by all domain services. These libraries can also contain SQL.

- **The antipattern**: a **single shared library of all entity objects**. Any change to the database table structures requires changing that library, which means **changing and redeploying every service** — regardless of whether it touches the changed table. Shared library versioning helps, but it is still hard to know which services a table change affects without detailed manual analysis.
- **The fix**: **logically partition the database** and mirror that partitioning with separate shared libraries. Partition into, say, five domains — `common`, `customer`, `invoicing`, `order`, `tracking` — with five matching shared libraries. A change to a table in `Invoicing` touches only `invoicing_entities_lib`, so **only the services using that library are affected**; no others need retesting or redeployment.
- **Handling the `Common` domain**: a `common_entities_lib` used by all services is relatively common and unavoidable. Because changing those tables requires coordinating every service, **lock the common entity objects in version control (if supported) and allow only the database team to make changes.** This controls change and emphasizes the significance of altering tables shared by everything.

## Common Risks

- **Too much interservice communication.** Interservice calls are typical in microservices but are *avoided* here. Domains should be as independent as possible, **with coupling focused only at the database level**. Excessive communication between domain services is a good indication that either the domains were partitioned incorrectly or **this isn't the right style for the problem**.
- **Too many domain services.** The practical upper limit is around **12**; beyond that, expect issues with testing, deployment, monitoring, database connections, and database changes.
- **Uncontrolled database schema change** — see the shared-library antipattern above.

## Governance
Beyond the general structural and operational checks (cyclomatic complexity, scalability, responsiveness):
- **Ensure changes don't span multiple domain services.** If they do, the domain boundaries aren't appropriately defined, or service-based isn't the right style.
- **Govern the amount of communication between domain services.** Some workflows legitimately require it — an `OrderProcessing` domain may need `CustomerNotification` to email order status. But **for the most part domain services should be largely independent, with orchestration taking place at the UI or API Gateway level.**

## Cloud Considerations
Works well in cloud environments despite coarse-grained services. Due to their large scope, domain services are **typically implemented as containerized services rather than serverless functions**, and can easily leverage cloud file storage, database, and messaging services.

## Team Topology Considerations
Domain-partitioned, so it **works best when teams are aligned by domain area** (cross-functional teams with specialization). **Technically partitioned teams (UI, backend, database) do not work well** — assigning domain-based requirements to them requires interteam communication and collaboration that proves difficult in most organizations.
- **Stream-aligned**: works well **if domain boundaries are properly aligned** and streams are focused on a specific domain. **It becomes challenging when streams cross domain service boundaries** — in which case analyze the boundaries and granularity of the services and either realign them to the streams or choose a different style.
- **Enabling**: **not as effective** here as in other distributed architectures, because of the coarse-grained services. Mitigate by carefully identifying and creating appropriate *components* within each domain service, giving specialists something granular to experiment on.
- **Complicated-subsystem**: can leverage the domain-level and subdomain-level modularity to focus on complicated processing independently.
- **Platform**: high modularity lets teams leverage common tools, services, APIs, and tasks.

## When to Use
- Business-related applications wanting distributed benefits without distributed cost.
- Teams practicing **domain-driven design** — coarse-grained, domain-scoped services map naturally onto domains.
- When you need **ACID transactions** in a distributed setting.
- When you want good modularity **without getting tangled up in the complexities of granularity and service coordination** (choreography vs. orchestration, Ch 18).
- **As a stepping stone.** Service-based architectures make good migration targets on the way to another distributed style, or when creating a new distributed system from scratch.

## The Stepping-Stone Argument

> **"Not every portion of an application needs to be microservices."** — Mark Richards

Moving to service-based architecture *first* lets teams analyze the domains and decide which portions **should** become microservices. In Going Green: `Recycling` and `Accounting` don't need further decomposition and should remain domain services. `Assessment` changes frequently and needs high agility, so **that** service should be broken into separate services, one per device type.

**If the team skipped this step and went straight to microservices, every piece of functionality would likely end up as a microservice — even the pieces that didn't need to be.**

> *"It's like buying a Ferrari but only using it to commute to work in rush-hour traffic — sure, it looks cool, but what a waste of power, speed, and agility!"*

## Key Takeaways
1. Keep services coarse-grained and domain-scoped; orchestrate **inside** the service facade, not across the network.
2. Cap domain services at roughly 12 when sharing one database.
3. Prefer sharing data over calling another domain service — heavy interservice chatter means bad domain boundaries or the wrong style.
4. Never ship one monolithic entity-object library. Partition the database logically and mirror it with per-domain shared libraries.
5. Lock common entity objects in version control and route changes through the database team.
6. Federate the UI and database to create separate quanta — and use the split for security zoning, not just scalability.
7. Exploit ACID transactions; this is the one distributed style where they work properly.
8. Use it deliberately as a stepping stone to learn which parts genuinely warrant microservices.

## Connects To
- **Ch 7**: architecture quantum — Going Green's two quanta.
- **Ch 9**: compensating updates (Fallacy #10), which this style largely avoids via ACID.
- **Ch 10 / Ch 11**: layered and modular monolith as the internal design of a domain service.
- **Ch 13**: microkernel — the Going Green example continued.
- **Ch 18**: microservices — granularity, choreography vs. orchestration, and the destination this style steps toward.
- **Ch 19**: choosing the appropriate architecture style.
