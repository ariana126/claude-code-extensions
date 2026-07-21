# Chapter 10: Aggregates

## Core Idea
An Aggregate is a **transactional consistency boundary**, not an object graph — cluster only what must be transactionally consistent to satisfy a *true* business invariant, and make everything outside that boundary eventually consistent. You cannot correctly reason about Aggregate design without applying transactional analysis.

## Frameworks Introduced

- **Rule: Model True Invariants in Consistency Boundaries**: An invariant is a business rule that must *always* be consistent (`c = a + b`); design the boundary around exactly the attributes that rule spans. Aggregate is synonymous with transactional consistency boundary.
  - When to use: at the start of every Aggregate discovery effort in a Bounded Context.
  - How:
    1. State the candidate rule out loud in the Ubiquitous Language; if domain experts don't recognize it as a rule, it's probably a false invariant.
    2. Distinguish transactional consistency (immediate, atomic) from eventual consistency — "invariant" always means the former.
    3. Draw a boundary around only the attributes that rule spans; consistency *outside* the boundary is irrelevant to this Aggregate.
    4. Test the design: can this Aggregate be modified in any way the business requires with its invariants fully consistent in a single transaction?
    5. Enforce the corollary: a properly designed Bounded Context modifies **only one Aggregate instance per transaction**, in all cases.
    6. Push the constraint into the UI — each user request should execute a single command on a single Aggregate instance.
  - Why it works / failure mode: false invariants are artificial constraints imposed by developers ("we must not allow a committed backlog item to be removed"), not business rules. They produce large clusters whose optimistic-concurrency version collides on unrelated operations — planning a backlog item fails a concurrent release scheduling, which is logically absurd.

- **Rule: Design Small Aggregates**: Limit the Aggregate to the Root Entity plus a minimal number of attributes and/or Value-typed properties — "the correct minimum is however many are necessary, and no more."
  - When to use: always; default to a single Root Entity and only add Entity parts when a true invariant forces it.
  - How:
    1. Include an attribute if it must be consistent with others — even implicitly (`name` and `description` on `Product` change together, though no expert states it as a rule).
    2. For each candidate contained part, ask: must it change over time, or can it be **completely replaced**? Replaceable ⇒ Value Object, not Entity.
    3. Prefer Value parts: they serialize with the Root, avoid SQL joins and separate tracking, are smaller, immutable, and easier to unit-test.
    4. Do a back-of-the-envelope (BOTE) count of collected objects at realistic production scale, then walk common usage scenarios.
    5. When a true consistency rule appears, add a few Entities or a collection — then keep pushing size back down.
  - Why it works / failure mode: smaller Aggregates perform, scale, *and* bias toward transactional success (commit conflicts become rare). A large cluster loads thousands of objects to add one element and "will never perform or scale well." Niclas Hedhman's team designed ~70% of Aggregates as a single Root Entity with Value properties; the other 30% had two to three Entities.

- **Rule: Reference Other Aggregates by Identity**: Hold `private ProductId productId;` rather than `private Product product;`. A direct reference does not place the referenced Aggregate inside your consistency boundary — there are still two Aggregates, not one.
  - When to use: for every association that crosses an Aggregate boundary.
  - How:
    1. Replace direct object pointers with the other Aggregate's globally unique identity Value type.
    2. Never modify both the referencing and referenced Aggregate in one transaction.
    3. Resolve dependencies **before** invoking Aggregate behavior: an Application Service uses Repositories/Domain Services to look up collaborators and passes them in.
    4. For complex domain-specific resolution, pass a Domain Service into the command method and let the Aggregate **double-dispatch** to it.
    5. For view assembly, accept multiple Repository calls; if query overhead bites, consider theta joins or CQRS before reintroducing direct references.
  - Why it works: inferred references are never eagerly loaded, so Aggregates are automatically smaller, faster to load, and cheaper on memory/GC. It also enables **almost-infinite scalability** via continuous repartitioning of Aggregate storage (Pat Helland, "Life beyond Distributed Transactions"), and lets Domain Events carry identities across Bounded Contexts to form remote associations.

- **Rule: Use Eventual Consistency Outside the Boundary**: "Any rule that spans AGGREGATES will not be expected to be up-to-date at all times." If executing a command on one Aggregate requires business rules to run on others, use eventual consistency.
  - When to use: whenever a single client request must affect two or more Aggregate instances.
  - How:
    1. Ask domain experts what delay is tolerable — they are often far more comfortable with delay than developers, and will accept seconds, minutes, hours, or days.
    2. Have the Aggregate command method publish a Domain Event carrying the relevant identities.
    3. Deliver it to asynchronous subscribers; each retrieves its own Aggregate and modifies **one instance per transaction**.
    4. On concurrency contention, don't acknowledge the message — let it be redelivered and retried up to a retry limit.
    5. On complete failure, compensate or report for pending intervention.
    6. Rewrite the use case to specify eventual consistency *and the acceptable update delay*.

- **Ask Whose Job It Is** (the tie-breaker, from Eric Evans): Examine the use case and ask whether it is the job of *the user executing this use case* to make the data consistent.
  - When to use: whenever transactional vs. eventual consistency is genuinely unclear and you're about to decide on technical preference alone.
  - How:
    1. Identify the actor performing the use case.
    2. If making the data consistent is that user's job ⇒ try transactional consistency, but only while obeying the other Aggregate rules.
    3. If it's another user's job, or the system's job ⇒ make it eventually consistent.
    4. If the answer is "it depends on the team," that ambiguity is itself a discovery — it may become a configurable workflow preference.
  - Why it works: it exposes the *real* system invariants instead of defaulting to a technical leaning ("classic DDD ⇒ transactional, CQRS ⇒ eventual"), and it deepens domain understanding either way.

## Key Concepts
- **Invariant**: A business rule that must always be transactionally (immediately, atomically) consistent.
- **Consistency boundary**: The line asserting everything inside adheres to its invariants no matter what operation runs; consistency outside is irrelevant.
- **False invariant**: An artificial constraint imposed by developers (e.g., "don't allow removal") that drives large-cluster design without a real business rule.
- **Large-cluster Aggregate**: An Aggregate designed for compositional convenience; loads many collections per operation and collides under optimistic concurrency.
- **Optimistic concurrency**: A version attribute incremented on change and checked before save; a stale client version is rejected — this is what protects invariants from concurrent modification.
- **Disconnected Domain Model**: Using a Repository from *inside* an Aggregate for lookup — a form of lazy loading, and the less favorable approach.
- **Double-dispatch**: Passing a Domain Service into an Aggregate command method so the Aggregate can call back to resolve references.
- **User-aggregate affinity**: A workflow where only one user focuses on a given set of Aggregate instances at a time; makes multi-Aggregate transactions safer when you're forced into them.
- **BOTE calculation**: Back-of-the-envelope sizing of how many objects an Aggregate really holds in production.
- **Almost-infinite scalability**: Scale achieved by continuous repartitioning of Aggregate storage, enabled by identity-only references (Helland).

## Mental Models
- Think of an Aggregate as a **transaction, not a tree**. If you're drawing composition to enable deep navigation, you're modeling the wrong thing.
- Use the **"whose job is it?"** question to break consistency ties, never "we're a CQRS shop" or "we're a classic DDD shop."
- Use **skepticism toward use cases**: when a spec demands multiple Aggregates change in one transaction, suspect a missed invariant (fold them into one new named concept) *or* a missing eventual-consistency story — don't just obey the spec.
- Think of a hand-waving concurrency failure as the model **shouting a missing concept at you**.
- Treat **`0..*` as a lie**: the count is almost never zero and keeps growing over time.

## Code Examples
```java
public class ProductBacklogItemService ... {
    @Transactional
    public void planProductBacklogItem(
        String aTenantId, String aProductId,
        String aSummary, String aCategory,
        String aBacklogItemType, String aStoryPoints) {

        Product product =
            productRepository.productOfId(
                    new TenantId(aTenantId),
                    new ProductId(aProductId));

        BacklogItem plannedBacklogItem =
            product.planBacklogItem(
                    aSummary, aCategory,
                    BacklogItemType.valueOf(aBacklogItemType),
                    StoryPoints.valueOf(aStoryPoints));

        backlogItemRepository.add(plannedBacklogItem);
    }
}
```
- **What it demonstrates**: After the redesign, `planBacklogItem()` is a CQS *query* acting as a Factory returning a new Aggregate, which the Application Service adds to its own Repository — instead of a `void` CQS command mutating a collection on `Product`.

```java
public class Product extends ConcurrencySafeEntity {
    public void reorderFrom(BacklogItemId anId, int anOrdering) {
        for (ProductBacklogItem pbi : this.backlogItems()) {
            pbi.reorderFrom(anId, anOrdering);
        }
    }
    public Set<ProductBacklogItem> backlogItems() {
        return this.backlogItems;
    }
}
// ProductBacklogItem.reorderFrom(...) is declared *protected* —
// only Product can invoke the state-modifying command.
```
- **What it demonstrates**: Tell, Don't Ask — the collection may be exposed for querying, but every state-altering command on a part is protected-scope, so clients can never determine or mutate the Root's shape.

## Reference Tables

| Reason to break the rules | Situation | Why it's tolerable / the cost |
|---|---|---|
| **One: User Interface Convenience** | Batch-creating many Aggregates from one form (`planBatchOfProductBacklogItems`) | No invariant issue — creating N Aggregates in a loop is semantically identical to creating them one at a time; each maintains its own invariants |
| **Two: Lack of Technical Mechanisms** | No messaging, timers, or background threads available for out-of-band processing | Forced multi-Aggregate transactions; safer if **user-aggregate affinity** holds. Don't retreat to large clusters instead |
| **Three: Global Transactions** | Legacy/enterprise policy mandates two-phase commit | Still avoid multi-Aggregate modification *within your local Bounded Context*; the system will never scale as it could |
| **Four: Query Performance** | Repository query overhead argues for a direct object reference | Weigh against size and performance trade-offs; e.g. lazily-loaded `useCaseDefinition` held by direct reference |

| | Transactional consistency | Eventual consistency |
|---|---|---|
| Scope | Inside one Aggregate boundary | Between Aggregates, and across Bounded Contexts |
| Trigger | It is *this* user's job to make the data consistent | It's another user's job, or the system's job |
| Mechanism | Single transaction, optimistic concurrency version | Domain Event + async subscriber, one Aggregate per transaction, retry on contention |
| UI impact | Immediate | Show a visual cue that status is uncertain, or let the next rendered view show it |

## Worked Example
**First Attempt: Large-Cluster Aggregate.** SaaSOvation's ProjectOvation team read the Language statement "Products *have* backlog items, releases, and sprints" as composition, and added consistency rules like "if a backlog item is committed to a sprint, we must not allow it to be removed." `Product` became one huge Aggregate:

```java
public class Product extends ConcurrencySafeEntity {
    private Set<BacklogItem> backlogItems;
    private Set<Release> releases;
    private Set<Sprint> sprints;
    private ProductId productId;
    private TenantId tenantId;
    ...
}
```

In production it failed immediately. Bill and Joe both load `Product` version 1. Bill plans a `BacklogItem`; the `Product` version becomes 2. Joe schedules a `Release` and his commit is rejected as stale. Nothing about planning a backlog item logically interferes with scheduling a release — but the shared Root version says otherwise. During a sprint planning meeting, with many users, nearly every request fails. The rules that drove the design were **false invariants**: developer-imposed removal constraints, not business rules. Beyond transactions, the cluster also loaded thousands of backlog items into memory just to append one, and would only get worse as tenants and products multiplied.

**Second Attempt: Multiple Aggregates.** Split into four Aggregates — `Product`, `BacklogItem`, `Release`, `Sprint` — each associated by inference through a shared `ProductId`. The `Product` method signatures change from `void planBacklogItem(...)` (a CQS command mutating a collection) to `BacklogItem planBacklogItem(...)` (a CQS query acting as a Factory). The transaction failure was solved **by modeling it away**: any number of `BacklogItem`, `Release`, and `Sprint` instances can now be created simultaneously.

**Rethinking Again: should `Task` split from `BacklogItem`?** The Language stated a genuine invariant: when a member estimates zero hours remaining on a task, `BacklogItem` checks all tasks and auto-transitions its status to done (or regresses it if hours return). BOTE analysis: ~12 days per sprint × 12 hours per task ⇒ 12 estimation logs per task, ~12 tasks per backlog item ⇒ **144 collected objects**, but with lazy loading only 1 + 12 + 12 = **25 objects maximum in memory** per request, and only at sprint end. Contention analysis showed only the 144th estimate ever modifies the Root. The eventual-consistency alternative (a `TaskHoursRemainingEstimated` Event → subscriber → Domain Service → `BacklogItem.estimateTaskHoursRemaining()`, optimized with a `select sum(task.hoursRemaining)` Repository query) worked, but complicated the UI with stale status. Then they asked **whose job is it?** — if the team member finishing the last task should trigger "done," compose `Task` inside `BacklogItem`; if a product owner verifies completion manually, neither consistency mode is needed. No clear answer emerged, which revealed a new domain aspect: it should be a configurable workflow preference. **Decision:** keep `Task` inside `BacklogItem` (it supports both automatic and manual transitions), and solve the real concern — the oversized `story` attribute — with a separate lazily-loaded `useCaseDefinition`, deliberately breaking the reference-by-identity rule for query performance. The whole discovery session cost 30–60 minutes.

## Key Takeaways
1. Aggregate = transactional consistency boundary. Design it by transactional analysis, never by drawing object graphs.
2. Modify exactly one Aggregate instance per transaction; treat any violation as a signal that a boundary is wrong or a concept is missing.
3. Interrogate every candidate invariant — developer-imposed "you can't delete this" rules are false invariants that create unscalable clusters.
4. Default to a Root Entity with Value-typed properties; promote a part to an Entity only when it must change rather than be replaced.
5. Reference other Aggregates by their globally unique identity Value type; resolve collaborators in the Application Service and pass them into the command method.
6. Use Domain Events plus async subscribers for anything spanning Aggregates, and negotiate the acceptable delay with domain experts explicitly.
7. Break the rules only for UI batch convenience, missing async mechanisms, mandated global transactions, or measured query performance — deliberately, never by default.
8. Never inject Repositories or Domain Services into Aggregates; look dependencies up first and pass them in.

## Connects To
- **ch05**: Entities — Root Entity identity, surrogate identity, `ConcurrencySafeEntity` as a Layer Supertype, optimistic concurrency versioning, self-delegating guards.
- **ch06**: Value Objects — why favoring Value parts makes Aggregates smaller, safer, and cheaper to persist.
- **ch07**: Domain Services — double-dispatch into an Aggregate; coordinating eventual consistency across Aggregates.
- **ch08**: Domain Events — the mechanism for eventual consistency inside and across Bounded Contexts.
- **ch09**: Modules — `product`, `product.backlogitem`, `product.release`, `product.sprint` reflect these Aggregate boundaries.
- **ch11**: Factories — `Product.planBacklogItem()` / `scheduleRelease()` / `scheduleSprint()` are Factory Methods on the Root.
- **ch12**: Repositories — one per Aggregate; `nextIdentity()` generates the Root's globally unique id.
- **ch14**: Application Services and User Interface — transactional boundary owner; UI should issue one command per Aggregate per request.
- **Pat Helland, "Life beyond Distributed Transactions"**: his "entity" is our Aggregate; identity references enable repartitioning and almost-infinite scale.
- **CQS (Fowler)**: command/query separation explains why `planBacklogItem()` changed from `void` to returning the new Aggregate.
- **Law of Demeter / Tell, Don't Ask**: information-hiding principles for Aggregate interfaces — Law of Demeter is stricter (no navigation past the Root); Tell, Don't Ask permits navigation for queries but keeps mutation inside the Aggregate, and is more broadly applicable.
- **NoSQL / key-value stores (MongoDB, Riak, Coherence, GemFire)**: whole-Aggregate-as-one-value persistence sidesteps the Root-versioning problem entirely.
