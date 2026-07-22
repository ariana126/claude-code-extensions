# Chapter 6: Replication

## Core Idea
Almost every distributed database uses one of three replication families — single-leader, multi-leader, or leaderless. Single-leader is simple and can be strongly consistent; multi-leader and leaderless are more resilient to faults, network interruptions, and latency spikes, but buy that resilience with weaker consistency and mandatory conflict resolution.

## Frameworks Introduced

- **Single-leader (leader-based / primary-backup / active-passive) replication**: one replica is the **leader** (primary/source); all writes go to it; it ships a **replication log** (change stream) to **followers** (read replicas/secondaries/hot standbys), which apply writes in the same order. Reads may go to any replica.
  - When to use: you need strong consistency, uniqueness constraints, or serializable transactions; the default choice for PostgreSQL, MySQL, Oracle Data Guard, SQL Server Always On, MongoDB, DynamoDB, Kafka, and consensus systems (Raft in CockroachDB, TiDB, etcd).
  - Sharded systems have one leader *per shard*; different shards may lead on different nodes.
  - Avoid the term "master–slave" — same meaning, widely considered offensive.

- **Synchronous vs. asynchronous vs. semisynchronous replication**:
  - Synchronous: leader waits for the follower's confirmation before reporting success and before making the write visible. Guarantees an up-to-date copy — but a single unresponsive follower blocks *all* writes.
  - Therefore: **never make all followers synchronous**. In practice, **semisynchronous** — exactly one follower synchronous, the rest async; if the sync follower stalls, an async one is promoted to synchronous. This guarantees an up-to-date copy on at least two nodes.
  - Majority quorum variant: a majority (e.g. 3 of 5 including the leader) synchronous, the rest async — used with consensus-based leader election.
  - Fully async: writes acknowledged to the client can be lost if the leader dies unrecoverably; still widely used with many or geo-distributed followers.

- **Setting up a new follower (no downtime)**:
  1. Take a consistent snapshot of the leader without locking the database (the same feature backups need; sometimes needs a tool like Percona XtraBackup).
  2. Copy the snapshot to the new node.
  3. The follower requests all changes since the snapshot's exact **replication log position** — PostgreSQL's *log sequence number*; MySQL's *binlog coordinates* or *global transaction identifiers (GTIDs)*.
  4. When the backlog is drained the follower has **caught up** and streams live changes.
  - Steps 1–2 can be served from archived logs+snapshots in object storage (WAL-G for PostgreSQL/MySQL/SQL Server; Litestream for SQLite).

- **Failover** (leader failure): (1) **detect** — no foolproof method, so use a timeout (say 30 s of no response); (2) **choose a new leader** — by election among remaining replicas or by a **controller node**; pick the replica with the most up-to-date changes (highest log sequence number, or the semisync follower the leader waited on); (3) **reconfigure** clients to write to the new leader and force the old leader to step down.
  - Failure modes: unreplicated writes on the old leader are usually **discarded** (writes you believed committed weren't durable); **split brain** where two nodes both believe they lead (guard with **fencing**; naive kill mechanisms can shut down *both* nodes); timeout tuning — too long means slow recovery, too short means spurious failovers that worsen an already-struggling system.

- **Quorum reads and writes (leaderless / Dynamo-style)**: with `n` replicas, a write needs `w` acknowledgements and a read queries `r` nodes. If **`w + r > n`**, the read and write sets must overlap in at least one node, so a read sees the latest write.
  - Typical: `n` odd (3 or 5), `w = r = (n+1)/2`. `n=3, w=2, r=2` tolerates one node down; `n=5, w=3, r=3` tolerates two.
  - Read-heavy tuning: `w = n, r = 1` makes reads fast but any one node failure blocks all writes. `w + r ≤ n` gives lower latency and higher availability at higher staleness probability.
  - Catch-up mechanisms: **read repair** (client detects a stale response among parallel reads and writes the newer value back — good for frequently read values); **hinted handoff** (a substitute replica stores *hints* for an unavailable replica and delivers them on recovery — covers values never read); **anti-entropy** (background process copies differences, in no particular order, possibly with long delay).
  - Why quorums are not absolute guarantees — the edge cases the authors list: a node restored from an old-value replica can drop the count below `w`; rebalancing can leave nodes disagreeing about which `n` hold a key; a read concurrent with a write may or may not see it (and a later read may see the older value); a write that failed overall (`< w` successes) is **not rolled back** on the replicas where it succeeded; real-time-clock timestamps let a fast-clock node silently drop writes; two concurrent writes conflict.

- **Happens-before and version vectors**: operation A **happens before** B if B knows about, depends on, or builds upon A. Two operations are **concurrent** iff neither happens before the other — physical time is irrelevant.
  - Single-replica algorithm: server keeps a version number per key, incremented on each write. Reads return **all siblings** plus the latest version number. A client must read before writing, must include the version number from the prior read, and must merge all values it received. On write, the server overwrites everything at or below that version number and keeps everything above it as a sibling.
  - Multi-replica: one version number **per replica per key**; the collection is a **version vector** (the **dotted version vector** variant is used in Riak 2.0, which encodes it as a string called *causal context*). Version vectors make it safe to read from one replica and write back to another — you may create siblings, but you lose no data if siblings are merged correctly.
  - A **version vector** is not quite a **vector clock**; for comparing replica states, version vectors are the correct structure.

## Key Concepts
- **Replication lag**: delay between a write on the leader and its appearance on a follower — usually sub-second, but can reach minutes under load, network trouble, or follower recovery.
- **Eventual consistency**: stop writing and wait, and followers converge. "Eventually" is deliberately vague — there is no bound on how far a replica may fall behind.
- **Read-after-write (read-your-writes) consistency**: a user always sees their *own* submitted updates; says nothing about other users' updates.
- **Monotonic reads**: a user never sees time move backward — no reading older data after having read newer data.
- **Consistent prefix reads**: writes that happened in a certain order are seen by everyone in that order (violated across independently replicating shards — the Mr. Poons / Mrs. Cake answer-before-question anomaly).
- **Statement-based replication**: ship the SQL statements. Breaks on `NOW()`/`RAND()`, autoincrement columns, `UPDATE ... WHERE`, triggers/stored procedures/UDFs. Also called **state machine replication** when made deterministic (VoltDB requires deterministic transactions).
- **WAL shipping**: ship the physical write-ahead log (PostgreSQL, Oracle). Describes which bytes changed in which blocks, so it couples replication to the storage format — usually forcing downtime for version upgrades.
- **Logical (row-based) log replication**: a storage-engine-independent per-row log (MySQL's **binlog**; PostgreSQL decodes the physical WAL into row events). Backward-compatible across versions → minimal-downtime upgrades; also parseable by external systems → **change data capture**.
- **Split brain**: two nodes both believe they are the leader; if both accept writes without conflict resolution, data is lost or corrupted.
- **Sync engine**: a library that captures local edits, sends them when online, merges incoming edits, and updates the UI. **Offline-first** apps keep working offline; **local-first** software also keeps working if the vendor shuts down its services (Git is local-first). Game equivalent: **netcode**.
- **Strong eventual consistency**: eventual consistency plus a **convergence** guarantee — all replicas that processed the same set of writes hold the same state regardless of arrival order.
- **CRDTs** (conflict-free replicated datatypes) and **OT** (operational transformation): the two automatic merge families.
- **Sloppy quorum** (Riak/Dynamo; Cassandra/ScyllaDB *consistency level ANY*): during a large network interruption, any reachable replica accepts the write even if it isn't one of the key's usual `n`. No guarantee subsequent reads see it.
- **Request hedging**: send to all replicas and use the fastest responses — significantly reduces tail latency and absorbs **gray failures** (degraded-but-not-dead nodes).
- **Region vs. availability zone**: a region is one geographic location containing multiple zones (separate datacenters with their own power/cooling). Multi-zone survives zonal outages; only multi-region survives regional outages, at the cost of latency, throughput, and networking bills.

## Mental Models
- **Replication is not a backup.** Replicas propagate writes fast — including your accidental `DELETE`. Backups store old snapshots so you can go back in time. Use both; archived replication logs often *are* the backup.
- **Think of a sync engine as multi-leader replication taken to the extreme**: each device is a "region" and the network between them is extremely unreliable — offline is just a very large network delay, so the app needs no separate offline mode.
- **Use conflict avoidance before conflict resolution.** Route all writes for a record to one designated leader (e.g. per-user home region) and the system is effectively single-leader for that record — but note that avoidance breaks down the moment you allow the designated leader to change.
- **A leaderless system's resilience comes from not distinguishing the normal case from the failure case.** There is no failover decision to get wrong; a slow replica just loses the race.
- **If the answer to "what if replication lag grows to hours?" is a bad user experience, don't paper over it in application code.** Pick a database that gives you the guarantee (linearizability + ACID; the NewSQL trend) — application-level workarounds are complex and easy to get wrong.

## Reference Tables

### The three replication approaches
| | Single-leader | Multi-leader | Leaderless |
|---|---|---|---|
| Who accepts writes | One leader per shard | Any leader | Any replica (`w` of `n`) |
| Write ordering | Leader defines it | None global | None |
| Conflicts | Impossible | Must be resolved | Must be resolved |
| Consistency ceiling | Strong (serializable, uniqueness constraints) | Weak — can't guarantee unique usernames or non-negative balances | Weak; `w+r>n` gives probable freshness |
| Failover | Required, risky | Not needed | Not needed |
| Network-interruption tolerance | Poor (writes need the leader) | Best (one local leader) | Good (quorum of reachable nodes) |
| Examples | PostgreSQL, MySQL, Kafka, Raft systems | MySQL/Oracle/SQL Server add-ons, YugabyteDB, sync engines, CouchDB | Riak, Cassandra, ScyllaDB (Dynamo-style) |

### Replication log implementations
| Method | Coupling | Cross-version leader/follower | Notes |
|---|---|---|---|
| Statement-based | None | Yes | Compact, but nondeterminism breaks it; MySQL <5.1, VoltDB |
| WAL shipping (physical) | Tight to storage engine | Usually no → upgrades need downtime | PostgreSQL, Oracle |
| Logical (row-based) | Decoupled | Yes → minimal-downtime upgrades | MySQL binlog, PostgreSQL logical decoding; enables CDC |

### Consistency guarantees under replication lag
| Guarantee | Anomaly it prevents | Implementation techniques |
|---|---|---|
| Read-after-write | "My own submission vanished" | Read user-owned data from the leader; read from leader for 1 minute after last update; exclude followers >1 min behind; client remembers its last write timestamp (logical or clock) and the replica waits to catch up |
| Monotonic reads | Time moving backward across refreshes | Pin each user to one replica, e.g. by hash of user ID (needs rerouting if that replica fails) |
| Consistent prefix reads | Seeing an answer before its question | Put causally related writes on the same shard; or track causality explicitly with version vectors |

### Conflict resolution strategies
| Strategy | Behavior | Cost |
|---|---|---|
| Conflict avoidance | Route all writes for a record to one leader | Breaks when the designated leader changes |
| **Last write wins (LWW)** | Greatest timestamp wins; ties broken by comparing values | Silently discards concurrent writes = data loss; clock-sync sensitive unless using a logical clock |
| Manual resolution | Store all **siblings**, return them all on read, app or user merges (CouchDB) | API changes to a set of values; user burden; naive merges misbehave; concurrent resolutions can themselves conflict (B/C vs C/B → B/C/C/B) |
| Automatic (CRDT / OT) | Converge deterministically while preserving intent | Can't enforce global invariants (e.g. "at most five items") |

## Worked Example
**Concurrent shopping-cart edits with version numbers (Figure 6-15).** Two clients edit one cart; the server tracks a version number per key and returns all siblings.

1. Client 1 adds `milk` — first write, server stores it as **v1** and echoes `[milk]`+v1.
2. Client 2 adds `eggs`, unaware of `milk`. Server assigns **v2**, stores `[eggs]` and `[milk]` as siblings, returns both plus v2.
3. Client 1 (still holding v1) writes `[milk, flour]` with version 1. The server sees v1 supersedes `[milk]` but is concurrent with `[eggs]`, so it assigns **v3** to `[milk, flour]`, overwrites `[milk]`, keeps `[eggs]`, returns both.
4. Client 2 (holding v2 and the values `[milk]`,`[eggs]`) merges them and adds `ham`, writing `[eggs, milk, ham]` with version 2. The server sees v2 overwrites `[eggs]` but is concurrent with `[milk, flour]`. Remaining: `[milk, flour]` @v3 and `[eggs, milk, ham]` @v4.
5. Client 1 (holding v3 with `[milk, flour]` and `[eggs]`) merges, adds `bacon`, writes `[milk, flour, eggs, bacon]` with version 3. This overwrites `[milk, flour]` but is concurrent with `[eggs, milk, ham]`, so both are kept.

Neither client is ever fully up to date, yet old versions get overwritten and **no writes are lost**. Contrast the **Amazon shopping-cart anomaly**: merging siblings by set union means an item deleted in one sibling but present in another **reappears** — device 1 removes `Book`, device 2 concurrently removes `DVD`, and after the union merge both are back. A CRDT that tracks the deletions instead yields `Cart = {Soap}`.

**The GitHub failover incident**: an out-of-date MySQL follower was promoted to leader. Its autoincrement counter lagged the old leader's, so it **reused primary keys** already assigned. Those keys were also used in a Redis store, so the reuse produced MySQL/Redis inconsistency and **disclosed private data to the wrong users**. Discarding unreplicated writes is especially dangerous when external systems are keyed off the same values.

**OT vs. CRDT merging `ice` → `nice!`**: one replica prepends `n` at index 0, another appends `!` at index 3. **OT** exchanges operations and *transforms* indexes — the `!` insertion is shifted from index 3 to 4 to account for the earlier insertion, avoiding `nic!e`. **CRDTs** instead give every character an immutable ID (`i`=1A, `c`=2A, …) and express the insertion as "new char 4B after existing char 3A" (`nil` for start-of-string), with concurrent same-position insertions ordered by ID — so replicas converge with no transformation at all.

## Key Takeaways
1. Never configure all followers synchronous; use semisynchronous so at least two nodes hold every acknowledged write without a single slow node halting writes.
2. Read scaling only works with asynchronous replication — and therefore forces you to decide which of read-after-write, monotonic reads, and consistent prefix reads your application actually needs.
3. During failover, always promote the most up-to-date follower; losing a fraction of a second of writes may be fine, promoting a replica days behind is catastrophic.
4. Prefer logical (row-based) replication over WAL shipping when you want zero-downtime version upgrades or change data capture.
5. Understand that LWW means "randomly pick one concurrent write and silently discard the rest" — acceptable only if you insert unique keys and never update.
6. Choose `n` odd and `w = r = (n+1)/2` as a default; treat `w + r > n` as a probability dial, not a guarantee. Quorums beyond 4-of-7 or 5-of-9 hurt tail latency.
7. Monitor replication lag. Leader-based systems expose it directly (leader position minus follower position); leaderless systems have no fixed write order, so hint counts are your best (and hard-to-interpret) proxy — but "eventual" must still be quantified for operability.
8. If you need uniqueness or non-negative-balance style invariants, use a single-leader system. Multi-leader fundamentally cannot enforce them.

## Anti-patterns
- **Treating replication as a backup**: an accidental delete replicates instantly; only a snapshot lets you go back in time.
- **Pretending asynchronous replication is synchronous**: a recipe for problems down the line; design for what happens when lag hits minutes or hours.
- **Statement-based replication with nondeterminism**: `NOW()`, `RAND()`, autoincrement, triggers, and UDFs diverge across replicas. MySQL now auto-falls back to row-based when it detects nondeterminism.
- **Aggressive automatic failover timeouts**: a load spike or network glitch triggers a needless failover that makes an already-struggling system worse. Many teams deliberately fail over manually.
- **Circular and star multi-leader topologies**: a single failed node interrupts replication between all others and usually needs manual reconfiguration; all-to-all is more fault-tolerant — but exposes message-reordering (an update arriving before its insert), which timestamps can't fix and version vectors can.
- **Multi-leader replication retrofitted onto a single-leader database**: subtle configuration pitfalls and bad interactions with autoincrement keys, triggers, and integrity constraints — often considered dangerous territory to avoid if possible.
- **Merging siblings by set union**: deleted items reappear (the Amazon cart anomaly); track deletions instead.
- **Sync engines for very large datasets**: they work by downloading everything the user may need — fine for a user's own files, wrong for an entire ecommerce catalog.

## Connects To
- **Ch 4 (Storage and Retrieval)**: WAL shipping reuses the B-tree write-ahead log verbatim as a replication stream.
- **Ch 7 (Sharding)**: this chapter assumes every replica holds the whole dataset; sharding removes that assumption. Rebalancing is also one of the ways quorums quietly break.
- **Ch 8 (Transactions)**: conflicts like double-booked meeting rooms; serializability as the alternative to conflict resolution.
- **Chs 9–10 (Distributed Systems Trouble, Consistency and Consensus)**: unreliable clocks (why LWW needs logical clocks), fencing against split brain, leader election as a consensus problem, linearizability.
- **Ch 12 (Stream Processing)**: change data capture from the logical replication log.
- **Dynamo paper (Amazon, 2007)**: origin of quorums, read repair, hinted handoff, sloppy quorums, and the shopping-cart merge anomaly. Note DynamoDB is architecturally unrelated — it uses single-leader replication over Multi-Paxos.
- **Lamport's happens-before relation**: the formal basis for defining concurrency without clocks.
