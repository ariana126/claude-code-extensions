# Design Patterns — Decision Cheatsheet

## The master question: what varies?
Table 1.2 — pick the pattern by the **aspect you want free to change**.

| Pattern | Aspect(s) that can vary |
|---|---|
| **Abstract Factory** | families of product objects |
| **Builder** | how a composite object gets created |
| **Factory Method** | subclass of object that is instantiated |
| **Prototype** | class of object that is instantiated |
| **Singleton** | the sole instance of a class |
| **Adapter** | interface to an object |
| **Bridge** | implementation of an object |
| **Composite** | structure and composition of an object |
| **Decorator** | responsibilities of an object, without subclassing |
| **Facade** | interface to a subsystem |
| **Flyweight** | storage costs of objects |
| **Proxy** | how an object is accessed; its location |
| **Chain of Responsibility** | object that can fulfill a request |
| **Command** | when and how a request is fulfilled |
| **Interpreter** | grammar and interpretation of a language |
| **Iterator** | how an aggregate's elements are accessed and traversed |
| **Mediator** | how and which objects interact with each other |
| **Memento** | what private information is stored outside an object, and when |
| **Observer** | number of objects that depend on another; how they stay up to date |
| **State** | states of an object |
| **Strategy** | an algorithm |
| **Template Method** | steps of an algorithm |
| **Visitor** | operations applicable to objects without changing their classes |

## Cause of redesign → pattern
| If this is what will change | Reach for |
|---|---|
| Creating an object by naming a class explicitly | Abstract Factory, Factory Method, Prototype |
| Dependence on specific operations | Chain of Responsibility, Command |
| Dependence on hardware/software platform | Abstract Factory, Bridge |
| Dependence on object representation or implementation | Abstract Factory, Bridge, Memento, Proxy |
| Algorithmic dependencies | Builder, Iterator, Strategy, Template Method, Visitor |
| Tight coupling | Abstract Factory, Bridge, Chain of Responsibility, Command, Facade, Mediator, Observer |
| Extending functionality by subclassing | Bridge, Chain of Responsibility, Composite, Decorator, Observer, Strategy |
| Inability to alter classes conveniently | Adapter, Decorator, Visitor |

## Disambiguation — patterns people confuse
| Confusion | The distinction |
|---|---|
| Adapter vs. Bridge | Adapter **retrofits** interfaces after the fact; Bridge is designed **up front** so abstraction and implementation vary independently. |
| Adapter vs. Decorator vs. Proxy | Adapter **changes** the interface; Decorator **extends** responsibilities and keeps the interface; Proxy **keeps** the interface and controls access. |
| Composite vs. Decorator | Composite aggregates for **uniform treatment** of part and whole; Decorator has one component and adds **responsibilities**. |
| Decorator vs. Strategy | Decorator changes the **skin**; Strategy changes the **guts**. |
| State vs. Strategy | State objects encapsulate **state-dependent behavior and transitions**; Strategy encapsulates an **algorithm the client chooses**. |
| Facade vs. Mediator | Facade abstracts a subsystem **unidirectionally** (subsystem doesn't know it); Mediator's colleagues **talk back** to it, multidirectionally. |
| Factory Method vs. Abstract Factory vs. Prototype | Factory Method needs a **new Creator subclass**; Abstract Factory needs a **new factory object** (flexible, but adding a product *kind* is invasive); Prototype needs **Clone + Initialize** and no subclass at all. |
| Template Method vs. Strategy | Template Method varies steps via **inheritance**; Strategy varies the whole algorithm via **delegation**. |
| Mediator vs. Observer | Mediator centralizes **who talks to whom**; Observer decouples **one-to-many change propagation**. Mediator often uses Observer internally. |
| Visitor vs. Iterator | Iterator varies **traversal**; Visitor varies **what you do at each node**. |
| Chain of Responsibility vs. Command | CoR varies **which object handles** the request; Command varies **when and how** it's carried out. |

## Class scope vs. object scope
- **Class scope** (Factory Method, Adapter-class, Interpreter, Template Method) — fixed at compile time via inheritance. Cheaper, static.
- **Object scope** (everything else) — changeable at run time via composition. More flexible, more indirection.
- Default to **object scope** unless the variation is genuinely compile-time. "Favor object composition over class inheritance."

## Thresholds, defaults, and tells
- **Don't apply a pattern until the flexibility is actually needed** — every pattern buys variation with indirection, paying in complexity and often performance. Read **Consequences** before committing.
- **Program to an interface, not an implementation** — if a `new ConcreteClass()` appears outside a creational pattern, that's a coupling smell.
- **Tell — cascading subclass explosion**: needing N×M subclasses for N features × M variants → Bridge, Decorator, or Strategy.
- **Tell — a big conditional on a type or state field** → Strategy (algorithm) or State (state), or polymorphism.
- **Tell — clients reaching deep into a subsystem** → Facade.
- **Tell — an object storing data it doesn't use, only to hand back later** → Memento.
- **Tell — huge numbers of near-identical fine-grained objects** → Flyweight (split intrinsic vs extrinsic state).
- **Adding a new operation is frequent, adding a new element class is rare** → Visitor. Reverse it and Visitor is the wrong call.
- **Singleton is the exception, not the default** — it's a global with better manners; it still couples clients to a lifetime decision and hurts testability.

## Applying a pattern — the 7 steps (§1.8)
1. Read it through; check **Applicability** and **Consequences** first.
2. Study **Structure, Participants, Collaborations**.
3. Study the **Sample Code**.
4. Rename participants for your domain, keeping the pattern name visible (`TeXLayoutStrategy`).
5. Define the classes: interfaces, inheritance, instance variables; modify existing classes.
6. Name operations from the responsibilities; be consistent (`Create-` prefix for factory methods).
7. Implement the operations, using the **Implementation** hints.
