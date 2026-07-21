# Clean Architecture — Cheatsheet

Decision rules, thresholds, and tells. Definitions live in [glossary.md](glossary.md); techniques in [patterns.md](patterns.md).

## The one rule everything reduces to

> **The Dependency Rule** — *Source code dependencies must point only inward, toward higher-level policies.*

If a change to a detail (DB, web, framework, device) forces a change to a business rule, the rule is violated. Nothing else in the book overrides this.

## Where does this code go?

| Question | Answer | Layer |
|---|---|---|
| Would this rule be true even with no computer? | Critical Business Rule | **Entities** (innermost) |
| Is it a rule that only exists because the app is automated? | Application-Specific Business Rule | **Use Cases** |
| Does it convert data between use-case form and an external form? | Conversion, not policy | **Interface Adapters** (controllers, presenters, gateways) |
| Is it something you didn't write, or a device? | Detail | **Frameworks & Drivers** (outermost) |

**Test:** if you can't answer, ask *"how far is this from the I/O?"* Farther = higher level = further inward (Ch19).

## When to draw a boundary

| Signal | Action |
|---|---|
| Two things change at **different rates** or for **different actors** | Draw a boundary (SRP/CCP) |
| The axis of change is a **detail** (DB, UI, framework, device) | Draw a boundary — always worth it |
| Symmetric, high-traffic, changes together | **Don't** — the boundary costs more than it returns |
| Uncertain but plausible | **Partial boundary** (Ch24) — pay ~half now, upgrade later |

Boundaries are **expensive** and require guessing the future. Over-engineering and under-engineering both cost; err toward the cheap partial boundary and monitor (Ch25).

## Decoupling mode — pick the cheapest that works

Source level → Deployment level → Service level. **Push this decision as late as possible, and be willing to move back down.** Default to a monolith with clean source-level boundaries; promote only under measured pressure (Ch16, Ch27).

- Services are **not** inherently decoupled. They are an expensive boundary, not a free one.
- A cross-cutting feature that touches every service ("the kitty problem") proves the boundary was drawn in the wrong dimension.

## Deferring decisions

**Good architecture maximizes the number of decisions NOT made.** Defer: database, web framework, UI technology, service topology, dependency-injection framework. If you can build and test the whole system without choosing, you have not yet needed to choose.

## SOLID, as decisions

| Principle | The decision it forces |
|---|---|
| **SRP** | Split a module when two *actors* would request changes to it. Not "one thing" — one actor. |
| **OCP** | Arrange components so a new requirement means *adding* code, not editing it. Protect high-level from low-level. |
| **LSP** | If a subtype needs an `if (type == X)` at the call site, the substitution is broken. |
| **ISP** | Don't depend on a module carrying baggage you don't use — it drags its recompiles/redeploys onto you. |
| **DIP** | Refer only to abstract interfaces. Concrete-and-volatile is the thing to avoid; concrete-and-stable (`String`) is fine. |

**Concrete component rule:** every system has at least one concrete component (`Main`). Push all concrete dependencies down into it.

## Component metrics — the numbers

| Metric | Formula | Reading |
|---|---|---|
| **I** (Instability) | `Fan-out / (Fan-in + Fan-out)` | 0 = maximally stable; 1 = maximally unstable |
| **A** (Abstractness) | `Na / Nc` (abstract classes+interfaces ÷ total classes) | 0 = all concrete; 1 = all abstract |
| **D** (Distance) | `\|A + I − 1\|` | 0 = on the Main Sequence; 1 = as far off as possible |

- **SDP:** depend in the direction of stability — `I` must *decrease* along each dependency.
- **SAP:** a stable component should be abstract. Stable + concrete = rigid.
- **Zone of Pain** (A≈0, I≈0): concrete and heavily depended on — e.g. a DB schema. Only *volatile* components here hurt.
- **Zone of Uselessness** (A≈1, I≈1): abstract with no dependents — dead abstraction.
- Aim for the **endpoints of the Main Sequence**; flag components with high `D` or high `D` variance.

## Component cohesion — the tension

REP, CCP, and CRP pull against each other; you cannot satisfy all three.

- Favor **CCP** (changes together, ships together) early — reusability doesn't matter yet.
- Shift toward **REP/CRP** as the project matures and other teams consume you.
- The tension diagram position is a *project-lifecycle* decision, not a permanent one.

## Cycles

Cycle in the component graph → break it with **DIP** (invert one dependency behind an interface) or by **extracting a new component** both can depend on. Enforce ADP continuously; cycles cost you the "morning after" build.

## Tells & smells

| You see… | You're probably… |
|---|---|
| Package structure named `controllers/`, `models/`, `views/` | Screaming the framework, not the use cases (Ch21) |
| Entities importing an ORM/annotation/framework type | Violating the Dependency Rule at the worst layer |
| Two teams merging conflicts in the same class | SRP violation — split by actor |
| Tests break when the UI changes | Fragile Tests Problem — add a Testing API (Ch28) |
| Business logic in a Presenter or Controller | Humble Object inverted — move policy inward |
| `#ifdef` for the processor scattered through app code | No HAL — the target hardware bottleneck (Ch29) |
| Everything `public` because packages need it | Organization without encapsulation (Ch34) |
| A "shared" library everyone depends on and everyone edits | Zone of Pain — split it or stabilize it |

## Anti-rules (things Martin explicitly rejects)

- "SRP means a module does one thing." — No: one *actor*.
- "Microservices are decoupled by definition." — No: only if the boundaries fall on real axes of change.
- "The database is the architecture." — The database is a detail; so is the web, so is the framework.
- "Duplication is always bad." — **True** duplication is; *accidental/false* duplication (two things that merely look alike now) must not be unified.
- "Diagrams enforce architecture." — Only the compiler does. Use access modifiers and module boundaries.
