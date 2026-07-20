# Chapter 8: From Executable Specifications to Automated Acceptance Tests

## Core Idea
Step definitions ("glue code") bind scenario text to automation code. The craft is in **pushing conversion and setup out of the step body** — via Cucumber Expressions, custom `@ParameterType`s, `@DataTableType`s, hooks, and containerized environments — so step definitions stay one or two readable lines.

## Frameworks Introduced

- **The Automation Decision** — not every scenario should be automated. The book's filter:
  | Scenario kind | Where it belongs |
  |---|---|
  | Too tricky to automate cost-effectively | Manual testing |
  | Only marginally interesting to the business | Unit or integration test |
  | Experimental / not yet understood | Prototype first; formalize later |
  | Everything else | Automate |
  - Payoffs when you do automate: testers spend less time on repetitive regression (and trust the suite because they *helped define it*); releases go out faster and more reliably; the scenarios become an accurate project dashboard.

- **Two-stage terminology**: a Gherkin scenario becomes an **executable specification** the moment it's in the suite (reported as *pending*). It becomes an **automated acceptance test** only once the underlying code that exercises the application exists.

- **Background vs. Hooks — the business-visibility rule.** This is the chapter's key architectural distinction:
  | | `Background:` | Hook (`@Before` / `@After`) |
  |---|---|---|
  | Audience | **Business facing and business readable** | Hidden from business readers |
  | Contains | Only information business readers care about | Low-level housekeeping |
  | Examples | Points schedules, status multipliers, reference data the rules depend on | Opening a browser, resetting a DB schema, deleting test data, starting containers |
  - Rule: "Background steps are designed to be business facing and business readable: they should only contain information that business readers care about."

- **The hook lifecycle:**
  | Hook | Runs | Notes |
  |---|---|---|
  | `@Before` / `Before(...)` | Before each scenario | The most common; reinitialize DB, seed reference data |
  | `@After` / `After(...)` | After each scenario | Cleanup; can take a `Scenario` param for name/status |
  | `@Before("@tag")` | Before each *tagged* scenario | Takes a **tag expression**: `@web`, `@web and @smoketest`, `@web and not @backend` |
  | `@BeforeAll` / `@AfterAll` | Once per run | Java support added in **Cucumber 7**; TypeScript has had it |
  | `EventListener` | Test run start/finish | Cleaner and more modular than static variables |
  - **Thread-safety warning**: `@BeforeAll` with a static variable "may not be thread safe. This means that if you are running your tests in parallel, you may run into trouble." Prefer an `EventListener`, or wrap shared state in `ThreadLocal`.

- **Progressive scenario layering with `Background`** — the recommended feature-file shape:
  1. `Background:` establishes the reference data (points schedule, multipliers).
  2. First scenario: the simplest case (route + cabin class).
  3. Second: one more variable (cabin class effect), as a `Scenario Outline`.
  4. Third: another variable (status level effect).
  Each scenario "builds on" and "develops and explores business rules and constraints" from the previous.

## Key Concepts

- **Step definition method** — the glue-code method Cucumber invokes for a given scenario line.
- **Cucumber Expression** — the `{...}` placeholder syntax in a step annotation. Modern replacement for regexes.
- **Anonymous type `{}`** — matches any expression and converts to whatever parameter type the method declares. Works with enums and most basic types.
- **`@ParameterType`** — declares a custom domain type; the name derives from the method name (or the `name` attribute). Can live in step definition classes or any glue-code class.
- **`@DataTableType`** — tells Cucumber how to convert one table row (given as a `Map<String,String>`) into a domain object, so the step definition can take a `List<DomainObject>` directly.
- **`DataTable`** — Cucumber's default table class; `.asMaps()` yields rows as maps. Works, but the book calls the resulting code "not very readable and more complex than we would typically expect."
- **Tag expression** — a single tag or a logical combination (`and`, `not`), used in runner config, CLI flags, and hooks.
- **TestContainers** — a library that spins up Docker containers (databases, Kafka, Elasticsearch, RabbitMQ) for tests.

## Reference Tables

**Built-in Cucumber Expression types:**
| Type | Description | Example |
|---|---|---|
| `{int}` | Whole number | `There are {int} remaining tasks` |
| `{float}` | Floating-point number | `The box weighs {float} kg` |
| `{word}` | A single word, no whitespace | `She buys a {word} jersey` |
| `{string}` | String in double quotes | `She flies to {string}` → `She flies to "New York"` |
| `{}` | **Anonymous** — matches anything; converts to the declared param type | `She flies to {}` |
| `{biginteger}` | `BigInteger` (JVM only) | `A population of {biginteger}` |
| `{bigdecimal}` | `BigDecimal` | `A total value of {bigdecimal}` |
| `{byte}` `{short}` `{long}` `{double}` | Corresponding primitives | `There are {long} apples` |

**Cucumber Expression flexibility syntax:**
| Syntax | Effect | Example |
|---|---|---|
| `(s)` | Optional text | `for {int} year(s)` matches "1 year" and "5 years" |
| `(s)he` | Optional prefix | Matches both "she" and "he" |
| `member/customer` | Alternative words (no whitespace) | Matches "member" or "customer" |

**Common regular expressions in step definitions:**
| Regex | Description | Example |
|---|---|---|
| `.*` | Any sequence, including nothing | `^(.*) is a frequent flyer` |
| `.+` | One or more characters | `^(.+) is a frequent flyer` |
| `\d+` | One or more digits | `Tara is (\d+) years old` |
| `\d{n}` | Exactly n digits | `In the year \d{4}` |
| `(a\|b\|c)` | Any listed value | `The status is (red\|amber\|green)` |
| `?` | Optional character | `s?he purchases a ticket` |
| `(?:x\|y)` | **Non-capturing** group — matched but not passed to the method | `Tara (?:buys\|has bought) a ticket` |
| `^` | Start of string; some Cucumber versions use it to detect regex mode | — |
| `(...)` | Capturing group → becomes a parameter | — |

**Project layout — Java (Maven conventions):**
| Path | Contents |
|---|---|
| `src/main/java` | Application code (may be absent in a multi-module setup where tests are their own module) |
| `src/test/java/.../AcceptanceTestSuite.java` | Runner class |
| `src/test/java/.../stepdefinitions/` | Glue code |
| `src/test/java/.../domain/` | Test framework support code |
| `src/test/resources/features/` | Feature files, grouped by capability |

**Project layout — TypeScript (Cucumber JS conventions):**
| Path | Contents |
|---|---|
| `src/` | Application code (Node conventions vary far more than Java's) |
| `features/` | Feature files |
| `features/step_definitions/` | Step definition libraries |
| `features/support/` | Config, parameter type definitions |
- Cucumber JS scans **all** `.ts`/`.js` files under `features/` for step definitions — the subfolder names are convention only, but IDEs expect them for navigation support.

## Code Examples

**The same step definition in three languages:**
```java
// Java — Cucumber
FlightDatabase flightDatabase = FlightDatabase.instance();

@Given("the distance from {} to {} is {int} km")
public void recordFlightDistance(String departure, String destination, int distanceInKm) {
    flightDatabase.recordTripDistance()
                  .from(departure).to(destination)
                  .as(distanceInKm).kilometres();
}
```
```typescript
// TypeScript — Cucumber JS
const flightDatabase = FlightDatabase.instance();

Given('the distance from {} to {} is {int} km',
      function (origin: string, destination: string, distanceInKm: number) {
    flightDatabase.recordTripDistance()
                  .from(origin).to(destination)
                  .as(distanceInKm).kilometres()
})
```
```csharp
// C# — SpecFlow (regex style)
[Given(@"the flying distance between (.*) and (.*) is (.*) km")]
public void DefineTheFlyingDistanceForATrip(string departure, string destination, int distance)
{
    flightDatabase.recordTripDistance()
                  .from(departure).to(destination)
                  .as(distance).kilometres();
}
```

**Java runner class with `@CucumberOptions`:**
```java
@RunWith(CucumberWithSerenity.class)
@CucumberOptions(
    features = "classpath:features",                                // where feature files live
    tags = "@important",                                            // limit execution to a subset
    glue = "com.manning.bddinaction.frequentflyer.stepdefinitions", // where glue code lives
    plugin = {"pretty", "json:target/cucumber.json"}                // console output + JSON results
)
public class AcceptanceTestSuite {}
```
The bare `@RunWith(Cucumber.class)` form works but searches the runner's own package for features — "in practice this can be a little confusing and make the feature files harder to find."

**Cucumber JS invocation and profile:**
```bash
npx cucumber-js \
    --require-module ts-node/register \    # run TypeScript without pre-transpiling
    --require 'features/**/*.ts' \         # scan for step definitions and hooks
    --tags '@important and not @wip' \     # tag expression
    'features/**/*.feature'
```
Capture the flags in a profile — Cucumber JS finds this automatically:
```javascript
// cucumber.js
module.exports = {
    default: `--require-module ts-node/register --require 'features/**/*.ts'`,
}
```
Then wire it to npm:
```json
"scripts": {
  "test": "cucumber-js 'features/**/*.feature'"
}
```
```bash
npm test
npm test -- --name='Flights outside Europe'      # the -- passes args through to Cucumber
npm test -- --tags='@important and not @wip'
npx cucumber-js --help
```

**Custom parameter type — returning a domain object:**
```java
@ParameterType("(Standard|Silver|Bronze|Gold) Frequent Flyer member")
public FrequentFlyerMember frequentFlyer(String statusName) {
    FrequentFlyerStatus status = FrequentFlyerStatus.valueOf(statusName);
    return FrequentFlyerMember.withStatus(status);
}

@Given("{} is a {frequentFlyer}")
public void aFrequentFlyerMember(String name, FrequentFlyerMember member) {
    this.member = member.named(name);
}

// …and it composes into other steps for free:
@Given("{} is a {frequentFlyer} with {int} points")
public void aFrequentFlyerMemberWithPoints(String name, FrequentFlyerMember member, int points) {
    this.member = member.named(name).withPoints(points);
}
```

**Custom parameter type with an explicit name and regex (dates):**
```java
@ParameterType(name = "ISO-date", value = "(\\d{4}-\\d{2}-\\d{2})")
public LocalDate isoDate(String formattedDate) {
    return LocalDate.parse(formattedDate);
}

@Given("{} joined the Frequent Flyer programme on {ISO-date}")
public void justJoined(String name, LocalDate date) {...}
```
Use the `name` attribute when the type name can't be a valid Java method name.

**Parameter type for an inline list:**
```java
@ParameterType(name = "string-values", value = "(.*)")
public List<String> stringValues(String destinationList) {
    return Stream.of(destinationList.split(","))
                 .map(String::trim)
                 .collect(Collectors.toList());
}

@Then("the available destinations should be {string-values}")
public void availableDestinations(List<String> destinations) {...}
```
Lets `Then the available destinations should be Berlin, Paris, New York` read naturally instead of requiring a table. *(A single-column table maps to `List<String>` automatically with no extra work.)*

**`DataTable` — the verbose way:**
```java
@When("{} asks for the following flight to be credited to his account:")
public void creditFlights(String name, DataTable flights) {
    List<PastFlight> requestedFlights = flights.asMaps()
            .stream()
            .map(row -> new PastFlight(
                    row.get("Flight Number"),
                    LocalDate.parse(row.get("Date")),
                    FlightStatus.valueOf(row.get("Status"))))
            .collect(Collectors.toList());
    ...
}
```

**`@DataTableType` — the clean way. Extract the conversion once:**
```java
public record PastFlight(String flightNumber, LocalDate scheduledDate, FlightStatus status) {}

@DataTableType
public PastFlight mapRowToPastFlight(Map<String, String> entry) {
    return new PastFlight(entry.get("Flight Number"),
                          LocalDate.parse(entry.get("Date")),
                          FlightStatus.valueOf(entry.get("Status")));
}

// Now the step definition takes domain objects directly:
@When("{word} asks for the following flight to be credited to his account:")
public void creditFlights(String name, List<PastFlight> requestedFlights) { ... }
```

**Handling tables where the relevant columns vary by scenario** — supply defaults for absent columns:
```java
@DataTableType
public PastFlight mapRowToPastFlight(Map<String, String> entry) {
    return new PastFlight(
            optional(entry.get("Flight Number"), "FT-101"),
            LocalDate.parse(optional(entry.get("Date"), "2020-10-01")),
            FlightStatus.valueOf(optional(entry.get("Status"), "COMPLETED")),
            isDelayed(entry),
            delayDurationOf(entry));
}

private <T> T optional(T cellValue, T defaultValue) {
    return Optional.ofNullable(cellValue).orElse(defaultValue);
}

private Boolean isDelayed(Map<String, String> entry) {
    if (entry.get("Delayed") == null) { return false; }
    return entry.get("Delayed").equalsIgnoreCase("Yes");
}

private Duration delayDurationOf(Map<String, String> entry) {
    if (entry.get("Delayed By") == null) { return Duration.ZERO; }
    return Duration.parse("PT" + entry.get("Delayed By"));
}
```
Alternative noted by the book: "some teams use a JSON or Excel template file to contain the default values, and only update the fields specified in the table."

**Hooks — general, tagged, and lifecycle:**
```java
@Before
public void prepareStaticData() {
    FlightDatabase.instance().setupAirports();
    FlightDatabase.instance().initialiseDefaultFlightPlans();
}

@After
public void logScenarioResult(Scenario scenario) {
    System.out.println(scenario.getName() + ":" + scenario.getStatus());
}

WebDriver driver;

@Before("@web")                       // only for scenarios tagged @web
public void prepareDriver() { driver = new ChromeDriver(); }

@After("@web")
public void closeBrowser() { driver.quit(); }
```
```typescript
Before(async function () {
    await FlightDatabase.instance().setupAirports();
    await FlightDatabase.instance().initialiseDefaultFlightPlans();
});

Before({ tags: '@web' }, function () { driver = new ChromeDriver(); });
After({ tags: '@web' }, async function () { await driver.close(); });

let dbContainer: StartedTestContainer;
BeforeAll({ timeout: 10 * 1000 }, async () => {          // default timeout is 5s
    dbContainer = await new DatabaseContainer(dbConfig).start();
});
AfterAll(async () => { await dbContainer.stop(); });
```
All Cucumber JS step functions and hooks support async functions returning `Promise`s.

**`EventListener` — the thread-safe alternative to `@BeforeAll` + static state:**
```java
public class DatabaseServerHandler implements EventListener {
    @Override
    public void setEventPublisher(EventPublisher eventPublisher) {
        eventPublisher.registerHandlerFor(TestRunStarted.class, event -> {
            TestDatabase.instance().startServer();
            TestDatabase.instance().initialiseDefaultFlightPlans();
        });
        eventPublisher.registerHandlerFor(TestRunFinished.class, event -> {
            TestDatabase.instance().stopServer();
        });
    }
}
```
Register it via the `plugin` attribute:
```java
@CucumberOptions(
        plugin = {"com.manning.bddinaction.plugins.DatabaseServerHandler"},
        features = "classpath:features"
)
public class AcceptanceTestSuite {}
```

**TestContainers — Docker environments per test run:**
```groovy
testCompile "org.testcontainers:testcontainers:1.15.0-rc2"
testCompile "org.testcontainers:postgresql:1.15.0-rc2"
```
```java
PostgreSQLContainer container = new PostgreSQLContainer("postgres:13.0")
        .withDatabaseName("integration-tests-database")
        .withUsername("sa")
        .withPassword("sa");

container.start();                       // downloads the image if needed
String jdbcUrl = container.getJdbcUrl();
```
Thread-safe encapsulation for parallel runs:
```java
public class TestDatabase {
    private static ThreadLocal<PostgreSQLContainer> container
            = ThreadLocal.withInitial(
            () -> new PostgreSQLContainer("postgres:11.1")
                    .withDatabaseName("integration-tests-db")
                    .withUsername("sa")
                    .withPassword("sa"));

    public static PostgreSQLContainer getInstance() {
        container.get().start();
        return container.get();
    }
}
```
Injecting the dynamically allocated address into Spring Boot — "one of the most challenging aspects":
```java
@SpringBootTest
@ContextConfiguration
public class EarningPointsStepDefinitions {

    @DynamicPropertySource
    static void properties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url",      TestDatabase.getInstance()::getJdbcUrl);
        registry.add("spring.datasource.username", TestDatabase.getInstance()::getUsername);
        registry.add("spring.datasource.password", TestDatabase.getInstance()::getPassword);
    }

    @Autowired PointsScheduleRepository pointsScheduleRepository;

    @Given("the following flight points schedule:")
    public void setupFlightPointsSchedule(List<PointsSchedule> pointsSchedules) {
        pointsScheduleRepository.deleteAll();
        pointsSchedules.forEach(pointsScheduleRepository::save);
    }
}
```

## Worked Example

**A feature file layered on a `Background`, and the glue code behind it.**

The business context: points depend on route, cabin class, and status. Marketing sets the per-route points. Silver members earn +50%, Gold members double.

The reference data goes in `Background` because *the business cares about it* — these numbers are the rules:
```gherkin
Feature: Earning Frequent Flyer points from flights
  In order to improve customer loyalty
  As an airline sales manager
  I want travelers to earn frequent flyer points when they fly with us

  Background:
    Given the following flight points schedule:
      | From     | To          | Class    | Points |
      | London   | New York    | Economy  | 550    |
      | London   | New York    | Business | 800    |
      | London   | New York    | First    | 1650   |
      | New York | Los Angeles | Economy  | 100    |
      | New York | Los Angeles | Business | 140    |
      | New York | Los Angeles | First    | 200    |
    And the following flyer types multipliers:
      | Status   | Multiplier |
      | Standard | 1.0        |
      | Silver   | 1.5        |
      | Gold     | 2.0        |
```

Scenario 1 — the simplest possible case, one variable:
```gherkin
  Scenario: Travelers earn points depending on the points schedule
    Given Stacy is a Standard Frequent Flyer member
    When she flies from London to New York in Economy class
    Then she should earn 550 points
```

Scenario 2 — adds cabin class, with a `Notes` column naming what each row exercises:
```gherkin
  Scenario Outline: Travelers earn more points in higher cabin classes
    Given Silvia is a Silver Frequent Flyer member
    When she flies from <From> to <To> in <Cabin> class
    Then she should earn <Points Earned> points

    Examples:
      | From     | To          | Cabin    | Points Earned | Notes             |
      | London   | New York    | Economy  | 550           | International leg |
      | New York | Los Angeles | Business | 800           | Domestic leg      |
      | New York | London      | First    | 1650          | Return trip       |
```

Scenario 3 — isolates the status multiplier by holding cabin class fixed:
```gherkin
  Scenario Outline: Higher frequent flyer status levels earn more points
    Given Tracy is a <Status> Frequent Flyer member
    When she flies from <From> to <To> in Business class
    Then she should earn <Points Earned> points

    Examples:
      | From     | To          | Status   | Points Earned |
      | London   | New York    | Standard | 800           |
      | New York | Los Angeles | Silver   | 210           |
      | New York | London      | Gold     | 1600          |
```

And the glue — note the background step's definition is written **exactly like any other step**; "for Cucumber, it makes no difference whether a step appears in a background step or in an ordinary scenario":
```java
@DataTableType
public PointsSchedule pointsSchedule(Map<String, String> row) {
    return PointsSchedule.from(row.get("From"))
                         .to(row.get("To"))
                         .flyingIn(CabinClass.valueOf(row.get("Class")))
                         .earns(Integer.parseInt(row.get("Points")));
}

@Given("the following flight points schedule:")
public void theFollowingFlightPointsSchedule(List<PointsSchedule> pointSchedules) {
    flightDatabase.addPointSchedules(pointSchedules);
}
```

**The refactoring arc from hard-coded to parameterized.** Watch duplication get eliminated in four steps.

*Step 1 — hard-coded, one method per value:*
```java
@Given("Tara is a Standard Frequent Flyer member")
public void aStandardFrequentFlyerMember() {
    member = FrequentFlyerMember.named("Tara").withStatus(FrequentFlyerStatus.Standard);
}

@Given("Tara is a Silver Frequent Flyer member")   // a whole second method for one word
public void aSilverFrequentFlyerMember() {
    member = FrequentFlyerMember.named("Tara").withStatus(FrequentFlyerStatus.Silver);
}
```
"Of course, this is wasteful."

*Step 2 — `{word}` parameters, but manual conversion in the body:*
```java
@Given("{word} is a {word} Frequent Flyer member")
public void aFrequentFlyerMember(String name, String status) {
    FrequentFlyerStatus statusLevel = FrequentFlyerCategory.valueOf(status);
    member = FrequentFlyerMember.named(name).withStatus(statusLevel);
}
```

*Step 3 — anonymous `{}` lets Cucumber do the enum conversion:*
```java
@Given("{word} is a {} Frequent Flyer member")
public void aFrequentFlyerMember(String name, FrequentFlyerStatus status) {
    member = FrequentFlyerMember.named(name).withStatus(status);
}
```

*Step 4 — a custom `{frequentFlyer}` type moves construction out entirely, and now composes:*
```java
@Given("{} is a {frequentFlyer}")
public void aFrequentFlyerMember(String name, FrequentFlyerMember member) {
    this.member = member.named(name);
}
```
Each step, the step definition body gets shorter and the domain vocabulary gets richer.

**Generating step definitions.** Run a scenario with no glue and Cucumber prints snippets:
```
$ mvn verify
...
There were undefined steps. You can implement missing steps with the snippets below:

@Given("Tara is a Frequent Flyer traveler")
public void tara_is_a_Frequent_Flyer_traveler() {
    // Write code here that turns the phrase above into concrete actions
    throw new cucumber.api.PendingException();
}
```
IntelliJ IDEA and Eclipse (with the Cucumber Eclipse plug-in) generate these from the contextual menu. But **the snippets are a starting point only**: "they may miss parameters, and at the very least, you will need to make parameter names more readable."

## Mental Models

- **Automation tests are code, not scripts.** "It's when we think of them as simple scripts, things that can be easily and quickly written with little skill or care involved, that we get into trouble." Badly designed suites cost more to maintain than they contribute.
- **The scenario says *what*; the step definition decides *how*.** `Given the distance from London to New York is 5500 km` could inject into a test DB, call a web service, or drive a UI — the text doesn't care.
- **Free text on both sides means drift.** Change a feature file and forget the annotation (or vice versa) and the scenario silently goes *pending*. IDE plug-ins that navigate scenario↔definition and highlight unmatched steps are the mitigation.
- **Zawinski's law on regexes**: "Some people, when confronted with a problem, think, 'I know, I'll use regular expressions.' Now they have two problems." Cucumber Expressions exist to reduce your exposure — but regexes still matter for `@ParameterType` definitions and legacy suites.
- **Grammar is a communication feature, not pedantry.** "she has been a member for 1 years" distracts the reader from the business intent. `year(s)` and `(s)he` cost nothing and remove friction.
- **In-memory DBs (H2, HSQLDB) vs. containers**: in-memory is fast to create and destroy, so each scenario gets fresh data — but breaks on proprietary types, stored procedures, message queues, NoSQL, and distributed caches. Containers solve that.
- **Shared test environments are a bottleneck, not a shortcut.** "Running tests this way locally is difficult, and having to deploy into a specific environment to test slows down feedback cycles and creates bottlenecks. In addition, these environments can be unstable" — deployments and manual testers interrupt runs.
- **Container startup is cheap enough not to optimize prematurely.** "Spinning up a TestContainers instance is generally so quick that it is perfectly feasible to use a new instance for each test."

## Anti-patterns

- **A step definition method per literal value** (`aStandardFrequentFlyerMember`, `aSilverFrequentFlyerMember`, …): parameterize instead.
- **Conversion logic inside step definition bodies**: `DataTable.asMaps().stream().map(...)` belongs in a `@DataTableType`.
- **Technical setup in `Background`**: opening browsers and resetting schemas are hooks, not business-readable context.
- **Opening a browser for every scenario when only some need one**: use `@Before("@web")`.
- **`@BeforeAll` + static mutable state with parallel execution**: not thread safe; use an `EventListener` or `ThreadLocal`.
- **Scenarios that depend on a previous scenario having seeded data**: hooks that reinitialize the schema per scenario are what make independence real.
- **Pasting generated snippets unmodified**: they miss parameters and have unreadable parameter names.
- **Treating a dedicated shared test environment as the answer**: slow feedback, local runs hard, unstable under concurrent use.

## Key Takeaways
1. Decide deliberately what to automate — some scenarios belong in manual testing, unit tests, or a prototype instead.
2. Keep step definition bodies to one or two lines by pushing conversion into `@ParameterType` and `@DataTableType` methods.
3. Prefer Cucumber Expressions over regexes; reach for regexes for custom parameter types, sets of allowed values, and non-capturing groups.
4. Use `(s)`, `(s)he`, and `word/synonym` so scenarios read as natural business prose.
5. Put business-meaningful reference data in `Background`; put everything technical in hooks.
6. Tag scenarios by their environmental needs (`@web`) and attach tagged hooks so you only pay for what a scenario uses.
7. Prefer `EventListener` over `@BeforeAll` + statics when you may run in parallel; wrap shared containers in `ThreadLocal`.
8. Give each scenario a fresh, self-owned environment — that's what makes the independence rule from ch 7 enforceable.
9. Use TestContainers to get production-like dependencies locally instead of queueing for a shared test environment.
10. Layer scenarios within a feature: simplest case first, one new variable at a time, with a `Notes` column explaining each example row.

## Connects To
- **Ch 3**: the first, minimal Cucumber + Maven + Serenity setup.
- **Ch 7**: Gherkin authoring, `Background`, tags, and the independence rule this chapter operationalizes.
- **Ch 9**: writing *solid* acceptance tests — the layered architecture that keeps these step definitions thin.
- **Ch 10–12**: automating the UI layer, design patterns, and the Screenplay Pattern.
- **Ch 16**: how tags and plugins feed living documentation and release evidence.
- **Cucumber, SpecFlow (.NET), Behave (Python), Serenity BDD, Serenity/JS, TestContainers, Docker, Docker Compose, H2/HSQLDB, Spring Boot**: the tools covered.
