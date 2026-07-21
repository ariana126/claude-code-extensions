# Chapter 5: Entities

## Core Idea
Model a domain concept as an Entity only when its *individuality* is a mandatory constraint — when it must be uniquely distinguished and mutable over a long life — and then design it around identity, life-cycle continuity, and intention-revealing behavior, not around getters and setters mirroring database columns.

## Frameworks Introduced

- **Unique Identity Creation Strategies** (four, in ascending complexity): user provides identity; application generates identity; persistence mechanism generates identity; another Bounded Context assigns identity.
  - When to use: at the very start of Entity design — "strip the Entity object's definition down to the most intrinsic characteristics, particularly those that identify it or are commonly used to find or match it."
  - How:
    1. Decide whether the identity must also be *human-readable* for finding/matching. A person's name is a poor identity (non-unique); a government-issued tax ID is a fine one for `Company`.
    2. Wrap raw identity in a **Value Object** (`TenantId`, `ProductId`) — immutability guarantees identity stability, and identity-specific behavior (e.g. `productId.creationDate()`) is centralized instead of leaking into clients.
    3. Distinguish **global identity** (required by an Aggregate Root) from **local identity** (Entities inside an Aggregate need uniqueness only within that Aggregate — a shortened UUID segment may suffice).
    4. Pick the generation strategy from the table below.
    5. Decide **early vs. late** generation.
    6. Add a surrogate identity if your ORM demands it.

- **Early vs. Late Identity Generation**: early = generation and assignment happen *before* the Entity is persisted (client asks `repository.nextIdentity()` and passes it to the constructor); late = generation happens *when* the Entity is persisted.
  - Use early when: (a) a Domain Event is published at construction and must carry the valid identity — with late generation the Event is published before the Repository ever sees the object, so the identity is absent/invalid; (b) two or more new Entities are added to a `java.util.Set` and their yet-unassigned identities (`null`, `0`, `-1`) make them equal, silently excluding all but the first.
  - The alternative to fixing the `Set` bug with early generation is refactoring `equals()`/`hashCode()` to compare non-identity attributes as if the Entity were a Value Object — but Vernon prefers early allocation, because Entity equality should be identity-based.

- **Surrogate Identity**: a second, ORM-only identity (typically a `long`/`int` mapped to the table primary key) held alongside the domain identity.
  - When to use: Hibernate (or similar) insists on a native database type as primary identity while the domain requires a different one.
  - How: add a surrogate attribute; add a primary-key column; declare `<id>` in the Hibernate mapping; hide the attribute behind a **Layer Supertype** (`IdentifiedDomainObject`) with `protected` (or `private`) accessors so the persistence leakage is invisible to clients and model developers — Hibernate reflects over any visibility. Keep the domain identity as a separate unique key (e.g. `k_tenant_id_username` over `tenant_id_id` + `username`), and let the surrogate serve as the foreign key throughout the data model for referential integrity, joins, and audits.

- **Identity Stability (modify-once guards)**: protect identity from modification for the lifetime of the Entity.
  - How: hide identity setters from clients (`protected`); inside the setter, throw `IllegalStateException` if the attribute is already non-`null`, and `IllegalArgumentException` if the new value is `null`. This still permits Hibernate's one-time reconstitution assignment, because the object starts from the zero-argument constructor with a `null` attribute. Prove it with a test that asserts the exception.

- **Discovering Entities from the Ubiquitous Language**: mine terse requirement statements with domain experts.
  - How:
    1. Listen for forms of the word **"change"** — a strong hint of an Entity (but beware: "change" can also mean "replace the Value").
    2. Listen for words implying **search resolution** ("authenticated") — if one thing must be found among many, it needs unique identity.
    3. Rewrite ambiguous requirements *with the whole team* until they read as complete, meaningful sentences.
    4. First capture only the attributes that provide identity and enable query matching; defer support attributes.
    5. Then dig for **indispensable behavior**, naming operations from the experts' verbs.
    6. Record findings in a lightweight glossary plus usage scenarios — but remember the Language is ultimately modeled by the code.

- **Roles and Responsibilities (object roles via interfaces)**: a class plays one role per interface it implements; with no explicit interface it plays the implicit role of its class.
  - When to use: fine-grained role interfaces (Udi Dahan's style, e.g. `IAddOrdersToCustomer`, `IMakeCustomerPreferred`) when a use case needs a specialized *fetching strategy* (`session.Get<IMakeCustomerPreferred>(customerId)`), per-role validation hooks, or simply to hide implementation details that must not leak to clients.
  - Failure mode: **object schizophrenia**. Delegating a role to `PersonPrincipal`/`SystemPrincipal` from a `UserPrincipal` leaves the delegates ignorant of the originating Entity's identity; passing the originator back changes the `Principal` interface. "Delegation is a good design choice only when it simplifies more than it complicates" [Gamma et al.]. Fine-grained interfaces implemented *on the class itself* avoid this.

- **Construction**: a constructor must take enough state to fully identify the Entity, to enable clients to find it, and to satisfy every invariant.
  - How: pass the unique identity (under early generation) plus any query attributes plus any state a non-`null` invariant depends on; use **self-encapsulation** — the constructor delegates to its own setters, and each setter asserts its own contractual **guards**; use a **Factory** for complex instantiation (here `Tenant.registerUser()` is the Factory, and `User`'s constructor is `protected` so only same-Module classes — i.e. `Tenant` — can create Users).

- **Three Levels of Validation**:
  1. **Attribute/property validation** — design-by-contract **preconditions** implemented as guards inside self-encapsulated setters (null, empty, length, range, format). Not really "validation": assertions.
  2. **Whole-object validation** — a separate **Validator** class implementing **Specification** [Evans & Fowler] or **Strategy** [Gamma et al.], placed in the same Module as the Entity so it can read `protected`/package-scope accessors.
  3. **Object-composition validation** — Ward Cunningham's **Deferred Validation**: "a class of checking that should be deferred until the last possible moment," run over a cluster of Entities or several Aggregates, best coordinated by a **Domain Service** that uses Repositories to load the instances.
  - How (levels 2–3): give the Validator a `ValidationNotificationHandler` and **collect the full set of results rather than throwing on the first failure**; prefer a specific handler method per condition (`handleWarpedWarble()`) over a generic `handleError(String)` so message keys don't couple to the validation process; push each check into its own `checkForX()` method; expose `validate(ValidationNotificationHandler)` on the Entity (optionally via the `Entity` Layer Supertype as a no-op) so the Entity decides *what* validates it without knowing *how*; when Aggregates pass through temporary intermediate states, model a status or publish a Domain Event (`WarbleTransitioned`) that tells clients validation is now appropriate.
  - Why it works: validation changes at a different pace than the Entity it validates; keeping it in a separate class avoids overloading the Entity's responsibilities and makes complex validations thoroughly testable.

- **Change Tracking**: an Entity does not by definition need change history — it only must support continuously changing state. When domain experts *do* care, create a unique **Domain Event** type for every important state-altering command on every Aggregate they care about, publish it as the command method completes, and have a subscriber save every Event to an **Event Store**. When only the technical team cares, that's Event Sourcing.

## Key Concepts
- **Entity**: a uniquely identified, mutable domain object whose individuality — not its attributes — is primary to its definition.
- **Local identity vs. global identity**: Entities inside an Aggregate need uniqueness only within it; the Aggregate Root needs global uniqueness.
- **Surrogate identity**: an ORM-only identity distinct from the domain identity, hidden behind a Layer Supertype.
- **Early / late identity generation**: assignment before persistence versus at persistence time.
- **Self-encapsulation**: "designing your classes so that all access to data, even from within the same class, goes through accessor methods" [Fowler].
- **Guard**: a precondition assertion inside a setter that throws rather than admit invalid state.
- **Intention-Revealing Interface** [Evans]: `activate()`/`deactivate()` rather than `setActive(boolean)` — the operation names come from the domain experts' words.
- **Object schizophrenia**: delegated objects don't know the identity of the originating object on which behavior was invoked.
- **Deferred Validation** [Cunningham, Checks]: detailed validation of a complex object or composition, postponed to the last possible moment.
- **ValidationNotificationHandler**: the collector that accumulates all validation failures instead of aborting at the first.
- **Layer Supertype** [Fowler, P of EAA]: an abstract base class (`IdentifiedDomainObject`, `Entity`) carrying cross-cutting concerns like surrogate id, optimistic concurrency, and `validate()`.

## Mental Models
- Use an Entity when you must ask "*which* one?"; use a Value Object when you only care "what is it?" If your Entities are mostly getters and setters, you have an entity-relationship model in Java, not a domain model.
- Think of identity as a Value Object with behavior: `APM-P-08-14-2012-F36AB21C` tells a human it is a Product from the Agile Project Management Context created 8/14/2012, and tells a developer which Bounded Context minted it.
- If DDD Entities feel like overkill for your problem, that's a signal — CRUD with Grails or Rails may genuinely be the cheaper, correct choice. Elaborately hand-built "glorified database table editors" are the expensive mistake.
- Treat validation as a *separate collaborator* on a *different change cadence* than the Entity — the Entity knows only that it can be validated.

## Anti-patterns
- **Anemic Domain Model** [Fowler]: doing entity-relationship modeling in Java, reflecting tables and columns into getter/setter objects — the trap CollabOvation fell into.
- **Trusting users to produce identity**: users misspell titles and later dislike them; if `Forum`/`Discussion` titles are the identity, correction is expensive. Prefer user-entered values as *matching properties*, not identity — or gate them behind an identity-approval workflow (viable only in low-throughput domains where human readability is a must).
- **Multiple public setters for one logical command**: intent becomes ambiguous and a single meaningful Domain Event can no longer be published.
- **Exposing the password (even encrypted) beyond the Aggregate boundary**: the only route to authentication must be the `AuthenticationService`.
- **Embedding validation logic in the Entity**: validation changes more often than the Entity and adds responsibility to an object already responsible for behavior and state.
- **Throwing on the first validation failure**: clients (and batch processes) need the complete set of results.
- **Forwarding delegation across role interfaces**: produces object schizophrenia; make role interfaces fine-grained and implement them on the Entity itself.
- **Overusing another Bounded Context's identity**: the local Entity's maintenance then depends on transitions in foreign systems — "use this approach as conservatively as possible."

## Code Examples

```java
public class User extends Entity {
    ...
    protected User(TenantId aTenantId, String aUsername,
            String aPassword, Person aPerson) {
        this();
        this.setPassword(aPassword);
        this.setPerson(aPerson);
        this.setTenantId(aTenantId);
        this.setUsername(aUsername);
        this.initialize();
    }

    protected void setPassword(String aPassword) {
        if (aPassword == null) {
            throw new IllegalArgumentException(
                   "The password may not be set to null.");
        }
        this.password = aPassword;
    }

    protected void setUsername(String aUsername) {
        if (this.username != null) {
            throw new IllegalStateException(
                    "The username may not be changed.");
        }
        if (aUsername == null) {
            throw new IllegalArgumentException(
                    "The username may not be set to null.");
        }
        this.username = aUsername;
    }
    ...
}
```
- **What it demonstrates**: construction by self-encapsulation — the constructor supplies every invariant-bearing attribute and delegates to setters whose guards enforce the contract; `setUsername()` additionally enforces identity stability as modify-once state, while still permitting Hibernate's single reconstitution assignment.

```java
public class Warble extends Entity {
    ...
    @Override
    public void validate(ValidationNotificationHandler aHandler) {
        (new WarbleValidator(this, aHandler)).validate();
    }
    ...
}
```
- **What it demonstrates**: the Entity decides *what* validates it without knowing *how* — the Validator (a Specification/Strategy) evolves at its own pace and reports every failure through the notification handler.

## Reference Tables

| Identity strategy | How it works | Use when | Watch out for |
|---|---|---|---|
| **User provides identity** | User types or selects a recognizable value; the application enforces uniqueness | Human-readable identity is essential and a review/approval workflow is affordable | Unique-but-wrong values; misspellings; users wanting to change what must be immutable; unusable in high-throughput domains |
| **Application generates identity** | UUID/GUID (`java.util.UUID.randomUUID()`, type 4 via `SecureRandom`, or type 3 name-based via `MessageDigest`), or a custom composite like `APM-P-08-14-2012-F36AB21C`; Factory is typically the Repository's `nextIdentity()` | Default choice; fast, no round trip, cacheable, safe across clustered/distributed nodes; supports early generation | 32/36-byte values are big and not human-readable — hide behind hypermedia link text; memory overhead in rare cases |
| **Persistence store generates identity** | Database sequence or auto-increment (2-, 4-, or 8-byte); Hibernate `<generator class="sequence">` or `native`; Riak `POST` without a key | Compact identities matter; referential integrity and tool support required | Round-trip performance; caching sequences loses values on restart (gaps); Hibernate's portable generator supports only *late* generation — early generation needs a custom query (Oracle `product_seq.nextval`, MySQL `LAST_INSERT_ID(next_val + 1)` via JDBC) |
| **Another Bounded Context assigns identity** | Exact match, or fuzzy "like search" against the external API with user selection; the chosen identity becomes the local identity, sometimes with copied state | Integration is unavoidable and the foreign system owns the concept | The most complex strategy: needs synchronization via Event-Driven Architecture and Domain Events, and translation of foreign concepts (not caching them). Use conservatively |

| Validation level | Mechanism | Where it lives |
|---|---|---|
| Attribute/property | Design-by-contract precondition **guards** in self-encapsulated setters | Inside the Entity/Value (`EmailAddress.setAddress()`: null, empty, ≤100 chars, regex format) |
| Whole object | **Validator** implementing Specification or Strategy, reporting to a `ValidationNotificationHandler` | Separate class in the same Module as the Entity |
| Object composition | **Deferred Validation** across a cluster of Entities/Aggregates | A Domain Service using Repositories, triggered when a Domain Event says the state is ripe |

## Worked Example
The Identity and Access Context team is handed five terse requirements:

> • Users exist in association with and under the control of a tenancy. • Users of a system must be authenticated. • Users possess personal information, including a name and contact information. • User personal information may be changed by the users themselves or by a manager. • User security credentials (passwords) may be changed.

**Step 1 — is it an Entity?** The repeated word **"change"** suggests one; the clincher is **"authenticated"** — finding one user among many demands unique identity. So `User` is an Entity. `Tenant` is *also* an Entity; the tenancy-control statement doesn't collapse them.

**Step 2 — fix the language.** "Users exist under the control of a tenancy" is vague: tenants own users but *don't collect and contain them*. Rewritten with the whole team:
> • Tenants allow for the registration of many users by invitation. • Tenants may be active or be deactivated. • Users of a system must be authenticated but can be authenticated only if the tenant is active.

That single restatement revealed registration-by-invitation, tenant activation state, and the dependency of authentication on tenant activity.

**Step 3 — identity and matching attributes.** `Tenant` gets an application-generated full UUID (guaranteed uniqueness *and* security — nobody can guess a subscriber's key), wrapped as a `TenantId` Value Object so every Entity in every Context can be "striped" with the correct tenant. Strong typing wins over a raw `String` even though the identity needs no Side-Effect-Free Functions. `Tenant` also gets a plain `String name` — no special behavior, but a help-desk worker must find a tenant by name, so it is an intrinsic characteristic. Billing, support contracts, and locations are pushed to other Contexts. `User` gets `username` (unique within a tenant, not across tenants) and `password` (never stored as clear text — which uncovers an `EncryptionService` Domain Service).

**Step 4 — reject a tempting model.** Should `username` + `password` form a `SecurityPrincipal` Whole Value used as identity? No: passwords change, and services must find a `User` without a password (e.g. to check a security `Role`). Note the idea for later; it isn't identity.

**Step 5 — behavior, test-first.** `private boolean active` reveals nothing; `setActive(boolean)` doesn't match the Language. Domain experts say *activate* and *deactivate*, so `Tenant` gets `activate()` and `deactivate()` — an Intention-Revealing Interface. Writing the test first surfaces a missing method:

```java
Tenant tenant = this.tenantFixture();
assertTrue(tenant.isActive());
tenant.deactivate();
assertFalse(tenant.isActive());
tenant.activate();
assertTrue(tenant.isActive());
```

`isActive()` is born. Considering "authenticated only if the tenant is active" then reveals an `AuthenticationService` Domain Service — something must check the Tenant before matching the User.

**Step 6 — defer what isn't clear.** `Invitation` is too fuzzy for the first rapid iteration, so it's postponed; but `registerUser()` is defined because it's essential to creating Users.

**Step 7 — Person.** "Personal" yields a `Person` class (an Entity, since a work phone number changing shouldn't replace the whole object) holding `Name` and `ContactInformation` Values. A developer asks: what if a `User` is a *system*? Rather than let clients navigate `User → Person` to execute behavior (forcing later client refactoring), the team models the personal behaviors *on* `User`, leaving `Person` exposed only for querying, so the accessor can later serve a `Principal` interface. `changePassword()` mirrors the requirement's wording, and the encrypted password is never exposed beyond the Aggregate.

## Key Takeaways
1. Choose an Entity only when individuality is a mandatory constraint; otherwise prefer a Value Object — and if the whole domain is really CRUD, use a CRUD tool and save the money.
2. Focus early Entity design solely on identity and the attributes used to find or match it; add supporting state and behavior afterward.
3. Wrap identity in a Value Object so identity behavior is centralized and identity stability is guaranteed by immutability.
4. Prefer application-generated identity (UUID via `repository.nextIdentity()`) with **early** generation — it keeps Domain Events valid, avoids the `java.util.Set` equality bug, and keeps `equals()`/`hashCode()` identity-based.
5. Keep the ORM's surrogate identity separate from and invisible to the domain, behind a Layer Supertype.
6. Enforce identity stability with modify-once guards that throw `IllegalStateException`, and prove it with a test.
7. Mine the Ubiquitous Language for Entities: "change" hints at mutability, search/authentication hints at identity; rewrite requirements with the team until they say something true.
8. Name operations from the domain experts' verbs (`activate()`, `deactivate()`, `changePassword()`), not `setX()` — one logical command, one Domain Event.
9. Validate at three levels — guards in setters, a Validator per whole object, Deferred Validation over compositions via a Domain Service — and always collect all failures through a notification handler.
10. Track change with Domain Events saved to an Event Store when domain experts care about specific occurrences; use Event Sourcing when only the technical team does.

## Connects To
- **ch01**: the Ubiquitous Language is the source of Entity names, attributes, operations, and the glossary that grows alongside the model.
- **ch02**: Bounded Context and Core Domain — identity assigned by another Bounded Context; `Tenant`/`User` came out of untangling the security concerns.
- **ch03**: Context Maps — foreign identity requires translation of foreign concepts, not local caching.
- **ch04**: Event-Driven Architecture and Event Sourcing — synchronizing with externally owned Entities, and change tracking beyond what experts ask for.
- **ch06**: Value Objects — identity holders, `Name`, `ContactInformation`, `EmailAddress`; the immutability that makes identity stable, and Side-Effect-Free Functions.
- **ch07**: Domain Services — `EncryptionService`, `AuthenticationService`, and the coordinator for Deferred Validation across Aggregates.
- **ch08**: Domain Events and the Event Store — published on every state-altering command; the reason identity must be generated early.
- **ch09**: Modules — Validators and Layer Supertypes live in the Entity's Module so package-scope accessors suffice.
- **ch10**: Aggregates — Roots require globally unique identity, invariants must hold transactionally, and optimistic concurrency rides on a Layer Supertype.
- **ch11**: Factories — `Tenant.registerUser()` as a Factory method with a `protected` `User` constructor.
- **ch12**: Repositories — the natural home of `nextIdentity()`.
- **ch13**: Integrating Bounded Contexts — synchronizing local Entities with foreign state changes.
- **Design by contract (Meyer) / Checks pattern language (Cunningham) / Specification (Evans & Fowler)**: the external foundations of the three validation levels.
