# Chapter 8: Transactions

## Core Idea
A transaction groups reads and writes into one logical unit that either commits or aborts, so the application can ignore partial failure and concurrency and simply retry. Transactions are not a law of nature — they exist to simplify the programming model — and the guarantees you actually get depend entirely on which isolation level you run at.

## Frameworks Introduced

- **ACID** (coined 1983 by Härder and Reuter):
  - **Atomicity**: *not* about concurrency. If a fault occurs partway through a sequence of writes, the transaction aborts and all its writes are discarded. "Abortability" would have been the better word; the defining feature is that an aborted transaction changed *nothing*, so retry is safe.
  - **Consistency**: application-specific invariants ("credits and debits balance"), which may be violated mid-transaction but must hold at commit. The database enforces only what you declare as constraints (foreign-key, uniqueness, check; complex ones via triggers or materialized views). The **C in ACID depends on how the application uses the database and is not a property of the database alone**.
  - **Isolation**: concurrent transactions don't step on each other. Formalized as **serializability**; most databases use weaker levels.
  - **Durability**: committed data isn't forgotten. Single-node: `fsync` + write-ahead log + checksums. Replicated: copied to N nodes. Perfect durability does not exist.
  - "ACID" has become mostly a marketing term. **BASE** (basically available, soft state, eventual consistency) is vaguer still — its only sensible definition is "not ACID".

- **Read committed** — two guarantees: (1) no dirty reads (you see only committed data); (2) no dirty writes (you overwrite only committed data). The default in Oracle, PostgreSQL, SQL Server, and many others.
  - How: dirty writes are prevented with **row-level locks** held until commit/abort. Dirty reads are usually prevented by remembering both the old committed value and the new uncommitted value, and serving readers the old one. Read locks *do* work (IBM Db2, SQL Server with `read_committed_snapshot=off`) but a long-running writer then blocks all readers — bad for operability.
  - Failure mode: does not prevent read skew, phantoms, lost updates, or write skew.

- **Snapshot isolation** (a.k.a. "repeatable read" in PostgreSQL, "serializable" in Oracle): each transaction reads from a consistent snapshot of all data committed at the start of that transaction.
  - When to use: backups, long-running analytical queries, periodic integrity checks — anything that scans large parts of the database and must not see it at different points in time.
  - How (MVCC): every transaction gets a unique, always-increasing `txid`. Each row has `inserted_by` and `deleted_by` fields; an update is internally a delete plus an insert. Nothing is overwritten in place; versions of the same row form a linked list in the heap. GC removes versions no transaction can still see.
  - Key principle: **readers never block writers, and writers never block readers**. Writes still take locks; reads take none.
  - Alternative implementation: immutable/copy-on-write B-trees (CouchDB, Datomic, LMDB) — every write transaction creates a new B-tree root, which *is* a consistent snapshot; no txid filtering needed, but compaction/GC still required.

- **Two-phase locking (2PL)**, sometimes called strong strict 2PL (SS2PL) — the only widely used serializability algorithm for ~30 years. Used by MySQL/InnoDB and SQL Server serializable, and Db2 repeatable read.
  - How: a shared/exclusive (multi-reader single-writer) lock on each object. Read → shared lock; write → exclusive lock; read-then-write → upgrade. **Locks are held until the end of the transaction.** The "two phases" are the growing phase (acquiring) and the shrinking phase (releasing at the end); they must not overlap.
  - Writers block readers and readers block writers — the exact inverse of snapshot isolation's mantra.
  - Phantoms need **predicate locks**: a lock on all objects matching a search condition, including objects that don't yet exist. Too slow in practice, so databases use **index-range locking** (a.k.a. **next-key locking**), a safe over-approximation attached to an index entry or index range. Fallback if no suitable index exists: a shared lock on the whole table.
  - Failure mode: unstable latencies and terrible high percentiles under contention. A read of an entire table takes a shared lock on the table, blocking all writers for its duration. Deadlocks are far more frequent than under read committed; each deadlock abort wastes all the work done.

- **Serializable snapshot isolation (SSI)** — first described in 2008; full serializability at a small penalty over snapshot isolation. Used in PostgreSQL serializable, SQL Server Hekaton, HyPer, CockroachDB, FoundationDB, BadgerDB.
  - How: snapshot isolation plus detection of **decisions based on an outdated premise**. Two detection cases:
    1. **Stale MVCC read**: track when a transaction ignored another transaction's write due to visibility rules; at commit time, if any ignored write has since committed, abort.
    2. **Writes affecting prior reads**: record reads against index entries (or the table if no index). When a transaction writes, it looks for recent readers of that data and acts as a **tripwire** — it notifies rather than blocks. At commit, if a conflicting write already committed, abort.
  - Why wait until commit to abort? A read-only transaction never needs aborting, the database doesn't yet know whether a write will follow, and the other transaction may still abort. Avoiding unnecessary aborts preserves long-running consistent-snapshot reads.
  - Why it works / failure mode: **optimistic** rather than pessimistic — no blocking, so latency is predictable and read-only queries need no locks. Performs badly under high contention (aborts multiply, and retries add load when already near max throughput). Requires read/write transactions to be fairly short; long-running read-only transactions are fine. Unlike serial execution, not limited to one CPU core — FoundationDB distributes conflict detection across machines.

- **Two-phase commit (2PC)** — atomic commit across multiple nodes, via a **coordinator** (transaction manager) and **participants**.
  - Steps: (1) application requests a globally unique transaction ID from the coordinator; (2) it begins a single-node transaction on each participant, tagged with that ID; (3) at commit time, the coordinator sends **prepare** to all participants; (4) each participant makes sure it can *definitely* commit under all circumstances — writes all transaction data to disk, checks conflicts and constraints — and by replying yes **surrenders the right to abort without actually committing**; (5) the coordinator writes its decision to its own transaction log on disk — this is the **commit point**; (6) it sends commit or abort to all participants, retrying forever until each succeeds.
  - Two points of no return: a participant's yes vote, and the coordinator's logged decision. (Single-node commit lumps both into writing one commit record.)
  - Why it works / failure mode: 2PC is a **blocking** protocol. If the coordinator crashes after participants voted yes, those participants are **in doubt** (uncertain) — they cannot unilaterally commit or abort and must wait for the coordinator to recover. If the coordinator's log is lost, only an administrator can resolve it manually. **3PC** is nonblocking in theory but assumes bounded network delay and bounded response times, so it cannot guarantee atomicity in real systems (Ch 9). The practical fix is to replace the single-node coordinator with a fault-tolerant consensus protocol (Ch 10).

## Key Concepts
- **Dirty read**: one transaction sees another's uncommitted writes; allowing them also causes **cascading aborts**.
- **Dirty write**: a transaction overwrites a value another uncommitted transaction wrote.
- **Read skew / nonrepeatable read**: a client sees different parts of the database at different points in time.
- **Lost update**: two clients do a read-modify-write cycle concurrently; the later write *clobbers* the earlier one.
- **Write skew**: two transactions read the same objects and then update *different* objects, invalidating a shared precondition. A generalization of lost update. **Only serializable isolation prevents it automatically.**
- **Phantom**: a write in one transaction changes the result of a search query in another transaction.
- **MVCC**: keeping several committed versions of a row side by side so different transactions see different points in time.
- **Conditional write / compare-and-set / optimistic locking**: update only if the value (or version number) hasn't changed since you read it.
- **Materializing conflicts**: creating rows (e.g., a room × time-slot table) purely as lock targets, turning a phantom into a concrete lock conflict. A last resort.
- **Stored procedure**: the whole transaction submitted ahead of time, avoiding per-statement network round trips — the precondition for serial execution.
- **In doubt / uncertain**: a 2PC participant that voted yes and hasn't heard the coordinator's decision.
- **Heuristic decision**: an XA escape hatch letting a participant unilaterally resolve an in-doubt transaction — a euphemism for *probably breaking atomicity*.

## Mental Models
- Think of atomicity as **abortability**: its value is that a failed transaction leaves *nothing* behind, which is what makes retry safe.
- Use the mantra **"readers never block writers, writers never block readers"** to tell snapshot isolation apart from 2PL. If your workload has long read-only queries alongside writes, you want the snapshot-isolation family; 2PL will make those queries freeze the table.
- Think of write skew as a transaction acting on an **outdated premise**. Whenever your code does SELECT → decide → write, ask what happens if a concurrent transaction changes the SELECT's result. That question is exactly what SSI mechanizes.
- Prefer optimistic concurrency control (SSI) when there is spare capacity and low contention; prefer pessimistic (2PL, serial execution) under high contention, since optimistic schemes degrade by aborting.
- Use idempotence, not distributed transactions, for exactly-once processing. Recording a unique message ID inside the same database transaction as the side effects gives you the same guarantee with none of the 2PC operational pain.

## Anti-patterns
- **Read-modify-write cycles in application code** (especially ORM-generated) instead of atomic operations — a classic source of lost updates that testing rarely catches.
- **Not retrying aborted transactions**: ORMs let the exception bubble up and throw away user input; the point of rollback is safe retry. But don't retry permanent errors (constraint violations), do use exponential backoff and retry limits for contention/overload, and beware that a retry whose commit ack was lost executes twice and that non-database side effects (email) still happen.
- **Assuming "ACID database" means safe**: most popular relational databases default to weak isolation. These bugs have bankrupted a Bitcoin exchange, triggered financial audits, and corrupted customer data. Assume an attacker will fire a burst of concurrent requests to exploit them.
- **Trusting isolation-level names**: PostgreSQL "repeatable read" = snapshot isolation; MySQL "repeatable read" = weaker MVCC that does *not* detect lost updates; Db2 "repeatable read" = serializability; Oracle "serializable" = snapshot isolation. **Nobody really knows what repeatable read means.**
- **Relying on lost-update detection to catch write skew**: it doesn't fire in PostgreSQL repeatable read, MySQL/InnoDB repeatable read, Oracle serializable, or SQL Server snapshot isolation.
- **`SELECT FOR UPDATE` to prevent a phantom**: when the query returns zero rows, there is nothing to lock.
- **XA transactions across heterogeneous systems**: the coordinator is usually a library inside the application process, so its local-disk log becomes critical durable state and the application code becomes a single point of failure. XA is a lowest-common-denominator API — no cross-system deadlock detection, no SSI. Orphaned in-doubt transactions hold locks across reboots until an administrator intervenes.
- **Long-running read/write transactions under SSI**: very likely to conflict and abort.

## Code Examples

Explicit locking to prevent lost updates (Example 8-1) — `FOR UPDATE` tells the database to lock all rows returned:

```sql
BEGIN TRANSACTION;

SELECT * FROM figures
  WHERE name = 'robot' AND game_id = 222
  FOR UPDATE;

-- Check whether move is valid, then update the position
-- of the piece that was returned by the previous SELECT.
UPDATE figures SET position = 'c4' WHERE id = 1234;

COMMIT;
```
- **What it demonstrates**: making a read-modify-write cycle safe when the logic can't be expressed as a single atomic database operation. Risks deadlock; the database detects it and aborts one transaction for the application to retry.

Concurrency-safe atomic update — always prefer this over a read-modify-write cycle:

```sql
UPDATE counters SET value = value + 1 WHERE key = 'foo';
```

Conditional write (optimistic locking) — safe only depending on the implementation:

```sql
-- This may or may not be safe, depending on the database implementation
UPDATE wiki_pages SET content = 'new content'
  WHERE id = 1234 AND content = 'old content';
```
- **What it demonstrates**: CAS in SQL. You must check whether the update took effect and retry if not. Prefer a version-number column over comparing full content. Note that MVCC implementations usually make an exception to the visibility rules so that concurrent writes *are* visible to the `WHERE` clause of `UPDATE`/`DELETE`.

Meeting-room booking that is **not** safe under snapshot isolation (Example 8-2):

```sql
BEGIN TRANSACTION;

-- Check for any existing bookings that overlap with the period of noon-1pm
SELECT COUNT(*) FROM bookings
  WHERE room_id = 123 AND
    end_time > '2025-01-01 12:00' AND start_time < '2025-01-01 13:00';

-- If the previous query returned zero:
INSERT INTO bookings
  (room_id, start_time, end_time, user_id)
  VALUES (123, '2025-01-01 12:00', '2025-01-01 13:00', 666);

COMMIT;
```
- **What it demonstrates**: a phantom. `SELECT FOR UPDATE` can't help because there are no rows to lock; you need serializable isolation (or materialized conflicts).

## Reference Tables

Table 8-1 — anomalies possible at each isolation level:

| Isolation level | Dirty reads | Read skew | Phantom reads | Lost updates | Write skew |
|---|---|---|---|---|---|
| Read uncommitted | ✗ Possible | ✗ Possible | ✗ Possible | ✗ Possible | ✗ Possible |
| Read committed | ✓ Prevented | ✗ Possible | ✗ Possible | ✗ Possible | ✗ Possible |
| Snapshot isolation | ✓ Prevented | ✓ Prevented | ✓ Prevented | ? Depends | ✗ Possible |
| Serializable | ✓ Prevented | ✓ Prevented | ✓ Prevented | ✓ Prevented | ✓ Prevented |

(Dirty writes are omitted — almost all transaction implementations prevent them.)

| Serializability technique | Mechanism | Best when | Limits |
|---|---|---|---|
| Actual serial execution | One thread, stored procedures, in-memory data (VoltDB/H-Store, Redis, Datomic) | Transactions are small and fast; active dataset fits in memory | Throughput capped at one CPU core per shard; one slow transaction stalls everything; VoltDB reports ~1,000 cross-shard writes/sec |
| Two-phase locking | Shared/exclusive locks held to end of transaction + index-range locks | Contention is low and predictable latency doesn't matter | Readers block writers and vice versa; unstable tail latency; frequent deadlocks |
| Serializable snapshot isolation | Optimistic; snapshot reads + conflict detection at commit | Spare capacity, low contention, read-heavy workloads | Abort rate dominates performance; needs short read/write transactions |

## Worked Example
**Write skew — the on-call doctors (Figure 8-8).** The hospital requires at least one doctor on call per shift. Aaliyah and Bryce are the two on call for shift 1234; both feel unwell and click "go off call" at the same time.

Under snapshot isolation, each transaction runs `SELECT count(*) FROM doctors WHERE on_call = true AND shift_id = 1234`. Both see **2**, both conclude it's safe, Aaliyah updates her own record, Bryce updates his, both commit. Now zero doctors are on call — the invariant is violated. Run serially, the second doctor would have been blocked.

Why the usual remedies fail: atomic single-object operations don't apply (two different objects are updated); automatic lost-update detection doesn't fire (it's not the same object); and a "at least one doctor on call" constraint spans multiple rows, which most databases can't express. The second-best fix is explicit locking of the rows the decision depends on:

```sql
BEGIN TRANSACTION;

SELECT * FROM doctors
  WHERE on_call = true
  AND shift_id = 1234 FOR UPDATE;

UPDATE doctors
  SET on_call = false
  WHERE name = 'Aaliyah'
  AND shift_id = 1234;

COMMIT;
```

**How SSI catches it instead (Figure 8-11).** Both transactions 42 and 43 read the index entry for `shift_id = 1234`, and the database records that they read it. When each writes, it checks the index for recent readers of the affected data — a tripwire, not a block — and notifies the other that its read may be stale. Transaction 42 commits first and succeeds, because 43's write hasn't taken effect yet. When 43 tries to commit, 42's conflicting write has already committed, so 43 must abort and retry.

**Exactly-once without distributed transactions.** Give every message a unique ID and keep a table of processed IDs. Begin a transaction; if the ID is present, ack and drop. Otherwise insert the ID, do the processing writes in the same transaction, commit, ack the broker, then delete the ID separately. Crash before commit → aborted, broker redelivers. Crash after commit but before ack → redelivery sees the ID and drops. Crash after ack but before delete → a stale ID wastes a little space. Concurrent retry → the uniqueness constraint blocks the duplicate. Processing becomes **idempotent** using only single-database transactions.

## Key Takeaways
1. Only serializable isolation prevents all the race conditions. Everything weaker leaves specific anomalies for you to handle manually — and you must know which.
2. Check what your database's isolation level names actually mean; the SQL standard's definitions are flawed and vendors disagree.
3. Prefer atomic database operations (`value = value + 1`, MongoDB in-place document updates, Redis structure ops) over read-modify-write in application code.
4. When you can't, use `SELECT ... FOR UPDATE`, a conditional write with a version number, or automatic lost-update detection — but remember none of these catch write skew.
5. Retry aborted transactions deliberately: transient errors only, with backoff and limits, guarding against duplicate commits and non-database side effects.
6. SSI is the modern default answer: full serializability, non-blocking, predictable latency, and scalable beyond one core. Keep read/write transactions short.
7. Database-internal distributed transactions (CockroachDB, TiDB, Spanner, FoundationDB, YugabyteDB, Kafka) work well because they replicate the coordinator via consensus, let coordinator and shards talk directly, replicate participants, and couple atomic commit with distributed concurrency control. Heterogeneous XA transactions do none of these — avoid them.
8. Transactions are not fundamentally unscalable. That belief came from the NoSQL era and "NewSQL" systems disproved it by combining sharding with consensus.

## Connects To
- **Ch 6 (Replication)**: locks and conditional writes assume a single up-to-date copy, so they don't apply to multi-leader or leaderless replication — which instead produce conflicting siblings resolved by application code or CRDTs. LWW conflict resolution is inherently prone to lost updates.
- **Ch 7 (Sharding)**: a transaction touching several shards or a global secondary index becomes a distributed transaction. VoltDB scales by making each shard a single-threaded transaction processor — but only if transactions stay within one shard.
- **Ch 9 (Trouble with Distributed Systems)**: unbounded network delay and process pauses are why 3PC cannot deliver nonblocking atomic commit in practice.
- **Ch 10 (Consistency and Consensus)**: consensus replaces the fragile single-node 2PC coordinator; "consistency" in the CAP theorem means linearizability, a fifth distinct meaning of the word. VoltDB's deterministic stored procedures are **state machine replication**.
- **Ch 12**: stream processors such as Kafka Streams achieve exactly-once semantics with the same idempotence approach.
- **Härder & Reuter (1983)**, "Principles of Transaction-Oriented Database Recovery" — origin of the ACID acronym; **System R (1975)** — origin of the isolation-level definitions still in the SQL standard; **Fekete et al. (2005)**, "Making Snapshot Isolation Serializable" — the theory PostgreSQL uses to reduce unnecessary SSI aborts.
