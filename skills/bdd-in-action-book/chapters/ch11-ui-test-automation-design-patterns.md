# Chapter 11: Test Automation Design Patterns for the UI Layer

## Core Idea
Page Objects centralize *where things are and how to touch them*, keeping locators out of test code. But Page Objects alone are not enough at scale — add an **Action/Query class layer** (a DSL) above them so step definitions describe business intent rather than pages.

## Frameworks Introduced

- **The Page Objects Pattern** — a class modeling a specific part of the UI, presenting business-focused methods. **Two roles:**
  1. **Isolates the technical implementation of the page from the tests**, making test code simpler and easier to maintain.
  2. **Centralizes the code that interacts with a page**, so a UI change means updating one place.
  - Lives in the **Interaction layer** (figure 11.1), providing business-friendly services upward to the Business Flow layer.

- **The Five Rules of a Good Page Object:**
  1. **Locate elements** — know what locator strategy to use, stored where it's easy to find and update. This is the primary role. *(Footnote: in Action-class and Screenplay approaches, this becomes the Page Object's* only *responsibility.)*
  2. **Represent components, not whole pages** — see below.
  3. **Report page state in business terms** — return simple types or domain objects.
  4. **Perform business tasks** — group related interactions into one business-meaningful method.
  5. **Hide wait conditions and other incidental details** — spinners, animations, timing.
  - Plus one hard prohibition: **no assertions**.

- **"Page Component Objects" — the naming correction.** Despite the name, Page Objects don't represent whole pages. Modern apps are "too rich and complex to be represented as a single object" — menu bars, navigation, search boxes, search results. Putting them all in one class makes it "large and unwieldy, hard to read, and hard to understand."
  > **Martin Fowler (2013):** "Despite the term 'page' object, these objects shouldn't usually be built for each page, but rather for the significant elements on a page."

- **The no-assertions rule and its rationale.** "Page Objects report the state of a page but don't make judgment calls about whether this state is as expected."
  - **The separation of concerns**: the step definition describes *what we expect* (the assertion); the Page Object tells us *what it sees* on the screen.
  - Why: burying assertions makes Page Objects "larger and more complex and also makes it harder to read what a test is actually testing." And "imagine if we needed to add assertion methods for every check we needed to do!"

- **The API-exposure rule.** "Page Objects should never expose implementation details about the page or component they're encapsulating. Page Object methods should accept and return **simple types such as strings, dates, Booleans, or domain-specific objects**. They should **never expose `WebDriver` or `WebElement`** classes."
  - So: no `getCurrentUserElement()`, no `loginPage.getEmailField().sendKeys(...)`.

- **Three granularities for Page Object methods** — pick by whether the actions are separable in business terms:
  | Style | Example | When |
  |---|---|---|
  | Expose elements (**never do this**) | `loginPage.getEmailField().sendKeys(email)` | — |
  | One method per field | `loginPage.enterEmail(...)`, `enterPassword(...)`, `clickLoginButton()` | When fields are genuinely used independently |
  | One business method | `loginPage.signinWithCredentials(email, password)` | When they're one business action — "we would never enter an email alone, without clicking on the login button" |

- **The limitations of Page Objects at scale** — three named failure modes:
  1. **UI tunnel vision**: "if all you have are Page Objects, there can be a temptation to test everything through the UI and miss the opportunity to streamline tests by implementing certain steps with faster and more reliable API calls."
  2. **Bloat and mixed concerns**: business logic ("search for flights") mixed with UI details ("select travel class from the dropdown menu").
  3. **Mirroring the UI structure**: "Many folks fall into the trap of writing Page Objects that closely model and duplicate the structure of the user interface, which can make the Page Object classes more complicated and fragile."

- **Action classes and Query classes** — the extra layer between step definitions and Page Objects, forming a **domain-specific language (DSL)**:
  | Type | Responsibility | Example |
  |---|---|---|
  | **Action class** | Encapsulates a business *task or action* | `Login.as(frequentFlyer)` |
  | **Query class** | Reads system state, returns business-friendly answers | `CurrentUser.isConnectedAs(frequentFlyer)` |
  - "Action classes know which pages (or APIs) they need to interact with but don't need to know implementation details such as how to locate a particular element on a page."
  - **Two stated advantages**: (a) "a much cleaner separation between the business-focused steps in the Cucumber scenarios (the *what*), and the nitty-gritty details of how these steps are implemented (the *how*)"; (b) "more options to reuse business steps between different scenarios, without having to add complexity to our Page Objects."
  - **The decisive argument for Action classes**: a Page Object–based login step "means that we can only perform this step via the UI. If we wanted to streamline things (for example by providing our authentication details via a Cookie, or using some other authentication mechanism), we would need to rewrite the whole step." An Action class models *the login process*, not the login screen.

- **Fluent Interface** — an API using method chaining to improve readability. Each method returns `this`; a terminal method performs the action. Scales gracefully as scenarios get richer (one-way → return trip → multi-stop).

## Key Concepts

- **`PageFactory` / `@FindBy`** — WebDriver's mechanism for declaring locators as annotated fields; elements are re-located on the fly each time you use them.
- **`WebElementFacade`** (Serenity BDD) — an enhanced `WebElement`. Its `type()` method extends `sendKeys()` by "ensuring that the field is ready and clearing it before sending the key values."
- **`@Steps`** (Serenity BDD) — auto-instantiates an Action class and any nested Page Objects.
- **`@Step("...")`** (Serenity BDD) — makes a method call appear as a step in the test report; `{0}` interpolates the first parameter.
- **`@DefaultUrl("/login")`** (Serenity BDD) — the relative or absolute URL used when the Page Object is opened.
- **`UIInteractionSteps`** (Serenity BDD) — base class for Action or Query classes that interact with the UI; provides helpers like `textOf(locator)`.

## Reference Tables

**`@FindBy` locator forms:**
| Expression | Finds by |
|---|---|
| `@FindBy(id="welcome-message")` | ID |
| `@FindBy(name="email")` | name attribute |
| `@FindBy(className="typeahead")` | CSS class name |
| `@FindBy(css=".typeahead li")` | CSS selector |
| `@FindBy(linkText="Book")` | Link text |
| `@FindBy(partialLinkText="Book")` | Partial link text |
| `@FindBy(tagName="h2")` | HTML tag |
| `@FindBy(xpath="//span[.='Singapore']")` | XPath |

**Convention over configuration**: if the field name matches the element's `id` or `name`, you can **omit `@FindBy` entirely**. A field named `email` is "the equivalent of first trying `@FindBy(id="email")`, and if that fails, `@FindBy(name="email")`."

## Code Examples

**A basic Page Object — locators as named constants:**
```java
public class LoginPage {
    private static final By EMAIL_FIELD = By.id("email");
    private static final By PASSWORD_FIELD = By.id("password");
    private static final By LOGIN_BUTTON = By.id("login-button");

    private final WebDriver driver;

    public LoginPage(WebDriver driver) { this.driver = driver; }

    public void open() { driver.get("http://localhost:3000/login"); }

    public void signinWithCredentials(String email, String password) {
        driver.findElement(EMAIL_FIELD).sendKeys(email);
        driver.findElement(PASSWORD_FIELD).sendKeys(password);
        driver.findElement(LOGIN_BUTTON).click();
    }
}
```
Two benefits from the named constants, per the book: locators are centralized in one findable place, **and** "when we read the code in the method we can focus on *what* element the code is looking for rather than *how* the element is located."

**A parameterized locator, removing near-duplicate XPaths.** First the redundant version:
```java
public class MenuBar {
    private static final By BOOK_FLIGHTS_BUTTON = By.xpath("//button[contains(.,'Book Flights')]");
    private static final By MY_BOOKINGS_BUTTON  = By.xpath("//button[contains(.,'My Bookings')]");
    private static final By MY_ACCOUNT_BUTTON   = By.xpath("//button[contains(.,'My Account')]");
    private static final By LOGOUT_BUTTON       = By.xpath("//button[contains(.,'Logout')]");
```
"The HTML structures and the corresponding XPath locators for each link are very similar, so this feels like duplicated work." The refactor:
```java
public class MenuBar {
    private WebDriver driver;
    public MenuBar(WebDriver driver) { this.driver = driver; }

    private static By buttonWithLabel(String label) {
        return By.xpath("//button[contains(.,'" + label + "')]");
    }

    public void navigateToBookFlights() { driver.findElement(buttonWithLabel("Book Flights")).click(); }
    public void navigateToMyBookings()  { driver.findElement(buttonWithLabel("My Bookings")).click(); }
    public void navigateToMyAccount()   { driver.findElement(buttonWithLabel("My Account")).click(); }
    public void logout()                { driver.findElement(buttonWithLabel("Logout")).click(); }
}
```

**`PageFactory` + `@FindBy` — the same Page Object with less boilerplate:**
```java
public class LoginPage {
    @FindBy(id="email")        WebElement emailField;
    @FindBy(id="password")     WebElement passwordField;
    @FindBy(id="login-button") WebElement loginButton;

    public LoginPage(WebDriver driver) {
        PageFactory.initElements(driver, this);
    }

    public void signinWithCredentials(String email, String password) {
        emailField.sendKeys(email);
        passwordField.sendKeys(password);
        loginButton.click();
    }
}
```
Each field use performs the equivalent of a fresh `driver.findElement(By...)` call.

**The Serenity BDD version — no WebDriver plumbing at all:**
```java
@DefaultUrl("/login")
public class LoginPage extends PageObject {
    @FindBy(id="email")        WebElementFacade email;
    @FindBy(id="password")     WebElementFacade password;
    @FindBy(id="login-button") WebElementFacade loginButton;

    public void signinWithCredentials(String emailValue, String passwordValue) {
        email.type(emailValue);         // type() = ready-check + clear + sendKeys
        password.type(passwordValue);
        loginButton.click();
    }
}
```
And in the step definition, Serenity instantiates the field for you:
```java
LoginPage loginPage;   // auto-initialized with the current WebDriver instance

@When("^s?he (?:logs|has logged) on with a valid username and password$")
public void logsOnWithAValidUsernameAndPassword() {
    loginPage.open();
    loginPage.signinWithCredentials(frequentFlyer.email, frequentFlyer.password);
}
```

**Page Object returning state, not elements:**
```java
public class CurrentUserPanel {
    private WebDriver driver;
    public CurrentUserPanel(WebDriver driver) { this.driver = driver; }

    private static final By CURRENT_USER = By.id("current-user");

    public String label() {
        return driver.findElement(CURRENT_USER).getText();   // a String, not a WebElement
    }
}
```
```java
@Then("he/she should be given access to his/her account")
public void shouldBeGivenAccessToHisAccount() {
    CurrentUserPanel currentUserPanel = new CurrentUserPanel(driver);
    assertThat(currentUserPanel.label()).isEqualTo(frequentFlyer.email);
}
```

**The assertion anti-pattern to avoid:**
```java
// ANTI-PATTERN — violates separation of concerns between Page Objects and test code
public void checkThatUserEmailDisplayedIs(String expectedEmail) {
    assertThat(driver.findElement(CURRENT_USER).getText()).isEqualTo(expectedEmail);
}
```

**Hiding a spinner wait inside a Page Object method:**
```java
private static final By SEARCH_BUTTON = By.id("search-button");
private static final By SPINNER = By.cssSelector(".block-ui-spinner");

public void submitSearch() {
    driver.findElement(SEARCH_BUTTON).click();
    Wait<WebDriver> wait = new FluentWait<>(driver)
            .withTimeout(Duration.ofSeconds(10))
            .pollingEvery(Duration.ofMillis(100));
    wait.until(invisibilityOfElementLocated(SPINNER));
}
```
The step definition never learns the spinner exists:
```java
@When("she/he searches for flights with the following criteria")
public void performSearch(FlightSearch search) {
    this.searchCriteria = search;
    menuBar.navigateToBookFlights();
    searchForm.enterSearchCriteria(search.from(), search.to(), search.travelClass());
    searchForm.submitSearch();
}
```
"Perhaps tomorrow the search results might be returned differently, without the spinner, but this should not affect our scenario or our step definition code."

**Action class — modeling the login *process*, not the login *screen*:**
```java
public class Login {
    LoginForm loginForm;                    // auto-initialized by Serenity

    @Step("Login as {0}")                   // appears as a step in the report
    public void as(FrequentFlyer frequentFlyer) {
        loginForm.open();
        loginForm.enterCredentials(frequentFlyer.email, frequentFlyer.password);
        loginForm.submit();
    }
}
```
```java
@Steps Login login;

@When("^s?he (?:logs|has logged) on with a valid username and password$")
public void logsOnWithAValidUsernameAndPassword() {
    login.as(frequentFlyer);
}
```

**Query class:**
```java
public class CurrentUser extends UIInteractionSteps {
    public boolean isConnectedAs(FrequentFlyer frequentFlyer) {
        return frequentFlyer.email.equals(textOf("#current-user"));
    }
}
```
```java
@Then("he/she should be given access to his/her account")
public void shouldBeGivenAccessToHisAccount() {
    assertTrue("the current user should be shown as " + frequentFlyer,
               currentUser.isConnectedAs(frequentFlyer));
}
```
The motivating question: "what happens if we decide to display the user's **first name** instead of their email? The intent of the step ('he/she should be given access to his/her account') wouldn't be any less valid. But the implementation would break." A Query class absorbs that change.

## Worked Example

**Search form — from Page Object to Fluent DSL.**

The scenario:
```gherkin
Background:
  Given Amy is a registered Frequency Flyer member
  And she has logged on with a valid username and password

Rule: Travellers must provide at least departure, destination and travel class
  Scenario Template: Missing mandatory fields should be highlighted
    When she tries to search for flights with the following criteria
      | From   | To   | Travel Class   |
      | <From> | <To> | <Travel Class> |
    Then the search should not be allowed
    And the <Missing Field> field should be highlighted as missing

    Examples:
      | From   | To        | Travel Class | Missing Field |
      |        | Hong Kong | Economy      | From          |
      | Sydney |           | Economy      | To            |
      | Sydney | Hong Kong |              | Travel class  |
```

*Stage 1 — the `SearchForm` Page Object.* Note that departure/destination are plain text fields while travel class is a JavaScript dropdown needing two clicks — **and the caller can't tell the difference**:
```java
public class SearchForm {
    private WebDriver driver;
    public SearchForm(WebDriver driver) { this.driver = driver; }

    public void setDeparture(String departure) {
        driver.findElement(By.id("departure")).sendKeys(departure);
    }

    public void setDestination(String destination) {
        driver.findElement(By.id("destination")).sendKeys(destination);
    }

    private By optionWithLabel(String label) {
        return By.xpath("//mat-option[normalize-space(.)='" + label + "']");
    }

    public void setTravelClass(TravelClass travelClass) {
        driver.findElement(By.id("travel-class")).click();                   // open the dropdown
        driver.findElement(optionWithLabel(travelClass.getLabel())).click(); // pick the option
    }
}
```
"This approach presents a business-readable representation of the information while still hiding the implementation details… All these details are hidden away behind readable and friendly methods."

Field-by-field, or one combined method — both valid:
```java
searchForm.setDeparture(search.from());
searchForm.setArrival(search.to());
searchForm.setTravelClass(search.travelClass());
// …or…
searchForm.enterSearchCriteria("Sydney", "London", TravelClass.ECONOMY);
```

*Stage 2 — reporting state in business terms.* The disabled button is easy:
```java
public boolean searchIsEnabled() {
    return driver.findElement(By.id("search-button")).isEnabled();
}
```
```java
@Then("the search should not be allowed")
public void searchShouldNotBeAllowed() {
    assertThat(searchForm.searchIsEnabled()).isFalse();
}
```

The highlighted-field check is trickier, and the book rejects the obvious approach: "We could check the CSS **color attribute**, but this will tie your code to the whims of the graphic designer." Instead, target the semantic class the framework applies (`mat-form-field-invalid`) and return field *names*:
```java
public List<String> missingFields() {
    return driver.findElements(By.cssSelector(".mat-form-field-invalid"))
            .stream()
            .map(label -> label.getText().trim().replace(" *", ""))   // strip the trailing asterisk
            .collect(Collectors.toList());
}
```
```java
assertThat(searchForm.missingFields()).containsExactly("From");
```

*Stage 3 — collections via `@FindBy`.* For the results list:
```java
public record MatchingFlight(String departure, String destination, TravelClass travelClass) {}

public class MatchingFlightsList {
    private WebDriver driver;

    public MatchingFlightsList(WebDriver driver) {
        this.driver = driver;
        PageFactory.initElements(driver, this);
    }

    @FindBy(css = ".flight-container .card")
    private List<WebElement> matchingFlights;                  // a collection, via @FindBy

    private final static By DEPARTURE    = By.cssSelector(".departure");
    private final static By DESTINATION  = By.cssSelector(".destination");
    private final static By TRAVEL_CLASS = By.cssSelector(".travel-class");

    public List<MatchingFlight> matchingFlights() {
        return matchingFlights.stream()
                .map(element -> new MatchingFlight(
                        element.findElement(DEPARTURE).getText(),      // nested query per card
                        element.findElement(DESTINATION).getText(),
                        TravelClass.withLabel(element.findElement(TRAVEL_CLASS).getText())
                )).collect(Collectors.toList());
    }
}
```
And the assertion, with a Cucumber parameter type doing the enum conversion:
```java
@ParameterType("Economy|Premium Economy|Business")
public TravelClass travelClass(String value) { return TravelClass.withLabel(value); }

@Then("the returned flights should match the travel class {travelClass}")
public void shouldMatchTravelClass(TravelClass expectedClass) {
    assertThat(matchingFlightsList.matchingFlights())
            .isNotEmpty()                                              // guard: don't pass vacuously
            .allMatch(flight -> flight.travelClass() == expectedClass,
                      "should have a travel class of " + expectedClass);
}
```
Note the `.isNotEmpty()` — without it, an empty result list would satisfy `allMatch` and the test would pass on a broken search.

*Stage 4 — the Fluent Interface, and why it earns its keep.* One-way search:
```java
@When("she/he searches for flights with the following criteria")
public void performSearch(FlightSearch search) {
    searchFlights.from(search.from())
            .to(search.to())
            .inTravelClass(search.travelClass())
            .andViewResults();
}
```
Return trip — one extra chained call:
```java
    searchFlights.from(search.from())
            .to(search.to())
            .inTravelClass(search.travelClass())
            .withAReturnTrip()
            .andViewResults();
```
Multi-stop journey:
```java
    searchFlights.from("London")
            .to("New York")
            .thenTo("Los Angeles")
            .inTravelClass(TravelClass.ECONOMY)
            .withAReturnTrip()
            .andViewResults();
```
The implementation just orchestrates existing Page Objects, returning `this` from each builder method:
```java
public class SearchFlights extends UIInteractionSteps {
    @Steps Navigate navigate;
    SearchForm searchForm;

    public SearchFlights from(String departure) {
        navigate.toTheBookFlightsPage();
        searchForm.setDeparture(departure);
        return this;
    }

    public SearchFlights to(String destination) {
        searchForm.setDestination(destination);
        return this;
    }

    public SearchFlights inTravelClass(TravelClass travelClass) {
        searchForm.setTravelClass(travelClass);
        return this;
    }

    public void andViewResults() {        // terminal method — no `this`
        searchForm.submitSearch();
    }
}
```

**The starting point this chapter fixes.** The raw script from ch 10:
```java
@When("he/she logs on with a valid username and password")
public void logsOnWithAValidUsernameAndPassword() {
    WebDriver driver = WebTestSupport.currentDriver();
    driver.get("http://localhost:3000");
    driver.findElement(By.linkText("Login")).click();
    driver.findElement(By.id("email")).sendKeys(frequentFlyer.email);
    driver.findElement(By.id("password")).sendKeys(frequentFlyer.password);
    driver.findElement(By.id("login-button")).click();
}
```
Two named problems: it doesn't scale (duplicate these lines for every login scenario), and — the subtler one — **"you're mixing selector logic (like `By.id("email")`) with the test data we pass to it (`frequentFlyer.email`). When we keep two things together in our code, it is hard to change one without risking changing the other."** Wanting to enter a *different* email elsewhere forces you to duplicate the locator.

## Anti-patterns

- **Locators inline in step definitions**: duplicated across scenarios; one ID change means many edits.
- **Mixing selector logic with test data in the same line**: coupling that makes either hard to change alone.
- **One Page Object per whole page**: large, unwieldy, hard to read. Model *components*.
- **Page Objects that mirror the UI structure**: "more complicated and fragile."
- **Exposing `WebElement` or `WebDriver` from Page Object methods**: leaks the implementation upward.
- **Assertions inside Page Objects**: bloats them and obscures what each test actually tests.
- **Near-identical locator constants** where one parameterized method would do.
- **Checking CSS *color* to detect a validation state**: "ties your code to the whims of the graphic designer" — target the semantic class instead.
- **Wait conditions in step definitions**: "rarely relevant to the business logic that a test demonstrates and just add noise."
- **Page Objects as your only abstraction**: creates UI tunnel vision and blocks the API-shortcut optimization.
- **`allMatch` without `isNotEmpty`**: an empty collection passes vacuously.

## Key Takeaways
1. Hoist every locator into a named constant or `@FindBy` field inside a Page Object — never into test code.
2. Build Page Objects for significant *components*, not whole pages.
3. Page Objects accept and return strings, dates, Booleans, and domain objects — never `WebElement` or `WebDriver`.
4. Keep assertions in step definitions and observation in Page Objects; the split is what keeps both readable.
5. Group interactions into one method when they're one business action; split them when they're genuinely used independently.
6. Bury spinners, animations, and waits inside Page Object methods so the test stays about behavior.
7. Parameterize locators when several elements share a structure.
8. Target semantic classes and states, not visual styling, when reading page state.
9. Add Action and Query classes above your Page Objects so a step can be re-implemented via API or cookie without touching the scenario.
10. Reach for a Fluent Interface when one business operation has many optional variations — it extends by adding a method, not by rewriting.

## Connects To
- **Ch 9**: the three layers — Page Objects live in the Interaction layer; Action classes sit between it and Business Flow.
- **Ch 10**: the raw WebDriver code and the four coupling problems this chapter resolves; locator strategies and wait conditions used here.
- **Ch 12**: the Screenplay Pattern — the next step beyond Action classes.
- **Ch 14–15**: the same patterns in Serenity/JS.
- **Martin Fowler, "PageObject" (2013)**; **Serenity BDD** (`PageObject`, `WebElementFacade`, `UIInteractionSteps`, `@Steps`, `@Step`, `@DefaultUrl`); **Selenium `PageFactory`/`@FindBy`**; **AssertJ**: sources and tools.
