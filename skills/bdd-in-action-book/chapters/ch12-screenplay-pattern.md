# Chapter 12: Scalable Test Automation with the Screenplay Pattern

## Core Idea
Screenplay is an **actor-centric** model built from five composable elements. Interactions are *objects, not methods*, so you extend the system by adding classes rather than modifying them — and tasks compose freely, which is what makes large suites stay maintainable.

## Frameworks Introduced

- **The Five Elements of Screenplay** (figure 12.2):
  | Element | Represents |
  |---|---|
  | **Actors** | Users and external systems interacting with ours |
  | **Interactions** | The most basic activities an actor can perform (click a button, send an API request) |
  | **Abilities** | What enables actors to interact through a given interface |
  | **Questions** | When answered by actors, provide information about system state |
  | **Tasks** | Group, combine, and reuse sequences of interactions or other tasks |

- **The layering principle** — the essence of the pattern in one sentence:
  > "At each layer, we focus on describing **what** is happening at that layer, leaving the **how** for the layer underneath."
  - And the language shift: "Whereas a Page Object architecture describes things in the language of the **solution** (pages, UI element, etc.), with Screenplay we model things using the language of the **business or the problem domain**."

- **Why Page Objects and Action classes run out** — the four named limitations:
  | Problem | Detail |
  |---|---|
  | **UI-shaped thinking** | Page Objects "place too much emphasis on how the user interface is built… harder to step back and see what the user is really trying to achieve." Incorporating API, batch, or DB interactions "might feel awkward and inconsistent." |
  | **Bloat** | Page Object classes "try to do way too much" — unrelated fields grouped because they share a page; complex hierarchies mimicking the app's page structure. |
  | **Non-reusable interactions** (Action classes) | Dropdown-handling logic "would need to be duplicated whenever we encounter a similar dropdown field anywhere in the application." |
  | **Single-actor assumption** (Action classes) | "Things can become tricky and boundaries between the different parts of a workflow blurred if more than one actor is involved." |
  - **Multi-actor scenarios are common in real projects**: "a loan application may need a client to make the application, and then one or more bank employees to review and approve or reject the application. Chat systems and games are other common examples."
  - **Composition problem**: with Action classes, "if we want to combine a sequence of methods (say, search flights, select a flight, and book the flight) into a single task (say, make a booking), we need to create a new method for that. This can lead to large Action classes with lots of methods."

- **Interactions as objects — the Command Pattern.** The single most important structural insight.
  - Conventional WebDriver: locate the element, then **invoke a method on it** (`loginButton.click()`).
  - Screenplay: **create an object** and pass it to `attemptsTo()` (`Click.on("#login-button")`).
  - **Why this matters**: "We don't have to modify our existing classes when we want to add new behavior; we simply create a new interaction class. And by not having to change our existing code so much, we reduce the risk of inadvertently breaking something." (Open/Closed Principle in practice.)
  - **The demonstrating example**: `WebDriver` has no double-click method. Conventionally you must introduce the `Actions` class and switch coding style entirely:
    ```java
    WebElement loginButton = driver.findElement(By.id("#login-button"));
    Actions action = new Actions(driver);
    action.doubleClick(loginButton).perform();
    ```
    In Screenplay you just use a different object: `DoubleClick.on("#login-button")`.
  - **The restaurant analogy** for the Command Pattern: "the waiter takes your order, writes it down on a piece of paper (the object), and passes this piece of paper to the kitchen, where your meal is prepared. In the same way the Interaction Object only contains instructions of what the actor should do; **it is the actor who performs them**."

- **Abilities as the Adaptor Pattern.** "An adaptor is a thin interface that allows two systems to work together, without having to change the code in either system. An ability, then, is a thin wrapper around a lower-level, interface-specific client such as a web browser driver, an HTTP client, a database client, and so on."
  - Consequence: "you can easily add new abilities without having to change the actor implementation for each new system you need to interact with."

- **Questions as assertions.** "In Screenplay, questions are how we write our assertions."
  - **The key idiom**: a Question object alone does nothing. "A `Question` class in Screenplay is a bit like an online poll: **if you don't ask anyone to answer the questions, you won't get much information.**" You must call `.answeredBy(actor)` — or hand it to `Ensure.that(...)`.

- **Three benefits of even trivial tasks** (a one-interaction `Navigate.toTheHomePage()`):
  1. **Higher-level abstraction and reusable behavior** — "every other actor will be able to navigate to the home page too, without having to remember what URL they need to open."
  2. **Single place for URLs and selectors** — no duplication.
  3. **Better reports** — "each custom task has its own description, which helps to produce far more informative test execution reports than simply listing all the 'clicks' and element selectors."

- **Cucumber integration: Cast, OnStage, and the Spotlight.**
  | Mechanism | Purpose |
  |---|---|
  | `OnStage.setTheStage(new OnlineCast())` | Set up a Cast of actors, each with their own `WebDriver`, in a `@Before` hook |
  | `OnStage.theActorCalled(name)` | Summon an actor by name; creates or retrieves |
  | `OnStage.theActorInTheSpotlight()` | Retrieve the **last active actor** when the step doesn't name anyone |
  | Pronoun recognition | Serenity BDD and Serenity/JS recognize common pronouns — "he" resolves to the last actor referenced |
  | `@ParameterType(".*") Actor actor(String)` | Convert the scenario's actor name straight into an `Actor` parameter |
  - Why a Cast is needed at all: "unlike a self-contained Screenplay test case, the actor will need to be used in other step definition methods, possibly in other classes, so we need to keep track of the actor between these steps."

## Key Concepts

- **`attemptsTo()`** — the universal entry point. Named "attempts to" rather than "performs" or "does" **"because, after all, this is a test, and something might go wrong."**
- **`Performable`** — the interface every interaction and task implements; `attemptsTo()` takes a list of them.
- **`Task.where(description, ...performables)`** — build a task from a description plus interactions/tasks. `{0}` interpolates the actor's name.
- **`Interaction.where(description, lambda)`** — build a custom interaction from a Java 8 lambda receiving the actor.
- **`Ensure`** — fluent assertions woven into the interaction flow; **the available assertion methods depend on the question's return type** (String questions get String assertions, integer questions get numeric ones).
- **`Cast` / `OnlineCast`** — manages the actors in a scenario and their abilities.

## Reference Tables

**Common Screenplay UI Interaction classes:**
| Interaction | Usage | Example |
|---|---|---|
| `Clear` | Clear a text field | `Clear.field("#email")` |
| `Click` | Click an element | `Click.on("#login-button")` |
| `Enter` | Type a value into a field | `Enter.theValue("secretPassword").into("#password")` |
| `Open` | Open a URL *(Serenity BDD)* | `Open.url("https://www.google.com")` |
| `Navigate` | Open a URL *(Serenity/JS)* | `Navigate.to("https://www.google.com")` |
| `Scroll` | Scroll to an element | `Scroll.to("#login-button")` |
| `SelectFromOptions` | Select a dropdown value *(Serenity BDD)* | `SelectFromOptions.byVisibleText("Economy").from("#travel-class")` |
| `Select` | Select a dropdown value *(Serenity/JS)* | `Select.option("Economy").from(travelClass)` |

**Wait conditions (`WebElementStateMatchers`)** — most have a `not` variant (`isNotVisible()`, `isNotEnabled()`, …):
| Condition | Waits until | Example |
|---|---|---|
| `isVisible()` | Element is rendered | `WaitUntil.the(".flight-container", isVisible())` |
| `isNotVisible()` | Element is not rendered | `WaitUntil.the("#login-button", isNotVisible())` |
| `isEnabled()` | Element is enabled | `WaitUntil.the("#search-button", isEnabled())` |
| `isPresent()` | Element is in the DOM | `WaitUntil.the("#search-button", isPresent())` |
| `containsText(...)` | Element contains given text | `WaitUntil.the(".status-message", containsText("Done"))` |

**Common Screenplay Question classes (Serenity BDD):**
| Question | Returns | Example |
|---|---|---|
| `Attribute` | A named HTML attribute value | `Attribute.of(".item-details-link").named("href")` |
| `Disabled` | Whether a field is disabled | `Disabled.of("#login-button")` |
| `Enabled` | Whether a field is enabled | `Enabled.of("#login-button")` |
| `SelectedValue` | Selected dropdown value | `SelectedValue.of("#travel-class")` |
| `Text` | Text content of an element | `Text.of("[test-dataid='name']")` |
| `Value` | A form field's `value` attribute | `Value.of("#firstName")` |
| `Visibility` | Whether an element is visible | `Visibility.of(".error-message")` |

**Screenplay implementations across languages:**
| Language | Library |
|---|---|
| Java / JVM | Serenity BDD |
| JavaScript / TypeScript | Serenity/JS, Cucumber Screenplay |
| Python | ScreenPy |
| .NET | Boa Constrictor |

*"Screenplay is a design pattern, not a library."*

## Code Examples

**Defining an actor and granting abilities:**
```java
WebDriver driver = new ChromeDriver();
Actor sally = Actor.named("Sally");
sally.can(BrowseTheWeb.with(driver));       // now all WebDriver interactions work
sally.can(CallAnApi.at("http://my.api.server:8000"));   // and REST ones
```
Reaching the underlying driver when you must:
```java
String currentUrl = BrowseTheWeb.as(actor).getDriver().getCurrentUrl();
```

**One `attemptsTo()` call, many interactions** — instead of repeating the call per line:
```java
tracy.attemptsTo(
    Open.url("http://localhost:3000/"),
    Click.on("//button[normalize-space()='Login']"),
    Enter.theValue("tracy@traveler.com").into("#email"),
    Enter.theValue("secretPassword").into("#password"),
    Click.on("#login-button")
);
```

**Waits, four ways:**
```java
// Element state matcher
tracy.attemptsTo(WaitUntil.the(".block-ui-spinner", isNotVisible()).forNoMoreThan(10).seconds());
tracy.attemptsTo(WaitUntil.the(".flight-container", isVisible()).forNoMoreThan(10).seconds());

// Selenium ExpectedConditions
tracy.attemptsTo(WaitUntil.the(titleIs("Search Results")).forNoMoreThan(Duration.of(3, SECONDS)));

// Arbitrary boolean function
tracy.attemptsTo(Wait.until(() -> fileIsProcessed()).forNoMoreThan(Duration.of(3, SECONDS)));
```

**REST interactions — the same actor, a different interface:**
```java
Traveler trevor = new Traveler("trevor@traveler.com", "secret");
actor.attemptsTo(
        Post.to("/users")
            .with(request -> request.body(trevor))
);
```

**Writing your own interaction class:**
```java
public class SwitchTo {
    public static Interaction parent() {
        return Interaction.where("{0} switches to the parent frame",
            theActor -> {
                WebDriver driver = BrowseTheWeb.as(theActor).getDriver();
                driver.switchTo().parentFrame();
            }
        );
    }
}
```
```java
sally.attemptsTo(SwitchTo.parent());
```

**Questions — raw, transformed, and domain-specific:**
```java
Text.of("[test-dataid='status-level']")                       // a question object; does nothing yet
Text.of("[test-dataid='point-balance']").asInteger()          // with a type transformation
Visibility.of("[test-dataid='point-balance']")

// Now actually ask someone:
String statusLevel   = Text.of("[test-dataid='status-level']").answeredBy(sally);
Integer pointBalance = Text.of("[test-dataid='point-balance']").asInteger().answeredBy(sally);
boolean balanceIsVisible = Visibility.of("[test-dataid='point-balance']").answeredBy(sally);
```
Wrap it for readability:
```java
public class Account {
    public static Question<Integer> pointBalance() {
        return Text.of("[test-dataid='point-balance']").asInteger();
    }
}

int pointBalance = Account.pointBalance().answeredBy(sally);
```

**Assertions — conventional vs. fluent:**
```java
// Conventional
sally.attemptsTo(Click.on("#my-account"));
int pointBalance = Account.pointBalance().answeredBy(sally);
Assert.assertEquals(1000, pointBalance);

// Woven into the flow with Ensure (Serenity BDD)
sally.attemptsTo(
  Click.on("#my-account"),
  Ensure.that(Account.pointBalance()).isEqualTo(1000)
);

Ensure.that(Account.statusLevel()).isEqualTo(UserLevel.BRONZE);

// Serenity/JS syntax
Ensure.that(Account.pointBalance(), equals(1000));
```

## Worked Example

**Composing tasks bottom-up: from one URL to a full login.**

*Level 1 — a task wrapping a single interaction:*
```java
public class Navigate {
    public static Performable toTheHomePage() {
        return Task.where("{0} goes to the login page",              // {0} = the actor's name
                    Open.url("https://www.frequent-flyers.bddinaction.com")
        );
    }
}
```
```java
sally.attemptsTo(Navigate.toTheHomePage());
```

*Level 2 — a task built from the previous task plus one interaction:*
```java
public class Navigate {
    ...
    public static final By LOGIN_BUTTON = By.xpath("//button[normalize-space()='Login']");

    public static Performable toTheLoginPage() {
        return Task.where("{0} goes to the login page",
                Navigate.toTheHomePage(),      // reuses the task above
                Click.on(LOGIN_BUTTON)
        );
    }
}
```

*Level 3 — a business task built from a task plus three interactions:*
```java
public class Login {
    public static Performable usingCredentials(String username, String password) {
        return Task.where("{0} logs in as " + username,
                Navigate.toTheLoginPage(),
                SendKeys.of(username).into("#email"),
                SendKeys.of(password).into("#password"),
                Click.on("#login-button")
        );
    }
}
```
```java
tracy.attemptsTo(Login.usingCredentials("tracy@traveler.com", "secretpassword"));
```

The book's point about reuse: "In test automation, we often think of reusability in terms of the locators and fields we interact with on a page, or of the low-level interactions we perform. But Screenplay takes the concept of reusability much further. Screenplay makes it easy to define reusable tasks made up of **other tasks and interactions**, and to use these tasks both to execute tests **and to build other, even higher-level tasks**."

*The full self-contained test, showing all layers at once:*
```java
WebDriver driver;

@Before
public void openBrowser() {
    driver = new ChromeDriver();
}

@Test
public void viewAccountBalance() {
    Actor sally = Actor.named("Sally")
                       .whoCan(BrowseTheWeb.with(driver));

    sally.attemptsTo(
      Login.usingCredentials("sally@flying-high.com", "secretpassword"),
      Navigate.toMyAccount(),
      Ensure.that(Account.pointBalance(), isEqualTo(1000)),
      Ensure.that(Account.statusLevel()).isEqualTo(UserLevel.BRONZE)
    );
}

@After
public void closeBrowser() {
    driver.quit();      // in @After so it runs even if the test fails
}
```

**A search task encapsulating a whole form** — the chapter's opening comparison. The scenario:
```gherkin
Rule: Travelers can search by departure, destination, and travel class
  Scenario Outline: Searching for flights by travel class
    Given Amy is logged on as registered Frequency Flyer member
    When she searches for flights with the following criteria
      | From   | To   | Travel Class   |
      | <From> | <To> | <Travel Class> |
    Then the returned flights should match the travel class <Travel Class>

    Examples:
      | From   | To        | Travel Class    |
      | Sydney | Hong Kong | Economy         |
      | London | New York  | Premium Economy |
      | Seoul  | Hong Kong | Business        |
```
The step definition:
```java
@When("{actor} searches for flights with the following criteria")
public void performSearch(Actor traveler, FlightSearch searchCriteria) {
    traveler.attemptsTo(
            SearchFlights.matchingCriteria(searchCriteria)
    );
}
```
And the task — note every line reads as *what the actor does to which element*:
```java
public class SearchFlights {
    public static Performable matching(FlightSearch searchCriteria) {
        return Task.where("Search for matching flights",
                Navigate.toBookFlights(),
                Type.theValue(searchCriteria.from()).into(SearchFlightsForm.FROM),
                Type.theValue(searchCriteria.to()).into(SearchFlightsForm.TO),
                Select.option(searchCriteria.travelClassName())
                      .from(SearchFlightsForm.TRAVEL_CLASS_DROPDOWN),
                Click.on(SearchFlightsForm.SEARCH_BUTTON),
                WaitUntil.the(SearchResultsList.SEARCH_RESULTS, isVisible())
                         .forNoMoreThan(5).seconds()
        );
    }
}
```
Compare against the Action-class version of just the destination field, whose dropdown-handling would have to be re-written at every similar field in the app:
```java
public void to(String destination) {
    $("#destination").type(destination);
    waitingForNoLongerThan(1).second()
        .find("/span[contains(.,'{0}')]", destination)
        .click();
}
```

**Screenplay + Cucumber, end to end.**

The scenario — the actor's name is *data*, not code:
```gherkin
Scenario: Stan checks his balance
  Stan is a standard frequent flyer member with 0 points

  Given Stan has logged into his account
  When he views his account details
  Then his account status should be:
    | Point Balance | Status Level |
    | 0             | STANDARD     |
```
"In other scenarios we might work with Silvia (who's a Silver Frequent Flyer member) or Bryony (a Bronze member). In other words, the name of the actor needs to be a **variable**."

*Set the stage once per scenario:*
```java
@Before
public void setTheStage() {
    OnStage.setTheStage(new OnlineCast());   // each actor gets their own WebDriver
}
```

*A custom parameter type turns the name into an Actor:*
```java
@ParameterType(".*")
public Actor actor(String actorName) {
    return OnStage.theActorCalled(actorName);
}

@Given("{actor} has logged into his/her account")
public void memberHasLoggedIn(Actor actor, String actorName) {
    actor.attemptsTo(...);
}
```

*Pronouns resolve to the last actor — "he" is Stan:*
```java
@When("{} views his/her account details")
public void viewsAccountSummary(String actorName) {
  OnStage.theActorCalled(actorName).attemptsTo(Navigate.toMyAccount());
}
```

*Persona credentials as an enum:*
```java
public enum FrequentFlyer {
    Stan("stan@flyinghigh.com", "secret"),
    Bryony("bryony@flyinghigh.com", "secret"),
    Silvia("silvia@flyinghigh.com", "secret");

    public final String email;
    public final String password;
    FrequentFlyer(String email, String password) {
        this.email = email;
        this.password = password;
    }
}

@Given("{} has logged into his/her account")
public void memberHasLoggedIntoTheirAccount(FrequentFlyer member) {
    theActorCalled(member.name()).attemptsTo(
            Login.usingCredentials(member.email, member.password)
    );
}
```

*The final step — the actor isn't named, so use the spotlight:*
```java
@DataTableType
public AccountStatus accountStatus(Map<String, String> statusValues) {
    Integer points = Integer.parseInt(statusValues.get("Point Balance"));
    UserLevel level = UserLevel.valueOf(statusValues.get("Status Level"));
    return new AccountStatus(level, points);
}

@Then("his/her account status should contain:")
public void accountStatusShouldContain(AccountStatus expected) {
  OnStage.theActorInTheSpotlight().attemptsTo(
      Ensure.that(MyAccount.statusLevel()).isEqualTo(expected.userLevel()),
      Ensure.that(MyAccount.pointBalance()).isEqualTo(expected.pointBalance())
    );
}
```
"The only real differences [from a self-contained Screenplay test] are the use of the `Cast` and `OnStage` classes to set up and manage the scenario actors."

## Mental Models

- **The film metaphor is literal.** "Despite the word 'screen' in its name, the Screenplay Pattern has nothing to do with computer screens." In film, a screenplay describes the actors, their dialogue, and the tasks they perform. Here, actors are users, their behavior and micro-goals are tasks, and the sequences become screenplays.
- **Actors are personas.** They map directly to the personas from ch 7 and the ones already named in your Gherkin scenarios — "Tracy the Traveler," "Amy the Account Manager."
- **"A star who never appears on stage isn't much of a star."** Defining an actor is only the beginning; they become interesting when performing tasks.
- **Screenplay is interface-agnostic by design.** The same actor can drive Selenium WebDriver, Webdriver.io, Playwright, a REST client, a database, or a mainframe — choose the ability, and the interaction classes follow.
- **Extend by adding, not modifying.** Every new behavior is a new interaction or task class. Existing classes stay untouched, so you don't break what works.

## Anti-patterns

- **Repeating `attemptsTo()` per line**: "would become repetitive and distract from the flow of the actions, making the code harder to read." Pass a sequence instead.
- **Building tests from low-level interactions only**: "would not be much of an improvement over doing so by directly calling WebDriver or REST client APIs… lengthy tests in which the higher-level business-specific concepts are difficult to discern and easy to miss in the noise of actors clicking on buttons and sending HTTP requests."
- **Page Object hierarchies mirroring the application's page structure**: complexity without benefit.
- **Action classes accumulating a method per task combination**: composition should be free, not a new method each time.
- **Assuming a single actor**: real business workflows (loan approval, chat, games) need several, with clear boundaries between their activities.
- **Writing a Question and never asking it**: without `.answeredBy(actor)` or `Ensure.that(...)`, nothing happens.
- **Closing the browser at the end of the test body**: put `driver.quit()` in `@After` "to ensure that it happens even if the test fails."

## Key Takeaways
1. Start every scenario from an actor; model what they're trying to achieve in business language, not screens and buttons.
2. Treat interactions as objects passed to `attemptsTo()` — this is what lets you add behavior without editing existing classes.
3. Give actors abilities (`BrowseTheWeb`, `CallAnApi`) rather than teaching the actor about each interface; abilities are adaptors.
4. Write custom interaction classes with `Interaction.where(description, lambda)` when the library lacks one — it's a few lines.
5. Wrap raw questions in domain-specific ones (`Account.pointBalance()`) so assertions read in business terms.
6. Remember a Question does nothing until an actor answers it; prefer `Ensure.that(...)` to weave assertions into the flow.
7. Build tasks bottom-up and reuse tasks *inside* tasks — even one-interaction tasks pay off in reuse, single-source locators, and readable reports.
8. In Cucumber, set the stage with a Cast in `@Before`, resolve actors by name via a `{actor}` parameter type, and use `theActorInTheSpotlight()` where the step names no one.
9. Store persona credentials in an enum (or HOCON) so scenarios name people, not data.
10. Reach for Screenplay when the suite is large, spans multiple interfaces, or involves multiple actors; Page Objects remain fine for small applications.

## Connects To
- **Ch 7**: personas — the direct ancestor of Screenplay actors.
- **Ch 9**: layers of abstraction — Screenplay is a rigorous implementation of them; the chapter's examples already used Screenplay syntax.
- **Ch 10–11**: the WebDriver code and Page Object/Action-class patterns this chapter supersedes at scale.
- **Ch 13**: REST API and microservice testing, with and without Screenplay.
- **Ch 14–15**: Serenity/JS — the same pattern in TypeScript.
- **Gang of Four, *Design Patterns* (1994)**: the Command and Adaptor patterns Screenplay builds on.
- **Origin story**: Kevin Lawrence's "In Praise of Abstraction" (AAFTT, 2007) → Antony Marcano's fluent DSL → JNarrate with Andy Palmer (2008) → screenplay-jvm with Jan Molak (2013) → Serenity BDD with John Ferguson Smart (2015).
