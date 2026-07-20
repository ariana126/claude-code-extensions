# Chapter 15: Portable Test Automation with Serenity/JS

## Core Idea
Abstract the *integration tool itself*, not just its API calls. Combine that with **blended testing** (UI where it matters, API where it doesn't), **task substitution**, and **parameterized tasks**, and you get test code portable across tools, suites, and teams.

## Frameworks Introduced

- **Interfaces are doors, not destinations** — the framing that drives the whole chapter:
  > "It is a mistake to focus on the external interfaces themselves as the subjects of our acceptance tests (there will be other tests for that). Rather, external interfaces are the means for a test automation system to interact with the business logic implemented by the system under test — **doors through which the tests can interact with concepts from the business domain**. Note that this is similar to how the actual external actors perceive the interfaces: the reason for a traveler to use a Web UI is to book a plane ticket, **not to interact with the UI for the sake of it**."
  - And: "Just like in the real world, we don't reason about the activities performed by an actual traveler in terms of sequences of meaningless clicks; neither should our acceptance tests."

- **Tasks as functions — parameter vs. argument.** The functional-programming framing that makes tasks reusable:
  | Concept | In a task |
  |---|---|
  | Function | The task (`SignUp`) |
  | **Parameter** | What varies (`travelerDetails`) — "task parameters enable variations in the consequences of a task" |
  | **Argument** | A concrete value (valid details → success; invalid details → failure) |
  - "The only factor that affects the outcome of the task to sign up is **what traveler details the actor provides**."

- **Pending tasks via `Task.where`** — two properties that make outside-in development work:
  1. **Rest parameter syntax** accepts one or more activities, so tasks compose from subtasks trivially.
  2. **Omit the activities** and the task throws `ImplementationPendingError` on execution; "Serenity/JS reports scenarios where such an error occurred as **pending implementation**." A way to name tasks you don't know how to build yet and still get a report showing where they sit.

- **Task substitution** — what the outside-in naming discipline unlocks:
  > "Defining acceptance test tasks from the perspective of an external actor and naming the tasks to describe **the business domain goal they help to accomplish, as opposed to how they do it**… enables substituting one task for another without affecting the tests that rely on it. That is, of course, if the tasks in question accomplish the same goal."
  - When you need *both* implementations available at once, "group the alternative implementations of a given task under a single class named after the goal," with method names indicating the difference: `LocateRegistrationForm.viaHomePage` / `.viaDirectNavigation`.
  - "This idea of substituting one task for another that accomplishes the same goal works at **all the levels of abstraction** and is the foundation of blended testing."

- **Blended testing** — "interacting with different external interfaces of the system under test in a single scenario **to play to their strengths**."
  - **Why UIs are slow to automate** — the specific UX patterns that cost you: a lengthy form "split across numerous pages to help the user make sense of where they are"; an online payment system introducing "artificial delays to help make its users feel that a transaction is more secure since it 'takes longer'"; animations "to make interacting with them more engaging." "Each one of those patterns increases the amount of time an automated test needs to spend interacting with the UI."
  - **The grammatical-voice convention** — the chapter's most elegant idea:
    | Keyword | Voice | Means | Implementation |
    |---|---|---|---|
    | `Given` | **Passive** — "Tracy **has signed up**" | We only care *that* it's done | API call |
    | `When` | **Active** — "Tracy **signs up**" | We want to *demonstrate how* it's done | Web UI |
    - "Since the steps are expressed using two grammatical voices, it's easy to differentiate between them when implementing their associated step definitions since they use a **different Cucumber expression** to match the step."
  - **If no API exists**: "it's worth considering creating **test-specific programmatic APIs** that help with test-specific tasks, such as registering test accounts, setting up test data, or accessing information about the state of the system under test that might not be available through the user interface."

- **System-level vs. component tests.** "A common mistake is to execute **all** the acceptance tests only against a fully assembled system deployed to a production-like environment." Alternatives: a web UI connected to mock web services, or individual UI components rendered with **Storybook** or **Playwright Component Tests**.

- **The three portability threats** the abstraction layer defends against:
  1. **Cross-tool incompatibility.** Selenium WebDriver, WebdriverIO, Puppeteer, Playwright, Cypress "each use different programming models and different APIs. This cross-tool incompatibility prevents test code written for one test integration tool from being used with another."
  2. **Different tools suit different suites.** Playwright for component tests and smoke tests (fast, good DX, modern rendering engines); WebdriverIO/Selenium for cross-browser and remote-grid tests (native WebDriver protocol support). "We could use Playwright for component tests and WebdriverIO for cross-browser tests **without having to change the test code**."
  3. **Tool lock-in.** "It mitigates the risk of the scenario where the maintainers of a given integration tool stop to support it." *(Footnote: exactly what happened to Angular Protractor — last commit 2020, EOL with Angular v16.)*

- **Two Page Object variants under Screenplay:**
  | | Classic Page Object (ch 11) | **Lean Page Object** | **Companion Page Object** |
  |---|---|---|---|
  | Responsibilities | Locate elements **and** model interactions | **Only** provide information about the widget | Provide element access **and** tasks, host element injected |
  | Why | — | Screenplay's tasks/interactions already model behavior | Ship test code alongside the widget library |
  | Returns | Values | `PageElement` / `QuestionAdapter` | **Tasks and question adapters**, "to make it easy to compose their results into higher-level types" |

- **Page Element Query Language** — for when there are no test-friendly identifiers. Uses **the same expectations** as assertions, synchronization, and flow control, and is extensible with your own expectations and questions:
  ```typescript
  Form.fields()
      .where(Form.label(), isPresent())
      .where(Text.of(Form.label()), equals(name))
      .first()
  ```

- **Service provider framework architecture.** `@serenity-js/web` "does not depend on, nor interact directly with, any test integration tools." It relies on `@serenity-js/playwright`, `@serenity-js/webdriverio` etc. to supply implementations of `Page` and `PageElement`.
  - **The one tool-specific piece**: the ability — `BrowseTheWebWithPlaywright` vs. `BrowseTheWebWithWebdriverIO`. That single configuration choice determines which service classes get instantiated. Everything else is agnostic.
  - You never call `WebdriverIOPage` or `PlaywrightPageElement` directly; you use service access APIs like `Page.current()` and `PageElement.located(By.css(...))`.

- **Cross-team code sharing** — the organizational problem and its fix:
  - **The problem**: a component team automates their widget tests "to the highest possible standard," but "consumer teams typically don't benefit from that at all when writing their end-to-end tests." Consumer teams must rediscover selectors, and must "keep their higher-level tests in sync with any changes introduced by the component teams." Worse: "the inherent risk of component teams **unknowingly breaking other teams' tests**" when HTML structure or data shapes change. Contract tests mitigate the API case; the duplication remains.
  - **The fix**: component teams **publish** their Serenity/JS test code, versioned with the component. "A mechanism that works well… is to publish it as part of the **same Node module** used to ship the widgets, but under a **separate entry point** to avoid interference of shared test code with production code."

## Key Concepts

- **`QuestionAdapter<T>`** — a proxy wrapping a data structure so static and dynamic/lazy-loaded values share one API. "Any fields we reference will also get wrapped in such proxy objects **recursively**, providing a consistent programming model."
- **`Question.fromObject`** — merges static, dynamic, or partially dynamic data structures into a `QuestionAdapter`. The mechanism for overriding persona defaults per scenario.
- **`Wait.until(value, expectation)` / `Wait.for(duration)`** — in **Core**, not the web module. "You can use them, for example, to keep polling a REST API until it returns a response that meets your expectation. This pattern can be useful when testing batch processing systems that process data asynchronously."
- **Expectations** (`isPresent()`, `equals()`, `includes()`, `not()`, `matches()`) — compatible across `Wait.until`, `Ensure.that`, *and* the Page Element Query Language. One vocabulary, three uses.
- **`PageElement` / `PageElements`** — a single element / a collection with query-language APIs.
- **`.describedAs(...)`** — custom description used in reporting.
- **`.of(parent)`** — establishes a parent/child relationship between page elements; chainable, and the host can be injected at runtime.
- **Toast** — "a brief, temporary notification that's shown when the actor submits the form, and that disappears shortly afterward."

## Code Examples

**Pending tasks — capture vocabulary before implementation:**
```typescript
import { Task } from '@serenity-js/core'

const LocateRegistrationForm = () =>
    Task.where('#actor locates registration form')          // no activities → pending

const FillOutRegistrationForm = (travelerDetails: TravelerDetails) =>
    Task.where('#actor fills out registration form')

const SubmitRegistrationForm = () =>
    Task.where('#actor submits registration form')

const SignUp = (travelerDetails: TravelerDetails) =>
    Task.where('#actor signs up',
        LocateRegistrationForm(),
        FillOutRegistrationForm(travelerDetails),
        SubmitRegistrationForm(),
    )
```
"Even though our tasks don't yet do anything meaningful, they already help us to capture business domain concepts and vocabulary… This pattern of using business domain vocabulary to name tasks helps to establish consistent terminology and **ubiquitous language** shared by both the business and technology folk." (Citing Evans, *Domain-Driven Design*, pp. 32–35.)

**Composing tool-agnostic interactions:**
```typescript
import { Task } from '@serenity-js/core'
import { Click, Navigate } from '@serenity-js/web'

const LocateRegistrationForm = () =>
    Task.where(`#actor locates the registration form`,
        Navigate.to('/'),
        Click.on(Form.buttonCalled('Register')),
    )
```
"Interactions to click and to navigate come from the Serenity/JS Web module. This module is **agnostic of the low-level integration tool** used."

**Grouped task variations:**
```typescript
export class LocateRegistrationForm {
    static viaHomePage = () =>
        Task.where(`#actor locates registration form via home page`,
            Navigate.to('/'),
            Click.on(Form.buttonCalled('Register')),
        );

    static viaDirectNavigation = () =>
        Task.where(`#actor registration form via direct navigation`,
            Navigate.to('/register'),      // same goal, faster
        );
}
```

**Blended testing — two implementations of one goal:**
```typescript
import { Answerable, QuestionAdapter, Task } from '@serenity-js/core'
import { Send, PostRequest } from '@serenity-js/rest'
import { Ensure, equals } from '@serenity-js/assertions'

class SignUp {
  using = (travelerDetails: QuestionAdapter<TravelerDetails>) =>
    Task.where(`#actor signs up`,
      LocateRegistrationForm(),
      FillOutRegistrationForm.using(travelerDetails),
      SubmitRegistrationForm(),
    )

  viaApiUsing = (travelerDetails: QuestionAdapter<TravelerDetails>) =>
    Task.where(`#actor signs up (via API)`,
      Send.a(PostRequest.to('/api/auth/register').with(travelerDetails)),
      Ensure.that(LastResponse.status(), equals(201)),
    )
}
```
Wired to the two grammatical voices:
```typescript
Given('{actor} has signed up', (actor: Actor) =>          // passive → API
    actor.attemptsTo(
        SignUp.viaApiUsing(notes<TravelerNotes>().get('travelerDetails')),
    ))

When('{actor} signs up', (actor: Actor) =>                // active → UI
    actor.attemptsTo(
        SignUp.using(notes<TravelerNotes>().get('travelerDetails')),
    ))
```

**`QuestionAdapter` recursion in action** — referencing fields of a proxied object as if it were static:
```typescript
export const FillOutRegistrationForm =
  (travelerDetails: QuestionAdapter<TravelerDetails> | TravelerDetails) =>
    Task.where(`#actor fills out the registration form`,
      SpecifyEmailAddress(travelerDetails.email),
      SpecifyPassword(travelerDetails.password),
      SpecifySalutation(travelerDetails.title),
      SpecifyFirstName(travelerDetails.firstName),
      SpecifyLastName(travelerDetails.lastName),
      SpecifyHomeAddress(travelerDetails.address),
      SpecifyCountryOfResidence(travelerDetails.country),
      SpecifySeatPreference(travelerDetails.seatPreference),
      ToggleNewsletterSubscription.off(),
      ToggleTermsAndConditions.on(),
    )
```

**Lean Page Object — transforming a CSS class into a domain concept:**
```typescript
import { By, CssClasses, PageElement } from '@serenity-js/web'
import { QuestionAdapter } from '@serenity-js/core'

export class Toaster {
    private static component = () =>
        PageElement.located(By.css(`.ngx-toastr`)).describedAs('toaster')

    static message = () =>
        PageElement.located(By.css(`.toast-message`))
            .of(Toaster.component())
            .describedAs('message')

    static status = () =>
        CssClasses.of(Toaster.component())
            .filter(cssClass => cssClass.startsWith('toast-'))
            .map(cssClass => cssClass.replace('toast-', ''))
            .slice(0, 1)[0]
            .describedAs('toaster status') as QuestionAdapter<string>
}
```
Note `status()`: `toast-success` / `toast-error` becomes `'success'` / `'error'` — "the low-level concept of a CSS class into a much more meaningful concept of the 'success' or 'error' state of the widget."

**Companion Page Object — host element injected, methods return tasks:**
```typescript
export class Toaster {
  constructor(private readonly hostElement: QuestionAdapter<PageElement>) {}

  message = () =>
    PageElement.located(By.css(`.toast-message`))
      .of(this.hostElement).describedAs('message');

  status = () =>
    CssClasses.of(this.hostElement)
      .filter(cssClass => cssClass.startsWith('toast-'))
      .map(cssClass => cssClass.replace('toast-', ''))
      .slice(0, 1)[0]
      .describedAs('toaster status') as QuestionAdapter<string>

  dismissMessage = () =>                       // returns a Task, not void
    Task.where(`#actor dismisses the message`,
      Wait.until(this.message(), isPresent()),
      Click.on(this.message()),
      Wait.until(this.message(), not(isPresent())),
    )
}
```

**Page Element Query Language — finding an input by its label text.** The Angular Material HTML gives you nothing to select on:
```html
<mat-form-field>
    <div class="mat-form-field-wrapper">
        <div class="mat-form-field-flex">
            <div class="mat-form-field-infix">
                <input name="email">
                <span><label for="email" aria-owns="email">
                    <mat-label>Email</mat-label>
                </label></span>
            </div>
        </div>
        <div><mat-error>Please enter your email</mat-error></div>
    </div>
</mat-form-field>
```
The completed `Form` class:
```typescript
import { matches, includes, isPresent } from '@serenity-js/assertions'
import { By, PageElement, PageElements, Text } from '@serenity-js/web'

export class Form {
    static buttonCalled = (name: string) =>
        Form.buttons().where(Text, includes(name)).first()
            .describedAs(`the "${ name }" button`)

    static inputFor = (name: string) =>
        Form.input().of(Form.fieldCalled(name))
            .describedAs(`the "${ name }" field`)

    static errorMessageFor = (name: string) =>
        Text.of(Form.errorMessage().of(Form.fieldCalled(name))
                   .describedAs(`the error message for "${ name }" field`))

    private static fieldCalled = (name: string) =>
        Form.fields()
            .where(Form.label(), isPresent())
            .where(Text.of(Form.label()), matches(new RegExp(name, 'i')))
            .first()

    public static buttons = () =>
        PageElements.located(By.css('button')).describedAs('buttons');

    public static fields = () =>
        PageElements.located(By.css('mat-form-field')).describedAs('form fields');

    public static label = () =>
        PageElement.located(By.css('label > mat-label, label > span')).describedAs('label')

    private static input = () => PageElement.located(By.css('input'))
    private static errorMessage = () => PageElement.located(By.css('mat-error'));
}
```
Which reduces a task to one line:
```typescript
export const SpecifyEmailAddress = (emailAddress: Answerable<string>) =>
    Task.where(`#actor specifies their email address`,
        Enter.theValue(emailAddress).into(Form.inputFor('Email')))
```

**Tool configuration — the single tool-specific line:**
```typescript
import { actorCalled, configure, Cast } from '@serenity-js/core'
import { BrowseTheWebWithPlaywright } from '@serenity-js/playwright'
import * as playwright from 'playwright'

const browser: playwright.Browser = await playwright.chromium.launch()

configure({
  actors: Cast.whereEveryoneCan(
    BrowseTheWebWithPlaywright.using(browser)      // ← the ONLY tool-specific part
  )
})

actorCalled('William').attemptsTo(
  Click.on(PageElement.located(By.css('.selector'))),   // fully tool-agnostic
)
```

## Worked Example

**Verification tasks: from a four-call sequence to one business phrase.**

The scenario step:
```gherkin
Then she should be advised of an error: "Email exists"
```
The toast widget's HTML:
```html
<div class="ngx-toastr toast-error">
    <div class="toast-message">Email exists, please try another name</div>
</div>
```

Because the message is a *toast* — brief, animated, self-dismissing — verifying it requires **four** things: trigger the error state, wait for the message to appear (after an animation), verify the text, and dismiss it to avoid waiting out the transition animation.

*The naive step definition works — and violates the layering rule:*
```typescript
import { Actor, Wait } from '@serenity-js/core'
import { Click } from '@serenity-js/web'
import { Ensure, includes, isPresent, not } from '@serenity-js/assertions'

Then('{pronoun} should be advised of an error: {string}',
  (actor: Actor, expectedMessage: string) =>
    actor.attemptsTo(
      Wait.until(ToasterMessage(), isPresent()),                              // wait
      Ensure.that(Text.of(ToasterMessage()), includes(expectedMessage)),      // verify
      Click.on(ToasterMessage()),                                             // dismiss
      Wait.until(ToasterMessage(), not(isPresent())),                         // wait
  )
)
```
"While this implementation works, it's far from ideal as it **violates the design principle** we discussed in section 14.2.1 — the one for the component of the Specification layer (the Cucumber step definition) not to directly invoke components of the interface-specific Integration layer."

*The composed version:*
```typescript
Then('{pronoun} should be advised of an error: {string}',
  (actor: Actor, expectedMessage: string) =>
    actor.attemptsTo(
      VerifySubmission.failedWith(expectedMessage),
  )
)
```
> "Compare the clarity of **'verify submission failed with an expected message'** versus the low-level sequence of interactions to **'wait, check, click, wait.'**"

*And the implementation, showing variation-grouping applied to verification:*
```typescript
import { Ensure, equals, includes, isPresent, not } from '@serenity-js/assertions';
import { Task, Wait } from '@serenity-js/core';
import { Click, Text } from '@serenity-js/web';
import { Toaster } from './Toaster';

export class VerifySubmission {
  static succeededWith(expectedMessage: string) {
    return Task.where(`#actor confirms successful form submission`,
      VerifySubmission.hasMessage(expectedMessage),
      VerifySubmission.hasStatus('success'),
      VerifySubmission.dismissMessage(),
    );
  }

  static failedWith(expectedMessage: string) {
    return Task.where(`#actor confirms failed form submission`,
      VerifySubmission.hasMessage(expectedMessage),
      VerifySubmission.hasStatus('error'),        // the only difference
      VerifySubmission.dismissMessage(),
    );
  }

  private static hasMessage(message: string) {
    return Task.where(`#actor confirms notification includes ${ message }`,
      Wait.until(Toaster.message(), isPresent()),
      Ensure.that(Text.of(Toaster.message()), includes(expectedMessage)),
    );
  }

  private static hasStatus(status: 'success' | 'error') {
    return Task.where(`#actor confirms form submission ${ status }`,
      Wait.until(Toaster.message(), isPresent()),
      Ensure.that(Toaster.status(), equals(status)),
    );
  }

  private static dismissMessage() {
    return Task.where(`#actor dismisses the message`,
      Wait.until(Toaster.message(), isPresent()),
      Click.on(Toaster.message()),
      Wait.until(Toaster.message(), not(isPresent())),
    );
  }
}
```
Both public variants share three private subtasks; only `hasStatus` differs. And it plugs into the happy path too:
```typescript
When('{actor} signs up using valid traveler details', (actor: Actor) =>
    actor.attemptsTo(
      SignUp.using(notes<TravelerNotes>().get('travelerDetails')),
      VerifySubmission.succeededWith('registered successfully'),
    ))
```

**Persona defaults with per-scenario overrides — killing feature-file clutter.**

*The problem.* A step definition requiring all details in one go produces this:
```gherkin
Scenario: Sign up using valid traveler details
  When Tracy signs up using following traveler details:
    | firstName      | Tracy                          |
    | lastName       | Traveler                       |
    | email          | Tracy.Traveler@example.org     |
    | password       | P@ssw0rd                       |
    | title          | Mx                             |
    | address        | 35 Victoria Street, Alexandria |
    | country        | Australia                      |
    | seatPreference | window                         |
  Then she should be able to sign in
```
"This is not ideal as it would seriously **clutter the feature file and distract the reader** from noticing the important details, not to mention the duplication of data this would cause across scenarios."

*The three-part solution:*
1. Give each actor a persona data set (via `TakeNotes` + `Notepad`, from ch 14).
2. Have step definitions inject that default set as the task argument.
3. **Partially override** the defaults in scenarios simulating error conditions.

*The signature change this requires.* The task originally took a static, synchronous structure:
```typescript
const SignUp = (travelerDetails: TravelerDetails) => Task
```
But the notepad "uses **dynamic** and **asynchronous** data structures to allow you to work with both static and dynamic/lazy-loaded data structures simultaneously using a consistent API." So:
```typescript
import { QuestionAdapter, Task } from '@serenity-js/core'

const SignUp = (travelerDetails: QuestionAdapter<TravelerDetails>) => Task
```
"Conveniently, all built-in Serenity/JS Screenplay APIs accept static and dynamic arguments."

*Default case:*
```typescript
When('{actor} signs up using valid traveler details', (actor: Actor) =>
    actor.attemptsTo(
        SignUp.using(notes<TravelerNotes>().get('travelerDetails')),
    ));
```

*Override case, merging defaults with scenario data:*
```typescript
import { Actor, Question } from '@serenity-js/core'
import { When, DataTable } from '@cucumber/cucumber'

When('{actor} tries to sign up using:', (actor: Actor, data: DataTable) =>
    actor.attemptsTo(
        SignUp.using(
            Question.fromObject<TravelerDetails>(
                notes<TravelerNotes>().get('travelerDetails'),   // defaults
                data.rowsHash() as Partial<TravelerDetails>,     // overrides
            )
        )
    ));
```

*Which lets the duplicate-email scenario stay minimal:*
```gherkin
Rule: Duplicate usernames are not allowed
  Scenario: Sign up using duplicate email address

    Mike Smith is an existing Frequent Flyer member.
    His wife Jenny Smith does not have a Frequent Flyer account.

    Given Mike has signed up using the following details:
      | email | smiths@example.org |
    When Jenny tries to sign up using:
      | email | smiths@example.org |
    Then she should be advised of an error: "Email exists"
```
Two notes from the book:
- On making the shared email explicit: "While technically speaking we could have two actors with the same email address defined in their traveler notes and **not mentioned in the feature file at all**, highlighting the address in the scenario itself can help to get the point across better and draw readers' attention to this key detail."
- On choosing a data table over an inline parameter (`using email address of "smiths@example.org"`): "It allows us to easily alter **other** default parameters as well, if needed, and to specify **multiple overrides at the same time** without having to define a separate Cucumber step for each override":
```gherkin
Given Mike has signed up using the following details:
  | firstName      | Michael            |
  | seatPreference | aisle              |
  | email          | smiths@example.org |
```

**Two ways to locate a page element, and why chaining matters.**

*Absolute, relative to the browsing context:*
```typescript
const ToasterMessage = () =>
    PageElement.located(By.css(`.ngx-toastr > .toast-message`))
        .describedAs('toaster message')
```

*Relative to a containing element:*
```typescript
const Toaster = () =>
    PageElement.located(By.css(`.ngx-toastr`)).describedAs(`toaster`)

const ToasterMessage = () =>
    PageElement.located(By.css(`.toast-message`))
        .of(Toaster())
        .describedAs('message')
```

*Chained with a runtime-injected host* — for when the same element appears in several places, or the container is only known at runtime:
```typescript
const NotificationsSection = () =>
    PageElement.located(By.id(`notifications`)).describedAs(`notifications section`)

const SpecificMessage = ToasterMessage().of(NotificationsSection())
```

## Mental Models

- **Simon Stewart (creator of Selenium WebDriver): "If you have WebDriver APIs in your test methods, you're doing it wrong."** Serenity/JS "takes this idea of abstracting the low-level API calls **one step further**, which enables you to abstract the entire web interface integration tool."
- **Web testing is hard because it's broad *and* deep.** "The scope being tested tends to be broad, particularly with the workflow-based acceptance testing. It also tends to be deep, as not every system allows for its user interface layer to be tested in isolation from the backend components."
- **The gradient from why → what → how.** "Those low-level activities are an implementation detail, the *how* of the much more important *what*, and the even more important *why*." Decompose one layer of abstraction at a time.
- **One expectation vocabulary, three uses.** `isPresent()`, `equals()`, `includes()` work identically in `Wait.until`, `Ensure.that`, and the Page Element Query Language — "a consistent programming experience whenever you need to make a decision, depending on whether an expectation is met."
- **`Wait` isn't a web concept.** It lives in Core, so it works for polling REST APIs and testing asynchronous batch systems too.
- **Naming tasks in domain vocabulary makes code readable by non-programmers.** "When the names of those tasks use the same domain-specific vocabulary our audience uses, our code becomes comprehensible even for audiences not used to programming or test automation in general."

## Anti-patterns

- **Treating external interfaces as the subject of acceptance tests**: they're the doors, not the destination.
- **Filling out the registration form via UI in every scenario needing an account**: "doing so for every single scenario in our test suite to perform test data setup would be **wasteful**."
- **Running all acceptance tests against a fully assembled, production-like deployment**: "a common mistake" — limit assembly where the scenario allows.
- **Invoking low-level web interactions directly in Cucumber step definitions**: violates the Specification/Integration layering rule.
- **Requiring all persona data inline in feature files**: clutters the file, hides the important detail, duplicates data across scenarios.
- **Inline step parameters where a data table would do**: forces a new step definition per override.
- **Writing separate test suites per integration tool**: exactly what the abstraction layer prevents.
- **Tool lock-in with hundreds of tests**: Protractor's EOL is the cautionary tale.
- **Consumer teams reverse-engineering selectors for shared widgets**: duplicated effort *plus* the risk of component teams silently breaking their tests.

## Key Takeaways
1. Model activities in domain vocabulary; the interface is how you reach the business logic, never the subject.
2. Stub tasks with `Task.where(description)` and no activities — you get the vocabulary and a pending-implementation report before writing any integration code.
3. Name tasks by goal, not mechanism; that's what makes one implementation substitutable for another.
4. Group task variations in a class named for the goal (`LocateRegistrationForm.viaHomePage` / `.viaDirectNavigation`).
5. Use the `Given`-passive / `When`-active convention to signal which steps get the API shortcut and which must go through the UI.
6. Build test-specific APIs if the system offers none — setup and state inspection are legitimate needs.
7. Compose `Wait` + `Ensure` sequences into named verification tasks; "verify submission failed" beats "wait, check, click, wait."
8. Give actors persona defaults via a Notepad and override only what a scenario needs, using `Question.fromObject` and a data table.
9. Take `QuestionAdapter<T>` in task signatures so static and lazily-resolved data work identically.
10. Keep Lean Page Objects information-only; use Companion Page Objects (returning tasks and adapters) when shipping test code with a widget library.
11. Reach for the Page Element Query Language when the DOM offers no test-friendly identifiers.
12. Isolate the integration tool behind one ability so the same suite runs on Playwright, WebdriverIO, or Selenium unchanged.
13. Have component teams publish their Screenplay test code alongside their widgets, under a separate module entry point.

## Connects To
- **Ch 11**: classic Page Objects — Lean and Companion variants refine that pattern under Screenplay.
- **Ch 12**: the Screenplay Pattern; `Task.where`, `Ensure`, actors, abilities.
- **Ch 13**: API-first automation — blended testing is its Serenity/JS formalization.
- **Ch 14**: the three-layer architecture, Journey Mapping, Cast, Notepad, and `TravelerDetails`.
- **Ch 10**: the locator strategies (`By.css`, `By.xpath`) that Serenity/JS abstracts.
- **Sources cited**: Eric Evans, *Domain-Driven Design* (ubiquitous language); Joshua Bloch, *Effective Java* (service provider framework); Marcano, Palmer, Smart & Molak, "Page Objects Refactored: SOLID Steps to the Screenplay Pattern" (2016).
- **Tools**: Serenity/JS (`@serenity-js/core`, `/web`, `/rest`, `/assertions`, `/playwright`, `/webdriverio`), Playwright, WebdriverIO, Selenium WebDriver, Puppeteer, Cypress, Storybook, Angular Material, Cucumber.js.
