# Chapter 13: Ports and adapters

## Core Idea
A **port** is an *intention* of communication, expressed as an interface. An **adapter** is its *implementation*. Define a port for every way an actor reaches your application and for every way your application reaches out — then swap adapters freely for testing or technology changes.

## Frameworks Introduced

- **Hexagonal architecture** (Alistair Cockburn), stated in its author's words:
  > "Allow an application to equally be driven by users, programs, automated test or batch scripts, and to be developed and tested in isolation from its eventual run-time devices and databases."
  - Noback prefers the alternative name: "**Ports & Adapters**… I think this name is actually better, because ports and adapters are the main concepts, and they are almost self-explanatory."

- **Port** — "an intention of communication."
  - **Incoming port**: a primary actor communicating with the application ("for creating an order", "for listing available e-books"). Drawn on the left.
  - **Outgoing port**: the application communicating with a supporting actor ("for saving an order"). Drawn on the right.
  - **Cockburn equates a port with an interface.** "Every port will have a corresponding `interface` element inside the hexagon."
  - **How to name one**: "complete the sentence 'for …'". Then, for code, Noback converts to imperatives: "personally I think it makes more sense to use imperative sentences like 'list available e-books', 'create order' and 'save order'."

- **Adapter** — the implementation of a port.
  - "An adapter often isn't a single class. All the collaborating objects should be considered part of the adapter too. For instance, if your `OrderRepository` implementation uses Doctrine ORM to store the `Order` entity, **all of Doctrine ORM should be considered part of the adapter**."
  - For an incoming port, the adapter includes the web server, PHP's request handling, the framework, **and the controller** — "since the controller is specifically designed for HTTP communication. It uses web-specific objects and services like the current request or the user's session. As soon as the controller calls an application service, we step out of the adapter and into the hexagon."
  - **"In fact, the test code itself should be considered an adapter since it communicates directly with the port."**

- **The asymmetry between incoming and outgoing ports** — the chapter's sharpest technical point:
  > "For outgoing ports, the application (or hexagon) contains an interface (`OrderRepository`, `VatRateProvider`) for which the adapter has to provide an implementation by **implementing** the interface. For incoming ports the application also contains an interface (e.g. `ApplicationInterface` or `CommandBus`) but the adapters don't implement this interface, they **use** it."
  - Answer to the chapter's own exercise: **yes, all ports should have an interface** — including incoming ones.

- **`ApplicationInterface`** — one interface abstracting the whole hexagon.
  - Why not one interface per application service: "I think it'll be quite annoying when you have to always create an application service class and a separate interface that looks just like the class. So let's not go this way."
  - The generalization: "we are trying to define an abstraction for the hexagon itself, which is in fact a collection of all the use cases of our application. This collection of use cases can be defined as a single API, which is both an **abstraction** (port adapters don't have to nor do they want to deal with what's going on behind the scenes) and a **contract** (port adapters rely on certain behaviors to be provided by the hexagon)."
  - The `Interface` suffix is normally bad naming — Noback grants an exception here, citing Mathias Verraes' "Sensible Interfaces."
  - The standard implementation "will basically be a proxy for already existing services."

- **Command bus** — the alternative when `Application` grows too large.
  - Trigger: "The size of this class may quickly get out of hand and we should take that as **design feedback**. Maybe the application is starting to do too many things and you need to subdivide it into modules. Another option is to try out the `Command bus` pattern."
  - How: a generic `CommandBus::handle(object $command)` that inspects the command's type and routes to a handler.
  - Trade-off: "we lose the parameter and return types that we have in the more specific `ApplicationInterface`. But when it comes to testing, the `CommandBus` has the same benefit… It's also a single thing that you can replace."
  - Also handles queries: "Maybe it should just be called 'bus' then, or 'message bus'."

- **Contract test** — how you prove two outgoing adapters are truly interchangeable.
  - "In such a test you specify how any implementation of the interface should behave. You can then run this test against each of the implementations you have." (Detailed in Ch 14 §14.3.)

- **Orthogonality of hexagonal and layered architecture:**
  > "Hexagonal architecture is **orthogonal** to a layered architecture. This means you can apply hexagonal architecture, a layered architecture, or both. Neither one implies the other. However, they share the same origin: the desire to separate pure use cases from infrastructural concerns."
  - The mapping: **inner hexagon = Domain + Application layers. Outer hexagon = Infrastructure layer.**

## Key Concepts
- **Hexagon** — the application's use cases; all core code.
- **Outer hexagon** — the adapters; corresponds to the Infrastructure layer.
- **Primary actor** — takes the initiative (user, external system calling your API).
- **Secondary / supporting actor** — the application reaches out to it (database, mail server).
- **Driver** — another name for an outgoing adapter.
- **Contract test** — a test run against every implementation of a port.
- **Command bus / message bus** — a generic dispatcher for command and query objects.

## Mental Models
- **Retrieving information is a port too.** "Incoming ports represent the intention of an actor to change something about the application's state or to produce some other kind of effect with it. Another intention could be to retrieve some information… **Every possibility to retrieve information from an application should also be represented by a port.**"
- **One port, many adapters — by output format as well as by input channel.** "Besides offering a JSON response the application may also provide a regular HTML page rendering a nice list of e-books. It could just as well provide an RSS feed… Each example would require a separate adapter of the same port."
- **The point of ports is swappability, and testing is the primary motivation.** "This is what hexagonal architecture is actually aiming for: the ability to replace adapters in order to make testing of the hexagon easier." Technology migration is the secondary benefit.
- **Test code is an adapter.** "This level of decoupling guarantees that invoking an application service from a test scenario isn't substantially different from invoking it from a web controller."
- **Don't un-`final` a class to make it testable.** "A quick solution would be to make the class non-`final` so you can create a test-double for it, but that doesn't make sense to me; the class is not supposed to be extended so it should remain `final`. A better solution is to define an interface."
- **You rarely browse `Infrastructure`.** "If I need to change something about some adapter code, I'm usually working on the use case itself… I can use the IDE's 'Find usages' or 'Find implementations' functionality and quickly jump to the related infrastructure code." Structure it anyway, but don't over-invest.
- **An `Infrastructure` sub-namespace that looks like a package probably is one.** "The `VatApiDotCom` classes form a stand-alone HTTP client for `vatapi.com` and might as well be extracted. If the code is not project-specific you may even make the library publicly accessible."
- **Shared code grows without limit unless watched.** "The advice about shared code is always to keep it to a minimum. If you don't keep an eye on it, it will grow quickly until everything ends up being 'shared code'."

## Anti-patterns
- **Depending directly on a concrete application service from a controller**: testing the adapter then also runs the real use case, "even though we're only interested in testing the behavior of the port adapter itself."
- **Removing `final` to enable mocking**: fix the abstraction, not the modifier.
- **One interface per application service**: "quite annoying when you have to always create an application service class and a separate interface that looks just like the class."
- **Letting `Application` grow unboundedly**: treat its size as design feedback — split into modules, or move to a command bus.
- **Treating the adapter as just one class**: the ORM, the framework, the HTTP client — all of it is the adapter, and forgetting that hides real coupling.
- **Unbounded shared code in `Infrastructure`**.

## Code Examples

An outgoing port and two adapters — the pattern hexagonal architecture exists for:

```php
// The port (inside the hexagon)
interface OrderRepository
{
    public function save(Order $order): void;
    public function getById(OrderId $orderId): Order;
}

// Production adapter
final class OrderRepositoryUsingSql implements OrderRepository
{
    private Connection $connection;

    public function save(Order $order): void { /* ... */ }
}

// Test adapter
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
            throw new RuntimeException(
                'Could not find order with ID ' . $orderId->asString()
            );
        }

        return $this->orders[$orderId->asString()];
    }
}
```

Two adapters for the **same** incoming port — the boundary is the application service call:

```php
final class OrderController                          // HTTP adapter
{
    public function orderEbookAction(Request $request): Response
    {
        // Everything above this line is adapter; the call crosses into the hexagon
        $orderId = $this->ebookOrderService->createOrder(
            CreateOrder::fromRequestData($request->request->all())
        );

        return new Response(/* ... */);
    }
}

final class CreateOrderCommand extends Command       // CLI adapter
{
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $orderId = $this->ebookOrderService->createOrder(
            new CreateOrder(
                (int)$input->getArgument('ebook_id'),
                (int)$input->getArgument('quantity'),
                $input->getArgument('email_address')
            )
        );

        $output->writeln(sprintf(
            '<success>Created a new order with ID %s', $orderId->asString()
        ));

        return 0;
    }
}
```

An information-retrieval port and one of its adapters:

```php
interface ListAvailableEbooksRepository
{
    /** @return array<Ebook> */
    public function listAll(): array;
}

final class EbookController                          // JSON adapter
{
    public function listAvailableEbooksAction(): Response
    {
        $ebooks = $this->ebooksRepository->listAll();

        return new JsonResponse(
            array_map(fn (Ebook $ebook) => ['title' => $ebook->title()], $ebooks)
        );
    }
}
```

`ApplicationInterface` — one abstraction for the whole hexagon:

```php
interface ApplicationInterface
{
    public function createOrder(CreateOrder $command): OrderId;

    /** @return array<Ebook> */
    public function listAvailableEbooks(): array;
}

final class Application implements ApplicationInterface
{
    // Basically a proxy for already existing services
    public function createOrder(CreateOrder $command): OrderId
    {
        return $this->ebookOrderService->createOrder($command);
    }

    public function listAvailableEbooks(): array
    {
        return $this->listAvailableEbooksRepository->listAll();
    }
}

final class OrderController
{
    private ApplicationInterface $application;   // one dependency, fully mockable

    public function orderEbookAction(Request $request): Response
    {
        $orderId = $this->application->createOrder(
            CreateOrder::fromRequestData($request->request->all())
        );

        return new Response(/* ... */);
    }
}
```

The command bus alternative:

```php
interface CommandBus
{
    /** @return mixed */
    public function handle(object $command);
}

final class HardWiredCommandBus implements CommandBus
{
    public function handle(object $command)
    {
        if ($command instanceof CreateOrder) {
            return $this->ebookOrderService->create($command);
        } elseif ($command instanceof /* ... */) {
            // and so on...
        }

        throw new RuntimeException('Unknown command type: ' . get_class($command));
    }
}
```

- **What it demonstrates**: the same testing benefit as `ApplicationInterface` — one replaceable seam — at the cost of parameter and return types.

## Reference Tables

**Incoming vs. outgoing ports**

| | Incoming port | Outgoing port |
|---|---|---|
| Actor | Primary (user, API client, CLI, test) | Secondary (database, mail server, VAT API) |
| Hexagon side | Left | Right |
| Example | "for creating an order" | "for saving an order" |
| Interface in code | `ApplicationInterface`, `CommandBus` | `OrderRepository`, `VatRateProvider` |
| Adapter's relation to the interface | **Uses** it | **Implements** it |
| Adapters include | Web server, PHP, framework, controller, test code | The repository implementation plus its ORM/client |

**Ports and layers combined**

| Hexagonal term | Layer term |
|---|---|
| Inner hexagon | Domain + Application |
| Outer hexagon | Infrastructure |
| Port (interface) | Domain or Application |
| Adapter (implementation) | Infrastructure |

**Structuring the `Infrastructure` namespace**

| Situation | Grouping |
|---|---|
| Multiple classes for one adapter | Sub-namespace per adapter |
| Multiple adapters sharing a technology | Sub-namespace per technology (`Sql`, `VatApiDotCom`, `Symfony`) — "gives readers of the code a clear overview of the ways in which this application connects to external systems" |
| Utility used by all SQL repositories | Put it in the `Sql` sub-namespace |
| Truly generic utility | `Shared` or `Common` — keep it minimal |

## Worked Example

**Making the incoming port an actual interface — the chapter's least obvious move.**

Outgoing ports are easy to accept as interfaces. "When you want to save an `Order` you need to reach outside the application and connect to a database, so you can't depend on a class there; you need an abstraction." `OrderRepository` was already an interface back in Ch 2.

Incoming ports look different. `OrderController` depends on the concrete `EbookOrderService` class, and that seems fine — the service is core code, it's not going anywhere.

**The problem shows up when you test the adapter.** You want to verify that `OrderController` correctly turns a request into a `CreateOrder` command and turns an `OrderId` back into a `Response`. But invoking the controller "will also invoke the actual `EbookOrderService`, even though we're only interested in testing the behavior of the port adapter itself." You end up hitting the database to test HTTP mapping.

**The tempting fix, rejected.** Drop `final` from `EbookOrderService` so you can subclass it as a test double. Noback refuses: "that doesn't make sense to me; the class is not supposed to be extended so it should remain `final`. A better solution is to define an interface. You can always create a test-double for an interface because it's designed to be extended."

**First attempt — an interface per service.** `EbookOrderServiceInterface` with the single method `create(CreateOrder): OrderId`. It works. It's also miserable: "quite annoying when you have to always create an application service class and a separate interface that looks just like the class. So let's not go this way."

**The reframe.** Instead of abstracting each service, ask what you're *actually* trying to abstract. "We are trying to define the incoming ports of our hexagon so we can invoke only the port adapters without also invoking the code inside the hexagon. This means we are trying to define an abstraction for **the hexagon itself**."

And the hexagon is exactly one thing: the collection of all use cases. That collection is a single API — simultaneously "an **abstraction** (port adapters don't have to nor do they want to deal with what's going on behind the scenes) and a **contract** (port adapters rely on certain behaviors to be provided by the hexagon)."

Hence `ApplicationInterface`, with a method per use case, and `Application` as a thin proxy over the existing services. Every controller takes exactly one dependency, fully replaceable in a test.

Noback flags the naming: the `Interface` suffix is usually a smell, but he grants it here, citing Verraes' "Sensible Interfaces" — this genuinely is *the interface to the application*.

**Then he pre-empts the obvious objection.** `Application` will accumulate a method per use case and eventually sprawl. His answer isn't a workaround — it's to read the growth as information: "The size of this class may quickly get out of hand and we should take that as **design feedback**. Maybe the application is starting to do too many things and you need to subdivide it into modules."

Only after that does he offer the command bus, which trades type safety for a generic `handle(object $command)` and keeps the same single replaceable seam. And note it isn't limited to commands: "The 'command' bus could also handle queries like `listAvailableEbooks()`. Maybe it should just be called 'bus' then, or 'message bus'."

**The asymmetry this reveals.** Now that both sides have interfaces, the difference stands out sharply:

> "For outgoing ports, the application contains an interface for which the adapter has to provide an implementation by **implementing** the interface. For incoming ports the application also contains an interface but the adapters don't implement this interface, they **use** it."

Both directions have a port. Both are interfaces. But the arrow attaches differently — and that's precisely why the Dependency rule (Ch 12) still holds in both directions: implementing points inward, and using points inward too.

## Key Takeaways
1. A port is an intention of communication; an adapter is its implementation. Name ports by completing "for …", then use imperatives in code.
2. Incoming ports serve primary actors; outgoing ports serve supporting actors. Both need interfaces.
3. The asymmetry: outgoing adapters **implement** the port interface; incoming adapters **use** it.
4. An adapter is never one class. The ORM, the framework, the web server, the HTTP client — all part of the adapter.
5. Test code is an adapter. That's the measure of whether your decoupling worked.
6. Retrieving information deserves a port too, and one port can have many adapters differing only in output format (JSON, HTML, RSS).
7. Don't drop `final` to enable mocking. Define an interface.
8. Prefer one `ApplicationInterface` (or `CommandBus`) over an interface per application service. It abstracts the hexagon itself.
9. Growth in `Application` is design feedback — split into modules, or adopt a command bus.
10. A command bus trades parameter and return types for genericity; it keeps the single replaceable seam. It can carry queries too.
11. Prove adapters are interchangeable with a contract test run against every implementation.
12. Hexagonal and layered architecture are orthogonal but complementary. Inner hexagon = Domain + Application; outer hexagon = Infrastructure.
13. Group `Infrastructure` by adapter or by technology — the technology grouping doubles as a map of every external connection your application has.

## Connects To
- **Ch 2**: `OrderRepository` — the book's first port, written long before the word existed.
- **Ch 4**: application services and command objects; the CLI adapter shown here is the one Ch 4 argued for.
- **Ch 6**: `VatRateProvider` is an outgoing port; `VatRateProviderUsingVatApiDotCom` its adapter; the integration test there is an adapter test.
- **Ch 9**: primary and supporting actors, defined there and reused here.
- **Ch 11**: `InMemoryOrderRepository` and the repository contract.
- **Ch 12**: layers; this chapter completes the `Infrastructure` namespace structure promised there.
- **Ch 14 (§14.3, §14.5)**: contract tests, and the in-memory repository put to work.
- **Alistair Cockburn**: hexagonal architecture.
- **Mathias Verraes, "Sensible Interfaces"**: when the `Interface` suffix is justified.
