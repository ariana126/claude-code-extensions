# Chapter 13: Integrating Bounded Contexts

## Core Idea
A Context Map's second, concrete form is the code that implements the relationship between Bounded Contexts — RESTful resources or messaging, always mediated by an Anticorruption Layer that translates a Published Language into your own Ubiquitous Language. Integration succeeds or fails on whether you respect the Principles of Distributed Computing: messages arrive late, out of order, more than once, or not at all.

## Frameworks Introduced

- **Principles of Distributed Computing** (stated as principles, not the "Fallacies" [Deutsch], to stress what must be planned for): the network is not reliable; there is always latency, maybe a lot; bandwidth is not infinite; do not assume the network is secure; network topology changes; knowledge and policies are spread across multiple administrators; network transport has cost; the network is heterogeneous.
  - When to use: before designing any inter-Context integration, especially RPC-style, where a naive developer assumes a remote call is as good as an in-process call.
  - Why it works / failure mode: one unavailable component cascades failure across every dependent system. Avoid RPC where autonomy matters — a failed RPC provider blocks its consumers outright.

- **Anticorruption Layer over an Open Host Service**: a three-part structure — **Service (Separated Interface, in the domain model) → Adapter (reaches the remote system) → Translator (Published Language → local type)**.
  - When to use: whenever a downstream Context consumes an upstream Context's representation and must not let foreign concepts leak in.
  - How:
    1. Declare a Separated Interface in the inner hexagon named in your own Language (`CollaboratorService.authorFrom(tenant, identity)`), not the foreign one.
    2. Put the implementation (`TranslatingCollaboratorService`) in an Infrastructure Module — it is technical and belongs at the outside of the Hexagonal (Ports and Adapters) architecture.
    3. Give it a specialized Adapter [Gamma et al.] (`UserInRoleAdapter`) that builds the request, issues it, and interprets HTTP status: 200 → translate; 204 → answer null; anything else → throw.
    4. Give it a Translator (`CollaboratorTranslator`) that reads the representation via a `RepresentationReader` and instantiates the local domain-specific type (`Author`, `Creator`, `Moderator`, `Owner`, `Participant` — subclasses of the `Collaborator` Value type).
    5. Return only local types across the interface; the domain model never sees JSON, HTTP, or a foreign `User`.
  - Why it works / failure mode: the Adapter absorbs remoteness, the Translator absorbs vocabulary; clients see a plain Factory-like call. Implementing an ACL via a Repository (ch12) is misplaced for Value Objects but natural if the ACL produces an Aggregate.

- **Custom Media Type as Published Language + `NotificationReader`**: define a media-type specification (RFC 4288 style) as the binding contract between producers and consumers instead of deploying Event interfaces and classes everywhere.
  - When to use: you want type safety at the read boundary without shared binaries, recompilation on Event change, or the "shared classes" slippery slope disguised as a Shared Kernel.
  - How: specify the `Notification` (notificationId, typeName as fully qualified Event class name, version, occurredOn, event payload) and each Event type; consumers read with XPath-like, dot-separated, or varargs navigation (`reader.eventStringValue("backlogItemId.id")`), typed as String/int/long/boolean/Date; key off `version` to read newer attributes so version-1 consumers never recompile.
  - Why it works / failure mode: losing the Event's methods is a *protection*, not a loss — the consumer should want only data, never foreign behavior. Trade-off: no code completion, no compile-time property navigation; Protocol Buffers may be easier when Event versions change often and drastically.

- **Long-Running Process with `TimeConstrainedProcessTracker`**: an Event starts a process, a tracker (retry interval, total retries, time-out Event name) watches it, and a completion Event ends it.
  - When to use: a multi-Context workflow that must finish, where you cannot rely on the remote Context ever answering.
  - How:
    1. On the starting Event, create and persist a tracker (`ProcessId`, description, retry interval, total retries, name of the `ProcessTimedOut` subclass) and store its `ProcessId` on the Aggregate (`product.setDiscussionInitiationId(...)`).
    2. Send the command to the remote Context's exchange.
    3. A background timer calls `checkForTimedOutProcesses()`; the repository answers `allTimedOut()` and each tracker runs `informProcessTimedOut()`, publishing a `ProcessTimedOut` subclass.
    4. A retry listener asks `hasFullyTimedOut()`: full time-out → compensate (e-mail the owner, move the Aggregate to `FAILED`); otherwise → retry the request.
    5. On the success Event, transition the Aggregate to its completion state and call `tracker.completed()` so it is never selected again.
  - Why it works / failure mode: the tracker is a technical Subdomain concept, not Core Domain, so relaxed Aggregate rules are acceptable. Retries are useless — and produce misleading error logs — unless the *receiving* Context's operations are idempotent.

## Key Concepts
- **Open Host Service**: a published protocol (here, RESTful resources over HTTP) giving all integrators access, expanded as new integration requirements appear.
- **Published Language**: the shared, standards-based exchange format — a custom media type such as `application/vnd.saasovation.idovation+json`.
- **Notification**: the envelope carrying a Domain Event plus notificationId, typeName, version, occurredOn.
- **`ExchangeListener`**: reusable abstract RabbitMQ base class; subclasses implement only `exchangeName()`, `listensToEvents()`, and `filteredDispatch()`.
- **`filteredDispatch()`**: the listener hook that filters unwanted notifications, reads Event data, and dispatches a Command to an Application Service.
- **`MemberChangeTracker`**: a Value Object inside the `Member` Aggregate holding `enablingOn`, `nameChangedOn`, `emailAddressChangedOn` so out-of-order and duplicate Events are rejected.
- **Idempotent operation**: a command whose repeated execution has no additional effect — required because RabbitMQ guarantees delivery *at least once*.
- **`Process` / `AbstractProcess`**: a state-machine interface (`ProcessCompletionType`: NotCompleted, CompletedNormally, TimedOut) with `completenessVerified()` so a process completes only after all steps confirm.
- **Integrating with a minimalist's mindset**: duplicate as little foreign information as possible; identity is safe to duplicate because it is immutable.

## Mental Models
- Think of RESTful and RPC integration as temporally coupled: create the *illusion* of decoupling with timers or a local message queue, backing off the timer or NAKing the message when the remote system is down.
- Design the Open Host Service around the integrator's **use cases**, not around your model: exposing your model as linked resources is not an Open Host Service at all — it is a Shared Kernel or a Conformist (ch03).
- Treat every received Event as potentially late, duplicated, and out of order: pass `occurredOn` on every Command and let the Aggregate decide whether the change still applies.
- Prefer immutable duplicated Values (Collaboration Context, never resynchronized) when the foreign data rarely changes; accept mutable duplicated Aggregates (Agile PM's `ProductOwner`/`TeamMember`) only when you will also handle `PersonNameChanged`, `PersonContactInformationChanged`, `UserAssignedToRole`, `UserUnassignedFromRole`, `UserEnablementChanged`, `TenantActivated`, `TenantDeactivated`.

## Anti-patterns
- **Deploying Event/DTO interfaces and classes to every consuming system**: forces recompilation on change and tempts consumers to use foreign model behavior as if it were their own.
- **Exposing the domain model as navigable RESTful resources**: couples integrators to your model — Conformist, not Open Host Service.
- **Assuming message ordering**: a `UserAssignedToRole` arriving after `UserUnassignedFromRole` strands a member in `disabled` and requires manual data patching.
- **Non-idempotent receiving operations under at-least-once delivery**: retries generate duplicate-creation attempts that are benign but pollute error logs as if they were bugs.
- **Duplicating foreign information you don't need**: every duplicated attribute obligates you to consume every Event that could change it.
- **File-based or shared-database integration**: "could make you old before your time."
- **Forgetting to re-register consumers after the broker returns**: your Context silently stops receiving notifications — the kind of eventual consistency you want to avoid.

## Code Examples
```java
public class UserInRoleAdapter {                       // the ACL's Adapter
    public <T extends Collaborator> T toCollaborator(
            Tenant aTenant, String anIdentity,
            String aRoleName, Class<T> aCollaboratorClass) {
        T collaborator = null;
        try {
            ClientRequest request = this.buildRequest(aTenant, anIdentity, aRoleName);
            ClientResponse<String> response = request.get(String.class);
            if (response.getStatus() == 200) {
                collaborator = new CollaboratorTranslator()
                        .toCollaboratorFromRepresentation(
                                response.getEntity(), aCollaboratorClass);
            } else if (response.getStatus() != 204) {
                throw new IllegalStateException("There was a problem requesting the user: "
                        + anIdentity + " in role: " + aRoleName);
            }
        } catch (Throwable t) {
            throw new IllegalStateException("Failed because: " + t.getMessage(), t);
        }
        return collaborator;
    }
}
```
- **What it demonstrates**: the Adapter owns remoteness and HTTP status semantics (200 translate / 204 absent / else fail) and hands off vocabulary translation to the Translator.

```java
public abstract class Member extends Entity {
    private MemberChangeTracker changeTracker;

    public void disable(Date asOfDate) {
        if (this.changeTracker().canToggleEnabling(asOfDate)) {
            this.setEnabled(false);
            this.setChangeTracker(this.changeTracker().enablingOn(asOfDate));
        }
    }
    public void changeEmailAddress(String anEmailAddress, Date asOfDate) {
        if (this.changeTracker().canChangeEmailAddress(asOfDate)
                && !this.emailAddress().equals(anEmailAddress)) {
            this.setEmailAddress(anEmailAddress);
            this.setChangeTracker(this.changeTracker().emailAddressChangedOn(asOfDate));
        }
    }
}
```
- **What it demonstrates**: `occurredOn`-driven guards make the Aggregate both order-tolerant and idempotent; the tracker never escapes the Aggregate boundary, so it doesn't pollute the Ubiquitous Language. (Pat Helland, "Activities: Coping with Messy Messages" [Helland] §5.)

## Reference Tables

| Integration style | Autonomy | Coupling | Use when |
|---|---|---|---|
| RPC / SOAP API | Lowest — provider down blocks consumer | Procedural, tight | Familiar teams, tolerant of coupling |
| RESTful HTTP (Open Host Service) | Low-medium; simulate decoupling with timers/queues | Published Language via media type | Query-style needs, "is this user in this role?" |
| Messaging (Domain Events) | Highest — works while a system is down | Published Language via Notification | Anything that must survive partner downtime |

| Duplication strategy | Collaboration Context | Agile Project Management Context |
|---|---|---|
| Local representation | Immutable `Collaborator` Value Objects | `ProductOwner` / `TeamMember` Aggregates |
| Kept in sync? | No — replaced wholesale, never updated | Yes — via Events from Identity and Access |
| Cost | Stale data if the remote changes | Must consume 7+ Event types, handle order + duplicates |
| Mechanism | REST + Anticorruption Layer | RabbitMQ listeners + `MemberChangeTracker` |

## Worked Example
**The Anticorruption Layer over the Identity and Access Context.**

*Upstream.* The Identity and Access team almost published their model as linked tenant→users→groups→roles resources. Recognizing that as a Shared Kernel/Conformist relationship, they instead asked what integrators' use cases actually need: "can this user play this role?" One resource:

```
GET /tenants/{tenantId}/users/{username}/inRole/{role}
→ 200 + application/vnd.saasovation.idovation+json   (user is in role)
→ 204 No Content                                     (no such user, or not in role)
```

`UserResource` is a JAX-RS Adapter on the RESTful Port of the Hexagonal architecture (ch04). It delegates to the `AccessService` Application Service (ch14), which finds the `User` and the `Role` Aggregates and calls `role.isInRole(user, groupMemberService)` — `GroupMemberService` being a Domain Service (ch07) holding checks the `Role` should not own. The response body carries `role, username, tenantId, firstName, lastName, emailAddress`.

*Downstream.* The Collaboration Context does not want users and roles; it wants Authors, Creators, Moderators, Owners, and Participants. Three collaborating classes form the ACL:

```java
public interface CollaboratorService {           // Separated Interface, domain model
    public Author authorFrom(Tenant aTenant, String anIdentity);
    public Creator creatorFrom(Tenant aTenant, String anIdentity);
    public Moderator moderatorFrom(Tenant aTenant, String anIdentity);
    public Owner ownerFrom(Tenant aTenant, String anIdentity);
    public Participant participantFrom(Tenant aTenant, String anIdentity);
}

// infrastructure.services
public class TranslatingCollaboratorService implements CollaboratorService {
    public Author authorFrom(Tenant aTenant, String anIdentity) {
        return this.userInRoleAdapter.toCollaborator(
                aTenant, anIdentity, "Author", Author.class);
    }
}
```

`UserInRoleAdapter` performs the GET; `CollaboratorTranslator` reads `username`, `firstName`, `lastName`, `emailAddress` from the representation and reflectively constructs the requested `Collaborator` subclass. An Application Service then uses it in local terms with no trace of the foreign Context:

```java
Author author = this.collaboratorService.authorFrom(tenant, anAuthorId);
Discussion newDiscussion = forum.startDiscussion(
        this.forumNavigationService(), author, aSubject);
```

Because `Collaborator` is an immutable Value, the team deliberately never resynchronizes name or e-mail changes — a simplicity trade-off the Agile PM team reversed, taking on Event-driven synchronization instead.

## Key Takeaways
1. Design the Open Host Service from integrators' use cases; publishing your model is a Conformist relationship in disguise.
2. Structure every Anticorruption Layer as Separated Interface (domain) → Adapter (remote access) → Translator (Published Language to local type), with the implementation in Infrastructure.
3. Use a custom media type plus a `NotificationReader`/`RepresentationReader` when you want a binding producer/consumer contract without shipping classes; version Events so version-1 consumers never recompile.
4. Publish enriched Domain Events (`UserAssignedToRole` carrying name and e-mail) so consumers rarely need a synchronous callback.
5. Pass `occurredOn` on every Command derived from an Event and let the Aggregate guard against out-of-order and duplicate delivery — that is what makes operations idempotent under at-least-once messaging.
6. Minimize duplicated foreign information; duplicate identity freely (it is immutable) and use soft deletion/disabling so references never dangle.
7. Wrap multi-Context workflows in a Long-Running Process with a `TimeConstrainedProcessTracker`: bounded retries, a `ProcessTimedOut` Event, compensation (e-mail + `FAILED` state) on full time-out, `tracker.completed()` on success.
8. Retries are worthless without idempotent receivers — make the receiving Application Service find-then-create (`exclusiveForumOfOwner`, `exclusiveDiscussionOfOwner`) before it creates.
9. Plan for the broker being down: back off sends to 30–60 seconds, rely on the Event Store to queue, confirm consumers reregister automatically, and expect a backlog-processing catch-up after your own downtime.

## Connects To
- **ch02 (Domains, Subdomains, Bounded Contexts)** and **ch03 (Context Maps)**: this chapter is the code form of a Context Map; Open Host Service, Published Language, Anticorruption Layer, Shared Kernel, Conformist all come from there.
- **ch04 (Architecture)**: Hexagonal/Ports and Adapters placement, Event-Driven Architecture, Long-Running Processes, REST.
- **ch08 (Domain Events)**: Event publication, the Event Store, and forwarding Events to a messaging mechanism.
- **ch10 (Aggregates)**: eventual consistency across Aggregates and Contexts; one Aggregate per transaction.
- **ch12 (Repositories)**: an ACL may be implemented as a Repository when it produces an Aggregate, not a Value Object.
- **ch14 (Application)**: Application Services receive Commands from listeners and manage transactions.
- **ch06 (Value Objects)** and **ch11 (Factories)**: `Collaborator` subclasses are Values produced by Factory-like ACL methods.
- **[Hohpe & Woolf]**: enterprise integration patterns for messaging; **[Helland]**: coping with messy messages in eventually consistent systems.
