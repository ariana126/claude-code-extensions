# Cheatsheet — Khorikov's Decision Rules

## Should this test exist?

Score the four pillars and **multiply** — a zero anywhere means zero value.

| Pillar | Question |
|---|---|
| Protection against regressions | How much code, how complex, how domain-significant? |
| **Resistance to refactoring** | How many false positives? **Non-negotiable — max it out** |
| Fast feedback | How quickly does it run? |
| Maintainability | How big is it, and how many out-of-process deps must stay alive? |

- **If you can't trace the test back to a business requirement** → it's brittle. Restructure or delete it.
- **If the test would score zero on resistance to refactoring** → delete it. This metric is binary; you can't concede "a little."
- **If in doubt** → *it's better to not write a test at all than to write a bad test.*

## What kind of test, by code type?

| Complexity/domain significance | Collaborators | Type | Test with |
|---|---|---|---|
| High | Few | **Domain model & algorithms** | Unit tests — heavily. Best ROI |
| Low | Few | Trivial code | **Nothing** |
| Low | Many | Controllers | Integration tests — briefly |
| High | Many | Overcomplicated | **Refactor it out of existence** |

**Rule of thumb**: the more important or complex the code, the fewer collaborators it should have. Code is either *deep* or *wide*, never both.

## Mock or not?

```
Is it an out-of-process dependency?
├─ No  → NEVER mock (intra-system = implementation detail)
└─ Yes → Can other applications observe it?
         ├─ No  (managed: your own database)      → use the REAL instance; verify final STATE
         └─ Yes (unmanaged: bus, SMTP, 3rd party) → MOCK it; verify INTERACTIONS
                 └─ Mock the LAST type before it leaves your app
```

- **Stub?** Never assert on it. A call to a stub is a means, not an end.
- **Shared database (both managed and unmanaged)?** Mock the externally-visible tables (they act as a message bus, rows as messages); verify final state for the rest.
- **Can't run a real database?** Write **no** integration tests rather than mocking it.
- **Logging?** Mock `IDomainLogger`, not `ILogger` — exact log structure doesn't matter to its audience.
- **Reaching for `CallBase = true`?** You're violating SRP. Split the class instead.

## Testing style, in preference order

| Style | Resistance-to-refactoring diligence | Maintainability | Verdict |
|---|---|---|---|
| **Output-based** | Low | Low cost | Always prefer — requires pure functions |
| State-based | Medium | Medium | Second choice |
| Communication-based | Medium | High cost | Occasional only |

## Interfaces: introduce one?

- **Single implementation + not mocked** → No. It's not an abstraction; it's a YAGNI violation.
- **Single implementation + unmanaged dependency** → Yes, to enable mocking.
- **Managed dependency** → No. Inject the concrete class.
- **In-process/domain class (`IUser`)** → **Huge red flag.** You'd only want it to mock domain classes, which you must never do.
- **Two or more real implementations** → Yes. Genuine abstractions are *discovered*, not invented.

## Thresholds & defaults

| Thing | Value |
|---|---|
| Act section | **1 line** (>1 = encapsulation breach; laxer for utility code) |
| Arrange section | Up to act + assert combined; beyond that, extract factory methods |
| Operations per client goal | **1** (more = likely leaking implementation details) |
| Units of work per integration test | **≥3** — one each for arrange, act, assert |
| Integration tests per business scenario | **1 happy path** (the longest — through all out-of-process deps) + edge cases unit tests can't reach |
| Coverage target | **None.** Low (<60%) signals trouble; high means nothing |
| Collaborators tolerable in a domain class | 1–3, provided none is out-of-process |
| Application layers | **3**: domain, application services, infrastructure |
| Diagnostic logging | Ideally unhandled exceptions only |

## Tells & smells

| If you see… | You're probably… |
|---|---|
| Act section >1 line | Missing encapsulation; invariant violation possible |
| Assert section bloated | Missing abstraction (add equality members / a value object) |
| Arrange section enormous | Facing a code-design problem — fix the object graph, don't mock it away |
| `if` in a test | Testing multiple things. No exceptions, even in integration tests |
| Multiple act sections | Multiple units of behavior (OK only for slow integration tests with costly external deps) |
| Fixture setup in the constructor | Coupling every test in the class together |
| Test name contains the method under test | Coupled to implementation details |
| `should be` in a test name | Stating a wish, not a fact — use `is` |
| The test recomputes the algorithm | Domain knowledge leaked; the test can't detect anything |
| A test needs a private method/field exposed | Missing abstraction, dead code, or a test claiming special privileges |
| A boolean `isTestEnvironment` in production | Code pollution |
| `DateTime.Now` or a static logger in a domain class | Ambient context — inject explicitly instead |
| A complex private method | Extract it into its own class |
| Mocking in a unit test | Your domain model touched something it shouldn't |
| A circular dependency | No entry point for reading the code — return a value instead of a callback |

## Trade-off matrices

**Controllers with conditional logic — pick two of three:**

| Option | Domain testability | Controller simplicity | Performance |
|---|---|---|---|
| Push all reads/writes to the edges | ✅ | ✅ | ❌ |
| Inject out-of-process deps into the domain | ❌ | ✅ | ✅ |
| **Split decisions into granular steps** ← pick this | ✅ | ❌ | ✅ |

Then mitigate the controller complexity with **CanExecute/Execute** and **domain events**.

**Database delivery:**

| | Eases merge conflicts | Handles data motion |
|---|---|---|
| State-based | ✅ | ❌ |
| **Migration-based** | ❌ | ✅ ← matters far more |

## Integration test operating rules

- Run **sequentially**. Don't parallelize; don't spin a container per test.
- Clean data at the **start** of the test, via a base class, with a hand-written script.
- **Never** use an in-memory database. Same DBMS vendor as production.
- Re-read database state in the assert section using the controller's own reading code — never reuse the input parameters or the arrange section's context.
- Test **writes** thoroughly, **reads** selectively, **repositories** never directly.

## The one-line summary of each chapter

1. The goal is sustainable growth — tests are a cost/benefit decision.
2. A unit test verifies a unit of *behavior*, fast, isolated *from other tests*.
3. Section sizes are a design diagnostic; name tests as plain-English facts.
4. Four pillars, multiplied; resistance to refactoring is non-negotiable.
5. Mock inter-system communication only; everything else is an implementation detail.
6. Output-based > state-based > communication-based; get there via functional architecture.
7. Split overcomplicated code into algorithms and controllers.
8. Real managed dependencies, mocked unmanaged ones.
9. Mock at the edges, with spies, verifying counts.
10. Real database, migrations, per-section units of work, clean at start.
11. Never grant tests privileges production code doesn't have.
