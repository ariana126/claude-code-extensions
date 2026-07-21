# Chapter 13: Concurrency

## Core Idea
Concurrency is a decoupling strategy — it separates *what* gets done from *when* it gets done — but correct concurrent code is hard even for trivial problems, so defend it structurally: separate thread-aware code from thread-ignorant POJOs, shrink shared data and critical sections to the minimum, know your library and the standard execution models, and test by jiggling execution order across many configurations and platforms.

## Frameworks Introduced

- **Single Responsibility Principle (for concurrency)**: Concurrency design is complex enough to be a reason to change in its own right, and therefore deserves to be separated from the rest of the code.
  - When to use: Any system with more than one thread.
  - How:
    1. Recognize that concurrency-related code has its own life cycle of development, change, and tuning, and its own challenges — different from and often harder than nonconcurrent code.
    2. Break the system into POJOs that know nothing of threading, plus separate classes that control the threading.
    3. When testing thread-aware code, test *only* that — which implies the thread-aware code must be small and focused.
  - **Recommendation: Keep your concurrency-related code separate from other code.**
  - Why it works / failure mode: The number of ways miswritten concurrency code can fail is challenging enough without the added burden of surrounding application code. Embedding concurrency details directly in production code is the common failure.

- **Corollary: Limit the Scope of Data**: The more places shared data can get updated, the more likely you forget to protect one (breaking all code that modifies it), the more duplication of guarding effort (a DRY violation), and the harder it is to locate failures.
  - **Recommendation: Take data encapsulation to heart; severely limit the access of any data that may be shared.**

- **Corollary: Use Copies of Data**: Avoid sharing data in the first place — copy objects and treat them read-only, or collect results from multiple threads in per-thread copies and merge them in a single thread. If copying lets you avoid synchronizing, the savings from avoiding the intrinsic lock will likely make up for the extra creation and GC overhead.

- **Corollary: Threads Should Be as Independent as Possible**: Write each thread so it exists in its own world, sharing no data with any other thread; each processes one client request, all required data from an unshared source stored in local variables.
  - **Recommendation: Attempt to partition data into independent subsets that can be operated on by independent threads, possibly in different processors.**

- **Know Your Library**: Use the provided thread-safe collections; use the executor framework for executing unrelated tasks; use nonblocking solutions when possible; remember several library classes are not thread safe.
  - **Recommendation: Review the classes available to you. In the case of Java, become familiar with `java.util.concurrent`, `java.util.concurrent.atomic`, `java.util.concurrent.locks`.**
  - Concrete: `ConcurrentHashMap` performs better than `HashMap` in nearly all situations, allows simultaneous concurrent reads and writes, and supports composite operations that are otherwise not thread safe — on Java 5, start with it.

- **Know Your Execution Models**: Learn Producer-Consumer, Readers-Writers, and Dining Philosophers; most concurrent problems you encounter will be a variation of these three.
  - **Recommendation: Learn these basic algorithms and understand their solutions.**

- **Beware Dependencies Between Synchronized Methods**: `synchronized` protects an individual method; if there is more than one synchronized method on the same shared class, the system may be written incorrectly.
  - **Recommendation: Avoid using more than one method on a shared object.** When you must, use exactly one of the three fixes (Client-Based Locking, Server-Based Locking, Adapted Server).

- **Keep Synchronized Sections Small**: Locks create delays and add overhead, so don't litter code with `synchronized`; but critical sections must be guarded, so design for as few critical sections as possible. Extending synchronization beyond the minimal critical section increases contention and degrades performance.
  - **Recommendation: Keep your synchronized sections as small as possible.**

- **Testing Threaded Code**: Proving correctness is impractical; testing does not guarantee it — but good testing minimizes risk.
  - **Recommendation: Write tests that have the potential to expose problems and then run them frequently, with different programmatic configurations and system configurations and load. If tests ever fail, track down the failure. Don't ignore a failure just because the tests pass on a subsequent run.**
  - How (the seven fine-grained rules):
    1. Treat spurious failures as candidate threading issues — *do not ignore system failures as one-offs*.
    2. Get your nonthreaded code working first — don't chase nonthreading and threading bugs at the same time.
    3. Make your threaded code pluggable — runnable with one thread, several threads, varying counts; against real collaborators or test doubles; with doubles that run fast, slow, or variably; for a configurable number of iterations.
    4. Make your threaded code tunable — time performance under different configurations, allow thread count to change easily, possibly at runtime, possibly self-tuning on throughput and utilization.
    5. Run with more threads than processors — task swapping is what exposes missing critical sections and deadlock.
    6. Run on different platforms — *run your threaded code on all target platforms early and often*; the JVM does not guarantee preemptive threading and OS threading policies differ.
    7. Instrument your code to try and force failures — *use jiggling strategies to ferret out errors*.

## Key Concepts
- **Bound Resources**: Resources of a fixed size or number used in a concurrent environment (e.g., database connections, fixed-size read/write buffers).
- **Mutual Exclusion**: Only one thread may access shared data or a shared resource at a time.
- **Starvation**: One thread or a group of threads is prohibited from proceeding for an excessively long time or forever (e.g., always letting quick-to-execute threads run first can starve long-running ones).
- **Deadlock**: Two or more threads each waiting for the others to finish, so none can proceed.
- **Livelock**: Threads in lockstep, each trying to work but finding another "in the way"; due to resonance, threads continue trying to make progress but cannot for an excessively long time or forever.
- **Critical section**: Any section of code that must be protected from simultaneous use for the program to be correct.
- **Jiggling**: Instrumenting code with `wait()`, `sleep()`, `yield()`, `priority()` so threads run in different orderings at different times, raising the odds a rare failing path is taken.
- **Concurrency as decoupling**: Separating *what* gets done from *when* it gets done; structurally the app becomes many little collaborating computers rather than one big main loop.

## Mental Models
- Think of **objects as abstractions of processing, threads as abstractions of schedule** (Coplien).
- Use **"how many execution paths does this line have?"** as the reality check: `return ++lastIdUsed;` has 12,870 possible byte-code execution paths for two threads — 2,704,156 if the field is a `long`.
- Think of a **Servlet as its own machine**: it receives everything as parameters to `doGet`/`doPost`, so if it uses only local variables it cannot cause synchronization problems — until it touches a shared resource like a DB connection.
- Use **"one-offs do not exist"** as the debugging stance: the longer a "cosmic ray" failure is ignored, the more code is built on a faulty approach.
- Think of **shutdown as its own hard project** — budget for it early, because it will take longer than you expect.

## Anti-patterns
- **Embedding concurrency details in application code**: Violates SRP for threads; makes both concerns untestable in isolation.
- **Large critical sections**: The naive attempt to have "as few `synchronized` statements as possible" by making each huge — increases contention and degrades performance.
- **Multiple synchronized methods on one shared object, called in sequence**: Each call is individually safe; the sequence is not.
- **Calling one locked section from another**: A direct route to deadlock.
- **Writing off intermittent failures as one-offs**: Threading bugs may surface once in a thousand or a million executions; dismissing them lets the faulty approach spread.
- **Leaving hand-inserted `yield()`/`sleep()` in production**: Unnecessarily slows the code; instrumentation belongs behind a test-time switch.
- **Believing the myths**: that concurrency always improves performance (it helps only when there is significant wait time to share between threads/processors); that design doesn't change under concurrency (it changes remarkably); that a Web/EJB container means you needn't understand concurrency (you'd better know what your container does and how to guard against concurrent update and deadlock).

## Code Examples

The race, in three lines:

```java
   public class X {
      private int lastIdUsed;
      public int getNextId() {
           return ++lastIdUsed;
       }
   }
```

Hand-coded jiggling:

```java
    public synchronized String nextUrlOrNull() {
        if(hasNext()) {
            String url = urlGenerator.next();
            Thread.yield(); // inserted for testing.
            updateHasNext();
            return url;
        }
        return null;
    }
```

Automated jiggling — a no-op in production, randomized in test:

```java
   public class ThreadJigglePoint {
       public static void jiggle() {
       }
   }

   public synchronized String nextUrlOrNull() {
     if(hasNext()) {
         ThreadJiglePoint.jiggle();
         String url = urlGenerator.next();
         ThreadJiglePoint.jiggle();
         updateHasNext();
         ThreadJiglePoint.jiggle();
         return url;
     }
     return null;
   }
```

- **What it demonstrates**: If jiggling breaks the code, the `yield()` did not break it — the code was already broken and jiggling made the failure evident. Two `ThreadJigglePoint` implementations (no-op for production, random sleep/yield/fall-through for test) let you run a thousand randomized orderings; IBM's ConTest does this with more sophistication.

## Reference Tables

**Execution-model definitions**

| Term | Definition |
|---|---|
| **Bound Resources** | Resources of a fixed size or number used in a concurrent environment — e.g. database connections, fixed-size read/write buffers. |
| **Mutual Exclusion** | Only one thread can access shared data or a shared resource at a time. |
| **Starvation** | One thread or a group of threads is prohibited from proceeding for an excessively long time or forever. |
| **Deadlock** | Two or more threads waiting for each other to finish; each waits for a resource the other holds, so none can proceed. |
| **Livelock** | Threads in lockstep, each trying to do work but finding another "in the way"; they keep trying but make no progress. |

**The three execution models**

| Model | Shape | Core difficulty |
|---|---|---|
| **Producer-Consumer** | One or more producers create work and place it in a buffer or queue; one or more consumers acquire and complete it. The queue is a **bound resource**. | Producers must wait for free space; consumers must wait for content. Coordination is via signaling — producers signal "no longer empty," consumers signal "no longer full"; both potentially wait to be notified. |
| **Readers-Writers** | A shared resource primarily serving readers, occasionally updated by writers. | Balancing correctness, throughput, and starvation. Making writers wait for zero readers starves writers under continuous readers; prioritizing frequent writers destroys throughput and blocks many readers for long periods; emphasizing throughput causes starvation and stale information. |
| **Dining Philosophers** | Philosophers (threads) around a table need two forks (resources) to eat; a fork sits between each pair. | Processes competing for resources; without careful design, deadlock, livelock, and throughput/efficiency degradation. |

**Three fixes for dependencies between synchronized methods**

| Technique | How |
|---|---|
| **Client-Based Locking** | The client locks the server before calling the first method and keeps the lock's extent covering the code calling the last method. |
| **Server-Based Locking** | Within the server, create a method that locks the server, calls all the methods, then unlocks; have the client call the new method. |
| **Adapted Server** | Create an intermediary that performs the locking — server-based locking for the case where the original server cannot be changed. |

## Worked Example

**The shared-counter race.** Create one instance of `X`, set `lastIdUsed` to 42, share it between two threads, and have both call `getNextId()`. Three outcomes are possible:

- Thread one gets 43, thread two gets 44, `lastIdUsed` is 44.
- Thread one gets 44, thread two gets 43, `lastIdUsed` is 44.
- **Thread one gets 43, thread two gets 43, `lastIdUsed` is 43.**

The third — the surprising one — happens when the two threads step on each other. `return ++lastIdUsed;` is a single line of Java but many byte-codes, and the two threads can interleave across them. Counting only generated byte-code, there are **12,870** possible execution paths for two threads through `getNextId`. Change `lastIdUsed` from `int` to `long` and the count rises to **2,704,156**. Most paths give valid results; the whole problem is that *some of them don't* — and the failing ones are rare enough to look like cosmic rays in production.

**Shutdown deadlock.** A parent thread spawns children and waits for all to finish before releasing resources. If one child deadlocks, the parent waits forever. Worse: on a shutdown signal, a producer child shuts down quickly while its consumer partner is blocked waiting for a message that will never come — so the consumer never sees the shutdown signal, never finishes, and the parent never finishes either.

## Key Takeaways
1. Separate thread-aware code from thread-ignorant POJOs; concurrency is its own reason to change, so it gets its own classes.
2. Shrink the surface: severely limit access to shared data, prefer copies over sharing, and partition work so threads are as independent as possible.
3. Learn `java.util.concurrent`, `.atomic`, and `.locks`; prefer thread-safe collections (`ConcurrentHashMap`), the executor framework for unrelated tasks, and nonblocking solutions.
4. Learn Producer-Consumer, Readers-Writers, and Dining Philosophers — nearly every real problem is a variant, and you should know the terms Bound Resources, Mutual Exclusion, Starvation, Deadlock, and Livelock precisely.
5. Avoid calling more than one method on a shared object; if you must, pick Client-Based Locking, Server-Based Locking, or an Adapted Server deliberately.
6. Keep synchronized sections as small as the true critical section — no smaller, no larger — and never call a locked section from another.
7. Get shutdown working early; it is harder and slower than you expect.
8. Test by running with more threads than processors, on every target platform, in many configurations, repeatedly — and instrument with jiggling (hand-coded or via a `ThreadJigglePoint`/aspect/ConTest) to force rare orderings.
9. Never write off an intermittent failure as a one-off.

## Connects To
- **Ch 11 (Systems)**: Same POJO-plus-framework separation; threading is another cross-cutting concern to keep out of domain logic.
- **Ch 12 (Emergence)**: Pluggability and testability come naturally from the Three Laws of TDD, which is what makes many-configuration testing possible.
- **Ch 9 (Unit Tests)**: Threaded tests must be run frequently and never ignored when they fail.
- **Appendix A "Concurrency II"**: The deeper tutorial — Client/Server Example, Possible Paths of Execution, Dependencies Between Methods Can Break Concurrent Code, Increasing Throughput, Deadlock.
- **Doug Lea, *Concurrent Programming in Java***: Origin of the `java.util.concurrent` collections.
- **IBM ConTest**: Tooling for systematic execution-order perturbation.
