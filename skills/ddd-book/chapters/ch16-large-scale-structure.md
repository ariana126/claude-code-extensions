# Chapter 16: Large-Scale Structure

## Core Idea
MODULES chunk a design into manageable bites, but there may be many of them, and modularity brings no *uniformity* — "a jumble of design decisions may be applied, each defensible but idiosyncratic." A **large-scale structure is a language that lets you discuss and understand the system in broad strokes**, so a developer can understand a part's role in the whole without knowing the whole's details.

> Devise a pattern of rules or roles and relationships that will span the entire system and that allows some understanding of each part's place in the whole — even without detailed knowledge of the part's responsibility.

Key properties: it usually spans more than one BOUNDED CONTEXT; **it is optional**; and **you can't represent most large-scale structures in UML, and you don't need to** — they shape and explain the model without appearing in it.

## The Opening Story

A Silicon Valley firm building a satellite communications simulator. A MODEL-DRIVEN DESIGN was going well; complexity drove decomposition into coherent MODULES of manageable size. **Now there were a *lot* of MODULES.** Which package holds a given aspect of functionality? Where does a new class go? What do some of these little packages really mean?

> They could tell a simple story of their simulation… **Every detail of that story was in the model, yet the broad arc of the story could not be seen.**
>
> Some essential concept from the domain was missing. But this time it was not a class or two missing from the object model, **it was a missing structure for the model as a whole.**

They rejected the gimmicks (an overview document, new class-diagram views) and instead imposed **layers** matching aspects of the communications system: a physical infrastructure layer able to transmit bits between nodes, a packet-routing layer, and others. **"These layers would outline their story of the system."**

Refactoring followed: MODULES redefined so as not to span layers; object responsibilities refactored so each object clearly belonged to one layer; **and conversely the definitions of the conceptual layers themselves refined based on hands-on experience applying them.** Layers, MODULES, and objects coevolved.

> These layers were not MODULES or any other artifact in the code. They were **an overarching set of rules that constrained the boundaries and relationships of any particular MODULE or object throughout the design, even at interfaces with other systems.**
>
> …People knew roughly where to look for a particular function. Individuals working independently could make design decisions that were broadly consistent with each other. **The complexity ceiling had been lifted.**

## Frameworks Introduced

- **EVOLVING ORDER**:
  > Let this conceptual large-scale structure evolve with the application, **possibly changing to a completely different type of structure along the way.** Don't overconstrain the detailed design and model decisions that must be made with detailed knowledge.
  - **The problem is not the existence of guiding rules, but rather the rigidity and source of those rules.** "If the rules governing the design really fit the circumstances, they will not get in the way but actually push development in a helpful direction, as well as provide consistency."
  - **The acknowledged trade-off**: "Individual parts have natural or useful ways of being organized and expressed that may not apply to the whole, so imposing global rules makes these parts less ideal. Choosing to use a large-scale structure favors **manageability of the model as a whole over optimal structuring of the individual parts.**" Mitigate by selecting the structure from actual experience and knowledge of the domain, and by avoiding over-constrictive structures.
  - **The upside beyond consistency**: "A really nice fit of structure to domain and requirements actually makes detailed modeling and design *easier*, by helping to quickly eliminate a lot of options" — and gives shortcuts to design decisions that could in principle be found at the object level, but in practice would take too long and yield inconsistent results.
  - **Applicability rule**: *"Large-scale structure should be applied when a structure can be found that greatly clarifies the system without forcing unnatural constraints on model development. Because an ill-fitting structure is worse than none, it is best not to shoot for comprehensiveness, but rather to find a minimal set that solves the problems that have emerged. **Less is more.**"* Not needed for systems simple enough to understand when broken into MODULES.
  - **On exceptions**: a structure "can be very helpful and still have a few exceptions, but those exceptions need to be flagged somehow, so that developers can assume the structure is being followed unless otherwise noted. **And if those exceptions start to get numerous, the structure needs to be changed or discarded.**"
  - It must **accommodate practical constraints** — designers may have no control over external or legacy subsystem models. Handle by changing the structure to fit them, by specifying how the application relates to externals, or by making the structure loose enough to flex around awkward realities.

- **SYSTEM METAPHOR**:
  > When a concrete analogy to the system emerges that captures the imagination of team members and seems to lead thinking in a useful direction, adopt it as a large-scale structure. Organize the design around this metaphor and **absorb it into the UBIQUITOUS LANGUAGE.** … But because all metaphors are inexact, **continually reexamine the metaphor for overextension or inaptness, and be ready to drop it if it gets in the way.**
  - It is *"a loose, easily understood, large-scale structure that is harmonious with the object paradigm."* Because it's only an analogy anyway, different models can map to it approximately — **which lets it apply across multiple BOUNDED CONTEXTS**, helping coordinate work between them.
  - **The firewall example, cutting both ways** (Ward Cunningham's): the metaphor influenced network architectures and shaped a whole product category — independently developed, somewhat interchangeable competing firewalls, readily grasped by novices, shared understanding across industry and customers. **Yet the analogy is inexact**: it led to software barriers that are sometimes insufficiently selective, impede desirable exchanges, and offer no protection against internal threats (wireless LANs are vulnerable). *"The clarity of the firewall has been a boon, but all metaphors carry baggage."*
  - **The honest caveat**: SYSTEM METAPHOR is popular because it's a core XP practice (Beck 2000), but *"few projects have found really useful METAPHORS, and people have tried to push the idea into domains where it is counterproductive. A persuasive metaphor introduces the risk that the design will take on aspects of the analogy that are not desirable… or that the analogy, while seductive, may not be apt."*
  - **"The 'naive metaphor' and why we don't need it."** Some in the XP community call the domain model itself the *naive metaphor*. But *"a mature domain model is anything but naive. In fact, 'payroll processing is like an assembly line' is likely a much more naive view than a model that is the product of many iterations of knowledge crunching with domain experts, and that has been proven by being tightly woven into the implementation of a working application."* **The term should be retired.** In XP's 12 practices, the role of SYSTEM METAPHOR can be fulfilled by a UBIQUITOUS LANGUAGE; augment that LANGUAGE with metaphors or other structures only when one fits well.

- **RESPONSIBILITY LAYERS**:
  > Look at the conceptual dependencies in your model and **the varying rates and sources of change** of different parts of your domain. If you identify natural strata in the domain, cast them as broad abstract responsibilities. **These responsibilities should tell a story of the high-level purpose and design of your system.** Refactor the model so that the responsibilities of each domain object, AGGREGATE, and MODULE fit neatly within the responsibility of one layer.
  - Unites two powerful principles: **layering** and **responsibility-driven design**. The variant that serves best is **RELAXED LAYERED SYSTEM** (Buschmann et al. 1996, p. 45), allowing components of a layer to access *any* lower layer, not just the one immediately below.
  - **Contrast with ad hoc layering**: laying out MODULE dependency diagrams so dependents appear above their dependencies "can make tracing dependencies easier — and sometimes makes some intuitive sense — **but doesn't give much insight into the model or guide modeling decisions. We need something more intentional.**"
  - **Three characteristics to look for and preserve** as layers get switched out, merged, split, and redefined:
    1. **Storytelling** — the layers should communicate the basic realities or priorities of the domain. **"Choosing a large-scale structure is less a technical decision than a business modeling decision."**
    2. **Conceptual dependency** — concepts in the upper layers should have meaning against the backdrop of the lower layers, while lower-layer concepts should be meaningful standing alone.
    3. **CONCEPTUAL CONTOURS** — if objects of different layers have different rates or sources of change, the layer accommodates the shearing between them.
  - **Keep it simple**: "going beyond four or possibly five becomes unwieldy. Having too many layers isn't as effective at telling the story, and the problems of complexity the large-scale structure was meant to solve will come back in a new form. **The large-scale structure must be ferociously distilled.**"

- **KNOWLEDGE LEVEL** (Fowler, "Accountability"; an application of **REFLECTION** — Buschmann et al. 1996 — to the domain layer):
  > *[Fowler]* A KNOWLEDGE LEVEL is a group of objects that describes how another group of objects should behave.
  >
  > *[Evans]* Create a distinct set of objects that can be used to describe and constrain the structure and behavior of the basic model. Keep these concerns separate as two "levels," one very concrete, the other **reflecting rules and knowledge that a user or superuser is able to customize.**
  - **Terminology mapping**: Fowler's *Knowledge Level* / *Operations Level* = POSA's *Meta Level* / *Base Level*.
  - **Not a layer.** "As much as it resembles layering, REFLECTION involves **mutual dependencies running in both directions**." (This is also why it is not a special case of RESPONSIBILITY LAYERS, especially the Policy layer — and why it **can coexist with most other large-scale structures**, providing an additional dimension of organization.)
  - **The reflection tools of the programming language are *not* for implementing the KNOWLEDGE LEVEL of a domain model** — those meta-objects describe the language constructs themselves. **The KNOWLEDGE LEVEL must be built of ordinary objects.**
  - **Two useful distinctions from ordinary REFLECTION**: (1) it focuses on the *application domain*; (2) **it does not strive for full generality** — "Just as a SPECIFICATION can be more useful than a general predicate, a very specialized set of constraints on a set of objects and their relationships can be more useful than a generalized framework. The KNOWLEDGE LEVEL is simpler and can communicate the specific intent of the designer."
  - **Use it sparingly.** "Like all powerful ideas, REFLECTION and KNOWLEDGE LEVELS can be intoxicating. It can unravel complexity by freeing operations objects from the need to be jacks-of-all-trades, **but the indirection it introduces does add some of that obscurity back in.** If the KNOWLEDGE LEVEL becomes complex… the users (or superuser) who configure it will end up needing the skills of a programmer — **and a meta-level programmer at that.**"
  - **Data migration problems don't disappear**: when a KNOWLEDGE LEVEL structure changes, existing operations-level objects must be dealt with; old and new may coexist, but careful analysis is needed either way.
  - **The burden on the designer**: "The design has to be robust enough to handle not only the scenarios presented in development, but **any scenario for which a user could configure the software in the future.**"

- **PLUGGABLE COMPONENT FRAMEWORK**:
  > Distill an ABSTRACT CORE of interfaces and interactions and create a framework that allows diverse implementations of those interfaces to be freely substituted. Likewise, **allow any application to use those components, so long as it operates strictly through the interfaces of the ABSTRACT CORE.**
  - Structure: high-level abstractions identified and shared across the breadth of the system; specialization in MODULES. **The central hub is an ABSTRACT CORE within a SHARED KERNEL** — but multiple BOUNDED CONTEXTS can lie behind the encapsulated component interfaces, which is especially convenient when components come from many sources or encapsulate preexisting software.
  - Components need not have divergent models: multiple components can live in one CONTEXT if the teams CONTINUOUSLY INTEGRATE, or share another SHARED KERNEL. A **PUBLISHED LANGUAGE** is another option for the hub's plug-in interface.
  - **A technical framework is only needed if it solves an essential technical problem** such as distribution or cross-application component sharing. **"The basic pattern is a conceptual organization of responsibilities. It can easily be applied within a single Java program."**
  - **Two serious downsides:**
    1. Very difficult to apply — requires precision in interface design and a model deep enough to capture the necessary behavior in the ABSTRACT CORE.
    2. **Applications have limited options.** Developers can specialize the model but can't change the ABSTRACT CORE without changing every component's protocol — so **"the process of continuous refinement of the CORE, refactoring toward deeper insight, is more or less frozen in its tracks."**
  - **Sequencing rule**: *"A PLUGGABLE COMPONENT FRAMEWORK should not be the first large-scale structure applied on a project, nor the second. The most successful examples have followed after the full development of multiple specialized applications."* The biggest obstacle is the maturity of understanding needed. (Fayad and Johnson 2000 survey attempts across several domains; "the success of such frameworks is a mixed story.")

## Reference — The Five Recurring Responsibility Layers

| Layer | The question it answers | Notes |
|---|---|---|
| **Potential** (a.k.a. Capability) | *What can be done? Never mind what we are planning to do — what **could** we do?* | The organization's resources, people, and their arrangement; vendor contracts also define potentials. Prominent in businesses with **large fixed capital investments** — transportation, manufacturing. |
| **Operation** | *What is being done? What have we managed to make of those potentials?* | Must reflect **the reality of the situation, not what we want it to be**. What we are *selling*, rather than what *enables* us to sell. Operational objects typically reference or are composed of Potential objects — **but a Potential object shouldn't reference the Operations layer.** |
| **Decision Support** | *What action should be taken, or what policy should be set?* | Analysis and decision making, based on information from lower layers; may use historical information to actively seek opportunities. Often implemented with data warehouse technology, making it a distinct BOUNDED CONTEXT in a CUSTOMER/SUPPLIER relationship with Operations — or deeply integrated. |
| **Policy** | *What are the rules and goals?* | Mostly passive, but constrains behavior in other layers. Sometimes a Policy is passed as an argument to a lower-level method; sometimes STRATEGY is applied. **Works well with Decision Support**, which provides the means to seek Policy's goals under Policy's constraints. |
| **Commitment** | *What have we promised?* | Has the nature of Policy (states goals directing future operations) *and* of Operations (commitments emerge and change as part of ongoing business activity). Prominent where potential is largely determined by current operations — financial services, insurance. |

**Notes on choosing:** In many existing systems in capital-intensive domains, Potential and Operations cover everything — they track the current situation and active plans and issue reports. *"But tracking is not always enough."* Decision Support is added above Operations when projects seek to guide users or automate decisions. **An intrinsic advantage of layers is that lower layers can exist without the higher ones**, facilitating phased introductions or higher-level enhancements on top of older operational systems.

Potential and Commitment **are not mutually exclusive** — a transportation company with many custom shipping services might use both. And for a domain unrelated to these, *"these layers might have to be completely original. Ultimately, you have to use your intuition, start somewhere, and let the ORDER EVOLVE."*

**On Policy layers implemented with rules engines**: this doesn't necessarily place them in a separate BOUNDED CONTEXT. *"In fact, the difficulty of coordinating such different implementation technologies can be eased by fastidiously using the same model across both. **When rules are written based on a different model than the objects they apply to, either the complexity goes way up or the objects get dumbed down to keep things manageable.**"*

## Worked Example — In Depth: Layering a Shipping System

The team has a MODEL-DRIVEN DESIGN and a distilled CORE DOMAIN, but is having trouble coordinating how the parts fit together.

**Discovering the strata.** Months steeped in shipping had revealed a natural stratification: *"It is quite reasonable to discuss transport schedules (the scheduled voyages of ships and trains) without referring to the cargoes aboard those transports. It is harder to talk about tracking a cargo without referring to the transport carrying it."* Two layers: **Operations** and its substrate, **Capability**.

- **Operations** — activities of the company, past, current, planned. `Cargo` is the obvious member (the focus of day-to-day activity), with `Route Specification` (delivery requirements) and `Itinerary` (the operational delivery plan) in its AGGREGATE, their life cycles tied to an active delivery.
- **Capability** — the resources the company draws upon. `Transit Leg` is the classic example: ships are scheduled to run with a certain capacity, which may or may not be fully utilized.
  - **Note the point-of-view dependence**: *"if we were focused on operating a shipping fleet, `Transit Leg` would be in the Operations layer. But the users of this system aren't worried about that problem."* (A company doing both, wanting them coordinated, might need two distinct layers — "Transport Operations" and "Cargo Operations.")

**The trickiest call — `Customer`.** In some businesses customers are transient, interesting while a package is delivered and then forgotten — that would make Customer purely operational for a consumer parcel service. **But this hypothetical company cultivates long-term relationships and most work is repeat business.** Given those *intentions of the business users*, `Customer` belongs in the potential layer.

> As you can see, **this was not a technical decision. It was an attempt to capture and communicate knowledge of the domain.**

**Consequence of the layering rule**: because `Cargo → Customer` can now only be traversed one way, the `Cargo` REPOSITORY needs a query finding all Cargoes for a Customer. *"There were good reasons to design it that way anyway, but with the imposition of the large-scale structure, it is now a requirement."*

**The third layer emerges after a few weeks of experimentation.** Both initial layers focus on situations or plans *as they are*; the `Router` isn't part of current realities or plans — it helps *change* those plans. Hence **Decision Support**: tools for planning and decision making, potentially automating some decisions (e.g. automatically rerouting Cargoes when a transport schedule changes). The `Router` SERVICE, helping a booking agent choose how to send a Cargo, sits squarely there.

**The one discordant element — and the refactoring it forces.** `Transport Leg` had an "is preferred" attribute, because the company prefers its own ships or those of companies it has favorable contracts with, biasing the `Router`. **"This attribute has nothing to do with 'Capability.' It is a policy that directs decision making."** Refactoring it out into a `Route Bias Policy` makes the policy explicit *and* makes `Transport Leg` more focused on the fundamental concept of transportation capability.

> **A large-scale structure based on a deep understanding of the domain will often push the model in directions that clarify its meaning.**

**How the structure affects ongoing design.** New requirement: routing restrictions for hazardous materials — certain materials barred from some transports or ports.

- **The appealing design without a structure**: give the responsibility to the object that owns both the `Route Specification` and the HazMat code — namely `Cargo`.
- **Why it can't be allowed**: the `HazMat Route Policy Service` itself fits Decision Support fine. **The problem is the dependency of `Cargo` (Operational) on `HazMat Route Policy Service` (Decision Support).** *"As long as the project is committed to these layers, this model cannot be allowed. It would confuse developers who expected the structure to be followed."*
- **The conforming design**: give the `Router` the responsibility for collecting appropriate policies before searching for a route — which means changing the `Router` interface to include the objects that policies might depend on.
- **Evans' honest verdict**: *"Now, this isn't necessarily a **better** design than the other. They both have pros and cons. **But if everyone on a project makes decisions in a consistent way, the design as a whole will be much more comprehensible, and that is worth some modest trade-offs on detailed design choices.**"*
- **And the escape hatch**: "If the structure is forcing many awkward design choices, then in keeping with EVOLVING ORDER, it should be evaluated and perhaps modified or even discarded."

**On notation**: the layer annotations are additional information imposed on UML for the reader's sake. *"If code is the ultimate design document for your project, it would be helpful to have a tool for browsing classes by layer or at least for reporting them by layer."*

## Worked Example — Employee Payroll and Pension (discovering a KNOWLEDGE LEVEL)

**The problem it addresses generally** — modeling accountability. Organizations define roles and relationships whose *rules vary greatly*: one company has a "department" headed by a "Director" reporting to a "Vice President"; another has a "module" headed by a "Manager" reporting to a "Senior Manager"; matrix organizations have people reporting to different managers for different purposes.

A typical application makes assumptions. When they don't fit, **users start using data-entry fields differently than intended; any behavior the application had misfires as users change the semantics; users develop workarounds or get the higher-level features shut off; they learn complicated mappings between their jobs and the software.** *"They would never be served well."* Later, developers discover the features' meanings were not what they seemed — differing by user community and situation — and changing anything without breaking those overlaid usages is daunting.

**Part 1 — the model tightens, then loosens, then finds a Type.**
1. **The old model** hard-wired the constraint that salaried employees get defined-benefit plans and hourly employees don't.
2. **Management decides office administrators should get defined benefit** — but they're paid hourly, and the model doesn't allow mixing.
3. **First proposal: remove the constraints.** Now each employee can be associated with either kind of plan. **Rejected by management** because it doesn't reflect company policy: *some* administrators could be switched and others not; or the janitor could be switched.
4. **The policy management wants enforced**: *"Office administrators are hourly employees with defined-benefit retirement plans."* This suggests the "job title" field now represents an important domain concept → refactor it into an explicit **`Employee Type`**.
5. Stated in the UBIQUITOUS LANGUAGE: *"An `Employee Type` is assigned to either `Retirement Plan` or either payroll. `Employees` are constrained by the `Employee Type`."* Access to edit `Employee Type` is restricted to a **superuser** who changes it only when company policy changes; ordinary personnel users change Employees or repoint them at a different Type.
6. Requirements satisfied. **"The developers sense an implicit concept or two, but it is just a nagging feeling at the moment. They don't have any solid ideas to pursue, so they call it a day."**

**Part 2 — recognizing the KNOWLEDGE LEVEL, and the second insight it unlocks.**
- Next morning, a developer closes in on the awkward point: **why were certain objects being secured while others were freely edited?** The cluster of restricted objects reminded him of KNOWLEDGE LEVEL — **and the existing model could already be viewed that way.** The restricted edits were the KNOWLEDGE LEVEL; the day-to-day edits the operational level. Everything above the line described types or long-standing policies; `Employee Type` effectively imposed behavior on `Employee`.
- **While he was sharing this, another developer had a second insight** — the clarity of the KNOWLEDGE-LEVEL view let her spot what had been bothering *her* the previous day. She had heard it in yesterday's sentence without putting her finger on it:

  > *"An `Employee Type` is assigned to either `Retirement Plan` **or either payroll**."*

  **But that was not really a statement in the UBIQUITOUS LANGUAGE. There was no "payroll" in the model.** *"They had spoken in the language they **wanted**, rather than the one they had."* The concept of payroll was implicit, lumped in with `Employee Type` — invisible until the KNOWLEDGE LEVEL was separated and the elements of that key phrase all appeared in the same level together… **except one.**
- Refactored again: `Payroll` becomes explicit and distinct from `Employee Type`; each `Employee Type` now has a `Retirement Plan` **and** a `Payroll`.

**The tells that revealed it**: *characteristic access restrictions* and a *"thing-thing" type relationship.* And the closing note: *"KNOWLEDGE LEVEL, like other large-scale structures, isn't strictly necessary… There may come a time when this structure doesn't seem to be pulling its weight and can be dropped. But for now, it seems to tell a useful story about the system and helps developers grapple with the model."*

## Worked Example — The SEMATECH CIM Framework

In a chip factory, *lots* of silicon wafers move between machines through hundreds of processing steps. A **manufacturing execution system (MES)** must track each lot, record its exact processing, and direct workers or equipment to the next machine and process. **Hundreds of different machines from dozens of vendors**, with carefully tailored recipes at each step — developing such software was daunting and prohibitively expensive. The SEMATECH consortium responded with the CIM Framework.

Two relevant aspects:
1. **Abstract interfaces for the basic concepts of the semiconductor MES domain — the CORE DOMAIN in the form of an ABSTRACT CORE.** These definitions include **both behavior and semantics**. A vendor producing a new machine develops a specialized implementation of the `Process Machine` interface; adhering to it, their machine-control component plugs into any CIM-based application.
2. **The rules by which those interfaces interact.** Any CIM-based application must implement a protocol hosting objects that implement some subset of the interfaces. Given that protocol and strict observance of the abstract interfaces, **the application can count on the promised services regardless of implementation.** *"The combination of those interfaces and the protocol for using them constitutes a tightly restrictive large-scale structure."*

It is tightly coupled to CORBA for persistence, transactions, events, and other technical services — **but the interesting thing is the PLUGGABLE COMPONENT FRAMEWORK itself, which allows people to develop software independently and integrate it smoothly into immense systems. "No one knows all the details of such a system, but everyone understands an overview."**

## Worked Example — The AIDS Memorial Quilt

*How can thousands of people work independently to create a quilt of more than 40,000 panels?* A few simple rules provide a large-scale structure, leaving the details to individual contributors. **Notice what the rules focus on:**
- **The overall mission** — memorializing people who have died of AIDS. *"Include the name of the person you are remembering… please limit each panel to one individual."*
- **The features of a component that make integration practical** — *"the finished, hemmed panel must be 3 feet by 6 feet — no more and no less!"* Leave 2–3 inches on each side for a hem; if you can't hem it, we'll do it for you.
- **The ability to handle the quilt in larger sections** — *"Remember that the Quilt is folded and unfolded many times, so durability is crucial. Since glue deteriorates with time, it is best to sew things to the panel."* Photos in clear vinyl should be placed **off-center so they avoid the fold**.

Everything else — appliqué, paint, stencil, collage, photos — is left to the contributor.

## How Restrictive Should a Structure Be?

The patterns range from the very loose SYSTEM METAPHOR to the restrictive PLUGGABLE COMPONENT FRAMEWORK — and **within a pattern there is a lot of choice about how restrictive to make the rules.**

**The worked case — upward signaling in a layered factory system.** Software directs each part to a machine per a recipe: the correct process is ordered from a Policy layer and executed in Operations. But **mistakes happen on the factory floor**, and *an Operations layer must reflect the world as it is* — so when a part is put in the wrong machine, that information must be accepted unconditionally. The exceptional condition needs to reach a higher layer that can correct it (reroute to repair, or scrap) — **without creating two-way dependencies from lower layers to higher ones.**

**The solution**: an event mechanism. Operations objects generate events whenever their state changes; Policy-layer objects listen for events of interest from lower layers. When an event violates a rule, the rule executes an action (part of the rule's definition) that responds — or generates an event for a still higher layer.

*(Banking analogue: asset values change (Operations), shifting portfolio segment values. When these exceed allocation limits (Policy), a trader is alerted, who can buy or sell to redress the balance.)*

**The trade-off**: figure this out case by case, or decide on a consistent pattern for all interactions between objects of particular layers?
- **More restrictive**: increases uniformity, makes the design easier to interpret, pushes developers toward good designs if the structure fits, and makes disparate pieces fit together better.
- **Less restrictive**: preserves flexibility developers need. Very particular communication paths **might be impractical across BOUNDED CONTEXTS**, especially in different implementation technologies in a heterogeneous system.

> **You have to fight the temptation to build frameworks and regiment the implementation of the large-scale structure. The most important contribution of the large-scale structure is conceptual coherence, and giving insight into the domain. Each structural rule should make development easier.**

## Refactoring Toward a Fitting Structure

*"In an era when the industry is shaking off excessive up-front design, some will see large-scale structure as a throwback to the bad old days of waterfall architecture. But in fact, **the only way a useful structure can be found is from a very deep understanding of the domain and the problem, and the practical way to that understanding is an iterative development process.**"*

A team committed to EVOLVING ORDER **must fearlessly rethink the large-scale structure throughout the project life cycle** and "should not saddle itself with a structure conceived of early on, when no one understood the domain or the requirements very well." Which means the final structure isn't available at the start, and you will have to refactor to impose it as you go. Three ways to control the cost:

1. **Minimalism.** *"Keep the structure simple and lightweight. Don't attempt to be comprehensive. Just address the most serious concerns and leave the rest to be handled on a case-by-case basis."* Early on, a loose structure — a SYSTEM METAPHOR or a couple of RESPONSIBILITY LAYERS — provides lightweight guidelines that nonetheless prevent chaos.
2. **Communication and self-discipline.** The whole team must follow the structure in new development *and* refactoring, so the whole team must understand it: **the terminology and relationships must enter the UBIQUITOUS LANGUAGE.** Without consistent adherence, structures decay — because *"the relationship of the structure to detailed parts of the model or implementation is not usually explicit in the code, and functional tests do not rely on the structure. Plus, the structure tends to be abstract."* **"The kinds of conversations that take place on most teams are not enough to maintain a consistent large-scale structure in a system."**
3. **Distillation lightens the load.** Removing mechanisms, GENERIC SUBDOMAINS, and other support from the CORE means there is simply less to restructure. Where possible, define supporting elements to fit the structure simply — a GENERIC SUBDOMAIN fitting within a single RESPONSIBILITY LAYER, or owned entirely by a single PLUGGABLE COMPONENT, or a SHARED KERNEL among related components. These elements may need refactoring to find their place, **but they move independently of the CORE, tend to be more narrowly focused, and ultimately are less critical, so refinement matters less.**

**Restructuring yields supple design — the leather jacket.** Each structural change means the entire system has to change to adhere to the new order. *"Obviously that is a lot of work. **This isn't quite as bad as it sounds.**"* Evans observes that a design *with* a large-scale structure is usually much easier to transform than one without — **even when changing from one kind of structure to another**, and *"even easier to change a system that has had **two** previous structures."* Partial explanations: it's easier to rearrange something whose current arrangement you can understand; and the discipline required to maintain the earlier structure permeates the whole system.

> A new leather jacket is stiff and uncomfortable, but after the first day of wear the elbows have flexed a few times… After months of wear, the leather becomes supple and is comfortable and easy to move in. So it seems to be with models that are transformed repeatedly with sound transformations. Ever-increasing knowledge is embedded into them and **the principal axes of change have been identified and made flexible,** while stable aspects have been simplified. The broader CONCEPTUAL CONTOURS of the underlying domain are emerging in the model structure.

And distillation and refactoring toward deeper insight apply **to the large-scale structure itself** — layers initially chosen on a superficial understanding are gradually replaced with deeper abstractions expressing the system's fundamental responsibilities.

## Anti-patterns
- **Design free-for-all** — systems no one can make sense of as a whole, very difficult to maintain; learning about one part doesn't transfer, producing MODULE specialists who can't help each other; CONTINUOUS INTEGRATION breaks down and the BOUNDED CONTEXT fragments.
- **Up-front imposed architecture** — freezes design decisions that become a straitjacket as requirements change and understanding deepens. *"Your work slows down as you try workarounds or try to negotiate with the architects. But your managers think the architecture is done… **The managers and architecture teams may even be open to input, but if each change is a heroic battle, it is too exhausting.**"* The two outcomes: **developers dumb down the application to fit the structure, or subvert it and have no structure at all.**
- **Architectures venturing into the application and domain model** — some technical architectures do solve technical problems (networking, persistence), but domain-level ones "often prevent the developers from creating designs and models that work well for the specifics of the problem. The most ambitious ones can even take away from application developers the familiarity and technical power of the programming language itself."
- **The gimmick fixes** — an overview document or new class-diagram views, in place of a real organizing principle.
- **Ad hoc layering** — dependency-ordered packages that make tracing easier but give no insight and guide no decisions.
- **Over-extending a metaphor** — the firewall's insufficiently selective barriers and blindness to internal threats.
- **Calling the domain model a "naive metaphor."**
- **Full generality in a KNOWLEDGE LEVEL** — and, at the opposite extreme, a fully flexible system allowing any possible relationship, which "would be inconvenient to use and wouldn't allow the organization's own rules to be enforced."
- **Fully customizing software per organization** — impractical even if each could pay, because organizational structure changes frequently.
- **Adopting a PLUGGABLE COMPONENT FRAMEWORK too early** — before multiple specialized applications have been fully developed.
- **Structures with numerous exceptions** — change or discard them.

## Key Takeaways
1. Reach for a large-scale structure when a MODULAR breakdown still leaves the system incomprehensible — and only when a structure can be found that clarifies without unnatural constraint. Less is more; an ill-fitting structure is worse than none.
2. Let the structure evolve, including into a completely different kind, and never let it overconstrain decisions requiring detailed knowledge.
3. Choose layers by *storytelling*, *conceptual dependency*, and *rates and sources of change* — the choice is a business modeling decision, not a technical one.
4. Accept modestly worse local designs in exchange for system-wide consistency — but treat many awkward forced choices as a signal to revise or drop the structure.
5. Expect the structure to push the model toward clarity: the "is preferred" attribute became an explicit `Route Bias Policy` only because the layering wouldn't tolerate it.
6. Keep layers to four or five; ferociously distill the structure itself.
7. Use KNOWLEDGE LEVEL sparingly, built from ordinary objects, deliberately *not* fully general — and remember dependencies run both ways, so it isn't a layer.
8. Signal upward with events, never with upward dependencies.
9. Put the structure's terminology into the UBIQUITOUS LANGUAGE — ordinary team conversation is not enough to keep an abstract structure alive, and neither code nor functional tests will enforce it.
10. Defer PLUGGABLE COMPONENT FRAMEWORKS until several applications in the domain have matured; they freeze refinement of the CORE.
11. Expect restructuring to get *easier* with each structure the system has lived through — the leather-jacket effect.

## Connects To
- **Ch 5 (Model Expressed in Software)**: MODULES — what a large-scale structure organizes *above*.
- **Ch 10 (Supple Design)**: CONCEPTUAL CONTOURS, which a good structure evolves toward and reveals; the leather-jacket suppleness argument.
- **Ch 12 (Design Patterns in the Model)**: STRATEGY, used to apply a Policy layer to lower layers.
- **Ch 14 (Maintaining Model Integrity)**: structures usually span BOUNDED CONTEXTS; SHARED KERNEL and PUBLISHED LANGUAGE in the PLUGGABLE COMPONENT hub; Decision Support often becomes its own context in a CUSTOMER/SUPPLIER relationship.
- **Ch 15 (Distillation)**: ABSTRACT CORE is the hub of a PLUGGABLE COMPONENT FRAMEWORK; distillation lightens the cost of restructuring; the CIM framework recurs as a cautionary example of buying the CORE.
- **Ch 11 (Applying Analysis Patterns)**: KNOWLEDGE LEVEL comes from Fowler 1996 (pp. 24–27) — a pattern that *structures a model* rather than modeling a domain.
- **Buschmann et al. 1996 (POSA)** — layering, RELAXED LAYERED SYSTEM, REFLECTION; **Beck 2000** — SYSTEM METAPHOR as an XP practice; **Fayad and Johnson 2000** — pluggable component framework attempts.
