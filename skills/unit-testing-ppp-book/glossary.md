# Glossary — Unit Testing Principles, Practices, and Patterns

**AAA (Arrange-Act-Assert)** — the three-part structure of every test: bring the SUT and dependencies to a desired state, invoke the behavior, verify the outcome (Ch 3)

**Active Record** — a domain class that retrieves and persists itself to the database; fails to scale because it merges business logic with out-of-process communication (Ch 7)

**Aggregate** — a DDD cluster of highly connected classes that is loosely coupled to other clusters, reducing total connectivity and improving testability (Ch 7)

**Ambient context** — resolving a dependency via a static method or field (e.g. `LogManager.GetLogger`, `DateTimeServer.Now`); an anti-pattern (Ch 8, Ch 11)

**Anti-corruption layer** — an adapter over a third-party library that abstracts its complexity, exposes only what you need, and speaks your domain language (Ch 9)

**Anti-pattern** — a common solution that looks appropriate on the surface but leads to problems down the road (Ch 11)

**Assertion-free testing** — tests with no assertions (often wrapped in try/catch); always pass, score 100% coverage, verify nothing (Ch 1)

**Atomic updates** — updates executed all-or-nothing: each must complete in its entirety or have no effect (Ch 10)

**Black-box testing** — testing that examines functionality without knowing internal structure, built around specifications and requirements. Use when *writing* tests (Ch 4)

**Branch coverage** — branches traversed by ≥1 test ÷ total branches; more precise than code coverage but still a bad positive indicator (Ch 1)

**Brittle test** — a test that runs fast and catches regressions but produces many false positives; can't withstand refactoring (Ch 4)

**CanExecute/Execute pattern** — introduce a `CanDo()` for each `Do()` and make its success a precondition of `Do()`, consolidating decisions in the domain layer (Ch 7)

**Circular dependency** — two or more classes that directly or indirectly depend on each other; adds cognitive load and offers no starting point for reading the code (Ch 8)

**Classical school (Detroit, classicist)** — isolates *unit tests* from each other; a unit is a class or set of classes; substitutes only shared dependencies. Khorikov's preference (Ch 2)

**Code coverage (test coverage)** — lines executed by ≥1 test ÷ total lines; trivially gamed by compacting code (Ch 1)

**Code depth vs. code width** — code can be deep (complex/important) or wide (many collaborators), never both (Ch 7)

**Code pollution** — adding production code that's only needed for testing (Ch 6, Ch 11)

**Collaborator** — a dependency that is either shared or mutable. Values and value objects are dependencies but *not* collaborators (Ch 2)

**Command** — a method that produces a side effect and returns `void`; substituted by a **mock** (Ch 5)

**Communication-based testing** — using mocks to verify communications between the SUT and its collaborators; the weakest of the three styles (Ch 6)

**Controller** — code with low complexity and many collaborators; orchestrates domain classes and external applications. Covered by integration tests (Ch 7)

**CQS (Command Query Separation)** — every method should be either a command or a query, never both. *Asking a question should not change the answer* (Ch 5)

**Cyclomatic complexity** — `1 + <number of branching points>`; equivalently, the number of tests needed for 100% branch coverage (Ch 7)

**Data motion** — changing the shape of existing data so it conforms to a new database schema (Ch 10)

**Diagnostic logging** — logging that helps developers understand what's happening inside the application; an implementation detail. Don't test it (Ch 8)

**Domain event** — a class describing an event meaningful to domain experts, used to inform external systems. Named in the past tense; immutable values (Ch 7)

**Domain model** — the collection of domain knowledge about the problem the project solves; the primary target of unit testing (Ch 1, Ch 8)

**Domain significance** — how significant a piece of code is for the problem domain; independent of complexity (Ch 7)

**Dummy** — a hardcoded value (null, a made-up string) that satisfies a method signature without participating in the outcome. A kind of stub (Ch 5)

**Edge case** — a business scenario execution that results in an error (Ch 8)

**Encapsulation** — the act of protecting code against invariant violations. Achieved by hiding implementation details and bundling data with operations (Ch 3, Ch 5)

**End-to-end test** — a subset of integration tests covering all or nearly all out-of-process dependencies, from the end user's point of view (Ch 2)

**Enterprise application** — software automating an organization's inner processes; high business-logic complexity, long lifespan, moderate data, low/moderate performance needs (Ch 1)

**Fail Fast principle** — stop the current operation as soon as any unexpected error occurs; shortens the feedback loop and protects persistent state. A viable alternative to integration testing (Ch 8)

**Fake** — functionally a stub, but created to replace a dependency that doesn't exist yet (Ch 5)

**False negative (type II error)** — the test passes though the functionality is broken. Guarded against by *protection against regressions* (Ch 4)

**False positive (type I error)** — the test fails though the functionality works. Guarded against by *resistance to refactoring* (Ch 4)

**Fast feedback** — the third pillar: how quickly the test executes (Ch 4)

**Functional architecture** — maximizes purely functional (immutable) code while minimizing side-effect code, by pushing side effects to the edges of a business operation. Hexagonal architecture taken to an extreme (Ch 6)

**Functional core (immutable core)** — the code that makes decisions, written as mathematical functions (Ch 6)

**Functional programming** — programming with mathematical functions (Ch 6)

**Given-When-Then** — AAA with labels more readable to non-programmers; preferred for tests shared with non-technical people (Ch 3)

**Good negative indicator / bad positive indicator** — a metric whose low reading reliably signals a problem but whose high reading signals nothing. Applies to both testability and coverage (Ch 1)

**Happy path** — a successful execution of a business scenario (Ch 8)

**Hexagonal architecture** — a set of interacting applications (hexagons), each with a domain layer and an application services layer; one-way dependency flow inward (Ch 5)

**Humble Object pattern** — extract testable logic out of code coupled to a difficult dependency, leaving a thin wrapper so humble it needs no tests (Ch 7)

**Implementation detail** — code that neither exposes an operation nor state helping a client achieve a goal (Ch 5)

**Integration test** — any test that isn't a unit test; in practice, one verifying integration with out-of-process dependencies. Covers controllers (Ch 2, Ch 8)

**Inter-system communication** — communication between your application and external applications; part of observable behavior (Ch 5)

**Intra-system communication** — communication between classes inside your application; an implementation detail (Ch 5)

**Invariant** — a condition that should hold true at all times. An **invariant violation** is an inconsistency that shouldn't be possible (Ch 3, Ch 5)

**London school (mockist)** — isolates *units* from each other; a unit is a class; substitutes all but immutable dependencies. Drives outside-in TDD (Ch 2)

**Maintainability** — the fourth pillar: how hard the test is to understand (a function of size) and to run (a function of out-of-process dependencies) (Ch 4)

**Managed dependency** — an out-of-process dependency only accessible through your application; interactions are implementation details. **Use the real instance in tests** (Ch 8)

**Mathematical function (pure function)** — a method with no hidden inputs or outputs; all are expressed in the signature (Ch 6)

**Migration-based delivery** — database delivery using explicit migrations stored in source control; makes migrations explicit and state implicit. **Preferred** (Ch 10)

**Mock** — a test double that **emulates and examines** *outcoming* interactions (calls that change a dependency's state). Substitutes commands (Ch 5)

**Mock (the tool) vs. mock (the test double)** — the mocking-library class vs. the instance it creates; the same tool creates both mocks and stubs (Ch 5)

**Mock chain** — mocks returning mocks returning mocks; a major driver of poor maintainability (Ch 6)

**Model database** — a live database instance used as the schema reference point; an anti-pattern (Ch 10)

**MUT (method under test)** — the specific method the test calls, as opposed to the **SUT** (the whole class) (Ch 2)

**Mutable shell** — the code that supplies input to the functional core and converts its decisions into side effects. Should be as dumb as possible (Ch 6)

**Object Mother** — a class or method producing test fixtures via factory methods with default arguments. Preferred over Test Data Builder in C# (Ch 3, Ch 10)

**Observable behavior** — code that exposes an operation or state helping a **client** achieve one of its **goals**. Depends on who the client is (Ch 5)

**Out-of-process dependency** — a dependency running outside the application's process; a proxy to data not yet in memory (Ch 2)

**Output-based testing (functional)** — feed input to the SUT and check the returned output. The highest-quality style; requires purely functional code (Ch 6)

**Overcomplicated code** — high complexity/domain significance *and* many collaborators (e.g. fat controllers). Should be refactored out of existence (Ch 7)

**Over-specification** — verifying things that aren't part of the end result; most commonly, examining interactions (Ch 5)

**Precondition** — a safeguard activated only in exceptional cases, letting software fail fast before errors reach the database. Test it only if it has domain significance (Ch 7)

**Private dependency** — a dependency not shared between tests (Ch 2)

**Protection against regressions** — the first pillar: how good the test is at indicating the *presence* of bugs. A function of code volume, complexity, and domain significance (Ch 4)

**Query** — a side-effect-free method that returns a value; substituted by a **stub** (Ch 5)

**Reference data** — data that must be prepopulated for the application to operate. *If the application can modify it, it's regular data; if not, it's reference data* (Ch 10)

**Refactoring** — changing existing code without modifying its observable behavior (Ch 4)

**Regression** — a feature that stops working as intended after a code change; synonymous with *software bug* (Ch 1)

**Repository** — a short-lived class enabling access to and modification of database data; always works on top of a transaction. Don't test directly (Ch 10)

**Resistance to refactoring** — the second pillar: the degree to which a test survives refactoring without failing. **Non-negotiable** because it's essentially binary (Ch 4)

**Shared dependency** — a dependency shared between *tests*, providing a means for them to affect each other's outcome (Ch 2)

**Software entropy** — the tendency of code to deteriorate; each change increases disorder (Ch 1)

**Spy (handwritten mock)** — a mock written manually rather than generated. **Superior to mocks at system edges** because it enables reusable fluent assertions (Ch 5, Ch 9)

**State-based delivery** — database delivery where source control holds the desired state and a comparison tool generates migrations. Impractical post-release (Ch 10)

**State-based testing** — verifying the state of the system after an operation completes; the middle-quality style (Ch 6)

**Structured logging** — decoupling log data capture from its rendering, enabling multiple output formats (Ch 8)

**Stub** — a test double that **only emulates** *incoming* interactions (calls that supply input data). Substitutes queries. **Never assert interactions with stubs** (Ch 5)

**Support logging** — logging intended for support staff or system administrators; part of observable behavior. **Test it** (Ch 8)

**SUT (system under test)** — the class being verified. Name it `sut` in tests (Ch 2, Ch 3)

**Tautology test** — a test that verifies nothing because it always passes or contains semantically meaningless assertions (Ch 4, Ch 9)

**Tell-don't-ask** — bundling data with the functions that operate on it (Fowler); a corollary of encapsulation (Ch 5)

**Test double** — the umbrella term for all non-production-ready fake dependencies. Five variants (dummy, stub, spy, mock, fake) reduce to two: mocks and stubs (Ch 2, Ch 5)

**Test fixture** — an object the test runs against, kept in a known fixed state before each run (Ch 3)

**Test isolation** — the ability for tests to run in parallel, sequentially, and in any order (Ch 5)

**Test Pyramid** — the ratio of unit (majority), integration (middle), and end-to-end (minority) tests. Flattens to a rectangle in simple CRUD projects (Ch 4, Ch 8)

**Trivial code** — low complexity and few collaborators (one-line properties, parameterless constructors). Don't test it (Ch 7)

**Trivial test** — a test covering code too simple to break; fast and refactoring-resistant but with no regression protection (Ch 4)

**Unit of behavior** — what a test should verify: something meaningful to the problem domain that a business person recognizes as useful. *Not* a unit of code (Ch 2)

**Unit of work** — maintains a list of objects affected by a business operation and executes all updates as one unit at the end, reducing data congestion (Ch 10)

**Unit test** — a test that verifies a single unit of behavior, does it quickly, and does it in isolation from other tests (Ch 2)

**Unmanaged dependency** — an out-of-process dependency other applications can access (SMTP server, message bus); interactions are observable behavior. **Mock it** (Ch 8)

**Value object (value)** — an immutable object with no individual identity, identified solely by content; two with equal content are interchangeable (Ch 2)

**Volatile dependency** — a dependency requiring extra runtime setup, or behaving nondeterministically (RNG, clock). Overlaps with but differs from *shared* (Ch 2)

**White-box testing** — testing derived from source code rather than requirements. Use when *analyzing* tests, never when writing them (Ch 4)

**YAGNI ("You aren't gonna need it")** — don't invest in functionality not needed right now; opportunity cost plus the cost of extra code (Ch 8)
