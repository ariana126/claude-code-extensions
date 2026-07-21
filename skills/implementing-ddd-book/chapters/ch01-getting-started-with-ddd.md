# Chapter 1: Getting Started with DDD

## Core Idea
DDD is not primarily a technology: it is a discipline of discussion, listening, and discovery that produces a Ubiquitous Language shared by domain experts and developers and captured directly in code. Invest that effort only where the domain is genuinely complex — the Core Domain — and score the project before committing.

## Frameworks Introduced

- **DDD Scorecard**: A points-based qualification test for whether a project deserves the DDD investment. Score each row of the scorecard table that describes your project, tally the points, and **if the total is 7 or higher, seriously consider using DDD**.
  - When to use: during project planning, before a major architectural commitment, because "once we make a major architectural decision and get several use cases deep in development, we are usually stuck with it."
  - How:
    1. Determine not whether the domain is *complex* (subjective, varies per company) but whether it is **nontrivial** — maturity, team capability, and challenge level differ per business.
    2. Score each descriptive row; complexity, expected growth in complexity, uncertain/changing requirements, and unclear Core Domain boundaries push the score up; pure data-centric CRUD with few, stable operations pushes it down.
    3. Tally. 7+ → invest in DDD. Below → a simpler approach (Transaction Script, Active Record) is honest and cheaper.
    4. Re-score when the domain shifts; being on the wrong side of complexity is expensive either way.
  - Why it works / failure mode: it forces the complexity decision *early*, while it is still cheap to change. Failure mode: teams underestimate domain complexity and innovation during planning, then discover Transaction Script requires as much or more code than a domain model.

- **Ubiquitous Language**: A shared team language developed *by the team* — domain experts and developers together — spoken openly and captured in the model in the code. Not "the language of the business," not industry-standard terminology, not the domain experts' lingo.
  - When to use: always, from the first modeling conversation, inside one Bounded Context.
  - How:
    1. Draw pictures of the physical and conceptual domain, labeled with names and actions; keep it informal — avoid ceremony that stifles discovery.
    2. Create a glossary of terms with simple definitions; list alternative terms, including the ones that failed, and why.
    3. If you dislike glossaries, capture documentation containing informal drawings — the goal is to force more terms and phrases to surface.
    4. Circle back with the whole team to review captured phrases; be agile and edit heavily.
    5. Speak the Language literally, in full sentences: "Nurses administer flu vaccines to patients in standard doses."
    6. Move it into code and tests, then **abandon the drawings and glossary** when they become impractical to keep in sync — team speech and the model in the code are the only guaranteed current denotations.
  - Why it works / failure mode: it removes translation between business and technical mental models, so business know-how outlives the team. Failure mode: attempting one Ubiquitous Language for a whole enterprise — "if you try to apply a single Ubiquitous Language to an entire enterprise, or worse, universally among many enterprises, you will fail."

- **Domain Model Health Check (Anemic Domain Model self-examination)**: A two-question checkup; you must be able to answer an emphatic "Yes!" to both, or the model is anemic.
  - When to use: on any codebase claiming to have a domain model.
  - How: if both answers are "No," the domain is healthy; both "Yes," it is very ill; one of each means run the examination again — you are in denial. Anemia costs you the full price of a domain model with none of the benefit: you map objects to and from the store all day and get a data model projected into objects, closer to Active Record, and honestly a Transaction Script.

- **Test-First Domain Object Design (DDD Is Not Heavy)**: Five steps proving DDD fits agile without heavy up-front design.
  - When to use: developing a new Entity or Value Object.
  - How:
    1. Write a test demonstrating how a client of the model should use the new domain object.
    2. Create the domain object with just enough code to make the test compile.
    3. Refactor both until the test represents real client usage and the object has proper behavioral method signatures.
    4. Implement each behavior until the test passes; refactor out inappropriate duplication.
    5. Demonstrate the code to team members **including domain experts**, to confirm the test uses the object per the current meaning of the Ubiquitous Language.
  - Note: use realistic test data — otherwise nontechnical domain experts cannot judge the implementation.

- **Justification for Tactical Modeling**: Criteria for spending the extra effort on Aggregates, Entities, Value Objects, Services, and Domain Events.
  - How: (a) If the Bounded Context is the Core Domain — complex, innovative, must endure through change — use the tactical patterns and staff it with your best developers. (b) A domain that is Generic or Supporting *to its consumers* may still be your Core Domain; judge from your business's viewpoint, not the customer's. (c) For a Supporting Subdomain that cannot be bought off the shelf, apply tactical patterns only if the team is capable and the model is innovative (adds business value, captures special knowledge — not merely technically intriguing).
  - Additional decision parameters: Are domain experts available and are you committed to forming a team around them? Will a simple domain grow complex, and is later refactoring from Transaction Script practical? Will tactical DDD ease integration with other Bounded Contexts? Will Transaction Script really be less code? Does the timeline allow the overhead? Will the investment protect the Core Domain from disruptive architectural change?

## Key Concepts
- **Domain Model**: A software model of a very specific business domain, usually an object model whose objects carry both data and behavior with literal, accurate business meaning.
- **Domain Expert**: Not a job title — whoever knows the line of business best; may be a product designer, salesperson, CEO, or VP.
- **Bounded Context**: A conceptual boundary within which every domain term has one specific contextual meaning; one of the two primary pillars of DDD alongside the Ubiquitous Language, and "one cannot properly stand without the other."
- **Core Domain**: The model area most valuable and important to the business, deserving the greatest investment and the best developers.
- **Strategic Design**: Determines the most important software investments, which existing assets to leverage, and who must be involved.
- **Tactical Design**: The building blocks (Aggregates, Entities, Value Objects, Services, Domain Events) used to craft the single elegant model of a solution.
- **Anemic Domain Model**: A "model" of getters and setters with no inherent behavior — a data model projected into objects, not a domain model.
- **DDD-Lite**: Using a subset of the tactical patterns while skipping Ubiquitous Language discovery, Bounded Contexts, and Context Mapping; technically focused, lower reward.
- **Anemia-Induced Memory Loss**: The state where no one can recall why a versatile do-everything method exists or how many correct uses it has.

## Mental Models
- **Use DDD to simplify, not to complicate.** Model a complex domain in the simplest possible way; never use DDD to make a solution more complex.
- **Think of "the design is the code and the code is the design."** Whiteboard diagrams are not the design — just a way to discuss model challenges.
- **When useful and realistic models diverge, DDD chooses useful.** You are not modeling the "real world"; you are delivering the model most useful to the business.
- **Think of strategic design as reading the map and tactical design as the climbing gear.** You study terrain and borders first; only when the route demands a vertical rock face do you bring pitons, cams, and carabiners.

## Anti-patterns
- **Anemic Domain Model**: You pay the full cost of building a domain model (including the object-relational impedance mismatch) and receive almost none of the benefit.
- **Intention-revealing failure in a catch-all `saveCustomer()`**: Three problems at once — the interface reveals little intention, the implementation adds hidden complexity, and the "domain object" is a dumb data holder. It becomes untestable because it can function incorrectly in more ways than correctly.
- **Setting attributes to express a business operation**: Puts the onus on the client to know the correct combination of fields; guards belong in behavior, not in setters that would have to understand the object's full state.
- **Publishing Domain Events from the client** because behavior lives outside the model: leaks domain logic out of the model. Bad.
- **A single enterprise-wide Ubiquitous Language**: Guaranteed failure; there is one Ubiquitous Language per Bounded Context.
- **DDD-Lite by default**: Skipping Subdomains and explicit Bounded Contexts produces exactly the tangles the tactical patterns cannot fix.

## Code Examples
```java
public class BacklogItem extends Entity {
    private SprintId sprintId;
    private BacklogItemStatusType status;

    public void commitTo(Sprint aSprint) {
        if (!this.isScheduledForRelease()) {
            throw new IllegalStateException(
                "Must be scheduled for release to commit to sprint.");
        }
        if (this.isCommittedToSprint()) {
            if (!aSprint.sprintId().equals(this.sprintId())) {
                this.uncommitFromSprint();
            }
        }
        this.elevateStatusWith(BacklogItemStatus.COMMITTED);
        this.setSprintId(aSprint.sprintId());
        DomainEventPublisher
            .instance()
            .publish(new BacklogItemCommitted(
                    this.tenant(),
                    this.backlogItemId(),
                    this.sprintId()));
    }
}
```
- **What it demonstrates**: A single Ubiquitous Language behavior (`backlogItem.commitTo(sprint)`) replaces the client's `setSprintId()` + `setStatus()` pair, absorbing the guard, the uncommit-first rule, and event publication — and reveals that the data-centric version was incomplete and buggy.

## Worked Example
**The requirement, spoken in the Language:** "Allow each backlog item to be committed to a sprint. It may be committed only if it is already scheduled for release. If it is already committed to a different sprint, it must be uncommitted first. When the commit completes, notify interested parties." Plus: "Allow each backlog item to be uncommitted from a sprint. When the backlog item is uncommitted, notify interested parties."

**Before:** `BacklogItem` exposes `setSprintId()` and `setStatus()`. The client writes two lines and must know the correct pairing. If a third attribute is added later, every client must be re-analyzed. Neither "behavior" carries business value or reveals intention, and the developer suffers cognitive overload picking attributes out of a data-centric model.

**After:** `commitTo(aSprint)` encodes the release guard, the uncommit-first rule, the status elevation, and the notification. Because `uncommitFromSprint()` itself publishes its Event, `commitTo()` never needs to know that it notifies — the second requirement is satisfied for free. Client code reduces to `backlogItem.commitTo(sprint)`.

**The parallel refactor at the application layer:** the catch-all `saveCustomer(customerId, firstName, lastName, street1, street2, city, state, postalCode, country, homePhone, mobilePhone, primaryEmail, secondaryEmail)` — which had degenerated into thirteen null checks so it could serve "at least a dozen business situations" — is split. `Customer` gains an intention-revealing interface: `changePersonalName()`, `relocateTo()`, `changeHomeTelephone()`, `disconnectHomeTelephone()`, `changeMobileTelephone()`, `disconnectMobileTelephone()`, `primaryEmailAddress()`, `secondaryEmailAddress()`. Each Application Service method then handles exactly one use case flow or user story:

```java
@Transactional
public void changeCustomerPersonalName(
    String customerId, String customerFirstName, String customerLastName) {
    Customer customer = customerRepository.customerOfId(customerId);
    if (customer == null) {
        throw new IllegalStateException("Customer does not exist.");
    }
    customer.changePersonalName(customerFirstName, customerLastName);
}
```

No client passes ten nulls after the first and last name. The narrower Application Service implies a narrower user interface goal, and the method can now be tested to confirm it does exactly what it should and nothing it shouldn't.

## Key Takeaways
1. Score the project first — 7 or higher on the DDD Scorecard before you commit; don't invest in what can be easily replaced.
2. Develop the Ubiquitous Language *with* domain experts; it is created by the whole team, not adopted from business jargon or industry standards.
3. There is one Ubiquitous Language per Bounded Context, and Bounded Contexts are smaller than you first imagine — large enough only to capture the complete Language of the isolated domain, and no larger.
4. Reject every concept that is not part of the agreed-upon Ubiquitous Language of your isolated Context.
5. Expose intention-revealing behaviors, not attribute accessors; each Application Service method should handle a single use case flow or user story.
6. Team speech and the model in the code are the only enduring expression of the Language — be prepared to abandon glossaries and drawings.
7. Sell DDD on business value: a useful model, precise business understanding, expert contribution to design, better UX, clean boundaries, better enterprise architecture, agile continuous modeling, and new strategic and tactical tools.

## Connects To
- **ch02**: Core Domain, Supporting Subdomain, Generic Subdomain, and Bounded Context are defined and applied there; the SaaSOvation Users/Permissions tangle is resolved there.
- **ch03**: Context Maps integrate the multiple Bounded Contexts that always surround the one you develop.
- **ch04**: Architecture — where DDD fits with Layers, Hexagonal, Event-Driven, and CQRS; Application Services also treated in ch14.
- **ch05, ch06, ch07, ch08, ch10**: Entities, Value Objects, Services, Domain Events, and Aggregates — the tactical tools justified by this chapter's criteria.
- **ch09**: Modules — the lighter alternative to a heavy subsystem for a simple Subdomain.
- **ch14**: Application Services and User Interface, the layer refactored in the worked example.
- **[Fowler, Anemic] / [Fowler, P of EAA]**: Anemic Domain Model, Active Record, Transaction Script — the alternatives to a real domain model.
- **[Evans]**: The original strategic design and Ubiquitous Language material this chapter builds on.
