# Facade
**Classification**: Object Structural | **Chapter**: 4

## Intent
Provide a unified interface to a set of interfaces in a subsystem. Facade defines a higher-level interface that makes the subsystem easier to use.

## Also Known As
*(none given)*

## Core Idea
Introduce one object that knows the whole subsystem and offers a single simple
entry point to it — glue, without hiding the lower-level classes from the few
clients who need them.

## Applicability
Use Facade when:
- You want a simple interface to a complex subsystem. Subsystems get more complex as they evolve, and applying patterns tends to produce more, smaller classes — reusable and customizable, but harder to use for clients who don't need to customize. A facade gives a simple default view good enough for most clients.
- There are many dependencies between clients and the implementation classes of an abstraction. A facade decouples the subsystem from clients and from other subsystems, promoting subsystem independence and portability.
- You want to **layer** your subsystems. Define a facade as the entry point to each level and have dependent subsystems communicate solely through each other's facades.

## Structure
- **Facade** (Compiler): knows which subsystem classes are responsible for a request and delegates client requests to the appropriate subsystem objects.
- **subsystem classes** (Scanner, Parser, ProgramNode, ProgramNodeBuilder, BytecodeStream, CodeGenerator): implement subsystem functionality, handle work assigned by the Facade, and **have no knowledge of the facade** — they keep no references to it.

Collaboration: clients send requests to the Facade, which forwards them to the
right subsystem objects, possibly doing work of its own to translate its
interface into the subsystem's. Clients using the facade need not access
subsystem objects directly — but may.

## How
1. Identify the subsystem's boundary and its public vs. private classes.
2. Define a Facade class whose operations are phrased in terms of what clients actually want to do (`Compile(input, output)`), not in terms of subsystem mechanics.
3. Implement each facade operation by instantiating and sequencing the right subsystem objects.
4. Choose your defaults deliberately — hard-coding choices (which code generator) keeps the common case simple; parameterizing everything erodes the point of the pattern.
5. If clients must be shielded from *which* subsystem implementation is used, make Facade abstract with concrete subclasses, or make it configurable with different subsystem objects.

## Consequences
**Benefits**
1. **Shields clients from subsystem components**, reducing the number of objects clients deal with and making the subsystem easier to use.
2. **Promotes weak coupling** between subsystem and clients. Subsystem components are often strongly coupled internally; weak external coupling lets you vary them without affecting clients, helps layer the system, and can eliminate complex or circular dependencies. Concretely, it reduces **compilation dependencies** — vital in large systems, limiting recompilation after a small change in an important subsystem, and simplifying ports since building one subsystem needn't build all others.
3. **Doesn't prevent applications from using subsystem classes directly.** You get to choose between ease of use and generality, per client.

**Liabilities**
- A facade can become a god object if it accumulates functionality rather than delegating it.
- Over-parameterizing the facade (letting clients supply Scanner, ProgramNodeBuilder, CodeGenerator…) adds flexibility but defeats the mission of simplifying the common case.

## Implementation Notes
- **Reducing client-subsystem coupling further.** Make Facade an *abstract class* with concrete subclasses per subsystem implementation, so clients talk to the subsystem through an abstract interface and never learn which implementation is in play. Alternatively, configure a single Facade object with different subsystem objects — customize by swapping components rather than subclassing.
- **Public versus private subsystem classes.** A subsystem is analogous to a class: a class encapsulates state and operations, a subsystem encapsulates classes, and both have public and private interfaces. The Facade is part of the public interface but not all of it — `Parser` and `Scanner` are public too; the private interface exists for subsystem *extenders*. Few OO languages support making subsystem classes private (C++ and Smalltalk historically had a global class namespace); C++ namespaces later made it possible to expose only the public classes.

## Worked Example
A compiler subsystem contains `Scanner`, `Parser`, `ProgramNodeBuilder`,
`ProgramNode` (a Composite parse tree), `CodeGenerator` (a Visitor),
`BytecodeStream`, `Token`. Most clients just want to compile.

```cpp
class Compiler {                               // Facade
public:
    Compiler();
    virtual void Compile(istream& input, BytecodeStream& output) {
        Scanner            scanner(input);
        ProgramNodeBuilder builder;
        Parser             parser;

        parser.Parse(scanner, builder);        // Builder pattern inside

        RISCCodeGenerator generator(output);
        ProgramNode* parseTree = builder.GetRootNode();
        parseTree->Traverse(generator);        // Visitor over a Composite
    }
};
```

What it demonstrates: one operation replaces a five-class choreography. Note the
deliberate hard-coding of `RISCCodeGenerator` — reasonable with a single target
architecture. Taking a `CodeGenerator` parameter in the constructor adds
flexibility; parameterizing `Scanner` and `ProgramNodeBuilder` as well starts
working against the pattern's purpose.

## Anti-patterns & Smells
- **Facade that implements the work itself**: a facade *delegates*; it defines no new functionality. When it starts holding logic, it's becoming a Mediator or a god class.
- **Subsystem classes that reference the facade**: creates the circular dependency the pattern is meant to break.
- **Sealing the subsystem**: hiding lower-level classes completely removes the escape hatch that makes Facade cheap to adopt.
- **Parameterizing everything**: an infinitely configurable facade is no simpler than the subsystem it fronts.

## Known Uses
- **ObjectWorks\Smalltalk compiler system** — inspiration for the Sample Code.
- **ET++** — `ProgrammingEnvironment` fronts the run-time browsing subsystem with `InspectObject` and `InspectClass`. The base class implements them as null operations; only `ETProgrammingEnvironment` actually opens browsers — abstract coupling means the application never knows whether browsing support exists.
- **Choices operating system** — facades compose several frameworks into one OS. `FileSystemInterface` represents storage and `Domain` represents address spaces. `Domain::RepairFault` handles a page fault by finding the memory object at the faulting address and delegating to its `MemoryObjectCache` (itself a Strategy localizing caching policy); `AddressTranslation` encapsulates the translation hardware. Domains are customized by swapping components.

## Related Patterns
- **Abstract Factory**: can be used with Facade to create subsystem objects in a subsystem-independent way, or *instead of* Facade to hide platform-specific classes.
- **Mediator**: similar in that it abstracts functionality of existing classes, but different in purpose. A mediator abstracts **arbitrary communication among colleague objects**, often centralizing behavior that belongs in none of them, and its colleagues **know about and talk to** the mediator instead of each other. A facade merely abstracts the **interface** to subsystem objects to make them easier to use; it defines **no new functionality**, and subsystem classes don't know it exists.
- **Adapter**: tempting to call a facade "an adapter to a set of objects," but a facade defines a **new** interface whereas an adapter reuses an **existing** one to make two existing interfaces work together.
- **Singleton**: usually only one Facade object is needed, so facades are often Singletons.
- **Builder, Composite, Visitor, Strategy**: all appear *inside* the compiler and Choices subsystems the facade fronts — a facade typically sits atop other patterns.

## Key Takeaways
1. Add a facade when a subsystem's internal decomposition (usually caused by applying other patterns) starts making life hard for ordinary clients.
2. A facade delegates and defines no new functionality — if it grows behavior, reconsider whether you want a Mediator.
3. Never hide the subsystem completely: keep the direct classes available for the minority of clients that need them.
4. Use facades as the entry point to each layer, so inter-subsystem dependencies run facade-to-facade and recompilation stays local.
