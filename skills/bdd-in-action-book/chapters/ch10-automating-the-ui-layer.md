# Chapter 10: Automating Acceptance Criteria for the UI Layer

## Core Idea
UI tests are for **four things only** — user journeys, what the UI presents, how it renders, and screen-specific logic. Everything else belongs below the UI. This chapter is the Selenium WebDriver reference: locators, interactions, waits, and why raw WebDriver in step definitions doesn't scale.

## Frameworks Introduced

- **The Four Reasons to Write a UI Test** — the chapter's central filter:
  1. **Illustrating key user journeys** through the system
  2. **Illustrating or checking what information is presented** in the UI in different circumstances
  3. **Showing how information is rendered** in the UI
  4. **Documenting and verifying screen-specific business logic**
  - Corollary (figure 10.1): "in a typical BDD project, a significant proportion of automated acceptance tests will be implemented as **non-UI** tests" — many more non-UI than UI.
  - Why non-UI wins where it can: tests business rules "more quickly and more precisely," and is "much easier to automate before development starts."

- **The UI-vs-code test decision rule**: *"Ask yourself whether you're illustrating how the user interacts with the application, or underlying business logic that's independent of the user interface."*
  - Worked instance — two acceptance criteria on the same feature go different ways:
    | Criterion | Where to test | Why |
    |---|---|---|
    | "The user should receive feedback indicating the strength of the password entered" | **Web test** | It's about interaction with the page |
    | "Only strong passwords should be accepted" | **Application code test** | You're really testing the password-strength algorithm; doing it through the UI "would be wasteful" |

- **The three-tier coverage strategy for exhaustive cases** — e.g. email validation:
  1. A `Scenario Outline` with a few invalid emails, through the UI → proves the user *is informed*.
  2. A single scenario with a **table of many cases**, looping inside one step definition → covers more without one web test each. "More efficient… but requires a little more logic in the step definition code to loop over the test cases."
  3. A lower-level unit test for the rest. "We would typically only use Cucumber if we felt this is the best way to document these rules, **and if they are something that the business care enough about** to have it appear in the living documentation."

- **Locator strategy preference order** — the chapter's implicit ranking:
  | Strategy | When | Trade-off |
  |---|---|---|
  | `data-testid` attribute | **Best when you control the HTML** | Purpose-built for tests; immune to JS-framework churn |
  | `By.id()` / `By.name()` | Common and convenient | "Less likely to change when the structure or style of the page changes" — but still coupled: `id` is often used for JS event handling, `name` for form submission |
  | `By.linkText()` / `By.partialLinkText()` | Links with no useful attributes | "Simple, intuitive, and relatively robust, though the test will obviously break if the displayed text is modified" |
  | `By.cssSelector()` | Nested elements, no clean id/name | Flexible, elegant, **fast** (native browser support) |
  | `By.xpath()` | When you need to match on **content**, or navigate relative to a matched node | More powerful than CSS, but more verbose, less readable, fragile if poorly crafted, **no native IE support → very slow there** |
  - "It's a good idea to make sure that all semantically significant elements in a page have a unique ID or name."

- **Nested lookups** — call `findElement()` on a `WebElement`, not just the driver:
  ```java
  driver.findElement(By.id("main-navbar"))   // narrow to the navbar
        .findElement(By.linkText("Book"))    // find the link within it
        .click();
  ```
  "This approach is clear and intuitive and tends to be **less error-prone than using complex XPath expressions or CSS selectors**."

- **Wait strategies for asynchronous pages:**
  | Type | Class | Use |
  |---|---|---|
  | **Explicit wait** | `WebDriverWait` + `ExpectedConditions` | Wait for a named condition with a timeout |
  | **Fluent wait** | `FluentWait` | Custom timeout, polling interval, ignored exceptions, and arbitrary lambda conditions |
  - **Why waits are needed**: in a conventional app, clicking a link triggers an HTTP request and a new page — "WebDriver will automatically wait for the new page to load." With AJAX, the page updates in place, and "WebDriver will not know if or when it needs to wait for updates."
  - **Timing problems aren't only about data**: animation libraries (e.g. **Toastr**'s fade-in notifications) cause the same failures.
  - **Useful trick**: `wait.until(...)` **returns the element it waited for**, so you can chain straight into `.getText()`.

## Key Concepts

- **Journey scenario** — a high-level scenario illustrating a user's path through the system (booking a flight, completing a purchase). Prime UI-test candidates — "but you don't need too many of them… just the more significant ones."
- **Bullet-point Gherkin** — `*` in place of `Given`/`When`/`Then`. "Behind the scenes, Cucumber treats these steps identically… so the style you use is very much a question of personal preference or team conventions."
- **`WebElement`** — WebDriver's representation of anything on the page you want to inspect or manipulate.
- **`findElement()` vs `findElements()`** — one element vs. a `List<WebElement>`.
- **WebDriverManager** — library that auto-downloads the right browser binary. *Note: "In the more recent versions of Selenium, this feature has been integrated into the Selenium library itself, so it is no longer necessary to configure drivers manually."*
- **Selenium Grid** — network of servers controlling browsers on real or virtual remote machines, for parallel execution. Managed commercially by SauceLabs and BrowserStack.
- **W3C WebDriver Specification** — the standard protocol between client libraries and browser-specific drivers.
- **Appium** — a WebDriver-based automation library for mobile apps; the same patterns apply.

## Reference Tables

**WebDriver browser drivers:**
| Browser | Implementation | Source |
|---|---|---|
| Firefox | Geckodriver | github.com/mozilla/geckodriver/releases |
| Chrome | ChromeDriver | chromedriver.chromium.org/downloads |
| Internet Explorer | InternetExplorerDriver | SeleniumHQ wiki |
| Microsoft Edge | edgedriver | developer.microsoft.com |
| Opera | OperaDriver | github.com/operasoftware/operachromiumdriver |
| Safari | SafariDriver | developer.apple.com |

**Useful CSS selectors:**
| Selector | Example | Matches |
|---|---|---|
| `.class` | `.navbar` | All elements with class `navbar` |
| `#id` | `#welcome-message` | The element with that id |
| `tag` | `img` | All `<img>` elements |
| `element element` | `.navbar a` | All `<a>` **anywhere inside** `.navbar` |
| `element > element` | `.navbar-header > a` | `<a>` **directly under** `.navbar-header` |
| `[attribute=value]` | `a[href="#/book"]` | Exact attribute match |
| `[attribute^=value]` | `a[href^="#"]` | Attribute **starts with** |
| `[attribute$=value]` | `a[href$="book"]` | Attribute **ends with** |
| `[attribute*=value]` | `a[href*="book"]` | Attribute **contains** |
| `:nth-child(n)` | `.navbar li:nth-child(3)` | The third `<li>` inside `.navbar` |

**Useful XPath expressions:**
| Expression | Example | Matches |
|---|---|---|
| `node` | `a` | All `<a>` elements |
| `//node` | `//button` | All `<button>` anywhere under the root |
| `//node/node` | `//button/span` | `<span>` **directly under** a `<button>` |
| `[@attribute=value]` | `//a[@class='navbar-brand']` | Attribute **exactly** equal |
| `[contains(@attribute,value)]` | `//div[contains(@class,'navbar-header')]` | Attribute **contains** — essential because modern frameworks append extra classes |
| `node[n]` | `//div[@id='main-navbar']//li[3]` | The third `<li>` inside that div |
| `[.=value]` | `//h2[.='Flying High Frequent Flyers']` | **Text content** equals — CSS cannot do this |
| `..` | `//span[.='Singapore']/../span[contains(@class,'destination-price')]` | Navigate to a **sibling via the parent** |

**Useful WebDriver wait conditions (`ExpectedConditions`):**
| Method | Waits for |
|---|---|
| `visibilityOfElementLocated(By.id("#elt"))` | Element on the page **and** visible |
| `visibilityOfNestedElementsLocatedBy(By.id("#parent"), By.id("#elt"))` | A child element to be present and visible |
| `textToBePresentInElementLocated(By.id("elt"), "expected text")` | Specific text inside an element |
| `invisibilityOfElementLocated(By.id("#elt"))` | An element to **disappear** |
| `invisibilityOfElementWithText(By.id("#elt"), "Disappearing text")` | An element containing given text to disappear |
| `numberOfElementsToBeMoreThan(By.id("#list"), 3)` | A count of matching elements |
| `titleContains("some title")` | Page title to contain a value |
| `urlContains("/search")` | URL to contain a value |
| `alertIsPresent()` | A JavaScript alert dialog |
| `and(cond1, cond2)` | Several conditions at once |

**Element interaction methods:**
| Method | Purpose | Gotcha |
|---|---|---|
| `click()` | Simulate a mouse click — works on **any** element, not just buttons/links | — |
| `sendKeys(text)` | Simulate typing | **Does not set the value** — call `clear()` first if the field has content |
| `sendKeys(text, Keys.TAB)` | Type then press a special key | Use the `Keys` class for Enter, Tab, etc. |
| `getText()` | Text content | The way to read a `<textarea>` |
| `getAttribute("value")` | Current field value | Works for inputs, checkboxes, HTML5 types — **but not `<textarea>`** |
| `new Select(elt).selectByVisibleText/Value/Index(...)` | Drop-downs | Only for real HTML `<select>` elements |
| `Select.getFirstSelectedOption()` / `getAllSelectedOptions()` | Query drop-down state | — |

## Code Examples

**Driver setup, with a Cucumber hook:**
```java
public class AuthenticationStepDefinitions {
    WebDriver driver;

    @Before("@webtest")                          // only for scenarios tagged @webtest
    public void setupWebdriver() {
        WebDriverManager.chromedriver().setup(); // download the binary (optional in newer Selenium)
        driver = new ChromeDriver();
    }

    @After("@webtest")
    public void closeWebdriver() { driver.quit(); }
}
```

**Browser configuration:**
```java
ChromeOptions options = new ChromeOptions();
options.addArguments("start-maximized",
                     "headless",
                     "disable-extensions",
                     "disable-popup-blocking",
                     "disable-infobars");
WebDriver driver = new ChromeDriver(options);
```

**Sharing the driver across step definition classes — `ThreadLocal`, not `static`:**
```java
public class WebTestSupport {
    private static ThreadLocal<WebDriver> DRIVER = new ThreadLocal<>();

    @Before("@webtest")
    public void setupDriver() {
        WebDriverManager.chromedriver().setup();
        DRIVER.set(new ChromeDriver(options));
    }

    public static WebDriver currentDriver() { return DRIVER.get(); }

    @After("@webtest")
    public void closeDriver() { DRIVER.get().quit(); }
}
```
A plain `static` field "will not work if you ever want to run your features or scenarios in parallel." Since each scenario runs in its own thread, `ThreadLocal` gives one driver per scenario, shared across all that scenario's step definitions.

**Test-friendly HTML with `data-testid`:**
```html
<div class="login-container">
    <form [formGroup]="form" (submit)="login(form)">
        <mat-form-field appearance="fill">
            <mat-label>Email</mat-label>
            <input id="email" data-testid="email">
        </mat-form-field>
        <mat-form-field appearance="fill">
            <mat-label>Password</mat-label>
            <input id="password" data-testid="password">
        </mat-form-field>
        <button type="submit" data-testid="login">Login</button>
    </form>
</div>
```

**Radio buttons and checkboxes** — three approaches, because `name` isn't unique and `id` isn't always related to the value:
```java
// (a) combine name (the group) with value
driver.findElement(By.cssSelector("input[name='seatPreference'][value='aisle']")).click();

// (b) click the label instead
driver.findElement(By.xpath("//label[.='Window']")).click();

// (c) build the selector from persona data
String seatPreference = String.format("//label[.='%s']", newMember.getSeatPreference());
driver.findElement(By.xpath(seatPreference)).click();
```

**Explicit wait, chaining into the returned element:**
```java
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(5));
String successMessage = wait.until(visibilityOfElementLocated(   // static import for fluency
                                   By.cssSelector(".toast-success")))
                            .getText();

assertThat(successMessage).isEqualTo("Logged in as " + newMember.getEmail());
```

**Fluent wait with a custom condition:**
```java
Wait<WebDriver> wait = new FluentWait<>(driver)
    .withTimeout(Duration.ofSeconds(30))         // wait up to 30s
    .pollingEvery(Duration.ofSeconds(1))         // check every second
    .ignoring(NoSuchElementException.class);     // don't fail while it's still absent

wait.until(driver -> driver.findElement(By.cssSelector(".toast-success"))
                           .getText()
                           .contains("@traveler.com"));
```
A condition is a Java 8 `Function` returning either a `WebElement` (waiting for an element) or a `Boolean` (waiting for a general condition).

## Worked Example

**Scraping the featured destinations — narrowing a CSS selector step by step.**

The scenario:
```gherkin
Scenario: Displaying featured destinations
  Given Jane has logged on
  When Jane views the home page
  Then she should see 3 featured destinations
  And the featured destinations should include Singapore
```

The rendered HTML:
```html
<div id="featured">
    <div class="featured-destination">
        <img src="img/singapore.png"></img>
        <span class="destination-title">Singapore</span>
        <span class="destination-price">$900</span>
    </div>
    <div class="featured-destination">...</div>
    <div class="featured-destination">...</div>
</div>
```

*Counting is easy:*
```java
List<WebElement> destinations = driver.findElements(By.cssSelector(".featured-destination"));
assertThat(destinations).hasSize(3);
```

*Getting titles — first attempt is too broad:*
```java
driver.findElements(By.cssSelector(".destination-title"));
```
"This would work, but it may not be robust. **If destination titles were used elsewhere on the page, you'd retrieve too many titles.**"

*Scoped to the container:*
```java
List<WebElement> destinations
  = driver.findElements(By.cssSelector("#featured .destination-title"));
List<String> destinationTitles = new ArrayList<String>();
for (WebElement destinationElement : destinations) {
    destinationTitles.add(destinationElement.getText());
}
assertThat(destinationTitles).contains("Singapore");
```

*The XPath equivalents, and why `contains()` matters:*
```java
driver.findElements(By.xpath("//span[@class='destination-title']"));   // exact class match
driver.findElements(By.xpath("//*[@class='destination-title']"));      // any tag, exact match
driver.findElements(By.xpath("//*[contains(@class,'destination-title')]"));  // ← use this
```
"Modern web applications will sometimes **add extra classes** to the `class` attribute, so you can't rely on an exact match."

*And where XPath genuinely beats CSS — matching on content, then navigating relative to it:*
```java
//span[.='Singapore']                                                     // find by text
//span[.='Singapore']/../span[contains(@class,'destination-price')]       // its sibling price
```
"The full power of XPath becomes more apparent when you need to find elements based on their content — something that's not currently supported in CSS."

**Automating a non-standard UI component (Angular Material).**

The `Title` field *looks* like a `<select>` but isn't:
```html
<mat-select role="listbox" id="title" data-testid="title">...</mat-select>
```
Clicking it dynamically injects options into the DOM:
```html
<div class="mat-select-panel-wrap">
    <div class="mat-select-panel mat-primary" id="title-panel">
        <mat-option role="option" value="Mr" class="mat-option">
            <span class="mat-option-text">Mr</span>
        </mat-option>
        <mat-option role="option" value="Ms" class="mat-option">...</mat-option>
        <mat-option role="option" value="Mrs" class="mat-option">...</mat-option>
    </div>
</div>
```
So it's a **two-click** interaction:
```java
driver.findElement(By.id("title")).click();                                   // 1. open it

// 2a. by the value attribute
driver.findElement(By.cssSelector("mat-option[value='Mr']")).click();

// 2b. or by displayed text, if the value isn't human-readable
driver.findElement(By.xpath("//*[@class='mat-option-text'][.='Mr']")).click();

// 2c. driven from persona data
String titleOption = String.format("mat-option[value='%s']", newMember.getTitle());
driver.findElement(By.cssSelector(titleOption)).click();
```
**The lurking bug**: "the dropdown list may not appear immediately. It may retrieve the list from a backend service… the code we just wrote may fail because the dropdown list entry it is looking for hasn't been populated yet." → this is exactly what waits are for.

**The full login step definition — and why it's the wrong shape.**

The scenario:
```gherkin
Business Need: Authentication
  Registered Frequent Flyer members can access their account using their email and password

  @webtest
  Example: Tracy successfully logs on to the Frequent Flyer app
    Given Tracy is a registered Frequency Flyer member
    When Tracy logs on with a valid username and password
    Then she should be given access to her account
```

Test data as an enum (a lightweight alternative to HOCON personas):
```java
public enum FrequentFlyer {
    Tracy("tracy@flyinghigh.com", "trac3");

    public final String email;
    public final String password;

    FrequentFlyer(String email, String password) {
        this.email = email;
        this.password = password;
    }
}

@Given("{} is a registered Frequency Flyer member")
public void frequentFlyerMember(FrequentFlyer frequentFlyer) {
    this.frequentFlyer = frequentFlyer;
}
```

The interaction step:
```java
@When("{} logs on with a valid username and password")
public void logsOnWithAValidUsernameAndPassword() {
    WebDriver driver = WebTestSupport.currentDriver();
    driver.get("http://localhost:3000");                                     // open the app
    driver.findElement(By.linkText("Login")).click();                        // go to login
    driver.findElement(By.id("email")).sendKeys(frequentFlyer.email);
    driver.findElement(By.id("password")).sendKeys(frequentFlyer.password);
    driver.findElement(By.id("login-button")).click();
}
```

And the assertion — note the `he/she` alternation from ch 8:
```java
@Then("he/she should be given access to his/her account")
public void shouldBeGivenAccessToTheAccount() {
    WebDriver driver = WebTestSupport.currentDriver();
    String currentUser = driver.findElement(By.id("current-user")).getText();
    assertThat(currentUser).isEqualTo(frequentFlyer.email);
}
```

**Now the critique.** A fuller version of the same idea:
```java
@Then("{} should be able to log on to the Frequent Flyer application")
public void shouldBeAbleToLoginAs(String name) {
    WebDriver driver = WebTestSupport.currentDriver();
    driver.get("http://localhost:3000/login");
    driver.findElement(By.id("email")).sendKeys(newMember.getEmail());
    driver.findElement(By.id("password")).sendKeys(newMember.getPassword());
    driver.findElement(By.id("login-button")).click();

    WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(5));
    String successMessage = wait.until(visibilityOfElementLocated(
                                       By.cssSelector(".toast-success"))).getText();
    assertThat(successMessage).isEqualTo("Logged in as " + newMember.getFirstName());
}
```

The book's four specific objections — worth memorizing as a review checklist:
1. **The WebDriver API is exposed in the test logic** → the test is tightly coupled to WebDriver. Switching to API calls or another technology means major changes.
2. **The URL is hard-coded** → can't run against a remote server.
3. **Locators are embedded in the test** → if other steps use the same elements, they're maintained in several places.
4. **Implementation details leak** (the need to wait for a Toastr message) that are irrelevant to the requirement.

The Screenplay version (ch 12) of the same step:
```java
@Then("{} should be able to log on to the Frequent Flyer application")
public void shouldBeAbleToLoginAs(Actor frequentFlyer) {
    frequentFlyer.attemptsTo(Login.usingTheirCredentials());
    frequentFlyer.should(
            seeThat(the(LOGIN_NOTIFICATION_MESSAGE),
                    containsText("Logged in as " + frequentFlyer.getName()))
    );
}
```

**Screen-specific rules that *do* belong in UI tests** — a duplicate-email check on a specific screen:
```gherkin
Rule: Duplicate usernames are not allowed

  Example: Someone tries to register with an email that is already used
  Mike Smith is an existing Frequent Flyer member.
  His wife Jenny Smith does not have a Frequent Flyer account

    Given Mike Smith is a Frequent Flyer member with the following details:
      | username | smiths@example.org |
      | password | correct-password   |
    When Jenny tries to register with a username of "smiths@example.org"
    Then she should be presented with an error message containing "Email exists, please try another name"
    And she should also be presented with a "Forgot your password?" link
```
"This is not really a full user journey; it **checks a specific business rule on a specific screen**. The logical way to implement this scenario would be via the user interface."

**Table-driven UI checks** for things Gherkin doesn't express naturally — mandatory fields:
```gherkin
Rule: Registering members need to complete all the mandatory fields
  Scenario: Mandatory fields for registration
    Given Candy does not have a Frequent Flyer account
    When she wants to register a new Frequent Flyer account
    Then the following information should be mandatory to register:
      | Field     | Error Message If Missing     |
      | email     | Please enter your email      |
      | password  | Please enter your password   |
      | firstName | Please enter your first name |
      | lastName  | Please enter your last name  |
      | address   | Please enter your address    |
      | country   | Please enter a valid country |
```

**Bullet-point Gherkin** for a journey scenario, when Given/When/Then feels "clunky and artificial":
```gherkin
Scenario: Tara books a flight from London to New York
  * Tara is a registered Frequent Flyer member
  * She searches for one-way flights from London to New York in Economy
  * She books the first available flight
  * She should be informed that her booking was successful
  * The booking appears in her My Booking section
```

## Mental Models

- **Mix UI and backend interactions within one journey scenario.** "Suppose that the registration feature has already been tested in another scenario. In that case we could implement the first step, 'Given Tara is a registered Frequent Flyer member,' with an **API call** rather than by registering via the web interface."
- **Stakeholders trust UI tests more** — "they reproduce end-user behavior well… Many stakeholders have a natural tendency to trust them for this reason." That trust is an argument for having *some*, not all.
- **Screenshots are documentation.** "The screenshots from automated web tests can be a valuable aid for testers, and they're also a great way to provide illustrated documentation."
- **Testability is an application design property, not a test-writing skill.** "Applications with clean HTML code, identifiers, names, and CSS classes for all the significant elements on a page make testing easier and more reliable." Frameworks that auto-generate element identifiers (many JSF-based ones) or use opaque plug-ins (Flash, Silverlight) make testing very difficult. **Your stack choice is a testability decision.**
- **Keep expressions simple.** "Simpler expressions tend to be easier to understand and to maintain, and in many cases they're more reliable."
- **Prefer `contains()` over exact class matching** — modern frameworks append classes at runtime.

## Anti-patterns

- **Testing everything through the UI**: slows the suite without adding proportionate confidence.
- **One web test per invalid input**: "we wouldn't want to test them all via the user interface — that would lead to a large number of web tests that would slow down the test suite."
- **Verifying an algorithm (password strength) by submitting values through a form**: "that would be wasteful."
- **Raw WebDriver calls inside step definitions**: couples tests to WebDriver, hard-codes URLs, scatters locators, and leaks timing details.
- **`static WebDriver` shared across step definitions**: breaks under parallel execution; use `ThreadLocal`.
- **Relying on `id`/`name` when you control the HTML**: `data-testid` is decoupled from JS event handling and form semantics.
- **Exact `@class` matching in XPath**: frameworks add classes; use `contains()`.
- **Unscoped CSS selectors** (`.destination-title` with no container): silently picks up matches elsewhere on the page.
- **Interacting immediately after an AJAX-triggering action**: the element may not exist yet. Also applies to *animations*, not just data loads.
- **`sendKeys()` on a populated field**: it appends; call `clear()` first.
- **`getAttribute("value")` on a `<textarea>`**: it has no value attribute; use `getText()`.
- **XPath-heavy suites targeting Internet Explorer**: no native XPath support means very slow tests.

## Key Takeaways
1. Reserve UI tests for journeys, presentation, rendering, and screen-specific logic — everything else goes lower and runs faster.
2. Ask "am I testing interaction, or interaction-independent logic?" and route the test accordingly, even for two criteria on the same feature.
3. Prove the UI path with two or three examples, then cover the exhaustive cases with a looping table step or unit tests.
4. Add `data-testid` attributes to your application — testability is something you build in, not something you work around.
5. Prefer CSS selectors for speed and readability; reach for XPath only for content matching and relative navigation.
6. Scope selectors to a container, and use `contains(@class, ...)` rather than exact class equality.
7. Use nested `findElement()` calls instead of one clever complex selector.
8. Share the driver via `ThreadLocal`, never `static`, so parallel execution stays possible.
9. Wait explicitly for AJAX updates *and* animations; chain off the element `wait.until()` returns.
10. Treat raw-WebDriver step definitions as a tutorial-only style — audit them for the four coupling problems and refactor into layers.

## Connects To
- **Ch 8**: hooks and tags — the `@Before("@webtest")` mechanism used throughout.
- **Ch 9**: the layered architecture whose absence this chapter's final critique demonstrates; personas and HOCON reappear here.
- **Ch 11**: test automation design patterns for the UI layer — the fix for the four coupling problems.
- **Ch 12**: the Screenplay Pattern, previewed in the final code comparison.
- **Ch 14–15**: Serenity/JS and portable test automation.
- **Selenium WebDriver, W3C WebDriver Spec, Selenium Grid, SauceLabs, BrowserStack, Appium, WebDriverManager, AssertJ, Angular Material, Toastr, Cypress**: tools referenced. Higher-level WebDriver wrappers named: Serenity BDD and Selenide (Java), Serenity/JS, Protractor, Webdriver.io (JavaScript), Watir (Ruby), Geb (Groovy).
