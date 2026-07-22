# Chapter 26: Architectural Intersections

## Core Idea
An architecture only works if it is **aligned** with the rest of the technical and business environment. **Nine intersections** must line up — and a misalignment in any one of them will make the architecture fail no matter how well the style was chosen.

## The Nine Intersections

| Intersection | The question to ask |
|---|---|
| **Implementation** | Is the implementation aligned with operational characteristics, architectural constraints, and the internal structure of the architecture? |
| **Infrastructure** | Do the infrastructure and deployment align with operational concerns — scalability, responsiveness, fault tolerance, availability? |
| **Data topologies** | Does the data topology (monolithic, domain databases, database-per-service) and **data type** properly align with the style? *"One widely ignored alignment."* |
| **Engineering practices** | Does the way the team creates, maintains, and tests software match the architecture? **Does the deployment pipeline match the style?** |
| **Team topologies** | *"If the team structure is not properly aligned with the architecture, development teams will usually struggle, finding even the simplest of changes challenging."* |
| **Systems integration** | What other systems must the architecture communicate with? *"Not paying attention to this can have devastating results in terms of maintenance, reliability, and operational characteristics."* |
| **The enterprise** | Is the architecture aligned with the frameworks, practices, guiding principles, and standards across the organization? |
| **The business environment** | Is it aligned with the business environment and problem domain? *"Too often architects ignore this important intersection, and as a result the architecture fails to meet the goals or needs of the business."* |
| **Generative AI** | How does the increasing use of LLMs impact the architecture? |

## Frameworks Introduced

- **Architecture and Implementation — three alignments.** *"The First Law is also architects' most common response to any question: 'It depends.' Perhaps the second most common response is, **'That's an implementation detail.'** When a software architecture fails to achieve its goals, this second response is often to blame."*
  1. **Operational concerns** — the architecture characteristics that drive architecture decisions.
  2. **Structural integrity** — the source code's directory structure must match the **logical architecture** (Ch 8). *"Without proper guidance, knowledge, and governance, it's easy for developers to ignore the system's logical architecture and start creating directory structures and namespaces as they please."* The result is architectures *"difficult to maintain, test, and deploy, and as a result… less reliable and harder to evolve or adapt to new features."*
     - **The fix**: automated governance tools — **ArchUnit** (Java), **ArchUnitNet** and **NetArchTest** (.NET), **PyTestArch** (Python), **TSArch** (TypeScript/JavaScript) — *"coupled with good communication and collaboration between the architect and the development team."*
  3. **Architectural constraints** — *"a governing rule or principle describing some sort of restriction within the architecture (such as limiting communications to only REST or using a specific type of database) required to achieve its goals. **If the system's implementation doesn't adhere to its constraints, the architecture will fail.** Thus, part of a software architect's job is to identify and communicate the constraints."*

- **Architecture and Infrastructure.** *"Just because an **architecture** can support high scalability doesn't mean it will — if the corresponding **infrastructure** doesn't support it, it won't."*
  - **The blame problem**: *"We've all too often witnessed architects and developers being blamed for architectural failures that were really caused by a misalignment between architecture and infrastructure."*
  - **The root cause**: lack of communication and collaboration between architects and those responsible for infrastructure and operations. *"Architects often fail to realize infrastructure's influence on characteristics such as scalability, responsiveness, fault tolerance, performance, availability, elasticity. **This misalignment gave rise to the field of DevOps.**"*
  - **The historical arc**: in the mid-2000s the relationship was *"contractual and formal, with lots of bureaucracy"* — most companies outsourced operations to a third party with SLAs for uptime, scale, and responsiveness. **Architectures of the 1990s and 2000s were "designed defensively around the assumption that operations would be outsourced and thus outside architects' control."** Older styles like orchestration-driven SOA required elaborate tools and frameworks for scalability and elasticity, so **architects built architectures handling scale, performance, and elasticity *internally* — with the side effect that these architectures were vastly more complex.**
  - **The microservices insight**: *"The creators of the microservices architecture style realized that **operational concerns are better handled by operations.** By creating a collaborative relationship between architecture and operations, the architects realized they could **simplify their designs** and rely on the operations people to handle the things they handle best. They teamed up with operations to create microservices, and to lay the foundations of what would become the DevOps movement."*
  - **Cloud misalignments still happen**: *"Deploying services across regions or even availability zones can decrease or even cancel out the performance and data integrity benefits of in-memory replicated caches and distributed caches. Similarly, **co-locating services, containers, or even Kubernetes Pods on the same virtual machine will significantly increase performance, but will also adversely impact scalability, fault tolerance, availability, and elasticity.**"*

- **Architecture and Data Topologies — four sub-alignments**:
  1. **Database topology** — monolithic, distributed domain-based, or database-per-service. *"Monolithic databases, while providing good data consistency and transactional support, can detract from scalability and fault tolerance. Distributed database topologies, while good at scalability and change control, can decrease data integrity, data consistency, and performance."* Microservices need database-per-service to maintain a strict bounded context; **service-based architecture (Ch 14) is more flexible.**
  2. **Architectural characteristics** — *"every architectural style has its superpowers (4–5 stars) and its weaknesses (1–2 stars). **So do database types** — and it's important to align a system's architectural superpowers with the corresponding superpowers of its database type."* In *Software Architecture: The Hard Parts* the authors rated six database types: **relational, key-value, document, columnar, graph, and NoSQL.** **Scalability and elasticity are superpowers for microservices, event-driven, and space-based architectures — and also for key-value and columnar databases**, making those good amplifiers.
  3. **Data structure** — *"If the data structure is relational — built upon a hierarchy of interdependent relationships — then a relational database aligns well. However, **storing key-value pairs in a relational database is a misalignment that can lead to inefficiencies in both the database and the architecture.**"* Some data is relational, some document based (**particularly when storing JSON-based event or request payloads**), some key-value driven. *"Given the potential diversity of data structures within any given architecture, we recommend **leveraging polyglot databases whenever feasible.**"*
  4. **Read/write priority**:

     | Priority | Database type |
     |---|---|
     | High **write** volumes over infrequent reads | **Columnar** |
     | High **read** volumes the priority | **Key-value, document, or graph** |
     | Reads and writes **about equally** | **Relational and NewSQL** |
     - *"Misaligning this factor can lead to poorly performing systems."*

- **Architecture and Engineering Practices — the process/practice distinction**:
  - **Processes** = *"how teams are formed and managed, how meetings are conducted and workflows organized — in short, **the mechanics of how people organize and interact**."* (Waterfall, Scrum, XP, Lean, Crystal.)
  - **Engineering practices** = *"the **process-agnostic** techniques and tools teams use to develop and release software"* — XP, CI, CD, TDD. *"**Software engineering** encompasses both software development and these practices."*
  - **Why the distinction matters**: *"Software development lacks many of the features of more mature engineering disciplines. Civil engineers can predict structural change with much more accuracy than software engineers can predict similar aspects of software structure. This means that **the Achilles' heel of software development is estimation**… traditional practices of estimation don't accommodate the exploratory nature of software development and the unknowns that typically arise."*
  - **Process still interacts with architecture**: *"Trying to build a modern system like microservices using an antiquated process like Waterfall will create a great deal of friction."* **Agile shines specifically at migrating between architectural styles**, because of *"tight feedback loops and… techniques like the **Strangler Pattern** and **feature toggles**."*
  - **The alignment rule**: *"Just like carefully considering the problem domain before choosing an architecture, architects must also ensure that their architectural style and engineering practices mesh. The microservices philosophy **assumes** teams will automate machine provisioning, testing, and deployment. **Trying to build a microservices architecture with an antiquated operations group, manual processes, and little testing would likely lead to failure.**"*
  - **Using fitness functions to detect misalignment**: a business needing **fast time to market** needs **agility** — a composite of **maintainability, testability, and deployability**. *"All three are influenced by engineering practices and procedures, and as such can be measured and tracked through fitness functions."* Microservices and service-based both support high agility, **but if the surrounding engineering practices aren't aligned, the system won't meet the agility goals.** *"Fitness functions can help identify a misalignment, prompting the architect to realign the engineering practices with the architecture (or vice versa)."*

- **Architecture and Team Topologies** — teams, like architectures, can be **domain partitioned** or **technically partitioned**:
  - **Domain-partitioned teams** are organized by domain area and typically cross-functional with specialization — e.g. one team owning **end-to-end processing of customer-related functionality, from the UI to the database.**
  - **Technically partitioned teams** each focus on one technical function. **UI teams, backend-processing teams, shared-services teams, and database teams align very nicely with the layered architecture style.** Alternatively, **business-function teams and data-synchronization teams align well with space-based architecture.**

- **Architecture and Systems Integration** — *"Systems rarely live in isolation."* When integrating, consider:
  - Is the called system **available**? Does it **scale and perform** to the level the calling system requires?
  - Which **communication protocols** to use.
  - What types of **contracts** to have between systems.
  - Whether the systems' **architectural characteristics are compatible**.
  - **Whether the integration preserves each system's architectural quantum.**
  - **The consequence of neglect**: *"the systems' static and dynamic coupling often results in architectures that can't scale, aren't responsive, and lack agility."*

- **Architecture and the Enterprise** — by *enterprise* the authors mean **the collection of all systems and products within a company (or a department or division).** Enterprise standards can cover **security standards, practices, procedures, platforms, technologies, documentation standards, and diagramming standards.**
  - **The consequence of ignoring them**: *"We have experienced many situations where the architect ignored enterprise-level practices, standards, and procedures. The usual result has been that **the architectural solution, however technically effective, is deemed a failed 'one-off' solution and scrapped.**"*

- **Architecture and the Business Environment — domain-to-architecture isomorphism.** *"An effective software architect understands the position and direction of the company, and aligns the architectures of critical systems to match the business environment."*
  - **Companies undergoing extreme cost-cutting** do **not** align with microservices or space-based architectures — *"very costly to create and maintain."*
  - **Businesses aggressively expanding through mergers and acquisitions** are **not** served well by monolithic styles — *"which lack the ability to evolve and adapt."*
  - **Ask**: is the company cost-cutting to stay afloat, or aggressively expanding? Pivoting every quarter to find its niche, or in a position of stability?

- **Known knowns, known unknowns, unknown unknowns** (Donald Rumsfeld). *"Many products start with a list of **known unknowns**: things developers must learn about the domain and technology they know will change. However, these same systems also fall victim to **unknown unknowns**: things no one knew were going to crop up."*
  - > **"Unknown unknowns are the nemeses of software systems. This is why all 'Big Design Up Front' software efforts suffer: architects cannot design for unknown unknowns."**
  - > *"All architectures become iterative because of **unknown unknowns**. Agile just recognizes this and does it sooner."* — Mark Richards
  - **What helps**: evolutionary architecture practices, iterative architecture, and embracing the characteristics **portability, scalability, evolvability, and adaptability.**
  - **Residuality theory** (Barry O'Reilly, *Residues: Time, Change, and Uncertainty in Software Architecture*, Leanpub 2024) — treat **business change as *stressors*** and the corresponding **architectural changes as *residues***. The theory: *"as the architect responds to change by applying more and more residues to the architecture, these residues will eventually start addressing **unknown** changes the architect cannot possibly predict, creating an architecture that has reached a critical state within complexity theory. It's an interesting theory, one we are watching closely."*

- **Architecture and Generative AI — two directions**:
  - **Incorporating Gen AI into an architecture**: *"leverage **abstraction** and **modularity**. It's important to be able to **replace one LLM with another quickly**, and to allow for **guardrails (rails)** and **evaluate results (evals)** from various LLMs."* Tools such as **Langfuse** create this observability.
  - **Gen AI as an architect assistant** — the honest assessment (early 2025): LLMs *"are great for solving very specific, deterministic problems, such as 'write source code in C# that generates a unique four-digit PIN with no repeating digits.'"* But for architecture-related prompts (**risk assessment, risk mitigation, antipattern detection, orchestration vs. choreography decisions**), *"we haven't had a tremendous amount of success with this endeavor. Asking an LLM whether microservices or space-based architecture would be most appropriate for a given situation rarely (if ever) yields the right answer."*
    - **Why**: *"everything in software architecture is a trade-off. **LLMs are great for understanding knowledge, but to this day, they still lack the wisdom necessary to make appropriate decisions.** That wisdom includes so much context that **it's much faster for the architect to solve a business problem by themselves than to teach an LLM all about the problem and its extended environment and context.** The fact that we've included eight other intersections to be concerned about should be evidence enough that this is a daunting task."*
    - **Tools with promise**: **Thoughtworks Haiven** *"can interpret an architecture diagram and fully describe a software architecture, saving the work of having to export a diagram into a machine-readable format such as XML."* Users can then ask it simple questions like whether it can identify bottlenecks or issues. Other efforts include **using an LLM to translate a PlantUML diagram or a pseudolanguage architecture description into executable ArchUnit code** to govern system structure. *"A lot of activity is happening in this area, so expect rapid change."*

## Worked Examples

**The implementation misalignment that crashed at 80,000 users.**

The architect is building an order-entry system needing to support **several thousand to half a million concurrent customers**, and chooses **microservices** based on its scalability and elasticity ratings. Correct choice.

During implementation, the development team hits a real problem: **because the bounded contexts are so tightly formed, `Order Placement` cannot access the inventory database directly** — it must **synchronously call the `Inventory` service** for current inventory on any item a customer is considering. *"Not only does this synchronous call tightly couple the two services, it greatly slows the system's responsiveness."*

So the team introduces an **in-memory replicated cache** (Apache Ignite, Hazelcast): the `Inventory` service holds a **writable** cache of item IDs and inventory counts; **each instance of `Order Placement` holds a replicated read-only copy in its internal memory.** This **decouples the services and significantly improves responsiveness.** Also a good decision.

**After production release**, as concurrent users grow, more instances of each service are needed. **The system crashes at about 80,000 concurrent customers** because the internal cache's memory requirements are too high, **causing out-of-memory conditions in all of the virtual machines.**

> *"In this scenario, the architecture and its implementation are misaligned. While the **architecture** focuses on supporting high levels of **scalability** and **elasticity**, the **implementation** focuses on **responsiveness** and **service decoupling**. **Both teams made good decisions, but in service of different goals.**"*

**This is the chapter's central lesson**: no individual decision was wrong. The failure was in the alignment.

---

**The constraints that must be enforced, not just stated.**

A business needs a new system with a **very limited budget and tight deadline**, and **expects lots of structural database changes** it needs done as quickly as possible. **A traditional layered architecture (Ch 10) is an excellent fit** — simple, cost-effective, technically partitioned, and it isolates database changes to one layer.

For that to work, the architect must define two constraints:
1. **All database logic must reside in the Persistence layer.**
2. **The Presentation layer cannot access the Persistence layer directly, but must go through all of the layers, even for simple queries.**

*"These constraints are necessary to prevent spreading the database logic throughout the entire architecture, and so that changes to the physical database structure (such as dropping a table or changing a column name) won't affect any code outside the Persistence layer."*

**What actually happens**: the UI developers decide **it's faster to call the database directly**, and the backend developers realize **it would be easier to maintain and test if Business logic and database logic sat together**, so they couple them in the Business layer. Both are locally reasonable.

**The result**: *"database changes will impact all of the code in every layer, take too long, and the system will not meet the business goals."* — **The architecture didn't fail. The alignment did.** *"Architectural tools are also useful for governing architectural constraints."*

---

**History: How Pets.com gave us elastic scale.**

*"People often assume that our current technical capabilities (like elastic scale) are just invented one day by some clever developer. In reality, **the best ideas are often born of hard lessons.**"*

Pets.com appeared around **1998**, hoping to become the Amazon.com of pet supplies. Its marketing department created a compelling mascot — **a sock puppet with a microphone that said irreverent things** — which became a superstar, appearing at parades and national sporting events.

*"Unfortunately, Pets.com's management apparently spent all the money on the mascot, **not on infrastructure**. Once orders started pouring in, they weren't prepared. The website was slow, transactions were lost, deliveries delayed… pretty much the worst-case scenario. Shortly after a disastrous Christmas rush, Pets.com closed down, **selling its only remaining valuable asset — the mascot.**"*

**What they needed was elastic scale**: the ability to spin up more instances of resources when needed. *"Cloud providers now offer this feature as a commodity, but early ecommerce companies had to manage their own infrastructure, and many fell victim to a previously unheard-of phenomenon: **too much success can kill a business.**"*

## Key Takeaways
1. Choosing the right style is necessary and nowhere near sufficient. **Nine intersections must align.**
2. Beware "that's an implementation detail" — it is the most common excuse behind architectures that fail their goals.
3. Verify that implementation optimizes for the **same** characteristics the architecture selected. Good local decisions in service of different goals still crash the system.
4. Enforce the source-code structure against the logical architecture with automated governance tools; policy alone will not hold.
5. Identify and **communicate** constraints explicitly — an unenforced constraint is not a constraint.
6. Collaborate with infrastructure and operations; the microservices lesson is that **operational concerns are better handled by operations**, and offloading them *simplifies* the architecture.
7. Watch for cloud-specific misalignments: cross-region deployment kills replicated-cache benefits; co-location boosts performance at the cost of every other operational characteristic.
8. Align the database on four axes — topology, characteristic superpowers, data structure, and read/write priority. Go polyglot when the data is genuinely diverse.
9. Separate process from engineering practice, and check that the practices your style *assumes* actually exist.
10. Align team partitioning with architecture partitioning.
11. Preserve architectural quanta across system integrations.
12. Comply with enterprise standards or your technically excellent solution gets scrapped as a one-off.
13. Match the architecture to the company's financial direction — cost-cutting rules out microservices and space-based; M&A rules out monoliths.
14. **You cannot design for unknown unknowns.** Choose iteration, evolvability, and adaptability instead of Big Design Up Front.
15. Build LLM abstraction and evaluation (rails and evals) into the architecture so engines can be swapped and measured.
16. Use Gen AI to describe and enumerate, not to decide. **Knowledge is not wisdom.**

## Connects To
- **Ch 8**: logical components and logical architecture — what the source structure must match.
- **Ch 9**: team topologies; the fallacies underlying integration risk.
- **Ch 10**: layered architecture and its constraints.
- **Ch 14 / Ch 16 / Ch 18**: the styles whose data topologies, infrastructure needs, and team alignments are being checked.
- **Ch 6**: fitness functions for detecting engineering-practice misalignment.
- **Ch 19**: domain/architecture isomorphism, extended here to the *business environment*.
- **Ch 21**: the same verdict on generative AI in decision-making.
- **Ch 27**: the First Law, which every intersection ultimately restates.
