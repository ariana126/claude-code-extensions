# Chapter 12: Repositories

## Core Idea
A Repository provides the illusion of an in-memory collection of all Aggregate instances of one type, hiding the persistence mechanism completely behind a domain-oriented interface. The single design decision that drives everything else is whether your persistence mechanism can track changes implicitly (collection-oriented) or cannot (persistence-oriented, save-based).

## Frameworks Introduced

- **Collection-Oriented Repository**: Design the interface to mimic a `Set` — `add()`, `addAll()`, `remove()`, `removeAll()`, plus finders. No hint of persistence in the public interface; **no `save()` method**.
  - When to use: your persistence mechanism tracks changes implicitly — Hibernate (Implicit Copy-on-Read), proxy-based ORMs (Implicit Copy-on-Write), or TopLink/EclipseLink (Explicit Copy-before-Write via `UnitOfWork`).
  - How:
    1. Declare the interface in the same Module (ch09) as the Aggregate type it stores.
    2. Model it on `java.util.Set`, not `Collection`: adding the same Aggregate twice must be a benign no-op (globally unique identity of the Root prevents duplicates).
    3. Return `void` rather than `boolean` from `add`/`remove` — success is not known until transaction commit.
    4. Add finder methods named in the Ubiquitous Language: `calendarEntryOfId()`, `calendarEntriesOfCalendar()`, `overlappingCalendarEntries()`.
    5. Add `nextIdentity()` so clients get the Aggregate's globally unique identity from the Repository.
    6. Put the implementation in the Infrastructure Layer (or an `impl` sub-package), depending downward via the Dependency Inversion Principle (ch04). Catch framework exceptions and rethrow as client-friendly/domain exceptions.
  - Why it works / failure mode: retrieved objects are still *held* by the collection, so a state change made on the retrieved instance is the change — no re-save. Fails when the persistence mechanism cannot detect dirty objects (key-value/NoSQL/Data Fabric), or when implicit copying costs too much memory in a very high-object-count domain.

- **Persistence-Oriented (Save-Based) Repository**: Replace `add`/`addAll` with `save()`/`saveAll()`; the client must save both on creation **and** after every modification.
  - When to use: in-memory Data Fabric (ch04) such as GemFire or Coherence, or key-value/document stores such as MongoDB or Riak — anything with no Unit of Work and no change tracking. Also use it preemptively if you may swap the persistence mechanism later.
  - How:
    1. Define `save(Aggregate)`, `saveAll(Collection)`, `remove`, `removeAll`, finders, `nextIdentity()`.
    2. Implement each `save()` as an explicit `put()` into the Map-like store, replacing the value under the key — each `put()`/`putAll()` is its own logical transaction.
    3. Namespace the store per Bounded Context short name → Aggregate simple name → `TenantId`, so tenants are physically segregated and "all instances of tenant" needs no query at all.
    4. Replace default Java serialization with compact custom serialization (e.g. a `BSONSerializer` for MongoDB) — default serialization wastes bytes and throughput.
    5. Audit clients: the risk is a *forgotten* `save()`, which an ORM-backed Unit of Work would have covered for you.

- **One Repository per Aggregate Type**: Provide Repositories only for Aggregates; the relationship is one-to-one, except that a small type hierarchy of interchangeable Aggregates (LSP) may share one Repository.

## Key Concepts
- **Implicit Copy-on-Read**: Persistence mechanism copies each object on read and diffs it at commit (Hibernate).
- **Implicit Copy-on-Write**: Objects handed out as proxies that copy and mark dirty on first invocation.
- **Explicit Copy-before-Write**: Client registers an object with a `UnitOfWork`, which answers an editable clone (TopLink); consumes memory only when needed.
- **`nextIdentity()`**: Repository-supplied generator of the Aggregate's globally unique identity, usually a UUID — not a database sequence.
- **Use case optimal query**: A complex query whose results are projected directly into a purpose-built Value Object (ch06) for one use case, rather than composing whole Aggregates.
- **Aggregate Store / Aggregate-Oriented Database**: A key-value or document store whose natural unit of write is a whole serialized Aggregate.
- **Repository-only persistence**: All persistence goes through Repositories; Aggregates never persist themselves (no Aggregate-managed persistence).
- **Layer Supertype**: A domain-wide common base class — distinct from a domain-specific Aggregate type hierarchy sharing one Repository.

## Mental Models
- Think of a Repository as a `Set`, not a `Collection`: adding twice must be harmless, and you never "re-save" what the set already holds.
- Use `editingCopy(aggregate)` or `useEditingMode()` when a `UnitOfWork`-based ORM forces registration — both express the need without leaking a persistence frame of mind.
- Treat many use-case-optimal finders across many Repositories as the smell **"Repository masks Aggregate mis-design"**: first re-examine Aggregate boundaries; if they are right, reach for CQRS (ch04).
- Transactions live in the Application Layer (ch14), never in the model: a Facade business method starts, commits, or rolls back around domain-model interaction.

## Anti-patterns
- **A `save()` method on a collection-oriented interface**: leaks the persistence mechanism into the domain interface and invites clients to think in CRUD.
- **Aggregate-managed persistence / ORM lifecycle-event cascades**: DDD experts avoid it as a rule of thumb; keep persistence in Repositories.
- **Repository finders that expose Aggregate parts the Root would not expose by navigation**: violates the Aggregate contract; permissible only to relieve a measured performance bottleneck.
- **Committing many Aggregates per transaction because it passes in unit tests**: works in dev, fails in production under concurrency — revisit consistency boundaries (ch10).
- **Encoding Aggregate subtype in the identity so clients can pick typed finders**: pushes type resolution onto clients and couples them to per-type operations (`if (id.identifiesWarble()) ...`).
- **DAO-style fine-grained CRUD on Aggregate internals**: DAOs wrap tables (Table Module, Table Data Gateway, Active Record — Transaction Script patterns); Repository and Data Mapper are the domain-model patterns.
- **Prolific stored procedures**: the language is opaque to the modeling team and the logic is hidden from view — the opposite of DDD. (Data Fabric entry processors written in Java are acceptable.)

## Code Examples
```java
public interface CalendarEntryRepository {           // collection-oriented
    public CalendarEntryId nextIdentity();
    public void add(CalendarEntry aCalendarEntry);
    public void addAll(Collection<CalendarEntry> aCollection);
    public void remove(CalendarEntry aCalendarEntry);
    public void removeAll(Collection<CalendarEntry> aCollection);
    public CalendarEntry calendarEntryOfId(
            Tenant aTenant, CalendarEntryId aCalendarEntryId);
    public Collection<CalendarEntry> overlappingCalendarEntries(
            Tenant aTenant, CalendarId aCalendarId, TimeSpan aTimeSpan);
}

public interface ProductRepository {                  // persistence-oriented
    public ProductId nextIdentity();
    public Product productOfId(Tenant aTenant, ProductId aProductId);
    public Collection<Product> allProductsOfTenant(Tenant aTenant);
    public void remove(Product aProduct);
    public void removeAll(Collection<Product> aProductCollection);
    public void save(Product aProduct);
    public void saveAll(Collection<Product> aProductCollection);
}
```
- **What it demonstrates**: the two orientations differ only in how instances enter the collection — `add()` at creation only, versus `save()` at creation *and* after every modification.

```java
public class HibernateCalendarEntryRepository
        implements CalendarEntryRepository {
    @Override
    public void add(CalendarEntry aCalendarEntry) {
        try {
            this.session().saveOrUpdate(aCalendarEntry);
        } catch (ConstraintViolationException e) {
            throw new IllegalStateException("CalendarEntry is not unique.", e);
        }
    }
    private org.hibernate.Session session() {
        return this.sessionProvider.session();   // thread-bound Session
    }
}
```
- **What it demonstrates**: `saveOrUpdate()` gives Set-like semantics (re-adding is a no-op), and framework exceptions are wrapped so no persistence detail escapes to clients.

## Reference Tables

| | Collection-Oriented | Persistence-Oriented |
|---|---|---|
| Mimics | `java.util.Set` | `java.util.Map` (put/get) |
| Interface methods | `add()`, `addAll()`, `remove()`, `removeAll()` | `save()`, `saveAll()`, `remove()`, `removeAll()` |
| Client saves after modify? | No — changes tracked implicitly | Yes — every modification needs `save()` |
| Requires of the mechanism | Change tracking: Implicit Copy-on-Read, Implicit Copy-on-Write, or Explicit Copy-before-Write | Nothing; explicit `put()` replaces value at key |
| Typical technology | Hibernate, TopLink/EclipseLink, JPA | Coherence, GemFire, MongoDB, Riak |
| Transaction unit | Session / Unit of Work, commit at Application Layer | Each `put()` is its own logical transaction |
| Main risk | ORM copy overhead in very large in-memory domains | A missed `save()` silently loses a change |
| Portability | Breaks if you later move to a key-value store | Survives a mechanism swap |

| Repository | DAO |
|---|---|
| Expressed in Aggregates and the Ubiquitous Language | Expressed in database tables, CRUD interfaces |
| Pairs with Data Mapper and a domain model | Pairs with Table Module, Table Data Gateway, Active Record, Transaction Script |
| Coarse-grained: whole Aggregate in, whole Aggregate out | Fine-grained access to rows and columns |

## Worked Example
**Aggregate type hierarchy — and why to avoid it.** You model external service suppliers with an abstract `ServiceProvider` and concrete `WarbleServiceProvider` / `WonkleServiceProvider`, sharing one `ServiceProviderRepository`. Client code is clean while it stays polymorphic:

```java
serviceProviderRepository.providerOf(id).scheduleService(date, description);
```

The trouble starts when finders must answer specific subtypes. Return the supertype and clients cannot invoke subtype-specific operations; return subtypes and clients must know which identity maps to which type, risking unmatched finds or `ClassCastException`. Encoding the type as a discriminator inside the identity "solves" it and produces exactly the smell you were avoiding:

```java
if (id.identifiesWarble()) {
    serviceProviderRepository.warbleOf(id).scheduleWarbleService(date, warbleDescription);
} else if (id.identifiesWonkle()) {
    serviceProviderRepository.wonkleOf(id).scheduleWonkleService(date, wonkleDescription);
}
```

**Fix**: collapse to a single concrete `ServiceProvider` Aggregate carrying a Standard Type (ch06) as a property, and dispatch *inside* the Aggregate so no type decision leaks to clients:

```java
public class ServiceProvider {
    private ServiceType type;
    public void scheduleService(Date aDate, ServiceDescription aDescription) {
        if (type.isWarble())      this.scheduleWarbleService(aDate, aDescription);
        else if (type.isWonkle()) this.scheduleWonkleService(aDate, aDescription);
        else                      this.scheduleCommonService(aDate, aDescription);
    }
}
```
If the dispatch gets messy, make the Standard Type a `State` [Gamma et al.], or use role-based interfaces (`SchedulableService`) instead of inheritance. **Decision rule**: two or a few concrete subclasses → separate Repositories; several or many, fully interchangeable under LSP → one shared Repository.

## Key Takeaways
1. Choose orientation from the persistence mechanism's change-tracking capability first — everything else in the interface follows from it.
2. Provide Repositories only for Aggregates; one Repository per Aggregate type, interface in the Aggregate's Module, implementation in Infrastructure.
3. Let the Repository mint identity via `nextIdentity()` (UUID) so identity assignment is early and independent of the data store.
4. Add behavior sparingly: `size()` (not `count`) mimics a collection; use-case optimal queries returning Value Objects are legitimate but are a smell in bulk.
5. Manage transactions in an Application Layer Facade, declaratively (`@Transactional`) or explicitly, and make sure Repositories share the same thread-bound Session / Unit of Work.
6. Test production Repository implementations against the real mechanism (setUp creates it, tearDown removes all instances); use `HashMap`-backed in-memory implementations when the real store is slow, unavailable, or the schema doesn't exist yet.
7. In-memory implementations can also count `save()` invocations, letting you assert that an Application Service saved exactly what it should have.

## Connects To
- **ch10 (Aggregates)**: Repositories store Aggregates; the transaction warning depends on correctly drawn consistency boundaries.
- **ch05 (Entities)**: identity creation techniques, surrogate vs domain identity, timing of identity assignment; role-based interfaces.
- **ch06 (Value Objects)**: Standard Types replace Aggregate type hierarchies; use case optimal queries return Value Objects.
- **ch09 (Modules)**: place the Repository interface in the Aggregate's Module.
- **ch04 (Architecture)**: Dependency Inversion Principle for Infrastructure placement; CQRS and Data Fabric.
- **ch14 (Application)**: transaction demarcation in Application Service Facades.
- **ch07 (Services)**: house stored procedures / entry-processor style computation under Domain Services.
- **Fowler, P of EAA**: Data Mapper, Unit of Work, Layer Supertype vs Table Module / Table Data Gateway / Active Record.
