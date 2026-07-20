# Chapter 9: Writing Solid Automated Acceptance Tests

## Core Idea
Most test-automation initiatives fail because maintenance cost outgrows feedback value. The cure is **layers of abstraction** — separating stable business rules from volatile UI details across three or four layers — plus **personas** to keep test data out of scenarios.

## Frameworks Introduced

- **The Four Rules of an Industrial-Strength Acceptance Test:**
  1. **It should communicate clearly.** Tests are *first and foremost communication tools*. Wording and semantics matter — they must explain to stakeholders, BAs, testers, and teammates what business tasks the application supports and how. Ideally they outlive development and help the BAU team.
  2. **It should provide meaningful feedback.** On failure, a developer should be able to see what the underlying requirement is trying to achieve and how it interacts with the application.
  3. **It should be reliable.** A test passes **if and only if** the application satisfies the business requirement. If it does break for technical reasons, the problem should be easy to isolate and simple to fix.
  4. **It should be easy to maintain.** A test that breaks on every update becomes a liability; developers stop updating it, leave it broken, and the entire investment is lost.

- **The Broken-Windows Vicious Circle** (figure 9.1) — the failure mode these rules prevent:
  > Tests in a well-written suite should be either **passing or pending**. A failing test should be "a red flag… that demands immediate attention." But when tests fail too often due to sporadic technical problems → the team loses confidence in them as a feedback mechanism → they're less motivated to fix them → **there are always a few broken tests in the build** → the suite no longer reports project health at all.

- **The Three (really four) Layers of Abstraction** (figures 9.3–9.5) — the chapter's central framework. Each layer implements the layer above by *orchestrating* the layer below:
  | Layer | Describes | Written as | Changes when… |
  |---|---|---|---|
  | **Business Rules** | The requirement in high-level business terms — goals and constraints | Gherkin scenarios in feature files (or JUnit/TestNG/NUnit/Node test libraries) | **The business changes its mind** or its understanding evolves |
  | **Glue code** (step definitions) | How each scenario step translates into business tasks and actions | `@Given`/`@When`/`@Then` methods | Scenario wording or task decomposition changes |
  | **Business Flow** | The user's journey — the high-level tasks needed to reach the goal | Reusable task objects/methods (e.g. Screenplay `Performable`s) | **Application workflow** changes (a new required step, a new legal confirmation) |
  | **Technical / System Interactions** | How to actually touch the application — locators, REST endpoints, DB queries | Page objects, locator classes, Serenity/Selenium components | **Screen layout, field names, HTML structure** change |
  - The whole point: "High-level business rules tend to be relatively stable, and changes to them will be driven by the business rather than by technical constraints. Lower-level implementation details… tend to change more frequently. When changes do happen at the lower implementation levels, the affect on the automated acceptance criteria should be minimal."
  - **The Business Flow layer never touches the application directly.** It delegates down. "We don't talk about clicking on any buttons or links… We focus purely on what she does, and the how comes later."
  - **Sequencing benefit**: you can write the Business Rules and Business Flow layers *before the UI exists*. They're authored with testers and BAs and act as guidelines for development. Only when the UI stabilizes do you implement the technical components.

- **Personas and Known Entities as test data** — "a persona assembles a set of precise data under a well-known name."
  - When to use: any time a scenario would otherwise be cluttered with names, addresses, phone numbers, dates of birth, or default domain values.
  - How: name the actor in the scenario (`Given Jane is not a Frequent Flyer member`); the step definition looks up the full record; downstream steps fill forms from it without any of it appearing in the scenario.
  - Storage options: external files (JSON, properties, **HOCON**), or a test database initialized at the start of each test.
  - **Known entities** generalize the idea beyond people: "a banking application working on transferring bank statement files might define a few standard file types and then only specify the fields that have different values for a given scenario."

- **Big-picture scenarios + persona defaults** — how to write a high-level flow for a data-heavy process:
  - State only what's *distinctive* in the scenario (`Given Jane owns a new Toyota Prius`).
  - Let a persona object supply sensible defaults for everything else (age, address, driving record), overriding only the scenario-relevant fields.
  - "We aren't worried about the details, such as where Jane lives, or whether she has had any accidents in the past… we don't want them muddying the picture at this high level."

## Key Concepts

- **BAU (business as usual) team** — the team that maintains applications after deployment; often not the team that built them. A primary audience for acceptance tests as documentation.
- **HOCON** — Human-Optimized Config Object Notation, a superset of JSON from the Typesafe/Lightbend `config` library. "More flexible and readable than plain JSON."
- **Screenplay** — the actor-centric layering style (`actor.attemptsTo(Task1, Task2, …)`), covered fully in ch 12.
- **Locator** — a WebDriver object identifying an element on a page (e.g. `By.partialLinkText("Register Now")`), kept in its own class to localize change.

## Mental Models

- **Automated tests are production code.** "Writing good, automated acceptance tests requires the same software engineering skills and disciplines, and the same level of craftsmanship, as well-written production code."
- **The historical reason test code is neglected**: "for many years, test automation has been synonymous with test scripts. Teams have been reluctant to put too much effort into writing scripts when they could be writing production code." And traditional testing tools used scripting languages with poor support for refactoring, reusable components, and clean code — so the habits never formed.
- **The best acceptance tests are collaborative artifacts** — "the result of a collaborative effort between testers and developers."
- **Judge a layer by what makes it change.** If a field rename forces you to edit a scenario, your layers have leaked.
- **High-level tasks are stable by construction.** "A customer will always need to apply for automobile insurance, choose a particular product, and provide the appropriate details. What details they need to enter about themselves may change as the application evolves, but the fact that they need to provide some personal information will not."
- **Not everything has to go through the UI.** "Some or all steps can be performed more effectively via REST API calls, database queries, message queues, or other non-UI-based approaches." Checking a confirmation email → a mock web server or an email testing service (TestMail, MailSlurp, MailHog). Checking a points balance → a REST call.

## Worked Example

**One scenario, traced down through every layer.**

*Business Rules layer* — the scenario, which mentions no data and no UI:
```gherkin
Scenario: Registering online for a new Frequent Flyer account
  Given Jane is not a Frequent Flyer member       # rule applies only to new members
  When Jane registers for a new account           # the high-level action under test
  Then she should be sent a confirmation email    # expected outcome
  And she should receive 500 bonus points         # expected outcome
```

*Persona data* — the details Jane carries, in a HOCON file at `src/test/resources/testdata/travelers.conf`:
```hocon
Jane: {
  firstName: Jane
  lastName: Smith
  email: "jane@acme.com"
  street: 10 Partridge Street
  city: Dandenong
  state: Victoria
  postCode: 3175
  country: Australia
  telephone: "0123456789"
  dateOfBirth: 1981-08-29
}
Terry: {
  firstName: Terry
  lastName: Traveler
  email: "terry@dummy-email.com"
  street: 100 Main Street
  city: Dublin
  country: Ireland
}
```
Note Terry deliberately has *fewer* fields — personas can be partial.

*Glue code layer* — the first step resolves the name to the record; nothing more:
```java
Traveler travelerDetails;

@Given("{} is not a Frequent Flyer member")
public void notAFrequentFlyer(String name) {
    travelerDetails = TravelerPersonas.findByName(name);
}
```

*The persona loader*, using Typesafe Config:
```java
import com.typesafe.config.Config;
import com.typesafe.config.ConfigFactory;

public class TravelerPersonas {
    private static Config travelers = ConfigFactory.load("testdata/travelers");

    public static Traveler findByName(String name) {
        Config travelerDetails = travelers.getConfig(name);
        return new Traveler(
                travelerDetails.getString("firstName"),
                travelerDetails.getString("lastName"),
                travelerDetails.getString("email"),
                travelerDetails.getString("street"),
                travelerDetails.getString("city"),
                travelerDetails.getString("state"),
                travelerDetails.getString("postCode"),
                travelerDetails.getString("country"),
                travelerDetails.getString("telephone"),
                travelerDetails.getString("dateOfBirth")
        );
    }
}
```

*Business Flow layer* — the `When` step decomposes into three business tasks. Still no clicking, no field names:
```java
@When("{actor} registers for a new account")
public void registersForANewAccount(Actor theTraveler) {
    theTraveler.attemptsTo(
            Navigate.toTheFrequentFlyerRegistrationPage(),
            EnterRegistrationDetails.using(travelerDetails),
            Confirms.termsAndConditions()
    );
}
```
The book spells out what this buys you: "maybe you'll need to add a step where Jane needs to provide additional details… or perhaps a new law means she needs to confirm her email address before the registration process can be completed." Those changes edit *this* method only.

*Technical layer* — now, finally, the actual interactions:
```java
public static Performable toTheFrequentFlyerRegistrationPage() {
    return Task.where("{0} opens the Frequent Flyer registration page",
            Open.url("https://frequent-flyer.flying-high.com"),   // open the browser
            Click.on(MenuBar.REGISTER)                            // click Register in the main menu
    );
}
```
And the locator lives in its own class, so a redesign touches one line:
```java
public class MenuBar {
    public static final By REGISTER = By.partialLinkText("Register Now");
}
```

**The payoff, stated concretely:** "suppose the design of the registration page changes, involving changes to the HTML structure and field names. Such a change would modify neither the business rule nor the workflow for this requirement, and those levels wouldn't be affected. The only code you'd need to update is within the page object that encapsulates the registration page. **This update would work for any scenario that uses this page.**"

**Big-picture scenario for a data-heavy process — car insurance.**

The scenario states only what distinguishes this case:
```gherkin
Scenario: Jane applies for comprehensive insurance online
  Given Jane owns a new Toyota Prius
  When Jane applies for comprehensive car insurance
  Then she should be shown a New Hybrid Car quote
  And she should receive a copy of the quote via email
```

The `Given` builds a driver persona, overriding only the vehicle:
```java
@Given("{actor} owns a {newOrUsed} {word} {}")
public void ownsACar(Actor theCustomer, NewOrUsed newOrUsed, String make, String model) {
    driverDetails = DriverPersonas.withName(theCustomer.getName())
                                  .withVehicle(Vehicle.thatIs(newOrUsed)
                                                      .ofMake(make)
                                                      .ofModel(model));
}
```

The `When` names the four big steps of a genuinely complex multi-page application process:
```java
@When("{actor} applies for comprehensive car insurance")
public void appliesForComprehensiveCarInsurance(Actor theDriver) {
    theDriver.attemptsTo(
            ApplyForAutomobileInsurance.forASingleCar(),
            ProvideDetails.from(driverDetails).aboutTheirCar(),
            ProvideDetails.from(driverDetails).aboutThemselves(),
            Conforms.theApplicationDetails()
    );
}
```

**And now watch the reuse.** A motorbike insurance scenario swaps two tasks and keeps two:
```java
theDriver.attemptsTo(
        ApplyForAutomobileInsurance.forAMotorcycle(),      // different
        ProvideDetails.from(driverDetails).aboutTheirMotorcycle(),  // different
        ProvideDetails.from(driverDetails).aboutThemselves(),       // reused
        Conforms.theApplicationDetails()                            // reused
);
```
"It's only inside each of these tasks that we actually interact with the application, so we only need to maintain how these interactions happen in one place for each task."

## Anti-patterns

- **Letting failing tests accumulate**: complacency sets in and the suite stops being a health signal. Passing or pending — nothing else.
- **Flat test code with no layers**: "a small change in a single, commonly used web page will break a large swath of tests, and developers will need to fix each test individually… thankless, unproductive work that does little to encourage the team to automate more acceptance tests."
- **Treating test automation as scripting**: no refactoring, no reusable components, no readability discipline — the historical root of the maintenance problem.
- **Putting persona data inline in scenarios**: addresses and phone numbers drown the business rule.
- **Business Flow steps that click buttons**: that's a layer violation; delegate to the technical layer.
- **Inlining locators where they're used**: keep them in a dedicated class so one redesign is one edit.
- **Driving every verification through the UI**: use REST calls, DB queries, or email-testing services where they're more effective and more reliable.
- **Waiting for the UI before writing any test code**: Business Rules and Business Flow can and should come first, as guidelines for the development work.

## Key Takeaways
1. Judge every acceptance test against four rules: communicates clearly, gives meaningful feedback, is reliable, is maintainable. Failing any one eventually kills the suite.
2. A well-run suite has only passing and pending tests — treat a red test as demanding immediate attention, because tolerating one leads to tolerating many.
3. Layer your automation so each kind of change (business rule / workflow / screen layout) lands in exactly one layer.
4. Never let the Business Flow layer touch the application; it orchestrates tasks, it doesn't click.
5. Keep locators, URLs, and endpoints in dedicated technical components so a redesign is a single localized edit that fixes every affected scenario at once.
6. Use named personas to move test data out of scenarios; extend the idea to "known entities" for non-human domain objects.
7. In big-picture scenarios, state only the distinguishing fact and let persona defaults carry the rest.
8. Write high-level tasks that will still be true after redesigns ("provide details about themselves"), and compose them across scenarios.
9. Write the top two layers before the UI exists — they guide development rather than trailing it.
10. Staff acceptance-test design as a developer-and-tester collaboration, with the same craftsmanship you'd apply to production code.

## Connects To
- **Ch 7**: declarative scenarios — this chapter explains the architecture that makes them cheap to maintain.
- **Ch 8**: step definitions and `@ParameterType`/`@DataTableType` — the glue-code layer named here.
- **Ch 10**: automating the UI layer, WebDriver locators in depth.
- **Ch 11**: test automation design patterns for the UI layer (Page Objects and beyond).
- **Ch 12**: the Screenplay Pattern — the actor-centric style used throughout this chapter's examples.
- **Ch 13**: API and microservice testing — the non-UI interaction paths mentioned here.
- **Gojko Adzic, "How to implement UI testing without shooting yourself in the foot"**: the source cited for the layered approach.
- **Typesafe/Lightbend config + HOCON**, **Serenity Screenplay**, **Selenium WebDriver**, **TestMail/MailSlurp/MailHog**: tools used.
