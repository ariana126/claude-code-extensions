# Chapter 17: Orchestration-Driven Service-Oriented Architecture

## Core Idea
A cautionary tale: an architecture built on **enterprise-wide reuse** and an extreme **service taxonomy**, which — because *reuse is implemented via coupling* — produced an architecture with the disadvantages of **both** monolithic and distributed styles. *"It illustrates one of the dangers of ignoring our First Law: everything in software architecture is a trade-off."*

**Architecture styles make sense in the context of the era when they evolved, much like art movements.** SOA is now mostly of historical interest, but its building blocks (the ESB) remain useful for integration architectures.

## Historical Context — Why It Made Sense

SOA appeared in the **late 1990s**, when small companies were growing into enterprises at breakneck pace, merging with smaller companies, and needing more sophisticated IT. Distributed computing had just become possible and necessary. But:
- Open source operating systems weren't yet considered reliable enough for serious work; **operating systems were expensive and licensed per machine.**
- Commercial database servers came with **Byzantine licensing schemes**, sometimes causing application-server vendors (offering database connection pooling) to battle database vendors.
- **Because so many resources were expensive at scale, architects adopted a philosophy of reusing as much as possible.**

These technical constraints wedded with organizational concerns: frequent mergers left organizations struggling with **variety and inconsistency between core business entities**. Reuse became the dominant philosophy.

> *"Since most organizations weren't using open source operating systems when this architecture was popular, alternative architectures like microservices were impossibly expensive."*

## Frameworks Introduced

- **The Service Taxonomy** — the driving philosophy is a specific type of abstraction and enterprise-level reuse, achieved through strict layers with well-defined responsibilities:

  | Layer | Granularity | Contents | Owner |
  |---|---|---|---|
  | **Business services** | Coarse | **No code** — just input, output, and sometimes schema. `ExecuteTrade`, `PlaceOrder` | Business users and/or analysts define the signatures |
  | **Enterprise services** | Fine | Shared atomic implementations around business domains (`CreateCustomer`, `CalculateQuote`) and transactional entities (`Customer`, `Order`, `Lineitem`) | A team of developers |
  | **Application services** | One-off | Single-implementation services that don't warrant reuse — e.g. one application needs geolocation and the organization won't invest in making it reusable | A single application team |
  | **Infrastructure services** | Concrete | Operational concerns: monitoring, logging, authentication, authorization | A shared infrastructure team working closely with operations |

  - **The business-service litmus test**: can an architect answer *"yes"* to *"Are we in the business of…?"* for this service? If so, the granularity is right. `ExecuteTrade` passes. **`CreateCustomer` fails** — the company isn't in the *business* of creating customers, though it must create them to execute trades. That's an enterprise service.
  - **The stated goal** for enterprise services: *"perfectly encapsulated building blocks of isolated business functionality that can be freely composed into more complex business workflows."* The theory was that a business would gradually accumulate reusable assets and never have to rewrite that part of a workflow again.
  - **Why it fails**: *"the ideal sweet spot of abstraction between all these forces is elusive at best and likely impossible because of numerous competing trade-offs."* **Business components aren't like construction materials, where solutions last decades. Markets, technology changes, engineering practices, and a host of other factors confound attempts to impose stability on the software world.**

- **Orchestration engine and message bus** — the heart of the architecture. It stitches together business service implementations using orchestration, including **transactional coordination and message transformation**. It defines the relationship between business and enterprise services, how they map, and **where transaction boundaries lie**. It also acts as an **integration hub**, letting architects integrate custom code with package and legacy software.
  - **All requests go through the engine — even internal calls.** `CreateQuote` calls the service bus, which defines the workflow of calls to `CreateCustomer` and `CalculateQuote`, each of which calls application services.
  - **Conway's Law correctly predicts** that the team of integration architects responsible for this engine becomes a **political force in the organization — and eventually a bureaucratic bottleneck.**
  - **The balanced verdict on ESBs**: *"While most architects consider it a bad idea to build an entire architecture around ESBs, they are immensely useful in integration-heavy environments. Where architects must combine an integration hub and orchestration engine, why not use a tool that already includes them?"* — **which points to an important architect skill: how to discern the true uses of tools, separate from the hype, both good and bad.**

- **Why so many "service" names?** — the term has suffered from **semantic diffusion**. This book covers three distinct "services" styles: SOA (Ch 17), microservices (Ch 18), service-based (Ch 14). *"An **entity service** in an orchestration-driven SOA is different in virtually every way from a service in a microservices architecture."* **Architects must parse the context whenever the word *service* appears in a name.**

## Reference Tables

**Characteristics ratings**

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Deployability** | ★ | Disastrous — poorly supported, and not an important or even aspirational goal when the style was developed |
| **Testability** | ★ | Same. Agile had just started and hadn't penetrated the large organizations using this style |
| **Simplicity** | ★ | — |
| **Cost** | ★ | **Simplicity and cost have the inverse of the relationship most architects would prefer** |
| **Performance** | ★★ | Never a highlight — each business request is split across so much of the architecture |
| **Elasticity** | ★★★ | Supported *despite* implementation difficulty; vendors poured enormous effort into session replication across application servers and similar techniques |
| **Scalability** | ★★★ | Same |

- **Partitioning**: *"perhaps the most technically partitioned general-purpose architecture ever attempted!"* **The backlash against its disadvantages led to more modern architectures such as microservices.**
- **Quantum: 1** — despite being distributed. Two reasons: (1) it generally uses a single database or just a few, creating coupling points across many concerns; (2) **more importantly, the orchestration engine is a giant coupling point — no part of the architecture can have different characteristics than the mediator that orchestrates all behavior.** *"Thus, this architecture manages to find the disadvantages of both monolithic **and** distributed architectures."*

## Worked Example

**The canonical `Customer` service — how reuse became coupling.**

An architect at an insurance company notices that each of **six divisions** contains a notion of `Customer`. The proper SOA strategy extracts the `Customer` parts into a reusable service and has the original services reference the canonical one. All customer behavior is now isolated in a single `Customer` service. **The obvious reuse goal is achieved.**

Then the negative trade-offs surfaced:

1. **Reuse is implemented *via* coupling.** A change to the `Customer` service **ripples out to all the other services**. Every incremental change becomes risky with a potentially huge ripple effect — requiring **coordinated deployments, holistic testing, and other drags on engineering efficiency.**

2. **The canonical model becomes everyone's problem.** To support one `Customer` service, **each division must include all the details the organization knows about its customers.** Auto insurance requires a **driver's license** — a property of the *person*, not the vehicle. So the `Customer` service must carry driver's-license details that the **disability insurance division cares nothing about** — yet that team must deal with the extra complexity of the single definition.
   - *"In many ways, DDD's insistence on **avoiding** holistic reuse derives from experiences with these kinds of architectures."*

3. **The technical partitioning is a practical nightmare.** A developer's ordinary task — *"add a new address line to `CatalogCheckout`"* — hits a domain concept **spread so thinly throughout the architecture that it was virtually ground to dust.** In SOA this could involve **dozens of services across several tiers**, plus changes to a single database schema. And **if the current enterprise services aren't defined at the correct transactional granularity, developers must either change their design or build a nearly identical new service** to change the transactional behavior. *"So much for reuse."*

**The generalized lesson**: architects **dread hearing the word *change*** in this style, because it requires deep analysis and the scope of work is wildly variable. On a lucky day, updating details about a single entity only touches the enterprise services layer. On a bad day — one where enterprise architects and business stakeholders didn't anticipate this kind of change — it means **highly coupled changes across four or five layers.**

## Anti-patterns / Common Risks

- **Accidental SOA** — the modern risk. When using an ESB as an integration facility, the danger is **the slippery slope of allowing the ESB to gradually encapsulate the entire architecture** — an architect gradually and unintentionally builds a fully orchestration-driven SOA without realizing it.
  - **Prevention**: ensure reasonable **encapsulation boundaries for orchestration** and pay close attention to **transactional boundaries**.
- **Declarative transactions** — a "feature" of application servers in SOA's heyday: configuration managers could change the transactional scope of individual entities (`EntityBeans`) depending on the transactional context, **declared in XML**. It largely failed for two reasons:
  1. **If a developer doesn't know what the transactional behavior will be at runtime**, it adds considerable complexity to entities and dependencies — forcing **almost identical versions of entities differing only in transactional scope.**
  2. **No matter how much sophistication vendors built into their message buses, edge cases constantly appeared** where myriad failure modes prevented clean transaction management, creating tangled inconsistencies for humans to untangle.
  - **The general principle**: *"Some complex, multifaceted features of systems (like transactions) cannot be cleanly abstracted away. Too many leaks in the abstraction prevent it from achieving reliability."*
- **Historical project risks**: cost, implementation duration, and — *"a shocking surprise"* — **how difficult these systems are to maintain and update.** Many were very expensive multiyear endeavors with critical decisions made high in the company hierarchy. **Rather than call them "failures," companies mostly transformed them into integration architectures with better boundaries, more closely aligned with DDD.**

## Governance
When this style was popular, **modern holistic testing was uncommon**. Teams rarely tested SOA outside formal QA-level testing, and tool creators gave little thought to testing individual parts; testing frameworks for mocking the message bus were **always cumbersome and inconsistent.** Governance suffered the same limitations — **automating architectural governance was even more foreign than automating testing. "Governance" meant heavyweight frameworks, meetings, and code reviews — all manual.**

**Modern use**: architects still deploy ESBs strategically where legacy systems must interact with modern ones, combining results and aggregating behavior. **Here, fitness functions play a critical role in preventing data or bounded contexts from "leaking" across parts of the ecosystem where they shouldn't appear.**

**Example**: an ESB coordinating an **ERP package**, an **online sales tool**, and modern **microservices-based `Accounting` services**. The system should only *read* from ERP and sales, and only *write* to `Accounting`. First build a fitness function ensuring all communication is consistently logged, then:
```
READ logs for ERP into ERP-logs for past 24 hours
READ logs for Sales into Sales-logs for past 24 hours

FOREACH entry IN ERP-logs
    IF 'operation' is 'update' and 'target' != 'accounting' THEN
       raise fitness function violation
            "Invalid communication between integration points"
    END IF

FOREACH entry IN Sales-logs
    IF 'operation' is 'update' and 'target' != 'accounting' THEN
       raise fitness function violation
            "Invalid communication between integration points"
    END IF
```
*"Using such fitness functions, architects can use tools like ESBs strategically while building guardrails around the places where teams typically misuse them."*

## Team Topology Considerations
Team topologies were an unknown concept when this style was popular — **and in fact the strict taxonomy of this style serves as a communication antipattern that *led* architects to develop the principles of team topologies.**

**The goal was extreme separation of responsibilities with a corresponding separation of team members.** Among adopting companies, *"it was rare indeed for someone building **business services** to chat with someone building **enterprise services**."* They were expected to communicate through **technical artifacts — contracts and interfaces**. The abstraction level created many integration layers, each implemented by different teams, **communicating through enterprise-level ticketing tools.** *"It should be easy to see why developers find it time-consuming to build features in this style."*

## Data Topologies
Not very interesting given the historical origins. Despite being distributed, it generally used **a single (or a few) relational databases** — common practice in all distributed architectures of the late 1990s. **Even transactionality was relegated away from the database to the message bus**, which offered declarative transactional interactions per entity.

> *"Architects in this era considered data a foreign country. While it is an inevitable part of the plumbing in both SOA and event-driven architectures, back then, they treated it more as an integration point than as part of the problem domain."*

## Cloud Considerations
Predates the cloud by several decades, so no consideration exists for building the original incarnation there. **However, the current-day use of this style makes it a good integration architecture for cloud and on-premises services that must integrate and participate in workflows.** As primarily an integration architecture, it works well with cloud-based services.

## Examples and Use Cases
Primary examples existed in **late 1990s and early 2000s large enterprises**, gradually displaced by more agile, domain-based distributed architectures like microservices — as *"even large enterprises have realized that change is inevitable and that software isn't static."*

**Where the building blocks survive**: an ESB includes both an **integration hub** (facilitating communication, protocol, and contract transformation) and an **orchestration engine** (building workflows between integration endpoints). Because orchestration-driven SOA includes **many layers of indirection**, it lets architects implement enterprise services as **integration points, package software, or bespoke code**. Client requests use the message bus to determine which enterprise services to call, in what order, and what information to aggregate; the enterprise services communicate via APIs to custom code, old systems, or package software.

## Key Takeaways
1. **Reuse is implemented via coupling.** Every reuse win you engineer is a coupling cost you will pay at change time.
2. Canonical entity models force every consumer to absorb every other consumer's complexity — this is the experience DDD's bounded context was invented to prevent.
3. Extreme technical partitioning grinds domain concepts to dust; a one-line domain change becomes a multi-layer, multi-team coordination problem.
4. Some features — transactions especially — cannot be cleanly abstracted away. Leaky abstractions over them never achieve reliability.
5. Use ESBs **strategically** for integration-heavy environments, never as the whole architecture — and guard the boundary with fitness functions to avoid **Accidental SOA**.
6. A giant orchestration mediator collapses the whole system into one quantum: nothing can have different characteristics than the mediator.
7. Read past architectures in the context of their constraints. *"Architects should learn from past approaches. We can continue using the parts that still make sense, while internalizing the lessons of what failed and why."*

## Connects To
- **Ch 1**: the First Law — this style is what ignoring it looks like at scale.
- **Ch 7**: DDD bounded context — developed in reaction to exactly these canonical-model experiences.
- **Ch 9**: Conway's Law predicting the integration-architect bottleneck; technical vs. domain partitioning.
- **Ch 14**: service-based architecture — another "service" style, entirely different in meaning.
- **Ch 18**: microservices — the direct backlash against this style's disadvantages.
- **Ch 24**: team topologies, whose principles were developed partly in reaction to this style's communication antipattern.
