# Chapter 17: Boundaries: Drawing Lines

## Core Idea
Software architecture is the art of drawing boundaries — lines that separate elements and forbid those on one side from knowing about those on the other. Draw them between things that matter (business rules) and things that don't (GUI, database, frameworks), with all arrows pointing toward the business rules, so premature decisions can never pollute the core.

## Frameworks Introduced

- **Drawing Boundaries**: partition the system into components, decide which are core business rules and which are plugins, then arrange the code so the arrows between components point in one direction — toward the core business.
  - When to use: earliest lines before any code is written (to defer decisions); later lines as the system reveals its axes of change.
  - How:
    1. Identify what saps people-power: **coupling — especially coupling to premature decisions.**
    2. A decision is premature if it has nothing to do with the business requirements — the use cases. Frameworks, databases, web servers, utility libraries, dependency injection all qualify.
    3. Put the detail behind an interface owned by the business side. `BusinessRules` use a `DatabaseInterface` to load and save; `DatabaseAccess` implements it and drives the actual `Database`.
    4. Draw the boundary across the inheritance relationship, just below `DatabaseInterface`. Both arrows leave `DatabaseAccess` — nothing knows `DatabaseAccess` exists.
    5. At component scale: `DatabaseInterface` classes live in the `BusinessRules` component; `DatabaseAccess` classes live in the `Database` component. So the `Database` knows about the `BusinessRules`, and not the reverse.
  - Why it works: the `Database` component holds the code that translates `BusinessRules` calls into the database's query language — that translation code is what knows about the business rules. Hence the `Database` doesn't matter to the `BusinessRules`, but cannot exist without them, and can be swapped for Oracle, MySQL, Couch, Datomic, or flat files.

- **Boundaries are drawn where there is an axis of change.**
  - When to use: as the test for whether a proposed line is real.
  - How: components on one side must change at different rates and for different reasons than components on the other. GUIs change at different times and rates than business rules — draw a line. Business rules change for different reasons than DI frameworks — draw a line.
  - Why it works: this is simply the Single Responsibility Principle again. **The SRP tells us where to draw our boundaries.**

- **Plugin Architecture**: treat the database and the GUI as plugins to the core, exactly as third-party plugin systems do.
  - When to use: for every component that is optional or that could be implemented in many different forms.
  - How: keep core business rules separate from and independent of such components; the UI can then be web, client/server, SOA, console, or anything else, and the store can be SQL, NOSQL, or file-system based. Replacements need not be trivial — moving a web UI to client/server may require reworking some communication — but the presumption of a plugin structure makes such a change *practical* rather than impossible.
  - Failure mode avoided: **plugin architecture creates firewalls across which changes cannot propagate.** If the GUI plugs into the business rules, GUI changes cannot affect them.

- **The Plugin Argument**: use dependency direction to decide who can hurt whom.
  - When to use: whenever you want a module to be immune to changes elsewhere.
  - How: ReSharper's source code depends on Visual Studio's. JetBrains (Russia) and Microsoft (Redmond) could hardly be more separate teams, yet nothing the ReSharper team does can disturb the Visual Studio team, while the Visual Studio team could completely disable the ReSharper team. That asymmetry is the one you want internally: business rules must not break when someone changes a web page format or a database schema.

## Key Concepts
- **Boundary**: a line separating software elements, restricting those on one side from knowing about those on the other.
- **Premature decision**: any decision that has nothing to do with the business requirements — frameworks, databases, web servers, utility libraries, DI.
- **Axis of change**: the seam where components on either side change at different rates and for different reasons; boundaries go here.
- **Plugin**: a component holding necessary functions not directly related to the core business, depending on the core and replaceable without the core's knowledge.
- **"The IO is irrelevant"**: the principle developers and customers most often miss — the GUI is not the system.
- **Download and Go**: the FitNesse rule that nothing produced should require downloading more than one jar file; it drove many architectural decisions.
- **Topology vs. architecture**: three-tier is a topology, not an architecture — exactly the kind of decision a good architecture defers.

## Mental Models
- **Think of the dependency arrow as "who cares about whom."** The less relevant component depends on the more relevant one; the GUI cares about the business rules, never the reverse.
- **Use the video game test on any UI-centric argument.** Behind the screen, mouse, buttons, and sounds there is a model — data structures and functions — that would happily execute its duties, modeling every event in the game, with nothing ever displayed. The interface does not matter to the model.
- **Think of the database as a tool the business rules use *indirectly*.** All the business rules need to know is that a set of functions can fetch or save data — not the schema, not the query language.
- **Use "could a stranger implement this side in a day?" as a boundary quality check** — a FitNesse customer wrote `MySqlWikiPage` and had the whole system on MySQL a day later.

## Worked Example

**FitNesse: deferring the database into nonexistence.** Started in 2001 by Martin and his son Micah as a simple wiki wrapping Ward Cunningham's FIT tool for acceptance tests.

1. **Own web server.** Before Maven "solved" the jar problem, the "Download and Go" rule (never more than one jar) drove a decision to write a bare-bones web server rather than adopt an existing one — absurd-sounding, but a bare-bones server is simple, and it postponed the web framework decision for years. (Velocity was slipped in much later.)
2. **A line, not a database.** MySQL was in the back of their minds, but they made the decision *irrelevant* by putting an interface between all data access and the repository: `WikiPage`, with the methods needed to find, fetch, and save pages.
3. **`MockWikiPage`** — methods stubbed out. For three months they built wiki-text-to-HTML translation, which needed no storage at all.
4. **`InMemoryPage`** — when stubs became insufficient, a derivative managing a hash table of pages in RAM. This carried them for a full year: the entire first version worked — creating pages, linking, wiki formatting, running FIT tests — with no ability to save anything.
5. **`FileSystemWikiPage`** — when persistence was finally needed, writing the hash tables to flat files was easy, so MySQL was skipped again.
6. Three months later flat files were judged good enough; MySQL was abandoned entirely — the decision deferred into nonexistence.
7. **`MySqlWikiPage`** — a customer who wanted MySQL was shown the `WikiPage` architecture and returned a day later with the whole system running on MySQL. (It was bundled for a while, nobody used it, and even its author dropped it.)

Payoff: 18 months of development with **no database running** meant no schema issues, no query issues, no database server, password, or connection-time issues — and fast tests, because nothing slowed them down.

**The two sad stories, for contrast.** Company P webified a successful 1980s desktop app with a three-tier "architecture" for a server farm: every domain object instantiated in GUI, middleware, and database tiers. Adding one field to a record meant changing three classes, several inter-tier messages, four protocols (data traveled both ways), eight protocol handlers, three executables. They developed for years running all three processes on one machine — and never sold a system that required a server farm. Company W hired an architect who built an enterprise-scale SOA: adding a contact's name, address, and phone to a sales record meant querying the `ServiceRegistry` for the `ContactService` ID, sending `CreateContact` with dozens of fields the programmer had no data for, then jamming the new ID into the sales record and sending `UpdateContact` to the `SaleRecordService`. Testing required firing up every service, the message bus, and the BPel server. Nothing is intrinsically wrong with structuring around services; the error was **premature adoption**.

## Key Takeaways
1. Draw lines between things that matter and things that don't: GUI ↔ business rules, database ↔ business rules, database ↔ GUI.
2. The point of early lines is to defer decisions and keep them from polluting core business logic; the enemy is coupling to premature decisions.
3. Put the database behind an interface that the business rules own — then the database component depends on the business rules, and any database will do.
4. The IO is irrelevant. The model does not need the interface.
5. Treat optional or many-formed components as plugins; the plugin structure is a firewall against change propagation.
6. Aim for the ReSharper/Visual Studio asymmetry: decide deliberately which modules are immune to which.
7. Boundaries belong on axes of change — this is the SRP telling you where to cut.
8. Dependency arrows point from lower-level details to higher-level abstractions: the Dependency Inversion Principle and the Stable Abstractions Principle at architectural scale.

## Connects To
- **Ch 15 (What Is Architecture?)**: boundaries are the concrete mechanism for "leave as many options open as possible, for as long as possible."
- **Ch 16 (Independence)**: company P and company W are what premature choice of decoupling mode looks like in practice.
- **Ch 18 (Boundary Anatomy)**: the physical forms a boundary can take and what each crossing costs.
- **Ch 20 (Business Rules)**: defines the core these lines are drawn around.
- **Single Responsibility Principle**: tells you where the boundaries go.
- **Dependency Inversion Principle / Stable Abstractions Principle**: justify the direction of every arrow.
- **Hexagonal Architecture / Ports and Adapters**: the same plugin-around-a-core shape under another name.
