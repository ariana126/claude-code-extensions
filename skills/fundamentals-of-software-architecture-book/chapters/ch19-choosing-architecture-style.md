# Chapter 19: Choosing the Appropriate Architecture Style

## Core Idea
**It depends** — but the dependency is structured. Choosing a style is the culmination of characteristics analysis, domain understanding, and trade-off reasoning, resolved through three determinations: **monolith or distributed**, **where data lives**, and **synchronous or asynchronous**.

## Frameworks Introduced

- **The Seven Forces Shifting Architecture "Fashion"** — why preferences change over time:
  1. **Observations from the past** — new styles arise from **pain points** in past experience. *"After building architectures that centered on code reuse, architects realized the negative trade-offs and seriously rethought the implications of reusing code."*
  2. **Changes in the ecosystem** — *"everything changes all the time… so chaotic that it's impossible to even predict what type of change will come next."* Not many years ago nobody knew what Kubernetes was; in a few more years it may be replaced by something not yet written.
  3. **New capabilities** — watch for new **paradigms**, not just new tools. Containers like Docker caused a tectonic shift affecting architects, tools, and engineering practices. *"Even something that looks like a new one-of-something-we-already-have could include nuances that make it a game changer… a minor change that aligns exactly with an architect's goals can change everything."*
  4. **Acceleration** — change keeps getting faster and more pervasive. New tools create new engineering practices, which lead to new designs and capabilities. **Generative AI is an outstanding example.**
  5. **Domain changes** — businesses evolve and merge.
  6. **Technology changes** — organizations chase changes with obvious bottom-line benefits.
  7. **External factors** — architects may be perfectly happy with a tool, but **prohibitive licensing cost can force a migration**.
  - *"Architects should understand current industry trends so they can make intelligent decisions about which trends to follow and when to make exceptions, regardless of how closely their organization follows current architecture fashion."*

- **The Seven Decision Criteria** — only approach the choice with sufficient knowledge of:

  | Criterion | What you need |
  |---|---|
  | **The domain** | As many important aspects as you can, **especially those affecting operational characteristics**. You don't have to be a subject matter expert — business analysts can fill gaps |
  | **Architecture characteristics that impact structural decisions** | Conduct a characteristics analysis. **It's possible to implement any *generic* style in almost any problem domain** — *generic* means general-purpose. The exceptions are domains needing special operational characteristics (a highly scalable auction site). **In most cases the real differences between styles concern not the domain but how well each supports various characteristics** — which is why the Part II star charts rate characteristics, not domains |
  | **Data architecture** | Collaborate with data developers on databases and schemas. Understand the impact of a given data design, **particularly if the new system must interact with an older or in-use data architecture** |
  | **Cloud deployments** | Trade-offs for on-premises differ sharply from cloud. Know **how much data the application will store and how much data can move around (which can incur significant costs)**. *"A decade ago, building a highly elastic and scalable on-prem system required esoteric skills and was seen as almost magical. Now, architects can achieve the same results just by changing their cloud provider's configuration parameters."* |
  | **Organizational factors** | A cloud vendor's cost may prevent the otherwise ideal design. **Knowing the company plans mergers and acquisitions might push you toward open solutions and integration architectures** |
  | **Process, teams, and operational concerns** | The development process, your interaction (or lack of it) with operations, the QA process. **If an organization lacks maturity in Agile engineering practices, styles that depend on them — such as microservices — will present difficulties** |
  | **Domain/architecture isomorphism** | See below |

- **Architecture isomorphism** — the generic "shape" of an architecture: **the way its components depend on each other within the overall topology**. From Greek *isos* ("equal") and *morph* ("form"/"shape"); *isomorphism* means "a map that preserves sets and relations among elements."
  - **Good matches**: **microkernel** suits systems requiring customizability (customizations become plug-ins). A **genome analysis** system requiring a large number of discrete operations suits **space-based architecture**, which offers a large number of discrete processors.
  - **Bad matches**: **highly scalable systems struggle with large monolithic designs**, because a highly coupled code base can't support many concurrent users. And **a domain with a huge amount of semantic coupling matches poorly with a highly decoupled distributed architecture** — an insurance application of multipage forms, each based on the context of previous pages, is a highly coupled problem, **difficult to model in microservices; an intentionally coupled architecture like service-based architecture would suit it better.**

- **The Three Determinations**:
  1. **Monolith versus distributed?** *Will a single set of architecture characteristics suffice, or do different parts need different sets?* A single set implies a monolith would be suitable (though other factors may still suggest distributed); different sets imply distributed. **The architecture quantum (Ch 7) is the tool for this determination.**
  2. **Where should data live?** In a monolith, architects commonly assume a single relational database or a few. In a distributed architecture, decide **which services persist data** — which also means thinking about **how data will flow through the architecture to build workflows**. *"Consider both structure and behavior when designing architecture, and don't be afraid to iterate on your design to find better combinations."*
  3. **Synchronous or asynchronous communication?** Synchronous is often more convenient but trades away scalability and reliability. Asynchronous gives unique performance and scale benefits **but plenty of headaches around data synchronization, deadlocks, race conditions, and debugging.**
     - **Tip: use synchronous communication by default, asynchronous when necessary** — because synchronous presents fewer design, implementation, and debugging challenges.

- **The output of this design process**: an **architecture topology** encompassing the chosen style (and any hybridizations), **Architectural Decision Records (ADRs)** for the parts of the design requiring the most effort, and **architecture fitness functions** protecting important principles and operational characteristics.

## Worked Example

**Monolith case study: Silicon Sandwiches.** The characteristics analysis (Ch 5) determined a **single quantum** was sufficient, and with a simple application and no huge budget, **the simplicity of a monolith was appealing**. Two component designs were produced in Ch 9 — one domain partitioned, one technically partitioned. Two implementations follow:

**Option A — Modular monolith.** Domain-centric components, a single relational database, a single web-based UI with careful mobile design considerations to keep cost down. Each identified domain appears as a component.
- **The forward-looking move**: *"If time and resources are sufficient, consider separating the tables and other database assets in the same way as the domain components, which would make it much easier to migrate this architecture to a distributed architecture if future requirements warrant it."*
- **The customization problem**: **the style itself doesn't inherently handle customization**, so it becomes part of the *domain* design. The architect designs an **`Override` endpoint** where developers upload individual customizations — and **must ensure every domain component references the `Override` component for each customizable characteristic.** *"Checking this would be a perfect job for an architectural fitness function."*

**Option B — Microkernel.** Uses domain/architecture isomorphism to make customizability structural.
- The **core system** is the domain components plus a single relational database. Again, careful synchronization between the domains and the data design facilitates future migration to distributed.
- **Each customization is a plug-in**: common ones in a single set of plug-ins with a corresponding database, plus a series of local ones each with its own data. **Because no plug-in needs coupling to another, each can maintain its own data and remain decoupled.**
- **The distinctive addition — the Backends for Frontends (BFF) pattern**: the API layer becomes a **thin microkernel adapter** in addition to the core architecture. The API layer supplies general information from the backend; **BFF adapters translate it into a format suitable for each frontend device.** The iOS BFF takes the generic backend output and customizes **data format, pagination, latency, and other factors** to fit what the iOS native application expects. This allows the richest possible UIs and makes it possible to expand to other devices later — **one of the benefits of the microkernel style.**
- **Communication in either option can be synchronous**, since the architecture needs no extreme performance or elasticity and no operation is lengthy.

---

**Distributed case study: Going, Going, Gone (GGG).**

**Why distributed**: the component analysis (Ch 8) showed different parts need different characteristics — **availability and scalability differ between the auctioneer and bidder roles**. The requirements also explicitly state ambitious expectations for scale, elasticity, and performance.

**Why microservices over EDA**: both low-level event-driven architecture and microservices match most of the required characteristics, **but microservices is better at supporting *variation* among operational architecture characteristics.** *"Purely event-driven architectures typically separate pieces not by their architecture characteristics, but by whether they use orchestrated or choreographed communication."*

**The performance concession**: achieving the stated performance goal would be a challenge in microservices — *"but the best way to address any weak point of an architecture is by designing to accommodate it."* Microservices offers high scalability by nature but **often develops specific performance issues caused by too much orchestration or too aggressive data separation.**

**Three user interfaces**: **Bidder** (numerous), **Auctioneer** (one per auction), **Streamer** (streams video and bids to bidders — **a read-only stream, which allows optimizations that wouldn't be available if updates were necessary**).

**The services**:

| Service | Role |
|---|---|
| `Bid Capture` | Captures online bidder entries and asynchronously sends them to `Bid Tracker`. **Needs no persistence** — it acts as a conduit |
| `Bid Streamer` | Streams bids back to online participants in a high-performance, read-only stream |
| `Bid Tracker` | Tracks bids from both `Auctioneer Capture` and `Bid Capture`, **unifying the two information streams and ordering bids in as close to real time as possible**. Both inbound connections are asynchronous, **letting developers use message queues as buffers to handle very different message flow rates** |
| `Auctioneer Capture` | Captures bids for the auctioneer — separated from `Bid Capture` because their characteristics are quite different (Ch 8) |
| `Auction Session` | Manages the workflow of individual auctions |
| `Payment` | Third-party payment provider, invoked after `Auction Session` completes the auction |
| `Video Capture` | Captures the video stream of the live auction |
| `Video Streamer` | Streams the auction video to online bidders |

**Why asynchronous where it appears**: *"primarily to accommodate operational architecture characteristics varying between services. For example, if the `Payment` service can only process a new payment every 500 ms, and a large number of auctions end at the same time, using synchronous communication would cause timeouts and other reliability headaches. **Message queues add reliability to a critical but fragile part of the architecture.**"*

**Final result: five quanta** — `Payment`, `Auctioneer`, `Bidder`, `Bidder Streams`, `Bid Tracker`. **Using quantum analysis at the component-design stage made it easier to identify service, data, and communication boundaries.**

**The closing honesty**: *"Note that this isn't the 'correct' design for GGG, and it's certainly not the only one. We don't even suggest that it's the best possible design — but it seems to have the **least worst** set of trade-offs."*

## Key Takeaways
1. Style choice follows characteristics analysis; it is never the starting point.
2. Any *generic* style can implement almost any domain — the differentiator is **which characteristics each style supports**, not the domain itself.
3. Match architecture isomorphism to problem shape: customizability → microkernel; many discrete operations → space-based; **highly semantically coupled domains → deliberately coupled styles, not microservices**.
4. Run the three determinations in order: monolith vs. distributed (via quantum analysis) → where data lives → sync vs. async.
5. **Default to synchronous; go asynchronous only when a specific characteristic mismatch demands it** — as with `Payment`'s 500 ms limit in GGG.
6. Check organizational readiness: microservices without mature Agile engineering practices will hurt.
7. Design the database partitioning to mirror the domain components even in a monolith — that's what makes later migration cheap.
8. Produce three artifacts: the topology, ADRs for the hardest decisions, and fitness functions protecting what matters.
9. Aim for the **least worst** set of trade-offs, not the correct design. There isn't one.

## Connects To
- **Ch 2**: "it depends" and trade-off analysis.
- **Ch 5**: the Silicon Sandwiches characteristics analysis this chapter builds on.
- **Ch 7**: architecture quantum — the decision tool for monolith vs. distributed.
- **Ch 8**: the GGG component analysis that produced these services.
- **Ch 9**: architecture partitioning; the isomorphic comparisons.
- **Ch 10–18**: the styles being chosen among.
- **Ch 21**: ADRs — one of the three outputs.
- **Ch 6**: fitness functions — another of the three outputs.
