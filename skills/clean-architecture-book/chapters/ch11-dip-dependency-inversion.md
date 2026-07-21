# Chapter 11: DIP: The Dependency Inversion Principle

## Core Idea
The most flexible systems are those in which source code dependencies refer only to abstractions, not to concretions. Where the flow of control crosses an architectural boundary, the source code dependency crosses it in the opposite direction — which is why it is called *inversion*.

## Frameworks Introduced
- **The Dependency Inversion Principle (DIP)**: source code dependencies should refer only to abstractions, never to volatile concretions.
  - In a statically typed language like Java: `use`, `import`, and `include` statements should refer only to source modules containing interfaces, abstract classes, or some other kind of abstract declaration. Nothing concrete should be depended on.
  - In dynamically typed languages like Ruby and Python the same rule applies, but "concrete module" is harder to define — it is **any module in which the functions being called are implemented**.
  - **Martin's stated tolerance**: treating this as an absolute rule is unrealistic, because software systems must depend on many concrete facilities. Java's `String` class is concrete and it would be unrealistic to force it to be abstract; the source code dependency on the concrete `java.lang.string` cannot and should not be avoided. `String` is *very stable* — changes are rare and tightly controlled — so we ignore the stable background of operating system and platform facilities when it comes to DIP. We tolerate those concrete dependencies because we can rely on them not to change. It is the **volatile** concrete elements — the modules we are actively developing, undergoing frequent change — that we want to avoid depending on.
  - The four coding practices:
    1. **Don't refer to volatile concrete classes.** Refer to abstract interfaces instead. Applies in all languages, static or dynamic. It puts severe constraints on object creation and generally enforces the use of Abstract Factories.
    2. **Don't derive from volatile concrete classes.** A corollary, but worth its own mention: in statically typed languages inheritance is the strongest and most rigid of all source code relationships, so use it with great care. In dynamic languages it is less of a problem but still a dependency — caution is always wisest.
    3. **Don't override concrete functions.** Concrete functions often require source code dependencies; overriding them doesn't eliminate those dependencies, you *inherit* them. Instead make the function abstract and create multiple implementations.
    4. **Never mention the name of anything concrete and volatile.** A restatement of the principle itself.

- **Stable Abstractions**: every change to an abstract interface corresponds to a change in its concrete implementations; conversely, changes to concrete implementations do not always, or even usually, require changes to the interfaces they implement. Therefore interfaces are less volatile than implementations.
  - Good designers work hard to reduce the volatility of interfaces — finding ways to add functionality to implementations without changing the interfaces. "This is Software Design 101."
  - Implication: stable architectures avoid depending on volatile concretions and favor stable abstract interfaces.

- **Abstract Factory** (Figure 11.1): the mechanism for creating volatile concrete objects without depending on them.
  - When to use: any time high-level policy must instantiate something concrete — and creating an object requires, in virtually all languages, a source code dependency on that object's concrete definition.
  - How:
    1. `Application` uses `ConcreteImpl` only through the `Service` interface.
    2. `Application` calls `makeSvc` on the `ServiceFactory` **interface**.
    3. `ServiceFactoryImpl` derives from `ServiceFactory`, instantiates `ConcreteImpl`, and returns it as a `Service`.
    4. `main` instantiates `ServiceFactoryImpl` and places it in a global variable of type `ServiceFactory`; `Application` reaches the factory through that variable.
  - Why it works: the curved line in Figure 11.1 is an **architectural boundary** separating abstract from concrete. All source code dependencies cross it pointing in the same direction — toward the abstract side. The **flow of control crosses the curved line in the opposite direction of the source code dependencies**; the dependencies are inverted against the flow of control, which is why we call this Dependency Inversion.

- **Concrete Components rule**: the concrete component in Figure 11.1 contains a single dependency, so it violates the DIP. This is typical. **DIP violations cannot be entirely removed, but they can be gathered into a small number of concrete components and kept separate from the rest of the system.** Most systems contain at least one such component, often called `main` because it contains the `main` function — the function the operating system invokes when the application starts up.

## Key Concepts
- **Concretion / concrete module**: a module in which the functions being called are implemented.
- **Volatility**: how actively a module is being developed and changed; the property that makes a concrete dependency dangerous.
- **Stable concrete dependency**: e.g. `java.lang.string` — tolerated because change is rare and tightly controlled.
- **Stable abstraction**: an interface deliberately kept unchanged while implementations grow.
- **Abstract Factory**: the pattern that lets abstract policy create concrete objects without naming them.
- **Architectural boundary**: the curved line separating the abstract component (high-level business rules) from the concrete component (implementation details those rules manipulate).
- **Flow of control vs. source code dependency**: the two cross the boundary in opposite directions.
- **`main`**: the concrete component that holds the unavoidable DIP violations and wires up the factories.
- **The Dependency Rule**: the later generalization — dependencies cross boundaries in one direction, toward the more abstract entity.

## Reference Tables

| Dependency target | Depend on it? | Reason |
|---|---|---|
| Abstract interface / abstract class | Yes | Less volatile than implementations |
| Concrete but stable platform facility (`String`, OS, standard library) | Yes, tolerated | Changes are rare and tightly controlled |
| Concrete and volatile (modules you're actively developing) | No | Frequent, capricious change propagates to you |
| Concrete instantiation site | Confine to `main`/factory impls | Violations are unavoidable — gather them, don't scatter them |

## Mental Models
- Think of the boundary as a **one-way mirror**: control passes through it forwards, dependency arrows point backwards.
- Use **volatility, not concreteness, as the real test** — the question is never "is it a class?" but "does it change often, and do I control when?"
- Think of `main` as the **dirt trap** of the architecture: all the concrete wiring collects there so the rest of the system stays clean.
- Treat `new` on a volatile class inside policy code as a boundary violation; route it through an Abstract Factory instead.

## Worked Example
**Abstract Factory across the boundary (Figure 11.1).**

`Application` needs a `ConcreteImpl` but must not name it. It uses it through the `Service` interface, and obtains one by calling `makeSvc()` on the `ServiceFactory` interface. `ServiceFactoryImpl` derives from `ServiceFactory`, does the actual `new ConcreteImpl(...)`, and hands it back typed as `Service`.

Draw the curved line between {`Application`, `Service`, `ServiceFactory`} on the abstract side and {`ConcreteImpl`, `ServiceFactoryImpl`} on the concrete side. Every source code dependency crosses that line pointing toward the abstract side: `ConcreteImpl` implements `Service`, `ServiceFactoryImpl` implements `ServiceFactory`. Nothing on the abstract side names anything on the concrete side.

But at runtime, control starts in `Application` and travels *into* `ConcreteImpl` — the opposite direction. That opposition is the inversion.

The concrete component still holds one dependency (`ServiceFactoryImpl` must name `ConcreteImpl`), so it violates the DIP — typically and unavoidably. Contain it: `main` instantiates `ServiceFactoryImpl` and stores it in a global variable of type `ServiceFactory`, and `Application` reaches the factory through that variable. The abstract component holds all the high-level business rules; the concrete component holds all the implementation details those rules manipulate.

## Anti-patterns
- **Instantiating volatile concrete classes inside policy code**: creating an object requires a source code dependency on its concrete definition, so `new` in high-level code silently inverts your architecture the wrong way.
- **Deriving from volatile concrete classes**: inheritance is the strongest and most rigid source code relationship in statically typed languages.
- **Overriding concrete functions**: you don't shed the base function's dependencies, you inherit them. Make it abstract and provide implementations instead.
- **Chasing zero DIP violations**: impossible — the goal is to gather them into a small number of concrete components, not to eliminate them.
- **Abstracting stable platform types**: wrapping `String` or the standard library to "obey the DIP" is cost with no benefit; they aren't volatile.

## Key Takeaways
1. Point `import`/`use`/`include` at abstractions; nothing concrete and volatile should be depended on.
2. Volatility is the criterion, not concreteness — `java.lang.string` is concrete, stable, and fine to depend on.
3. Interfaces are less volatile than implementations, and good designers work to keep them that way.
4. Apply the four rules: don't refer to, don't derive from, don't override, don't name volatile concretions.
5. Use Abstract Factories to create volatile objects without depending on them; `main` wires the factory impl into a global of the abstract type.
6. DIP violations can't be removed, only concentrated into a few concrete components — usually `main`.
7. The flow of control crosses the boundary in the opposite direction of the source code dependencies. That is the inversion, and it generalizes into the Dependency Rule.

## Connects To
- **Ch 8 (OCP)**: the `FinancialDataGateway` and presenter interfaces are DIP applied for directional control.
- **Ch 9 (LSP)**: depending on an abstraction is only safe if its implementations are substitutable.
- **Ch 14 (SDP/SAP)**: "stable abstractions" here becomes the Stable Abstractions Principle and the I/A metrics.
- **Ch 22 (The Clean Architecture) & Ch 26 (The Main Component)**: the curved line becomes architectural boundaries; the Dependency Rule is this chapter generalized, and `main` is formalized as the ultimate detail and dirtiest component.
- **Dependency injection / IoC containers**: the industrial form of the Abstract Factory arrangement described here.
