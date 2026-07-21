# Chapter 17: Smells and Heuristics

## Core Idea
The book's master catalog: 66 numbered heuristics (plus 3 Java-specific ones) that Martin compiled by refactoring real programs and writing down *why* he made each change. Read top to bottom once; use as a reference forever. The list is not a rule book — it implies a value system, and "clean code is not written by following a set of rules."

## How to Use This Catalog
Cite the code when you make or request a change: "`[G28]` — encapsulate that conditional." A code without its title is useless; always pair them. Chapters 15 and 16 are worked demonstrations of exactly this practice.

---

## Comments (C1–C5)

| Code | Title | Actionable gloss |
|---|---|---|
| **C1** | Inappropriate Information | Don't hold in comments what belongs in source control, issue tracking, or other record-keeping systems. Change histories, authors, last-modified dates, SPR numbers — all clutter. Reserve comments for technical notes about code and design. |
| **C2** | Obsolete Comment | A comment that has gone old, irrelevant, or incorrect. Best not to write one that will become obsolete; when you find one, update or delete it immediately. Obsolete comments drift away from the code they described and become floating islands of misdirection. |
| **C3** | Redundant Comment | A comment describing something that already describes itself — `i++; // increment i`, or a Javadoc that says no more than the signature. Comments should say what the code cannot. |
| **C4** | Poorly Written Comment | If a comment is worth writing, write it well: choose words carefully, use correct grammar and punctuation, don't ramble, don't state the obvious, be brief. |
| **C5** | Commented-Out Code | An abomination. It rots, calls functions that no longer exist, uses renamed variables. Nobody deletes it because everyone assumes someone else needs it. **Delete it** — source control remembers. |

## Environment (E1–E2)

| Code | Title | Actionable gloss |
|---|---|---|
| **E1** | Build Requires More Than One Step | You should check out with one command and build with one other. No hunting for JARs, XML files, or arcane context-dependent scripts. Target: `svn get mySystem; cd mySystem; ant all`. |
| **E2** | Tests Require More Than One Step | You should run *all* unit tests with a single command — ideally one button in the IDE, at worst one shell command. Quick, easy, and obvious. |

## Functions (F1–F4)

| Code | Title | Actionable gloss |
|---|---|---|
| **F1** | Too Many Arguments | Zero arguments is best, then one, two, three. More than three is very questionable and should be avoided with prejudice. |
| **F2** | Output Arguments | Counterintuitive — readers expect arguments to be inputs. If a function must change state, have it change the state of the object it is called on. |
| **F3** | Flag Arguments | A boolean argument loudly declares the function does more than one thing. Confusing; eliminate by splitting the function. |
| **F4** | Dead Function | Methods that are never called should be discarded. Don't be afraid to delete — source control remembers. |

## General (G1–G36)

| Code | Title | Actionable gloss |
|---|---|---|
| **G1** | Multiple Languages in One Source File | Ideally one language per source file. Java + XML + HTML + Javadoc + JavaScript in one file is confusing at best. Minimize both the number and extent of extra languages. |
| **G2** | Obvious Behavior Is Unimplemented | Follow the Principle of Least Surprise: implement the behavior another programmer would reasonably expect (e.g. `StringToDay` should handle abbreviations and ignore case). When it doesn't, readers lose trust and must read the details. |
| **G3** | Incorrect Behavior at the Boundaries | Don't trust intuition that code works in all corner cases. Look for every boundary condition and write a test for it. There is no replacement for due diligence. |
| **G4** | Overridden Safeties | Turning off compiler warnings, disabling failing tests, hand-controlling `serialVersionUID` — risky. Chernobyl melted down because safeties were overridden one by one. |
| **G5** | Duplication | One of the most important rules in the book — DRY / "Once, and only once." Every duplication is a missed abstraction. Identical clumps → extract a method; repeated switch/if-else chains → polymorphism; similar algorithms with different lines → TEMPLATE METHOD or STRATEGY. |
| **G6** | Code at Wrong Level of Abstraction | Separate higher-level general concepts from lower-level detail *completely*. Constants, variables and utilities that pertain only to an implementation must not appear in the base class (`percentFull()` on `Stack` belongs on `BoundedStack`). Applies to files, components, and modules too. |
| **G7** | Base Classes Depending on Their Derivatives | Base classes should know nothing about their derivatives, so the two can deploy in separate JARs and be changed independently. Rare exception: a fixed derivative set, as in a finite state machine. |
| **G8** | Too Much Information | Well-defined modules have very small interfaces that do a lot with a little. Hide your data, utility functions, constants, temporaries. Fewer methods, fewer instance variables, fewer protected members — keep coupling low by limiting information. |
| **G9** | Dead Code | Code that isn't executed: unreachable `if` branches, `catch` blocks for exceptions never thrown, uncalled utilities, impossible switch cases. It doesn't get updated when designs change, so it rots. Delete it. |
| **G10** | Vertical Separation | Define variables and functions close to where they're used. Declare locals just above first use with small vertical scope; define private functions just below their first use, so finding one is a matter of scanning downward. |
| **G11** | Inconsistency | Do similar things the same way — a corollary of least surprise. If `response` names an `HttpServletResponse` in one function, use it everywhere; if one method is `processVerificationRequest`, the sibling is `processDeletionRequest`. |
| **G12** | Clutter | Empty default constructors, unused variables, uncalled functions, uninformative comments — meaningless artifacts. Remove them; keep source files clean and well organized. |
| **G13** | Artificial Coupling | Things that don't depend on each other shouldn't be coupled — e.g. a general enum nested inside a specific class, or a general-purpose static in a specific class. Usually the result of putting something in a *convenient* rather than a *correct* place. Lazy and careless. |
| **G14** | Feature Envy | A method interested in another class's variables and functions rather than its own — using accessors/mutators to manipulate another object's data. Eliminate it, since it exposes one class's internals to another. Sometimes a necessary evil (a report class formatting another object's data). |
| **G15** | Selector Arguments | A dangling `false` at the end of a call is abominable. Selector arguments (boolean, enum, or int) combine many functions into one and are a lazy way to avoid splitting a large function. Prefer many functions to passing in a behavior code. |
| **G16** | Obscured Intent | Run-on expressions, Hungarian notation, and magic numbers all hide the author's intent. Small and dense can still be impenetrable; take the time to make intent visible. |
| **G17** | Misplaced Responsibility | Put code where a reader would naturally expect it (least surprise): `PI` with the trig functions, `OVERTIME_RATE` in `HourlyPayCalculator`. Use function *names* to decide — `getTotalHours` implies it computes the total, `saveTimeCard` doesn't. |
| **G18** | Inappropriate Static | `Math.max(a,b)` is a good static. But `HourlyPayCalculator.calculatePay(employee, rate)` should not be, because there's a real chance you'll want it polymorphic. Prefer nonstatic; when in doubt, make it nonstatic. |
| **G19** | Use Explanatory Variables | Break calculations into intermediate values held in meaningfully named variables. Hard to overdo — more explanatory variables are generally better than fewer, and an opaque module can turn transparent. |
| **G20** | Function Names Should Say What They Do | `date.add(5)` — days? weeks? mutating or returning new? If it mutates, `addDaysTo`/`increaseByDays`; if it returns new, `daysLater`/`daysSince`. If you must read the implementation to know, fix the name or the structure. |
| **G21** | Understand the Algorithm | Getting tests to pass by plugging in `if`s and flags is not "working." Before you're done, know the solution is correct. Often the best way to gain that understanding is to refactor the function until it's obvious how it works. |
| **G22** | Make Logical Dependencies Physical | A dependent module must not *assume* things about what it depends on — it should explicitly ask for them. `HourlyReporter`'s `PAGE_SIZE` constant should become `formatter.getMaxPageSize()`. |
| **G23** | Prefer Polymorphism to If/Else or Switch/Case | Most switches are the brute-force solution, not the right one; cases where functions are more volatile than types are rare. **ONE SWITCH rule**: at most one switch for a given type of selection, and its cases must create polymorphic objects that replace all other such switches. |
| **G24** | Follow Standard Conventions | Every team follows a coding standard based on industry norms — variable declaration placement, naming, brace style. The code itself is the documentation of the convention. Be mature enough to realize where the braces go doesn't matter, only that you all agree. |
| **G25** | Replace Magic Numbers with Named Constants | Hide raw numbers behind well-named constants (`SECONDS_PER_DAY`, `LINES_PER_PAGE`). Exceptions where the raw number reads better: `feetWalked/5280.0`, `hourlyRate * 8`, `radius * Math.PI * 2`. "Magic number" also covers any non-self-describing token — `assertEquals(7777, Employee.find("John Doe")...)` has two. |
| **G26** | Be Precise | Don't assume the first match is the only match; don't use floating point for currency; don't skip locking because concurrent update "seems unlikely"; don't declare `ArrayList` where `List` will do; don't default everything to protected. Check for null if a function can return it. Imprecision is disagreement or laziness. |
| **G27** | Structure over Convention | Enforce design decisions with structure rather than convention. Naming conventions are good but inferior to structures that force compliance: a base class with abstract methods compels implementation; a switch over a nicely named enum does not. |
| **G28** | Encapsulate Conditionals | Extract a function that explains a conditional's intent. `if (shouldBeDeleted(timer))` beats `if (timer.hasExpired() && !timer.isRecurrent())`. |
| **G29** | Avoid Negative Conditionals | Negatives are harder to understand than positives. `if (buffer.shouldCompact())` beats `if (!buffer.shouldNotCompact())`. |
| **G30** | Functions Should Do One Thing | A function with multiple sections performing a series of operations does more than one thing — split it into several smaller functions that each do one thing. (Loop + test + act becomes `pay()` → `payIfNecessary(e)` → `calculateAndDeliverPay(e)`.) |
| **G31** | Hidden Temporal Couplings | Temporal coupling is often necessary but must never be hidden. Structure arguments so the required call order is obvious — a "bucket brigade" where each function produces what the next needs. Extra syntactic complexity is worth exposing the true temporal complexity. |
| **G32** | Don't Be Arbitrary | Have a reason for your structure and communicate it *through* the structure. Arbitrary-looking structure invites others to change it; consistent structure gets preserved. Public classes that aren't utilities of another class belong at the top level of their package, not nested. |
| **G33** | Encapsulate Boundary Conditions | Boundary conditions are hard to track — put their processing in one place. No swarms of `+1`s and `-1`s scattered around: extract `int nextLevel = level + 1;` and use `nextLevel` everywhere. |
| **G34** | Functions Should Descend Only One Level of Abstraction | Every statement in a function should sit at one level below the operation the function's name describes. Perhaps the hardest heuristic to follow, because humans mix levels seamlessly. Splitting along abstraction lines often uncovers further lines that were obscured. |
| **G35** | Keep Configurable Data at High Levels | A default or configuration constant known at a high level must not be buried in a low-level function — expose it as an argument passed down. FitNesse parses command-line args on the first executable line and holds defaults (`DEFAULT_PORT = 80`) at the top of `Arguments`. |
| **G36** | Avoid Transitive Navigation | If A collaborates with B and B with C, users of A shouldn't know about C — no `a.getB().getC().doSomething()`. The Law of Demeter / "Writing Shy Code." Widespread transitive navigation makes architectures rigid because interposing a new class means editing every call chain. |

## Java (J1–J3)

| Code | Title | Actionable gloss |
|---|---|---|
| **J1** | Avoid Long Import Lists by Using Wildcards | If you use two or more classes from a package, import the whole package. Wildcard imports create no true dependency (they just add to the name search path), so they keep modules less coupled; specific imports are hard dependencies. Name conflicts must still be imported or qualified specifically. |
| **J2** | Don't Inherit Constants | Don't hide constants at the top of an inheritance hierarchy by implementing a constants interface. Hideous — don't use inheritance to cheat the language's scoping rules. Use a static import instead. |
| **J3** | Constants versus Enums | Use enums, not `public static final int`. The meaning of an int gets lost; an enum belongs to a named enumeration. Enums can carry methods and fields, allowing far more expression and flexibility (e.g. `HourlyPayGrade` with an abstract `rate()`). |

## Names (N1–N7)

| Code | Title | Actionable gloss |
|---|---|---|
| **N1** | Choose Descriptive Names | Names are 90 percent of what makes software readable. Don't choose quickly; meanings drift as software evolves, so reevaluate frequently. Good names overload the code's structure with description and set readers' expectations about the rest of the module. |
| **N2** | Choose Names at the Appropriate Level of Abstraction | Don't name for implementation — name for the abstraction level of the class or function you're in. `Modem.dial(phoneNumber)` should be `connect(connectionLocator)` if some modems are hard-wired. Fix low-level names every time you pass over the code. |
| **N3** | Use Standard Nomenclature Where Possible | Base names on existing convention: pattern names (`AutoHangupModemDecorator`), language conventions (`toString`), and the team's own ubiquitous language (Evans, DDD). The more overloaded with project-relevant meaning, the easier to read. |
| **N4** | Unambiguous Names | Choose names that make the workings unambiguous. `doRename` that contains `renamePage` tells you nothing about the difference; `renamePageAndOptionallyAllReferences` is long but its explanatory value outweighs the length. |
| **N5** | Use Long Names for Long Scopes | Name length should track scope length. `i` and `j` are fine in a five-line loop and would be obfuscated by `rollCount`; over long distances, short names lose meaning, so go longer and more precise. |
| **N6** | Avoid Encodings | No type or scope encoding in names. Prefixes like `m_` or `f`, and project/subsystem prefixes like `vis_`, are useless and distracting in modern environments. Keep names free of Hungarian pollution. |
| **N7** | Names Should Describe Side-Effects | A name must describe everything the thing is or does; don't hide side effects behind a simple verb. `getOos()` that lazily *creates* the stream should be `createOrReturnOos`. |

## Tests (T1–T9)

| Code | Title | Actionable gloss |
|---|---|---|
| **T1** | Insufficient Tests | "That seems like enough" is not a metric. A suite should test everything that could possibly break; tests are insufficient so long as any condition is unexplored or any calculation unvalidated. |
| **T2** | Use a Coverage Tool! | Coverage tools report gaps in your testing strategy and make under-tested modules, classes and functions easy to find. Most IDEs mark covered lines green and uncovered red — quick way to spot unexercised `if`/`catch` bodies. |
| **T3** | Don't Skip Trivial Tests | They are easy to write and their documentary value exceeds their cost. |
| **T4** | An Ignored Test Is a Question about an Ambiguity | When requirements are unclear, express the question as a commented-out or `@Ignore`d test. Choose between the two based on whether the ambiguity is about something that would compile. |
| **T5** | Test Boundary Conditions | Take special care at boundaries — we usually get the middle of an algorithm right and misjudge the edges. |
| **T6** | Exhaustively Test Near Bugs | Bugs congregate. When you find one in a function, test that function exhaustively; you'll probably find the bug wasn't alone. |
| **T7** | Patterns of Failure Are Revealing | Diagnose by looking at *which* tests fail — "all inputs over five characters fail," "every negative second argument fails." Complete test cases ordered reasonably expose patterns; the red/green shape alone can spark the solution. |
| **T8** | Test Coverage Patterns Can Be Revealing | Looking at which code the *passing* tests do and don't execute gives clues to why the failing tests fail. |
| **T9** | Tests Should Be Fast | A slow test is a test that won't get run — when things get tight, slow tests get dropped from the suite. Do what you must to keep them fast. |

---

## Highest-Leverage Heuristics
The ones most frequently cited across Chapters 15–16 and most often actionable in review:
**G5 Duplication** · **G30 Functions Should Do One Thing** · **G34 Functions Should Descend Only One Level of Abstraction** · **N1 Choose Descriptive Names** · **G6 Code at Wrong Level of Abstraction** · **G19 Use Explanatory Variables** · **G28 Encapsulate Conditionals** · **G23 Prefer Polymorphism to If/Else or Switch/Case** · **G9 Dead Code** · **T2 Use a Coverage Tool!**

## Anti-patterns (cross-cutting)
- **Treating the list as a checklist**: "You don't become a software craftsman by learning a list of heuristics." The list implies a value system; professionalism comes from values that drive disciplines.
- **Citing a code without its title**: `[G28]` alone is opaque; `[G28] Encapsulate Conditionals` is a review comment.
- **Fixing smells without tests**: every heuristic-driven change in Ch15/Ch16 was validated by a green suite after each step.

## Key Takeaways
1. Cite heuristic code *and* title in reviews and commit messages — it turns taste into a shared, defensible standard.
2. Duplication (G5) is the single most important structural smell; every instance is a missing abstraction.
3. Abstraction-level violations (G6, G34, N2) are the hardest to see and the most expensive to leave.
4. Comments and dead code (C1–C5, F4, G9, G12) are pure deletions — the cheapest wins available.
5. Tests are first-class: coverage tools (T2), boundary tests (T5), and failure patterns (T7, T8) *locate* defects, not merely detect them.
6. Structure beats convention (G27): if a rule matters, make the compiler enforce it.
7. Completeness of this list is not the goal — the value system behind it is.

## Connects To
- **Ch 2 (Meaningful Names)**: N1–N7.
- **Ch 3 (Functions)**: F1–F4, G15, G20, G30, G34.
- **Ch 4 (Comments)**: C1–C5.
- **Ch 9 (Unit Tests)**: T1–T9.
- **Ch 15 (JUnit Internals)** and **Ch 16 (Refactoring SerialDate)**: worked applications of this catalog.
- **Appendix C**: cross-reference of where each heuristic is referenced in the text.
- **Fowler, _Refactoring_**: origin of "code smell" and of Feature Envy (G14).
- **Hunt & Thomas, _The Pragmatic Programmer_**: DRY (G5), Writing Shy Code / Law of Demeter (G36).
- **Evans, _Domain-Driven Design_**: ubiquitous language (N3).
- **GOF**: TEMPLATE METHOD and STRATEGY as duplication removers (G5).
