---
name: architecture-guideline
description: >
  Use this skill for decisions about the shape of a system rather than the shape
  of a class. Triggers: choosing or changing an architecture style; monolith
  versus microservices; splitting a monolith or merging services back; drawing
  service, module, or team boundaries; deciding where a class or piece of logic
  belongs; a domain coupled to a framework, ORM, or HTTP; sync versus async;
  transactional versus eventual consistency; writing an ADR; judging whether
  something is over-engineered. Also use on mention of "architecture
  characteristics", "architecture quantum", "connascence", "fitness function",
  "ADR", "bounded context", "context map", "anticorruption layer", "core
  domain", "aggregate", "hexagonal", "ports and adapters", "dependency rule",
  "modular monolith", "microkernel", "event-driven", "space-based", "saga",
  "CQRS", "event sourcing", or "distributed monolith". Use it even if the user
  only says "how should I structure this?" or "is this architecture any good?" —
  this skill provides the methodology.
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
  sources:
    - "Fundamentals of Software Architecture (2nd Edition) by Mark Richards and Neal Ford"
    - "Clean Architecture by Robert C. Martin"
    - "Advanced Web Application Architecture by Matthias Noback"
    - "Domain-Driven Design by Eric Evans"
    - "Implementing Domain-Driven Design by Vaughn Vernon"
---

# Architecture Guideline Skill

This skill encodes one architecture methodology synthesised from five books that
genuinely disagree with each other. The spine is *Fundamentals of Software
Architecture* by Richards and Ford, because its central claim survives contact
with real projects: **there is no best architecture, only the least worst one**,
and every rule that sounds absolute is a trade-off someone hasn't priced yet.

Where the sources conflict, this skill resolves them the same way every time:

> **Fundamentals wins on *whether* and *which*. Clean Architecture, Noback,
> Evans and Vernon win on *how*, once the decision is made.**

So Martin's Dependency Rule does not decide whether you need a boundary here —
characteristics and trade-offs decide that. But once you've decided a boundary
exists, the Dependency Rule decides which way it points, and Noback decides which
side each class lands on. Evans and Vernon decide where the boundary *goes* when
the axis of change is the domain rather than the technology.

This skill deliberately overlaps with `oop-guideline` at the seam. Where a topic
bottoms out in class mechanics — command/query separation, value objects,
constructor rules, pattern selection — this skill states the architectural rule
and points there for the mechanics.

## Start Here: Is This Even an Architecture Decision?

Two tests, and you need **either** one:

1. **Every option carries a significant trade-off.** If one option is simply
   better, it isn't an architecture decision — it's a preference, and you should
   just take the better one.
2. **It is expensive to reverse.** Structure, dependencies, interfaces,
   deployment topology, and construction techniques qualify. Which logging
   library you use usually does not.

If neither holds, stop applying this skill and use `oop-guideline` instead. Most
"architecture debates" are design debates wearing a costume, and treating them
as architectural is how teams end up with ADRs for things a rename would fix.

Two laws govern everything below. **Everything is a trade-off** — if you think
you've found an option with no downside, you haven't found the downside yet.
And **why is more important than how** — a decision without its justification
gets re-litigated forever, which is the Groundhog Day antipattern.

There is also a prior question, from Noback: **does this project deserve to be
decoupled at all?** A small purely infrastructural script, or something genuinely
generatable from a config file, does not. Anything with actions, state
transitions, or invariants does. Anything that might outlive its stated purpose —
which is every proof of concept that succeeds — does. Automated testing is never
the optional part; only the *type* of test is a choice.

## Step 1 — Derive the Architecture Characteristics

Architecture characteristics are the system's *capabilities*, as distinct from
the domain's *behavior*. They drive the structure, and nothing downstream makes
sense until they exist. Do not skip to a style.

**Pick at most three, unordered.** A full ranking is a fool's errand —
stakeholders never agree on every priority, and asking them to try produces
either deadlock or the answer "all of them", which means you asked the wrong
question. An unordered top three achieves consensus and drives the real
conversation. Aiming to support *all* characteristics is the **generic
architecture antipattern**; it produces a system that is mediocre at everything.

Gather candidates from two places: **explicit** ones stated in requirements, and
**implicit** ones nobody writes down but everybody assumes — availability,
security, maintainability, feasibility, and above all **modularity**, which is
the implicit characteristic most systems live or die by. Then apply the
**elimination test**: ask "if I had to remove one, which would it be?" and cull
the explicit ones first, since implicit ones tend to support general success.
The test measures critical necessity, not desirability.

**A characteristic you cannot measure is a wish.** Each one needs an objective
definition before it counts. Some are composite and have no single definition of
their own — agility, for instance, decomposes into deployability, modularity, and
testability, and you measure those. Anything you can measure, you can then
govern with a fitness function (Step 5).

**Translate abstractions into concrete units before negotiating**, because it
turns an ego argument into an arithmetic one:

| Uptime | Downtime per year (per day) |
|---|---|
| 99.0% | 87 hrs 46 min (14 min) |
| **99.9%** | **8 hrs 46 min (86 sec)** |
| 99.99% | 52 min 33 sec (7 sec) |
| **99.999%** | **5 min 35 sec (1 sec)** |

Nobody argues with "five nines means 86 seconds of downtime *per year*, and our
deploy takes four minutes" the way they argue with "five nines is unrealistic".

**Read `references/characteristics-and-governance.md`** when eliciting
characteristics from stakeholders, defining a measurement for one, or preparing
for a negotiation about a requirement you think is wrong.

## Step 2 — Find the Boundaries

A boundary is the most expensive thing in this skill and the hardest to move
later, so it gets its own step before any style is chosen.

**Draw a boundary when two things change at different rates or for different
actors.** That is the SRP restated at component scale: split a module when two
*actors* would request changes to it — not because it "does two things". When
the axis of change is a **detail** — the database, the UI, the framework, a
device — the boundary is essentially always worth it. When two things are
symmetric, high-traffic, and always change together, **don't** — the boundary
costs more than it returns.

**Top-level partitioning is technical or domain, and you must choose
deliberately.** Technical partitioning (presentation / business / persistence)
suits systems whose changes are mostly technical. Domain partitioning suits
everything else, and is required if you're doing DDD. Heavy chatter between your
top-level pieces means you partitioned along the wrong axis.

**Where the axis of change is the domain, the boundary is a bounded context.**
A bounded context is a region where every term means exactly one thing; the
earliest warning that you've drawn it wrong is confusion of language between
teams. Size it to roughly one team of fewer than ten people — two teams in one
context will diverge the language no matter how disciplined they are. Classify
each subdomain as **core** (build it, staff it with your best people),
**supporting** (build or contract), or **generic** (buy or outsource). Treating a
generic subdomain as core is the most expensive mistake available.

Below contexts sit components. Derive them from the workflow's happy-path steps
or from actors and actions — never from entities. Components named `*Manager`,
`*Handler`, `*Processor`, `*Supervisor`, or `*Engine` are the **entity trap**.
Check each one with the **conjunction test**: write its role as prose and count
the *ands*, *alsos*, and commas. Cheap, subjective, and remarkably reliable.

**Boundaries require guessing the future, so prefer the cheap version.** When a
boundary is plausible but not proven, build a **partial boundary** — pay about
half now, upgrade later. Over-engineering and under-engineering both cost; the
partial boundary is the hedge.

**Read `references/boundaries-and-contexts.md`** when identifying contexts or
components, mapping relationships between contexts, deciding what to build versus
buy, or measuring whether existing components are coupled sensibly.

## Step 3 — Choose a Style

Only now. The style follows from the characteristics and the boundaries; it is
never the starting point, and choosing one because it's current is
resume-driven architecture.

The first fork is the only one that really matters:

**Does one set of architecture characteristics suffice for the whole system?**

- **Yes → monolithic.** Then: changes mostly technical → **layered**. Changes
  mostly domain-shaped, or you're doing DDD → **modular monolith**. Distinct,
  ordered, deterministic one-way processing → **pipeline**. The domain requires
  per-client or per-jurisdiction customisation → **microkernel**.
- **No → distributed.** Then: you want distributed benefits cheaply, need ACID
  transactions, or aren't sure how far to decompose → **service-based** (also the
  stepping stone, and the right default when someone says "microservices"). The
  system reacts to things that have happened and needs responsiveness plus
  evolvability → **event-driven**. More than ~10,000 concurrent users or
  unpredictable spikes with the database as the ceiling → **space-based**. You
  need genuinely different operational characteristics per service → **microservices**.

Two rules constrain what you just picked. **The architecture quantum is the
smallest independently deployable piece with high functional cohesion and its own
data** — and **the database is inside the quantum**. Six services sharing one
database are one quantum, which means one deployment risk, one scaling ceiling,
and one failure domain. You have a distributed monolith and none of the benefits.
Second, **communicate synchronously by default and asynchronously only when
necessary**; async buys responsiveness and pays for it with error handling,
ordering, and debuggability.

**Decoupling has levels, and you should pick the cheapest that works**: source
level, then deployment level, then service level. Push this decision as late as
possible and be willing to move *back down*. Services are not inherently
decoupled — they are an expensive boundary, not a free one. Default to a
monolith with clean source-level boundaries and promote only under measured
pressure.

**Read `references/styles.md`** when comparing styles, sizing a quantum,
designing distributed communication, or checking a style's known failure modes.
For the full chapter-length treatment of any one style, use the
`fundamentals-of-software-architecture-book` skill.

## Step 4 — Decouple the Core from the Infrastructure

Inside whichever style you chose, the same question keeps recurring: is this code
core, or is it infrastructure? Noback's two rules answer it, and **both must
pass** or it's infrastructure:

1. **No dependency on an external system** — nor on code written for talking to a
   specific type of external system.
2. **No special context required** — nor a dependency designed for one context
   only.

"Can I mock it?", "is it in `vendor/`?", and "does it have an interface?" are all
invalid tests. The cheapest real test is the **CLI thought experiment**: if the
business ran from the command line, would the application still need this? No →
it was justifiably infrastructure. Yes → decouple it.

Then the Dependency Rule places it: **source code dependencies point only
inward**, toward higher-level policy. Interfaces go inward, implementations go
outward. If a change to a detail forces a change to a business rule, the rule is
violated and nothing else overrides that.

| Class | Layer |
|---|---|
| Entity, value object, domain event, domain service, write-model repository **interface** | **Domain** |
| Application service, command object, event subscriber, read model, read-model repository **interface** | **Application** |
| Controller, CLI command, any repository **implementation**, the container, clock and random services | **Infrastructure** |

Dependencies run Infrastructure → Application → Domain and never outward. Enforce
it in the build (Step 5), not in a document.

**Extract abstractions in two steps, and the second is the one people skip.**
Introducing an interface is step one; making it communicate *purpose* rather than
mechanism is step two. `Connection.insert(table, data)` becomes
`Repository.save(member)`. An interface extracted from a vendor façade keeps the
vendor's vocabulary and buys indirection with no decoupling. The test is: *would
this interface still be useful if the implementation changed radically?* — not
"can I create a test double for it?", which is true of every interface including
bad ones. For an external service, use **two layers**: a façade whose methods
mirror the vendor's endpoints, and above it an interface phrased in your domain's
words. That upper interface is an **anticorruption layer**, and it pays for
itself the first time the upstream changes.

Every concrete dependency gets pushed down into a single **composition root** —
`Main`, the ultimate detail. Fetching from the container there is fine; fetching
from it anywhere else is service location.

**Good architecture maximises the number of decisions *not* made.** Defer the
database, the web framework, the UI technology, the service topology, and the DI
framework. If you can build and test the whole system without choosing, you have
not yet needed to choose. Deferring out of *fear* rather than judgment is the
Covering Your Assets antipattern; the rule is the **last responsible moment** —
decide when the cost of deferring exceeds the risk of deciding.

**Read `references/core-and-infrastructure.md`** when placing a class, designing a
port, wrapping an external service, introducing read models, or deciding where a
validation rule lives.

## Coupling, Cohesion, and Connascence

**Two things are coupled if changing one might break the other.** That is the
whole definition, and it means coupling is never zero — the goal is to put it
where you can afford it.

**Higher coupling is acceptable at narrower scope.** Two classes in one module
may be tightly coupled with little consequence; two services coupled the same way
is a distributed monolith. Judge coupling against the distance it spans.

Connascence gives the vocabulary, weakest to strongest. **Static** (visible in the
source): name → type → meaning → position → algorithm. **Dynamic** (only visible
at runtime): execution → timing → values → identity. Three rules follow: prefer
static over dynamic; prefer weaker forms over stronger; and **increase locality**,
because strong connascence inside one class is fine while the same connascence
across a network boundary is a defect waiting for a deploy. This is why sagas are
expensive — they create connascence of values, the second-strongest dynamic form,
across service boundaries.

**Reuse is coupling.** A team asking for both maximum decoupling and maximum
reuse is asking for incompatible things, and someone has to say so. Reuse
requires abstraction *and* low volatility: reuse plumbing, and **never reuse the
domain**. The shared library that everyone depends on and everyone edits is the
Zone of Pain in physical form.

Component-level health has actual numbers. **Instability** `I = Ce / (Ca + Ce)`
measures volatility; **abstractness** `A = Na / Nc`; **distance from the main
sequence** `D = |A + I − 1|`. Depend in the direction of stability — `I` must
decrease along each dependency — and a stable component should be abstract,
because stable and concrete is rigid. High `D`, or high variance in `D`, is where
to look first. Cycles in the component graph get broken with dependency inversion
or by extracting a new component both sides depend on.

Beware the two dead zones. The **Zone of Pain** (concrete, heavily depended on) is
only harmful when the component is *volatile* — a stable database schema lives
there quite happily. The **Zone of Uselessness** (abstract, nothing depends on it)
is dead abstraction, and it should be deleted.

## Consistency and Transaction Boundaries

The transaction boundary is an architecture decision, and in a domain model it
has a name: **the aggregate is the consistency boundary**. Model true invariants
inside it, design it small, reference other aggregates **by identity rather than
by object reference**, and use eventual consistency outside it. Roughly 70% of
aggregates should be a single root plus values.

**Modify exactly one aggregate per transaction.** When you can't, you have a
wrong boundary or a missing concept — not a reason to widen the transaction. Only
four things sanction breaking this: UI convenience when batch-creating aggregates
with no shared invariant, a genuine lack of async mechanisms, an externally
mandated global transaction, and *measured* query performance.

**Ask whose job it is** to decide transactional versus eventual. If it is *this*
user's job to make the data consistent, try transactional. If it's another user's
job or the system's, use eventual — publish a domain event and negotiate the
acceptable delay with domain experts, who reliably tolerate far more than
developers expect. If the honest answer is "it depends on the team", that
ambiguity is itself a discovery and probably belongs in the model as a
configurable workflow preference. Never decide this by house style.

**Verify the invariant is real before designing around it.** Say it aloud in the
ubiquitous language; if the experts don't recognise it as a rule, it's a false
invariant — usually developer-authored, usually phrased as "we must not allow X
to be removed". The symptom is unrelated operations colliding on the same
aggregate's optimistic-concurrency version.

Across services, "we need a distributed transaction" means **the granularity is
too fine**. Fix the granularity first. If service boundaries genuinely can't move
and coordination is genuinely required, a **saga** with compensating transactions
is the tool — but if transactions are a *dominant* feature of the system,
microservices was the wrong style.

**Orchestration when you need state, error handling, recoverability, or restart.
Choreography when you need responsiveness, scalability, decoupling, or
parallelism.** Orchestration costs a throughput bottleneck, a single point of
failure, fewer parallelism opportunities, and tighter coupling. Event payloads are
decided **per event, not per system**: data-based payloads win on performance and
scalability, key-based payloads win on contract management, bandwidth, and
fragility. For updates, include prior values or you get anemic events.

**Read `references/core-and-infrastructure.md`** for aggregate, repository, and
domain-event mechanics, and `references/styles.md` for the distributed
communication trade-offs.

## Step 5 — Govern It, or It Decays

An architecture that isn't enforced is a diagram. **Only the compiler and the
build enforce architecture.** Access modifiers, module boundaries, and automated
checks are the mechanism; a document that says "the domain layer must not import
the framework" prevents nothing.

**Fitness functions** are any objective integrity assessment of a characteristic —
metrics, monitors, unit tests, chaos engineering. Wire them into the continuous
build (ArchUnit, NetArchTest, PyTestArch, TSArch, deptrac, JDepend) or into
production. Govern the important-but-not-urgent with them: layer rules, cycles,
complexity, coupling caps, module boundaries. **Explain every fitness function
before imposing it** — an ivory-tower rule breeds workarounds, not compliance.

**Write an ADR for every architecture decision, however obvious**, and
retroactively for the ones already made. Structure: numbered title, status
(proposed / accepted / superseded, or RFC with a deadline), context including the
alternatives, decision in affirmative commanding voice **with its full
justification**, consequences including the trade-off analysis, and compliance.
The justification is the part that matters — a decision re-debated forever is one
whose *why* was never recorded.

**Do the trade-off analysis properly.** Enumerate factors *contextualised to this
organisation and this solution*, build a plus/minus matrix per option, and then
**weight the factors against actual organisational goals**. Skipping that last
step is the Out of Context antipattern: the raw count of plusses is not the
answer. Redo the analysis each time — small differences in context flip outcomes.

**Assess risk with impact × likelihood, each scored 1–3.** Consider impact first
and default unknown likelihood to 3. **Rate any unknown technology 9** — the risk
matrix doesn't apply to ignorance. Run **risk storming** after major features:
individual identification, then consensus on a posted diagram, then mitigation
with business stakeholders present, one criterion per session. Bring a cheaper
alternative to that last conversation, because mitigation costs money.

Two closing rules for defending decisions: **give the justification before the
demand**, since people stop listening the moment they disagree; and
**demonstration defeats discussion**.

**Read `references/characteristics-and-governance.md`** when writing an ADR,
designing fitness functions, running a risk assessment, or preparing to defend a
decision.

## What This Implies for Tests

The architecture determines which test is even possible, so the two decisions are
the same decision. Noback's mapping:

| What you're proving | Test |
|---|---|
| An entity protects an invariant, or records an event | Unit test |
| A value object's behavior | Unit test |
| A use case's effect ("paying produces an invoice") | Use case test, with in-memory adapters |
| `save()` then `getById()` round-trips | Contract test, real database, no doubles |
| `POST /x` calls the right application method | Driving test |
| The real API or mailer actually works | Adapter test |
| Everything is wired together in production | End-to-end — only a few |

**A test is not a unit test if it invokes infrastructure code.** Controllers,
application services, event subscribers, and repository implementations are
therefore never unit-tested. If you find you *can't* write a fast test for a piece
of business logic, that is architectural feedback: the logic is on the wrong side
of a boundary. Use `test-guideline` for test structure, naming, and mocking
mechanics.

## Anti-Patterns

Read `references/ANTI_PATTERNS.md` for the full catalogue, and consult it when
reviewing an existing system or when something feels wrong and you can't name it.
The ones worth carrying in your head:

- **Distributed monolith** — services that must deploy together, or share a
  database. One quantum, all of the cost, none of the benefit.
- **Architecture sinkhole** — requests passing through layers that do nothing.
  Concerning above ~20%; at 80% you chose the wrong style.
- **Entity trap** — components derived from entities, named `*Manager` or
  `*Processor`.
- **Grains of sand** — microservices so fine-grained that every use case needs a
  distributed transaction.
- **Generic architecture** — designing to support every characteristic at once.
- **Framework or ORM types inside the domain** — the Dependency Rule violated at
  the worst possible layer.
- **Package structure that screams the framework** (`controllers/`, `models/`,
  `views/`) rather than the use cases.
- **The accidental shared kernel** — replicating an upstream database "for
  autonomy", which produces the opposite.
- **Publishing model-shaped resources** instead of use-case-shaped ones, which
  makes every consumer a conformist by accident.
- **DDD-Lite** — tactical patterns with no strategic design behind them.
- **Groundhog Day** — the same decision debated forever because you gave the
  *what* and never the *why*.
- **Frozen Caveman** — an architect reflexively re-fighting one past incident on
  every new system.

## Review Checklist

- [ ] Is this actually an architecture decision — significant trade-offs, or hard
      to reverse?
- [ ] Are there at most three named architecture characteristics, and is each one
      measurable?
- [ ] Was the style chosen *from* those characteristics, or picked first?
- [ ] Does each boundary sit on a real axis of change — a different rate, a
      different actor, or a different domain?
- [ ] Could a partial boundary do the job instead of a full one?
- [ ] What is the architecture quantum, and is the database inside it?
- [ ] Do all source dependencies point inward, with interfaces inward and
      implementations outward?
- [ ] Does any domain code import a framework, ORM, HTTP, or clock?
- [ ] Do the abstractions name the question rather than the mechanism?
- [ ] Is the coupling affordable at the distance it spans?
- [ ] Is anything reusing the *domain* rather than the plumbing?
- [ ] Does each transaction modify exactly one aggregate?
- [ ] Has each invariant been said aloud to a domain expert?
- [ ] Is communication synchronous unless async was specifically justified?
- [ ] Is every architecture rule enforced by the build rather than by a document?
- [ ] Does each ADR record the *why*, the alternatives, and the consequences?
- [ ] Were unknown technologies rated as maximum risk?
- [ ] Can the core's business logic be tested without infrastructure?
- [ ] Which decisions did this design let you *avoid* making?
