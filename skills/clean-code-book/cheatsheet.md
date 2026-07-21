# Clean Code — Cheatsheet

## Hard Thresholds Martin Commits To

| Thing | Limit |
|---|---|
| Function length | "hardly ever 20 lines"; blocks in `if`/`else`/`while` are one line — a call |
| Indent level in a function | 1 or 2, never more |
| Function arguments | 0 > 1 > 2; avoid 3; 4+ needs special justification and still shouldn't be used |
| Levels of abstraction per function | exactly one; every statement one level below the function's name (G34) |
| File length | aim ~200 lines, upper limit 500 (FitNesse: ~50k lines, avg ~65, largest ~400) |
| Line width | 80 is the arbitrary Hollerith limit; 100–120 fine; Martin's personal cap 120 |
| Asserts per test | one *concept* per test is the firm rule; one assert is a guideline |
| Switches per type of selection | at most one, and it must produce polymorphic objects (G23) |
| Class size | measured in responsibilities, not lines — 5 methods can be too many |
| Name length | tracks scope length (N5); single letters only as locals in short methods |
| TDD cycle | ~30 seconds |

## Decision Rules

**Design**
- If you can't derive a concise class name → it's too large. If the ~25-word description needs "and"/"or"/"but" → too many responsibilities.
- When rules conflict, Beck's order wins: **runs all tests > no duplication > expresses intent > fewest classes and methods**. Never trade the earlier for the later.
- When adding new *types* dominates → objects and polymorphism. When adding new *functions* dominates → data structures and procedures. (Data/Object Anti-Symmetry)
- When adding a feature requires a change in three places per new type → extract a class.
- When a class depends on volatile concrete details → invert to an abstraction (DIP).
- When adding new feature kinds → extend by subclassing so no existing class changes (OCP).

**Functions & names**
- If a name requires a comment, the name failed — rename it.
- If you can extract a function whose name isn't a restatement of its implementation → it did more than one thing.
- If a function divides into sections (declarations / initialization / work) → more than one thing.
- Never pass a boolean flag — split into two named functions.
- Split any function that both mutates and reports (Command Query Separation).
- If `try` appears, it is the first word in the function, and nothing follows `catch`/`finally`.
- Declare locals just above first use; define private functions just below first use (G10).
- Prefer nonstatic; when in doubt, make it nonstatic (G18).

**Comments**
- "Comments are always failures." Before writing one: try a function name, then a variable. Keep it only if both fail.
- Don't comment bad code — rewrite it. Inaccurate comments are far worse than none.
- A comment that forces you to look in another module has failed.
- Delete commented-out code and dead functions on sight — source control remembers, and nobody else will dare delete it (C5, F4, G9).

**Errors**
- Use unchecked exceptions in general application development — checked exceptions violate OCP and cascade through signatures. Exception: critical libraries where callers must catch.
- One exception class per area, distinguished by message; separate classes only when you'd catch one and let another pass.
- Never return null; never pass null. Return `Collections.emptyList()` or a Special Case object.

**Tests**
- No production code until a failing test exists; no more test than is sufficient to fail; no more production code than passes the current test.
- Write unit tests just *before* the production code that passes them.
- If tests are hard to write, coupling is too tight → apply DIP/DI/interfaces.
- Test code is as important as production code. Dirty tests are equal to or worse than no tests.
- A system that cannot be verified should never be deployed.

**Concurrency**
- Keep concurrency code separate — it has its own life cycle and failure modes (SRP for threads).
- Severely limit shared-data access; prefer copies — avoiding the lock usually beats creation/GC cost.
- Keep synchronized sections as small as the true critical section. Never call a locked section from another.
- Synchronize as little as possible, not as much as possible.
- I/O-bound → add threads. CPU-bound → add hardware.
- Deadlock threat → impose a global resource ordering (breaks circular wait).
- Get nonthreaded code working first; get shutdown working early. Never dismiss a spurious failure as a one-off.

**Refactoring**
- To write clean code, first write dirty code, then clean it.
- When you can see the next feature would leave an unfixable mess → stop adding features and refactor now. "A mess five minutes ago is very easy to clean up right now."
- Never make massive structural changes in the name of improvement — some programs never recover. Many tiny changes, tests green after each.
- Judge a refactor by the cost of the *next* change, not by how it looks.
- Measure coverage before refactoring legacy code (T2).

## Tells & Smells

| If you see… | You're probably in… |
|---|---|
| `if (x == null) x = new Impl()` in runtime code | construction tangled with use → move to `main`/DI (Ch 11) |
| `a.getB().getC().doD()` | train wreck / transitive navigation (G36) |
| Swarms of `+1` / `-1` around a variable | unencapsulated boundary condition (G33) — extract `nextLevel`, or rebase the variable to zero (Ch 15) |
| A predicate reading `shouldNot…` | invert it (G29) |
| Two twin methods differing only by a flag | split into two named functions (G15) |
| A method taking its own class as an argument | should be a true instance method (G14) |
| A base class naming or constructing a derivative | needs an Abstract Factory (G7) |
| `Manager`, `Processor`, `Super`, `Data`, `Info` in a name | weasel words hiding unfocused aggregation |
| Class members prefixed `m_` / `f` | strip them — the IDE supplies scope (N6) |
| A comment holding change history | delete it; source control owns that (C1) |
| Only tests break after you delete something | ask whether the feature exists at all (F4) |
| "I'll clean it up later" | LeBlanc's law: later equals never |

## Java-Specific (J1–J3)
- Import wildcards when you use ≥2 classes from a package (J1).
- Enums over `public static final int` (J3).
- Build with one command; test with one command (E1, E2).
