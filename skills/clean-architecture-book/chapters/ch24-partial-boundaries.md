# Chapter 24: Partial Boundaries

## Core Idea
Full-fledged architectural boundaries are expensive to build and to maintain, so when you judge the cost too high but still think "yeah, but I might," implement a **partial boundary** — Skip the Last Step, One-Dimensional Boundaries, or a Facade — as a placeholder for a boundary that may one day be needed.

## Frameworks Introduced
- **Skip the Last Step**: do all the work necessary to create independently compilable and deployable components, then simply keep them together in the same component.
  - When to use: when you genuinely expect the split and want zero release friction now — the FitNesse "download and go" case, where users should get one jar file and execute it without hunting for other jars or working out version compatibilities.
  - How:
    1. Build the reciprocal interfaces.
    2. Build the input/output data structures.
    3. Manage the dependencies as if the two sides were separate.
    4. Compile and deploy all of it as a single component.
  - Why it works: you pay the full design cost but escape the *administration* of multiple components — no version number tracking, no release management burden. That difference should not be taken lightly.
  - Failure mode: over time, as it becomes clear the separation will never be needed, the boundary weakens. Dependencies start to cross the line in the wrong direction, and re-separating later becomes a chore. This is exactly what happened to FitNesse's web component and wiki component.

- **One-Dimensional Boundaries**: the traditional **Strategy pattern** — a `ServiceBoundary` interface used by clients and implemented by `ServiceImpl` classes.
  - When to use: when you want the dependency inversion in place cheaply and can tolerate isolation in only one direction.
  - How: declare the boundary interface on the client's side; have the implementation depend on it. The necessary dependency inversion is in place, isolating `Client` from `ServiceImpl`.
  - Why it works: it sets the stage for a future full boundary at a fraction of the setup and ongoing maintenance cost of reciprocal interfaces.
  - Failure mode: without reciprocal interfaces, nothing prevents a **backchannel** — a direct dependency from the implementation side back to the client side — other than the diligence and discipline of the developers and architects. Separation can degrade pretty rapidly.

- **Facades**: even simpler — the boundary is defined by a `Facade` class that lists all the services as methods and deploys the service calls to classes the client is not supposed to access.
  - When to use: when the boundary is aspirational and you want only a single named place that documents where it would go.
  - How: put every service call on the Facade; keep the service classes nominally off-limits to the client.
  - Cost: even the dependency inversion is sacrificed. `Client` has a **transitive dependency on all those service classes** — in static languages a change to the source of one `Service` class forces `Client` to recompile. Backchannels are trivially easy to create.

## Key Concepts
- **Full-fledged architectural boundary**: reciprocal polymorphic `Boundary` interfaces, `Input` and `Output` data structures, and all the dependency management needed to isolate the two sides into independently compilable and deployable components.
- **Partial boundary**: a structure that holds a place for such a boundary without paying all of its cost.
- **Anticipatory design**: deciding for a boundary you do not yet need — often frowned upon in the Agile community as a YAGNI violation.
- **YAGNI**: "You Aren't Going to Need It."
- **Backchannel**: a dependency crossing the boundary in the wrong direction, bypassing the interface.
- **Reciprocal interfaces**: the pair of interfaces that maintain isolation in *both* directions; their absence is what makes a boundary one-dimensional.
- **Download and go**: the FitNesse design goal that motivated Skip the Last Step — one jar, no version hunting.

## Mental Models
- Think of a partial boundary as **rough-in plumbing**: you run the pipe to the wall now because opening the wall later is what actually costs money.
- Use the **"yeah, but I might" test**: YAGNI answers "will I need this?", but an architect is also allowed to answer "possibly, and the retrofit is expensive."
- Think of each option as **a point on a cost/decay curve**: the more you pay up front, the slower the boundary rots — and the more you save, the faster backchannels appear.
- Treat an unrealized boundary as **perishable**. Each of these can be degraded if the boundary never materializes; schedule a look at it.

## Reference Tables

| Technique | Structure | Dependency inversion | Isolation direction | Up-front cost | Ongoing cost | Main risk |
|---|---|---|---|---|---|---|
| **Skip the Last Step** | Full reciprocal interfaces + input/output data structures, compiled/deployed as one component | Full | Both | Same as a full boundary (all code and preparatory design work) | Low — no multiple-component administration, no version tracking, no release management | Separation weakens over time; dependencies cross in the wrong direction and re-separating becomes a chore (FitNesse) |
| **One-Dimensional Boundaries** (Strategy) | `ServiceBoundary` interface used by `Client`, implemented by `ServiceImpl` | Yes | One direction only | Moderate | Moderate | Backchannels — only developer diligence and discipline prevent them |
| **Facades** | `Facade` class lists all services as methods, delegates to hidden service classes | None | None (naming convention only) | Lowest | Lowest | `Client` has a transitive dependency on all service classes; in static languages a service change forces `Client` to recompile; backchannels are trivially easy |

## Worked Example
**FitNesse and the web component.**

The web server component of FitNesse was designed to be separable from the wiki and testing part. The motive was reuse: the team might want to build other web-based applications on that web component. But a core design goal was **download and go** — the user downloads one jar file and executes it, without hunting for other jar files or working out version compatibilities.

So the team applied **Skip the Last Step**. They did all the work of a full boundary — reciprocal interfaces, input/output data structures, disciplined dependency management — and then compiled and deployed everything as a single component. They paid the full design cost and none of the multi-component release cost.

Then the danger arrived on schedule. Over time it became clear there would never be a need for a separate web component. With no compiler or release process enforcing the line, the separation between the web component and the wiki component began to weaken; dependencies started to cross in the wrong direction. Today, re-separating them would be something of a chore.

The lesson is not "don't do this." It is that a partial boundary's integrity rests on the intention that motivated it — when the intention dies, the boundary decays, and that decay must be watched for rather than assumed away.

## Key Takeaways
1. Price the boundary before building it: reciprocal interfaces, input/output data structures, and independent compile/deploy are a lot of work to build *and* to maintain.
2. Use Skip the Last Step when you want the full structure without the release-management burden — you save the administration, not the code.
3. Use the Strategy pattern when you want cheap dependency inversion and accept one-directional isolation.
4. Use a Facade only as a marker; it sacrifices dependency inversion and leaves a transitive dependency on every service class.
5. Every partial boundary decays if the real boundary never materializes; only developer discipline prevents backchannels.
6. Deciding where an architectural boundary might one day exist — and whether to implement it fully or partially — is one of the functions of an architect.

## Connects To
- **Ch 25 (Layers and Boundaries)**: the "you must guess intelligently" argument that justifies partial boundaries, and the watch-for-friction discipline that decides when to complete one.
- **Ch 22 (The Clean Architecture)**: defines the full-fledged boundary these techniques partially approximate.
- **Ch 17 (Boundaries)** and **Ch 18 (Boundary Anatomy)**: where boundaries go and what they look like at full strength.
- **Ch 11 (DIP)**: the inversion that Strategy keeps and Facade discards.
- **Strategy and Facade patterns (GoF)**: the two named patterns used here as boundary placeholders.
- **YAGNI (Extreme Programming)**: the countervailing pressure this chapter argues with rather than dismisses.
