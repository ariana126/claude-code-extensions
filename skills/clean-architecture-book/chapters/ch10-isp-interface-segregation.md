# Chapter 10: ISP: The Interface Segregation Principle

## Core Idea
Depending on something that carries baggage you don't need causes troubles you didn't expect — so segregate fat interfaces into the narrow ones each user actually calls. (This is a genuinely short chapter; the argument is one diagram at the class level and one at the architectural level.)

## Frameworks Introduced
- **The Interface Segregation Principle (ISP)**: don't force a user to depend on operations it does not use; split a multi-operation class behind per-user interfaces.
  - The situation (Figure 10.1): an `OPS` class exposes `op1`, `op2`, `op3`. `User1` uses only `op1`, `User2` only `op2`, `User3` only `op3`. In a language like Java the source code of `User1` inadvertently depends on `op2` and `op3` even though it never calls them — so a change to `op2` forces `User1` to be recompiled and redeployed although nothing it cared about changed.
  - The remedy (Figure 10.2): segregate the operations into interfaces `U1Ops`, `U2Ops`, `U3Ops`. `User1`'s source now depends on `U1Ops` and `op1`, not on `OPS`, so changes to `OPS` that `User1` doesn't care about no longer touch it.
  - When to use: any statically typed codebase where one class or module serves several distinct client groups; and, at the architectural scale, any decision to adopt a framework or library.
  - How:
    1. Map each client to the operations it actually calls.
    2. Define one interface per client group, containing exactly those operations.
    3. Have the fat implementation class implement all of them.
    4. Point every client's `import`/`use`/`include` at its own narrow interface.
  - Why it works: it is the *included declarations in source code* that create source code dependencies, and those dependencies are what force recompilation and redeployment. Narrow the declaration, narrow the blast radius.
  - Failure mode / boundary of the argument: in dynamically typed languages such declarations don't exist in source — they're inferred at runtime — so there are no source code dependencies to force recompilation. That is the primary reason dynamically typed languages create systems that are more flexible and less tightly coupled. Which could lead you to conclude the ISP is a language issue rather than an architecture issue — and that conclusion is what the rest of the chapter refutes.

- **ISP at the architectural level**: it is harmful, in general, to depend on modules that contain more than you need.
  - The scenario: architect wants framework F in system S; the authors of F bound it to database D. So S depends on F, which depends on D.
  - The damage, even if S never uses D's extra features: (a) changes to unused features within D can force redeployment of F and therefore of S; (b) worse, a *failure* of one of those features within D may cause failures in F and in S.

## Key Concepts
- **Fat interface**: a class or module exposing operations that no single client needs in full.
- **Segregated interface**: a client-specific interface (`U1Ops`) containing only the operations one user group calls.
- **Inadvertent dependency**: a source code dependency on operations the client never calls, created purely by including a declaration.
- **Recompile-and-redeploy coupling**: the concrete cost of an inadvertent dependency in a statically typed language.
- **Included declarations**: `import` / `use` / `include` statements — the actual carriers of static source code dependency.
- **Baggage**: features of a depended-on module that the depender neither uses nor wants, but inherits the change and failure risk of.
- **Common Reuse Principle**: the component-level restatement of the ISP, covered in Chapter 13.

## Reference Tables

| | Statically typed (Java) | Dynamically typed (Ruby, Python) |
|---|---|---|
| Declarations users must include | Yes — `import`/`use`/`include` | No — inferred at runtime |
| Source code dependency created | Yes | No |
| Forces recompilation/redeployment | Yes | No |
| Consequence | More tightly coupled | More flexible, less tightly coupled |
| ISP still applies? | Yes, literally | Yes, at the architectural level |

## Mental Models
- Think of an `import` as **signing up for someone else's release schedule**. Import only what you call.
- Use "what comes along for the ride?" when evaluating a framework: F's chosen database D is now your risk surface for both change *and* failure.
- Think of the ISP as **the same statement as the Common Reuse Principle**, one scale down: don't depend on things you don't use.
- Segregate at the point of *use*, not the point of *definition* — the interfaces belong to the clients.

## Worked Example
**Framework F and database D.**

An architect working on system S wants to include framework F. The authors of F bound F to a particular database, D. The dependency chain becomes S → F → D.

Now suppose D contains features that F does not use and that S therefore does not care about. Two failures follow. First, changes to those unused features within D may force the redeployment of F, and consequently of S — S pays deployment cost for a database feature it has never touched. Second, and worse, a runtime failure in one of those unused D features may cause failures in F and therefore in S: S can be brought down by a component it doesn't use, inside a database it didn't choose, reached through a framework it only wanted for something else.

This is the class-level `OPS` diagram scaled up. `User1` recompiling because `op2` changed and S falling over because an unused D feature broke are the same defect at two magnitudes.

## Anti-patterns
- **The fat service class** (`OPS`) that every client imports wholesale: every client is recompiled for every change to any operation.
- **Dismissing ISP as a static-language artifact**: the recompilation argument is language-dependent, but the harm of depending on modules containing more than you need is not.
- **Adopting a framework without auditing its transitive bindings**: you inherit its database, its versions, and its failure modes.
- **Defining interfaces around the implementation's shape** rather than around each client's needs — that just renames the fat interface.

## Key Takeaways
1. Split fat interfaces into per-client interfaces so each user's source code names only what it calls.
2. In statically typed languages, unnecessary declarations mean unnecessary recompilation and redeployment.
3. Dynamically typed languages avoid the source-dependency mechanism, which is why they are less tightly coupled — but they don't escape the underlying principle.
4. At architectural scale, depending on a module that carries baggage imports both its change cost and its failure modes.
5. Audit transitive dependencies (S → F → D) before adopting any framework.
6. The one-line lesson: depending on something that carries baggage you don't need can cause you troubles that you didn't expect.

## Connects To
- **Ch 13 (Component Cohesion)**: the Common Reuse Principle is the ISP restated for components.
- **Ch 8 (OCP)**: the `FinancialReportRequester` interface exists for exactly this reason — to stop the Controller from acquiring transitive dependencies on the Interactor's entities.
- **Ch 11 (DIP)**: both push clients toward depending on minimal, stable abstractions rather than on rich concretions.
- **Ch 34 / framework independence**: "the framework is a detail" is the ISP argument applied to the biggest dependency most systems take on.
