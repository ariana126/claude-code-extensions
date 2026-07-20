# Testing Against a Real Database

Read this when setting up or repairing an integration test suite that touches a
database. Integration tests against a real database give the strongest
protection against regressions available — but only once the prerequisites are
in place.

## Prerequisites

Three things must be true before database tests are worth writing.

**1. The schema lives in source control.** Treat it as ordinary code. The
alternative — a dedicated live "model database" that serves as the reference
point — is an anti-pattern for two reasons: there is **no change history**, so
you cannot reconstruct the schema as of a past release when reproducing a
production bug; and there is **no single source of truth**, since the model
database competes with the repository. No modification to database structure
should happen outside source control.

**2. Every developer gets their own instance**, ideally local, to maximize test
speed. A shared database means tests interfere with each other, and a
non-backward-compatible change blocks everyone else.

**3. Delivery is migration-based.** See below.

## Migration-Based vs. State-Based Delivery

| | State-based | Migration-based |
|---|---|---|
| Explicit in source control | The desired state | The migrations |
| Implicit | Migrations (tool-generated at deploy time) | The state (assembled from migrations) |
| Eases | Merge conflicts | **Data motion** |
| Verdict | Only before first release | **Preferred** |

**State-based** keeps SQL describing the desired end state in source control and
lets a comparison tool work out the transition at deploy time.
**Migration-based** keeps explicit migrations that move the database from one
version to the next; the state is something you assemble by replaying them.

The trade-off is merge conflicts versus **data motion** — reshaping existing data
so it conforms to a new schema. Data motion matters far more in almost every
project, because once you have shipped you have data you cannot discard.

Comparison tools fundamentally cannot handle data motion: **a schema is
objective — there is one way to interpret it — but data is context-dependent.**
Splitting a `name` column into `first_name` and `last_name` requires a script
encoding a domain-specific rule about how names split. No tool can infer that.

**The discipline:** apply every schema modification through a migration,
including reference data. Once a migration is committed, don't edit it — write a
new one that corrects it. The single exception is when the incorrect migration
would cause data loss.

## Reference Data

Reference data is data that must be prepopulated for the application to work at
all — a `user_type` table backing a foreign key constraint, a list of currencies,
a set of country codes.

**The test that distinguishes it:** if the application can modify the data, it is
regular data; if not, it is reference data.

Keep reference data in source control as `INSERT` statements inside migrations.
Reference and regular data can share a table if you add a flag marking the
unmodifiable rows and forbid the application from touching them.

This matters for cleanup: the deletion script must remove all regular data and
**none** of the reference data, because reference data is controlled solely by
migrations.

## Cleanup

Four options, ranked:

| Approach | Verdict |
|---|---|
| Restore a backup before each test | Solves cleanup but is **much slower** — even with containers, seconds per test compound |
| Clean up at the **end** of a test | Fast but **skippable** — a crashed build or a debugger breakpoint leaves data behind |
| Wrap each test in an uncommitted transaction | Solves skipping but **creates a setup unlike production** |
| **Clean up at the start of a test** | **Best** — fast, unskippable, and consistent |

There is no need for a separate teardown phase; make cleanup part of the arrange
section, via a base class shared by all integration tests.

**Write the deletion SQL by hand**, in foreign-key order. Deriving table
relationships automatically or disabling integrity constraints is more machinery
than the problem deserves, and hand-written scripts give granular control over
what survives.

## Transactions, Repositories, and Units of Work

A business operation involves two decisions that cannot be made at the same
moment: **what data to update**, and **whether to keep the updates**. You only
know the second after every step has succeeded, and you can only take those
steps by touching the database. Separate them:

- **Repositories** provide access to and modification of data. They are
  short-lived, disposed as soon as the call completes, and enlist themselves into
  the current transaction. A repository should take the context as a constructor
  parameter, making it explicit that it cannot reach the database on its own.
- **A transaction** commits or rolls back everything as a unit and lives for the
  whole business operation.

`commit()` is called by the controller, because deciding to commit is
decision-making, and it belongs at the very end so that any early return
prevents it. `dispose()` is indiscriminate and involves no decision, so delegate
it to the infrastructure layer that constructed the controller.

A **unit of work** improves on a plain transaction by maintaining a list of
objects affected by the operation and executing all updates together at the end.
This defers the updates, which shortens the database transaction's life, reduces
contention, and often cuts the number of round trips. Most ORMs give you one for
free.

### Why multiple units of work per test

Use **at least three** — one each for arrange, act, and assert.

In production, each business operation gets its own exclusive context, created
just before the controller call and disposed right after. A test that shares one
context across all three sections creates an environment the controller never
sees in production, which is the first problem.

The second is worse. Even queries that look independent are not independent if
they share a context: the assert section may query the user and the company
separately from the arrange section, but with a shared context the ORM can serve
**cached** objects rather than reading the database. The test then verifies the
ORM's memory rather than what was actually persisted — defeating its entire
purpose.

Extracting the helpers below tends to push the count from three to five, since
each helper opens its own context. That is a deliberate trade of a little speed
for a lot of maintainability, and it is the right trade — especially with the
database on the developer's own machine.

## Shortening Tests

| Test section | Reuse technique |
|---|---|
| Arrange | **Object Mother** — factory methods with default arguments |
| Act | **Decorator method** taking the controller call as a parameter |
| Assert | **Fluent interface** over the domain objects |

Object Mother is preferred over **Test Data Builder** (`newUser().withEmail(...).build()`).
The builder reads slightly better but needs substantially more boilerplate, and
in any language with default arguments the factory method gets you the same
thing for free:

```
createUser(email = "user@mycorp.com", type = EMPLOYEE, confirmed = false)
```

Defaults let each test specify only the arguments it cares about, which
**emphasizes which arguments are relevant to the scenario** — a readability win
beyond the line count.

**Where to put factory methods:** start in the same test class. Move them to a
shared helper only once duplication becomes a real problem. Don't put them in the
base class — reserve that for code that must run in every test, like cleanup.

## What to Test, and What Not To

| Target | Guidance |
|---|---|
| **Writes** | Test thoroughly — high stakes |
| **Reads** | Higher threshold; only the most complex or important, and only via integration tests |
| **Repositories** | Never directly — only as part of the overarching suite |
| **Event dispatchers and similar plumbing** | Don't test separately |

**Reads and writes have asymmetric stakes.** A bug in a write corrupts data,
which affects your database *and* every external system reading from it. A bug
in a read usually just shows someone the wrong number. So the bar for testing a
read should be higher.

There is a deeper reason reads need less machinery. Domain modeling exists mainly
for encapsulation, and encapsulation is about preserving consistency across
*changes*. No changes, no need — so reads need no domain model and often no ORM
at all. Plain SQL is faster and skips abstraction layers you don't want. And
because reads have hardly any abstraction layers, **unit tests are useless
there**; if you test a read, use an integration test against the real database.

**Don't test repositories directly.** They sit in the controllers quadrant —
little complexity, one out-of-process dependency — so they carry the full
maintenance cost of an integration test while their regression-protection gains
largely overlap with the integration tests you already have. Where a repository
does contain real complexity, extract it into a self-contained algorithm and unit
test that instead. With an ORM this extraction is impossible (you cannot test
mappings without hitting the database), which is exactly why the answer there is
to cover them incidentally through the overarching suite.

## Never Substitute an In-Memory Database

SQLite or an in-memory fake is tempting: no cleanup, faster runs, an instance per
test. It is still the wrong call.

In-memory databases are **not functionally consistent** with real ones. Type
coercion differs, constraint enforcement differs, transaction semantics differ,
and dialect-specific SQL either fails or silently means something else. You get
false positives from behavior that only breaks in the fake, and — far more
damaging — **false negatives** from bugs the fake cannot reproduce. Protection
against regressions never materializes, and the gap gets filled with manual
regression testing.

**Use the same DBMS vendor in tests as in production.** Version or edition may
differ. The vendor must not.

## Parallelization

Run integration tests **sequentially**. Parallelizing them means making all test
data unique so constraints aren't violated and tests don't consume each other's
input, and it makes cleanup considerably trickier. The complexity is rarely worth
the wall-clock saving.

Similarly, a **container per test** is too much maintenance burden — images to
maintain, instances to allocate, batching because you cannot start them all at
once, disposal to manage. Reach for it only if minimizing execution time is
genuinely critical.

None of this is an argument against containers as such. Running your single
per-developer instance in a container is perfectly reasonable; it is the
per-test instance that doesn't pay.

## The Payoff

Integration tests working directly against managed dependencies are the most
efficient protection available against bugs from large-scale refactorings —
schema changes, switching ORMs, even changing database vendor. When the
underlying data access is replaced wholesale, a well-written suite needs only a
couple of lines changed to confirm the transition worked. That is the return
that justifies all the setup above.
