# Chapter 2: Defining Nonfunctional Requirements

## Core Idea
Beyond what an application does, you must explicitly articulate and measure how well it does it —
performance (response time distributions, not averages), reliability (fault tolerance), scalability
(cost of coping with growing load), and maintainability (operability, simplicity, evolvability).

## Frameworks Introduced

- **Response time as a distribution, measured by percentiles**: report p50 (median), p95, p99, p999 —
  never the arithmetic mean as your "typical" number.
  - When to use: any user-facing latency target, any SLO/SLA, any monitoring dashboard.
  - How: the mean is useful only for estimating throughput limits. Use the median to say how long
    users typically wait. Use *tail latencies* (p95/p99/p999) to size how bad outliers are. Measure on
    the **client** side, because queueing delay is not part of service time and is often the bulk of
    the variability. Keep a rolling window (e.g. 10 minutes) and recompute each minute; if sorting
    every value is too expensive use HdrHistogram, t-digest, OpenHistogram, or DDSketch.
  - Why it works: Amazon specified internal services at p999 even though it affects 1 in 1,000
    requests, because the slowest requests belong to customers with the most data — the most valuable
    ones. Amazon deemed optimizing p9999 (slowest 1 in 10,000) too expensive for too little benefit;
    very high percentiles are dominated by random events outside your control.
  - Failure mode: **averaging percentiles is mathematically meaningless.** To reduce time resolution
    or combine machines, add the histograms.

- **Fault vs. failure**: A *fault* is one part of the system stopping working correctly (a disk dies,
  a machine crashes, a dependency has an outage). A *failure* is the system as a whole ceasing to
  provide the required service — i.e. not meeting the SLO.
  - When to use: whenever specifying reliability, so you can name what you tolerate.
  - How: they are the same thing at different levels. Name each part that cannot be tolerated as a
    *single point of failure* (SPOF). State fault tolerance as a bounded claim — "tolerates at most
    two simultaneous disk failures", "at most one of three nodes crashing" — because tolerating *any*
    number of faults is meaningless.
  - Why it works: it converts "is it reliable?" into a testable statement. Counterintuitively you
    should then *increase* the rate of faults deliberately — **fault injection**, and the wider
    discipline of **chaos engineering** — because many critical bugs are due to poor error handling,
    and continually exercising the fault-tolerance machinery is the only way to trust it.

- **Materialization / materialized view (the fan-out timeline)**: precompute and incrementally update
  the result of an expensive read query so reads are served from a cache, at the cost of more work on
  writes.
  - When to use: read-heavy workloads where the same expensive query runs constantly.
  - How: push instead of poll; on each write, fan out to every dependent view. Enqueue deliveries
    during spikes and accept a slightly longer delivery delay — reads stay fast because they still hit
    the cache. Handle the extremes specially (see Worked Example).

- **Load parameters → scalability questions**: describe load with the numbers that actually drive
  your bottleneck, then ask growth questions against them.
  - How: pick throughput measures (requests/sec, GB of new data/day, checkouts/hour) plus peaks (peak
    simultaneous online users) plus distribution statistics (read:write ratio, cache hit rate, items
    per user — e.g. followers). Then ask both directions: (1) if load increases with resources fixed,
    what happens to performance? (2) if load increases and performance must stay fixed, how much must
    resources increase? Goal: stay inside the SLA while minimizing cost.
  - **Linear scalability** = double the resources handles double the load at the same performance.
    Occasionally sublinear cost is possible via economies of scale or better peak distribution; much
    more likely cost grows faster than linearly.

- **Three maintainability principles**: *Operability* (make it easy for the organization to keep the
  system running smoothly), *Simplicity* (make it easy for new engineers to understand, via
  well-understood consistent patterns), *Evolvability* (make it easy to change the system for
  unanticipated future use cases).

## Key Concepts
- **Response time**: what the client sees — every delay incurred anywhere in the system.
- **Service time**: the duration the service is actively processing the request.
- **Queueing delay**: waiting for a CPU to become free, or for an outbound packet to be buffered; not
  part of service time.
- **Latency**: catchall for time during which a request is not being actively processed (it is
  *latent*); *network latency* is time spent traveling through the network. *Jitter* is variation in
  network delay.
- **Head-of-line blocking**: a server processes only a few things in parallel, so a few slow requests
  hold up subsequent fast ones — the client sees slow response times regardless of service time.
- **Tail latency amplification**: when one end-user request requires many backend calls (even in
  parallel), it waits for the slowest; a small fraction of slow backend calls makes a much larger
  fraction of end-user requests slow.
- **Metastable failure**: an overloaded system enters a vicious cycle (long queue → timeouts →
  retries → more load — a *retry storm*) and stays broken even after load drops, until reboot/reset.
- **SLO / SLA**: an SLO is a target (e.g. median < 200 ms, p99 < 1 s, ≥ 99.9% of valid requests
  non-error); an SLA is the contract specifying consequences (e.g. refunds) if the SLO is missed.
- **Fan-out**: the factor by which one initial request multiplies into downstream requests.
- **Exactly-once semantics**: taking over a failed task without missing or duplicating any work.
- **Availability zone**: a cloud provider's label for physically co-located resources, which are more
  likely to fail together than geographically separated ones.
- **Rolling upgrade**: patching a multi-node fault-tolerant system one node at a time, with no user-
  visible downtime.
- **Blameless postmortem**: after an incident, participants share full detail without fear of
  punishment, so the organization can learn.
- **Big ball of mud**: a project mired in complexity; *essential* complexity is inherent to the
  problem domain, *accidental* complexity comes from tooling limits (a flawed distinction, since the
  boundary shifts as tooling evolves).

## Mental Models
- **Think of response time as a distribution with a shape, not a number.** Context switches, TCP
  retransmissions, GC pauses, page faults, and even mechanical vibrations in the rack add random delay.
- **Use throughput to size cost, response time to judge user experience.** Throughput determines how
  many servers you need; response time is what users care about.
- **Treat "human error" as a symptom, not a cause.** Configuration changes by operators were the
  leading cause of outages in one study of large internet services, with hardware faults involved in
  only 10–25% of cases. The fix is the sociotechnical system: rollback mechanisms, gradual rollouts,
  property testing on random inputs, clear monitoring, interfaces that encourage the right thing.
  Blaming the person when a preventable mistake occurs is really about the organization's priorities.
- **Expect to rethink your architecture at every order of magnitude of load.** There is no *magic
  scaling sauce*; a system for 100,000 requests/sec of 1 kB each looks nothing like one for 3
  requests/minute of 2 GB each, even though both move 100 MB/second.
- **Minimize irreversibility to improve flexibility.** A database migration you can roll back is a
  far lower-stakes decision than one you cannot.

## Reference Tables

Scaling architectures

| Architecture | What is shared | Also called | Trade-off |
|---|---|---|---|
| Shared-memory | RAM across threads/processes on one machine | Vertical scaling / scaling up | Simplest, but cost grows faster than linearly and bottlenecks mean a 2× machine won't handle 2× load |
| Shared-disk | Disk array via NAS or SAN; independent CPU/RAM | — | Traditional for on-premises data warehousing; contention and locking overhead limit scalability |
| Shared-nothing | Nothing; each node has own CPU, RAM, disk; coordination in software over the network | Horizontal scaling / scaling out | Potential for linear scaling, best price/performance hardware, elastic, multi-datacenter fault tolerance — but requires explicit sharding and all distributed-systems complexity |

Cloud native databases separate storage from transaction execution: multiple compute nodes share one
storage service. Superficially shared-disk, but the storage service exposes a specialized
database-specific API rather than a filesystem (NAS) or block device (SAN), avoiding the old
scalability problems.

Hardware failure rates the authors commit to

| Component | Rate |
|---|---|
| Magnetic hard drives | 2–5% fail per year → with 10,000 disks, expect ~1 failure per day |
| SSDs | 0.5–1% fail per year; uncorrectable errors ~once per year per drive, even when nearly new — higher than magnetic disks |
| CPU cores | ~1 in 1,000 machines has a core that occasionally computes the wrong result |
| RAM | >1% of machines hit an uncorrectable error per year even with ECC, typically crashing the machine |
| Other (PSU, RAID controllers, memory modules) | Fail less frequently than hard drives |

Overload countermeasures

| Side | Technique |
|---|---|
| Client | Exponential backoff (increase and randomize time between retries); circuit breaker; token bucket |
| Server | Load shedding (proactively reject as overload approaches); backpressure (tell clients to slow down); choice of queueing and load balancing algorithms |

Latency-impact studies (treat with skepticism)

| Study | Claim |
|---|---|
| Google 2006 | Search slowdown 400 ms → 900 ms associated with 20% drop in traffic and revenue |
| Google 2009 | 400 ms increase → only 0.6% fewer searches per day |
| Bing 2009 | 2 s increase in load time → 4.3% less ad revenue |
| Akamai | 100 ms increase → up to 7% lower ecommerce conversion — but the same study shows *very fast* loads also correlate with low conversion (404 pages), so it does not separate content from load time |
| Yahoo 2010 | Controlling for result quality: 20–30% more clicks on fast searches when the fast/slow difference is ≥ 1.25 s |

## Code Examples

```sql
SELECT posts.*, users.* FROM posts
  JOIN follows ON posts.sender_id = follows.followee_id
  JOIN users   ON posts.sender_id = users.id
  WHERE follows.follower_id = current_user
  ORDER BY posts.timestamp DESC
  LIMIT 1000
```
- **What it demonstrates**: the naive read-time home timeline — correct, simple, and completely
  unaffordable at scale, which is what motivates materialization.

## Worked Example
**Social network home timeline latency/throughput budget.** Assume 500 million posts per day = 5,800
posts/sec average, spiking to 150,000 posts/sec. The average user follows 200 people and has 200
followers (celebrities like Barack Obama have over 100 million followers).

*Read-time approach (polling):* posts should reach followers within five seconds, so clients re-run
the timeline query every 5 s. With 10 million users online simultaneously that is **2 million timeline
queries per second**. Each query must fetch and merge recent posts from 200 followed accounts →
**400 million lookups per second**. And that is the average case; users following tens of thousands of
accounts are far worse.

*Write-time approach (fan-out into materialized timelines):* on each post, look up all followers and
insert the post into each follower's timeline, like delivering into a mailbox; clients subscribe to
their timeline stream instead of polling. At 5,800 posts/sec × fan-out 200 = **just over 1 million
home timeline writes per second** — a large number, but a huge saving versus 400 million lookups/sec.
During a spike the deliveries are enqueued (posts take slightly longer to appear) while timeline
*reads* stay fast from cache.

*The two extremes:*
- A user following a very large number of prolific accounts gets a high write rate to their timeline —
  but they aren't reading it all, so it's fine to **drop some of their timeline writes** and show a
  sample.
- A celebrity post must reach millions of timelines, and dropping is **not** acceptable. Store
  celebrity posts separately and **merge them at read time** with the materialized timeline. Even
  with such optimizations, celebrities require a lot of infrastructure.

## Anti-patterns
- **Reporting the mean response time**: the average tells you nothing about how bad the worst
  experience is, and hides the tail entirely. Report p50/p95/p99 with histograms.
- **Averaging percentiles across machines or time windows**: mathematically meaningless. Aggregate
  the histograms, then compute the percentile.
- **Measuring latency only server-side**: misses queueing delay in the client's outbound buffer and
  the network. The number that matters is what the client experiences.
- **Treating scalability as a one-dimensional property**: "is it scalable?" is unanswerable. Ask
  "if load parameter X grows to N, what must change?"
- **Naive retries on failure**: turns a transient overload into a **metastable failure** where the
  retry storm sustains the outage after the original load is gone. Use exponential backoff with
  jitter and circuit breakers.
- **Blaming humans for outages**: configuration errors by operators are a leading cause of outages,
  but punishing people suppresses the disclosure you need. Run blameless postmortems and design
  systems that make the right action the easy one.
- **Treating an SLA as an SLO**: an SLO is an internal target; an SLA is a contract with
  consequences. Confusing them means either over-engineering or an unfunded promise.

## Key Takeaways
1. Write nonfunctional requirements down. An app that is unbearably slow or unreliable might as well
   not exist, but these requirements go unstated because they seem obvious.
2. Report percentiles, measure them client-side, and never average percentiles across machines or
   time windows — add histograms instead.
3. Design against metastable failure explicitly: exponential backoff and circuit breakers on the
   client, load shedding and backpressure on the server. An overloaded system may not recover on its
   own even after load drops.
4. Software faults are far more dangerous than hardware faults because they are highly correlated —
   every node runs the same buggy code (the 2012 leap second Linux kernel bug; SSDs of certain models
   failing at exactly 32,768 hours). Redundancy does not help; testing assumptions, process
   isolation, crash-and-restart, avoiding feedback loops, and production monitoring do.
5. Don't optimize for hypothetical scale at a startup — simplicity and flexibility win while you are
   still learning customers' needs. Premature scalability work is wasted at best and locks you into
   an inflexible design at worst.
6. The general scalability principle is to break the system into smaller components that operate
   largely independently (microservices, sharding, stream processing, shared-nothing) — but the hard
   part is knowing where to draw the line, and simpler is usually better (5 services beat 50; a
   single-machine database beats a distributed setup that isn't needed; manual scaling beats
   autoscaling when load is predictable).
7. Most software cost is maintenance, not initial development. "Good operations can often work around
   the limitations of bad software, but good software cannot run reliably with bad operations."
8. More automation is not always better for operability: the cases automation can't handle are the
   most complex, so heavy automation demands a *more* skilled ops team, and an automated system that
   goes wrong is harder to troubleshoot.

## Connects To
- **Ch 1**: applies the operational/analytical and distributed/single-node trade-offs by giving you
  metrics to judge them; materialized views are derived data.
- **Ch 5**: rolling upgrades and schema/API evolution as the mechanics of evolvability.
- **Ch 6, 10**: replication and consensus as the machinery that tolerates loss of machines, racks,
  and availability zones.
- **Ch 7**: sharding, the concrete technique behind shared-nothing horizontal scaling.
- **Ch 9**: timeouts and unbounded delays — why response time varies unboundedly in distributed
  systems.
- **Ch 12**: exactly-once semantics for fault-tolerant fan-out and stream processing.
- **External**: Google's SRE practice and blameless postmortems; chaos engineering; the Post Office
  Horizon scandal as a case of English law presuming computers operate correctly; HdrHistogram,
  t-digest, DDSketch for percentile estimation; domain-driven design and design patterns as
  application-level complexity management built *on top of* the abstractions in this book.
