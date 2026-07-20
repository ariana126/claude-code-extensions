# Chapter 10: A Field Guide to Objects

## Core Idea
A taxonomy of the object types you'll find in a typical web or console application, each with an explicit **recognition test** ("an object is a *X* if…"). They arrange themselves into three layers — infrastructure, application, domain — with dependencies pointing strictly inward.

## Frameworks Introduced

- **The seven object types and their recognition tests**:

  **Controller** — if a front controller calls it (making it an entry point to the service graph, Ch 2 §2.12), it contains infrastructure code revealing the delivery mechanism, and it calls an application service or read model repository.
  - Tell: mentions of `Request`, request parameters, forms, HTML templates, sessions, cookies — or CLI arguments, options, flags, terminal output.
  - Web controllers and console commands are conceptually the same thing; call both "controllers."

  **Application service** — if it performs a single task, contains **no** infrastructure code, and describes one use case of the application (usually one-to-one with a stakeholder feature request).
  - Reads like a recipe: "take an object out of this repository, call a method on it, save it again."
  - Receives **primitive-type** data so the controller doesn't have to convert first; converts to value objects itself.
  - Also known as a "command handler" when invoked with a command object.

  **Write model repository** — if it offers methods for retrieving and saving an object, and its interface hides the underlying technology.

  **Entity** — if it has a unique identifier, has a life cycle, is persisted by and retrievable from a write model repository, uses named constructors and command methods, and produces domain events on instantiation and modification.
  - Has **few or no query methods** — retrieving information is delegated to query objects.

  **Value object** — if it's immutable, wraps primitive data, adds meaning via domain terms (`Year`, not `int`), imposes limitations via validation, and **acts as an attractor of useful behavior** (`Position.toTheLeft(steps)`, `Title.abbreviated()`).

  **Event listener** — if it's an immutable service with injected dependencies, and has at least one method accepting a single domain event argument.
  - Naming convention: class = what you're going to do (`NotifyGroupMembers`); method = why (`whenMeetupRescheduled`).

  **Read model** — if it has only query methods (so it's immutable), is designed for a specific use case, and **all the data needed — and no more — is available the moment you retrieve it** (no extra queries).

- **Abstract vs. concrete — which types get an interface**:
  - **Concrete, no interface**: controllers (rewrite them if you switch frameworks, don't add a second implementation), application services (if the use case changes, the service changes), entities, value objects, read models.
  - **Abstraction + implementation**: repositories (read and write) and any other service reaching outside the application.
  - The rule underneath: *anything that crosses a system boundary gets an interface; anything that expresses your understanding of the domain or a use case does not.*

- **The three layers**, with dependencies pointing only inward:
  - **Infrastructure** (outermost): controllers, repository *implementations*.
  - **Application**: application services, command objects, read models, read model repository *interfaces*, event listeners.
  - **Domain** (innermost): entities, value objects, write model repository *interfaces*.

## Key Concepts
- **Front controller**: The single entry point — `index.php`, Spring's `DispatcherServlet`, `bin/console`.
- **Command object**: A DTO carrying the client's request as one thing from controller to application service.
- **Query object**: An object with only query methods; a read model is one.
- **"Smarter" read model**: One used by an *application service* rather than a view — returns proper value objects instead of primitives, so the service needn't worry about validity. Feels like a write model with no way to write.

## Mental Models
- **Layers as concentric circles.** Infrastructure wraps application, which wraps domain. Nothing inner ever names anything outer.
- **The namespace encodes the layer.** `Infrastructure\UserInterface\Web`, `Application\ScheduleMeetup`, `Domain\Model\Meetup` — the layering is visible in every `use` statement.
- **Value objects attract behavior.** Once `Title` exists, `abbreviated()` has an obvious home. This is the payoff for the extra typing Ch 3 asked for.
- **Design doesn't distinguish domain events from value objects — usage does.** Both are immutable data holders. A domain event is *created and recorded inside an entity, then dispatched*; a value object *models an aspect of* the entity.
- **The read-model-repository / regular-service boundary is genuinely fuzzy.** Is `ExchangeRateProvider` a repository over a "collection" of rates, or just a service? Noback's answer: it doesn't matter. What matters is that both get an abstraction (the question) and an implementation (how it's answered).

## Anti-patterns
- **Infrastructure code inside an application service**: web requests, SQL, filesystem access. That's what disqualifies it.
- **Entities with many query methods**: information retrieval belongs to read models (Ch 8).
- **"Entities in the wild that aren't proper entities"**: Noback's own aside — many so-called entities don't fiercely protect themselves against invalid state, and so don't qualify.
- **Read models requiring extra queries** to fill in what a view needs: the read model wasn't designed for the use case.
- **Interfaces on controllers, application services, entities, or value objects**: they're concrete by nature; an interface adds ceremony with no substitutability benefit.
- **Depending on a repository implementation instead of its interface**: kills testability and framework/database portability.

## Code Examples

An application service — the "recipe," with the layer visible in the namespace:

```php
namespace Application\ScheduleMeetup;

use Domain\Model\Meetup\Meetup;
use Domain\Model\Meetup\MeetupRepository;
use Domain\Model\Meetup\ScheduledDate;
use Domain\Model\Meetup\Title;

final class ScheduleMeetupService
{
    private MeetupRepository meetupRepository;      // the INTERFACE, from Domain

    public function __construct(MeetupRepository meetupRepository) {
        this.meetupRepository = meetupRepository;
    }

    public function schedule(
        string title,                                // primitives in…
        string date,
        UserId currentUserId
    ): MeetupId {
        meetup = Meetup.schedule(                    // …converted to value objects here
            this.meetupRepository.nextIdentity(),
            Title.fromString(title),
            ScheduledDate.fromString(date),
            currentUserId
        );
        this.meetupRepository.save(meetup);
        return meetup.meetupId();
    }
}
```
- **What it demonstrates**: Nothing here knows about HTTP, the CLI, or SQL. The same service backs both the web controller and the console command.

The abstraction/implementation split, across two layers:

```php
namespace Domain\Model\Meetup;               // DOMAIN layer: the interface

interface MeetupRepository
{
    public function save(Meetup meetup): void;
    public function nextIdentity(): MeetupId;
    /** @throws MeetupNotFound */
    public function getById(MeetupId meetupId): Meetup;
}

namespace Infrastructure\Persistence\DoctrineOrm;   // INFRASTRUCTURE layer: the details

final class DoctrineOrmMeetupRepository implements MeetupRepository
{
    private EntityManager entityManager;
    private UuidFactoryInterface uuidFactory;

    public function save(Meetup meetup): void {
        this.entityManager.persist(meetup);
        this.entityManager.flush(meetup);
    }

    public function nextIdentity(): MeetupId {
        return MeetupId.fromString(this.uuidFactory.uuid4().toString());
    }
}
```
- **What it demonstrates**: The dependency arrow points inward — infrastructure knows about domain, never the reverse. Swap Doctrine for anything without touching `ScheduleMeetupService`.

## Reference Tables

| Object type | Layer | Abstraction? | Recognize by |
|---|---|---|---|
| Controller | Infrastructure | No | Framework/delivery-mechanism vocabulary |
| Application service | Application | No | One use case, no infrastructure code |
| Command object (DTO) | Application | No | Public primitive properties |
| Read model | Application | No | Query methods only, use-case shaped |
| Read model repository | Application (interface) / Infrastructure (impl) | **Yes** | Returns read models for one use case |
| Event listener | Application | No | `when…(DomainEvent)` methods |
| Entity | Domain | No | Identity + life cycle + records events |
| Value object | Domain | No | Immutable, validated, behavior-attracting |
| Write model repository | Domain (interface) / Infrastructure (impl) | **Yes** | `getById()` / `save()`, technology hidden |

| Controller calls… | When it should… |
|---|---|
| An application service | Produce an effect — change state, send an email |
| A read model repository | Return information the client requested |

## Worked Example

**Scheduling a meetup, traced through every layer** — the chapter's integrating example.

```php
// ── INFRASTRUCTURE ──────────────────────────────────────────────
namespace Infrastructure\UserInterface\Web;

final class MeetupController extends AbstractController
{
    public function scheduleMeetupAction(Request request): Response {
        form = this.createForm(ScheduleMeetupType.className);
        form.handleRequest(request);
        if (form.isSubmitted() && form.isValid()) {
            // hand primitives to the application service
            return new RedirectResponse('/meetup-details/' . meetup.meetupId());
        }
        return this.render('scheduleMeetup.html.twig', ['form' => form.createView()]);
    }
}

// The same use case from the terminal — a different controller, same service
namespace Infrastructure\UserInterface\Cli;

final class ScheduleMeetupCommand extends Command
{
    protected function configure() {
        this.addArgument('title', InputArgument.REQUIRED)
            .addArgument('date', InputArgument.REQUIRED);
    }
    public function execute(InputInterface input, OutputInterface output) {
        title = input.getArgument('title');
        date  = input.getArgument('date');
        // ... call the same ScheduleMeetupService ...
        output.writeln('Meetup scheduled');
    }
}

// ── APPLICATION ─────────────────────────────────────────────────
// Optionally, a command object carries the request as one thing:
namespace Application\ScheduleMeetup;

final class ScheduleMeetup {          // a DTO — public, primitive, easy to build
    public string title;
    public string date;
}

final class ScheduleMeetupService {
    public function schedule(ScheduleMeetup command, UserId currentUserId): MeetupId {
        meetup = Meetup.schedule(
            this.meetupRepository.nextIdentity(),
            Title.fromString(command.title),
            ScheduledDate.fromString(command.date),
            currentUserId
        );
        // ...
    }
}

// ── DOMAIN ──────────────────────────────────────────────────────
namespace Domain\Model\Meetup;

final class Meetup {
    private array events = [];
    private MeetupId meetupId;
    private Title title;
    private ScheduledDate scheduledDate;
    private UserId userId;

    private function __construct() {}

    public static function schedule(
        MeetupId meetupId, Title title, ScheduledDate scheduledDate, UserId userId
    ): Meetup {
        meetup = new Meetup();
        meetup.meetupId = meetupId;
        meetup.title = title;
        meetup.scheduledDate = scheduledDate;
        meetup.userId = userId;
        meetup.recordThat(new MeetupScheduled(meetupId, title, scheduledDate, userId));
        return meetup;
    }

    public function reschedule(ScheduledDate scheduledDate): void {
        // ...
        this.recordThat(new MeetupRescheduled(this.meetupId, scheduledDate));
    }

    private function recordThat(object event): void { this.events[] = event; }
    public function releaseEvents(): array { return this.events; }
    public function clearEvents(): void { this.events = []; }
}

final class Title {
    private string title;
    private function __construct(string title) {
        Assertion.notEmpty(title);
        this.title = title;
    }
    public static function fromString(string title): Title { return new Title(title); }
    public function abbreviated(string ellipsis = '...'): string { /* ... */ }
}

// ── Back out through APPLICATION: dispatching what the entity recorded ──
final class RescheduleMeetupService {
    public function reschedule(MeetupId meetupId, /* ... */): void {
        meetup = /* ... */;
        meetup.reschedule(/* ... */);
        this.dispatcher.dispatchAll(meetup.recordedEvents());
    }
}

final class NotifyGroupMembers {                       // class = what; method = why
    public function whenMeetupRescheduled(MeetupRescheduled event): void {
        // Send an email to group members using data from the event
    }
}

// ── And the read side, entirely separate ────────────────────────
namespace Application\UpcomingMeetups;

final class UpcomingMeetup {          // read model: primitives, use-case shaped
    public string title;
    public string date;
}

interface UpcomingMeetupRepository {
    /** @return UpcomingMeetup[] */
    public function upcomingMeetups(DateTime today): array;
}

namespace Infrastructure\ReadModel;

final class UpcomingMeetupDoctrineDbalRepository implements UpcomingMeetupRepository {
    public function upcomingMeetups(DateTime today): array {
        rows = this.connection./* ... */;              // straight to the data source
        return array_map(function (array row) {
            upcomingMeetup = new UpcomingMeetup();
            upcomingMeetup.title = row['title'];
            upcomingMeetup.date  = row['date'];
            return upcomingMeetup;
        }, rows);
    }
}
```

Note `Title.abbreviated()` — a value object attracting behavior — and that the read path never touches `Meetup` at all.

## Key Takeaways
1. Each object type has a recognition test; if an object fails all of them but still follows the book's rules, that's fine.
2. Controllers are infrastructure. Application services must be free of it — that's what makes one service serve both web and CLI.
3. Application services take primitives and convert to value objects themselves, so controllers do no domain work.
4. Entities have identity, a life cycle, named constructors, command methods, and recorded events — and few query methods.
5. Interfaces go on things that cross system boundaries (repositories, external services). Not on controllers, application services, entities, value objects, or read models.
6. Three layers — infrastructure → application → domain — with dependencies only inward. Put layer names in namespaces.
7. Inward-only dependencies buy two things: testing without a live database, and surviving framework or database swaps.
8. Value objects and domain events look identical structurally; usage distinguishes them.

## Connects To
- **Ch 2 §2.12**: controllers as entry points to the immutable service object graph
- **Ch 3 & 4**: entities and value objects get their formal recognition tests here
- **Ch 7 §7.2 / Ch 9 §9.5**: event listeners placed in the application layer
- **Ch 8**: read models and read model repositories located in the architecture
- **Hexagonal Architecture / Ports and Adapters, Clean Architecture, Onion Architecture**: §10.8 is the same layering; Ch 11 names them
- **Domain-Driven Design**: entities, value objects, repositories, domain events, application services
