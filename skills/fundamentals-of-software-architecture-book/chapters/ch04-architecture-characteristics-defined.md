# Chapter 4: Architectural Characteristics Defined

## Core Idea
An **architecture characteristic** must satisfy three criteria — it is nondomain, it influences structure, and it is critical to success — and because characteristics are synergistic and never free, the goal is never the *best* architecture but the **least worst** one.

## Frameworks Introduced

- **The Three Criteria for an Architecture Characteristic** — all three must hold:
  1. **Specifies a nondomain design consideration.** Domain requirements say *what* the application should do; characteristics specify *how* to implement them and *why* certain choices were made — the operational and design criteria for success. (No requirements doc says "prevent technical debt," yet it's a real design consideration.)
  2. **Influences some structural aspect of the design.** The test: can it be handled by design alone, or does it demand special *structure*?
  3. **Is critical or important to the application's success.** Every supported characteristic adds design complexity, so **strive for the fewest possible, not the most.**
  - When to use: as a filter on every proposed "-ility" during architecture kickoff. If it fails any criterion, it's not architectural.
  - Why it works: the three parts form a triangle where each element supports the others; the resulting fulcrum is exactly why architects say *trade-off* so often.

- **Implicit vs. Explicit characteristics**:
  - **Explicit** — appears in requirements documents or specific instructions.
  - **Implicit** — rarely appears in requirements yet is necessary for success. Availability, reliability, security, and modularity underpin virtually all applications. Architects must use *domain knowledge* to surface these during analysis. (A high-frequency trading firm may never write down "low latency" because everyone already knows.)

- **The Four Categories of Architecture Characteristics** — Operational, Structural, Cloud, Cross-cutting (tables below). Use them as a checklist so no category is silently skipped.

- **Least Worst Architecture**: *"Never strive for the best architecture; aim for the least worst architecture."*
  - Why: supporting too many characteristics produces generic solutions that try to solve every business problem, become unwieldy, and rarely work.
  - Corollary: **design for iteration.** The easier the architecture is to change, the less anyone must stress about getting it exactly right the first time. Agile's lesson about iteration holds at the architecture level too.

## Key Concepts

- **Architecture characteristics** — the *capabilities* of a system; nondomain, structural, success-critical.
- **Problem domain (domain)** — the requirements gathered when a company decides to solve a problem with software; the system's *behavior*.
- **Structural design** — the architect's two core activities together: architecture characteristics analysis (Ch 4) + logical component design (Ch 8). Can run in any order or in parallel, but meet at a critical join point.
- **Non-functional requirements** — the sticky legacy term the authors reject as *self-denigrating*: how do you convince a team to care about something labeled "non-functional"?
- **Quality attributes** — also rejected, because it implies after-the-fact quality *assessment* rather than *design*.
- **Ubiquitous language** — DDD's practice of establishing agreed, objective definitions inside your organization. The only practical fix for the industry's terminological chaos.
- **Function point analysis** — a late-1970s estimation technique that decomposed requirements into units of work; abandoned as subjective, but its "non-function points" gave us the term *non-functional requirements*.

## Reference Tables

**Table 4-1. Common operational architectural characteristics** (heavy overlap with operations and DevOps)

| Term | Definition |
|---|---|
| **Availability** | How much of the time the system must be available; 24/7 requires steps to get back up quickly after any failure |
| **Continuity** | Disaster recovery capability |
| **Performance** | How well the system performs — measured via stress testing, peak analysis, frequency-of-function analysis, response times |
| **Recoverability** | Business continuity: how quickly the system must get back online after disaster; backup strategies, duplicate hardware |
| **Reliability/safety** | Whether the system must be fail-safe or is mission critical in a way that affects lives or large sums. Usually a spectrum, not a binary |
| **Robustness** | Ability to handle error and boundary conditions while running (internet or power failure) |
| **Scalability** | Ability to perform and operate as users or requests increase |

**Table 4-2. Structural architectural characteristics**

| Term | Definition |
|---|---|
| **Configurability** | How easily end users can change configuration through interfaces |
| **Extensibility** | How well the architecture accommodates changes that extend existing functionality |
| **Installability** | How easy it is to install on all necessary platforms |
| **Leverageability/reuse** | Extent to which common components can be leveraged across multiple products |
| **Localization** | Support for multiple languages in entry/query screens and data fields |
| **Maintainability** | How easy it is to apply changes and enhance the system |
| **Portability** | Ability to run on more than one platform (e.g. Oracle and SAP DB) |
| **Upgradeability** | How easy and quick it is to upgrade servers and clients to a newer version |

**Table 4-3. Cloud provider architectural characteristics** (new in the 2nd edition)

| Term | Definition |
|---|---|
| **On-demand scalability** | Provider's ability to scale up resources dynamically based on demand |
| **On-demand elasticity** | Provider's flexibility as resource demands spike |
| **Zone-based availability** | Provider's ability to separate resources by computing zones for resilience |
| **Region-based privacy and security** | Provider's legal ability to store data from various countries; many countries restrict citizen data from leaving the region |

**Table 4-4. Cross-cutting architectural characteristics**

| Term | Definition |
|---|---|
| **Accessibility** | Access for all users, including those with disabilities like colorblindness or hearing loss |
| **Archivability** | Constraints around archiving or deleting data after a period |
| **Authentication** | Ensuring users are who they say they are |
| **Authorization** | Ensuring users access only certain functions (by use case, subsystem, page, business rule, field level) |
| **Legal** | Legislative constraints — GDPR, Sarbanes-Oxley, build/deploy regulations, reservation rights |
| **Privacy** | Ability to encrypt and hide transactions from internal employees, including DBAs and network architects |
| **Security** | Encryption in the database and network communication, remote-access authentication, other measures |
| **Supportability** | Level of technical support needed; extent of logging and other debugging facilities |
| **Usability/achievability** | Level of training required for users to achieve their goals |

**ISO characteristics** (reworded by the authors): Performance efficiency (time behavior, resource utilization, capacity) · Compatibility (coexistence, interoperability) · Usability (appropriateness recognizability, learnability, user error protection, accessibility) · Reliability (maturity, availability, fault tolerance, recoverability) · Security (confidentiality, integrity, nonrepudiation, accountability, authenticity) · Maintainability (modularity, reusability, analyzability, modifiability, testability) · Portability (adaptability, installability, replaceability). The authors **exclude ISO's *functional suitability***, since it describes the motivation to build the software, not an architecture characteristic.

## Mental Models

- **Capabilities vs. behavior.** Architecture characteristics are the system's *capabilities*; the domain is its *behavior*. (Framing carried over from *Head First Software Architecture*.)
- **Design or structure?** Security can be handled by *design* in a monolith (encryption, hashing, salting, fitness functions) or by *structure* in microservices (a hardened service with stricter access protocols). Scalability offers no such choice — **no amount of clever design lets a monolith scale past a point; the system must become distributed.** This is why operational characteristics get the most architectural attention: they most often demand structural support.
- **Flying a helicopter.** Controls for each hand and each foot, all synergistic — changing one impacts all the others. That is the trade-off process for characteristics: improving *security* almost certainly degrades *performance* (on-the-fly encryption, indirection to hide secrets).
- **Terms that look identical usually aren't.** *Interoperability* implies ease of integration with other systems, hence published, documented APIs; *compatibility* concerns industry and domain standards. *Learnability* means either "how easily users learn the software" or "how well the system self-configures via ML." *Availability ≠ reliability*: IP is available but not reliable — packets arrive out of order and the receiver must re-request.

## Worked Example

**Deciding whether "security" is an architecture characteristic on your project.** Run the three criteria:

1. *Nondomain?* Yes — no business requirement describes encryption schemes; it's a capability, not a behavior. ✅
2. *Influences structure?* **This is the discriminating question.** Every project takes baseline precautions during design and coding — that alone does *not* make it architectural. It rises to an architecture characteristic only when the architect determines the architecture needs **special structure** to support it: e.g. in microservices, building a separately hardened service with stricter access protocols. In a monolith handled purely by coding hygiene, it stays a design concern. ⚠️ Depends
3. *Critical to success?* For a payments system, yes; for an internal reporting tool, possibly not — and every "yes" here adds complexity you must pay for forever. ⚠️ Depends

*Then check the synergy*: adding it will degrade performance through encryption and indirection. If performance is also on your list, you've just created a trade-off to be resolved explicitly rather than discovered in production.

**Lesson**: the same word ("security") is architectural on one project and not on another. The criteria, not the word, decide.

## Anti-patterns

- **Calling them "non-functional requirements"** — a self-denigrating label that makes it hard to get teams to invest in them.
- **Calling them "quality attributes"** — implies assessment after the fact rather than deliberate design.
- **Maximizing characteristics** — trying to support every "-ility" produces a generic architecture that solves every business problem badly. Support is never free: design effort, implementation effort, maintenance, and often structural cost.
- **Assuming a shared vocabulary exists.** There is no complete standard; ISO's list is an incomplete category list. Organizations invent their own terms, or worse, use the same term for wildly different meanings. Fix with a ubiquitous language and objective definitions.
- **Waiting for the perfect architecture** instead of designing for iteration.

## Key Takeaways
1. Apply all three criteria before accepting anything as an architecture characteristic — nondomain, structural, critical.
2. Actively hunt **implicit** characteristics from domain knowledge; they never appear in the requirements doc but sink the project.
3. Walk all four categories (operational, structural, cloud, cross-cutting) so nothing is silently omitted.
4. Ask "design or structure?" for each candidate — that answer determines whether it is your problem or the team's.
5. Expect synergy: every characteristic you add interacts with all the others and with the domain. Name the interactions.
6. Choose the **fewest** characteristics, and aim for the **least worst** architecture, not the best.
7. Establish objective definitions internally (ubiquitous language); the industry will never give you one.
8. Optimize for iterability so being wrong is cheap.

## Connects To
- **Ch 1**: characteristics are the first of the four dimensions; the First Law explains their synergy.
- **Ch 3**: modularity as an implicit characteristic; metrics for structural characteristics.
- **Ch 5**: how to identify and qualify characteristics from domain concerns and requirements.
- **Ch 6**: measuring and governing them with fitness functions.
- **Ch 7**: the *scope* of characteristics and their relation to coupling; DDD bounded contexts.
- **Ch 8**: logical component design — the other half of structural design.
- **Ch 19**: choosing an architecture style based on the characteristics you selected.
