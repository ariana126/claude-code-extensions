---
name: fundamentals-of-software-architecture-book
description: "Knowledge base from \"Fundamentals of Software Architecture: An Engineering Approach\" (2nd Edition) by Mark Richards and Neal Ford. Use when applying Richards and Ford's frameworks for architecture characteristics, architecture styles (layered, modular monolith, microkernel, microservices, event-driven, space-based, service-based), coupling and connascence, architecture quantum, fitness functions, ADRs, risk storming, trade-off analysis, or the soft skills of the architect role."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, style name, or chapter number] -->

# Fundamentals of Software Architecture, 2nd Edition
**Authors**: Mark Richards & Neal Ford | **Chapters**: 27 | **Generated**: 2026-07-22

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `connascence`, `architecture quantum`, `saga`, `risk storming`, or another indexed topic; I find and read the relevant chapter
- **With a chapter** — ask for `ch15`; I load that specific chapter
- **Browse** — ask "what chapters do you have?" for the full index

When you ask about a topic not covered in Core Frameworks below, I read the relevant chapter file before answering.

---

## Core Frameworks & Mental Models

### The Three Laws
1. **Everything in software architecture is a trade-off.**
   - *Corollary 1*: If you think you've found something that isn't a trade-off, you just haven't identified it yet.
   - *Corollary 2*: You can't do trade-off analysis once and be done with it.
2. **Why is more important than how.** You can reverse-engineer *how* from a running system; you can never recover *why*.
3. **Most architecture decisions aren't binary but exist on a spectrum between extremes.**

**Derived test**: *an architecture decision is one where **every** option carries significant trade-offs.* The architect's job is being an **objective arbiter of trade-offs**, not an evangelist — yesterday's best practice becomes tomorrow's antipattern.

### The Four Dimensions of Architecture
Architecture = **architecture style** (starting scaffolding) + **architecture characteristics** (capabilities) + **logical components** (behavior) + **architecture decisions** (constraints). If you can only describe the style, you haven't described the architecture.

### Architecture Characteristics — three criteria (all must hold)
1. Specifies a **nondomain** design consideration
2. **Influences some structural aspect** of the design (ask: design or structure? Security can be either; scalability *cannot* be solved by design in a monolith)
3. Is **critical or important** to success

Choose the **fewest**, not the most. **Never strive for the best architecture; aim for the least worst.** Hunt **implicit** characteristics (availability, security, modularity) — they never appear in requirements. Decompose **composites** (agility = deployability + modularity + testability) before measuring. Elicit with the worksheet: max 7 candidates, then stakeholder consensus on the **top three, unordered** — full ranking is a fool's errand.

### Architecture Quantum — the unit of scope
*The smallest part of the system that runs independently*: independently deployable, high functional cohesion, low external implementation static coupling, synchronous communication with other quanta. **The database is inside the quantum** — shared database means one quantum no matter how many services. Characteristics live at the **quantum** level, not the system level.

**Four couplings**: **semantic** (the problem's own coupling — almost no leverage) · **implementation** (your choices — full leverage) · **static** (the wiring; defines quantum scope) · **dynamic** (runtime communication).
**One-line test**: *two things are coupled if changing one might break the other.*
**Rule**: higher coupling is allowed at narrower scope; the broader the scope, the looser the coupling must be.

### Connascence — the language of coupling
Two components are connascent if changing one requires changing the other.
- **Static** (weak→strong): Name → Type → Meaning → Position → Algorithm
- **Dynamic** (weak→strong): Execution → Timing → Values → Identity
- **Three properties**: *strength* (prefer static over dynamic) · *locality* (strong connascence inside one module is fine; across modules is not — this is DDD's bounded context) · *degree* (blast radius)
- **Weirich's rules**: convert strong forms to weak (Degree); use weaker forms as elements get further apart (Locality)
- **Page-Jones**: minimize connascence overall, minimize it across boundaries, **maximize it within boundaries**

### Top-Level Partitioning — one of your first decisions
**Technical** (layered): easy to find a *category* of code; the domain is smeared across every layer. **Domain** (modular monolith, microservices): matches how change actually arrives; industry trend runs decidedly this way. Technical partitioning's real cost is data-level coupling, which forecloses future distribution.

### Fitness Functions
*Any mechanism providing an objective integrity assessment of an architecture characteristic.* Not a framework to download — a perspective on existing tools (metrics, monitors, unit tests, chaos engineering). Their purpose is guarding the **important but not urgent** (modularity, layer rules, cycles) that schedule pressure erodes. Code review is too late; automate at commit. Explain every function before imposing it. Tools: ArchUnit (Java), NetArchTest/ArchUnitNet (.NET), PyTestArch, TSArch, JDepend.

### Choosing a Style — three determinations
1. **Monolith or distributed?** One set of characteristics → monolith; multiple sets → distributed. Use quantum analysis.
2. **Where does data live?** And how does it flow to build workflows?
3. **Synchronous or asynchronous?** **Default to synchronous; go async only when necessary** — async buys performance and scale but costs data synchronization, deadlocks, race conditions, and debuggability.

Match **architecture isomorphism** to problem shape: customizability → microkernel; many discrete operations → space-based; **heavily semantically coupled domains → deliberately coupled styles, not microservices**.

### The Fallacies of Distributed Computing
The network is reliable · latency is zero · bandwidth is infinite · the network is secure · the topology never changes · there is only one administrator · transport cost is zero · the network is homogeneous — **plus** versioning is easy · compensating updates always work · observability is optional.

**Know your production latency average *and* 95th–99th percentile.** Long-tail latency is what kills distributed architectures. Ten chained calls at 100 ms average adds a full second.

### Architecture Decisions
- Decide at the **last responsible moment**: where deferral cost exceeds decision risk.
- Always give a **business** justification alongside the technical one (cost, time to market, user satisfaction, strategic positioning). If you can't find one, reconsider the decision.
- **Nygard's significance test**: does it affect structure, non-functional characteristics, dependencies, interfaces, or construction techniques? Technology choices serving a characteristic *are* architectural.
- **ADRs**: Title · Status (Proposed/Accepted/Superseded, + RFC) · Context · Decision (*commanding voice*: "We will use X") · Consequences (with the trade-off analysis) · **Compliance** · **Notes**.
- Never email a decision — email context plus a link to the single system of record, only to those directly impacted.

### Trade-Off Analysis Method
1. Enumerate **contextualized** factors specific to this organization and solution
2. Build a +/− matrix per option
3. **Weight the factors against actual organizational goals** — skipping this is the **Out of Context antipattern**; the raw count of plusses is not the answer

**The hidden trade-off you'll miss**: reuse requires **abstraction *and* low volatility**. Reuse plumbing; never reuse the domain. **You cannot have both decoupling and high reuse — reuse is implemented via coupling.**

### The Architect as Leader
About **50% of the job is people skills.** Build the right-sized "room": too tight and developers leave; too loose and they become accidental architects. Calibrate involvement via five factors (familiarity, size, experience, complexity, **duration** — short projects need *less*).
- Give the **justification before the demand**; people stop listening once they disagree
- "This means," not "you must." "Have you considered?", not "what you need to do"
- **Demonstration defeats discussion**
- When someone disagrees, set the condition for them to prove themselves right — both outcomes win
- Translate abstractions into concrete units (86 seconds/day, not "three nines")
- Save cost and time for **last**
- Never add accidental complexity to prove your worth

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-introduction.md) | Introduction | Three Laws, Four Dimensions, Eight Expectations |
| [ch02](chapters/ch02-architectural-thinking.md) | Architectural Thinking | Architecture/design spectrum, Knowledge Pyramid, 20-minute rule, personal radar |
| [ch03](chapters/ch03-modularity.md) | Modularity | Cohesion scale, afferent/efferent coupling, LCOM, Distance from Main Sequence, connascence |
| [ch04](chapters/ch04-architecture-characteristics-defined.md) | Architecture Characteristics Defined | Three criteria, four categories, implicit vs. explicit, least worst |
| [ch05](chapters/ch05-identifying-architectural-characteristics.md) | Identifying Architectural Characteristics | Domain-concern translation, composites, katas, characteristics worksheet |
| [ch06](chapters/ch06-measuring-and-governing.md) | Measuring and Governing | Cyclomatic Complexity, fitness functions, Simian Army, governance |
| [ch07](chapters/ch07-scope-of-architectural-characteristics.md) | Scope of Architectural Characteristics | Architecture quantum, four couplings, bounded context, scoping decision tree |
| [ch08](chapters/ch08-component-based-thinking.md) | Component-Based Thinking | Logical vs. physical architecture, Workflow/Actor-Action, Entity Trap, Law of Demeter |
| [ch09](chapters/ch09-foundations.md) | Foundations | Style vs. pattern, top-level partitioning, Conway's Law, team topologies, the fallacies |
| [ch10](chapters/ch10-layered-architecture.md) | Layered Architecture | Layers of isolation, open/closed layers, Architecture Sinkhole |
| [ch11](chapters/ch11-modular-monolith.md) | Modular Monolith | Monolithic vs. modular structure, module communication, mediator, module governance |
| [ch12](chapters/ch12-pipeline-architecture.md) | Pipeline Architecture | Four filter types, pipes, filter tagging, AWS Step Functions |
| [ch13](chapters/ch13-microkernel-architecture.md) | Microkernel Architecture | Core system, plug-ins, microkern-ality spectrum, registry, contracts |
| [ch14](chapters/ch14-service-based-architecture.md) | Service-Based Architecture | Domain services, ACID vs. BASE, partitioned shared libraries, stepping stone |
| [ch15](chapters/ch15-event-driven-architecture.md) | Event-Driven Architecture | Events vs. messages, payload types, Workflow Event pattern, mediator topology, data topologies |
| [ch16](chapters/ch16-space-based-architecture.md) | Space-Based Architecture | Processing units, data grids, data pumps, replicated vs. distributed caching, collision formula |
| [ch17](chapters/ch17-orchestration-driven-soa.md) | Orchestration-Driven SOA | Service taxonomy, reuse-as-coupling, Accidental SOA, declarative transactions |
| [ch18](chapters/ch18-microservices-architecture.md) | Microservices Architecture | Bounded context, granularity guidelines, sidecar/service mesh, Saga, Database-per-Service |
| [ch19](chapters/ch19-choosing-architecture-style.md) | Choosing the Appropriate Style | Seven decision criteria, architecture isomorphism, three determinations, BFF |
| [ch20](chapters/ch20-architectural-patterns.md) | Architectural Patterns | Orthogonal coupling, Hexagonal vs. Service Mesh, orchestration vs. choreography, CQRS, broker patterns |
| [ch21](chapters/ch21-architectural-decisions.md) | Architectural Decisions | Three decision antipatterns, last responsible moment, ADRs, LLM limits |
| [ch22](chapters/ch22-analyzing-architecture-risk.md) | Analyzing Architecture Risk | Risk matrix, risk assessments, direction of risk, risk storming |
| [ch23](chapters/ch23-diagramming-architecture.md) | Diagramming Architecture | Representational consistency, semantic layers, UML/C4/ArchiMate, diagram guidelines |
| [ch24](chapters/ch24-making-teams-effective.md) | Making Teams Effective | Architect personalities, Elastic Leadership, team warning signs, checklists, layered stack guidance |
| [ch25](chapters/ch25-negotiation-and-leadership.md) | Negotiation and Leadership | Negotiation techniques, nines of availability, 4 Cs, pragmatic vs. visionary, calendar control |
| [ch26](chapters/ch26-architectural-intersections.md) | Architectural Intersections | Nine intersections, unknown unknowns, residuality theory, Gen AI alignment |
| [ch27](chapters/ch27-laws-revisited.md) | The Laws Revisited | Trade-off method, both corollaries, Out of Context antipattern, reuse trade-off |

## Topic Index

- **ACID / BASE** → ch14, ch18
- **ADRs** → ch21, ch27
- **Agility (composite)** → ch5, ch6, ch26
- **Antipatterns (decision)** → ch21
- **API Gateway** → ch14, ch18
- **Architecture quantum** → ch7, ch14, ch15, ch18
- **Availability (nines)** → ch25
- **Big Ball of Mud** → ch9, ch11, ch13
- **Bounded context** → ch7, ch18
- **Caching (replicated/distributed)** → ch16, ch26
- **Checklists** → ch6, ch24
- **Choreography vs. orchestration** → ch15, ch18, ch20
- **Cloud** → ch4, ch7, and every style chapter
- **Cohesion** → ch3, ch8
- **Complexity (essential/accidental)** → ch3, ch6, ch25
- **Connascence** → ch3, ch18
- **Constraints** → ch24, ch26
- **Conway's Law** → ch9, ch17
- **Coupling (four types)** → ch3, ch7, ch8, ch18
- **CQRS** → ch20
- **Cyclomatic Complexity** → ch3, ch6
- **Data topologies** → ch14, ch15, ch16, ch18, ch26
- **DDD** → ch7, ch9, ch18, ch27
- **Diagramming (C4, ArchiMate, UML)** → ch23
- **Distributed computing fallacies** → ch9
- **Elastic Leadership** → ch24
- **Elasticity vs. scalability** → ch5, ch16
- **Entity Trap** → ch8, ch18
- **Event payloads** → ch15
- **Events vs. messages** → ch15
- **Fitness functions** → ch6, ch10, ch16, ch17, ch22, ch26
- **Generative AI / LLMs** → ch21, ch26
- **Governance** → ch6, and every style chapter
- **Granularity** → ch3, ch14, ch18
- **Katas** → ch5, ch27
- **Law of Demeter** → ch8
- **Layers of isolation** → ch10
- **LCOM / Distance from Main Sequence** → ch3, ch6
- **Least worst** → ch4, ch5, ch8, ch19
- **Logical components** → ch8, ch26
- **Modularity** → ch3, ch11
- **Negotiation** → ch25
- **Partitioning (technical/domain)** → ch9, ch19, ch26
- **Patterns vs. styles** → ch9, ch20
- **Poison event / Swarm of Gnats** → ch15
- **Risk matrix / risk storming** → ch22
- **Saga / compensating transactions** → ch9, ch18
- **Sidecar / service mesh** → ch18, ch20
- **Stamp coupling** → ch9, ch15, ch27
- **Team topologies** → ch9, ch24, ch26, and every style chapter
- **Technical breadth vs. depth** → ch2
- **Trade-off analysis** → ch2, ch27
- **Ubiquitous language** → ch3, ch4, ch6
- **Unknown unknowns** → ch26

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions and chapter references
- [patterns.md](patterns.md) — every technique and pattern with when-to-use, how, and trade-offs
- [cheatsheet.md](cheatsheet.md) — style selection tree, ratings table, thresholds, tells and smells, decision rules

---

## Scope & Limits

This skill covers the book's content only. It reflects the 2nd edition (2025), which adds the modular monolith chapter, cloud and team-topology sections per style, the Third Law, and treatment of generative AI. For hands-on implementation in a specific codebase, combine with project-specific context. For deeper dives the authors themselves defer to: *Software Architecture: The Hard Parts* (granularity, the eight Saga patterns), *Building Evolutionary Architectures* (fitness functions), *Building Microservices* (Newman), and *Building Micro-Frontends* (Mezzalira).
