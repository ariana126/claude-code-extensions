# Chapter 23: Presenters and Humble Objects

## Core Idea
The **Humble Object pattern** splits behavior into a hard-to-test half stripped to its barest essence and an easy-to-test half — and that split almost always lands exactly on an architectural boundary. The Clean Architecture is full of Humble Object implementations.

## Frameworks Introduced
- **Humble Object Pattern** (Meszaros, *xUnit Patterns*, p. 695): originally identified as a way to help unit testers separate behaviors that are hard to test from behaviors that are easy to test.
  - When to use: at any boundary where something untestable (screen, database, network, framework) meets logic you want under test — and, inversely, use it to *discover* boundaries you had not drawn.
  - How:
    1. Take the module that mixes hard- and easy-to-test behavior.
    2. Split it into two modules or classes.
    3. Make one **humble**: it contains all the hard-to-test behaviors, stripped down to their barest essence — it moves data, it does not process data.
    4. Put all the testable behaviors that were stripped out into the other module.
    5. Define a simple data structure between them; the testable half fills it, the humble half consumes it.
    6. Treat the seam as an architectural boundary and enforce the Dependency Rule across it.
  - Why it works: the untestable half becomes so trivial that not testing it costs nothing, while everything with judgment in it moves into a class you can drive with plain unit tests. Testability has long been known to be an attribute of good architectures; this pattern is why.
  - Failure mode: leaving *any* processing in the humble half — a format decision, a conditional, a computation in the View — puts untestable judgment back on the wrong side of the line.

- **Presenter / View split**: the canonical Humble Object instance for GUIs.
  - How: the **View** is the humble object — as simple as possible, it moves data into the GUI but does not process it. The **Presenter** is the testable object — it accepts data from the application and formats it for presentation into the **View Model**, so the View can simply move it to the screen.
  - Rule for the View Model: anything and everything that appears on the screen and that the application has some control over is represented as a **string, a boolean, or an enum**. Nothing is left for the View to do other than load the data from the View Model into the screen.

- **Database Gateways** (Fowler, *Patterns of Enterprise Application Architecture*, p. 466): polymorphic interfaces between the use case interactors and the database, containing methods for **every create, read, update, or delete operation** the application can perform.
  - How: name each method for the query it answers — e.g. `UserGateway.getLastNamesOfUsersWhoLoggedInAfter(Date)` returning a list of last names. Declare the interface in the use case layer; implement it in the database layer. The *implementation* is the humble object: it simply uses SQL, or whatever the interface to the database is.
  - The interactors are **not humble** — they encapsulate application-specific business rules — but they are **testable**, because gateways can be replaced with stubs and test-doubles.

## Key Concepts
- **Humble object**: the half containing all the hard-to-test behavior, reduced to its barest essence.
- **View Model**: a simple data structure of strings, booleans, and enums holding everything the screen will display.
- **Presenter**: the testable object that formats application data (a `Date`, a `Currency`) into the View Model.
- **Database gateway**: a polymorphic interface with one method per CRUD operation the application performs; SQL is not allowed in the use cases layer.
- **Data Mapper**: the honest name for an ORM — it loads data into data structures from relational database tables.
- **Object vs. data structure**: an object's users cannot see its data (it is private) and so see only a set of operations; a data structure is a set of public data variables with no implied behavior.
- **Service listener**: the input-side humble object that receives data from a service interface and formats it into a simple data structure for the application.

## Mental Models
- Think of the humble half as **a conveyor belt, not a workshop**: it carries finished goods; it never manufactures.
- Use "**can I unit-test this?**" as a boundary detector. Where the answer flips from yes to no, you have found an architectural boundary — the Presenter/View line is one of many.
- Think of ORMs as **data mappers sitting in the database layer**, forming another Humble Object boundary between the gateway interfaces and the database — not as a mapping between objects and tables, because there is no such thing as an object relational mapper.
- Use the **`Date` test** on any Presenter: if the application hands over a `Date` and the View is the thing that formats it, the split is wrong.

## Anti-patterns
- **Formatting in the View**: turning a `Currency` into a string with decimal places and markers, or deciding a negative value should be red, inside the untestable half. The Presenter should have set a boolean flag in the View Model.
- **SQL in the use cases layer**: bypasses the gateway interface and drags the database inward across a boundary.
- **Believing in the "ORM"**: objects are not data structures; treating a mapper as if it produced business objects smuggles persistence concerns into the domain.
- **Making the interactor humble**: interactors encapsulate application-specific business rules; strip them and the logic ends up somewhere untestable.
- **Passing service payloads straight into the application**: without a service listener converting to a simple data structure, the external format becomes an inward dependency.

## Worked Example
**A screen full of money, buttons, and menu items.**

The application wants a date displayed in a field. It hands the Presenter a `Date` object; the Presenter formats it into an appropriate string and places it in the View Model, where the View can find it.

The application wants money on the screen. It passes a `Currency` object; the Presenter formats it with the appropriate decimal places and currency markers into a string in the View Model. If that value should be turned red when negative, the Presenter sets a simple boolean flag in the View Model.

Every button on the screen has a name — a string in the View Model, placed there by the Presenter. If a button should be grayed out, the Presenter sets a boolean flag. Every menu item name is a string loaded by the Presenter. Radio buttons, check boxes, and text fields get their names loaded into appropriate strings and booleans. A table of numbers becomes a table of properly formatted strings.

Result: the View's entire job is to move data from the View Model to the screen. It is humble, and everything with a decision in it is under unit test.

The same shape recurs on the persistence side: `UserGateway.getLastNamesOfUsersWhoLoggedInAfter(aDate)` is declared where the interactor lives; the implementing class in the database layer is humble, doing nothing but running the SQL. On the service side: the application loads simple data structures and passes them across the boundary to modules that format and send them; inbound, service listeners receive data from the service interface and format it into a simple data structure that crosses back.

## Key Takeaways
1. Split any hard-to-test behavior into a humble half (barest essence, no processing) and a testable half.
2. The View moves data; the Presenter decides everything — strings, booleans, enums, all precomputed in the View Model.
3. Where testability changes, an architectural boundary is lurking. Use the pattern to find boundaries, not just to serve them.
4. Declare database gateways as polymorphic interfaces in the use case layer, one method per CRUD operation; keep all SQL in the humble implementation.
5. Interactors are not humble but are testable — stub the gateways.
6. ORMs are data mappers and belong in the database layer, forming a Humble Object boundary between gateway interfaces and the database.
7. Communication across an architectural boundary will almost always involve some kind of simple data structure.

## Connects To
- **Ch 22 (The Clean Architecture)**: presenters, views, controllers, and gateway implementations all live in the Interface Adapters circle; this chapter explains *why* they split where they do.
- **Ch 24 (Partial Boundaries)**: when the full reciprocal-interface boundary is too costly, a Humble Object split may still be worth keeping.
- **Ch 28 (The Test Boundary)**: testability as an architectural attribute, taken further.
- **Meszaros, *xUnit Patterns*** and **Fowler, *PoEAA***: sources for Humble Object and Database Gateway respectively.
- **MVP / MVVM**: the industry names for the Presenter/View Model arrangement described here.
