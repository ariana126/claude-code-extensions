# Design Patterns — Full Reference

Read this when the question is "which pattern fits here?", when someone arrives
holding a pattern and you need to decide whether it earns its place, or when GoF
advice appears to contradict a rule in this skill.

The governing idea: **a pattern is not a goal, it's the answer to "what varies?"**
Name the axis of variation first and the pattern falls out of it. Name no axis
and every pattern is premature — indirection bought with nothing to spend it on.

This skill's spine is Noback's *Object Design Style Guide*; GoF supplies the
vocabulary and the selection method. Where the two conflict, section 3 says
which wins and why. For a pattern's full Applicability / Consequences /
Implementation, use the `design-patterns-book` skill — this file deliberately
doesn't duplicate it.

## Contents

1. [Selection Tables](#1-selection-tables)
2. [Where GoF and Noback Agree](#2-where-gof-and-noback-agree)
3. [Where This Skill Overrides GoF](#3-where-this-skill-overrides-gof)
4. [Patterns and the Object Taxonomy](#4-patterns-and-the-object-taxonomy)
5. [Tells and Smells](#5-tells-and-smells)
6. [Applying a Pattern](#6-applying-a-pattern)

---

## 1. Selection Tables

### By what varies

The single most useful table in GoF (Table 1.2). Name the aspect you want free
to change; it names the pattern.

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

### By cause of redesign

Start from the change you fear rather than the structure you want.

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

### Disambiguation

| Confusion | The distinction |
|---|---|
| Adapter vs. Bridge | Adapter **retrofits** an interface after the fact; Bridge is designed **up front** so abstraction and implementation vary independently. |
| Adapter vs. Decorator vs. Proxy | Adapter **changes** the interface; Decorator **extends** responsibilities and keeps the interface; Proxy **keeps** the interface and controls access. |
| Composite vs. Decorator | Composite aggregates for **uniform treatment** of part and whole; Decorator wraps one component and adds **responsibilities**. |
| Decorator vs. Strategy | Decorator changes the **skin**; Strategy changes the **guts**. |
| State vs. Strategy | State encapsulates **state-dependent behavior and its transitions**; Strategy encapsulates **an algorithm the client chooses**. |
| Facade vs. Mediator | Facade simplifies a subsystem **unidirectionally** (the subsystem doesn't know); Mediator's colleagues **talk back** to it. |
| Factory Method vs. Abstract Factory vs. Prototype | A new Creator **subclass** / a new factory **object** / a `Clone()` on the product. |
| Template Method vs. Strategy | Template Method varies steps by **inheritance**; Strategy varies the whole algorithm by **delegation**. This skill always picks delegation — see §3. |
| Mediator vs. Observer | Mediator centralizes **who talks to whom**; Observer decouples **one-to-many change propagation**. |
| Visitor vs. Iterator | Iterator varies **traversal**; Visitor varies **what you do at each node**. |
| Chain of Responsibility vs. Command | CoR varies **which object handles** the request; Command varies **when and how** it's carried out. |

### Class scope vs. object scope

Factory Method, class-Adapter, Interpreter and Template Method are **class
scope** — fixed at compile time via inheritance. Everything else is **object
scope**, changeable at run time via composition. Default to object scope. That
is the same instruction as "inheritance is not on the ladder" in
`changing-behavior.md` §7, arrived at from GoF's own principle: *favor object
composition over class inheritance.*

## 2. Where GoF and Noback Agree

Most of this skill is already GoF, unlabeled. The escalation ladder in
`changing-behavior.md` is a sequence of patterns:

| Rung | What the reference calls it | Pattern |
|---|---|---|
| 2 | Replaceable dependency — inject `FileLoader` | **Strategy** |
| 3 | Composition — `MultipleLoaders` dispatching by extension | **Composite** |
| 4 | Decoration — `CachedFileLoader`, `LoggingLineImporter` | **Decorator** |
| 5 | Notification objects and event listeners | **Observer** |

And elsewhere in the skill:

- **Adapter** — wrapping a system boundary behind an abstraction named for the
  question rather than the mechanism (`Clock`, `FileLoader`, `ExchangeRates`)
  is Adapter applied at the point GoF calls "inability to alter classes
  conveniently": you can't change the standard library or the vendor SDK, so
  you wrap it.
- **Null Object** — `NullLogger` and `NoOpEventDispatcher` in
  `construction.md` §2. Not a GoF pattern, but it's what makes "no optional
  dependencies" affordable.
- **Observer with a domain-language interface** — `ImportNotifications` with
  `whenLineImported()` is Observer with the generic `Subject`/`attach()`
  machinery collapsed into one named interface. Explicit and greppable, at the
  cost of changing the interface to add a notification.
- **Facade** — an application service is a facade over the domain: one method
  per use case, clients never reach past it into entities and repositories.
- **Command** — GoF's Command object *is* the command object named in the
  Application layer in `layers-and-models.md` §4. Note the collision: GoF's
  **Command pattern** (a request reified as an object) is a different thing
  from a **command method** under CQS (a void, state-changing method). Both
  appear in this skill; keep them apart when speaking.

Two GoF principles are load-bearing here under other names:

- **Program to an interface, not an implementation** ≡ this skill's
  two-part abstraction rule: an interface, *and* a name with no implementation
  details in it. GoF stops at the first half; `HttpClient` satisfies GoF and
  still fails here.
- **Favor object composition over class inheritance** ≡ the ladder itself, and
  `final` by default.

## 3. Where This Skill Overrides GoF

GoF catalogues what works; it doesn't rank the entries. This skill does, and in
seven places it lands somewhere the 1994 book didn't. Each override has a
reason — cite the reason, not the ruling.

**Singleton — rejected.** `Config.getInstance()` is a service locator wearing
a nicer hat: a global access point that never appears in a constructor
signature, so a class with four hidden dependencies reads as a class with none
(`ANTI_PATTERNS.md` §1, §6, §31). It also welds every client to a lifetime
decision and makes tests share state. The need behind it — "there must be
exactly one" — is real and is met by instantiating once at the composition root
and injecting it. One instance is a *wiring* fact, not a property of the class.

**Template Method — a waypoint, not a destination.** GoF presents it as a
first-class pattern; here it's the second of three states, better than raw
subclassing and strictly weaker than composition. The conversion is one
mechanical step (`changing-behavior.md` §8): promote the `abstract protected`
hook to a `public` method on an injected object, mark the class `final`.
Everything Template Method does, Strategy does — plus composability, decoration,
and independent testing of the hook.

**Prototype / `Clone()` — prefer construction.** Cloning bypasses the
constructor, which is exactly where this skill puts validation. An immutable
modifier should build the copy **through the constructor** so the guards are
reused for free (`SKILL.md` § Mutability). Deep-vs-shallow copy bugs are the
second reason; a constructor taking values has neither problem.

**Factory Method — usually the wrong factory.** It varies behavior by requiring
a Creator *subclass*, i.e. inheritance as an extension mechanism. Prefer an
injected factory object (a service like any other) or, for value objects and
entities, **named constructors** — `SalesOrder.place()`, `Money.fromCents()` —
which give you multiple construction paths funnelling through one guarded
private constructor with no hierarchy at all.

**Builder — narrower than GoF suggests.** A builder is an object that is
invalid until `build()` is called, which is the trap this skill's "require the
minimum data to behave consistently" rule exists to close. For domain objects,
named constructors plus a complete constructor win. Builder stays legitimate
where GoF aimed it: genuinely large composite structures assembled step by step
from a parse or a stream — and in test fixtures, where readability of the
*test* is the point and the object still comes out fully validated.

**Memento — usually unnecessary for entities.** The "observe an object's state
without opening it up" problem is already solved here by **recorded domain
events**: a private `events` list appended to by command methods, exposed via
`recordedEvents()`. That gives tests and read models what they need without a
snapshot type and without getters. Memento remains the right call for genuine
undo/redo over an editor-like model.

**Observer with mutable registration — no.** GoF's `subject.attach(observer)`
after construction is a behavior-changing setter (`ANTI_PATTERNS.md` §4): the
service takes different execution paths depending on who called what first.
Pass listeners to the constructor. If listeners genuinely must be dynamic, that
belongs in a dispatcher wired at the composition root, not on the domain service.

## 4. Patterns and the Object Taxonomy

The skill's load-bearing split — **service** vs **other object** — also sorts
the catalogue. Applying a service-shaped pattern to a value object is how a
repository ends up injected into a `Money`.

**For services** (do-ers, constructed once, hold dependencies): Strategy,
Decorator, Adapter, Facade, Proxy, Chain of Responsibility, Observer, Mediator,
Abstract Factory. These all compose objects that hold *collaborators*.

**For other objects** (materials, hold values): Composite (an `Order` of
`OrderLines`; a nested `Specification`), State (transitions owned by the
entity), Null Object (`EmptyPage`, `NoDiscount`), Flyweight (shared immutable
values — which value objects already are), Iterator (a first-class collection
answering questions about itself).

**Neither, or at the edge**: Command objects and DTOs live in the Application
layer; Interpreter and Visitor come up in parsers and reporting, not in ordinary
domain code.

A pattern that requires injecting a service into an entity or value object is a
pattern you've placed in the wrong layer — the behavior belongs in a service
that takes both the entity and the collaborator (`ANTI_PATTERNS.md` §21).

## 5. Tells and Smells

| What you see | Reach for |
|---|---|
| A big `switch`/`if` chain on a *type* field, growing with each feature | **Strategy** — one implementation per branch, dispatched by a composite |
| A big `switch` on a *status* field, with rules about which status follows which | **State** — transitions owned by the object |
| N × M subclasses for N features × M variants | **Bridge**, **Decorator** or **Strategy** |
| Cross-cutting logic (logging, caching, retries) duplicated in every implementation | **Decorator** |
| Clients reaching deep into a subsystem, knowing its call order | **Facade** |
| An object storing data it never uses, only to hand back later | **Memento** — or, more likely here, that data belongs to the caller |
| Huge numbers of near-identical fine-grained objects | **Flyweight** — split intrinsic from extrinsic state |
| Adding a new *operation* is frequent; adding a new *element class* is rare | **Visitor**. Reverse it and Visitor is the wrong call |
| `new ConcreteClass()` appearing outside a factory or the composition root | A coupling smell — program to an interface |
| A conditional choosing *who* handles a request | **Chain of Responsibility** |

## 6. Applying a Pattern

The threshold first: **don't apply a pattern until you need the flexibility.**
Every pattern buys variation with indirection, paid for in complexity and often
performance. Read a pattern's **Applicability** and **Consequences** before its
structure diagram — those sections, not the diagram, are the pattern's real
content. This is the same instruction as "abstract early, generalize late":
introduce the interface at the first implementation, wait for roughly three
similar cases before generalizing.

Once you've decided (GoF §1.8, compressed):

1. Read it through — **Applicability** and **Consequences** first.
2. Study Structure, Participants, Collaborations, then the sample code.
3. Rename the participants for your domain, but **keep the pattern name
   visible**: `TeXLayoutStrategy`, `CachedFileLoader`, `NullLogger`. The name is
   documentation for the next reader.
4. Define the classes; name operations from responsibilities, consistently.
5. Apply this skill's rules to the result — the pattern tells you the shape, not
   the mechanics. The participants are still `final`, still take required
   constructor arguments, still obey CQS, and the interface still gets a name
   free of implementation details.

Step 5 is the one people skip. A Strategy interface called `IPaymentHandler`
with an optional logger and a `setMode()` is a correctly shaped pattern built
out of everything this skill forbids.
