---
name: designing-data-intensive-applications-book
description: "Knowledge base from \"Designing Data-Intensive Applications, 2nd Edition\" by Martin Kleppmann and Chris Riccomini. Use when applying their frameworks for replication, sharding, transactions, isolation levels, consistency and consensus, storage engines, encoding and schema evolution, batch and stream processing, or distributed systems failure modes — while designing data systems, studying the book, or referencing its concepts."
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
---

<!-- argument-hint: [topic, framework name, or chapter number] -->

# Designing Data-Intensive Applications (2nd Edition)
**Authors**: Martin Kleppmann & Chris Riccomini | **Publisher**: O'Reilly, 2026 | **Chapters**: 14 | **Generated**: 2026-07-22

## How to Use This Skill

- **Without arguments** — load the core frameworks below for reference
- **With a topic** — ask about `replication`, `write skew`, `sharding`, `exactly-once`; I find and read the relevant chapter
- **With a chapter** — ask for `ch08`; I load that specific chapter file
- **Browse** — ask "what chapters do you have?" to see the full index

When you ask about a topic not covered in Core Frameworks below, I will read the
relevant chapter file before answering.

---

## Core Frameworks & Mental Models

**Everything is a trade-off.** The authors' central stance: there is no "best" database, only choices appropriate to a workload. Their job is to give you the vocabulary to state the trade-off precisely. When someone proposes a technology, ask what it gives up.

**Name the anomaly, not the guarantee.** Never say "we need strong consistency." Say which observable bug you must prevent: read-your-writes, monotonic reads, consistent prefix reads, or linearizability. The first three cost almost nothing; the last requires consensus and is unavailable during a network partition. Most production bugs need one of the cheap three.

**Faults vs. failures.** A *fault* is one component deviating from spec; a *failure* is the system stopping service. You cannot prevent faults, so build systems that tolerate them — and prove it by injecting faults deliberately.

**Response time is a distribution.** Measure percentiles, never averages. p99 is the experience of your most valuable users, since they have the most data. Queueing delay dominates the tail; a few slow requests block everything queued behind them (head-of-line blocking), and fan-out amplifies this so that most user requests touch at least one slow backend.

**Data outlives code.** Deployments swap code in minutes; rows keep their original encoding for years. So every schema needs **backward compatibility** (new code reads old data) and **forward compatibility** (old code reads new data). Rolling upgrades make forward compatibility mandatory, not optional.

**Log-structured vs. page-oriented storage.** LSM-trees (memtable → SSTables → compaction, with Bloom filters) win on write throughput and compression; B-trees (pages + write-ahead log) win on predictable read latency. Column-oriented storage is the analytics answer: store columns separately, sort consistently, compress with run-length and bitmap encoding.

**Single-leader replication is the default** because it gives one unambiguous answer to "in what order did the writes happen?" Its costs are a throughput ceiling and a dangerous failover. Leaderless quorums (`w + r > n`) trade that for availability, but the overlap guarantee is weaker than it looks — use version vectors, not last-write-wins, unless you're content to discard data at random.

**Shard by range if you need scans, by hash if you need spread.** Always create many more shards than nodes so rebalancing moves whole shards. Never `hash(key) % node_count`.

**Isolation levels are a ladder of anomalies.** Read committed stops dirty reads and writes. Snapshot isolation adds a consistent point-in-time view — but still permits **write skew** and **phantoms**, where two transactions read the same state, update *different* rows, and jointly break an invariant. Only serializable isolation stops that. Prefer SSI (optimistic, aborts under contention) over 2PL (blocking).

**Distributed systems: assume nothing.** Network delay is unbounded — multi-minute round trips happen. Timeouts can never distinguish a dead node from a slow network. Clocks drift and jump. Any process can pause for tens of seconds (GC, VM steal time), so a leaseholder can wake up as a **zombie** still believing it leads. **Fencing tokens** — monotonic tokens the resource itself checks — are the defense. Locks alone do not protect you.

**Consensus is for the few things that need it**: leader election, uniqueness constraints, atomic commit, lease issuance. Total order broadcast, linearizable compare-and-set, and consensus are all the same problem in different clothes. Use a proven implementation; never hand-roll.

**Prefer idempotence and compensation over coordination.** Distinguish **integrity** (data is uncorrupted and correctly derived — violations are perpetual, so this is non-negotiable) from **timeliness** (users see current state — violations are temporary, so this can be eventual). Integrity is achievable without coordination via idempotent operations and end-to-end request IDs enforced by a uniqueness constraint. Many business constraints are *loosely interpreted* anyway — airlines overbook, banks allow overdrafts — because an apology workflow is cheaper than global coordination.

**One system of record; everything else is derived.** Designate a single authoritative dataset. Indexes, caches, materialized views, and search indexes are derived data — reproducible functions of the log, rebuildable at will. Never dual-write from application code; use change data capture so derived stores are ordered followers of one leader. This is *unbundling the database*: assembling storage, indexing, and views out of separate systems wired by event logs.

**Batch processing buys human fault tolerance.** Because input is immutable, a bad deploy is repaired by fixing the code and rerunning. That property — not raw throughput — is the real argument for batch, and the reason to keep derived data reproducible.

**Window by event time, never processing time.** Using the processor's clock fabricates a traffic spike whenever a backlog drains. "Exactly-once delivery" is impossible; exactly-once *effect* is achievable through idempotence plus atomic commit of output, state, and offset.

**Data is a liability as much as an asset.** Treat personal data as a toxic asset whose breach risk is weighed against its value. Practice data minimization. And test your design by substituting the word "surveillance" for "data" — if the result reads sinister, believe it.

---

## Chapter Index

| # | Title | Key Frameworks |
|---|-------|----------------|
| [ch01](chapters/ch01-trade-offs-in-data-systems-architecture.md) | Trade-Offs in Data Systems Architecture | OLTP vs. OLAP, ETL/data warehouse, systems of record vs. derived data, cloud/disaggregation |
| [ch02](chapters/ch02-defining-nonfunctional-requirements.md) | Defining Nonfunctional Requirements | Percentiles & response-time distribution, fault vs. failure, load parameters, operability/simplicity/evolvability |
| [ch03](chapters/ch03-data-models-and-query-languages.md) | Data Models and Query Languages | Relational/document/graph selection, normalization, schema-on-read vs. -on-write, event sourcing & CQRS |
| [ch04](chapters/ch04-storage-and-retrieval.md) | Storage and Retrieval | LSM-tree, SSTable, Bloom filter, B-tree + WAL, write amplification, column storage |
| [ch05](chapters/ch05-encoding-and-evolution.md) | Encoding and Evolution | Backward/forward compatibility, Protobuf field tags, Avro writer's/reader's schema, schema registry, durable execution |
| [ch06](chapters/ch06-replication.md) | Replication | Single-leader replication, sync/async/semisync, failover, quorums (`w + r > n`), happens-before & version vectors |
| [ch07](chapters/ch07-sharding.md) | Sharding | Key-range vs. hash sharding, fixed shard count, consistent hashing, request routing, local vs. global secondary indexes |
| [ch08](chapters/ch08-transactions.md) | Transactions | ACID, read committed, snapshot isolation/MVCC, 2PL, serializable snapshot isolation (SSI), two-phase commit |
| [ch09](chapters/ch09-the-trouble-with-distributed-systems.md) | The Trouble with Distributed Systems | Timeout-based failure detection, monotonic vs. time-of-day clocks, confidence intervals, fencing tokens, system models, safety vs. liveness |
| [ch10](chapters/ch10-consistency-and-consensus.md) | Consistency and Consensus | Linearizability, equivalence of consensus formulations, total order broadcast, epochs & quorums, Lamport/hybrid logical clocks, CAP & PACELC |
| [ch11](chapters/ch11-batch-processing.md) | Batch Processing | Human fault tolerance, MapReduce, shuffle, sort-merge join, dataflow engines, job orchestration |
| [ch12](chapters/ch12-stream-processing.md) | Stream Processing | Log-based brokers, change data capture, log compaction, outbox pattern, event-time windowing, exactly-once, stream joins |
| [ch13](chapters/ch13-a-philosophy-of-streaming-systems.md) | A Philosophy of Streaming Systems | Unbundling the database, write path/read path, end-to-end argument, timeliness vs. integrity, coordination avoidance, Kappa architecture |
| [ch14](chapters/ch14-doing-the-right-thing.md) | Doing the Right Thing | Surveillance thought experiment, feedback loops, data minimization & purpose limitation, data as a toxic asset |

## Topic Index

- **ACID, isolation levels** → ch08
- **Avro, Protocol Buffers, JSON Schema** → ch05
- **B-trees, LSM-trees, SSTables, Bloom filters** → ch04
- **Batch processing, MapReduce, shuffle** → ch11
- **Byzantine faults** → ch09
- **CAP theorem, PACELC** → ch10
- **Change data capture (CDC), outbox pattern** → ch12, ch13
- **Clocks, drift, monotonic vs. time-of-day** → ch09, ch10
- **Column-oriented storage, data warehouse** → ch01, ch04
- **Consensus, total order broadcast, Raft/ZooKeeper** → ch10
- **Consistency guarantees (read-your-writes, monotonic reads)** → ch06, ch10
- **Consistent hashing, rebalancing** → ch07
- **Data models: relational, document, graph** → ch03
- **Derived data, systems of record, unbundling** → ch01, ch13
- **Encoding, serialization, schema evolution** → ch05
- **Ethics, privacy, surveillance, consent** → ch14
- **Event sourcing, CQRS** → ch03, ch12
- **Exactly-once semantics, idempotence** → ch05, ch12, ch13
- **Fencing tokens, leases, zombies** → ch09
- **Full-text search, inverted index, vector embeddings** → ch04
- **Leaderless replication, quorums, version vectors** → ch06
- **Linearizability, strict serializability** → ch10
- **Log compaction, log-based message brokers** → ch12
- **Maintainability, operability, evolvability** → ch02
- **MVCC, snapshot isolation** → ch08
- **Network partitions, unbounded delay, partial failure** → ch09
- **OLTP vs. OLAP, HTAP, data lake** → ch01
- **Percentiles, tail latency, SLOs** → ch02
- **Replication lag, failover, split brain** → ch06
- **Secondary indexes (local vs. global)** → ch04, ch07
- **Serializability, 2PL, SSI** → ch08
- **Sharding, partition keys, hot spots, skew** → ch07
- **Stream processing, windowing, stream joins** → ch12, ch13
- **Timeliness vs. integrity, compensating transactions** → ch13
- **Two-phase commit (2PC), XA** → ch08
- **Write skew, phantoms, lost updates** → ch08

## Supporting Files

- [glossary.md](glossary.md) — all key terms with definitions, mapped to chapters
- [patterns.md](patterns.md) — techniques and design patterns with when-to-use and trade-offs
- [cheatsheet.md](cheatsheet.md) — decision rules, selection tables, thresholds, and failure tells

---

## Scope & Limits

Covers the book's content only — the 2nd edition (2026), which differs substantially from
the 2017 first edition (rewritten cloud/architecture chapters, new material on sharding,
streaming philosophy, and vector/embedding indexes). For hands-on implementation in a
specific codebase or for a particular database's actual behavior, verify against that
system's documentation: the book describes families of designs, and individual products
deviate — especially in what they call their isolation levels.
