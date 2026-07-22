# Cheatsheet — Fundamentals of Software Architecture (2nd Ed.)

## Style selection decision tree
- **One set of architecture characteristics suffices?** → **monolithic**
  - Changes mostly **technical** (UI/DB replacement)? → **Layered** (Ch 10)
  - Changes mostly **domain**-shaped, or doing DDD? → **Modular monolith** (Ch 11)
  - Distinct, ordered, **deterministic one-way** processing steps? → **Pipeline** (Ch 12)
  - Domain requires **customization** per client/location/jurisdiction? → **Microkernel** (Ch 13)
- **Multiple sets of characteristics needed?** → **distributed**
  - Want distributed benefits at low cost; **ACID** transactions needed; unsure how far to decompose? → **Service-based** (Ch 14) — *also the stepping stone*
  - System **reacts to things that happened**; needs extreme responsiveness + evolvability? → **Event-driven** (Ch 15)
  - Need **>10,000 concurrent users** / unpredictable spikes; database is the ceiling? → **Space-based** (Ch 16)
  - Need **variation in operational characteristics per service**, plus max scalability/evolvability? → **Microservices** (Ch 18)
  - Integration-heavy legacy/modern mix? → **ESB as integration architecture only** (Ch 17) — never as the whole architecture
- **Then**: quantum boundaries → persistence → **sync by default, async only when necessary**

## Ratings at a glance (★ = weak, ★★★★★ = signature strength)

| Style | Cost | Simplicity | Deploy | Test | Scale | Elastic | Fault tol. | Perf/Resp | Evolve |
|---|---|---|---|---|---|---|---|---|---|
| **Layered** | ★★★★★ | ★★★★★ | ★ | ★★ | ★ | ★ | ★ | ★★★ | ★ |
| **Modular monolith** | ★★★★★ | ★★★★★ | ★★ | ★★ | ★ | ★ | ★ | ★★ | ★★★ |
| **Pipeline** | ★★★★★ | ★★★★★ | ★★★ | ★★★ | ★ | ★ | ★ | ★★ | ★★★ |
| **Microkernel** | ★★★★★ | ★★★★★ | ★★★ | ★★★ | ★ | ★ | ★ | ★★★ | ★★★ |
| **Service-based** | ★★★★ | ★★★★ | ★★★★ | ★★★★ | ★★★ | ★★ | ★★★★ | ★★★ | ★★★★ |
| **Event-driven** | ★★★ | ★★ | ★★★ | ★★ | ★★★★ | ★★★★ | ★★★★ | ★★★★ | ★★★★★ |
| **Space-based** | ★ | ★ | ★★★ | ★ | ★★★★★ | ★★★★★ | ★★★ | ★★★★★ | ★★★ |
| **Orchestration SOA** | ★ | ★ | ★ | ★ | ★★★ | ★★★ | ★★★ | ★★ | ★ |
| **Microservices** | ★ | ★ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★★ | ★★★★★ | ★ | ★★★★★ |

## Thresholds & defaults

| Metric | Value |
|---|---|
| Cyclomatic Complexity | **<5** preferred (industry says <10); **>50** = unrecoverable by coverage |
| Architecture Sinkhole requests | ≤20% OK; **80% = wrong style** |
| Domain services on one database | **≤12** |
| Microservices sharing one database | **≤5–6** |
| Modular monolith coupling points per module | **≤5** (pick a number and enforce it) |
| Replicated cache size | **<100 MB**; >500 MB → distributed |
| Replication latency (planning default) | **100 ms** |
| Space-based use threshold | **>10,000 concurrent users** |
| Large team / small team | **>12** / **≤5** |
| Handshake duration | **2–3 seconds** |
| Daily learning | **20 minutes, before email** |

## Availability: say seconds, not nines

| Uptime | Downtime/year (per day) |
|---|---|
| 99.0% | 87 hrs 46 min (14 min) |
| **99.9%** | **8 hrs 46 min (86 sec)** |
| 99.99% | 52 min 33 sec (7 sec) |
| **99.999%** | **5 min 35 sec (1 sec)** |

**Rule**: translate out of "nines" before negotiating. It converts an ego argument into an arithmetic one.

## Event payload: data-based vs. key-based

| Criterion | Data-based | Key-based |
|---|---|---|
| Performance & scalability | **Good** | Bad |
| Contract management | Bad | **Good** |
| Stamp coupling | Bad | **Good** |
| Bandwidth | Bad | **Good** |
| Restricted DB access | **Good** | Bad |
| System fragility | Bad | **Good** |

**Decide per event, not per system.** Extreme scale → data-based. Frequently changing data → key-based. Updates → include **prior values** or you get anemic events.

## Orchestration vs. choreography

| Need | Choose |
|---|---|
| State, error handling, recoverability, restart | **Orchestration** |
| Responsiveness, scalability, decoupling, parallelism | **Choreography** |

Orchestration's costs: throughput bottleneck, single point of failure, fewer parallelism opportunities, tighter coupling.

## Caching: replicated vs. distributed

| Criterion | Replicated | Distributed |
|---|---|---|
| Optimizes | **Performance** | **Consistency** |
| Cache size | <100 MB | >500 MB |
| Data type | Relatively static | Highly dynamic |
| Update frequency | Low | High |
| Fault tolerance | **High** | Low |

*Mix both across processing units. Never near-cache.*

## Database type by read/write priority
- Write-heavy → **columnar** · Read-heavy → **key-value, document, graph** · Balanced → **relational, NewSQL**
- Amplify scalability/elasticity styles (microservices, EDA, space-based) with **key-value or columnar**

## Architect involvement (Elastic Leadership) — score ±20 each

| Factor | +20 (more) | −20 (less) |
|---|---|---|
| Team familiarity | New members | Know each other |
| Team size | >12 | ≤5 |
| Experience | Mostly junior | Mostly senior |
| Complexity | High | Simple |
| **Duration** | **Long (2 yrs)** | **Short (2 mo)** ⟵ counterintuitive |

Negative total → facilitate and stay out of the way. Positive → mentor and coach without disrupting.

## Tells & smells

| If you see… | You're probably in… |
|---|---|
| Component named `*Manager`, `*Handler`, `*Processor` | **Entity Trap** (Ch 8) |
| Role statement full of *and*/*also*/*as well as* | Component doing too much (Ch 8) |
| Frequent merge conflicts | **Process loss** — team too large (Ch 24) |
| Silent nods in a large meeting | **Pluralistic ignorance** (Ch 24) |
| Work dropped, unclear ownership | **Diffusion of responsibility** (Ch 24) |
| Heavy intermodule/interservice chatter | Domains defined wrong, or wrong style (Ch 11, Ch 14, Ch 18) |
| "We need a distributed transaction" | **Granularity too fine** (Ch 18) |
| Same decision debated repeatedly | **Groundhog Day** — you never gave the *why* (Ch 21) |
| Architect reflexively citing one past incident | **Frozen Caveman** (Ch 2) |
| Architect owns critical-path code | **Bottleneck Trap** (Ch 2) |
| Requirements say "all of them" | You asked stakeholders to rank instead of pick three (Ch 5) |
| Diagram nobody wants to change | **Irrational Artifact Attachment** (Ch 23) |
| "That's an implementation detail" | Implementation/architecture misalignment (Ch 26) |
| Team wants decoupling **and** high reuse | Fundamentally incompatible — reuse *is* coupling (Ch 27) |

## Decision rules that survive context
- **Guide, don't specify** — "use a reactive framework," not "use React" — unless a characteristic depends on the exact technology.
- **Two things are coupled if changing one might break the other.** Higher coupling is allowed at narrower scope.
- **Reuse requires abstraction *and* low volatility.** Reuse plumbing; never reuse the domain.
- **The database is inside the quantum.** Shared database = one quantum, regardless of how many services.
- **Give the justification before the demand** — people stop listening once they disagree.
- **Decide at the last responsible moment**: when deferral cost exceeds decision risk.
- **Rate unknown technology 9.** The risk matrix doesn't apply to ignorance.
- **Demonstration defeats discussion.**
- **Never strive for the best architecture; aim for the least worst.**
- **An architecture decision is one where every option carries significant trade-offs.**
- **Use an LLM to enumerate trade-offs, never to choose.** Knowledge is not wisdom.
