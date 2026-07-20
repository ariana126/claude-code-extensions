# Chapter 12: Architectural layers

## Core Idea
MVC — even with a service layer bolted on — can't tell you where things go. Use three layers (**Domain**, **Application**, **Infrastructure**), enforce the **Dependency rule** ("source code dependencies should only point inwards"), express layers as namespaces, and let a tool verify it.

## Frameworks Introduced

- **The three layers, and exactly what goes in each:**

  | Layer | Contains | Code type |
  |---|---|---|
  | **Domain** | Entities, value objects, domain events, entity (write model) repository **interfaces**, domain services | Core |
  | **Application** | Application services / command handlers, command DTOs, view model repository **interfaces**, view model DTOs, event subscribers, interfaces for infrastructure services | Core |
  | **Infrastructure** | Web controllers, CLI commands, write **and** read model repository *implementations*, services connecting to external systems, services using time or randomness, the service container | Infrastructure |

- **The Dependency rule** (Robert C. Martin) — "source code dependencies [between layers] should only point inwards."
  - "The word 'inwards' hints at drawing layers as concentric circles instead of horizontal blocks."
  - Allowed: Infrastructure → Application, Infrastructure → Domain, Application → Domain. Never the reverse.
  - The relationship to class-level design: "For class-level dependencies we have the **Dependency inversion principle**… For layer-level dependencies, we have the **Dependency rule**." Apply the former and you satisfy the latter.

- **The four questions the Application layer must answer at a glance:**
  1. **What actors can do** with your application, and what data each task needs (application services + their parameters / command DTOs).
  2. **What an actor can learn** from your application (view model repository interfaces + view model objects).
  3. **How use cases connect to each other** (event subscribers).
  4. **What in the outside world your use cases depend on** (interfaces for infrastructure services).

- **Data direction ≠ dependency direction** — the distinction that makes layering work.
  - Runtime flow: framework → controller (Infra) → application service (App) → entity (Domain) → repository implementation (Infra).
  - "So when an application service saves an entity, the data flows from the `Application` layer to the `Infrastructure` layer. But the application service class doesn't depend on an infrastructure class, it depends on an abstraction: the repository interface that lives in the `Domain` layer."

- **Namespaces as the visible form of layers** — with a substructure per layer:
  - `Domain\Model\<Aggregate>\…` and `Domain\Service\…` (structure taken from Vaughn Vernon's *Implementing DDD*; "this is really just an example… You and your team can always settle on a different structure").
  - `Application\<UseCasePhrase>\…` — one sub-namespace per use case, holding the application service, command DTO, view model repository interface, and view model object. **"Make sure to include use cases for performing tasks (e.g. `CreateOrder`) as well as use cases that are about retrieving information (e.g. `ListAvailableEbooks`)."**
  - `Infrastructure\…` — structured by how the application connects to the outside world (completed in Ch 13).

- **Automated verification with `deptrac`** — map namespaces to layers, declare allowed dependency directions, run it in the build.
  - What it *can't* do: "As far as I know, there is no tool that can perform an 'is this core or infrastructure code' check, meaning there is no tool to verify that code is in the correct layer."
  - What it *can* do: catch every Dependency rule violation.

## Key Concepts
- **Layer** — "a way of grouping things"; once grouped, you can "state the desired properties of these layers."
- **Dependency rule** — inward-only source code dependencies between layers.
- **Dependency inversion principle** — the class-level counterpart: depend on abstractions, not concretions.
- **Domain service** — a Domain-layer service; belongs beside entities and value objects.
- **Command DTO** — Application layer, not Domain, not Infrastructure.
- **Concentric circles** — the drawing convention that makes "inwards" meaningful.
- **"Manager"** — the anti-pattern name for a service that grew unmanageable.

## Mental Models
- **A layer is nothing — and that's the point.** "You won't find a layer in your code, nor in your running application… But once we've made this grouping, we can state the desired properties of these layers. That's why layering is an architectural activity."
- **Layers are a decision aid before they're a constraint.** "They provide broad categories for your code, helping you find the right place for each class."
- **The layer test is just Chapter 1's two rules.** "If you don't want it to be infrastructure code, you can refactor it using any of the techniques demonstrated in Part I. After doing so you are 'allowed' to move the code to one of the other layers."
- **Domain objects are implementation details of the Application layer.** "Most of these details should stay behind the application layer. The infrastructure layer generally shouldn't be concerned with anything that's going on in the domain layer." Controllers deal in primitives and DTOs; only the Application layer knows the rich domain objects.
- **The Domain/Application split is optional — and Noback says so.** "The separation between application and domain code is not strictly necessary, and doesn't improve either of these quality aspects [testability, life expectancy]. However, I like to keep the distinction because it helps me clarify what the use cases of my application are… Without a separate application layer… The reader would see entities, but wouldn't know what an actor could do with them. They would see a repository, but they wouldn't know if the information exposed by it will end up being presented to a user, or if it's only for internal use."
- **Don't document the architecture separately.** Three unanswerable questions: "Does everybody really read the documentation? Will they be able to understand it, and apply it to their own contributions? Who will make sure the documentation gets updated if it needs to?" Instead: "make sure the use of layers is apparent from the moment you take your first look at the code."
- **The dual payoff of inward-only dependencies.** For the architect: "you can reconnect your application to different types of actors without affecting the classes that are in the `Application` or `Domain` layer." For the developer: "all the business logic… can be tested in isolation from its surrounding infrastructure, by replacing only a few infrastructure implementations with fast and predictable test doubles."

## Anti-patterns
- **MVC as an architecture**: "there is just too much that doesn't have a natural place within the categories of models, views, and controllers." Notably, it can't separate a use case's primary action from its secondary effects.
- **Fat controllers**: "controllers end up containing all the business logic for a given use case, and the model is likely going to be a simple data holder."
- **The failed service-layer rescue** — three compounding mistakes:
  1. Extracted services "aren't truly decoupled from the framework. They still rely on the session, or the current web request."
  2. They mix domain logic with persistence logic for one concept, so they "grow too large and become unmanageable" (the "manager").
  3. "Domain models still remain simple data holders and can't protect any of their invariants, nor implement any business rule all by themselves. This again results in services that have too much to do."
  - "The reason to start using services is a good one… but usually it's the implementation that's lacking."
- **Services doing everything in one method**: "large methods that start processing a request and perform all of the secondary tasks in the same method (or if you're 'lucky' in private methods of the same class). These services may even reach out to remote parts of the code base to do remotely related jobs."
- **An entity in `Infrastructure\Entity`**: wrong namespace, wrong layer.
- **An HTTP client injected into an Application-layer class**: infrastructure leaking upward.
- **A Domain class importing from Infrastructure**: `use Infrastructure\ExchangeRateProvider;` inside `Domain\Service\CurrencyConverter` — a textbook Dependency rule violation.
- **Documenting layers on a wiki page**: unread, unapplied, unmaintained.

## Code Examples

Three violations a tool can catch from `namespace` and `use` statements alone:

```php
namespace Infrastructure\Entity;

/** An entity doesn't belong in the Infrastructure layer */
final class Order
{
    // ...
}
```

```php
namespace Application\RegisterUser;

final class WelcomeEmail
{
    public function __construct(Client $httpClient)
    {
        /** An HTTP client doesn't belong inside the Application layer */
        $this->httpClient = $httpClient;
    }
}
```

```php
namespace Domain\Service;

/** A Domain class should not depend on a class from the Infrastructure layer */
use Infrastructure\ExchangeRateProvider;

final class CurrencyConverter
{
    private $exchangeRateProvider;

    public function __construct(ExchangeRateProvider $exchangeRateProvider)
    {
        $this->exchangeRateProvider = $exchangeRateProvider;
    }
}
```

- **What it demonstrates**: the third is the interesting one. `CurrencyConverter` is a legitimate domain service and *should* depend on an exchange-rate provider — but on an **interface** defined in Domain or Application, never on the Infrastructure implementation.

`deptrac` configuration — the whole ruleset in nine lines:

```yaml
paths:
  - ./src

layers:
  - name: Infrastructure
    collectors:
      - type: className
        regex: .*\\Infrastructure\\.*
  - name: Domain
    collectors:
      - type: className
        regex: .*\\Domain\\.*
  - name: Application
    collectors:
      - type: className
        regex: .*\\Application\\.*

ruleset:
  Infrastructure:
    - Application
    - Domain
  Application:
    - Domain
  Domain:
    # nothing
```

- **What it demonstrates**: `Domain: # nothing` is the strongest line in the file — the innermost layer is allowed to depend on no other layer at all.

## Reference Tables

**Which layer? (the chapter's exercise answers)**

| Class type | Layer |
|---|---|
| Entity | Domain |
| Value object | Domain |
| Domain event | Domain |
| Entity / write model repository **interface** | Domain |
| Domain service | Domain |
| Application service / command handler | Application |
| Command DTO | Application |
| View model repository **interface** | Application |
| View model DTO | Application |
| Event subscriber | Application |
| Interface for an infrastructure service | Application |
| Entity / write model repository **implementation** | Infrastructure |
| View model repository **implementation** | Infrastructure |
| Web controller | Infrastructure |
| CLI command / Symfony Console Application | Infrastructure |
| Service container | Infrastructure |
| Service using time or randomness | Infrastructure |

**Note the pattern**: interfaces live inward (Domain or Application), implementations live outward (Infrastructure). That single rule generates most of the table.

**Data flow vs. dependency direction**

| Step | Layer | Data direction | Depends on |
|---|---|---|---|
| Framework accepts HTTP request | Infrastructure | in | — |
| Controller builds DTO, calls service | Infrastructure | in | Application |
| Application service creates/modifies entity | Application | in | Domain |
| Application service saves via repository | Application → Infrastructure | **out** | Domain (the *interface*) |

## Worked Example

**Why MVC-plus-services fails, in three diagrams.**

**Diagram 1 — fat controller.** The framework gives you good tools for extracting request data, managing sessions, and rendering templates. "This is all great, and frameworks usually do a good job at this. But when it comes to making the jump from the controller to the model, things are likely to go wrong." Business logic accumulates in controllers; models degrade to data holders.

**Diagram 2 — the attempted rescue.** Developers notice and extract services. Controllers shrink. **The services become the new problem**, for three compounding reasons:

1. *Still framework-coupled.* "They still rely on the session, or the current web request." (Ch 5's disease, moved.)
2. *Two responsibilities in one class.* Grouped around a domain concept, each service "manages both the domain logic and the persistence logic for this particular concept." (Ch 2's disease, moved.)
3. *Anemic models.* "Domain models still remain simple data holders and can't protect any of their invariants… This again results in services that have too much to do." (Ch 8's disease, unaddressed.)

The verdict is precise: "the reason to start using services is a good one… but usually it's the implementation that's lacking. Without decoupling the service from the framework, without separating domain logic from persistence logic, and without taking the extra step of defining richer domain objects, the result will be disastrous."

Every one of those three fixes is a Part I chapter. **The service layer only works if you've already done Part I.**

**Diagram 3 — the structural gap MVC can't close.** Even with all three fixed, MVC "doesn't help us separate a use case in a primary action and its secondary effects. Services usually end up having large methods that start processing a request and perform all of the secondary tasks in the same method… These services may even reach out to remote parts of the code base to do remotely related jobs."

That's Ch 11's application service + domain events + event subscribers — and MVC has no vocabulary for any of it. Hence: "MVC isn't a sufficient organizational principle for web applications."

**The fix, and why it's structured this way.**

Three layers, with a strikingly simple generating rule: **interfaces point inward, implementations point outward.** `OrderRepository` (interface) is Domain; `OrderRepositoryUsingSql` is Infrastructure. That one rule places most classes correctly.

The subtlety worth internalizing: data flows *outward* to the database while dependencies point *inward*. "The application service class doesn't depend on an infrastructure class, it depends on an abstraction: the repository interface that lives in the `Domain` layer." Redraw the layers as concentric circles and the inversion becomes visually obvious — every arrow points in.

**Making it real.** Layers are invisible; documentation about them rots. So encode them in namespaces (`Domain\Model\Order\Order`, `Application\CreateOrder\CreateOrderService`, `Infrastructure\…`) and let `deptrac` enforce the rule in CI.

One detail in the Application namespace layout is easy to miss and matters a lot: **one sub-namespace per use case, including read-only ones.** `CreateOrder` *and* `ListAvailableEbooks`. That directly encodes Ch 11's "revolutionary" insight — retrieving information is a first-class use case — into the directory structure, where nobody can overlook it.

**And the honest caveat.** Noback flags the Domain/Application split as optional: it "doesn't improve either of these quality aspects" (testability, life expectancy). He keeps it purely for legibility — so a reader can tell what an actor can *do*, and whether a given repository serves users or internal code. Consistent with Ch 9: the big win was core vs. infrastructure; this is refinement.

## Key Takeaways
1. MVC plus a service layer is not enough. It has no place for use cases, secondary effects, read models, or abstractions over infrastructure.
2. The service-layer rescue fails unless you also decouple from the framework, split domain from persistence logic, and make domain objects rich. All three are Part I.
3. Three layers: Domain (entities, value objects, events, write-model repository interfaces, domain services), Application (use cases and everything expressing them), Infrastructure (everything connecting to the outside world).
4. The generating rule: interfaces inward, implementations outward.
5. The Dependency rule: source code dependencies between layers point only inwards. Applying dependency inversion at the class level satisfies it automatically.
6. Data direction and dependency direction are different things. Data flows outward to the database; dependencies point inward to abstractions.
7. Domain objects are implementation details of the Application layer. Infrastructure should see primitives and DTOs, not rich domain objects.
8. Give each layer a namespace, and one Application sub-namespace per use case — including read-only use cases.
9. Don't document layers separately. Make them apparent from the code, and enforce them with `deptrac` in the build.
10. Tools can verify the Dependency rule but not layer membership — "is this core or infrastructure code" still needs a human.
11. The Domain/Application split is optional for testability. Keep it for legibility.

## Connects To
- **Ch 1**: the two rules for core code are the test for whether something belongs in Infrastructure.
- **Ch 2, 5, 8**: the three reasons the naive service layer fails map to persistence coupling, framework coupling, and anemic models.
- **Ch 4**: application services — the heart of the Application layer.
- **Ch 9**: the strategy (dependency inversion + universal invokability) is what makes the Dependency rule hold; also the "nice-to-have" framing this chapter fits into.
- **Ch 11**: the object catalog this chapter sorts into layers.
- **Ch 13**: completes the `Infrastructure` namespace structure via ports and adapters.
- **Ch 14**: inward-only dependencies are what make isolated use case testing possible.
- **Robert C. Martin, "Clean Architecture"**: the Dependency rule and concentric circles.
- **Vaughn Vernon, "Implementing Domain-Driven Design"**: the `Domain\Model` / `Domain\Service` namespace layout.
- **`deptrac`**: automated Dependency rule verification.
