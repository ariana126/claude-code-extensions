# Chapter 14: A testing strategy for decoupled applications

## Core Idea
Four test types, each covering one region of the hexagon: **unit tests** for entities and value objects, **adapter tests** for port implementations, **use case tests** for everything inside the hexagon, and a handful of **end-to-end tests** to prove the parts are wired together.

## Frameworks Introduced

- **The four test types, mapped to the architecture:**

  | Test type | Covers | Involves infrastructure? | Speed / stability |
  |---|---|---|---|
  | **Unit test** | Entities, value objects | No | Fast, stable |
  | **Use case test** | Everything inside the hexagon | No | Fast, stable |
  | **Adapter test** (contract / driving) | Port adapters | Yes | Slower, less stable |
  | **End-to-end test** | The whole deployed application | Yes, all of it | Slowest, least stable |

- **The generalized unit test definition.** Michael Feathers' version — a test is *not* a unit test if it (1) talks to the database, (2) communicates across the network, (3) touches the file system, (4) can't run at the same time as other unit tests, (5) needs special environment setup. Noback generalizes:
  > **"A test is not a unit test if it invokes infrastructure code."**
  - Items 1–3 are Rule 1 violations; items 4–5 are Rule 2 violations. Plus the clock and the random device, which Feathers' list omits.
  - "The test framework has 'unit' in its name, so all the tests that this framework runs are usually called 'unit tests'. But the test framework itself can't guarantee that the tests you write and run are true unit tests." Call them **isolated tests** and move the rest to an integration suite.

- **What a unit test is about** — not size, but behavior. "I want a unit test to test the behaviors of an **object**. I don't worry about which classes are involved… So I don't annotate my unit tests with `@covers` annotations either."
  - What gets unit tests: entities and value objects. "These domain objects are great candidates for isolated tests because they have to protect all kinds of domain invariants, which all deserve to be separately tested."
  - What doesn't: "I don't write unit tests for objects that coordinate changes in domain objects, like application services, event subscribers, and repositories."
  - Style: "Ideally each method consists of three statements," using factory methods like `aPaidOrder()` whose "name can be used to describe what's special about the object it returns."

- **Contract test** (for outgoing port adapters) — one test run against every implementation.
  - When to use: when the interface has a *specifiable* contract. Repositories, yes.
  - How: a data provider yields entities; a generator yields every implementation; loop and assert.
  - The rule that makes it valid: "you shouldn't rely on specific behavior of one of the implementations. The test methods should only call methods that are defined on the interface. This guarantees that the implementations follow the **Liskov Substitution Principle**."
  - Realism requirement: "use a real database, preferably the same database that you use in production. **Don't create test doubles for anything.** Make sure this test will expose any problem with the code that would otherwise only show up once the code is running in production."
  - When a contract test *doesn't* work: `VatRateProvider` "just needs to provide some kind of answer, but we can't really define in a contract what a good answer is, other than that it should be an answer of the right type… But this is already guaranteed at the language level." Test the specific implementation instead.

- **The five-option realism ladder for testing against an external service** — best to worst:
  1. Against the real service — most confidence, "may sometimes fail for reasons that you can't do anything about."
  2. Against the third party's sandbox environment.
  3. Against a fake server you run — "great because it shows that you are using your HTTP client correctly: it can make actual HTTP requests."
  4. Against a fake/mock HTTP client from the client library — "puts some trust in your library."
  5. Against a fake/mock of the HTTP client *interface* — "you might make some bad assumptions about how to use the library correctly."
  - Related rule: "don't mock what you don't own." Noback's generalization: **"don't mock an interface whose contract is bigger than the interface itself can describe."**

- **Driving test** (for incoming port adapters) — mock the application, exercise the framework.
  - What it must prove: "whether the port adapter eventually makes the correct call to the application core."
  - **Mock `ApplicationInterface`, and run through the framework**, not by instantiating the controller yourself. Direct instantiation "would leave too many things untested": the hand-built `Request` won't match the framework's, you don't know the framework can instantiate the controller, and you don't know it routes `/create-order` there. "All of these are currently unverified assumptions."
  - Why mock the core: "we shouldn't use integration tests to test core code. Core code allows itself to be tested with unit tests or use case tests, which both run very quickly and are also very stable… Adapter tests are integration tests and are by definition slower and less stable."

- **The adapter-test trade-off** — stated explicitly:
  > "The trade-off is between how many assumptions your test verifies and how fast and stable your tests will be."
  - Noback's position: "keeping the test suite fast and stable is very important… the majority of the tests for incoming adapters shouldn't make actual HTTP requests. They can invoke the framework programmatically and verify 80% of the assumptions." Cover the remaining 20% with a few end-to-end tests.

- **Use case test** — the centerpiece. "Use case tests test use cases, but most importantly they **document the primary actions and their effects**."
  - What you need (the chapter's own list, from the exercise): an interface for the application, a service container, an event dispatcher. **Not** a router, **not** a template renderer.
  - Mechanism: a hand-written `TestServiceContainer` wiring the real core services with in-memory and spy implementations of the outgoing ports.

- **The five hand-written container guidelines:**
  1. Build a hierarchy — `TestServiceContainer` extends `DevelopmentServiceContainer` extends `abstract ServiceContainer`, with a `ProductionServiceContainer` sibling.
  2. "Factory methods should be `private` when possible."
  3. Override with `(abstract) protected` methods; this also lets you "widen the scopes for testing when needed (e.g. in production the `EventDispatcher` might be a private service, but when testing it could be a `public` one)."
  4. "Define services as stateless objects so you can return a new instance… every time." Keep an instance in a property only for stateful services (in-memory repositories, the event dispatcher) or expensive instantiation.
  5. "The constructor of the container can be used to force certain configuration values to be provided. It's recommended to define a configuration value object that provides sensible defaults."

- **Spy over mock** — two reasons, both practical:
  1. With a PHPUnit mock "we can't verify that the right argument (the `OrderId` from the created order) has been provided."
  2. "This approach to creating mock objects is tied to PHPUnit as a test framework. We'll later look at a different test runner for use case tests, so it's smart to stay decoupled from PHPUnit."
  - A spy "will keep a record of what has happened to it, so you can later make assertions about that."

- **The top-down development workflow** — the chapter's practical payoff:
  1. Discuss the feature with stakeholders; challenge the scenarios; find edge cases.
  2. Write them in Gherkin.
  3. Run a **process modelling** session (Ch 11 §11.7) to choose the elements — "the process can be modelled in pseudo-code first (i.e. using sticky notes)."
  4. Program test-driven, jumping between scenarios and unit tests for individual domain objects.
  5. At this point **all Application and Domain code exists and the feature works** — with test doubles as outgoing adapters and `Context` classes as incoming adapters.
  6. Wrap the Infrastructure layer around it: routing, controllers, templates on the left; repositories, migrations, API clients on the right. Test each with adapter tests.
  7. Add a few end-to-end tests — "an interesting option is to reuse the scenarios you wrote for the use case tests. Behat allows you to run the same scenario against a different `Context`."

## Key Concepts
- **Isolated test** — the clearer name for a true unit test.
- **Adapter test** — Noback's name for an integration test, since integrating code *is* a port adapter.
- **Contract test** — one test verifying every implementation of a port.
- **Driving test** — the incoming-port counterpart.
- **Spy** — a test double recording what happened to it.
- **Use case test** — exercises the hexagon, documenting primary actions and their effects.
- **Gherkin / Behat / step definition / `Context` class** — scenario language, runner, glue code, and the class holding it.
- **Living documentation** — scenarios that document, specify, *and* verify.
- **Specification by Example / ATDD / BDD** — the family of practices this belongs to.
- **Liskov Substitution Principle** — what a contract test enforces.

## Mental Models
- **Unit tests are for building blocks; you stop worrying about them once they're safe.** "These tests support development by allowing the developer to specify the behavior of the smaller elements, allowing them to ignore some of those behaviors when the larger elements are being tested… If the building blocks are safe to use, then you don't have to worry about all the details once you start using the blocks to build the bigger structures."
- **Gherkin scenarios don't test anything by themselves.** "It's mainly useful to establish a shared understanding between domain experts and software developers." Automation comes second.
- **Scenarios should be written by developers.** "I think it's a common misconception that scenarios need to be written by business people, not by programmers. I'm afraid this is the reason that many developers don't even think about writing them." The developer discusses, writes, and lets stakeholders verify — "as a bonus, this increases their amount of trust in the development team."
- **Write your own event dispatcher.** Third-party ones "don't have a `dispatchAll()` method, they require a base class for every domain event, or their event objects are mutable. Also, event dispatchers often allow listeners to break the chain and stop propagation… since an event subscriber is a really simple piece of code, you could just write your own and it would not become a maintenance burden."
- **The test container is not the framework's container.** "It only contains services needed by the core of our application, so you won't find a router there, or a template renderer."
- **A use case test proves the `Mailer` is *called*, never that email is *sent*.** "What we also need to prove is that the production implementation of the `Mailer` interface is able to send emails. That would be the job for, you guessed it, an adapter test."
- **Bottom-up building risks building the wrong thing.** "The risk of starting with the smaller elements and working your way up is that in the end it may turn out that you chose the wrong building blocks, or designed them in the wrong way. You may discover this yourself, or you may get some feedback from another stakeholder who isn't happy with the feature."
- **Scenarios tell you when you're done.** "You'll know automatically when the work is done so you won't build more than needed."

## Anti-patterns
- **Calling everything PHPUnit runs a unit test**: the framework can't enforce isolation; you must.
- **`@covers` annotations on behavior tests**: "which classes are involved is somewhat irrelevant."
- **Unit-testing controllers, application services, or repository implementations**: use adapter tests and use case tests instead.
- **Test doubles inside a contract test**: defeats its entire purpose.
- **Calling implementation-specific methods in a contract test**: breaks substitutability.
- **A contract test for a service with no specifiable contract**: verifying `VatRateProvider` returns a `VatRate` tests the type system, not your code.
- **Instantiating the controller directly in an adapter test**: leaves request construction, controller instantiation, and routing unverified.
- **Testing core logic through an adapter test**: slower and less stable than the unit/use case tests that could do it.
- **End-to-end tests peeking at the database**: "An end-to-end test should treat the application as a black box… It should not take a peek inside the database or anything."
- **Many end-to-end tests**: "they tend to be slow and unstable. They break for many unrelated reasons, and those reasons are often not programming or configuration mistakes."
- **Starting a feature with routing, controllers, templates, and migrations**: framework-first, and incompatible with decoupled development.

## Code Examples

Unit test on an entity — three statements, factory method carrying the setup:

```php
final class OrderTest extends TestCase
{
    /** @test */
    public function it_cant_be_cancelled_if_it_has_already_been_paid(): void
    {
        $order = $this->aPaidOrder();

        $this->expectException(CouldNotCancelOrder::class);

        $order->cancel();
    }

    /** @test */
    public function you_can_modify_the_external_reference(): void
    {
        $order = $this->aNewOrder();

        $order->setPaymentReference('ABC123');

        self::assertArrayContainsObjectOfType(
            ExternalReferenceWasModified::class,
            $order->releaseEvents()
        );
    }
}
```

A contract test — every entity variant × every implementation:

```php
final class OrderRepositoryContractTest extends TestCase
{
    /**
     * @test
     * @dataProvider orders
     */
    public function it_can_save_and_load_order_entities(Order $order): void
    {
        foreach ($this->orderRepositories() as $orderRepository) {
            $orderRepository->save($order);

            $fromRepository = $orderRepository->getById($order->orderId());

            self::assertEquals($order, $fromRepository);
        }
    }

    /** @return Generator<OrderRepository> */
    private function orderRepositories(): Generator
    {
        yield new InMemoryOrderRepository();
        yield new OrderRepositoryUsingDoctrineDbal(/* ... */);
    }

    /** @return Generator<array<Order>> */
    public function orders(): Generator
    {
        yield [Order::create(/* ... */)];
        yield [Order::create(/* ... */)->cancel()];
        yield [Order::create(/* ... */)->markAsPaid()];
    }
}
```

A driving test — mock the core, run the real framework:

```php
final class OrderControllerTest extends WebTestCase
{
    public function it_correctly_invokes_createOrder(): void
    {
        $application = $this->createMock(ApplicationInterface::class);
        $application->expects($this->once())
            ->method('createOrder')
            ->with(new CreateOrder(2, 1, 'matthiasnoback@gmail.com'))
            ->will($this->returnValue(new OrderId(1001)));

        $client = self::createClient();
        $client->getContainer()->set(ApplicationInterface::class, $application);

        $client->request('POST', '/create-order', [
            'ebook_id' => '2',
            'quantity' => '1',
            'email_address' => 'matthiasnoback@gmail.com'
        ]);

        self::assertTrue(
            $this->client->getResponse()->isRedirect('/order-details/1001')
        );
    }
}
```

- **What it demonstrates**: four assumptions verified at once — the framework instantiates the controller, routes `/create-order` to it, `CreateOrder::fromRequestData()` extracts the body correctly, and the redirect target is right. No `Order` entity is created, so no secondary actor is needed.
- **The caveat Noback names**: "The `WebTestCase` client doesn't communicate with a web server; it doesn't make an actual HTTP request… once the application runs behind a web server it may still not function correctly."

The spy:

```php
final class MailerSpy implements Mailer
{
    /** @var array<OrderId> */
    private array $emailsSentFor = [];

    public function sendOrderConfirmationEmail(OrderId $orderId): void
    {
        $this->emailsSentFor[] = $orderId;
    }

    /** @return array<OrderId> */
    public function emailsSentFor(): array
    {
        return $this->emailsSentFor;
    }
}
```

The hand-written test container:

```php
final class TestServiceContainer
{
    private ?EventDispatcher $eventDispatcher = null;
    private ?ApplicationInterface $application = null;
    private ?OrderRepository $orderRepository = null;
    private ?Mailer $mailer = null;

    public function eventDispatcher(): EventDispatcher
    {
        if ($this->eventDispatcher === null) {
            $this->eventDispatcher = new ConfigurableEventDispatcher();
            $this->eventDispatcher->addSubscriber(
                OrderWasCreated::class,
                [$this->sendOrderConfirmationEmail(), 'whenOrderWasCreated']
            );
        }

        return $this->eventDispatcher;
    }

    public function application(): ApplicationInterface
    {
        if ($this->application === null) {
            $this->application = new Application(
                $this->orderRepository(),
                $this->eventDispatcher()
            );
        }

        return $this->application;
    }

    private function orderRepository(): OrderRepository
    {
        if ($this->orderRepository === null) {
            $this->orderRepository = new InMemoryOrderRepository();
        }

        return $this->orderRepository;
    }

    // public, and narrowed to MailerSpy so tests can call emailsSentFor()
    public function mailer(): MailerSpy
    {
        if ($this->mailer === null) {
            $this->mailer = new MailerSpy();
        }

        return $this->mailer;
    }
}
```

- **Note on the return type**: narrowing `Mailer` to `MailerSpy` in an override "is still allowed (according to the Liskov Substitution Principle that is)."

The use case test itself — four lines:

```php
$container = new TestServiceContainer();

$orderId = $container->application()->createOrder(
    new CreateOrder(2, 1, 'matthiasnoback@gmail.com')
);

self::assertContainsEqual($orderId, $container->mailer()->emailsSentFor());
```

The same test as a Gherkin scenario plus step definitions:

```gherkin
Feature: Ordering an e-book
  Scenario: the customer receives an order confirmation email
    When a customer creates an order for an e-book
    Then they should receive an order confirmation email
```

```php
final class OrderContext implements Context
{
    private TestServiceContainer $container;
    private ?OrderId $orderId = null;

    public function __construct()
    {
        $this->container = new TestServiceContainer();
    }

    /** @When a customer creates an order for an e-book */
    public function aCustomerCreatesAnOrderForAnEbook(): void
    {
        $this->orderId = $this->container->application()->createOrder(
            new CreateOrder(2, 1, 'matthiasnoback@gmail.com')
        );
    }

    /** @Then they should receive an order confirmation email */
    public function theyShouldReceiveAnOrderConfirmationEmail(): void
    {
        Assert::assertInstanceOf(OrderId::class, $this->orderId);
        Assert::assertContainsEqual(
            $this->orderId,
            $this->container->mailer()->emailsSentFor()
        );
    }
}
```

A builder for read models — "focus only on the relevant values":

```php
final class EbookBuilder
{
    private string $id = 'ad5075f1-be24-4ae1-8ba8-9efec6f4933b';
    private int $price = 2500;
    private string $title = 'The title';

    public static function create(): self { return new self(); }

    public function withTitle(string $title): self
    {
        $this->title = $title;
        return $this;
    }

    public function build(): Ebook
    {
        return new Ebook(
            EbookId::fromString($this->id),
            new Money($this->price, new Currency('EUR')),
            $this->title
        );
    }
}
```

## Reference Tables

**Which test type? (the chapter's exercise, answered)**

| Thing to test | Test type |
|---|---|
| When the customer has paid, they receive an invoice | **Use case test** |
| Creating an order records an `OrderWasCreated` event | **Unit test** |
| `save()` then `getById()` returns an equivalent object | **Adapter test** (contract test) |
| `POST /create-order` calls `ApplicationInterface::createOrder()` | **Adapter test** (driving test) |
| `POST /create-order`, then `/list-orders` shows it | **End-to-end test** |

**What to unit-test, and what not to**

| Element | Unit test? |
|---|---|
| Entity | Yes |
| Value object | Yes |
| Application service | No — use case test |
| Event subscriber | No — use case test |
| Repository implementation | No — adapter test |
| Controller | No — adapter test |

**The four Gherkin advantages**

| Advantage | Why |
|---|---|
| High-level language | "easier to write in more abstract, high-level terms… leaving out the implementation details" |
| Variation | "easier to specify what the behavior should be in slightly different situations" |
| Written before code | "you can validate your understanding with other stakeholders who may not know anything about programming" |
| Living documentation | scenarios document, specify, **and** verify |

## Worked Example

**Building the use case test infrastructure, one gap at a time.**

**The scenario**: "When the customer creates an order, they should receive an order confirmation email."

**Map it to Ch 11's catalog** — five elements plus two services:
1. A `Customer` entity with a `CustomerId`.
2. A `createOrder()` application service method that creates the `Order`, saves it, and dispatches recorded events.
3. An `Order` entity producing `OrderWasCreated`.
4. An `OrderRepository` interface with an in-memory implementation.
5. A `SendOrderConfirmationEmail` subscriber.
Plus: a `Mailer` abstraction and an `EventDispatcher`.

**Write your own event dispatcher.** Third-party ones fail on specifics: no `dispatchAll()`, a required base class for domain events, mutable event objects, and listeners able to stop propagation. "Since an event subscriber is a really simple piece of code, you could just write your own and it would not become a maintenance burden."

**Build a `TestServiceContainer`.** Not the framework's — "it only contains services needed by the core of our application, so you won't find a router there, or a template renderer." Lazy-instantiating factory methods wire `Application` to `InMemoryOrderRepository` and `ConfigurableEventDispatcher`.

**First attempt at the test:**
```php
$orderId = $container->application()->createOrder(new CreateOrder(2, 1, 'matthiasnoback@gmail.com'));
// TODO verify that an email was sent
```

**Attempt 1 at the assertion — a PHPUnit mock `Mailer`**, injected via a `setMailer()` method on the container. It works, and Noback rejects it for two reasons:
1. "We can't verify that the right argument (the `OrderId` from the created order) has been provided."
2. "This approach to creating mock objects is tied to PHPUnit as a test framework. We'll later look at a different test runner for use case tests, so it's smart to stay decoupled from PHPUnit."

Reason 2 is the architectural one — he already knows Behat is coming.

**Attempt 2 — a spy.** `MailerSpy` records every `OrderId` it was asked to mail. Now:
- `setMailer()` disappears; the container instantiates the spy itself, "which makes it automatically available in other tests as well."
- `mailer()` becomes `public` and its return type narrows from `Mailer` to `MailerSpy` — legal under LSP, and it's what gives tests access to `emailsSentFor()`.

The assertion becomes exact, framework-agnostic, and one line:
```php
self::assertContainsEqual($orderId, $container->mailer()->emailsSentFor());
```

**Then the same test in Gherkin.** The `OrderContext` holds the container and the `OrderId` between steps; the two step-definition methods are the same code the PHPUnit test contained. Behat matches each scenario line to an annotated method; an exception means the step failed.

Noback is careful about what this buys: "the scenario itself doesn't test anything. It's mainly useful to establish a shared understanding between domain experts and software developers."

**The honest limit, raised as a sidebar.** "But how do we know if an actual email will be sent?" It doesn't. "We can be certain that the `Mailer` will be called, because the test does prove that. What we also need to prove is that the production implementation of the `Mailer` interface is able to send emails. That would be the job for, you guessed it, an adapter test."

That's the whole strategy in one exchange: each test type proves exactly one thing, and only the union of them proves the feature works.

**Where this lands in the workflow.** After step 5 of the top-down workflow, "the feature is working, but the entire `Infrastructure` layer is still missing. So far the port adapters for outgoing ports are provided by test doubles, and the `Context` classes act as adapters for the incoming ports."

That's a striking statement: you have a working, tested, demonstrable feature with **no controller, no route, no template, and no database table.** Ch 13's claim that test code is an adapter turns out to be literal — `OrderContext` *is* the incoming adapter, and `MailerSpy` and `InMemoryOrderRepository` *are* the outgoing ones.

Then infrastructure gets wrapped around it, and the same Gherkin scenarios get reused end-to-end: "Behat allows you to run the same scenario against a different `Context`. During the first run you would test only core code by making calls to the `ApplicationInterface` directly. During the second run you would start the web server… and test the entire application by making actual HTTP requests."

One scenario, two adapters, two levels of confidence.

## Key Takeaways
1. "A test is not a unit test if it invokes infrastructure code." Call true unit tests *isolated tests* and keep them in a separate suite.
2. Unit-test only entities and value objects. Application services, subscribers, repositories, and controllers get use case tests or adapter tests.
3. A unit test tests an object's behavior, not a class. Skip `@covers`; aim for three statements per test; hide setup in well-named factory methods.
4. Contract tests prove Liskov substitutability. Use the real database, no test doubles, and call only interface methods.
5. Not every port deserves a contract test. If the contract is "returns the right type," the language already enforces it — test the specific implementation instead.
6. When testing against an external service, climb the five-option ladder as far as stability allows. Don't mock an interface whose contract is bigger than the interface can describe.
7. Driving tests mock `ApplicationInterface` and run through the real framework — instantiating the controller yourself leaves routing and request construction unverified.
8. Mock the core in adapter tests. Integration tests are the wrong tool for core logic.
9. Trade assumptions-verified against speed-and-stability. Verify ~80% programmatically; cover the rest with a few end-to-end tests.
10. Use case tests need an application interface, a hand-written service container, and an event dispatcher — no router, no template renderer.
11. Prefer spies to mocks: they capture arguments and keep you independent of the test framework.
12. Write your own event dispatcher; third-party ones bring mutable events, base classes, and stoppable propagation.
13. End-to-end tests treat the application as a black box — no database peeking — and there should be only a few.
14. Work top-down: scenarios → process modelling → test-driven core → infrastructure → end-to-end. You'll get a working feature before writing a single controller.
15. Developers should write the Gherkin. Stakeholders verify it. That's where shared understanding and trust come from.

## Connects To
- **Ch 5**: the "two islands" strategy and the unit-testability property this chapter operationalizes.
- **Ch 6 (§6.4)**: the `VatRateProvider` integration test, repeated here with an injected HTTP client to make the realism point sharper.
- **Ch 7**: the `Clock` abstraction is what lets acceptance tests control time.
- **Ch 9**: "the test suite is an alternative infrastructure for our core code" — this chapter is that claim made concrete.
- **Ch 11**: the design pattern catalog the scenario maps onto; §11.5's event dispatcher; §11.7's process modelling in the workflow.
- **Ch 13**: ports and adapters give the test types their names and boundaries; `InMemoryOrderRepository`, `ApplicationInterface`, and "test code is an adapter" all pay off here.
- **Michael Feathers**: the unit test definition.
- **Behat / Gherkin / Codeception / Panther / Symfony `WebTestCase`**: the tooling.
- **Gáspár Nagy & Seb Rose, "The BDD Books"**; **Gojko Adzic, "Specification by Example"**: further reading on scenario-driven development.
