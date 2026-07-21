# Chapter 7: SRP: The Single Responsibility Principle

## Core Idea
The SRP is not "a module should do one thing" — it is **"A module should be responsible to one, and only one, actor."** Separate code that different actors depend on, because putting it together couples people who should never affect each other.

## Frameworks Introduced
- **The Single Responsibility Principle (SRP)**: *A module should be responsible to one, and only one, actor.*
  - Evolution of the wording, in Martin's own order:
    1. "A module should have one, and only one, reason to change."
    2. "A module should be responsible to one, and only one, user or stakeholder."
    3. Final: "A module should be responsible to one, and only one, **actor**."
  - "User" and "stakeholder" are the wrong words because more than one person usually wants the same change. The right unit is the *group* requesting the change — the **actor**.
  - **Module** = the simplest definition, a source file. Where a language has no source files, a module is "a cohesive set of functions and data structures."
  - When to use: any time one class/source file is edited by people answering to different parts of the org chart.
  - How:
    1. For each public method, name the actor who specifies and consumes it (accounting/CFO, HR/COO, DBAs/CTO).
    2. If two methods trace to different actors, they belong in different classes.
    3. Move the functions out into per-actor classes; leave the data behind as a methodless data structure (`EmployeeData`) shared by all three.
    4. Forbid the three classes from knowing about each other — that is what kills accidental duplication.
    5. If instantiating and tracking three objects is painful, put a **Facade** in front of them.
  - Why it works: cohesion is the force that binds together the code responsible to a single actor; separating by actor makes each change land in exactly one file, so no team's change can silently break another team's behavior.
  - Failure mode: applied as "one class, one function," it shatters the design pointlessly. Each actor's class still holds a large family of private methods — the split is by *audience*, not by verb count.

- **The Facade pattern (as an SRP remedy)**: a thin `EmployeeFacade` that contains very little code and is responsible only for instantiating and delegating to the function classes.
  - Variant: keep the single most important business rule in the original `Employee` class and use *that* class as the Facade for the lesser functions — for designers who want key business rules to stay near the data.

## Key Concepts
- **Actor**: the group of one or more people who require a particular change to the system.
- **Reason to change**: a users/stakeholders-driven pressure on a module, not a technical category.
- **Cohesion**: the force that binds together code responsible to a single actor.
- **Accidental duplication**: two actors' behavior converging on one shared helper, so a change made for one silently rewrites the other.
- **Module**: a source file, or where none exists, a cohesive set of functions and data structures.
- **Scope (of a class)**: outside a class holding a family of methods, no one knows its private members exist.
- **Common Closure Principle**: the SRP restated at the component level.
- **Axis of Change**: the SRP restated at the architectural level; it is responsible for the creation of architectural boundaries.

## Mental Models
- Think of each public method as having an **org-chart owner**. Draw the org chart above the class; every distinct box above it is a violation.
- Use "who gets fired when this is wrong?" as the actor test — the CFO, the COO, and the CTO are three answers, so three classes.
- Think of shared helper functions as **couplings between departments**, not as DRY wins. Duplicate code serving different actors is not duplication at all.
- Treat merge conflicts as diagnostic data: two people editing one file for unrelated reasons is the SRP telling you where the seam is.

## Anti-patterns
- **Reading SRP as "a module should do just one thing"**: that principle exists for *functions* during refactoring, at the lowest level — it is not one of the SOLID principles.
- **Deduplicating across actors**: extracting `regularHours()` because two methods happen to compute the same thing today couples the CFO's team to the COO's team.
- **God classes edited by many teams**: guarantees merges, and merges are risky affairs no tool handles in every case.
- **Splitting by technical verb instead of by actor**: yields many one-method classes and none of the protection.

## Code Examples
```java
class Employee {
    public Money calculatePay();   // spec'd by Accounting  -> CFO
    public String reportHours();   // spec'd by HR          -> COO
    public void save();            // spec'd by DBAs        -> CTO

    private int regularHours();    // shared by the first two: the trap
}
```
- **What it demonstrates**: three actors coupled inside one source file, with a shared private algorithm that turns a CFO-requested tweak into a silent HR data corruption.

## Worked Example
**The `Employee` class from a payroll application.**

`Employee` exposes `calculatePay()`, `reportHours()`, and `save()`. `calculatePay()` is specified by accounting (CFO); `reportHours()` by human resources (COO); `save()` by the DBAs (CTO). Three actors, one file.

*Symptom 1 — accidental duplication.* Both `calculatePay()` and `reportHours()` need non-overtime hours, so a conscientious developer factors the algorithm into `regularHours()`. Later the CFO's team asks for a tweak to how non-overtime hours are computed. A developer finds `regularHours()` via `calculatePay()`, changes it, tests it carefully, and ships; accounting validates the result. Nobody notices `reportHours()` also calls it. HR keeps reading reports that are now wrong, and by the time the problem surfaces the bad data has cost the COO's budget millions.

*Symptom 2 — merges.* The CTO's DBAs want a schema change to the `Employee` table; the COO's HR clerks want a different hours-report format. Two developers on two teams check out `Employee`, and their changes collide. The merge puts both the CTO and the COO at risk — and plausibly the CFO too.

*Solution.* Separate the data from the functions. `EmployeeData` becomes a simple data structure with no methods. `PayCalculator`, `HourReporter`, and `EmployeeSaver` each hold only the source code for their own actor and are **not allowed to know about each other**, so accidental duplication cannot occur. The cost is three objects to instantiate and track, so add `EmployeeFacade` — a near-empty class that instantiates the three and delegates to them. Alternatively, keep the most important business rule inside `Employee` itself and let `Employee` act as the Facade for the lesser functions.

Objection answered: each of these classes is far from a single function. Calculating pay, generating a report, or persisting data each require many private methods; each class is a scope whose private family is invisible from outside.

## Key Takeaways
1. State the principle as "responsible to one, and only one, actor" — never as "does one thing."
2. Identify actors by org chart, not by subject matter: accounting/CFO, HR/COO, DBAs/CTO.
3. Separate the code that different actors depend on; keep the resulting classes ignorant of one another.
4. Resist DRY across actor boundaries — shared helpers are the mechanism of accidental duplication.
5. Use a Facade (or the original class as Facade) to restore convenience after splitting.
6. Frequent merges in one file are a symptom, not a tooling problem.
7. The same idea recurs upward: Common Closure Principle at the component level, Axis of Change at the architectural level.

## Connects To
- **Ch 8 (OCP)**: separating what changes for different reasons is step one; OCP then arranges the dependencies between those separated pieces.
- **Ch 13 (Component Cohesion)**: the SRP becomes the Common Closure Principle for components.
- **Ch 17 (Boundaries)**: the Axis of Change is what architectural boundaries are drawn along.
- **Conway's Law**: actors are organizational units, so the SRP is effectively Conway's Law applied to source files.
- **Facade pattern (GoF)**: the standard remedy for the instantiation burden created by splitting.
