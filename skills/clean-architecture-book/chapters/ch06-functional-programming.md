# Chapter 6: Functional Programming

## Core Idea
Variables in functional languages do not vary — and since **all race conditions, deadlock conditions, and concurrent update problems are due to mutable variables**, immutability is an architectural concern, not a stylistic one. Where full immutability is impractical, segregate mutability and push as much processing as possible into the immutable components.

## Frameworks Introduced
- **Segregation of Mutability**
  - When to use: the most common compromise whenever infinite storage and infinite processor speed are unavailable — that is, always.
  - How: segregate the application, or the services within it, into mutable and immutable components. Immutable components perform their tasks in a purely functional way, using no mutable variables. They communicate with one or more components that are not purely functional and allow variable state to be mutated. Protect those mutable variables with **transactional memory**, which treats variables in memory the same way a database treats records on disk — a transaction- or retry-based scheme. Then push as much processing as possible into the immutable components and drive as much code as possible *out* of the components that must allow mutation.
  - Why it works / failure mode: you cannot have a race condition or concurrent update problem if no variable is ever updated, and you cannot have deadlocks without mutable locks — so shrinking the mutable region shrinks the entire class of concurrency bugs. Failure mode: Clojure's `atom` facility is adequate for simple applications but cannot completely safeguard against concurrent updates and deadlocks when multiple *dependent* variables come into play; those cases need more elaborate facilities.
- **Event Sourcing**
  - When to use: when storage and processing power are sufficient for the reasonable lifetime of the application — increasingly the normal case, given processors executing billions of instructions per second and billions of bytes of RAM.
  - How: store the transactions, not the state. When state is required, apply all the transactions from the beginning of time. Take shortcuts where needed — compute and save the state every midnight, then compute only the transactions since midnight. Nothing is ever deleted or updated from the store.
  - Why it works / failure mode: applications become **CR, not CRUD**; because neither updates nor deletions occur in the data store, there cannot be any concurrent update issues. With enough storage and processor power, applications become entirely immutable and therefore *entirely functional*. Failure mode: unbounded transaction growth — the naive version needs infinite storage and infinite processing power to work forever, which is why the snapshot shortcut exists.
- **Compare and Swap** (the discipline behind `swap!`)
  - How: read the value, pass it to the update function; when the function returns, lock the variable and compare it to the value that was passed in. If the same, store the returned value and release the lock. Otherwise release the lock and retry the strategy from the beginning.

## Key Concepts
- **Immutability**: the values of symbols do not change; the foundational notion of λ-calculus, invented by Alonzo Church in the 1930s.
- **Mutable variable**: a variable that changes state during execution — e.g. the Java loop control variable `i`; the Clojure version has none.
- **Transactional memory**: protection of in-memory variables by transaction- or retry-based schemes, as a database protects records on disk.
- **`atom`**: in Clojure, a special kind of variable whose value may mutate only under very disciplined conditions enforced by the `swap!` function.
- **Event sourcing**: a strategy wherein we store the transactions, but not the state.
- **CR (not CRUD)**: the shape of an event-sourced application — creates and reads only, no updates or deletes.
- **Lazy evaluation**: no element of a never-ending list is evaluated until it is accessed, so only the first 25 elements of an infinite list are actually created.
- **The three disciplines**: structured programming is discipline imposed upon direct transfer of control; object-oriented programming upon indirect transfer of control; functional programming upon variable assignment.

## Mental Models
- Think of immutability as concurrency insurance: the question is never "is immutability elegant?" but "is immutability practicable?" — and the answer is yes, if certain compromises are made.
- Use the storage/CPU budget as the dial. Immutability is unconditionally practicable given infinite storage and infinite processor speed; the more memory we have and the faster our machines are, the less we need mutable state.
- Think of event sourcing as something you already trust: this is precisely the way your source code control system works.
- Treat each paradigm as a subtraction. Each has taken something away, each restricts some aspect of how we write code, and none has added to our power or capabilities. What we have learned over the last half-century is *what not to do*.

## Anti-patterns
- **Storing state instead of transactions**: forces mutation, and with it the entire family of concurrent update problems.
- **Sprinkling mutation through the codebase**: leaves you unable to reason about which components are exposed to concurrency; well-structured applications are segregated into those components that mutate variables and those that do not.
- **Relying on `atom`-style single-variable protection for dependent state**: it cannot fully safeguard against concurrent updates and deadlocks once multiple dependent variables interact.
- **Assuming software is a rapidly advancing technology**: the rules of software are the same today as in 1946 when Turing wrote the first code to execute in an electronic computer. Tools and hardware changed; the essence did not.

## Code Examples

The mutable version — `i` changes state during execution:

```java
public class Squint {
  public static void main(String args[]) {
    for (int i=0; i<25; i++)
      System.out.println(i*i);
  }
}
```

The functional version — `x` is initialized but never modified:

```clojure
(println ;___________________ Print
  (take 25 ;_________________ the first 25
    (map (fn [x] (* x x)) ;__ squares
      (range)))) ;___________ of Integers
```

Disciplined mutation via transactional memory:

```clojure
(def counter (atom 0)) ; initialize counter to 0
(swap! counter inc)    ; safely increment counter.
```

- **What it demonstrates**: the Java program's only essential difference is the mutable loop-control variable; where mutation is genuinely required, `swap!` confines it to a compare-and-swap discipline rather than free assignment.

## Reference Tables

| Paradigm | Discipline imposed upon | Capability removed |
|---|---|---|
| Structured programming | direct transfer of control | `goto` |
| Object-oriented programming | indirect transfer of control | function pointers |
| Functional programming | variable assignment | assignment |

| Approach | Stores | Concurrency exposure | Cost |
|---|---|---|---|
| Mutable state | current balance | races, deadlocks, concurrent updates | cheap storage, cheap reads |
| Event sourcing (naive) | every transaction forever | none (CR only) | unbounded storage and compute |
| Event sourcing + snapshots | transactions + nightly state | none | bounded compute; large but affordable storage |

## Worked Example
The banking balance. A conventional application maintains customers' account balances and *mutates* them as deposit and withdrawal transactions execute. The functional alternative: store only the transactions. When anyone wants a balance, add up all the transactions for that account from the beginning of time. No mutable variables are required anywhere.

The objection is obvious — the transaction count grows without bound and the processing to total it becomes intolerable; making the scheme work *forever* needs infinite storage and infinite processing power. But perhaps we don't have to make it work forever, and perhaps we have enough of both for the reasonable lifetime of the application. Add the shortcut: compute and save the state every midnight, then when state is needed compute only the transactions since midnight. Offline storage has grown so fast that trillions of bytes now count as small.

The payoff is structural, not just tidy. Nothing is ever deleted or updated, so the application is CR rather than CRUD, and there cannot be any concurrent update issues at all. If this sounds absurd, note that it is precisely how your source code control system works.

## Key Takeaways
1. Every race condition, deadlock, and concurrent update problem traces back to a mutable variable — so treat mutability as an architectural budget item.
2. Segregate the system into immutable and mutable components, and push processing toward the immutable side.
3. Protect whatever must mutate with transactional memory, and know its limit: single-variable schemes break down on multiple dependent variables.
4. Consider event sourcing wherever storage and compute allow — storing transactions instead of state eliminates concurrent update issues by construction.
5. Snapshot periodically to bound the replay cost; you rarely need the scheme to work forever.
6. Remember the three subtractions: structured removes `goto`, OO removes function pointers, functional removes assignment. Software is sequence, selection, iteration, and indirection. Nothing more. Nothing less.

## Connects To
- **Ch 3**: "Functional programming imposes discipline upon assignment" — developed here in full.
- **Ch 4 and Ch 5**: the other two negative disciplines; this chapter closes the set.
- **Part III (Design Principles / SOLID)**: the shift from paradigm-level restriction to mid-level structure.
- **CQRS**: the read/write split that event sourcing is normally paired with in practice (Martin credits Greg Young for teaching them the event-sourcing concept).
- **Immutable value objects / persistent data structures**: the object-level application of the same discipline.
- **Version control systems**: the everyday, already-trusted instance of event sourcing.
