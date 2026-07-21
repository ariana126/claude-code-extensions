# Appendix A: Concurrency II (by Brett L. Schuchert)

## Core Idea
Amplifies Chapter 13. Concurrency is a throughput tool for I/O-bound systems, not a speed-up for CPU-bound ones; the discipline that keeps concurrent code clean is to isolate *all* thread management behind one abstraction and to push locking into the server, never the client.

## Frameworks Introduced

- **Isolate the threading policy behind one interface (SRP for concurrency)**
  - When to use: the moment you add threading to any server, handler, or pipeline.
  - How: name the responsibilities the class currently holds (socket connection management, client processing, threading policy, shutdown policy); give each its own class; funnel all thread creation into a single `ClientScheduler`-style abstraction.
  - Why it works: when there is a concurrency bug, there is exactly one place to look, and swapping `ThreadPerRequestScheduler` for `ExecutorClientScheduler` is a new class plus a wiring change. Failure mode: leaving thread creation inline in `process()` — the class then has four reasons to change and every other responsibility becomes untestable without threads.

- **Server-Based Locking (preferred) vs Client-Based Locking**
  - When to use: any time a client must call two methods on a shared object to complete one logical operation (`hasNext()` then `next()`), because per-method `synchronized` does not make that pair atomic.
  - How: change the server's API to be multithread-aware — collapse the pair into one synchronized method (`getNextOrNull()` returning `null` instead of a separate `hasNext()`).
  - Why it works: five reasons — reduces repeated code, allows better performance (swap in a non-thread-safe server for single-threaded deployment), reduces the possibility of error, enforces a single policy, reduces the scope of shared variables.
  - Failure mode of the alternative: "Client-based locking really blows." One programmer forgetting one `synchronized` block produced a ring-buffer corruption that took weeks of reading assembly listings to find (Local 705, Chicago, 1971).

- **Adapted Server** (the ADAPTER escape hatch)
  - When to use: you need server-based locking but do not own the server code.
  - How: wrap the unsafe class in your own class exposing only synchronized, multithread-aware operations. Better yet, use the thread-safe collections with extended interfaces.

- **Deadlock: four necessary conditions, break any one**
  - Mutual Exclusion, Lock & Wait, No Preemption, Circular Wait. All four must hold; break one and deadlock is impossible.

- **Testing multithreaded code**
  - Monte Carlo testing — make the test tunable, run it repeatedly on every target deployment platform, continuously, under varying and production-like loads. The longer it runs green, the more likely either the code is correct *or* the tests are inadequate.
  - Instrument with **ConTest** (IBM): failure rate improved from ~1 in 10,000,000 iterations to ~1 in 30.

## Key Concepts
- **Atomic operation**: any operation that is uninterruptible. Assignment to a 32-bit value is atomic per the Java Memory Model; assignment to a 64-bit value is *two* 32-bit assignments and is not. `++` is **not** atomic.
- **Frame**: per-invocation record holding the return address, parameters, and local variables.
- **Local variable**: any variable in method scope; every nonstatic method has at least `this`.
- **Operand stack**: the LIFO stack where JVM instruction parameters are placed.
- **Compare and Swap (CAS)**: an atomic processor operation — verify the variable still holds the last known value, set it if so, retry if not. Optimistic locking, versus `synchronized`'s pessimistic locking.
- **Future**: a handle to a computation submitted to an `ExecutorService`; `get()` blocks until it completes.
- **Callable**: like `Runnable` but returns a result.
- **Starvation**: a thread persistently unable to acquire the combination of resources it needs (low CPU utilization).
- **Livelock**: threads in lockstep repeatedly acquiring and releasing one resource each (high, useless CPU utilization).
- **Circular wait / deadly embrace**: T1 holds R1 and wants R2; T2 holds R2 and wants R1.

## Mental Models
- **Use threads when the bottleneck is I/O, not the processor.** Adding threads to a processor-bound problem does not make it faster — there are only so many CPU cycles. When one part waits on I/O, another can use that time.
- **Think of every non-atomic line as a shuffled deck.** One line, `return ++lastIdUsed;`, compiles to 8 bytecodes; with 2 threads that is **12,870** possible interleavings. Make `lastIdUsed` a `long` and it becomes **2,704,156**. Add `synchronized` and it drops to **2** (N! in the general case).
- **Think of thread-safe methods as not composing.** `containsKey` then `put` are each safe; the pair is not. The same for `hasNext`/`next`.
- **Synchronize as little as possible, not as much as possible.** In `PageIterator`, only `getNextPageOrNull` is synchronized — the expensive `getPageFor` is left open so I/O overlaps.

## Anti-patterns
- **Thread creation inline in business logic**: violates SRP; four responsibilities in one `process()` method; makes non-concurrency code impossible to test without threads.
- **Unbounded thread creation**: `new Thread(...)` per request with no limit will hit the JVM's ceiling and grind to a halt under public-net load.
- **Assuming `++` is atomic**: the most common misconception; it is read-modify-write.
- **Tolerating the failure** (catching the exception and cleaning up): "rather like cleaning up memory leaks by rebooting at midnight."
- **Client-based locking on a widely-used shared resource**: one missed lock among hundreds of call sites = a bug that surfaces once a day at random.
- **Adding debug statements to find a deadlock**: the debug code changes timing, the deadlock "disappears," and the debug code stays in as the "fix."
- **Using non-thread-safe classes as if they were safe**: `SimpleDateFormat`, database connections, `java.util` containers, Servlets.

## Code Examples

Threading policy isolated — the server run loop knows nothing about threads:
```java
public void run() {
  while (keepProcessing) {
    try {
      ClientConnection clientConnection = connectionManager.awaitClient();
      ClientRequestProcessor requestProcessor
        = new ClientRequestProcessor(clientConnection);
      clientScheduler.schedule(requestProcessor);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
  connectionManager.shutdown();
}
```

Swapping the policy = one new class (Listing A-1):
```java
public class ExecutorClientScheduler implements ClientScheduler {
    Executor executor;
    public ExecutorClientScheduler(int availableThreads) {
        executor = Executors.newFixedThreadPool(availableThreads);
    }
    public void schedule(final ClientRequestProcessor requestProcessor) {
        Runnable runnable = new Runnable() {
            public void run() {
                requestProcessor.process();
            }
        };
        executor.execute(runnable);
    }
}
```
- **What it demonstrates**: SRP applied to concurrency; the Executor framework replacing hand-rolled `new Thread`.

Client-Based Locking — works, but every client must remember:
```java
IntegerIterator iterator = new IntegerIterator();
while (true) {
  int nextValue;
  synchronized (iterator) {
    if (!iterator.hasNext())
      break;
    nextValue = iterator.next();
  }
  doSometingWith(nextValue);
}
```

Server-Based Locking — the API itself becomes multithread-aware:
```java
public class IntegerIteratorServerLocked {
    private Integer nextValue = 0;
    public synchronized Integer getNextOrNull() {
        if (nextValue < 100000)
            return nextValue++;
        else
           return null;
    }
}
```
```java
while (true) {
    Integer nextValue = iterator.getNextOrNull();
    if (next == null)
        break;
    // do something with nextValue
}
```
- **What it demonstrates**: collapsing a two-call protocol into one atomic call removes the duplication *and* the possibility of client error.

Adapted Server, when you don't own the code:
```java
public class ThreadSafeIntegerIterator {
    private IntegerIterator iterator = new IntegerIterator();
    public synchronized Integer getNextOrNull() {
        if(iterator.hasNext())
            return iterator.next();
        return null;
    }
}
```

Future + Callable — overlap remote I/O with local work:
```java
public String processRequest(String message) throws Exception {
    Callable<String> makeExternalCall = new Callable<String>() {
        public String call() throws Exception {
            String result = "";
            // make external request
            return result;
        }
    };
    Future<String> result = executorService.submit(makeExternalCall);
    String partialResult = doSomeLocalProcessing();
    return result.get() + partialResult;
}
```

Non-blocking update via Atomic classes (CAS) instead of `synchronized`:
```java
public class ObjectWithValue {
    private AtomicInteger value = new AtomicInteger(0);
    public void incrementValue() {
        value.incrementAndGet();
    }
    public int getValue() {
        return value.get();
    }
}
```
- **What it demonstrates**: optimistic detect-and-retry, almost always cheaper than acquiring a lock even under moderate-to-high contention.

Logically, CAS is:
```java
int variableBeingSet;
void simulateNonBlockingSet(int newValue) {
    int currentValue;
    do {
       currentValue = variableBeingSet
    } while(currentValue != compareAndSwap(currentValue, newValue));
}
int synchronized compareAndSwap(int currentValue, int newValue) {
    if(variableBeingSet == currentValue) {
        variableBeingSet = newValue;
        return currentValue;
    }
    return variableBeingSet;
}
```

## Reference Tables

### Client-Based vs Server-Based Locking

| | Client-Based Locking | Server-Based Locking | Adapted Server |
|---|---|---|---|
| Where the lock lives | In every client, around a multi-call sequence | Inside the server, in one API method | In a wrapper you own |
| Repeated code | Duplicated at every call site | None | None |
| Error surface | One forgotten lock breaks everything | Single point of policy | Single point of policy |
| Performance | Cannot swap in an unsynchronized server | Can swap in a non-thread-safe server for single-threaded deployment | Same as server-based |
| Scope of shared variables | Visible to clients | Hidden in server | Hidden in wrapper |
| Use when | You cannot change the server *and* cannot wrap it | You own the server — **default choice** | You don't own the server code |

### Thread-safety of common Java types

| Not thread safe | Thread-safe alternative |
|---|---|
| `SimpleDateFormat` | Per-thread instance |
| Database connections | Pool, one per thread of work |
| `java.util` containers (`HashTable` multi-call sequences) | `java.util.concurrent` collections |
| Servlets | Avoid mutable instance state |
| `synchronized` counter | `AtomicBoolean`, `AtomicInteger`, `AtomicReference` |

Three cures for the `containsKey`-then-`put` race:
1. **Lock the `HashTable`** — `synchronized(map) { if (!map.containsKey(key)) map.put(key, value); }`
2. **Wrap it** (ADAPTER) — `WrappedHashtable.putIfAbsent(K, V)` marked `synchronized`
3. **Use the thread-safe collections** — `ConcurrentHashMap.putIfAbsent(key, value)`. The `java.util.concurrent` collections provide exactly these compound operations.

### Executor Framework

| Piece | Role |
|---|---|
| `Executor` / `ExecutorService` | Sophisticated thread pool with queueing and priorities; use it instead of hand-rolling `new Thread` |
| `Executors.newFixedThreadPool(n)` | Bounded pool — caps concurrency, avoiding unbounded thread creation |
| `Runnable` | Unit of work, no result |
| `Callable<T>` | Unit of work that returns a result |
| `Future<T>` | Handle to the pending result; `get()` blocks until complete |
| `CompletionService` | Consume futures in completion order rather than submission order |

### Deadlock: the four conditions and how to break them

| Condition | Meaning | How to break it | Cost |
|---|---|---|---|
| **Mutual Exclusion** | Resource cannot be shared and is limited in number | Use simultaneously-usable resources (e.g. `AtomicInteger`); increase resource count to ≥ thread count; check all resources are free before seizing any | Most resources are genuinely limited |
| **Lock & Wait** | Thread holds resources while waiting for more | Refuse to wait: check before seizing, release everything and start over if busy | Starvation, livelock; but almost always implementable as a last resort |
| **No Preemption** | Threads can't take resources from each other | Request mechanism: ask the owner to release; owner that is itself waiting releases all and restarts | Managing the requests is tricky |
| **Circular Wait** | Deadly embrace — T1 has R1 wants R2, T2 has R2 wants R1 | **Most common approach**: agree a global ordering of resources and always allocate in that order | Resources held longer than needed; impossible when resource 2's identity depends on operating on resource 1 |

### Related library primitives (Ch 13 "Know Your Library")
`ReentrantLock` (a lock acquirable in one method and released in another) · `Semaphore` (a counting lock with N permits) · `CountDownLatch` (releases all waiting threads after a set number of events, so all start together).

## Worked Example
**The client/server throughput problem, end to end.**
1. A single-threaded server accepts a socket, calls `process(socket)`, then loops. A test asserts `@Test(timeout = 10000)` that a batch of client requests completes in ten seconds — a throughput validation.
2. The test fails. Diagnose *where* the time goes: I/O-bound (sockets, DB, VM swap) or processor-bound (calculation, regex, GC). Only the I/O-bound case benefits from threads.
3. Naive fix: wrap the body of `process` in a `Runnable` and `new Thread(...).start()`. The test now passes in just over one second — but the server now has four responsibilities and no limit on threads.
4. Clean fix: extract `ConnectionManager`, `ClientRequestProcessor`, and a `ClientScheduler` interface. `ThreadPerRequestScheduler` reproduces the naive behavior; `ExecutorClientScheduler` with `newFixedThreadPool(n)` bounds it. Only one class ever touches threads.

**The throughput arithmetic** (page-reader example): 1 s I/O to fetch a page, 0.5 s CPU to parse it, I/O uses 0% CPU and parsing 100%. Single-threaded: 1.5 s per page. With three threads, each 1-second read overlaps two parses, so the CPU is fully utilized: **2 pages/second — three times the single-threaded throughput.**

## Key Takeaways
1. Add threads only when the bottleneck is I/O; a processor-bound problem gains nothing from more threads.
2. Keep thread management in a few well-controlled places, and let that code do *nothing* but thread management.
3. Prefer server-based locking to client-based locking; if you don't own the server, adapt it.
4. Individually synchronized methods do not compose — any two-call protocol on shared state is a race.
5. `++` is not atomic; 64-bit assignment is not atomic. One innocuous line has 12,870 interleavings with two threads.
6. Use `java.util.concurrent` — `Executor`/`Future`/`CompletionService` for scheduling, `ConcurrentHashMap.putIfAbsent` for compound operations, `Atomic*` for non-blocking CAS updates.
7. Deadlock needs all four of mutual exclusion, lock & wait, no preemption, and circular wait; imposing a global resource ordering (breaking circular wait) is the usual cure.
8. Threading bugs surface once in millions of iterations — run Monte Carlo tests on every target platform under load, and instrument with a tool like ConTest.
9. Isolating the thread-related part of the solution is what makes tuning and experimentation possible at all. TANSTAAFL — every deadlock strategy costs something.

## Connects To
- **Ch 13 (Concurrency)**: this appendix supports and amplifies it; `ReentrantLock`, `Semaphore`, `CountDownLatch` and the "Know Your Library" material live there.
- **Ch 10 (Classes) / SRP**: the entire "isolate threading policy" argument.
- **Ch 17 G26 Be Precise**: "avoiding locks because you don't think concurrent update is likely is lazy at best."
- **GOF ADAPTER**: the Adapted Server and `WrappedHashtable`.
- **Doug Lea, _Concurrent Programming in Java: Design Principles and Patterns_**: the recommended next step.
- **Java Memory Model / JVM spec**: atomicity guarantees for 32-bit vs 64-bit assignment.
- **IBM ConTest**: bytecode instrumentation to surface interleaving bugs.
