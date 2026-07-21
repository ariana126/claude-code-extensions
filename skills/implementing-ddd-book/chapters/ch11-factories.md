# Chapter 11: Factories

## Core Idea
Use a Factory when creation must be *expressed in the Ubiquitous Language* or must *guarantee correct state* that clients cannot be trusted to supply — most often as a Factory Method on an Aggregate Root that creates another Aggregate, supplying `TenantId` and parent identity itself.

## Frameworks Introduced

- **Factory Method on Aggregate Root**: Put a Language-named creation method on an Aggregate Root that instantiates and returns a *different* Aggregate (or an inner part), filling in the association identities from its own state.
  - When to use: whenever the domain experts phrase creation as a behavior of an existing Aggregate — "Calendars schedule calendar entries," "Authors start discussions on forums," "Products plan backlog items."
  - How:
    1. Name the method from the Language, not from the type being built: `scheduleCalendarEntry()`, `startDiscussion()`, `planBacklogItem()` — never `createX()`/`newX()`.
    2. Have the client pass only the domain-meaningful parameters, usually Value Objects, plus the new identity from `repository.nextIdentity()`.
    3. Supply the sensitive parameters yourself from the Root: `this.tenant()`, `this.calendarId()`, `this.forumId()`.
    4. Put creation-time guards that only the Root can evaluate at the top of the method (`if (this.isClosed()) throw ...`).
    5. Declare the created Aggregate's full constructor `protected`, so clients are forced through the Factory Method.
    6. Publish the corresponding Domain Event, then return the new instance.
    7. Make the client add the returned Aggregate to its own Repository — the Factory does not persist it.
  - Why it works / failure mode: it simultaneously expresses the Language, reduces the client's parameter burden (9 of 11 for `CalendarEntry`, 3 of 5 for `Discussion`), and makes it structurally impossible to create an instance under the wrong tenant — a disastrous outcome in a multitenant system. The cost: the Root must be loaded from its persistence store before it can create anything, which is extra overhead under high traffic.

- **Factory on Service**: Design a Domain Service as a Factory when creation requires interacting with another Bounded Context and translating foreign objects into local types.
  - When to use: integration boundaries — when a concept in the foreign model (a *user in a role*) must become a different concept in your model (an `Author`, `Moderator`, `Owner`, `Participant`).
  - How:
    1. Declare the Service interface in the domain model, with one creation method per local type: `authorFrom(Tenant, String identity)`, `moderatorFrom(...)`, `ownerFrom(...)`.
    2. Take only the minimal inputs the local Context has — the `Tenant` and the foreign identity (username).
    3. Implement it in the Infrastructure Layer, since it's a technical concern.
    4. Delegate to an **Adapter** that talks to the foreign Context's Open Host Service and confirms the role.
    5. Delegate translation of the Published Language response to a separate **Translator** class that performs the actual creation.
    6. Return a local Value Object; the foreign model's life cycle and terminology never leak in.

- **Factory vs. Plain Constructor (when a Factory earns its keep)**: A public constructor is fine until one of these is true.
  - When to use a Factory:
    1. The construction is complex, or spans multiple objects, and you want to create an entire Aggregate as a piece, enforcing its invariants.
    2. Some required state must not come from the client (tenancy, parent identity) because getting it wrong is unsafe.
    3. A behavioral method name would express the Ubiquitous Language in a way a constructor name cannot.
    4. The client should not have to reference the concrete class being instantiated (class hierarchies ⇒ Abstract Factory: pass basic parameters, let the Factory pick the concrete type).
    5. A creation-time business guard exists that only another Aggregate can evaluate.
  - When a plain constructor suffices: construction is non-complex, all parameters are safely client-supplied, and no Language term describes the act of creating.

## Key Concepts
- **Factory**: An object encapsulating complex assembly that creates entire Aggregates as a piece, enforcing invariants, without exposing concrete classes to clients [Evans, p. 138].
- **Factory Method (on an Aggregate Root)**: A creation method that is one behavior among many on a first-class model citizen — the Root's primary responsibility remains its own Aggregate behavior.
- **Dedicated Factory**: An object whose *only* purpose is instantiating one Aggregate type; it has no other responsibility and is not a first-class citizen of the model.
- **Service-Based Factory**: A Domain Service that produces local model types by translating from a foreign Bounded Context.
- **`nextIdentity()`**: The Repository method that generates the new Aggregate's globally unique identity, passed *into* the Factory Method by the client.
- **Adapter / Translator split**: `UserInRoleAdapter` is responsible only for communicating with the foreign Context; `CollaboratorTranslator` is responsible only for translation that results in creation.
- **Protected constructor**: The mechanism that forces clients through the Factory Method rather than around it.

## Mental Models
- Think of a Factory Method name as **a sentence the domain experts already say**: "Calendars schedule calendar entries" becomes `calendar.scheduleCalendarEntry(...)`. If no such sentence exists, you probably want a constructor.
- Use the **"what must the client NOT be allowed to supply?"** test to decide what the Factory fills in — in multitenancy, `TenantId` is always on that list.
- Think of a Service-Based Factory as **the seam that separates two Contexts' life cycles and terminologies** — users and roles go in, `Author`s and `Moderator`s come out.
- Guards belong where the knowledge is: the Factory Method needs no parameter guards if the Value Object constructors, the target constructor, and its self-delegating setters already guard — but it *does* carry the guard only the Root knows (`Forum is closed`).

## Code Examples
```java
package com.saasovation.collaboration.domain.model.forum;

public class Forum extends Entity {
    public Discussion startDiscussion(
            DiscussionId aDiscussionId,
            Author anAuthor,
            String aSubject) {
        if (this.isClosed()) {
            throw new IllegalStateException("Forum is closed.");
        }

        Discussion discussion = new Discussion(
                this.tenant(),      // supplied by the Root, not the client
                this.forumId(),     // supplied by the Root, not the client
                aDiscussionId,
                anAuthor,
                aSubject);

        DomainEventPublisher.instance()
            .publish(new DiscussionStarted(...));

        return discussion;
    }
}
```
- **What it demonstrates**: All four benefits at once — Language-expressive name ("Authors start discussions on forums"), a creation guard only the `Forum` can evaluate, `Tenant`/`ForumId` supplied by the Root so only 3 of 5 parameters fall to the client, and a Domain Event published before the new Aggregate is returned.

```java
public interface CollaboratorService {
    public Author authorFrom(Tenant aTenant, String anIdentity);
    public Moderator moderatorFrom(Tenant aTenant, String anIdentity);
    public Owner ownerFrom(Tenant aTenant, String anIdentity);
    public Participant participantFrom(Tenant aTenant, String anIdentity);
}

// Infrastructure Layer implementation:
public class UserRoleToCollaboratorService implements CollaboratorService {
    @Override
    public Author authorFrom(Tenant aTenant, String anIdentity) {
        return (Author) UserInRoleAdapter.newInstance()
            .toCollaborator(aTenant, anIdentity, "Author", Author.class);
    }
}
```
- **What it demonstrates**: A Domain Service acting as a Factory across a Context boundary — interface in the model, implementation in Infrastructure, Adapter for communication, Translator for creation.

## Reference Tables

| Factory form | Site | Best for | Cost |
|---|---|---|---|
| Public constructor | The Aggregate itself | Non-complex construction, all params safely client-supplied | No Language expression, no guaranteed association state |
| **Factory Method on Aggregate Root** | `Calendar.scheduleCalendarEntry()`, `Forum.startDiscussion()`, `Product.planBacklogItem()` | Expressing the Language; guaranteeing tenancy and parent identity; creation-time guards | Root must be loaded from its store before creating |
| **Dedicated Factory object** | Standalone, no other responsibility | Genuinely complex assembly (e.g., building a `Set<Invitee>`) | Not a first-class model citizen |
| **Factory on Service** | `CollaboratorService` | Cross-Context creation with translation | Complexity lives in Adapter + Translator |
| **Abstract Factory** | Standalone | Creating one of several concrete types in a class hierarchy from basic parameters | Class hierarchies bring their own pain — see Repositories (ch12) |

## Worked Example
**Creating `CalendarEntry` instances.** The CollabOvation team put the Factory Method on `Calendar`, driven by a domain-expert scenario: *"Calendars schedule calendar entries."*

The client test calls `calendar.scheduleCalendarEntry(...)` with nine arguments — starting with `calendarEntryRepository().nextIdentity()`, then `Owner`, subject, description, `TimeSpan`, `Alarm`, `Repetition`, location, and a `Set<Invitee>` — and asserts both that the returned entry is non-null and that a `CalendarEntryScheduled` Event was published to a subscribed handler. The client then adds the new Aggregate to `calendarEntryRepository()`; failing to do so simply releases it to the garbage collector.

Inside, `scheduleCalendarEntry()` passes **eleven** arguments to the `CalendarEntry` constructor. The two the client never sees are `this.tenant()` and `this.calendarId()` — precisely the two whose corruption would be disastrous in a multitenant SaaS product, where every tenant's data must stay segregated. `CalendarEntry`'s constructor is declared `protected` so no client can bypass this.

The method carries no parameter guards: the Value Object constructors, the `CalendarEntry` constructor, and the setters it self-delegates to already guard everything. The trade-off the team accepted is that `Calendar` must be fetched from persistence before an entry can be created — worth it now, but something to re-weigh as traffic in the Bounded Context grows. The team also noted that assembling the `Set<Invitee>` remained awkward for clients, pointing toward a *dedicated* Factory for that one job.

## Key Takeaways
1. Name Factory Methods with the domain experts' verb — `scheduleCalendarEntry()`, `startDiscussion()`, `planBacklogItem()` — because a constructor name can never carry the Ubiquitous Language.
2. Let the Factory Method supply what the client must not: `TenantId`, parent Aggregate identity, and any state whose corruption would be unsafe.
3. Make the created Aggregate's constructor `protected` — otherwise the Factory Method is a suggestion, not a guarantee.
4. Pass `repository.nextIdentity()` in from the client, and have the client add the returned Aggregate to its Repository; the Factory creates but does not persist.
5. Skip redundant guards in the Factory Method when constructors and self-delegating setters already guard — but do place guards only the Root can evaluate (`Forum is closed`).
6. Design a Domain Service as a Factory at Context boundaries, splitting communication (Adapter) from translation-that-creates (Translator), and house the implementation in Infrastructure.
7. Accept the cost: an Aggregate Factory Method means loading the Root first — re-evaluate under increasing traffic.

## Connects To
- **ch01**: Ubiquitous Language — the primary justification for a Factory Method over a constructor.
- **ch02**: Bounded Contexts — Service-Based Factories translate between them; CollabOvation speaks of authors and moderators, not users.
- **ch03**: Anticorruption Layer, Open Host Service, Published Language — what `UserInRoleAdapter` and `CollaboratorTranslator` implement.
- **ch05**: Entities — self-delegation and guards explain why the Factory Method needs no guards of its own.
- **ch06**: Value Objects — most Factory Method parameters are Values; `Collaborator` subclasses are Values.
- **ch07**: Services — Domain Services designed as Factories.
- **ch08**: Domain Events — `CalendarEntryScheduled`, `DiscussionStarted` published from within the Factory Method.
- **ch09**: Modules — the Service interface lives in the domain model Module, its implementation in an Infrastructure Module.
- **ch10**: Aggregates — `Product.planBacklogItem()`/`scheduleRelease()`/`scheduleSprint()` became Factory Methods when the large cluster was split.
- **ch12**: Repositories — `nextIdentity()` feeds the Factory; also the reference for the pain of type hierarchies with Abstract Factory.
- **ch13**: Integrating Bounded Contexts — where the bulk of Service-as-Factory material lives.
- **Gang of Four (Gamma et al.)**: Abstract Factory, Factory Method, Builder, Adapter.
