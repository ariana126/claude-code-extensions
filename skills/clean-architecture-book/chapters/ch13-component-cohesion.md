# Chapter 13: Component Cohesion

## Core Idea
Which classes belong in which component is decided by three competing principles — REP, CCP, and CRP — and there is no permanent right answer: a good architect picks a position in the tension triangle that fits the team's *current* concerns and moves it as the project matures.

## Frameworks Introduced
- **REP: The Reuse/Release Equivalence Principle** — *"The granule of reuse is the granule of release."*
  - When to use: whenever a component is meant to be consumed by anyone outside the team that writes it.
  - How: (1) track the component through a release process; (2) give it a release number; (3) publish release documentation and notifications describing what changed, so consumers can decide whether to integrate; (4) ensure the classes grouped in it form a cohesive group with an overarching theme — they must be *releasable together*, sharing a version number and release tracking that makes sense to both author and user.
  - Why it works / failure mode: people cannot and will not reuse components that are not released and numbered — there is no way to know compatibility or what a new release brings. The principle is admittedly weak advice ("it should make sense"), but violations are easy to detect: the grouping doesn't make sense, and your users will notice.
- **CCP: The Common Closure Principle** — *"Gather into components those classes that change for the same reasons and at the same times. Separate into different components those classes that change at different times and for different reasons."*
  - When to use: always during active development; for most applications maintainability matters more than reusability.
  - How: (1) identify the axes of change you expect or have experienced; (2) gather into one component the classes closed to the same *types* of change; (3) if two classes are so tightly bound, physically or conceptually, that they always change together, put them in the same component; (4) verify: when a requirement changes, only one component should need redeploying, and components that don't depend on it need no revalidation or redeployment.
  - Why it works / failure mode: this is the SRP restated for components — a component should not have multiple reasons to change. It is "closure" in the OCP sense: 100% closure is unattainable, so closure must be *strategic*, aimed at the most common expected changes. Failure mode: a change scatters across many components, multiplying release, revalidation, and redeployment work.
- **CRP: The Common Reuse Principle** — *"Don't force users of a component to depend on things they don't need."*
  - When to use: when deciding what to *exclude* from a component, and when reviewing a dependency you only partially use.
  - How: (1) put classes that tend to be reused together in the same component — expect lots of mutual dependencies inside it; (2) make the contents inseparable, so it is impossible to depend on some and not the others; (3) split out any class not tightly bound to the rest. Classic pair: a container class and its associated iterators belong together.
  - Why it works: when you depend on a component you depend on *all* of it — every change to the used component means the using component is likely recompiled, revalidated, and redeployed, even for changes it doesn't care about.

## Key Concepts
- **Component cohesion**: The set of forces determining which classes and modules belong together in a single deployable component.
- **Granule of release**: The versioned, documented, tracked unit that consumers actually adopt — under REP, identical to the granule of reuse.
- **Strategic closure**: Because 100% closure is impossible, designing classes to be closed against the most common kinds of change you expect or have experienced.
- **Inclusive principle**: REP and CCP — both push toward *larger* components.
- **Exclusive principle**: CRP — pushes toward *smaller* components.
- **The Tension Diagram**: The triangle whose vertices are REP, CCP, and CRP and whose edges describe the *cost of abandoning the principle on the opposite vertex*.
- **Develop-ability vs. reusability**: The core trade-off; early projects favor develop-ability (CCP), mature ones shift toward reusability (REP).
- **Relation to SRP**: CCP is the component form of SRP — SRP separates methods into classes, CCP separates classes into components, by reason to change.
- **Relation to ISP**: CRP is the generic version of ISP — ISP says don't depend on classes with methods you don't use; CRP says don't depend on components with classes you don't use.

## Mental Models
- Think of REP + CCP as centripetal and CRP as centrifugal: two forces inflate the component, one deflates it, and architecture is choosing where they balance today.
- Use the sound bite when partitioning at *any* granularity: "Gather together those things that change at the same times and for the same reasons. Separate those things that change at different times or for different reasons."
- Use the reduction "Don't depend on things you don't need" whenever you're about to pull in a component for one class.
- Think of component structure as a position that *drifts*, not a decision that's made: projects start on the right side of the triangle (sacrificing reuse) and slide left as other projects begin drawing from them.

## Reference Tables

**The Tension Diagram for Component Cohesion** (vertices = principles; each edge names the cost of abandoning the principle on the *opposite* vertex):

| Edge (principles you emphasize) | Principle sacrificed | Cost you pay |
|---|---|---|
| REP + CRP (reuse-focused) | CCP | Too many components are impacted when simple changes are made |
| REP + CCP (release-focused) | CRP | Too many unneeded releases are generated (users get changes they don't need) |
| CCP + CRP (development-focused) | REP | Reuse is sacrificed — the component is hard for others to consume |

**Direction and life cycle:**

| Project phase | Dominant concern | Dominant principle | Position in the triangle |
|---|---|---|---|
| Early development | Develop-ability | CCP | Right-hand side; only sacrifice is reuse |
| Maturing, other projects begin to draw from it | Reusability | REP (with CRP) | Slides toward the left |

**Principle summary:**

| Principle | Statement | Effect on component size | Analogue at class level |
|---|---|---|---|
| REP — Reuse/Release Equivalence | The granule of reuse is the granule of release | Larger (inclusive) | — |
| CCP — Common Closure | Classes that change together, at the same times and for the same reasons, belong together | Larger (inclusive) | SRP |
| CRP — Common Reuse | Don't force users to depend on things they don't need | Smaller (exclusive) | ISP |

## Worked Example
A team ships a `utils` component holding a container class, its iterators, a date formatter, and a currency formatter.

- **CRP check**: A billing service imports `utils` only for the currency formatter. It now recompiles, revalidates, and redeploys every time the container's iterators change — changes it does not care about. The classes are separable, so CRP is violated. Split: container + iterators into one component (they are reused together and tightly coupled — they belong together), formatters elsewhere.
- **CCP check**: The date and currency formatters change for the same reason — locale policy — and at the same time. Keep them in one `formatting` component so a locale change means redeploying one component, and nothing that doesn't depend on it needs revalidation.
- **REP check**: Each resulting component now has an overarching theme, so it can carry its own version number and release notes that make sense to author and user alike. Consumers can read the notes for a `formatting` release and decide to stay on the old version.
- **The tension**: The split raised the component count, so simple cross-cutting changes now touch more components (the cost of leaning on REP + CRP). Early in the project, when the team was the only consumer, keeping one `utils` component under CCP was the correct call. Once other projects began drawing from it, the position slid left. The partitioning appropriate today may not be appropriate next year — expect the composition to jitter and evolve.

## Key Takeaways
1. Name the three principles precisely — REP (Reuse/Release Equivalence Principle), CCP (Common Closure Principle), CRP (Common Reuse Principle) — because each answers a different question about component contents.
2. If a component isn't versioned, documented, and released, it cannot be reused: the granule of reuse *is* the granule of release.
3. For most applications maintainability beats reusability — apply CCP first so a requirement change lands in one component.
4. CRP is mostly a rule about what to *keep out*: make component contents inseparable so nobody depends on classes they don't need.
5. The three principles fight each other. Locate your project on the tension triangle deliberately, know which cost you are choosing to pay, and revisit it as the project matures.
6. Cohesion is not "a module does one function." It is the dynamic balance of reusability against develop-ability, and it will shift over the life of the project.

## Connects To
- **Ch 12**: These principles decide what goes *inside* the independently deployable units defined there.
- **Ch 14**: Component coupling (ADP, SDP, SAP) governs the dependencies *between* the components this chapter fills; the ADP's "jitters" are the same evolutionary pressure.
- **Ch 7 (SRP)**: CCP is SRP restated for components — one reason to change.
- **Ch 8 (OCP)**: CCP addresses "closure" in the OCP sense; closure must be strategic because 100% closure is unattainable.
- **Ch 10 (ISP)**: CRP is the generic, component-level version of ISP.
- **Ch 27, "Services: Great and Small"**: The Kitty Problem — changes scattered across many services is the CCP violation at service scale.
