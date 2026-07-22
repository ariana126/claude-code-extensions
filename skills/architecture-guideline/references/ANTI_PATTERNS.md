# Architecture Anti-Patterns — Full Reference

This file expands on the anti-patterns summarised in SKILL.md. Read it when
reviewing an existing system, when a design feels wrong but you can't name why, or
when someone proposes something that pattern-matches to a known failure.

Each entry follows the same shape: what you'd see, why it hurts, and what to do
instead.

An antipattern, in Koenig's definition, is *something that seems like a good idea
when you begin but leads you into trouble*. Everything below looked reasonable to
someone competent at the time.

---

# Part I — Structural

## 1. The Distributed Monolith

**Symptom**: services that must be deployed together, that share a database, or
that cannot answer a request without a synchronous call to a sibling. Releases are
coordinated. A schema change forces every service to redeploy.

**Why it's bad**: the database is inside the architecture quantum, so services
sharing one are **one quantum** regardless of how many repositories and pipelines
exist. You are paying microservices' costs — network latency, distributed
debugging, operational overhead, ★ on simplicity and cost — while receiving the
monolith's constraints. It is strictly the worst of both.

**Fix**: either give each service its own data and remove the synchronous
required-path calls, or merge back to **service-based architecture** and stop
pretending. Merging back is a legitimate, under-used move.

## 2. Grains of Sand

**Symptom**: microservices so fine-grained that ordinary use cases span four or
five of them, and "we need a distributed transaction" is a recurring sentence.

**Why it's bad**: granularity too fine creates connascence of values — the
second-strongest dynamic connascence — across network boundaries. Every workflow
becomes a saga, every saga needs compensating transactions, and compensation is
where correctness quietly goes to die.

**Fix**: **fix the granularity before reaching for a saga.** Merge services along
the transaction boundary. If transactions are a *dominant* feature of the system,
microservices was the wrong style.

## 3. Architecture Sinkhole

**Symptom**: requests passing through layers that perform no business logic —
controller calls service calls repository, each one a pass-through.

**Why it's bad**: every layer costs latency and a file to edit while contributing
nothing. Up to ~20% of requests behaving this way is normal and acceptable. **At
80%, you chose the wrong style.**

**Fix**: measure the actual proportion first. If it's genuinely high, either move
to a different style, or open specific layers — and document which layers are open
and closed **and why**. Opening all of them fixes throughput and destroys change
management, which is the Fast-Lane Reader trap.

## 4. The Entity Trap

**Symptom**: one component per database table, with names ending in `Manager`,
`Supervisor`, `Controller`, `Handler`, `Engine`, or `Processor`.

**Why it's bad**: these names describe machinery rather than business capability,
so the components have no natural cohesion and no clear owner. Evans reaches the
same diagnosis from the domain side: an object named `…Manager` or `…Doer` with no
state and no domain meaning is a service in disguise, and usually a sign that
behavior was pulled out of the model.

**Fix**: derive components from workflow steps or from actors and actions, never
from entities. Then apply the **conjunction test** — write the role statement as
prose and count the *ands*, *alsos*, and commas.

## 5. Unstructured Monolith

**Symptom**: a monolith whose code is so interdependent it cannot be unraveled.
Every attempt to extract a module reveals four more dependencies.

**Why it's bad**: it forecloses every option. You can't extract a service, can't
test in isolation, and can't reason about the blast radius of a change. A rewrite
becomes the only exit, and rewrites mostly fail.

**Fix**: prevention is the whole story — a **modular monolith** with enforced
module boundaries: namespace compliance checks, a numeric cap on coupling points
per module, and forbidden-dependency rules in CI. If you're already here, use the
Strangler pattern and pick boundaries by actual change frequency.

## 6. Accidental SOA

**Symptom**: an ESB introduced for integration gradually encapsulates the entire
architecture. Business logic ends up in the orchestration engine.

**Why it's bad**: orchestration-driven SOA has the worst ratings across almost
every column, and nothing arrived at it deliberately — it accumulated.

**Fix**: an ESB is legitimate as an **integration architecture only**, connecting
a legacy and modern estate. Draw an explicit line about what may live in it, and
enforce it with a fitness function.

## 7. The Generic "Shared" Library

**Symptom**: a `common` or `shared` package that every component depends on and
every team edits. In service-based architectures, a single all-entities library.

**Why it's bad**: it sits in the **Zone of Pain** — concrete and heavily depended
upon — and it is *volatile*, which is what makes that zone painful. Every change
forces every consumer to redeploy, so the "shared" library becomes the thing that
prevents independent deployment.

**Fix**: partition it by domain and mirror the data partitioning. Lock genuinely
common entity objects in version control so only one team may change them. Reuse
plumbing; **never reuse the domain**.

## 8. Package Structure That Screams the Framework

**Symptom**: top-level directories named `controllers/`, `models/`, `views/`,
`services/`.

**Why it's bad**: the structure tells you which framework was used and nothing
about what the system does. Someone opening the repository learns the delivery
mechanism instead of the business.

**Fix**: organise by domain — the architecture should scream its use cases. Package
by component rather than by layer.

---

# Part II — Coupling and Dependencies

## 9. Framework or ORM Types Inside the Domain

**Symptom**: entities carrying ORM annotations, domain services taking a `Request`,
value objects extending a framework base class, `new Date()` inside a business
rule.

**Why it's bad**: the Dependency Rule is violated at the worst possible layer. A
framework upgrade now forces changes to business rules, the domain can't be tested
without booting the framework, and the framework's lifecycle becomes the business's
lifecycle.

**Fix**: apply Noback's two rules to classify the code, then invert the dependency
with the two-step recipe — interface first, *purpose-named* second. Move mapping
outside the entity. Replace `new Date()` with an injected clock or a method
argument.

## 10. Skipping Step Two of the Abstraction Recipe

**Symptom**: an interface extracted directly from a vendor façade. Method names
mirror the vendor's endpoints; return types are vendor-shaped
(`VatRateCheckResult`); a parameter exists that only one vendor understands.

**Why it's bad**: you bought indirection with no decoupling. The vendor's
vocabulary survives into your domain, so swapping vendors still means rewriting
everything that touches the interface.

**Fix**: two layers. A façade mirroring the vendor's API, then an interface phrased
in **your domain's words** above it. Test the result with *"would this interface
still be useful if the implementation changed radically?"* — never *"can I mock
it?"*.

## 11. Jumpy Code — Abstractions All the Way Down

**Symptom**: service → abstraction → class → abstraction → class, where each hop
adds nothing but a name.

**Why it's bad**: each abstraction costs two to three elements, and pass-throughs
pay that cost for zero decoupling. Reading the code becomes navigation rather than
comprehension.

**Fix**: delete the pass-throughs. **Let infrastructure call infrastructure
directly** — Noback kept `Clock` and deleted `UuidFactory` and `Calendar` for
exactly this reason. Abstract what core code must be independent of, and nothing
more.

## 12. Wanting Decoupling and High Reuse Simultaneously

**Symptom**: a team that wants independently deployable services *and* a shared
library for all common logic.

**Why it's bad**: **reuse is coupling.** These are not two goals in tension to be
balanced — they are fundamentally incompatible, and pursuing both produces a shared
library that blocks the independent deployment you wanted.

**Fix**: say so explicitly, early. Reuse requires abstraction *and* low volatility:
reuse plumbing (logging, auth, monitoring — ideally in a sidecar), never the
domain. Some duplication across services is the price of the architecture you
chose.

## 13. Service Locators and Hidden Wiring Across Boundaries

**Symptom**: a container, registry, or static accessor reached from inside a
service to fetch collaborators.

**Why it's bad**: the real dependency count becomes invisible, so no design
pressure ever builds. At architecture scale this means dependency-rule violations
that no static analysis can see — the import looks innocuous.

**Fix**: constructor injection everywhere, with a single **composition root**.
Reaching into the container from a controller is fine; from the service it calls,
it isn't. See `oop-guideline` for the class-level treatment.

---

# Part III — Domain and Boundaries

## 14. DDD-Lite

**Symptom**: entities, value objects, repositories, and aggregates in a codebase
with no bounded contexts, no context map, and no ubiquitous language sessions with
actual experts.

**Why it's bad**: the tactical patterns without strategic design produce ceremony
without benefit. The model doesn't match anyone's mental model, so it drifts, and
the extra structure just makes drift more expensive.

**Fix**: either invest in the strategic side — subdomains, contexts, language, a
core-domain vision statement — or stop paying for the tactical patterns. Vernon's
scorecard threshold is 7; below that, DDD may simply be the wrong investment.

## 15. False Invariants

**Symptom**: an aggregate designed around a rule like "we must not allow X to be
removed", which no domain expert recognises when you say it aloud.

**Why it's bad**: developer-authored invariants inflate aggregate boundaries, which
forces multi-aggregate transactions and produces contention. The symptom is
unrelated operations colliding on the same root's optimistic-concurrency version.

**Fix**: say every invariant aloud in the ubiquitous language and have an expert
confirm it. Delete the ones they don't recognise, then re-size the aggregate.

## 16. Misclassifying a Generic Subdomain as Core

**Symptom**: your best developers building an in-house identity, billing, or
notification system while the actual differentiating domain tangles.

**Why it's bad**: this is the most expensive mistake available in strategic design,
and it is invisible while it's happening because the work is going well. Elegant
peripheral features shipping on time while the core rots is the classic
project-killing staffing pattern.

**Fix**: classify every subdomain explicitly — core (build, best people), supporting
(build or contract), generic (**buy or outsource**). Revisit the classification when
the business changes.

## 17. The Accidental Shared Kernel

**Symptom**: replicating an upstream team's database "so we're autonomous", or
exposing navigable model-shaped resources over an API.

**Why it's bad**: you now depend on their schema, which is their most volatile
artifact and one they never agreed to keep stable. Exposing model resources makes
every consumer a Conformist by accident — they couple to your internal model, and
you can no longer refactor it.

**Fix**: publish **use-case-shaped** resources, not model-shaped ones. Consume
through an anticorruption layer. Name the relationship on a context map and get
both teams to agree to it explicitly — a shared kernel you *chose* is fine; one you
*drifted into* is not.

## 18. Assuming Customer-Supplier Where the Reality Is Conformist

**Symptom**: designing around promised upstream changes that never arrive.

**Why it's bad**: it kills projects *late*, when the schedule has no slack.
Altruism may motivate upstream developers to make promises, but they are unlikely
to fulfil them without a real incentive.

**Fix**: test the relationship before designing around it. When the upstream won't
genuinely serve you, there are exactly three options: **Separate Ways, Conformist,
or Anticorruption Layer.** There is no fourth.

## 19. Handing a Write Model to a Read-Only Client

**Symptom**: a controller, template, or serialiser receiving an entity; a report
endpoint calling `findAll()` and looping.

**Why it's bad**: the client can call anything on that entity, so the day one of
them modifies it, tracing what happened is hard. It is usually also a performance
problem hiding inside a design problem — loading every entity ever created to
answer one question.

**Fix**: a read model shaped for that use case, with its own repository, built
directly from the data source in one query. Success signals: the write model's
getters can be deleted, and the client stops reshaping what it received. See
`oop-guideline` for the class-level mechanics.

---

# Part IV — Distributed Systems

## 20. Async Everywhere by Default

**Symptom**: message queues between components that could simply call each other,
adopted because async "scales better".

**Why it's bad**: async buys responsiveness and pays with error handling, ordering
guarantees, debuggability, and testability. Event-driven architecture rates ★★ on
simplicity and testability for real reasons.

**Fix**: **synchronous by default, asynchronous only when necessary**, decided per
interaction and recorded with its reason. And note the trap in the other direction:
two quanta communicating synchronously on a required path have collapsed into one
quantum — dynamic quantum entanglement.

## 21. The Swarm of Gnats and the Poison Event

**Symptom**: too many fine-grained derived events; or a derived event that loops
forever between two services.

**Why it's bad**: event volume becomes its own scaling problem, and the workflow
exists nowhere in particular, so nobody can answer "what happens when a customer
orders?" without reading six codebases.

**Fix**: coarsen the events to meaningful business facts. For loops, break the
cycle explicitly and add a workflow processor that delegates errors, repairs, and
resubmits — while queueing subsequent messages for the same context in FIFO, since
repaired messages process out of order.

## 22. Anemic Events and Stamp Coupling

**Symptom**: an update event carrying only new values with no prior state
(*anemic*); or an event carrying far more data than any consumer needs (*stamp
coupling*).

**Why it's bad**: anemic events force consumers to guess or to query back, which
re-couples them. Stamp coupling turns every payload change into a coordinated
release across every consumer.

**Fix**: decide payload style **per event, not per system** — data-based for scale,
key-based for contract management and low fragility. For updates, include prior
values. Enrich for the common consumer, not for all of them.

## 23. The API Gateway as an Orchestrator

**Symptom**: routing logic in the gateway growing into workflow logic; or a
nominally choreographed service becoming a complex mediator (the **Front
Controller** antipattern).

**Why it's bad**: it recreates the ESB inside microservices — a single throughput
bottleneck, a single point of failure, and business logic in the one component no
team owns.

**Fix**: the gateway routes and handles cross-cutting concerns. **Never a mediator
or orchestrator.** If you need orchestration, make it an explicit service with an
owner.

## 24. Adopting Space-Based (or Event Sourcing, or CQRS) Speculatively

**Symptom**: in-memory data grids, event stores, or read-model projections adopted
before the problem they solve has been measured.

**Why it's bad**: space-based rates ★ on cost, simplicity, and testability, and its
threshold is **>10,000 concurrent users** with the database as the proven ceiling.
CQRS should follow the genuine failure of repository finders and DTOs; event
sourcing only pays off on complex, competitive-advantage models and drags CQRS in
behind it.

**Fix**: measure first. A read replica, a cache, or a use-case-shaped read model
solves most of what these get adopted for. Adopting the expensive option early
means the interface will be shaped by a guess.

---

# Part V — Process and People

## 25. Resume-Driven Architecture

**Symptom**: a style chosen before any characteristic was named, and defended with
adoption statistics rather than trade-offs.

**Why it's bad**: characteristics drive style. Reversing the order means the
system's structure is optimised for something other than the system's needs.

**Fix**: refuse to discuss styles until the top three characteristics exist. If
someone can't name the characteristic that disqualifies a modular monolith, it
isn't disqualified.

## 26. Generic Architecture

**Symptom**: designing to support *all* the characteristics. Every stakeholder's
priority made it onto the list.

**Why it's bad**: the characteristics conflict — performance against elasticity,
simplicity against evolvability — so supporting all of them means being mediocre at
each. "All of them" as an answer means you asked stakeholders to rank instead of
pick three.

**Fix**: the worksheet plus the elimination test. **Never strive for the best
architecture; aim for the least worst.**

## 27. Architecture by Implication

**Symptom**: a team coding without knowing which style they're in. Ask three
developers what the architecture is and get three answers.

**Why it's bad**: with no named style there are no rules to violate, so structural
decay is undetectable until it's irreversible.

**Fix**: name the style, write the ADR, and add fitness functions. Even naming an
existing accidental structure is progress — you can't govern an unnamed thing.

## 28. Groundhog Day

**Symptom**: the same decision debated every few months, with the same arguments.

**Why it's bad**: you recorded the *what* and never the *why*. Without the
justification, each new person legitimately re-opens it, and you have no defence
except authority.

**Fix**: ADRs with full justification, alternatives considered, and consequences.
**Give the justification before the demand** — people stop listening the moment
they disagree.

## 29. Covering Your Assets

**Symptom**: an architect who avoids or defers every decision to avoid being wrong.

**Why it's bad**: deferring is only virtuous when it is *judgment* rather than
*fear*. Undecided things still get decided — by whoever writes the code first, with
no analysis at all.

**Fix**: the **last responsible moment** — decide when the cost of deferring exceeds
the risk of deciding. And note the genuine version of this principle: good
architecture maximises the number of decisions *not yet made*, which is deliberate
deferral, not avoidance.

## 30. Frozen Caveman and the Bottleneck Trap

**Symptom**: an architect who raises the same pet concern on every system,
regardless of context (**Frozen Caveman**); or one who owns critical-path code and
blocks the team (**Bottleneck Trap**).

**Why it's bad**: the first spends the architecture's risk budget on an incident
from a decade ago. The second makes the architect the constraint, which is the one
role that must not be.

**Fix**: for the first, run risk storming — individual identification first, so one
voice can't anchor the room — and rate risks with impact × likelihood rather than
memory. For the second, delegate critical-path implementation and keep enough
hands-on work to stay credible without being load-bearing.

## 31. Irrational Artifact Attachment

**Symptom**: a diagram nobody wants to change, because of how long it took to make.

**Why it's bad**: attachment to an artifact grows with the time spent producing it,
so the most elaborate diagram becomes the least revisable — usually the one most in
need of revision.

**Fix**: cheap artifacts, revised often. And remember that **only the compiler and
the build enforce architecture** — a diagram documents intent, it never constrains
anything.

## 32. Ivory Tower Fitness Functions

**Symptom**: architecture rules imposed in CI without explanation. Developers find
workarounds — a wrapper class, a suppression annotation, a carve-out.

**Why it's bad**: an unexplained rule produces compliance theatre rather than the
characteristic you wanted, and you now have false confidence on top of the original
problem.

**Fix**: **explain every fitness function before imposing it.** Some require new
stories to become checkable at all; budget for that rather than skipping the
explanation. Rules the team believes in survive; rules they don't get routed
around.
