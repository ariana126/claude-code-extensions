---
name: screenplay-guideline
description: >
  Use this skill when writing, reviewing, or refactoring acceptance tests and
  end-to-end tests in TypeScript. Triggers include: writing e2e or acceptance
  tests with Playwright, WebdriverIO, or Cucumber; implementing or reviewing
  Cucumber step definitions; refactoring Page Objects that have grown unwieldy;
  structuring a test automation suite; deciding whether a test setup step should
  go through the UI or an API; modelling tests that involve more than one user or
  role; or making a test suite readable by non-programmers. Also use when the
  user mentions "Screenplay pattern", "Serenity/JS", "@serenity-js", "actor",
  "attemptsTo", "Task.where", "Ensure.that", "Cast", "abilities", "blended
  testing", "task substitution", "Lean Page Object", or "three-layer test
  architecture". Use this skill even if the user just says "write e2e tests for
  this flow" or "our e2e suite is slow and brittle" without naming a pattern —
  this skill provides the architecture.
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
  sources:
    - "BDD in Action, 2nd Edition by John Ferguson Smart and Jan Molak"
    - https://serenity-js.org
---

# Screenplay Guideline

This skill encodes an actor-centric architecture for acceptance and end-to-end
tests, based on the **Screenplay Pattern** as presented in *BDD in Action, 2nd
Edition* by John Ferguson Smart and Jan Molak. All examples use **Serenity/JS**
(TypeScript).

Screenplay picks up where unit testing leaves off. For unit and integration test
philosophy — what to mock, the AAA pattern, test naming — see the sibling
`test-guideline` skill instead. This skill is about the layer above.

## When to Reach for Screenplay

Screenplay is a design pattern, not a library. It costs more upfront than Page
Objects, so apply it where it earns that cost back:

| Reach for Screenplay when | Page Objects are fine when |
|---------------------------|----------------------------|
| The suite is large or growing | The app is small and the suite is a handful of tests |
| Tests span multiple interfaces (UI **and** API, DB, batch) | Everything goes through one web UI |
| Workflows involve **more than one actor** | A single user drives every scenario |
| Non-programmers need to read the test code | Only the test team reads it |

Multi-actor workflows are more common than teams expect: a loan application needs
a client to apply and a bank employee to approve or reject it. Chat systems and
games are the same shape. Page Object and Action-class designs quietly assume a
single actor, and boundaries blur once a second one appears.

**Do not retrofit Screenplay onto a three-test suite.** The pattern pays off
through composition and reuse; with nothing to reuse, it is just ceremony.

## The Five Elements

| Element | Represents |
|---------|------------|
| **Actors** | Users and external systems interacting with ours |
| **Interactions** | The most basic activities an actor can perform (click a button, send a request) |
| **Abilities** | What enables an actor to interact through a given interface |
| **Questions** | When answered by actors, provide information about system state |
| **Tasks** | Group, combine, and reuse sequences of interactions or other tasks |

Everything flows through one entry point:

```typescript
await actor.attemptsTo(
    Navigate.to('/'),
    Click.on(Form.buttonCalled('Register')),
)
```

It is called `attemptsTo` rather than `performs` because this is a test, and
something might go wrong.

### Why interactions are objects, not methods

This is the structural insight the whole pattern rests on. Conventionally you
locate an element and invoke a method on it (`loginButton.click()`). In
Screenplay you **create an object** and hand it to the actor (`Click.on(...)`).

The consequence: you extend the system by *adding* classes, never by modifying
them. WebDriver has no double-click method — conventionally you must pull in a
separate `Actions` class and switch coding style entirely. In Screenplay,
`DoubleClick.on(...)` is just another class. Existing code stays untouched, so
you cannot break what already works.

Think of a waiter taking your order: they write it on a slip of paper (the
object) and pass it to the kitchen. The slip only describes *what* to do — it is
the actor who performs it.

### Abilities are adaptors

An ability is a thin wrapper around a lower-level, interface-specific client — a
browser driver, an HTTP client, a database client. Grant abilities to actors
rather than teaching actors about each interface:

```typescript
actor.whoCan(
    BrowseTheWebWithPlaywright.using(browser),
    CallAnApi.at('http://localhost:3000'),
)
```

New interface, new ability. The actor implementation never changes.

## Three-Layer Architecture

A test suite is a **system**, and it deserves the same architectural care as
production code. Organize it into three layers:

| Layer | Responsibility | Contains |
|-------|----------------|----------|
| **Specification** | Capture workflows and business rules that stakeholders care about | Cucumber feature files, Playwright/Mocha specs |
| **Domain** | Model the activities required to complete those workflows; attach business meaning to sequences of lower-level activities | Screenplay tasks, questions, notes |
| **Integration** | Bridge the business domain and the technology domain | Abilities, element locators, test data setup |

**The layering rule**: an element of a given layer depends only on other elements
in the same layer, or elements in the layer *directly below* it.

The most common design error is **skipping the Domain layer** — invoking
Playwright or WebDriver APIs directly from a step definition. This welds your
specifications to one interface and one tool, and blocks blended testing and
reusable test code entirely.

```typescript
// Wrong — the Specification layer reaches past Domain into Integration
Then('{pronoun} should be advised of an error: {string}',
  async (actor: Actor, expectedMessage: string) =>
    actor.attemptsTo(
      Wait.until(ToasterMessage(), isPresent()),
      Ensure.that(Text.of(ToasterMessage()), includes(expectedMessage)),
      Click.on(ToasterMessage()),
      Wait.until(ToasterMessage(), not(isPresent())),
  )
)

// Right — one named task in the Domain layer says what is happening
Then('{pronoun} should be advised of an error: {string}',
  async (actor: Actor, expectedMessage: string) =>
    actor.attemptsTo(
      VerifySubmission.failedWith(expectedMessage),
  )
)
```

Compare the clarity of *"verify submission failed with an expected message"*
against the low-level sequence *"wait, check, click, wait."*

Each layer has a different reader. Optimize Cucumber scenarios for the business
audience; optimize tasks for the technical audience's cognitive load.

## Task Design and Naming

### Decompose one layer at a time

Borrow **Hierarchical Task Analysis** from UX research: each higher-level
activity is a mini-goal (the *what*) served by a sequence of lower-level
activities (the *how*). Signing up decomposes into locate the form, fill it out,
submit it, confirm success. Locating the form decomposes into navigate home and
click the register link.

At each layer, describe **what** is happening, and leave the **how** to the layer
underneath. Do not jump from a business goal straight to a dozen clicks.

### Name tasks by goal, not mechanism

This is not a style preference — it is what makes tasks substitutable. Two tasks
that accomplish the same goal can replace one another without touching the tests
that rely on them, *provided* their names describe the goal rather than the
route:

```typescript
export class LocateRegistrationForm {
    static viaHomePage = () =>
        Task.where(`#actor locates registration form via home page`,
            Navigate.to('/'),
            Click.on(Form.buttonCalled('Register')),
        )

    static viaDirectNavigation = () =>
        Task.where(`#actor locates registration form via direct navigation`,
            Navigate.to('/register'),          // same goal, faster
        )
}
```

Group variations under a class named for the goal, with method names carrying the
difference. This works at every level of abstraction, and it is the foundation of
blended testing.

Naming tasks in domain vocabulary establishes a **ubiquitous language** shared by
business and technical people — the test code becomes readable by people who do
not write code.

### Compose bottom-up, and reuse tasks inside tasks

```typescript
const SignUp = (travelerDetails: QuestionAdapter<TravelerDetails>) =>
    Task.where(`#actor signs up`,
        LocateRegistrationForm.viaHomePage(),
        FillOutRegistrationForm.using(travelerDetails),
        SubmitRegistrationForm(),
    )
```

Even a task wrapping a *single* interaction earns its keep: every actor can reuse
it, URLs and selectors live in one place, and reports describe business steps
instead of listing clicks.

### Stub tasks before implementing them

`Task.where(description)` with no activities throws `ImplementationPendingError`,
and Serenity/JS reports the scenario as pending implementation:

```typescript
const FillOutRegistrationForm = (travelerDetails: TravelerDetails) =>
    Task.where('#actor fills out registration form')     // no activities → pending
```

This lets you capture the vocabulary of a workflow outside-in, and get a report
showing where the gaps are, before writing any integration code.

## Questions and Assertions

Questions are how you write assertions. A Question object on its own does
nothing — it is like an online poll nobody answers. It must be handed to an actor
via `Ensure.that(...)` or `.answeredBy(actor)`.

Prefer weaving assertions into the flow:

```typescript
await actor.attemptsTo(
    Click.on(Navigation.myAccount()),
    Ensure.that(Account.pointBalance(), equals(1000)),
)
```

Wrap raw questions in domain-specific ones so assertions read in business terms.
`Account.pointBalance()` communicates; `Text.of('[data-test=point-balance]')`
does not.

One expectation vocabulary — `isPresent()`, `equals()`, `includes()`, `not()`,
`matches()` — works identically in `Ensure.that`, `Wait.until`, and the Page
Element Query Language. Learn it once, use it in all three.

Note that `Wait` lives in `@serenity-js/core`, not the web module: use it to poll
a REST API or test asynchronous batch processing too.

## Blended Testing

Interacting with the UI is slow, and much of that cost is deliberate UX design —
multi-page forms, artificial payment delays that make transactions *feel*
secure, engagement animations. Every one of those patterns taxes your suite.

Exercise a workflow through the UI **at least once**. Doing it *every* time a
scenario merely needs a signed-up user is wasteful.

Signal the split with grammatical voice:

| Keyword | Voice | Means | Implementation |
|---------|-------|-------|----------------|
| `Given` | **Passive** — "Tracy **has signed up**" | We only care *that* it is done | API call |
| `When` | **Active** — "Tracy **signs up**" | We want to *demonstrate how* | Web UI |

This is not just a convention for humans: the two voices produce different
Cucumber expressions, so the split happens automatically at the step-definition
level.

```typescript
class SignUp {
  static using = (travelerDetails: QuestionAdapter<TravelerDetails>) =>
    Task.where(`#actor signs up`,
      LocateRegistrationForm.viaHomePage(),
      FillOutRegistrationForm.using(travelerDetails),
      SubmitRegistrationForm(),
    )

  static viaApiUsing = (travelerDetails: QuestionAdapter<TravelerDetails>) =>
    Task.where(`#actor signs up (via API)`,
      Send.a(PostRequest.to('/api/auth/register').with(travelerDetails)),
      Ensure.that(LastResponse.status(), equals(201)),
    )
}
```

```typescript
Given('{actor} has signed up', async (actor: Actor) =>       // passive → API
    actor.attemptsTo(SignUp.viaApiUsing(notes<TravelerNotes>().get('travelerDetails'))))

When('{actor} signs up', async (actor: Actor) =>             // active → UI
    actor.attemptsTo(SignUp.using(notes<TravelerNotes>().get('travelerDetails'))))
```

**If no suitable API exists**, consider building test-specific programmatic APIs
for registering accounts, seeding test data, or inspecting state the UI does not
expose. That is a legitimate need, not a workaround.

Keep DevTools open while exploring the app manually — spotting that the
registration form fires a `POST` is what makes the shortcut possible.

### "End to end" means the ends of the workflow

It does not mean "against a fully assembled system deployed to production-like
infrastructure through a browser." Exercise the workflow from beginning to end —
its *breadth* — while freely using APIs, in-memory databases, mocked services, or
component-level rendering within it. Running every acceptance test against a full
deployment is a common and expensive mistake.

## Actors, Cast, and Personas

Actors are personas. They map directly onto the named personas in your Gherkin —
"Tracy the Traveler," not "the user."

The actor's name belongs in the scenario as **data**, not code:

```gherkin
Scenario: Stan checks his balance
  Given Stan has logged into his account
  When he views his account details
  Then his account status should be:
    | Point Balance | Status Level |
    | 0             | STANDARD     |
```

A `Cast` creates actors on demand and grants their abilities. Configure it once
in a `BeforeAll` hook. Pronouns like "he" resolve to the last active actor, and
`actorInTheSpotlight()` retrieves that actor when a step names nobody.

Give each actor persona defaults through the `TakeNotes` ability and a `Notepad`,
then override only what a scenario actually needs. Requiring every field inline
clutters the feature file and buries the one detail that matters:

```gherkin
# Cluttered — eight rows, and the reader cannot tell which one is the point
When Tracy signs up using following traveler details:
  | firstName | Tracy | lastName | Traveler | email | ... |

# Focused — the shared email address is the whole point of the scenario
When Jenny tries to sign up using:
  | email | smiths@example.org |
```

Merge defaults with overrides via `Question.fromObject`:

```typescript
When('{actor} tries to sign up using:', async (actor: Actor, data: DataTable) =>
    actor.attemptsTo(
        SignUp.using(
            Question.fromObject<TravelerDetails>(
                notes<TravelerNotes>().get('travelerDetails'),   // defaults
                data.rowsHash() as Partial<TravelerDetails>,     // overrides
            )
        )
    ))
```

Prefer a data table over an inline step parameter — it lets a scenario override
several defaults at once without a new step definition for each combination.

Accept `QuestionAdapter<T>` in task signatures rather than a plain `T`, so static
and lazily-resolved data work through one API. All built-in Serenity/JS APIs
accept both.

**Read `references/setup.md`** when wiring up a project: Cast configuration,
persona factories, Cucumber parameter types, and swapping Playwright for
WebdriverIO.

## Page Objects Under Screenplay

Screenplay does not abolish Page Objects — it narrows their job. Since tasks and
interactions already model behavior, a **Lean Page Object** only reports
information about a widget and never models interactions. A **Companion Page
Object** additionally returns tasks and takes its host element by injection; use
it when shipping test code alongside a widget library so consumer teams do not
reverse-engineer your selectors.

Never assert inside a Page Object, and never expose the raw driver.

**Read `references/page-objects.md`** when building widget abstractions, or when
the DOM offers no test-friendly identifiers and you need the Page Element Query
Language.

## Anti-Patterns

Read `references/ANTI_PATTERNS.md` for the full catalogue. The ones worth
internalizing:

- **Low-level interactions inside step definitions** — the Specification layer
  reaching past Domain into Integration. Compose a named task instead.
- **Tests built only from low-level interactions** — technically Screenplay, but
  business concepts drown in the noise of clicks and HTTP requests.
- **Writing a Question and never asking it** — without `Ensure.that(...)` or
  `.answeredBy(actor)`, nothing is verified and the test passes vacuously.
- **Treating the interface as the subject of the test** — interfaces are doors
  through which tests reach business logic, not destinations. A traveler uses the
  UI to book a ticket, not to interact with the UI.
- **Page Object hierarchies mirroring the app's page structure** — complexity
  with no corresponding benefit.
- **Assuming a single actor** — real workflows have several, and the boundaries
  between their activities need to be explicit.

## Quick Checklist Before Merging a Test

- [ ] Does the scenario start from an actor with a goal, in business language?
- [ ] Does every step definition call a Domain-layer task, never a raw driver API?
- [ ] Is each task named for the goal it accomplishes, not the route it takes?
- [ ] Does each layer describe *what*, leaving *how* to the layer below?
- [ ] Are `Given` steps passive and API-backed where the UI adds no value?
- [ ] Is every Question actually answered by an actor?
- [ ] Would a non-programmer on the team understand the task names?
- [ ] Could this task be reused by another actor, or inside a higher-level task?
