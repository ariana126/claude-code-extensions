# Layers, Write Models and Read Models — Full Reference

Read this when structuring a codebase, deciding which layer a new class belongs
in, working out whether something needs an interface, or when a read-only client
is being handed an entity.

## Contents

1. [Never Hand an Entity to a Read-Only Client](#1-never-hand-an-entity-to-a-read-only-client)
2. [Read Models Are Shaped by Use Cases](#2-read-models-are-shaped-by-use-cases)
3. [Three Ways to Build a Read Model](#3-three-ways-to-build-a-read-model)
4. [The Three Layers](#4-the-three-layers)
5. [Recognition Tests for Each Object Type](#5-recognition-tests-for-each-object-type)
6. [Which Types Get an Interface](#6-which-types-get-an-interface)
7. [Domain Events](#7-domain-events)

---

## 1. Never Hand an Entity to a Read-Only Client

**The rule**: never give a modifiable entity to a client that shouldn't modify
it. Split the entity into a **write model** exposing command methods and one or
more **read models** exposing only information.

**Why, in Noback's words**: "Even if the client doesn't modify it today, one day
it might, and then it will be hard to find out what happened." The cost isn't
the modification itself — it's that state changes stop being traceable to a
single place.

**Important qualification**: query methods on write models are *not* forbidden.
A client that modifies an entity may legitimately need to read from it first to
decide or validate — `salesInvoice.wasCancelled()` before
`salesInvoice.finalize()` is fine, because that client modifies. The rule targets
clients that *only* read.

**The success signal**: after extracting the read model, you can **delete the
write model's getters** and no write-model client breaks. Here's what's left of a
purchase order after the stock report stops reaching into it:

```
class PurchaseOrder {
  private constructor() {}

  static place(id: PurchaseOrderId, productId: ProductId, quantity: int): PurchaseOrder { ... }
  markAsReceived(): void { this.wasReceived = true }

  // productId(), orderedQuantity(), wasReceived() — all deleted
}
```

**The clearest anti-pattern**: passing an entity to a template renderer or a
serializer. It may be a write model today only by accident, and the view can
call anything on it.

## 2. Read Models Are Shaped by Use Cases

One entity produces **many** read models, each shaped for one screen, report, or
endpoint, and each named for that purpose: `PurchaseOrderForStockReport`, then
`StockReport` itself. A listing might need only ID and date; a form needs only
the fields it edits.

**The test of a good read model: the client stops transforming it.** If the
controller still loops and reshapes what it got back, the read model was shaped
for the entity rather than for the use case.

A read model is recognizable by three properties: it has only query methods (so
it's immutable), it's designed for a specific use case, and **all the data
needed — and no more — is available the moment you retrieve it.** A read model
that requires a second query to fill in what the view needs isn't finished.

**Read models can be trivially reshaped; write models cannot.** That asymmetry
is why you multiply read models freely and guard the write model jealously.

A **"smarter" read model** is one consumed by an application service rather than
a view: it returns proper value objects instead of primitives, so the service
needn't worry about validity. It feels like a write model with no way to write.

## 3. Three Ways to Build a Read Model

A cost ladder, not a ranking:

| Approach                              | Runtime cost         | Dev/maintenance | Use when                                        |
|---------------------------------------|----------------------|-----------------|-------------------------------------------------|
| From the write model (`forStockReport()`) | High — loads all entities | Low        | A stopgap; the client still sees the write model |
| **Direct from the data source (SQL)**     | Low                  | **Low**         | **Default.** Write model stable, raw data usable |
| From domain events                        | Lowest — precomputed | High            | Recomputation is genuinely too expensive         |

**Option 2 is the default** because it's cheapest at runtime *and* in
development and maintenance — a rare combination, and the reason to reach for it
before anything cleverer:

```
class StockReportSqlRepository implements StockReportRepository {
  getStockReport(): StockReport {
    const rows = this.connection.execute(
      `SELECT product_id, SUM(ordered_quantity) AS quantity_in_stock
       FROM purchase_orders WHERE was_received = 1 GROUP BY product_id`
    )
    return new StockReport(rows)
  }
}

class StockReportController {
  constructor(private repository: StockReportRepository) {}   // no PurchaseOrderRepository
  execute(request): Response {
    return new JsonResponse(this.repository.getStockReport().asArray())
  }
}
```

The controller no longer knows the write model exists. No `findAll()`, no loop,
no transformation.

**Option 1 is a stopgap.** The entity offers `forStockReport()`, which is quick
to write, but the client still touches the write model — so the original goal
isn't actually met.

**Option 3 costs the most.** A listener maintains its own `stock_report` table
incrementally, so the query collapses to `SELECT * FROM stock_report`. Noback's
framing: *sit next to the user with a piece of paper* — instead of re-summing
every purchase order on each request, write down each receipt as it happens and
keep a running total. Same answer, computed once at write time.

Escalate to option 3 only when the write model **changes often**, the raw data
**needs interpretation before use**, or recomputation is **genuinely too
expensive**. The costs are real: more moving parts, harder domain-event
evolution, and failed listeners that need operational tooling and re-running.

**Event sourcing is a separate and much larger commitment** — reconstructing the
*write* model from events too. You get every benefit described in this file
without it.

## 4. The Three Layers

```
Infrastructure  controllers, repository IMPLEMENTATIONS
Application     application services, command objects, read models,
                read model repository INTERFACES, event listeners
Domain          entities, value objects, write model repository INTERFACES
```

Think of them as concentric circles: infrastructure wraps application, which
wraps domain. **Nothing inner ever names anything outer.**

**Put the layer name in the namespace or module path** —
`Infrastructure/UserInterface/Web`, `Application/ScheduleMeetup`,
`Domain/Model/Meetup`. Then the layering is visible in every import, and a
violation is visible in code review without any tooling.

Inward-only dependencies buy two concrete things: you can test the domain
without a live database, and you can survive a framework or database swap.

```
// DOMAIN — the interface
interface MeetupRepository {
  save(meetup: Meetup): void
  nextIdentity(): MeetupId
  getById(id: MeetupId): Meetup      // throws MeetupNotFound
}

// INFRASTRUCTURE — the details
class OrmMeetupRepository implements MeetupRepository { ... }
```

The dependency arrow points inward: infrastructure knows about domain, never the
reverse.

## 5. Recognition Tests for Each Object Type

Each type has an explicit test. An object that fails all of them but still
follows the rest of the guideline is fine — the taxonomy describes what's common,
not what's mandatory.

**Controller** — a front controller calls it (making it an entry point to the
service graph), it contains infrastructure code revealing the delivery
mechanism, and it calls an application service or a read model repository.
*Tell*: mentions of requests, forms, templates, sessions, cookies — or CLI
arguments, flags, and terminal output. Web controllers and console commands are
conceptually the same thing; call both controllers.

**Application service** — it performs a single task, contains **no**
infrastructure code, and describes one use case, usually one-to-one with a
stakeholder's feature request. It reads like a recipe: take an object out of a
repository, call a method on it, save it again. It receives **primitive** data so
the controller doesn't have to convert first, and converts to value objects
itself. Also called a command handler when invoked with a command object.

```
class ScheduleMeetupService {
  constructor(private meetupRepository: MeetupRepository) {}   // the INTERFACE, from Domain

  schedule(title: string, date: string, currentUserId: UserId): MeetupId {
    const meetup = Meetup.schedule(
      this.meetupRepository.nextIdentity(),
      Title.fromString(title),                 // primitives in, value objects here
      ScheduledDate.fromString(date),
      currentUserId
    )
    this.meetupRepository.save(meetup)
    return meetup.meetupId()
  }
}
```

Nothing here knows about HTTP, the CLI, or SQL — which is exactly what lets the
same service back both a web controller and a console command.

**Write model repository** — offers methods for retrieving and saving an object,
and its interface hides the underlying technology. Repositories are the
legitimate exception to CQS at the object level: save and retrieve are inverse
operations, so one object holding both is fine.

**Entity** — has a unique identifier and a life cycle, is persisted by and
retrievable from a write model repository, uses named constructors and command
methods, and produces domain events on instantiation and modification. It has
**few or no query methods**; retrieving information is delegated to read models.

**Value object** — immutable, wraps primitive data, adds meaning via domain terms
(`Year`, not `int`), imposes limitations via validation, and **acts as an
attractor of useful behavior** (`Position.toTheLeft(steps)`,
`Title.abbreviated()`).

**Event listener** — an immutable service with injected dependencies, having at
least one method that accepts a single domain event argument. Naming convention:
the class says *what* you're going to do (`NotifyGroupMembers`), the method says
*why* (`whenMeetupRescheduled`).

**Read model** — only query methods, designed for a specific use case, all
required data present on retrieval.

| Object type            | Layer                                  | Abstraction? |
|------------------------|----------------------------------------|--------------|
| Controller             | Infrastructure                         | No           |
| Application service    | Application                            | No           |
| Command object (DTO)   | Application                            | No           |
| Read model             | Application                            | No           |
| Read model repository  | Application (interface) / Infra (impl) | **Yes**      |
| Event listener         | Application                            | No           |
| Entity                 | Domain                                 | No           |
| Value object           | Domain                                 | No           |
| Write model repository | Domain (interface) / Infra (impl)      | **Yes**      |

## 6. Which Types Get an Interface

**The rule underneath all of it**: anything that crosses a system boundary gets
an interface; anything that expresses your understanding of the domain or a use
case does not.

- **Concrete, no interface**: controllers (if you switch frameworks you rewrite
  them, you don't add a second implementation), application services (if the use
  case changes, the service changes), entities, value objects, read models.
- **Abstraction plus implementation**: repositories, both read and write, and any
  other service reaching outside the application.

Putting an interface on a controller or an application service adds ceremony
with no substitutability benefit — there will never be a second implementation.
Depending on a repository *implementation* instead of its interface has the
opposite problem: it kills testability and portability at once.

The boundary between "read model repository" and "ordinary service" is genuinely
fuzzy — is `ExchangeRateProvider` a repository over a collection of rates, or
just a service? Noback's answer is that it doesn't matter. What matters is that
both get an abstraction (the question being asked) and an implementation (how
it's answered).

## 7. Domain Events

An entity records events internally on state change; the application service
dispatches them after saving:

```
class Meetup {
  private events = []

  static schedule(id, title, date, userId): Meetup {
    const meetup = new Meetup()
    ...
    meetup.recordThat(new MeetupScheduled(id, title, date, userId))
    return meetup
  }

  reschedule(date: ScheduledDate): void {
    ...
    this.recordThat(new MeetupRescheduled(this.meetupId, date))
  }

  private recordThat(event): void { this.events.push(event) }
  releaseEvents(): array { return this.events }
}

class RescheduleMeetupService {
  reschedule(meetupId, ...): void {
    ...
    this.repository.save(meetup)
    this.dispatcher.dispatchAll(meetup.releaseEvents())
  }
}
```

Three things about events worth holding onto:

- **Structurally, domain events and value objects are identical.** Both are
  immutable data holders. *Usage* is what distinguishes them: a domain event is
  created and recorded inside an entity then dispatched; a value object models an
  aspect of the entity.
- **Name them in the domain's language, and don't create redundant ones.**
  `CartWasCreated` is already implied by `ProductWasAddedToCart`.
- **Add data on a need-to-know basis, driven by tests.** Fat event objects
  stuffed with fields "just in case" are a real anti-pattern — every field is
  something you'll later have to keep populated and evolve.
