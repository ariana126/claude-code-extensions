# Chapter 11: Batch Processing

## Core Idea
A batch job reads **immutable, bounded** input and regenerates its output from scratch, with no side effects — which is what buys you retryability, rollback, and cheap parallelism. Distributed batch frameworks are essentially distributed operating systems: a filesystem, a scheduler, and programs piped together.

## Frameworks Introduced

- **Human fault tolerance / minimizing irreversibility**: because input is read-only and output is derived, a bug is fixed by rolling back the code and rerunning, or by switching back to the previous output directory (**time travel**, supported by most object stores and open table formats).
  - When to use: any pipeline where a deploy could corrupt data. Databases with read/write transactions do *not* have this property — rolling back the code does nothing to fix the bad rows it wrote.
  - Why it works: input immutability plus no external side effects means a rerun is idempotent at the job level. Corollary: never write to a production database directly from inside a batch task, because that reintroduces irreversibility.

- **MapReduce**: four steps — (1) read input files and break into **records**; (2) call the **mapper** once per record to emit zero or more key-value pairs; (3) **sort** all pairs by key (implicit, you never write it); (4) call the **reducer** once per key with an iterator over that key's values.
  - When to use: understand it as background; it is largely obsolete and no longer used at Google.
  - How: mapper is stateless per record and parallel across input shards; reducers for different keys run in parallel. A second sorting stage means a second MapReduce job whose input is the first job's output.
  - Failure mode: file-based I/O between stages prevents job pipelining, joins must be written from scratch, and a new JVM is launched per task.

- **Shuffle** (the foundational distributed-sort algorithm; *not* random): each mapper creates one local output file per reducer (file `m1,r2` holds mapper 1's data for reducer 2), choosing the file by **hash of the key**, and sorts pairs within each file using log-structured merge techniques. Reducers then copy their file from every mapper and mergesort them, so equal keys become consecutive across mappers.
  - Why it works: sorting turns "collect all values for a key" into a sequential scan with O(1) memory per key.
  - Modern variants (BigQuery) keep shuffle data in memory and offload to a replicated external sorting service.

- **Sort-merge join** with **secondary sort**: to join clickstream events against a user table, emit both keyed by user ID; arrange the sort so the reducer always sees the *user record first*, then the activity events in timestamp order. The reducer stashes the user attribute in a local variable and streams the events. No network requests, one user record in memory at a time.

- **Dataflow engines (Spark, Flink)**: model the entire workflow as one job rather than independent subjobs, with operators (`join`, `group by`, filter, aggregate) assembled freely instead of alternating map/reduce.
  - Advantages over MapReduce: sort only where required; fuse consecutive sharding-preserving operators into one task; scheduler sees all data dependencies so it can co-locate producer and consumer and exchange via shared memory; intermediate state stays in memory or local disk instead of being replicated to the DFS; operators start as soon as their input is ready; processes are reused across operators.

- **Distributed job orchestration** (YARN, Kubernetes) — three components:
  - **Task executors** (YARN `NodeManager`, Kubernetes `kubelet`): fetch executable code, start and monitor tasks, heartbeat liveness, enforce isolation via Linux **cgroups**.
  - **Resource manager**: global view of node hardware, task status, node status. State lives in ZooKeeper (YARN) or etcd (Kubernetes). A centralized scalability/availability bottleneck.
  - **Scheduler**: maps task requests onto nodes. Application-specific subschedulers are YARN **ApplicationMasters** / Kubernetes **operators**.

## Key Concepts
- **Online (offline) systems**: online systems optimize response time and availability; batch/offline systems optimize **throughput**, running minutes to days.
- **Working set**: the amount of memory a job needs random access to — here, the number of *distinct* keys, not the number of records.
- **Data node**: the per-machine daemon serving DFS blocks over the network (HDFS **DataNode**, GlusterFS `glusterfsd`); metadata lives in a separate service (HDFS **NameNode**, 3FS metadata service on FoundationDB).
- **Erasure coding (Reed–Solomon)**: recovers lost blocks with lower storage overhead than full replication; like RAID but over a conventional datacenter network.
- **Gang scheduling**: hold resources until a job's full allocation is simultaneously available. Risks idle nodes, starvation, and deadlock.
- **Preemption / spot instances**: killing low-priority tasks to free capacity. EC2 **spot instances**, Azure **spot VMs**, GCP **preemptible instances**. Preemptions occur *more frequently than hardware faults*.
- **Workflow / DAG**: a dependency graph of batch jobs, managed by Airflow, Dagster, or Prefect (not by YARN or Spark's per-job scheduler). 50–100 jobs per pipeline is common.
- **Data lakehouse**: query engine over a DFS/object store with table formats (Apache Iceberg) and catalogs (Unity) supplying table metadata.
- **Bulk synchronous parallel (BSP) / Pregel model**: iterative graph processing by propagating information one edge at a time until convergence. Apache Giraph, Spark GraphX, Flink Gelly.
- **Data mesh / data contract / data fabric**: practices letting teams across an org safely publish data for others to consume.

## Code Examples

The Unix pipeline that finds the five most popular pages in an NGINX access log:

```bash
cat /var/log/nginx/access.log |
  awk '{print $7}' |
  sort             |
  uniq -c          |
  sort -r -n       |
  head -n 5
```
- **What it demonstrates**: the whole MapReduce shape in six commands — `awk` is the mapper (extract key), `sort` is the shuffle, `uniq -c` is the reducer. GNU Coreutils `sort` spills to disk and parallelizes across cores, so this scales past memory; the bottleneck becomes disk read rate.

Variations: `awk '$7 !~ /\.css$/ {print $7}'` to omit CSS files; `awk '{print $1}'` to rank client IPs.

The equivalent in-memory Python:

```python
from collections import defaultdict

counts = defaultdict(int)

with open('/var/log/nginx/access.log', 'r') as file:
    for line in file:
        url = line.split()[6]
        counts[url] += 1

top5 = sorted(((count, url) for url, count in counts.items()),
              reverse=True)[:5]

for count, url in top5:
    print(f"{count} {url}")
```
- **What it demonstrates**: hash-table aggregation vs sorting. The hash table wins while the working set (distinct URLs + counters, often < 1 GB) fits in memory; sorting wins when it doesn't, because mergesort has sequential disk access patterns.

NGINX log format and a sample line:

```
$remote_addr - $remote_user [$time_local] "$request"
$status $body_bytes_sent "$http_referer" "$http_user_agent"

216.58.210.78 - - [27/Jun/2025:17:55:11 +0000] "GET /css/typography.css HTTP/1.1"
200 3377 "https://martin.kleppmann.com/" "Mozilla/5.0 ..."
```

## Reference Tables

| | Distributed filesystem (HDFS, JuiceFS, Ceph) | Object store (S3, GCS, Azure Blob) |
|---|---|---|
| Addressing | paths, directories, inodes | `s3://bucket/key`; slashes are just part of the key |
| Mutability | in-place writes, file handles (`fopen`, `fseek`) | objects immutable; update = full `put`. Appends only in Azure Blob and S3 Express One Zone |
| Listing | `ls` of one directory | prefix `list` behaves like recursive `ls -R`; empty directories impossible (use a zero-byte object) |
| Links, locks, rename | hard/symlinks, file locking, atomic rename | usually absent; rename = copy + delete, nonatomic, per-object for a "directory" |
| Compute locality | tasks can run on a node holding the block | storage and compute separated; scales independently |
| Block size | HDFS 128 MB; JuiceFS & many object stores 4 MB (vs ext4's 4,096 bytes) | — |

| Layer | Local OS | Distributed equivalent |
|---|---|---|
| Block device driver | disk driver | data node block API over the network |
| Page cache | OS page cache | data node OS page cache (+ client/local-disk cache in JuiceFS) |
| Filesystem metadata | ext4/XFS inodes | NameNode, 3FS metadata service |
| VFS | common syscall API | DFS protocol (S3 API, FUSE, NFS) as a pluggable interface |
| Scheduler | kernel scheduler | YARN / Kubernetes |
| Pipes | in-memory buffer + backpressure | task-to-task network transfer, or DFS files between jobs |

| Framework | Intermediate data handling | Recovery |
|---|---|---|
| MapReduce | always written back to the DFS; downstream waits for full completion | rerun individual failed tasks; robust under frequent preemption but write-heavy |
| Spark | kept in memory, spilled to local disk; only final result to DFS | tracks lineage of how intermediate data was computed and recomputes it |
| Flink | streaming-style execution | periodic checkpointed snapshots of tasks |

| Optimizer / API | Execution style |
|---|---|
| Pandas DataFrame | executes each method call immediately, in memory, indexed and ordered |
| Spark DataFrame | translates all calls into a query plan, optimizes, then runs on the dataflow engine; generally *not* indexed or ordered |
| Daft | hybrid — small in-memory ops on the client, large datasets server-side, sharing Apache Arrow |

## Worked Example
**Joining clickstream events to user profiles with MapReduce.** Left input: a log of activity events (the fact table) for logged-in users. Right input: a user database (a dimension). Goal: is a page more popular with younger or older users?

1. **Mapper A** scans activity events, emitting `(user_id → page view URL)`.
2. **Mapper B** scans the user database row by row, emitting `(user_id → date of birth)`.
3. The **shuffle** hashes `user_id` so both sides land on the same reducer, regardless of the shard they started on. A **secondary sort** orders each key's values so the user-database record arrives *first*, followed by activity events in timestamp order.
4. The **reducer** reads the first value as the date of birth into a local variable, then iterates the events, emitting `(URL, date of birth)` per view. Memory held: one user record. Network requests made during join logic: zero.
5. A **second MapReduce job** shuffles that output by URL, and its reducers iterate the page views for one URL, incrementing a per-age-group counter — a group-by plus aggregation, producing the age distribution per URL.

**Scheduling counterexample.** A 5-node cluster with 160 cores receives two jobs each wanting 100 cores. Run 80+80 and backfill? Gang-schedule job 1 fully and idle nodes while reserving for job 2 (risking deadlock if other jobs also reserve)? Wait for 100 free cores (risking starvation)? Preempt job 1's tasks (wasting the work already done)? The general problem is **NP-hard**, so real schedulers use heuristics: FIFO, dominant resource fairness (DRF), priority queues, capacity/quota scheduling, and bin packing.

## Mental Models
- **Think of a batch job as a pure function**: immutable input → new output, input untouched. Every
  operational virtue of batch processing (retry, rollback, monitoring, experimentation) follows from
  that one property, not from throughput.
- **Use sorting, not hashing, once the working set exceeds memory.** The working set is the number of
  *distinct keys*, not the number of records — a billion page views over ten thousand URLs has a tiny
  working set.
- **Think of the shuffle as the real cost center.** Mappers exist to prepare data for the sort; the
  reducer's power comes entirely from records arriving grouped by key. Design jobs to minimize how
  many times data crosses the shuffle.
- **Treat a hot key as a load-balancing problem, not a correctness problem.** Skew makes one reducer
  the whole job's critical path; randomize the hot key across reducers and combine in a second pass.

## Anti-patterns
- **Writing to a production database record-by-record from batch tasks**: per-record network calls are
  orders of magnitude too slow, parallel tasks overwhelm the database, and partial output escapes the
  job's all-or-nothing guarantee. Bulk-load prebuilt files or publish to a topic instead.
- **Jobs with side effects**: any effect outside the output dataset breaks the ability to rerun
  safely, which is the entire point of batch processing.
- **Nondeterministic jobs** (depending on wall-clock time, random numbers, or remote services): the
  rerun no longer reproduces the result, so recovery and speculative execution both become unsound.
- **Overwriting the input, or the previous output**: destroys time travel — the ability to roll back
  to yesterday's output after a bad deploy.
- **Hand-writing MapReduce today**: dataflow engines fuse operators, keep intermediates in memory,
  pipeline stages, and reuse processes. Reach for MapReduce only to understand what they optimize.
- **Assuming preemption is rare**: on shared and spot-instance clusters, tasks are killed far more
  often by the scheduler than by hardware faults. Budget for it.

## Key Takeaways
1. Make batch inputs immutable and jobs side-effect-free. That single discipline gives you rollback, retry, monitoring jobs over the same inputs, and fast iteration.
2. Sorting beats hashing once the working set exceeds memory — and the working set depends on the number of *distinct keys*, not records.
3. Prefer a dataflow engine (Spark, Flink) or a warehouse query engine over hand-written MapReduce: fewer sorts, fused operators, in-memory intermediates, pipelined stages, reused processes.
4. Never write to a production database record-by-record from batch tasks. Per-record network calls are orders of magnitude too slow, parallel tasks overwhelm the DB, and partial output escapes the job's all-or-nothing guarantee. Push to a Kafka topic (sequential writes, buffer, fan-out to many consumers, DMZ security boundary) or bulk-load prebuilt files (TiDB Lightning, Pinot Hadoop import, RocksDB SST import).
5. Streams still don't give you atomicity by themselves: consumers must hold ingested data invisible to queries — like an uncommitted transaction under read committed — until the job signals completion.
6. Batch jobs are ideal for spot/preemptible instances because they aren't time-sensitive and task-level retry is cheap; expect preemption to be more common than hardware failure.
7. Use a workflow scheduler (Airflow, Dagster, Prefect) for cross-job dependencies; the job orchestrator (YARN, Kubernetes) only schedules one job at a time.
8. Batch's structural weakness: any change to the input — even one byte — requires reprocessing the entire dataset, and downstream jobs generally can't start until the whole upstream job finishes.

## Connects To
- **Ch 4 (Storage)**: LSM/log-structured storage and SSTable merging is exactly the mechanism behind sorting and shuffling; key-value stores optimize small values while object stores optimize MB–GB objects.
- **Ch 7 (Sharding)**: sharding by hash of key determines which reducer a mapper's output goes to.
- **Ch 6 (Replication)**: DFS block replication and erasure coding.
- **Ch 10 (Consensus)**: coordination services (ZooKeeper for YARN, etcd for Kubernetes) hold cluster state.
- **Ch 12 (Stream Processing)**: same shape of computation with **unbounded** input; jobs never complete.
- **Ch 3 / Data Warehousing**: star schemas (fact + dimension tables), ETL/ELT, OLAP cubes, columnar formats (Parquet) vs row-based (Avro), cloud warehouses converging with batch frameworks.
- **Papers/systems**: Dean & Ghemawat 2004 (MapReduce), Dryad, Nephele, Zaharia (Spark/RDD lineage), Pregel (BSP graph processing), Ray/Kubeflow/Flyte for LLM data prep.
