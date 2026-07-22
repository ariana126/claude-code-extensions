# Cheatsheet — DDIA (2nd ed.)

Decision rules, thresholds, and tells. For definitions see `glossary.md`; for full techniques see `patterns.md`.

## Storage engine selection

| If… | Choose | Because |
|---|---|---|
| Write-heavy, throughput matters | LSM-tree | Lower write amplification, better compression |
| Read-heavy, p99 latency matters | B-tree | No compaction interference; predictable reads |
| Analytical scans over few columns | Column store | Scans read only needed columns; RLE/bitmap compress hard |
| Range scans are core | Anything sorted (B-tree, SSTable) | Hash indexes cannot range scan |
| Dataset fits in memory | In-memory store | Speed comes from skipping encoding, not from avoiding disk reads |
| Similarity / semantic search | Vector index (HNSW, IVF) | Exact search doesn't scale past small corpora |

**Thresholds**: Bloom filter ≈ 10 bits/key → ~1% false positives; each +5 bits divides the rate by 10. B-tree branching factor: several hundred. Disk failure ≈ 2–5%/yr (HDD), 0.5–1%/yr (SSD).

## Data model selection

- **One-to-many, read as a unit, whole tree updated together** → document model (locality wins).
- **Many-to-many, or joins you can't predict** → relational (the query optimizer earns its keep).
- **Highly heterogeneous, evolving connections** → graph (property graph or triples).
- **Analytics** → star schema, or one big table when join cost dominates.
- **Tell**: if you're hydrating IDs in application code, you've written a join by hand — and probably an N+1 query.
- **Tell**: if writes must update many copies of the same fact, you denormalized too far.

## Consistency: ask for the weakest guarantee that fixes your bug

| Symptom the user reports | Guarantee to request | Cost |
|---|---|---|
| "I saved it and it vanished" | Read-your-writes | Route reads to leader for recent writers |
| "The comment count went back up" | Monotonic reads | Pin user to one replica |
| "The reply appears before the question" | Consistent prefix reads | Preserve causal order |
| "Two users saw different winners" | Linearizability | Majority quorum / consensus; unavailable during partition |

**Rule**: don't say "we need strong consistency" — name the anomaly. Most bugs need one of the top three, which are far cheaper than linearizability.

## When you actually need consensus

Need it for: leader election, uniqueness constraints, atomic commit across shards, fencing/lease issuance.
Don't need it for: most reads, per-key writes with a single leader, anything you can make idempotent and commutative.
**Rule**: reach for a proven implementation (etcd, ZooKeeper, Raft library) — never hand-roll. FLP says no deterministic async algorithm always terminates; timeouts restore liveness, not safety.

## Sharding decisions

- Range scans needed? → **key-range** sharding. Otherwise → **hash** sharding.
- Always create **many more shards than nodes** (e.g. 1,000 shards / 10 nodes) so rebalancing moves whole shards.
- **Never** `hash(key) % node_count` — every node change reshuffles everything.
- Hot *key* (one celebrity)? → append a random suffix to split it; accept fan-out on every read.
- Hot *shard*? → rebalance or split the range.
- Secondary index: writes ≫ reads → **local/document-partitioned**; reads ≫ writes → **global/term-partitioned**.

## Isolation level selection

| Anomaly | Read committed | Snapshot isolation | Serializable |
|---|---|---|---|
| Dirty read / dirty write | prevented | prevented | prevented |
| Read skew (nonrepeatable read) | **allowed** | prevented | prevented |
| Lost update | **allowed** | usually detected | prevented |
| Write skew / phantom | **allowed** | **allowed** | prevented |

**Escalation ladder for read-modify-write**: atomic op → compare-and-set → `SELECT FOR UPDATE` → serializable isolation → (last resort) materializing conflicts.
**Naming trap**: PostgreSQL "repeatable read" = snapshot isolation; Oracle "serializable" = snapshot isolation. Check what you actually got.
**Pick SSI over 2PL** unless contention is so high that abort-and-retry costs more than blocking.

## Distributed systems assumptions to never make

| Tempting assumption | Reality | Defense |
|---|---|---|
| The timeout means the node is dead | Can't distinguish node from network failure | Design for both; use fencing |
| Network delay is bounded | Multi-**minute** round trips occur under congestion | Timeouts + retries + idempotence |
| My clock is accurate | Drift up to 200 ppm ≈ 6 ms per 30 s; NTP jumps backward | Monotonic clocks for durations; confidence intervals for ordering |
| Holding a lock means I'm still the leader | GC pause / VM steal time makes you a zombie | **Fencing tokens** — locks alone are not enough |
| A process runs at a steady rate | Pauses of tens of seconds happen | Treat every step as arbitrarily delayable |

**Rule**: use time-of-day clocks for *displaying* time, monotonic clocks for *measuring* durations. Never order events across nodes by physical timestamps unless you have bounded uncertainty (and then use the interval, not the point).

## Performance targets

- Measure **response time** distributions, not averages. Report p50/p95/p99 — the average tells you nothing about the worst experience.
- Queueing delay usually dominates the tail; a few slow requests block the queue (head-of-line blocking).
- Tail latency amplifies with fan-out: many backend calls per request → most user requests hit at least one slow backend.
- **Tell**: if load dropped but the system stays down, you have a metastable failure — a retry storm. Fix with backpressure, jittered exponential backoff, and circuit breakers.

## Batch vs. stream

- Input bounded and reruns must be cheap → **batch**. Immutable input gives human fault tolerance: fix code, rerun, damage undone.
- Input unbounded, results needed continuously → **stream**.
- Both, over the same logic → **Kappa**: one system, reprocess history through the streaming path.
- Window by **event time**, never processing time — otherwise draining a backlog fabricates a traffic spike.
- **Rule**: "exactly-once delivery" is impossible; exactly-once *effect* is achievable via idempotence + end-to-end request ID + atomic commit of output/state/offset.

## Derived data discipline

- Designate exactly **one system of record**. Everything else is derived and must be rebuildable from it.
- Never dual-write to two systems from application code — use CDC so derived stores are followers of one ordered log.
- **Integrity** (correct derivation) is non-negotiable and needs no coordination — idempotence and uniqueness checks suffice.
- **Timeliness** is negotiable — let it be eventual, repair with compensating transactions.
- Business constraints are often **loosely interpreted** (overbooking, overdrafts): apologize and compensate rather than coordinate synchronously.

## Ethics checks before shipping

- Replace the word "data" with "surveillance" in your design doc; if it reads sinister, it is.
- Treat personal data as a **toxic asset** — weigh breach risk against value, not just value.
- **Data minimization**: collect only what a specified explicit purpose requires; purge when the purpose ends.
- Consent that costs the user access to an essential service is not freely given.
- Watch for self-reinforcing **feedback loops**: does the system's output shape its own future input?
