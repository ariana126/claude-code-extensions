# The 23 Patterns — Compact Reference

Format: **When to use** / **How** / **Trade-offs**. Classification in the heading.
For depth, open the matching `chapters/` file.

---

# Creational

## Abstract Factory — *Object Creational*
**When**: a system must be independent of how its products are created, and you ship **families** of related products that must be used together (look-and-feels, platform widget sets).
**How**: an AbstractFactory interface with one factory method per product kind; a ConcreteFactory per family; clients hold the abstract factory and the abstract products.
**Trade-offs**: isolates concrete classes and enforces family consistency; but **adding a new product kind** means changing the factory interface and every concrete factory. Factories are often Singletons, or implemented as Prototype registries to avoid a subclass per family.

## Builder — *Object Creational*
**When**: the construction of a complex object must be independent of its parts and assembly, and the same process must yield different representations (one parser → RTF, TeX, or a widget tree).
**How**: a Director drives an abstract Builder step by step; ConcreteBuilders accumulate their own product and expose a `GetResult`.
**Trade-offs**: lets you vary the product's internal representation and isolates construction code; but requires a builder per representation, and the products often share no common interface. Composite is frequently what a builder builds.

## Factory Method — *Class Creational*
**When**: a class can't anticipate the class of objects it must create, or wants subclasses to specify it. The framework hook.
**How**: define a `CreateProduct()` operation in Creator; subclasses override it. Variants: an abstract method (subclass must), a default implementation (subclass may), or a parameterized factory method keyed by an identifier.
**Trade-offs**: the least machinery of the creational patterns; but requires **subclassing the Creator just to change the product**, which can force a parallel class hierarchy.

## Prototype — *Object Creational*
**When**: classes to instantiate are specified at run time, or you want to avoid a Creator hierarchy parallel to the product hierarchy, or instances differ only in a few state combinations.
**How**: an abstract `Clone()` on the product; clients copy a prototypical instance and initialize it. Keep a prototype manager/registry for lookup by key.
**Trade-offs**: adds and removes products at run time and reduces subclassing; but **every product must implement `Clone()`**, which is hard when the class already exists or contains circular references — and deep vs. shallow copy is a real decision.

## Singleton — *Object Creational*
**When**: there must be exactly one instance and it needs a well-known global access point, with room to subclass it.
**How**: private constructor, static `Instance()` returning a lazily created instance. For subclassable singletons, choose the subclass in `Instance()` or use a **registry of singletons** keyed by name.
**Trade-offs**: better than a global variable (lazy, subclassable, permits a variable number of instances later); but hides dependencies, complicates testing, and needs care with static-initialization order and threading.

---

# Structural

## Adapter (Wrapper) — *Class & Object Structural*
**When**: you want to use an existing class whose interface doesn't match, especially a library you can't change.
**How**: **class adapter** — inherit interface from Target and implementation privately from Adaptee. **Object adapter** — hold a reference to the Adaptee and forward. Prefer object adapters; they adapt subclasses too.
**Trade-offs**: class adapter is faster and lets you override Adaptee behavior but commits to one Adaptee class; object adapter is flexible but adds a level of indirection. Two-way adapters give transparency to both sides.

## Bridge (Handle/Body) — *Object Structural*
**When**: an abstraction **and** its implementation should both be extensible by subclassing, and you must avoid a permanent compile-time binding (or an N×M class explosion).
**How**: split into two hierarchies — Abstraction holds a pointer to an Implementor; RefinedAbstractions and ConcreteImplementors vary independently. Decide the implementor lazily or via an abstract factory.
**Trade-offs**: decouples interface from implementation, hides implementation from clients, allows run-time switching; but adds indirection and is over-engineering when there's only ever one implementation. Designed **up front**, unlike Adapter.

## Composite — *Object Structural*
**When**: you want part-whole hierarchies and clients to treat individual objects and compositions **uniformly**.
**How**: a Component interface declaring both leaf operations and child-management (`Add`/`Remove`/`GetChild`); Composite stores children and forwards.
**Trade-offs**: makes clients simple and new component types easy; but the uniformity is bought by **declaring child operations on leaves** — you trade type safety for transparency. Parent references, child ordering, and caching are the main implementation decisions.

## Decorator (Wrapper) — *Object Structural*
**When**: you must add responsibilities to individual objects dynamically and transparently, without subclassing — or subclassing is impractical (class explosion, sealed class).
**How**: Decorator conforms to Component's interface, holds a Component, and adds behavior before/after forwarding. Keep the abstract Decorator lightweight; nest freely.
**Trade-offs**: more flexible than static inheritance and pay-as-you-go; but produces **many small look-alike objects** that are hard to debug, and a decorator is not identical to its component (fails identity/`==` tests).

## Facade — *Object Structural*
**When**: you need a simple default view of a complex subsystem, or want to layer subsystems and minimize client coupling.
**How**: one class offering a unified higher-level interface that delegates to subsystem classes. Subsystem classes stay public; the facade doesn't hide them.
**Trade-offs**: reduces coupling and makes the subsystem easier to use without preventing expert access; but risks becoming a god object. Usually a Singleton. Abstract Facade + concrete subclasses lets you swap subsystem implementations.

## Flyweight — *Object Structural*
**When**: an application uses a huge number of objects, storage cost is prohibitive, most object state can be made **extrinsic**, and objects don't depend on identity.
**How**: split state — **intrinsic** (shareable, in the flyweight) vs **extrinsic** (context-dependent, passed in at call time). A FlyweightFactory pools and shares instances.
**Trade-offs**: dramatic space savings; but you pay run-time cost to compute or transfer extrinsic state, and clients must never rely on object identity. Combines well with Composite (shared leaves need no parent pointer).

## Proxy (Surrogate) — *Object Structural*
**When**: you need a placeholder controlling access. Four kinds: **remote** (different address space), **virtual** (create expensive objects on demand), **protection** (access rights), **smart reference** (ref counts, locking, load-on-first-access).
**How**: Proxy implements the Subject interface and holds a reference to the RealSubject, doing work before/after forwarding.
**Trade-offs**: adds a level of indirection that can be entirely invisible to clients; but introduces latency and the proxy may need to preserve the illusion (e.g. answering queries without loading the subject).

---

# Behavioral

## Chain of Responsibility — *Object Behavioral*
**When**: more than one object may handle a request, the handler isn't known a priori, and the set of handlers should be specified dynamically.
**How**: each handler holds a successor; it either handles the request or forwards. Give the base class a default forwarding implementation.
**Trade-offs**: reduces coupling and adds flexibility in assigning responsibility; but **receipt isn't guaranteed** — a request can fall off the end of the chain unhandled, and debugging is harder. Composite parents make natural successors.

## Command (Action, Transaction) — *Object Behavioral*
**When**: you must parameterize objects by an action, queue or log requests, or support undo/redo.
**How**: a Command interface with `Execute()` (and `Unexecute()`); ConcreteCommands bind a Receiver to an action. A **command history** list plus a "present" marker gives undo/redo; **MacroCommand** composes commands.
**Trade-offs**: decouples invoker from receiver and makes commands first-class, extensible objects; but produces one class per operation. A command copied before going on the history list acts as a **Prototype**; use Memento to snapshot state for undo.

## Interpreter — *Class Behavioral*
**When**: a simple language's grammar is stable and efficiency isn't critical — regular expressions, boolean expressions, simple query languages.
**How**: one class per grammar rule; build an abstract syntax tree of Terminal and Nonterminal expressions, each with an `Interpret(Context)`.
**Trade-offs**: grammar is easy to change and extend, and new interpretations are easy (add a Visitor); but **complex grammars produce at least one class per rule**, which becomes unmanageable — use a parser generator instead.

## Iterator (Cursor) — *Object Behavioral*
**When**: you need to access an aggregate's elements without exposing its representation, support multiple concurrent traversals, or a uniform interface across aggregate types.
**How**: **external** iterators (client drives `Next`) are more flexible; **internal** iterators (iterator drives) are easier to use. Polymorphic iterators require heap allocation — wrap them in an `IteratorPtr` proxy so the destructor cleans up.
**Trade-offs**: supports traversal variations and simplifies the aggregate; but polymorphic iterators leak without care, and **robust iterators** (valid across mutation) cost extra machinery. NullIterator makes Composite traversal uniform.

## Mediator — *Object Behavioral*
**When**: objects communicate in a well-defined but complex many-to-many web, reuse is hard because of it, or behavior distributed across classes should be customizable without subclassing them all.
**How**: colleagues talk only to the Mediator, which encapsulates the interaction. Colleagues can notify it via **Observer** instead of a direct call.
**Trade-offs**: turns many-to-many into one-to-many, decouples colleagues, and centralizes control; but **the mediator itself becomes a monolith** that's hard to maintain. Unlike Facade, communication is bidirectional.

## Memento (Token) — *Object Behavioral*
**When**: a snapshot of an object's state must be saved for later restore (undo, checkpoints) without violating encapsulation.
**How**: Originator creates a Memento holding its state and restores from it. Two interfaces: **wide** for the Originator (full access, often via `friend`), **narrow** for the Caretaker (opaque, store-and-return only).
**Trade-offs**: preserves encapsulation and simplifies the Originator; but can be **expensive** if state is large, and the caretaker can't know the storage cost it's carrying. **Incremental mementos** record only changes.

## Observer (Publish-Subscribe, Dependents) — *Object Behavioral*
**When**: a change to one object requires changing an unknown, varying number of others, and you don't want them tightly coupled.
**How**: Subject keeps a list of Observers and calls `Notify()`; observers `Update()` and pull what they need. **Push** model sends details (assumes observer needs); **pull** model sends only the subject (more failsafe, more calls). A **ChangeManager** mediator handles complex or DAG-shaped dependencies and batching.
**Trade-offs**: abstract, broadcast coupling; but an innocuous update can cascade expensively, and observers holding a **dangling reference to a deleted subject** is a classic bug. Register interest by *aspect* to reduce spurious updates.

## State (Objects for States) — *Object Behavioral*
**When**: an object's behavior depends on its state and it's littered with large multipart conditionals on that state.
**How**: a State class per state, each implementing the state-specific behavior; Context delegates and swaps its State object. Decide deliberately whether **Context** or the **State subclasses** define transitions — the latter is decentralized but couples states to each other.
**Trade-offs**: localizes state-specific behavior, makes transitions explicit and atomic; but **multiplies the number of classes**. Stateless State objects are often Singletons or Flyweights.

## Strategy (Policy) — *Object Behavioral*
**When**: many related classes differ only in behavior, you need variants of an algorithm, or a class has conditionals selecting among behaviors.
**How**: a Strategy interface per algorithm family; Context holds one and delegates. Pass data either as parameters (decoupled, may pass unused data) or by giving the strategy a reference back to the Context.
**Trade-offs**: eliminates conditionals, gives a family of reusable algorithms, and allows run-time choice; but **clients must know the strategies** to choose one, and you pay a communication overhead plus an object per strategy. Strategies make good Flyweights; template parameters remove the indirection when the choice is compile-time.

## Template Method — *Class Behavioral*
**When**: you want to fix an algorithm's skeleton and let subclasses vary specific steps — the fundamental **framework** technique.
**How**: a non-virtual template method calling **abstract operations** (subclass *must* supply) and **hook operations** (default, subclass *may* override). Prefix them (`Do-`) so it's clear which are meant to be overridden. Minimize the number of primitive operations.
**Trade-offs**: maximal code reuse and **inversion of control** — the "Hollywood Principle: don't call us, we'll call you"; but the variation is fixed at compile time and the inverted control flow is harder to follow. Factory Method is often called *by* a template method.

## Visitor — *Object Behavioral*
**When**: an object structure has many unrelated element classes, and you need to add many distinct, unrelated operations without polluting them — and the **element hierarchy rarely changes**.
**How**: **double dispatch** — element's `Accept(Visitor)` calls `visitor->VisitConcreteElement(this)`. The visitor accumulates state across the traversal. Traversal can live in the object structure, an Iterator, or the visitor itself.
**Trade-offs**: adding a new operation is trivial and related behavior is localized in one class; but **adding a new ConcreteElement class requires changing every visitor** — the fundamental asymmetry. Visitors often need privileged access to element state, weakening encapsulation.
