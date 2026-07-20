# Glossary — Object Design Style Guide

**Abstraction** — An interface *plus* a name free of implementation details. Both halves are required; `HttpClient` is only half an abstraction, `ExchangeRates` is a whole one. (Ch 6, Ch 7, Ch 9)

**Application service** — Performs one task, contains no infrastructure code, corresponds to one use case. Receives primitives, converts to value objects. Also called a command handler. (Ch 10)

**Assertion** — A precondition check at the top of a method; often from a library (`Assertion.greaterThan`, `Assertion.allIsInstanceOf`). For programmers, not users — never collect them into a list. (Ch 3, Ch 5)

**Black box test** — Tests behavior from outside with no knowledge of internals. See *object testing*. (Ch 11)

**Command method** — Imperative name, `void` return, produces a side effect. (Ch 4, Ch 6, Ch 7)

**Command object** — A DTO carrying a client's request as one thing from controller to application service. (Ch 3, Ch 10)

**Command/Query Separation (CQS)** — Every method is either a command or a query, never both. (Ch 6)

**Composition (object composition)** — Assigning objects to another object's properties to build something more capable. (Ch 1, Ch 9)

**Concretion** — A concrete implementation of an abstraction. (Ch 9, Ch 10)

**Controller** — Called by a front controller; contains delivery-mechanism code; calls an application service or read model repository. Infrastructure layer. (Ch 10)

**Decoration** — Composition where the wrapper implements the same interface as the thing it wraps, adding behavior around it. (Ch 9)

**Dependency** — An object another object needs to do part of its job. (Ch 1, Ch 2)

**Dependency injection** — Receiving dependencies as constructor arguments. The only acceptable way to obtain one. (Ch 1, Ch 2)

**Dependency Inversion Principle** — Depend on abstractions, not concretions; §6.5 and §9.2 are DIP in practice. (Ch 6, Ch 9)

**Domain event** — A small immutable object recording that something happened inside an entity (`PlayerMoved`, `PurchaseOrderReceived`). Structurally like a value object; distinguished by usage. (Ch 4, Ch 8, Ch 10)

**Domain invariant** — Something always true about a concept, from domain knowledge. Constructors and modifier methods exist to protect them. (Ch 3, Ch 4)

**DTO (data transfer object)** — Lives at the application's edge. Public properties, primitive values, filled stepwise, collects validation errors instead of throwing, property fillers allowed. The exception to most rules. (Ch 3, Ch 4, Ch 10)

**Dummy** — A test double that does nothing meaningful; exists to fill a parameter. (Ch 1, Ch 6, Ch 7)

**Entity** — Identifiable, mutable, has a life cycle, persisted by a write model repository, uses named constructors and command methods, records domain events. Few or no query methods. (Ch 4, Ch 10)

**Event listener** — An immutable service with at least one method taking a single domain event. Named for what it does; methods named for why (`NotifyGroupMembers.whenMeetupRescheduled`). (Ch 7, Ch 9, Ch 10)

**Event sourcing** — Reconstructing the *write* model from events. Explicitly **not** required to separate read from write models. (Ch 8)

**Fake** — A test double with working, configurable, in-memory behavior. (Ch 6)

**Failure scenario** — A condition the method itself recognizes as failure after arguments passed inspection. Throws `RuntimeException`. (Ch 5)

**Final** — Marks a class as non-extensible. Should be the default for every class, including entities and value objects. (Ch 1, Ch 9)

**Fluent interface** — Modifier methods returning `this`, enabling chaining. Forbidden on mutable objects; free on immutable ones. (Ch 4)

**Front controller** — The single entry point: `index.php`, `DispatcherServlet`, `bin/console`. (Ch 10)

**Generalization** — Making an abstraction more generic. Do it *after* roughly three similar cases, never before. (Ch 7, Ch 9)

**Getter** — The simplest query method. Named without a `get` prefix: `itemCount()`, not `getItemCount()`. (Ch 6)

**Happy path** — The part of a method where nothing is wrong. (Ch 5)

**Hexagonal architecture (ports and adapters)** — Structuring around how the application communicates with the outside world. (Ch 10, Ch 11)

**Hidden dependency** — A dependency invisible in the constructor signature: static accessors, standard-library functions, system calls. (Ch 2)

**Immutable** — No property can change after instantiation, **and** every object held in those properties is itself immutable. (Ch 1, Ch 4)

**Integration test** — Tests an object against the outside thing it relies on. Not a unit test. (Ch 6)

**InvalidArgumentException** — For a client's programming mistake, knowable by inspecting the argument. Don't create custom subclasses. (Ch 3, Ch 5)

**Layers** — Infrastructure (controllers, repository implementations) → Application (application services, command objects, read models, read model repository interfaces, event listeners) → Domain (entities, value objects, write model repository interfaces). Dependencies point inward only. (Ch 10)

**LogicException** — Parent of `InvalidArgumentException`; used for illegal state transitions. Named "Invalid…". (Ch 4, Ch 5)

**Mock** — A test double declaring expectations up front and self-verifying. **Commands only.** (Ch 1, Ch 7)

**Modifier method** — Changes an object or produces a changed copy. On mutable objects: command method. On immutable objects: declarative name, returns own type. (Ch 4)

**Named constructor** — A `public static` factory method returning an instance, with a `private` regular constructor guarding all paths. Also used for exceptions. (Ch 3, Ch 5)

**Notification object** — A domain-named interface replacing a generic event dispatcher when the listeners are few and similar. (Ch 9)

**Null object** — A harmless implementation doing nothing (`NullLogger`) or representing the empty case (`EmptyPage`). (Ch 2, Ch 6)

**Object testing** — Testing behavior from outside, with test doubles **only** for system-boundary crossings. Preferred over class testing. (Ch 11)

**Polymorphism** — A parameter typed `Foo` accepts any `Foo`; behavior varies without changing calling code. Prefer interface types. (Ch 1)

**Postcondition check** — A "this should never happen" check on a result before returning. Rarely needed if you have tests and strong types. (Ch 5)

**Precondition check** — An assertion verifying arguments are usable. (Ch 5)

**Property filler** — A method like `fromArray()` copying raw data into properties. Banned for entities/value objects; allowed for DTOs. (Ch 3)

**Query method** — Returns information, no side effects, non-`void` return type, single return type. (Ch 6)

**Query object** — An object with only query methods. A read model is one. (Ch 10)

**Read model** — Query methods only, designed for one specific use case, all needed data available on retrieval with no extra queries. (Ch 8, Ch 10)

**Read model repository** — Returns read models for a specific use case; interface hides the storage mechanism. (Ch 8, Ch 10)

**Reinstantiation test** — *"Could I reinstantiate this service before every method call and get the same behavior?"* If no, the service accumulates state. (Ch 7)

**Replace primitive with object** — Fowler/Beck refactoring; moves an assertion from every method taking the primitive into one new type's constructor. (Ch 3, Ch 5)

**Repository (write model)** — Offers retrieval and saving; interface hides the underlying technology. Domain layer interface, infrastructure layer implementation. (Ch 2, Ch 10)

**Return early** — As soon as you know what you'll return or that you must throw, do it. Eliminate `else`. (Ch 5)

**RuntimeException** — For an external condition breaking the method; not knowable from the argument. Named by finishing "Sorry, I …" → "CouldNot…". (Ch 5)

**Scoping** — `private` / `protected` / `public`. Class-based, not instance-based: any `Foo` can read another `Foo`'s private property. Default to `private`. (Ch 1, Ch 9)

**Service** — Performs a task or returns information; created once with everything it needs, immutable thereafter, reused many times. Named for what it does. (Ch 2)

**Service locator** — A service you retrieve other services from. Legitimate at the framework entry point; never a constructor argument. (Ch 1, Ch 2)

**Spy** — A test double recording the calls made to it, so you write a normal assertion afterward. **Commands only.** (Ch 7)

**State transition** — A change that unlocks or forecloses future operations (delivered → can't cancel). Modifier methods must verify these. (Ch 4)

**Static factory method** — A `public static` method returning a new instance. The seed of named constructors. (Ch 1)

**Stub** — A test double returning hardcoded values. **Queries only.** (Ch 1, Ch 6)

**Template method pattern** — A `final` public method calling an `abstract protected` hook. Better than raw subclassing, but strictly weaker than composition — convert by promoting the hook to a public method on an injected object. (Ch 9)

**Test double** — Any stand-in for a real dependency: dummy, stub, fake, mock, spy. (Ch 1)

**Trait** — Compiler-level code reuse. **Not inheritance** — the name never enters the type hierarchy. Use for entities/value objects, which can't use DI. (Ch 9)

**Value object** — Immutable, wraps primitive data, adds domain meaning, validates, and attracts useful behavior. Replaceable and anonymous — no identity. (Ch 3, Ch 4, Ch 10)

**Write model** — An entity exposing command methods; the object through which state changes go. (Ch 8)
