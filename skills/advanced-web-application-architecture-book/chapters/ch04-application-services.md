# Chapter 4: Application services

## Core Idea
Extract the use case out of the controller into an **application service** that accepts only primitive-type input, so any client — web form, JSON API, CLI, CSV import, cron job — can invoke the same code.

## Frameworks Introduced

- **Application service** — "used to model a use case that has side-effects (like saving a new entity) in a reusable way."
  - When to use: any controller action that does real work beyond translating HTTP to a call.
  - How: one class, one public method named after the use case, dependencies injected via the constructor, primitives (or a command object) in, an identifier out.

- **The four-step refactoring sequence** — the exact order Noback uses, and the order the chapter's exercise asks you to reproduce:
  1. **Extract Variable** — pull every `$request->get(...)` up to the top of the method, so the middle no longer touches the `Request`.
  2. **Extract Class** — move the now-infrastructure-free block into a new service; inject its dependencies as constructor arguments; pass the extracted variables as method arguments.
  3. **Inline Variable** — the intermediate variables have served their purpose; inline them at the call site.
  4. **Introduce Parameter Object** — collapse the growing parameter list into a single command object.
  - Why the order matters: Extract Variable creates a clean seam *first*, so Extract Class becomes a mechanical move rather than a rewrite.

- **Command object** — a parameter object named after a user intention.
  - When to use: as soon as an application service method takes more than a couple of parameters, or you anticipate it will (buyer name, currency, …).
  - How: name it after what the user wants to do — `CreateOrder`, not `OrderData` or `CreateOrderRequest`. "It's called a command because the object represents a user intention: something the user wants the application to do."
  - "This has nothing to do with command-line applications."

- **The "only use primitive-type data" rule** — how input becomes delivery-mechanism-agnostic.
  - When to use: designing any application service signature.
  - How: `int $ebookId, int $orderQuantity, string $emailAddress`. Redefine the input "without mentioning any infrastructure-specific concept like 'request'."
  - Why it works: "As long as the client can provide primitive data it can invoke the use case." A JSON decoder, a CSV parser, and a console argument list can all produce primitives; none of them can produce a `Request`.

- **One step per service, events for the rest** — Noback's preferred shape for multi-step use cases.
  - When to use: a use case whose scenario has several distinct steps.
  - How: "the application service only performs the first step, and leaves the other steps to other services." The entity records a domain event on construction; the service saves the entity, then dispatches `$order->releaseEvents()`; subscribers handle the remaining steps.
  - Why it works: it stops the application service accumulating unrelated dependencies, and makes each step independently testable and independently skippable.

## Key Concepts
- **Application service** — reusable, infrastructure-independent representation of a use case with side effects.
- **Command object** — parameter object holding all input for one use case, named after the user's intention.
- **Use case** — a thing the business needs the application to do, independent of how it's triggered.
- **Delivery mechanism** — the infrastructure that carries input to the application (HTTP, CLI, cron, file upload).
- **Domain event** — recorded by the entity when something noteworthy happens (`OrderWasCreated`); released and dispatched by the application service.
- **Event subscriber** — a service handling a later step of the scenario (`SendEmail::whenOrderWasCreated()`).
- **Extract Variable / Extract Class / Inline Variable / Introduce Parameter Object** — the four named refactorings, in sequence.

## Mental Models
- **A controller's only remaining job is translation.** Take primitives out of the delivery mechanism, build the command, call the service, render the result. Nothing else.
- **Use "will this step still happen if someone calls the service from elsewhere?" to place code.** The confirmation email can't stay in the controller: "whenever somebody creates an order, they should receive a confirmation email too… So if there will ever be a second place where `EbookOrderService::create()` gets called, the customer won't receive that email."
- **A growing constructor is a design signal, not an inconvenience.** When moving the email code in adds `Twig\Environment`, `Swift_Mailer`, and a system email address to the application service, "seeing all these dependencies worries me… These things don't belong inside the more domain-oriented code."
- **Introduce the interface before you write the implementation, on purpose.** "For me this is really stress-reducing. I can postpone all my worries about the correct usage of the mailer API, and I can move these messy details out of sight." Just don't postpone it indefinitely.
- **An interface is "a guarantee that at runtime, it will be possible to" do the thing.** The caller depends on the guarantee, never the mechanism.
- **Creating and saving is one step, not two.** "Creating the order isn't useful without also saving it, you can't save an order without creating it first."

## Anti-patterns
- **Copying use case code into a second entry point**: "there are now two places that contain the code for this use case… a developer changes something in one location, and forgets to update the other."
- **Moving use case code to the new entry point**: solves nothing — the use case is now welded to CLI infrastructure instead of web infrastructure.
- **Forging a `Request` to call a controller from a console command**: "an ugly workaround; I think most people would consider it a hack." Also needs a stand-in session service, and then you have to extract the order ID back out of a `Response`.
- **Framework/library types in an application service constructor**: `Swift_Mailer`, `Twig\Environment`, and a system email address are infrastructure concerns leaking into domain-oriented code. Hide them behind an intention-revealing interface.
- **Leaving a required side effect in the controller**: guarantees it will be silently skipped by the next client.
- **Passing `Request`/`Session` into core code**: an API controller shouldn't keep state between requests, and a CLI client "wouldn't even know about sessions."
- **Introducing an interface and forgetting the implementation**: Noback names this as his own recurring mistake.

## Code Examples

The extracted application service:

```php
final class EbookOrderService
{
    private EbookRepository $ebookRepository;
    private OrderRepository $orderRepository;

    public function __construct(
        EbookRepository $ebookRepository,
        OrderRepository $orderRepository
    ) {
        $this->ebookRepository = $ebookRepository;
        $this->orderRepository = $orderRepository;
    }

    public function create(
        int $ebookId,
        int $orderQuantity,
        string $emailAddress
    ): OrderId {
        $ebook = $this->ebookRepository->getById($ebookId);
        $orderAmount = $ebook->price()->multipliedBy($orderQuantity);

        $orderId = $this->orderRepository->nextIdentity();

        $order = new Order(
            $orderId,
            $ebook->id(),
            $emailAddress,
            $orderQuantity,
            $ebook->price(),
            $orderAmount
        );

        $this->orderRepository->save($order);

        return $orderId;
    }
}
```

The same service reached from a completely different delivery mechanism — no changes required:

```php
final class CreateOrderCommand extends Command
{
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $orderId = $this->container->get('ebook_order_service')->create(
            (int)$input->getArgument('ebook_id'),
            (int)$input->getArgument('quantity'),
            $input->getArgument('email_address')
        );

        $output->writeln(sprintf(
            '<success>Created a new order with ID %s</success>',
            $orderId->asString()
        ));

        return 0;
    }
}
```

The command object, named after the intention:

```php
final class CreateOrder
{
    private int $ebookId;
    private int $orderQuantity;
    private string $emailAddress;

    public function __construct(int $ebookId, int $orderQuantity, string $emailAddress)
    {
        $this->ebookId = $ebookId;
        $this->orderQuantity = $orderQuantity;
        $this->emailAddress = $emailAddress;
    }

    public function ebookId(): int { return $this->ebookId; }
    public function orderQuantity(): int { return $this->orderQuantity; }
    public function emailAddress(): string { return $this->emailAddress; }
}
```

The abstraction that keeps SwiftMailer out of the service:

```php
interface SendOrderConfirmationEmail
{
    public function send(OrderId $orderId, string $emailAddress): void;
}

final class SendOrderConfirmationEmailWithSwiftMailer
    implements SendOrderConfirmationEmail
{
    public function send(OrderId $orderId, string $emailAddress): void
    {
        $message = (new Swift_Message('Order ' . $orderId->asString()))
            ->setFrom($this->systemEmailAddress)
            ->setTo($emailAddress)
            ->setBody(
                $this->twig->render('email/order_confirmation.html.twig')
            );

        $this->mailer->send($message);
    }
}
```

- **What it demonstrates**: the application service now reads `$this->sendConfirmationEmail->send($orderId, $createOrder->emailAddress());` — one line where there were fifteen. "It's now easy to recognize that sending the confirmation email is the second step in the process."

The event-based version, where the service stops orchestrating entirely:

```php
final class Order
{
    private array $events;

    public function __construct(OrderId $orderId, string $emailAddress /* ... */)
    {
        // When we create an order, a domain event will be "recorded"
        $this->events[] = new OrderWasCreated($orderId, $emailAddress);
    }

    public function releaseEvents(): array
    {
        return $this->events;
    }
}

final class EbookOrderService
{
    public function create(CreateOrder $command): OrderId
    {
        $order = new Order(/* ... */);
        // First save the Order, then dispatch the recorded events:
        $this->eventDispatcher->dispatchAll($order->releaseEvents());

        return $orderId;
    }
}

final class SendEmail   // registered as a subscriber for OrderWasCreated
{
    public function whenOrderWasCreated(OrderWasCreated $event): void
    {
        $this->sendConfirmationEmail->send($event->orderId(), $event->emailAddress());
    }
}
```

## Reference Tables

**Why a use case needs more than one client — the concrete cases**

| Client | What it provides | Why it can't reuse a controller |
|---|---|---|
| Web form | HTTP POST | (the original) |
| JSON API endpoint | Decoded JSON body | Different parsing; must not use sessions |
| CSV import | One order per line | Loops; no request at all |
| Console command | CLI arguments | No HTTP, no session |
| Cron job | Scheduled trigger | No user, no request |
| Exploratory testing | CLI arguments | Frontend may not exist yet |

**Where each step of the scenario belongs**

| Code | Belongs in | Reason |
|---|---|---|
| Reading `$request->get(...)` | Controller | Delivery-mechanism specific |
| Writing to the session | Controller | Web-only concept |
| Creating + saving the `Order` | Application service | The use case's primary step; one step, not two |
| Sending the confirmation email | Event subscriber *(or the service, via an interface)* | Must happen for every caller |
| Constructing `Swift_Message` | Interface implementation | Infrastructure detail |

## Worked Example

**The chapter opens by taking a wrong turn deliberately, then reasoning its way out.**

**The setup.** After Ch 2 and Ch 3, `orderEbookAction()` reads well — entity, repository, read model, value object all in place. But it still takes a `Request`, writes to a `Session`, and returns a `Response`. By Ch 1's Rule 2, "everything inside `orderEbookAction()` should still be considered infrastructure code."

**Run the CLI thought experiment (Ch 3).** Would a command-line business still need to order e-books? Yes. So it must be decoupled.

**Three tempting wrong answers, examined and rejected:**
1. *Copy the code into the console command.* Two copies of one use case. "A maintenance nightmare."
2. *Move the code to the console command.* Same problem, different infrastructure.
3. *Forge a `Request` and call the controller from the command.* Requires a fake request, a stand-in session service, and then digging the order ID back out of a `Response`. "An ugly workaround."

**The honest objection.** Noback raises it himself: "maybe the whole exercise is too far-fetched? It doesn't even make sense to order e-books from the command-line." His answer isn't that the CLI matters — it's that the CLI is a *stand-in* for real requirements: a JSON API endpoint for a partner's frontend, a CSV import of orders taken at a conference booth, a cron job syncing the catalog. "In each example, the client is of a different type."

**The refactoring.** Extract Variable pushes all `$request->get()` calls to the top and all session writes to the bottom, leaving a clean infrastructure-free middle. Extract Class moves that middle into `EbookOrderService::create()`. Inline Variable cleans up the call site. Introduce Parameter Object collapses three parameters into `CreateOrder`.

**Then the second step — and the real lesson.** The controller also sends a confirmation email. Can it stay? No: the email must fire for *every* caller of `create()`, and the controller isn't every caller.

So move it into the application service. Do that literally and the constructor grows to five dependencies including `Swift_Mailer`, `Twig\Environment`, and a system email address string. Noback flags the discomfort rather than declaring victory: "seeing all these dependencies worries me."

Fix it with an interface named after the *step*, not the tool: `SendOrderConfirmationEmail::send(OrderId, string)`. The service drops back to a single readable line. All the Swift/Twig noise moves into `SendOrderConfirmationEmailWithSwiftMailer`.

**The final move.** Even that isn't Noback's preference. "It works best if the application service only performs the first step, and leaves the other steps to other services." `Order` records an `OrderWasCreated` event in its constructor; the service saves and dispatches; a `SendEmail` subscriber sends the mail. `EbookOrderService` is no longer in charge of email at all.

**One practical note dropped at the end**: real confirmation emails need more than an ID and an address. Introduce a read model that fetches everything in one go, formatted for the email body — and since it's for presentation, "it's actually a view model" (Ch 3).

## Key Takeaways
1. Neither copy nor move use case code to a second entry point. Extract it to a shared application service.
2. The four refactorings run in order: Extract Variable → Extract Class → Inline Variable → Introduce Parameter Object.
3. Primitive-type input is what makes a service reusable — that, not the parameter object, is the answer to "what makes an application service reusable by different clients?"
4. Name the command object after the user's intention (`CreateOrder`), and remember "command" here means intention, not CLI.
5. Any required side effect must live where every caller reaches it — never in the controller.
6. When moving a step in makes the constructor sprout framework types, introduce an interface named after the step. The service should read as a list of steps, not a list of API calls.
7. Prefer one step per application service, with domain events driving the rest. The entity records events; the service dispatches them; subscribers do the remaining work.
8. Introducing the interface before the implementation is a legitimate technique for deferring messy details — as long as you eventually write the implementation.

## Connects To
- **Ch 1**: this chapter finally makes the use case pass Rule 2 — no special context needed.
- **Ch 2**: the `Order` entity and `OrderRepository` the service orchestrates; `Order` gains event recording here.
- **Ch 3**: the CLI thought experiment reused; the `Ebook` read model consumed; view models recommended for email bodies.
- **Ch 5**: service locators — `$this->container->get(...)` still litters these listings and is dealt with next; constructor injection is previewed here.
- **Ch 8**: validation of the command object's data.
- **Ch 11 (§11.4)**: the application service pattern in depth.
- **Ch 11 (§11.5)**: event dispatching and subscribing in depth.
- **Refactoring (Fowler)**: Extract Variable, Extract Class, Inline Variable, Introduce Parameter Object.
- **CQRS**: the command object is the "C".
