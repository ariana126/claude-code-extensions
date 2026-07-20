# BDD in Action — Decision Cheatsheet

## Where does this test belong?

| If the scenario is about… | Automate via | Why |
|---|---|---|
| A key user journey through the system | **UI** (a few only) | Illustrates real behavior; stakeholders trust it |
| What information the UI presents / how it renders | **UI** | Only testable there |
| Screen-specific logic (duplicate email → reset-password link) | **UI** | It's a rule *about* a screen |
| A business rule independent of the interface | **API or code** | Faster, more precise, automatable before the UI exists |
| An algorithm (password strength, email validity) | **Unit test** | Driving it through a form is "wasteful" |
| A precondition another scenario already proved | **API** | Don't re-prove what's covered |
| A cross-service effect (email sent) | **Listen for the event** at your boundary | Don't exercise another team's system |

**Ask**: *"Am I illustrating how the user interacts with the application, or logic that's independent of the interface?"*

## Which discovery technique?

| Shape of the uncertainty | Technique |
|---|---|
| Don't know which goal to pursue at all | **Pirate Canvas** → Epic Landscape |
| Have a goal, need features | **Impact Mapping** |
| Have a backlog, need priority | **Reverse Impact Mapping** |
| Many business rules to enumerate fast | **Example Mapping** (25–30 min) |
| Workflows, journeys, alternate flows | **Feature Mapping** |
| Value defined by what the system produces | **OOPSI** |
| Clear inputs → outputs, data transformation | **A table** |
| Existing system, no coverage | **Journey Mapping** + steel thread |

## Gherkin quality gate — five checks

1. **Declarative?** No clicks, fields, or buttons. Grep your suite for `click`, `enter`, `select`.
2. **One rule?** If a failure wouldn't tell you what broke, split it.
3. **Named actor?** "I" and "the user" tell you nothing about what's valuable.
4. **Essential only?** Drop any column whose values are identical or don't change the outcome — but stop before the scenario goes vague (*the fish seller*).
5. **Independent?** Every scenario sets up its own state. No scenario depends on a previous one running.

**Instant smell**: a scenario containing **"verify"** or **"check"** is a manual test script in disguise.

## Which `Given` steps to keep

| Keep | Drop |
|---|---|
| Anything that **changes the outcome** (e.g. "Tara is a Frequent Flyer" when members aren't charged a fee) | Implementation detail implied by another step (e.g. "Tara has logged on") |

Both errors cost you: too many `Given`s obscure what's required; a missing one becomes a silent assumption.

## Given vs. When → which mechanism

| Keyword | Voice | Means | Implement with |
|---|---|---|---|
| `Given` | Passive — "has signed up" | We only care *that* it's done | **API call** |
| `When` | Active — "signs up" | We want to *demonstrate how* | **UI** |

## Layer routing — where does this change land?

| What changed | Layer to edit |
|---|---|
| The business changed its mind | Business Rules (scenario) |
| A new required step in the workflow | Business Flow (task) |
| Field renamed, HTML restructured | Technical (Page Object / locator class) |
| Scenario wording | Glue code |

**If a field rename forces you to edit a scenario, your layers have leaked.**

## Feature vs. User Story

**Feature** — could you deploy it alone and still deliver business value? Would it get a user-manual section? Then it's a feature.
**Otherwise** it's a User Story: a planning artifact, **discarded once the feature ships**.

Context-dependent: "Pay with Visa" is a story at an airline, a feature at a FinTech start-up where each card integration is major work.

## Feature file organization

| Scheme | Verdict |
|---|---|
| By business capability | ✅ **Use this** |
| Flat | Only for a handful of files |
| One per User Story | ❌ Stories are transitory; new stories replace old scenarios |
| One directory per release | ❌ Features span iterations |

*"You wouldn't organize a user manual with one chapter per release."*
Organize by **product** feature (one file per capability); plan by **release** feature.

## Locator strategy — in preference order

1. `data-testid` — **if you control the HTML**. Immune to framework churn.
2. `By.id` / `By.name` — convenient, but coupled to JS event handling and form semantics.
3. `By.linkText` / `partialLinkText` — for links with no attributes; breaks if display text changes.
4. `By.cssSelector` — flexible, fast (native browser support). **Scope it to a container.**
5. `By.xpath` — only for matching on **content** or navigating relative to a match. Verbose, fragile, and *very slow on IE*.

**Always** use `contains(@class, ...)` rather than exact class equality — frameworks append classes at runtime.
**Prefer** nested `findElement()` calls over one clever complex selector.

## Business goal classification

Every commercial goal reduces to one of four. If it fits none, question the feature.

| Category | Example |
|---|---|
| Increasing revenue | "Increase ticket sales revenue by 5%" |
| Reducing costs | "Reduce hotline costs via online redemption" |
| Protecting revenue | "Avoid losing customers to a rival program" |
| Avoiding future costs | Compliance reports that dodge next year's fines |

*Nonprofit/government variant*: improving service, reducing costs, avoiding future costs.

## Thresholds & defaults

| Rule of thumb | Value |
|---|---|
| Example Mapping session | **25–30 minutes**, then vote |
| "Popping the why stack" | **≈5 questions** to a viable business goal |
| Detailed planning horizon | **~3 months** — beyond that, detail is rework |
| Strategic planning cadence | 2–3 months (aligns with SAFe PI planning); some teams weekly |
| Maintenance share of software cost | **40–80%** (Glass) |
| Delivered features never used | **~45%** (Standish CHAOS) |
| Projects failing significantly | **~50%** |
| Declarative refactor payoff | **80%** less time to write and automate new scenarios (one team) |
| UI tests as share of acceptance tests | A small minority; journey scenarios rarer still |

## Tells & smells

| If you see… | You probably have… |
|---|---|
| "verify" / "check" in a scenario | A manual test script converted to Gherkin |
| `testTransfer()` naming a method under test | Implementation-coupled unit tests |
| Several near-identical scenarios | A missing `Scenario Outline` |
| Repeated opening steps | A missing `Background` |
| A broken test nobody fixes | The vicious circle — the suite has stopped being a health signal |
| All tests green, feature unfinished | You're tracking readiness without **coverage** |
| A `WebDriver` call in a step definition | Four coupling problems: tool lock-in, hard-coded URLs, scattered locators, leaked timing |
| A wait condition in a step definition | Noise that belongs in a Page Object or task |
| Assertions inside a Page Object | Broken separation of concerns |
| `allMatch` with no `isNotEmpty` | A test that passes vacuously on empty results |
| `static WebDriver` | Parallel execution will break |
| "It takes an overnight batch to set up test data" | An automation requirement you haven't scoped |
| Checking CSS **color** for validation state | Coupling to the graphic designer's whims |
| The whole JSON response mapped to a record | A test that breaks when a field is added |

## Real Options — three principles, one common misreading

1. Options have value (inversely proportional to what you know).
2. Options expire (when there's no longer time to integrate before the deadline — and you can sometimes *push the expiry back*).
3. Never commit early unless you know why.

⚠️ **The misreading**: Real Options is *not* "always delay to the last moment." Delay only until you have enough information — **then implement as quickly as possible.**

## Sequencing rules

- **Stories**: hardest/most uncertain first (Deliberate Discovery), not easiest first.
- **Scenarios in a feature**: simplest case first, one new variable at a time.
- **Layers**: Business Rules and Business Flow *before* the UI exists.
- **Legacy systems**: high-level acceptance tests first; retrofitted unit tests are superficial.
- **Pirate Metrics**: optimize **one bottleneck at a time** — spending on Acquisition when the problem is Activation is pure waste.

## Screenplay quick reference

```
actor.attemptsTo(Interaction, Task, Ensure.that(Question).isEqualTo(x))
actor.can(BrowseTheWeb.with(driver))          // ability = adaptor
Task.where("{0} does something", ...activities)  // {0} = actor name
Question.answeredBy(actor)                     // a Question does nothing until asked
OnStage.theActorCalled(name) / theActorInTheSpotlight()
```
Interactions are **objects, not methods** — that's what lets you add behavior without editing existing classes.
