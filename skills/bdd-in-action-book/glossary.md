# Glossary — BDD in Action, 2nd Edition

**AARRR / Pirate Metrics** — Acquisition, Activation, Retention, Referral, Return. Five growth metrics (Dave McClure); each stage is a potential bottleneck, optimize one at a time. (Ch 4)

**Abilities** — What enables a Screenplay actor to interact with a system (`BrowseTheWeb`, `CallAnApi`, `TakeNotes`). An implementation of the Adaptor Pattern. (Ch 12, 14)

**Acceptance test** — A business-facing test that end users or sponsors can use to check a feature works as intended. (Ch 2)

**Action class** — A class encapsulating a business task, sitting between step definitions and Page Objects. Knows which pages or APIs to use, not how to locate elements. (Ch 11)

**Actor** — Someone or something interacting with the system under test; the starting point of every Screenplay scenario. Often maps to a persona. (Ch 12)

**ATDD (Acceptance Test–Driven Development)** — Users collaborate with developers to write automated acceptance criteria before features are built. Part of the BDD family. (Ch 2)

**Automated acceptance test** — An executable specification with the underlying code that exercises the application; before that code exists it reports as *pending*. (Ch 8)

**Background** — Gherkin keyword for steps run before every scenario in a feature file. Business-facing only; technical setup goes in hooks. (Ch 7, 8)

**BAU (Business as Usual) team** — The maintenance team inheriting an application after deployment; a primary audience for living documentation. (Ch 9, 16)

**BDD (Behavior-Driven Development)** — A collaborative development approach where teams use structured conversations about examples and counterexamples of business rules to build shared understanding of valuable features. (Ch 1)

**Beginner's mind** — Approaching discovery having dropped assumptions and preconceptions about what a system should do. (Ch 14)

**Blended testing** — Interacting with different external interfaces (UI, API) within a single scenario to play to their strengths. (Ch 15)

**Brittle test** — One prone to failing randomly for no apparent reason; long UI scenarios are the main source. (Ch 7, 10)

**Bullet-point Gherkin** — Using `*` in place of Given/When/Then. Cucumber treats the steps identically. (Ch 10)

**Burndown chart** — Graph comparing work remaining in a sprint against work planned. (Ch 16)

**Capability** — The ability to achieve a goal, independent of implementation. Liz Keogh's test: it can be prefixed with "to be able to." (Ch 4, 5)

**Cast** — Screenplay construct managing the actors in a scenario and their abilities; `OnlineCast` gives each their own WebDriver. (Ch 12, 14)

**Command Pattern** — An object containing all information needed to perform an action is passed to something that performs it. The basis of Screenplay interactions. (Ch 12)

**Companion Page Object** — A Screenplay-style Page Object shipped with a widget library, whose methods return tasks and question adapters. (Ch 15)

**Consequence** — Feature Mapping's term for an expected outcome at the end of a flow (mauve card). (Ch 6)

**Continuous delivery** — Every build is a potential release; a passing release candidate can go to production once stakeholders approve. (Ch 8)

**Continuous deployment** — As above, but with no manual approval stage. (Ch 8)

**Continuous integration** — Automatically building and testing whenever a change is committed. (Ch 8)

**Counterexample** — A case where a rule does *not* apply; the primary tool for surfacing hidden rules. (Ch 1, 6)

**Cucumber Expression** — The `{int}`, `{word}`, `{string}`, `{}` placeholder syntax in step annotations; the modern replacement for regular expressions. (Ch 8)

**`@DataTableType`** — Cucumber annotation telling the framework how to convert one table row into a domain object. (Ch 8)

**Declarative scenario** — One describing *what* the user is trying to achieve rather than *how* they click. The first mark of good Gherkin. (Ch 7)

**Deliberate Discovery** — Dan North's principle that ignorance is the constraint; proactively hunt out and reduce uncertainty, tackling the most uncertain stories first. (Ch 5)

**Digital product backlog** — Agile project-management or issue-tracking software holding the backlog; enables automated metrics and BDD reporting integration. (Ch 16)

**DSL (domain-specific language)** — The Action/Query class layer modeling the business domain readably. (Ch 11)

**Ecosystem Thinking** — Considering all actors in a business ecosystem, not just users (Peter Merel). (Ch 4)

**Empty/pending scenario** — A scenario title with no steps; reports as pending and counts against feature coverage. (Ch 7, 16)

**`Ensure`** — Serenity's fluent assertion class weaving assertions into the interaction flow; available methods depend on the question's return type. (Ch 12)

**Epic** — A large User Story or high-level deliverable spanning more than one iteration. The book deliberately declines to police the term. (Ch 5)

**Epic Landscape** — A breadth-first view of the epics to deliver, framed by the bottlenecks they remove; output of a Pirate Canvas. (Ch 4)

**Example** — Cucumber 6 synonym for `Scenario`, used to group concrete cases under a `Rule`. (Ch 7)

**Example Mapping** — Matt Wynne's breadth-first technique using four card colors (yellow story, blue rule, green example, pink question), timeboxed to 25–30 minutes. (Ch 3, 6)

**Executable specification** — An automated test that illustrates and verifies how the application delivers a business requirement, written in business-readable form. (Ch 1, 2)

**Expectations** — Serenity/JS predicates (`isPresent()`, `equals()`, `includes()`) usable identically in waits, assertions, and the Page Element Query Language. (Ch 15)

**Feature** — Deliverable software functionality supporting a capability. Test: could you deploy it alone and still deliver business value? (Ch 4, 5)

**Feature coverage** — How many acceptance criteria have been defined and automated per requirement — *and which requirements have none*. (Ch 16)

**Feature file** — A `.feature` text file, under version control, holding all scenarios for one feature. (Ch 2, 7)

**Feature Mapping** — Like Example Mapping but decomposing examples into steps and consequences; best for workflows and user journeys. (Ch 6)

**Feature readiness** — A feature is ready when all its acceptance criteria pass. (Ch 16)

**`@FindBy`** — Selenium annotation declaring a locator on a Page Object field; omittable when the field name matches the element's id or name. (Ch 11)

**Fluent Interface** — An API using method chaining for readability; each method returns `this`, a terminal method acts. (Ch 11)

**Friends episode notation** — Naming examples "The one where…" (Daniel Terhorst-North). The original: "the one where Joey gets his head stuck in a turkey." (Ch 6)

**Gherkin** — The structured plain-language format (`Given`/`When`/`Then`/`And`/`But`) used by Cucumber and related tools. Supports 70+ languages. (Ch 2, 7)

**Glue code** — Step-definition code binding scenario text to test automation or application code. (Ch 3, 8)

**Hierarchical Task Analysis (HTA)** — UX technique decomposing activities into a hierarchy where each higher-level activity is the *what* of lower-level *hows*. (Ch 14)

**Hook** — A method run before or after scenarios, optionally filtered by tag expression; where technical setup belongs. (Ch 7, 8)

**HOCON** — Human-Optimized Config Object Notation, a JSON superset from the Typesafe/Lightbend config library; used for persona data and `serenity.conf`. (Ch 9)

**Hypothesis-Driven Development** — Jeffery L. Taylor's framing: "We believe X will result in Y. We will know this to be true when Z." (Ch 4)

**Impact Mapping** — Gojko Adzic's five-question mind-mapping technique: Pain point → Goal → Actor → Impact → Deliverable. (Ch 3, 4)

**Imperative scenario** — One reading as a list of low-level UI instructions; couples the spec to the screens. (Ch 7)

**Interaction** — In Screenplay, the most basic activity an actor can perform. An object, not a method. (Ch 12)

**Journey Mapping** — Six-step visual technique for discovering how an existing system's features are used and which are critical. (Ch 14)

**Journey scenario** — A high-level scenario illustrating a user's path through the system. Should be a small minority of your acceptance criteria. (Ch 10, 13)

**JSONPath** — Query language for JSON documents, analogous to XPath. (Ch 13)

**Known entity** — A domain object in a well-known state; the non-human generalization of a persona. (Ch 9)

**Knowledge Constraint** — The claim that the real constraint on a project is lack of knowledge, not time, budget, or programmer hours. (Ch 1)

**Last responsible moment** — The point past which you no longer have time to understand requirements before the feature is due. (Ch 5)

**Lean Page Object** — Under Screenplay, a Page Object with the single responsibility of providing information about a widget. (Ch 15)

**Living documentation** — Documentation generated from passing executable specifications, so it cannot drift out of date. Refers to both the feature files and the generated reports. (Ch 1, 16)

**Locator** — An object identifying an element on a page (`By.id`, `By.css`, `By.xpath`); kept in dedicated classes to localize change. (Ch 9, 10)

**Non-capturing group** — Regex `(?:x|y)`; matched but not passed to the step definition method. (Ch 8)

**`OnStage`** — Serenity's Screenplay class for summoning actors by name (`theActorCalled`) or implicitly (`theActorInTheSpotlight`). (Ch 12)

**OOPSI** — Outcome, Outputs, Process, Scenarios, Inputs (Jenny Martin & Pete Buckney). Works backward from the highest-value outcomes. (Ch 6)

**Outside-in** — Starting from acceptance criteria and working down, building only what's needed to make them pass. (Ch 2, 3)

**Page Component Object** — The more accurate name for a Page Object: model significant *elements* on a page, not whole pages (Martin Fowler). (Ch 11)

**Page Element Query Language** — Serenity/JS's portable, expectation-based alternative to raw selectors for complex widgets. (Ch 15)

**Page Object** — A class modeling part of a UI, presenting business-focused methods. Locates elements and reports state; never asserts. (Ch 11)

**`@ParameterType`** — Cucumber annotation declaring a custom domain type for step parameters. (Ch 8)

**Persona** — A rich fictional user description including goals, abilities, and background. Used to name actors and carry test data. (Ch 7, 9)

**Pirate Canvas** — Peter Merel's breadth-first technique combining Pirate Metrics, Impact Mapping, and Theory of Constraints. Asks "What sucks?" per metric. (Ch 4)

**Popping the why stack** — Repeatedly asking why (≈5 times) until you reach a viable business goal. (Ch 4)

**Product feature vs. release feature** — A coherent capability documented as one unit (one feature file) vs. the smallest independently deliverable slice used for release planning. (Ch 5)

**Product Backlog Refinement** — Scrum practice of adding detail, estimates, and order to backlog items; ongoing, collaborative. (Ch 5)

**`QuestionAdapter<T>`** — Serenity/JS proxy wrapping a value so static and lazily-resolved data share one API; wraps referenced fields recursively. (Ch 15)

**Query class** — An Action-class variant that reads system state and returns it in business terms. (Ch 11)

**Question** — In Screenplay, a query about system state that an actor answers; the basis of assertions. Does nothing until `.answeredBy(actor)` or `Ensure.that(...)`. (Ch 12)

**Real Options** — Chris Matts' three principles: options have value; options expire; never commit early unless you know why. Delay only until you have enough information, then act fast. (Ch 5)

**Release evidence** — Living documentation produced to record what shipped, against which rules, tested how — often for audit or compliance. (Ch 16)

**Rest Assured** — Java REST client library with a readable DSL for calls, extraction, and assertions. (Ch 13)

**`Rule`** — Cucumber 6 keyword naming a single business rule, grouping its examples. (Ch 7)

**Scenario** — A formalized example of how a feature works, composed of steps. (Ch 2)

**Scenario Outline / Scenario Template** — A parameterized scenario run once per row of an `Examples:` table, with `<placeholder>` substitution. (Ch 2, 7)

**Screenplay Pattern** — An actor-centric model built from actors, interactions, abilities, questions, and tasks. A design pattern, not a library. (Ch 12)

**Selenium Grid** — A network of servers controlling browsers on remote machines, for parallel and cross-browser execution. (Ch 10)

**Service provider framework** — The architecture letting `@serenity-js/web` stay tool-agnostic while plugin modules supply implementations. (Ch 15)

**Slicing** — Breaking a feature into User Stories deliverable in one iteration. (Ch 3, 5)

**SMART goals** — Specific, Measurable, Achievable, Relevant, Time-bound. Relevance is the most important attribute. (Ch 4)

**Soap opera personas** — Andy Palmer's technique: introduce personas on the fly as stories develop, rather than researching them up front. (Ch 7)

**Specification by Example (SBE)** — Gojko Adzic's term for practices using examples and conversation to discover requirements; chosen to reach non-testers put off by "test." (Ch 2)

**Speculate / Illustrate / Formulate / Automate / Demonstrate / Validate** — The six phases of the BDD flow. (Ch 3)

**Split by rule** — Automating a workflow's scenarios in small batches, one business rule at a time. (Ch 14)

**Steel thread** — The minimum set of simplest successful scenarios exercising a workflow end to end; surfaces assumptions and dependencies early. (Ch 14)

**Step definition** — The glue-code method Cucumber invokes for a scenario line. (Ch 8)

**Story card** — Front: the story plus priority and estimate. Back: an initial, deliberately non-exhaustive list of acceptance criteria. (Ch 5)

**Tag** — `@name` on a feature, scenario, or example table; used to filter execution and reports, trigger hooks, and link to issues. (Ch 7, 16)

**Tag expression** — A single tag or logical combination (`@web and not @backend`). (Ch 8)

**Task** — In Screenplay, a named group of interactions or other tasks achieving a micro-goal. Composable and reusable. (Ch 12)

**Task board** — A physical board of cards representing stories and tasks in status columns. (Ch 16)

**Task parameter vs. argument** — What varies in a task (traveler details) vs. a concrete value passed in (valid details). (Ch 15)

**Task substitution** — Replacing one task with another achieving the same goal, without affecting dependent tests. (Ch 15)

**TDD (Test-Driven Development)** — Kent Beck's write-failing-test / make-it-pass / refactor cycle. BDD's direct ancestor. (Ch 2)

**TestContainers** — Library spinning up Docker containers (databases, Kafka, Elasticsearch) for tests. (Ch 8)

**Three Amigos** — A developer, a tester, and a BA or product owner discussing a feature and drawing examples before implementation. (Ch 6)

**`ThreadLocal`** — Java construct giving each thread its own instance; required for sharing WebDrivers or containers under parallel execution. (Ch 8, 10)

**Toast** — A brief, temporary, usually animated notification. A common source of wait-related test failures. (Ch 15)

**Ubiquitous language** — A shared vocabulary businesspeople and developers both use to describe the system (Eric Evans, DDD). (Ch 2, 15)

**Unit test** — A small test describing and verifying the behavior of an individual component. (Ch 2)

**User Story** — A planning artifact breaking a feature into deliverable chunks. Disposable once the feature ships. (Ch 5)

**Vanity metric** — A measure that looks like progress but doesn't track what you care about (site visits vs. sign-ups). (Ch 4)

**Vision statement** — A concise statement of expected outcomes and objectives; states objectives, never technology or timeframe. (Ch 4)

**WebDriverManager** — Library auto-downloading browser binaries; now integrated into recent Selenium versions. (Ch 10)

**YAGNI** — "You ain't gonna need it." One of three valid postures on speculative work, alongside building it now and buying an option. (Ch 5)
