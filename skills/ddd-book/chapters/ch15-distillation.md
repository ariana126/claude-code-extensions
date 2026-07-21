# Chapter 15: Distillation

## Core Idea
LAYERED ARCHITECTURE separates domain from technology, but in a large system **even the isolated domain may be unmanageably complex.** Distillation separates the components of that mixture to extract the one part that distinguishes your software and makes it worth building: the **CORE DOMAIN**. The by-products (GENERIC SUBDOMAINS, COHESIVE MECHANISMS) become more valuable too.

**What strategic distillation buys you:**
- Aids all team members in grasping the overall design and how it fits together
- Facilitates communication by identifying a core model of manageable size to enter the UBIQUITOUS LANGUAGE
- Guides refactoring
- Focuses work on areas of the model with the most value
- Guides outsourcing, use of off-the-shelf components, and decisions about assignments

## Frameworks Introduced

- **CORE DOMAIN**:
  > Boil the model down. Find the CORE DOMAIN and provide a means of easily distinguishing it from the mass of supporting model and code. Bring the most valuable and specialized concepts into sharp relief. **Make the CORE small.**
  >
  > **Apply top talent to the CORE DOMAIN, and recruit accordingly.** Spend the effort in the CORE to find a deep model and develop a supple design — sufficient to fulfill the vision of the system. **Justify investment in any other part by how it supports the distilled CORE.**
  - **The easy decisions it produces**: make the CORE distinctive while keeping the rest as generic as practical; **if you need to keep some aspect secret as competitive advantage, it is the CORE DOMAIN** (no need to waste effort concealing the rest); and when time forces a choice between two desirable refactorings, **take the one that most affects the CORE first.**
  - **Choosing the CORE depends on your point of view.** Many applications need a generic money model; a *currency trading* application needs an elaborate money model that is CORE. Even then, part of the money model may be generic — distillation continues by separating the generic money concepts and retaining only the specialized aspects. **"One application's CORE DOMAIN is another application's generic supporting component."**
  - Identification of the CORE **should evolve through iterations**. The importance of a set of relationships may not be apparent at first; objects that seem obviously central may turn out to have supporting roles.

- **The escalation of distillations** — in ascending order of commitment and design impact:

  | Technique | Investment | Effect |
  |---|---|---|
  | **DOMAIN VISION STATEMENT** | Minimal | Communicates basic concepts and their value |
  | **HIGHLIGHTED CORE** | Little or no design modification | Improves communication, guides decision making |
  | **GENERIC SUBDOMAINS** | Aggressive refactoring and repackaging | Explicitly separates non-motivating subdomains for individual treatment |
  | **COHESIVE MECHANISMS** | Encapsulation with versatile, supple design | Removes computational distractions, disentangling the CORE |
  | **SEGREGATED CORE** | Repackaging across the system | Makes the CORE directly visible, even in the code |
  | **ABSTRACT CORE** | Extensive reorganizing and refactoring | Expresses the most fundamental concepts and relationships in pure form |

  *"Each of these techniques requires a successively greater commitment, but a knife gets sharper as its blade is ground finer."*

- **GENERIC SUBDOMAIN**:
  > Identify cohesive subdomains that are not the motivation for your project. Factor out generic models of these subdomains and place them in separate MODULES. **Leave no trace of your specialties in them.**
  >
  > Once they have been separated, give their continuing development lower priority than the CORE DOMAIN, and **avoid assigning your core developers to the tasks (because they will gain little domain knowledge from them).** Also consider off-the-shelf solutions or published models.
  - **"Generic doesn't mean reusable."** If you're implementing it yourself, **you should specifically not concern yourself with the reusability of that code** — that goes against distillation's basic motivation. Reuse does happen, but *model* reuse is often the better level. You don't have to develop the model in its full generality; **model and implement only the part you need for your business.**
  - **But be strict about keeping within the generic concept.** Introducing industry-specific elements costs twice: (1) it impedes future development — your needs will grow, and anything outside the concept makes clean expansion much harder without rebuilding; (2) more important, **those industry-specific concepts belong either in the CORE DOMAIN or in their own more specialized subdomains — and those specialized models are even more valuable than the generic ones.**
  - **Why GENERIC SUBDOMAINS are the right place for outside expertise**: they don't require deep understanding of your CORE and don't present a major opportunity to learn the domain; confidentiality is less of a concern; and they lessen the training burden for those not committed to deep domain knowledge.

- **DOMAIN VISION STATEMENT**:
  > Write a short description (**about one page**) of the CORE DOMAIN and the value it will bring, the "value proposition." **Ignore those aspects that do not distinguish this domain model from others.** Show how the domain model serves and balances diverse interests. **Keep it narrow.** Write this statement early and revise it as you gain new insight.
  - Modeled after management vision statements — but where those are "abandoned after the project gets funding, and… never used in the actual development process or even read by the technical staff," this one is **used directly by management and technical staff during all phases** to guide resource allocation, guide modeling choices, and educate team members.
  - Especially valuable because **the critical aspects of the domain model may span multiple BOUNDED CONTEXTS**, which by definition can't be structured to show their common focus.
  - Shareable with nontechnical team members, management, and even customers (absent proprietary content).

- **HIGHLIGHTED CORE** — two forms, both being *"a reflection on the model, not necessarily part of the model itself"*:
  - **The Distillation Document**:
    > Write a very brief document (**three to seven sparse pages**) that describes the CORE DOMAIN and the primary interactions among CORE elements.
    - **It is not a complete design document.** It's "a minimalist entry point that delineates and explains the CORE and suggests reasons for closer scrutiny of particular pieces."
    - **All the usual risks of separate documents apply**: it may not be maintained; it may not be read; and by multiplying information sources it may defeat its own purpose of cutting through complexity.
    - **The best mitigation is to be absolutely minimalist.** Staying away from mundane detail and focusing on central abstractions and their interactions lets the document age more slowly, because that level of the model is usually more stable.
    - Write it to be understood by the **nontechnical** members of the team.
  - **The Flagged CORE**:
    > Flag the elements of the CORE DOMAIN within the primary repository of the model, without particularly trying to elucidate its role. **Make it effortless for a developer to know what is in or out of the CORE.**
    - Technique doesn't matter: a UML stereotype, JavaDoc comments, an IDE tool, page tabs and a highlighter.

- **The Distillation Document as Process Tool** — a governance mechanism, not just documentation:
  - **When a model or code change affects the distillation document, it requires consultation with other team members.** When made, it requires immediate notification of the whole team and dissemination of a new version.
  - Changes outside the CORE, or to details not in the document, **can be integrated without consultation or notification** — developers have the full autonomy XP suggests.
  - Why it works: "Changes to the model of the CORE DOMAIN should have a big effect. Changes to widely used generic elements may require a lot of code updating, but they still shouldn't create the conceptual shift that CORE changes do."

- **COHESIVE MECHANISM**:
  > Partition a conceptually COHESIVE MECHANISM into a separate lightweight framework. **Particularly watch for formalisms or well-documented categories of algorithms.** Expose the capabilities of the framework with an INTENTION-REVEALING INTERFACE. Now the other elements of the domain can focus on expressing the problem ("what"), delegating the intricacies of the solution ("how") to the framework.
  - The symptom: *"The conceptual 'what' is swamped by the mechanistic 'how.' A large number of methods that provide algorithms for resolving the problem obscure the methods that express the problem."*
  - **Try the model fix first.** "The first solution to seek is a model that makes the computation mechanism simple." Only when the insight emerges that *some part of the mechanism is itself conceptually coherent* do you extract it. This is not a catch-all "calculator" — extracting the coherent part should make the remaining mechanism easier to understand.
  - **Separation of responsibilities**: *"The model of the CORE DOMAIN or a GENERIC SUBDOMAIN formulates a fact, rule, or problem. A COHESIVE MECHANISM resolves the rule or completes the computation as specified by the model."*
  - Keep it **narrowly focused on the computation** and avoid mixing in the expressive domain model.

- **SEGREGATED CORE**:
  > Refactor the model to separate the CORE concepts from supporting players (**including ill-defined ones**) and strengthen the cohesion of the CORE while reducing its coupling to other code. Factor all generic or supporting elements into other objects and place them into other packages, **even if this means refactoring the model in ways that separate highly coupled elements.**
  - **The four steps:**
    1. Identify a CORE subdomain (possibly drawing from the distillation document).
    2. Move related classes to a new MODULE, **named for the concept that relates them**.
    3. Refactor code to sever data and functionality that are not direct expressions of the concept. Put removed aspects into (possibly new) classes in other packages, placing them with conceptually related tasks — **but don't waste too much time being perfect.** Keep focused on scrubbing the CORE subdomain and making its references to other packages explicit and self-explanatory.
    4. Refactor the newly segregated MODULE to simplify and clarify its relationships with other MODULES. **(This becomes an ongoing refactoring objective.)** Then repeat with another CORE subdomain.
  - **What to do with the residue**: it "can be left more or less where it was, or placed into packages based on prominent classes. Eventually, more and more of the residue can be factored into GENERIC SUBDOMAINS, but in the short term any easy solution will do, just so the focus on the SEGREGATED CORE is retained."
  - **When to do it**: "when you have a large BOUNDED CONTEXT that is critical to the system, but where the essential part of the model is being obscured by a great deal of supporting capability."
  - **It is an evolving team decision.** The whole team must move together, requiring a decision process disciplined enough to carry it out. **"The challenge is to constrain everyone to use the same definition of the CORE while not freezing that decision"** — because the CORE evolves like everything else, and working with a SEGREGATED CORE produces new insight into what's essential. Insights must be shared continuously, but an individual or pair cannot act unilaterally; the joint decision process must be **agile enough to make repeated course corrections.**

- **ABSTRACT CORE**:
  > Identify the most fundamental concepts in the model and factor them into distinct classes, abstract classes, or interfaces. Design this abstract model so that it expresses **most of the interaction between significant components.** Place this abstract overall model in its own MODULE, while the specialized, detailed implementation classes are left in their own MODULES defined by subdomain.
  - **"Consider slicing horizontally rather than vertically."** Reductive vertical packaging by subdomain can obscure or complicate cross-subdomain interaction: either many inter-MODULE references (defeating the partitioning) or indirect interaction (making the model obscure). If most cross-MODULE interactions can be expressed at the level of polymorphic interfaces, refactor those types into a special CORE MODULE.
  - **"We are not looking for a technical trick here."** This is valuable only when the polymorphic interfaces correspond to fundamental domain concepts. *"If all the classes that were frequently referenced across MODULES were automatically moved into a separate MODULE, the likely result would be a meaningless mess."*
  - Requires deep understanding of key concepts and their roles in major interactions — **an example of refactoring to deeper insight**, usually requiring considerable redesign.
  - **It should end up looking a lot like the distillation document** (if both were used and the document evolved with the application) — only written in code, and therefore more rigorous and complete.

- **Choosing refactoring targets** — Evans rejects both common XP answers ("start anywhere, it all has to be refactored" — impractical except with a team entirely of top programmers; "start wherever it hurts" — *"tends to pick around the edges, treating symptoms and ignoring root causes, shying away from the worst tangles"*):
  - **In a pain-driven refactoring**: look to see if the root involves the CORE DOMAIN or the relationship of the CORE to a supporting element. If it does, **bite the bullet and fix that first.**
  - **When you have the luxury of refactoring freely**: focus first on better factoring of the CORE DOMAIN, on improving the segregation of the CORE, and on purifying supporting subdomains to be GENERIC.
  - *"This is how to get the most bang for your refactoring buck."*

## Key Concepts
- **CORE DOMAIN** — the parts of the model distinctive and central to the purposes of the intended applications; where the most value should be added.
- **GENERIC SUBDOMAIN** — a cohesive subdomain that isn't the motivation for your project, modeled with no trace of your specialties.
- **COHESIVE MECHANISM** — an extracted, conceptually coherent computational framework behind an INTENTION-REVEALING INTERFACE.
- **DOMAIN VISION STATEMENT** — a one-page value proposition for the CORE DOMAIN.
- **HIGHLIGHTED CORE** — distillation document and/or flagged CORE.
- **SEGREGATED CORE** — the CORE physically repackaged into its own MODULES.
- **ABSTRACT CORE** — the fundamental concepts factored into a polymorphic MODULE expressing most cross-subdomain interaction.
- **Distillation document** — 3–7 sparse pages describing the CORE and its primary interactions; also a change-governance trigger.

## Mental Models
- **"A model proposes; a COHESIVE MECHANISM disposes."** The cleanest statement of the GENERIC SUBDOMAIN vs. COHESIVE MECHANISM distinction: a GENERIC SUBDOMAIN is *based on an expressive model representing some aspect of how the team views the domain* — no different from the CORE, just less central; a COHESIVE MECHANISM **does not represent the domain**, it solves a sticky computational problem posed by the expressive models.
  - In practice the distinction is usually not pure at first, unless you recognize a formalized, published computation. Successive refactoring can distill it into a purer mechanism *or* transform it into a GENERIC SUBDOMAIN with previously unrecognized model concepts that make the mechanism simple.
- **Like a gardener pruning a tree**, clearing the way for the growth of the main branches.
- **Plagiarize.** Tom Lehrer: *"Plagiarize! Plagiarize. Let no one's work evade your eyes… Only be sure always to call it please, **research**."* Good advice in domain modeling, especially for a GENERIC SUBDOMAIN. When the field already has a formalized rigorous model — accounting, physics — **use it**: robust, streamlined, and widely understood, reducing present and future training burden.
- **Don't feel compelled to implement all of a published model** if a simplified, self-consistent subset satisfies you. But where a well-traveled, well-documented (or formalized) model exists, **it makes no sense to reinvent the wheel.**
- **When a MECHANISM *is* CORE**: the one exception to removing mechanisms is when the mechanism is itself proprietary and a key part of the software's value — a particularly effective scheduling algorithm in shipping logistics, or the risk-rating algorithms at an investment bank Evans worked at (*"held so closely that even most of the CORE developers were not allowed to see them"*). Deeper analysis might still reveal a model making the rules explicit with an encapsulated solving mechanism — a cost-benefit decision for another day.
- **Full circles are common, and they don't return to their starting point.** A year after the organization-chart graph framework was extracted, other developers reabsorbed it — adding node behavior to the parent class of the organizational ENTITIES — while **retaining the declarative public interface and keeping the MECHANISM encapsulated.** *"The end result is usually a deeper model that more clearly differentiates facts, goals, and MECHANISMS. Pragmatic refactoring retains the important virtues of the intermediate stages while shedding the unneeded complications."*

## Who Does the Work?

**The vicious circle**: "The most technically proficient members of project teams seldom have much knowledge of the domain. This limits their usefulness and reinforces the tendency to assign them to supporting components, sustaining a vicious circle in which lack of knowledge keeps them away from the work that would build domain knowledge."

Meanwhile *"scarce, highly skilled developers tend to gravitate to technical infrastructure or neatly definable domain problems that can be understood without specialized domain knowledge… perceived to build transferable professional skills and provide better resume material."* The specialized CORE ends up "put together by less skilled developers who work with DBAs to create a data schema and then code feature-by-feature without drawing on any conceptual power in the model at all."

**Break the cycle** by assembling a team matching strong developers with a long-term commitment and an interest in becoming repositories of domain knowledge, together with one or more domain experts who know the business deeply. *"Domain design is interesting, technically challenging work when approached seriously, and developers can be found who see it this way."*

**On hiring and buying:**
- **Short-term outside design expertise for the nuts and bolts of the CORE is usually impractical** — the team needs to accumulate domain knowledge, and **"a temporary member is a leak in the bucket."** But an expert in a *teaching/mentoring* role can be very valuable.
- **The CORE DOMAIN is unlikely to be purchasable.** Industry-specific model frameworks (SEMATECH's CIM framework for semiconductor manufacturing; IBM's "San Francisco") have not been compelling, *"except perhaps as PUBLISHED LANGUAGES facilitating data interchange."*
- **The more fundamental reason for caution**: *"The greatest value of custom software comes from the total control of the CORE DOMAIN."* If a framework constrains you more than providing high-level abstractions you specialize, there are three likely possibilities:
  1. **You are losing an essential software asset** → back off restrictive frameworks in your CORE.
  2. **The area treated by the framework is not as pivotal as you thought** → redraw the CORE boundaries to the truly distinctive part.
  3. **You don't have special needs in your CORE** → consider a lower-risk solution, such as purchasing software to integrate with.
- **"One way or another, creating distinctive software comes back to a stable team accumulating specialized knowledge and crunching it into a rich model. No shortcuts. No magic bullets."**

## Reference — Four Options for a GENERIC SUBDOMAIN

| Option | Advantages | Disadvantages |
|---|---|---|
| **1. Off-the-shelf solution** (buy or open source) | Less code to develop; maintenance burden externalized; probably more mature, used in multiple places, more bulletproof and complete | Still must spend time evaluating and understanding it; can't count on correctness/stability; may be overengineered so integration exceeds a minimalist homegrown build; foreign elements don't integrate smoothly (possibly a distinct BOUNDED CONTEXT; hard to reference ENTITIES from your packages); may introduce platform/compiler-version dependencies |
| **2. Published design or model** | More mature than homegrown, reflects many people's insights; instant, high-quality documentation | May not quite fit your needs, or may be overengineered for them |
| **3. Outsourced implementation** | Keeps core team free for the CORE; more development without permanently enlarging the team or dissipating CORE knowledge; **forces an interface-oriented design and helps keep the subdomain generic, because the specification is passed outside** | Still requires core-team time (interface, coding standards); significant overhead transferring ownership back inside (though less than for specialized subdomains, since a generic model needs no special background); code quality can vary |
| **4. In-house implementation** | Easy integration; you get just what you want and nothing extra; temporary contractors can be assigned | Ongoing maintenance and training burden; **it is easy to underestimate the time and cost** |

Evans' verdict on option 1: *"Off-the-shelf subdomain solutions are worth investigating, but they are usually not worth the trouble."* Successes he's seen: elaborate workflow requirements met by commercial workflow systems with API hooks; an error-logging package deeply integrated. **"The more generic the subcomponent, and the more distilled its own model, the better the chance that it will be useful."**

For option 3, **automated tests play an important role**: require implementers to provide unit tests, and — "a really powerful approach" — specify or even write automated *acceptance* tests for the outsourced components, which ensures a degree of quality, clarifies the spec, and smooths reintegration. Options 3 and 4 both combine excellently with option 2.

## Project Risk Management

Agile processes manage risk by tackling the riskiest tasks early; XP calls for an end-to-end system running immediately. **"This initial system often proves a technical architecture, and it is tempting to build a peripheral system that handles some supporting GENERIC SUBDOMAIN because these are usually easier to analyze. But be careful; this can defeat the purpose of risk management."**

Projects face risk from both sides — technical and domain-modeling. *"The end-to-end system mitigates risk only to the extent that it is an embryonic version of the challenging parts of the actual system."* Domain modeling risk is easy to underestimate: unforeseen complexity, inadequate access to business experts, gaps in developers' key skills.

> **Therefore, except when the team has proven skills and the domain is very familiar, the first-cut system should be based on some part of the CORE DOMAIN, however simple.**

The CORE is high risk **because it is often unexpectedly difficult and because without it, the project cannot succeed.**

## Worked Example — A Tale of Two Time Zones

Twice Evans watched the best developers on a project spend weeks on storing and converting times with time zones. Two projects, near-perfect contrast.

**Shipping (scheduling international transports).** Accurate time calculation is critical; schedules are tracked in local time, so conversion is unavoidable.
1. Need **clearly established first**.
2. Proceeded with **CORE DOMAIN development and early application iterations** using available time classes and dummy data.
3. As the application matured, existing time classes proved inadequate and the problem proved intricate (country variations, the International Date Line).
4. **With requirements by now even clearer**, searched for an off-the-shelf solution; found none; had to build it.
5. Assigned **one of their best programmers** — because it required research and precision engineering — but **specifically one on a temporary contract**, because the task needed no shipping knowledge and would cultivate none.
6. He didn't start from scratch: researched several existing implementations, adapted the **public-domain BSD Unix solution** (elaborate database, C implementation), reverse-engineered the logic, and wrote an import routine for the database.
7. Harder than expected, but delivered and integrated with the CORE.

**Insurance (claims processing).** Event times (car crash, hail storm) recorded in local time, so time zones were "needed."
- Requirements were still in play; **not even an initial iteration had been attempted.**
- A junior-but-smart developer was assigned to build a time zone model ***a priori***. Not knowing what would be needed, it was assumed it should be **flexible enough to handle anything**.
- A senior developer was added to help. **They wrote complex code, but no specific application used it, so it was never clear that the code worked correctly.**
- The project ran aground; **the time zone code was never used.** And if it had been, *simply storing local times tagged with the time zone might have been sufficient, even with no conversion*, because this was primarily reference data, not the basis of computations. Even with conversion, **all data was to be gathered from North America**, where conversions are relatively simple.

| | Shipping | Insurance |
|---|---|---|
| GENERIC model decoupled from CORE | ✓ | ✓ |
| CORE model state | Mature, so resources could be diverted without stunting it | **Undeveloped — attention elsewhere continued the neglect** |
| Requirements | Knew exactly what they needed; critical support for international scheduling | **Unknown → attempt at full generality where North-America-specific conversion might have sufficed** |
| Staffing | Short-term contractor used for the generic task | **Long-term programmers assigned who could have been repositories of domain knowledge** |
| Cost | Diverted a top programmer from the CORE | Neglect of the CORE DOMAIN model |

**Both did one thing right**: cleanly segregating the generic time zone model from the CORE. A shipping-specific or insurance-specific time zone model would have coupled the CORE to supporting detail (making the CORE harder to understand) **and** made the time zone MODULE harder to maintain (its maintainer would need to understand the CORE and its interrelationship with time zones).

> **"We technical people tend to enjoy definable problems like time zone conversion, and we can easily justify spending our time on them. But a disciplined look at priorities usually points to the CORE DOMAIN."**

## Worked Example — Two Domain Vision Statements

**Airline Booking System — IN the statement:**
> The model can represent passenger priorities and airline booking strategies and balance these based on flexible policies. The model of a passenger should reflect the "relationship" the airline is striving to develop with repeat customers. Therefore, it should represent the history of the passenger in useful condensed form, participation in special programs, affiliation with strategic corporate clients, and so on.
>
> Different roles of different users (such as passenger, agent, manager) are represented to enrich the model of relationships and to feed necessary information to the security framework.
>
> Model should support efficient route/seat search and integration with other established flight booking systems.

**Airline Booking System — important, but NOT in the statement:**
- The UI should be streamlined for expert users but accessible to first-time users.
- Access over the Web, by data transfer, maybe other UIs, so the interface will be designed around XML with transformation layers.
- A colorful animated logo cached on the client machine for fast return visits.
- Visual confirmation of a reservation within 5 seconds.
- A security framework authenticating identity and limiting feature access by role privileges.

**Semiconductor Factory Automation — IN:**
> The domain model will represent the status of materials and equipment within a wafer fab in such a way that necessary audit trails can be provided and automated product routing can be supported.
>
> The model will not include the human resources required in the process, but must allow selective process automation through recipe download.
>
> The representation of the state of the factory should be comprehensible to human managers, to give them deeper insight and support better decision making.

**Semiconductor Factory Automation — NOT:**
- Web enabled through a servlet, structured to allow alternative interfaces.
- Industry-standard technologies wherever possible; open source preferred (Apache).
- Web server on a dedicated server; application on a single dedicated server.

**The pattern**: everything about *technology, UI, performance, deployment, and infrastructure* is out — however important. What stays is what the *model* represents, what it deliberately excludes, and whose interests it balances.

## Worked Example — The Flagged CORE at an Insurance Company

Day one on the project, Evans was handed the "domain model": **a two-hundred-page document purchased at great expense from an industry consortium.** Days of wading through class diagrams covering everything from detailed policy composition to extremely abstract models of relationships between people. Factoring quality "ranged from high-school project to rather good." **But where to start?**

The project culture heavily favored abstract framework building; predecessors had focused on a very abstract model of people's relationships with each other, things, and activities. *"It was actually a nice analysis… their experiments with the model had the quality of an academic research project. But it wasn't getting us anywhere near an insurance application."*

**His first instinct was to start slashing** — find a small CORE, refactor it, reintroduce complexity as needed. **Management was alarmed.** The document carried great authority: industry experts had produced it, and *"they had paid the consortium far more than they were paying me, so they were unlikely to weigh my recommendations for radical change too heavily."*

**So instead of refactoring**, he went through the document with a business analyst who knew the insurance industry and the specific application, and **identified the handful of sections presenting the essential, differentiating concepts**, providing a navigation of the model that clearly showed the CORE and its relationship to supporting features.

> A new prototyping effort started from this perspective, and quickly yielded a simplified application that demonstrated some of the required functionality.
>
> **Two pounds of recyclable paper was turned into a business asset by a few page tabs and some yellow highlighter.**

## Worked Example — A Mechanism in an Organization Chart

A project needed an elaborate organization-chart model: who works for whom, in which branches, answering questions like *"Who, in this chain of command, has authority to approve this?"* and *"Who, in this department, is capable of handling an issue like this?"*

The team realized **most of the complexity was traversing specific branches of the organizational tree** — exactly the problem solved by the well-developed formalism of a **graph** (nodes connected by edges, plus traversal rules and algorithms).

A subcontractor implemented a graph traversal framework as a COHESIVE MECHANISM, using **standard graph terminology and algorithms familiar to most computer scientists and abundantly documented in textbooks**. Crucially: *"By no means did he implement a fully general graph. It was a subset of that conceptual framework that covered the features needed for our organization model."* Behind an INTENTION-REVEALING INTERFACE, the means of obtaining answers is not a primary concern.

Now the organization model could simply state, in standard graph terminology, that **each person is a node and each relationship an edge**.

**The two costs avoided by not incorporating the mechanism into the domain model:**
1. The model would have been **coupled to a particular method of solving the problem**, limiting future options.
2. More important, **the model of an organization would have been greatly complicated and muddied.**

Keeping them separate allowed a much clearer declarative style of describing organizations, and isolated the intricate graph-manipulation code in a purely mechanistic framework based on proven algorithms **that could be maintained and unit-tested in isolation.**

*(A second example: a framework for constructing SPECIFICATION objects and their comparison/combination operations — letting the CORE and GENERIC SUBDOMAINS declare SPECIFICATIONS in clear language while the framework handles the intricate operations.)*

## Worked Example — Segregating the CORE of a Cargo Shipping Model

**Start with the DOMAIN VISION STATEMENT, not the "bottom line."** The instinct is to focus on pricing and invoices — but the statement says:

> *…Increase visibility of operations and provide tools to fulfill customer requirements faster and more reliably…*

**This application is not being designed for the sales department. It is going to be used by the front-line operators of the company.** So all money-related issues go into (admittedly important) supporting roles — someone had already placed some into a `Billing` package; keep it and recognize it as supporting.

The focus is **cargo handling: delivery of the cargo according to customer requirements.** Extract those classes into a new `Delivery` package.

**Two model changes came out of the segregation itself:**
1. **`Customer Agreement` now constrains `Handling Step`.** *"This is typical of the insights that tend to arise as the team segregates the CORE. As attention is focused on effective, correct delivery, it becomes clear that the delivery constraints in the `Customer Agreement` are fundamental and should be **explicit** in the model."*
2. **`Customer Agreement` attaches directly to `Cargo`** rather than requiring navigation through `Customer`. At delivery time the Customer is less relevant to operations than the agreement itself; the old path required finding the right Customer *according to the role it played in the shipment* and then querying it. **"This interaction would clog up every story you set out to tell about the model."** The new association makes the most important scenarios direct — and now `Customer` can be pulled out of the CORE altogether.

**On borderline calls**: `Leg` has a strong argument for staying. *"I tend to be minimalist in the CORE, and the `Leg` has tighter cohesion with `Transport Schedule`, `Routing Service`, and `Location`, none of which needed to be in the CORE. **But if a lot of the stories I wanted to tell about this model involved `Legs`, I'd move it into the `Delivery` package and suffer the awkwardness of its separation from those other classes.**"* — the decision criterion is *which stories you need to tell*, not structural cohesion.

**Afterward**, the leftover `Shipping` package is just "everything left over after we pulled out the CORE" — follow up with further refactorings for more communicative packaging. It might take several passes; **it doesn't have to be done all at once.** End state: one SEGREGATED CORE package, one GENERIC SUBDOMAIN, and two domain-specific packages in supporting roles.

**Note also**: in this example all class *definitions* were unchanged, but *"often distillation requires refactoring the classes themselves to separate the generic and domain-specific responsibilities, which can then be segregated."*

## The Costs of a SEGREGATED CORE
- Relationships with tightly coupled non-CORE classes may become **more obscure or even more complicated** — outweighed by the clarity gained.
- **A nicely cohesive MODULE may be broken**, sacrificing its cohesion to bring out the CORE's. *"This is a net gain, because the greatest value-added of enterprise software comes from the enterprise-specific aspects of the model."*
- **It is a lot of work** — potentially absorbing developers in changes all over the system.

## Anti-patterns
- **The elegant peripheral feature** — on a syndicated loan project, most strong talent worked happily on database mapping layers and messaging interfaces while the business model was in the hands of developers new to object technology. The single experienced object developer on a domain problem built a genuinely useful, well-designed, elegantly UI'd commenting system for long-lived domain objects. It went into production. **"Unfortunately, they were peripheral."** Meanwhile an incompetent developer was turning the mission-critical "loan" module **into an incomprehensible tangle that the project very nearly did not recover from.**
- **Building a generic model a priori** — the insurance time-zone story: no requirements, so aim for total flexibility, and no application ever exercises it, so correctness is never established.
- **Designing GENERIC SUBDOMAIN code for reusability** — contradicts distillation's premise.
- **Leaking industry-specific concepts into a generic subdomain** — impedes future expansion, and misplaces concepts that are more valuable elsewhere.
- **Proving the architecture with a peripheral end-to-end system** — defeats the purpose of risk management when the real risk is domain modeling.
- **Mechanically extracting an ABSTRACT CORE** — moving all frequently cross-referenced classes into one MODULE yields "a meaningless mess."
- **The two default XP refactoring strategies** — "refactor everything" (impractical) and "refactor where it hurts" (picks around the edges, treats symptoms, avoids the worst tangles, and the code becomes harder and harder to refactor).

## Key Takeaways
1. Make the CORE small, put your best long-term people on it, and justify every other investment by how it supports the CORE.
2. Recognize that what's CORE depends on your application; today's CORE money model is another project's generic component, and the boundary evolves through iterations.
3. Break the vicious circle that keeps strong developers away from the domain — a temporary member is a leak in the bucket for the CORE, but exactly right for a GENERIC SUBDOMAIN.
4. Don't expect to buy your CORE; a framework that constrains it is either costing you an asset, mislabeled as CORE, or evidence you have no special needs there.
5. Factor out generic subdomains with no trace of your specialties, and give them lower priority — but never design them for reusability.
6. Start distillation cheaply: a one-page DOMAIN VISION STATEMENT and a 3–7 page distillation document cost almost nothing and change how the team allocates attention.
7. Use the distillation document as a change-governance signal: if a change would alter it, consult the team; if not, proceed autonomously.
8. Extract COHESIVE MECHANISMS behind intention-revealing interfaces — but only after trying to find a model that makes the computation simple, and only for the conceptually coherent part.
9. Segregate the CORE into its own MODULES when supporting capability is obscuring it, accepting broken cohesion elsewhere and the whole-team commitment it demands.
10. Slice horizontally into an ABSTRACT CORE only when the polymorphic interfaces correspond to fundamental domain concepts.
11. Base the first-cut system on some part of the CORE DOMAIN, however simple — that's where the underestimated risk lives.
12. Aim refactoring at the CORE and its relationship to supporting elements, not wherever the pain happens to surface.

## Connects To
- **Ch 4 (Isolating the Domain)**: LAYERED ARCHITECTURE gets you to an isolated domain; distillation handles the complexity that remains inside it.
- **Ch 5 (Model Expressed in Software)**: MODULES — "recognizing useful, meaningful MODULES is a modeling activity"; developers and domain experts collaborate in strategic distillation as part of knowledge crunching.
- **Ch 10 (Supple Design)**: INTENTION-REVEALING INTERFACES, ASSERTIONS, SIDE-EFFECT-FREE FUNCTIONS make COHESIVE MECHANISMS useful; "draw on established formalisms"; declarative style is what a distilled CORE enables — *"an exceptional payoff comes when part of the CORE DOMAIN itself breaks through to a deep model and starts to function as a language."*
- **Ch 11 (Applying Analysis Patterns)**: published models are the best source for GENERIC SUBDOMAINS (Fowler 1996).
- **Ch 14 (Maintaining Model Integrity)**: a SHARED KERNEL is often the CORE DOMAIN and/or GENERIC SUBDOMAINS; PUBLISHED LANGUAGE is where industry frameworks have actually delivered; sharpening the CORE is a prerequisite step in two transformation game plans.
- **Ch 16 (Large-Scale Structure)**: the other principle for making a big model tractable.
- **Fayad and Johnson 2000** (*Domain-Specific Application Frameworks*), **SEMATECH CIM**, **IBM San Francisco**.
