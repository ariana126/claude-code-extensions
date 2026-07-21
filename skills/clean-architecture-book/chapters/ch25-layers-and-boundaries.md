# Chapter 25: Layers and Boundaries

## Core Idea
Architectural boundaries exist everywhere, not just between UI, business rules, and database — and since building them all is expensive while retrofitting a missing one is more expensive, you must guess intelligently, then watch the system for the first inkling of friction.

## Frameworks Introduced
- **Decompose along axes of change, not along the UI/rules/database triple**: it is easy to think of systems as three components; for most systems the number is larger.
  - When to use: whenever a component can vary along more than one independent dimension.
  - How:
    1. List each way the component might need to vary. For a text game UI: the *human language* (English, Spanish) and the *communication mechanism* (shell window, SMS, chat application).
    2. Each independent axis is a potential architectural boundary.
    3. Interpose an abstract API component on each axis; the variations are implemented by concrete components that serve it.
    4. Point all source code dependencies at the abstract API, following the Dependency Rule.
  - Why it works: any number of UI components can then reuse the same game rules; the rules do not know, nor care, which human language is used.
  - Failure mode: stopping at the three-component picture leaves the second axis (delivery mechanism) unseparated, so adding SMS forces edits inside the language code.

- **API ownership rule: the API is defined and owned by the *user*, not by the implementer.**
  - How: `GameRules` communicates with `Language` through an API that `GameRules` defines and `Language` implements. `Language` communicates with `TextDelivery` using an API that `Language` defines but `TextDelivery` implements. Inside each component you find polymorphic `Boundary` interfaces used by that component's code and implemented by the next one out — in both directions. In each case the API defined by those `Boundary` interfaces is owned by the **upstream** component.

- **Data streams**: orienting the diagram so all arrows point up puts `GameRules` — the component containing the highest-level policies — at the top, and reveals the flow as separate streams.
  - How: trace input from `TextDelivery` (bottom left) rising through `Language`, translated into commands to `GameRules`; `GameRules` sends data down to `DataStorage` (lower right), and output back down through `Language` to `TextDelivery`. Two streams: one for communicating with the user, one for persistence, meeting at the top.
  - Not always two: add multiplayer and you add a network component, dividing the flow into three streams, all controlled by `GameRules`. As systems become more complex, the component structure may split into many such streams.

- **The watchful-eye discipline** (the chapter's actual decision procedure):
  1. Weigh the costs and determine where the architectural boundaries lie — which should be fully implemented, which partially, and which ignored.
  2. Recognize this is **not a one-time decision** made at the start of the project.
  3. **Watch.** Pay attention as the system evolves. Note where boundaries may be required.
  4. Watch for the **first inkling of friction** caused by those boundaries not existing.
  5. At that point weigh the cost of implementing versus the cost of ignoring, and review that decision frequently.
  6. Aim to implement each boundary right at the **inflection point where the cost of implementing becomes less than the cost of ignoring.**

## Key Concepts
- **Axis of change**: an independent dimension along which a component may need to vary; each one defines a potential architectural boundary.
- **Abstract component**: a component (shown with a dashed outline) that defines only an API, implemented by the components above or below it.
- **Upstream ownership**: the API across a boundary is defined and owned by the calling (higher-level) component.
- **Data stream**: one of the paths of information flow converging on the highest-level policy component.
- **Central Transform**: the older structured-design name for the top component where the streams meet (Page-Jones, *Practical Guide to Structured Systems Design*).
- **MoveManagement**: the lower-level `GameRules` policy dealing with the mechanics of the map — cavern connections, object locations, moving the player, determining events.
- **PlayerManagement**: the higher-level policy holding player health and the cost or benefit of each event; it receives declared events like `FoundFood` or `FellInPit` and decides whether the player wins or loses.
- **Over-engineering vs. under-engineering**: over-engineering is often much worse than under-engineering — but a needed boundary that does not exist is very expensive to add later, even with comprehensive test suites and refactoring discipline.

## Mental Models
- Think of "UI, business rules, database" as **the beginner's cut**, sufficient only for some simple systems.
- Use **"how many ways can this vary independently?"** to count boundaries — human language and delivery mechanism are two different axes hiding inside one "UI."
- Remember that **arrows point in the direction of source code dependencies, not the direction of data flow** — that is why a diagram of upward arrows can carry data downward.
- Think of the architect's job as **guessing intelligently and then watching**, not as deciding once. "You must see the future. You must guess — intelligently."
- Treat a boundary decision as an **option with a strike price**: exercise it at the inflection point where implementing becomes cheaper than ignoring.

## Worked Example
**Hunt the Wumpus, from three components to many.**

Start with the 1972 text adventure: the player types `GO EAST` or `SHOOT WEST`, and the computer responds with what the player sees, smells, hears, and experiences while hunting a Wumpus through caverns full of traps and pits. The naive picture is three components: UI, game rules, persistent state.

*First boundary — language.* Keep the text UI but decouple it from the game rules so the game can ship in different markets. `GameRules` communicates with the UI through a **language-independent API**; the UI translates that API into the appropriate human language. Now any number of UI components reuse the same game rules, which neither know nor care which language is in play.

*Second boundary — persistence.* The game state may live in flash, in the cloud, or just in RAM. `GameRules` must not know the details, so define another API it uses to talk to the data storage component, with dependencies directed inward per the Dependency Rule.

*Third boundary — delivery mechanism.* Language is not the only axis of change for the UI: the text might be delivered through a normal shell window, text messages, or a chat application. That is a second axis, so interpose a `TextDelivery` API between `Language` and the transport. `Language` is an abstract component implemented by `English` and `Spanish`; `TextDelivery` is implemented by concrete components such as `SMS`. `GameRules` owns the API `Language` implements; `Language` owns the API `TextDelivery` implements.

*Streams.* Orient all arrows upward and `GameRules` sits on top. Input rises from `TextDelivery` through `Language` into `GameRules`; data descends to `DataStorage`; output descends through `Language` back to the user. Two streams — user communication on the left, persistence on the right — meeting at the top.

*Crossing the streams.* Make it multiplayer over the net and a `Network` component adds a third stream, all controlled by `GameRules`.

*Splitting the streams.* The streams do not all merge into one component. Inside `GameRules`, `MoveManagement` handles map mechanics and declares events such as `FoundFood` or `FellInPit` to `PlayerManagement`, which tracks health and decides win or loss. Make it a massive multiplayer game — `MoveManagement` local to the player's computer, `PlayerManagement` on a server offering a micro-service API to all connected clients — and a full-fledged architectural boundary now exists between them.

*The point.* An absurdly simple program, implementable in 200 lines of Kornshell, is used as a proxy for a much larger system. You would not apply the clean architecture to the game itself. You apply this *reading* of it to systems where the boundaries matter.

## Key Takeaways
1. Stop at UI/business rules/database only for genuinely simple systems; most systems have more components than that.
2. Find boundaries by enumerating independent axes of change — one "UI" can hide several.
3. Let the upstream (higher-level) component define and own the API across each boundary; the downstream component implements it.
4. Draw dependency arrows, not data-flow arrows, and orient the diagram so the highest-level policy sits at the top.
5. Expect multiple data streams, and expect the top component itself to split into higher- and lower-level policies.
6. Fully implemented boundaries are expensive — and ignored boundaries are very expensive to add later, even with comprehensive test suites and refactoring discipline.
7. Over-engineering is often much worse than under-engineering, so guess intelligently, then watch for friction and implement at the inflection point where implementing costs less than ignoring.

## Connects To
- **Ch 24 (Partial Boundaries)**: the "which should be fully implemented, which partially, which ignored" decision this chapter poses is answered with those three techniques.
- **Ch 22 (The Clean Architecture)**: the Dependency Rule is what directs every arrow in the Wumpus diagrams.
- **Ch 26 (The Main Component)**: Hunt the Wumpus continues there as the concrete `Main`.
- **Ch 27 (Services: Great and Small)**: the `PlayerManagement` micro-service API is the bridge into that discussion.
- **YAGNI**: the wisdom this chapter accepts and then bounds.
- **Page-Jones, *Practical Guide to Structured Systems Design***: the Central Transform, the older name for the component where streams meet.
