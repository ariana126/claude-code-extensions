# Chapter 2: Domains, Subdomains, and Bounded Contexts

## Core Idea
A business Domain decomposes into Subdomains (one Core Domain plus Supporting and Generic Subdomains) that describe the **problem space**, and is solved by Bounded Contexts — explicit *linguistic* boundaries — that constitute the **solution space**. Aim to align each Subdomain one-to-one with a Bounded Context; where you can't, use Subdomains as an assessment view over the mess.

## Frameworks Introduced

- **Problem Space / Solution Space Assessment**: Two separate assessments, performed in order, that establish where you are before you build.
  - When to use: at project inception, and whenever a new Core Domain initiative is planned in a landscape of existing systems.
  - How — problem space questions (keep high-level but thorough; assess Subdomains that already exist *and those that are needed*):
    1. What is the name of and vision for the strategic Core Domain?
    2. What concepts should be considered part of the strategic Core Domain?
    3. What are the necessary Supporting Subdomains and Generic Subdomains?
    4. Who should do the work in each area of the domain?
    5. Can the right teams be assembled? Are all stakeholders aligned with and committed to the vision?
  - How — solution space questions (think in terms of cleanly separated Bounded Contexts, because you are looking at the Ubiquitous Language of each):
    1. What software assets already exist, and can they be reused? What must be acquired or created?
    2. How are these connected or integrated, and what additional integration is needed?
    3. Given existing and new assets, what is the required effort? Does any supporting project risk delaying or failing the whole program?
    4. Where are the terms of the Ubiquitous Languages completely different? Where do concepts and data overlap between Bounded Contexts?
    5. How are shared terms and overlapping concepts mapped and translated between Bounded Contexts?
    6. Which Bounded Context contains the Core Domain concepts, and which tactical patterns will model it?
  - Why it works / failure mode: Subdomains let you rapidly view only the parts of the Domain needed to solve one specific problem, which saves costly mistakes in a large enterprise. Failure mode: skipping the problem-space assessment and letting existing system boundaries define your thinking.

- **Bounded Context**: An explicit boundary within which a domain model exists; inside it all terms and phrases of the Ubiquitous Language have specific meaning, and the model reflects the Language with exactness. It is **principally a linguistic boundary**.
  - When to use: around every domain model you develop; also as an analytical wrapper around a legacy monolith or ERP.
  - How to get it right:
    1. Let the Language of domain experts — not architecture, frameworks, packaging, or task distribution — indicate where the real contextual boundaries are.
    2. Name it `Name-of-Model Context` (Collaboration Context, Identity and Access Context, Agile Project Management Context).
    3. Size it so it fully expresses its complete Ubiquitous Language: "There are just as many notes as I required, neither more nor less."
    4. Factor out extraneous concepts that aren't in the Language; they belong in a Supporting or Generic Subdomain, or in no model at all. Be equally careful not to factor out concepts that truly belong in the Core Domain.
    5. Assign **a single team to a single Bounded Context**. Two or more teams in one Context produce a divergent, ill-defined Ubiquitous Language.
    6. Include inside the boundary: the domain model, Application Services, user interface views, service endpoints (REST/SOAP/messaging) that expose it as an Open Host Service, and the database schema *if your team designed it* (a preexisting or externally imposed schema lives outside).
  - Why it works / failure mode: it makes the inevitable differences in meaning explicit and well understood rather than fighting them. Failure mode: chasing an all-inclusive model where every concept has one global meaning — impossible to agree on, and impossible to keep agreed.

- **Subdomain Classification (Core / Supporting / Generic)**: The triage that decides where investment goes.
  - How: A **Core Domain** is of primary importance to the success of the organization — the business must *excel* there; it gets the highest priority, domain experts with deep knowledge, the best developers, and maximum leeway. A **Supporting Subdomain** models an essential but non-Core aspect of the business and is somewhat specialized, so the business creates it. A **Generic Subdomain** captures nothing special to the business yet is required for the overall solution — it could be replaced with any off-the-shelf equivalent.
  - Criterion of perspective: classification is relative to the viewpoint. The mapping service is a Core Domain to the company that sells it and a Generic Subdomain to the inventory team that consumes it. Being Supporting or Generic does not mean unimportant — it means the business has no need to excel there.

## Key Concepts
- **Domain**: What an organization does and the world it does it in — its realm of know-how and its methods of operating.
- **Subdomain**: One logical business function within the whole Domain; a tool of the problem space, used to view only the parts needed to solve a given problem.
- **Core Domain**: The Subdomain of primary strategic importance, where excellence yields competitive advantage.
- **Supporting Subdomain**: Essential but not Core; specialized enough that the business creates it rather than buying it.
- **Generic Subdomain**: Required for the solution but captures nothing special to the business; replaceable off the shelf.
- **Problem Space**: The combination of the Core Domain and the Subdomains it must use.
- **Solution Space**: One or more Bounded Contexts — the specific software models, the realization view.
- **Assessment View**: Conceptually dividing a large Bounded Context with two or more Subdomains (or grouping multiple Contexts under one Subdomain) to reason about a brownfield landscape.
- **Big Ball of Mud**: The tangle that results when linguistic boundaries are ignored; modularization alone does not fix linguistic misalignment.
- **Segregated Core**: The [Evans] refactoring used when a large, critical Bounded Context has its essential model obscured by a great deal of supporting capability.

## Mental Models
- **Context is king.** Two objects both named `Account` — one in a Banking Context, one in a Literary Context — are distinguishable only by the name of their conceptual container. You never rename a concept just to disambiguate it from another Context; the Context does that work.
- **Use the Book life-cycle test when someone proposes a central model.** A publisher's Book differs at proposal, contract, editorial, layout, translation, production, marketing, sales, and shipping. A single central Book model produces confusion, contention, and little deliverable software; separate Bounded Contexts sharing only an identity ship regularly.
- **Think of the Bounded Context as a fence, not a wall.** "Keep your fences horse-high." Boundaries need not be impenetrable, but the Context must know with full knowledge what crosses its borders and why — and foreign concepts must take on characteristics compatible with the territory within.
- **Use Modules before you split a Context.** If a set of services seems spread across several "Bounded Contexts," judicious use of Modules often reduces the true count to one — and Modules are also the right tool for dividing developer responsibilities.

## Code Examples
```java
public class Forum extends Entity {
    public Discussion startDiscussion(
            String aUsername, String aSubject) {
        if (this.isClosed()) {
            throw new IllegalStateException("Forum is closed.");
        }
        User user = userRepository.userFor(this.tenantId(), aUsername);
        if (!user.hasPermissionTo(Permission.Forum.StartDiscussion)) {
            throw new IllegalStateException(
                    "User may not start forum discussion.");
        }
        String authorUser = user.username();
        String authorName = user.person().name().asFormattedName();
        String authorEmailAddress = user.person().emailAddress();
        Discussion discussion = new Discussion(
                this.tenant(), this.forumId(),
                DomainRegistry.discussionRepository().nextIdentity(),
                authorUser, authorName, authorEmailAddress, aSubject);
        return discussion;
    }
}
```
- **What it demonstrates**: The linguistic tangle — a collaboration Aggregate referencing `User`, querying a Repository for one, and checking `Permission`, all security concepts foreign to the Collaboration Language; the distortion also hides the concept `Author`, whose three attributes are carried around loose instead of as a Value Object.

```java
public class Forum extends Entity {
    public Discussion startDiscussionFor(
        ForumNavigationService aForumNavigationService,
        Author anAuthor,
        String aSubject) {
        if (this.isClosed()) {
            throw new IllegalStateException("Forum is closed.");
        }
        Discussion discussion = new Discussion(
                this.tenant(), this.forumId(),
                aForumNavigationService.nextDiscussionId(),
                anAuthor, aSubject);
        DomainEventPublisher
            .instance()
            .publish(new DiscussionStarted(
                    discussion.tenant(), discussion.forumId(),
                    discussion.discussionId(), discussion.subject()));
        return discussion;
    }
}
```
- **What it demonstrates**: After Segregated Core — `User` and `Permission` are gone, `Author` is an explicit Value Object supplied by the Application Service, and the model expresses only collaboration.

## Reference Tables

| Aspect | Problem Space | Solution Space |
|---|---|---|
| Unit | Subdomain | Bounded Context |
| Question answered | What strategic business challenge must be solved? | How will we implement software to solve it? |
| Content | Core Domain + the Subdomains it must use | One or more specific software models |
| Stability | Varies project to project | Realization view, once developed |
| Ideal alignment | One Subdomain ↔ one Bounded Context (achievable in greenfield) | Legacy/Big Ball of Mud forces intersection |

| Subdomain type | Business must excel? | Typical origin | Example (SaaSOvation) |
|---|---|---|---|
| Core Domain | Yes — competitive advantage | Built, best developers | Agile Project Management Context (ProjectOvation) |
| Supporting Subdomain | No, but specialized | Built because it's specific | Collaboration Context, as add-on to ProjectOvation |
| Generic Subdomain | No | Bought or built once, reusable | Identity and Access Context (IdOvation); mapping service |

## Worked Example
**SaaSOvation's Collaboration Context tangle and its fix.** The CollabOvation team used DDD-Lite: tactical patterns for technical payoff, no strategic design. They baked security and permissions into the collaboration model, so `Forum`, `Post`, `Discussion`, `Calendar`, and `Calendar Entry` all coupled to `User` and `Permission`.

Some argued "So what if collaboration concepts are tightly coupled to Users and Permissions? We must track who did what!" The senior developer's rebuttal was not about coupling: **"The linguistics are wrong here."** Everything in a Collaboration Context must have a linguistic association to collaboration. Users and Permissions are identity and access concepts — security concerns. The right collaboration concepts are Author, Owner, Participant, and Moderator. A Forum does not need to know *who* may post or under what conditions; it needs to know that an Author is posting, the who-may-do-what question having already been answered elsewhere.

The trigger that made the problem undeniable: the team wanted to switch from permissions to role-based access management, and a change to how users or permissions worked would ripple through the whole model.

They considered two [Evans] refactorings:
1. **Responsibility Layers** — push security and permissions into a lower layer of the same model. Rejected: Responsibility Layers address large-scale models where each layer legitimately *stays* in the Core Domain; here the concepts were misappropriated and did not belong at all.
2. **Segregated Core** — search out all security and permissions concerns and refactor them into completely separate packages within the same model. Chosen, because the pattern's own statement fit exactly: use it "when you have a large Bounded Context that is critical to the system, but where the essential part of the model is being obscured by a great deal of supporting capability."

The interim result: all security and permissions classes moved to segregated Modules, and Application Service clients check security *before* calling into the Core Domain. `ForumApplicationService.startDiscussion()` now obtains an `Author` from a `collaboratorService` and passes it to `forum.startDiscussion(...)`, freeing the Core to model only collaboration compositions and behaviors.

The eventual result: a separate **Identity and Access Context** (IdOvation), a Generic Subdomain to its consumers, with multitenancy, invitation-only self-service registration, encrypted passwords, nested groups, and role-based permissions publishing Domain Events named as past-tense noun-verb pairs (`TenantProvisioned`, `UserPasswordChanged`, `PersonNameChanged`). Business leadership endorsed the direction once they saw the separated service could become a new SaaS product.

**The road not taken:** the team could have miniaturized — ten Bounded Contexts, one per collaboration facility (Forum, Calendar, …), since the facilities were largely uncoupled and each would make a natural deployment unit. They rejected it: ten domain models were unnecessary to achieve the deployment goal and would work against the Ubiquitous Language. Instead they kept one model and produced a separate JAR (Jigsaw module) per facility, plus one for shared model objects like `Tenant`, `Moderator`, `Author`, and `Participant`.

**The next project nearly repeated the mistake:** stakeholders originally planned to build ProjectOvation as a revision-control branch of the CollabOvation model. Having learned from the muddle, they built the Agile Project Management Context separately, thinking of its consumers as Product Owners and Team Members — the Scrum roles — with users and roles managed inside the Identity and Access Context. ProjectOvation is also designed to keep functioning autonomously if IdOvation or CollabOvation goes offline.

## Key Takeaways
1. Never model the whole enterprise in one model; decompose the Domain into Subdomains and develop models in Bounded Contexts.
2. A Bounded Context is a linguistic boundary — use "does every term here have one unambiguous meaning?" as the touchstone.
3. Aim for one Subdomain per Bounded Context; expect to fail at that in brownfield, and use Subdomains as an assessment view over the mud instead.
4. Classify Subdomains from *your* business's viewpoint: what is Generic to your consumers may be your Core Domain.
5. Name Bounded Contexts as `Name-of-Model Context` and make those names part of the Ubiquitous Language.
6. Size a Context by its Language, never by architecture, deployment packaging, or developer task distribution — fake boundaries fragment the Language.
7. One team per Bounded Context; the sole exception is two teams jointly designing a Shared Kernel, which is uncommon and generally avoided.
8. Duplicate objects appearing identically in two Contexts signal a modeling error — unless the Contexts share a Shared Kernel.

## Connects To
- **ch01**: Ubiquitous Language and the Core Domain investment argument this chapter operationalizes; the SaaSOvation/DDD-Lite backstory starts there.
- **ch03**: Context Maps — the tool for mapping and integrating the Bounded Contexts identified here; Shared Kernel, Big Ball of Mud, and Open Host Service are defined there.
- **ch04**: Architecture — Layers and Hexagonal, and how the components inside a Bounded Context are arranged.
- **ch06**: Value Objects and Standard Type (the `Security`/`Futures` example).
- **ch07, ch08, ch09, ch10, ch12**: Domain Services, Domain Events, Modules, Aggregates, Repositories — the elements counted when right-sizing a Context.
- **ch13**: Integrating Bounded Contexts — the implementation of the integrations sketched here.
- **ch14**: Application Services and User Interface, both inside the Bounded Context boundary.
- **Smart UI Anti-Pattern [Evans]**: Rejected — do not drag domain concepts into the UI.
