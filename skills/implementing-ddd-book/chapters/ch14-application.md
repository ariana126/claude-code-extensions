# Chapter 14: Application

## Core Idea
An *application* is the finest set of components assembled around a Core Domain model: user interface, Application Services, and infrastructure. Keep Application Services thin — they coordinate tasks, transactions, and security only — and choose deliberately among the several ways to get model state onto the glass and user gestures back into the model.

## Frameworks Introduced

- **Render Data Transfer Object from Aggregate Instances**: the Application Service reads Aggregates via Repositories and a *DTO Assembler* [Fowler, P of EAA] flattens their attributes into one view-shaped DTO.
  - When to use: the presentation tier is physically remote from the business tier and data must be serialized over the wire; or lazy-loaded collections must be resolved before the transaction closes.
  - How: (1) define a DTO holding every attribute the view needs; (2) Application Service loads each Aggregate by Repository; (3) DTO Assembler reads Aggregate state into the DTO; (4) serialize/transfer; (5) view reads DTO attributes only.
  - Why it works / failure mode: it resolves lazy loads because the Assembler touches everything. But in a single-VM architecture it is YAGNI — accidental complexity, near-duplicate classes shadowing domain objects, and large short-lived objects churning the garbage collector.

- **Use a Mediator to Publish Aggregate Internal State**: instead of letting clients navigate into an Aggregate, the client implements an "interest" (Mediator / Double-Dispatch / Callback) interface and the Aggregate double-dispatches its state onto it.
  - When to use: you need to expose Aggregate state for rendering without coupling clients to the Aggregate's internal shape or structure.
  - How: (1) define a narrow `XxxInterest` interface with `informY(...)` methods; (2) client implements it; (3) client passes itself to `provideXxxInterest(anInterest)`; (4) the Aggregate calls `inform*` for each state of interest; (5) never let the interface reflect a *view* specification — keep it about Aggregate state.
  - Why it works / failure mode: the Aggregate keeps control of what it reveals, and shape changes don't ripple. Failure mode: teams disagree whether this is an Aggregate responsibility at all — decide as a team.

- **Render Aggregate Instances from a Domain Payload Object (DPO)** [Vernon, DPO]: a payload container holding references to *whole Aggregate instances*, not copied attributes.
  - When to use: single-VM architecture where DTOs are unnecessary but you still need to move a cluster of model objects from the Application Layer to the view.
  - How: (1) Application Service loads Aggregates via Repositories; (2) instantiates the DPO holding the references; (3) presentation asks the DPO for Aggregates and the Aggregates for viewable state; (4) resolve lazy loads before the transaction commits — eager fetch, or a **Domain Dependency Resolver** [Vernon, DDR] (a Strategy, one per use case flow, that forces access to every lazy property the flow consumes).

- **Use Case Optimal Repository Queries**: design Repository finder methods that compose a superset of one or more Aggregates directly into a Value Object shaped for the use case.
  - When to use: rendering needs a custom projection and you'd otherwise load several whole Aggregates just to recombine them.
  - How: (1) name the finder for the use case; (2) return a Value Object (not a DTO) because the query is *domain* specific, not application specific; (3) query the unified domain persistence store, not a separate read store; (4) the view renderer consumes the Value Object directly. Note: once you are here you are one step from CQRS — consider going all the way.

- **Data Transformer (decoupled service output)**: the client passes a Transformer to the Application Service, which double-dispatches on it to produce the client's required format.
  - When to use: multiple disparate clients (RIA, thick client, REST, messaging, test drivers) need the same use case in different representations.
  - How: (1) define `XxxDataTransformer` interface; (2) implement per format (`...XMLDataTransformer`, `...JSONDataTransformer`, `...CSVDataTransformer`, `...DPO/DTODataTransformer`); (3) service method takes the Transformer parameter and returns an `XxxData` whose `value()` answers the format; (4) inject the Transformer rather than hard-coding it.

- **Void Application Services with a standard output Port**: declare every Application Service method `void` and `write()` results to a named output Port; registered readers adapt the output per client (Hexagonal / Ports and Adapters).
  - When to use: you want zero coupling between the Application Layer and any client's data type.
  - How: (1) inject a named output Port into the service; (2) after delegating to the model, `write()` the result; (3) each client registers a reader ahead of invocation; (4) readers transform via Data Transformers. Trade-off: query method names get awkward — `tenant()` becomes `findTenant()` since it no longer answers anything.

## Key Concepts
- **Application**: the finest set of components assembled to interact with and support a Core Domain model — model, UI, Application Services, infrastructure.
- **Application Service**: direct client of the domain model; one method per use case flow; owns task coordination, transaction control, and security — never business logic.
- **Domain Service**: holds the "significant process . . . in the domain" [Evans]; the Application Service delegates to it.
- **Domain Payload Object (DPO)**: container of references to whole Aggregate instances for transfer between logical layers in one VM.
- **Domain Dependency Resolver**: per-use-case Strategy that forces resolution of lazy-loaded Aggregate state before the transaction commits.
- **Presentation Model / View Model** [Fowler, PM]: an Adapter that derives view-specific properties and indicators from model state and tracks user edits.
- **Command object** [Gamma et al.]: a named, serialized method invocation carrying only basic types; replaces long Application Service parameter lists.
- **Command Handler**: semantically equivalent to an Application Service method, but temporally decoupled via a queue.
- **Service Factory / Registry**: `ApplicationServiceRegistry` / `DomainRegistry` beans giving lookup access to services and Repositories where injection isn't used.
- **Enterprise component container**: EJB Session Facades or IoC-hosted JavaBeans (Spring) that host Application Services; logical differences between containers are minimal.

## Mental Models
- Think of the UI's job as two questions only: *how do we render domain objects onto the glass* and *how do we communicate user gestures back to the model*. Every pattern in this chapter answers one or the other.
- The UI usually renders properties of **many** Aggregate instances but should submit a state-mutating request against **one** instance of one type.
- Use a Presentation Model when you need a bidirectional Adapter: it turns `summary()` into `getSummary()` for frameworks that demand JavaBean getters, and turns user edits back into a single Application Service call.
- Treat REST resources as a separate View Model, not a mirror of your Aggregates — represent *use cases*, not Aggregate state.
- Use `void` + output Port when you'd otherwise let client data types dictate your service API; an Aggregate publishing a Domain Event is the same idea one layer down (the Domain Event Publisher is the Aggregate's output Port).

## Anti-patterns
- **Domain logic leaking into the Application Service**: if `provisionTenant()` did more than delegate — e.g. also assigned an administrator and published events — the model would be gutted. Push it into a Domain Service.
- **Presentation Model as a heavy Facade**: several lines managing detailed Application Service usage, or acting as the Application Service itself, exceeds its responsibility. Delegate in one call.
- **DTOs in a single-VM architecture**: accidental complexity plus memory churn for objects that only shadow the model.
- **Letting Assemblers navigate deeply into Aggregates**: tightly couples every client to one Aggregate's internal implementation.
- **One-to-one REST representations of Aggregate state**: clients must then understand your model's state transitions and subtleties, and you lose all benefit of abstraction.
- **Nine-parameter service methods**: replace with a Command object.
- **Accidental Bounded Context in the Application Layer**: composing three models by merging DTOs produces an Anemic Domain Model driven by Transaction Script. Decide explicitly whether it should become a real unified Domain Model.

## Code Examples
```java
public class BacklogItem ... {
     public void provideBacklogItemInterest(
              BacklogItemInterest anInterest) {
          anInterest.informTenantId(this.tenantId().id());
          anInterest.informProductId(this.productId().id());
          anInterest.informBacklogItemId(this.backlogItemId().id());
          anInterest.informStory(this.story());
          anInterest.informSummary(this.summary());
          anInterest.informType(this.type().toString());
     }

     public void provideTasksInterest(TasksInterest anInterest) {
          Set<Task> tasks = this.allTasks();
          anInterest.informTaskCount(tasks.size());
          for (Task task : tasks) { ... }
     }
 }
```
- **What it demonstrates**: the Aggregate publishes state by double-dispatch onto a Mediator interest, revealing values without revealing shape or structure.

```java
public class TenantIdentityService {
     @Transactional
     @PreAuthorize("hasRole('SubscriberRepresentative')")
     public void deactivateTenant(TenantId aTenantId) {
         this.nonNullTenant(aTenantId).deactivate();
     }

     private Tenant nonNullTenant(TenantId aTenantId) {
         Tenant tenant = this.tenant(aTenantId);
         if (tenant == null) {
             throw new IllegalArgumentException("Tenant does not exist.");
         }
         return tenant;
     }
 }
```
- **What it demonstrates**: a thin Application Service — declarative transaction, declarative method-level security, a guard, and one delegation to the model.

## Reference Tables

### Ways to render domain objects onto the UI

| Approach | Carries | Best when | Advantages | Costs |
|---|---|---|---|---|
| **DTO + DTO Assembler** | copied attributes | presentation tier is remote; serialization required | resolves lazy loads; hides model from view | YAGNI in one VM; near-duplicate classes; GC pressure; Assembler may couple to Aggregate internals |
| **Mediator / Double-Dispatch interest** | state pushed to a callback | you must expose state without exposing shape | zero client coupling to Aggregate structure; composable with DTO/DPO | extra interfaces; contested as an Aggregate responsibility |
| **Domain Payload Object (DPO)** | references to whole Aggregates | single-VM architecture, no serialization | simplest to design; small memory footprint; reuses already-loaded objects | lazy loads unresolved at commit → needs eager fetch or Domain Dependency Resolver; still needs a state-reading mechanism |
| **State representations (REST)** | use-case-shaped representations | REST resources / remote clients | clients decouple from the model; a real View Model | must resist mirroring Aggregate state; a second model to maintain |
| **Use case optimal query** | Value Object from a custom Repository finder | view needs a superset of Aggregates | no whole-Aggregate loading; no assembly code; domain-specific | proliferating finders; you're nearly at CQRS anyway |
| **Presentation Model** | view-derived properties + edit tracking | Web 2.0 RIA or desktop clients | bidirectional Adapter; derives view indicators; adapts non-getter models | can bloat into a Facade if undisciplined |

### Application Service vs Domain Service

| | Application Service | Domain Service |
|---|---|---|
| Responsibility | task coordination of one use case flow | significant business process that doesn't belong to one Entity/Value Object |
| Business logic | none — keep it thin | yes, this is where it lives |
| Transactions | controls them (ACID) | no |
| Security | commonly enforces it (e.g. `@PreAuthorize`) | no |
| Publishes Domain Events | no | yes |
| Typical body | guard, delegate, return/write | multi-step model orchestration |

## Worked Example
`provisionTenant()` walked end-to-end. Naively the Application Service would create the `Tenant`, add it to the Repository, assign an administrator, provision the Administrator role, and publish `TenantAdministratorRegistered` and `TenantProvisioned`. That leaks the model. Instead, all three steps — (1) instantiate `Tenant` and add to Repository, (2) assign administrator and provision the Administrator role, publishing `TenantAdministratorRegistered`, (3) publish `TenantProvisioned` — go into the Domain Service `TenantProvisioningService`. The Application Service keeps only `@Transactional`, `@PreAuthorize("hasRole('SubscriberRepresentative')")`, and one delegation.

Then the parameter list is attacked: nine parameters is at least a few too many, so a `ProvisionTenantCommand` of basic types is introduced with both a multi-arg and a zero-arg constructor plus setters, so UI form-field mappers can populate it. It is more than a DTO because it is *named for the operation*. The same Command can be dispatched directly to the service method, or queued to a Command Handler — semantically the same method, temporally decoupled, which buys throughput and scalability (see Appendix A).

Finally the return type is attacked: exposing `Tenant` couples every client to the model, so either pass a `TenantDataTransformer` and answer `TenantData`, or make the method `void` and `write()` the `Tenant` to a named output Port whose registered readers adapt it per client.

## Key Takeaways
1. Keep Application Services thin — task coordination, transactions, security — and push all business logic into Aggregates, Value Objects, or Domain Services.
2. One Application Service method per use case flow; if the body grows past guard-and-delegate, a Domain Service is missing.
3. Pick a rendering approach by architecture, not fashion: DTOs only when the presentation tier is genuinely remote; DPOs in a single VM; use case optimal queries when you're comfortable heading toward CQRS.
4. Never let clients navigate deeply into Aggregates — publish state via a Mediator interest or an Aggregate Root query interface.
5. Replace long parameter lists with Command objects named for the operation; the same object works synchronously or through a queued Command Handler.
6. Support disparate clients with Data Transformers, or go further and make services `void` with a single output Port and per-client adapters — accepting that query method names get awkward.
7. Apply DIP throughout: infrastructure implements interfaces owned by UI, Application Services, and the domain model — so Repository implementations live in infrastructure while the interface lives in the model.
8. When one UI composes several Bounded Contexts, prefer a single Application Layer for composition — but recognize it is a bargain-basement Bounded Context with a built-in Anticorruption Layer, and decide consciously whether it deserves a real unified Domain Model.

## Connects To
- **ch04 (Architecture)**: Layers, Hexagonal Ports and Adapters, REST, and CQRS all determine where Application Services live and how output is decoupled.
- **ch07 (Services)**: the Application Service vs Domain Service distinction, and Service Factory vs Dependency Injection.
- **ch08 (Domain Events)**: writing to an output Port is the Application Layer analogue of an Aggregate publishing through the Domain Event Publisher.
- **ch09 (Modules)**: naming presentation/application Modules for a composed context, e.g. `com.consumerhive.productreviews.application`.
- **ch10 (Aggregates)**: the UI renders many Aggregate instances but mutates one; Aggregate design must permit state reading without shape exposure.
- **ch12 (Repositories)**: transaction control, use case optimal queries, and the trade-offs against CQRS read stores.
- **ch13 (Integrating Bounded Contexts)**: programmatic/API "user interfaces" are covered there, not here.
- **Appendix A (A+ES)**: queued Command Handlers as temporally decoupled Application Service methods.
- **Fowler, P of EAA / GoF**: DTO, DTO Assembler, Presentation Model, Separated Interface; Mediator, Adapter, Strategy, Command, Facade.
