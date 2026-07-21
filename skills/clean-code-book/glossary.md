# Clean Code — Glossary

**Active Record** — A DTO with added navigational methods like `save`/`find`; treat as a data structure and keep business rules in separate objects. (Ch 6)

**Adapted Server** — Wrapping an unowned, thread-unsafe class in a synchronized adapter when you cannot add server-based locking. (Ch 13, App A)

**Artificial coupling** — A dependency that serves no purpose, binding two modules that have no real relationship. (Ch 17, G13)

**Aspect** — A modular construct that specifies which points in a system should have their behavior modified in a consistent way. (Ch 11)

**Atomic operation** — An operation that cannot be interrupted partway; note a 64-bit assignment is *two* 32-bit assignments and is not atomic. (App A)

**BDUF (Big Design Up Front)** — Designing everything before implementing anything; harmful because it resists change. (Ch 11)

**Bean** — An object with private variables exposed via getters and setters; conventional, but still effectively a data structure. (Ch 6)

**Bound Resources** — Resources of a fixed size or number used in a concurrent environment (connections, fixed-size buffers). (Ch 13)

**Boundary** — The seam between your code and code you don't control. (Ch 8)

**Boy Scout Rule** — Leave the campground cleaner than you found it: every check-in, make one small improvement. (Ch 1, Ch 15)

**Broken windows** — Visible decay invites more decay; one mess licenses the next. (Ch 1)

**Bucket brigade** — A chain where each call's output feeds the next, creating hidden temporal coupling. (Ch 15)

**CAS (compare-and-swap)** — Optimistic lock-free update: retry until the value you read is still the value you're replacing. (App A)

**Checked exception** — An exception declared in the signature, forcing every intermediate caller to change when a low-level method adds one; violates the Open-Closed Principle. (Ch 7)

**Clean test** — A test whose defining quality is readability, readability, and readability. (Ch 9)

**Clutter** — Meaningless artifacts in source: unused variables, dead functions, pointless comments. (Ch 17, G12)

**Code rot** — Modules gradually insinuating themselves into each other until nothing can change independently. (Ch 14)

**Code-sense** — The acquired sense of cleanliness that lets a programmer see options and choose the best transformation. (Ch 1)

**Code smell** — A surface symptom that points at a deeper design fault. (Ch 17)

**Cohesion** — The degree to which a class's methods and variables are co-dependent; maximal when every variable is used by every method. (Ch 10)

**Command Query Separation (CQS)** — A function should either change state or answer a question, never both. (Ch 3)

**Comment rot** — Comments drift into lies as the code moves away from them; the older and farther, the worse. (Ch 4)

**Conceptual affinity** — Shared naming or task that pulls related code together vertically. (Ch 5)

**Context (in exceptions)** — Enough information in the message to name the failed operation and the type of failure. (Ch 7)

**Critical section** — Code that must be protected from simultaneous use by multiple threads; keep it as small as truly necessary. (Ch 13)

**Cross-Cutting Concern** — A concern (persistence, transactions, security, caching) that cuts across natural object boundaries. (Ch 11)

**Data/Object Anti-Symmetry** — Objects make adding new types easy and new functions hard; data structures make adding new functions easy and new types hard. (Ch 6)

**Data structure** — Exposes its data and has no meaningful behavior; the complement of an object. (Ch 6)

**Deadlock** — Threads each waiting on resources the others hold, so none proceeds; broken most commonly by imposing a global resource ordering. (Ch 13, App A)

**Dead code** — Code that can never execute; delete it on sight. (Ch 17, G9)

**Dependency Injection (DI)** — A class receives its dependencies passively via constructor args or setters rather than resolving them itself. (Ch 11)

**Dependency Inversion Principle (DIP)** — Depend on abstractions, not on volatile concrete details. (Ch 10)

**Dependency magnet** — A widely imported class whose every change forces mass recompiles. (Ch 3)

**Disinformation** — A name whose entrenched meaning misleads (e.g. `accountList` for something that isn't a List). (Ch 2)

**Dining Philosophers** — Classic pattern of threads competing for shared resources, prone to deadlock and livelock. (Ch 13)

**DSL (Domain-Specific Language)** — A small focused language that closes the communication gap between domain experts and code. (Ch 11)

**DTO (Data Transfer Object)** — A class with public variables and no functions, used to move raw data across a boundary. (Ch 6)

**Dual standard** — Test code may be less efficient than production code, but never less clean. (Ch 9)

**Dummy scope** — An empty `while`/`for` body; if unavoidable, put the semicolon on its own indented line inside braces. (Ch 5)

**Emergent design** — Good design that arises from repeatedly applying a few simple rules rather than from up-front planning. (Ch 12)

**Explaining temporary variable** — A named intermediate that makes an algorithm's steps legible. (Ch 16, G19)

**F.I.R.S.T.** — Tests must be **F**ast, **I**ndependent, **R**epeatable, **S**elf-validating, and **T**imely. (Ch 9)

**Feature Envy** — A method more interested in another class's data than its own. (Ch 6, Ch 16, G14)

**Flag argument** — A boolean parameter, which proves the function does more than one thing; split it into two named functions. (Ch 3)

**Four Rules of Simple Design** — In Kent Beck's priority order: runs all the tests; contains no duplication; expresses the intent of the programmer; minimizes the number of classes and methods. (Ch 12)

**Future** — A handle to a computation that hasn't completed yet, letting you overlap remote I/O with local work. (App A)

**God class** — A class with an enormous surface that does everything. (Ch 10)

**Grand Redesign in the Sky** — The doomed rewrite that must race a moving target and usually loses. (Ch 1)

**Gratuitous context** — Redundant application-wide prefixes on every name (e.g. `GSD…`). (Ch 2)

**Hidden temporal coupling** — An undeclared requirement that calls happen in a particular order. (Ch 15)

**Hungarian Notation** — Encoding a variable's type into its name; obsolete and misleading in modern typed languages. (Ch 2)

**Hybrid** — A class that is half object and half data structure; the worst of both, never build one. (Ch 6)

**Inversion of Control (IoC)** — Moving a secondary responsibility (here, dependency resolution) out of an object to a dedicated mechanism. (Ch 11)

**Jiggling** — Deliberately instrumenting code to perturb thread execution ordering and force latent failures to surface. (Ch 13, App A)

**Law of Demeter** — Method `f` of class `C` may call methods only on `C`, on objects `f` creates, on `f`'s arguments, and on `C`'s instance variables — never on objects returned by those. (Ch 6, G36)

**Learning test** — A controlled experiment that checks your understanding of a third-party API; also becomes a release-compatibility check. (Ch 8)

**LeBlanc's law** — *Later equals never.* (Ch 1)

**Livelock** — Threads acquiring and releasing in useless lockstep, active but making no progress. (Ch 13, App A)

**Logical dependency** — An assumption one module makes about another that is not expressed in code; make it physical. (Ch 16, G22)

**Magic number** — A bare non-self-describing literal token; replace with a named constant. (Ch 17, G25)

**Mandated comment** — A comment required by policy (a javadoc on every function), producing clutter and lies. (Ch 4)

**Mental mapping** — Forcing the reader to translate your name into what it actually means. (Ch 2)

**Monadic / dyadic / triadic / polyadic** — Functions of one / two / three / four-or-more arguments. (Ch 3)

**Mumbling** — A comment that is meaningful only to its author. (Ch 4)

**Mutual Exclusion** — Ensuring only one thread accesses shared data at a time. (Ch 13)

**Newspaper Metaphor** — Read a source file like a newspaper: headline name, synopsis at the top, increasing detail downward. (Ch 5)

**Noise words** — `Info`, `Data`, `Object`, `a`, `an`, `the` — additions that create no meaningful distinction. (Ch 2)

**Noninvasive** — Achieving a change without manually editing the target's source (proxies, aspects). (Ch 11)

**Nonlocal information** — A comment describing a distant subsystem; it has failed and isn't worth its bits. (Ch 4)

**Object** — Hides its data behind abstractions and exposes functions that operate on it; the complement of a data structure. (Ch 6)

**One Switch rule** — At most one switch per type of selection, and it must produce polymorphic objects. (Ch 3, Ch 17, G23)

**Open-Closed Principle (OCP)** — Open for extension, closed for modification: add new behavior by subclassing, not by editing existing classes. (Ch 10)

**Ordinal day** — Days offset from an epoch — the abstraction `SerialDate`'s "serial number" was obscuring. (Ch 16)

**Orphaned blurb** — A comment separated from the code it describes. (Ch 4)

**POJO** — A plain domain-focused object with no framework dependencies. (Ch 11)

**Position marker** — A banner of slashes used to mark a section; almost always noise. (Ch 4)

**Primal Conundrum** — Programmers know messes slow them down, yet make messes to go fast — the pressure that never abates. (Ch 1)

**Principle of Least Surprise** — A function or class should do what another programmer would reasonably expect. (Ch 17, G3)

**Producer-Consumer** — Producers queue work, consumers drain it; the queue is a bound resource requiring mutual signaling. (Ch 13)

**Readers-Writers** — Concurrency pattern balancing throughput against starvation and stale data. (Ch 13)

**Reading:writing ratio** — Time spent reading code exceeds time writing it by well over 10 to 1; therefore optimize for reading. (Ch 1)

**Rough draft** — The messy but working first version, written expressly to be cleaned afterward. (Ch 14)

**Scissors rule** — The old C++ convention of putting instance variables at the bottom of a class. (Ch 5)

**Seam** — A substitution point in the code where you can swap in a test double. (Ch 8)

**Selector argument** — A parameter that chooses which behavior the function performs; split the function instead. (Ch 17, G15)

**Separation of Concerns** — The oldest and most important design technique: keep unrelated concerns in unrelated modules. (Ch 11)

**Side effect** — A hidden action the function's name doesn't promise. (Ch 3)

**Single Responsibility Principle (SRP)** — A class or module should have one, and only one, reason to change. (Ch 10, Ch 13)

**Special Case Pattern** — An object that encapsulates exceptional behavior so the client never sees the exceptional case. (Ch 7)

**Starvation** — A thread prohibited from proceeding for an excessively long time. (Ch 13, App A)

**Stepdown Rule** — Every function should be followed by those at the next level of abstraction, so the file reads top-down. (Ch 3, Ch 10)

**Structure over Convention** — Enforce design decisions with structure (abstract methods) rather than relying on convention. (Ch 17, G21)

**Template Method** — Removes higher-level duplication when several procedures differ in only one step. (Ch 12)

**Temporal coupling** — A hidden dependency on call order. (Ch 3, Ch 15)

**TO paragraph** — The test for one level of abstraction: "TO *X*, we do these steps…" (Ch 3)

**Train wreck** — Chained calls (`a.getB().getC().doD()`) coupled like train cars. (Ch 6, G36)

**Transitive navigation** — Reaching through an object graph via chained getters; write shy code instead. (Ch 17, G36)

**Three Laws of TDD** — (1) Write no production code until a failing test exists; (2) write no more test than is sufficient to fail; (3) write no more production code than passes the current test. (Ch 9)

**Ubiquitous language** — The team's shared project vocabulary, reflected directly in the code. (Ch 17, N3)

**Unchecked exception** — An exception not declared in signatures; the default choice for general application development. (Ch 7)

**Vertical distance** — The separation between related pieces of code, which measures how important they are to each other. (Ch 5, G10)

**Vertical openness** — Blank lines used to separate complete thoughts. (Ch 5)

**Wading** — Slogging through tangled bad code looking for a clue about what's going on. (Ch 1)

**Weasel words** — `Processor`, `Manager`, `Super` in a class name, signaling unfocused aggregation. (Ch 10)

**Wrapping** — Enclosing a third-party API behind your own type so its changes touch one place. (Ch 7, Ch 8)
