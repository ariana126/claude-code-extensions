# Chapter 4: Storage and Retrieval

## Core Idea
Storage engines split into two OLTP families — log-structured (append immutable files, merge in background) and update-in-place (B-trees) — plus a separate column-oriented family for analytics; pick and tune the engine by matching its write-amplification and read-path characteristics to your workload.

## Frameworks Introduced

- **LSM-tree (Log-Structured Merge-tree) / LSM storage engine**: keep a cascade of immutable sorted files (SSTables) that are merged and compacted in the background.
  - When to use: write-heavy workloads; high write throughput on the same hardware; when you want cheap snapshots, good compression, or segment files on object storage.
  - How: (1) write goes into an in-memory ordered map (**memtable**) — red–black tree, skip list, or trie; (2) every write is also appended to a separate on-disk log for crash recovery; (3) when the memtable exceeds a threshold (typically a few MB) flush it to disk as a new immutable **SSTable segment**, each with its own sparse index; (4) reads check memtable, then newest segment, then older segments until found; (5) a background merge/compaction process merges segments mergesort-style, keeping only the most recent value per key.
  - Deletion: append a **tombstone**; compaction discards prior values, and the tombstone itself can be dropped once merged into the oldest segment.
  - Why it works: sequential large writes beat small random writes on both HDDs and SSDs; immutable segments make crash recovery trivial (delete the unfinished SSTable and restart).
  - Failure mode: latency spikes under sustained high write throughput when compaction can't keep up and the memtable fills — RocksDB and others apply **backpressure**, suspending reads and writes until the memtable is flushed.

- **SSTable (Sorted String Table)**: an immutable file of key-value pairs sorted by key, each key appearing once, grouped into blocks of a few KiB, with a **sparse index** storing only the first key of each block.
  - How to read a missing key: binary-search the sparse index to the bracketing block (e.g. `handiwork` lies between `handbag` and `handsome`), seek, scan the block. Blocks are individually compressed, trading CPU for disk space and I/O bandwidth.

- **Bloom filter**: per-SSTable probabilistic membership test.
  - How: hash each key into k bit positions, set those bits. On query, if any bit is 0 the key is **definitely absent** — skip the SSTable. If all are 1, consult the sparse index; a **false positive** just costs wasted work.
  - Numbers: ~10 bits per key gives a 1% false-positive rate; the rate drops tenfold per additional 5 bits per key.
  - Does not help range queries (you'd have to hash every possible key in the range).

- **B-tree**: fixed-size pages, overwritten in place, forming a balanced tree of depth O(log n).
  - How: root page holds keys and child references; each child owns a contiguous key range. Descend until a **leaf page**. Insert into the page whose range covers the key; if full, **split** into two half-full pages and update the parent (splits can cascade to the root, creating a new root).
  - Numbers: pages traditionally 4 KiB; PostgreSQL 8 KiB, MySQL 16 KiB. **Branching factor** typically several hundred. Most databases fit in 3–4 levels; a 4-level tree of 4 KiB pages with branching factor 500 stores up to 250 TB.
  - Reliability: use a **write-ahead log (WAL)** — every modification appended to the WAL and `fsync`'d before pages are updated — because multi-page overwrites risk orphan pages and **torn pages**. In filesystems the equivalent is journaling. LMDB instead uses copy-on-write, which also aids concurrency control.

- **Write amplification**: total bytes written to disk divided by bytes you'd write with a plain append-only log with no index.
  - Use when: the bottleneck is disk write bandwidth, or you care about SSD wear. B-trees write data at least twice (WAL + page) and often rewrite a whole page for a few changed bytes. LSM-trees write to log, then memtable flush, then every compaction — but typically have *lower* write amplification because they never write whole pages and can compress SSTable blocks.
  - Measurement rule: run the benchmark long enough that compaction is competing with new writes; an empty LSM-tree flatters itself.

- **Column-oriented (columnar) storage**: store all values of each column together rather than all values of each row.
  - When to use: analytics/data-warehouse fact tables — often 100+ columns wide, but a typical query touches only 4 or 5.
  - How: break the table into blocks of thousands-to-millions of rows (often one timestamp range per block); within a block, store each column separately in the same row order, so the k-th entry of every column belongs to the same row. Apply **bitmap encoding** (one bitmap per distinct value, one bit per row), then **run-length encoding**; **roaring bitmaps** switch between representations. Sort whole rows (not columns independently) by an administrator-chosen sort key — the first sort key compresses best.
  - Writes: buffer into a row-oriented sorted in-memory store; merge in bulk into new immutable column files (the LSM idea again). Queries combine on-disk columns with in-memory recent writes; the distinction is invisible to the analyst.

## Key Concepts
- **Log**: an append-only sequence of records on disk (not application logs) — the simplest, fastest write primitive.
- **Index**: an additional structure derived from primary data; speeds reads, costs disk space, and slows writes — so databases index nothing by default and require you to choose.
- **Memtable**: the in-memory ordered map absorbing writes before an SSTable flush.
- **Tombstone**: a deletion marker appended to the log so compaction can discard older values.
- **Size-tiered compaction**: merge newer/smaller SSTables into older/larger ones (e.g. four 256 MB tables → one 898 MB table, shrunk by deletions/overwrites/TTLs).
- **Leveled compaction**: fixed-size SSTables grouped into levels L0, L1, … with key-range partitioning beyond L0; merges level *i* into *i*+1 when a level exceeds its size limit.
- **Clustered index**: the row itself is stored inside the index (InnoDB primary key; one per table in SQL Server).
- **Heap file**: unordered storage of rows referenced by indexes; Postgres uses this. Growing a value may force a move plus index updates or a forwarding pointer.
- **Covering index / index with included columns**: stores some columns in the index so queries can be answered from the index alone.
- **Concatenated index**: several fields appended into one key — answers (lastname, firstname) and lastname alone, but never firstname alone.
- **Inverted index**: term → **postings list** of document IDs (or a sparse bitmap); the core of full-text search (Lucene stores it in SSTable-like merged files).
- **Vector embedding**: array of floats (often >1,000) locating a document in semantic space; compared by **cosine similarity** or **Euclidean distance**.
- **Materialized view / data cube (OLAP cube)**: precomputed query results / grid of aggregates grouped by dimensions.

## Mental Models
- **Think of the read/write trade-off as a dial, not a menu.** Every index you add buys read speed with write throughput and disk space. Appending to a file is the floor cost of a write; everything else is amplification above it.
- **Use sequential writes as the unit of thinking for SSDs too.** Flash reads/writes a 4 KiB page but erases a 512 KiB block; sequential workloads let whole blocks be erased without garbage collection, so random writes both slow you down and wear the drive out faster.
- **Use "LSM for writes, B-tree for reads" as the starting hypothesis, then benchmark.** Benchmarks are workload-sensitive, and real engines blend both (e.g. multiple B-trees merged LSM-style).
- **Think of full-text search as a very-high-dimensional query.** Each term is a dimension with value 0/1; "red apples" is a bitwise AND of two bitmaps — the same operation as a vectorized warehouse predicate.
- **In-memory databases are not fast because they skip disk reads** (the OS page cache already handles that); they're fast because they skip encoding in-memory structures into a disk format.

## Code Examples

```bash
#!/bin/bash
db_set () {
    echo "$1,$2" >> database
}
db_get () {
    grep "^$1," database | sed -e "s/^$1,//" | tail -n 1
}
```
- **What it demonstrates**: the world's simplest database — `db_set` has excellent O(1) append performance, `db_get` has terrible O(n) scan performance, which is exactly why indexes exist. Old values are never overwritten, so `tail -n 1` wins.

```sql
SELECT
  dim_date.weekday, dim_product.category,
  SUM(fact_sales.quantity) AS quantity_sold
FROM fact_sales
  JOIN dim_date    ON fact_sales.date_key   = dim_date.date_key
  JOIN dim_product ON fact_sales.product_sk = dim_product.product_sk
WHERE
  dim_date.year = 2024 AND
  dim_product.category IN ('Fresh fruit', 'Candy')
GROUP BY
  dim_date.weekday, dim_product.category;
```
- **What it demonstrates**: a warehouse query scanning a huge number of rows but only three columns of `fact_sales` — the case for columnar storage.

```sql
SELECT * FROM restaurants WHERE latitude  > 51.4946 AND latitude  < 51.5079
                            AND longitude > -0.1162 AND longitude < -0.1004;
```
- **What it demonstrates**: a 2D range query a concatenated index cannot serve efficiently — it needs an R-tree/Bkd-tree or a space-filling curve.

## Reference Tables

### LSM-tree vs. B-tree
| Dimension | LSM-tree | B-tree |
|---|---|---|
| Write path | Append + background compaction; sequential, large | Overwrite pages in place; random, small |
| Write throughput | Higher (rule of thumb: write-heavy → LSM) | Lower |
| Point reads | Check several SSTables; Bloom filters cut I/O | One page per level; fast and predictable |
| Range queries | Scan all segments in parallel and merge; Bloom filters don't help | Fast — sorted structure |
| Write amplification | Usually lower (no full-page writes, compressible blocks) | ≥2× (WAL + page), whole-page writes |
| Disk space | Compaction rewrites data; better compression; stale copies until compacted | Fragmentation from deletions; needs vacuum |
| Latency tail | Spikes/backpressure when compaction lags | More predictable |
| Snapshots / backups | Easy — segments are immutable | Harder — pages are overwritten |
| Guaranteed deletion | Slow — tombstone must propagate through all levels | Direct |

### Compaction strategies
| Strategy | Mechanism | Best for |
|---|---|---|
| Size-tiered | Merge small/new SSTables into large/old ones | Mostly writes, few reads; needs lots of temporary disk space |
| Leveled | Fixed-size, key-range-partitioned SSTables in growing levels L0..Ln | Read-dominated workloads; less disk space; also good when few keys are written often and many rarely |

### Vector indexes
| Index | Mechanism | Accuracy / speed |
|---|---|---|
| Flat | Store vectors as-is, compare against all | Exact, slow |
| IVF (inverted file) | Cluster space into centroids; query checks *probes* partitions | Approximate; more probes = more accurate, slower |
| HNSW | Multi-layer proximity graphs, descend from sparse top layer to dense bottom | Approximate, fast |

## Worked Example
**B-tree page split on insert.** Insert key 334 into a B-tree where the leaf page covering range 333–345 is already full. The engine splits it into a page for 333–337 (which holds the new key 334) and a page for 337–345, then updates the parent to reference both children with boundary value 337 between them. If the parent lacks space for the new reference, it splits too, and splits may cascade to the root; splitting the root creates a new root one level up. This keeps the tree balanced at O(log n) depth — but the multi-page overwrite is precisely the dangerous, non-atomic operation the WAL exists to make recoverable: crash midway and you can be left with an orphan page or a torn page.

## Key Takeaways
1. Choose LSM storage for write-heavy workloads and B-trees for read-heavy ones — then verify with a benchmark on *your* workload, run long enough for compaction effects to appear.
2. Budget ~10 Bloom-filter bits per key for a 1% false-positive rate; add 5 bits per 10× reduction.
3. Set your columnar sort key to the column your queries filter on most (usually a date) — it doubles as the index *and* gives the strongest run-length compression.
4. Every secondary index is a write tax; add them deliberately from known query patterns, and prefer covering indexes only when the read win outweighs the extra space and write cost.
5. Random writes hurt on SSDs too — via flash garbage collection and accelerated wear — not just on spinning disks.
6. `SELECT *` is an anti-pattern in analytics: columnar storage's entire benefit is reading only the columns a query touches.
7. Keep raw data in the warehouse and treat data cubes / materialized aggregates purely as a precomputed fast path — cubes can't answer questions about dimensions they don't contain.

## Anti-patterns
- **On-disk hash indexes**: require heavy random I/O, are expensive to grow, need fiddly collision logic, and can't do range queries. Keep hash maps in memory or use sorted structures.
- **Benchmarking an empty LSM-tree**: all disk bandwidth goes to new writes because no compaction is running; the measured throughput is fantasy.
- **Relying on a concatenated index for multidimensional queries**: it filters one dimension at a time, not simultaneously — use R-trees/Bkd-trees or space-filling curves.
- **Assuming a delete is a delete in LSM storage**: records survive in higher levels until the tombstone propagates through all compaction levels, which can take a long time — a compliance risk.
- **Confusing wide-column (column-family) stores with column-oriented storage**: Bigtable, HBase, and Accumulo are row-oriented despite the name.

## Connects To
- **Ch 3 (Data Models and Query Languages)**: this chapter is the database's-eye view of the same store/query interface — star and snowflake schemas from Ch 3 are what columnar storage is optimized for.
- **Ch 8 (Transactions)**: durability, crash recovery, `fsync`, and copy-on-write B-trees underpin snapshot isolation.
- **Chs 6–7 (Replication, Sharding)**: embedded engines (RocksDB, SQLite, LMDB, DuckDB) handle single-machine data; these chapters scale across machines.
- **Bigtable paper (2006)**: origin of the terms SSTable and memtable; O'Neil et al. (1996) named the LSM-tree; Bayer & McCreight (1970) introduced the B-tree.
- **Lucene / Elasticsearch**: an inverted index built on log-structured merged files — the same machinery in a search-engine costume.
