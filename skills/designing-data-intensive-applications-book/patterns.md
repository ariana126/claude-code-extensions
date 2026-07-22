# Patterns & Techniques — DDIA (2nd ed.)

## LSM-Tree Storage
**When to use**: write-heavy workloads; when write throughput and compression matter more than predictable read latency.
**How**: buffer writes in an in-memory memtable → flush to immutable sorted SSTables → compact in background (size-tiered or leveled) → Bloom filter per SSTable to skip lookups.
**Trade-offs**: lower write amplification and better compression than B-trees, but reads may touch several SSTables and compaction competes for I/O, hurting p99. Leveled compaction = lower space amplification; size-tiered = lower write amplification.

## B-Tree + Write-Ahead Log
**When to use**: read-heavy and latency-sensitive OLTP; the default unless you have reason otherwise.
**How**: fixed-size pages, branching factor in the hundreds; write to the WAL and fsync before modifying pages, so a torn page can be repaired on recovery.
**Trade-offs**: every write goes to disk at least twice; predictable reads; mature locking for transactions.

## Column-Oriented Storage
**When to use**: analytical scans reading a few columns over many rows.
**How**: store each column in its own file, sorted consistently; compress with bitmap or run-length encoding; low-cardinality columns compress dramatically.
**Trade-offs**: excellent scan and compression performance; single-row reads and updates become expensive — writes usually go through an LSM front end.

## Schema Evolution (Protobuf / Avro)
**When to use**: any data that outlives the code that wrote it — which is all persisted data.
**How**: Protobuf — identify fields by numeric tag; only add optional fields; never change or reuse a tag. Avro — writer's schema and reader's schema resolved by field *name*, with reader-declared defaults; distribute schemas via a registry that checks compatibility before deploy.
**Trade-offs**: Protobuf tags are simple but demand discipline; Avro needs schema distribution but supports dynamically generated schemas.

## Single-Leader Replication
**When to use**: the default; you need a simple, correct answer to "who decides write order?"
**How**: all writes go to the leader, which ships a logical (row-based) replication log to followers. New followers start from a snapshot plus its log position. Semisynchronous: one synchronous follower, the rest async.
**Trade-offs**: no write conflicts, but the leader is a throughput ceiling and failover risks split brain, lost writes, and stale reads.

## Quorum Reads and Writes
**When to use**: leaderless (Dynamo-style) stores where availability during partitions beats strong consistency.
**How**: write to `w` replicas, read from `r`, with `w + r > n` so the sets overlap. Repair with read repair, hinted handoff, and anti-entropy.
**Trade-offs**: no failover needed, but the overlap guarantee is weaker than it looks — sloppy quorums, concurrent writes, and clock skew all break it. Use version vectors, not last-write-wins, unless discarding data is acceptable.

## Consistency Guarantees You Can Actually Ask For
**When to use**: instead of demanding "strong consistency", name the specific anomaly you must prevent.
**How**: read-your-writes (see your own updates) → monotonic reads (never go backward in time) → consistent prefix reads (causal order) → linearizability (one copy, atomic ops).
**Trade-offs**: each step up costs coordination and latency; linearizability requires a majority quorum or consensus and is unavailable during partitions.

## Sharding
**When to use**: dataset or throughput exceeds one machine.
**How**: **key-range** shards keep keys sorted (range scans work, hot spots likely); **hash sharding** spreads load (kills range scans). Prefer many more shards than nodes so rebalancing moves whole shards. Never use `hash(key) % N` with N = node count.
**Trade-offs**: relieve a hot key by appending a random suffix — at the cost of fanning out every read of that key.

## Secondary Indexes on Sharded Data
**When to use**: you need queries by a non-partition-key field.
**How**: **local (document-partitioned)** — each shard indexes only its own data; cheap writes, scatter/gather reads. **Global (term-partitioned)** — index sharded by term; a single-shard read, but writes touch remote shards and are usually asynchronous.
**Trade-offs**: pick by read/write ratio. Global indexes usually give up read-your-writes on the index.

## Snapshot Isolation (MVCC)
**When to use**: long-running read-only queries alongside writes; the sweet spot for most applications.
**How**: keep multiple committed row versions; each transaction reads the versions committed as of its start.
**Trade-offs**: prevents dirty and nonrepeatable reads, but not lost updates or write skew. Confusingly named "repeatable read" in PostgreSQL and "serializable" in Oracle.

## Preventing Lost Updates and Write Skew
**When to use**: read-modify-write cycles and invariants spanning multiple rows.
**How**: atomic operations (`UPDATE … SET x = x + 1`) > conditional write / compare-and-set > explicit `SELECT FOR UPDATE` > materializing conflicts (rows created solely as lock targets) > actual serializable isolation.
**Trade-offs**: materializing conflicts is ugly and error-prone — reach for serializable isolation first.

## Serializable Snapshot Isolation (SSI)
**When to use**: you want real serializability without 2PL's latency collapse.
**How**: run optimistically on a snapshot; track read-write dependencies; abort a transaction at commit time if its read premise became stale.
**Trade-offs**: no blocking, scales across shards, but aborts under contention — the application must retry.

## Two-Phase Commit (2PC)
**When to use**: atomic commit spanning heterogeneous systems, when there is no better option.
**How**: coordinator sends prepare, participants vote and durably promise, coordinator writes the decision and sends commit/abort.
**Trade-offs**: a coordinator crash leaves participants **in doubt**, holding locks indefinitely. XA amplifies this. Prefer a single sharded database with internal atomic commit, or idempotent retries plus compensating transactions.

## Fencing Tokens
**When to use**: any lock or lease guarding a resource in a distributed system.
**How**: the lock service issues a monotonically increasing token with each grant; the resource rejects any write bearing a token lower than the highest it has seen.
**Trade-offs**: requires the resource to participate. Without it, a paused (GC, VM steal time) leaseholder resumes as a zombie and corrupts data — locks alone do not protect you.

## Change Data Capture + Log Compaction
**When to use**: keeping search indexes, caches, and derived stores in sync with a system of record.
**How**: parse the database's replication log into an event stream; use the **outbox pattern** to decouple internal schema from the public stream; log compaction retains the latest value per key so a new consumer can rebuild full state from the log alone.
**Trade-offs**: derived systems become eventually consistent followers of one leader — asynchronous but ordered, which is far easier to reason about than dual writes.

## Event Sourcing + CQRS
**When to use**: the audit trail or the sequence of changes is itself valuable.
**How**: store immutable domain events as the system of record; build read-optimized views by folding the event log.
**Trade-offs**: state is the integral of the changelog and the changelog is the derivative of state. Deleting data requires crypto-shredding; views must be rebuildable.

## Windowed Stream Aggregation
**When to use**: computing rates and aggregates over unbounded streams.
**How**: window by **event time**, never processing time. Correct device clocks using three timestamps (event time, device send time, server receive time). Choose tumbling / hopping / sliding / session windows by the question asked. Handle stragglers by dropping with a metric, or publishing a correction.
**Trade-offs**: you can never be certain a window is complete — you trade waiting (timeliness) against completeness.

## Exactly-Once (Effectively-Once) Processing
**When to use**: stream processing whose output must survive faults without duplication.
**How**: combine idempotent operations, an end-to-end client-generated request ID enforced by a uniqueness constraint, and atomic commit of output + state + offset (checkpointing or microbatching).
**Trade-offs**: "exactly-once delivery" is impossible; exactly-once *effect* is achievable. Idempotence usually depends on fencing to exclude stale writers.

## MapReduce and Dataflow Engines
**When to use**: bounded, large inputs where reruns must be safe.
**How**: mapper → shuffle (hash-partitioned sort) → reducer; sort-merge join with secondary sort to bring the dimension row first. Dataflow engines (Spark, Flink) keep the DAG in memory and avoid materializing every intermediate stage.
**Trade-offs**: immutable input gives **human fault tolerance** — fix the code, rerun, and bad output is fully repaired. This is the single biggest operational advantage of batch processing.

## Unbundling the Database
**When to use**: composing storage, indexes, and materialized views out of separate systems.
**How**: pick one system of record; derive everything else through event logs and CDC; shift the write path/read path boundary to trade precomputation against query cost.
**Trade-offs**: flexibility and best-of-breed components, at the cost of owning the consistency story yourself. Favor coordination avoidance: preserve **integrity** with idempotence and end-to-end IDs, and let **timeliness** be eventual, repaired by compensating transactions.
