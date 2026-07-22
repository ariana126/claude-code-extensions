# Chapter 10: Consistency and Consensus

## Core Idea
Linearizability is the precise definition of "strong consistency" — behave as if there is one copy of the data and every operation is atomic — and the only fault-tolerant way to implement it is consensus. A surprisingly large family of problems (CAS, locks/leases, uniqueness constraints, shared logs, atomic commit) are all *equivalent* to consensus.

## Frameworks Introduced

- **Linearizability (a.k.a. atomic consistency, strong consistency, immediate consistency, external consistency)**: a *recency guarantee* on reads and writes of a single **register**. If one operation finishes before another starts, the later one must observe a state at least as new.
  - When to use: locking and leader election (a lease must not be granted twice), hard uniqueness constraints (username, filename, account balance ≥ 0, seat booking), and cross-channel timing dependencies (two communication paths between the same two components).
  - How to test it: record start/end timestamps of every request and response, mark the point at which each op appears to take effect, then check the markers can be joined in a sequential order that only moves forward in time and forms a valid register history. Computationally expensive but decidable (Knossos, Elle).
  - Why it works / failure mode: it costs latency *all the time*, not just during faults. Attiya and Welch prove response time of linearizable reads/writes is at least proportional to the *uncertainty of network delay*. No faster algorithm exists.

- **The equivalence of consensus formulations**: single-value consensus ≡ linearizable CAS ≡ shared log / total order broadcast ≡ atomic commitment. A solution to any one converts into a solution for all others.
  - How: CAS→consensus: init register to null, every proposer does CAS(null, myValue); decided value is whatever sticks. Log→consensus: propose by appending; the value in the *first* log entry is decided. Consensus→log: one consensus instance per log slot; append when a slot and all prior slots are decided; retry rejected proposals in a later slot.
  - Caveat: **fetch-and-add has consensus number 2**, not ∞ — the node that reads 0 wins but the others cannot learn who won if the winner crashes. CAS and shared logs have consensus number ∞.

- **Consensus safety/liveness properties** (single-value form):
  - **Uniform agreement**: no two nodes decide differently.
  - **Integrity**: a node cannot change its mind after deciding.
  - **Validity**: if value v is decided, v was proposed by some node.
  - **Termination**: every node that does not crash eventually decides. (Liveness; requires a majority of nodes functioning. The first three are safety and hold even if a majority fails.)

- **Epoch-numbered leadership (two rounds of voting)**: consensus algorithms don't guarantee one leader at a time; they guarantee a unique leader *per epoch* (ballot number in Paxos, view number in Viewstamped Replication, term number in Raft).
  - How: on suspecting leader death via timeout, a node starts an election with a strictly greater epoch number. Higher epoch wins conflicts. Before appending an entry the leader collects a quorum vote; nodes vote yes only if unaware of a higher epoch. The election quorum and the append quorum must overlap.
  - Not 2PC: in consensus *any* node can start an election and only a quorum must respond; in 2PC only the coordinator requests votes and *every* participant must say yes.

- **Logical clocks**: an algorithm that counts events rather than measuring time. Requirements: compact and unique timestamps, totally ordered, and ordering consistent with causality (happens-before).
  - **Lamport clock**: timestamp = (counter, node ID). Increment counter on every generated timestamp; on seeing a foreign timestamp with a greater counter, raise the local counter to match. Compare counter first, break ties by node ID lexicographically.
  - **Hybrid logical clock (HLC)**: counts microseconds like a physical clock but advances to match any greater foreign timestamp, and increments on every generation so it is monotonic across NTP jumps. Used by CockroachDB. Needs no special hardware, only roughly synchronized clocks.

## Key Concepts
- **Register**: a single object (one key, row, or document) on which linearizability is defined.
- **Linearizability vs serializability**: serializability is a multi-object *isolation* level allowing any serial order (stale reads permitted); linearizability is a single-object *recency* guarantee. Both together = **strict serializability** / **strong-1SR** (Spanner, FoundationDB offer it; CockroachDB deliberately does not).
- **CAP theorem**: on a network partition you must choose CP (consistent, unavailable) or AP (available, not linearizable). Better phrased: *either consistent or available when partitioned*. Of mostly historical interest.
- **PACELC**: during a Partition choose A or C; Else, choose L (low latency) or C.
- **Total order broadcast (atomic broadcast)**: protocol delivering the same messages to all nodes in the same order; the implementation substrate for shared logs.
- **State machine replication**: apply the same log of deterministic operations in the same order on every replica, and all replicas converge.
- **Timestamp oracle**: a single-node linearizable ID generator, persisted and replicated (TiDB/TiKV, after Google Percolator).
- **Vector clock**: per-node counter vector; unlike Lamport/HLC it can *detect* concurrency, at the cost of one integer per node.
- **FLP result**: no deterministic algorithm in the asynchronous model always terminates if a node may crash. Timeouts or randomness make consensus solvable in practice.
- **Ephemeral node**: ZooKeeper znode tied to a client session; disappears when heartbeats stop, releasing the lease.
- **Unclean leader election**: Kafka option letting a non-up-to-date replica become leader — availability over consensus safety.

## Mental Models
- Think of linearizability as "the system has one variable in a single-threaded program." Use it when a race between two clients must have exactly one winner.
- Think of a consensus algorithm as *single-leader replication done right*: automatic leader election, no lost committed writes, no split brain.
- Use logical clocks when you need causal ordering cheaply; use a linearizable ID generator (or Spanner-style clock uncertainty waiting) when you need ordering between operations that *never communicated*.
- When you see two communication channels between the same two components (file store + message queue; push notification + fetch), suspect a cross-channel race that only linearizability (or explicit coordination) closes.

## Anti-patterns
- **Assuming quorum reads/writes (w + r > n) give linearizability**: with variable network delay, one client can read the new value from a quorum while a later client reads the old value from a different quorum. Requires synchronous read repair *plus* read-before-write timestamp checks — and a linearizable CAS is still impossible without consensus.
- **Last-write-wins on time-of-day clocks (Cassandra, ScyllaDB)**: clock skew makes timestamp order inconsistent with actual event order, so it is nonlinearizable by construction.
- **Reading from a consensus node without a quorum check**: the node may have just been deposed; the read is stale. etcd sends linearizable reads through a quorum vote; ZooKeeper reads may be stale by default.
- **Building automatic failover without a proven consensus algorithm**: almost certainly unsafe.
- **Using a coordination service as a general database**: ZooKeeper/etcd hold small, slow-changing data in memory (leader-for-shard assignments changing on the order of minutes/hours), not thousands of writes per second.
- **Sharding a linearizable ID generator**: multiple shards handing out IDs independently destroys the linearizable order. Same for spreading it across regions.
- **Tuning consensus timeouts too tight**: the cluster spends more time electing leaders than doing work; too loose, and failure recovery takes forever.

## Reference Tables

| Replication method | Linearizable? | Why |
|---|---|---|
| Single-leader | Potentially | Only if all reads/writes go to the *real* leader; a delusional leader or async failover breaks it |
| Consensus algorithms (Raft, Zab, Multi-Paxos, VR) | Likely | Designed to prevent split brain; reads still need a quorum check |
| Multi-leader | No | Concurrent writes on multiple nodes, async replication, conflicts |
| Leaderless (Dynamo-style quorums) | Probably not | Race conditions despite w+r>n; LWW clocks make it worse |

| ID generator scheme | Unique | Ordered w/ causality | Linearizable | Size |
|---|---|---|---|---|
| Single-node autoincrement | yes | yes | yes | 64 bit |
| Sharded (odd/even, shard bits) | yes | no | no | compact |
| Preallocated ID blocks | yes | no | no | compact |
| Random UUID (v4) | yes | no | no | 128 bit |
| Wall-clock + uniquifier (UUIDv7, Snowflake, ULID, ObjectID) | yes | approximate | no | 128 bit |
| Lamport clock / HLC | yes | yes | no | small |
| Vector clock | yes | yes + detects concurrency | no | O(nodes) |
| Timestamp oracle / Spanner TrueTime | yes | yes | yes | 64 bit |

| Consensus number | Primitive |
|---|---|
| 2 | fetch-and-add / atomic increment |
| ∞ | compare-and-set, shared log / total order broadcast, atomic commitment |

## Worked Example
**Nonlinearizable ID generator leaks a private photo.** User A's social account is public. From their laptop they set the account to **private**; then from their phone they **upload a photo**. Account settings and photos live in two different databases (or shards), each stamping writes with a Lamport/hybrid logical clock.

Because the photos database never read from the accounts database, its local counter lags. The photo upload therefore receives a *lower* timestamp than the settings change, even though it happened later in real time. A viewer who is not a friend then reads A's profile using MVCC snapshot isolation with a read timestamp that falls *between* the two: greater than the photo upload, less than the permissions change. The snapshot shows the account as still public and the photo as present — the viewer sees the embarrassing photo.

Fixes considered and rejected: have the photos DB read account status first (easy to forget); have the client track the user's latest write timestamp (fails across laptop and phone). The correct fix is a **linearizable ID generator**, which guarantees the later-completed upload gets the greater ID. Implement it as a single node that (1) atomically fetch-and-adds a counter, (2) persists and replicates a record describing a *batch* of IDs before handing them out — so a crash skips IDs but never duplicates or reorders them. Or use Spanner's approach: read a clock *interval*, wait out the uncertainty before returning, and get linearizable IDs with zero communication.

## Key Takeaways
1. Linearizability is a recency guarantee on a single object; serializability is an isolation level over multiple objects. You can pick each independently.
2. Quorums do not give you linearizability. Assume Dynamo-style leaderless replication is nonlinearizable.
3. Locks, leases, uniqueness constraints, CAS, shared logs, and atomic commit are all the same problem — consensus. If you need any of them fault-tolerantly, use a proven implementation (etcd, ZooKeeper, Consul), never hand-roll.
4. Consensus requires a strict majority: 3 nodes to tolerate 1 failure, 5 to tolerate 2. Adding nodes does not increase throughput — it slows the algorithm.
5. Logical clocks (Lamport, HLC) give total order consistent with causality without special hardware, but not linearizability: a node can only order against timestamps it has *seen*.
6. The cost of linearizability is latency proportional to network-delay uncertainty, paid at all times — not only during partitions. Most systems that skip it do so for performance, not fault tolerance.
7. Outsource consensus to a small fixed cluster (3 or 5 nodes) rather than running it across thousands of application nodes.

## Connects To
- **Ch 6 (Replication)**: single-leader, multi-leader, and leaderless replication, and which can be made linearizable.
- **Ch 8 (Transactions)**: serializability, snapshot isolation/MVCC, write skew, two-phase commit and distributed transactions.
- **Ch 9 (Distributed System Trouble)**: unreliable clocks, process pauses, fencing tokens, the partially synchronous system model, safety vs liveness.
- **Ch 12 (Stream Processing)**: shared logs are the substrate for event sourcing and stream processing.
- **Ch 13**: approaches for avoiding linearizability without sacrificing correctness (coordination avoidance).
- **Papers**: Herlihy & Wing 1990 (linearizability), Lamport 1978 (Time, Clocks), FLP 1985, Chandra & Toueg 1996 (failure detectors), Ongaro & Ousterhout 2014 (Raft), Burrows 2006 (Chubby), Attiya & Welch 1994 (linearizability cost).
