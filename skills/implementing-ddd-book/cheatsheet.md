# Cheatsheet — Vernon's Decision Rules

## Thresholds & defaults
| Rule of thumb | Value |
|---|---|
| DDD Scorecard total to justify DDD | **≥ 7** |
| Aggregates modified per transaction | **exactly 1** |
| Aggregates that should be a single Root + Values | **~70%** (rest have 2–3 Entities) |
| Module size before splitting into sub-Modules | **~60 classes** |
| NotificationLog page size | **20 entries** (fixed) |
| Broker-offline send back-off | **30–60 seconds** |
| Events enrichment | the **80% rule** — enrich for the common consumer, not all |
| Aggregate discovery session | **30–60 minutes** is enough |

## Should I use DDD here?
- Score ≥ 7 → yes; the model is complex enough that the decision becomes unchangeable a few use cases in
- Core Domain → tactical patterns + your best developers
- Supporting Subdomain → build or contract
- Generic Subdomain → **buy or outsource**; never lavish Core effort on it
- Tactical patterns without strategic design → you're doing DDD-Lite, expect it to rot

## Entity or Value Object?
- Does it **measure, quantify, or describe**? → Value Object
- Must it be **uniquely resolvable and mutable** over time? → Entity
- Requirements say "change" + a search/authentication term? → Entity
- Can the part be **completely replaced** rather than must change? → **Value Object** (default)
- Comes from an upstream Context? → immutable Value; you own fewer properties

## Transactional or eventual consistency?
1. **Ask whose job it is.** Is it *this* user's job to make the data consistent?
   - Yes → try transactional (still obey the other Aggregate rules)
   - Another user's or the system's job → eventual
   - "It depends on the team" → that ambiguity is a discovery; make it a configurable workflow preference
2. Never decide by house style ("we're CQRS" / "we're classic DDD")
3. Eventual → publish a Domain Event, negotiate the **acceptable delay with domain experts** (they tolerate far more than developers expect), one Aggregate per subscriber transaction, retry on contention

## Is this invariant real?
- Say it aloud in the Ubiquitous Language. Experts don't recognize it as a rule? → **false invariant**
- "We must not allow X to be removed" (developer-authored) → false invariant
- Symptom of false invariants: unrelated operations collide on the Root's optimistic-concurrency version

## Where does this behavior live?
| Tempted to write… | Put it in… | Because |
|---|---|---|
| A static method on an Aggregate Root | **Domain Service** | that impulse is the DDD smell for homeless behavior |
| Logic in an Application Service beyond guard-and-delegate | **Domain Service** | domain logic must not leak out of the model |
| A calculation needing 2+ Aggregates or a Repository | **Domain Service** | Aggregates must not access Repositories |
| Validation inside an Entity | **Validator** (Specification/Strategy) | it changes at a different pace and must collect all failures |
| Creation phrased as an Aggregate's behavior | **Factory Method on the Root** | a constructor name can't carry the Language |
| Creation requiring another Context | **Domain Service as Factory** | separates the Contexts' life cycles |

## Repository style
| Your persistence mechanism | Style | Interface |
|---|---|---|
| Hibernate, TopLink, JPA (implicit change tracking) | Collection-oriented | `add`/`remove`, **no** `save` |
| Key-value store, Data Fabric, or may swap later | Persistence-oriented | `save`/`saveAll` |

One Repository per Aggregate type. Transactions belong to an Application Layer Facade, never the Domain Layer.

## UI rendering: which option?
- Presentation tier genuinely **remote** → DTO + DTO Assembler (serialization required; Assembler resolves lazy loads)
- **Single VM** → Domain Payload Object + Domain Dependency Resolver — DTOs here are YAGNI and GC churn
- Query can't be served by the model → **Use Case Optimal Repository Query** into a Value Object
- Many optimal queries piling up → smell: the Repository is **masking Aggregate mis-design**
- Multiple disparate clients → Data Transformer, or void service writing to an output Port

## Integration tells & smells
- Exposing navigable **model** resources → you just created a Conformist or Shared Kernel. Publish **use-case-shaped** resources instead
- Consuming a foreign representation without Separated Interface → Adapter → Translator → foreign vocabulary is in your model
- Replicating an upstream database for "autonomy" → that's a Shared Kernel, and you have no autonomy
- Acting on Events without passing `occurredOn` into the Command → messaging is out-of-order and at-least-once; guard the Aggregate with a change tracker
- Retrying a non-idempotent receiver → make it **find-then-create** first, or retries only produce misleading errors
- Two teams in one Bounded Context → split the Context or merge the teams; two teams diverge the Language
- Terminology fuzzy, boundary unclear → separate with a **Module**, not a Bounded Context (thinner, reversible)

## Breaking the Aggregate rules — the only four sanctioned reasons
1. **UI convenience** (batch-creating N Aggregates from one form) — no invariant issue
2. **Lack of technical mechanisms** (no messaging/timers/threads) — safer under user-aggregate affinity; don't retreat to large clusters
3. **Global transactions** (mandated 2PC) — still avoid multi-Aggregate modification *locally*
4. **Query performance** (measured) — e.g. a lazily-loaded direct reference

## A+ES: worth it?
- Re-execution cheap → resolve concurrency by reload + re-run the delegate
- Re-execution expensive (payments, order placement) → per-Root Event conflict resolution; same-type conflicts, different-type doesn't
- Replaying or applying a post-snapshot tail → call **Mutate/ReplayEvents**, never `Apply` (Apply re-appends to Changes)
- Can't answer a query from Streams → build a **Read Model Projection** (disposable, rebuildable with no downtime)
- Choosing a serializer → **tag-based** (Protocol Buffers, Thrift, Avro, MessagePack) so renames don't break consumers
- Adopting A+ES → plan for CQRS; only pays off on complex competitive-advantage models
