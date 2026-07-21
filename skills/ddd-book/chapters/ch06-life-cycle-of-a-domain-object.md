# Chapter 6: The Life Cycle of a Domain Object

## Core Idea
Objects with long lives create two problems: **maintaining integrity throughout the life cycle** and **preventing the model from being swamped by life-cycle management**. AGGREGATES draw the boundaries within which invariants hold; FACTORIES encapsulate creation and reconstitution; REPOSITORIES encapsulate finding and retrieving. FACTORIES and REPOSITORIES don't come *from* the domain, but they belong to the domain design.

## Frameworks Introduced

- **AGGREGATE** (system attributed to David Siegel, 1990s, unpublished):
  > Cluster the ENTITIES and VALUE OBJECTS into AGGREGATES and define boundaries around each. Choose one ENTITY to be the root of each AGGREGATE, and control all access to the objects inside the boundary through the root. Allow external objects to hold references to the root only. Transient references to internal members can be passed out for use within a single operation only. Because the root controls access, it cannot be blindsided by changes to the internals. This arrangement makes it practical to enforce all invariants for objects in the AGGREGATE and for the AGGREGATE as a whole in any state change.
  - **Definition**: *a cluster of associated objects treated as a unit for the purpose of data changes.* Each has a **root** (a single ENTITY) and a **boundary**.
  - **The seven transaction rules:**
    1. The root ENTITY has global identity and is ultimately responsible for checking invariants.
    2. Root ENTITIES have global identity; ENTITIES inside the boundary have **local identity**, unique only within the AGGREGATE.
    3. Nothing outside the boundary can hold a reference to anything inside **except the root**. The root may hand out internal ENTITY references for **transient** use only — the receiver may not hold on to them. A copy of a VALUE OBJECT may be handed out freely; it's just a VALUE and no longer associated with the AGGREGATE.
    4. Corollary: **only AGGREGATE roots can be obtained directly with database queries.** All other objects must be found by traversal.
    5. Objects within the AGGREGATE may hold references to other AGGREGATE **roots**.
    6. A delete operation must remove everything within the boundary at once.
    7. When a change to any object inside the boundary is committed, **all invariants of the whole AGGREGATE must be satisfied.**
  - Invariants *spanning* AGGREGATES are not expected to be current at all times — resolve them via event processing, batch processing, or other update mechanisms within a specified time.
  - When to use: whenever concurrent access, transaction scope, or cascading deletes are unclear — which, in an interconnected domain, is always.
  - Why it works: the problem *surfaces* as database transaction difficulty but is **rooted in the model — in its lack of defined boundaries.** A model-driven solution makes the model easier to understand and guides implementation changes.
  - Design heuristic: *find a model that leaves high-contention points looser and strict invariants tighter.* This requires domain knowledge about **frequency of change** between instances of certain classes.

- **FACTORY**:
  > Shift the responsibility for creating instances of complex objects and AGGREGATES to a separate object, which may itself have no responsibility in the domain model but is still part of the domain design. Provide an interface that encapsulates all complex assembly and that does not require the client to reference the concrete classes of the objects being instantiated. Create entire AGGREGATES as a piece, enforcing their invariants.
  - **Two basic requirements of a good FACTORY:**
    1. Each creation method is **atomic** and enforces all invariants of the created object or AGGREGATE. A FACTORY should only be able to produce an object in a consistent state — raise an exception rather than return an improper value.
    2. The FACTORY should be **abstracted to the type desired**, not to the concrete class(es) created.
  - **Where to put it** — "create a factory to build something whose details you want to hide, and place the FACTORY where you want the control to be":
    - **FACTORY METHOD on the AGGREGATE root** — for adding elements inside a preexisting AGGREGATE; hides the interior and gives the root responsibility for integrity as elements are added.
    - **FACTORY METHOD on a closely involved spawner** — e.g. `Brokerage Account` creating `Trade Order`. The Trade Order is *not* in the same AGGREGATE (it goes on to interact with trade execution, where Brokerage Account would only be in the way), but the account holds the data to embed and the rules governing allowed trades. Bonus: the FACTORY decouples the client if `Trade Order` later becomes a hierarchy of `Buy Order` / `Sell Order`.
    - **Standalone FACTORY / SERVICE** — when there's something to hide but no natural host. Usually produces an entire AGGREGATE, hands out a root reference, and enforces invariants.
  - **Interface design rules:**
    - Each operation must be atomic — pass everything needed in a single interaction; decide and standardize the failure convention (exception vs. null).
    - **The FACTORY will be coupled to its arguments.** Safest parameters come from a *lower design layer*, or are objects already closely related to the product in the model (a `Purchase Order Item` factory taking a `Catalog Part` adds no new dependency — the AGGREGATE already referenced Part). Use the **abstract type** of arguments, not concrete classes.
  - **Where invariant logic goes**: the FACTORY can delegate checking to the product, and often that's best. But a FACTORY already knows the product's internals, so placing invariant logic there can reduce clutter — *especially appealing for AGGREGATE-spanning rules, especially unappealing for FACTORY METHODS attached to other domain objects.* And an object needn't carry logic that can never fire in its active lifetime (identity assignment rules for an ENTITY whose ID is immutable after creation; anything about a fully immutable VALUE).
  - **ENTITY vs. VALUE OBJECT factories**: VALUE factories must allow a *full* description of the product (immutable, complete on exit). ENTITY factories take just the essential attributes for a valid AGGREGATE; details can be added later if no invariant requires them. Only ENTITY factories deal with identity assignment.

- **Reconstitution** — a FACTORY used for reconstitution differs in exactly two ways:
  1. It **does not assign a new tracking ID** — that would break continuity with the previous incarnation, so identifying attributes must be input parameters.
  2. It **handles invariant violations differently**. On creation, a FACTORY simply balks. On reconstitution, the object *already exists* in the system — that fact can't be ignored, and neither can the violation. You need a strategy for repairing inconsistencies, which makes reconstitution harder than creation.

- **REPOSITORY**:
  > For each type of object that needs global access, create an object that can provide the illusion of an in-memory collection of all objects of that type. Set up access through a well-known global interface. Provide methods to add and remove objects, which will encapsulate the actual insertion or removal of data in the data store. Provide methods that select objects based on some criteria and return fully instantiated objects or collections of objects whose attribute values meet the criteria, thereby encapsulating the actual storage and query technology. **Provide REPOSITORIES only for AGGREGATE roots that actually need direct access.** Keep the client focused on the model, delegating all object storage and access to the REPOSITORIES.
  - Advantages: a simple model for obtaining persistent objects; decoupling from persistence technology, multiple database strategies, even multiple data sources; **communicating design decisions about object access**; easy substitution of a dummy in-memory implementation for testing.
  - **Query design options**: hard-coded queries with specific parameters (cheap, buildable on any infrastructure, "they do just what some client would have had to do anyway"), or a **SPECIFICATION-based** framework letting a client describe what it wants without concern for how it's obtained (Ch 9). Even a flexible design should still allow specialized hard-coded queries — *frameworks that don't allow for such contingencies tend to distort the domain design or get bypassed by developers.*
  - **Implementation concerns**: abstract the type (one REPOSITORY per *type*, which may be an abstract superclass, an interface, or a concrete class — not per class); exploit the decoupling to optimize, cache, or swap persistence strategies; **leave transaction control to the client** — the REPOSITORY inserts and deletes but ordinarily does not commit, because the client has the context to define units of work.
  - **Relationship with FACTORIES**: *"The FACTORY makes new objects; the REPOSITORY finds old objects."* Technically a REPOSITORY that builds objects from data *is* a factory, but keeping the model in the forefront matters more: reconstitution is not creation. Reconcile by having the REPOSITORY **delegate** object creation to a FACTORY, which unloads all persistence responsibility from the FACTORY.
  - **Avoid "find or create."** A minor convenience at best; most apparent uses evaporate once ENTITIES and VALUE OBJECTS are distinguished (a client wanting a VALUE goes straight to a FACTORY). The distinction between a new and an existing object is usually important in the domain, and transparently combining them muddles it.

- **When a constructor is all you need** — the trade-offs favor a bare public constructor when *all* of these hold:
  1. The class is the type — not part of an interesting hierarchy, not used polymorphically via an interface.
  2. The client cares about the implementation, perhaps as a way of choosing a STRATEGY.
  3. All the object's attributes are available to the client, so no object creation nests inside the exposed constructor.
  4. The construction is not complicated.
  - A public constructor **must follow the same rules as a FACTORY**: atomic, satisfying all invariants. **Avoid calling constructors within constructors of other classes; constructors should be dead simple.** "The threshold for choosing to use a little FACTORY METHOD isn't high."

## Key Concepts
- **AGGREGATE** — a cluster of objects treated as a unit for data changes, with a root and a boundary.
- **Root ENTITY** — the only member outside objects may reference; responsible for checking invariants.
- **Local identity** — identity distinguishable only within an AGGREGATE.
- **Invariant** — a consistency rule that must be maintained whenever data changes.
- **FACTORY** — a program element whose responsibility is the creation of other objects.
- **FACTORY METHOD / ABSTRACT FACTORY / BUILDER** — creation patterns (Gamma et al. 1995).
- **REPOSITORY** — an object providing the illusion of an in-memory collection of all objects of a type.
- **Reconstitution** — creating an instance from stored data; conceptually the *middle* of an ENTITY's life cycle, not its beginning.
- **QUERY OBJECT / METADATA MAPPING LAYER** — supporting persistence patterns (Fowler 2002).
- **SPECIFICATION** — a declarative description of criteria an object must satisfy (Ch 9).

## Mental Models
- **Think of an AGGREGATE as an ownership and transaction boundary, not a containment diagram.** The car/tires example: tires are ENTITIES with rotation histories, but nobody queries for a tire and asks which car it's on — they find the car and ask it. So the car is the root. An engine block with an engraved serial number tracked independently might be its own root.
- **Use "does anyone query for this outside the context of its owner?"** as the root test.
- **Assembly is a different job from operation.** No one designs an engine block that inserts its own pistons; a mechanic or robot does it, and neither rides along while you drive. Cars are never assembled and driven at the same time, so there's no value in combining those functions.
- **A client that assembles domain objects breaches encapsulation.** It must know the internal structure and some of the object's rules; even calling a constructor couples it to concrete classes. If the client is in the application layer, **responsibilities have leaked out of the domain layer altogether.**
- **Treat the choice between traversal and search as a design decision** — trading the decoupling of a search against the cohesiveness of an association. Should `Customer` hold all its `Order`s, or should Orders be found by a query on Customer ID? "The right combination of search and association makes the design comprehensible."
- **If you need to search the database for a preexisting VALUE, suspect you have an unrecognized ENTITY.** (Exceptions exist: saved travel itineraries retrieved under a username; enumerations with a fixed set of possible values.)
- **Client code ignores REPOSITORY implementation; developers do not.** Encapsulation doesn't excuse ignorance of what happens under the hood.

## Worked Example — Purchase Order Integrity

**Model**: a Purchase Order broken into line items, with the invariant *the sum of the line items can't exceed the PO's approval limit*. Three interrelated problems in the existing implementation: invariant enforcement (the PO checks the total when an item is added and marks itself invalid — not adequate), change management (deleting/archiving a PO takes its line items, but nothing says where to stop following relationships), and database contention.

**Attempt 1 — lock the individual line item being edited.** George edits item 001; Amanda can edit any other line item on any PO, including other items on George's PO. Objects are read into each user's memory space; locks are taken only when an edit begins.

**The break:** George and Amanda edit *separate line items of the same PO*. Everything looks fine to both users and to the software — each ignores changes elsewhere in the database during their transaction, and neither locked item is involved in the other's change. **After both save, the stored PO violates the approval limit. An important business rule has been broken. And nobody even knows.**

**Attempt 2 — lock the entire PO.** The invariant can now be enforced: the transaction won't save until Amanda resolves the problem (raise the limit, or drop a guitar). Fine if work spreads across many POs; **cumbersome if multiple people typically work on different line items of one large PO.**

**Attempt 3 — also lock the "part."** Because if someone changes the price of a trombone while Amanda is adding to her order, the invariant breaks again. But now George, Amanda, and Sam working on *different* POs contend over the same instruments — over-cautious locking interferes with people's work, and then: **deadlock.** "Those three will be waiting a while."

**The fix comes from domain knowledge, not from locking strategy:**
1. Parts are used in many POs (**high contention**).
2. There are fewer changes to parts than to POs.
3. **Changes to part prices do not necessarily propagate to existing POs** — it depends on the timing of the price change relative to the PO's status. Obvious once you consider archived, already-delivered POs: they must show the price *as of when they were filled*.

**Resolution: copy the price into `Line Item`.** The PO + its items form an AGGREGATE whose invariant is now enforceable; part price changes no longer immediately affect items that reference the part. Broader consistency is handled *outside* the invariant — e.g. present users a daily queue of items with outdated prices to update or exempt.

**The principle demonstrated:** loosen the line-item→part dependency to avoid contention and better reflect business reality; tighten the PO→line-item relationship to guarantee the rule. The AGGREGATE imposes an ownership consistent with business practice — creation and deletion of a PO and its items are naturally tied together, while creation and deletion of parts is independent.

## Anti-patterns
- **All access by creation or traversal**: a team enthusiastically embracing MODEL-DRIVEN DESIGN on an object database reasoned that existing conceptual relationships would supply every needed association. This forced exactly the endless tangle AGGREGATES exist to prevent. They abandoned the strategy quickly but never replaced it with a coherent one — they cobbled together ad hoc solutions and **became less ambitious.**
- **Direct database access from client code**: developers are tempted to bypass AGGREGATES or even object encapsulation, taking the data they need directly. "More and more domain rules become embedded in query code or simply lost." ENTITIES and VALUE OBJECTS degrade into data containers, and the design shifts toward a data-processing style.
- **The "all objects" query** (Kyle Brown's story): a WebSphere manufacturing application ran out of memory after a few hours in production. To summarize information about every item in the plant, developers used a query called "all objects," instantiated each one, and selected the bits they needed — **bringing the entire database into memory at once.** It passed testing because the test data was small.
- **Dressing up a framework construct to look like a REPOSITORY**: e.g. forcing J2EE's "EJB Home" into REPOSITORY shape. **"In general, don't fight your frameworks."** Keep the fundamentals of DDD, let go of specifics when the framework is antagonistic, and look for genuine conceptual affinities. If you have the freedom, choose frameworks harmonious with your design style.
- **Constructors calling constructors of other classes** — complex nested assembly belongs in a FACTORY.

## Reference — Designing Objects for Relational Databases

Three common cases:
1. **The database is primarily a repository for the objects.**
2. **The database was designed for another system.**
3. **The database is designed for this system but serves roles other than object store.**

For case 1 (the important common case), **simple directness is best**:
- A table row should contain an object, perhaps along with subsidiaries in an AGGREGATE.
- A foreign key should translate to a reference to another ENTITY object.
- Don't let the data model and object model diverge, *regardless of the powers of the mapping tools* — multiple overlapping models are just too complicated (the same argument as against separate analysis and design models).
- **Sacrifice some richness of object relationships to stay close to the relational model; compromise formal relational standards such as normalization if it simplifies the mapping.**
- Mappings must be **transparent** — understandable by inspecting the code or the mapping tool entries.
- Processes outside the object system should **not** access such a store: they can violate object-enforced invariants, and their access locks in the data model so it's hard to change when objects are refactored.
- Use the UBIQUITOUS LANGUAGE to tie the two together — names and associations of objects should correspond **meticulously** to those of the relational tables.

For case 2, two domain models coexist in one system (see Ch 14) — conform to the other system's implicit model, or make yours completely distinct. For case 3, a deliberately separate schema can be clean rather than "awkward and full of compromises conforming to last year's object model" — but note this separation is *usually taken unintentionally*, when the team fails to keep the database current with the model.

Note the drag: refactoring culture has barely touched relational database design, and data migration issues discourage frequent change. That drag on object-model refactoring is real — but if the two models diverge, transparency is lost quickly.

## Key Takeaways
1. Draw AGGREGATE boundaries from domain knowledge about contention and change frequency — loosen high-contention relationships, tighten the ones carrying strict invariants.
2. Enforce the rule that only AGGREGATE roots are globally reachable and only roots can be queried directly; everything else comes by traversal.
3. Commit-time consistency applies to a whole AGGREGATE; cross-AGGREGATE consistency is eventual, by design.
4. Move complex assembly into FACTORIES so domain objects stay focused on their mid-life responsibilities and clients stay decoupled from concrete classes.
5. Make every creation operation atomic and invariant-enforcing — including plain constructors when a constructor is the right call.
6. Reconstitution is not creation: preserve the tracking ID and plan a repair strategy for invariant violations in stored data.
7. Provide REPOSITORIES only for AGGREGATE roots that genuinely need direct access — doing more muddies important distinctions.
8. Keep transaction control in the client, not the REPOSITORY.
9. Avoid "find or create"; the distinction between new and existing usually matters in the domain.
10. When a relational database is the object store, keep the mapping simple and transparent, sacrificing model richness rather than losing model/implementation coupling.

## Connects To
- **Ch 5 (Model Expressed in Software)**: AGGREGATES resolve the "web of relationships" problem hinted at by the OODB contention story; FACTORIES and REPOSITORIES are the supporting objects deliberately excluded from the model-expressing objects there.
- **Ch 9 (Making Implicit Concepts Explicit)**: SPECIFICATION, the basis of flexible REPOSITORY queries.
- **Ch 10 (Supple Design)**: characterizing well-designed components so developers can use encapsulated behavior responsibly; design layering within a layer.
- **Ch 14 (Maintaining Model Integrity)**: when the database belongs to a legacy or external system, two domain models coexist.
- **Ch 16 (Large-Scale Structure)**: further discussion of stratification.
- **Gamma et al. 1995** (FACTORY METHOD, ABSTRACT FACTORY, BUILDER), **Fowler 2002** (METADATA MAPPING LAYER, QUERY OBJECT; Rob Mee and Edward Hieatt on REPOSITORY implementation).
