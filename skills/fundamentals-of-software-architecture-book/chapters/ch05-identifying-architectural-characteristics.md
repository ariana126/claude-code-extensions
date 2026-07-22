# Chapter 5: Identifying Architectural Characteristics

## Core Idea
Architecture characteristics come from three sources — **domain concerns**, **explicit requirements**, and **implicit domain knowledge** — and the architect's job is to translate business language into "-ilities," then ruthlessly cut the list down to the top three.

## Frameworks Introduced

- **The Three Sources of Architecture Characteristics**: (1) domain concerns voiced by stakeholders, (2) explicit statements in requirements documents, (3) the architect's own implicit domain knowledge. Domains carry their own implicit characteristics — an architect on medical diagnostic software already internalizes data integrity and the consequences of lost messages.

- **The Domain-Concern Translation Table** — architects and stakeholders speak different languages ("lost in translation"). Architects say scalability, interoperability, fault tolerance, learnability, availability; stakeholders say mergers and acquisitions, user satisfaction, time to market, competitive advantage.

  **Table 5-1. Translating domain concerns into architectural characteristics**

  | Domain concern | Architectural characteristics |
  |---|---|
  | Mergers and acquisitions | Interoperability, scalability, adaptability, extensibility |
  | Time to market | Agility, testability, deployability |
  | User satisfaction | Performance, availability, fault tolerance, testability, deployability, agility, security |
  | Competitive advantage | Agility, testability, deployability, scalability, availability, fault tolerance |
  | Time and budget | Simplicity, feasibility |

  - When to use: in the first stakeholder session, to turn business goals into justifiable architecture decisions.

- **Composite architectural characteristics** — a characteristic with no single objective definition, composed of other measurable things. **Agility** is the canonical example: it decomposes into **deployability + modularity + testability**, all of which *are* measurable.
  - When to use: whenever a stakeholder names a goal you can't directly measure. Decompose it and give each part an objective definition.
  - Failure mode: latching onto one constituent for convenience — *"like forgetting to put the flour in the cake batter."*

- **Architecture Katas** (devised by Ted Neward, adapted by the authors at `fundamentalsofsoftwarearchitecture.com`) — timeboxed practice exercises for deriving characteristics from domain descriptions. *Kata* is Japanese for a solo martial-arts training exercise emphasizing proper form.
  - Rationale (Fred Brooks): *"How do we get great designers? Great designers design, of course."* Architects design maybe half a dozen systems in a career — practice must be manufactured.
  - **Kata sections**: *Description* (the domain problem) · *Users* (expected number and types) · *Requirements* (domain requirements) · *Additional context* (considerations outside the requirements that still influence design — the 2nd-edition addition that makes exercises realistic).
  - How: small teams design for a set time (characteristics analysis + diagrams), then share and vote. An experienced architect evaluates the trade-off analysis and names missed trade-offs.

- **The Architecture Characteristics Worksheet** (downloadable at `developertoarchitect.com/resources.html`) — run as an interactive, architect-facilitated session:
  1. **Seven slots** on the left for the desired characteristics. (Why seven? An architect must restrict the list to some reasonable number — six or eight would also work.)
  2. **Second column** lists implicit characteristics present in most systems; "pull" one into the first column when it becomes a driving concern requiring special design.
  3. If the first column fills and a better item appears, move the displaced one to **"Others Considered."**
  4. **Final step**: collaboratively check the **top three** highest-priority characteristics, *in any order*.
  - Why the top three, unordered: full ranking is *a fool's errand* — stakeholders rarely agree on the priority of every characteristic, wasting time and generating frustration. Picking three unordered items makes consensus achievable and drives the real discussion about what matters.

- **The Elimination Test**: once you have a first-pass list, ask *"if I had to eliminate one, which would it be?"* Determining the least applicable characteristic is how you test for critical necessity. Generally you cull **explicit** characteristics first — implicit ones tend to support general success.

## Key Concepts

- **Scalability** — handling a large number of concurrent users without serious performance degradation (increase of users *over time*).
- **Elasticity** — withstanding *bursts* of traffic. Often confused with scalability but has different constraints. Some systems are scalable but not elastic (a hotel reservation system's traffic is predictably seasonal); a concert-ticket booking system needs high elasticity when tickets drop.
- **Explicit characteristic** — appears in a requirements specification.
- **Implicit characteristic** — not stated, but necessary; derived from domain knowledge.
- **Sacrificial architecture** — a deliberately simple architecture chosen under cost, time, or skill-set constraints, expected to be replaced.
- **Internationalization (i18n)** — supporting multiple locales; usually a design and UX concern rather than a structural one.
- **Generic architecture** — the antipattern of designing to support *all* characteristics.

## Mental Models

- **Decode domain language into engineering equivalents.** "Thousands, perhaps millions of users" is never written as "we need scalability" — the architect performs that translation.
- **What isn't in the requirements is often what decides the design.** A university registration system for 1,000 students over 10 hours: do you design for even distribution, or for all 1,000 students registering in the final 10 minutes? Anyone who knows student procrastination knows the answer — and no requirements document will tell you.
- **Overspecifying is as damaging as underspecifying.** Because characteristics are synergistic, every extra one overcomplicates the design.
- **"There are no wrong answers in architecture, only expensive ones."** (Mark Richards)
- **Guard against manufactured brittleness.** If the external traffic service is down, should the whole site fail — or just be slightly less efficient? Don't build fragility in by over-specifying reliability at integration points.
- **Define characteristics in relation to each other.** Establish a performance baseline *without* scale, then an acceptable performance level *at* a given number of users.

## Worked Example

**Kata: Silicon Sandwiches**

> *Description*: A national sandwich shop wants online ordering in addition to call-in.
> *Users*: Thousands, perhaps one day millions.
> *Requirements*: (1) place an order, select pickup or delivery where offered; (2) give pickup customers a time and directions, integrating with external mapping services that include traffic; (3) dispatch a driver for delivery; (4) mobile device accessibility; (5) national daily promotions and specials; (6) local daily promotions and specials; (7) accept payment online, at the shop, or on delivery.
> *Additional context*: shops are franchised with different owners; the parent company plans overseas expansion; the corporate goal is inexpensive labor to maximize profit.

**Step 1 — Explicit characteristics, requirement by requirement:**

| Input | Derived characteristic | Reasoning |
|---|---|---|
| "Thousands, perhaps millions" | **Scalability** | Never asked for directly; expressed as a user count |
| Meal-time traffic (not stated) | **Elasticity** | Sandwich traffic bursts around mealtimes — lurking in the problem domain |
| Order / pickup-or-delivery | *none* | No special structural need |
| External mapping services | Reliability (**bounded**) | Integration points affect reliability — but don't fail the whole site when traffic data is unavailable |
| Dispatch driver | *none* | — |
| Mobile accessibility | **Performance** (page-load) | Points to a mobile-optimized web app over multiple native apps, given budget and simplicity. *Collaborate with UX before deciding* |
| National + local promotions | **Customizability** | Also implies location-based traffic customization |
| Payment online/shop/delivery | Security (implicit only) | Nothing suggests security beyond baseline |
| Franchised shops, different owners | Feasibility / cost | May warrant a simple or sacrificial architecture |
| Overseas expansion | Internationalization | Design and UX, not structure |
| Inexpensive labor | Usability | Design, not architecture |

**Step 2 — Implicit characteristics**: availability (users can reach the site), stability (the site stays up mid-interaction; nobody wants to be logged out mid-purchase), security (third-party payments + general hygiene: no plaintext card numbers, don't store too much).

**Step 3 — Architecture or design?** Customizability could be structural (**microkernel**, Ch 13 — default behavior in the core, location-specific parts as plug-ins) or pure design (**Template Method** — parent defines the workflow, children override). Resolve with three questions: (a) are there good reasons *not* to use microkernel, e.g. performance and coupling? (b) are other desirable characteristics harder under one option? (c) what does it cost to support all characteristics in the *architecture* versus in the *design*?

**Step 4 — Eliminate one.** The candidates are customizability (push it down into application design) or performance (the least critical *operational* characteristic here). Dropping performance doesn't mean building something slow — it means not prioritizing it over scalability and availability.

**Lesson**: "There is no best design in architecture, only a least worst collection of trade-offs."

## Anti-patterns

- **Generic architecture** — designing to support *all* characteristics. If you hand stakeholders a long list and ask which they want, the answer is always **"All of them!"**
- **The *Vasa*** — the definitive case study in overspecification. A Swedish warship (1626–1628) built to be both troop transport *and* gunship, with two decks instead of one and cannons twice the normal size. Expert shipbuilders had misgivings but couldn't say no to King Adolphus. On its maiden voyage it fired a salute in Stockholm harbor, capsized from being top-heavy, and sank. Salvaged in 1961; now a museum piece.
- **False equivalence with composites** — equating agility solely with time to market, or answering "we must finish end-of-day fund pricing on time" with performance alone. That fails because: it doesn't matter how fast it is if it isn't *available*; more funds means it must *scale*; it must be *reliable* enough not to crash mid-calculation; it must be *recoverable* enough to restart from 85% complete; and the prices must be *auditably* correct. Performance was one of six.
- **Ivory Tower architecture** — making architecture decisions in isolation from the implementation team. Collaborate with developers, tech leads, project managers, operations, and domain analysts.
- **Chasing the exactly correct set of characteristics** — developers can implement functionality many ways; identifying the important *structural* elements just enables a simpler design.

## Key Takeaways
1. Mine all three sources: what stakeholders say, what the requirements state, and what only your domain knowledge knows.
2. Translate business goals into "-ilities" using Table 5-1 — it is the bridge across the language gap.
3. Decompose composites (agility → deployability + modularity + testability) and define each part objectively.
4. Separate explicit from implicit characteristics; hunt implicit ones deliberately, because nobody will write them down.
5. Distinguish scalability (growth over time) from elasticity (bursts) — they have different constraints.
6. Use the worksheet: max seven candidates, then get consensus on the **top three, unordered**. Never try to fully rank them.
7. Ask "which would I eliminate?" to test true criticality.
8. Ask "architecture or design?" before committing structure — customizability is often a design pattern, not an architecture style.
9. Practice with katas; you will not get enough real reps in a career.

## Connects To
- **Ch 4**: the three criteria and the four categories that define what qualifies as a characteristic.
- **Ch 6**: giving composite characteristics objective, measurable definitions; the ubiquitous language.
- **Ch 7**: the *scope* of the characteristics you've identified — architecture quantum.
- **Ch 8**: logical component design, the other half of structural design.
- **Ch 13**: microkernel as the structural answer to customizability.
- **Ch 21**: capturing the trade-off analysis behind these choices as ADRs.
