# Chapter 7: Performing Tasks

## Core Idea
A command method performs one task, has an imperative name and a `void` return type, and delegates its *secondary* effects to event listeners. Services stay immutable inside as well as out — no accumulated state between calls. And unlike queries, calls to commands **are** worth asserting on.

## Frameworks Introduced

- **Command method**: Imperative name, `void` return, produces a side effect. `sendReminderEmail()`, `saveRecord()`, `changePassword()`.

- **Three guiding questions for "is this method too big?"**:
  1. Does the method name have — or want — an "and" in it?
  2. Do all lines contribute to the *main* job?
  3. Could part of this work run in a background process?
  - Three yeses means split it. `changeUserPassword()` that also mails the user "might as well have been named `changeUserPasswordAndSendAnEmailAboutIt()`."

- **Use events to perform secondary tasks**: Dispatch a domain event after the primary action; register listeners for the effects.
  - When to use: a command has a clear main job plus follow-on effects.
  - Why it works: you can add effects without touching the original method; the original object stops carrying dependencies it only needs for effects; effects can move to a background process.
  - **The cost, and Noback's mitigations**: cause and effect end up in distant parts of the codebase. Fix by (a) making it team knowledge that events decouple, so readers reach for "find usages"; (b) **always dispatching explicitly** — a visible `eventDispatcher.dispatch()` call signals that more is about to happen. Never dispatch implicitly.

- **The reinstantiation test for service statelessness**: *"Could I reinstantiate this service before every method call and still get the same behavior?"*
  - If no, the service accumulates state. A `Mailer` that remembers `sentTo` fails: reinstantiating it would send duplicate emails.
  - The fix is rarely "add a flag" — it's to **push the invariant into a value object**. A `Recipients` collection that cannot contain duplicates makes the deduplication logic unnecessary everywhere else.

- **Abstraction, then generalization** (in that order): Introduce an interface with a specific, higher-level method first. Only after **about three cases** show the same shape should you generalize into a generic interface.
  - Why the ordering matters: generalizing early means revising the interface and every implementation for each new case you didn't anticipate.

- **Mock/spy for commands, never for queries**: A command is supposed to be called *at least once* (it's part of the job) and *not more than once* (side effects shouldn't repeat) — both worth asserting. Queries are side-effect free, so call count is an implementation detail.

## Key Concepts
- **Event listener**: A service with a `when…` method invoked when a matching event is dispatched — `SendEmail.whenUserPasswordChanged()`.
- **Event dispatcher**: Maps event types to listeners; listeners configured at construction time only (Ch 2 §2.9).
- **Mock**: A test double that declares expectations up front (`expects(once())`) and self-verifies at test end.
- **Spy**: A test double that records the calls made to it, so you write a normal assertion afterward.
- **Generalization**: Making an abstraction's types and methods more generic after seeing repeated shape.

## Mental Models
- **Separate the main job from its effects.** Changing a password is the job; the notification email, the upload folder, the queue message are effects.
- **Command chains may contain queries; query chains may not contain commands.** The asymmetry is the whole point of CQS — a command already has side effects, so gathering information along the way costs nothing.
- **A query-then-command pair on the same object is a conversation that should have happened inside it.** `if (obstacle.isOnTheRight()) player.moveLeft();` → `player.evade(obstacle)`. The object keeps the knowledge and can evolve its behavior freely.
- **Immutable services don't need to be shared.** Service containers share instances for performance; if your services are truly immutable, sharing is optional — except for genuine resources like database connections.

## Anti-patterns
- **Command methods that do the job *and* its effects**: the name lies, and the object carries dependencies it only needs for the secondary work.
- **Services that accumulate state across calls** (`Mailer.sentTo`): behavior differs between the first and second call with the same arguments.
- **Implicit event dispatching**: hidden effects with no signal in the code that anything else happens.
- **Returning a special value to signal failure**: throw instead — `InvalidArgumentException` if the argument was inspectably wrong, `RuntimeException` otherwise.
- **Abstracting only the transport**: `Queue` is the abstraction; `rabbitMqConnection.publish(...)` inline is not.
- **Generalizing on the first or second case**: you'll rewrite the interface and every implementation.
- **Mocking query methods**: couples tests to the implementation — a refactor that calls a query twice instead of caching it breaks the test for no reason.

## Code Examples

Splitting a command with an event:

```php
// Before — changeUserPassword AND sendAnEmailAboutIt
public function changeUserPassword(UserId userId, string plainTextPassword): void
{
    user = this.repository.getById(userId);
    hashedPassword = /* ... */;
    user.changePassword(hashedPassword);
    this.repository.save(user);
    this.mailer.sendPasswordChangedEmail(userId);      // secondary effect, wrong place
}

// After — the primary action dispatches; a listener handles the effect
final class UserPasswordChanged
{
    private UserId userId;
    public function __construct(UserId userId) { this.userId = userId; }
    public function userId(): UserId { return this.userId; }
}

public function changeUserPassword(UserId userId, string plainTextPassword): void
{
    user = this.repository.getById(userId);
    hashedPassword = /* ... */;
    user.changePassword(hashedPassword);
    this.repository.save(user);
    this.eventDispatcher.dispatch(new UserPasswordChanged(userId));   // explicit signal
}

final class SendEmail
{
    public function whenUserPasswordChanged(UserPasswordChanged event): void {
        this.mailer.sendPasswordChangedEmail(event.userId());
    }
}
```
- **What it demonstrates**: `Mailer` is no longer a dependency of the password-changing service. Adding a third effect later requires zero changes to `changeUserPassword()`.

Abstraction first, generalization only after ~3 cases:

```php
// Step 1 — abstraction: an interface with a specific, higher-level method
interface Queue {
    public function publishUserPasswordChangedEvent(UserPasswordChanged event): void;
}

final class RabbitMQQueue implements Queue {
    public function publishUserPasswordChangedEvent(UserPasswordChanged event): void {
        this.rabbitMqConnection.publish(
            'user_events', 'user_password_changed',
            json_encode(['user_id' => (string)event.userId()])
        );
    }
}

// Step 2 — generalization, ONLY after several publish...Event() methods look alike
interface CanBePublished {
    public function queueName(): string;
    public function eventName(): string;
    public function eventData(): array;
}

final class RabbitMQQueue implements Queue {
    public function publish(CanBePublished event): void {
        this.rabbitMqConnection.publish(
            event.queueName(), event.eventName(), json_encode(event.eventData())
        );
    }
}
```

## Reference Tables

| Method under test calls… | Use | Why |
|---|---|---|
| `save(User): void` — a command | **Mock** or **spy** | Verify it was called, once, with the right argument |
| `getById(UserId): User` — a query | **Dummy**, **stub**, or **fake** | Never assert on the calls |

| Failure in a command | Exception |
|---|---|
| Empty string for a required `key` | `InvalidArgumentException` — inspectable from the argument |
| Entity ID already in use | `RuntimeException` — only knowable at runtime |

| Chain starts with a… | May it contain a…? |
|---|---|
| Query | Command — **no** (would hide a side effect) |
| Command | Query — **yes** (gathering information is free) |

## Worked Example

**Making a stateful service stateless** — Noback's best demonstration that "add a guard" is the wrong instinct.

```php
// Problem: Mailer remembers who it has emailed. It fails the reinstantiation test.
final class Mailer
{
    private array sentTo = [];

    public function sendConfirmationEmail(EmailAddress recipient): void {
        if (in_array(recipient, this.sentTo)) { return; }
        // Send the email here...
        this.sentTo[] = recipient;
    }
}

// Intermediate fix — move deduplication to the argument. Mailer is stateless again,
// but it still has to know to call the special uniqueEmailAddresses() method.
final class Mailer
{
    public function sendConfirmationEmails(Recipients recipients): void {
        foreach (recipients.uniqueEmailAddresses() as emailAddress) { /* send */ }
    }
}

// Better — make duplicates impossible in the first place. The invariant lives
// in Recipients, so there is nothing left for Mailer to remember or check.
final class Recipients
{
    private array emailAddresses;

    private function __construct(array emailAddresses) {
        this.emailAddresses = emailAddresses;
    }

    public static function emptyList(): Recipients {
        return new Recipients([]);
    }

    public function with(EmailAddress emailAddress): Recipients {
        if (in_array(emailAddress, this.emailAddresses)) {
            return this;                                  // already present, no-op
        }
        return new Recipients(array_merge(this.emailAddresses, [emailAddress]));
    }

    public function emailAddresses(): array {
        return this.emailAddresses;
    }
}
```

Three chapters converge here: the immutable modifier returning a copy (Ch 4), the value object protecting a domain invariant (Ch 3), and the stateless service (Ch 2). `uniqueEmailAddresses()` disappears because uniqueness is no longer a thing anyone has to *do*.

**And the mock/spy choice**, two ways to test the same dispatch:

```php
// With a mock — the framework verifies; no assertion line at the end
/** @test */
public function it_dispatches_a_user_password_changed_event(): void
{
    eventDispatcherMock = this.createMock(EventDispatcher.className);
    eventDispatcherMock
        .expects(this.once())
        .method('dispatch')
        .with(new UserPasswordChanged(userId));

    service = new ChangePasswordService(eventDispatcherMock, /* ... */);
    service.changeUserPassword(userId, /* ... */);
}

// With a hand-written spy — an ordinary assertion, easier to read and refactor
final class EventDispatcherSpy implements EventDispatcher
{
    private array events = [];
    public function dispatch(object event): void { this.events[] = event; }
    public function dispatchedEvents(): array { return this.events; }
}

/** @test */
public function it_dispatches_a_user_password_changed_event(): void
{
    eventDispatcher = new EventDispatcherSpy();
    service = new ChangePasswordService(eventDispatcher, /* ... */);
    service.changeUserPassword(userId, /* ... */);

    assertEquals([new UserPasswordChanged(userId)], eventDispatcher.dispatchedEvents());
}
```

## Key Takeaways
1. Command methods: imperative name, `void`, one job.
2. Apply the three questions ("and" in the name / all lines on-task / could it run in background) and split via events.
3. Always dispatch events explicitly — the visible `dispatch()` call is what keeps distant effects discoverable.
4. Apply the reinstantiation test to every service; fix failures by moving the invariant into a value object, not by adding internal flags.
5. Throw on failure — never a special return value.
6. Commands may call queries; queries may never call commands.
7. A query-then-command pair on the same object means the decision belongs inside that object.
8. Abstract when crossing a system boundary; generalize only after roughly three similar cases.
9. Mocks and spies are for commands; dummies, stubs, and fakes are for queries.

## Connects To
- **Ch 2 §2.9**: services immutable from the outside; §7.3 closes the loophole from the inside
- **Ch 4 §4.12**: entities record events internally; here services dispatch them outward
- **Ch 5 §5.2**: the exception rules applied to task failures
- **Ch 6 §6.5–6.6**: the query counterparts — abstractions and (non-)verified test doubles
- **Ch 8**: dispatched domain events become the source for building read models
- **Ch 9**: event listeners as a way to add behavior without modifying existing services
