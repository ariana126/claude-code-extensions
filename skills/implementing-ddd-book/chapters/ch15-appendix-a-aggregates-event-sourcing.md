# Appendix A: Aggregates and Event Sourcing (A+ES)

*Contributed by Rinat Abdullin. Code is C#, matching the source.*

## Core Idea
A+ES represents the entire state of an Aggregate as an append-only Event Stream: behaviors emit Events, Events mutate in-memory state, and state is reconstituted by replaying the Stream in order of occurrence. This never loses the *reason* for a change, but it forces CQRS on you because Event Streams are hard to query.

## Frameworks Introduced

- **A+ES execution sequence (Application Service driving an event-sourced Aggregate)**: the canonical eight steps.
  - When to use: any command entering a Bounded Context whose Aggregates are event sourced.
  - How: (1) client invokes an Application Service method; (2) obtain Domain Services needed for the operation; (3) load the Event Stream by the client-supplied Aggregate identity; (4) reconstitute the Aggregate by applying all Events from the Stream; (5) execute the Aggregate's business operation with contract-required parameters; (6) the Aggregate may double-dispatch to Domain Services or other Aggregates and generates new Events; (7) append newly generated Events using the Stream *version* to guard against concurrency conflicts; (8) publish the newly appended Events to subscribers via messaging infrastructure.
  - Why it works / failure mode: version-checked append gives optimistic concurrency for free. Failure mode: replaying huge Streams — fix with caching, snapshots, or identity partitioning.

- **Apply / Mutate / When split**: `Apply(e)` adds the Event to `Changes` *and* calls `Mutate(e)`; `Mutate(e)` dispatches to the overloaded `When(SpecificEvent)` that owns the state transition.
  - When to use: every event-sourced Aggregate.
  - How: (1) reconstitution constructor loops the Stream calling `Mutate` only — never `Apply`, or already-persisted Events would be re-appended; (2) business methods call `Apply` for new Events; (3) `When` overloads contain *only* state assignment; (4) because `Apply` mutates immediately, each subsequent step of a multi-step behavior sees up-to-date state; (5) optionally split into two classes — one for state, one for behavior — collaborating exclusively through `Apply`, guaranteeing state is mutated only by Events.

- **Command Handlers as temporally decoupled Application Services**: serialize the method name plus parameters into a Command class and dispatch it over a message queue to a handler.
  - When to use: you need load balancing, competing consumers, system partitioning, or availability during service downtime.
  - How: (1) define `XxxCommand` with properties matching the service method parameters (Command contracts follow the same semantics as Events and can be shared across systems); (2) rename the service method to `When(XxxCommand)`; (3) declare `IApplicationService { void Execute(ICommand cmd); }` implemented as a dynamic dispatch to `When` — mirroring `Mutate`; (4) wrap handlers in decorators for logging, auditing, authorization, validation; (5) centralize failure handling, e.g. retry on concurrency contention with Capped Exponential Back-off.

- **Retry-on-concurrency via lambda-captured behavior**: pass the business operation as `Action<TAggregate>` so it can be re-executed against a freshly reloaded Aggregate.
  - When to use: default concurrency strategy when re-executing the behavior is cheap.
  - How: (1) `Update(id, execute)` loads the Stream, reconstitutes, invokes `execute(aggregate)`, appends; (2) on `EventStoreConcurrencyException`, fall through a `while(true)` loop and reload; (3) the delegate re-runs against the newer state, producing Events that append after the competing ones; (4) add an optional brief delay.

- **Event conflict resolution**: reduce real concurrency failures by testing whether your pending Events actually conflict with the ones that won.
  - When to use: re-executing the behavior is too expensive or infeasible (payment gateway charge, order placement, third-party integration).
  - How: (1) catch the concurrency exception carrying the actual server Events and version; (2) for each pending Event × each succeeded Event call `ConflictsWith()`; (3) if any conflict, throw `RealConcurrencyException`; (4) otherwise append at the server's actual version. Majority-case rule: **Events of the same type always conflict; Events of different types do not.** Define the resolver per Aggregate Root.

- **Snapshots**: serialized copies of an Aggregate's full state stored at a known Stream version.
  - When to use: individual Streams reach hundreds of thousands of Events.
  - How: (1) `ISnapshotRepository.TryGetSnapshotById(id, out agg, out version)`; (2) on hit, load only Events after that version and call `ReplayEvents()` (which calls `Mutate` only — using `Apply` would re-add already-persisted Events to `Changes` and cause serious bugs); (3) on miss, reconstitute from the whole Stream; (4) generate snapshots on a background thread after N new Events; (5) tune the threshold per Aggregate type.

- **Read Model Projections**: Domain Event subscribers that project Events into a persistent Read Model.
  - When to use: any query A+ES can't answer, e.g. "total of all customer orders within the last month".
  - How: (1) write a Projection class with `When(SomeEvent)` handlers — like an A+ES Application Service, but reacting to Events instead of Commands; (2) update a serializable DTO via `IDocumentWriter`; (3) persist to a document database, memcached, CDN, or relational tables; (4) treat Projections as completely disposable — to replace a Read Model, discard the data and replay the entire Event Stream through the Projection classes, automatable with zero downtime.

- **Events enrichment**: add data members that aren't needed for reconstitution but drastically simplify subscribers.
  - When to use: a Projection would otherwise have to correlate several Event types and maintain lookup state to render one view.
  - How: rule of thumb — **design Events with enough information to satisfy 80 percent of subscribers**. Include (a) the Entity identifiers that own the Event (`CustomerId` to `Customer`), and (b) display properties such as `ProjectName`, `CustomerName`. Monolithic Bounded Contexts benefit less, since they keep secondary lookup tables and Entity maps.

## Key Concepts
- **Event Stream**: append-only, per-identity list of serialized Event messages; the sole source of an Aggregate's state.
- **Event Store**: strongly consistent append-only persistence for Event Streams, keyed by root Entity identity.
- **`IEventStore` vs `IAppendOnlyStore`**: the project-specific typed/serializing layer sits over the reusable low-level byte-array storage engine layer.
- **Optimistic concurrency version**: the Stream version carried from `Load()` to `Append()`; a mismatch means someone else appended.
- **Snapshot**: serialized Aggregate state recorded at a specific Stream version, plus `ReplayEvents()` for the tail.
- **Read Model Projection**: an Event-driven, disposable, rebuildable view; "very similar to an Aggregate instance" in how it builds state.
- **Focused Aggregate**: a small Aggregate carved around one behavioral aspect (`Customer:505`, `SecurityAccount:505`, `Consumer:505`), possibly each in a different Bounded Context with different technology.
- **Write-through vs write-behind replication**: Master Event Store considers Events saved only after replicating to the Clone, versus replicating on a separate thread with possible inconsistency.
- **Given-When-Expect**: the unit-test form natural to A+ES — Given past Events, When a method/Command is invoked, Expect Events or an exception.
- **Functional database**: an Event Store viewed as persisting the *arguments to the functions* that mutate state; snapshots are memoization.

## Mental Models
- Think of a Command as a serialized method invocation and a Command Handler as an Application Service method that is temporally decoupled — same semantics, different availability profile.
- Think of Aggregate state as a **left fold of all past Events**: `Func<State, Event, State>` applied across the Stream. Business methods are `Func<TArg1, TArg2..., State, Event[]>`.
- Use A+ES when structural freedom matters: no matter how complex an Aggregate becomes, it is always just a sequence of serialized Events — so you can restructure internals as domain understanding deepens, move hosting infrastructure, or download one instance's Stream to a dev machine and replay it to debug production.
- Because creating a new Aggregate costs no tables, schemata, or Repository methods, A+ES removes the pressure that makes Aggregates grow — expect *smaller* Aggregates, which serves the Aggregate Rules of Thumb.
- Start modeling by naming incoming Commands, outgoing Events, and behaviors; group them into Aggregates *later*, based on similarity, relevance, and business rules.

## Anti-patterns
- **Calling `Apply()` during replay or after a snapshot**: re-adds already-persisted Events to `Changes` and causes serious bugs. Use `Mutate()` / `ReplayEvents()`.
- **Arbitrarily small Aggregates**: design still exists to protect true business invariants; an Aggregate may legitimately hold multiple Entities and Value Objects.
- **Name-based Event serialization (`DataContractSerializer`, `JsonSerializer`)**: renaming a member silently breaks consumers or produces buggy data. Prefer Protocol Buffers (or Thrift, Avro, MessagePack), which track members by integral tag.
- **Mutable Event contracts**: Streams are immutable by nature; make fields read-only and set them only via constructor.
- **Primitive-typed identities in contracts**: `new ProjectAssignedToCustomer(customerId, projectId)` with two `long`s compiles fine when swapped. Value Object identities make the compiler catch it.
- **Hand-maintaining hundreds of Event/Command contracts**: tedious and error prone — generate them from a compact DSL.
- **Putting complex Core Domain Value Objects into a Shared Kernel just for type-safe deserialization**: brittle. Either keep two sets (contract VOs vs Core Domain VOs) and convert, or standardize serialized Events as a Published Language and consume dynamically.
- **Adopting A+ES for a simple model**: defining Events demands deep domain understanding, justified only for complex models yielding competitive advantage.

## Code Examples
```csharp
public partial class Customer
{
  public List<IEvent> Changes = new List<IEvent>();

  public void LockForAccountOverdraft(
    string comment, IPricingService pricing)
  {
    if (!ManualBilling)
    {
      var balance = pricing.GetOverdraftThreshold(Currency);
      if (Balance < balance)
      {
        LockCustomer("Overdraft. " + comment);
      }
    }
  }

  public void LockCustomer(string reason)
  {
    if (!ConsumptionLocked)
    {
      Apply(new CustomerLocked(_state.Id, reason));
    }
  }

  void Apply(IEvent e) { Changes.Add(e); Mutate(e); }
  public void Mutate(IEvent e) { ((dynamic) this).When((dynamic)e); }
  public void When(CustomerLocked e) { ConsumptionLocked = true; }
}
```
- **What it demonstrates**: behavior double-dispatches to a Domain Service, guards on current state, and expresses its outcome purely as an Event; `Apply` records it for persistence and immediately mutates state so later steps see it.

```csharp
void Update(CustomerId id, Action<Customer> execute)
{
  while(true)
  {
    EventStream eventStream = _eventStore.LoadEventStream(id);
    var customer = new Customer(eventStream.Events);
    try
    {
      execute(customer);
      _eventStore.AppendToStream(
        id, eventStream.Version, customer.Changes);
      return;
    }
    catch (EventStoreConcurrencyException)
    {
      // fall through and retry, with optional brief delay
    }
  }
}
// usage: Update(c.Id, customer => customer.LockCustomer(c.Reason));
```
- **What it demonstrates**: lambda-captured behavior removes repetitive Stream management *and* makes automatic retry possible, since the same behavior can be re-executed against a reloaded Aggregate.

## Reference Tables

### A+ES benefits vs costs

| Benefits | Costs / drawbacks |
|---|---|
| The reason for every change is never lost (traditional state serialization overwrites the previous state irrecoverably) | Defining Events requires deep business-domain understanding — justified only for complex, competitive-advantage models |
| Reliability, near- and far-term business intelligence, analytic discoveries, full audit log, look back in time to debug | Lack of tooling and a consistent body of knowledge; higher cost and risk for inexperienced teams |
| Append-only Streams perform outstandingly and support many replication options (cf. LMAX low-latency trading) | Limited pool of experienced developers |
| Event-centric design keeps attention on Ubiquitous Language behaviors, avoiding ORM impedance mismatch | Almost certainly requires CQRS, since Event Streams are hard to query — more cognitive load and learning curve |
| Structural freedom: restructure Aggregate internals, move hosting, replay one instance locally to debug | Large Streams degrade load performance; needs caching, snapshots, or partitioning |
| Aggregates get smaller because creating a new one costs nothing | Read Models must be maintained and rebuilt via Projections |

### Event Store persistence options

| Option | What you get | What you must handle yourself |
|---|---|---|
| **Relational (MySQL, MS SQL, Oracle)** | Strong consistency, transactions, caching, no learning curve where already standardized; `ES_Events(Id, Name, Version, Data LONGBLOB)`; append = begin tx → check version → insert → commit | Little — simplest route |
| **NoSQL with strong consistency (MongoDB, RavenDB, Azure Blob, file system)** | Cheap horizontal options, cloud-native hosting | Consistency guarantees must be verified |
| **BLOB / file-based (Riak Bitcask-inspired)** | Exclusive write lock with concurrent reads; one store per Context, per Aggregate type, or per instance | Concurrency management, fragmentation (preallocate large regions), caching, in-memory index, length-prefixed variable fields, CRC/hash for integrity |

### Concurrency strategies

| Strategy | Use when | Mechanism |
|---|---|---|
| Propagate `EventStoreConcurrencyException` to the client | Simplest case | User manually retries |
| Automatic retry loop | Re-executing the behavior is cheap | Reload Stream, re-run the `Action<T>` delegate, append |
| Event conflict resolution | Re-execution is expensive or infeasible (credit card charge, third-party order) | `ConflictsWith()` per Aggregate Root; same-type Events conflict, different-type do not; append at the server's actual version when no conflict |

## Worked Example
`LockForAccountOverdraft` end-to-end. `CustomerApplicationService` is constructed with `IEventStore` and the `IPricingService` Domain Service. On the call it (2.1) loads the Event Stream by `CustomerId`, (2.2) builds `new Customer(stream.Events)` — the constructor loops calling `Mutate`, so `When(CustomerLocked)` / `When(CustomerUnlocked)` restore `ConsumptionLocked` — (3) invokes `customer.LockForAccountOverdraft(comment, _pricingService)`, which double-dispatches to the pricing service for the overdraft threshold and, if the balance is below it, calls `LockCustomer`, which guards on `ConsumptionLocked` and `Apply`s a `CustomerLocked` Event, and (4) appends `customer.Changes` at `stream.Version`.

That method is then refactored three ways without changing the model: the parameters become a serializable `LockCustomerCommand` handled by `When(LockCustomerCommand)` so it can arrive over a queue (load balancing, competing consumers, availability during maintenance, plus wrappable logging/auditing/authorization); the Stream plumbing collapses into `Update(c.Id, customer => customer.LockCustomer(c.Reason))`; and the same `Update` becomes the retry loop for `EventStoreConcurrencyException` — thread 2 catching the exception reloads Events 1–5 and re-executes the delegate, producing Events 6–7 appended after Event 5.

Sharing across Aggregates is then shown: `Invoice` needs `Customer` name, billing address, and tax ID. Rather than coupling to the `Customer` Aggregate, `CustomerBillingProjection` maintains a `CustomerBillingView` Read Model, exposed to `Invoice` through the Domain Service `IProvideCustomerBillingInformation`, which just queries the document store. Changing what that returns means changing the Projection and replaying Events — the `Customer` Aggregate is untouched.

## Key Takeaways
1. Reconstitute with `Mutate`, record with `Apply` — never mix them, or replayed Events get re-persisted.
2. Carry the Stream version from load to append; that single variable is your optimistic concurrency control.
3. Prefer automatic retry with a lambda-captured behavior; fall back to per-Aggregate Event conflict resolution when re-execution is expensive.
4. Expect to adopt CQRS: build Read Model Projections as disposable Event subscribers you can discard and rebuild by replaying the whole Stream.
5. Enrich Events to satisfy roughly 80 percent of subscribers — owning Entity identifiers plus display names — even though it exceeds what reconstitution needs.
6. Choose a tag-based serializer (Protocol Buffers, Thrift, Avro, MessagePack) so renaming Event members doesn't break consumers; make Event contracts immutable.
7. Model identities and quantities as Value Objects so the compiler catches misordered contract parameters, and decompose fat Event contracts into cohesive parts (`InvoiceHeader`, `InvoiceFooter`, `CurrencyAmount`).
8. Generate Event and Command contracts from a compact DSL — fewer errors, faster iteration, and a one-screen terse glossary of the Ubiquitous Language.
9. Write tests as Given-When-Expect against Events, not internal state; pushing `When` up to a Command yields specifications printable as human-readable use cases for domain experts.
10. In F#/Clojure, model state as an immutable record folded over Events; the Event Store becomes a functional database and snapshots become memoization.

## Connects To
- **ch01 (DDD / Ubiquitous Language)**: Event-first modeling forces attention onto behaviors named in the Ubiquitous Language.
- **ch02 (Bounded Contexts)**: focused Aggregates may live in different Contexts with different technology and scaling profiles.
- **ch03 (Context Maps)**: Shared Kernel for contract Value Objects, or Published Language for standardized serialized Events.
- **ch04 (Architecture)**: CQRS is effectively mandatory with A+ES; also Event-driven architecture and long-term business intelligence.
- **ch05 (Entities)**: Streams are keyed by root Entity identity.
- **ch06 (Value Objects)**: immutable, Side-Effect-Free Functions map directly onto functional Event-sourced state records.
- **ch07 (Domain Services)**: passed into Aggregate command methods; also expose Read Models to other Aggregates.
- **ch08 (Domain Events)**: Event definition and Event Store fundamentals.
- **ch10 (Aggregates)**: A+ES biases toward the Rule of Thumb "Design Small Aggregates" while still protecting true invariants.
- **ch12 (Repositories)**: a Repository base class can encapsulate Event Store access and reconstitution; `ISnapshotRepository`.
- **ch13 (Integrating Bounded Contexts)**: dynamic-typing Event consumption avoids deploying contract types to subscribers.
- **ch14 (Application)**: Command objects and Command Handlers as temporally decoupled Application Service methods.
- **External**: Greg Young [Young, ES]; Riak Bitcask BLOB storage model; Protocol Buffers / Thrift / Avro / MessagePack; LMAX.
