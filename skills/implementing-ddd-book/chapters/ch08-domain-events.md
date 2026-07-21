# Chapter 8: Domain Events

## Core Idea
Capture "something happened that domain experts care about" as an explicit, immutable, past-tense Domain Event published from an Aggregate — then use those Events to achieve eventual consistency between Aggregates, to eliminate batch processing, and to keep Bounded Contexts across the enterprise autonomous.

## Frameworks Introduced
- **Domain Event modeling**: "Model information about activity in the domain as a series of discrete events. Represent each event as a domain object." [Evans, Ref]
  - When to use: listen for the domain-expert phrases **"When . . ."**, **"If that happens . . ."**, **"Inform me if . . ." / "Notify me if . . ."**, **"An occurrence of . . ."** — and for cross-team requirements where occurrences must be communicated across Bounded Contexts.
  - How: (1) derive the name from the command that caused it, stated in the past tense (`BacklogItem#commitTo(Sprint)` → `BacklogItemCommitted`); (2) name Event and properties per the Ubiquitous Language of the Context where it *originates*; (3) give it an `occurredOn` timestamp via the minimal `DomainEvent` interface; (4) add the identity of every Aggregate involved (`BacklogItemId`, `SprintId`), plus `TenantId` in a multitenant environment even though it wasn't a command parameter; (5) include whatever would be needed to *trigger the Event again* — command parameters and useful state transitions; (6) give it a full-state constructor and read accessors only — Events are immutable, and any derived-state behavior must be Side-Effect Free.
  - Why it works: the Event names the business occurrence itself, so subscribers know exactly what happened and when, replacing complex catch-up queries with immediate, contextual reactions. Failure mode: modeling every command outcome as an Event when experts don't care — know when to disregard extraneous happenings (Event Sourcing is the exception, where Events are deliberately more prolific).
  - **Event enrichment**: add state or derived operations when subscribers would otherwise have to query back on the source Aggregate; more common under Event Sourcing.

- **Events with Aggregate characteristics**: model an Event as an Aggregate with its own Repository when it is created by direct client request rather than as the outcome of Aggregate behavior.
  - How: (1) keep it immutable; (2) assign a *generated* unique identity (so later design changes can't break uniqueness) rather than relying on property-based identity; (3) the Repository must not permit removal — it records the past; (4) implement `equals()`/`hashCode()`; (5) have a Domain Service create it, add it to the Repository, and publish it — which requires Repository and messaging to share a persistence store, or a global XA transaction.

- **Event identity — when it is needed**: usually a Value-style identity (Event name/type + Aggregate identities + timestamp) is sufficient. Assign formal unique identity when (a) the Event is modeled as an Aggregate, (b) Events must be compared and their properties don't distinguish them, or (c) Events are published outside the local Bounded Context, where redelivery is possible and remote subscribers need an ID for de-duplication. Some messaging infrastructures supply a message ID in the header, making a model-generated one unnecessary.

- **Lightweight Publish-Subscribe (`DomainEventPublisher`)**: an in-process Observer that lets the model publish Events without ever coupling to messaging middleware.
  - How it works: subscribers and a `publishing` flag are held in `ThreadLocal`s (one request = one thread); a Web filter calls `reset()` at the start of each request so pooled threads don't inherit stale subscribers; Application Services call `subscribe()` *before* invoking Event-generating Aggregate behavior; `publish()` iterates subscribers, filtering on `subscribedToEventType()` (a subscriber answering `DomainEvent.class` receives all Events) and invoking `handleEvent()`; neither `subscribe()` nor `publish()` may run while publishing, preventing concurrent modification from nested publishes.
  - Consequence: all subscribers run synchronously, on the same thread, inside the same transaction — normally the one the Application Service controls.

- **Model/Event persistence consistency — three options** (the model store and the Event delivery store must always agree):
  1. Domain model and messaging infrastructure share one persistence store — single local transaction, good performance; requires the messaging product's tables to live in your schema, and isn't always possible.
  2. Global XA (two-phase commit) across separate stores — keeps them separate; needs XA support everywhere, is expensive and slow.
  3. **Event Store** in the model's own persistence store, owned by your Bounded Context, drained by a custom out-of-band forwarder — guarantees model+Event consistency in one local transaction, enables REST notification feeds, keeps the messaging store private; costs you a custom forwarder and requires clients to de-duplicate. **This is the approach Vernon uses.**

- **Event Store — six benefits**: (1) a queue for publishing Events through messaging middleware; (2) feeding REST-based notifications to polling clients; (3) a historical record of every command outcome, for debugging model *and* clients (an Event Store is not merely an audit log); (4) trending, forecasting, business analytics; (5) reconstituting Aggregates on retrieval — Event Sourcing, with periodic snapshots (e.g. every 100 Events); (6) undoing blocks of changes by removing/marking Events, or patching/inserting Events to correct bugs in the stream.

## Key Concepts
- **Domain Event**: an immutable domain object representing something that happened that domain experts care about, named in the past tense.
- **`DomainEvent` interface**: the minimal contract every Event implements — a single `occurredOn()` accessor.
- **`DomainEventPublisher`**: thread-bound, in-process Publish-Subscribe component; the model's only publishing dependency.
- **`DomainEventSubscriber`**: handler pair of `handleEvent()` plus `subscribedToEventType()` (the type filter).
- **Event Store / `StoredEvent`**: an append-only table of serialized Events (`eventId`, `eventBody` JSON, `occurredOn`, `typeName`).
- **`Notification`**: an Event wrapper carrying type name, notification identity (the `StoredEvent` `eventId`), timestamp, and the Event itself.
- **`NotificationLog`**: a fixed-size (20) page of Notifications published as a RESTful resource; either *current* or *archived*.
- **Archived log**: a full, immutable log — identical on every request, therefore cacheable indefinitely.
- **`PublishedMessageTracker`**: application-layer record of the most recently published `StoredEvent` id per topic/exchange type.
- **Autonomous service**: a coarse-grained business service that avoids in-band RPC, integrating through asynchronous messaging instead.
- **Idempotent operation**: one that can execute two or more times in succession with results identical to executing it once.

## Mental Models
- Think of an Event as *the past tense of a command*: the command is the cause, the Event is the recorded fact.
- Use Events to replace nightly batch jobs: instead of running expensive catch-up queries to discover what happened, react to each discrete occurrence as it happens, spreading the work into short spurts across the day.
- Treat the Event contract as **domain-wide**, at least enterprise-broad — not a private Bounded Context concept. If an Event lacks what a subscriber needs, version it or design a new one rather than letting the subscriber query back.
- Think of the RESTful notification feed as an Atom feed: the client, not the server, tracks its position; the server just publishes stable, cacheable pages.
- Ask "how did this business work before computers?" to calibrate latency tolerance — seconds, minutes, hours, or even days between consistent states are often entirely acceptable.

## Anti-patterns
- **Modifying a second Aggregate instance inside an Event handler**: violates the modify-one-Aggregate-instance-per-transaction rule; all other consistency must be achieved asynchronously.
- **Coupling the domain model to messaging middleware**: middleware belongs only in Infrastructure; the model publishes through the lightweight Observer.
- **Present-tense or command-shaped Event names**: the occurrence already happened; the name must say so.
- **Carrying whole objects in Events / replicating foreign models**: correctly designed Events rarely carry entire objects — at minimum a foreign Aggregate's identity. If you must nearly replicate the foreign model, that's a modeling error (or a case where RPC is genuinely unavoidable).
- **In-band RPC between systems**: a remote system's unavailability or load becomes your failure; risk multiplies with each RPC dependency. Don't give in to RPC too easily.
- **Using the REST notification style as a Queue**: it is a fan-out pull model; many producers feeding one or a few order-sensitive consumers will break down under polling.
- **Assuming exactly-once delivery**: unacknowledged messages get redelivered, and a `PublishedMessageTracker` commit can fail after the broker accepted the messages — subscribers must de-duplicate.
- **De-duplicating by "highest message ID seen"** under messaging middleware: messages arrive out of order, so tracking only the most recent ID silently drops valid Events. (Under the REST style this *is* safe, since logs are traversed in order.)

## Code Examples
```java
public class DomainEventPublisher {
    private static final ThreadLocal<List> subscribers = new ThreadLocal<List>();
    private static final ThreadLocal<Boolean> publishing =
            new ThreadLocal<Boolean>() {
        protected Boolean initialValue() { return Boolean.FALSE; }
    };

    public static DomainEventPublisher instance() {
        return new DomainEventPublisher();
    }

    public <T> void publish(final T aDomainEvent) {
        if (publishing.get()) { return; }
        try {
            publishing.set(Boolean.TRUE);
            List<DomainEventSubscriber<T>> registered = subscribers.get();
            if (registered != null) {
                Class<?> eventType = aDomainEvent.getClass();
                for (DomainEventSubscriber<T> subscriber : registered) {
                    Class<?> subscribedTo = subscriber.subscribedToEventType();
                    if (subscribedTo == eventType ||
                        subscribedTo == DomainEvent.class) {
                        subscriber.handleEvent(aDomainEvent);
                    }
                }
            }
        } finally {
            publishing.set(Boolean.FALSE);
        }
    }

    public DomainEventPublisher reset() {
        if (!publishing.get()) { subscribers.set(null); }
        return this;
    }

    public <T> void subscribe(DomainEventSubscriber<T> aSubscriber) {
        if (publishing.get()) { return; }
        List<DomainEventSubscriber<T>> registered = subscribers.get();
        if (registered == null) {
            registered = new ArrayList<DomainEventSubscriber<T>>();
            subscribers.set(registered);
        }
        registered.add(aSubscriber);
    }
}
```
- **What it demonstrates**: the whole publishing mechanism — thread-bound subscriber lists, the `DomainEvent.class` wildcard filter, the re-entrancy guard, and `reset()` for pooled threads — with zero infrastructure coupling, so an Aggregate can simply call `DomainEventPublisher.instance().publish(new BacklogItemCommitted(...))`.

## Reference Tables

### Two architectural styles for forwarding stored Events
| | Notifications as RESTful resources | Messaging middleware (e.g. RabbitMQ fanout exchange) |
|---|---|---|
| Model | Pull; clients `GET` a well-known URI | Push; broker delivers to registered subscribers |
| Subscriber registry | None — publisher keeps no subscriber list | Broker maintains subscribers/listeners |
| Position tracking | **Client** stores the most recently applied notification id | Publisher stores `PublishedMessageTracker` per exchange |
| Ordering | Guaranteed by log traversal (chronological application) | Messages can arrive out of order |
| De-duplication | Effectively unnecessary — client saves only the last applied id | **Required** — Idempotent Receiver, tracking topic + message ID of every handled message |
| Scaling | HTTP caching: current log `max-age=60`, archived logs `max-age=3600` (immutable); server cache warmed by any client | Broker handles delivery guarantees, load, and retries |
| Best fit | Fan-out Publish-Subscribe to many consumers | Publish-Subscribe *or* Queues; ordered task feeds |
| Weak fit | Queue semantics (few consumers, many producers, strict sequence) | Requires operating and depending on middleware |

### Notification log mechanics
| Element | Rule |
|---|---|
| Log size | 20 notifications maximum |
| Current log | Holds at most 19 (possibly 0); auto-archived on reaching 20 |
| Log identity | Encoded low,high range (`61,80`) — stable for the whole lifetime even before the log fills, so caching works |
| Hypermedia | `Link: <…/61,80>; rel=self`, `rel=previous`, `rel=next`; the current log never has `rel=next` |
| Immutability | Events already in a log never change; archived logs are guaranteed identical on every request |
| Persistence | Logs and Notifications are never persisted — they're manufactured on demand from `StoredEvent` rows |

## Worked Example
**`BacklogItemCommitted`, end to end.** The requirement: "Allow each backlog item to be committed to a sprint. . . . *When the backlog item is committed, notify the sprint and other interested parties.*"

1. **Name it.** Command `BacklogItem#commitTo(Sprint)` → Event `BacklogItemCommitted`. The team considered the more verbose `BacklogItemCommittedToSprint` but, since in Scrum a backlog item is only ever committed to a sprint (releases are *scheduled*, not committed), the compact name is unambiguous.
2. **Give it properties.** `occurredOn`, `backlogItemId` (what it happened on), `committedToSprintId` (what it happened with — required because a subscriber must notify the `Sprint`), and `tenantId` (needed locally to query both Repositories, and remotely so foreign Contexts know which tenant applies), even though it was never a command parameter. Full-state constructor, read accessors only.
3. **Publish it.** `commitTo()` ends with `DomainEventPublisher.instance().publish(new BacklogItemCommitted(tenantId(), backlogItemId(), sprintId()))`.
4. **Subscribe locally.** A `MessageConsumer` receiving `"BacklogItemCommitted"` initially fetched the `Sprint` and `BacklogItem` from Repositories and called `sprint.commit(backlogItem)` directly — but who manages the transaction? Refactored to delegate to `ApplicationServiceRegistry.sprintService().commitBacklogItem(tenantId, sprintId, backlogItemId)`, so the Application Service owns the transaction, in harmony with Hexagonal Architecture. De-duplication is unnecessary here because committing an already-committed `BacklogItem` is idempotent.
5. **Store every Event.** In the Identity and Access Context an `@Aspect` component, `IdentityAccessEventProcessor`, intercepts every Application Service method (`@Before("execution(* …application.*.*(..))")`) and registers a wildcard subscriber returning `DomainEvent.class`; `handleEvent()` delegates to `EventStore.instance().append()`, which JSON-serializes the Event into a `StoredEvent` (`typeName`, `occurredOn`, `eventBody`) row with a database-generated `eventId`.
6. **Publish outward, REST style.** `NotificationService.currentNotificationLog()` computes the current log id arithmetically from `countStoredEvents()` (`remainder = count % 20`, `low = count - remainder + 1`, `high = low + 19`), loads `allStoredEventsBetween(low, high)`, wraps each in a `Notification`, and returns a `NotificationLog` — served by a JAX-RS `NotificationResource` at `/notifications` and `/notifications/{id}`.
   *Client walk-through:* logs hold notifications 1–65; the client has applied through 58. It `GET`s `//iam/notifications` (the current log, 61–80, containing 61–65), doesn't find 58, follows `rel=previous` to `//iam/notifications/41,60`, probes back 60 → 59 → 58, finds its marker, then applies forward 59, 60, follows `rel=next` back to the current log, applies 61–65, and stops (the current log has no `rel=next`).
7. **Publish outward, messaging style.** `publishNotifications()` loads the `PublishedMessageTracker` for exchange `saasovation.identity_access`, queries `allStoredEventsSince(mostRecentPublishedMessageId)`, sends each through a fanout `MessageProducer` with `MessageParameters` carrying Event type, notification id (unique message ID for de-duplication) and `occurredOn` — so subscribers can route without parsing the JSON body — then updates the tracker. A JMX `TimerMBean` `NotificationListener` invokes it on a recurring interval; because the timer keeps firing, a failed run self-heals once infrastructure problems are cleared. Because the tracker and the broker commit separately, the failure sequence "messages sent → tracker commit fails → republish" delivers duplicates, which is precisely why subscribers must implement Idempotent Receiver.

## Key Takeaways
1. Mine domain-expert speech for "When…", "If that happens…", "Notify me if…", "An occurrence of…" — those phrases mark Events, and once agreed they become part of the Ubiquitous Language.
2. Name Events in the past tense after the command that caused them, and carry enough state — including the Aggregate identities and `TenantId` — to trigger the Event again.
3. Publish from the Aggregate through a lightweight, thread-bound `DomainEventPublisher`; never let the model see messaging middleware.
4. Register subscribers from Application Services (sometimes Domain Services) *before* executing the Event-generating behavior, and never modify a second Aggregate in a handler — use asynchronous delivery for that.
5. Keep the model's persistence store and the Event delivery store consistent; prefer an Event Store in your own store with an out-of-band forwarder over shared stores or XA.
6. An Event Store is not an audit log — it is a publishing queue, a REST feed source, a debugging record, an analytics source, and the foundation of Event Sourcing.
7. Choose REST notification logs for fan-out to many polling consumers (HTTP caching does the scaling work); choose messaging middleware when you need push, queues, or broker-managed delivery.
8. Assume duplicate delivery under messaging: make the subscriber (not necessarily the domain object) idempotent by tracking handled topic+message IDs, committed together with the local model changes.
9. Establish latency tolerances explicitly with domain experts — eventual consistency measured in seconds to hours is usually acceptable, and it buys autonomy plus freedom from two-phase commits.

## Connects To
- **ch02**: Events are a *domain-wide* concept spanning Subdomains and Bounded Contexts; the publishing contract should be at least enterprise-broad.
- **ch03**: Context Maps show which Contexts consume your notifications and through what relationship (Anticorruption Layer, etc.).
- **ch04**: Hexagonal Architecture puts Application Services in charge of transactions; Event Sourcing (also Appendix A) is the extreme application of the Event Store.
- **ch06**: Events are immutable like Value Objects, and any derived behavior on them must be Side-Effect Free.
- **ch05**: prefer a *generated* unique identity for Events modeled as Aggregates, for the same reasons as Entities.
- **ch07**: a Domain Service can create, store, and publish a client-initiated Event; Domain Services may also register subscribers.
- **ch10**: the modify-one-Aggregate-instance-per-transaction rule is what makes Events and eventual consistency necessary.
- **ch12**: Repositories retrieve the Aggregates that handlers act on; an Event-as-Aggregate gets a removal-free Repository.
- **ch13 / ch14**: Integrating Bounded Contexts covers the remaining notification detail; Application Services and the User Interface bracket the publisher lifecycle (`reset()` in a Web filter).
- **Observer / Publish-Subscribe [Gamma et al.]**, **Idempotent Receiver [Hohpe & Woolf]**, **Atom feeds & [Parastatidis et al., RiP]**, **RabbitMQ fanout exchange**, **JMX `TimerMBean` / [Quartz]**: the external patterns and technologies the implementation rests on.
