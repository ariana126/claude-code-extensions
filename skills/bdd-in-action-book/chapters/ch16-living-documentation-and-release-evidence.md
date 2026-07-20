# Chapter 16: Living Documentation and Release Evidence

## Core Idea
Living documentation closes the loop that started with the first stakeholder conversation. It reports not just pass/fail but **feature readiness** and — crucially — **feature coverage**: how much of a requirement has acceptance criteria at all, including the parts nobody has built yet.

## Frameworks Introduced

- **What "living documentation" means, precisely.** "A living document is a document that is always up to date and that always reflects the current state of the system."
  - Feature files written with customers = **executable specifications**.
  - Automated with Cucumber = **living documentation**.
  - The term "can refer to the feature files themselves (assuming they are automated and executed) **or** the test reports that are generated when the tests are executed."
- **Release evidence** — living documentation reports produced to document "what features go into a particular release, what business rules they relate to, and how they were tested… This may simply be for communication with stakeholders or might be required for **audit or compliance purposes**."

- **The four audiences and what each gets:**
  | Audience | Use |
  |---|---|
  | **Business stakeholders** | Review what a feature does; confirm it matches business needs and constraints |
  | **Testers** | A starting point for exploratory testing; saves routine manual testing of basics; shows where to focus |
  | **Developers** | Understand what an existing feature does and how it works |
  | **New team members / BAU team** | Onboard on both what the application does **and how** — "for organizations that hand over projects to a different team once they go into production, the benefits of this alone can be worth the time invested" |

- **Feature readiness vs. feature coverage** — the chapter's central distinction:
  | | **Feature readiness** | **Feature coverage** |
  |---|---|---|
  | Question | Which features are ready to deploy? | Which requirements have acceptance criteria at all? |
  | Definition | "A feature can be considered ready (or done) when **all of its acceptance criteria pass**" | "How many acceptance criteria have been defined and automated for each requirement… **and what requirements have no automated acceptance criteria**" |
  | Source | Aggregating scenario results per feature | Requirements knowledge beyond the test reports |
  | Blind spot | Everything not yet written | Requirements the tool doesn't know about |
  - The core insight: **"Test results can tell you what features were tested, but they can't tell you which features have no tests at all."**
  - Why stakeholders want this: "when the development team reports on progress, stakeholders are less interested in which individual tests pass or fail and are **more interested in what functionality is ready to be deployed to production**."

- **Feature coverage ≠ code coverage:**
  | | Code coverage | Feature coverage |
  |---|---|---|
  | Measures | Lines of code exercised during tests | Requirements with defined acceptance criteria |
  | Tells you | What parts of the code base are untested | Whether the app does what it's supposed to |
  | Limitation | "Can't tell you whether an application has been tested **effectively**… only how much code was executed" | "Only as thorough as the number of overall requirements it knows about" |
  - **The Agile caveat**: "BDD practitioners, and Agile projects in general, avoid defining more detailed requirements up front than necessary. Stories and scenarios will typically be available for the current iteration, but not for much more; beyond that, the product backlog will typically contain higher-level features and Epics."

- **Empty scenarios as coverage markers.** Cucumber allows scenarios with a title and no steps. They report as **pending** and count *against* feature coverage — a lightweight way to declare "this acceptance criterion exists but isn't built."

- **Four ways to organize living documentation** — mix them by audience and purpose:
  | Strategy | Best for |
  |---|---|
  | **By high-level requirements** (Epics, capabilities) | "Documenting what the application does as a whole and how it does it" |
  | **By tags** (cross-functional concerns) | Nonfunctional requirements — security, performance, external integrations |
  | **By release/iteration tag** | "Reporting on progress and preparing release notes" |
  | **Low-level (unit tests)** | Technical documentation for maintainers |
  - "These choices are not exclusive… teams often use a mix of several strategies for different purposes or different audiences."

- **Technical living documentation — a different bar.** "For technical living documentation, **sophisticated reporting capabilities are less important than code readability and clarity**. The primary audience is the developer who will need to maintain the code later on. Developers are used to reading code, so technical documentation in the form of well-organized, readable, annotated code samples is generally quite sufficient." Complement with "light, higher-level architectural documentation, stored, for example, on a project wiki."
  - And: "writing unit tests that make good technical documentation relies more on an **attitude** than on using a particular tool."

- **The four arguments against mirroring package structure in tests** — a well-argued position:
  1. **The historical reason is obsolete.** The original motivation was that Java classes in a package could access protected fields of other classes in that package. Modern IDEs also make "find usages" trivial, removing the navigation argument.
  2. **Accessing protected fields is a smell.** "If you need to access protected variables, you may be **binding your test code too tightly to the implementation**, which risks making the unit tests more brittle."
  3. **It assumes classes map to behavior.** "If you refactor a class, change its name, or break it into several smaller classes, **the requirement that these classes implement shouldn't change**."
  4. **It hampers refactoring.** "A modern IDE will tell you at a glance if a method or a class isn't being used anywhere. Unless it's part of an API for an external client, a method that's never used anywhere can generally be deleted."
  - The alternative: "test packages or directories organized in terms of **functional slices** are often easier to navigate, especially when you come back to a code base after a long period."

- **BDD for legacy applications** — two strategies with different risk profiles:
  | Strategy | Viability |
  |---|---|
  | **Retrofit high-level acceptance tests** (typically web tests) | Works well. "These acceptance tests both describe and document the existing system and help reduce the risk of regressions when new features are introduced." |
  | **Retrofit unit tests** | Hard. "Unit tests written too long after the code was written tend to be quite **superficial**… it can be difficult to invent them after the fact, as it involves a deep understanding of how each class or component is expected to behave." |
  - **The pragmatic path**: "Some teams with mission-critical legacy applications… use BDD tests to document **the most critical or high-risk parts of their application first**, before expanding into less critical functionality. Unit tests are written in the spirit of documenting the current application behavior and giving code samples for how to use each class."

## Key Concepts

- **Source of truth** — executable specifications become "the definitive reference for the current set of application requirements."
- **Digital product backlog** — the book's shorthand for "Agile project-management software" ("because it's a lot easier to say"). Automates burndown charts and other metrics, and lets you attach extra information without cluttering a board.
- **Burndown chart** — "a graphical representation commonly used in Scrum projects that compares the amount of work remaining in a sprint to the work planned for the sprint."
- **Task board** — a physical board of index cards representing stories, tasks, and bug fixes, arranged in status columns.
- **`@Issue:` tag** (Serenity BDD) — links features, rules, and examples to issue-tracker items.

## Reference Tables

**Enabling Cucumber Reports publishing** — three options:
| Method | How |
|---|---|
| Environment variable | Set `CUCUMBER_PUBLISH_ENABLED=true` |
| Properties file | `cucumber.properties` in `src/test/resources`, set `cucumber.publish.enabled=true` |
| Runner annotation | Set `publish` to `true` in `@CucumberOptions` |
- **Recommendation**: "Often it is useful to only generate and publish these reports as part of a continuous integration build job, so **using the environment variable is generally the most common option**."

**Collaboration tooling for non-developers:**
| Tool | What it does |
|---|---|
| **Cucumber Studio** | Online environment for requirements discovery and writing Cucumber scenarios; supports online Example Mapping sessions |
| **Behave Pro** | Write Gherkin acceptance criteria **directly in JIRA**, auto-synced with version control |
| Both | Integrate with test execution so results display alongside the specifications |
- **The caveat**: "These tools are still relatively new and immature and often lack support for the most recent Gherkin features. However, they are evolving fast."

## Code Examples

**A feature file declaring coverage it hasn't built** (listing 16.1):
```gherkin
Business Need: Authentication

  Registered Frequent Flyer members can access their account using their
  email and password

  Rule: 1) Frequent Flyers can authenticate by entering their credentials on the login page
    Scenario: Trevor successfully logs on to the Frequent Flyer app      # fully defined
      Given Trevor has registered as a Frequent Flyer member
      And he has confirmed his email address
      Then he should be able to log on to the Frequent Flyer application

  Rule: 2) Frequent Flyers can sign in with SSO using their Google or Facebook account
    Example: Trevor logs in using his Google credentials                 # empty → pending
    Example: Trevor logs in using his Facebook credentials               # empty → pending
```
**The result**: "All of the implemented automated acceptance criteria in the Authentication feature **pass**. However, the feature coverage metric is only around **33%** because two of the three scenarios remain to be implemented, so although all of the tests are green, this feature is only around one-third complete."

**Linking to a JIRA hierarchy with `@Issue` tags:**
```gherkin
@Issue:FHFF-3                     # the feature as a whole → JIRA Epic
Business Need: Authentication

Registered Frequent Flyer members can access their account using their
email and password

  @Issue:FHFF-1                   # first rule → JIRA User Story
  Rule: 1) Frequent Flyers can authenticate by entering their credentials on the login page
    Example: Trevor successfully logs on to the Frequent Flyer app
      Given Trevor has registered as a Frequent Flyer member
      And he has confirmed his email address
      Then he should be able to log on to the Frequent Flyer application

  @Issue:FHFF-4                   # second rule → JIRA User Story
  Rule: 2) Frequent Flyers can sign in with SSO using their Google or Facebook account
    Example: Trevor logs in using his Google credentials
    Example: Trevor logs in using his Facebook credentials
```
Configure the link target in `serenity.conf`:
```hocon
jira.url = https://myorg.atlassian.net
```

**Tagging a cross-functional (nonfunctional) concern:**
```gherkin
@Issue:FHFF-4
@security:sso
Rule: 2) Frequent Flyers can sign in with SSO using their Google or Facebook account
  Example: Trevor logs in using his Google credentials
  Example: Trevor logs in using his Facebook credentials
```

**Tagging by release, for a focused release report:**
```gherkin
Feature: Earning Points

  Frequent Flyers earn status points each time they fly.
  As they earn more points, their status level increases and they get more benefits.

  @release:iteration-1
  Rule: Members achieve new status levels when they earn sufficient points
    Scenario Outline: Earning status levels from points earned for status level <Status Level>
      Given Stan is a new Frequent Flyer Member
      When he earns between <Min Points> and <Max Points> points
      Then his status should become <Status Level>

      Examples:
        | Min Points | Max Points | Status Level |
        | 0          | 999        | STANDARD     |
        | 1000       | 1999       | BRONZE       |
        | 2000       | 4999       | SILVER       |
        | 5000       |            | GOLD         |
```
Two uses: "run a separate batch of acceptance tests for the features containing the `@release:iteration-1` tag" *or* "simply view the report page dedicated to this tag."

**Unit tests as technical living documentation — JavaScript:**
```javascript
describe('FrequentFlyerController', () => {
    describe('When creating a new account', () => {

        it('should generate a new number for each account', async () => {
            const result = await controller.create(newFrequentFlyer);
            expect(result.frequentFlyerNumber).toBeDefined()
        })

        it('new Frequent Flyer accounts should be Pending', async () => {
            const result = await controller.create(newFrequentFlyer);
            const frequentFlyerNumber = result.frequentFlyerNumber;
            const frequentFlyerAccount =
                controller.findByFrequentFlyerNumber(frequentFlyerNumber)
            expect(frequentFlyerAccount.isActivated).toBeFalsy()
        });

        it('should return an error if the email is invalid', async () => {
            const result = controller.create(frequentFlyerWithAnInvalidEmail);
            await expect(result).rejects.toThrow("Invalid email address");
        })
    });
});
```

**The same attitude in C# with NSpec** — "also does a great job of explaining what feature it's describing and illustrating how an API should be used":
```csharp
public class WhenUpdatingStatusPoints : nspec
{
    FrequentFlyer member;
    void before_each()
    {
        member = new FrequentFlyer();
    }
    void earning_status_points()
    {
       context["When cumulating Frequent Flyer points"] = () =>
       {
          it["should earn points for each flight"] = () =>
          {
             member.earnStatusPoints(100);
             member.earnStatusPoints(50);
             member.getStatusPoints().should_be(150);
          };
          it["should upgrade status when enough points are earned"] = () =>
          {
              member.earnStatusPoints(300);
              member.getStatus().should_be(Status.Silver);
          };
       };
    };
};
```

## Mental Models

- **Living documentation closes the circle.** "BDD reporting completes the circle that started with the initial conversations with business stakeholders. The stakeholders, business analysts, testers, and anyone else who participated in the conversations… see the conversations they had and the examples they discussed appear as part of the generated reports."
- **Verbatim reflection drives engagement.** "This feedback loop is a great way to get **buy-in** from business stakeholders, who are often much more keen to contribute actively when they see the results of their contributions **verbatim** in the living documentation."
- **Reports document intent, not just outcome.** "BDD reports don't simply provide a list of test outcomes… First, BDD reports **document and describe what the application is expected to do**, and they report whether the application performs these operations correctly. When you drill into the details, a BDD report also illustrates **how** a particular feature is performed, from the user's perspective."
- **Green tests can hide an unfinished feature.** The Authentication example is the case in point: 100% passing, 33% covered.
- **Physical boards vs. digital backlogs is not either/or.** Physical boards are "excellent communication facilitators" with "great visibility for the current work in progress" but aren't optimal for distributed teams, are time-consuming to maintain, and can't auto-calculate metrics. "Some teams prefer to keep track of work in some sort of issue-tracking system, **even if they still use a physical board** for day-to-day organization and visibility."
- **The Gherkin-in-version-control friction is real.** "One of the disadvantages of the Gherkin format as a collaboration tool is that the feature files need to be stored in a version control system… This can create a **barrier for nondevelopers**." That's the problem Cucumber Studio and Behave Pro address.

## Anti-patterns

- **Reporting only individual test pass/fail to stakeholders**: they care about deployable functionality, not test counts.
- **Treating all-green as done**: without feature coverage, an unimplemented acceptance criterion is invisible.
- **Confusing code coverage with feature coverage**: code coverage says nothing about whether the app does the right thing.
- **A flat list of features in the living documentation**: "for large projects, a flat list of features can quickly become unwieldy."
- **Committing to one organization scheme**: requirements-based, tag-based, and release-based views serve different readers.
- **Mirroring production package structure in test packages**: obsolete motivation, encourages implementation coupling, assumes classes map to behavior, and hampers refactoring.
- **Retrofitting unit tests to a legacy system as the first move**: they "tend to be quite superficial" when written long after the code. Retrofit high-level acceptance tests first.
- **Rewriting a legacy application instead of documenting it**: "for many organizations, rewriting the entire application isn't a viable proposition."
- **Locking non-developers out of the specifications**: if writing feature files requires a dev environment, business stakeholders can't collaborate on them.

## Key Takeaways
1. Report feature *readiness* to stakeholders — aggregate scenarios per feature, not individual test results.
2. Track feature *coverage* too, so requirements with no tests at all are visible; green tests are not the same as a finished feature.
3. Use empty scenarios as declared-but-unbuilt acceptance criteria; they report as pending and reduce coverage honestly.
4. Never treat code coverage as a proxy for feature coverage — they answer different questions.
5. Integrate reporting with a digital product backlog via `@Issue:` tags so the doc structure mirrors the backlog structure automatically.
6. Tag scenarios by cross-functional concern (`@security:sso`) and by release (`@release:iteration-1`) to slice the same suite for different readers.
7. Enable Cucumber report publishing via the `CUCUMBER_PUBLISH_ENABLED` environment variable so it runs only in CI.
8. For technical living documentation, prioritize readable, well-named tests over sophisticated reporting — it's an attitude, not a tool.
9. Organize test directories by functional slice, not by mirroring production packages.
10. On legacy systems, retrofit high-level acceptance tests first; add BDD unit tests to the most critical or high-risk parts before expanding.
11. Evaluate collaboration tools (Cucumber Studio, Behave Pro) if version-control friction is keeping non-developers out of your specifications.

## Connects To
- **Ch 1–3**: the Demonstrate phase of the BDD flow; living documentation as the sixth step.
- **Ch 2**: living documentation as a core BDD principle and the maintenance argument for it.
- **Ch 7**: tags, feature descriptions, scenario descriptions, and pending scenarios — the raw material these reports render.
- **Ch 8**: `@CucumberOptions` plugins, and `serenity.conf`.
- **Ch 14**: the legacy-system approach this chapter's final section complements.
- **Serenity BDD / Serenity JS reports, Cucumber Reports (SmartBear), Cucumber Studio, Behave Pro, JIRA, JUnit 5, NSpec**: tools referenced.
