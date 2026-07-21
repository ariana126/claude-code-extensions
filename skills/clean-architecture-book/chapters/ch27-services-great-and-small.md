# Chapter 27: Services: Great and Small

## Core Idea
Services are just function calls across process and/or platform boundaries — they are not, in and of themselves, architecturally significant. Architectural boundaries do not fall *between* services; they run *through* services, dividing them into components.

## Frameworks Introduced
- **The Decoupling Fallacy**: the claim that services are strongly decoupled because they run in separate processes/processors and cannot see each other's variables.
  - When to use: whenever a team justifies a micro-service split on the grounds of "decoupling."
  - How to test the claim:
    1. Ask what data records pass between the services. Add a field to one of them mentally — count how many services must change.
    2. Ask which services must *agree on the interpretation* of that field. Agreement on semantics is coupling.
    3. Ask what shared resources exist inside the processor or on the network (databases, queues, caches). Those couple too.
    4. Compare the service interface to a function interface. Service interfaces are *no more formal, no more rigorous, and no better defined* than function interfaces.
  - Why it fails: services are decoupled only at the level of individual variables. They remain strongly coupled by the data they share, and are therefore indirectly coupled to each other.

- **The Fallacy of Independent Development and Deployment**: the belief that each service can be owned, written, maintained, and operated by a dedicated team, and that this scales to hundreds or thousands of services and teams.
  - When to use: when scalability of *the org* is being used to justify the service topology.
  - How to test the claim:
    1. Note that history shows large enterprise systems have been built successfully from monoliths and component-based systems too. Services are not the only scalable option.
    2. Apply the decoupling fallacy: to the extent services are coupled by data or behavior, their development, deployment, and operation *must* be coordinated.
    3. Run a cross-cutting feature through the topology (see the Kitty Problem) and count the services that change.
  - Failure mode: a functional decomposition — which is what most service diagrams are — is exactly the decomposition most vulnerable to new features that cut across all those functional behaviors.

- **Component-Based Services**: give each service an internal component structure built with the SOLID principles, so new features arrive as new components rather than edits to existing ones.
  - When to use: any service that will have to absorb cross-cutting features over its life — i.e., all of them.
  - How:
    1. Inside the service, express the stable logic as abstract base classes in one or more jar files (or Gems, or DLLs).
    2. Express each new feature or feature extension as *another* jar file containing classes that extend those abstract base classes.
    3. Derive the feature classes using Template Method or Strategy.
    4. Have factories under the control of the UI create the concrete feature classes.
    5. Deploy by *adding* the new jar to the service's load path and loading it dynamically at runtime — not by redeploying the service.
  - Why it works: adding features this way conforms to the Open-Closed Principle, and the derivative components follow the Dependency Rule, so the new feature is genuinely decoupled and independently developable and deployable.

## Key Concepts
- **Architecturally significant service**: a service whose interface constitutes a boundary separating high-level policy from low-level detail and obeying the Dependency Rule — as opposed to one that merely separates behaviors.
- **Expensive function call**: a service that only separates application behaviors across a process boundary, buying no architectural benefit for the operational cost.
- **Cross-cutting concern**: a new requirement that cuts across many functional behaviors at once; every software system faces this, service-oriented or not.
- **Functional decomposition**: splitting a system by the steps of its behavior (find, select, dispatch); highly vulnerable to cross-cutting features.
- **Kitty Problem**: the taxi-aggregator case where adding kitten delivery forces a change in every service.
- **Internal component design**: a component structure *inside* a service that carries the real architectural boundaries.
- **Little monolith**: a service with no internal component structure, which must be redeployed for every change.

## Mental Models
- Think of a service as a function call that happens to cross a process or platform boundary. Some function calls are architecturally significant; most are not. The same is true of services.
- Use the "add one field to the shared data record" test to measure real decoupling — count the services that must change and re-agree on semantics.
- Think of architectural boundaries as running *through* services, not between them. The service is a deployment unit; the component is the architectural unit.
- Use services when you need scalability and develop-ability across processes and platforms — not when what you actually need is a boundary. A service is an expensive way to draw a boundary.

## Anti-patterns
- **Calling a service topology an "architecture"**: architecture is defined by boundaries and by the dependencies that cross them, never by the physical mechanisms by which elements communicate and execute.
- **Services as little monoliths**: with no internal component structure, every new feature means editing and redeploying the service — no OCP, no independent deployment.
- **Functional decomposition into micro-services**: services shaped like the steps of a workflow are broadside-vulnerable to any feature that cuts across the workflow.
- **Assuming shared data records are harmless**: they are the strongest coupling in a service system; adding a field ripples to every service that touches it.
- **One micro-service per programmer**: Martin's footnote — subdividing staff so each small team owns a correspondingly small number of services makes the service count roughly equal to the programmer count, which is a staffing artifact, not a design.
- **Clients and services so coupled as to have no architectural significance whatever**: hoped to be rare; experience suggests otherwise.

## Worked Example
**The taxi aggregator and the Kitty Problem.**

The system knows many taxi providers in a city and lets customers order rides, selecting on pickup time, cost, luxury, and driver experience. The architects chose micro-services for scalability:

| Service | Responsibility |
|---|---|
| `TaxiUI` | Deals with customers ordering taxis on mobile devices |
| `TaxiFinder` | Examines inventories of the various `TaxiSuppliers`, determines candidate taxis, deposits them in a short-term data record attached to the user |
| `TaxiSelector` | Applies the user's criteria (cost, time, luxury, …) to choose a taxi from the candidates |
| `TaxiDispatcher` | Orders the chosen taxi |

After a year in operation, marketing announces **kitten delivery**. Customers order kittens delivered to home or office; the company sets up kitten collection points across the city; a nearby taxi collects a kitten and delivers it. One supplier agrees to participate, others may decline. Drivers allergic to cats must never be selected. A vehicle used for kitten delivery within the last 3 days must not be selected for customers who declare allergies.

How many services must change? **All of them.** `TaxiUI` needs kitten ordering, `TaxiFinder` needs supplier participation, `TaxiSelector` needs the allergy and 3-day rules, `TaxiDispatcher` needs collection-point routing. The services are all coupled and cannot be independently developed, deployed, and maintained.

**Objects to the rescue.** In a component-based design, classes roughly corresponding to those services live behind boundaries obeying the Dependency Rule. Most of the original logic stays in abstract base classes; the ride-specific portion is extracted into a `Rides` component, and the kitten feature goes into a new `Kittens` component. Both override the abstract base classes using Template Method or Strategy, and both are instantiated by factories under the control of the UI. Now only `TaxiUI` changes; the kitty feature ships as a new jar/Gem/DLL added to the system and dynamically loaded at runtime.

**Component-based services.** Apply the same trick inside each service. The services remain as before, but each gets its own internal component design so new features arrive as new derivative classes in their own components. The architectural boundaries now run through the services.

## Key Takeaways
1. Services are function calls across process/platform boundaries. Ask of each one whether it separates high-level policy from low-level detail and obeys the Dependency Rule — if not, it is not architecturally significant.
2. Decoupling by process is decoupling at the variable level only. Shared data records, shared semantics, and shared resources keep services strongly coupled.
3. Independent deployability is real only to the degree the services are genuinely uncoupled; coupled services need coordinated development, deployment, and operation.
4. Cross-cutting concerns are the acid test. Take a plausible new feature, run it through the service diagram, and count the services that change.
5. Design services with internal component architectures following the Dependency Rule, so features are added as new derivative components — OCP at the service scale.
6. A service may be a single component surrounded by one boundary, or several components separated by boundaries. Both are legitimate; which one you have is an architectural fact, not a deployment fact.
7. Services buy scalability and develop-ability. Do not buy them expecting an architecture — you have to design that separately.

## Connects To
- **Ch 17 (Boundaries: Drawing Lines)**: services are one of the most expensive boundary mechanisms available; this chapter is the cost/benefit check.
- **Ch 18 (Boundary Anatomy)**: services as a boundary crossing type, alongside local processes, threads, and function calls.
- **Ch 8 (OCP)**: adding features as new jar files rather than edits to existing ones is the OCP applied at deployment scale.
- **Ch 22 (The Clean Architecture)**: the internal component design each service should have.
- **Ch 25 (Layers and Boundaries)**: same lesson — boundaries are not where the obvious physical seams are.
- **Conway's Law**: one-service-per-team topologies encode the org chart into the deployment diagram; the Kitty Problem shows what happens when a feature does not respect that chart.
- **Aspect-Oriented Programming**: an alternative answer to the cross-cutting concern problem that Martin instead solves with polymorphic components.
