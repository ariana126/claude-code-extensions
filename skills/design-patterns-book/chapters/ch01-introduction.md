# Chapter 1: Introduction

## Core Idea
Experts don't solve design problems from first principles; they reuse solutions that
worked before. A **design pattern** names, abstracts, and identifies the key aspects of a
recurring design structure — the participating classes and instances, their roles,
collaborations, and distribution of responsibilities — so you can apply it deliberately
instead of rediscovering it. Patterns sit between reusable data structures (too concrete)
and whole frameworks (too specialized): they are *descriptions of communicating objects
and classes customized to solve a general design problem in a particular context*.

## Frameworks Introduced

**The four essential elements of a pattern** — use this to judge whether something you've
found is really a pattern, and to write one up:
1. **Pattern name** — a handle for the problem, solutions, and consequences in a word or
   two. Raises the level of design vocabulary and abstraction. Naming is the hardest part.
2. **Problem** — when to apply the pattern: the context, the symptomatic inflexible
   structure, and any preconditions.
3. **Solution** — the elements, relationships, responsibilities, and collaborations. Not
   a concrete implementation — a template applicable many ways.
4. **Consequences** — results and trade-offs: space/time, language/implementation issues,
   and impact on flexibility, extensibility, portability.

**The pattern template** — every catalog entry has: Pattern Name and Classification;
Intent; Also Known As; Motivation; Applicability; Structure (OMT diagrams + interaction
diagrams); Participants; Collaborations; Consequences; Implementation; Sample Code (C++
or Smalltalk); Known Uses (at least two, from different domains); Related Patterns.

**Application vs. toolkit vs. framework** — three targets with different priorities:
- *Application*: internal reuse, maintainability, extension. Reduce dependencies.
- *Toolkit*: a set of related reusable classes providing general-purpose functionality
  (collections, C++ iostreams). Emphasizes **code reuse**; imposes no architecture.
- *Framework*: cooperating classes forming a reusable design for a class of software.
  Emphasizes **design reuse**; dictates architecture; produces **inversion of control** —
  you reuse the main body and write the code *it* calls. Hardest of the three to design.

Patterns differ from frameworks in three ways: patterns are more abstract (only
*examples* of patterns can be embodied in code), smaller architectural elements (a
framework contains several patterns, never the reverse), and less specialized (a
framework always has an application domain).

## Key Concepts
- **Interface / signature / type**: a signature is an operation's name, parameters, and
  return value; the interface is the set of all signatures; a *type* is a name denoting a
  particular interface. An object may have many types; different classes can share a type.
- **Subtype / supertype**: a type whose interface contains another's; the subtype
  *inherits* the supertype's interface.
- **Dynamic binding / polymorphism**: run-time association of a request to an object and
  one of its operations; substitutability of same-typed objects at run-time.
- **Class inheritance vs. interface inheritance (subtyping)**: class inheritance defines
  an object's implementation in terms of another's (code and representation sharing);
  interface inheritance describes when an object can be *used in place of* another.
- **White-box reuse**: reuse by subclassing — the parent's internals are visible to the
  subclass. Static, compile-time, easy, but "inheritance breaks encapsulation."
- **Black-box reuse**: reuse by **object composition** — objects assembled through
  well-defined interfaces; no internals visible. Dynamic, run-time, replaceable.
- **Delegation**: two objects handle a request — a receiver forwards to a *delegate* and
  passes *itself* along so the delegated operation can refer back to the receiver.
- **Parameterized types (generics, templates)**: a third composition technique — define a
  type without specifying all the types it uses; supply them at the point of use.
- **Aggregation vs. acquaintance**: aggregation means one object *owns* or *is part of*
  another, with identical lifetimes (diamond-base arrow). Acquaintance means an object
  merely *knows of* another ("association", "using"; plain arrowhead) — weaker, looser,
  more frequently remade. Both are often implemented identically (pointers/references);
  the distinction is one of **intent**.
- **Abstract class / abstract operation / mixin class**: an abstract class defines a
  common interface and defers implementation; it cannot be instantiated. A mixin provides
  an optional interface to other classes and requires multiple inheritance.

## Mental Models
- **"Program to an interface, not an implementation."** Never declare variables as
  instances of concrete classes; commit only to an interface defined by an abstract
  class. Clients then know neither the object's type nor its implementing class. You must
  instantiate concrete classes *somewhere* — that's exactly what the creational patterns
  (Abstract Factory, Builder, Factory Method, Prototype, Singleton) are for.
- **"Favor object composition over class inheritance."** Composition keeps each class
  encapsulated and focused on one task; hierarchies stay small. Cost: more objects, and
  behavior lives in their interrelationships rather than in one class. Designers overuse
  inheritance; most designs get simpler by leaning on composition.
- **"Encapsulate the concept that varies."** The unifying theme: each pattern lets some
  aspect of structure vary independently of the rest.
- Think of run-time structure as an ecosystem and compile-time structure as a taxonomy —
  the two are largely independent. Code won't reveal how the system works until you know
  the patterns (Composite, Decorator, Observer, Chain of Responsibility especially).
- Delegation is an extreme case of composition: a Window that *has* a Rectangle instead
  of *being* one can become circular at run-time by swapping in a Circle.

## Anti-patterns
- **Subclassing for reuse of implementation**: binds the subclass to the parent's
  representation; any parent change forces subclass change. Cure: inherit only from
  abstract classes.
- **Declaring variables of concrete class type**: hard-codes an implementation choice and
  defeats polymorphism.
- **Strict real-world modeling**: yields a system reflecting today's realities, not
  tomorrow's. The useful abstractions (Strategy's algorithm objects, State's state
  objects, Composite's uniform component) have no physical counterpart and emerge later.
- **Applying patterns indiscriminately**: patterns buy flexibility with extra levels of
  indirection, which costs comprehensibility and sometimes performance. Apply a pattern
  only when the flexibility is actually needed; read the Consequences section first.
- **Over-parameterized, highly dynamic designs**: harder to understand than static ones.
  Delegation is a good choice only when it simplifies more than it complicates — it works
  best used in highly stylized ways, i.e. in standard patterns.

## Reference Tables

### Table 1.1: The design pattern space (Purpose × Scope)

| Scope | Creational | Structural | Behavioral |
|---|---|---|---|
| **Class** | Factory Method | Adapter (class) | Interpreter, Template Method |
| **Object** | Abstract Factory, Builder, Prototype, Singleton | Adapter (object), Bridge, Composite, Decorator, Facade, Flyweight, Proxy | Chain of Responsibility, Command, Iterator, Mediator, Memento, Observer, State, Strategy, Visitor |

**Purpose** = what a pattern does: *creational* patterns concern object creation,
*structural* the composition of classes or objects, *behavioral* how classes/objects
interact and distribute responsibility. **Scope** = whether it applies primarily to
classes (relationships fixed at compile-time via inheritance) or objects (relationships
changeable at run-time). Most patterns are object-scope.

Creational *class* patterns defer part of object creation to subclasses; creational
*object* patterns defer it to another object. Structural *class* patterns use inheritance
to compose classes; structural *object* patterns assemble objects. Behavioral *class*
patterns use inheritance to describe algorithms and flow of control; behavioral *object*
patterns describe how a group of objects cooperates on a task no one object can do alone.

### Causes of redesign → patterns that address them

| # | Cause of redesign | Design patterns |
|---|---|---|
| 1 | Creating an object by specifying a class explicitly | Abstract Factory, Factory Method, Prototype |
| 2 | Dependence on specific operations | Chain of Responsibility, Command |
| 3 | Dependence on hardware and software platform | Abstract Factory, Bridge |
| 4 | Dependence on object representations or implementations | Abstract Factory, Bridge, Memento, Proxy |
| 5 | Algorithmic dependencies | Builder, Iterator, Strategy, Template Method, Visitor |
| 6 | Tight coupling | Abstract Factory, Bridge, Chain of Responsibility, Command, Facade, Mediator, Observer |
| 7 | Extending functionality by subclassing | Bridge, Chain of Responsibility, Composite, Decorator, Observer, Strategy |
| 8 | Inability to alter classes conveniently | Adapter, Decorator, Visitor |

### How to select a design pattern
1. Consider how design patterns solve design problems (finding appropriate objects,
   determining granularity, specifying interfaces and implementations).
2. Scan Intent sections; narrow with the classification of Table 1.1.
3. Study how patterns interrelate (Figure 1.1 relationship graph).
4. Study patterns of like purpose — each catalog chapter compares and contrasts its own.
5. Examine a cause of redesign (table above) and find the patterns that avoid it.
6. Consider what should be variable in your design — the inverse question. Focus on
   *encapsulating the concept that varies* (Table 1.2 lists the aspect each pattern
   lets you vary: e.g. Abstract Factory → families of product objects; Bridge →
   implementation of an object; Command → when and how a request is fulfilled;
   Strategy → an algorithm; Visitor → operations applied to objects without changing
   their classes).

### How to use a design pattern
1. Read the pattern through for an overview; check Applicability and Consequences first.
2. Study Structure, Participants, and Collaborations.
3. Study Sample Code for a concrete implementation.
4. Choose participant names meaningful in your application context, but keep the
   participant name inside them (e.g. `SimpleLayoutStrategy`, `TeXLayoutStrategy`).
5. Define the classes: interfaces, inheritance relationships, instance variables; modify
   existing affected classes.
6. Define application-specific operation names, consistently (e.g. a `Create-` prefix for
   factory methods).
7. Implement the operations to carry out the pattern's responsibilities and
   collaborations.

## Code Examples

```cpp
// Program to an interface, not an implementation.
// Bad: commits the client to a concrete class at compile-time.
MotifScrollBar* sb = new MotifScrollBar;

// Good: the variable's type is the abstract interface, and creation is
// abstracted behind a creational pattern (here, Abstract Factory).
ScrollBar* sb = guiFactory->CreateScrollBar();
```

```cpp
// Delegation: Window HAS-A Rectangle rather than IS-A Rectangle.
// Swap the delegate at run-time and the window becomes circular.
class Window {
public:
    virtual float Area() { return _shape->Area(); }  // forward to delegate
private:
    Shape* _shape;   // acquaintance/aggregation decided by intent
};
```

**What they demonstrate**: the two principles in one line each — abstract type on the
left of the declaration, and reuse obtained by holding a reference rather than by
inheriting a representation.

## Worked Example: design patterns inside Smalltalk MVC
MVC is not one pattern but a composition of several — a good test of whether you can
*see* patterns in an existing design.
- **Model ↔ View** uses a subscribe/notify protocol: the model notifies dependents when
  its data changes, so multiple views (spreadsheet, histogram, pie chart) can present the
  same model and new views need no model rewrite. Generalized, this is **Observer** —
  decoupling objects so a change in one affects many others without the changed object
  knowing their details.
- **CompositeView**, a subclass of View, contains and manages nested views yet is usable
  wherever a View is. Generalized: **Composite** — treat a group of objects like an
  individual object, with some subclasses primitive (Button) and others composite.
- **View ↔ Controller**: a view holds a Controller instance implementing a response
  strategy; replace the instance (even at run-time — give it a controller that ignores
  input to disable the view) to change behavior without touching presentation.
  Generalized: **Strategy** — an object representing an algorithm.
- MVC also uses **Factory Method** to specify a view's default controller class and
  **Decorator** to add scrolling to a view.

## Key Takeaways
1. A pattern is name + problem + solution + consequences. If you can't state the
   consequences, you haven't captured the pattern.
2. Program to an interface, not an implementation — and put every `new` of a concrete
   class behind a creational pattern.
3. Favor object composition over class inheritance; inherit from abstract classes when
   you must inherit at all.
4. Ask "what should be able to vary here without redesign?" and let the answer pick the
   pattern (Table 1.2 / the causes-of-redesign table).
5. Aggregation vs. acquaintance is a decision about intent and lifetime, not about C++
   syntax — both compile to pointers.
6. Run-time structure is designed, not declared; code alone won't show it until you know
   the patterns in play.
7. Indirection isn't free. Apply a pattern only when you actually need the flexibility.

## Connects To
- **Ch 2 (Lexi case study)** — the eight patterns applied end-to-end in one design.
- **Ch 3–5** — the catalog, organized exactly by the Purpose × Scope table above.
- **Ch 6 (Conclusion)** — what patterns do for a design vocabulary and community.
- Patterns named here: Observer, Composite, Strategy, Factory Method, Decorator,
  Abstract Factory, Builder, Prototype, Singleton, Bridge, Adapter, Proxy, Memento,
  Facade, Flyweight, Mediator, Chain of Responsibility, Command, Iterator, Visitor,
  Template Method, State, Interpreter.
