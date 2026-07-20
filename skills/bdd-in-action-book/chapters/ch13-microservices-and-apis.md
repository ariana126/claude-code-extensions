# Chapter 13: BDD and Executable Specifications for Microservices and APIs

## Core Idea
**"API testing" vs. "testing with APIs"** — the goal is never to exercise a layer, it's to illustrate a business rule. Once you accept that, most scenarios (including whole user journeys) can be automated through fast, reliable API calls, with the UI reserved for genuinely UI-specific behavior.

## Frameworks Introduced

- **The chapter's central distinction — testing *with* APIs, not testing APIs:**
  > "Traditional thinking about test automation encourages us to think in terms of application layers: end-to-end tests, UI tests, API tests, integration tests, unit tests… However, when we are writing and automating executable specifications, our thinking needs to be a little different. The goal is to illustrate and automate an example of a business use case or business rule, **not** to exercise a specific layer of the application… **Interacting with the interfaces is just a means to an end rather than a goal on its own.**"
  - And the corollary (§13.6): "Testing the details of your API design, such as what fields are included and what error codes are returned, are often easier to do using unit or integration testing tools and with the same technology stack as the development itself."

- **Four kinds of executable specification** — the chapter's taxonomy, each with a different automation strategy:
  | Kind | Purpose | Automate via |
  |---|---|---|
  | **Big picture** | Capture the key business outcome in a few succinct scenarios before drilling in | Often **pure API** — "none of these steps need to interact with the UI" |
  | **User journey exploration** | Break the journey into steps (register → pending → confirm → active) | API, reusing the same client code |
  | **UI behavior** | Field validation, mandatory fields, T&Cs, redirects | UI component tests |
  | **System interaction** | Cross-service effects (an email sent, an event published) | Listen for the event, or use an email-testing service |
  - Ordering advice: "It is always a good idea to capture the key business outcomes as a few succinct, easy-to-read scenarios **before drilling more into the details**. This helps us document the intent of a feature more clearly and keep the focus on the business outcomes that really matter."

- **Why web tests aren't enough** — the specific costs:
  - "Interacting with a browser adds significant overhead in terms of execution time and system resources."
  - "Web tests can fail because the wrong version of a browser is installed on a test machine, because the site is responding slowly, or because the browser crashes."
  - "Tests that fail for reasons unrelated to the application logic waste development time and resources and **can reduce the team's confidence in the test suite**."
  - Four things non-UI tests add: they work at different levels including application code directly; they can verify **nonfunctional requirements such as performance**; and "implementing non-UI acceptance tests, and the corresponding application code, is also a great way to **discover what components your application needs and to design clean, effective APIs**."

- **The partial-response principle** — the chapter's most transferable technique:
  - "We are testing functionality via the API, not testing the API itself… so it makes more sense to simply extract the `frequentFlyerNumber` field from this response. **Limiting ourselves to a single field reduces our dependency on the structure of the JSON response; if another field is added to the structure, for example, our test will not fail.**"
  - Same idea when mapping to objects: define a record with only the fields you need, and annotate `@JsonIgnoreProperties(ignoreUnknown = true)`.
  - "By only getting the information we really need, and ignoring incidental fields, we can help make our test automation code more flexible and robust."

- **The API-client abstraction layer** — the same discipline as Page Objects and Screenplay tasks, applied to APIs:
  > "It is good practice to avoid interacting directly with our application layers (UI or APIs) in our step definition methods. This is why, in previous chapters, we saw how to use action classes and Screenplay tasks to create a more readable and more reusable layer of abstraction… **We can do something similar with the API layers.**"
  - One class per service (`MembershipAPI`, `TokenAPI`), sharing a configurable base class. Keeping them separate is "cleaner and more maintainable."

- **The decoupled-architecture testing benefit**: "We do not need to have a working email service to be able to implement the email confirmation logic; **all we need is to agree on how the single-use token service will work.**" Decoupling lets work proceed independently and in parallel — including test work.

- **Intent-expressing wrappers for uncertain implementations.** When you don't yet know *how* you'll verify something (real inbox? event bus? external service?), name the intent and let the class decide:
  > "In both cases, the automation code in the step definition method should try to express the **intent** of the step rather than the implementation."

## Key Concepts

- **API (Application Programming Interface)** — "describes how an application can interact with another application programmatically… the actions you can perform, the queries you can ask, and the data structures you can send to and receive from the application."
- **Rest Assured** — a REST client library with "a readable DSL to both interact with REST APIs, but also to extract data from, and make assertions about, the responses."
- **JSONPath** — "similar to XPath, but for JSON documents. It allows sophisticated queries to retrieve individual values or collections of values from complex JSON structures."
- **`then()`** — Rest Assured's response-checking method, accepting simple values and Hamcrest matchers.
- **`serenity.conf`** — HOCON project configuration in `src/test/resources`; holds driver choice, reporting options, and here the `base.url`.
- **Single-use token** — issued by a dedicated token service, embedded in the confirmation email link.

## Reference Tables

**JSONPath / Rest Assured extraction patterns:**
| Need | Code |
|---|---|
| Top-level string | `response.jsonPath().getString("lastName")` |
| Top-level as int | `response.jsonPath().getInt("frequentFlyerNumber")` |
| Nested value (dot notation) | `response.jsonPath().getInt("passport.number")` |
| Sub-structure as an object | `response.jsonPath().getObject("passport", Passport.class)` |
| Whole document as an object | `response.jsonPath().getObject(".", AccountStatus.class)` |
| Collection of field values | `response.jsonPath().getList("flightHistory.to")` |
| Collection of objects | `response.jsonPath().getList("flightHistory", Flight.class)` |

**HTTP verbs used in the worked example:**
| Verb | Purpose | Endpoint |
|---|---|---|
| `POST` | Register a new member | `/frequent-flyer` |
| `GET` | Fetch single-use token | `/tokens/frequent-flyer/{id}` |
| `POST` | Confirm email address | `/frequent-flyer/email-confirmation` |
| `GET` | Read membership details | `/frequent-flyer/{id}` |
| `DELETE` | Clean up after the scenario | `/frequent-flyer/{id}` |

## Code Examples

**Configurable API client base class** — reads from config with a sensible default:
```java
public class ConfigurableAPIClient {
    public ConfigurableAPIClient() {
        RestAssured.baseURI = Serenity.environmentVariables()
                                      .getProperty("base.url",
                                           "http://localhost:3000/api");
    }
}
```
```hocon
# serenity.conf
base.url = "http://localhost:3000/api"
```

**POST with a body, extracting one field:**
```java
public class MembershipAPI extends ConfigurableAPIClient {
    public String register(TravelerRegistration newMember) {
        Response response = RestAssured.given()
              .contentType(ContentType.JSON)     // format of the data being posted
              .body(newMember)                   // Rest Assured converts the record to JSON
              .post("/frequent-flyer");
        return response.jsonPath().getString("frequentFlyerNumber");   // just the one field
    }
}
```

**GET with a path parameter:**
```java
public class TokenAPI extends ConfigurableAPIClient {
    public String getEmailToken(String frequentFlyerNumber) {
        return RestAssured.given()
                          .pathParam("id", frequentFlyerNumber)
                          .get("/tokens/frequent-flyer/{id}")
                          .getBody().asString();   // simple string response, no parsing needed
    }
}
```

**POST plus response verification with `then()`:**
```java
public record EmailValidation(String frequentFlyerNumber, String email, String token) {}

public void confirmEmail(String frequentFlyerNumber, String email, String token) {
    RestAssured.given()
        .contentType(ContentType.JSON)
        .body(new EmailValidation(frequentFlyerNumber, email, token))
        .post("/frequent-flyer/email-confirmation")
        .then().statusCode(201);      // throws if the status isn't as expected
}
```
Richer checks with Hamcrest matchers:
```java
RestAssured.given()
        .contentType(ContentType.JSON)
        .body(new EmailValidation(frequentFlyerNumber, email, token))
        .post("/frequent-flyer/email-confirmation")
        .then()
        .statusCode(201)
        .body("frequentFlyerNumber", equalTo(frequentFlyerNumber))
        .body("token", not(emptyOrNullString()));
```
And assertions over collections via JSONPath:
```java
RestAssured.when()
           .get("/frequent-flyer/{id}/history", id)
           .then()
           .body("flightHistory.to", hasItems("Paris", "London"));
```

**Mapping a partial response.** The endpoint returns ten fields; the test needs three:
```java
@JsonIgnoreProperties(ignoreUnknown = true)     // required — Rest Assured errors on unmapped fields
public record AccountStatus(int statusPoints,
                            MembershipTier tier,
                            boolean isActivated) {}

public AccountStatus getMemberStatus(String frequentFlyerNumber) {
    return RestAssured.given()
                    .get("/frequent-flyer/{number}", frequentFlyerNumber)
                    .jsonPath()
                    .getObject(".", AccountStatus.class);   // "." = the whole document
}
```

**DELETE cleanup in an `@After` hook** — not in the last step of every scenario:
```java
@After
public void deleteFrequentFlyerAccount() {
    membershipAPI.deleteFrequentFlyer(newFrequentFlyerNumber);
}

public void deleteFrequentFlyer(String frequentFlyerNumber) {
    RestAssured.when()
               .delete("/frequent-flyer/{id}", frequentFlyerNumber)
               .then().statusCode(200);
}
```

**Intent-expressing wrapper for an uncertain verification:**
```java
@Steps
EmailMonitor emails;

@Then("he/she should be sent an email with an email validation link")
public void shouldBeSentAnEmailWithAnEmailValidationLink() {
    assertThat(emails.newAccountConfirmationMessageSentTo(newMember.email())).isTrue();
}
```
"The `EmailMonitor` class is then free to choose whether to query the event bus logs, subscribe to a particular message type, or use an external service to monitor the email messages that go out."

## Worked Example

**Registration: from Example Map to a fully API-automated journey.**

*The Example Mapping session with Marcus from marketing surfaced seven rules:*
- Travelers can sign up as frequent flyers on the Flying High website.
- New frequent flyers provide name, address, and email.
- If an account already exists with that email, offer a password reset.
- **Email must be validated before the account activates** — Marcus needs valid addresses for promotions.
- Compliance and legal require approving terms and conditions.
- If an email isn't validated after a time, send a follow-up automatically.
- A welcome email is sent, sequenced by marketing's own specialized software.

Note how several rules come from *non-obvious stakeholders* — marketing wants deliverable addresses, compliance wants T&C approval.

*The architecture (figure 13.3), which determines what's testable where:*
1. Traveler registers on the page →
2. POST to the Frequent Flyer endpoint →
3. Service adds a **pending** account to the membership DB →
4. Service requests a single-use token from the token service →
5. Service publishes a `NewFrequentFlyerEvent` to a message broker →
6. The **email service (a different team)** subscribes and sends the confirmation email with the token link →
7. Member clicks the link →
8. POST to the email confirmation endpoint → account becomes **active** →
9–11. Login via the authentication service, account overview via the membership service.

*The big-picture scenario:*
```gherkin
Rule: Travelers can register as new members on the Flying High website

  Example: Tracy registers as a new Frequent Flyer
    Given Tracy does not have a Frequent Flyer account
    When she registers for a new Frequent Flyer account with valid details
    And she confirms her email address
    Then she should have a new Standard tier account with 0 points
```
"Upon closer observation, we might note that **none of these steps need to interact with the UI**… This is especially true if we have other scenarios that explore the UI in more detail."

*Step 1 — test data from HOCON:*
```hocon
Tracy: {
  email: "tracy@example.org"
  password: "trac1"
  firstName: "Tracy"
  lastName: "Traveler"
  address: "10 Pinnack Street, Reading"
  country: "United Kingdom"
  title: "Mrs"
}
```
```java
public record TravelerRegistration(String firstName, String lastName, String title,
                                   String email, String password,
                                   String address, String country) {}

public class TravelerRegistrationConfig {
    public static TravelerRegistration forTravelerNamed(String name) {
        Config travelerDetails = ConfigFactory.load("travelers").getConfig(name);
        return new TravelerRegistration(
                travelerDetails.getString("firstName"),
                travelerDetails.getString("lastName"),
                travelerDetails.getString("title"),
                travelerDetails.getString("email"),
                travelerDetails.getString("password"),
                travelerDetails.getString("address"),
                travelerDetails.getString("country"));
    }
}

TravelerRegistration newMember;

@Given("{} does not have a Frequent Flyer account")
public void has_no_frequent_flyer_account(String name) {
    newMember = travelerRegistrationConfig.forTravelerNamed(name);
}
```

*Step 2 — register, keeping the step definition free of Rest Assured:*
```java
MembershipAPI membershipAPI = new MembershipAPI();

@When("he/she registers for a new Frequent Flyer account")
public void registers_for_a_new_frequent_flyer_account() {
    newFrequentFlyerNumber = membershipAPI.register(newMember);
}
```
The endpoint returns ten fields; only `frequentFlyerNumber` is extracted:
```json
{
    "isActivated": false, "tier": "STANDARD", "statusPoints": 0,
    "firstName": "Tracy", "lastName": "Traveler", "title": "Mrs",
    "email": "tracy@example.org", "address": "10 Pinnack Street, Reading",
    "country": "United Kingdom", "frequentFlyerNumber": 1000036
}
```

*Step 3 — confirm the email, spanning two services:*
```java
TokenAPI tokenAPI = new TokenAPI();

@When("he/she confirms her email address")
public void confirms_email_address() {
    emailToken = tokenAPI.getEmailToken(newFrequentFlyerNumber);
    membershipAPI.confirmEmail(newFrequentFlyerNumber, newMember.email(), emailToken);
}
```
**The test bypasses the email service entirely** — it fetches the token directly from the token service and posts the confirmation, because the email service belongs to another team and its delivery isn't what this scenario is about.

*Step 4 — verify with a partial response:*
```java
@Then("he/she should have a new {tier} tier account with {int} points")
public void should_have_a_new_account_with_points(MembershipTier tier, Integer points) {
    TravelerAccountStatus accountStatus = membershipAPI.getMemberStatus(newFrequentFlyerNumber);
    assertThat(accountStatus.statusPoints()).isEqualTo(points);
    assertThat(accountStatus.tier()).isEqualTo(tier);
}
```

*Cleanup* — the `@After` DELETE hook shown above restores the initial state.

**Splitting the journey into granular scenarios** — and one thing deliberately *not* asserted:
```gherkin
Rule: Travelers must confirm their email before their account is created

  Example: Tracy's account is initially pending activated
    Given Tracy does not have a Frequent Flyer account
    When Tracy registers for a new Frequent Flyer account
    Then she should be sent an email with an email validation link
    And her account should be pending activation

  Example: Tracy cannot access her account before having activated her email
    Given Tracy has registered for a new Frequent Flyer account
    But she has not yet confirmed her email
    When she attempts to access her Frequent Flyer account details
    Then she should be invited to first confirm her email address

  Example: Tracy confirms her email
    Given Tracy has registered for a new Frequent Flyer account
    When she confirms her email address
    Then her account should be activated
```
> "Note that in the third scenario we have **not** included a clause like 'And she should be able to log in'… While we could include this step, it is not strictly necessary (we have already demonstrated that a user can log in after confirming their email in the 'Tracy registers as a new Frequent Flyer' scenario), and adding the extra step would make the scenario **slower and potentially less stable**."

**A validation rule that looks like UI work but isn't.** Marcus wants *deliverable* addresses, not just well-formed ones — so the rule needs domain checks and disposable-address detection, which live on the server:
```gherkin
Rule: Travelers must provide a valid email address
  Scenario Outline: Emails must be correctly formed and non-disposable
    Given Tracy does not have a Frequent Flyer account
    When she registers with an email of <email>
    Then the email address should be <Accepted/Rejected> with the message "<Reason>"

    Examples: Correctly-formed emails should be accepted
      | email                  | Accepted/Rejected | Reason |
      | sarah@example.org      | Accepted          |        |
      | sarah-jane@example.org | Accepted          |        |

    Examples: Invalid emails should be rejected
      | email                       | Accepted/Rejected | Reason                 |
      | example.com                 | Rejected          | email must be an email |
      | #@%^%#$@#$@#.com            | Rejected          | email must be an email |
      | email@example..com          | Rejected          | email must be an email |
      | email@inexistant-domain.com | Rejected          | Invalid email address  |
```
Note the **two separate `Examples:` blocks with their own titles** — accepted and rejected cases labelled distinctly. "The user will see the error message mentioned in the Reason column on the registration page… However, the actual email validation is performed on the server, so this scenario could be implemented via API calls without needing to refer to the user interface."

**A genuinely mixed scenario — API setup, UI verification:**
```gherkin
Rule: Duplicate accounts with the same email address are not allowed

  Example: Someone tries to register with an email that is already used

  Trevor is an existing Frequent Flyer member.
  His wife Candy does not have a Frequent Flyer account

    Given Harry Smith has registered as thesmiths@example.org
    When Candy tries to register with the same email
    Then she should be informed that this email address is already in use
    And she should be presented with the option to reset her password
```
"In the first step… Harry has already registered. **This step would typically be implemented via an API call.** We have already illustrated how a user interacts with the registration page to register, and there is **little value in repeating those interactions here.** However, the following steps illustrate how Candy tries to enter the same email but is not allowed to register… This is a very UI-focused flow."

**Verifying a cross-service effect.** Two valid strategies:
1. Set up an email server and monitor the inbox — "there are some scenarios where the importance or risks involved may make this a useful strategy." (Services like **Mailinator** provide realistic email/SMS test infrastructure.)
2. In an event-driven architecture, "it may be enough to simply **listen for the appropriate event**, without needing to check the actual email delivery."

Either way, the step definition names the intent and the `EmailMonitor` class picks the mechanism.

## Mental Models

- **Ask what the scenario is *about*, not what layer it lives in.** "The focus at this stage is not to test a specific layer of the application; it is to illustrate what the application should do in business terms. Once we understand what the application should do… we can consider how we will go about demonstrating these examples."
- **Journey scenarios are a small minority.** "These journey scenarios should only make a very small proportion of our acceptance criteria. **The bulk** of our acceptance criteria will take the form of smaller, more granular, and more nimble scenarios that explore specific business rules within a user journey."
- **A mixed scenario is fine.** "Some scenarios might require UI interactions, whereas others might be possible entirely via API calls, while still others might need a combination of UI and API calls. **And that's fine.**"
- **Don't re-prove what another scenario already proved.** Both the omitted "should be able to log in" step and the API-based registration in the duplicate-email scenario follow this rule.
- **Designing your non-UI tests designs your application.** Writing acceptance tests against components "is a great way to discover what components your application needs and to design clean, effective APIs within your application."

## Anti-patterns

- **Web tests as the only automation option**: slow, resource-hungry, and subject to environment failures that erode trust in the suite.
- **Registering through the UI in every scenario that needs a registered user**: "slow and wasteful (since we have already illustrated that user journey elsewhere)."
- **Mapping the entire JSON response into a record**: couples the test to fields it doesn't care about; a new field breaks the test.
- **Forgetting `@JsonIgnoreProperties(ignoreUnknown = true)`**: "By default, Rest Assured will try to find a property for every field in the JSON document and throw an error when it doesn't find them."
- **Rest Assured calls directly in step definitions**: same coupling problem as raw WebDriver — wrap them in API client classes.
- **One client class for several services**: keep `TokenAPI` and `MembershipAPI` separate; "it would be cleaner and more maintainable."
- **Cleanup as a final scenario step**: "that would be hard to maintain" — use `@After`.
- **Adding extra confirmation steps to a scenario "just to be safe"**: slower and less stable, and usually redundant.
- **Using acceptance tests to test API design details** (fields present, error codes): that belongs in unit/integration tests in the development stack.

## Key Takeaways
1. Ask what a scenario is *about* before choosing a mechanism; even full user journeys are often best automated purely through APIs.
2. Write the big-picture outcome scenario first, then decompose into granular business-rule scenarios — and keep journey scenarios rare.
3. Extract only the fields you need from responses; use `@JsonIgnoreProperties` and single-field JSONPath queries to stay decoupled from response shape.
4. Wrap API calls in per-service client classes with a shared configurable base — never call Rest Assured from a step definition.
5. Use API calls to *set up* preconditions even in UI-focused scenarios; don't re-prove flows other scenarios already cover.
6. Verify cross-service effects at the boundary you own (an event published, a message sent), not by exercising another team's system.
7. Name the intent in step definitions when the verification mechanism is undecided; let the wrapper class change freely.
8. Clean up test data in `@After` with a DELETE call, not in scenario steps.
9. Keep API *design* testing (fields, status codes) in unit/integration tests; keep acceptance tests about business rules.
10. Treat decoupled architectures as a testing asset — agreeing on a contract lets you test without the collaborating service existing.

## Connects To
- **Ch 6**: Example Mapping — the session that produced this feature's rules.
- **Ch 9**: layers of abstraction and personas/HOCON — applied here to API clients.
- **Ch 10**: the four reasons to write a UI test; this chapter is the other side of that decision.
- **Ch 12**: Screenplay's `CallAnApi` ability and `Post.to(...)` interaction — the Screenplay way to do the same thing.
- **Ch 8**: `@After` hooks, used here for API cleanup.
- **Rest Assured, JSONPath, Hamcrest, Typesafe Config/HOCON, Serenity BDD, Mailinator**: tools used.
- **Further reading cited**: *Microservice APIs* (José Peralta, Manning 2022), *Microservice Patterns* (Chris Richardson, Manning 2018).
