# Screenplay Anti-Patterns

The full catalogue. Each entry gives the smell, why it hurts, and the fix.

## Architecture

### Skipping the Domain layer

**Smell.** A Cucumber step definition calls `page.click()`, `driver.findElement()`,
or Serenity/JS web interactions directly.

**Why it hurts.** The Specification layer — the interface between your test suite
and the people accepting the functionality — becomes welded to one interface and
one tool. Blended testing becomes impossible, and no other scenario can reuse the
logic.

**Fix.** Compose the sequence into a named task and call that. `VerifySubmission.failedWith(message)`
instead of "wait, check, click, wait."

### Treating the interface as the subject of the test

**Smell.** Tests named and organized around screens, endpoints, or components
rather than around what an actor is trying to achieve.

**Why it hurts.** External interfaces are doors through which tests reach business
logic, not destinations. A traveler uses the web UI to book a plane ticket, not to
interact with the UI for its own sake. Interface-shaped tests do not survive
interface changes, and there are already other tests for API contracts and
component rendering.

**Fix.** Name and structure tests by business goal. If you genuinely need to test
that an endpoint returns a 400 for a malformed payload, that is a unit test.

### Running every acceptance test against a fully assembled deployment

**Smell.** The whole suite requires a production-like environment with every
service running.

**Why it hurts.** "End to end" means the ends of the *workflow* — its breadth —
not maximum deployment depth. Full assembly makes runs slow, environments
contended, and failures ambiguous.

**Fix.** Exercise workflows against a UI backed by mocked services, in-memory
databases, or individually rendered components (Storybook, Playwright component
tests) wherever the scenario allows.

### Writing separate test suites per integration tool

**Smell.** One suite for Playwright component tests, another for Selenium
cross-browser runs, testing the same behavior.

**Why it hurts.** Double the maintenance for one set of business rules, and the
two drift apart.

**Fix.** Isolate the tool behind a single ability. One suite runs on either.

### Tool lock-in

**Smell.** Hundreds of tests calling one tool's API directly.

**Why it hurts.** Angular Protractor's last commit was 2020 and it hit end of life
with Angular v16. Teams coupled to it had no cheap exit.

**Fix.** The abstraction layer is insurance. Pay for it before you need it.

## Task design

### Building tests only from low-level interactions

**Smell.** `attemptsTo` receives twenty `Click` and `Enter` calls.

**Why it hurts.** This is barely an improvement over calling the driver directly.
You get lengthy tests where higher-level business concepts are hard to discern
and easy to lose in the noise of clicks and HTTP requests.

**Fix.** Group into tasks named for the goal. Decompose one layer of abstraction
at a time.

### Naming tasks by mechanism instead of goal

**Smell.** `ClickRegisterThenFillForm` rather than `SignUp`.

**Why it hurts.** Task substitution depends entirely on the name describing the
goal. A task named for its route cannot be swapped for a faster implementation of
the same goal, which kills blended testing.

**Fix.** Name by goal. Group variations under a goal-named class:
`LocateRegistrationForm.viaHomePage` / `.viaDirectNavigation`.

### Repeating `attemptsTo()` once per line

**Smell.**

```typescript
await actor.attemptsTo(Navigate.to('/'))
await actor.attemptsTo(Click.on(loginButton))
await actor.attemptsTo(Enter.theValue(email).into(emailField))
```

**Why it hurts.** Repetitive, and it distracts from the flow of the actions.

**Fix.** Pass the sequence to a single call.

### Action classes accumulating a method per combination

**Smell.** An Action class grows `searchFlights`, `selectFlight`, `bookFlight`,
`searchAndBookFlight`, `searchSelectAndBookFlight`.

**Why it hurts.** Composition should be free. Needing a new method for every
sequence produces enormous classes.

**Fix.** Tasks compose from other tasks by construction. No new method required.

### Filling out forms through the UI purely for test data setup

**Smell.** Every scenario's `Given` walks a multi-page registration form.

**Why it hurts.** Wasteful. UIs are slow by design — multi-page forms, artificial
payment delays, engagement animations. Exercise the sign-up UI once; do not pay
for it in every scenario that merely needs an account.

**Fix.** The `Given`-passive / `When`-active split, with an API-backed
implementation for the passive voice. If no suitable API exists, build a
test-specific one for setup and state inspection.

## Questions and assertions

### Writing a Question and never asking it

**Smell.**

```typescript
Text.of(Toaster.message())        // constructed, then nothing
```

**Why it hurts.** A Question is like an online poll: if nobody answers it, you get
no information. The test passes vacuously while verifying nothing.

**Fix.** Hand it to `Ensure.that(...)` or call `.answeredBy(actor)`.

### Asserting on raw markup instead of domain concepts

**Smell.** `Ensure.that(CssClasses.of(toaster), includes('toast-error'))`

**Why it hurts.** The assertion reads as markup, not business meaning, and breaks
when the widget library restyles.

**Fix.** Transform in a Lean Page Object so the question returns `'error'`, then
assert on that.

### Asserting inside a Page Object

**Smell.** A Page Object method that throws or returns a boolean judgment.

**Why it hurts.** Mixes locating with verifying, and hides failures from the
reporting layer.

**Fix.** Page Objects report state. Assertions belong in tasks, via questions.

## Actors and data

### Assuming a single actor

**Smell.** A global `actor` or a suite where no scenario names who is acting.

**Why it hurts.** Real business workflows involve several actors — a loan
application needs a client to apply and an employee to approve; chat systems and
games are the same. Boundaries between their activities blur, and scenarios stop
communicating who did what.

**Fix.** Name actors in scenarios as data. Use a Cast, resolve by name, and use
the actor-in-the-spotlight where a step names nobody.

### Requiring all persona data inline in feature files

**Smell.** An eight-row data table on every sign-up step.

**Why it hurts.** Clutters the feature file, distracts the reader from the detail
that actually matters, and duplicates data across scenarios.

**Fix.** Persona defaults via `TakeNotes` and a `Notepad`; override only what the
scenario is actually about, using `Question.fromObject`.

### Inline step parameters where a data table would do

**Smell.** `Given Mike has signed up using email address "smiths@example.org"`

**Why it hurts.** Forces a new step definition for every field you might want to
override, and cannot express multiple overrides at once.

**Fix.** A data table takes any subset of fields with one step definition.

## Page Objects

### Page Object hierarchies mirroring the app's page structure

**Smell.** A class per page, inheriting from a `BasePage`, mirroring the site map.

**Why it hurts.** Complexity without benefit. Classes try to do too much, and
unrelated fields end up grouped merely because they share a screen.

**Fix.** Model components, not pages. Keep them lean.

### Consumer teams reverse-engineering shared widget selectors

**Smell.** Three teams independently maintaining selectors for the same design
system component.

**Why it hurts.** Duplicated effort, plus the risk of the component team silently
breaking everyone's tests with an HTML change.

**Fix.** The component team publishes Screenplay test code with the widget, under
a separate module entry point.

## Lifecycle

### Closing the browser at the end of the test body

**Smell.** `await browser.close()` as the last line of a test.

**Why it hurts.** It does not run when the test fails, leaking browser processes
exactly when you have the most failures.

**Fix.** `AfterAll` / `After` hooks.
