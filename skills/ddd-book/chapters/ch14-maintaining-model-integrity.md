# Chapter 14: Maintaining Model Integrity

*(Opens Part IV: Strategic Design — context, distillation, large-scale structure)*

## Core Idea
**"Total unification of the domain model for a large system will not be feasible or cost-effective."** So decide *proactively* which parts unify and *pragmatically* recognize which don't. Draw explicit BOUNDED CONTEXTs, map them, and choose a named relationship pattern for every boundary — because the alternative isn't one clean model, it's silent corruption.

## The Opening Failure

Several teams building a major new system in parallel. The customer-invoicing team was ready to implement `Charge` when they found another team had already built one. Diligently, they reused it: added an "expense code," reused the "posted amount" attribute they'd have called "amount due" (*"what's in a name?"*), added a few methods and associations, ignored the many associations they didn't need. **Their module ran.**

Days later, the bill-payment module — which `Charge` had originally been written for — began producing charges nobody remembered entering, and crashed on the month-to-date tax report. The crash came from summing amount-deductible across the month's payments: the mystery records had no value in "percent deductible," though the data-entry application both required it and supplied a default.

> The problem was that these two groups had **different models**, but they did not realize it, and there were no processes in place to detect it. Each made assumptions about the nature of a charge that were useful in their context (billing customers versus paying vendors).

What they did after: created separate `Customer Charge` and `Supplier Charge` classes. *"The immediate problem having been solved, they went back to doing things just as before. Oh well."*

## Frameworks Introduced

- **BOUNDED CONTEXT**:
  > Explicitly define the context within which a model applies. Explicitly set boundaries in terms of **team organization**, **usage within specific parts of the application**, and **physical manifestations such as code bases and database schemas**. Keep the model strictly consistent within these bounds, but don't be distracted or confused by issues outside.
  - Definition of *context*: "whatever set of conditions must apply in order to be able to say that the terms in a model have a specific meaning."
  - What it buys: for teams inside, **clarity** — they know they must stay consistent with one model, and watch for fractures. For teams outside, **freedom** — "They don't have to walk in the gray zone, not using the same model, yet somehow feeling they should."
  - **"Cells can exist because their membranes define what is in and out and determine what can pass."**
  - **BOUNDED CONTEXTS are not MODULES.** When two sets of objects are recognized as different models they're almost always placed in separate MODULES, which does provide name spaces and demarcation. But MODULES also organize elements *within* one model and don't communicate an intent to separate CONTEXTS — and the separate name spaces MODULES create **inside** a BOUNDED CONTEXT actually make accidental model fragmentation *harder* to spot.

- **Recognizing splinters — two categories of damage:**
  - **Duplicate concepts** — two model elements representing the same concept. Every change must be made in two places with conversions; every new insight requires reanalyzing the other — *"except the reanalysis doesn't happen in reality,"* so you get two versions following different rules with different data. Plus team members must learn both, and how they're synchronized.
  - **False cognates** — *"slightly less common, but more insidiously harmful."* Two people using the same term (or object) think they mean the same thing and don't. Subtlest when both definitions relate to the same aspect of the domain but were conceptualized slightly differently. Result: teams stepping on each other's code, databases with weird contradictions, confused communication. (Named after the natural-language phenomenon: English speakers learning Spanish misuse *embarazada* — it means "pregnant," not "embarrassed." Oops.)
  - **The early warning is usually a confusion of language.** Coded interfaces not matching up is the obvious symptom; unexpected behavior the likely subtle one.

- **CONTINUOUS INTEGRATION**:
  > Institute a process of merging all code and other implementation artifacts frequently, with automated tests to flag fragmentation quickly. Relentlessly exercise the UBIQUITOUS LANGUAGE to hammer out a shared view of the model as the concepts evolve in different people's heads.
  - **Operates at two levels**: (1) integration of model *concepts* — by constant communication, most fundamentally by hammering out the UBIQUITOUS LANGUAGE; (2) integration of the *implementation* — by a systematic merge/build/test process that exposes splinters early.
  - Characteristics of effective processes: a step-by-step reproducible merge/build technique; automated test suites; **rules setting a reasonably small upper limit on the lifetime of unintegrated changes**; and — seldom formally included — constant exercise of the UBIQUITOUS LANGUAGE.
  - The reinforcing loop: "the integration of concepts smooths the way for the integration of the implementation, while the integration of the implementation proves the validity and consistency of the model and exposes splinters."
  - **Scope limit**: "do not make the job any bigger than it has to be. CONTINUOUS INTEGRATION is essential only *within* a BOUNDED CONTEXT." Neighboring-context issues, including translation, don't need the same pace.
  - Threshold: apply it within any BOUNDED CONTEXT larger than a two-person task. Fragmentation starts with as few as three or four people.
  - It also provides a **safety net against overcautious behavior** — developers duplicating functionality because they fear breaking existing code.

- **CONTEXT MAP**:
  > Identify each model in play on the project and define its BOUNDED CONTEXT. **This includes the implicit models of non-object-oriented subsystems.** Name each BOUNDED CONTEXT, and make the names part of the UBIQUITOUS LANGUAGE.
  >
  > Describe the points of contact between the models, outlining explicit translation for any communication and highlighting any sharing.
  >
  > **Map the *existing* terrain. Take up transformations later.**
  - It "is in the overlap between project management and software design." Boundaries naturally follow team organization: people who work closely share a context; people on different teams — or on the same team who don't talk — split off. **Physical office space matters too**; team members at opposite ends of a building, let alone different cities, will probably diverge without extra integration effort.
  - Form doesn't matter (diagrams, text, or just shared discussion), but the MAP **must be shared and understood by everyone**, must name each context, and must make points of contact and their natures clear.
  - **On finding an entangled, inconsistent splinter**: *"Put a dragon on the map and finish describing everything."* Then, with an accurate global view, address the confusion. Until you have an unambiguous map placing all work in some context with explicit relationships, **change only the outright contradictions.** And: *"don't change the map until the change in reality is **done**."*
  - **Language discipline**: Don't say, "George's team's stuff is changing, so we're going to have to change our stuff that talks to it." Say, *"The `Transport Network` model is changing, so we're going to have to change the **translator** for the `Booking context`."*
  - **Testing at the boundaries**: contact points are particularly important to test. Tests compensate for translation subtleties and the lower communication level at boundaries, acting as an early warning system — "especially reassuring in cases where you depend on the details of a model you don't control." *"Trust, but verify."*

## The Seven Relationship Patterns

| Pattern | Situation | Core prescription |
|---|---|---|
| **SHARED KERNEL** | Two teams, closely related applications; full CONTINUOUS INTEGRATION too costly (skill, politics, or team size) | Designate a subset of the model (plus its code and database design) that both teams agree to share. **It has special status and shouldn't be changed without consulting the other team.** Integrate a functional system frequently, but less often than internal CI (e.g. daily CI → weekly kernel merge), **running the tests of both teams**. |
| **CUSTOMER/SUPPLIER DEVELOPMENT TEAMS** | Upstream feeds downstream; dependencies go one way; different user communities, possibly different tool sets | Establish a clear customer/supplier relationship. **In planning sessions, make the downstream team play the customer role to the upstream team.** Negotiate and budget tasks for downstream requirements so commitments and schedule are understood. **Jointly develop automated acceptance tests validating the expected interface, and add them to the upstream team's CI suite.** During the iteration, downstream members must be available to upstream developers just as conventional customers are. |
| **CONFORMIST** | Upstream/downstream where **upstream has no motivation to serve downstream** — and the upstream design quality/style is tolerable | **Eliminate the complexity of translation by slavishly adhering to the model of the upstream team.** You share their UBIQUITOUS LANGUAGE; the supplier is in the driver's seat, so make communication easy for them. |
| **ANTICORRUPTION LAYER** | A large interface with a legacy or external system whose model would otherwise corrupt yours | **Create an isolating layer to provide clients with functionality in terms of their own domain model.** The layer talks to the other system through its existing interface, requiring little or no modification to it, and internally translates in both directions. |
| **SEPARATE WAYS** | Two feature sets with **no indispensable relationship** | **Declare a BOUNDED CONTEXT to have no connection to the others at all**, allowing developers to find simple, specialized solutions within this small scope. Features can still be organized in middleware or the UI layer, but no shared logic and an absolute minimum of data transfer — preferably none. |
| **OPEN HOST SERVICE** | Your subsystem is in high demand; a custom translator per consumer is bogging the team down | **Define a protocol that gives access to your subsystem as a set of SERVICES. Open the protocol so all who need to integrate can use it.** Enhance and expand it for new requirements — except when a single team has idiosyncratic needs, where a one-off translator keeps the shared protocol simple and coherent. |
| **PUBLISHED LANGUAGE** | Multiparty exchange where no participant's model should be the medium | **Use a well-documented shared language that can express the necessary domain information as a common medium of communication, translating as necessary into and out of that language.** |

### Notes on the relationship patterns

- **SHARED KERNEL is a balance.** It can't be changed as freely as other parts of the design; decisions require consultation; automated test suites must be integrated so both teams' tests pass on any change. It's often the CORE DOMAIN, some GENERIC SUBDOMAINS, or both. **The goal is to *reduce* duplication, not eliminate it** (eliminating it would mean one BOUNDED CONTEXT).
- **CUSTOMER/SUPPLIER has two crucial elements**: (1) the relationship must genuinely be customer-and-supplier, **with the customer's needs paramount** — in contrast to "the poor-cousin relationship that often emerges, in which the downstream team has to come begging"; (2) there must be an automated test suite that lets upstream change code without fear and lets downstream stop monitoring upstream. *"In a relay race, the forward runner can't be looking backward all the time… He or she has to be able to trust the baton carrier to make the handoff precisely."* It succeeds far more often when both teams work under the same management, or when they're in different companies genuinely in those roles.
- **CONFORMIST vs. SHARED KERNEL**: both have an overlapping same-model area, an additively extended area, and an unaffected area. **The difference is decision-making and process** — SHARED KERNEL is collaboration between tightly coordinating teams; CONFORMIST deals with a team not interested in collaboration.
- **"Following isn't always bad."** With an off-the-shelf component that has a large interface, you should typically CONFORM. *"If it is good enough to give you value, there is probably knowledge crunched into its design. Within its narrow sphere, it may well be much more advanced than your own understanding… In effect, **you could be dragged into a better design.**"* When the interface is small, translation is viable; when it's large, follow the leader.
- **CONFORMIST is "very unappealing emotionally, which is why we choose it less often than we probably should."** And it must be done **wholeheartedly**: extension only, no modification of the existing model.
- **The downstream team facing an indifferent upstream has exactly three paths**: abandon the upstream (SEPARATE WAYS), CONFORM, or build an ANTICORRUPTION LAYER. Which of the last two depends on the quality and style of the upstream design.
- The spectrum runs from cooperative to pessimistic: CONTINUOUS INTEGRATION → SHARED KERNEL → CUSTOMER/SUPPLIER → CONFORMIST → ANTICORRUPTION LAYER → SEPARATE WAYS.
- **OPEN HOST couples consumers to the host's model**, forcing other teams to learn the host's dialect — which is what motivates PUBLISHED LANGUAGE.
- **PUBLISHED LANGUAGE's key constraint**: *"do not equate the interchange language and the model of the host."* The published language must be stable, yet you need freedom to keep refactoring the host. Keeping them close reduces translation overhead (you may even make your host a CONFORMIST), but reserve the right to beef up the translation layer and diverge.

## Implementing an ANTICORRUPTION LAYER

**It is not a mechanism for sending messages to another system. It is a mechanism that translates conceptual objects and actions from one model and protocol to another.**

**Public interface**: usually a set of **SERVICES**, occasionally an ENTITY. Building a whole new layer "gives us an opportunity to **reabstract** the other system's behavior and offer its services and information to our system consistently with our model." It may not even make sense to represent the external system as a single component — use multiple SERVICES, each with a coherent responsibility *in terms of our model*.

**Internal structure** — FACADE + ADAPTER (Gamma et al. 1995) + translator:
- **FACADE** — an alternative interface simplifying access to a messy subsystem, exposing only the functionality you need. **It does *not* change the model of the underlying system; it must be written strictly in accordance with the other system's model, and it belongs in the other system's BOUNDED CONTEXT.** Otherwise you diffuse translation responsibility, overload the FACADE, or worst, create a third model belonging to neither context.
- **ADAPTER** — supports a SERVICE's interface and knows how to make equivalent requests of the other system or its FACADE. (Evans uses the term loosely: Gamma emphasizes conforming to a standard interface clients expect, whereas here *we* choose the adapted interface and the adaptee may not even be an object.)
- **Translator** — the actual conversion of conceptual objects or data, a distinct complex task placed in its own object. Lightweight, instantiated when needed, stateless, not distributed — it belongs with the ADAPTER(s) it serves.

**Additional considerations:**
- It can be **bidirectional**, with SERVICES on both interfaces, their own ADAPTERs, and potentially the same translators applied symmetrically.
- **Where to place communication links** is pragmatic: between FACADE and the other subsystem if you have no access; between ADAPTER and FACADE if the FACADE can be integrated directly (its protocol is presumably simpler); or the entire layer can live with the other subsystem. *"These are implementation and deployment decisions… They have no bearing on the conceptual role."*
- If you do have access to the other subsystem, **a little refactoring over there can make your job easier** — write more explicit interfaces for the functionality you'll use, starting with automated tests if possible.
- If the other subsystem is simple or has a clean interface, **you may not need the FACADE.**
- Add functionality **specific to the relationship of the two subsystems** — an audit trail for external-system use, or trace logic for debugging calls.
- If translation difficulty gets out of hand you may make model choices that keep you closer to the external system — carefully, selectively, without compromising model integrity. **If that seems the most natural solution for much of the important part of the problem, become a CONFORMIST instead.**
- It also works **between two subsystems of your own design** based on different models — particularly two contexts that have gone SEPARATE WAYS but still need some functional integration.

**The cautionary tale (the Great Wall).** It let the Chinese regulate commerce with neighbors while impeding invasion and unwanted influence, defining a boundary for two thousand years. **But its construction was immensely expensive and bankrupted at least one dynasty, probably contributing to its fall.** *"The benefits of isolation strategies must be balanced against their costs. There is a time to be pragmatic and make measured revisions to the model, so that it can fit more smoothly with foreign ones."* Integration can be very valuable, **but it is always expensive.**

## Worked Example — Booking Context (defining a BOUNDED CONTEXT from reality)

Looking at the project **as it is**, not as it ideally should be:

| Element | In or out | Why |
|---|---|---|
| Booking application team | **In** | Consumers of the model; they display and manipulate the objects even though they don't modify them. |
| Legacy cargo-tracking system | **Out** | A decision was made up front that the new model would depart from the legacy's. |
| The translation mechanism to legacy | **Out** (it *is* the boundary) | Owned by the legacy maintenance team. **"It is good that translation is out of CONTEXT."** It would be unrealistic to ask the legacy team to make real use of a model when their primary work is out of context. |
| Database schema | **In** | The modeling team controls it and has deliberately kept the O/R mapping straightforward, so the schema is driven by the model. |
| Voyage-scheduling team | **Out — and that's the finding** | The two teams were initiated together intending one unified system; they coordinate casually and occasionally share objects, but not systematically. **They are not in the same BOUNDED CONTEXT and do not realize it.** |

**"The most concrete gain in this particular case is probably realizing the risk of the informal sharing"** — they need to decide the cost/benefit trade-offs of sharing and put processes in place (SHARED KERNEL might suit), and in the meantime **stop trying to share code until some changes are made.**

## Worked Example — Two Contexts in a Shipping Application (translation in practice)

The `Routing Service` is a SERVICE encapsulating a mechanism behind an INTENTION-REVEALING INTERFACE of SIDE-EFFECT-FREE FUNCTIONS, characterized by ASSERTIONS: pass in a `Route Specification`, get back an `Itinerary` that satisfies it. Nothing is stated about **how**.

**Behind the curtain — Evans' own mistake, admitted:** *"Initially on the project on which this example is based, I was too dogmatic about the internals of the `Routing Service`. I wanted the actual routing operation to be done with an extended domain model… But the team working on the routing problem pointed out that, to make it perform well and to draw on well-established algorithms, the solution needed to be implemented as an optimized network, with each leg of a voyage represented as an element in a matrix. They insisted on a distinct model of shipping operations for this purpose. They were clearly right… and so, lacking any better idea, I yielded."*

Two BOUNDED CONTEXTS resulted, each with its own conceptual organization of shipping operations. **Only two translations were needed** — not a full mapping between the models:

1. `Route Specification` → **List of location codes**. Think about the meaning of the sequence: first in the list is the beginning of the path, which is forced through each location in turn to the last. So **origin and destination are first and last, with the customs clearance location (if any) in the middle.**
   - **Note the asymmetry**: the reverse translation would be *ambiguous*, because network traversal input allows any number of intermediate points, none specifically designated as a customs clearance point. Fortunately that direction isn't needed — *"but it gives a glimpse of why some translations are impossible."*
2. **List of `Node` IDs** → `Itinerary`. Look up `Node` and `Shipping Operation` objects via a REPOSITORY; break the Node list into departure/arrival pairs by `operationTypeCode`; each pair maps to one `Leg`:

```
departureNode.shippingOperation.vesselVoyageId → leg.vesselVoyageId
departureNode.shippingOperation.date           → leg.loadDate
departureNode.locationCode                     → leg.loadLocationCode
arrivalNode.shippingOperation.date             → leg.unloadDate
arrivalNode.locationCode                       → leg.unloadLocationCode
```

The implementation collapses to delegation:

```java
public Itinerary route(RouteSpecification spec) {
   Booking_TransportNetwork_Translator translator =
      new Booking_TransportNetwork_Translator();
   List constraintLocations = translator.convertConstraints(spec);
   // Get access to the NetworkTraversalService
   List pathNodes = traversalService.findPath(constraintLocations);
   Itinerary result = translator.convert(pathNodes);
   return result;
}
```

**The translator is the one object both teams have to work together to maintain.** It should be very easy to unit-test, and **it would be a particularly good idea for the teams to collaborate on a test suite for it. Other than that, they can go their separate ways.**

## Worked Example — Unifying an Elephant

Six blind men each describe the elephant they touched: a wall, a snake, a tree, a rope. *"Though each was partly in the right, / And all were in the wrong!"*

- **No integration needed** → it doesn't matter that the models aren't unified.
- **Some integration needed** → they may not have to agree on what an elephant is, **but they get a lot of value from merely recognizing that they don't agree.** *"This way, at least they don't unknowingly talk at cross-purposes."* With separate BOUNDED CONTEXTS established, they can work out how to communicate about the few aspects they care about in common — perhaps the elephant's location.
- **More sharing wanted** → unifying is hard. **"None of them is likely to give up his model and adopt one of the others. After all, the man who touched the tail *knows* the elephant is not like a tree."** So: **"Unifying multiple models almost always means creating a new model."**
- **First-pass unification (part-whole)** is the easy case — "an elephant is a wall, held up by tree trunks, with a rope at one end and a snake at the other." Adequate for some needs.
- **The hard case is two models looking at the same part differently.** If one man had said "snake" and another "fire hose" about the trunk, neither could accept the other's model — it contradicts his own experience. **They need a new abstraction combining the "aliveness" of a snake with the water-shooting function of a hose, while leaving out the inapt implications of both** (venomous fangs; detachability and storage in a fire truck).
- **The forcing function for depth**: *"If the elephant starts moving, the 'tree' theory is out, and our blind modelers may break through to the concept of 'legs.'"* New requirements force deeper models.
- **The unification principle**: *"Successful model unification, to a large extent, hinges on **minimalism**. An elephant trunk is both more and less than a snake, but **the 'less' is probably more important than the 'more.'** Better to lack the water-spewing ability than to have an incorrect poison-fang feature."*

## Worked Example — An Insurance Project Slims Down (SEPARATE WAYS)

A team set out to integrate everything a customer service agent or claims adjuster needed into one system. After a year: stuck — analysis paralysis plus a major up-front infrastructure investment, nothing to show an increasingly impatient management, and an overwhelming scope.

A new project manager forced everyone into a room for a week. They listed requirements, estimated difficulty and importance, ruthlessly chopped the difficult-and-unimportant, and ordered the rest. **"Many smart decisions were made in that room that week, but in the end, only one turned out to be important":**

> At some point it was recognized that **there were some features for which integration provided little added value.** For example, adjusters needed access to some existing databases, and their current access was very inconvenient. **But, although the users needed to have this data, none of the other features of the proposed software system would use it.**

Solutions: export a key report as HTML on the intranet; write a specialized query in a standard software package. Integrate by organizing links on an intranet page or buttons on the desktop. **They launched small projects attempting no more integration than launching from the same menu. Several valuable capabilities were delivered almost overnight.**

*"It could have gone that way, but unfortunately the team slipped back into old habits. They paralyzed themselves again. In the end, their only legacy turned out to be those small applications that had gone their SEPARATE WAYS."*

**The cost of SEPARATE WAYS**: it forecloses options. Continuous refactoring can eventually undo any decision, **but it is hard to merge models that have developed in complete isolation.** If integration turns out to be needed, translation layers will be necessary and may be complex — "of course, this is something you will face anyway."

## Worked Example — CML, a PUBLISHED LANGUAGE for chemistry

Innumerable programs catalog, analyze, and manipulate chemical formulas. Exchanging data was always difficult — almost every program used a different domain model, and most were written in languages like FORTRAN that don't express a model fully anyway. Sharing meant unraveling another system's database and inventing a translation scheme.

**Chemical Markup Language (CML)** (Murray-Rust et al. 1995) is an XML dialect developed and managed by a group representing academics and industry, able to describe chemical formulas of organic and inorganic molecules, protein sequences, spectra, and physical quantities.

**The payoff**: "tools can be developed that would never have been worth the trouble to write before, when they would have only been usable for one database" — e.g. the JUMBO Browser, a Java application creating graphical views of CML structures.

**The double advantage of building on XML** — "a sort of published meta-language": the learning curve is flattened by familiarity with XML; implementation is eased by off-the-shelf tools like parsers; and documentation is helped by the many books on handling XML.

**The DB2 counter-example.** Evans built a Btrieve interface for a Smalltalk product, implementing it against the client's own undocumented persistence abstractions. It worked and integrated smoothly, but: the lack of formal specification meant a lot of work to figure out requirements; there was no opportunity to reuse the component to migrate another application; **and the new software more deeply entrenched the company's model of persistence, making later refactoring even harder.** The better path: identify the *subset* of the DB2 interface actually in use and support that — DB2's interface is complex but **tightly specified and thoroughly documented**, the application already knew how to talk to it, and future redesign would have been constrained no further than before.

## Choosing Your Model Context Strategy

**Team decision or higher.** Teams must decide where to define contexts and what relationships to have — or at least the decisions must be propagated to and understood by everyone; often they involve agreements beyond your own team. *"On the merits, decisions should be based on the cost-benefit trade-off between the value of independent team action and the value of direct and rich integration. **In practice, political relationships between teams often determine how systems are integrated.**"* A technically advantageous unification may be impossible because of reporting structure; management may dictate an unwieldy merger. **"You won't always get what you want, but at least you may be able to assess and communicate something of the cost incurred, and take steps to mitigate it."**

**Putting ourselves in context.** We really *are* part of the primary context we work in, and that will be reflected in our CONTEXT MAP. "This isn't a problem if we are aware of the bias and are mindful of when we step outside the limits of that MAP's applicability."

### Transforming boundaries — the forces

| Favoring **larger** BOUNDED CONTEXTS | Favoring **smaller** BOUNDED CONTEXTS |
|---|---|
| Flow between user tasks is smoother when more is handled with a unified model | Communication overhead between developers is reduced |
| It is easier to understand one coherent model than two distinct ones plus mappings | CONTINUOUS INTEGRATION is easier with smaller teams and code bases |
| Translation between two models can be difficult (sometimes impossible) | Larger contexts may call for more versatile abstract models, requiring skills that are in short supply |
| Shared language fosters clear team communication | Different models can cater to special needs or encompass the jargon of specialized user groups, with their own dialects of the UBIQUITOUS LANGUAGE |

**Deep integration between contexts is impractical.** Integration is limited to those parts of one model that can be *rigorously stated in terms of the other* — and even that may take considerable effort. This makes sense when the interface between two systems will be small.

### The decision sequence

1. **Start with the easiest decisions — delineate the external systems.** Major legacy systems you're not immediately replacing, external service providers. **But be careful about assumptions**: it's convenient to treat each as its own BOUNDED CONTEXT, but most external systems only weakly meet the definition, because *a BOUNDED CONTEXT is defined by an **intention** to unify the model within certain boundaries.* Check whether the legacy team is well coordinated; **"it is not unusual to find semantic contradictions in different parts of such systems."**
2. **Relationships with external systems — three candidates.** First consider **SEPARATE WAYS** — *"Yes, you wouldn't have included them if you didn't need integration. But be really sure. Would it be sufficient to give the user easy access to both systems? Integration is expensive and distracting."* If essential, choose between **CONFORMIST** and **ANTICORRUPTION LAYER**:
   - CONFORMIST is unlikely to be practical for a major new system (*"after all, why are you building a new system?"*), but is appropriate for **peripheral extensions to a large dominant system** — lightweight decision-support tools written in Excel and the like. If your interface would be large, translation can easily be a bigger job than the functionality itself. There's still room for good design: if a discernible domain model lies behind the other system, **make it more explicit than it was in the old system — while strictly conforming.**
   - ANTICORRUPTION LAYER when your system is more than an extension, when the interface is small, or when the other system is very badly designed.
3. **The system under design.** Fewer than ten people on highly interrelated functionality → **one BOUNDED CONTEXT**. As the team grows, look for a SHARED KERNEL and break off relatively independent functionality into contexts of **fewer than ten people each**. If all dependencies between two run one direction → **CUSTOMER/SUPPLIER**. If two groups' mindsets clash so constantly that their modeling efforts conflict — from genuinely different needs, different background knowledge, or the management structure — and the cause can't or won't be changed → **SEPARATE WAYS**, with any needed translation layer developed and maintained *jointly* by the two teams as the single point of CONTINUOUS INTEGRATION. (Contrast external systems, where the ANTICORRUPTION LAYER accommodates the other system as-is with little support from the other side.)
   - **"Generally speaking, there is a correspondence of one team per BOUNDED CONTEXT. One team can maintain multiple BOUNDED CONTEXTS, but it is hard (though not impossible) for multiple teams to work on one together."**
4. **Catering to special needs with distinct models.** Local jargons may be very precise and tailored; standardizing enterprise-wide requires extensive training and analysis, and the new terminology may not serve as well as the finely tuned version they already had. Costs and risks of allowing SEPARATE WAYS here: loss of shared language reduces communication; extra integration overhead; duplication of effort. **"But perhaps the biggest risk is that it can become an argument against change and a justification for any quirky, parochial model."** The test question: ***how valuable is the particular jargon of this user group?*** — weighing independent team action against translation risk, and watching for terminology variations with no value. Sometimes a deep model emerges that unifies both languages — **but you can't plan on a deep model; "you just have to accept the opportunity when it arises, change your strategy, and refactor."**
5. **Deployment.** *"One of those boring tasks that are almost always a lot harder than they look."* CUSTOMER/SUPPLIER teams must coordinate to release versions tested together — both code and data migrations must work in those combinations. In a distributed system, keeping translation layers within a single process avoids multiple versions coexisting. **The feasibility of a deployment plan should feed back into the drawing of context boundaries**: with a translation layer, one context can be updated so long as a new translation layer presents the same interface; a SHARED KERNEL imposes a much greater coordination burden in development *and* deployment; SEPARATE WAYS can make life much simpler.

**The trade-off, summarized:** *"you will trade off the benefits of seamless integration of functionality against the additional effort of coordination and communication. You trade more independent action against smoother communication. More ambitious unification requires control over the design of the subsystems involved."*

## Transformations — Game Plans

**When your project is already under way** — the first step is to define BOUNDED CONTEXTS **according to the way things are now**. *"This is crucial. To be effective, the CONTEXT MAP must reflect the true practice of the teams, **not** the ideal organization."* Then tighten practices **around that current organization**: improve CONTINUOUS INTEGRATION within contexts, refactor stray translation code into ANTICORRUPTION LAYERS, name the existing contexts and get them into the UBIQUITOUS LANGUAGE. Only then consider changing the boundaries — in small pieces chosen pragmatically for most value at least effort and disruption.

**General rule**: *"breaking up CONTEXTS is pretty easy, but merging them or changing the relationships between them is challenging."*

### SEPARATE WAYS → SHARED KERNEL

1. **Evaluate the initial situation.** Be sure the two contexts are indeed *internally* unified before unifying them with each other.
2. **Set up the process** — decide how code will be shared and what the module naming conventions are. At least **weekly integration** of the kernel code, and **it must have a test suite. Set this up before developing any shared code** (the suite will be empty, so it should be easy to pass!).
3. **Choose a small subdomain** duplicated in both contexts but **not part of the CORE DOMAIN** — simple, relatively generic or noncritical, because this first merger establishes the process. Examine existing integrations and translations; choosing something already translated gives you a proven translation and thins the translation layer.
4. **Form a group of two to four developers drawn from both teams** to work out a shared model. Three approaches: adopt one model wholesale and refactor the other context to fit (retaining the coherence of a model developed as a unit); choose piece by piece (best of both, taking care not to end up with a jumble); or **find a new, deeper model capable of assuming both responsibilities**. Whatever the derivation, it must be ironed out in detail — including **the hard work of identifying synonyms and mapping terms not already being translated** — and the joint team outlines a basic set of tests.
5. **Developers from either team implement it**, reconvening the group if the model runs into problems.
6. **Developers of each team integrate with the new SHARED KERNEL.**
7. **Remove translations that are no longer needed.**

Then repeat steps 3–7 in subsequent iterations, taking on more complicated subdomains, multiple at once, and eventually CORE DOMAIN subdomains. **Note**: when the two models have conformed to different user communities' specialized jargon, **defer merging those** unless a breakthrough gives you a language capable of superseding both. *"An advantage of a SHARED KERNEL is that you can have some of the advantages of CONTINUOUS INTEGRATION while retaining some of the advantages of SEPARATE WAYS."*

**The alternative worth considering first**: if one model is definitely preferred, **shift toward it without integrating** — systematically transfer full responsibility for subdomains by refactoring applications to call the favored context's model and enhancing it as needed. No ongoing integration overhead, redundancy eliminated, and potentially the favored context takes over completely.

### SHARED KERNEL → CONTINUOUS INTEGRATION

*"This is not just a matter of resolving the model differences. You are going to be changing team structures and ultimately the language people speak."*

1. **Prepare the people first.** Ensure all CONTINUOUS INTEGRATION processes (shared code ownership, frequent integration) are in place on **each team separately**, and **harmonize integration procedures** so everyone does things the same way.
2. **Start circulating team members between teams** — creating a pool of people who understand both models and beginning to connect the two teams.
3. **Clarify the distillation of each model individually** (Ch 15).
4. **Begin merging the core domain into the SHARED KERNEL.** Several iterations; temporary translation layers may be needed between newly shared and not-yet-shared parts. **Once into merging the CORE DOMAIN, go pretty fast — it is a high-overhead phase, fraught with errors, and should be shortened as much as possible, taking priority over most new development. But don't take on more than you can handle.**
   - Merging the CORE: adopt one model and modify the other, or create a new model of the subdomain. **Watch out if the two models have been tailored to distinct user needs** — you may need both models' specialized power, calling for a deeper model superseding both. Very difficult, "but if you are committed to the full merger… you no longer have the option of multiple dialects." **Be careful that the clarity doesn't come at the cost of your ability to address your users' specialized needs.**
5. **Increase integration frequency to daily and finally to CONTINUOUS INTEGRATION** as the kernel grows.
6. End state: one large team, or two smaller teams sharing a code base they integrate continuously and trading members back and forth frequently.

### Phasing Out a Legacy System

Setting: an old system used daily, recently supplemented by modern systems communicating through an ANTICORRUPTION LAYER.

**First decide on a testing strategy.** Automated unit tests for new functionality, plus the special needs of phase-out — some organizations run new and old in parallel for a period.

Per iteration:
1. Identify specific legacy functionality that could be added to one of the favored systems **within a single iteration**.
2. Identify additions required in the ANTICORRUPTION LAYER.
3. Implement.
4. Deploy.

Sometimes equivalent functionality takes more than one iteration, "but still plan the new functions in small, iteration-sized units, only waiting multiple iterations for deployment." Deployment usually requires bigger releases — user training, a successful parallel period, logistics.

Once running in the field:
5. Identify and remove any unnecessary parts of the ANTICORRUPTION LAYER.
6. Consider excising the now-unused legacy modules — **"though this may not turn out to be practical. Ironically, the better designed the legacy system is, the easier it will be to phase it out. But badly designed software is hard to dismantle a little at a time."** It may be best to ignore unused parts until the whole thing can be switched off.

Repeat. **The ANTICORRUPTION LAYER will alternately shrink *and* swell** as combinations change the interdependence. All else equal, migrate first the functions that lead to smaller ANTICORRUPTION LAYERS — "but other factors are likely to dominate, and you may have to live with some hairy translations during some transitions."

### OPEN HOST SERVICE → PUBLISHED LANGUAGE

1. **If an industry-standard language is available, evaluate it and use it if at all possible.**
2. If none, sharpen up the **CORE DOMAIN** of the host system (Ch 15).
3. Use the CORE DOMAIN as the basis of an interchange language, **using a standard interchange paradigm such as XML if at all possible.**
4. **Publish** the new language to all involved in the collaboration (at least).
5. If a new system architecture is involved, publish that too.
6. Build translation layers for each collaborating system.
7. Switch over.

Additional collaborators should then be able to enter with minimal disruption.

## Anti-patterns
- **Reusing a class across an unrecognized model boundary** — the opening `Charge` story; and generally, **"code reuse between BOUNDED CONTEXTS is a hazard to be avoided."**
- **Fixing the symptom and going back to old habits** — separate `Customer Charge` / `Supplier Charge` without changing the process that let the collision happen.
- **Ambitious total unification** — the risks: too many legacy replacements at once; coordination overhead exceeding the team's abilities; specialized applications forced onto models that don't satisfy them (pushing behavior elsewhere); and conversely, satisfying everyone with one model producing **complex options that make the model difficult to use.**
- **Assuming primitive data is unambiguous across systems** — *"this problem tends to sneak up on us because we think that what we are transporting between systems is primitive data, whose meaning is unambiguous and must be the same on both sides. **This assumption is usually wrong.**"* Subtle differences arise from how data are associated in each system.
- **Low-level interfaces to external systems** — they take away the other system's model's power to explain the data and constrain values and relationships, while saddling you with interpreting primitives not expressed in your own model.
- **Half-hearted CONFORMIST** — modifying the existing model instead of extension-only.
- **Making the FACADE do translation** — it belongs in the other system's context and must follow the other system's model.
- **Equating the PUBLISHED LANGUAGE with the host's model** — freezes the host against refactoring.
- **Fragmenting a large CONTEXT because the model is hard to comprehend** — "This fragmentation leads to lost opportunities." If a large context addresses compelling integration needs and is feasible apart from model complexity, breaking it up may not be the answer. **Try distillation and large-scale structure first (Ch 15, Ch 16).**
- **Changing the CONTEXT MAP to reflect intentions rather than reality.**

## Key Takeaways
1. Accept that total unification is infeasible; the goal is *conscious* choice about what unifies and honest recognition of what doesn't.
2. Define each BOUNDED CONTEXT in terms of team organization, application usage, and physical artifacts — and keep the model strictly consistent inside while ignoring outside concerns.
3. Watch for duplicate concepts and false cognates; the earliest warning is confusion of language, not failing code.
4. Run CONTINUOUS INTEGRATION at both levels — merge/build/test *and* relentless exercise of the UBIQUITOUS LANGUAGE — but only within a context.
5. Draw the CONTEXT MAP of the terrain as it actually is, name every context into the UBIQUITOUS LANGUAGE, and change reality before you change the map.
6. Pick a named relationship pattern for every boundary; the spectrum trades cooperation cost against independence, and you rarely get to choose on technical merit alone.
7. Choose CONFORMIST more often than feels comfortable — a good component's model probably encodes knowledge you don't have.
8. Build ANTICORRUPTION LAYERS as FACADE + ADAPTER + translator, and remember the Great Wall: isolation has a price that can bankrupt you.
9. Ask hard whether integration is needed at all; SEPARATE WAYS delivered the insurance project's only surviving value.
10. Test at every context boundary — it's the early warning system for models you don't control.
11. When merging contexts, start with a non-core subdomain, set up the process and test suite *before* sharing code, and defer merging models tailored to distinct user jargons.
12. Phase out legacy in iteration-sized units, expecting the ANTICORRUPTION LAYER to swell before it shrinks.

## Connects To
- **Ch 2 (Ubiquitous Language)**: this chapter supplies what Ch 2 deferred — how multiple models and dialects coexist; context names enter the LANGUAGE.
- **Ch 4 (Isolating the Domain)**: "other kinds of isolation" — the forward reference to BOUNDED CONTEXT and ANTICORRUPTION LAYER.
- **Ch 6 (Life Cycle)**: when the database belongs to a legacy or external system, two domain models coexist in one system.
- **Ch 7 (Extended Example)**: the `Allocation Checker` as an ANTICORRUPTION LAYER named from our side.
- **Ch 10 (Supple Design)**: SIDE-EFFECT-FREE FUNCTIONS make context interfaces easy to test — "one of the secrets to comfortable coexistence with other CONTEXTS."
- **Ch 12 (Design Patterns in the Model)**: the same `Routing Service` interface, here with a completely different implementation behind it.
- **Ch 15 (Distillation)**: CORE DOMAIN and GENERIC SUBDOMAINS — what a SHARED KERNEL usually contains, and a prerequisite step in two of the transformation game plans.
- **Ch 16 (Large-Scale Structure)**: the other answer to "this model is too complex to comprehend."
- **Gamma et al. 1995** (FACADE, ADAPTER), **Murray-Rust et al. 1995** (CML), **Extreme Programming** (the iteration planning game as the CUSTOMER/SUPPLIER mechanism).
