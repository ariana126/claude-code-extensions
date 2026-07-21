# Chapter 19: Policy and Level

## Core Idea
A computer program is a detailed description of the policy by which inputs are transformed into outputs; architecture is the art of separating those policies, regrouping them by how they change, and arranging source code dependencies so they always point toward the higher-level policies — where "level" means distance from the inputs and outputs.

## Frameworks Introduced

- **Level = "the distance from the inputs and outputs."**
  - When to use: whenever you must decide which of two components should depend on the other.
  - How: the farther a policy is from **both** the inputs and the outputs, the higher its level. Policies that manage input and output are the lowest-level policies in the system. Rank components by that distance, then make every source code dependency point up the ranking.
  - Why it works: higher-level policies change less frequently and for more important reasons; lower-level policies change frequently and with more urgency but for less important reasons. Pointing dependencies upward means trivial-but-urgent low-level changes have little or no impact on the higher, more important levels.

- **Regrouping policy into a directed acyclic graph.**
  - When to use: as the core act of architecting a nontrivial system.
  - How:
    1. Break the system's policy into smaller statements of policy — how business rules are calculated, how reports are formatted, how input data is validated.
    2. Group them by change: policies that change **for the same reasons and at the same times** are at the same level and belong in the same component; policies that change for different reasons or at different times are at different levels and go in different components (SRP and CCP).
    3. Form the components into a **directed acyclic graph** — nodes are components of same-level policy, directed edges are dependencies connecting components at different levels.
    4. The edges are source code, compile-time dependencies: `import` in Java, `using` in C#, `require` in Ruby — the dependencies the compiler needs.
    5. Set every edge's direction by level: **low-level components are designed so that they depend on high-level components.**

- **Decouple source code dependencies from data flow; couple them to level.**
  - When to use: any time the obvious call chain would make a high-level policy name a low-level one.
  - How: introduce interfaces owned by the high-level unit and let low-level classes implement them, so data can flow one way while dependencies point the other.
  - Failure mode if ignored: the high-level policy becomes unusable outside its original IO context and breaks whenever an IO device changes.

- **Lower-level components should be plugins to higher-level components.** The `Encryption` component knows nothing of the `IODevices` component; `IODevices` depends on `Encryption`.

## Key Concepts
- **Policy**: a statement of how inputs are transformed into outputs; a whole program is one, decomposable into many smaller ones.
- **Level**: the distance from the inputs and outputs.
- **Highest-level component**: the one farthest from both inputs and outputs — in the encryption example, `Translate`. (Meilir Page-Jones called this the "Central Transform.")
- **Source code / compile-time dependency**: the `import`, `using`, or `require` edge — the only kind of dependency the architecture graph is built from.
- **Directed acyclic graph**: the shape architecture aims for — same-level policy in nodes, cross-level dependencies as edges, no cycles.
- **Data flow**: the runtime movement of information, drawn as curved solid arrows in the data flow diagram; it does *not* always point the same way as the dashed source code dependencies.
- **Plugin relationship**: the low-level component depends on and plugs into the high-level one, never the reverse.

## Mental Models
- **Think of level as radius, not altitude.** Measure outward from the IO boundary in both directions; the component nobody can reach quickly from either edge is your highest level.
- **Use rate-and-reason of change as the grouping test.** Same reasons and same times → same component. Different reasons or different times → different levels, different components.
- **Think of the arrows and the data as two separate drawings on the same page.** Data flow is fixed by the problem; dependency direction is your choice — spend it on level.
- **Use "would this policy survive a change of device?" as the level check.** It is far more likely the IO devices change than the encryption algorithm; if a change of device forces a change to your algorithm, the dependency is upside down.

## Code Examples

```javascript
function encrypt() {
  while(true)
    writeChar(translate(readChar()));
}
```
- **What it demonstrates**: the *incorrect* architecture. The high-level `encrypt` function depends on the lower-level `readChar` and `writeChar` functions — dependencies follow the data flow instead of the level.

## Worked Example

**The simple encryption program** — reads characters from an input device, translates them using a table, writes the translated characters to an output device.

*Data flow diagram (Figure 19.1).* Curved solid arrows show data: input device → `Translate` → output device. Straight dashed lines show the properly designed source code dependencies. `Translate` is the **highest-level component** because it is farthest from both inputs and outputs. Note that the two sets of arrows do not point the same way — that is the point.

*The naive implementation* (the `encrypt` loop above) inverts this: the high-level function names both low-level IO functions directly.

*Better architecture (Figure 19.2).* A dashed border surrounds the `Encrypt` class together with the `CharWriter` and `CharReader` **interfaces**; all dependencies crossing that border point **inward**, making that unit the highest-level element in the system. `ConsoleReader` and `ConsoleWriter` are concrete classes outside the border — low level, because they are close to the inputs and outputs, and they implement the interfaces the high-level unit owns.

*Component view (Figure 19.3).* Zoomed out, this is two components: `Encryption` and `IODevices`, with the arrow running from `IODevices` to `Encryption`. Lower-level components plug in to higher-level ones.

*Payoff.* The high-level encryption policy is decoupled from the lower-level input/output policies, making it usable in a wide range of contexts. Changes to input and output policies are unlikely to affect the encryption policy — and it is far more likely that the IO devices will change than that the encryption algorithm will. If the algorithm does change, it will be for a more substantive reason than an IO device swap.

## Key Takeaways
1. Treat the whole system as policy, then split it into policies that change together and regroup them into components.
2. Define level precisely — distance from the inputs and outputs — and never argue about "high level" on vibes.
3. Build the component graph as a DAG whose edges are compile-time dependencies, all pointing from lower to higher level.
4. Decouple source code dependencies from data flow and couple them to level; use interfaces owned by the high-level unit to invert direction where needed.
5. Put the interfaces inside the high-level boundary (`CharReader`, `CharWriter` with `Encrypt`), and the implementations (`ConsoleReader`, `ConsoleWriter`) outside it.
6. Expect low-level policy to change often, urgently, and for unimportant reasons — arrange the graph so those changes cannot reach the important levels.
7. This chapter mixes SRP, OCP, CCP, DIP, SDP, and SAP; identifying where each was used is a productive review exercise on your own designs.

## Connects To
- **Ch 15 (What Is Architecture?)**: turns the informal policy/details split into a measurable definition of level.
- **Ch 17 (Boundaries: Drawing Lines)**: the plugin arrangement here is the same shape drawn between business rules, GUI, and database.
- **Ch 18 (Boundary Anatomy)**: supplies the mechanics for a crossing that must run against the flow of control, which is exactly what `CharWriter` does.
- **Ch 20 (Business Rules)**: applies the level definition to Entities (higher, general) versus use cases (lower, application-specific and closer to IO).
- **Dependency Inversion Principle / Stable Abstractions Principle**: the justification for pointing edges at abstractions.
- **Structured design's "Central Transform"** (Page-Jones): the pre-OO name for the highest-level component.
