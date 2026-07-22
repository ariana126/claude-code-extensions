# Chapter 7: Sharding

## Core Idea
Sharding splits a dataset into subsets so that each record belongs to exactly one shard, letting you scale write throughput and data volume horizontally — but only if the scheme spreads load evenly and can be rebalanced, because skew turns 10 nodes into 1 busy node and 9 idle ones.

## Frameworks Introduced

- **Key-range sharding**: Assign each shard a contiguous range of partition keys, min to max, like volumes of a paper encyclopedia. Keys are stored sorted within the shard (B-tree or SSTables).
  - When to use: when you need efficient range scans over the partition key (e.g., time-series readings for a month), or want related records co-located.
  - How: boundaries adapt to the data, not to the alphabet — ranges are unevenly spaced by design. Set an initial set of boundaries on an empty database (**pre-splitting**, HBase/MongoDB), then grow by splitting a shard into two subranges when it exceeds a configured size (HBase default: **10 GB**) or when write throughput stays persistently above a threshold. Merge adjacent small shards after mass deletions. Manual boundaries: Vitess. Automatic: Bigtable, HBase, CockroachDB, RethinkDB, FoundationDB, MongoDB range mode; YugabyteDB does both.
  - Why it works / failure mode: number of shards adapts to data volume automatically. Failure mode: sequential keys (timestamps) send **all** writes to the newest shard. Splitting is expensive — it rewrites all data like an LSM compaction — and the shard that needs splitting is usually already hot, so splitting can push it over the edge.

- **Hash sharding (hash-range)**: Hash the partition key first, then assign each shard a contiguous range of *hash values* rather than key values.
  - When to use: when you don't care about key adjacency (tenant IDs, user IDs) and want uniform distribution despite skewed input keys.
  - How: use a non-cryptographic but process-stable hash (MongoDB: MD5; Cassandra/ScyllaDB: Murmur3). With a 16-bit hash (0–65,535), give shard 0 values 0–16,383, shard 1 values 16,384–32,767, etc. Split a shard when it gets too big — so shard count adapts to data volume. Cassandra/ScyllaDB variant: split the hash space into ranges with *random* boundaries, proportional to node count (**16 ranges per node** default in Cassandra, **256** in ScyllaDB); imbalances average out across many ranges. Used by YugabyteDB, DynamoDB, optional in MongoDB.
  - Why it works / failure mode: uniform hash output erases input skew, and per-node multiplicity smooths random boundary imbalance. Failure mode: range queries over the partition key are destroyed — matching keys scatter across all shards.

- **Fixed number of shards**: Create far more shards than nodes (e.g., 1,000 shards on 10 nodes = 100 each); key goes to `hash(key) % 1000`; track shard→node assignment separately.
  - When to use: when you can estimate final scale up front and want cheap rebalancing.
  - How: on node add/remove, move *entire shards*, never split them. Keys→shards mapping never changes; only shards→nodes. The transfer is not instant, so the old assignment serves reads and writes while data moves. Pick a shard count divisible by many factors so it splits evenly across various node counts. Assign more shards to more powerful nodes to weight load. Used by Citus, Riak, Elasticsearch, Couchbase.
  - Failure mode: you can never have more nodes than shards; getting the number wrong forces an expensive resharding that rewrites every shard and may require downtime. Shard size grows proportionally to dataset size, so a highly variable dataset ends with shards that are either too big (slow rebalance/recovery) or too small (per-shard overhead).

- **Consistent hashing**: A hash function mapping keys to a specified number of shards such that (1) keys per shard are roughly equal, and (2) when shard count changes, as few keys as possible move.
  - When to use: as the alternative to `mod N`, which moves most keys whenever N changes.
  - Variants: original Karger et al. (1997); **highest random weight** a.k.a. **rendezvous hashing**; **jump consistent hashing**. These assign the new node individual keys scattered across all other nodes, rather than splitting a few existing shards into subranges.
  - Note: "consistent" here has nothing to do with replica consistency or ACID consistency — it means a key's tendency to stay in the same shard.

- **Request routing** (three approaches):
  1. Client contacts any node (round-robin LB); the node serves it if it owns the shard, otherwise forwards and relays the reply.
  2. Client sends to a **routing tier** — a shard-aware load balancer that handles no requests itself.
  3. Client is sharding-aware and connects directly to the right node.
  - How: a coordination service (ZooKeeper, etcd) holds the authoritative shard→node map, using consensus for fault tolerance and split-brain protection; routing tiers and clients subscribe and get notified on ownership change. HBase and SolrCloud use ZooKeeper; Kubernetes uses etcd; MongoDB uses its own *config server* plus `mongos` daemons; Kafka, YugabyteDB, TiDB, ScyllaDB use built-in Raft. Riak instead uses a **gossip protocol** — weaker, split-brain is possible, tolerable only because leaderless databases make weak guarantees anyway. DNS is usually enough for finding node IPs, which change more slowly.

## Key Concepts
- **Shard / partition**: A subset of the data such that each record belongs to exactly one; called *partition* in Kafka, *range* in CockroachDB, *region* in HBase/TiDB, *vBucket* in Couchbase, *vnode* in Riak, *token-range* in Cassandra, *tablet* in Bigtable/YugabyteDB/ScyllaDB. In PostgreSQL, *partitioning* means splitting a table across files on one machine; *sharding* means across machines.
- **Partition key**: The field determining a record's shard; all records with the same partition key land on the same shard. In a key-value store it's the key or its first part; in a relational model, any column (not necessarily the primary key).
- **Skew**: Unfair sharding where some shards hold more data or serve more queries than others.
- **Hot shard / hot spot**: A shard with disproportionately high load. **Hot key**: a single key with high load (e.g., a celebrity).
- **Rebalancing**: Moving load between nodes so it stays even as nodes are added or removed.
- **Pre-splitting**: Configuring an initial set of shard boundaries on an empty database, requiring advance knowledge of the key distribution.
- **Local secondary index (document-partitioned index)**: Each shard indexes only its own records; writes touch one shard, reads must scatter-gather.
- **Global secondary index (term-partitioned index)**: The index is sharded by the *indexed term*, covering data from all shards; reads of a postings list hit one shard, writes touch many.
- **Postings list**: The list of record IDs stored under an index entry such as `color:red`.
- **Cell-based architecture**: Grouping services and storage for a set of tenants into a self-contained *cell* so a fault stays inside one cell (fault isolation).
- **Heat management / adaptive capacity**: Amazon's automated handling of hot shards.

## Mental Models
- Think of a shard as a small database of its own — that independence is exactly what allows scale-out, and exactly why cross-shard writes need distributed transactions and become the bottleneck.
- Use sharding only when a single machine genuinely can't hold the data or absorb the write throughput. Replication is useful at any scale; sharding is heavyweight and mostly relevant at large scale — and a single machine can do a lot nowadays. If reads are the problem, use read scaling (Ch 6), not sharding.
- Think of the partition key as the first part of a concatenated index: shard on the first column, sort by the rest. Then range queries *within* one partition key stay efficient even under hash sharding.
- Use sharding for multitenancy, not just for scale: it buys resource isolation, permission isolation, per-tenant backup/restore, GDPR/CCPA export-and-delete on one shard, data residency by region, and gradual per-tenant schema rollout.

## Anti-patterns
- **`hash(key) % N` where N is the node count**: adding a node moves most keys. With 3 nodes → 4, hash 3 moves to node 3, hash 6 to node 2, hash 9 to node 1. Cheap to compute, terrible to rebalance.
- **Timestamp as the leading key component under key-range sharding**: every current write targets the same shard while the rest sit idle. Prefix with sensor/entity ID instead — at the cost of one range query per sensor.
- **Using `Object.hashCode()` (Java) or `Object#hash` (Ruby) as the sharding hash**: the same key can hash differently in different processes.
- **Hand-rolling secondary indexes over a key-value store in application code**: race conditions and partial write failures silently desync the index from the data.
- **Scatter-gather reads on local secondary indexes as your main query path**: prone to tail latency amplification, and adding shards raises capacity but not query throughput, because every shard still processes every query.
- **Fully automatic rebalancing combined with automatic failure detection**: an overloaded, slow node is declared dead, its load is moved elsewhere, other nodes overload, and you get cascading failure. Keep a human in the loop, and pre-rebalance ahead of known events (Cyber Monday, World Cup ticket sales).

## Reference Tables

| Dimension | Key-range sharding | Hash sharding |
|---|---|---|
| Range queries on partition key | Efficient | Inefficient (keys scattered) |
| Hot-spot risk from sequential keys | High | Low |
| Number of shards | Adapts to data volume via splitting | Fixed in advance, or adapts if hash-range |
| Rebalance mechanism | Split range into subranges (expensive rewrite) | Move whole shards (cheap), or split hash ranges |
| Can isolate a single hot key on its own shard | Yes | Yes (hash-range) |
| Example systems | Bigtable, HBase, CockroachDB, FoundationDB, Vitess | DynamoDB, Cassandra, ScyllaDB, Riak, Citus, Couchbase |

| Dimension | Local (document-partitioned) index | Global (term-partitioned) index |
|---|---|---|
| Write path | One shard only | Possibly many index shards; may need a distributed transaction |
| Single-condition read | Query all shards, combine | One shard for the postings list |
| Fetching full records | From matching shards | Still from all shards holding those IDs |
| Multi-term AND | Local intersection | Terms on different shards; intersecting long postings lists over the network is slow |
| Freshness | In sync with data | May be stale (DynamoDB updates global indexes asynchronously) |
| Systems | MongoDB, Riak, Cassandra, Elasticsearch, SolrCloud, VoltDB | CockroachDB, TiDB, YugabyteDB, DynamoDB (both) |

## Worked Example
**Used-car listing site, sharded by listing ID** (IDs 0–499 → shard 0, 500–999 → shard 1), with secondary indexes on `color` and `make`.

*Local index:* when a red car is inserted into shard 0, shard 0 appends its ID to its own `color:red` postings list. Red cars exist in both shard 0 and shard 1. A query "all red cars" must fan out to every shard and merge. If you already know the listing ID's partition key, you query only that shard; if you only need *some* results, you can query any single shard.

*Global index:* the index itself is sharded by term — colors `a`–`r` in shard 0, colors `s`–`z` in shard 1; makes split between `f` and `h`. "Color = red" now reads a single index shard's postings list. But "red AND Honda" puts the two terms on different index shards, so the system must ship postings lists over the network to intersect them — fine when short, slow when long. And inserting one car may require writing to several index shards atomically.

**Hot-key mitigation:** a celebrity post makes one partition key extremely hot. Append two random digits to the key, splitting writes across 100 keys and therefore across shards. Costs: every read must fan out to all 100 keys and combine (read volume per shard is *not* reduced — only writes are split), you need bookkeeping of which keys are split, and a promotion process from regular key to managed hot key. Load also shifts over time — a viral post is hot for days, then calms down — and some keys are read-hot while others are write-hot, needing different strategies.

## Key Takeaways
1. Don't shard until a single node genuinely cannot hold the data or absorb the writes; sharding is heavyweight and the scheme is hard to change afterward.
2. Choose the partition key first and deliberately — accessing a record is fast when you know its shard and inefficient (all-shard scan) when you don't.
3. Never use `mod N` over node count; use hash-range sharding, a fixed oversupply of shards, or a consistent hashing algorithm.
4. Uniform key distribution is not uniform *load*. Hot keys need range-based shard boundaries (isolate the key, possibly on its own machine) or application-level key salting.
5. Prefer local secondary indexes when writes dominate; prefer global secondary indexes when read throughput exceeds write throughput and postings lists are short — accepting possible staleness.
6. Put a human in the loop for rebalancing, or at least gate automatic rebalancing so it can't cascade with automatic failure detection.
7. Sharding is also a multitenancy tool: isolation, per-tenant restore, GDPR deletion, and data residency all fall out of one-tenant-per-shard — provided every tenant fits on one node.

## Connects To
- **Ch 6 (Replication)**: orthogonal to sharding — each shard is replicated; a node can be leader for some shards and follower for others. Read scaling, not sharding, solves read-throughput problems.
- **Ch 8 (Transactions)**: a write touching several shards needs a distributed transaction, which is much slower than a single-node transaction and can bottleneck the system.
- **Ch 9 (Trouble with Distributed Systems)**: network partitions (netsplits) are unrelated to data partitioning; but false failure detection is what makes automatic rebalancing dangerous.
- **Ch 10 (Consistency and Consensus)**: ZooKeeper/etcd/Raft provide the fault-tolerant, split-brain-free shard→node map.
- **Ch 11**: analytical queries aggregate and join across many shards in parallel rather than routing to one.
- **Ch 4 (Storage and Retrieval)**: SSTables/B-trees give sorted order inside a shard; shard splitting costs the same as an LSM compaction. Data warehouses (BigQuery partition keys + cluster columns, Snowflake micro-partitions, Delta Lake) apply the same idea under different names.
- **Consistent Hashing and Random Trees** (Karger et al., STOC 1997) — the original consistent hashing paper.
