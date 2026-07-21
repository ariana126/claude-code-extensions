# Chapter 18: Boundary Anatomy

## Core Idea
A boundary crossing at runtime is nothing more than a function on one side calling a function on the other and passing data; the architecture lives in the *source code dependencies*, not in the call. Boundaries come in escalating physical strengths — monolith, deployment component, local process, service — and each buys more isolation at a higher cost per crossing.

## Frameworks Introduced

- **Boundary Crossing / managing source code dependencies**: the trick to an appropriate boundary crossing is to manage the source code dependencies, because when one source module changes, others may have to be changed, recompiled, and redeployed. Building firewalls against that change is what boundaries are all about.
  - When to use: every boundary, at every physical strength.
  - How, in the two directions of control flow:
    - **Low-level client calls a higher-level service** — the simplest possible crossing. The `Client` calls `f()` on the `Service`, passing an instance of `Data` (`<DS>` marks a data structure). Runtime dependency and compile-time dependency point the *same* way, toward the higher-level component. The definition of `Data` sits on the **called** side.
    - **High-level client needs a lower-level service** — use dynamic polymorphism to invert the dependency against the flow of control. The high-level `Client` calls `f()` on the lower-level `ServiceImpl` through the `Service` interface. Control flows left to right, but all dependencies cross right to left, *toward the higher-level component*. The data structure definition sits on the **calling** side.
  - Why it works: the runtime dependency opposes the compile-time dependency, so higher-level components stay independent of lower-level details while still driving them.

- **The Ladder of Boundary Strength (monolith → deployment components → local processes → services)**: choose the weakest boundary that meets the need, because strength costs latency.
  - When to use: whenever deciding how to physically separate two components; revisit as operational needs change.
  - How: see the reference table. In every case the segregation strategy is identical — source code dependencies point one way across the boundary, always toward the higher-level component.
  - Failure mode: dealing with service boundaries where none are needed wastes effort, memory, and cycles — and chatty communication across an expensive boundary destroys performance.

- **The plugin rule at every physical level**: lower-level processes and services plug in to higher-level ones.
  - How: the source code of a higher-level process must not contain the names, physical addresses, or registry lookup keys of lower-level processes; the source of a higher-level service must not contain any specific physical knowledge of a lower-level service, such as a URI.

## Key Concepts
- **Boundary crossing**: at runtime, a function on one side of a boundary calling a function on the other and passing data.
- **The dreaded monolith**: a disciplined segregation of functions and data within a single processor and address space, deployed as a single executable — a statically linked C/C++ project, an executable jar, a single .NET `.EXE`.
- **Dynamic polymorphism**: the mechanism monoliths depend on to manage internal dependencies; without OO or an equivalent, architects fall back to the dangerous practice of pointers to functions — most find prolific use too risky and abandon component partitioning altogether.
- **Static polymorphism**: generics or templates; sometimes viable for dependency management in monoliths (especially C++), but it cannot protect against recompilation and redeployment the way dynamic polymorphism can — and it is not an option for deployment components.
- **Deployment component**: the simplest *physical* boundary — a dynamically linked library: .NET DLL, Java jar, Ruby Gem, UNIX shared library. Delivered in binary; deployment is just gathering these units into a WAR file or a directory.
- **Threads**: not architectural boundaries and not units of deployment — a way to organize the schedule and order of execution, wholly inside one component or spread across many.
- **Local process**: a process created from the command line or an equivalent system call, running on the same processor(s) but in a **separate address space**; memory protection generally prevents sharing memory, though shared memory partitions are often used. Think of it as an *uber-component* composed of lower-level components managing dependencies through dynamic polymorphism.
- **Service**: the strongest boundary — a process that does not depend on its physical location and assumes all communication takes place over the network.
- **Chattiness**: the volume of crossings; permissible across cheap boundaries, must be carefully limited or avoided as boundary cost rises.

## Mental Models
- **Think of a boundary's strength and its cost as the same dial.** More isolation always means slower, more expensive crossings; pick the cheapest boundary that solves the actual problem.
- **Use "which side owns the data structure?" to check the arrow.** With the flow of control, the `<DS>` definition is on the called side; against it (dependency inverted), it is on the calling side.
- **Think of invisible boundaries as real ones.** A monolith's boundaries have no physical representation at deployment, but the ability to independently develop and marshal components for final assembly is immensely valuable.
- **Use "does the higher level know a name, address, or URI of the lower level?" as the plugin test** — if yes, the arrow is backwards regardless of the physical topology.

## Reference Tables

| Boundary | Decoupling mode | Address space | Communication mechanism | Cost per crossing | Chattiness | Delivery form |
|---|---|---|---|---|---|---|
| **Monolith** | Source level | Single processor, single address space | Function calls | Very fast, inexpensive | Can be very chatty | Source code (compiled + statically linked) |
| **Deployment components** | Deployment level | Generally same processor and address space | Function calls (one-time hit for dynamic linking / runtime loading) | Inexpensive | Can still be very chatty | Binary: DLL, jar, Gem, shared library |
| **Local processes** | — | Same processor(s), **separate** address spaces | Sockets, mailboxes, message queues; sometimes shared memory partitions | Moderately expensive: OS calls, marshaling/decoding, interprocess context switches | Should be carefully limited | Statically linked monolith or dynamically linked components |
| **Services** | Service level | Location-independent; may or may not share a processor | Network, always assumed | Very slow — turnaround from tens of milliseconds to seconds; high latency | Avoid chatting where possible | Independent execution unit |

*Threads are none of the above: not a boundary, not a deployment unit.*

## Worked Example

**Reading the two crossing diagrams.**

*Case 1 — with the flow of control (Figure 18.1).* A low-level `Client` calls `f()` on a higher-level `Service`, passing a `Data` instance. Both the runtime dependency and the compile-time dependency point right, toward `Service`. `Data`'s definition lives with `Service`, on the called side. Nothing special is needed: the natural direction already points toward the higher level.

*Case 2 — against the flow of control (Figure 18.2).* Now the `Client` is the high-level component and the service is lower level. Control still flows left to right, but the `Client` must not depend on the detail. Introduce a `Service` interface on the client's side; `ServiceImpl` implements it. The `Client` calls `f()` through the interface; `ServiceImpl` points left at that interface. Every dependency now crosses right to left toward the higher-level component, and the data structure definition sits on the calling side. This is dynamic polymorphism used to invert the dependency against control flow — and it is exactly what a monolith needs in order to partition at all.

*Composition in a real system.* A service is often just a facade for a set of interacting local processes; each of those local processes is almost certainly either a statically linked monolith of source-code components or a set of dynamically linked deployment components. So one system mixes local chatty boundaries with latency-sensitive ones, and the strategy — dependencies toward the higher level, lower levels plugging in — is unchanged at every layer of that composition.

## Key Takeaways
1. Manage source code dependencies, not runtime calls; boundaries exist to stop change from propagating through recompilation and redeployment.
2. When control flows toward the higher level, dependencies follow naturally; when it flows toward the lower level, invert with dynamic polymorphism.
3. A monolith still has real boundaries — invisible at deployment, invaluable for independent development and assembly.
4. Without dynamic polymorphism, component partitioning tends to collapse; pointers to functions are the risky fallback most architects refuse.
5. Threads are scheduling, not architecture — never count them as boundaries or deployment units.
6. Match chattiness to cost: chatty across function calls, restrained across processes, minimal across services.
7. Higher-level source must never contain names, physical addresses, registry keys, or URIs of lower-level processes and services.
8. Expect mixtures — most systems other than pure monoliths use more than one boundary strategy at once.

## Connects To
- **Ch 16 (Independence)**: this chapter gives the physical anatomy of the three decoupling modes named there, and the cost data behind "push the decoupling mode decision late."
- **Ch 17 (Boundaries: Drawing Lines)**: where to draw the line; this chapter is what the line is made of.
- **Ch 19 (Policy and Level)**: supplies the definition of "higher level" that every arrow here points toward.
- **Dependency Inversion Principle**: the interface-in-the-middle move in Figure 18.2 is DIP in its architectural form.
- **Open–Closed Principle**: plugging lower-level processes and services into higher-level ones is OCP across process boundaries.
