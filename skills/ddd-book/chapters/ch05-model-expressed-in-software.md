# Chapter 5: A Model Expressed in Software

## Core Idea
Four building blocks make a model expressible in code — constrained **Associations**, **ENTITIES** (defined by identity), **VALUE OBJECTS** (defined by attributes), and **SERVICES** (operations that aren't things) — organized into **MODULES** chosen for domain meaning, not technical convenience. Every one of these distinctions is a modeling decision that also happens to make implementation practical.

## Frameworks Introduced

- **Constraining Associations** — three ways to make an association tractable:
  1. **Impose a traversal direction** — a bidirectional association means both objects can only be understood together. Directionality often reflects real domain bias.
  2. **Add a qualifier**, effectively reducing multiplicity — and embedding a rule into the model.
  3. **Eliminate nonessential associations** — the ultimate simplification.
  - When to use: on every many-to-many or bidirectional association that early brainstorming produced.
  - Why it works: constraining a many-to-many *by direction* reduces its implementation to one-to-many — a **much** easier design. And it gives significance to whichever bidirectional associations remain: their retention now *conveys* that bidirectionality is a real domain characteristic.
  - Rule: **"For every traversable association in the model, there is a mechanism in the software with the same properties."** The mechanism can be a collection, a pointer, or an encapsulated database lookup — all consistent with the same model.

- **ENTITY (a.k.a. Reference Object)**:
  > When an object is distinguished by its identity, rather than its attributes, make this primary to its definition in the model. Keep the class definition simple and focused on life cycle continuity and identity. Define a means of distinguishing each object regardless of its form or history. Be alert to requirements that call for matching objects by attributes. Define an operation that is guaranteed to produce a unique result for each object, possibly by attaching a symbol that is guaranteed unique. … The model must define what it *means* to be the same thing.
  - When to use: when the object has continuity through a life cycle and distinctions independent of attributes that matter to the user. A person, a city, a car, a lottery ticket, a bank transaction.
  - How to model: **keep ENTITIES spare.** Strip to the most intrinsic characteristics — especially those that identify it or are commonly used to find or match it. Add only behavior essential to the concept, and only attributes required by that behavior. Push everything else into associated objects. ENTITIES then fulfill responsibilities largely by *coordinating the operations of objects they own*.
  - Designing the identity operation: language `==` compares memory location — **too fragile**. Every DB retrieval and every network transmission creates a new instance and loses that identity. Options, in order of preference: a genuinely unique natural key (watch for exceptions — newspapers by name+city+date break on extra editions and name changes); an **immutable** assigned ID symbol; an externally issued identifier (SSN — but children and nonresidents lack one, and privacy objections are real; phone numbers get shared, changed, reassigned).
  - Key insight: **"Identity is not intrinsic to a thing in the world; it is a meaning superimposed because it is useful."** The same real-world thing may or may not be an ENTITY.
  - Note: a model ENTITY is *not* a Java "entity bean." Most ENTITIES are ordinary objects.

- **VALUE OBJECT**:
  > When you care only about the attributes of an element of the model, classify it as a VALUE OBJECT. Make it express the meaning of the attributes it conveys and give it related functionality. Treat the VALUE OBJECT as immutable. Don't give it any identity and avoid the design complexities necessary to maintain ENTITIES.
  - When to use: anything you care about for *what* it is, not *who* or *which* it is.
  - How: the attributes should form a conceptual whole (Ward Cunningham's **WHOLE VALUE** pattern) — street, city, and postal code belong to one Address, not three fields on Person.
  - VALUE OBJECTS may be assemblages of other VALUES (a window style + height + width, combined into walls) and may even *reference* ENTITIES (a scenic `Route` from San Francisco to L.A. is a VALUE even though the two cities and the highway are ENTITIES).
  - Design freedom from having no identity: **copying, sharing, immutability** are now purely technical choices. FLYWEIGHT (Gamma et al. 1995) becomes available — one shared electrical-outlet instance pointed at a hundred times.
  - Restrict sharing to when: saving space/object count in the database is critical; communication overhead is low (centralized server); and the shared object is **strictly immutable**.
  - **When to allow mutability**: the VALUE changes frequently; object creation/deletion is expensive; replacement would disturb clustering; there is little sharing anyway. **If a VALUE's implementation is mutable, it must not be shared.** Design VALUES immutable whenever you can.
  - Rule on associations: bidirectional associations between two VALUE OBJECTS **make no sense** — without identity, "points back to the same object" is meaningless. If your model seems to need one, **rethink the decision to call it a VALUE**; it may have an unrecognized identity.

- **SERVICE**:
  > When a significant process or transformation in the domain is not a natural responsibility of an ENTITY or VALUE OBJECT, add an operation to the model as a standalone interface declared as a SERVICE. Define the interface in terms of the language of the model and make sure the operation name is part of the UBIQUITOUS LANGUAGE. Make the SERVICE stateless.
  - Three characteristics of a good SERVICE:
    1. The operation relates to a domain concept that is not a natural part of an ENTITY or VALUE OBJECT.
    2. The interface is defined in terms of other elements of the domain model.
    3. The operation is **stateless** — any client can use any instance without regard to that instance's history. (It may read and even change globally accessible information; it just holds no state of its own affecting its behavior.)
  - Naming: named for an **activity — a verb rather than a noun**. Parameters and results should be domain objects.
  - Caveat: **"the more common mistake is to give up too easily on fitting the behavior into an appropriate object, gradually slipping toward procedural programming."** Use SERVICES judiciously; don't strip ENTITIES and VALUES of all behavior.
  - Granularity benefit: medium-grained stateless SERVICES are easier to reuse, avoid inefficient fine-grained messaging in distributed systems, and stop domain knowledge from leaking into the application/UI layer where coordination would otherwise happen.
  - Access: don't over-engineer. A SINGLETON (Gamma et al. 1995) or a "doer" object is a fine delivery mechanism; J2EE/CORBA publishing is overkill when the motivation is just logical separation.

- **MODULE (a.k.a. Package)**:
  > Choose MODULES that tell the story of the system and contain a cohesive set of concepts. This often yields low coupling between MODULES, but if it doesn't, look for a way to change the model to disentangle the concepts, or search for an overlooked concept that might be the basis of a MODULE that would bring the elements together in a meaningful way. Seek low coupling in the sense of concepts that can be understood and reasoned about independently of each other. …
  >
  > Give the MODULES names that become part of the UBIQUITOUS LANGUAGE. MODULES and their names should reflect insight into the domain.
  - Why it works: **cognitive overload is the primary motivation for modularity**, not technical metrics. High cohesion / low coupling apply to *concepts*, not just code. "If your model is telling a story, the MODULES are chapters."
  - Trade-off rule: when conceptual clarity and technical coupling conflict, **go with conceptual clarity**, accepting more inter-module references or occasional ripple effects. Developers can handle that if they understand the story the model tells.
  - Agile MODULES: MODULES must coevolve with the model, but rarely do — refactoring them is disruptive to the team and to source control, so structure and names lag the classes. Early mistakes cause high coupling, which makes refactoring harder, which increases inertia. Only overcome by biting the bullet and reorganizing based on where the trouble actually is.

- **Four rules of thumb for mixing non-object paradigms**:
  1. **Don't fight the implementation paradigm.** There's always another way to think about a domain — find concepts that fit.
  2. **Lean on the UBIQUITOUS LANGUAGE.** Consistent naming across tools keeps parts of the design from diverging even without a rigorous connection.
  3. **Don't get hung up on UML.** Better a nonstandard drawing or plain English than distorting the model to fit what's easy to draw.
  4. **Be skeptical.** Having rules doesn't mean you need a rules engine. Multiple paradigms complicate matters enormously — exhaust the dominant paradigm first.

## Key Concepts
- **ENTITY / Reference Object** — an object defined primarily by identity, with continuity through a life cycle.
- **VALUE OBJECT** — an object representing a descriptive aspect of the domain with no conceptual identity.
- **SERVICE** — a stateless standalone operation in the model, named for an activity, with no encapsulated state.
- **MODULE / Package** — a named grouping of model concepts that tells part of the domain's story.
- **WHOLE VALUE** — Ward Cunningham's pattern: a VALUE's attributes must form a conceptual whole.
- **FLYWEIGHT** — sharing one immutable instance in place of many identical copies.
- **Denormalization** — storing multiple copies of the same data so it clusters on disk with each owning ENTITY.
- **Qualified association** — an association narrowed by a key, reducing multiplicity and embedding a rule.
- **Modeling paradigm** — objects, logic/rules, workflow; MODEL-DRIVEN DESIGN needs *expressive implementation* in whichever is chosen.

## Mental Models
- **Ask "does the user *care* if this is the same one?"** — Evans' rephrasing of the metaphysical identity question into a practical modeling test. (Am I the same person I was at age five? Wrong question. *Does the application care?*)
- **"Is Address a VALUE OBJECT? Who's asking?"** — the same real-world concept flips category by context:
  - *Mail-order company*: needed for card confirmation and parcel addressing; two roommates sharing an address needn't be noticed → **VALUE OBJECT**.
  - *Postal service* organizing delivery routes: addresses sit in a hierarchy of regions/cities/zones/blocks and inherit their zip code from the parent; reassigning a zone moves all of them → **ENTITY**.
  - *Electric utility*: two roommates each ordering service must be recognized as one destination → **ENTITY** (or make a "dwelling" ENTITY with an address attribute, restoring Address to a VALUE).
- **Think of an ENTITY as a thread of continuity, not a bag of attributes.** Two deposits of the same amount to the same account on the same day are distinct transactions; their *amounts* are interchangeable money VALUES.
- **Two objects can share an identity without sharing attributes or even a class** — reconciling a check register against a bank statement is exactly the task of matching same-identity transactions recorded by different people on different dates.
- **Avoid unnecessary constraints in a model** so developers stay free to do purely technical tuning; state the *essential* constraints explicitly so tuning can't change meaningful behavior.
- **Treat MODULES as a communications mechanism**: putting classes together tells the next developer to think about them together. "Now let's talk about the 'customer' module" should work in a conversation with a business expert.

## Code Examples

Associations in a brokerage account — same model, two implementations:

```java
public class BrokerageAccount {
    String accountNumber;
    Customer customer;
    Set investments;
    public Customer getCustomer() { return customer; }
    public Set getInvestments()   { return investments; }
}
```

```java
public class BrokerageAccount {
  String accountNumber;
  String customerSocialSecurityNumber;
  public Customer getCustomer() {
    String sqlQuery = "SELECT * FROM CUSTOMER WHERE"
      + "SS_NUMBER='" + customerSocialSecurityNumber + "'";
    return QueryService.findSingleCustomerFor(sqlQuery);
  }
  public Set getInvestments() {
    String sqlQuery = "SELECT * FROM INVESTMENT WHERE"
      + "BROKERAGE_ACCOUNT='" + accountNumber + "'";
    return QueryService.findInvestmentsFor(sqlQuery);
  }
}
```

Now **qualify** the association — one investment per stock symbol — which embeds a business rule:

```java
public class BrokerageAccount {
  String accountNumber;
  Customer customer;
  Map investments;
  public Investment getInvestment(String stockSymbol) {
    return (Investment) investments.get(stockSymbol);
  }
}
```

- **What it demonstrates**: the model, not the storage mechanism, dictates the traversal contract; and discovering a constraint (one investment per stock — untrue if lots must be tracked) makes the model more precise *and* the implementation easier to maintain.

Java package imports — convention that communicates MODULE intent:

```java
// Conventional: obscures that packageB is a cohesive unit
import packageB.ClassB1;
import packageB.ClassB2;
import packageB.ClassB3;

// Preferred: conveys the intent to depend on a MODULE
import packageB.*;
import packageC.*;
```

- **What it demonstrates**: mixing scales (classes depending on packages) is worth it to express a *conceptual* dependency. If one class genuinely needs a specific class in another package with no conceptual dependency between the MODULES, move the class or reconsider the MODULES.

## Reference Table — Partitioning SERVICES into Layers (funds transfer)

| Layer | Service | Responsibility |
|---|---|---|
| **Application** | Funds Transfer App Service | Digests input (e.g., an XML request); sends a message to the domain service for fulfillment; listens for confirmation; decides to send notification via infrastructure. |
| **Domain** | Funds Transfer Domain Service | Interacts with the necessary `Account` and `Ledger` objects, making appropriate debits and credits; supplies confirmation of the result (transfer allowed or not). |
| **Infrastructure** | Send Notification Service | Sends e-mails, letters, and other communications as directed by the application. |

The discriminator: **technical SERVICES should lack any business meaning at all.** Exporting transactions to a spreadsheet is an *application* service — "file formats" has no meaning in banking and no rules are involved. Transferring funds is a *domain* service — the term is meaningful banking language and it embeds real rules.

## Worked Example — Tuning a Database with VALUE OBJECTS

Databases place data at physical disk locations, and sophisticated ones cluster related data so it can be fetched in one physical operation. If an object is referenced by many others, some of those referrers won't be on the same page, forcing extra reads.

Because a VALUE OBJECT has no identity, you may freely **copy instead of share**: store a copy of the VALUE on the same page as *each* ENTITY that uses it. This is **denormalization** — used when access time matters more than storage space or maintenance simplicity. In a relational database, put the VALUE's columns in the owning ENTITY's table rather than associating to a separate table. In a distributed system, pass a copy of the whole VALUE to the other server rather than holding a slow remote reference.

The economy of copying vs. sharing flips by environment: copies can clog a system with object count; sharing can slow a distributed system, since a shared instance means a message back to the object for every interaction while a copy lives independently on the receiving machine.

This is the general rule at work: **defining VALUE OBJECTS and designating them immutable removes an unnecessary constraint, leaving developers free to do purely technical performance tuning without risk to meaningful behavior.**

## Anti-patterns
- **Assigning identity to every object** (as some frameworks do): the system must track it all, performance optimizations are ruled out, real analytical effort is spent defining meaningless identities — and worst, "taking on artificial identities is misleading. It muddles the model, forcing all objects into the same mold."
- **"Manager"/"doer" objects masquerading as model objects** — no state, no domain meaning beyond the operation they host. Better than corrupting a real model object, but the honest answer is a SERVICE.
- **Forcing an operation into an object that doesn't fit**: complex operations swamp a simple object, obscure its role, and — because they draw together many domain objects — create dependencies that tangle concepts which could have been understood independently.
- **Infrastructure-driven packaging (the four-tier project)**: a well-reasoned scheme (persistence / intrinsic behavior / application-specific behavior / public interface) that the framework required be split into four package sets named by tier. Result: every MODULE was multiplied by four, so developers avoided making MODULES and never refactored one; finding all the data and behavior of one conceptual class consumed the mental space that should have gone to modeling. The app shipped with **an anemic domain model** that basically fulfilled database-access needs, with behavior in a few SERVICES.
  - The two costs, stated generally: (1) if the framework's partitioning pulls apart the elements implementing a conceptual object, **the code no longer reveals the model**; (2) **there is only so much partitioning a mind can stitch back together** — if the framework uses it all up, developers lose the ability to chunk the model meaningfully.
  - Rule: *unless there is a real intention to distribute code on different servers, keep all the code implementing a single conceptual object in the same MODULE, if not the same object.* Distribution flexibility "just in case" is too great a sacrifice.
- **J2EE entity bean + session bean split** — data/access in one, business logic in the other, often in different packages. This directly negates encapsulating data with the logic that operates on it.
- **The immature-paradigm gamble** (Evans' early-1990s OODB project): the off-the-shelf infrastructure didn't scale, fine-grained object storage was far costlier than expected, and a tangle of interdependencies caused contention at low concurrency. They filled a large fraction of database capacity *with test data*. Months lost; a rare expert hired at his price. The lesson they extracted — **limit the web of relationships in a model; decouple closely interrelated aggregates** — foreshadows Ch 6.
- **Rules engine fracture**: a common outcome is an application split in two — static data storage in objects, and an ad-hoc rules application that has lost almost all connection with the object model. The rules become "little programs" rather than conceptual rules in the model.

## Key Takeaways
1. Constrain every association you can — impose direction, add a qualifier, or delete it — because each constraint both simplifies implementation and records domain insight.
2. Decide ENTITY vs. VALUE OBJECT deliberately; the answer depends on the application, not on the real-world thing.
3. Keep ENTITIES spare: identity, the attributes used to find/match them, and only essential behavior. Push the rest outward.
4. Never rely on language identity operators for ENTITY identity — define an operation that survives persistence, transmission, and archiving.
5. Make VALUE OBJECTS immutable by default; that single decision unlocks copying, sharing, FLYWEIGHT, and denormalization as free technical choices.
6. If you find yourself wanting a bidirectional association between two VALUES, you've probably misclassified one of them.
7. Model an operation as a SERVICE only after genuinely trying to place it on an ENTITY or VALUE — but do model it as a SERVICE rather than inventing a phony object.
8. Choose MODULES by the story they tell and name them into the UBIQUITOUS LANGUAGE; refactor them even though it hurts.
9. Resist technically driven packaging schemes; use packaging to separate the domain layer, then leave domain developers free.
10. Prefer objects for MODEL-DRIVEN DESIGN today (maturity, tooling, shared developer culture) — but MODEL-DRIVEN DESIGN needs *expressive implementation*, not objects specifically. If a tool can't express the model, reconsider the tool.

## Connects To
- **Ch 3 (Model-Driven Design)**: these four patterns are the points of direct correspondence between implementation and model — "if they do not map straightforwardly and obviously, clean up the code, go back and change the model, or both."
- **Ch 4 (Layered Architecture)**: SERVICES span all three upper layers; the domain/application/infrastructure discriminator is developed here.
- **Ch 6 (Life Cycle of a Domain Object)**: AGGREGATES (the "web of relationships" lesson), FACTORIES, REPOSITORIES — the supporting objects deliberately kept *out* of the model objects here.
- **Ch 9 (Making Implicit Concepts Explicit)**: modeling unconventional concepts (rules, processes, constraints) within the object paradigm before reaching for another one.
- **Ch 10 (Supple Design)**: declarative design; generated code should live in a separate package so it doesn't clutter what developers actually read.
- **Part IV (Strategic Design)**: packaging and breaking down big models at scale.
- **Gamma et al. 1995** (FLYWEIGHT, SINGLETON, FACADE), **Ward Cunningham** (WHOLE VALUE), **Larman 1998** (cohesion/coupling as patterns).
