# Chapter 13: A Philosophy of Streaming Systems

## Core Idea
No single tool serves all access patterns, so build applications as *dataflow*: designate a system of record, funnel writes through an ordered event log, and derive every other representation (indexes, caches, materialized views, ML models, UIs) asynchronously and deterministically from it — then get correctness end to end via request IDs and idempotence rather than distributed transactions.

## Frameworks Introduced

- **Unbundling the database**: Take the features a database bundles internally (secondary indexes, materialized views, replication logs, full-text indexes) and provide them as separate systems wired together by CDC and event logs. Unbundling unifies *writes*; the complementary approach, a **federated database** (polystore, e.g. PostgreSQL foreign data wrappers, Trino, Hoptimator, Xorq), unifies *reads*.
  - When to use: only when no single product satisfies all your requirements. If one technology does everything you need, use it.
  - How: (1) pick a system of record; (2) capture its changes via CDC or an event-sourcing log; (3) route the log to derived systems; (4) make consumers deterministic and idempotent; (5) rederive by replaying when code or schema changes.
  - Why it works: loose coupling. At the *system* level a slow or failed consumer just lags — the log buffers, the fault is contained, whereas distributed transactions escalate local faults into global failures. At the *human* level teams own components independently behind a log interface.
  - Failure mode: operational complexity and premature optimization. Goal is breadth (many workloads), not depth (beating a specialist on its own workload).

- **Write path / read path**: The write path is precomputed eagerly on ingest; the read path is lazy work done when someone asks. The derived dataset is where they meet.
  - When to use: whenever deciding between an index, a cache, a materialized view, or a full scan.
  - How: indexes, caches, and materialized views only *shift the boundary* — more write-path work buys less read-path work. Extremes: no index (zero write work, `grep`-like scan on read) vs. precomputing all query results (impossible: query space is infinite). Cache the common queries, serve the tail from the index.
  - Extension: push the boundary all the way to the device. Server-sent events / WebSockets extend the write path to the end user; on-device state is a cache of server state, and screen pixels are a materialized view of model objects that are a local replica of datacenter state.

- **End-to-end argument (Saltzer, Reed & Clark, 1984)**: "The function in question can completely and correctly be implemented only with the knowledge and help of the application standing at the endpoints of the communication system."
  - When to use: any correctness property — duplicate suppression, integrity checking, encryption.
  - How: generate a request ID (UUID, or a hash of the form fields) in the *client*, pass it through every hop, enforce a uniqueness constraint on it at the database.
  - Why it works: TCP dedups only within one connection; 2PC only between coordinator and participant; stream-processor exactly-once only within the framework. None stop a user re-submitting a timed-out POST. Low-level mechanisms remain useful as probability reducers, not as guarantees.

- **Timeliness vs. integrity**: Split the overloaded word "consistency" into two requirements.
  - Timeliness = users observe an up-to-date state (linearizability is a strong form; read-after-write a weaker one). Violations are temporary; wait and retry.
  - Integrity = absence of corruption; derivations must be correct. Violations are *perpetual* — they need explicit checking and repair.
  - Slogan: "violations of timeliness are allowed under eventual consistency, whereas violations of integrity result in perpetual inconsistency." In most applications integrity matters far more than timeliness.

- **Coordination-avoiding data systems**: Because dataflow preserves integrity without atomic commit or linearizability, and because many constraints can be loosely enforced, you can run multi-leader across regions with weak timeliness but strong integrity. Introduce synchronous coordination only where recovery is impossible; don't make the whole application pay.

## Key Concepts
- **System of record vs. derived data**: One authoritative source of new input; every other representation is a reproducible function of it.
- **Total order broadcast**: Deciding a total order of events; equivalent to consensus, and normally requires a single leader node.
- **Kappa architecture**: Run reprocessing of history and processing of live events in the same system (supersedes the lambda architecture, which had problems and fell out of use).
- **Compensating transaction**: A later corrective action (refund, apology, upgrade) that repairs a temporarily violated constraint.
- **Loosely interpreted constraint**: A business rule deliberately allowed to be violated (overbooked flights, oversold stock, overdrafts) because an apology workflow already exists.
- **Exactly-once / effectively-once semantics**: Arranging computation so the final effect equals a fault-free run, typically via idempotence plus fencing.
- **Auditing**: Checking data integrity, ideally end to end and continuously; the basis for "trust, but verify" and self-validating systems.
- **Federated database / polystore**: Unified read-only query interface over heterogeneous engines.
- **Provenance / causality tracking**: Logging *reads* as events so you can reconstruct what a user saw before deciding.
- **Reads are events too**: Serving a read is a stream-table join; a one-off read is a join that forgets, a subscription is a persistent join.

## Mental Models
- Think of the dataflow across an organization as **one huge database**: batch/stream/ETL jobs are its trigger and materialized-view maintenance machinery, derived systems are its index types, and `CREATE INDEX` is just reprocessing existing data into a new view.
- Use the **spreadsheet model** when designing derived state: change a cell, everything downstream recomputes. VisiCalc had this in 1979; data systems still mostly poll.
- Prefer **subscribing over querying** when a service needs another service's data: replacing an RPC for the exchange rate with a locally maintained stream-joined table is both faster and more failure-tolerant. "The fastest and most reliable network request is no network request at all."
- Treat **gradual migration as dual gauge railway track**: run old and new derived views side by side, shift a small fraction of users, roll back cheaply, then drop the old view. Reversibility is what lets you move fast.

## Code Examples

A non-idempotent transfer (Example 13-1) — the standard atomicity demo that is nevertheless *incorrect*, because a client that loses the connection after `COMMIT` may retry and transfer $22:

```sql
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance + 11.00 WHERE account_id = 1234;
UPDATE accounts SET balance = balance - 11.00 WHERE account_id = 4321;
COMMIT;
```

The end-to-end fix (Example 13-2) — a client-generated request ID plus a uniqueness constraint:

```sql
ALTER TABLE requests ADD UNIQUE (request_id);

BEGIN TRANSACTION;
INSERT INTO requests
  (request_id, from_account, to_account, amount)
  VALUES('0286FDB8-D7E1-423F-B40B-792B3608036C', 4321, 1234, 11.00);

UPDATE accounts SET balance = balance + 11.00 WHERE account_id = 1234;
UPDATE accounts SET balance = balance - 11.00 WHERE account_id = 4321;
COMMIT;
```

- **What it demonstrates**: A duplicate retry aborts on the uniqueness violation, which relational databases maintain correctly even at weak isolation levels (unlike an application-level check-then-insert, which is unsafe under nonserializable isolation). The `requests` table doubles as an event log — the balance updates are redundant and could be derived downstream.

## Reference Tables

| Dimension | Distributed transactions (2PC/XA) | Log-based derived data |
|---|---|---|
| Mechanism | Atomic commit protocol | Deterministic retry + idempotence |
| Reading your own writes | Yes, immediately | Not by default (asynchronous) |
| Fault behavior | Aborts if any participant fails; amplifies faults | Log buffers; fault contained locally |
| Cross-technology use | Needs a standard protocol; XA has poor fault tolerance and performance | Works across heterogeneous systems |
| Scope where it works well | Single system, small scope | Whole-organization integration |

| | Timeliness | Integrity |
|---|---|---|
| Meaning | Observing an up-to-date state | Absence of corruption / correct derivation |
| Violation duration | Temporary | Permanent until repaired |
| Fix | Wait and retry | Explicit checking and repair |
| Provided by | Linearizability, read-after-write | Atomicity, durability, idempotence, exactly-once |
| Required by loose constraints? | No | Yes |

## Worked Example
**Multishard payment without atomic commit** (Figure 13-2): transfer money, checking sufficient funds, while deducting a fee — with three accounts potentially in three different shards.

1. The client assigns a unique request ID and appends the transfer request to the log shard chosen by *source account ID*.
2. A stream processor consuming that shard maintains a local database of the source account state plus the IDs of requests already processed (entirely derived from the log). On an unseen request ID it checks whether the balance suffices.
3. If it does, it reserves the amount in local state and emits three events, all carrying the original request ID: an *outgoing payment* event to its own input shard (source account), an *incoming payment* event to the destination account shard, and an *incoming payment* event to the fees account shard.
4. The outgoing payment event eventually loops back to the source account processor, which recognizes the request ID as a reservation it made and executes the payment, updating local state. Duplicates are ignored by request ID.
5. Destination and fees shards are consumed by independent tasks that apply the payment and deduplicate by request ID.

Crash case: if the source processor dies mid-request, at-least-once delivery makes it reprocess the request; being deterministic it makes the same allow/deny decision and re-emits the same events with the same request ID, so downstream consumers discard the duplicates. Atomicity comes not from a transaction but from the fact that appending the *initial request event* is a single atomic write — once it is in the log, all downstream effects eventually happen. The user learns the outcome by subscribing to the source account shard and waiting for the outgoing-payment (or explicitly emitted "declined payment") event. Requirements: per-account events processed strictly in log order, at-least-once delivery, deterministic processors.

## Anti-patterns
- **Trusting a lower layer for an end-to-end property**: TCP retransmission does not prevent duplicate
  form submissions, and a serializable transaction does not prevent a user's retried request from
  paying twice. The end-to-end argument says the guarantee must be enforced where the semantics live
  — with a client-generated request ID and a uniqueness constraint.
- **Reaching for distributed transactions to preserve integrity**: 2PC couples availability across
  systems and leaves participants in doubt. Idempotence plus end-to-end request IDs achieves the same
  integrity without coordination.
- **Coordinating synchronously to enforce a loosely interpreted constraint**: airlines overbook, shops
  oversell, banks allow overdrafts — because an apology workflow is cheaper than global coordination.
  Find out whether the business rule is actually strict before paying for linearizability.
- **Confusing timeliness with integrity**: a timeliness violation is temporary and self-repairing; an
  integrity violation is perpetual until someone fixes it. Spending your coordination budget on
  timeliness leaves nothing for the guarantee that actually matters.
- **Assuming a global event order exists**: sharded logs, multiple regions, microservices, and offline
  clients all produce unordered events. Capture causality explicitly rather than assuming it.
- **Blindly trusting components not to corrupt data**: disks, networks, and your own software do
  corrupt data. Build self-validating and auditable systems that check integrity continuously rather
  than discovering the corruption years later.
- **Unbundling before you need it**: assembling storage, indexes, and views out of separate systems
  means you own the consistency story. A single database that already does the job is the better
  default.

## Key Takeaways
1. Funnel all input through one system that decides a total order; derive everything else by processing that order. Whether you use CDC or event sourcing matters less than committing to a single ordering.
2. Total order broadcast does not scale past one leader — sharded logs, multi-region deployments, microservices, and offline clients all leave events unordered. Capture causality explicitly (logical timestamps, referencing the event ID of the state the user saw) rather than assuming a global order.
3. Serializable transactions do not make your application correct. Add end-to-end measures — client-generated request IDs, uniqueness constraints, end-to-end checksums, end-to-end encryption.
4. Ask whether your constraint really needs timeliness. If an apology workflow exists (backorder, overbooking, overdraft fee), write optimistically and check afterward; validate synchronously only before actions you cannot undo.
5. Prefer asynchronous derivation over synchronous distributed transactions when data crosses a technology boundary written by different teams — an ordered log with idempotent consumers is the only abstraction that is practical there.
6. Design for auditability: immutable events plus deterministic derivation lets you rerun derivations, compare results, and reproduce the circumstances of a bug ("time-travel debugging"). Read your backups back; HDFS and S3 continuously scrub replicas rather than trusting disks.
7. Coordination reduces apologies for inconsistency but adds apologies for outages. Aim for the sweet spot, not zero.

## Connects To
- **Ch 12**: Builds directly on event streams, CDC, log-based brokers, consumer offsets, and exactly-once semantics.
- **Ch 11**: Batch processing supplies the reprocessing half of the kappa architecture; batch processors are "a distributed version of Unix."
- **Ch 10**: Uniqueness constraints require consensus; the shared-log username-claim algorithm *is* the consensus-from-a-shared-log construction.
- **Ch 8 / Ch 6**: Weak isolation levels and replication lag are exactly the guarantees this chapter reframes as timeliness vs. integrity.
- **End-to-End Arguments in System Design** (Saltzer, Reed, Clark, 1984); **"The Log"** (Kreps); **Coordination Avoidance in Database Systems** (Bailis et al.); **Certificate Transparency** and **Merkle trees** as lightweight, non-blockchain auditing tools.
