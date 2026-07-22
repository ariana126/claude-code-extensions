# Chapter 10: Layered Architecture Style

## Core Idea
The layered (n-tiered) architecture organizes components into horizontal **technical** layers with **layers of isolation** enforced by closing them; it is the cheapest, simplest, most familiar style — and every one of its virtues degrades as the code base grows.

## Topology

- **Four standard layers**: Presentation → Business → Persistence → Database. Some architectures merge Business and Persistence (when SQL/HSQL is embedded in business components). Smaller applications may have three; larger, more complex business applications five or more. No hard restriction on number or type.
- **Three physical (deployment) variants**:
  1. Presentation + Business + Persistence as one deployment unit; Database as a separate external database or filesystem.
  2. Presentation as its own deployment unit; Business + Persistence as a second; Database external.
  3. All four layers in a single deployment, including the database — useful for smaller applications with an embedded or in-memory database (mobile apps). **Many on-premises products ship this way.**
- **Partitioning**: technically partitioned. A domain like "customer" is spread across the Presentation, Business, Rules, Services, and Database layers, making domain changes difficult. **A DDD approach does not fit this style well.**
- **Architecture quantum**: always **1** (monolithic UI, monolithic database, monolithic backend processing).
- **Data topology**: traditionally a single monolithic database; the Persistence layer maps object hierarchies to the set-based realm of relational databases.

## Frameworks Introduced

- **Layers of Isolation** — changes in one layer generally don't affect components in other layers, provided the contracts between layers remain unchanged. Each layer is independent, with little or no knowledge of the others' inner workings.
  - **Requirement**: layers involved in the major flow of a request must be **closed**. If Presentation can reach Persistence directly, changes to Persistence hit *both* Business and Presentation, producing a tightly coupled, brittle, expensive-to-change application.
  - **Payoff**: any layer can be replaced without impacting any other — swap an old UI framework for a new one entirely within the Presentation layer. (Assumes well-defined contracts and the **Business Delegate** pattern — an adapter that invokes business objects from the presentation tier, reducing coupling between business services and the UI.)

- **Open vs. Closed Layers**:
  - **Closed** — a request cannot skip the layer; it must pass through the layer immediately beneath.
  - **Open** — a request may bypass the layer and go to the next one down.
  - **When to open a layer**: to add a layer that *restricts* access without forcing traversal. See the worked example.
  - **Governance imperative**: failure to document or communicate which layers are open and closed (**and why**) usually results in tightly coupled, brittle architectures that are very difficult to test, maintain, and deploy.

## Reference Tables

**Characteristics ratings** (1 star = poorly supported; 5 stars = a signature strength)

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Cost** | ★★★★★ | Primary strength — perhaps the lowest-cost style |
| **Simplicity** | ★★★★★ | Primary strength — not as complex as distributed styles, easy to understand |
| **Deployability** | ★ | Deployments are high risk, infrequent, full of ceremony. A three-line change requires redeploying the entire unit, bundled with dozens of other changes |
| **Testability** | ★★ | Nobody runs the full regression suite for a three-line change. Two stars rather than one because you *can* mock or stub components or an entire layer |
| **Elasticity** | ★ | Monolithic deployment, no architectural modularity |
| **Scalability** | ★ | Same. Quantum is always 1, so applications scale only to a point. Scaling individual functions requires complex techniques (multithreading, internal messaging, parallel processing) this style isn't suited to |
| **Fault tolerance** | ★ | One out-of-memory condition crashes the entire application unit |
| **Availability** | ★ | High MTTR — startup ranges from ~2 minutes (small apps) to 15+ minutes (large apps) |
| **Responsiveness** | ★★★ | Achievable with careful design, caching, multithreading; held back by lack of inherent parallel processing, closed layering, and the Architecture Sinkhole |
| **Modularity / agility / maintainability** | degrading | *All* engineering characteristics start well and degrade as the code base grows |

## Code Examples

**ArchUnit fitness function to govern layers (Example 10-1)** — the same function shown in Ch 6, originally written for this style:
```java
layeredArchitecture()
    .layer("Controller").definedBy("..controller..")
    .layer("Service").definedBy("..service..")
    .layer("Persistence").definedBy("..persistence..")

    .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
    .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
    .whereLayer("Persistence").mayOnlyBeAccessedByLayers("Service")
```
- **What it demonstrates**: the architect names the layers (in ArchUnit syntax, two periods on either side of a package name indicate ownership), then declares the permitted inter-layer communication — i.e. codifies the open/closed decisions.
- **Governance verdict**: excellent. Because this style is so common, the architects who built the original structural testing tools built them with layered architecture in mind. Fitness function libraries support it extremely well.

## Worked Example

**Adding a Services layer to enforce a restriction.**

*The problem*: the Business layer contains shared objects with common functionality for business components — date and string utility classes, auditing classes, logging classes. The architect decides the Presentation layer must not use these shared business objects.

*Why this is hard to govern as-is*: **architecturally**, the Presentation layer already has access to the Business layer, and therefore to everything inside it, including the shared objects. The restriction exists only as a rule nobody can enforce.

*The structural fix*: add a **new Services layer** containing all the shared business objects, positioned below Business.
- Because the **Business layer is closed**, the Presentation layer now cannot reach the Services layer — the restriction is enforced by the architecture rather than by policy.
- But the new Services layer **must be marked open**. Otherwise the Business layer would be forced to traverse Services to reach Persistence on every call. Marking it open lets Business either use Services or bypass it straight to Persistence.

*The lesson*: open/closed is not a stylistic preference — it is the mechanism that converts an architecture *decision* into an architecture *constraint*.

## Anti-patterns

- **Architecture by Implication / Accidental Architecture** — when developers or architects "just start coding," unsure which style they are using, chances are good they are implementing a layered architecture.
- **Architecture Sinkhole** — requests pass from layer to layer with **no business logic performed**. Presentation → Business (nothing) → Rules (nothing) → Persistence → a simple SQL call, then straight back up with no aggregation, calculation, rules, or transformation. Costs unnecessary object instantiation and processing, draining memory and performance.
  - **Every layered architecture has some sinkhole scenarios.** The question is what percentage.
  - **The 80-20 rule**: 20% sinkhole requests is acceptable; **80% is a strong indicator that layered architecture is the wrong style for this problem domain.**
  - Alternative fix: make all layers open — with the trade-off of much harder change management.
- **Fast-Lane Reader** (early 2000s) — the tempting shortcut of letting Presentation hit the database directly for simple retrievals. Faster, but it destroys layers of isolation.

## When to Use
- Small, simple applications or websites.
- Very tight budget and time constraints — this may be the lowest-cost style, and its familiarity promotes ease of development.
- When you're still determining whether a more complex architecture is warranted but must begin development.
- When **feasibility** is the driving characteristic: *can we deliver the stated scope in the allotted time with the resources available?* Investor-funded organizations needing something fast often choose it even knowing parts will be rewritten.
- **If you use it as a stepping stone**: keep code reuse to a minimum and keep object hierarchies (inheritance depth) shallow. This preserves modularity and makes moving to another style later feasible.

## When Not to Use
- Large applications and systems — maintainability, agility, testability, and deployability all degrade with size.
- When high operational characteristics (scalability, elasticity, fault tolerance) are required.

## Cloud Considerations
Options are limited to deploying one or more layers via a cloud provider. The inherent technical partitioning is a good fit for separated deployments — **but** communication latency between on-premises servers and the cloud may create issues, because workflows typically traverse most of the layers.

## Team Topology Considerations
Generally **independent of team topology** — works with any configuration.
- **Stream-aligned**: works well; the architecture is small, self-contained, and represents a single journey through the system. Teams own the flow through every layer end to end.
- **Enabling**: pairs well thanks to modularity and separation by technical concern. A specialist can experiment with a new UI library by adding behavior to the Presentation layer while the other layers stay isolated from the change.
- **Complicated-subsystem**: each layer performs a very specific task. The Persistence layer is a perfect hook for a team needing operational data for analytics — they work there without affecting layers the stream-aligned team still owns.
- **Platform**: can leverage the high modularity and the many available tools. **The challenge is the general monolith problem**: as the system grows, no matter how well partitioned and governed, it strains against database connections, memory, performance, concurrent users, or other constraints — and keeping it operational becomes increasingly difficult work.

## Examples and Use Cases
- **Operating systems** (Linux, Windows) — Hardware layer (CPU, memory, I/O) · Kernel layer (hardware abstraction, memory management, process scheduling) · System Call Interface layer (system services) · User layer (applications and utilities).
- **The OSI networking model / TCP/IP** — Physical (transmits data) · Data Link (error detection, frame synchronization) · Network (routing, IP) · Transport (reliable transmission, TCP) · Application (SMTP, FTP, HTTP).

## Key Takeaways
1. Close the layers on the main request flow; that is what buys layers of isolation.
2. Document which layers are open and closed **and why** — undocumented layering produces brittle, untestable architectures.
3. Add a layer to *enforce* a restriction structurally instead of relying on policy; mark it open so you don't force needless traversal.
4. Measure your sinkhole percentage. Past ~20%, question the style itself.
5. Expect ratings to decay with size — the style's strengths are all size-dependent.
6. If you're using it as a starting point, minimize reuse and keep inheritance shallow so you can leave later.
7. Don't pair it with DDD; the domain is smeared across every layer.

## Connects To
- **Ch 6**: fitness functions — the ArchUnit example was written for this style.
- **Ch 9**: technical top-level partitioning; Conway's Law and technical team seating.
- **Ch 11**: modular monolith — the domain-partitioned monolithic alternative.
- **Ch 19**: choosing the appropriate style.
- **Ch 20**: architectural patterns.
