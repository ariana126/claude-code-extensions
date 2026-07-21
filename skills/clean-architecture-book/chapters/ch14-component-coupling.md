# Chapter 14: Component Coupling

## Core Idea
Three principles govern the relationships *between* components: allow no cycles in the dependency graph (ADP), depend in the direction of stability (SDP), and make a component as abstract as it is stable (SAP) — and the last two combined are the DIP for components, measurable with the I, A, and D metrics.

## Frameworks Introduced
- **ADP: The Acyclic Dependencies Principle** — *"Allow no cycles in the component dependency graph."*
  - When to use: continuously, on any project large enough that more than one developer touches shared code.
  - How: (1) partition the development environment into releasable components, each owned by a developer or team; (2) when a component works, give it a release number and publish it; other teams keep using the old release until *they* choose to adopt the new one; (3) keep the dependency structure a directed acyclic graph (DAG) — components are nodes, dependencies are directed edges; (4) monitor for cycles continuously and break each one as it appears.
  - Why it works / failure mode: with a DAG you find the blast radius of a release by following arrows backward, you can test a component by building only what it depends on, and you release bottom-up in an obvious order. With a cycle, the components in it effectively become one large component — everyone must use exactly the same release of everyone else's work, unit tests drag in unrelated libraries, build order may not exist at all, and build issues grow geometrically with the number of modules. That is "the morning after syndrome."
- **Breaking a Cycle** — two primary mechanisms; it is *always* possible to reinstate the DAG.
  - How (1) **Apply the DIP**: create an interface declaring the methods the client needs, put that interface in the *client's* component, and have the far component inherit/implement it. This inverts the offending dependency. (2) **Create a new component**: extract the class(es) both components depend on into a new component that both then depend on.
  - Why it works: both convert an upward-pointing arrow into a downward one without changing behavior. Consequence: the component structure jitters and grows as requirements change — that is expected, not a defect.
- **SDP: The Stable Dependencies Principle** — *"Depend in the direction of stability."*
  - When to use: whenever adding a dependency, especially from something hard to change onto something designed to be easy to change.
  - How: (1) compute I = Fan-out / (Fan-in + Fan-out) for each component; (2) require the I metric of a component to be *larger* than the I metrics of the components it depends on — I must decrease in the direction of dependency; (3) draw unstable components at the top of the diagram so any arrow pointing *up* is visibly an SDP (and ADP) violation; (4) fix a violation with the DIP — extract an interface into its own abstract component that both sides depend on.
  - Why it works / failure mode: stability means "not easily moved," not "rarely changed" — a component with many incoming dependencies is hard to change because every change must be reconciled with all dependents. Failure mode: someone in a stable component hangs a dependency on your Flexible component; not a line of your code changes, yet your component is now hard to change.
- **SAP: The Stable Abstractions Principle** — *"A component should be as abstract as it is stable."*
  - When to use: when placing high-level policy, and when auditing whether a stable component is extensible.
  - How: (1) put high-level architecture and policy into stable components (I = 0); (2) make those components consist of interfaces and abstract classes so they can be extended without modification (OCP); (3) keep unstable components (I = 1) concrete, since instability makes concrete code easy to change; (4) measure A = Na ÷ Nc.
  - Why it works: SDP says dependencies run toward stability, SAP says stability implies abstraction — therefore dependencies run in the direction of abstraction. SDP + SAP = the DIP for components, but with shades of gray: a class is abstract or not, whereas a component can be partially abstract and partially stable.

## Key Concepts
- **The morning after syndrome**: You arrive to find your working code broken because somebody stayed later and changed something you depend on.
- **The weekly build**: Developers ignore each other four days a week and integrate on Friday; as the project grows, integration overflows into Saturday, then Thursday, then biweekly, and the develop-versus-integrate duty cycle collapses.
- **Directed acyclic graph (DAG)**: A dependency structure in which, starting from any component, you cannot follow dependencies back to that component.
- **Fan-in**: Incoming dependencies — the number of classes outside the component that depend on classes within it.
- **Fan-out**: Outgoing dependencies — the number of classes inside the component that depend on classes outside it.
- **I (Instability)**: I = Fan-out / (Fan-in + Fan-out), range [0, 1]. I = 0 is maximally stable (responsible and independent); I = 1 is maximally unstable (irresponsible and dependent).
- **A (Abstractness)**: A = Na ÷ Nc, where Nc is the number of classes in the component and Na the number of abstract classes and interfaces. Range [0, 1].
- **Abstract component**: A component containing nothing but interfaces — no executable code — a necessary tactic in statically typed languages like Java and C#, and an ideal dependency target. In dynamically typed languages like Ruby and Python these components don't exist at all.
- **The Main Sequence**: The line connecting (1, 0) and (0, 1) on the A/I graph — the locus of points maximally distant from both zones of exclusion.
- **D (Distance)**: D = |A + I – 1|, range [0, 1]. 0 means directly on the Main Sequence; 1 means as far from it as possible.
- **The "jitters"**: The component structure is volatile under changing requirements; the dependency graph jitters and grows as cycles appear and are broken.

## Mental Models
- Think of stability as *how much work it takes to move something*, not how often it moves. A penny on its edge sits unchanged for years and is not stable; a table is stable because turning it over takes effort. Incoming dependencies are what make a component heavy.
- Use "unstable on top" as a drawing convention: once volatile components are at the top of the diagram, every SDP and ADP violation is literally an arrow pointing up.
- Think of component dependency diagrams as a map of *buildability and maintainability*, not of function. That is why they cannot be designed top-down — there is nothing to build or maintain at the start.
- Use volatility as an invisible third axis on the A/I graph. A concrete, heavily depended-on component at (0, 0) is only painful if it is *volatile* — a database schema hurts, the `String` component doesn't.
- Use D over time as a control chart: plot D per component per release, set a control threshold (e.g. D = 0.1), and investigate any component that crosses it.

## Reference Tables

**Dependency management metrics**

| Metric | Formula | Range | Meaning at 0 | Meaning at 1 |
|---|---|---|---|---|
| Fan-in | count of outside classes depending on classes inside | ≥ 0 | nothing depends on it (irresponsible) | — |
| Fan-out | count of inside classes depending on classes outside | ≥ 0 | depends on nothing (independent) | — |
| **I** (Instability) | I = Fan-out / (Fan-in + Fan-out) | [0, 1] | maximally stable: responsible and independent | maximally unstable: irresponsible and dependent |
| **A** (Abstractness) | A = Na ÷ Nc | [0, 1] | no abstract classes at all | nothing but abstract classes |
| **D** (Distance) | D = \|A + I – 1\| | [0, 1] | directly on the Main Sequence | as far from the Main Sequence as possible |

*In C++, dependencies are typically counted from `#include` statements; in Java, from `import` statements and qualified names. Easiest to calculate with one class per source file. (Fan-out/Fan-in were formerly called Efferent/Afferent coupling, Ce/Ca.)*

**Zones of exclusion on the A/I graph**

| Zone | Position | Character | Why it's bad | Examples |
|---|---|---|---|---|
| **Zone of Pain** | (0, 0) | highly stable, highly concrete | Rigid: cannot be extended (not abstract), very hard to change (highly depended on) | Database schema — volatile, concrete, heavily depended on, hence painful schema updates |
| Harmless corner of (0,0) | (0, 0), volatility ≈ 0 | stable, concrete, nonvolatile | Not a problem — it isn't going to change | A concrete `String` utility component |
| **Zone of Uselessness** | (1, 1) | maximally abstract, no dependents | Detritus: leftover abstract classes nobody ever implemented, sitting unused | Orphaned interface hierarchies |
| **Main Sequence** | line (1, 0) ↔ (0, 1) | neither too abstract for its stability nor too unstable for its abstractness | The target: depended on to the extent it is abstract, depends on others to the extent it is concrete | Ideal: the two endpoints |

**The three coupling principles**

| Principle | Statement | Enforced by |
|---|---|---|
| ADP — Acyclic Dependencies | Allow no cycles in the component dependency graph | DAG check; break cycles via DIP or a new component |
| SDP — Stable Dependencies | Depend in the direction of stability | I decreases in the direction of dependency |
| SAP — Stable Abstractions | A component should be as abstract as it is stable | A rises as I falls; SDP + SAP = DIP for components |

## Worked Example

**1. The cycle.** A typical application has components `Main`, `View`, `Presenters`, `Controllers`, `Authorizer`, `Interactors`, `Database`, `Entities` arranged as a DAG. Releasing `Presenters` affects only `View` and `Main` (follow arrows backward). Releasing `Main` affects nothing. Building the system runs bottom-up: `Entities`, then `Database` and `Interactors`, then `Presenters`, `View`, `Controllers`, `Authorizer`, and `Main` last.

Now a new requirement makes `User` in `Entities` use `Permissions` in `Authorizer`. `Authorizer` depends on `Interactors`, which depends on `Entities` — a cycle. Consequences: `Database` must now be compatible with `Authorizer` *and* `Interactors` to release; `Entities`, `Authorizer`, and `Interactors` have effectively become one large component; unit-testing `Entities` requires building and integrating `Authorizer` and `Interactors`.

**Fix A (DIP):** create an interface with the methods `User` needs, put it in `Entities`, and have `Authorizer` inherit it. The `Entities` → `Authorizer` dependency inverts; the cycle breaks.
**Fix B (new component):** move the shared class(es) into a new component that both `Entities` and `Authorizer` depend on.

**2. Computing I.** For component `Cc`: three classes outside `Cc` depend on classes inside it, so Fan-in = 3. One class outside `Cc` is depended on by classes inside it, so Fan-out = 1.

    I = Fan-out / (Fan-in + Fan-out) = 1 / (3 + 1) = 1/4 = 0.25

`Cc` is fairly stable. Under SDP, every component `Cc` depends on must have an I *lower* than 0.25.

**3. Fixing an SDP violation.** `Flexible` (designed to be easy to change, I ≈ 1) is depended on by `Stable` (I ≈ 0) because class `U` in `Stable` uses class `C` in `Flexible`. Arrow points up. Fix: create interface `US` declaring every method `U` needs, put it in a new component `UServer`, and make `C` implement `US`. Now `Stable` → `UServer` ← `Flexible`. `UServer` is very stable (I = 0), `Flexible` keeps its necessary instability (I = 1), and all dependencies flow in the direction of decreasing I.

**4. Computing A and D.** Suppose `UServer` has Nc = 4 classes of which Na = 4 are interfaces: A = 4/4 = 1, I = 0, so D = |1 + 0 – 1| = 0 — exactly on the Main Sequence. Suppose `Payroll` has Nc = 20, Na = 2 → A = 0.1, and I = 0.2. Then D = |0.1 + 0.2 – 1| = 0.7 — deep toward the Zone of Pain, well past a D = 0.1 control threshold. Reexamine and restructure.

**5. Statistical use.** Compute the mean and variance of D across all components; a conforming design has both near zero. Use the variance to set control limits and flag components more than one standard deviation (Z = 1) from the mean — they are either very abstract with few dependents or very concrete with many dependents. Plot D per component across releases to catch strange dependencies creeping in.

## Key Takeaways
1. Break every cycle the moment it appears — a cycle fuses its components into one, resurrecting the morning after syndrome and making unit tests drag in the world.
2. Break cycles two ways only: invert the dependency with the DIP, or extract the shared classes into a new component both sides depend on.
3. Do not design the component structure top-down. It is a map of buildability and maintainability, so it evolves with the code — CCP first, then CRP as reusable elements emerge, then ADP as cycles appear.
4. Stability means hard to move, not slow to change. Measure it: I = Fan-out / (Fan-in + Fan-out), and require I to decrease in the direction of dependency.
5. Make stable components abstract (A = Na / Nc) so their stability doesn't make them rigid. Abstract components containing only interfaces are the ideal dependency target in statically typed languages.
6. Keep volatile components off (0, 0) — the Zone of Pain — and off (1, 1) — the Zone of Uselessness. Aim for the endpoints of the Main Sequence, and use D = |A + I – 1| to find the strays.
7. Treat these as measurements against an arbitrary standard, not laws. A metric is not a god; it is imperfect but useful.

## Connects To
- **Ch 12**: Independent deployability is exactly what a dependency cycle destroys.
- **Ch 13**: CCP and CRP shape component *contents*; this chapter shapes the arrows between them, and both chapters end on the same theme — the structure jitters and evolves.
- **Ch 11 (DIP)**: SDP + SAP together are the DIP applied at component granularity, with shades of gray a class cannot have.
- **Ch 8 (OCP)**: Abstract classes are what let a maximally stable component still be extended without modification.
- **Continuous Integration**: The modern answer to the weekly build's collapsing duty cycle — small, frequent integrations rather than one Friday reckoning.
- **Isolation of volatility / Plugin architecture (Part V–VI)**: The dependency graph is molded by architects specifically to protect stable high-value components from volatile ones.
