# Chapter 3: BDD — The Whirlwind Tour

## Core Idea
An end-to-end walkthrough of one feature (train timetables) through all six BDD phases, showing how a business goal becomes an Impact Map, then a story, then a Gherkin scenario, then failing glue code that *discovers the API design*, then unit-tested production code, then living documentation.

## Frameworks Introduced

- **The BDD Flow — six phases** (figure 3.1). The spine of the entire book; parts 2 and 3 expand each phase.
  1. **Speculate** — conversations with businesspeople to identify high-level business goals and the key features that deliver them.
  2. **Illustrate** — build deeper understanding of a specific feature through conversations about concrete examples of business rules and user journeys.
  3. **Formulate** — transform key examples into executable specifications, in a notation both business-readable and executable.
  4. **Automate** — turn executable specifications into automated acceptance tests and use them to drive development.
  5. **Demonstrate** — passing tests act as evidence a feature is correctly implemented, and as documentation of how it works.
  6. **Validate** — the team and business see how features fare in the real world and whether they deliver the promised value.

- **The Measurable Vision Statement**: convert a vague goal into one with a number attached.
  - When to use: at project kickoff, before any feature discussion.
  - How: take the sponsor's stated goal, ask *why* users would use it and how it benefits them, then restate with a target metric and a timeframe using data you can actually measure.
  - Failure mode: "We want to build an application that lets commuters plan their journeys online" states *what to build*, not what success looks like. It gives the team nothing to trade off against.

- **Impact Mapping** (Gojko Adzic; figure 3.3) — four questions to discover and prioritize features from a goal:
  - **Why** are we doing this? (business goals)
  - **Whose** behavior do we need to change? (key actors)
  - **How** might their behavior change? (behavior changes that achieve the goal)
  - **What** software features might support that behavior change?
  - When to use: the Speculate phase, in a workshop with businesspeople.
  - Why it works: it forces features to justify themselves against a behavior change, which in turn justifies itself against a goal. A "rate railway stations" feature dies immediately — it gives a commuter running late no actionable information.

- **Example Mapping** (Matt Wynne) — a four-color card technique for the Illustrate conversation:
  | Card color | Represents |
  |---|---|
  | **Yellow** (top of board) | The feature or User Story under discussion |
  | **Blue** | A business rule |
  | **Green** | An example or counterexample of a rule |
  | **Pink** | A question nobody can answer right now |
  - When to use: a focused ~25-minute conversation before work starts on a story.
  - Why it works: makes the discovery visual, keeps the conversation bounded, and turns unknowns (pink cards) into explicit, trackable items instead of silent assumptions.

- **Two feature-description templates** — pick by altitude:
  | Template | Order | Best for |
  |---|---|---|
  | `In order to <business goal>` / `As a <stakeholder>` / `I want <capability>` | Value first | Higher-level **features**, where emphasis is on business value |
  | `As a <stakeholder>` / `I want <something>` / `So that <business goal>` | Actor first | Detailed **User Stories** within a feature |
  - Optional fourth line: `Unlike currently where <the painful status quo>` — contrasts your solution with today's way of working.
  - Why value-first matters: starting from the outcome reduces scope creep and keeps the *why* visible.

- **Outside-In Development with deliberate stubbing**: as you implement a layer, you discover services it needs. You have a choice — build them now, or model them as an interface/dummy and come back.
  - Rule of thumb from the book: for simple problems, build it now; **for complex code it is generally much more efficient to stay focused on the work at hand** and stub the collaborator.

## Key Concepts

- **Speculate/Illustrate/Formulate/Automate/Demonstrate/Validate** — the six BDD phases.
- **Glue code** — step-definition code that binds the text of a scenario step to test automation or application code.
- **Cucumber Expressions** — the `{...}` notation in `@Given`/`@When`/`@Then` annotations that identifies and types the test data inside a step.
- **`@ParameterType`** — a Cucumber annotation defining a custom expression (e.g. `{time}`, `{times}`) that parses a string into a domain type.
- **Pending scenario** — a scenario with no glue code behind it; it still executes and still appears in reports as awaiting implementation.
- **BAU (Business as Usual) team** — the maintenance team that inherits the application post-release.
- **Serenity BDD** — an open source library that organizes and reports on BDD test results.

## Mental Models

- **Think of a failing acceptance test as the specification of the gap.** "A failing acceptance criterion illustrates a difference between what the requirements ask for and what the application currently does." That's not a problem — that's your starting point.
- **Use glue code as an API design sandbox.** "Writing the glue code gives them the perfect opportunity to experiment with different API designs and see what they like best." Write the step you *wish* you could write; the API falls out.
- **Start from the `@Then` step and work backward.** BDD practitioners begin with the outcome they need and work back to the machinery that produces it.
- **Treat "many unit tests per acceptance criterion" as the normal ratio** (figure 3.11). Acceptance tests use a full stack and demonstrate end-to-end behavior; unit tests isolate components and localize errors.
- **BDD and TDD are both example-driven; they differ in altitude.** TDD is developer-centric at the level of classes, methods, and APIs. BDD is team-centric at the level of business goals, features, and scenarios.
- **Read the pass/pending ratio as a progress meter.** Passing acceptance criteria ÷ total specified acceptance criteria is a concrete measure of how much work is done — and tracking it over time shows velocity.

## Code Examples

**The scenario, after three rounds of refinement:**
```gherkin
Feature: Show next departing trains

  As a commuter traveling between two stations on the same line
  I want to know what time the next trains for my destination will leave
  So that I can spend less time waiting at the station

  Scenario: Next train going to the requested destination on the same line
    Given the T1 train to Chatswood leaves Hornsby at 8:02, 8:15, 8:21
    When Travis wants to travel from Hornsby to Chatswood at 8:00
    Then he should be told about the trains at: 8:02, 8:15
```

**Skeleton step definitions — empty methods that define the contract:**
```java
package com.bddinaction.traintimetables.stepdefinitions;

import io.cucumber.java.ParameterType;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

public class DepartingTrainsStepDefinitions {

    @Given("the {} train to {} leaves {} at {}")
    public void theTrainLeavesAt(String line, String to, String from, String departureTimes) {}

    @When("Travis want to travel from {} to {} at {}")
    public void travel(String from, String to, String departureTime) {}

    @Then("he should be told about the trains at: {}")
    public void shouldBeToldAboutTheTrainsAt(String expectedTimes) {}
}
```
- **What it demonstrates**: "For teams practicing BDD, code like this is the gateway to production code. It tells you precisely what your underlying code needs to do to satisfy the business requirements."

**Custom Cucumber Expressions turn strings into domain types:**
```java
@Then("he should be told about the trains at: {times}")
public void shouldBeToldAboutTheTrainsAt(List<LocalTime> expected) {
    assertThat(proposedDepartures).isEqualTo(expected);
}

@ParameterType(".*")
public LocalTime time(String timeValue) {
    return LocalTime.parse(timeValue, DateTimeFormatter.ofPattern("H:mm"));
}

@ParameterType(".*")
public List<LocalTime> times(String timeValue) {
    return stream(timeValue.split(","))
            .map(String::trim)
            .map(this::time)
            .collect(Collectors.toList());
}
```
- **What it demonstrates**: parsing lives in the expression, not the step body — steps stay about behavior.

**The production class the tests drove out:**
```java
public class ItineraryService {
    private TimeTable timeTable;

    public ItineraryService(TimeTable timeTable) {
        this.timeTable = timeTable;
    }

    public List<LocalTime> findNextDepartures(LocalTime departureTime,
                                              String from, String to) {
        var lines = timeTable.findLinesThrough(from, to);      // ask timetable which lines connect
        return lines.stream()
               .flatMap(line -> timeTable.getDepartures(line).stream())
               .filter(trainTime -> !trainTime.isBefore(departureTime))  // drop past trains
               .sorted()                                                 // earliest first
               .limit(2)                                                 // next two only
               .collect(Collectors.toList());
    }
}
```

**The interface that outside-in development *discovered*:**
```java
public interface TimeTable {
    List<String> findLinesThrough(String from, String to);
    List<LocalTime> getDepartures(String lineName, String from);
}
```
- **What it demonstrates**: the interface wasn't designed up front. Implementing `findNextDepartures()` revealed exactly two things it needed from the timetable — no more, no less.

**The Maven/Cucumber test runner:**
```java
@RunWith(CucumberWithSerenity.class)
@CucumberOptions(features = "src/test/resources/features/",
                 glue = "manning.bddinaction")
public class AcceptanceTestSuite {}
```

## Reference Tables

**Project layout (Serenity Cucumber Starter):**
| Path | Contents |
|---|---|
| `src/main/java` | Application source code |
| `src/test/java` | Test Java classes (step definitions, runners) |
| `src/test/resources/features/` | Cucumber feature files, grouped by capability |
| `pom.xml` | Maven build script |
| `build.gradle` | Gradle equivalent |

**Commands:**
| Command | Purpose |
|---|---|
| `mvn verify` | Download dependencies and run the suite |
| `mvn clean verify` | Full clean run; reports land in `target/site/serenity/index.html` |

**Change type → what to do first (§3.7):**
| Change request | First action |
|---|---|
| Modification of an existing feature | Update the automated acceptance criteria to reflect the new requirement |
| Bug your criteria didn't catch | Write new acceptance criteria that *reproduce* the bug, then fix, then use them to prove resolution |
| Change large enough to make criteria redundant | Delete the old acceptance criteria and write new ones |

## Worked Example

**The Illustrate conversation that reshaped the feature.**

Tracy gathers Jill (rail domain expert), Tess (tester), and Dave (developer) before work starts on "show the optimal route between two stations":

> **Tracy:** Can you give me an example of a commuter traveling between two stations?
> **Jill:** Sure, how about going from Epping to Town Hall?
> **Tracy:** And what would that look like?
> **Jill:** They'd take the T9 line — 8 to 16 trains per hour depending on time of day. We'd just propose the next scheduled trips.
> **Dave:** Is the next train that arrives always the best train to take?
> **Jill:** Not always; if the next is an all-stops and the following is an express, the following one might be better.
> **Tess:** Will there always be a next train?
> **Jill:** No; they stop around midnight. If the last train has left, we'd need to tell the commuter about night bus options.
> **Dave:** Are there any days trains don't run at all?
> **Jill:** I don't think so, but I'd have to check with the timetable people. *(→ pink card)*
> **Tracy:** Could a trip offer a choice of more than one line?
> **Jill:** Yes — Hornsby to Central could be T9 or T1, 37 to 48 minutes, trains every couple of minutes. We'd need departure and arrival times for both lines.

In under ten exchanges, "show the next train" became: express vs. all-stops matters, after-midnight needs a night-bus fallback, multiple lines can serve one trip, and a service-days question needs an answer. The team splits the feature into two stories — **Direct Connections** (one possible line, simple enough to build the architecture on) and **Alternative Routes** (multiple lines).

**Then the Formulate conversation refined the scenario three times.** Tess writes:

```gherkin
Given the next train leaves Hornsby at 8:02
When Travis wants to travel from Hornsby to Chatswood at 8:00
Then he should be told to take the 8:02 train
```

Jill reads it aloud and objects: *two* lines depart Hornsby; an 8:02 train could go either direction. Tess adds the line and direction:

```gherkin
Given the T1 train to Chatswood leaves Hornsby at 8:02
```

Jill still isn't happy: *"That's not very realistic. Travis only has two minutes to buy a ticket and get to the right platform. He really needs to be told about the next few trains, not just the next one."* Tess proposes showing the next two. Final form:

```gherkin
Given the T1 train to Chatswood leaves Hornsby at 8:02, 8:15, 8:21
When Travis wants to travel from Hornsby to Chatswood at 8:00
Then he should be told about the trains at: 8:02, 8:15
```

Reading the scenario aloud to a domain expert caught a correctness bug *and* a usability defect before a line of code existed.

**And the unit test conversation improved testability.** Tess's first attempt:

```java
List<LocalTime> proposedDepartures
    = itineraryService.findNextDepartures(LocalTime.of("8:25"), "Hornsby", "Central");
assertThat(proposedDepartures).containsExactly(LocalTime.of("8:30"));
```

> **Tess:** I'm not too happy with this test. It doesn't make it very clear *why* the answer is 8:30. Are we relying on test data that might change? Where does this time come from?

Dave's fix — make the test data explicit and local:

```java
private LocalTime at(String time) {
    return LocalTime.parse(time, DateTimeFormatter.ofPattern("H:mm"));
}

@Test
@DisplayName("should return the first train after the departure time")
void tripWithOneScheduledTime() {
    // Given
    timeTable = departures(at("8:10"), at("8:20"), at("8:30"));
    itineraries = new ItineraryService(timeTable);
    // When
    List<LocalTime> proposedDepartures
       = itineraries.findNextDepartures(at("8:25"), "Hornsby", "Central");
    // Then
    assertThat(proposedDepartures).containsExactly(at("8:30"));
}
```

Now the test carries its own answer: given trains at 8:10/8:20/8:30 and a request at 8:25, obviously 8:30. They then add `tripWithSeveralScheduledTimes()` (proves only two are returned) and `anAfterHoursTrip()` (the edge case where none are available and the result is empty).

**Maintenance in one edit.** Users later ask for the next *four* trains. Update the scenario's `Then` line, run it, watch it fail — the failure names exactly the gap. Use the unit tests to isolate `ItineraryService`, update `should propose the next 2 trains` to `should propose the next 4 trains`, change `.limit(2)` to `.limit(4)`. The requirement, the test, and the documentation all moved together because they are one artifact.

## Anti-patterns

- **A vision statement with no number in it**: unmeasurable goals can't guide trade-offs or tell you whether the app delivered.
- **Accepting the sponsor's stated goal as the goal**: "let commuters plan journeys online" hides the actual pain (missing connections, waiting on platforms).
- **Proposing features that don't trace to a behavior change**: the "rate railway stations" feature — plausible-sounding, zero actionable value to the target actor.
- **Unit tests whose expected value has no visible origin**: if a reader can't see *why* 8:30 is correct, the test is brittle and uncommunicative.
- **Building every collaborator you discover, immediately**: for complex code, stub it as an interface and stay on the current task.
- **Building a feature that takes more than one sprint without slicing it**: split into stories deliverable incrementally so feedback comes earlier and risk drops.
- **Assuming passing acceptance tests means auto-deploy to production**: that requires "a great deal of discipline and the utmost confidence" in the suite. Most enterprises still want exploratory testing — but the automated suite saves QA days or weeks of mechanical regression work.

## Key Takeaways
1. Put a measurable number and timeframe on the project vision before discussing any feature.
2. Run Impact Mapping (Why → Who → How → What) to derive features from goals rather than accepting a feature list.
3. Use Example Mapping's four colors during the Illustrate conversation; pink cards make unknowns explicit rather than assumed.
4. Read scenarios aloud to a domain expert — that is where correctness and usability defects surface cheapest.
5. Write glue code before production code and let it design your API; start from `@Then` and work backward.
6. Stub discovered collaborators as interfaces when the domain is complex; don't chase every dependency down at once.
7. Expect many unit tests per acceptance criterion — acceptance tests prove end-to-end behavior, unit tests localize the failure.
8. For maintenance, always change the acceptance criterion first and let it fail; the failure defines the work.

## Connects To
- **Ch 1–2**: the principles this chapter demonstrates end to end.
- **Ch 4**: Impact Mapping and Feature Injection in depth (Speculate).
- **Ch 5**: Gherkin notation in great detail (Formulate).
- **Ch 6**: Example Mapping and Feature Mapping in depth (Illustrate).
- **Ch 7–8**: from examples to executable specifications to automated acceptance tests (Formulate/Automate).
- **Ch 16**: living documentation and release evidence (Demonstrate).
- **Serenity BDD, Cucumber, Maven, JUnit 5, AssertJ**: the concrete stack used throughout this walkthrough.
