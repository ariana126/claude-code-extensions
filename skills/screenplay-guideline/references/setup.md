# Serenity/JS Project Setup

Read this when wiring up a new Screenplay suite, configuring actors, or swapping
the underlying integration tool.

## Contents

- [Module layout](#module-layout)
- [The single tool-specific line](#the-single-tool-specific-line)
- [Generic Cast](#generic-cast)
- [Custom Cast with personas](#custom-cast-with-personas)
- [Persona factories](#persona-factories)
- [Cucumber wiring](#cucumber-wiring)
- [Waiting and synchronization](#waiting-and-synchronization)

## Module layout

| Module | Provides |
|--------|----------|
| `@serenity-js/core` | `Actor`, `Cast`, `Task`, `Question`, `Wait`, `Notepad`, `TakeNotes` |
| `@serenity-js/web` | `Navigate`, `Click`, `Enter`, `Select`, `PageElement`, `Text`, `By` — tool-agnostic |
| `@serenity-js/rest` | `Send`, `PostRequest`, `GetRequest`, `LastResponse`, `CallAnApi` |
| `@serenity-js/assertions` | `Ensure`, `equals`, `includes`, `isPresent`, `not`, `matches` |
| `@serenity-js/playwright` | `BrowseTheWebWithPlaywright` — one of several integration adaptors |
| `@serenity-js/webdriverio` | `BrowseTheWebWithWebdriverIO` |

`@serenity-js/web` does not depend on or interact with any integration tool
directly. It relies on an adaptor module to supply implementations of `Page` and
`PageElement`. You never instantiate `PlaywrightPageElement` yourself — you use
service access APIs like `Page.current()` and `PageElement.located(By.css(...))`.

## The single tool-specific line

The ability is the *only* place the integration tool appears:

```typescript
import { actorCalled, configure, Cast } from '@serenity-js/core'
import { BrowseTheWebWithPlaywright } from '@serenity-js/playwright'
import * as playwright from 'playwright'

const browser = await playwright.chromium.launch()

configure({
  actors: Cast.whereEveryoneCan(
    BrowseTheWebWithPlaywright.using(browser),      // ← the ONLY tool-specific part
  )
})

await actorCalled('William').attemptsTo(
  Click.on(PageElement.located(By.css('.selector'))),   // fully tool-agnostic
)
```

Swapping to WebdriverIO changes that import and that line. Nothing else.

This matters for three reasons:

1. **Cross-tool incompatibility.** Selenium, WebdriverIO, Puppeteer, Playwright,
   and Cypress each use different programming models and APIs, so test code
   written for one is normally unusable with another.
2. **Different tools suit different suites.** Playwright is excellent for
   component and smoke tests; WebdriverIO and Selenium have native WebDriver
   protocol support for cross-browser and remote-grid runs. With the abstraction
   in place you can use both against the same test code.
3. **Tool lock-in.** Angular Protractor's last commit was in 2020 and it reached
   end of life with Angular v16. Teams with hundreds of Protractor-coupled tests
   had no cheap exit.

## Generic Cast

When every actor is identical:

```typescript
import { BeforeAll, AfterAll } from '@cucumber/cucumber'
import { configure, Cast } from '@serenity-js/core'
import { BrowseTheWebWithPlaywright } from '@serenity-js/playwright'
import * as playwright from 'playwright'

let browser: playwright.Browser

BeforeAll(async () => {                      // configure exactly once, before any scenario
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

Close the browser in an `AfterAll` hook, not at the end of a test body, so it
happens even when a test fails.

## Custom Cast with personas

When actors are distinct people carrying their own data:

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
    )
  }
}

BeforeAll(() => {
  configure({
    actors: new Actors(browser, { baseURL: 'http://localhost:3000/' })
  })
})
```

Granting `CallAnApi` alongside `BrowseTheWebWithPlaywright` is what makes blended
testing possible — the same actor reaches the system through either door.

## Persona factories

Generate persona data from the actor's name rather than reading fixtures from
JSON, CSV, or a database. This keeps scenarios independent and avoids shared
mutable test data:

```typescript
export interface TravelerNotes {
    travelerDetails: TravelerDetails
}

export abstract class TravelerDetails {
  title: string
  firstName: string
  lastName: string
  email: string
  password: string
  address: string
  country: string
  seatPreference: 'window' | 'aisle'

  static of(actorName: string): TravelerDetails {
    return {
      title: 'Mx',
      firstName: actorName,
      lastName: 'Traveler',
      email: `${ actorName }.Traveler@example.org`,
      password: 'P@ssw0rd',
      address: '35 Victoria Street, Alexandria',
      country: 'Australia',
      seatPreference: 'window',
    }
  }
}
```

Read a note inside a task with `notes<TravelerNotes>().get('travelerDetails')`.
Because that returns a `QuestionAdapter`, you can reference its fields as if the
object were static — the adapter wraps nested fields recursively:

```typescript
export const FillOutRegistrationForm =
  (travelerDetails: QuestionAdapter<TravelerDetails> | TravelerDetails) =>
    Task.where(`#actor fills out the registration form`,
      SpecifyEmailAddress(travelerDetails.email),
      SpecifyPassword(travelerDetails.password),
      SpecifyFirstName(travelerDetails.firstName),
      SpecifyLastName(travelerDetails.lastName),
      ToggleTermsAndConditions.on(),
    )
```

## Cucumber wiring

Define parameter types so an actor's name in a scenario becomes an `Actor`:

```typescript
import { actorCalled, actorInTheSpotlight } from '@serenity-js/core'
import { defineParameterType } from '@cucumber/cucumber'

defineParameterType({
    name: 'actor',
    regexp: /[A-Z][a-z]+/,
    transformer(name: string) {
        return actorCalled(name)
    },
})

defineParameterType({
    name: 'pronoun',
    regexp: /he|she|they|his|her|their/,
    transformer() {
        return actorInTheSpotlight()      // the last actor referenced
    },
})
```

Which lets step definitions read naturally:

```typescript
Given('{actor} has logged in', async (actor: Actor) =>
    actor.attemptsTo(LogIn.viaApi()))

When('{pronoun} views their account details', async (actor: Actor) =>
    actor.attemptsTo(Navigate.toMyAccount()))
```

The Cast is needed because an actor must persist across step definitions —
possibly across several files — within a single scenario.

## Waiting and synchronization

`Wait` lives in `@serenity-js/core`, not the web module, so it is not a
browser-only concept:

```typescript
// Wait for a UI condition
Wait.until(Toaster.message(), isPresent())

// Poll a REST API until it meets an expectation — useful for async batch systems
Wait.until(LastResponse.status(), equals(200))

// Fixed delay — a last resort, since it slows every run by the full duration
Wait.for(Duration.ofSeconds(2))
```

Prefer `Wait.until` with an expectation over `Wait.for` with a duration. The same
expectations work in `Ensure.that` and the Page Element Query Language.
