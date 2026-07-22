# Object Design Anti-Patterns — Full Reference

This file expands on the anti-patterns summarized in SKILL.md. Read it when
reviewing existing code, or when a class feels wrong but you can't pinpoint why.

Each entry follows the same shape: what you'd see, why it hurts, and what to do
instead.

## 1. Service Locator or Container as a Constructor Argument

**Symptom**: a constructor takes a `Container`, `ServiceLocator`,
`EntityManager`, `Registry`, or `ModuleRef`, and the class calls `.get(...)` on
it to reach what it actually needs.

**Why it's bad**: one argument hides three dependencies. The constructor
signature stops being an honest inventory, and — more damaging — all design
pressure disappears. A class with eight real dependencies looks exactly like a
class with one, so nobody ever notices it should be split.

**Fix**: inject what you use, not where you'd get it from. Ask *does this class
use the argument directly, or retrieve the real dependency from it?* Iterate
until the answer is "uses directly": `ServiceLocator` → `EntityManager` →
`UserRepository`.

## 2. Optional Dependencies and Default Values

**Symptom**: `constructor(logger: Logger | null = null)`, followed by
`if (this.logger)` guards scattered through the class.

**Why it's bad**: you can no longer tell how an object is configured by reading
the call site, and the default silently becomes an implementation detail that
can change under you. The guards multiply, and one will eventually be forgotten.

**Fix**: promote the argument to required, then make it easy to satisfy — a null
object (`NullLogger`) for a collaborator, a `createDefault()` factory for a
configuration value.

## 3. Setter Injection

**Symptom**: `setLogger()`, `setRepository()` called after construction.

**Why it's bad**: the object exists in an incomplete state between `new` and the
last setter, and any code running in that window sees a broken object. It also
makes the service mutable, which forfeits the safety of a shared, reused service
graph.

**Fix**: constructor injection, always.

## 4. Behavior-Changing Setters

**Symptom**: `ignoreErrors()`, `addListener()`, `setStrictMode(true)` on a
service.

**Why it's bad**: the service takes different execution paths depending on who
called what first. Two clients sharing the instance now interfere with each
other, and the bug only shows up under a particular ordering.

**Fix**: make the variation a constructor argument, or a separate
implementation. Once constructed, a service should be impossible to reconfigure.

## 5. Doing Work in a Constructor

**Symptom**: a constructor that creates directories, opens connections, touches
files, or calls a method on a dependency.

**Why it's bad**: merely instantiating the object leaves side effects behind,
even if it's never used. Testing requires the world to be in a particular state
before you can even build the thing.

**Fix**: a constructor validates and assigns, nothing else. Push setup *outward*
into a factory or the application bootstrap, not inward into a lazy private
method. Detection test: if reordering the property assignments changes behavior,
you're doing work in there.

## 6. Hidden Dependencies

**Symptom**: `Cache.get(...)`, `new Date()`, `time()`, `readFile(...)`,
`Math.random()` inside a class whose constructor mentions none of it.

**Why it's bad**: the dependency exists whether or not it's declared — it's just
invisible. Tests become time-dependent or filesystem-dependent and eventually
fail on their own, and nobody can tell what a class touches by reading its
signature.

**Fix**: static accessors become injected objects. System calls become an
injected gateway or `Clock` — or better, a method argument, since "the current
time" is contextual task data rather than a collaborator. Complex standard
library calls become injected wrappers *only* when you'd want to replace the
behavior later, it's too complex to inline, or it deals in objects rather than
primitives; `strpos` and `array_keys` stay put.

## 7. Task Data in the Constructor

**Symptom**: a service constructed with a `Request`, a `Session`, the current
user, or the entity it's about to operate on.

**Why it's bad**: the service is now welded to one job in one context. It can't
be reused, can't be batched, and has to be rebuilt for every unit of work.

**Fix**: apply the batch test — *could I run this in a batch without
reinstantiating it?* If no, the argument is task data and belongs on the method.
The word "current" is the tell.

## 8. Setters for Essential Data

**Symptom**: `new Money(); money.setAmount(10); money.setCurrency('EUR')`.

**Why it's bad**: the object exists in an inconsistent state in between, and
anything that reads it there gets a meaningless answer rather than an error. A
`Position` with no `y` yet will happily compute a distance.

**Fix**: all essential data goes through the constructor, and the object is
complete the moment it exists.

## 9. The JavaBean Shape

**Symptom**: a zero-argument constructor plus a getter and setter for every
property.

**Why it's bad**: Noback states plainly that *every* rule in the book is
incompatible with it — invalid starting states, invalid intermediate states, and
internals so exposed that you can't change them without breaking clients.

**Fix**: named constructors, required data, private properties, command methods.
DTOs are the only objects that may legitimately look like this, and only because
they carry outside data inward at the application edge.

## 10. Anemic Entities

**Symptom**: an entity is a bag of getters and setters, and the deciding happens
in a service or controller that reads its fields and writes them back.

**Why it's bad**: the invariants have nowhere to live. Every caller must
remember the rules, so they get re-implemented slightly differently in each
place, and one of them will be wrong.

**Fix**: move the decision inside. `if (obstacle.isOnTheRight()) player.moveLeft()`
becomes `player.evade(obstacle)`. A query-then-command pair on the same object is
a conversation that belongs within it.

## 11. Getters Whose Callers Do the Real Work

**Symptom**: clients call a getter and then compute something from what comes
back — the same computation, at several call sites.

**Why it's bad**: the logic is duplicated, changes in several places, and gets
tested in none of them properly. The object's internals are effectively public.

**Fix**: make the method smarter, or move the call inside the object. The tell
that it worked is that you can **delete** the getter, not merely wrap it — the
internal collection becomes genuinely private.

## 12. Getters That Exist Only for Tests

**Symptom**: a property is exposed so a unit test can assert on it.

**Why it's bad**: it leaks internal state for no client's benefit, and it's the
first step down the anemic-model slide — once it's public, production code will
eventually use it too.

**Fix**: for entities, record domain events and assert on those. For everything
else, assert on observable behavior. If you can't observe it and no client
needs it, consider whether the property should exist at all.

## 13. CQS Violations

**Symptom**: `increment(): int` — a method that changes state *and* returns
information. Or a query method that calls a command.

**Why it's bad**: the object changes even when the caller only wanted to look, so
a query is no longer safe to call any number of times. A query calling a command
hides a side effect behind something that looks safe.

**Fix**: split into a command and a query, or make the object immutable — an
immutable `incremented(): Counter` has no state change left to separate.

**Legitimate exceptions** exist and are worth naming so nobody wastes time on
them: `nextIdentity()` must return an ID and mark it used or two clients get the
same one; a repository both saves and retrieves; a controller must return a
response even for a command.

## 14. Nullable and Mixed Return Types

**Symptom**: `@return string|bool`, or a method that returns `null` when it can't
find something.

**Why it's bad**: every caller inherits the burden of checking, and one of them
won't. Mixed return types make it impossible to use the result without first
asking what it is.

**Fix**: single return types. Instead of `null`: throw when the client supplied
an identifier and expects existence; return a null object (`EmptyPage`); return
the natural empty value (`[]`, `0`, `''`); or wrap the nullable method in a
stricter one that throws. And name honestly — `get…` promises to return or
throw, `find…` may come back empty.

## 15. `get` Prefixes

**Symptom**: `getItemCount()`, `getDiscountPercentage()`.

**Why it's bad**: minor but real — `getItemCount()` reads as an instruction,
`itemCount()` reads as an aspect of the object. Since query names are nouns and
command names are verbs, the prefix muddles the one signal that tells a reader
which kind of method they're looking at.

**Fix**: drop the prefix on queries.

## 16. Stringly-Typed Parameters

**Symptom**: `sendInvoice(email: string, amount: number, currency: string)`, with
validation repeated wherever those values arrive.

**Why it's bad**: the same validation lives in several places, and nothing stops
a caller passing an unvalidated value. Parameters that always travel together
(`amount` + `currency`) also make return types ambiguous — `convert(): number`
returns a number in *which* currency?

**Fix**: extract value objects when the answer to "would any string/int be
acceptable here?" is no. Name them for the concept, not their validity —
`EmailAddress`, never `ValidEmailAddress`. Composite values become one type:
`Money`.

## 17. Mutable State Leaking Through an Immutable Object

**Symptom**: an "immutable" object returns its internal array, collection, or a
mutable inner object from a getter.

**Why it's bad**: immutability is **transitive**. One mutable escape hatch
undoes the entire guarantee, and it does so invisibly — the class still looks
immutable from the outside.

**Fix**: return copies, return immutable views, or better, don't return the
collection at all — answer the question the caller was going to compute from it.

## 18. Fluent Interface on a Mutable Object

**Symptom**: `order.addLine(x).addLine(y)` where `addLine` mutates and returns
`this`.

**Why it's bad**: it reads exactly like the immutable modified-copy idiom, so
callers reasonably assume the original is untouched. It isn't.

**Fix**: mutable modifiers are command methods — imperative name, `void` return.
Immutable objects get a fluent interface for free, with no ambiguity.

## 19. Inheritance to Change Behavior

**Symptom**: `class XmlParameterLoader extends ParameterLoader` overriding a
`protected` method. Or `protected` properties on a class for the benefit of
subclasses.

**Why it's bad**: the subclass depends on the parent's internals. Renaming a
`protected` method or adding a parameter to it silently breaks every subclass,
including ones you don't own and will never see fail.

**Fix**: climb the ladder instead — configurable value, replaceable dependency,
composition, decoration, notification. Template method is an improvement over
raw subclassing but strictly weaker than composition, and converts in one step:
promote the `abstract protected` method to a `public` method on an injected
object, then mark the class `final` again.

## 20. Extending Third-Party Base Classes

**Symptom**: `class UserRepository extends AbstractDoctrineRepository`,
`class MyController extends FrameworkController`.

**Why it's bad**: framework internals change between versions far more often
than published APIs do. You've coupled yourself to the part with no
compatibility promise, and the invitation to extend doesn't come with one.

**Fix**: use only `public` methods that are part of the published interface, and
compose rather than extend. If the framework makes that genuinely impossible,
keep the subclass as thin as you can and treat it as infrastructure.

## 21. Injecting a Service into an Entity or Value Object

**Symptom**: a repository, HTTP client, or provider passed to a value object's
constructor — or reached via a static or global accessor from inside one.

**Why it's bad**: the object stops being a value. It can no longer be
constructed freely, compared cheaply, or reasoned about locally, and it drags
infrastructure into the domain layer.

**Fix**: pass the *result* of the service as a method argument
(`money.convert(exchangeRate)`), or accept that the behavior wanted to be a
service all along (`ExchangeService.convert(money, target)`). Needing to pass a
service into a value object is usually the signal for the latter.

## 22. Custom Exception Classes for Invalid Arguments

**Symptom**: `class InvalidLatitudeException extends InvalidArgumentException`,
thrown from a constructor and caught nowhere.

**Why it's bad**: an invalid argument is a programming mistake. You don't
recover from it, you fix it — so a dedicated type buys you nothing but a file.

**Fix**: use the generic `InvalidArgumentException` and distinguish cases in
tests by asserting on a keyword from the message. Write a custom class only when
you'll catch it specifically, there are several distinct ways to fail, or you
want named constructors like `CouldNotFindProduct.withId(id)`. Custom
`RuntimeException` subclasses are a different matter and often justified — those
represent the world not cooperating, which callers really do handle.

## 23. Asserting Only on the Exception Class

**Symptom**: a failure test that checks the exception type and nothing else.

**Why it's bad**: the test can pass while covering an entirely different branch
than the one you meant to exercise — a false sense of coverage in exactly the
place you were being careful.

**Fix**: assert on a keyword from the message too.

## 24. Handing a Write Model to a Read-Only Client

**Symptom**: an entity passed to a template renderer or serializer; a controller
that calls `findAll()` and reduces the result in a loop.

**Why it's bad**: the view can call anything on it, so it's a write model by
accident. The loop is also a performance problem — it iterates every entity ever
created to answer one question.

**Fix**: extract a read model shaped for the use case, with its own repository,
built directly from the data source. You'll know it's right when the write
model's getters can be deleted and the client stops transforming what it
receives.

## 25. Read Models the Client Still Has to Transform

**Symptom**: the controller retrieves a read model and then loops, maps, or
reshapes it before rendering.

**Why it's bad**: the read model was shaped for the entity, not for the use
case, so the transformation logic just moved rather than disappeared.

**Fix**: reshape the read model until the client uses it as-is. All the data
needed — and no more — should be present the moment it's retrieved, with no
follow-up queries.

## 26. Reaching for Event-Sourced Read Models by Default

**Symptom**: domain events and projection listeners introduced for a report that
one SQL query would answer.

**Why it's bad**: more moving parts, harder domain-event evolution, and failed
listeners that need operational tooling and re-running — all paid up front for a
runtime saving nobody measured.

**Fix**: build read models directly from the data source by default; it's
cheapest at runtime *and* in maintenance. Escalate only when the write model
changes often, the raw data needs interpretation, or recomputation is genuinely
too expensive.

## 27. Interfaces on Things That Don't Cross a Boundary

**Symptom**: `interface UserController`, `interface ScheduleMeetupServiceInterface`,
an interface per entity.

**Why it's bad**: ceremony with no substitutability benefit. There will never be
a second implementation — if the use case changes, the service changes; if you
switch frameworks, you rewrite the controller rather than adding an
implementation.

**Fix**: interfaces go on repositories and anything else crossing a system
boundary. Not on controllers, application services, entities, value objects, or
read models.

## 28. Abstracting Only the Transport

**Symptom**: `interface HttpClient` used as the seam for fetching exchange rates.

**Why it's bad**: it passes the first half of the abstraction test (it's an
interface) and fails the second (the name leaks the mechanism). You can swap HTTP
libraries easily; you can't swap to a local rates table, which is the swap you
actually wanted.

**Fix**: name the *question*, not the transport. `ExchangeRates` with an
`exchangeRateFor(from, to)` method. Every question deserves a method, and every
answer deserves a type.

## 29. Generalization Before It's Needed

**Symptom**: JSON, XML *and* YAML loaders written before anyone asked for the
second one.

**Why it's bad**: you're maintaining implementations nobody uses, against an
interface shaped by guesses about requirements that haven't arrived.

**Fix**: **abstract early, generalize late.** Introduce the interface at the
first implementation — that part is cheap and buys testability immediately. Wait
for roughly three similar cases before generalizing the interface itself.

## 30. Creating a Class Too Eagerly

**Symptom**: a one-line private helper promoted to its own class with an
interface and a test file.

**Why it's bad**: the indirection costs more than the clarity it buys, and the
class has no independent reason to exist.

**Fix**: escalate deliberately — a better variable name, then an extracted
private method, and a new class *only* when the code grows too large, needs
testing on its own, or crosses a system boundary.

## 31. Singleton and Other Global Access Points

**Symptom**: `Config.getInstance()`, `Logger.instance()`, a module-level mutable
object imported everywhere, or any static accessor reached from inside a class.

**Why it's bad**: it's anti-pattern §1 with better manners. The dependency never
appears in the constructor signature, so a class with four hidden collaborators
reads as a class with none and no design pressure ever builds up (§6). It also
welds every client to a lifetime decision that isn't the class's business, and
tests end up sharing mutable state across cases.

**Fix**: "there must be exactly one" is a *wiring* fact, not a property of the
class. Instantiate it once at the composition root and inject it like any other
dependency. The class itself stays ordinary and instantiable, which is what
makes it testable.

## 32. Pattern-First Design

**Symptom**: an Abstract Factory producing one product, a Strategy interface
with a single implementation, a Builder for an object with three fields — chosen
because the pattern was known, not because something varied.

**Why it's bad**: every pattern buys variation with indirection, paid for in
complexity and often performance. With no axis of variation, you've paid the
price and bought nothing. Worse, the interface is shaped by a guess, so the
second implementation — if it ever arrives — usually doesn't fit it.

**Fix**: name the axis of variation before naming the pattern; if you can't
finish the sentence "I want *this* to be free to change", there's no pattern to
apply yet. Then escalate as in §29 and §30 — abstract early, generalize late,
and let a real second case shape the interface. See
`design-patterns.md` for selecting by what varies.
