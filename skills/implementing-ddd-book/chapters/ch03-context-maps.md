# Chapter 3: Context Maps

## Core Idea
A Context Map is a simple, informal drawing of the Bounded Contexts *that already exist* and the organizational and integration relationships between them — plus, in its detailed form, the source code of those integrations. Draw the current terrain first; the Map's real payoff is forcing inter-team communication about relationships you would otherwise assume.

## Frameworks Introduced

- **The Nine DDD Organizational and Integration Relationships** (one commonly exists between any two Bounded Contexts):
  - **Partnership**: When teams in two Contexts will succeed or fail together, a cooperative relationship needs to emerge. The teams institute a process for coordinated planning of development and joint management of integration, cooperate on the evolution of their interfaces, and schedule interdependent features so they complete for the same release.
  - **Shared Kernel**: Designate with an explicit boundary some subset of the domain model that the teams agree to share. Keep the kernel small. The shared stuff has special status and shouldn't be changed without consultation with the other team. Define a continuous integration process that keeps the kernel model tight and aligns the Ubiquitous Language of the teams. Sharing model and code forms a very intimate interdependency that can leverage or undermine design work.
  - **Customer-Supplier Development**: Two teams in an upstream-downstream relationship where the upstream team may succeed independently of the downstream team's fate. Downstream priorities factor into upstream planning; negotiate and budget tasks for downstream requirements so everyone understands the commitment and schedule.
  - **Conformist**: When the upstream team has no motivation to provide for the downstream team's needs, the downstream team is helpless. Altruism may motivate upstream promises, but they are unlikely to be fulfilled. The downstream team eliminates the complexity of translation by slavishly adhering to the model of the upstream team.
  - **Anticorruption Layer**: As a downstream client, create an isolating layer that provides your system with the functionality of the upstream system **in terms of your own domain model**. The layer talks to the other system through its existing interface, requiring little or no modification to it, and translates internally in one or both directions. Use it when control or communication is inadequate for a Shared Kernel, Partnership, or Customer-Supplier relationship, so translation must take a defensive tone.
  - **Open Host Service**: Define a protocol that gives access to your subsystem as a set of services. Open the protocol so all who need to integrate with you can use it. Enhance and expand it for new integration requirements — except when a single team has idiosyncratic needs, in which case use a one-off translator so the shared protocol stays simple and coherent.
  - **Published Language**: A well-documented shared language that can express the necessary domain information as a common medium of communication, translating as necessary into and out of it. Often combined with Open Host Service.
  - **Separate Ways**: Be ruthless about requirements. If two sets of functionality have no significant relationship, cut them completely loose. Integration is always expensive and sometimes the benefit is small. Declare a Bounded Context to have no connection to the others at all, enabling simple, specialized solutions within a small scope. Applicable Context-wide or case-by-case.
  - **Big Ball of Mud**: Where models are mixed and boundaries are inconsistent, draw a boundary around the entire mess and designate it a Big Ball of Mud. Do not try to apply sophisticated modeling within this Context. Be alert to the tendency for such systems to sprawl into other Contexts.

- **Drawing a Context Map**:
  - When to use: at the very start of a DDD effort, before you decide anything about integration — and again whenever a new Context enters planning (it is not premature to map a Context that exists only in planning, not yet in code).
  - How:
    1. Map the **present, not the imagined future**; update as the landscape changes.
    2. Hand-draw it; whiteboards and dry-erase markers rule. If you use a tool, keep it informal — the more ceremony, the fewer people use it.
    3. Name each Bounded Context and make the names part of the Ubiquitous Language; describe the points of contact, outlining explicit translation for any communication and highlighting any sharing [Evans, p. 345].
    4. Mark each relationship's ends with **U** (Upstream) and **D** (Downstream), and label the connector boxes with the pattern abbreviations: **OHS** (Open Host Service), **PL** (Published Language), **ACL** (Anticorruption Layer). Upstream connectors typically carry OHS/PL, downstream connectors ACL.
    5. Zoom in when curiosity warrants: add Modules, significant Aggregates, team allocation, boundary objects — but push back when detail becomes ceremonious.
    6. Post it prominently on a team wall. Upload to a wiki only if the team actually visits the wiki; "a wiki can be a place where information goes to die."
  - Why it works / failure mode: it converts assumed relationships into stated ones. Failure mode: your team counts on a Customer-Supplier relationship with a legacy team that intends only to hand you what they already have — forcing an unexpected Conformist relationship that, discovered late, delays or kills the project.

- **Translation Map**: A logical diagram showing how a representational state (e.g., an XML or JSON representation from an upstream Open Host Service) maps onto a Value Object in the local model — for example, a `User` in the `Role` of Moderator in the Identity and Access Context becoming a `Moderator` Value Object in the Collaboration Context.
  - Diagnostic: if the translations are overly complex, requiring lots of data copying and synchronization, and the translated object looks a lot like the foreign one, you are **using too much from the foreign Bounded Context** and importing conflict into your own model.

## Key Concepts
- **Context Map**: Expressed two ways — the simple diagram of mappings between existing Bounded Contexts, and, in detail, the source code of the integrations.
- **Upstream / Downstream**: Upstream models influence downstream models the way a city's activity on a river affects populations below it; vertical position on the Map is a visual cue, the U/D labels are the explicit statement.
- **Notification Log / Notification Resource**: A RESTful resource publishing groups of Domain Events; a stable minted URI serves the current log, and archived logs are navigable as a chain. Every Event published is always available in order of occurrence, and each client is responsible for preventing duplicate consumption.
- **Autonomy**: The ability of a downstream Context to keep operating when upstream Contexts are unavailable — achieved by translating minimal foreign state into local domain objects and synchronizing via asynchronous notifications, not by replicating upstream databases.
- **Eventual Consistency (in integration)**: Requesting remote resource creation via a locally handled Domain Event and modeling the interim unavailability as a legitimate state.

## Mental Models
- **A Context Map is *not* an Enterprise Architecture or system topology diagram.** It conveys interacting models and DDD organizational patterns — though it will incidentally expose integration bottlenecks and sticky governance issues other methods miss.
- **"When you get yourself a powerful thirst, always drink upstream from the herd."** Position on the Map is about influence, not importance: the new Core Domain sits at the *bottom* of the SaaSOvation Map precisely because it is downstream of everything it consumes.
- **Think minimalistic about synchronized state.** Keep only the minimal attributes of remote models the local model needs — not merely to reduce synchronization, but so that a `ProductOwner` doesn't unwittingly hybridize into a `UserOwner`.
- **Model unavailability as a state, not a bug.** Working around eventual consistency is not a kludge; the add-on may never have been purchased, and that is a nontechnical reason to design for resource unavailability.

## Code Examples
```java
public enum DiscussionAvailability {
    ADD_ON_NOT_ENABLED, NOT_REQUESTED, REQUESTED, READY;
}

public final class Discussion implements Serializable {
    private DiscussionAvailability availability;
    private DiscussionDescriptor descriptor;
    ...
}

public class Product extends Entity {
    ...
    private Discussion discussion;
    ...
}
```
- **What it demonstrates**: A Standard Type implemented as a State that makes every remote-resource unavailability scenario explicit, so a `Discussion` Value Object cannot be misused while the eventually-consistent remote creation is pending.

## Reference Tables

| Pattern | Position | Nature | Use when |
|---|---|---|---|
| Partnership | Peer | Organizational | Two teams succeed or fail together |
| Shared Kernel | Peer | Organizational + code | Explicit small shared model subset, continuous integration, mutual consultation |
| Customer-Supplier | Upstream/Downstream | Organizational | Upstream commits to serve downstream priorities in its planning |
| Conformist | Upstream/Downstream | Organizational | Upstream has no motivation to help; downstream adopts its model wholesale |
| Anticorruption Layer | Downstream (ACL) | Integration | Defensive translation into your own model |
| Open Host Service | Upstream (OHS) | Integration | Publish a protocol as services for all integrators |
| Published Language | Upstream (PL) | Integration | Documented shared language; usually with OHS |
| Separate Ways | None | Organizational | No significant relationship; integration cost exceeds benefit |
| Big Ball of Mud | Either | Reality | Mixed models, inconsistent boundaries; wrap it, don't model within it |

| Pattern | Typical technical realization |
|---|---|
| Open Host Service | REST resources; usually thought of as RPC-style API, but can be message exchange |
| Published Language | XML schema; REST representations in XML/JSON/Protocol Buffers/HTML; hypermedia (HATEOAS) so clients navigate linked resources; also the message format in an Event-Driven Architecture |
| Anticorruption Layer | A Domain Service per ACL in the downstream Context; may sit behind a Repository interface; a client Domain Service implementation calls the remote OHS and translates representations into local domain objects |

## Worked Example
**SaaSOvation maps its way out of the tangle, in three drawings.**

*Map 1 — the existing terrain.* The Collaboration team, having realized their model was a tangle, drew the Context Map of what existed. The `Collaboration Context` boundary came out an odd shape, conveying the likely existence of a second Context without clean separation from the Core Domain. A narrow passage near the top, marked with a caution sign, showed foreign concepts migrating back and forth almost without censure. The lesson drawn: boundaries need not be impenetrable, but the Context must control with full knowledge what crosses them, and foreign concepts must "demonstrate the right to be there, even taking on characteristics compatible with the territory within."

*Map 2 — Subdomain analysis.* Problem-space assessment carved two Subdomains out of that single Bounded Context: a **Collaboration Core Domain** and a **Security Generic Subdomain**. Because Subdomains should align one-to-one with Bounded Contexts, this proved the single Context had to become two.

*Map 3 — after Segregated Core.* Crisp boundaries: the bold-bordered Core Domain `Collaboration Context` downstream of the new Generic Subdomain `Identity and Access Context`. The team deliberately did **not** draw the future `Agile Project Management Context` — "It wouldn't help the team to jump ahead too far." Recognizable boundary shapes were kept constant across diagrams as visual cues.

*Map 4 — augmentation for the new Core Domain.* When ProjectOvation started, the Map was augmented rather than redrawn: `Identity and Access Context` furthest upstream (OHS/PL), `Collaboration Context` upstream of `Agile Project Management Context` as a Supporting Subdomain, and the new Core Domain at the bottom with an ACL on every downstream connector.

*Zoom 1 — Collaboration → Identity and Access (the easy, less robust integration).* Synchronous, RPC-like consumption of REST resources, storing nothing locally: it reaches out for information every single time. Boundary objects pull the content of interest out of the representation and create the appropriate Value Object; a Translation Map documents XML → `Moderator`. Cost: if the remote system is unavailable, the entire local execution fails and the user is told to try again later. The team accepted this to meet a delivery schedule and intends to revisit it.

*Zoom 2 — Agile PM → Identity and Access (the autonomous integration).* Out-of-band asynchronous event processing is strategically favored. `NotificationResource` publishes a custom media type `application/vnd.saasovation.idovation+json` over `//iam/notifications` (a minted, stable URI for the current log) and `//iam/notifications/{notificationId}` (the archived chain). Locally: a timer fires, `MemberSynchronizer` delegates to `MemberService` (a Domain Service, the ACL interface) via `maintainMembers()`; `MemberService` delegates to `IdentityAccessNotificationAdapter`, the Adapter acting as client to the remote OHS; the Adapter delegates to `MemberTranslator`, which translates the Published Language into local concepts, calling `updateMember()` when a local `Member` already exists. `Member`'s subclasses are `ProductOwner` and `TeamMember` — local contextual concepts, not remote `User` clones.

*Zoom 3 — Agile PM → Collaboration (creating remote resources autonomously).* Use case *Create a Product*, precondition "the collaboration feature is enabled (option was purchased)": the user supplies Product information, indicates a desire for a team discussion, requests creation, and the system creates the Product **with a Forum and Discussion**. Unlike identity, these objects don't exist yet — a direct threat to autonomy. Solution: publish a `ProductInitiated` Domain Event handled by *our own* system; the local handler requests remote Forum and Discussion creation, retrying periodically over RPC or exchanging messages, and updates the `Product` with an identity reference when creation completes (`attachDiscussion()`). The interim is modeled explicitly by `DiscussionAvailability`, whose three non-`READY` values map to three user messages ("you need to purchase the add-on option" / "the product owner didn't request the creation" / "setup has not yet completed; check back soon") — and the first doubles as a marketing tickler.

*A naming subtlety worth keeping:* `Discussion` exists in both Contexts with the same name and different types. In the `Collaboration Context` it is an Aggregate managing a set of Posts; in the `Agile PM Context` it is a Value Object holding only a reference to the foreign Discussion.

## Key Takeaways
1. Draw the Map of the *current* situation first — before designing integrations — and let it force conversations about relationships you'd otherwise assume.
2. Your Map is for your team's solution-space perspective; other teams may not use DDD and may not care about it.
3. Label every relationship with U/D and with OHS, PL, or ACL; expect OHS/PL upstream and ACL downstream.
4. Prefer Customer-Supplier over Conformist when management can enforce a supplier commitment — but recognize a Conformist relationship early if the upstream team won't commit.
5. Using Open Host Service and Published Language between your own Contexts does not remove the need for an Anticorruption Layer downstream; it just makes the translation simple and elegant.
6. Achieve autonomy with asynchronous notifications and minimal translated local state — never by replicating upstream databases, which amounts to a Shared Kernel and doesn't achieve autonomy anyway.
7. Model remote-resource unavailability as an explicit state; eventual consistency is a valid modeled state, not a kludge.
8. Keep Maps simple enough to post on a wall and revisit in discussion; reject ceremony, or the Map dies unread.

## Connects To
- **ch01**: Ubiquitous Language — Bounded Context names become part of it; Big Ball of Mud is what DDD-Lite drifts toward.
- **ch02**: Bounded Contexts, Core/Supporting/Generic Subdomains, and problem-space assessment; this chapter is the solution-space assessment counterpart.
- **ch04**: Event-Driven Architecture, where a Published Language carries Domain Events as messages.
- **ch06**: Value Objects, including the Standard Type implemented as a State (`DiscussionAvailability`).
- **ch07**: Domain Services — the usual home of an Anticorruption Layer interface.
- **ch08**: Domain Events and feed-based notification logs (why both a current log and archived logs exist).
- **ch09, ch10**: Modules and Aggregates — optional detail when zooming into a Map.
- **ch12**: Repositories — an ACL may hide behind a Repository interface.
- **ch13**: Integrating Bounded Contexts — the full technical implementations of OHS, PL, and ACL sketched here.
- **REST / HATEOAS / custom media types**: The concrete carrier of Open Host Service and Published Language in these examples; RabbitMQ messaging was the alternative under negotiation.
- **[Brandolini]**: The Context Map drawing style adopted here.
