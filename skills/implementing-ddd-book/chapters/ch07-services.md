# Chapter 7: Services

## Core Idea
"Sometimes, it just isn't a thing." When a significant process, transformation, or calculation is not the natural responsibility of an Entity or Value Object, model it as a stateless Domain Service named in the Ubiquitous Language — but only after proving that no Entity or Value can carry the behavior, because overusing Services produces an Anemic Domain Model.

## Frameworks Introduced
- **Domain Service** (Evans): "When a significant process or transformation in the domain is not a natural responsibility of an ENTITY or VALUE OBJECT, add an operation to the model as a standalone interface declared as a SERVICE. Define the interface in terms of the language of the model and make sure the operation name is part of the UBIQUITOUS LANGUAGE. Make the SERVICE stateless."
  - When to use — three qualifying situations: (1) perform a significant business process; (2) transform a domain object from one composition to another; (3) calculate a Value requiring input from more than one domain object.
  - How: (1) confirm the operation feels out of place on any Aggregate or Value; (2) name the Service and its operation from the Ubiquitous Language of its Bounded Context; (3) place it in the same Module as the Aggregates it concerns; (4) keep it stateless — no instance state carried between calls; (5) let it use Repositories freely (Aggregates should not); (6) return a Value Object, not a whole Aggregate, where a lean result suffices; (7) make an Application Service its client.
  - Why it works / failure mode: it pulls domain knowledge out of clients and back into the model, where the Ubiquitous Language governs it. Failure mode: reaching for it as a silver bullet, which drains Entities and Values of behavior → Anemic Domain Model.

- **Make Sure You Need a Service** (the caution): don't lean toward Services; model one only if the circumstances fit. Diagnostic sequence used for authentication — try the behavior on an Entity, watch the client accumulate domain knowledge, watch responsibilities violate Single Responsibility, and only then introduce the Service.
  - How to run the check: (1) write the client code you'd need if the behavior lived on an Entity; (2) ask how much a client must *understand* to invoke it; (3) ask whether the Ubiquitous Language is stated explicitly ("authenticate", not "isAuthentic"); (4) ask whether any Entity would gain responsibilities outside its own concept (a `Tenant` learning about password encryption); (5) if the answers point outward, the operation belongs in a Domain Service.

- **Separated Interface [Fowler, P of EAA] — optional, not obligatory**: declare the Service interface in the domain model Module and place a technical implementation in Infrastructure (per Dependency Inversion Principle / Hexagonal).
  - When to use: the Service has a technical implementation, or genuinely multiple specialized implementations (`EncryptionService` in the domain, `MD5EncryptionService` in infrastructure).
  - When to skip: purely domain-specific Services such as calculations, which will only ever be implemented one way. SaaSOvation dropped the Separated Interface and shipped `AuthenticationService` as a plain class.
  - How to decide: if the only name you can invent for the implementation is `XxxServiceImpl`, that's strong evidence you don't need a Separated Interface. If you do split, name each implementation for its specialty — the need to name specialties is proof specialties exist in your domain.
  - Note: skipping it does not weaken testability — dependencies can be injected, resolved by a Service Factory (`DomainRegistry`), or passed as constructor/method parameters.

- **Mini-layer of Domain Services**: a thin layer of Domain Services sitting above the Entities and Value Objects of the model.
  - When to use: rarely, and only when the domain's characteristics support it — Vernon cites the Identity and Access Context, where it is genuinely helpful.
  - How: (1) confirm the model still holds behavior in its Entities and Values; (2) keep transactions and security *out* — those are Application Service concerns; (3) test every calculation Service for correctness. Default expectation: this path usually leads to Anemic Domain Model, which is an anti-pattern.

## Key Concepts
- **Domain Service**: a stateless operation in the domain model fulfilling a domain-specific task, expressed in the Ubiquitous Language.
- **Application Service**: the natural client of the domain model — coordinates tasks, controls transactions and security, and holds *no* business logic.
- **Anemic Domain Model [Fowler]**: an anti-pattern in which all domain logic lives in Services and Entities/Values are mere data holders.
- **Calculation process**: a Domain Service that derives a Value from state spread across many Aggregates of a type.
- **Transformation Service**: the more technical, integration-oriented Domain Service, implemented in Infrastructure with Adapters and translators.
- **Separated Interface**: interface in the model, implementation elsewhere, so a client depending on the interface stays unaware of the implementation.
- **`DomainRegistry`**: a Service Factory that decouples clients from Service implementations without requiring a Separated Interface.
- **`UserDescriptor`**: a small, secure Value Object returned instead of a full `User` — suitable for a per-user Web session.

## Mental Models
- Use a Domain Service when a static method on an Aggregate Root starts to look attractive — that impulse is a DDD code smell, and the Service is the intended tool.
- Think of the split this way: **Application Service coordinates, Domain Service knows.** If the code contains a rule, a derivation, or a policy, it belongs in the Domain Service; if it only fetches, delegates, and commits, it belongs in the Application Service.
- Judge a design by what the *client* must understand: any domain knowledge visible in the client (encrypting a password, checking a tenant is active) is knowledge that leaked out of the model.
- Repositories flow *downward* into Services, not *upward* into Aggregates: a Service may use Repositories; an Aggregate instance should not.

## Anti-patterns
- **Static method on an Aggregate Root** (`Product.businessPriorityTotals(Set<BacklogItem>)`): a code smell; it has no natural home and signals a missing Domain Service.
- **Repository access from inside an Aggregate**: avoid it as a rule of thumb; refactor the operation into a Domain Service that owns the Repository call.
- **Business logic in an Application Service**: even a trivial summation, or deriving `totalValue = totalBenefit + totalPenalty`, is domain logic and must not leak into the Application Layer.
- **Overzealous Services / mini-layer by default**: yields Anemic Domain Model.
- **Domain knowledge dumped on the client**: making the client fetch the `Tenant`, check `isActive()`, encrypt the password, then compare — the client should coordinate exactly one domain-specific operation.
- **Naming the implementation `XxxServiceImpl`** in the same package as the interface: signals either an unnecessary Separated Interface or an unconsidered name.
- **Transactions or security inside Domain Services**: application concerns wrongly pushed into the model.

## Code Examples
```java
public class BusinessPriorityCalculator {
    public BusinessPriorityTotals businessPriorityTotals(
            Tenant aTenant, ProductId aProductId) {
        int totalBenefit = 0, totalPenalty = 0, totalCost = 0, totalRisk = 0;

        java.util.Collection<BacklogItem> outstandingBacklogItems =
            DomainRegistry.backlogItemRepository()
                .allOutstandingProductBacklogItems(aTenant, aProductId);

        for (BacklogItem backlogItem : outstandingBacklogItems) {
            if (backlogItem.hasBusinessPriority()) {
                BusinessPriorityRatings ratings =
                    backlogItem.businessPriority().ratings();
                totalBenefit  += ratings.benefit();
                totalPenalty  += ratings.penalty();
                totalCost     += ratings.cost();
                totalRisk     += ratings.risk();
            }
        }
        return new BusinessPriorityTotals(
                totalBenefit, totalPenalty,
                totalBenefit + totalPenalty, totalCost, totalRisk);
    }
}
```
- **What it demonstrates**: a calculation-process Domain Service — stateless, uses a Repository (which an Aggregate must not), aggregates Values across many Aggregates, and keeps the derived `totalValue` computation inside the domain rather than in the Application Layer.

## Reference Tables

| | Domain Service | Application Service | SOA / remote service |
|---|---|---|---|
| Contains business logic | Yes | **No** | No (it's a facade) |
| Lives in | Domain model Module (impl may be Infrastructure) | Application Layer | Infrastructure / boundary |
| Typical client | Application Service | User Interface, remote client | Other systems |
| Controls transactions & security | No | **Yes** | N/A |
| Granularity | Fine-to-medium, may span several Aggregates atomically | Task coordination | Coarse-grained, remote-capable, RPC/MoM |
| Stateless | Required | Typically | Varies |

| Decision | Rule |
|---|---|
| Behavior fits naturally on an Aggregate/Value? | Put it there — no Service. |
| Needs input from more than one domain object? | Domain Service. |
| Needs a Repository? | Domain Service (never the Aggregate). |
| Only one, purely domain-specific implementation? | Plain class; no Separated Interface. |
| Technical implementation or multiple specialties? | Separated Interface, implementation in Infrastructure, named for its specialty. |

## Worked Example
**Authenticating a `User` in the Identity and Access Context.** Requirements: users must be authenticated but only if the tenant is active; passwords are stored encrypted; users can be authenticated only if enabled.

*Attempt 1 — behavior on the Entity.* The client finds the `User` via its Repository and calls `user.isAuthentic(aPassword)`. Problems: the client must understand what authenticating means; the Language is wrong ("is authentic" instead of "authenticate"); and the tenant-active rule is simply missing.

*Attempt 2 — move `authenticate()` onto `Tenant`.* The client now fetches the `Tenant`, checks `isActive()`, fetches the `User`, and calls `tenant.authenticate(user, aPassword)`. The tenant rule is honored, but the client carries even more domain knowledge — and password encryption has nowhere good to go. Four undesirable options, all rejected:
1. `Tenant` encrypts and passes the encrypted password to `User` — violates `Tenant`'s Single Responsibility.
2. `User` authenticates from clear text — authentication becomes a facade on `Tenant` implemented on `User`, and `User` needs a protected interface to hide it.
3. `Tenant` asks `User` to encrypt, then compares — extra steps, untidy collaborations, `Tenant` still knows authentication details.
4. The client encrypts — the client should know nothing about encryption at all.

*Resolution — a Domain Service.* The client's only responsibility becomes coordinating one domain-specific operation:

```java
UserDescriptor userDescriptor =
    DomainRegistry.authenticationService()
        .authenticate(aTenantId, aUsername, aPassword);
```

`AuthenticationService.authenticate()` guards against null parameters, fetches the `Tenant` and checks `isActive()`, encrypts the clear-text password through `EncryptionService`, retrieves the `User` from the Repository *filtered on tenant + username + encrypted password*, confirms `user.isEnabled()`, and returns a lean `UserDescriptor` Value (tenantId, username, emailAddress) — or `null`. Returning `null` rather than throwing declares that failed authentication is a normal domain possibility, not an exceptional error; had the team judged it exceptional, they'd have thrown `AuthenticationFailedException`.

Tests then document the contract from the client's perspective: `testAuthenticationSuccess` asserts the `UserDescriptor` fields match the fixture `User`; `testAuthenticationTenantFailure`, `testAuthenticationUsernameFailure`, and `testAuthenticationPasswordFailure` each assert `null`.

**Parallel case (the Core Domain).** `Product` originally composed `BacklogItem` instances, so `businessPriorityTotals()` was a simple instance method. When `BacklogItem` was promoted to its own Aggregate, the team's first instincts — call `BacklogItemRepository` from inside `Product`, then make the method static and pass the collection in — were both rejected by the senior mentor. The answer was the `BusinessPriorityCalculator` Domain Service, consumed by a private method of the `ProductService` Application Service.

## Key Takeaways
1. Recognize the smell: wanting a static method on an Aggregate Root means you need a Domain Service.
2. Qualify the Service against the three reasons — significant process, transformation, or multi-object calculation — before creating it.
3. Keep Services stateless and name both the type and its operation from the Ubiquitous Language of the Bounded Context.
4. Never put business logic in an Application Service; make the Application Service the *client* of the Domain Service and let it own the transaction.
5. Domain Services may use Repositories; Aggregate instances should not.
6. Return small Values (`UserDescriptor`) rather than exposing full Aggregates to clients.
7. Treat Separated Interface as a decoupling decision, not a habit — use it for technical or multi-implementation Services, and name implementations for their specialty rather than `Impl`.
8. Overusing Services yields an Anemic Domain Model; the mini-layer of Domain Services is a rare, justified exception, not a default.

## Connects To
- **ch05**: the authentication analysis starts from the Entity design deferred in Entities; guards and Assertions carry over.
- **ch06**: Domain Services return and consume Value Objects (`UserDescriptor`, `BusinessPriorityTotals`), and can supply Standard Types.
- **ch04**: Dependency Inversion Principle and Hexagonal Architecture decide where the implementation class lives; SOA services are explicitly *not* Domain Services.
- **ch09**: place the Service in the same Module as the Aggregates whose concepts it expresses.
- **ch10**: the breakup of the large `Product` Aggregate is what created the need for the calculator Service.
- **ch12**: Repositories are used from Services, not from Aggregates.
- **ch13**: Transformation Services — the integration-oriented, Infrastructure-resident Services with Adapters and translators.
- **ch14**: Application Services own transactions and security and act as clients of Domain Services.
- **Single Responsibility Principle [Martin] / Anemic Domain Model [Fowler] / Separated Interface [Fowler, P of EAA] / Adapter & Factory [Gamma et al.]**: the external principles the chapter argues from.
