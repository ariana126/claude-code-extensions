# Chapter 7: From Examples to Executable Specifications

## Core Idea
The complete Gherkin reference plus — more importantly — the craft of writing scenarios that survive: **declarative not imperative, one business rule per scenario, named actors, essential detail only, and each scenario independent.**

## Frameworks Introduced

- **The Five Marks of Good Gherkin** (§7.6) — the chapter's core contribution:
  1. **Declarative, not imperative** — describe *what* the user is trying to achieve, not *how* they click. Imperative Gherkin couples the spec to the screens; change a field and the scenario breaks even though the business logic didn't.
  2. **Does one thing well** — one business rule per scenario. Complex rule or oversized scenario? Split it.
  3. **Has meaningful actors** — named personas, third person, not "I" and "the user."
  4. **Focuses on the essential, hides the incidental** — strip steps, columns, and data that don't influence the outcome.
  5. **Is independent** — every scenario sets up its own state; no scenario may depend on a previous one having run.

- **The Declarative/Imperative Test** — borrowed from grammar and functional programming:
  | | Imperative | Declarative |
  |---|---|---|
  | Parenting | "Take your clothes off the floor, put them in the basket, then clean up those toys" | "Your room needs to be tidy by dinner time" |
  | Restaurant | "I'd like to walk to the second table from the right by the window and sit down, and for you to bring two menus" | "A table for two by the window, please" |
  | Code (Kotlin) | loop, accumulate `totalAges`, divide by `ages.size` | `ages.average()` |
  | Gherkin | `When I Enter "Paris" into the city field` / `And I set price range to "Any"` / … | `When I look for a hotel within 10 km of Paris for 2 nights on 04-04-2019` |
  - **Management analogy**: imperative Gherkin is a manager micromanaging — extra work for her, no freedom for the team. Declarative Gherkin states the goal and lets the step implementation choose the route (web page, web service, or domain model directly).
  - **Reported payoff**: one team saw an **80% reduction** in the time to write and automate new scenarios after refactoring old Cucumber test scripts to a declarative approach.

- **The Incidental-Detail Filter** — rules of thumb for what to cut:
  - **Question any column whose values are identical**, or that has no clear influence on the outcome.
  - Assume what can be safely assumed (login, navigation) and implement it behind the scenes.
  - But **don't over-strip**: "we need to remove enough of it so that the scenario is focused… but not too much, so that it doesn't become overly generic and vague." The flight number stayed in because Flying High staff are intimately familiar with them.
  - **The fish seller story** (in the book, from the *New Haven Register*, 1890): a sign reading "Fresh fish sold here" is whittled by well-meaning friends to "Fish sold here" → "Fish here" → "Fish" → nothing at all. The cautionary tale against over-elimination.

- **Personas in scenarios** — from UX. A persona is a rich description including goals, abilities, and background, not a generic role.
  - **Soap opera personas** (Andy Palmer): if you have no UX budget, don't define personas up front — introduce them on the go, like TV characters. Start with "Carrie, the compliance officer" or "Barry, the small business owner" and let detail accrete as stories develop ("Barry has a business account and is domiciled in Bermuda, which subjects him to extra attention from compliance").

- **The Test-Script Smell Detector** — how to spot a manual test script masquerading as a scenario:
  | Tell | Example |
  |---|---|
  | Test-script style names | "End-to-end Hotel Booking Test", "TC1–Hotel Booking–positive test case" |
  | Instruction verbs | "Check that I have enough points", "Verify the message that appears" |
  | Long lists of low-level UI interactions | click, select, enter, hit |
  | Given/When/Then in no particular order | `Given`…`Then`…`And`…`Then`…`When` |
  | Describes what a *tester* should do, not the expected outcome | "verify that the price is correct" |
  - **The one-word heuristic**: "A scenario with words like **'verify'** or **'check'** is often a test script in disguise."
  - **Why manual scripts don't translate**: manual testing crams as much as possible into one pass because setup is expensive. Automated tests are cheap to run but must give *precise* feedback when they fail.

- **Feature-file organization strategies** — three options, one recommended:
  | Strategy | Verdict |
  |---|---|
  | Flat directory | OK for a handful of files; confusing beyond that |
  | One file per User Story | **Bad.** Stories are transitory planning artifacts; a new story may change or replace an earlier story's scenarios, leaving no clear home |
  | One directory per release/iteration | **Bad.** Feature development often spans iterations → either no clear home or duplicated files |
  | **By functionality and capability** | **Recommended.** Mirrors how the app actually works |
  - **The underlying principle**: story- and release-based layouts "confuse **project delivery** with **product documentation**." *"You wouldn't organize a user manual or a requirement specification document with one chapter per release, so you probably shouldn't organize your feature files this way either."*

## Key Concepts

- **Feature file** — a `.feature` plain-text file, under version control, holding all scenarios for one feature. Java convention: `src/test/resources/features/`.
- **Feature description** — any text between the `Feature:` title and the first scenario; appears in living documentation. Can be pulled from JIRA by Serenity BDD (see ch 16).
- **Scenario description** — text between the scenario title and the first `Given`; also appears in reports. Ideal for stating the business rule or calculation.
- **Scenario Outline** (a.k.a. `Scenario Template`) — a parameterized scenario with `<placeholder>` variables, run once per row of an `Examples:` (or `Scenarios:`) table.
- **Background** — steps run before every scenario in the feature; removes duplication of common setup.
- **`Rule` / `Example`** (Cucumber 6+) — `Rule` names a single business rule; `Example` (a synonym of `Scenario`) groups its examples and counterexamples beneath it.
- **Pending scenario** — a scenario title with no steps; appears in living documentation as recorded-but-not-implemented.
- **Tag** — `@name` on a feature, scenario, or example table. Used to filter execution, filter reports, and trigger hooks.
- **Hook** — a method run before or after scenarios carrying a specific tag; used for environment setup/teardown.
- **Brittle test** — one prone to failing randomly for no apparent reason; long UI scenarios are the main source.

## Reference Tables

**Gherkin keywords:**
| Keyword | Purpose |
|---|---|
| `Feature:` | Title — should describe **an activity a user wants to perform** (Dan North) |
| `Scenario:` / `Example:` | One concrete example; title summarizes what's special about it |
| `Scenario Outline:` / `Scenario Template:` | Parameterized scenario with `<placeholders>` |
| `Examples:` / `Scenarios:` | Table of data rows driving a Scenario Outline |
| `Background:` | Steps run before every scenario in the file |
| `Rule:` | (Cucumber 6+) A single business rule grouping examples |
| `Given` | Preconditions / inputs — sets the stage |
| `When` | The action or event under test |
| `Then` | Expected outcome, compared against observed |
| `And` / `But` | Continuation of the previous non-And/But step; purely for readability |
| `#` | Comment — **does not appear in living documentation** |
| `#language: fr` | Write the whole file in another language (`Fonctionnalité`, `Scénario`, `Etant donné que`, `Quand`, `Alors`) |

**Serenity BDD tag conventions:**
| Form | Example | Use |
|---|---|---|
| Plain tag | `@frequentflyer`, `@important`, `@ui` | Grouping, filtering execution and reports |
| Typed tag `@<type>:<name>` | `@component:authentication` | Groups results by tag *type* in reports |
| Issue link | `@issue:FF-123` | Reporting tools create a link back to JIRA etc. |

**Table shapes inside a step:**
| Shape | Use |
|---|---|
| Header row + data rows | A collection of records |
| Field names in column 1, values in column 2 | A single record |
| Single column, no header | A simple list of values |

## Code Examples

**A feature file with description and scenarios:**
```gherkin
Feature: Earning Frequent Flyer points from flights
  In order to improve customer loyalty
  As an airline sales manager
  I want travelers to earn frequent flyer points when they fly with us

  Scenario: Flights within Europe earn 100 points
    Given Tara is a Frequent Flyer traveler
    When she completes a flight between Paris and Berlin
    Then she should earn 100 points

  Scenario: Flights outside Europe earn 1 point every 10 km
    Given the distance from London to New York is 5500 km
    And Tara is a Frequent Flyer traveler
    When she completes a flight between London and New York
    Then she should earn 550 points
```

**`Background` removing duplicated setup:**
```gherkin
Feature: Logging on to the 'My Flying High' website
  Frequent Flyer members can register on the 'My Flying High' website
  using their Frequent Flyer number and a password that they provide

  Background: Martin is registered on the site
    Given Martin is a Frequent Flyer member
    And Martin has registered online with a password of 'secret'

  Scenario: Logging on successfully
    When Martin logs on with password 'secret'
    Then he should be given access to the site

  Scenario: Logging on with an incorrect password
    When Martin logs on with password 'wrong'
    Then he should be informed that his password was incorrect

  Scenario: Logging on with an expired account
    Given the account has expired
    When Martin logs on with password 'secret'
    Then he should be informed that his account has expired
    And he should be invited to renew his account
```

**`Rule` + `Example` (Cucumber 6):**
```gherkin
Feature: Transferring points between members

  Background:
    Given the following Frequent Flyer members
      | Name  | Surname | Family Code |
      | Sarah | Sparrow | FAM-101     |
      | Steve | Sparrow | FAM-101     |
      | Fred  | Falcon  | FAM-202     |

  Rule: Frequent Flyer members in the same family can transfer points
    Example: Transfer points between existing members
      Given the following Frequent Flyer account balances:
        | owner | points | status-points |
        | Sarah | 100000 | 800           |
        | Steve | 50000  | 50            |
      When Sarah transfers 40000 points to Steve
      Then the accounts should be as follows:
        | owner | points | status-points |
        | Sarah | 60000  | 800           |
        | Steve | 90000  | 50            |

    Example: Transfer points between non-family members
      When Sarah tries to transfer 10000 points to Fred
      Then the transfer should not be allowed

  Rule: Members cannot transfer more points than they have
    Example: Steve tries to transfer more points than he has
      When Steve tries to transfer 100000 points to Sarah
      Then the transfer should not be allowed
```

**Pending scenarios as placeholders:**
```gherkin
Feature: Booking flights with Frequent Flyer points
  As a Frequent Flyer program manager
  I want members to be able to book flights with their points
  So that they will want to earn more points

  Scenario: Booking an individual flight using points
  Scenario: Booking an individual flight using money and points
  Scenario: Booking a flight for more than one passenger
```

**Recommended directory structure — by capability:**
```
+ features
    + frequent_flyers
        + account
            + register.feature
            + change_password.feature
            + view_flight_history.feature
        + book_a_flight
            + book_with_points.feature
            + book_with_points_and_cash.feature
        + earn_points
            + earn_points_from_flights.feature
            + earn_points_from_hotel_stays.feature
            + earn_points_from_car_rentals.feature
```

## Worked Example

**The bad scenario, and its complete rehabilitation.**

The book's canonical anti-example (listing 7.4):

```gherkin
Scenario: End-to-end hotel booking test
  Given I login to the Travel Booking App
  Then I am on the Home Page
  And I click the New Trip tab
  And I click on the Hotels dropdown menu item
  Then I am on the Hotel Search page
  When I Enter "Paris" into the city field
  And I set price range to "Any"
  And I set check-in date to "04-04-2019"
  And I enter number of nights to "2"
  And I set distance to "10"
  When I hit "search" button
  Then the hotels listed are:
    | Hotel Name | Distance | Availability | Price | Pool | Gym |
    | Ritz       | 3.2      | Yes          | 400   | Y    | Y   |
    | Savoy      | 6.9      | Yes          | 500   | N    | Y   |
  When I select "Ritz" from the list
  And I select "Pay with points"
  And check that I have enough points
  And I click "Pay"
  Then verify the message that appears
  And verify that the price is correct
  And I click on logout
```

Everything wrong with it, per the book: long and dense; a monotonous sequence of low-level UI interactions; breaks when buttons or fields change even though business logic is intact; no clear goal or outcome; exercises many business rules at once; **if it failed, you couldn't tell what broke**. And it raises more questions than it answers — what other payment options exist? How many points are needed? What message should appear, and why does it matter?

*Step 1 — collapse the imperative search steps.* Six steps become one:
```gherkin
When I look for a hotel with:
  | City  | Check-in Date | Nights | Distance from center |
  | Paris | 04-04-2019    | 2      | 10 km                |
```
or simply:
```gherkin
When I look for a hotel within 10 km of Paris for 2 nights on 04-04-2019
```

*Step 2 — split concerns.* Even that single step conflates searching by distance with checking availability — two separate concerns. Start simpler: `When I look for a hotel within 10 km of Paris`. **"Features tend to be easier to understand if the scenarios start out with simple cases and build up progressively to more complex ones."**

*Step 3 — assume the incidental, name the actor, supply the data.* Login and navigation collapse into context. The `Then` table loses Availability, Price, Pool, and Gym — none influence *distance-based search*. And critically, the hotels must come from somewhere: real-world Gherkin "often falls into the trap of relying on production or production-like data."

The rehabilitated scenario:
```gherkin
Scenario: Search for available hotels by distance
  Given Bindi needs to make a business trip to Paris
  And the following hotels have available rooms:
    | Hotel Name | Location | Distance from center |
    | Ritz       | Paris    | 3.2                  |
    | Savoy      | Paris    | 6.9                  |
    | Hilton     | Paris    | 12.5                 |
  When Bindi searches for a hotel within 10 km of Paris
  Then she should be presented with the following hotels:
    | Hotel Name | Location | Distance from center |
    | Ritz       | Paris    | 3.2                  |
    | Savoy      | Paris    | 6.9                  |
```
Note the Hilton at 12.5 km is the **counterexample built into the data** — the scenario proves exclusion as well as inclusion.

*Step 4 — the payment logic gets its own scenario, with real numbers:*
```gherkin
Scenario: Travelers can pay for a hotel booking using points
Frequent Flyers can book rooms using points at a rate of $1 per point
  Given the following hotels have available rooms:
    | Hotel Name | Location | Nightly cost |
    | Ritz       | New York | 500          |
  And Bindi has a balance of 1200 points
  When she books 2 nights at the Ritz
  Then she should be charged a remaining balance of $0
  And she should have 200 remaining points
```
And its variations, which the end-to-end script could never have expressed:
```gherkin
Scenario Outline: Travelers can pay using cash and points
Points are consumed before cash
  Given the following hotels have available rooms:
    | Hotel Name | Location | Nightly cost |
    | Ritz       | New York | 500          |
  And Bindi has a balance of <Available Points> points
  When she books 2 nights at the Ritz
  Then she should be charged a remaining balance of $<Cash cost>
  And she should have <Remaining Points> points remaining

  Examples:
    | Available Points | Cash cost | Remaining Points |
    | 1200             | 0         | 200              |
    | 800              | 200       | 0                |
    | 0                | 1000      | 0                |
```

**Personas transforming a vague scenario.**

Generic:
```gherkin
Scenario: Account home page
  Given I have a savings account
  When I open my accounts home page
  Then I should see details about my account
```
*"This feels a tad vague. We don't describe what specific account details would be relevant."*

Now write it as **Sam**, the stay-at-home dad who watches his expenses like a hawk and knows the current balance doesn't reflect what's actually available:
```gherkin
Scenario: Account owners should be able to see their balance at a glance
  Given Sam has the following accounts:
    | Type    | Number | Current Balance | Pending Transaction |
    | Current | 123456 | $530.00         | $-200.00            |
    | Savings | 234567 | $2500           |                     |
  When he views his account summary
  Then he should see the balance and pending transactions for each account:
    | Type    | Current Balance | Pending Transactions | Available |
    | Current | $530.00         | $-200.00             | $330.00   |
    | Savings | $2500           |                      | $2500.00  |
```
The persona supplied the requirement: *pending transactions and an available balance*, which "details about my account" never would have.

Same effect on stories. Generic: *"As a user / I want to see my account details / So that I can know how much money I have."* With **Elsa, the young executive on the go**: *"Wants to view her account balance at a glance / So that she can quickly know whether she needs to transfer money from her savings account."* That story tells you Elsa needs her primary balances in a prominent font on the home page — not three clicks away in the top-left corner.

**Dependent vs. independent scenario chains.**

The fragile pattern (listing 7.5) — each scenario only works if the previous one passed:
```gherkin
Scenario: Step 1 - User navigates to the booking page
  Given I log in to the Corporate Booking App
  When I click on the "Hotels" button
  Then I should see the Hotel search page

Scenario: Step 2 - User looks for a hotel by location
  Given I Enter "Paris" into the city field
  ...
```
Easier to read than one giant scenario, but "just as fragile. If one scenario fails, the following ones will be compromised."

The fix (listing 7.6) — **semantically sequential, mechanically independent.** Each sets up its own data:
```gherkin
Scenario: A traveler can look for a hotel by location and price
  Given Bindi needs to travel to New York for business
  And the following hotels have available rooms:
    | Hotel Name | Location | Nightly cost | In policy |
    | Ritz       | Paris    | 400          | Yes       |
    | Hilton     | New York | 600          | Yes       |
    | Conrad     | New York | 800          | No        |
  When she looks for hotels in New York
  Then she should be shown the following hotels:
    | Hotel Name | Location | Nightly cost | In policy |
    | Hilton     | New York | 600          | Yes       |
    | Conrad     | New York | 800          | No        |

Scenario: A traveler books a hotel using their corporate credit card
  Given Bindi is looking for hotels in New York
  When she books a room in the New York Hilton with her corporate card
  Then the booking should be placed on hold
  And the travel plan should be submitted to Logistics for approval

Scenario: Each trip needs to be approved by a logistics officer
  Given Bindi has booked the following trip:
    | Destination | Date       | Nights | Hotel  | Flight |
    | New York    | 15-05-2020 | 3      | Hilton | FH-101 |
  And Logan is a logistics officer
  When Logan reviews his list of tasks
  Then Logan should see the following trips in his inbox:
    | Destination | Date            | Bookings      | Status           |
    | New York    | 15-18 May, 2020 | Flight, Hotel | Pending Approved |
```
You read them in sequence for the full picture, but any one can fail without compromising the others. **The subtle bonus**: each becomes a conversation starter — "in the third scenario, Bindi gets her trip approved. But what if the trip was *not* approved?" That question opens an entire new feature file.

**High-level journey scenarios still have a place** — as long as they stay high level:
```gherkin
Scenario: Booking a business trip
  Given Bindi needs to make a business trip to Paris
  When she books a flight and a hotel on the corporate booking system
  Then the trip should be placed in her calendar
  And her corporate credit card should be charged
```

**Wordy scenarios → Scenario Outline.** Five near-identical scenarios about flight eligibility (listing 7.1) collapse to one (listing 7.2):
```gherkin
Scenario Outline: Eligible flights in the past 90 days can be claimed.
  Given Todd has just joined the Frequent Flyer program
  And Todd asks for the following flight to be credited to his account:
    | Flight Number | Flight Date | Status   |
    | <Flight>      | <Date>      | <Status> |
  Then the flight should be considered <Eligibility>

  Examples:
    | Flight | Date      | Status    | Eligibility | Reason             |
    | FH-99  | -60 days  | COMPLETED | Eligible    |                    |
    | FH-87  | -100 days | COMPLETED | Ineligible  | Too old            |
    | OH-101 | -60 days  | COMPLETED | Ineligible  | Different airline  |
    | FH-99  | -60 days  | CANCELLED | Ineligible  | Must be completed  |
    | FH-99  | +5 days   | CONFIRMED | Ineligible  | Hasn't taken place |
```
Why it's better than five scenarios: less duplication to maintain; **readers skim past near-identical scenarios and miss details**; tabular form makes patterns and boundary conditions visible at a glance; and it produces better living documentation.

**Trimming incidental detail from an example table.** Before — eight columns, unclear why rows differ:
```
| Booking | Number | Date       | Airline     | From   | To     | Credit |
| DDSF245 | FH-101 | 20-12-2018 | Flying High | London | Paris  | Yes    |
| SFGG345 | FH-201 | 21-10-2018 | Flying High | London | Oslo   | Yes    |
...
```
After — booking reference dropped (no effect on the outcome), departure/destination dropped (they matter for *how many* points, not *whether*), flight number kept (Flying High staff know them), and a `Notes` column added to name the rule each row exercises:
```gherkin
Scenario Outline: Earning Frequent Flyer points for past flights
Users can request credits for Frequent Flyer flights completed in the past three months
  Given Terry joined the Frequent Flyer program on 20-01-2019
  When Terry requests credit for flight <Number> on <Date> with <Airline>
  Then the flight should be credited: <Credited>

  Examples:
    | Number | Date       | Airline     | Credited | Notes                |
    | FH-101 | 01-02-2019 | Flying High | Yes      |                      |
    | FH-999 | 20-10-2018 | Flying High | No       | Flight too old       |
    | OA-102 | 01-02-2019 | Other Air   | No       | Not with Flying High |
```

**Which `Given`s to include.** For "change a flight to another date":
```gherkin
Given Tara is a Frequent Flyer traveler                                # KEEP — non-members are charged a fee, so this drives the outcome
And Tara has logged on to the Frequent Flyer app using tara@email.com  # DROP — implementation detail; if she's a member, logging on is implied
And Tara has booked the following flight:                              # KEEP — the subject of the scenario
  | Departure | Destination | Date       | Class   |
  | London    | New York    | 13-01-2020 | Economy |
```
The rule cuts both ways: "Too many `Given`s can make it harder for a reader to know precisely what's required… But preconditions that *should* be present in the `Given` steps, but aren't, are effectively **assumptions that can lead to misunderstandings later on**."

## Mental Models

- **Gherkin is simultaneously three things** (figure 7.10): a requirements specification, an executable test, and living documentation. Optimize for all three — that's why it's hard.
- **Scenarios are code.** "Scenarios are like application code: you should write with the intention of making readability and maintenance easy… they'll likely long outlast the development project."
- **"Less is more"** — the book's stated rule of thumb for scenario writing.
- **Good Gherkin is like Hemingway; bad Gherkin is a trashy beach novel or a badly translated washing machine manual.** "Very often, the easier a Gherkin scenario is to understand, the more effort the authors have put in to make it so."
- **Title the feature after an activity, not a domain** (Dan North). "Earning Frequent Flyer points from flights" is bounded; "Frequent Flyer point management" sprawls into viewing status, partner purchases, and more.
- **Put Given and When in the scenario title, never the expected outcome** (Matt Wynne). Context and events are stable; outcomes change as the business evolves.
- **Split composite steps for reuse.** `Then she should earn 100 points and 50 bonus points` → two steps. Slightly longer, but each is independently diagnosable and reusable across scenarios.
- **Comments are invisible to stakeholders.** They don't appear in living documentation, so beyond temporarily commenting out a step, "comments should be used with moderation."

## Anti-patterns

- **Imperative, click-by-click scenarios**: fragile, unreadable, coupled to the UI, impossible to give business feedback on.
- **One scenario testing many rules**: when it fails you can't tell what broke, and it raises more questions than it answers.
- **"Verify" / "check" steps**: instructions to a human tester, far too vague for automation, and they describe activity rather than outcome.
- **Converting manual test scripts to Gherkin**: the two testing modes have opposite economics; the result inherits all the wrong optimizations.
- **Generic actors ("I", "the user", "the customer")**: tells you nothing about what would actually be valuable.
- **Relying on production or production-like data**: good scenarios "show a logical progression from the first `Given` to the final `When`", including setting up the data they need.
- **Chained scenarios where step 2 depends on step 1**: one failure cascades and obscures the health of the application.
- **Duplicated setup steps across scenarios**: use `Background`.
- **Many near-identical scenarios for one rule**: use `Scenario Outline`; readers skim and miss details otherwise.
- **A feature file per User Story, or a directory per release**: confuses project delivery with product documentation.
- **Over-stripping detail** (the fish seller): strip until focused, not until vague.
- **Including navigation and login steps** when the scenario is about something else entirely.

## Key Takeaways
1. Write what the user is trying to achieve, not which buttons they press — the step implementation decides whether it drives the UI, an API, or the domain model.
2. One business rule per scenario; order scenarios simple-to-complex within a feature.
3. Use named personas in third person; invent them on the fly (soap opera style) if you have no UX research.
4. Include a `Given` only if it influences the outcome — but never omit one that does.
5. Drop any table column whose values are identical or that doesn't change the result; add a `Notes`/`Reason` column to name the rule each row exercises.
6. Make every scenario independently runnable, setting up its own data; sequence them semantically, never mechanically.
7. Collapse repeated scenarios with `Scenario Outline` + `Examples:`, and repeated setup with `Background`.
8. Organize feature files by business capability, never by story or release.
9. Grep your suite for "verify" and "check" — those scenarios are test scripts wearing a costume.
10. Keep a handful of high-level end-to-end journey scenarios for the big picture, but let focused rule-scenarios do the real work.

## Connects To
- **Ch 2**: the first Gherkin primer; `Scenario Outline` and in-step tables introduced.
- **Ch 5**: why stories are transitory and features are durable — the basis of the file-organization rule.
- **Ch 6**: the Example Maps, Feature Maps, and tables that feed into these scenarios.
- **Ch 8**: automating these scenarios in Java with Cucumber, including tag filters and hooks.
- **Ch 9**: writing solid automated acceptance tests — the layered design that keeps declarative scenarios maintainable.
- **Ch 16**: Serenity BDD living documentation, tag-based reporting, and JIRA integration.
- **The Cucumber Book (Wynne & Hellesøy)**, **"What's in a story" (Dan North)**, **Soap Opera Personas (Andy Palmer)**: external sources referenced.
