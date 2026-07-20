# Chapter 14: Executable Specifications for Existing Systems with Serenity/JS

## Core Idea
Retrofitting tests to a legacy system means shifting from *"what should we build?"* to *"how are the existing features used, and which are on the critical path?"* **Journey Mapping** answers that; a **three-layer test automation system** turns the answer into code that scales.

## Frameworks Introduced

- **Journey Mapping** — six steps, building one visual map:
  1. **Determine actors and goals** — understand the business context: not only *how* the system is built, but *what* it is and *who* it's built for.
  2. **Determine what workflows support those goals** — and identify prerequisite workflows.
  3. **Associate workflows with features** — the system-centric view (registration, authentication, flight finder, bookings).
  4. **Establish a steel thread** — the simplest successful scenario per feature.
  5. **Determine verifiable consequences** — work *backward* from outcomes.
  6. **Task analysis** — decompose each scenario into a hierarchy of tasks.
  - Discipline: "start with one or a handful of actors and their goals, identify **only the critical workflows** required to accomplish those goals, and **complete the automation test automation cycle before iterating** on the Journey Map again."
  - "Try to maintain the right balance between breadth and depth of this discovery exercise and be mindful not to attempt to map out every single workflow the system supports upfront."

- **The Steel Thread** — borrowed from bridge construction:
  > "Just like what the bridge builders used to do when constructing a bridge across a valley, you don't start with a 5-foot piece of the whole bridge, as the bridge would fall down, unsupported. You begin with a **simple cable right across, a steel thread**, which you then use to pull over the first narrow beam. Then you attach other parts to that beam until you have a bridge."
  - In testing: "exercising the absolute **minimum of scenarios within each feature** required for the actor to achieve their goal."
  - **Five things a steel thread buys you**: validates your understanding of how the system works; surfaces unconscious assumptions; reveals dependencies the team or sponsors didn't know about; buys time to change your test architecture or the system; and creates "opportunities for you to react sooner and address risks before they become problems."
  - **The failure it prevents**: "dependencies go undetected for weeks or months, only to appear at the last minute when you realize that, for example, even though you've built a state-of-the-art test automation system, **setting up the test data it needs to run is a manual process that takes weeks and needs to be performed by a different team that you don't control.**"

- **Redefining "end to end"** — one of the chapter's most useful corrections:
  > "Contrary to popular opinion, 'end to end' **doesn't mean running the tests against a fully assembled and deployed system through its web interface**. Far from it. When talking about end to end we mean **the ends of the workflow, focusing on its breadth rather than its depth**. While you'll want to exercise the workflow from its beginning to its end… you could choose to perform parts or even the whole workflow against its APIs not the Web UI, or against in-memory databases rather than a production-like DB server."

- **The Three-Layer Test Automation System** (n-tier architecture, figure 14.15):
  | Layer | Responsibility | Contains |
  |---|---|---|
  | **Specification** | Capture workflows, business rules, usage examples that stakeholders find important. "The interface between the test automation system and the people accepting the functionality." | Cucumber feature files (or Mocha, Jasmine, Playwright runners) |
  | **Domain** | Model the exact activities required to complete Specification-layer workflows; **associate business meaning with sequences of lower-level activities** | Screenplay tasks, questions, notes |
  | **Integration** | "Bridges the gap between the business domain and the technology domain" — translates activities into low-level interactions | Abilities, element locators, test data setup, reporting |
  - **The layering rule**: "an element of a given layer depends only on other elements in the same layer, or elements that belong to the layer **directly below** it."
  - **Why layers**: "each one specializes in a particular aspect of the test automation system. This specialization allows for more cohesive design of each aspect and makes these designs much easier to understand."
  - **The named common design error**: "to **skip the Domain layer** and invoke low-level integration APIs, such as Selenium WebDriver APIs, directly in the Specification layer. This ties the Specification layer with interface-specific interactions and tools and acts as an obstacle to introducing more advanced techniques such as blended testing or reusable test code."

- **Hierarchical Task Analysis (HTA)** — from UX research. "Each higher-level activity becomes a **mini-goal (the what)** of a sequence of **lower-level activities (the how)**."
  - Signing up → locate the registration form + fill it out + submit it + confirm success.
  - Locating the form → navigate to the homepage + click the register link.
  - Expanded fully, "we'd end up with **over a dozen low-level interactions**" for a simple sign-up.
  - **The payoff**: "it makes perfect sense for our automated tests to exercise this workflow **at least once** through the web-based interface… However, exercising it in full **every single time** a scenario requires the test actor to be signed up is rather wasteful." → the same outcome is a single POST request.

- **Split by rule** — a batching strategy that falls out of the map: "instead of trying to automate all the scenarios of a given workflow in one go, we could instead divide them by business rules they support and implement in **much smaller batches, one business rule at a time**."
  - Diagnostic bonus: "the **ratio of scenario to rule cards** is an indication of [a workflow's] variability."

- **Journey Map card colors** (extending Feature Mapping's convention):
  | Color | Represents |
  |---|---|
  | **White** (left of board) | Workflows |
  | **Green** | Scenarios |
  | **Purple** | Consequences |
  | **Yellow** (middle) | Tasks / activities |
  | **Blue** | Business rules |
  | **Pink** | Unanswered questions, topics for exploratory testing |

## Key Concepts

- **Beginner's mind** — approach discovery "dropping our assumptions, expectations, and preconceived ideas about what the system should and shouldn't do in our opinion." Asking each stakeholder their perspective "will help us understand the business context better and highlight any inconsistencies and contradictions sooner… in an objective and blameless way."
- **Expectations vs. reality** — describe outcomes with *"should"*, because "when it comes to complex legacy systems, the expected outcome might sometimes be at odds with the actual outcome." Establishing what a system *should* do "tends to be a better starting point than simply mirroring the current behavior of the system in your automated tests," and avoids "replicating any defects and misunderstood requirements from the system into your test suite."
- **Cast** (Serenity/JS) — a factory class implementing the `Cast` interface, telling the framework which actors to engage and with what abilities.
- **Notepad / `TakeNotes`** — an ability giving actors a state object holding initial data (persona details) and letting them record information mid-scenario for later use.
- **Blended testing** — mixing UI and API interactions within one scenario (covered in ch 15).
- **`TravelerDetails` factory** — generates persona data dynamically rather than reading from a JSON/CSV file or database.

## Mental Models

- **"The way we think about our automated tests is the way we treat them, and the way we treat them is what they become."** The chapter's argument for the whole framing shift.
- **Think "test automation system," not "tests."** "A specialized supporting system we develop to verify and document the behavior of the system under test… as soon as we start thinking in terms of **systems** we should see parallels with what we've already learned as an industry about software systems architecture, domain modeling, functional composition, or design patterns."
- **Workflow boundaries are where reusability lives.** "**Understanding where the boundaries lie between the different workflows is critical in designing reusable test code.**" Finding a flight and booking a flight are separate because a traveler might only be checking times or comparing prices — or might have entered booking directly from an ad, bypassing the finder entirely.
- **Start from the outcome and work backward.** "The easiest way to capture a workflow so that it can be then turned into an automated test is perhaps slightly counterintuitive: we'll start from the outcome and then work our way back. How would we know if a given workflow was successful?… And on the other hand, how would we know if a given workflow was **not** successful?"
- **Ask about prerequisites explicitly, and listen for red flags.** If you hear a workflow can't be done "without coordinating with a third party," "locking down the test environment to avoid interference from other testers," or "running an overnight batch process to set up the test data" — "you'll know right away that you need to incorporate solving those problems into your test automation approach."
- **The happy-path steel thread avoids combinatorial paralysis.** "It offers a mental model that helps us to avoid getting overwhelmed by the combinatorial explosion of all the possible paths an actor could take through the system. Instead, we will consider this variability within a much more manageable scope of each individual feature."
- **Keep DevTools open while exploring manually.** "This will help you spot opportunities to make your tests interact directly with the APIs." The observation that submitting the registration form fires a POST is what makes the API shortcut possible.
- **Optimize each layer for its reader.** "Just like we optimize the Cucumber scenarios for the reading experience of the **business audience**, we optimize our custom Serenity/JS tasks for the reading experience and to reduce the **cognitive load of the technical audience.**"

## Code Examples

**Generic Cast — every actor identical:**
```typescript
import { BeforeAll, AfterAll } from '@cucumber/cucumber'
import { configure, Cast } from '@serenity-js/core'
import { BrowseTheWebWithPlaywright } from '@serenity-js/playwright'
import * as playwright from 'playwright'

let browser: playwright.Browser

BeforeAll(async () => {                              // configure exactly once, before any scenario
  browser = await playwright.chromium.launch({ headless: true })
  configure({
    actors: Cast.whereEveryoneCan(
      BrowseTheWebWithPlaywright.using(browser),
    )
  })
})

AfterAll(async () => {
  await browser.close()
})
```

**Custom Cast — actors as distinct personas with three abilities:**
```typescript
import { Actor, configure, Cast, TakeNotes, Notepad } from '@serenity-js/core'
import { BrowseTheWebWithPlaywright, PlaywrightOptions } from '@serenity-js/playwright'
import { CallAnApi } from '@serenity-js/rest'

class Actors implements Cast {
  constructor(
    private readonly browser: playwright.Browser,
    private readonly options: PlaywrightOptions,
  ) {}

  prepare(actor: Actor): Actor {
    return actor.whoCan(
      BrowseTheWebWithPlaywright.using(this.browser, this.options),
      CallAnApi.at(this.options.baseURL),
      TakeNotes.using(
        Notepad.with<TravelerNotes>({
          travelerDetails: TravelerDetails.of(actor.name),
        }),
      ),
    );
  }
}

BeforeAll(() => {
  configure({
    actors: new Actors(browser, { baseURL: 'http://localhost:3000/' })
  })
})
```

**Notepad contents and the persona factory:**
```typescript
export interface TravelerNotes {
    travelerDetails: TravelerDetails
}

export abstract class TravelerDetails {
  title: string;   firstName: string;  lastName: string;
  email: string;   password: string;
  address: string; country: string;
  seatPreference: 'window' | 'aisle';

  static of(actorName: string): TravelerDetails {
    return {
      title: 'Mx',
      firstName: actorName,
      lastName: 'Traveler',
      email: `${ actorName }.Traveler@example.org`,
      password: 'P@ssw0rd',
      address: '35 Victoria Street, Alexandria',
      country: 'Australia',
      seatPreference: 'window'
    }
  }
}
```
**TypeScript note**: the returned plain object is compatible with the `TravelerDetails` abstract class "even though it does **not** inherit from it," because TypeScript uses a **structural** type system. "Note that this is different than in Java, where its **nominal** type system makes using structures like enums more appropriate."

**Custom Cucumber parameter types for actors and pronouns:**
```typescript
import { defineParameterType } from '@cucumber/cucumber'
import { actorCalled, actorInTheSpotlight } from '@serenity-js/core'

defineParameterType({
    name: 'actor',
    regexp: /[A-Z][a-z]+/,
    transformer: (name: string) => actorCalled(name)
})

defineParameterType({
    name: 'pronoun',
    regexp: /he|she|they|his|her|their/,
    transformer: () => actorInTheSpotlight()
})
```
`actorCalled(name)` "retrieves the actor that's already been instantiated or instantiates one and passes it to our implementation of the `Cast` interface, where the actor is configured with abilities and the initial state of the `Notepad`."
**Caveat**: "the regular expressions work for scenarios expressed in English and will need to be adjusted to support other languages."

**Step definitions — the two async patterns.**

*Pattern 1 — bracket-less arrow function, for simple steps that only call `attemptsTo`:*
```typescript
Given('{actor} has signed up', (actor: Actor) =>
  actor.attemptsTo(/* activities */)
)
```
"This minimal bracket-less arrow function expression helps us avoid the syntax noise of the equivalent but much more verbose traditional anonymous function":
```typescript
Given('{actor} has signed up', function (actor: Actor): Promise<void> {
  return actor.attemptsTo(/* activities */)
})
```

*Pattern 2 — `async`/`await`, for multiple actors or extra variables:*
```typescript
// When Alice sends a message "hello!" to Bob
When('{actor} sends a message {string} to {actor}',
  async (sender: Actor, messageText: string, receiver: Actor) => {
    await sender.attemptsTo(
      SendMessage.with(messageText).to(receiver.name)
    )
    await receiver.attemptsTo(
      Ensure.that(Messages.received(), contain(messageText)),
    )
  }
)
```
**Why this matters**: "all the APIs provided by the framework are asynchronous by default… `actor.attemptsTo(...)` returns a `Promise`. This `Promise` **needs to be returned** to any test runner that invokes Serenity/JS code… so that it can correctly synchronize its execution."

## Worked Example

**Building the Flying High Journey Map, step by step.**

*Step 1 — actor and goal.* Ask the business sponsor the primary purpose. Answer: "to enable travelers to book a flight."
→ Actor: **traveler**. Goal: **book a flight**.

*Step 2 — workflows.* To book a flight: **find a flight**, then **make a booking**. Deliberately kept separate — "because an actor is looking for a flight doesn't necessarily mean that they want to make a booking. It could be that they want to check the departure and arrival times or compare its price. The same goes for the flight-booking workflow… they might have entered the booking workflow right after clicking on an ad or a link in the newsletter, therefore bypassing the flight finder altogether."

*Prerequisites.* The system supports only authenticated travelers → an unauthenticated traveler must **sign in**; one with no account must **sign up** first.

*Step 3 — associate with features.* Sign up → *registration*. Sign in → *authentication*. Find a flight → *flight finder*. Make a booking → *bookings*.
Note that features enable *multiple* workflows: authentication also enables reset-password; flight finder might offer favorite destinations; bookings might allow extra services, rescheduling, or refunds.

*Step 4 — the steel thread.* Pick the **simplest successful** scenario per feature:
| Feature | Simplest successful scenario |
|---|---|
| Registration | Sign up with valid traveler details, **email-based** registration (not third-party) |
| Authentication | Sign in with valid credentials — nothing to trip form validation |
| Flight finder | Search for a **one-way direct flight in economy class** |
| Bookings | Book that flight |

*Step 5 — consequences, forward and backward.*
- Happy path: the traveler's account is created → the actor can proceed to sign-in.
- Unhappy path: invalid registration details → form validation kicks in, the account is **not** registered, and the actor is advised how to fix the problems.
- Unknown activities get a placeholder card marked **TBC**.

*Step 6 — task analysis of "sign up".* One high-level task (*sign up via Web UI*) with three subtasks: locate the registration form, fill it out, submit it while confirming success. Expanded fully, that's over a dozen low-level interactions — navigate to homepage, click register, specify salutation, type first name, type last name, …

*The optimization the DevTools console revealed*: submitting the form fires a single **HTTP POST to the registration API**. So in every scenario where registration is a *precondition* rather than the subject, one POST replaces a dozen browser interactions.

**From Journey Map tasks to Cucumber steps.**

The rule the chapter derives: **scenario steps should correspond to the high-level tasks from the Journey Map.** Since "our target audience typically has a very limited amount of time to dedicate to reviewing… it's important to ensure those scenarios are succinct and highlight only the important steps directly affecting the outcome."

The happy path becomes **two steps** — matching the two high-level tasks:
```gherkin
Feature: Sign up

  Customers must sign up to the Frequent Flyer program to book flights
  that earn them Frequent Flyer points.

  Rule: Registered Frequent Flyer account is required to use the system

    Scenario: Sign up using valid traveler details

      When Tracy signs up using valid traveler details
      Then she should be able to sign in
```

The negative case, **at most four steps**, with narrative context carried in the description:
```gherkin
Feature: Sign up
  # ...

  Rule: Duplicate usernames are not allowed

    Scenario: Sign up using duplicate email address

      Mike Smith is an existing Frequent Flyer member.
      His wife Jenny Smith does not have a Frequent Flyer account.

      Given Mike has signed up using the following details:
        | email | smiths@example.org |
      When Jenny tries to sign up using:
        | email | smiths@example.org |
      Then she should be advised of an error: "Email exists"
      And she should be presented with an option to reset password
```
"Both the scenarios… highlight only the important steps that affect the final outcome and use **metadata in the form of scenario descriptions and rule names** to provide additional context."

**The step definition, decomposed.**
```typescript
// "When Tracy signs up using valid traveler details"
When('{actor} signs up using valid traveler details', (actor: Actor) =>
  actor.attemptsTo(
    SignUp.using(
      notes<TravelerNotes>().get('travelerDetails')
    ),
    VerifySubmission.succeededWith('registered successfully')
  ));
```
Line by line, per the book:
1. A **Cucumber expression** defines the matching pattern; the `{actor}` token is substituted with a Serenity/JS actor via the custom parameter type.
2. `actor.attemptsTo(...)` **creates the mapping** between a Cucumber step and a sequence of Screenplay tasks.
3. A custom `SignUp` task is instantiated via its static factory method.
4. It's parameterized with a **note** on `travelerDetails`, retrieved from the actor's notepad.
5. A second custom task verifies the submission succeeded.

And using a pronoun for the follow-on step:
```typescript
Then('{pronoun} should be able to sign in', async (actor: Actor) => {
    const details = notes<TravelerNotes>().get('travelerDetails')

    await actor.attemptsTo(
        SignIn.using(details.email, details.password),
    )
})
```
"Since it's more natural to think of the task to `SignIn` as only requiring two arguments, the email and the password, we extract a variable, `travelerDetails`, to avoid code duplication and then pass the required parameters individually."

**Note what hasn't been written yet.** `SignUp` and `SignIn` don't exist at this point — and that's deliberate: "it is, in fact, a common practice when working with Serenity/JS to approach designing any such custom, domain-specific tasks the exact same way we approach designing the rest of our test automation system. **We start from the outside and optimize the interfaces in each layer for the experience of its intended audience.**"

## Anti-patterns

- **Writing or generating as many test scripts as possible** to cover a legacy system: mistakes volume for value.
- **Limiting automation to end-to-end tests against a fully assembled, deployed system**: "missing opportunities to integrate tests with programmatic APIs, not paying enough attention to the context in which the system operates, or not taking the business priorities and risks into consideration."
- **Assuming you already know why the system exists**: drop the assumption; ask each stakeholder.
- **Mirroring the system's current behavior in your tests**: risks "replicating any defects and misunderstood requirements from the system into your test suite."
- **Mapping the entire system upfront**: iterate — map a slice, automate it, map again.
- **Treating acceptance tests as "unsophisticated scripts"**: "it's fine for them to look like spaghetti code of low-level interactions, devoid of business domain meaning" — this view produces "slow, flaky tests… difficult-to-understand and reused test code."
- **Implementing low-level interaction sequences directly in step definition libraries**: even Cucumber users fall into this; it's the Domain-layer-skipping error.
- **Calling WebDriver APIs from the Specification layer**: couples specifications to tools and blocks blended testing and reuse.
- **Driving a full UI workflow every time it's merely a precondition**: "rather wasteful" — a dozen interactions where one POST would do.
- **Automating a whole workflow's scenarios in one batch**: split by rule instead.
- **Forgetting to return the `Promise` from `attemptsTo()`**: the test runner can't synchronize execution.

## Key Takeaways
1. On a legacy system, discover *how existing features are used* and which sit on the critical path — not what to build.
2. Map actors → goals → workflows → features, and interrogate prerequisites; red-flag answers ("overnight batch," "coordinate with a third party") are automation requirements in disguise.
3. Draw workflow boundaries deliberately: they're where reusable test code comes from.
4. Build a steel thread of simplest-successful scenarios end to end *first* — it surfaces assumptions and hidden dependencies while you still have time to act.
5. "End to end" means the ends of the *workflow*, not the full deployed stack through a browser. Use APIs and in-memory DBs freely within it.
6. Work backward from consequences; ask both "how would we know it succeeded?" and "how would we know it failed?"
7. Describe outcomes with "should" — expected behavior, not observed behavior, or you'll enshrine existing bugs.
8. Use HTA to decompose tasks, then exercise the full UI path *once* and take the API shortcut everywhere it's only a precondition.
9. Keep DevTools open during manual exploration; the network tab tells you where the shortcuts are.
10. Structure the suite as a three-layer system, and never let the Specification layer touch integration APIs directly.
11. Make Cucumber step count match the count of high-level Journey Map tasks — two-step scenarios are a feature, not a shortfall.
12. Split automation work by business rule to keep batches small.

## Connects To
- **Ch 6**: Feature Mapping — Journey Mapping extends its card conventions and consequence-first thinking.
- **Ch 9**: layers of abstraction — the same idea, formalized here as a three-layer architecture.
- **Ch 12**: the Screenplay Pattern — actors, abilities, tasks, and Cast, now in TypeScript.
- **Ch 13**: the API-shortcut principle; `CallAnApi` reappears here as an ability.
- **Ch 15**: the Domain layer implementation, blended testing, and portability across Playwright/WebdriverIO/Selenium.
- **Hierarchical Task Analysis (HTA)** from UX research; **Serenity/JS**, **Playwright**, **Cucumber.js**, **Mocha/Jasmine**: tools and techniques used.
