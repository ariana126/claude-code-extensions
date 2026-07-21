# Patterns — Domain-Driven Design

## Part I — Putting the Model to Work

### UBIQUITOUS LANGUAGE (Ch 2)
**When to use**: always, from the start, even when the model is too weak to carry it.
**How**: use the model as the backbone of one language in speech, writing, diagrams, and code. When a phrase is awkward, try alternative expressions (= alternative models), then refactor code to match the winner. A change in the LANGUAGE *is* a change to the model.
**Trade-offs**: costs relentless discipline; pays back by forcing model weaknesses into the open. Never split the language between developers and experts — technical and domain jargon are permitted *extensions*, not rival vocabularies.

### MODEL-DRIVEN DESIGN (Ch 3)
**When to use**: whenever domain complexity dominates and you have a modeling-paradigm language (OO, logic).
**How**: reject any model impractical to implement, and any that doesn't express the domain. Iterate model/design/code as one activity. One model per part of the system.
**Trade-offs**: demands more of the model than either analysis or design alone; limited applicability in purely procedural languages.

### HANDS-ON MODELERS (Ch 3)
**When to use**: always; specialized roles are fine, splitting modeling from implementation is not.
**How**: everyone contributing to the model touches code; everyone changing code learns to express the model in it; everyone has some contact with domain experts.
**Trade-offs**: forfeits the illusion of leverage from an architect role; buys days-not-months feedback on implementation constraints.

## Part II — Building Blocks

### LAYERED ARCHITECTURE (Ch 4)
**When to use**: any project committing to MODEL-DRIVEN DESIGN. DDD requires exactly one layer to exist — the domain layer.
**How**: UI → Application (thin; task-progress state only) → Domain (business state and rules) → Infrastructure. Depend only downward; communicate upward via callbacks or OBSERVER.
**Trade-offs**: overhead makes simple tasks slower — which is why SMART UI is a legitimate alternative fork.

### SMART UI (Ch 4)
**When to use**: simple, rule-light, data-entry-dominated projects with short timelines and teams that aren't advanced object modelers.
**How**: business logic in the UI, relational database as shared repository, most automated 4GL tooling available.
**Trade-offs**: high immediate productivity, integration only through the database, no behavior reuse, complexity ceiling hit fast, and **no migration path except replacing entire applications**. Choose it wholeheartedly or not at all.

### ENTITY (Ch 5)
**When to use**: the object has continuity through a life cycle and distinctions independent of attributes that matter to the user.
**How**: make identity primary; keep the class spare (identity + matching attributes + essential behavior); define an identity operation surviving persistence, transmission, and archiving.
**Trade-offs**: identity tracking costs performance and analysis — which is why not everything should be one.

### VALUE OBJECT (Ch 5)
**When to use**: you care only about *what* it is, not *who* or *which*.
**How**: express the meaning of the attributes it conveys; make it a conceptual whole; treat as immutable.
**Trade-offs**: immutability unlocks free copying, sharing, FLYWEIGHT, and denormalization. Allow mutability only when the value changes frequently, creation/deletion is expensive, or clustering demands it — **and then never share it.**

### SERVICE (Ch 5)
**When to use**: a significant process or transformation that is not a natural responsibility of an ENTITY or VALUE OBJECT.
**How**: standalone interface, named for an activity (verb, not noun), stateless, parameters and results are domain objects, operation name in the UBIQUITOUS LANGUAGE.
**Trade-offs**: the common mistake is reaching for it too early and sliding toward procedural programming; the payoff is medium-grained interfaces that keep domain knowledge out of the application layer.

### MODULE (Ch 5)
**When to use**: always; cognitive overload, not technical metrics, is the motivation.
**How**: choose MODULES that tell the story of the system with a cohesive set of concepts; name them into the UBIQUITOUS LANGUAGE.
**Trade-offs**: when conceptual clarity conflicts with technical coupling, **take conceptual clarity**. Refactoring MODULES is disruptive, so they lag the classes — bite the bullet periodically.

### AGGREGATE (Ch 6)
**When to use**: whenever transaction scope, cascading deletes, or concurrent-access consistency is unclear.
**How**: cluster ENTITIES and VALUES, pick one root ENTITY, allow external references only to the root, allow only transient use of handed-out internal references, query only for roots, delete the whole boundary at once, satisfy all invariants at every commit.
**Trade-offs**: cross-AGGREGATE consistency becomes eventual by design. Find boundaries by loosening high-contention relationships and tightening the ones carrying strict invariants.

### FACTORY (Ch 6)
**When to use**: creation is complicated or reveals too much internal structure.
**How**: atomic creation methods enforcing all invariants; abstract to the desired type, not the concrete class; place a FACTORY METHOD on the AGGREGATE root or a closely-involved spawner, or build a standalone FACTORY.
**Trade-offs**: skip it for a bare public constructor when the class is the type, the client cares about the implementation, all attributes are available to the client, and construction is simple.

### REPOSITORY (Ch 6)
**When to use**: for AGGREGATE roots that actually need direct global access.
**How**: provide the illusion of an in-memory collection; add/remove methods; criteria-based selection returning fully instantiated objects; hard-coded queries or SPECIFICATION-based.
**Trade-offs**: leave transaction control to the client; providing REPOSITORIES for non-roots muddies important distinctions.

## Part III — Refactoring Toward Deeper Insight

### SPECIFICATION (Ch 9, extended Ch 10)
**When to use**: a business rule doesn't fit the responsibility of any obvious ENTITY or VALUE, and its variety would overwhelm the object's meaning.
**How**: a predicate-like VALUE OBJECT answering `isSatisfiedBy()`. Unifies **validation**, **selection**, and **building to order**. Combine with `and`/`or`/`not`; add `subsumes` for implication.
**Trade-offs**: with database selection, choose between SQL in the SPEC (leaks table structure), double dispatch to a specialized repository query (rule split), or double dispatch to a generic query filtered in memory (performance hit). Implement only AND if that's all you need.

### INTENTION-REVEALING INTERFACES (Ch 10)
**When to use**: everywhere in a public domain interface.
**How**: name for effect and purpose, never means. Write the test first, in the shape you wish the API had. "Pose the question, but don't present the means by which the answer shall be found."
**Trade-offs**: none, beyond the discipline of writing tests first.

### SIDE-EFFECT-FREE FUNCTIONS (Ch 10)
**When to use**: as much of the program's logic as possible.
**How**: strictly segregate commands (returning no domain data) from queries; then move complex logic into an immutable VALUE OBJECT so the command becomes trivial.
**Trade-offs**: sometimes requires finding a new model; the reward is safe combination of operations and easy testing.

### ASSERTIONS (Ch 10)
**When to use**: for every command that produces side effects, and for class/AGGREGATE invariants.
**How**: state post-conditions and invariants; if the language can't hold them, put them in automated unit tests or documentation. Prefer models whose assertions a developer can *infer*.
**Trade-offs**: a counterintuitive-but-true assertion signals a missing concept — unless it's serving a real requirement, as with the unmixed-paints report.

### CONCEPTUAL CONTOURS (Ch 10)
**When to use**: whenever deciding granularity.
**How**: observe the axes of change and stability through successive refactorings; align the model with the domain's consistent aspects.
**Trade-offs**: cookbook granularity rules don't work. Localized refactorings mean the model fits; sweeping ones mean it doesn't.

### STANDALONE CLASSES (Ch 10)
**When to use**: for the most intricate computations.
**How**: treat every dependency as suspect until proven essential (counting implicit concepts carried in primitives); factor intricate computation into VALUE OBJECTS held by more connected classes.
**Trade-offs**: don't dumb the model down to primitives to achieve it.

### CLOSURE OF OPERATIONS (Ch 10)
**When to use**: mostly on VALUE OBJECTS, where a computation can produce a new instance.
**How**: define operations whose return type matches the argument/implementer type; may close under an abstract type.
**Trade-offs**: half-closure (return matches implementer, argument is a primitive or basic library type) frees the mind almost as much.

### STRATEGY / POLICY as a domain pattern (Ch 12)
**When to use**: a domain process has more than one legitimate way of being done, and the options are obscuring the process.
**How**: factor apart a rule and the behavior it governs; name the strategy for the business policy.
**Trade-offs**: clients must know about the different strategies; object count rises (mitigate with stateless shared instances).

### COMPOSITE as a domain pattern (Ch 12)
**When to use**: a genuine whole-part hierarchy where parts share a conceptual type with the whole.
**How**: abstract type over all members; containers return aggregated information; clients never distinguish leaves from containers.
**Trade-offs**: the static class diagram says *less*; the operational symmetry is where the power is. Don't apply it before it's needed.

## Part IV — Strategic Design

### BOUNDED CONTEXT (Ch 14)
**When to use**: always — multiple models are in play on any large project whether you name them or not.
**How**: define the context in terms of team organization, application usage, and physical artifacts. Keep the model strictly consistent inside; ignore issues outside.
**Trade-offs**: larger contexts give smoother user-task flow and shared language; smaller ones reduce communication overhead and ease CONTINUOUS INTEGRATION. Roughly one team per context.

### CONTINUOUS INTEGRATION (Ch 14)
**When to use**: within any BOUNDED CONTEXT larger than a two-person task.
**How**: reproducible merge/build, automated tests, a small upper limit on the lifetime of unintegrated changes — plus constant exercise of the UBIQUITOUS LANGUAGE.
**Trade-offs**: essential only *within* a context; neighboring-context translation needn't move at the same pace.

### CONTEXT MAP (Ch 14)
**When to use**: first, before any strategic change.
**How**: identify and name every model in play including non-OO subsystems; describe points of contact and translation. **Map the existing terrain; take up transformations later.**
**Trade-offs**: it will show ugly truths — put a dragon on the map and finish describing everything before fixing anything.

### SHARED KERNEL (Ch 14)
**When to use**: two closely related teams for whom full CONTINUOUS INTEGRATION is too costly.
**How**: designate a shared model subset with its code and schema; change only by consultation; integrate frequently but less often than internal CI, running both teams' tests.
**Trade-offs**: reduces (not eliminates) duplication; greater coordination burden in development *and* deployment.

### CUSTOMER/SUPPLIER DEVELOPMENT TEAMS (Ch 14)
**When to use**: one-way dependency between teams that can be directed from a common source.
**How**: downstream plays the customer in planning sessions; jointly develop automated acceptance tests added to the upstream CI suite; downstream stays available during the iteration.
**Trade-offs**: fails without shared management or a genuine commercial customer relationship — then you're a CONFORMIST.

### CONFORMIST (Ch 14)
**When to use**: an indispensable upstream with tolerable design quality and no motivation to serve you; or an off-the-shelf component with a large interface.
**How**: adhere slavishly to the upstream model; extension only, no modification.
**Trade-offs**: deepens dependency and limits you to the upstream model plus additive enhancements — "very unappealing emotionally, which is why we choose it less often than we probably should." Upside: you may be dragged into a better design.

### ANTICORRUPTION LAYER (Ch 14)
**When to use**: a large interface with a legacy or external system whose model would corrupt yours.
**How**: FACADE (in the *other* system's model) + ADAPTER per SERVICE + stateless translator. Public interface as SERVICES reabstracted in your terms. Can be bidirectional.
**Trade-offs**: the Great Wall — genuinely protective and potentially bankrupting. If translation difficulty gets out of hand, become a CONFORMIST.

### SEPARATE WAYS (Ch 14)
**When to use**: two feature sets with no indispensable relationship.
**How**: declare no connection at all; organize in middleware or the UI only.
**Trade-offs**: forecloses options — merging models developed in complete isolation is hard. But integration is *always* expensive and sometimes the benefit is small.

### OPEN HOST SERVICE / PUBLISHED LANGUAGE (Ch 14)
**When to use**: many consumers, when a custom translator per consumer is bogging the team down.
**How**: expose a set of SERVICES as an open protocol; if the interaction needs formalizing, adopt an industry-standard language or publish one built from your CORE using XML.
**Trade-offs**: OPEN HOST couples consumers to your dialect. **Never equate the published language with the host's model** — the language must be stable while the host keeps refactoring.

### CORE DOMAIN (Ch 15)
**When to use**: any system large enough that priorities must be set.
**How**: boil the model down, make the CORE small and easily distinguishable, apply top talent, and justify every other investment by how it supports the CORE.
**Trade-offs**: what's CORE depends on the application and evolves; you almost certainly cannot buy it.

### GENERIC SUBDOMAIN (Ch 15)
**When to use**: a cohesive subdomain that isn't your project's motivation.
**How**: factor into separate MODULES leaving no trace of your specialties; lower priority; keep core developers off it. Options: off-the-shelf, published model, outsourced, in-house.
**Trade-offs**: **do not design for reusability** — but be strict about staying within the generic concept.

### COHESIVE MECHANISM (Ch 15)
**When to use**: a computation's "how" is swamping the model's "what," *and* part of the mechanism is conceptually coherent.
**How**: partition into a lightweight framework behind an INTENTION-REVEALING INTERFACE; watch for published formalisms and algorithm categories.
**Trade-offs**: try to find a model that makes the computation simple *first*. Keep it in the CORE only when the mechanism itself is proprietary value.

### SEGREGATED CORE / ABSTRACT CORE (Ch 15)
**When to use**: a large critical context where supporting capability obscures the essential model (SEGREGATED); heavy cross-MODULE interaction expressible polymorphically (ABSTRACT).
**How**: SEGREGATED — move CORE classes into a MODULE named for the concept, sever non-expressive data and functionality, iterate. ABSTRACT — slice horizontally, factoring fundamental concepts into their own MODULE.
**Trade-offs**: expensive whole-team commitments; SEGREGATED may break otherwise-cohesive MODULES; ABSTRACT is meaningless unless the interfaces are genuine domain concepts.

### EVOLVING ORDER (Ch 16)
**When to use**: whenever imposing a large-scale structure.
**How**: let the structure evolve with the application, possibly changing type entirely; flag exceptions; discard or change the structure if exceptions multiply.
**Trade-offs**: an ill-fitting structure is worse than none. Less is more.

### RESPONSIBILITY LAYERS (Ch 16)
**When to use**: the domain has natural strata with different rates and sources of change.
**How**: cast the strata as broad abstract responsibilities telling the system's story; refactor so every object, AGGREGATE, and MODULE fits one layer. Common set: Potential, Operations, Decision Support, Policy, Commitment. Signal upward with events, never dependencies.
**Trade-offs**: forces locally suboptimal designs for global consistency. Keep to four or five layers.

### KNOWLEDGE LEVEL (Ch 16)
**When to use**: roles and relationships among ENTITIES must be configurable by users at install or runtime.
**How**: a distinct set of ordinary objects describing and constraining the basic model, edited by a superuser. Not fully general — specialized constraints beat a general framework.
**Trade-offs**: dependencies run both ways (so it isn't a layer); indirection adds back some obscurity; data migration problems remain; the designer must anticipate every configuration a user could produce.

### PLUGGABLE COMPONENT FRAMEWORK (Ch 16)
**When to use**: a very mature, deep, distilled model — after several specialized applications in the domain already exist.
**How**: distill an ABSTRACT CORE of interfaces and interactions; components plug into a hub; applications operate strictly through the abstract interfaces.
**Trade-offs**: very hard to design, and it **freezes continuous refinement of the CORE**. Never the first or second structure applied.
