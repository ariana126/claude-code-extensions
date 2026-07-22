# Chapter 12: Stream Processing

## Core Idea
Stream processing is batch processing over **unbounded** input: events arrive forever, so you can never "finish." Mutable state and an append-only log of immutable events are two sides of the same coin — state is the integral of the event stream over time, and the changelog is the derivative of state.

## Frameworks Introduced

- **Log-based message broker** (Kafka, Kinesis; Pub/Sub is similar but exposes a JMS-style API): combine the durable storage of a database with the low-latency notification of messaging. A topic is a group of **partitions** (shards); within a partition messages are append-only and totally ordered by a monotonically increasing **offset**. No ordering across partitions.
  - When to use: high message throughput, each message fast to process, ordering matters, and you want to replay history. Use a JMS/AMQP broker instead when messages are individually expensive, you want message-level parallelism, and ordering doesn't matter.
  - How: producers append; consumers read sequentially and periodically record their offset (like a replication **log sequence number**). Load balancing assigns whole *shards* to consumers in a **consumer group**; fan-out is free because reading doesn't delete. Route all events that must be ordered together to the same shard by making the natural entity the **partition key** (e.g., user ID).
  - Failure mode: parallelism is capped at the number of shards; one slow message causes head-of-line blocking for its shard; on consumer restart, messages after the last recorded offset are reprocessed.

- **Change data capture (CDC)**: observe all writes to a database and extract them as a stream, making the source database the *leader* and every derived system (search index, cache, warehouse, data lake) a *follower*.
  - When to use: any time the same data lives in multiple stores. It fixes the dual-writes race because the database decides one order and everyone applies that order.
  - How: attach to the logical/row-based replication log (Debezium connectors for MySQL, PostgreSQL, Oracle, SQL Server, Db2, Cassandra; Maxwell parses the MySQL binlog; GoldenGate for Oracle; pgcapture for PostgreSQL; Kafka Connect ties them to Kafka). Bootstrap from a **consistent snapshot** tied to a known log offset — Debezium uses Netflix's DBLog watermarking for incremental snapshots. Then keep the topic **log-compacted** so a new consumer starting from offset 0 gets a full database copy without another snapshot.
  - Caveat: CDC is asynchronous, so all replication-lag problems apply; and it turns an internal schema into a public API.

- **Log compaction**: periodically discard all but the most recent value for each key; a null value (**tombstone**) removes a key. Disk space then depends on the *current contents*, not the write history. Works for CDC (each event carries the full new row) but *not* for event sourcing (events express user intent and don't override each other).

- **Outbox pattern**: expose a purpose-built outbox table to CDC instead of the internal domain schema. It is a dual write, but both writes are in the *same database transaction*, so it avoids the race. Costs: maintaining the internal→outbox transformation, and extra write amplification.

- **Event time vs processing time windowing**: never window by the processing machine's system clock if there is meaningful processing lag.
  - How to trust device clocks: log **three timestamps** — (1) event occurred, per device clock; (2) event sent to server, per device clock; (3) event received, per server clock. `(3) − (2)` estimates the device clock offset; apply it to (1).
  - Straggler handling: either drop them (track a dropped-events metric and alert) or publish a **correction** and retract the previous output. Watermark-style messages ("no more events with timestamp earlier than *t*") work but require tracking each producer individually.

- **Exactly-once semantics** (more accurately **effectively-once**): all outputs and side effects of processing an event persist *if and only if* processing succeeds — downstream messages, emails/push notifications, database writes, operator state changes, and the consumer offset advance, all atomically.
  - Mechanism 1: **microbatching** (Spark Streaming, ~1 s batches — smaller means more scheduling overhead, larger means more latency). Implicitly imposes a tumbling window equal to the batch size, windowed by *processing* time.
  - Mechanism 2: **checkpointing** (Flink) — rolling snapshots of operator state to durable storage, triggered by barriers in the stream, with no forced window size.
  - Mechanism 3: internal **atomic commit** (Google Cloud Dataflow, VoltDB, Kafka transactions) — unlike XA, transactions stay inside one framework covering both state and messaging, and the protocol cost is amortized over many messages per transaction.
  - Mechanism 4: **idempotence** — e.g., store the Kafka offset of the triggering message alongside each written value, and skip the write if the offset was already applied (Storm's Trident). Requires: replay in the same order, deterministic processing, no concurrent writers, and possibly **fencing** on failover.
  - Failure mode of 1 and 2: once output leaves the framework, the framework cannot un-emit it. Microbatching/checkpointing alone are not enough for external side effects.

## Key Concepts
- **Event**: a small, self-contained, immutable object describing something that happened at a point in time, usually carrying a time-of-day timestamp.
- **Backpressure (flow control)**: block the producer when the buffer fills. The three options for slow consumers are drop, buffer, or backpressure; Unix pipes and TCP use backpressure, log-based brokers use large fixed-size buffering (a disk-backed **ring buffer**).
- **Dead letter queue (DLQ)**: park a message that repeatedly kills consumers so the stream unblocks; any message in a DLQ is an error and should be alerted on.
- **Complex event processing (CEP)**: standing queries stored long-term, evaluated against arriving events by a state machine — the inverse of a database, where data persists and queries are transient. Esper, Apama, TIBCO StreamBase; Elasticsearch's **percolator** does the same for full-text search on streams.
- **Incremental view maintenance (IVM)**: compile SQL into operators that recompute only what changed, instead of `REFRESH MATERIALIZED VIEW` reprocessing everything on a schedule. Materialize, RisingWave, ClickHouse, Feldera.
- **Slowly changing dimension (SCD)**: give each version of a joined record (e.g., a tax rate) a unique identifier so joins against historical data are deterministic — at the cost of making log compaction impossible.
- **Crypto-shredding**: store deletable data encrypted and forget the key. Moves the problem to mutable key storage, and you must pick key granularity up front. Datomic's **excision** and Fossil's **shunning** actually rewrite history instead.

## Code Examples

The social-network home timeline expressed as the materialized view that a table–table join maintains:

```sql
SELECT follows.follower_id AS timeline_id,
  array_agg(posts.* ORDER BY posts.timestamp DESC)
FROM posts
JOIN follows ON follows.followee_id = posts.sender_id
GROUP BY follows.follower_id
```
- **What it demonstrates**: a stream–stream join of the `posts` and `follows` changelogs *is* the incremental maintenance of this query's result. If a stream is the derivative of a table and a join is a product `u·v`, the changes follow the product rule `(u·v)′ = u′v + uv′` — any change to `posts` is joined with current followers, and any change to `follows` is joined with current posts.

## Reference Tables

| | AMQP/JMS-style broker | Log-based broker |
|---|---|---|
| Delivery unit | individual message assigned to a consumer | whole shard assigned to a consumer node |
| Progress tracking | per-message acknowledgment | periodic consumer offset checkpoint |
| After processing | message deleted (destructive) | log unchanged (read-only); replayable |
| Ordering under load balancing | broken by redelivery after a crash | preserved within a shard |
| Parallelism | per message, unbounded consumers | at most one consumer per shard |
| Slow message | other consumers proceed | head-of-line blocking in that shard |
| Best for | task queues, async RPC, expensive per-message work | high throughput, ordering, derived data, reprocessing |

| Window type | Definition | Implementation |
|---|---|---|
| **Tumbling** | fixed length, every event in exactly one window (10:03:00–10:03:59, then 10:04:00–10:04:59) | round each event timestamp down to the nearest interval |
| **Hopping** | fixed length with overlap for smoothing (5-min window, 1-min hop: 10:03:00–10:07:59, then 10:04:00–10:08:59) | compute 1-min tumbling windows, aggregate several adjacent ones |
| **Sliding** | all events within an interval *of each other* (10:03:39 and 10:08:12 share a 5-min sliding window) | buffer of events sorted by time, expire old ones |
| **Session** | no fixed duration; events for one user grouped until an inactivity gap (e.g., 30 min) | sessionization for website analytics |

| Join type | Inputs | State maintained | Window |
|---|---|---|---|
| **Stream–stream** (window join) | two activity streams | recent events indexed by join key | bounded time window (e.g., 1 hour) |
| **Stream–table** (enrichment) | activity stream + DB changelog | local copy of the database (hash join), kept fresh by CDC | infinite for the table side, none for the stream side |
| **Table–table** (materialized view maintenance) | two DB changelogs | latest state of both tables | infinite; newer versions overwrite older |

| State recovery strategy | System |
|---|---|
| Snapshot operator state to a DFS | Flink |
| Replicate state changes to a log-compacted Kafka topic | Kafka Streams |
| Redundantly process each input message on several nodes | VoltDB |
| Rebuild by replaying inputs (short windows) or the log-compacted change stream | any CDC-backed local replica |

## Worked Example
**The dual-writes race, and how CDC fixes it.** Two clients concurrently update item `X`. Client 1 sets it to `A`; client 2 sets it to `B`. Each application writes first to the database, then to the search index.

Because of unlucky interleaving, the **database** sees client 1's `A` then client 2's `B` and settles on `B`. The **search index** sees client 2's `B` then client 1's `A` and settles on `A`. The two systems are now permanently inconsistent, and **no error occurred** — without a concurrency-detection mechanism like version vectors, one value silently overwrote another and nobody noticed. A second, independent failure mode: one write succeeds and the other fails, which is the atomic commit problem (expensive to solve via 2PC).

The structural cause: there is no single leader. The database has a leader and the search index has a leader, and neither follows the other — it's effectively multi-leader replication.

With CDC, the database alone decides the order `A` then `B` and records it in its replication log in that order. The search index consumes that log and applies the same order, converging on `B`. Adding a data warehouse is just adding another consumer of the same change stream. A log-based broker is the right transport because it preserves order (a JMS/AMQP broker's redelivery would reorder it).

**Corollary sizing calculation** for how much replay headroom a log gives you: a 20 TB drive with 250 MB/s sequential write throughput fills in about **22 hours** at maximum write rate. Since real deployments rarely saturate write bandwidth, a disk-based log typically buffers days or weeks of messages — enough time for a human operator to notice a lagging consumer and fix it before data is lost.

## Mental Models
- **Think of state and the changelog as derivatives of each other**: state is the integral of the
  change stream over time; the changelog is the derivative of state. Either can be reconstructed from
  the other, which is why CDC and event sourcing are the same idea from opposite ends.
- **Use a log-based broker when the consumer is a derived dataset; use a JMS/AMQP-style queue when
  messages are independent tasks.** Consuming a log is non-destructive, so you can replay history
  through new code — the batch-processing property, applied to streams. A queue that deletes on ack
  cannot do that.
- **Think of a stream–table join as querying a local replica, not calling a service.** Maintain a
  local copy of the dimension table via CDC and the join becomes a memory lookup, deterministic on
  replay — unlike a remote query, whose answer changes between runs.
- **Treat window completeness as unknowable.** You cannot prove no more events will arrive; you can
  only choose how long to wait. Every windowing decision is a timeliness/completeness trade.

## Anti-patterns
- **Dual writes from application code** to a database and a search index: the two systems can apply
  concurrent writes in different orders and diverge permanently, with no way to detect it. Make one
  system the leader and derive the rest.
- **Windowing by processing time**: manufactures a fake traffic spike every time a consumer restarts
  and drains a backlog, while the true rate was steady.
- **Trusting the device clock**: mobile clocks are wrong and sometimes deliberately set wrong. Correct
  with three timestamps — event time, device send time, server receive time — and derive the offset.
- **Silently dropping straggler events**: if you ignore late arrivals with no metric, you cannot tell
  correct results from lossy ones. Count what you drop, or publish a correction.
- **Claiming "exactly-once delivery"**: impossible. What is achievable is exactly-once *effect*, via
  idempotence plus atomic commit of output, state, and offset together.
- **Retrying a poison message forever**: blocks the whole partition. Route it to a dead letter queue
  and alert — every DLQ entry is a bug.
- **Exposing internal table schemas directly to CDC consumers**: couples every downstream system to
  your refactorings. Use the outbox pattern to publish a deliberate public event schema.

## Key Takeaways
1. Never do dual writes to two systems from application code. Make one system the leader and derive the rest via CDC or event sourcing.
2. Prefer log-based brokers when you want derived data: consuming is non-destructive, so you can start a second consumer at yesterday's offset, write output elsewhere, and reprocess with new code as many times as you like — the batch-processing property, applied to streams.
3. Window by **event time**, not processing time. Processing-time windows manufacture fake spikes whenever a consumer restarts and drains a backlog, while the true rate was steady.
4. Log compaction turns a topic into a durable full copy of a database keyed by primary key. It works for CDC events (full row per event) but not for event-sourced intent events, which need the whole history plus periodic state snapshots as a read optimization.
5. Exactly-once means "the visible effect is as if processed once." Get it via microbatching, checkpointing, framework-internal atomic commit, or idempotent writes tagged with the source offset — and remember none of these can retract a side effect that already left the framework.
6. A monitored lagging consumer only hurts itself in a log-based system: it consumes no broker resources when shut down beyond its offset, so you can safely consume a production log for debugging.
7. Cross-stream ordering is not guaranteed, so joins against changing state are nondeterministic. Pin the version you joined against (SCD identifiers) or denormalize the value into the event.
8. Probabilistic algorithms (Bloom filters, HyperLogLog, percentile estimators) are a *memory optimization* in stream analytics — stream processing is not inherently approximate.
9. Immutability has limits: high-churn datasets make history grow prohibitively, and GDPR-style deletion means actually rewriting history. Deletion is "harder to retrieve," not "impossible to retrieve."

## Connects To
- **Ch 4 (Storage)**: log-structured storage, log compaction, tombstones, Bloom filters — the same machinery, reused for messaging.
- **Ch 6 (Replication)**: replication logs, log sequence numbers, setting up new followers from a consistent snapshot, replication lag, read-your-own-writes, detecting concurrent writes with version vectors.
- **Ch 7 (Sharding)**: topic partitions and partition keys are shards.
- **Ch 8 (Transactions)**: two-phase commit, XA, read committed isolation, actual serial execution (a single-threaded shard consumer needs no concurrency control).
- **Ch 10 (Consistency and Consensus)**: shared logs and total order broadcast are what a log-based broker is; state machine replication is what a stream consumer does.
- **Ch 11 (Batch Processing)**: same sharding, parallelization, mapping, and filtering — but sorting and sort-merge joins are impossible on unbounded input, and restart-from-scratch fault tolerance doesn't scale to a job running for years.
- **Ch 13**: events touching multiple state shards; avoiding coordination.
- **Papers/systems**: Kreps et al. 2011 (Kafka), Akidau et al. 2015 (the Dataflow Model), Gupta & Mumick 1995 (materialized view maintenance), DBSP 2024 (incremental computation), DBLog watermarking, Gray & Reuter 1992 ("there is no fundamental need to keep a database at all; the log contains all the information there is").
