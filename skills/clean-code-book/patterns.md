# Clean Code — Techniques & Patterns

Concrete, repeatable moves. Each is a technique you can execute, not a principle to admire.

## The Boy Scout Rule
**When to use**: Every check-in, without exception.
**How**: Make one small improvement to code you touched — rename a variable, split a function, kill one duplication, clean one composite `if`.
**Trade-offs**: None at this size; the rule exists precisely because large cleanups never get scheduled. (Ch 1, Ch 15)

## Extract Method Until You Can't
**When to use**: A function exceeds ~20 lines, has >1–2 indent levels, or divides into sections.
**How**: Extract until every remaining line sits exactly one level below the function's name. If you can extract a function whose name isn't a restatement of its implementation, the original did more than one thing.
**Trade-offs**: Produces many small functions — that's the goal, not a cost. (Ch 3, G34)

## Comment → Function or Variable
**When to use**: You are about to write an explanatory comment.
**How**: First try a function name (`isEligibleForFullBenefits()`), then explanatory local variables. Keep the comment only if both fail.
**Trade-offs**: Names can't express *why*; comments that say WHY survive, comments that say WHAT rot. (Ch 4, G19)

## Rename → Extract Constant → Extract Class
**When to use**: A name needs a comment, or orphan variables lack context.
**How**: Rename for intent; promote magic literals to named constants; wrap related orphan variables in a class that supplies the context (`GuessStatisticsMessage`).
**Trade-offs**: Costs a class; buys a place for the concept to live. (Ch 2)

## Bury the Switch in an Abstract Factory
**When to use**: A switch selects on type and would otherwise be duplicated everywhere.
**How**: Move it into a factory, once, behind an interface; it returns polymorphic objects. Enforce at most one switch per type of selection.
**Trade-offs**: Indirection, in exchange for never editing existing classes to add a type (OCP). (Ch 3, G23)

## Reduce Argument Count
**When to use**: A function takes 3+ arguments, or any boolean flag.
**How**: Flags → split into two named functions. Dyads → convert by membership, by making one a field, or by extracting a class (`FieldWriter`). 3+ → wrap into an argument object (`makeCircle(Point, double)`). Or use the keyword form, encoding argument names into the function name.
**Trade-offs**: Argument objects can feel ceremonial; they usually reveal a missing concept. (Ch 3, F1)

## Write Try-Catch-Finally First
**When to use**: Writing any code that can throw.
**How**: Start from a test that expects the exception; write the try-catch-finally as the scaffold; then fill in and narrow the caught type. Extract the try-body into a named method so the algorithm is separate from error handling.
**Trade-offs**: Feels backwards; guarantees the transaction scope leaves consistent state. (Ch 7)

## Special Case Object
**When to use**: A "failure" is really a business alternative, and the client shouldn't branch on it.
**How**: Return an object that encapsulates the exceptional behavior; the client calls it uniformly. Likewise return `Collections.emptyList()` rather than null.
**Trade-offs**: One more class; removes a whole class of null checks. (Ch 7)

## Wrapping a Boundary
**When to use**: Any third-party API or unowned type crossing into your system.
**How**: Encapsulate it inside one class (`Sensors` around a `Map`) and expose only the operations you need. Never pass the boundary interface around or return it from public APIs.
**Trade-offs**: Not every use needs wrapping — only the ones that would leak. (Ch 8)

## Learning Tests
**When to use**: Adopting an unfamiliar library.
**How**: Write tests that exercise the API the way you intend to use it, before integrating. Re-run on each library release.
**Trade-offs**: Free — you had to learn it anyway — and they become compatibility checks. (Ch 8)

## The Interface We Wish We Had (+ ADAPTER)
**When to use**: The far-side API doesn't exist yet or is awkward.
**How**: Define the interface you want, code against it, then write an adapter to the real API. Test across the seam with a fake.
**Trade-offs**: An extra layer; keeps the awkwardness in one place. (Ch 8)

## BUILD-OPERATE-CHECK
**When to use**: Structuring any unit test.
**How**: Three visually distinct parts — build the test data, operate on it, check the results. Refactor obfuscating detail into a domain-specific testing language (`makePages`, `submitRequest`, `assertResponseIsXML`).
**Trade-offs**: Never design that testing API up front; let it evolve from refactoring. (Ch 9)

## Split by Cohesion
**When to use**: Instance variables serve only a subset of methods, or private methods apply only to a subset.
**How**: Extract the cohesive subset into its own class. Test with a ~25-word description: if it needs "and", there are too many responsibilities. If you can't name the class concisely, it's too large.
**Trade-offs**: More classes, each smaller — but the spur should be an actual system change; if the class is logically complete, leave it alone. (Ch 10)

## Separate Constructing from Using
**When to use**: You see `if (x == null) x = new Impl()` in runtime code.
**How**: Move all construction to `main` (or a DI container), and write the rest of the system assuming objects are already wired. Use an Abstract Factory when the application must control *when* an object is built.
**Trade-offs**: If dependency arrows point from the application back toward `main`, the separation has failed. (Ch 11)

## Template Method for Higher-Level Duplication
**When to use**: Two or more procedures differ in exactly one step.
**How**: Massage the near-identical lines until they *are* identical, then extract the varying step into an abstract method.
**Trade-offs**: Inheritance coupling; use when the shape genuinely is fixed. (Ch 12)

## Concurrency: Choose One Locking Strategy
**When to use**: A client must call more than one method on a shared object to do one thing (per-method `synchronized` is then not enough).
**How**: Pick exactly one of — **Client-Based Locking** (client locks around the call sequence), **Server-Based Locking** (add a method to the server that does the whole thing under one lock), or **Adapted Server** (wrap an unowned class in a synchronized adapter).
**Trade-offs**: Prefer server-based when you own the server — it removes duplication, error surface, and shared-variable scope. (Ch 13, App A)

## Thread-Failure Jiggling
**When to use**: Testing any threaded code.
**How**: Insert `ThreadJigglePoint` calls (no-op in production, random `sleep`/`yield` in test) to perturb execution ordering; or use ConTest. Run with more threads than processors, on every target platform, early and often.
**Trade-offs**: Non-deterministic, so it proves presence not absence of bugs — but ConTest raised detection from ~1-in-10,000,000 to ~1-in-30. Never dismiss a spurious failure as a one-off. (Ch 13, App A)

## Successive Refinement
**When to use**: Any nontrivial module — and specifically the moment you can see the next feature would leave an unfixable mess.
**How**: Write it dirty with tests. Then append an empty skeleton of the target abstraction (breaks nothing); change one field's type and let the compiler enumerate the breakage; move behavior into derivatives; delete the now-parallel structures; split into files. Make a large number of very tiny changes, each keeping all tests green.
**Trade-offs**: Never make massive structural changes in the name of improvement — some programs never recover. Judge the result by the cost of the next change. Most of a good refactor is deletion and relocation. (Ch 14)

## Refactor Behind a Coverage Measurement
**When to use**: Cleaning legacy code you didn't write.
**How**: Measure coverage first (SerialDate: 50% → 92%), write an independent test suite, keep should-pass tests commented as an executable backlog, then refactor in tiny verified steps. Comment out suspect guards and run the tests to prove code is dead before deleting.
**Trade-offs**: Slow start; it's the only way to refactor without a rewrite. (Ch 15, Ch 16, T2)

## Enum Absorption
**When to use**: `public static final int` code constants with matching validators and converters.
**How**: Move the constants into an enum, then delete the validators and converters they existed to support. Replace the switch with an enum carrying an abstract method. Move enums to their own files as they grow.
**Trade-offs**: Java-specific; eliminates whole categories of invalid state. (Ch 16, J3)

## Extract Explanatory Predicate
**When to use**: A raw boolean expression appears in a condition.
**How**: Extract it into a named predicate; invert any `shouldNot`-style negative. Intent beats mechanism.
**Trade-offs**: One more tiny method — the point of the exercise. (Ch 15, G28, G29)

## Rebase to Zero
**When to use**: `+1` / `-1` adjustments recur around a variable.
**How**: The variable is misnamed — rename it (index vs length) and rebase to zero. If rebasing makes a `>` want to become `>=`, the old guard was dead; delete it.
**Trade-offs**: Touches arithmetic broadly; run the full suite after every single change. (Ch 15, G33, G9)
