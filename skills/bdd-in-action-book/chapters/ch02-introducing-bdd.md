# Chapter 2: Introducing Behavior-Driven Development

## Core Idea
BDD began as Daniel Terhorst-North's attempt to make TDD teachable — by renaming tests as *behavior specifications* — and then expanded into requirements analysis, giving the whole lifecycle one ubiquitous language that is simultaneously specification, test, and documentation.

## Frameworks Introduced

- **The Nine BDD Principles** (§2.3) — the practices that define a BDD team:
  1. **Focus on features that deliver business value** — propose only features demonstrably tied to a business goal.
  2. **Work together to specify features** — BA + developer + tester + user, not a relay race.
  3. **Embrace uncertainty** — assume your *understanding* of requirements will evolve; seek early feedback rather than locking specs.
  4. **Illustrate features with concrete examples** — Given/When/Then, in the users' own vocabulary.
  5. **Don't write automated tests; write executable specifications** — same artifact serves as acceptance criteria, regression test, and requirement.
  6. **Apply the same principles to unit tests** — developer-facing executable specifications.
  7. **Deliver living documentation** — product documentation generated from passing specs.
  8. **Use living documentation to support maintenance** — maintenance is 40–80% of software cost (Glass).
  9. These activities are **continuous and repeated per feature**, not a linear waterfall (figure 2.2).

- **The Outside-In Approach**: start from the acceptance criteria and work down, building only what is needed to make them pass.
  - When to use: implementing any feature in a BDD team.
  - How: (1) take the acceptance criterion as the goal; (2) before writing code, reason about what the code *should do* and express that as a low-level, developer-facing executable specification; (3) write code to satisfy it; (4) repeat until the acceptance criterion passes.
  - Why it works: it applies the value filter recursively — "just as no feature is implemented unless it contributes to an identified business goal, no code is written unless it contributes to making an acceptance test pass."

- **"Should"-Naming for Unit Tests** (North's original insight): name unit tests as full sentences using the word *should*, describing what the class should do rather than which method is under test.
  - When to use: every unit test.
  - How: replace `testTransfer()` with `should_transfer_funds_to_a_different_bank()`; replace `BankAccountTest` with `WhenTransferringInternationalFunds`.
  - Why it works: naming by behavior decouples the test from the implementation (refactoring no longer forces test renames), makes intent obvious when the test breaks, and — critically — tells you *what test to write next*, which is where TDD learners get stuck.

- **The Two Levels of Executable Specification**:
  | | Customer-facing | Developer-facing |
  |---|---|---|
  | Audience | Business, end users | Developers |
  | Written by | Whole team collaboratively | Developers |
  | Vocabulary | Business domain | Technical/component |
  | Tools | Cucumber, SpecFlow | JUnit 5, NUnit, Mocha, RSpec |
  | Describes | How users interact with the system | Low-level component behavior |

## Key Concepts

- **Unit test** — a small test describing and verifying the behavior of an individual component (a method or function).
- **Acceptance test** — a business-facing test that end users or sponsors can use to check a feature works as intended.
- **Executable specification** — an automated test that illustrates and verifies how the application delivers a specific business requirement, written in business-readable form.
- **Feature** — a tangible, deliverable piece of functionality that helps the business achieve its business goals.
- **Gherkin** — the plain-language-with-structure format (`Given`/`When`/`Then`/`And`/`But`) used by most BDD tools.
- **Feature file** — a text file grouping one feature description with its scenarios.
- **Scenario** — a formalized example of how a feature works, composed of steps.
- **Scenario Outline** — a parameterized scenario run once per row of an `Examples:` table, with `<placeholder>` substitution.
- **Ubiquitous language** — (from Eric Evans' DDD) a shared vocabulary businesspeople and developers both use to describe and model the system.
- **Single source of truth** — because requirements *are* the executable specifications, there is one place to change, eliminating doc/test drift.

## Mental Models

- **Think of BDD's origin as a rename, not a new technique.** North changed what you *call* the artifact (specification, not test) and the naming convention (`should`), and TDD suddenly became teachable. The vocabulary shift is the intervention.
- **Use "users will design a solution for you, not tell you what they need" as your default expectation.** When users write requirements, they hand you their imagined implementation — forfeiting the team's design expertise and binding you to a possibly suboptimal solution.
- **Treat naming a test after its method as coupling.** `testTransfer()` is coupled to `transfer()`; rename the method and the test lies.
- **Think of executable specifications as communication artifacts that happen to validate.** "Executable specifications are about communication as much as they are about validation."
- **Use the BDD family names interchangeably when done well.** ATDD, Specification by Example (SBE), Story Test-Driven Development, and Example-Guided Development are converging; Gojko Adzic coined SBE specifically to reach nontesters put off by the word "test."

## Code Examples

**Implementation-coupled unit tests (the anti-pattern):**
```java
public class BankAccountTest {
    @Test
    public void testTransfer() {...}
    @Test
    public void testDeposit() {...}
}
```
- **What it demonstrates**: names say nothing about expected behavior, are coupled to method names, and give no signal about which tests remain to be written.

**Behavior-named specifications (the BDD form):**
```java
public class WhenTransferringInternationalFunds {
    @Test
    public void should_transfer_funds_to_a_local_account() {...}
    @Test
    public void should_transfer_funds_to_a_different_bank() {...}
    @Test
    public void should_deduct_fees_as_a_separate_transaction() {...}
}
```
- **What it demonstrates**: the class name states the context, each method states an expected behavior — the test reads as a specification.

**A Cucumber step definition in Java:**
```java
Client client;

@Given("{client} has a {accountType} account with ${int}")   // the step this implements
public void setupAccount(Client client,
                         AccountType accountType,
                         int balance) {
    this.client = client;
    client.opens(BankAccount.ofType(accountType).withBalance(balance));  // call application code
}
```
- **What it demonstrates**: Cucumber pattern-matches the Gherkin step text to a method, extracts the typed variables, and invokes the application code.

**A developer-facing executable specification (JUnit 5):**
```java
@DisplayName("When creating a new bank account")
class WhenCreatingANewAccount {

    @DisplayName("A new account should have an initial balance")
    @Test
    void newAccountBalance() {
        BankAccount account = BankAccount.ofType(AccountType.Savings)
                                         .withBalance(100);
        assertThat(account.getBalance()).isEqualTo(100.0);
    }
}
```
- **What it demonstrates**: the low-level spec flows directly from the step definition above — the step needed `BankAccount.ofType(...).withBalance(...)`, so that API gets designed and documented here.

## Reference Tables

**Gherkin keywords and their roles:**
| Keyword | Role |
|---|---|
| `Given` | Preconditions — prepares the test environment |
| `When` | The action under test |
| `Then` | The expected outcomes |
| `And` / `But` | Join several Given, When, or Then steps readably |

**Benefits vs. challenges of BDD:**
| Benefits (§2.4) | Challenges (§2.5) |
|---|---|
| Reduced waste — effort aligned to business goals | Requires high business engagement and collaboration |
| Reduced costs — fewer useless features, fewer bugs | Works best in an Agile or iterative context |
| Easier and safer changes — living docs + regression suite | Doesn't work well in a silo (offshore dev, separate QA) |
| Faster releases — testers freed for exploratory testing | Poorly written tests raise test-maintenance costs |

## Worked Example

**The Gherkin primer, end to end — a feature file for money transfer:**

```gherkin
Feature: Transferring money between accounts
  In order to manage my money more efficiently
  As a bank client
  I want to transfer funds between my accounts whenever I need to

  Scenario: Transferring money to a savings account
    Given Tess has a current account with $1000
    And a savings account with $2000.00
    When she transfers $500 from current to savings
    Then she should have $500 in her current account
    And she should have $2500 in her savings account

  Scenario: Transferring with insufficient funds
    Given Tess has a current account with $1000
    And a savings account with $2000.00
    When she transfers $1500 from current to savings
    Then she should receive an 'insufficient funds' error
    And she should have $1000 in her current account
    And she should have $2000 in her savings account
```

Note the second scenario is the **counterexample** — it pins down what happens when the rule *doesn't* apply, including that balances stay untouched.

**Collapsing repetition with a Scenario Outline:**

```gherkin
Scenario Outline: Earning interest
  Given Tess has a <account-type> account with $<initial-balance>
  And the interest rate for <account-type> accounts is <interest>
  When the monthly interest is calculated
  Then she should have earned $<earnings>
  And she should have $<new-balance> in her <account-type> account

  Examples:
  | initial-balance | account-type | interest | earnings | new-balance |
  | 10000           | Current      | 1.0      | 8.33     | 10008.33    |
  | 10000           | Savings      | 3.0      | 25       | 10025       |
  | 10000           | SuperSaver   | 5.0      | 41.67    | 10041.67    |
```

This runs three times, substituting each row into the `<...>` placeholders. It saves typing *and* makes the whole rule visible at a glance.

**Tabular data inside steps** — the same transfer scenario, more concisely:

```gherkin
Scenario: Transferring money between accounts within the bank
  Given Tess has the following accounts:
    | account | balance |
    | current | 1000    |
    | savings | 2000    |
  When she transfers 500.00 from current to savings
  Then her accounts should look like this:
    | account | balance |
    | current | 500     |
    | savings | 2500    |
```

## Anti-patterns

- **Writing unit tests named after the method under test**: couples test to implementation, hides intent, gives no guidance on what to test next.
- **Losing the big picture in TDD detail**: a known TDD failure mode — developers become so detail-focused they lose sight of the business goals.
- **Storing requirements in a Word doc or wiki alongside separate tests**: every change must be made twice, guaranteeing eventual inconsistency.
- **Handing detailed specs from BAs to an offshore dev team, with QA at the end**: you can still get BDD's code-quality benefits, but you lose the requirements-clarification benefits entirely.
- **QA intervening only at project end**: forfeits their contribution to requirements — testers are "particularly good" at proposing corner cases and edge cases during example discovery.
- **Automating acceptance tests without the right abstraction levels**: fragile tests at scale become a maintenance liability that discredits BDD.
- **Treating executable specifications as a magic documentation solution**: they aren't automatically meaningful or relevant — that takes practice and discipline, and other architectural docs are still needed.

## Key Takeaways
1. Name tests as behaviors with "should," and name the enclosing class as a context ("WhenTransferringInternationalFunds") — this single change is the origin of BDD.
2. Work outside-in: acceptance criterion → developer-facing spec → code. Write no code that doesn't serve a failing acceptance test.
3. Make requirements and tests the *same artifact* so they cannot drift; this is the single source of truth.
4. Use counterexamples (insufficient funds, edge cases) as first-class scenarios, not afterthoughts — this is where testers add the most value.
5. Reach for `Scenario Outline` + `Examples:` when several scenarios share a shape; reach for in-step tables when a single step carries structured data.
6. Expect BDD to fail in silos: it needs conversation between business, dev, and QA. Without engagement, adopt it at the coding level only and set expectations accordingly.
7. Budget for test-automation skill. Fragile, poorly abstracted acceptance tests are the most common way BDD adoptions collapse.

## Connects To
- **Ch 1**: the two failure axes BDD's principles map onto.
- **Ch 3**: the whirlwind tour applying all of this to one worked feature.
- **Ch 5**: Gherkin notation covered in much more detail.
- **Ch 9**: executable specifications as single source of truth, and writing solid acceptance tests.
- **Ch 16**: living documentation and release evidence.
- **TDD (Kent Beck)** and **DDD (Eric Evans)**: BDD's two direct ancestors — the red/green/refactor cycle and the ubiquitous language.
- **Specification by Example (Gojko Adzic)**, **ATDD**, **FIT/FitNesse (Ward Cunningham, Robert C. Martin)**, **JBehave (Terhorst-North)**: the surrounding family of practices and tools.
