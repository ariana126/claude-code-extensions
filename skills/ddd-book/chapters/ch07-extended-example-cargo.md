# Chapter 7: Using the Language — An Extended Example

## Core Idea
The Part II patterns are applied one at a time in isolation, but on a real project they combine. This chapter walks a cargo shipping model through ENTITY/VALUE classification, association constraint, AGGREGATE boundaries, REPOSITORY selection, FACTORIES, scenario cross-checking, a mid-course refactoring, MODULE naming, and a third-party integration — showing the *forces* each pattern resolves.

## The Domain

New software for a cargo shipping company. Three initial requirements:
1. Track key handling of customer cargo
2. Book cargo in advance
3. Send invoices to customers automatically when the cargo reaches some point in its handling

Starting model, and the sentences it enables ("Multiple `Customers` are involved with a `Cargo`, each playing a different `role`"; "A series of `Carrier Movements` satisfying the `Specification` will fulfill the delivery `goal`"):

| Object | Meaning |
|---|---|
| `Handling Event` | A discrete action taken with the Cargo — loading onto a ship, clearing customs. Likely elaborated into a hierarchy. |
| `Delivery Specification` | The delivery **goal** — minimally destination + arrival date. Follows the SPECIFICATION pattern (Ch 9). |
| `Delivery History` | What has **actually happened** to a Cargo. Can compute current `Location` from the last load/unload and the corresponding Carrier Movement's destination. |
| `Carrier Movement` | One particular trip by a particular Carrier (truck, ship) from one Location to another. |
| `role` | Distinguishes the parts Customers play — shipper, receiver, payer. |

**Why `Delivery Specification` instead of putting the goal on `Cargo`** — three advantages:
1. `Cargo` would otherwise own the detailed meaning of all those attributes and associations, cluttering it and making it harder to understand or change.
2. It makes it **easy and safe to suppress detail** when explaining the model — the diagram says "there is a SPECIFICATION of delivery" and the details need not be thought about (and can change later).
3. It is **more expressive**: it says explicitly that the exact means of delivery is undetermined, but must accomplish the stated goal.

## Worked Example — Step by Step

### 1. Isolate the domain: three application-layer coordinators
- `Tracking Query` — access past and present handling of a Cargo
- `Booking Application` — register a new Cargo and prepare the system for it
- `Incident Logging Application` — record each handling (feeding the Tracking Query)

**"These application classes are coordinators. They should not work out the answers to the questions they ask. That is the domain layer's job."**

### 2. Distinguish ENTITIES from VALUE OBJECTS

| Object | Verdict | Identity / reasoning |
|---|---|---|
| `Customer` | ENTITY | Identity matters to the user. Tax ID fails for international companies — **ask a domain expert**: the company already assigns an ID at first sales contact, used company-wide. Reusing it establishes continuity with existing systems. Initially manual entry. |
| `Cargo` | ENTITY | Two identical crates must be distinguishable. Auto-generated tracking ID, visible to the user, conveyed to the customer at booking. |
| `Handling Event` | ENTITY | Real-world events aren't interchangeable. **Domain expert reveals** the natural key: Cargo ID + completion time + type ("the same Cargo cannot be both loaded and unloaded at the same time"). |
| `Carrier Movement` | ENTITY | Identified by a code from a shipping schedule. |
| `Location` | ENTITY | Two places with the same name aren't the same. Lat/long is a unique key but impractical and uninteresting here — use an arbitrary internal generated ID. |
| `Delivery History` | ENTITY, but… | Not interchangeable, so an ENTITY — yet one-to-one with its Cargo, so **its identity is borrowed from the Cargo that owns it.** Clarified once AGGREGATES are drawn. |
| `Delivery Specification` | VALUE OBJECT | Doesn't depend on Cargo; expresses a *hypothetical state* of some Delivery History. Two Cargoes to the same place **could share a Specification but could not share a History**, even though both histories start out empty. |
| `role`, timestamps, names | VALUE OBJECT | `role` qualifies an association but has no history or continuity; shareable across Cargo/Customer associations. |

### 3. Constrain associations
- **Customer → Cargo: dropped.** A direct reference to every Cargo shipped becomes cumbersome for long-term repeat Customers, and *the concept of a Customer is not specific to Cargo* — in a large system Customer plays roles with many objects. Keep it free of such specific responsibilities; find Cargoes by Customer via a database query.
- **Handling Event → Carrier Movement only.** If the application tracked ship inventory, the reverse traversal would matter; the business tracks only Cargo. Bonus: disallowing the direction with multiplicity **reduces the implementation to a simple object reference**.
- **One circular reference remains**: Cargo → Delivery History → Handling Events → Cargo. Circular references logically exist in many domains but are tricky to maintain. Initial prototype: a Java `List` of Handling Events on Delivery History (simple but fragile). Later, likely a database lookup keyed on Cargo. **The model is the same either way — it contains the cycle.** If the history query is infrequent, the lookup gives good performance, simpler maintenance, and cheaper Handling Event insertion; if frequent, keep the direct pointer.

### 4. Draw AGGREGATE boundaries
`Customer`, `Location`, and `Carrier Movement` have their own identities and are shared by many Cargoes → each is its own root.

`Cargo` is an obvious root, but the boundary takes thought. Candidate rule: sweep in everything that would not exist but for this particular Cargo.
- **`Delivery History`: inside.** No one looks it up directly without wanting the Cargo; no need for global access; identity derived from Cargo. It fits inside and need not be a root.
- **`Delivery Specification`: inside.** It's a VALUE OBJECT, so no complications.
- **`Handling Event`: its own root.** Two queries were considered — Handling Events for a Delivery History (local to the Cargo AGGREGATE), and all operations to load/prepare for a particular Carrier Movement. The second means **the activity of handling the Cargo has meaning even apart from the Cargo itself.**

### 5. Select REPOSITORIES — driven by application requirements, not by "which are roots"
Only the five AGGREGATE roots are candidates. Then go back to the requirements:
- Booking Application needs to select Customers by role → **Customer Repository**
- Booking needs to specify a destination → **Location Repository**
- Activity Logging needs to look up the Carrier Movement a Cargo is loaded onto → **Carrier Movement Repository**
- …and to say which Cargo was loaded → **Cargo Repository**
- **No Handling Event Repository yet** — the association with Delivery History is a collection in the first iteration, and no requirement asks what's been loaded onto a Carrier Movement. *"Either of these reasons could change; if they did, then we would add a REPOSITORY."*

### 6. Walk through scenarios to cross-check
**Changing a Cargo's destination** ("we said Hackensack but we really need Hoboken"): `Delivery Specification` is a VALUE OBJECT, so throw it away, get a new one, and use a setter on `Cargo` to replace it. This is exactly what immutability buys.

**Repeat business** — old Cargoes as prototypes for new ones, using PROTOTYPE (Gamma et al. 1995). Cargo is an ENTITY and an AGGREGATE root, so copy carefully, considering each thing inside the boundary:
- `Delivery History` → **create a new, empty one**; the old history doesn't apply. *This is the usual case with ENTITIES inside the AGGREGATE boundary.*
- `Customer Roles` → copy the Map including keys (they'll likely play the same roles), but **do not copy the Customer objects** — end up referencing the same ones, because they are ENTITIES *outside* the boundary.
- `Tracking ID` → get a new one from the same source as a from-scratch Cargo.

**"We have copied everything inside the Cargo AGGREGATE boundary, we have made some modifications to the copy, but we have affected nothing outside the AGGREGATE boundary at all."**

## Code Examples

Primitive constructor creating both halves of the two-way association, encapsulated by the root:

```java
public Cargo(String id) {
    trackingID = id;
    deliveryHistory = new DeliveryHistory(this);
    customerRoles = new HashMap();
}
```

Because neither `Cargo` nor `Delivery History` is complete without pointing to its counterpart, they must be created together — and since Cargo is the root, **`Delivery History`'s constructor is used exclusively by its AGGREGATE root**, so the composition stays encapsulated.

FACTORY signature options for the prototype scenario (all returning a Cargo with empty Delivery History and null Delivery Specification):

```java
public Cargo copyPrototype(String newTrackingID)                   // FACTORY METHOD on Cargo
public Cargo newCargo(Cargo prototype, String newTrackingID)       // standalone FACTORY
public Cargo newCargo(Cargo prototype)                             // standalone, also generates the ID
```

ENTITY constructor taking exactly the identifying attributes:

```java
public HandlingEvent(Cargo c, String eventType, Date timeStamp) {
    handled = c;
    type = eventType;
    completionTime = timeStamp;
}
```

FACTORY METHOD per event type, abstracting instance creation over a family of specialized subclasses:

```java
public static HandlingEvent newLoading(
   Cargo c, CarrierMovement loadedOnto, Date timeStamp) {
      HandlingEvent result =
         new HandlingEvent(c, LOADING_EVENT, timeStamp);
      result.setCarrierMovement(loadedOnto);
      return result;
}
```

- **What it demonstrates**: non-identifying attributes of an ENTITY can usually be added later; but when all attributes are set in the initial transaction and never altered, a per-type FACTORY METHOD makes client code more expressive and frees it from knowing which subclass to instantiate or how to initialize it.

## Worked Example — Pause for Refactoring: An Alternative Cargo AGGREGATE

**"Modeling and design is not a constant forward process. It will grind to a halt unless there is frequent refactoring to take advantage of new insights to improve the model and the design."**

**The pain**: adding a `Handling Event` requires inserting it into `Delivery History`'s collection, which drags the whole `Cargo` AGGREGATE into the transaction. If another user is modifying that Cargo, the Handling Event transaction can fail or be delayed. But entering Handling Events is **operational work that must be quick and simple** — an important application requirement is entering them *without contention*.

**The change**: replace `Delivery History`'s collection with a query, backed by a new `Handling Event Repository`. Consequences:
- Handling Events can be added without raising integrity issues outside their own AGGREGATE → transactions complete without interference.
- With many event entries and few queries, this is **more efficient**. And if a relational database is underneath, a query was probably emulating the collection anyway.
- Reduces the difficulty of maintaining the Cargo↔Handling Event cycle.
- The REPOSITORY can offer *optimized* queries — e.g. return just the last reported load/unload to infer current status, or (later, if asked) all Cargoes on a particular Carrier Movement.
- `Delivery History` now has **no persistent state** and can be derived on demand. The ENTITY is repeatedly recreated, but *"the association with the same Cargo object maintains the thread of continuity between incarnations."* The Cargo Factory simplifies (no empty Delivery History to attach), and persistent object count drops — meaningful in some object databases. If users seldom check status before arrival, a lot of unneeded work disappears.

**The counter-argument Evans keeps honest**: on an object database, traversing an association or explicit collection is probably much faster than a REPOSITORY query. If the access pattern is frequent full-history listing rather than occasional targeted queries, the trade-off favors the explicit collection. And *"the added feature ('What is on this Carrier Movement?') hasn't been requested yet, and may never be, so we don't want to pay much for that option."*

**The point that matters**: these are **degrees of freedom within the same model**. Modeling VALUES, ENTITIES, and AGGREGATES as done here confined every change inside the `Cargo` AGGREGATE boundary — plus one added REPOSITORY, with **no redesign of `Handling Event` itself.**

## Anti-patterns
- **MODULES partitioned by pattern** — one package for ENTITIES, one for VALUE OBJECTS, etc. Objects with little conceptual relationship get crammed together (low cohesion) while associations run willy-nilly between MODULES (high coupling). *"The packages tell a story, but it is not the story of shipping; it is the story of what the developer was reading at the time."* Evans notes this is no worse than separating persistent from transient objects, or **any methodical scheme not grounded in the meaning of the objects**.
- **Talking to a foreign system directly** — the Booking Application accommodating the Sales Management System's design would make MODEL-DRIVEN DESIGN harder to keep and **confuse the UBIQUITOUS LANGUAGE**.
- **Naming the translator after the foreign system** — "Sales Management Interface" would miss the opportunity to *use language to recast the problem along lines more useful to us*.
- **Business rules in the application layer** — the first cut had the Booking Application applying "a Cargo is accepted if the space allocated for its Enterprise Segment is greater than the quantity already booked plus the size of the new Cargo." Enforcing a business rule is a domain responsibility.

## Worked Example — MODULES that tell the domain's story

Replace pattern-based packaging with broad domain concepts. The names must contribute to the team's language, so that this story can be told:

> "Our company does **shipping** for **customers** so that we can **bill** them. Our sales and marketing people deal with **customers**, and make agreements with them. The operations people do the **shipping**, getting the cargo to its specified destination. The back office takes care of **billing**, submitting invoices according to the pricing in the **customer's** agreement."

Intuitive, refinable in later iterations, possibly replaceable entirely — but already aiding MODEL-DRIVEN DESIGN and contributing to the UBIQUITOUS LANGUAGE.

## Worked Example — New Feature: Allocation Checking (integrating a foreign system)

**Requirement**: sales runs separate software for yield management, allocating how much cargo of each type to book (by goods type, origin, destination, or any category name they choose) — to stop profitable business being crowded out, while avoiding underbooking (unused capacity) and excessive overbooking (bumping cargo often enough to hurt customer relationships). Bookings must now be checked against these allocations.

**Step 1 — ANTICORRUPTION LAYER (Ch 14), named from our side.** Rather than a general translation mechanism, define a SERVICE per allocation function needed, implemented by a class named for its responsibility *in our system*: **`Allocation Checker`**. A lower-level `Sales Management System Interface` may still handle the machinery of talking to the other program, but it isn't responsible for translation and stays hidden behind the Allocation Checker, so it doesn't appear in the domain design. Other integrations (e.g. using their customer database) would get their own translator.

**Step 2 — reabstract, don't conform: ENTERPRISE SEGMENT.** To answer "How much of this type of Cargo may be booked?" we need a notion of Cargo "type," which our model lacks. The lazy path is to pass a collection of the other system's category-keyword strings. Instead, **enrich our model** — brainstorm with a domain expert, and borrow the **ENTERPRISE SEGMENT** analysis pattern (Fowler 1996, *Analysis Patterns*): *a set of dimensions that define a way of breaking down a business* — goods type, origin, destination, and time dimensions such as month-to-date. `Enterprise Segment` enters our model as an additional VALUE OBJECT, derived per Cargo.

The `Allocation Checker` translates between `Enterprise Segment`s and the external category names. The `Cargo Repository` gains a query based on `Enterprise Segment` — and notably **answers with a count, not a collection of instances.**

**Step 3 — shift the two leaked responsibilities to the Allocation Checker.** It was unclear how the Booking Application derived the Enterprise Segment, and the acceptance rule didn't belong there. Changing the Allocation Checker's interface separates the two SERVICES and makes the interaction explicit.

**The resulting constraint** is narrow and acceptable: the Sales Management System must not use dimensions the Allocation Checker can't turn into Enterprise Segments. Without ENTERPRISE SEGMENT, the equivalent constraint would force the sales system to use only dimensions expressible as Cargo Repository queries — feasible, but *the sales system spills into other parts of the domain*. As designed, the Cargo Repository only handles Enterprise Segment, and **changes in the sales system ripple only as far as the Allocation Checker**, which was conceived as a FACADE anyway.

**Performance tuning behind the interface**: two message exchanges per allocation check. The second (does the sales system accept this cargo?) is irreducible. The first (derive the Enterprise Segment) rests on relatively static data and behavior — so it can be cached and relocated onto the Allocation Checker's server, halving messaging overhead. The price: more complexity and duplicated data to keep current. *"But when performance is critical in a distributed system, flexible deployment can be an important design goal."*

**The final design question — why not let `Cargo` derive its own Enterprise Segment?** At first glance elegant, since Cargo holds the data. But **Enterprise Segments are defined arbitrarily, to divide along lines useful for business strategy.** The same ENTITIES could be segmented differently for different purposes: this segment is for *booking allocation*; tax accounting could use a completely different one; and even the allocation segment changes if the sales system is reconfigured for a new strategy. Cargo would have to know about the Allocation Checker — well outside its conceptual responsibility — and would carry methods for deriving specific segment types.

> **The responsibility for deriving this value lies properly with the object that knows the rules for segmentation, rather than the object that has the data to which those rules apply.**

(Those rules could later be split into a separate STRATEGY object passed to a Cargo — beyond current requirements, but not a disruptive change.)

## Key Takeaways
1. Ask a domain expert for identity schemes rather than inventing them — the company's existing customer ID and the natural key for Handling Events both came from conversation, not analysis.
2. An ENTITY whose identity is borrowed from its owner usually belongs *inside* that owner's AGGREGATE and needs no REPOSITORY.
3. Decide AGGREGATE membership by asking whether the thing has meaning apart from its owner — that single question moved `Handling Event` out and kept `Delivery History` in.
4. Create REPOSITORIES from application requirements, not from the list of roots; add them when a requirement appears.
5. Cross-check design decisions by walking real scenarios; the PROTOTYPE walkthrough is what proves the AGGREGATE boundary was drawn correctly.
6. Let contention requirements drive refactoring — replacing a collection with a REPOSITORY query decoupled two AGGREGATES' transactions.
7. Good AGGREGATE boundaries confine significant design changes; the alternative Cargo design touched nothing outside its boundary.
8. Name MODULES so the team can tell the business's story with them; never partition by pattern or by technical category.
9. Wrap foreign systems in an ANTICORRUPTION LAYER named for *your* responsibility, and take the chance to reabstract their concepts into your model.
10. Put a derivation on the object that knows the *rules*, not the object that holds the *data*.

## Connects To
- **Ch 4 (Layered Architecture)**: the three application classes as coordinators.
- **Ch 5 (Model Expressed in Software)**: ENTITY/VALUE classification, association constraint, MODULES — and the infrastructure-driven packaging problem, here recurring as pattern-driven packaging.
- **Ch 6 (Life Cycle)**: AGGREGATES, FACTORIES, REPOSITORIES all combined; the "collection vs. query" trade-off.
- **Ch 9 (Making Implicit Concepts Explicit)**: SPECIFICATION, which `Delivery Specification` follows.
- **Ch 11 (Applying Analysis Patterns)**: ENTERPRISE SEGMENT, borrowed from Fowler's *Analysis Patterns* (1996).
- **Ch 14 (Maintaining Model Integrity)**: ANTICORRUPTION LAYER.
- **Gamma et al. 1995**: PROTOTYPE, FACADE, STRATEGY.
