# Patterns & Techniques — BDD in Action, 2nd Edition

## Impact Mapping
**When to use**: Strategic planning; deriving features from goals rather than accepting a feature list.
**How**: Build a mind map answering five questions — **Pain point** (why, and how measured?) → **Goal** (improve what, by how much?) → **Actor** (who helps *or hinders*?) → **Impact** (what behavior change?) → **Deliverables** (what features support it?).
**Trade-offs**: Produces many candidate deliverables, which can obscure the high-impact ones. Not a plan — a living document with metrics attached to each assumption. Run it in **reverse** (features → goals) to prioritize an existing backlog objectively.

## Pirate Canvas
**When to use**: Breadth-first discovery across a whole business ecosystem, when you don't yet know which goal to pursue.
**How**: Draw five columns (Acquisition, Activation, Retention, Referral, Return). Top half: ask "What sucks?" per column, five-whys to root cause, attach a measure. Bottom half: convert each pain point into Why (measurable goal) → Who → How (behavior change) → What (deliverable).
**Trade-offs**: Deliberately keeps only the most valuable deliverables per metric — "a forest of impacts and deliverables will make it harder to focus." Deliverables often aren't software at all.

## Popping the Why Stack
**When to use**: Any time a stakeholder arrives with a feature request rather than a problem.
**How**: Ask "why" / "how does this benefit users or stakeholders?" repeatedly. Rule of thumb: five questions reaches a viable business goal.
**Trade-offs**: Can feel like interrogation; frame as building shared understanding. Expect the real value model to differ from the stated one.

## Hypothesis-Driven Development
**When to use**: Every proposed feature, in the Speculate phase.
**How**: "We believe *\<capability\>* will result in *\<outcome\>*. We will know this to be true when *\<measurable result\>*." Then find the cheapest experiment that could disprove it.
**Trade-offs**: Requires the discipline to actually collect the metric in the Validate phase and to abandon features the data rejects.

## Real Options
**When to use**: Any decision where you lack information and committing early would foreclose alternatives.
**How**: Three principles — options have value; options expire; never commit early unless you know why. Identify each option's expiry (time to integrate before the deadline) and push expiry dates back where you can.
**Trade-offs**: Options have a price (abstraction layers, configurability, up-front discussion). And the common misreading: **delay only until you have enough information, then act as fast as possible.** Deferral is not a virtue in itself.

## Deliberate Discovery
**When to use**: Sequencing work within a feature.
**How**: Identify the stories with the most uncertainty and tackle those first; re-review the remaining stories in light of what you learned.
**Trade-offs**: Runs against the natural tendency to do easy stories first, and against velocity optics early in an iteration.

## Example Mapping
**When to use**: Enumerating business rules for a story quickly, breadth-first.
**How**: Yellow card (story) at top; blue cards (rules) beneath; green cards (examples/counterexamples) per rule, named "The one where…"; pink cards for unanswerable questions. Timebox 25–30 min, facilitate, then vote on whether you understand enough to start.
**Trade-offs**: Superficial by design — details come in Formulate. Needs a facilitator or the team forgets to record. Newly discovered out-of-scope rules tell you where to slice the story.

## Feature Mapping
**When to use**: Workflows, user journeys, and data transformations — where flows matter more than rule enumeration.
**How**: Start from one concrete end-to-end example; break it into **step** cards (yellow) leading to **consequence** cards (mauve). Interrogate each step: "What else could happen here? Why is this detail significant?" Add rows for variations; an arrow means "same steps as above."
**Trade-offs**: Slower than Example Mapping. Converts especially cleanly into acceptance criteria — the book's recommendation for teams new to BDD.

## OOPSI
**When to use**: When a feature is best understood by what it produces.
**How**: Outcome → **Outputs** (including failure outputs) → Process → Scenarios (rules and edge cases) → Inputs (concrete data, usually tables).
**Trade-offs**: Works backward from Feature Mapping's direction; pick by which end you understand better.

## Journey Mapping
**When to use**: Retrofitting tests to an existing system with no coverage.
**How**: Actors & goals → workflows (and prerequisites) → associate with features → steel thread → consequences → task analysis. Iterate: map a slice, automate it, map again.
**Trade-offs**: Requires stakeholder time and beginner's mind. Don't map the whole system upfront.

## Steel Thread
**When to use**: Starting automation on a large or unknown system.
**How**: Exercise the minimum set of *simplest successful* scenarios per feature, end to end across the workflow.
**Trade-offs**: Only rudimentary happy-path coverage — but it surfaces assumptions and hidden dependencies while you still have time to act, and avoids combinatorial paralysis.

## Split by Rule
**When to use**: A workflow with many scenarios and multiple business rules.
**How**: Divide scenarios by the business rule they support; automate one rule at a time.
**Trade-offs**: More frequent integration overhead in exchange for much smaller batches. The scenario-to-rule card ratio indicates a workflow's variability.

## Scenario Outline + Examples
**When to use**: Several scenarios differing only in data.
**How**: Parameterize with `<placeholders>`; supply an `Examples:` table. Add a `Notes`/`Reason` column naming the rule each row exercises. Use separate titled `Examples:` blocks to group accepted vs. rejected cases.
**Trade-offs**: Less prose context per case — but readers skim near-identical scenarios and miss details, so tables usually communicate better.

## Background
**When to use**: Several scenarios in a file share business-meaningful setup.
**How**: `Background:` steps run before each scenario.
**Trade-offs**: **Business-facing only.** Browsers, database resets, and container startup belong in hooks, not Background.

## Personas / Known Entities as Test Data
**When to use**: Whenever scenarios would otherwise carry names, addresses, or default domain values.
**How**: Name the actor in the scenario; the step definition resolves the record from HOCON, JSON, an enum, a test DB, or a factory. Override only the scenario-relevant fields.
**Trade-offs**: Indirection — a reader must know where persona data lives. Pays for itself immediately in feature-file readability. Extend to "known entities" for non-human domain objects.

## Layers of Abstraction (3-layer)
**When to use**: Every acceptance test suite beyond a tutorial.
**How**: **Business Rules** (scenarios, change when the business changes its mind) → **Business Flow** (user journey tasks, change when the workflow changes) → **Technical** (locators, endpoints, change when the screen changes). Each layer orchestrates the one below and never reaches past it.
**Trade-offs**: More files and indirection up front. In return, one kind of change lands in exactly one layer. You can write the top two layers before the UI exists.

## Page Objects / Page Component Objects
**When to use**: Any UI test suite.
**How**: One class per significant *component* (not per page). Centralize locators as named constants or `@FindBy` fields. Expose business-meaningful methods returning simple types or domain objects. Hide waits and spinners inside methods.
**Trade-offs**: **Never assert inside a Page Object** and never expose `WebDriver`/`WebElement`. Alone, they encourage UI tunnel vision and can bloat — add an Action/Query layer above them at scale.

## Action & Query Classes (DSL layer)
**When to use**: When step definitions would otherwise be tied to the UI, or when the same task might be done via API or cookie.
**How**: Action classes model a business *process* (`Login.as(user)`), not a *screen*. Query classes read state and answer in business terms (`CurrentUser.isConnectedAs(user)`).
**Trade-offs**: An extra layer. The payoff is being able to re-implement a step's mechanism without touching the scenario.

## Fluent Interface / Builder
**When to use**: One business operation with many optional variations (one-way → return → multi-stop search).
**How**: Each builder method returns `this`; a terminal method performs the action. Implement by orchestrating existing Page Objects.
**Trade-offs**: Extends by adding a method rather than rewriting — but a large fluent API is its own design problem.

## Screenplay Pattern
**When to use**: Large suites, multiple interfaces, or multiple actors in one scenario.
**How**: Actors with **abilities** perform **tasks** composed of **interactions**, and answer **questions** used for assertions. Interactions are *objects* passed to `attemptsTo()`, not methods.
**Trade-offs**: More concepts to learn than Page Objects. In return: extend by adding classes rather than modifying them; tasks compose freely; multi-actor scenarios work naturally. Page Objects remain fine for small applications.

## Task Substitution
**When to use**: Two ways to reach the same goal (UI vs. API; long path vs. shortcut).
**How**: Name tasks by *goal*, never mechanism. Group variations in one class named for the goal: `LocateRegistrationForm.viaHomePage` / `.viaDirectNavigation`.
**Trade-offs**: Only safe when the tasks genuinely achieve the same outcome.

## Blended Testing
**When to use**: UI-focused workflows needing preconditions the UI can supply only slowly.
**How**: Convention — `Given` + **passive voice** ("Tracy has signed up") → API implementation; `When` + **active voice** ("Tracy signs up") → UI implementation. Different Cucumber expressions match each.
**Trade-offs**: Requires an API. If none exists, build test-specific APIs for setup and state inspection.

## Testing *with* APIs
**When to use**: Whenever the scenario is about a business rule rather than the interface.
**How**: Wrap calls in per-service client classes (`MembershipAPI`, `TokenAPI`) over a configurable base. Extract only the fields you need; annotate partial records `@JsonIgnoreProperties(ignoreUnknown = true)`. Clean up with a DELETE call in `@After`.
**Trade-offs**: More technical and needs architecture knowledge. Faster, more robust, more comprehensive than UI-only testing. API *design* testing (fields, status codes) belongs in unit/integration tests.

## Hooks & Tagged Hooks
**When to use**: Technical setup and teardown the business shouldn't see.
**How**: `@Before`/`@After` per scenario; `@Before("@web")` for tagged subsets; `@BeforeAll`/`@AfterAll` or an `EventListener` per run.
**Trade-offs**: `@BeforeAll` with static state isn't thread-safe under parallel execution — prefer an `EventListener` or `ThreadLocal`.

## Virtual Test Environments (TestContainers)
**When to use**: Production-like dependencies (Postgres, Kafka, Elasticsearch) needed locally.
**How**: Instantiate a container class, `start()`, inject the dynamic address (e.g. Spring's `@DynamicPropertySource`). Wrap in `ThreadLocal` for parallel runs.
**Trade-offs**: Requires Docker. Startup is fast enough that a fresh instance per test is usually feasible. Beats in-memory DBs when you need proprietary types, stored procedures, queues, or caches.

## Portable Integration Layer
**When to use**: Multiple suites needing different tools (component vs. cross-browser), or protecting against tool EOL.
**How**: Abstract the *tool*, not just its API calls. Keep exactly one tool-specific line — the ability (`BrowseTheWebWithPlaywright` vs. `BrowseTheWebWithWebdriverIO`). Everything else uses service-access APIs.
**Trade-offs**: You depend on the abstraction supporting the features you need. Guards against lock-in (cf. Protractor's EOL).

## Lean & Companion Page Objects
**When to use**: Under Screenplay, where tasks already model behavior.
**How**: **Lean** — information only (elements and derived state, e.g. CSS class → 'success'/'error'). **Companion** — shipped with the widget library, host element injected, methods returning tasks and question adapters.
**Trade-offs**: Companion objects require cross-team agreement on a shared language and a publishing convention (same Node module, separate entry point).

## Page Element Query Language
**When to use**: Complex widgets with no test-friendly identifiers.
**How**: Filter element collections by expectations — `Form.fields().where(Text.of(Form.label()), equals(name)).first()`. Reuses the same expectation vocabulary as waits and assertions.
**Trade-offs**: More verbose than a CSS selector, far more robust than a brittle XPath. Ideally add `data-testid` attributes instead — this is for when you can't.

## Living Documentation & Feature Coverage
**When to use**: Reporting progress to stakeholders; audit and release evidence.
**How**: Aggregate scenario results per feature (readiness). Declare unbuilt acceptance criteria as **empty scenarios** so they report pending and reduce coverage. Link to the backlog with `@Issue:` tags; slice with `@security:` and `@release:` tags.
**Trade-offs**: Coverage is only as thorough as the requirements the tool knows about — and Agile teams deliberately don't detail far ahead. Never confuse with code coverage.

## Retrofitting BDD to Legacy Systems
**When to use**: A mission-critical legacy app with low coverage that can't be rewritten.
**How**: Retrofit **high-level acceptance tests first** (typically web tests) to describe, document, and guard against regressions. Add BDD unit tests to the most critical or high-risk parts only, written as worked examples of how to use each class.
**Trade-offs**: Retrofitted unit tests "tend to be quite superficial" — inventing behavioral specs after the fact requires deep understanding. Describe what the system *should* do, not what it currently does, or you enshrine existing bugs.
