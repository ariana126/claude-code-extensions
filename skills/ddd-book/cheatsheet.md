# DDD Cheatsheet — Evans' Judgment, Compressed

## Decision Rules

| When… | Do… | Because… |
|---|---|---|
| A term appears in expert speech but not in the design | Chase it as a concept lead | A missing term is the earliest signal of a missing model element. *Doubly urgent when developers use it too.* |
| A scenario sentence comes out awkward to say | Change the model, not the sentence | Rough edges in a model are easy to *hear* before they're visible in code |
| A business rule sits in a guard clause | Name it as a domain object (Policy/SPECIFICATION) | Experts can't verify what they can't read |
| Domain experts don't understand the model | Fix the model | "If sophisticated domain experts don't understand the model, there is something wrong with the model" |
| An object needs identity that must survive DB round-trips | ENTITY with an explicit identity operation | Language `==` is lost on every retrieval and transmission |
| You care only *what* it is, not *which* | VALUE OBJECT, immutable | Immutability makes copying/sharing/FLYWEIGHT/denormalization free technical choices |
| You want a bidirectional association between two VALUES | Reclassify one — it has unrecognized identity | Without identity, "points back to the same" is meaningless |
| An operation won't sit on any ENTITY or VALUE | SERVICE, named as a verb, stateless | But try harder first — the common mistake is giving up too early and sliding into procedural code |
| Two users edit different parts of one invariant | The AGGREGATE boundary is wrong | Locking a line item let both saves violate the PO limit — and nobody knew |
| A relationship is high-contention and its rule is soft | Loosen it (copy the value in) | Copy the price into `Line Item`; correct history beats live coupling |
| You need a stored object and don't have a reference | REPOSITORY — but only for AGGREGATE roots that need it | Anything else muddies important distinctions |
| You want "find or create" | Don't | The distinction between new and existing usually matters in the domain |
| A command both calculates and mutates | Split it, then push the calculation into a VALUE OBJECT | Enables intermediate combination *and* analytical reuse |
| The honest post-condition is counterintuitive | Look for a missing concept — after checking it isn't serving a real requirement | Paint mixing's odd volume rule existed to report unmixed paints |
| Refactorings keep rippling across many concepts | Your model doesn't fit the domain's contours | Localized refactoring = fit; sweeping = message to deepen the model |
| Two teams share code without a named relationship | Stop sharing until you name it | The `Charge` collision shipped silently and crashed the tax report |
| An upstream team won't serve you | SEPARATE WAYS, CONFORMIST, or ANTICORRUPTION LAYER — nothing else | "Altruism may motivate upstream developers to make promises, but they are unlikely to be fulfilled" |
| An off-the-shelf component has a large interface | CONFORM to its model | "If it is good enough to give you value, there is probably knowledge crunched into its design" |
| Two feature sets never call each other or share data | SEPARATE WAYS | Integration is always expensive; sometimes the benefit is ~zero |
| Deciding between two desirable refactorings | The one touching the CORE DOMAIN wins | |
| You must choose what to keep secret | The CORE DOMAIN — and nothing else | No need to waste effort concealing the rest |
| A framework constrains your CORE | Back it off, redraw the CORE, or admit you have no special needs | Those are the only three explanations |
| A breakthrough looks right but scary | Ask: time to parity? solvable otherwise? cost of delay with an installed base? do *we* think it's right? | The four questions that unblocked Share Pie |
| You can fully justify a refactoring | You waited too long | Costs are already incurred and the target is more embedded |
| A large-scale structure forces many awkward designs | Modify or discard it | An ill-fitting structure is worse than none |
| Deciding whether a design pattern belongs in the domain layer | Does it say something about the *conceptual* domain? | COMPOSITE yes; FLYWEIGHT no |

## Thresholds & Defaults

| Thing | Value |
|---|---|
| BOUNDED CONTEXT team size | **< 10 people**; roughly **one team per context** |
| CONTINUOUS INTEGRATION threshold | Any context **larger than a two-person task**; fragmentation starts at 3–4 people |
| SHARED KERNEL merge cadence | Less often than internal CI — e.g. **daily CI → weekly kernel merge** |
| RESPONSIBILITY LAYERS count | **4, at most 5** |
| DOMAIN VISION STATEMENT | **~1 page** |
| Distillation document | **3–7 sparse pages** |
| Anchor diagram size | **3–5 objects** |
| Exploration team | **4–5 people**, 30–90 min, 2–3 meetings over a few days |
| Unintegrated change lifetime | A "reasonably small upper limit" — most Agile teams merge **daily** |
| SPECIFICATION operators | **Implement only AND** unless you need more |
| CORE DOMAIN size | **Small.** Be minimalist; move a class in only if your stories need it |

## Layer Placement (LAYERED ARCHITECTURE)

| Question | Answer |
|---|---|
| "Every credit has a matching debit" | **Domain** — never the application layer |
| Deciding *when* to send a notification | **Application** |
| Knowing *how* to send it | **Infrastructure** |
| Which account to debit for a transfer | **Domain service** — "funds transfer" is meaningful banking language |
| Exporting transactions to a spreadsheet | **Application service** — "file format" has no domain meaning |
| Test for a technical service | It should **lack any business meaning at all** |
| State reflecting the business situation | **Domain** |
| State reflecting a task's progress | **Application** |

## Tells & Smells

| You see… | You're probably in… |
|---|---|
| Experts say "yes, but…" about a technically fine model | Shallow model; keep crunching for a deep one |
| Requirements keep arriving that complicate the design | Wrong model, not a hard domain |
| Rounding/arithmetic bugs surviving ever-more-complex code | A wrong constraint tying two things together |
| A model term the experts don't use or don't understand | A concept you invented from incomplete understanding (`Loan Investment`) |
| New hires immediately suggest the "missing obvious" classes | Your model is genuinely deep (they haven't done the discovery) |
| Objects named `…Manager`, `…Doer`, with no state or domain meaning | A SERVICE in disguise |
| Every new requirement adds complexity in the same place | Dig there — the missing concept is under it |
| Two people use the same term meaning different things | **False cognate** — the most insidious splinter |
| The same concept implemented twice with conversions | **Duplicate concepts** — reanalysis of the second never actually happens |
| Confusion of language between teams | The *earliest* warning of a broken BOUNDED CONTEXT |
| A batch script that keeps getting more complicated | "A place where we swept stuff under the rug" — implicit domain logic |
| Restricted-edit objects clustered near freely-edited ones | An implicit **KNOWLEDGE LEVEL** |
| A "thing-thing" type relationship | Same |
| A document whose terms never appear in speech or code | It's wrong, too big, or unimportant — archive it |
| The best developers on infrastructure, juniors on the CORE | The classic project-killing staffing pattern |
| Elegant peripheral features shipping while the CORE tangles | Same, in progress |
| A "flexible" model built before any application uses it | The insurance time-zone failure |
| A structure with many flagged exceptions | Change or discard the structure |
| Every architecture change is a heroic battle | Developers will dumb down the app or subvert the structure entirely |

## The Three Strategic Principles

| Principle | Answers | Primary artifact |
|---|---|---|
| **Context** | *Where does this model mean what it says?* | CONTEXT MAP |
| **Distillation** | *What actually matters here?* | DOMAIN VISION STATEMENT + CORE |
| **Large-scale structure** | *What's the story of the whole system?* | RESPONSIBILITY LAYERS et al. |

## Assessment Checklist (start any project here)
1. Can you draw a **consistent** CONTEXT MAP?
2. Is there a UBIQUITOUS LANGUAGE, and is it rich enough to help development?
3. Is the CORE DOMAIN identified? **Can you write the vision statement?**
4. Does the technology work *for or against* MODEL-DRIVEN DESIGN?
5. Do the developers have the necessary technical skills?
6. Do they know the domain — and are they **interested** in it?

## Refactoring Triggers (Ch 13)
Refactor when: the design **doesn't express the team's current understanding**; important concepts are **implicit and you see how to surface them**; or an important part can be made **suppler**.
Don't: the day before a release; for technical virtuosity that misses the domain; or toward a "deeper model" **you couldn't convince a domain expert to use**.
