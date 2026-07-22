# Boundaries, Contexts, and Components — Full Reference

Read this when identifying bounded contexts or components, mapping the
relationships between contexts, deciding what to build versus buy, breaking up a
monolith, or measuring whether existing components are coupled sensibly.

## Contents

1. [When to Draw a Boundary](#1-when-to-draw-a-boundary)
2. [Top-Level Partitioning](#2-top-level-partitioning)
3. [Subdomains: Where to Spend Effort](#3-subdomains-where-to-spend-effort)
4. [Bounded Contexts](#4-bounded-contexts)
5. [Context Mapping](#5-context-mapping)
6. [Distillation and the Core Domain](#6-distillation-and-the-core-domain)
7. [Finding Components](#7-finding-components)
8. [Component Cohesion](#8-component-cohesion)
9. [Component Coupling and the Metrics](#9-component-coupling-and-the-metrics)
10. [Partial Boundaries](#10-partial-boundaries)

---

## 1. When to Draw a Boundary

| Signal | Action |
|---|---|
| Two things change at **different rates** or for **different actors** | Draw a boundary |
| The axis of change is a **detail** — database, UI, framework, device | Draw it; essentially always worth it |
| Symmetric, high-traffic, and always changes together | **Don't.** The boundary costs more than it returns |
| Plausible but unproven | **Partial boundary** — pay half now, upgrade later |

The actor-based reading of the SRP is what makes this operational: **split a module
when two different actors would request changes to it.** Not "when it does two
things" — that phrasing is vague enough to justify anything. Two teams repeatedly
merging conflicts in the same class is the observable version of the same signal.

**Boundaries are expensive and require guessing the future.** Over-engineering and
under-engineering both cost real money; the honest position is that you will get
some of them wrong, which is exactly why the partial boundary exists.

**Decoupling has levels — take the cheapest that works.** Source level, then
deployment level, then service level. Push the decision as late as possible and be
willing to move *back down* a level when evidence says you over-committed.

A useful falsification test: **a cross-cutting feature that touches every service
proves the boundary was drawn in the wrong dimension.** If "add a new pet type"
requires editing all six services, the decomposition axis was wrong, not the
implementation.

---

## 2. Top-Level Partitioning

The first structural decision, and one of the hardest to reverse:

- **Technical partitioning** — presentation, business, persistence. Suits systems
  whose changes are mostly technical. Its weakness is that every domain feature
  cuts across every partition.
- **Domain partitioning** — organised by domain or workflow. Suits everything
  else, and is required if you're doing DDD. Its weakness is duplicated technical
  concerns across domains.

**Heavy chatter between top-level pieces means you partitioned on the wrong axis.**
This is the same diagnosis whether the pieces are layers, modules, or services.

**Conway's Law is a constraint, not an observation.** Organisations produce designs
that copy their own communication structures, so a decomposition that fights the
org chart will lose. The **Inverse Conway Maneuver** — changing team structures to
promote the architecture you want — is the available lever. Team topologies
(stream-aligned, enabling, complicated-subsystem, platform) give the vocabulary.

---

## 3. Subdomains: Where to Spend Effort

Classify every subdomain, because the classification determines the investment:

| Type | Meaning | What to do |
|---|---|---|
| **Core Domain** | Where you must excel; your competitive advantage | **Build it.** Staff it with your best people. Apply the tactical patterns here |
| **Supporting** | Essential and specialised, but not differentiating | Build or contract out |
| **Generic** | Required but unremarkable — auth, billing, notifications | **Buy or outsource.** Never lavish core effort here |

**Misclassifying a generic subdomain as core is the most expensive mistake
available.** The observable version: your best developers are building an identity
service while the core domain tangles, and elegant peripheral features ship on
schedule while the thing that makes money doesn't.

**Should you use DDD here at all?** Vernon's scorecard sets the bar at a total of
**7 or higher**. Decide early — the complexity commitment becomes unchangeable a
few use cases in. Applying the tactical patterns with no strategic design behind
them is **DDD-Lite**, and it rots.

---

## 4. Bounded Contexts

A bounded context is a region where everything about a portion of the domain is
visible and coherent internally, and opaque outside. Inside it, every term means
exactly one thing.

### Sizing

- **Fewer than ten people**, roughly **one team per context**. Two teams in one
  context will diverge the language regardless of discipline — split the context or
  merge the teams.
- Continuous integration is required for any context larger than a two-person task;
  fragmentation begins at three or four people.
- Unintegrated changes need a small upper bound on lifetime — most teams merge
  daily.

### The earliest warning signs

| You see | Diagnosis |
|---|---|
| Confusion of language between teams | The **earliest** warning of a broken context boundary |
| Two people using the same term differently | A **false cognate** — the most insidious splinter |
| The same concept implemented twice with conversions between them | **Duplicate concepts**; the promised reanalysis of the second never happens |
| A term in expert speech that appears nowhere in the design | A missing model element — chase it |
| Heavy chatter between contexts | The boundary is in the wrong place |

### When *not* to make one

When the terminology is merely fuzzy and the boundary unclear, separate the
concepts with a **module** instead. A module is thinner and reversible; a bounded
context is a commitment with a team, a language, and usually a deployment attached.

---

## 5. Context Mapping

Before integrating anything, draw the map and label each relationship with its
direction — **U** for upstream, **D** for downstream.

| Relationship | Meaning | When it's right |
|---|---|---|
| **Partnership** | Two contexts succeed or fail together; coordinated planning | Genuine mutual dependency with aligned incentives |
| **Shared Kernel** | A jointly owned subset of the model; changes require agreement | Small, stable, and both teams can commit to the coordination cost |
| **Customer-Supplier** | Upstream genuinely plans around downstream's needs | Upstream has real incentive to serve you, usually same organisation |
| **Conformist** | Downstream adopts the upstream model wholesale, no translation | The upstream model is good, or you have no leverage and translation isn't worth it |
| **Anticorruption Layer** | Downstream translates defensively | Default when consuming anything you don't control |
| **Open Host Service** | Upstream publishes a protocol for many integrators | You are the upstream and have several consumers |
| **Published Language** | A documented shared exchange language | Industry standards, or an OHS that has stabilised |
| **Separate Ways** | No integration at all; duplicate instead | Two feature sets that never call each other or share data |
| **Big Ball of Mud** | Mixed models, boundaries unenforced | Never chosen — only discovered. Map it honestly and contain it |

### The judgment calls

- **Assuming Customer-Supplier where the reality is Conformist kills projects
  late.** Altruism may motivate upstream developers to make promises, but they are
  unlikely to fulfil them. Test the relationship before designing around it.
- **When an upstream team won't serve you, you have exactly three options:**
  Separate Ways, Conformist, or Anticorruption Layer. There is no fourth.
- **When an off-the-shelf component has a large interface, conform to its model.**
  If it's good enough to give you value, there is probably knowledge crunched into
  its design.
- **Separate Ways is a legitimate choice.** Integration is always expensive, and
  sometimes the benefit is approximately zero. Duplication across contexts is not
  the same sin as duplication within one.
- **Shared Kernel merges less often than internal CI.** Daily CI inside a context,
  weekly kernel merge across them, as a starting cadence.

### The anticorruption layer

Use one **any time a foreign context's representation enters your model** — even
when the upstream offers an Open Host Service. Three parts: a **separated
interface** in your domain model, an **adapter** that owns the HTTP, messaging, or
JSON, and a **translator** that produces your local domain type. Your model never
sees the foreign vocabulary.

It costs more classes and pays for itself the first time the upstream changes.
The tell that you skipped it: foreign vocabulary appearing in your domain types.

### Integration smells

- **Exposing navigable model resources** makes every consumer a Conformist or
  creates an accidental Shared Kernel. Publish **use-case-shaped** resources.
- **Replicating an upstream database "for autonomy"** is a Shared Kernel with extra
  steps, and gives you no autonomy at all.
- **Acting on events without passing `occurredOn` into the command** ignores that
  messaging is out-of-order and at-least-once. Guard the aggregate with a change
  tracker.
- **Retrying against a non-idempotent receiver** produces only misleading errors.
  Make the operation find-then-create first.

---

## 6. Distillation and the Core Domain

Distillation is the work of separating what matters from what merely exists.

- **The core domain should be small.** Be minimalist; move a class into it only
  when your stories require it.
- **A domain vision statement is about one page.** A distillation document is
  **three to seven sparse pages**. An anchor diagram holds **three to five
  objects**. If yours are larger, they are not distillations.
- **When choosing between two desirable refactorings, the one touching the core
  domain wins.**
- **When choosing what to keep secret, keep the core domain secret and nothing
  else.** There is no value in concealing the rest.
- **A document whose terms never appear in speech or code** is wrong, too big, or
  unimportant. Archive it.

Supporting techniques: extract a **generic subdomain** into its own module (or buy
it); extract a **cohesive mechanism** when an algorithm is conceptually separable
from the policy that uses it; use a **segregated core** or **abstract core** when
the core is entangled with supporting code you can't remove.

**When a framework constrains your core**, there are exactly three explanations:
back the framework off, redraw the core, or admit you have no special needs and
the framework's model is fine. Pick one explicitly.

---

## 7. Finding Components

Below the context sits the component: a building block implementing a business
function, physically a namespace or directory leaf node.

### The identification cycle

Identify core components → assign user stories → analyse roles and
responsibilities → analyse architecture characteristics → refactor → repeat.
**It never terminates by design.** Resist perfecting the first pass.

### Two starting approaches

- **Workflow approach** — one component per major happy-path step. Leaner.
- **Actor–Action approach** — major actions per actor, where **the system is always
  an actor**. Generates more components; suits multi-actor systems.

Neither maps one-to-one; several workflow steps can legitimately share a component.

### Two tests

**The entity trap.** Components derived from entities — one component per database
table — is the most common decomposition failure. Tells: names ending in
`Manager`, `Supervisor`, `Controller`, `Handler`, `Engine`, `Processor`. These
names describe machinery, not business capability. The same smell appears in
Evans as objects named `…Manager` or `…Doer` with no state and no domain meaning:
that's a service in disguise.

**The conjunction test.** Write the component's role and responsibility statement
as prose, then count the *ands*, *alsos*, *in additions*, *as well ases*, and
commas. Cheap, subjective, and remarkably reliable.

### Law of Demeter, honestly stated

Find *knowledge* a component holds that isn't its *responsibility*, and defer it
downstream. But be clear about what this achieves: it **redistributes** coupling
rather than eliminating it — the receiving component becomes more coupled. That is
often the right trade, and it is still a trade.

---

## 8. Component Cohesion

Three principles that pull against each other. You cannot satisfy all three.

- **REP (Reuse/Release Equivalence)** — the granule of reuse is the granule of
  release.
- **CCP (Common Closure)** — things that change together belong together.
- **CRP (Common Reuse)** — don't force consumers to depend on things they don't
  use.

**Favour CCP early**, when reusability doesn't matter yet and change velocity is
high. **Shift toward REP and CRP as the project matures** and other teams start
consuming you. Your position in this tension is a *project-lifecycle* decision, not
a permanent identity.

The cohesion scale itself, best to worst: functional, sequential, communicational,
procedural, temporal, logical, coincidental. LCOM (lack of cohesion in methods)
measures it mechanically, but the scale is more useful for judgment.

---

## 9. Component Coupling and the Metrics

| Metric | Formula | Reading |
|---|---|---|
| **I** (Instability) | `Ce / (Ca + Ce)` | 0 = maximally stable; 1 = maximally unstable |
| **A** (Abstractness) | `Na / Nc` | 0 = all concrete; 1 = all abstract |
| **D** (Distance) | `\|A + I − 1\|` | 0 = on the main sequence; 1 = as far off as possible |

Where **Ca** is afferent coupling (fan-in: how many components depend on this one)
and **Ce** is efferent coupling (fan-out: how many this one depends on).

Two principles follow:

- **SDP (Stable Dependencies)** — depend in the direction of stability. `I` must
  *decrease* along each dependency.
- **SAP (Stable Abstractions)** — a stable component should be abstract. Stable and
  concrete is rigid, because everything depends on it and it cannot be extended.

### The two dead zones

- **Zone of Pain** (A≈0, I≈0) — concrete and heavily depended upon. Only harmful
  when the component is **volatile**; a stable database schema or a standard
  library lives here quite happily. The genuinely painful case is the "shared"
  library everyone depends on and everyone edits.
- **Zone of Uselessness** (A≈1, I≈1) — abstract with nothing depending on it. Dead
  abstraction. Delete it.

Aim for the endpoints of the main sequence, and flag components with high `D` or
high variance in `D`.

### Cycles

A cycle in the component graph costs you the "morning after" build. Break it two
ways: invert one dependency behind an interface (DIP), or extract a new component
that both sides depend on. Enforce the acyclic dependencies principle continuously
with a fitness function — cycles reappear the moment nobody is checking.

### Connascence, as the finer instrument

Static, weakest to strongest: **name → type → meaning → position → algorithm.**
Dynamic, weakest to strongest: **execution → timing → values → identity.**

Three rules: prefer static over dynamic, prefer weaker over stronger, and
**increase locality**. Strong connascence within one class is fine; the same
connascence across a network boundary is a defect waiting for a deploy. This is
the precise reason sagas are expensive — connascence of values across services.

**Temporal coupling** — nonstatic dependencies based on timing or transaction
order — deserves special mention because tooling cannot detect it. Two objects
that must be used in a fixed order is the class-level version; merge the
responsibility.

---

## 10. Partial Boundaries

When a boundary is plausible but unproven, pay half.

- **Skip the last step.** Do all the work of a full boundary — separate interfaces,
  separate component structure — but keep it in one deployable. Promotion later is
  mechanical.
- **One-dimensional boundary (Strategy).** An interface with a single
  implementation, positioned where the second one would go. Cheap; degrades quietly
  if nobody maintains the discipline.
- **Facade.** No interface at all — just a class that all access goes through.
  Cheapest, weakest, and still better than nothing, because it gives you one place
  to change.

The **humble object** pattern is the related move at the code level: split
hard-to-test behaviour from easy-to-test behaviour, push the untestable part
(rendering, I/O, framework glue) to the very edge, and leave the policy testable.
Business logic in a presenter or controller is this pattern inverted.

Use these when uncertain, and treat the promotion or removal of a partial boundary
as a decision worth an ADR — including the decision to remove one, which is the
one teams never make.
