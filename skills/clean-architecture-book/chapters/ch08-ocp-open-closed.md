# Chapter 8: OCP: The Open-Closed Principle

## Core Idea
A software artifact should be open for extension but closed for modification — and at the architectural level this means partitioning the system into components and arranging them in a dependency hierarchy that protects higher-level components from changes in lower-level ones. This is the most fundamental reason we study software architecture.

## Frameworks Introduced
- **The Open-Closed Principle (OCP)** — coined by Bertrand Meyer, 1988: *A software artifact should be open for extension but closed for modification.* Behavior should be extendible without modifying the artifact.
  - When to use: whenever a new requirement is a variation on existing behavior (a new presentation, a new delivery mechanism, a new data source). A good architecture reduces the amount of changed code to the barest minimum — ideally zero.
  - How:
    1. Apply the SRP: separate the things that change for different reasons (here: *calculating* the reported data vs. *presenting* it).
    2. Partition the resulting processes into classes.
    3. Group those classes into components (Controller, Interactor, Database, Presenters/Views).
    4. Organize the source code dependencies so every component boundary is crossed **in one direction only**.
    5. Point the arrows toward the components you want to protect.
  - The governing rule: **If component A should be protected from changes in component B, then component B should depend on component A.**
  - Why it works: source code dependency is the transmission medium of change. An arrow from A to B means A's source mentions B's name and B mentions nothing about A — so change cannot propagate backwards along the arrow.
  - Failure mode: if simple extensions to the requirements force massive changes to the software, the architects have engaged in a spectacular failure.

- **The hierarchy of protection ("level")**: rank components by how high-level their policy is; higher level = more protected.
  - Interactor is highest level (it holds the business rules — the central concern) and is therefore the most protected: changes to Database, Controller, Presenters, or Views have no impact on it.
  - Controller is peripheral to the Interactor but central to Presenters and Views.
  - Presenters are higher level than Views, lower level than Controller and Interactor.
  - Views are among the lowest-level concepts, so the least protected.

- **Directional control**: insert an interface purely to invert a dependency that would otherwise point the wrong way.
  - Example: `FinancialDataGateway` sits between `FinancialReportGenerator` and `FinancialDataMapper` to invert what would have been an Interactor → Database dependency. Same job for `FinancialReportPresenter` and the two `View` interfaces.

- **Information hiding**: insert an interface to stop a caller from learning too much about a callee's internals.
  - Example: `FinancialReportRequester` protects `FinancialReportController` from transitive dependencies on the `FinancialEntities` inside the Interactor. Software entities should not depend on things they don't directly use.

## Key Concepts
- **Open for extension / closed for modification**: new behavior arrives as new code, not as edits to old code.
- **Source code dependency**: A depends on B iff A's source mentions B's name; the only dependency direction that matters for protection.
- **Component**: a deployable grouping of classes; boundaries drawn as double lines in the diagram.
- **Level**: distance from the inputs and outputs; the Interactor holds the highest-level policies of the application.
- **Interactor**: the component containing the business rules — the central concern; everything else deals with peripheral concerns.
- **Directional control**: adding abstraction solely to make a dependency arrow point the desired way.
- **Information hiding**: adding abstraction to prevent transitive dependencies on internals.
- **Unidirectional component graph**: every double line crossed in one direction only.

## Reference Tables

| Component | Level | Protected from | Depends on (points toward) |
|---|---|---|---|
| Interactor | Highest — business rules | Database, Controller, Presenters, Views (i.e. everything) | nothing peripheral |
| Controller | High | Presenters, Views | Interactor (via `FinancialReportRequester`) |
| Presenters | Middle | Views | Controller / Interactor abstractions |
| Views | Lowest | (least protected) | Presenters |
| Database | Detail | — | Interactor's `FinancialDataGateway` |

Notation used in Figure 8.2: `<I>` = interface, `<DS>` = data structure; open arrowheads = *using*, closed arrowheads = *implements*/*inheritance*.

## Mental Models
- Think of the arrow as a **blast radius fence**: change flows only against the arrow, never with it.
- Use "who must be protected?" to decide direction — then make the *other* party do the depending.
- Think of every interface in a clean design as doing one of two jobs: **directional control** (fix the arrow) or **information hiding** (block transitive knowledge). If it does neither, question it.
- Treat "how much old code must change?" as the scoring function for any architecture proposal. Ideally zero.

## Anti-patterns
- **Treating OCP as a class-level trick only**: it guides classes and modules, but takes on far greater significance at the level of architectural components.
- **Letting the Interactor reference the Database or the Presenter directly**: the arrow now points from policy to detail, and every schema or UI change reaches the business rules.
- **Bidirectional component boundaries**: any double line crossed both ways destroys the protection hierarchy.
- **Transitive dependency leakage**: exposing the Interactor's entities to the Controller couples the Controller to internals it never uses (the same defect the ISP and the Common Reuse Principle address).
- **Recoiling from the "complexity" of the class diagram**: most of that complexity exists precisely to make dependencies point the correct direction.

## Worked Example
**The financial summary thought experiment.**

The system displays a financial summary on a web page: data is scrollable and negative numbers are rendered in red. Stakeholders now ask for the same information as a report printed on a black-and-white printer — properly paginated, with page headers, page footers, and column labels, and negative numbers surrounded by parentheses.

New code is obviously required. The architectural question is: *how much old code must change?* Answer: ideally zero.

Step 1 — apply the SRP. Generating the report involves two separate responsibilities: **calculating** the reported data and **presenting** it. An analysis procedure inspects the financial data and produces reportable data; two reporter processes format that data for web and printer.

Step 2 — apply the DIP to the dependencies. Partition the processes into classes and the classes into components: `Controller` (upper left), `Interactor` (upper right), `Database` (lower right), and four `Presenter`/`View` components (lower left). `FinancialDataMapper` implements `FinancialDataGateway`, but `FinancialDataGateway` knows nothing of `FinancialDataMapper` — so the Interactor does not depend on the Database. `FinancialReportPresenter` and the View interfaces do the same job for output. `FinancialReportRequester` hides the Interactor's internals from the Controller.

Result: adding the printed report means adding a new Presenter and View. The Interactor, which holds the highest-level policy, is untouched; the Controller is untouched. Every component boundary is crossed in one direction only, toward the thing being protected.

## Key Takeaways
1. State it as Meyer did: open for extension, closed for modification — behavior extendible without modifying the artifact.
2. OCP is one of the driving forces behind system architecture, not merely a class-design tip.
3. The operative rule: if A must be protected from B, then B depends on A.
4. Get there by SRP first (separate what changes for different reasons), then DIP (arrange the dependencies).
5. Rank components by level; the highest-level policy holder (the Interactor) gets the most protection, the Views the least.
6. Add interfaces deliberately for **directional control** or **information hiding**, and know which one you are buying.
7. Don't depend on things you don't directly use — transitive dependencies are a violation you'll meet again as the ISP and the Common Reuse Principle.

## Connects To
- **Ch 7 (SRP)**: supplies the separation OCP then arranges.
- **Ch 11 (DIP)**: supplies the inversion mechanism; the interfaces here are exactly DIP in action.
- **Ch 10 (ISP)** and **Ch 13 (Common Reuse Principle)**: both restate "don't depend on what you don't use."
- **Ch 22 (The Clean Architecture)**: the Interactor/Controller/Presenter/View split here is the concentric-circle architecture in embryo, and the one-directional double lines become the Dependency Rule.
- **Plugin architecture / Hexagonal Architecture**: same protection hierarchy expressed as ports and adapters.
