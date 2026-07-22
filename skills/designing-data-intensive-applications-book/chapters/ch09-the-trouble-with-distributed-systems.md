# Chapter 9: The Trouble with Distributed Systems

## Core Idea
The defining characteristic of a distributed system is **partial failure**: parts break unpredictably and nondeterministically while other parts work fine, and you often cannot even know whether an operation succeeded. Networks, clocks, and process scheduling all give unbounded delays, so you must design for suspicion, pessimism, and paranoia — and rely on quorums and fencing rather than on any single node's judgment.

## Frameworks Introduced

- **Timeout-based failure detection**: the only general way to detect a fault.
  - How: retry a few times, wait for a timeout, then declare the node dead. In a fictional network with maximum delay *d* and maximum handling time *r*, `2d + r` would be the right timeout — but neither bound exists in real systems.
  - Trade-off: too short → alive nodes falsely declared dead, actions performed twice, load transferred onto already-struggling nodes, risking **cascading failure**. Too long → users wait during real outages.
  - Better than a constant: continually measure response times and their variability (**jitter**) and adjust automatically. The **Phi Accrual failure detector** (used in Akka and Cassandra) does this; TCP retransmission timeouts work similarly.
  - Explicit signals you sometimes get: TCP `RST`/`FIN` when no process listens; a crash-notification script (HBase does this); switch management interfaces; ICMP Destination Unreachable. None can be counted on.

- **Monotonic vs. time-of-day clocks** — the split you must respect.
  - **Time-of-day clock** (`clock_gettime(CLOCK_REALTIME)`, `System.currentTimeMillis`): seconds since the epoch, NTP-synchronized, comparable across machines — but may jump backward on forced NTP reset, on leap seconds, or on DST. **Unsuitable for measuring elapsed time.**
  - **Monotonic clock** (`clock_gettime(CLOCK_MONOTONIC)` / `CLOCK_BOOTTIME`, `System.nanoTime`): guaranteed to move forward; the *absolute* value is meaningless and never comparable across machines. NTP may **slew** its rate (by default up to ±0.05%) but cannot make it jump. Resolution usually microseconds or better.
  - Use monotonic clocks for durations and timeouts; use time-of-day clocks only for points in time, and never for ordering events across nodes.

- **Clock readings with a confidence interval**: treat a clock reading not as a point but as a range `[earliest, latest]`.
  - When to use: any time correctness depends on time ordering across machines.
  - How: uncertainty = expected quartz drift since last sync + the time server's own uncertainty + network round-trip time. Google's **TrueTime** (Spanner) and **Amazon ClockBound** expose this explicitly; `clock_gettime` does not, so you cannot tell whether its error is five milliseconds or five years.
  - Why it works: if two intervals do not overlap (A_earliest < A_latest < B_earliest < B_latest), B definitely happened after A. Spanner deliberately **waits out the length of the confidence interval** before committing a read/write transaction, guaranteeing that any later reader's interval doesn't overlap. Google deploys a GPS receiver or atomic clock per datacenter to keep uncertainty to about **7 ms**. The atomic clocks are not strictly necessary — having a confidence interval is what matters; accurate sources only keep it small. YugabyteDB can use ClockBound on AWS the same way.

- **Fencing tokens** — the robust defense against zombie leaseholders.
  - How: every time the lock service grants a lock or lease, it returns a monotonically increasing number. Every write request to the storage service must carry the client's current token. The storage service remembers the highest token it has processed and rejects any write with a lower one. A client that has just acquired a lease should immediately make a write, which fences off all zombies.
  - Why it works: it protects against *both* long process pauses and network-delayed requests from a crashed former holder, unlike STONITH. It resembles optimistic concurrency control, except fencing is **permanent** whereas OCC failures can be retried.
  - Implementations: ZooKeeper's `zxid` or node `cversion`; etcd revision number + lease ID; Hazelcast's `FencedLock`; Chubby calls them **sequencers**; Kafka calls them **epoch numbers**; Paxos **ballot number** and Raft **term number** serve the same role.
  - **Fencing with multiple replicas**: put the fencing token in the most significant digits of the LWW timestamp. Then every timestamp from the new leaseholder outranks every timestamp from the old one, even if the old one's write happened later in real time. A zombie write may still land on an unreached replica, but a quorum read prefers the higher timestamp and read repair/anti-entropy eventually overwrites it.
  - Alternative: if you write to only one storage service that supports conditional writes (S3 **conditional writes**, Azure Blob **conditional headers**, GCS **request preconditions**), the lock service is somewhat redundant — the lease could be built directly on that service.

- **System models** — formalize your assumptions so algorithms can be proved correct.
  - Timing: **synchronous** (bounded network delay, bounded pauses, bounded clock error — unrealistic); **partially synchronous** (behaves synchronously *most of the time* but occasionally blows past every bound — realistic); **asynchronous** (no timing assumptions at all, not even a clock — very restrictive).
  - Node failures: **crash-stop / fail-stop** (a node crashes and never returns); **crash-recovery** (nodes crash and may return, with stable storage preserved and in-memory state lost); **degraded performance / partial functionality** — a **limping node**, **gray failure**, or **fail-slow** node, which is harder to handle than a cleanly dead one; **Byzantine (arbitrary) faults**.
  - **The partially synchronous model with crash-recovery faults is generally the most useful for modeling real systems.**

- **Safety vs. liveness properties**:
  - **Safety** = if violated, you can point to the exact moment it broke, and the damage cannot be undone (e.g., *uniqueness* and *monotonic sequence* of fencing tokens).
  - **Liveness** = may not hold now but there is always hope it will hold later; the giveaway word is "eventually" (e.g., *availability*; eventual consistency is a liveness property).
  - Rule: require safety properties to hold in **all** situations of the system model, even if every node crashes or the whole network fails. Attach caveats only to liveness properties — e.g., "a request receives a response provided a majority of nodes have not crashed and the network eventually recovers."

## Key Concepts
- **Partial failure**: some parts break unpredictably while others work; nondeterministic, and you may not know whether an operation succeeded.
- **Asynchronous packet network**: no guarantee about when, or whether, a packet arrives. The internet and datacenter Ethernet are both of this kind.
- **Network partition / netsplit**: part of the network cut off from the rest. Unrelated to sharding.
- **Unbounded delay**: no upper limit on packet transit. Round-trip times of **several minutes** occur at high percentiles across cloud regions; delays over a minute occur even inside one datacenter during a switch topology reconfiguration.
- **Noisy neighbor**: another tenant's usage of shared links, switches, NICs, and CPUs making your delays highly variable.
- **Circuit vs. packet switching**: a telephone circuit statically reserves bandwidth end to end (ISDN: 16 bits every 250 µs, 4,000 frames/sec), giving **bounded delay**. Ethernet/IP are packet-switched, optimized for **bursty traffic**, and so queue without bound. Variable delay is not a law of nature but a cost/benefit trade-off against hardware utilization.
- **Clock drift**: quartz runs fast or slow with temperature. Google assumes up to **200 ppm** — 6 ms drift when resynced every 30 s, 17 seconds when resynced daily.
- **Steal time**: CPU time a VM loses to the hypervisor; manifests as the clock jumping forward.
- **Zombie**: a former leaseholder that hasn't learned it lost the lease and still acts as holder.
- **Lease**: a lock with a timeout that must be periodically renewed; if the holder stops renewing, another node takes over.
- **Quorum**: voting so decisions don't depend on a single node. Usually an absolute majority (>half) — 3 nodes tolerate 1 failure, 5 tolerate 2 — and safe because two conflicting majorities cannot exist.
- **Byzantine fault**: a node that "lies" — arbitrary, faulty, or contradictory responses. The **Byzantine Generals Problem** generalizes the **two generals problem**.
- **Logical clocks**: incrementing counters capturing only relative ordering, versus **physical clocks** (time-of-day and monotonic) that measure elapsed time.

## Mental Models
- Think of a node as fundamentally unable to *know* anything about another node — it can only guess from messages received or not received. Problems in the network cannot be reliably distinguished from problems at a node.
- Use quorums, not self-assessment. If a quorum declares a node dead, it *is* dead and must step down, even if it feels perfectly alive. A node cannot trust its own judgment of the situation.
- Treat any line of code as a place where the process may pause for a minute. Writing distributed code is like writing thread-safe code, except you have no mutexes, semaphores, or shared memory — only messages over an unreliable network.
- Prefer a single machine when you can. Distributed systems engineers regard a problem as trivial if it can be solved on one computer, and a single computer can do a lot nowadays. Use distribution when you need fault tolerance, low latency by geography, or scale — not by default.
- Determinism is the master key: event sourcing replays logs deterministically, workflow engines require deterministic definitions for durable execution, and state machine replication runs the same deterministic transactions on each replica. Nondeterminism is the root of every problem in this chapter.

## Anti-patterns
- **Trusting TCP's "reliability"**: TCP retransmits and reorders, but it can't tell whether the packet or the ack was lost, can't unplug a cable, and dedupes only within a single connection — reconnect and retransmit, and you may duplicate data. An ack means only that the remote *kernel* received the bytes; the application may have crashed before handling them. To be sure a request succeeded, you need a positive response **from the application itself**.
- **LWW conflict resolution using client time-of-day timestamps** (Cassandra/ScyllaDB's default path): writes mysteriously disappear because a node with a lagging clock cannot overwrite a fast-clocked node's values until the skew elapses, and arbitrary amounts of data are silently dropped with no error. LWW also cannot distinguish sequential-but-quick writes from genuinely concurrent ones (needs version vectors), and two nodes can generate identical millisecond timestamps, requiring a random tiebreaker that itself violates causality.
- **Assuming better NTP will fix ordering**: NTP accuracy is bounded by network round-trip time, so you'd need clock error significantly below network delay — not possible. Even with tight sync, a packet sent at 100 ms can arrive at 99 ms by the receiver's clock.
- **Comparing a lease expiry set on another machine to your local system clock**, and assuming negligible time passes between checking `lease.isValid()` and calling `process(request)`. A 15-second pause between those lines means you process a request holding an expired lease.
- **STONITH (shoot the other node in the head)** as your only fencing: it doesn't protect against a network-delayed request from a crashed client, nodes can all shut each other down, and by the time the zombie is detected data may already be corrupt.
- **Assuming Byzantine fault tolerance protects against bugs or attackers**: BFT algorithms need a supermajority (>2/3) correct, so you'd need four independent implementations and hope the bug appears in only one. If an attacker compromises one node running your software, they can probably compromise all of them. Authentication, access control, encryption, and firewalls remain the real defenses.
- **Ignoring silent clock failure**: a broken CPU or misconfigured network fails loudly; a drifting quartz clock or misconfigured NTP client keeps working while diverging from reality, producing silent, subtle data loss. Monitor clock offsets across the cluster and remove any node that drifts too far.

## Code Examples

The lease-renewal loop that looks correct but isn't:

```java
while (true) {
    request = getIncomingRequest();

    // Ensure that the lease always has at least 10 seconds remaining
    if (lease.expiryTimeMillis - System.currentTimeMillis() < 10000) {
        lease = lease.renew();
    }

    if (lease.isValid()) {
        process(request);
    }
}
```
- **What it demonstrates**: two bugs at once. (1) It compares an expiry time computed on a *different* machine to the local time-of-day clock, so a few seconds of skew breaks it. (2) Even with a monotonic clock, it assumes negligible time between the check and `process(request)`; a 15-second pause anywhere in between means another node has taken over and this thread proceeds unsafely, never learning it was asleep.

## Reference Tables

| Cause of a process pause | Typical trigger |
|---|---|
| Thread contention | Shared locks/queues; worse on many-core machines and hard to diagnose |
| Stop-the-world GC | Historically minutes; a tuned modern collector usually a few ms |
| VM suspend/resume | Live migration; length depends on memory write rate |
| End-user device suspend | Closing a laptop lid |
| OS context switch / hypervisor switch | **Steal time**; long run queue under heavy load |
| Synchronous disk I/O | Including surprise I/O such as the Java classloader loading a class lazily; worse on network block devices (EBS) |
| Page fault / swapping | Extreme case is **thrashing**; often mitigated by disabling paging on servers |
| `SIGSTOP` | Ctrl-Z, or an ops engineer sending it accidentally |

| Timing model | Assumption | Realistic? |
|---|---|---|
| Synchronous | Bounded delay, pauses, and clock error | No |
| Partially synchronous | Synchronous most of the time, occasionally unbounded | Yes — the practical default |
| Asynchronous | No timing assumptions, no clock, no timeouts | Very restrictive |

| Node failure model | Assumption |
|---|---|
| Crash-stop (fail-stop) | Node crashes and never returns |
| Crash-recovery | Node crashes, may return; stable storage survives, memory doesn't |
| Degraded / limping / gray failure / fail-slow | Node answers health checks but is too slow to do useful work |
| Byzantine | Node may do absolutely anything, including deceiving others |

| Verification technique | What it checks | Examples |
|---|---|---|
| Model checking | A *model* of the algorithm across its state space | TLA+, Gallina, FizzBee; used by CockroachDB, TiDB, Kafka; TLA+ exposed data loss in viewstamped replication |
| Fault injection / chaos engineering | The real system under injected faults | Netflix Chaos Monkey, Jepsen |
| Deterministic simulation testing (DST) | Your *actual code* over randomized, replayable executions | FoundationDB (Flow), TigerBeetle, FrostDB (patched Go runtime), Rust MadSim, Antithesis (custom hypervisor) |

## Worked Example
**The distributed-lock corruption bug (Figures 9-4 to 9-6) — a real bug HBase used to have.**

Goal: only one client at a time may write a file in a storage service, so clients take a lease from a lock service first.

*Failure 1 (process pause).* Client 1 holds the lease, then pauses for too long — a GC pause, a VM suspend, whatever. The lease expires. Client 2 acquires the lease and starts writing. Client 1 resumes, still believing its lease is valid, and continues writing. Split brain; the file is corrupted.

*Failure 2 (delayed request).* No pause at all — client 1 simply crashes. Just before crashing it sent a write request that gets stuck in the network for a minute. By the time it arrives, client 1's lease has timed out, client 2 has acquired the lease and written. The delayed write lands anyway. Same corruption.

*The fix.* The lock service returns an increasing **fencing token** with each grant. Client 1 holds token 33 and pauses. Client 2 acquires the lease with token 34, writes to storage including its token. Client 1 revives and sends its write with token 33. The storage service has already processed token 34, so it **rejects** the token-33 write. Both zombies and delayed requests are fenced off, permanently — unlike an OCC conflict, this rejection is never retried into success.

*Extension to replicas.* If storage is a leaderless replicated store with LWW, embed the token in the top digits of the timestamp: client 2's timestamps all start with `34…`, client 1's with `33…`. Client 2 writes to a quorum but can't reach replica 3, so the zombie's write may succeed there — harmless, because a quorum read prefers the `34…` value and read repair overwrites the stale one.

## Key Takeaways
1. If you send a request and get no response, it is **impossible** to distinguish a lost request, a dead node, and a lost response. Design for that, and prefer idempotent operations.
2. Use monotonic clocks for durations and timeouts; never use time-of-day clocks to order events across nodes. Use logical clocks / version vectors for causality.
3. If you must rely on synchronized clocks, get a confidence interval (TrueTime, ClockBound) and monitor cluster clock offsets, removing drifting nodes — bad clocks fail silently and cause data loss, not crashes.
4. Assume any thread can pause for tens of seconds at any line. Never assume that the state you checked is still true when you act on it.
5. Protect single-owner resources with fencing tokens, not just leases. Reject writes carrying an outdated token, or use conditional writes.
6. Make major decisions by quorum, not by any single node's opinion — including the decision to declare a node dead.
7. Assume nodes are unreliable but honest. Byzantine fault tolerance is impractical for server-side data systems; but do add cheap guards against weak lying: application-level checksums (or TLS) against corrupt packets that evade TCP checksums, input sanitization, and multiple NTP servers so an outlier server is excluded.
8. Choose the partially synchronous, crash-recovery model, keep safety properties unconditional and allow caveats only on liveness, and verify with a combination of model checking, fault injection, and deterministic simulation testing.
9. Bounded delays and hard real-time guarantees *are* achievable (RTOS, static resource partitioning, circuit switching) — but they cost utilization and money, which is why almost nobody buys them.

## Connects To
- **Ch 5 / Ch 6 (Replication)**: leader election, split brain, and LWW conflict resolution are exactly the mechanisms this chapter shows to be fragile. Rolling upgrades are the payoff of tolerating partial failure.
- **Ch 7 (Sharding)**: network partitions have nothing to do with data partitioning; but false failure detection is what makes automatic rebalancing dangerous.
- **Ch 8 (Transactions)**: unbounded delay and process pauses are why 3PC can't deliver nonblocking atomic commit; Spanner's TrueTime waiting implements distributed snapshot isolation; the optimistic-vs-pessimistic distinction reappears in fencing.
- **Ch 10 (Consistency and Consensus)**: the solutions — quorum-based consensus, leader leases with terms/ballots, and the lock services (ZooKeeper, etcd, Chubby) that issue fencing tokens.
- **Ch 12 (Stream Processing)**: durable execution and workflow engines depend on determinism; "real-time" there means low-latency streaming, not hard deadlines.
- **Lamport et al., "The Byzantine Generals Problem"**; **Saltzer, Reed & Clark, "End-to-End Arguments in System Design"** (why only an application-level response confirms success); **Bailis & Kingsbury, "The Network Is Reliable"** (the empirical fault catalogue).
