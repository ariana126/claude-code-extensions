# Glossary

**Active Record** — design pattern where the entity loads, saves, and deletes itself, usually by extending a framework base class (Ch 2)

**Adapter** — the implementation of a port; includes all collaborating objects (the ORM, the framework, the HTTP client), not just one class (Ch 13)

**Adapter test** — Noback's name for an integration test, since the code that integrates with external actors *is* a port adapter (Ch 14)

**Aggregate** — DDD term for an entity plus its child entities and value objects; this book says "entity" instead (Ch 11)

**Application layer** — holds application services, command DTOs, view model repository interfaces, view model DTOs, event subscribers, and interfaces for infrastructure services (Ch 12)

**Application service** — models a use case with side effects in a reusable way; takes primitives or a command object, returns `void` or a new entity's ID (Ch 4, 11)

**`ApplicationInterface`** — a single interface abstracting the whole hexagon, so incoming adapters can be tested without invoking core code (Ch 13)

**Assertion** — a guard function (`Assertion::email()`) an object uses to protect *itself*; not for validating user input (Ch 2, 8)

**Calendar** — a `today(): Date` abstraction; introduced in Ch 7 and then deliberately removed as a pass-through (Ch 7)

**Clock** — the conventional name for a time factory abstraction; gives the application one place where "now" is determined (Ch 7)

**Command bus** — a generic `handle(object $command)` dispatcher routing commands (and queries) to handlers; trades types for genericity (Ch 13)

**Command handler** — what an application service becomes once it accepts a command object (Ch 11)

**Command method** — changes state or performs an action; returns `void` (Ch 11)

**Command object** — a parameter object named after a user intention (`CreateOrder`); also a DTO carrying data from controller to application service (Ch 4, 8, 11)

**Command Query Separation** — satisfied for free once `save()` returns `void` (Ch 2)

**Composition root** — "a (preferably) unique location in an application where modules are composed together"; located at or near the entry point (Ch 5)

**Contract test** — one test run against every implementation of a port, proving Liskov substitutability (Ch 13, 14)

**Core code** — code executable in any context, with no special setup and no external systems available (Ch 1)

**CRUD-only** — an application generatable from a config file describing models, fields, types, and validation rules; the one case that genuinely doesn't need decoupling (Ch 15)

**Data Mapper** — the entity is passive; a repository extracts its data and stores it (Ch 2)

**Dependency injection** — services receive dependencies and configuration values as constructor arguments (Ch 5, 9)

**Dependency inversion** — services depend on abstractions rather than concrete classes; the dependency arrow flips (Ch 9)

**Dependency rule** — "source code dependencies [between layers] should only point inwards" (Ch 12)

**Design tension** — the strain that appears when one object serves two clients with different needs (Ch 3)

**Domain event** — an immutable object named after what happened (`OrderWasCreated`), recorded internally by an entity and released after saving (Ch 3, 4, 11)

**Domain invariant** — the things that are always true about an entity (Ch 11)

**Domain layer** — holds entities, value objects, domain events, entity repository interfaces, and domain services (Ch 12)

**Driver** — another name for an outgoing adapter (Ch 13)

**Driving test** — an adapter test for an incoming port: mock `ApplicationInterface`, exercise the real framework (Ch 14)

**End-to-end test** — treats the deployed application as a black box; only public channels, no database peeking (Ch 14)

**Entity** — a stateful object that guarantees its own consistency, has identity, and gets persisted; the only object type with persistent state (Ch 2, 11)

**Entry point** — "the user code that the framework calls first," typically the routed controller (Ch 5)

**Eventual consistency** — the system is consistent only after all event subscribers finish (Ch 11)

**Façade** — "defines a higher-level interface that makes the subsystem easier to use"; often shipped as a vendor SDK (Ch 6)

**Hexagon** — the application's use cases; all core code. The **outer hexagon** is the Infrastructure layer (Ch 13)

**Identity map** — tracks loaded entities so `save()` knows whether to `INSERT` or `UPDATE` (Ch 11)

**Impure / not referentially transparent** — a function that can give different answers on repeated calls; unusable for validation (Ch 8, 9)

**Incomplete / invalid / inconsistent** — the three states an object must prevent: missing required data, right type but wrong value, and data that can't co-exist (Ch 8)

**Infrastructure code** — code needing external systems, special setup, or designed for one specific runtime context (Ch 1)

**Integration test** — uses IO to verify real cooperation with an external system (Ch 6, 7)

**Isolated test** — the clearer name for a true unit test (Ch 14)

**"Jumpy" code** — service → abstraction → class → abstraction → class; the smell of too many elements (Ch 7)

**Just-right-engineering** — extra elements justified by a separation you've decided is worth making (Ch 15)

**Leaky abstraction** — an interface carrying vendor-specific details (a `$filter` parameter only one API understands) (Ch 6)

**Legacy code** — Michael Feathers: "simply code without tests" (Ch 9)

**Level of abstraction** — whether an interface speaks your domain's language or the vendor's (Ch 6)

**Living documentation** — scenarios that document, specify, *and* verify (Ch 14)

**Named constructor** — `OrderId::fromString()`, `Date::fromCurrentTime()`, `RateType::tbe()` (Ch 2, 6, 7)

**`nextIdentity()`** — repository method producing the next identifier, so entities have identity from birth (Ch 2, 7)

**Object-pure** — deterministic; behavior determined by own logic plus constructor and method arguments, and nothing more (Ch 5, 9)

**Port** — "an intention of communication," expressed as an interface. **Incoming** serves primary actors; **outgoing** serves supporting actors (Ch 13)

**Primary actor** — takes the initiative for communication (a user, an API client) (Ch 9, 13)

**Primitive obsession** — bare strings where clients must guess valid values (Ch 6)

**Process Modelling** — Brandolini's technique for designing commands, events, read models, effects, and policies before coding (Ch 11)

**Protection** — "we don't assign a value to a property, then validate it; we protect the object from ending up in an incorrect state" (Ch 8)

**Read model** — an immutable object specialized in providing information; **internal** read models serve the application, **view models** serve users (Ch 3, 11)

**Repository** — abstraction for saving and reconstituting entities; an interface plus at least one implementation (Ch 2, 11)

**Resistant to change** — an object with so many roles and clients that nobody can safely modify it (Ch 3)

**Secondary / supporting actor** — a system your application acts upon (the database, a mail server) (Ch 9, 13)

**Service locator** — any global mechanism for fetching a service on demand: `$container->get()`, `resolve()`, `Zend_Registry::get()` (Ch 5)

**Spiking** — fiddling with code and design until you know what to do; acceptable temporarily, not acceptable to ship (Ch 6)

**Spy** — a test double recording what happened to it, so you can assert on it later (Ch 14)

**Table Data Gateway** — one interface per database table hiding SQL; an intermediate step that only solves half the problem (Ch 2)

**Temporal dependency** — the requirement that a framework has been booted and configured *before* this code can run (Ch 5)

**Universally invokable** — a use case reachable from any delivery mechanism (Ch 9)

**Use case test** — exercises the hexagon, documenting primary actions and their effects; needs an application interface, a service container, and an event dispatcher (Ch 14)

**User code** — "what makes your application special"; the domain-specific business logic no framework can write for you (Ch 9)

**Value object** — immutable, no identity, defined by its value; validates in its constructor so it never needs validating again (Ch 2, 3, 8)

**View model** — a read model whose data crosses the application boundary; returns render-ready **primitives**, never value objects (Ch 3, 11)
