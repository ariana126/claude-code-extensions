# Chapter 11: Key design patterns

## Core Idea
Replace the framework's element types (controllers, models, templates) with a framework-independent catalog — **entities, repositories, application services, domain events, event subscribers, read models, view models** — and use them as primitives you can design with before choosing any framework.

## Frameworks Introduced

- **The catalog** — seven object types, each with a defined job:

  | Type | Job | Mutable? | Returns |
  |---|---|---|---|
  | **Entity** | Preserves state; protects invariants | Yes (the only one) | `void` from command methods |
  | **Repository** | Saves/loads entities across the app boundary | — | Entity, or `void` |
  | **Application service** | Coordinates a use case; one entity per call | — | `void`, or a new entity's ID |
  | **Domain event** | Records that something happened | No | — |
  | **Event subscriber** | Handles secondary effects | — | `void` |
  | **Read model** | Provides information internally | No | Value objects |
  | **View model** | Exposes data to primary actors | No | Render-ready primitives |

- **"In infrastructure code, frameworks are your friend. In core code, they are not."** — the chapter's opening thesis.
  - Framework-determined core code produces: (1) implicit use cases inside controllers, (2) a domain model coupled to its infrastructure, (3) code coupled to the framework.
  - The goal: "By using these objects as 'primitives' you can implement all of the application's use cases, without even choosing a framework. The framework will just be the finishing touch, the bridge between your application's core and the outside world."

- **Entity = aggregate.** "In this book the concept of an entity is the same as the concept of an aggregate in Domain-Driven Design literature… In my experience the term 'aggregate' leads to a lot of confusion so I decided to use the word 'entity'."
  - The five entity rules:
    1. **Protect invariants** — named constructor, minimum required data, identity from the start, relations by ID.
    2. **Constrain updates** — only modifiable fields; force related fields to change together; verify the change is possible given current state.
    3. **Model state changes as actions** — `cancel()`, not `setCancelled()`. Command methods return `void`.
    4. **Don't think too much about tables** — "you can let the design of your object determine what storage model would work best."
    5. **Record domain events** — internally, released after saving.

- **The state machine diagram** — a design tool for entities.
  - When to use: designing any entity with more than a trivial lifecycle.
  - How: "document the possible states of an entity and what actions (state transitions) are available for any given state. **Create unit tests for your entity to prove that it correctly implements the state machine you had in mind.**"

- **The seven application service rules** (§11.4.1–11.4.7):
  1. **Return the identifier of a new entity** — never the entity itself.
  2. **Input should be primitive-type data** — so any client can construct it.
  3. **Wrap input in command objects** — a DTO named after the intention, making the service a **command handler**.
  4. **Translate primitive input to domain objects** — or better, let the command object's accessors do it.
  5. **Add contextual information as extra arguments** — never fetched, never constructor-injected.
  6. **Save only one entity per call** — helps performance, prevents concurrent updates, keeps use cases focused.
  7. **Move secondary tasks to a domain event subscriber.**

- **The upstream/downstream subscriber placement rule** — where an event subscriber lives determines your module dependency graph.
  - Naming convention: **the class name says *what* it does** (`CreateInvoice`); **the method name says *when*** (`whenOrderFullyDelivered`).
  - Placement: put the subscriber "in the module where they produce their effect." `CreateInvoice` belongs in **Invoicing**, subscribing to events from **Orders**.
  - Why: "The order comes first, and determines what needs to be invoiced. The invoice comes second… So the order module is *upstream*, the invoicing module is *downstream*." Placing `CreateInvoice` in Orders would make Orders depend on Invoicing — backwards.
  - Result: "the orders module doesn't have to know anything about the invoicing module. The invoicing module doesn't have to be explicitly told to create an invoice; it will respond to the fact that an order was fully delivered."

- **Read models as local representations of remote entities** — "the Dependency Inversion Principle applied to models."
  - Invoicing owns its own `Order` read model *and* its `OrderRepository` interface. "That way, `Invoicing` is the owner of the object's API so it can be easily modified to meet future needs."
  - The payoff: "Even if the `Orders` module gets replaced by a third-party platform for selling e-books, the `Invoicing` module doesn't need to suffer. The only thing that needs to be done is rewrite the `OrderRepository` implementation to use the third-party platform's API." Noback calls this "a very powerful architectural technique."

- **Process Modelling** (Alberto Brandolini, "Introducing Event Storming") — using this catalog in design sessions.
  - Where it fits: "between higher-level design sessions where the focus is on the problem domain, and lower-level design sessions where the programmers want to take a step in the direction of the solution."
  - What you design: commands, events, read models, effects, and decisions (policies). Noback extends it by zooming into the "System" box and adding application services and event subscribers.
  - The insight he calls revolutionary: "consider the user as someone who is influenced by the real world, who lets the system inform them about something, and who then makes a decision based on this information. I realized that **retrieving information from a system should be considered an important use case, just as important as a use case where the user decides to do something.**"

## Key Concepts
- **Domain invariant** — "the things that are always true about" an entity.
- **Command method** — changes state; returns `void`.
- **Command object / DTO** — input for one use case, named after the intention.
- **Command handler** — what an application service becomes once it takes a command object.
- **Identity map** — tracks loaded entities so `save()` knows `INSERT` vs. `UPDATE`.
- **Eventual consistency** — "the system's state will be consistent only after all event subscribers are finished."
- **Upstream / downstream module** — which comes first in the business process; determines allowed dependency direction.
- **Primary/secondary effect** — the one entity change vs. everything it triggers.

## Mental Models
- **Every framework leaves fingerprints.** "When you take a look at the directory structure of most web application projects, you'll immediately notice the framework that's been used." That's fine for infrastructure and fatal for core.
- **Design entities without thinking about tables.** "Your entity should in the first place be a well-designed object regardless of the database that will eventually support storing it."
- **The repository contract, stated plainly**: "when you have saved an `Order` with a certain `OrderId` you can at any time retrieve a copy of it by providing that same `OrderId`… The object you get back could be the exact same instance, or an object that behaves in an identical way to the one you saved."
- **Dispatch events only after persistence.** "You shouldn't dispatch the events until you are certain that the entity's changes have been persisted."
- **One action can record several events** — when a change "means different things to different observers," or when it "brings the entity into some new state" (`LineDelivered` plus `OrderFullyDelivered`).
- **Watch the ORM cost/benefit line.** Rolling your own mapping means identity maps, child-entity change tracking, `DELETE` detection — "before you know it you'll be implementing your own ORM." Noback has had "great benefits from writing my own mapping code, but make sure to fully consider your own context."
- **Recognizable patterns lower the cost of everything.** "Implementing use cases becomes more like following a recipe. Understanding use cases implemented by others also becomes easier, because you recognize the same patterns in their work."

## Anti-patterns
- **Traversing between entities**: `$this->getLine(1)->getProduct()->getProductGroup()->getProducts();` Fetch the other entity from its own repository instead.
- **Changing multiple entities in one transaction**: "Make a clear distinction between the primary change and secondary effects."
- **Passing an entity to a client that won't change it**: use a read model.
- **Setter-style state changes**: `setCancelled()` instead of `cancel()` skips the "is this transition allowed?" check.
- **Returning the entity from an application service**: "an entity is a write model with built-in behaviors for changing its state. It should not be available to clients that don't want to change its state. Clients of application services are usually controllers and they certainly shouldn't change entity state." Return the ID and fetch a view model.
- **Throwing while populating a command object**: cast types and fill defaults; don't validate (Ch 8 §8.6). "This way, the controller still has a chance to validate the command object itself and show form errors to the user."
- **Long chains of value-object construction in the application service**: "application services tend to become long lists of these primitive-value-to-value-object transformations, which obscures the view on the actual use case."
- **The upstream module reaching into the downstream one**: "It would damage the ability to decouple modules from each other if the order module would reach out to the invoicing module and start calling methods there."
- **Doing entity work directly inside an event subscriber**: delegate to an application service. (Exception: *infrastructure-level* subscribers — logging, queueing — "can't, because an application service can't do any infrastructure work.")
- **A view model that makes the template work**: "make sure that the template renderer doesn't need to do much more than just `echo` a couple of properties."

## Code Examples

An entity: named constructor, guarded transitions, recorded events:

```php
final class Order
{
    private array $events = [];
    private bool $wasCancelled = false;
    private bool $wasDelivered = false;

    private function __construct(/* ... */) { /* ... */ }

    public static function create(OrderId $orderId, CustomerId $customerId): Order
    {
        return new self(/* ... */);   // identity from the start; relation by ID
    }

    public function changeDeliveryAddress(DeliveryAddress $deliveryAddress): void
    {
        if ($this->wasCancelled) {
            throw new LogicException(sprintf(
                'Order %s was already cancelled', $this->id->asString()
            ));
        }
        // ...
    }

    public function cancel(): void      // an action, not a setter
    {
        if ($this->wasDelivered) {
            throw new LogicException(sprintf(
                'Order %s has already been delivered', $this->id->asString()
            ));
        }

        $this->wasCancelled = true;
        $this->events[] = new OrderWasCancelled($this->id);
    }

    public function releaseEvents(): array
    {
        $events = $this->events;
        $this->events = [];   // note: releasing clears
        return $events;
    }
}
```

One action recording two events:

```php
public function markLineAsDelivered(int $lineNumber): void
{
    $this->line($lineNumber)->markAsDelivered();
    $this->events[] = new LineDelivered($this->id, $lineNumber);

    if ($this->allLinesHaveBeenDelivered()) {
        $this->events[] = new OrderFullyDelivered($this->id);
    }
}
```

The repository interface and a trivially simple test double:

```php
interface OrderRepository
{
    /** @throws CouldNotSaveOrder */
    public function save(Order $order): void;

    /** @throws CouldNotFindOrder */
    public function getById(OrderId $orderId): Order;
}

final class InMemoryOrderRepository implements OrderRepository
{
    private array $orders = [];

    public function save(Order $order): void
    {
        $this->orders[$order->orderId()->asString()] = $order;
    }

    public function getById(OrderId $orderId): Order
    {
        if (!isset($this->orders[$orderId->asString()])) {
            throw CouldNotFindOrder::withId($orderId);
        }

        return $this->orders[$orderId->asString()];
    }
}
```

The application service, with events dispatched **after** saving:

```php
final class OrderService
{
    private OrderRepository $orderRepository;
    private EventDispatcher $eventDispatcher;

    public function changeDeliveryAddress(ChangeDeliveryAddress $command): void
    {
        $order = $this->orderRepository->getById($command->orderId());
        $order->changeDeliveryAddress($command->deliveryAddress());

        $this->orderRepository->save($order);

        $this->eventDispatcher->dispatchAll($order->releaseEvents());
    }
}
```

Type conversion moved into the command object — §11.4.4's preferred form:

```php
final class ChangeDeliveryAddress
{
    private string $orderId;
    private string $address;
    private string $postalCode;
    private string $city;
    private string $country;

    public function orderId(): OrderId
    {
        return OrderId::fromString($this->orderId);
    }

    public function deliveryAddress(): DeliveryAddress
    {
        return DeliveryAddress::fromScalars(
            $this->address, $this->postalCode, $this->city, $this->country
        );
    }
}
```

- **What it demonstrates**: two advantages — "less noise inside the application service," and "the getters on the command DTO can be called multiple times… There's no need to duplicate the instantiation logic." Downside: "you could accidentally trigger a domain-level exception inside the controller by calling one of those getters. In practice I find that this doesn't get in the way and is just something to be aware of."

The event dispatcher and a subscriber:

```php
interface EventDispatcher
{
    public function dispatchAll(array $events): void;
}

final class SimpleEventDispatcher implements EventDispatcher
{
    private array $subscribers;

    public function dispatchAll(array $events): void
    {
        foreach ($events as $event) {
            foreach ($this->subscribersForEvent($event) as $subscriber) {
                $subscriber($event);
            }
        }
    }

    private function subscribersForEvent(object $event): array
    {
        return $this->subscribers[get_class($event)] ?? [];
    }
}

// Class name = WHAT it does. Method name = WHEN it does it.
final class CreateInvoice
{
    private InvoicingService $invoicingService;

    public function whenOrderFullyDelivered(OrderFullyDelivered $event): void
    {
        $this->invoicingService->createInvoiceFromOrder($event->orderId(), /* ... */);
    }
}
```

The controller: use the returned ID to fetch a view model:

```php
public function createOrderAction(Request $request): Response
{
    $orderId = $this->orderService->createOrder(/* ... */);
    $order = $this->orderDetailsRepository->getById($orderId);   // view model

    return $this->templateRenderer->render('order-details.html.twig', [
        'order' => $order
    ]);
}
```

## Reference Tables

**Framework elements vs. the catalog**

| Framework thinks in | This book thinks in |
|---|---|
| Controllers | Application services (+ thin controllers) |
| Models / entities (ORM-coupled) | Entities, value objects |
| — | Repositories (interface + implementation) |
| Templates | View models |
| — | Read models |
| Framework events | Domain events + event subscribers |

**Where does each kind of input go on an application service?**

| Input | Mechanism |
|---|---|
| Job-specific data | Command object (primitives in, value objects out) |
| Contextual info (current user ID, request data) | Extra argument, folded into the command object |
| Dependencies (repositories, dispatcher) | Constructor, by interface |

**Event subscriber: core or infrastructure?**

| Subscriber | Kind | How it does its work |
|---|---|---|
| `CreateInvoice` | Core | Delegates to an application service |
| Log the domain event | Infrastructure | Does the work itself; may inject infrastructure services |
| Push to a queue | Infrastructure | Same |
| Store events in a database | Infrastructure | Same |

## Worked Example

**Invoicing and Orders: how two modules stay decoupled while one clearly depends on the other's business process.**

**The requirement.** When an order is fully delivered, create an invoice. Invoicing needs the customer ID, billing address, and each line's product description, quantity, and tariff.

**The naive wiring.** Put a `CreateInvoice` event subscriber in the **Orders** module; it calls `InvoicingService`. It works — but it establishes a dependency **from Orders to Invoicing**, and that's backwards. "The order comes first, and determines what needs to be invoiced. The invoice comes second, and it's based on data from the order. So the order module is *upstream*, the invoicing module is *downstream*."

**The fix — move the subscriber.** Put `CreateInvoice` in **Invoicing**, subscribing to `OrderFullyDelivered`. The arrow flips: Invoicing depends on Orders. "The orders module doesn't have to know anything about the invoicing module. The invoicing module doesn't have to be explicitly told to create an invoice; it will respond to the fact that an order was fully delivered."

The naming convention is what makes this readable: `CreateInvoice` (what) `::whenOrderFullyDelivered()` (when).

**Now Invoicing needs order data — but must not touch the `Order` entity.** Apply Ch 2's "act as if it already exists" trick inside `InvoicingService`:

```php
$invoice = Invoice::create($order->customerId(), $order->billingAddress());

foreach ($order->lines() as $line) {
    $invoice->addLine(
        $line->productDescription(),
        $line->quantity(),
        $line->tariff()
    );
}
```

Let the IDE generate the classes. Out falls an `Order` read model with exactly four methods and a `Line` with three — a fraction of the entity's surface.

**The critical placement decision.** "Note that the `Order` read model is part of the **Invoicing** module. That way, `Invoicing` is the owner of the object's API so it can be easily modified to meet future needs." Same for the `OrderRepository` interface: the *consumer* defines the shape of what it consumes.

**The payoff — the "very powerful architectural technique."** Right now both modules read the same database, so there's no code-level dependency between them at all. Now suppose you drop your own Orders module and start selling e-books through a third-party platform.

Invoicing doesn't change. `InvoicingService` doesn't change. The `Order` read model doesn't change. "The only thing that needs to be done is rewrite the `OrderRepository` implementation to use the third-party platform's API to retrieve information about an order."

Noback names the principle: **"It's like the Dependency Inversion Principle applied to models."** A read model owned by its consumer is a *local representation of a remote entity* — and it doesn't care whether that entity lives in your database, another module, or someone else's SaaS.

**The three rules that made it work**, each of which would have broken it if violated:
1. `CreateInvoice` delegates to `InvoicingService` rather than manipulating the `Invoice` entity itself — "a classic case of **Eventual consistency**."
2. The read model lives in the consuming module, so the consumer owns its API.
3. The repository is an interface, so the implementation can be swapped without any core code noticing.

## Key Takeaways
1. Frameworks are your friend in infrastructure code and your enemy in core code. Use the catalog as your primitives; add the framework last.
2. "Entity" here means DDD's aggregate. Entities are the only stateful objects; everything else should be immutable and stateless.
3. Never traverse entity to entity, and never change more than one entity per transaction. Fetch by ID; handle the rest with events.
4. Model state changes as actions (`cancel()`), not setters. Draw the state machine, then unit-test that the entity implements it.
5. Design entities without thinking about tables. Let the object's design suggest the storage model, not the reverse.
6. Application services return `void` or a new entity's ID — never the entity. The controller uses that ID to fetch a view model.
7. Command objects carry the input, are named after the intention, and are best given accessors that return value objects.
8. Contextual information is a method argument, never fetched and never constructor-injected.
9. Dispatch domain events only after the entity has been persisted.
10. Name event subscribers for *what* they do; name their methods for *when*. Put them in the module where the effect lands — that's what keeps module dependencies pointing downstream.
11. Core subscribers delegate to application services; infrastructure subscribers do their own work.
12. A read model owned by its consuming module is a local representation of a remote entity — the Dependency Inversion Principle applied to models, and the thing that lets you replace an entire upstream system.
13. This catalog is a modelling vocabulary, not just an implementation guide. Use it in Process Modelling sessions.
14. Retrieving information is a first-class use case, as important as changing something. Both belong in core code.

## Connects To
- **Ch 2**: entity and repository design; the "act as if it already exists" trick, reused for the `Order` read model.
- **Ch 3**: read models and view models; the two sync strategies referenced here.
- **Ch 4**: application services, command objects, and the multi-step/event discussion this chapter formalizes.
- **Ch 5 (§5.5)**: contextual information as method arguments.
- **Ch 8 (§8.6)**: populate command objects without throwing, so the controller can still show form errors.
- **Ch 12**: how these object types group into architectural layers.
- **Ch 13**: repositories and other abstractions as ports; their implementations as adapters.
- **Ch 14**: these patterns are what make scenario-based use case testing possible.
- **Alberto Brandolini, "Introducing Event Storming"**: Process Modelling.
- **Domain-Driven Design**: aggregates (called entities here), domain events, repositories.
- **TalisORM**: Noback's own mapping library, letting entities track their own "new" state.
