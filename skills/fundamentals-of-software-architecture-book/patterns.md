# Patterns & Techniques — Fundamentals of Software Architecture (2nd Ed.)

## Architecture Characteristics Worksheet
**When to use**: eliciting driving characteristics from stakeholders (Ch 5).
**How**: architect-facilitated session. Seven slots for candidate characteristics; a second column of implicit ones you can "pull" in; displaced items go to "Others Considered." Final step: stakeholders collaboratively pick the **top three, in any order**.
**Trade-offs**: full ranking is a fool's errand — stakeholders never agree on every priority. Unordered top-three achieves consensus and drives the real discussion. Download: `developertoarchitect.com/resources.html`

## The Elimination Test
**When to use**: after a first-pass characteristics list (Ch 5).
**How**: ask "if I had to eliminate one, which?" Cull **explicit** characteristics first; implicit ones tend to support general success.
**Trade-offs**: tests critical necessity rather than desirability.

## Architecture Katas
**When to use**: building architect skill without waiting for real projects (Ch 5, Ch 27).
**How**: timeboxed team exercise with four sections — Description, Users, Requirements, Additional context. Teams produce characteristics analysis + diagrams, then share and vote; an experienced architect critiques the trade-off analysis.
**Trade-offs**: no answer key exists — only trade-offs. Site: `fundamentalsofsoftwarearchitecture.com`

## Fitness Functions
**When to use**: governing the *important but not urgent* — modularity, layer rules, cycles, complexity (Ch 6).
**How**: any objective integrity assessment — metrics, monitors, unit tests, chaos engineering. Wire into the continuous build (JDepend, ArchUnit, NetArchTest, ArchUnitNet, PyTestArch, TSArch) or into production (Netflix's Conformity/Security/Janitor Monkeys).
**Trade-offs**: explain every function before imposing it; ivory-tower fitness functions breed workarounds. Some require new stories (e.g. adding a `@SharedService` annotation).

## Component Identification & Refactoring Cycle
**When to use**: greenfield systems and every feature change (Ch 8).
**How**: identify core components → assign user stories → analyze roles and responsibilities → analyze architecture characteristics → refactor → repeat forever.
**Trade-offs**: never terminates by design; resist perfecting the first pass.

## Workflow Approach / Actor–Action Approach
**When to use**: producing initial components before requirements exist (Ch 8).
**How**: *Workflow* — one component per major happy-path step. *Actor/Action* — major actions per actor, where **the system is always an actor**.
**Trade-offs**: Actor/Action generates more components and suits multi-actor systems; Workflow is leaner. Neither maps 1:1 — several steps can share a component.

## The Conjunction Test
**When to use**: checking whether a component does too much (Ch 8).
**How**: write the role-and-responsibility statement as prose. Count *and*, *also*, *in addition*, *as well as*, and commas.
**Trade-offs**: cheap, subjective, and remarkably reliable.

## Law of Demeter (Principle of Least Knowledge)
**When to use**: reducing component coupling (Ch 8).
**How**: find *knowledge* a component holds that isn't its *responsibility*, and defer it downstream.
**Trade-offs**: **redistributes** coupling rather than eliminating it — the receiving component becomes more coupled.

## Layers of Isolation (Open/Closed Layers)
**When to use**: layered architecture (Ch 10).
**How**: close layers on the main request flow. Insert a new **open** layer to enforce an access restriction structurally.
**Trade-offs**: closed layers cause Architecture Sinkholes; opening all layers fixes throughput but makes change management much harder. Document which layers are open/closed **and why**.

## Modular Monolith Governance
**When to use**: preventing module-boundary decay (Ch 11).
**How**: (1) namespace-prefix compliance checks; (2) a numeric cap on afferent+efferent coupling points per module (e.g. 5); (3) explicit forbidden-dependency rules via ArchUnit.
**Trade-offs**: works cleanly with the monolithic structure; the modular structure requires per-module validation.

## Mediator (module communication)
**When to use**: decoupling modules in a modular monolith (Ch 11).
**How**: a mediator component orchestrates requests to modules; only the mediator needs the API.
**Trade-offs**: every module is now coupled *to the mediator*. Simplifies rather than eliminates coupling.

## Filter Type Tagging
**When to use**: governing pipeline architecture (Ch 12).
**How**: Java annotations / C# custom attributes marking each filter's entry point and type (PRODUCER, TESTER, TRANSFORMER, CONSUMER).
**Trade-offs**: won't stop a determined developer; supplies context at the point of temptation, which fitness functions can't easily do here.

## Microkernel Registry & Contracts
**When to use**: plug-in architecture (Ch 13).
**How**: registry maps a key to a plug-in reference (point-to-point, queue, or REST URL). Standard contract per plug-in domain; **adapt** third-party contracts rather than special-casing the core.
**Trade-offs**: runtime plug-ins need OSGi/Jigsaw/Prism; compile-based are simpler but require full redeployment.

## Partitioned Shared Libraries (service-based data)
**When to use**: controlling database change across domain services (Ch 14).
**How**: logically partition the database and mirror it with per-domain entity-object libraries. Lock `common` entity objects in version control; only the database team may change them.
**Trade-offs**: a single all-entities library is an antipattern — every schema change forces redeployment of every service.

## Workflow Event Pattern
**When to use**: asynchronous error handling (Ch 15).
**How**: consumer delegates the error immediately and moves to the next message; a workflow processor repairs the data programmatically and resubmits, or routes to a human dashboard.
**Trade-offs**: repaired messages process **out of order**. Mitigate by queuing subsequent messages for the same context (e.g. brokerage account) in FIFO until the error clears.

## Preventing Data Loss (EDA)
**When to use**: any asynchronous architecture (Ch 15, Ch 16).
**How**: persisted queues + synchronous send (producer→broker), client acknowledge mode (broker→consumer), ACID commit + last participant support (consumer→database).
**Trade-offs**: each mechanism slows responsiveness and can degrade consistency.

## Request-Reply Messaging
**When to use**: when an event processor needs an immediate response (Ch 15).
**How**: **correlation ID** (recommended) — reply message's CID equals the request's message ID, consumed via a message selector. Or **temporary queue** — simpler, no selector needed.
**Trade-offs**: temporary queues make the broker create and delete a queue per request, significantly hurting performance at volume. Request-reply merges the two processors into one quantum.

## Mediator Delegation Model
**When to use**: mediated EDA with mixed event complexity (Ch 15).
**How**: classify events simple/hard/complex; route everything through a simple mediator (Camel, Mule) that handles it or forwards to BPEL (Apache ODE, Oracle BPEL) or BPM (jBPM).
**Trade-offs**: Camel for complex long-running human-interaction events is unmaintainable; a BPM engine for simple flows wastes months.

## Replicated vs. Distributed Caching
**When to use**: space-based architecture (Ch 16).
**How**: replicated for small (<100 MB), relatively static, low-update, fault-tolerance-critical data; distributed for large (>500 MB), highly dynamic, high-update, consistency-critical data. **Mix both across processing units.**
**Trade-offs**: near-cache is explicitly **not recommended** — unsynchronized front caches produce inconsistent data and responsiveness.

## Data Abstraction Layer (readers/writers)
**When to use**: space-based architecture (Ch 16).
**How**: readers and writers carry transformation logic so cache schemas can differ from database schemas and schema changes can be buffered.
**Trade-offs**: versus a data *access* layer, which couples processing units to database structures.

## Sidecar & Service Mesh
**When to use**: operational reuse in microservices (Ch 18, Ch 20).
**How**: cross-cutting operational concerns in a per-service sidecar; sidecars connected by a service plane (Istio) into a mesh with a global control console.
**Trade-offs**: must implement a sidecar per platform; the sidecar may grow large/complex; independent teams cause implementation drift.

## Saga & Compensating Transactions
**When to use**: only when distinct service boundaries are unavoidable **and** transactional coordination is required (Ch 18).
**How**: a mediator calls each participant, records success/failure, and issues reversals on failure. Requests typically sit in a **pending** state until overall success.
**Trade-offs**: creates Connascence of Values, the worst dynamic connascence, and heavy network coordination traffic. **If transactions are a dominant feature, microservices is the wrong style — fix granularity instead.** Eight Saga variants appear in *Software Architecture: The Hard Parts*, Ch 12.

## CQRS
**When to use**: sharply divergent read/write volumes, or reads needing isolation for security (Ch 20).
**How**: writes to one datastore (database or durable queue), synchronized — usually asynchronously — to a separate read datastore.
**Trade-offs**: enables different characteristics and data models per side, at the cost of eventual consistency between them.

## Single-Broker vs. Domain-Broker
**When to use**: EDA infrastructure design (Ch 20).
**How**: one broker for the whole workflow, or one per domain group mirroring domain partitioning.
**Trade-offs**: single = centralized discovery + least infrastructure, but a fault-tolerance single point and throughput ceiling. Domain = better isolation, matches boundaries, more scalable, but harder queue/topic discovery, more infrastructure cost, more moving parts.

## ADRs (Architectural Decision Records)
**When to use**: every architectural decision, however obvious — and retroactively on existing systems (Ch 21).
**How**: Title (numbered) · Status (Proposed/Accepted/Superseded, + RFC with deadline) · Context (forces + alternatives) · Decision (**affirmative commanding voice**, with full justification) · Consequences (including trade-off analysis) · Compliance · Notes. Store in a dedicated repo or wiki organized as `application/common`, `application/<app>`, `integration`, `enterprise`.
**Trade-offs**: superseded ADRs keep bidirectional number links, preserving the historical trail. Also usable for *standards* — if you can't justify one, it probably shouldn't exist.

## Risk Matrix & Risk Assessment
**When to use**: quantifying and tracking architecture risk (Ch 22).
**How**: impact × likelihood, each 1–3. Bands: 1–2 low, 3–4 medium, 6–9 high. **Consider impact first; default unknown likelihood to 3.** Build assessments with critical characteristics as criteria and domains as context; add **direction** arrows from fitness-function trends; filter to high-risk for stakeholder presentations.
**Trade-offs**: services are too fine-grained a context — they miss inter-service coordination risk.

## Risk Storming
**When to use**: after any major feature, or at the end of each iteration (Ch 22).
**How**: Phase 1 **individual** identification on sticky notes; Phase 2 **consensus** on a posted diagram; Phase 3 **mitigation** with business stakeholders present. One criterion or context per session. **Unknown technologies automatically rate 9.**
**Trade-offs**: mitigation costs money — bring a cheaper alternative to the stakeholder conversation.

## Checklists
**When to use**: processes without dependent ordering where steps are frequently skipped (Ch 24).
**How**: three recommended — developer code-completion (definition of done), unit/functional testing (grow it from every QA finding), software release (grow it from every failed deployment).
**Trade-offs**: Law of Diminishing Returns — too many checklists and developers stop using them. Automate items out. Enforce via ownership first, Hawthorne-effect spot-checks second. **Do state the obvious; it's what gets missed.**

## Layered Stack Guidance
**When to use**: controlling third-party library adoption (Ch 24).
**How**: require two answers — overlap with existing functionality, and technical **and business** justification. Then: special-purpose → developers decide; general-purpose → developers recommend, architect approves; framework → architect only.
**Trade-offs**: requiring business justification changes how developers think (see the Scala story).

## Negotiation Techniques
**When to use**: any challenged decision (Ch 25).
**How**: read the buzzwords for the real characteristic → gather information first → **translate abstractions into concrete units** (86 seconds/day, not "three nines") → divide and conquer the requirement → qualified cost and time **last**. With architects: **demonstration defeats discussion**. With developers: justification **before** demand; "this means" not "you must"; "have you considered" not "what you need to do"; let them prove themselves right; turn requests into favors.
**Trade-offs**: leading with cost/time poisons the negotiation.

## Trade-Off Analysis Method
**When to use**: every architecture decision (Ch 27).
**How**: (1) enumerate **contextualized** factors specific to this organization and solution; (2) build a +/− matrix per option; (3) **weight the factors against actual organizational goals**.
**Trade-offs**: skipping step 3 is the **Out of Context antipattern** — the raw count of plusses is not the answer. Redo the analysis every time; subtle variable differences flip the outcome.
