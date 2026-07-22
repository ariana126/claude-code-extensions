# Chapter 6: Measuring and Governing Architecture Characteristics

## Core Idea
Vague "-ilities" become governable only when decomposed into **objectively measurable** definitions and then enforced automatically by **fitness functions** — any mechanism providing an objective integrity assessment of an architecture characteristic.

## Frameworks Introduced

- **The Three Reasons Characteristics Resist Definition** — diagnose which one you're facing:
  1. **They aren't physics.** Terms have vague meanings. How do you design for *agility*, *deployability*, or *wicked fast performance*? Perspectives differ across the industry, sometimes for legitimate contextual reasons, sometimes accidentally.
  2. **Wildly varying definitions.** Even inside one organization, departments disagree on what *performance* means. Without a unified definition there is no proper conversation.
  3. **Too composite.** Many desirable characteristics are collections of smaller ones (agility → modularity + deployability + testability).
  - **The single fix for all three**: decompose composites into constituent parts and agree on concrete definitions — creating a **ubiquitous language** around architecture that exposes objectively measurable features.

- **The Three Kinds of Measures**:
  - **Operational measures** — performance, scalability, availability. Nuanced: measuring *average* response time hides the 1% of requests taking 10× longer, so also measure **maximum** response times. High-level teams don't set arbitrary numbers; they build **statistical models** over time and alarm when real-time metrics fall outside prediction. A miss means either the model is wrong or something is amiss — teams want to know both.
  - **Structural measures** — no comprehensive metric for architecture quality exists, but narrow-dimension metrics do: Cyclomatic Complexity, LCOM, Distance from the Main Sequence (Ch 3).
  - **Process measures** — testability via code-coverage tools; deployability via percentage of successful deployments, deployment duration, and issues/bugs raised by deployments. Process characteristics can drive *structure*: if deployability and testability are high priorities, the architect emphasizes modularity and isolation at the architecture level.

- **Cyclomatic Complexity (CC)** — Thomas McCabe Sr., 1976. An objective complexity measure at the function/method, class, or application level, computed by applying graph theory to **decision points**.
  - Formula (single function): `CC = E − N + 2`, where `N` = nodes (lines of code) and `E` = edges (possible decisions).
  - General formula (with fan-out to other methods, i.e. **connected components**): `CC = E − N + 2P`, where `P` = number of connected components.
  - Baseline: no decision statements → `CC = 1`; a single conditional → `CC = 2`.
  - **Thresholds**: the industry generally accepts **under 10**; the authors consider that very high and prefer **under 5**, indicating cohesive, well-factored code. `Crap4J` combines CC with code coverage — past **CC 50**, no amount of coverage rescues the code. (Neal's worst find: a single C function of 4,000+ lines with `CC > 800`, using `GOTO` to escape deeply nested loops.)
  - **Interpretation questions**: is the function complex because of the *problem domain* or because of *poor coding*? Is the code partitioned poorly — could a large method be broken into smaller, logical, well-factored chunks that distribute the complexity?
  - **AI note**: CC is useful for assessing code from developers *or* generative AI — generative AI tends to solve problems by brute force, producing accidental complexity.
  - **TDD side effect**: writing a simple test, then the smallest code to pass it, encourages discrete behavior and good test boundaries — yielding smaller methods with naturally low CC.

- **Fitness Functions** — from *Building Evolutionary Architectures* (Ford et al., O'Reilly 2022). The term comes from **evolutionary computing**, not biology: in a genetic algorithm, a fitness function is an objective measure of how close the output comes to its aim (e.g. for the traveling salesperson problem, separate fitness functions for route length, cost, and time away).
  - **Architectural fitness function**: *any mechanism that provides an objective integrity assessment of some architecture characteristic or combination of architecture characteristics.*
  - **Not a framework to download** — a new perspective on existing tools. "Any mechanism" means chaos engineering, metrics, monitors, or unit-testing libraries, depending on use.
  - **Purpose**: guard the **important rather than urgent** practices. Modularity is the archetype: critical to architects, near-zero impact on day-to-day coding, therefore the first thing sacrificed under schedule pressure.

- **Governance** — from the Greek *kubernan*, "to steer." Covers any aspect of the software development process the architect wants to influence, including software quality. Lineage: Extreme Programming's automation drive → continuous integration → DevOps → automated architectural governance.

## Code Examples

**Cyclomatic Complexity evaluation (Example 6-1)** — `CC = 3 − 2 + 2 = 3`:
```c
public void decision(int c1, int c2) {
    if (c1 < 100)
        return 0;
    else if (c1 + C2 > 500)
       return 1;
    else
      return -1;
}
```
- **What it demonstrates**: two decision points produce three execution paths.

**Cycle-detection fitness function with JDepend (Example 6-2)**:
```java
public class CycleTest {
    private JDepend jdepend;

    @BeforeEach
    void init() {
      jdepend = new JDepend();
      jdepend.addDirectory("/path/to/project/persistence/classes");
      jdepend.addDirectory("/path/to/project/web/classes");
      jdepend.addDirectory("/path/to/project/thirdpartyjars");
    }

    @Test
    void testAllPackages() {
      Collection packages = jdepend.analyze();
      assertEquals("Cycles exist", false, jdepend.containsCycles());
    }
}
```
- **What it demonstrates**: wire this into the continuous build and stop worrying about trigger-happy developers reflexively accepting the IDE's auto-import dialog and creating cyclic dependencies.

**Distance from the Main Sequence fitness function (Example 6-3)**:
```java
@Test
void AllPackages() {
    double ideal = 0.0;
    double tolerance = 0.5; // project-dependent
    Collection packages = jdepend.analyze();
    Iterator iter = packages.iterator();
    while (iter.hasNext()) {
      JavaPackage p = (JavaPackage)iter.next();
      assertEquals("Distance exceeded: " + p.getName(),
        ideal, p.distance(), tolerance);
    }
}
```
- **What it demonstrates**: turning an esoteric structural metric into an enforced threshold.

**ArchUnit layer governance (Example 6-4)** — Java, inspired by and using parts of the JUnit ecosystem:
```java
layeredArchitecture()
    .layer("Controller").definedBy("..controller..")
    .layer("Service").definedBy("..service..")
    .layer("Persistence").definedBy("..persistence..")

    .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
    .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
    .whereLayer("Persistence").mayOnlyBeAccessedByLayers("Service")
```
- **What it demonstrates**: encoding a layered architecture's rules so developers can't erode them with "better to ask forgiveness than permission" shortcuts.

**NetArchTest layer dependencies (Example 6-5)** — the .NET equivalent:
```csharp
// Classes in the presentation should not directly reference repositories
var result = Types.InCurrentDomain()
    .That()
    .ResideInNamespace("NetArchTest.SampleLibrary.Presentation")
    .ShouldNot()
    .HaveDependencyOn("NetArchTest.SampleLibrary.Data")
    .GetResult()
    .IsSuccessful;
```

## Key Concepts

- **Fitness function** — objective integrity assessment of a characteristic; the unit of automated governance.
- **Governance** — steering any aspect of the development process the architect must influence.
- **Cyclic dependencies** — components that reference each other in a network; you cannot reuse one without dragging the others along. Tends toward the **Big Ball of Mud**.
- **K-weight budget** — a maximum number of bytes of libraries and frameworks allowed on a page. Rationale is physics: only so many bytes travel a network at a time, especially on mobile in low-bandwidth areas.
- **First contentful paint / first CPU idle** — modern web performance budget metrics that speak volumes about mobile user experience.
- **Chaos engineering** — a discipline born at Netflix when moving to AWS removed their control over operations.

## Mental Models

- **Fitness functions are checklists, not bureaucracy.** Atul Gawande's *The Checklist Manifesto* — pilots and surgeons use checklists not because they're forgetful, but because doing a highly detailed job repeatedly makes details slip. Developers *know* not to release insecure code; it just competes with hundreds of other priorities. Fitness functions build governance into the substrate of the architecture.
- **Code review is too late.** If a team imports rampantly for a week before the review, the damage is done. Automate at commit time.
- **Not *if* something breaks, but *when*.** Chaos engineering's reframe: anticipating breakages and testing to prevent them makes systems much more robust.
- **Every metric will be gamed.** Once developers learn how compliance is measured, some code to the metric — unit tests with no assertions "touch" the code and inflate coverage without verifying anything. Fitness functions can enforce that every test has at least one assertion. Dedicated rule-breakers will always find a way; the goal is preventing *accidental* lapses.
- **Metrics are blunt.** CC measures complexity but can't tell **essential** (the problem is hard) from **accidental** (the design is poor). Establish baselines so you can judge which you have.

## Worked Example

**Netflix's Simian Army — fitness functions in production.** When Netflix moved operations to AWS, its architects lost control over operations and worried about defects appearing operationally. Their answer was to run fitness functions *against production*:

| Monkey | What it governs |
|---|---|
| **Chaos Monkey** | Simulates general chaos to see how well the system endures it |
| **Latency Monkey** | A specialization built because AWS latency was such a persistent problem |
| **Chaos Kong** | Simulates an entire Amazon datacenter failure — has helped Netflix survive real ones |
| **Conformity Monkey** | Enforces architect-defined governance rules in production (e.g. every service must respond without errors for all requests) |
| **Security Monkey** | Checks each service for well-known security defects — ports that shouldn't be active, configuration errors |
| **Janitor Monkey** | Finds instances no other service routes to anymore and disintegrates them out of production |

The Janitor Monkey exists because Netflix has an *evolutionary* architecture: developers routinely migrate to newer services, leaving old ones running with no collaborators — and running services on the cloud costs money.

**The pattern to copy**: identify the architectural rule that matters, decide whether it is checkable at build time (JDepend, ArchUnit) or only in production (Conformity, Security), then automate it there.

## Anti-patterns

- **Ivory-tower fitness functions** — architects ascending to write esoteric rules developers can't understand. *"Architects must ensure that developers understand the purpose of a fitness function before imposing it on them."* Design and implement them collaboratively.
- **Cyclic dependencies** — accumulated one auto-import dialog at a time.
- **Measuring only averages** — outliers vanish at scale.
- **Coding to the metric** — coverage without assertions.
- **Overly complex code** — a "code smell" so bad it has an imaginary odor. It harms modularity, testability, deployability, and nearly every other desirable characteristic. Left unwatched, complexity comes to dominate the code base.

## Key Takeaways
1. Decompose composites and agree on concrete definitions first — measurement and governance are impossible without a ubiquitous language.
2. Measure maximums and distributions, not just averages; graduate to statistical models with alarms on deviation.
3. Keep Cyclomatic Complexity under 5 where the domain permits; investigate whether high CC is essential or accidental.
4. Treat fitness functions as a *perspective on existing tools*, not a new framework — metrics, monitors, unit tests, and chaos experiments all qualify.
5. Automate the **important but not urgent** rules (modularity, layer dependencies, cycles) into the continuous build, where schedule pressure can't erode them.
6. Use ArchUnit (Java) or NetArchTest (.NET) to encode layer and dependency rules as tests.
7. Extend governance into production where build-time checks can't reach — Netflix's Conformity, Security, and Janitor Monkeys are the model.
8. Explain every fitness function before imposing it; governance without comprehension breeds workarounds.

## Connects To
- **Ch 3**: the structural metrics being governed — CC, LCOM, Distance from the Main Sequence, cyclic dependencies.
- **Ch 4**: the characteristics being measured, and the ubiquitous language recommendation.
- **Ch 5**: composite characteristics that must be decomposed before they can be measured.
- **Ch 10**: layered architecture — the structure the ArchUnit example is protecting.
- **Ch 22**: analyzing architecture risk — the complementary manual assessment.
- **External**: *Building Evolutionary Architectures* (Ford et al.), *Chaos Engineering* (Rosenthal & Jones), *The Checklist Manifesto* (Gawande).
