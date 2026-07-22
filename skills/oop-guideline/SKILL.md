---
name: oop-guideline
description: >
  Use this skill when designing, writing, or reviewing object-oriented code in
  any language. Triggers include: reviewing or writing a class, service, entity,
  or value object; deciding what belongs in a constructor versus a method;
  adding a dependency; wondering whether a getter should exist; choosing an
  exception type; making a class configurable or extensible; choosing or
  applying a design pattern; or reacting to a class that "does too
  much" or "is hard to test". Also use when the user mentions "value object",
  "entity", "DTO", "immutability", "CQS", "null object",
  "anemic domain model", "dependency injection", "service locator",
  "composition over inheritance", "read model", "domain event", "design
  pattern", "strategy", "decorator", "observer", "singleton", "template
  method", "which pattern should I use", a "big switch on a type field", or a
  "subclass explosion". Use it even if the user just says "review this class"
  or "is this good design?" without naming a methodology — this skill provides
  the methodology.
license: MIT
metadata:
  version: "1.1"
  author: ariana.maghsoudi82@gmail.com
  sources:
    - "Object Design Style Guide by Matthias Noback"
    - "Design Patterns: Elements of Reusable Object-Oriented Software by Gamma, Helm, Johnson & Vlissides"
---

# OOP Guideline Skill

This skill encodes one coherent object-oriented design philosophy, taken from
*Object Design Style Guide* by Matthias Noback. The through-line is that an
object should be **impossible to misuse**: complete the moment it exists, honest
about what it needs, and unable to enter a state its domain doesn't allow.

Noback's own caveat applies and is worth keeping: bend these rules when quality
genuinely doesn't matter or the effort clearly outweighs the benefit. He
estimates that's under 5% of real cases, so treat a deviation as something to
justify rather than a coin flip.

The book deliberately does *not* tell you which objects you need or what their
responsibilities are. It tells you how to build the ones you've decided on.

Where behavior has to vary, the second source is *Design Patterns* by the Gang
of Four — used here for its selection method ("what varies?") and its
vocabulary, not as a catalogue to work through. Noback stays the spine: where
the two disagree, `references/design-patterns.md` records which wins and why.

## Start Here: The Two Types of Objects

Every object is either a **service** or an **other object**, and this is the
load-bearing distinction — nearly every other rule dispatches on it.

- A **service** is a do-er. It performs a task or answers a question:
  `EventDispatcher`, `UserRepository`, `TemplateRenderer`, `DiscountCalculator`.
  Named for what it *does*. Constructed once, reused forever.
- An **other object** is a material — the thing being worked on: `User`,
  `Money`, `Credentials`, `Position`. Named for what it *is*.

The two get opposite rulesets. **Services receive dependencies; other objects
receive values.** A service never holds task data; an other object never holds
a service. When you catch yourself wanting to inject a repository into a `Money`,
that's the signal the behavior belongs in a service instead.

Before applying any rule below, decide which kind of object you're looking at.

## Creating Services

**Every dependency and configuration value is a required constructor argument.**
No optional arguments, no default values, no setter injection. There is no such
thing as an optional dependency — you either need it or you don't. If a
dependency feels optional, replace it with a **null object** (`NullLogger`,
`NoOpEventDispatcher`); if a config value feels optional, offer a
`Configuration.createDefault()` factory. Both give clients the convenience they
wanted without leaving the service able to exist half-configured, and both
delete the `if (this.logger)` guards that would otherwise spread through every
method.

**Inject what you need, not where you can get it from.** If a constructor
argument is something you call `.get()` on — a container, service locator,
entity manager, registry — inject the real collaborator instead. Ask: *does this
service use the dependency directly, or retrieve the real dependency from it?*
Iterate until the answer is "uses directly": `ServiceLocator` → `EntityManager`
→ `UserRepository`. The payoff is that the constructor signature becomes an
honest inventory. A locator hides three dependencies behind one and removes all
design pressure to notice you have too many.

**A constructor does exactly two things: validate and assign.** No `mkdir`, no
connecting, no calling a dependency, no lazy setup. There's a quick test for
whether you've broken this: *if reordering the property assignments changes the
behavior, you're doing work in the constructor.* When a constructor wants to do
work, push that outward into a factory or the application's bootstrap — not
inward into a lazy private method.

**Task data and "the current X" are method arguments, not constructor
arguments.** The **batch test** decides it: *could I run this service in a batch
without reinstantiating it?* If no, the argument belongs on the method. The word
"current" is the reliable tell — the current time, the currently logged-in user,
the current request, the current locale are all contextual data.

| Argument is…                       | Goes where                        |
|------------------------------------|-----------------------------------|
| A collaborating service            | Constructor                       |
| A configuration value              | Constructor (required, no default)|
| Task data                          | Method                            |
| Contextual info ("the current X")  | Method                            |

**Make hidden dependencies explicit.** A dependency that doesn't appear in the
constructor signature still exists — it's just invisible. Static accessors
(`Cache.get(...)`) become injected objects. Complex standard-library calls
(`json_encode`) become injected wrappers, though only when you'd want to replace
the behavior later, it's too complex to inline, or it deals in objects rather
than primitives — `strpos` and `array_keys` stay where they are. System calls
(`new Date()`, `time()`, filesystem reads) become an injected `Clock` or gateway,
or better, get passed as a method argument, since "the current time" is
contextual data rather than a collaborator.

**Once constructed, a service must be impossible to reconfigure.** No
`setLogger()`, no `ignoreErrors()`, no `addListener()`. Behavior-changing setters
mean the service takes different execution paths depending on who called what
first, which is a bug waiting for a race to happen.

**Read `references/construction.md`** when designing a new class from scratch or
untangling a constructor that has grown awkward — it covers constructor
injection, null objects, the Clock pattern, DTO rules, and what to test about
construction.

## Creating Other Objects

**State the domain invariant as a sentence before writing any code.** "A
position has both an x and a y." "Latitude is between −90 and 90 inclusive."
Then encode it as a constructor check, then cover it with a test. Writing the
sentence first is what stops you from encoding an arbitrary rule you can't
defend.

**Require the minimum data needed to behave consistently, and require data that
is meaningful.** All essential data goes through the constructor — no setters
for it. An object that exists but can't answer questions yet is a trap:
`new Position()` followed by `distanceTo(other)` gives a meaningless answer
rather than an error. Type-correct isn't enough either; validate ranges,
relationships, and combinations. Put each check directly above the assignment it
guards, so the relationship reads clearly.

**When two arguments must be validated against each other, suspect the design
before writing the check.** Two escape hatches usually apply. Either one
argument is derivable — a `Deal` computes `totalAmount()` rather than validating
a passed-in total — or you actually have two construction paths, and
`Line.dotted(distance)` / `Line.solid()` separates them cleanly.

**Extract a value object when the answer to "would any string/int be acceptable
here?" is no**, or when the same validation appears in two places. Name it for
the concept, not its validity: `EmailAddress`, never `ValidEmailAddress` —
because if a `ValidEmailAddress` can exist, so can an invalid one, which is
exactly what you just forbade. What you're really doing is extending the type
system: wherever an `EmailAddress` appears, validation is already guaranteed and
the compiler enforces it for you. Values that always travel together
(`amount` + `currency`) become one type for the same reason.

**Use named constructors, with the regular constructor private** so nothing
bypasses them. They earn their keep three ways: building from primitives
(`Date.fromString()`), speaking the domain (a sales order is *placed*, so
`SalesOrder.place()`), and offering several construction paths that all funnel
through one guarded private constructor. Don't reflexively add `toString()` for
symmetry — wait for a real need.

**Only test constructors for how they should fail**, and never add a getter just
so a test can see inside. The happy path is covered implicitly by behavior tests.
Skip tests for checks a better type system could have caught; write them for
ranges, counts, relationships, and domain rules.

**DTOs invert all of this on purpose.** They live at the application's edge and
carry outside data inward: public properties, filled stepwise, primitives only,
property fillers welcome, and validation errors *collected* rather than thrown.
That's the deliberate exception, not a loophole for entities.

## Mutability

The default is immutable, and the exceptions are few:

- **Service** → immutable, always.
- **Entity** → mutable. Tracking change is its job.
- **DTO** → mutable, public properties, few rules.
- **Everything else** → immutable.

**Immutability is transitive.** A getter that hands out a mutable collection or
a mutable inner object undoes it entirely.

The modifier method's shape follows from mutability. A **mutable modifier is a
command method**: imperative name, `void` return, changes state. An **immutable
modifier has a declarative name and returns its own type**. Derive the name from
the sentence *"I want this …, but …"* → `toTheLeft(4)`,
`withDiscountApplied()`. Prefer the domain word over the technical one:
`toTheLeft()` beats `withXDecreasedBy()`.

**Build the copy through the constructor rather than cloning**, so the
validation gets reused for free. And **never give a mutable object a fluent
interface** — it reads like it returns a new thing when it doesn't. Immutable
objects get one for free without the ambiguity.

**Verify entity state changes through recorded domain events**, not by adding
getters. A private `events` list appended to by command methods and exposed via
`recordedEvents()` lets tests assert on what happened without opening up the
entity's internals — and the same mechanism later powers read models.

## Method Structure and Exceptions

Every method has the same skeleton:

```
preconditions → failure scenarios → happy path → postconditions → return
```

Failure checks go at the top. Return early, throw early, and eliminate `else`.
The template shrinks as the design improves: strong types delete preconditions,
and good tests delete postconditions.

**One question picks the exception type**: *could you know this is wrong by
looking only at the value provided?*

- **Yes** → the language's built-in "bad argument" error (`InvalidArgumentException`,
  `ValueError` / `TypeError`, `IllegalArgumentException`). This is a programming
  mistake. Fail hard, don't catch it, don't write a custom subclass for it. Name
  it by filling in "Invalid…".
- **No** → a runtime error. The world didn't cooperate; this is recoverable, and
  a custom class here is usually justified. Name it by finishing the sentence
  "Sorry, I …" → "CouldNot…".

The names above are the book's; use whatever your language calls the equivalent.
What carries across is the *split*, not the class names.

Drop the "Exception" suffix from the name. Write a custom class only if you'll
catch it specifically, there are several distinct ways to fail, or you want
named constructors — `CouldNotFindProduct.withId(productId)` puts message
assembly inside the exception where it belongs. Fewer exception classes means
tests distinguish cases by asserting on a message keyword, which is what Noback
recommends anyway; asserting only on the exception class lets a test pass while
covering the wrong branch.

Assertions are for programmers, validation errors are for users. Never collect
assertion failures into a list — fail immediately.

## Command/Query Separation

Every method is **either** a command or a query, never both:

- **Command** — has a side effect, returns `void`, imperative verb name.
- **Query** — returns information, has no side effects, single specific return
  type, noun-ish name.

The practical guarantee is that a query is safe to call any number of times,
including zero. `increment(): int` breaks it: the object changes even when the
caller only wanted to look. Immutability gives you CQS for free — an immutable
`incremented(): Counter` has no state change to separate out.

**Query chains may not contain commands; command chains may contain queries.**
A query method that calls a command hides a side effect behind something that
looks safe.

**No `get` prefix.** `itemCount()` reads as an aspect of the object;
`getItemCount()` reads as an instruction. And encode uncertainty in the name:
`get…` promises to return or throw, `find…` may come back empty-handed.

**Avoid returning `null`** — it shifts a burden onto every caller. In rough
order of preference: throw an exception (the client supplied the ID and expects
existence), return a null object (`EmptyPage`), return the type's natural empty
value (`[]`, `0`, `''`), or wrap the nullable method in a stricter one that
throws. Single return types always — no `string | false`.

**Avoid query methods that expose internal state.** Watch what clients actually
*do* with a getter's return value; that logic almost always belongs inside the
object. Either make the method smarter or move the call inside. The tell that it
worked is that you can **delete the getter**, not merely wrap it:

```
// Before — the calculation lives at every call site
let total = Money.zero()
for (const line of order.lines()) {
  total = total.add(new Money(line.quantity() * line.tariff()))
}

// After — each object answers the question it is actually being asked
const total = order.totalAmount()
// lines(), quantity() and tariff() can now all be deleted
```

**A query-then-command pair on the same object is a conversation that belongs
inside it.** `if (obstacle.isOnTheRight()) player.moveLeft()` should be
`player.evade(obstacle)`.

**Limit the scope of a command and dispatch events for secondary effects** — and
dispatch explicitly, so the effect stays discoverable.

Deviating from CQS is occasionally right. `nextIdentity()` must return an ID
*and* mark it used, or two clients get the same one; a repository legitimately
both saves and retrieves; and a controller must return a response even when it
performed a command. Noback's position is explicit — follow CQS almost always,
break it when following it would badly complicate the code.

## Abstraction

An abstraction is **two things, and it needs both**:

1. An **interface**, not a class.
2. A name with **no implementation details** in it.

`HttpClient` passes the first test and fails the second — it still leaks that
this is an HTTP call, so you can swap HTTP libraries but not swap to a local
rates table. `ExchangeRates`, `FileLoader`, `Queue`, `Clock` pass both. Apply
this whenever you cross a system boundary: network, filesystem, clock, database,
queue.

**Abstract early, generalize late.** Introducing the `FileLoader` interface at
the first implementation is right. Writing JSON, XML, *and* YAML loaders before
anyone asks is generalization before it's needed — wait for roughly three
similar cases, because generalizing early means rewriting the interface and
every implementation.

**Not every question deserves its own class.** Escalate deliberately: a better
variable name → extract a private method → a new class only when the code grows
too large, needs testing on its own, or crosses a system boundary.

## Reading a Signature

The fastest review tool in this skill — most design problems are visible in the
signature alone:

| Signature                        | Verdict                                              |
|----------------------------------|------------------------------------------------------|
| `setPassword(string): void`      | Mutable command method. Fine.                        |
| `withPassword(string): User`     | Immutable modified copy. Fine.                       |
| `withPassword(string): void`     | Mutable but **badly named** — declarative name, void  |
| `setPrice(Money): Product`       | **Confused** — imperative name, non-void return       |
| `increment(): int`               | **CQS violation** — changes state *and* returns       |
| `isValid(string): string\|bool`  | **Mixed return type** — pick one                      |
| `findOneBy(type): Page?`         | Nullable — prefer throw, null object, or empty value  |
| `getItemCount(): int`            | Drop the `get` prefix                                 |
| `__construct(Container, ...)`    | Injecting where you'd get it from, not what you need  |
| `__construct(Logger? = null)`    | Optional dependency — promote it and use a null object|

Two more quick checks:

- **Is this method too big?** Three yeses means split it: does the name have (or
  want) an "and" in it; do all lines contribute to the *main* job; could part of
  it run in a background process?
- **Is this service stateless?** *Could I reinstantiate it before every call and
  get the same behavior?* If no, don't add a flag — move the invariant into a
  value object.

## Changing Behavior

**Replace parts; don't change them.** When behavior must vary, modify the
structure of the object graph rather than the code inside a class. Climb this
ladder in order and stop at the first rung that works:

1. **Constructor argument for a configurable value** — promote the hardcoded
   `'/var/log/app.log'` to an argument.
2. **Constructor argument for a replaceable dependency** — extract an
   abstraction for the varying part and inject it.
3. **Composition** — combine several implementations of the interface.
4. **Decoration** — layer behavior (caching, logging, retries) on top of any
   implementation.
5. **Notification object or event listener** — let other services respond
   without the original knowing.

**Inheritance is not on the ladder.** Subclassing ties you to the parent's
internals: renaming a `protected` method or adding a parameter to it silently
breaks every subclass, including ones you don't own. Template method is better
than raw subclassing but strictly weaker than composition, and it converts in
one mechanical step — promote the `abstract protected` method to a `public`
method on an injected object and mark the class `final` again.

**Don't extend third-party classes even when the framework invites you to.**
Internals change between versions; published APIs don't.

**`final` and `private` by default** on every class, including entities and
value objects. The sole exception is a genuine type hierarchy where the subclass
is a *special case* of the parent. Once classes are `final`, `protected` has no
purpose left. For shared implementation in entities and value objects — which
can't use dependency injection — use traits, which are compiler-level copy/paste
and deliberately don't enter the type hierarchy.

**Read `references/changing-behavior.md`** when the task is "make this
configurable", "add logging/caching/retries to this service", or any time
subclassing is on the table — it works the ladder in full, with the
template-method conversion and the decoration trade-offs Noback himself flags.

## Choosing a Pattern

The rungs above are patterns — Strategy, Composite, Decorator, Observer — and
naming them helps only if you pick them the right way round. **Name the axis of
variation first; the pattern follows from it.** A pattern chosen before you can
say what varies is indirection with nothing to spend it on.

| What you want free to change                 | Pattern   |
|----------------------------------------------|-----------|
| An algorithm                                 | Strategy  |
| The states of an object, and its transitions | State     |
| Responsibilities, without subclassing        | Decorator |
| The interface to an object you can't change  | Adapter   |
| The interface to a subsystem                 | Facade    |
| Structure of a part-whole hierarchy          | Composite |
| How many objects depend on this one          | Observer  |
| When and how a request is carried out        | Command   |
| How an object is accessed                    | Proxy     |

Three tells worth carrying in your head:

- **A growing conditional on a type field** → Strategy. **On a status field,
  with rules about which status follows which** → State.
- **N × M subclasses for N features × M variants** → Bridge, Decorator, or
  Strategy.
- **Clients that know a subsystem's internal call order** → Facade.

And the distinctions that actually get confused: Decorator changes the **skin**,
Strategy the **guts**; State owns its **transitions** while Strategy is an
algorithm the **client** picks; Adapter **changes** an interface, Decorator
**extends** behavior behind it, Proxy **controls access** through it.

Two cautions. **Don't apply a pattern until you need the flexibility** — same
threshold as "abstract early, generalize late" above. And the pattern gives you
the shape, never the mechanics: the participants are still `final`, still take
required constructor arguments, still obey CQS. A `Strategy` with an optional
logger and a `setMode()` is a correctly shaped pattern built out of everything
this skill forbids.

**Read `references/design-patterns.md`** when selecting a pattern, or when GoF
advice appears to contradict a rule here — it holds the full selection tables,
the seven places this skill deliberately overrides GoF (Singleton, Template
Method, Prototype, Factory Method, Builder, Memento, mutable Observer
registration), and which patterns suit services versus other objects. For a
pattern's own Applicability and Consequences, use the `design-patterns-book`
skill.

## Read Models and Layers

**Never hand a modifiable entity to a client that shouldn't modify it.** Even if
the client doesn't modify it today, one day it might, and then finding out what
happened is hard. Split into a write model (command methods) and one read model
per use case, named for that use case. Query methods on the write model are
still fine — the rule targets clients that *only* read.

Two signals tell you the split is done: you can **delete the write model's
getters** without breaking a write-model client, and the reading client **stops
transforming** what it got back. If the controller still loops and reshapes, the
read model isn't matched to the use case yet.

Build read models directly from the data source — one query — as the default;
it's cheapest at runtime *and* in maintenance. Building from the write model is
a stopgap that doesn't actually meet the goal. Building from domain events is
the expensive option, justified only when the write model changes often, raw
data needs interpretation, or recomputation is genuinely too costly. Event
sourcing is a separate and much larger commitment; none of this requires it.

Dependencies point **inward only**:

```
Infrastructure  controllers, repository IMPLEMENTATIONS
Application     application services, command objects, read models,
                read model repository INTERFACES, event listeners
Domain          entities, value objects, write model repository INTERFACES
```

Interfaces go on repositories and anything else crossing a system boundary. They
do **not** go on controllers, application services, entities, value objects, or
read models — those are concrete by nature, and an interface adds ceremony with
no substitutability benefit.

**Read `references/layers-and-models.md`** when structuring a codebase, placing
a new class in a layer, or when a read-only client is being handed an entity —
it covers the recognition tests for each object type and the three read-model
build strategies in full.

## Anti-Patterns

Read `references/ANTI_PATTERNS.md` for the full catalogue, and consult it when
reviewing existing code or when a class feels wrong but you can't name why. The
ones worth carrying in your head:

- **Service locator or container as a constructor argument** — hides the real
  dependency count.
- **Optional dependencies and setter injection** — objects that exist
  half-configured.
- **JavaBean shape** (no-arg constructor plus a getter/setter per property) —
  incompatible with essentially every rule here. Only DTOs may look like this.
- **Anemic entities** whose callers do all the deciding via getters.
- **`new Date()` inside domain code** — a hidden dependency on the system clock.
- **Getters that exist so a test can see inside** — use recorded domain events.
- **Passing an entity to a template renderer or serializer** — it's a write
  model by accident, and the view can call anything on it.
- **Injecting a service into an entity or value object** — via constructor,
  setter, or a static accessor.
- **Singleton or any global access point** — a service locator with better
  manners; the dependency still never appears in the constructor signature.
- **A pattern applied before the axis of variation is known** — indirection
  with nothing varying.

## Review Checklist

- [ ] Is this a service or an other object, and is the right ruleset applied?
- [ ] Are all constructor arguments required, with no defaults or setter
      injection?
- [ ] Does the constructor only validate and assign?
- [ ] Is every dependency visible in the signature — no locators, statics, or
      system calls?
- [ ] Is task data (anything "current") on the method rather than the
      constructor?
- [ ] Can the object exist in an invalid or incomplete state? It shouldn't.
- [ ] Is there a primitive here that wouldn't accept just any string or int?
- [ ] Is everything immutable except entities and DTOs — and transitively so?
- [ ] Is each method clearly a command *or* a query, named accordingly?
- [ ] Could any getter be deleted by moving its caller's logic inside?
- [ ] Does anything return `null` that could throw or return an empty value?
- [ ] Is the exception type chosen by the "knowable from the argument alone"
      test?
- [ ] Do abstractions name the question rather than the mechanism?
- [ ] Is behavior varied by replacing parts rather than by subclassing?
- [ ] If a pattern is in use, can you name the axis of variation it buys?
- [ ] Is there a conditional on a type or status field that wants to be a
      Strategy or a State?
- [ ] Is every class `final` and every member `private` unless justified?
- [ ] Is any read-only client holding a write model?
