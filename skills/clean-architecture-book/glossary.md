# Clean Architecture — Glossary

**Abstract Factory** — Pattern letting a high-level component create concrete instances without depending on their names; the interface lives inside, the implementation outside (Ch11, Ch26).

**Abstractness (A)** — `A = Na / Nc`: abstract classes and interfaces divided by total classes in a component. Range 0–1 (Ch14).

**Accidental Duplication** — Two pieces of code that look alike now but change for different reasons; unifying them is a mistake. Contrast with true duplication (Ch16).

**Acyclic Dependencies Principle (ADP)** — Allow no cycles in the component dependency graph (Ch14).

**Actor** — The person or group that requests a change to a module. The unit of responsibility in the SRP (Ch7).

**Application-Specific Business Rule** — A rule that exists only because the business is automated; lives in the Use Case layer (Ch20).

**Architecture** — The shape given to a system by the way it is divided into components, and the way those components communicate. Its purpose is to support development, deployment, operation, and maintenance — and to leave as many options open as possible (Ch15).

**Boundary** — A line across which source code dependencies are controlled and inverted. Separates things that matter from things that don't (Ch17).

**Boundary Crossing** — A call across an architectural line, ranging from a function call in a monolith to a network hop between services; cost rises with the strength of the boundary (Ch18).

**Common Closure Principle (CCP)** — Gather into a component the classes that change for the same reasons at the same times; the component form of the SRP (Ch13).

**Common Reuse Principle (CRP)** — Don't force users of a component to depend on things they don't need; the component form of the ISP (Ch13).

**Component** — The smallest unit of deployment — a jar, gem, DLL, or shared library (Ch12).

**Concrete Component Rule** — Every system has at least one concrete component; keep it small and push all concrete dependencies into it (usually `Main`) (Ch11).

**Critical Business Rule** — A rule that would be true whether or not the business were automated; lives in the Entities layer (Ch20).

**Decoupling Mode** — Source level, deployment level, or service level. The decision should be deferred as long as possible and remain reversible (Ch16).

**Dependency Inversion Principle (DIP)** — Depend on abstractions, not concretions; the most flexible systems refer only to abstract interfaces (Ch11).

**Dependency Rule** — *Source code dependencies must point only inward, toward higher-level policies.* The overriding rule of the Clean Architecture (Ch22).

**Detail** — Anything the business rules should not know about: the database, the web, the UI, the framework, the device (Part VI).

**Device Independence** — Writing to an abstract I/O interface rather than a specific device; the archetypal architectural win (Ch15, Appendix A).

**Distance from the Main Sequence (D)** — `D = |A + I − 1|`, range 0–1. 0 means the component sits on the Main Sequence (Ch14).

**Entity** — An object or data structure encapsulating enterprise-wide Critical Business Rules; the innermost circle (Ch20, Ch22).

**Event Sourcing** — Storing transactions rather than state and deriving state by replay; eliminates mutable variables (Ch6).

**Facade** — The cheapest partial boundary: a single class delegating to a set of services, with no dependency inversion (Ch24).

**Fan-in** — Incoming dependencies: classes outside a component that depend on classes inside it (Ch14).

**Fan-out** — Outgoing dependencies: classes inside a component that depend on classes outside it (Ch14).

**Fragile Tests Problem** — Tests coupled to the app's structure (typically through the GUI) that break on every refactor (Ch28).

**Frameworks & Drivers** — The outermost circle: databases, web servers, devices, third-party frameworks (Ch22).

**Hardware Abstraction Layer (HAL)** — An interface expressing the services the software needs from hardware, not the hardware's register map (Ch29).

**Humble Object Pattern** — Split a module into a testable half holding all behavior and an untestable "humble" half holding as little as possible (Ch23).

**Independent Deployability / Developability** — Two of the benefits a good component boundary buys; neither is granted automatically by using services (Ch16, Ch27).

**Instability (I)** — `I = Fan-out / (Fan-in + Fan-out)`, range 0–1. 0 = maximally stable, 1 = maximally unstable (Ch14).

**Interface Adapters** — The third circle: controllers, presenters, gateways — code that converts data between use-case form and external form (Ch22).

**Interface Segregation Principle (ISP)** — Avoid depending on modules that carry baggage you don't use (Ch10).

**Level** — Distance from the inputs and outputs. Higher level = farther from I/O; dependencies should point toward higher levels (Ch19).

**Liskov Substitution Principle (LSP)** — Subtypes must be substitutable for their base types without the caller needing to know which it has (Ch9).

**Main Component** — The dirtiest, lowest-level component; creates and injects everything, then hands control to higher-level policy. The initial plugin (Ch26).

**Main Sequence** — The line `A + I = 1` on the abstractness/instability graph; components should sit on or near it, ideally at its endpoints (Ch14).

**Open-Closed Principle (OCP)** — A software artifact should be open for extension but closed for modification; the primary driver of architectural structure (Ch8).

**Package by Component** — Organizing code as coarse-grained components with a public interface and package-private internals (Ch34).

**Package by Layer / by Feature / Ports and Adapters** — The three alternative packaging strategies Brown compares against Package by Component (Ch34).

**Partial Boundary** — A boundary built at reduced cost — Skip the Last Step, One-Dimensional Boundary, or Facade — that can be upgraded later (Ch24).

**Plugin Architecture** — Structure in which volatile mechanisms are plugins to stable business rules, achieved by inverting the dependency (Ch5, Ch17).

**Policy** — A statement of a business rule or a procedure that computes something; systems are trees of policy statements grouped by how and why they change (Ch19).

**Presenter** — The testable half of a UI Humble Object; produces a View Model the View blindly renders (Ch23).

**Reuse/Release Equivalence Principle (REP)** — The granule of reuse is the granule of release; components must be tracked and released as versioned units (Ch13).

**Screaming Architecture** — A structure whose top-level organization announces the system's use cases, not its framework (Ch21).

**Single Responsibility Principle (SRP)** — A module should be responsible to one, and only one, actor (Ch7).

**Skip the Last Step** — The strongest partial boundary: do the full component design but deploy as a single component (Ch24).

**Stable Abstractions Principle (SAP)** — A component should be as abstract as it is stable (Ch14).

**Stable Dependencies Principle (SDP)** — Depend in the direction of stability; `I` should decrease along each dependency (Ch14).

**Structured Programming** — Discipline imposed on direct transfer of control; removes `goto` (Ch4).

**Target Hardware Bottleneck** — The condition where code can only be tested on the target board, throttling all development (Ch29).

**Tension Diagram** — The triangle showing REP, CCP, and CRP pulling against each other; the balance shifts over a project's life (Ch13).

**Testing API** — A dedicated API letting tests verify behavior without coupling to app structure, security, or the UI (Ch28).

**True Duplication** — Two pieces of code that must change together forever; the only kind worth eliminating (Ch16).

**Use Case** — A description of the way an automated system is used, holding application-specific business rules; the second circle (Ch20, Ch22).

**Zone of Pain** — Region near (A=0, I=0): concrete and heavily depended on, e.g. a database schema. Painful only when volatile (Ch14).

**Zone of Uselessness** — Region near (A=1, I=1): abstract with no dependents — dead abstraction (Ch14).
