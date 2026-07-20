# Chapter 1: The Goal of Unit Testing

## Core Idea
The goal of unit testing is **to enable sustainable growth of the software project** — not to find bugs, not to improve design, and definitely not to hit a coverage number. Tests are code, so every test has a cost as well as a benefit; only tests whose value exceeds their upkeep cost belong in the suite.

## Frameworks Introduced

- **Sustainable Growth as the Goal**: Unit testing exists to let a project maintain its development pace over time. Without tests, software entropy compounds until progress stalls; with *bad* tests, stagnation is merely delayed, not avoided.
  - When to use: Whenever you're justifying testing effort, arguing about coverage targets, or deciding whether a test earns its keep.
  - How: Ask of any test — "does this let us change code faster six months from now, net of its maintenance cost?" If no, delete it.

- **Cost–Benefit Analysis of a Test**: Every test's net value = (regressions caught + refactoring confidence) − (maintenance cost).
  - When to use: Reviewing an existing suite, or before adding a new test.
  - How: Price the cost side across four activities:
    1. Refactoring the test when you refactor underlying code
    2. Running the test on every code change
    3. Dealing with false alarms it raises
    4. Reading the test to understand how the code behaves
  - Why it works: It reframes "more tests = better" into an economic decision. Tests with near-zero or negative net value are common and actively harmful.

- **Good Negative Indicator / Bad Positive Indicator**: The book's most reusable reasoning tool, applied twice in this chapter.
  - When to use: Any time someone proposes a metric as a quality *target*.
  - How: Ask whether a low reading reliably signals a problem (negative indicator) and whether a high reading reliably signals health (positive indicator). Most testing metrics are the former only.
  - Applied to **testability**: hard-to-unit-test code is reliably bad (tight coupling). Easy-to-test code is *not* reliably good.
  - Applied to **coverage**: 10% coverage reliably means undertested. 100% coverage means nothing.

- **The Three Attributes of a Successful Test Suite**:
  1. It's **integrated into the development cycle** — run on every code change, however small. An unused test is pure cost.
  2. It **targets only the most important parts of the code base** — above all the **domain model** (business logic), which gives the best return per hour invested.
  3. It **provides maximum value with minimum maintenance cost** — the hardest attribute, and the subject of the rest of the book.

## Key Concepts

- **Software entropy** — the tendency of code to deteriorate: each change increases disorder, so fixing one bug introduces others until the base becomes unreliable.
- **Regression** — a feature that stops working as intended after an event (usually a code change). Synonymous with *software bug*; used interchangeably in this book.
- **Coverage metric** — the fraction of source code a test suite executes, from 0 to 100%.
- **Code coverage (test coverage)** — lines executed by ≥1 test ÷ total lines of production code. Trivially gamed by compacting code.
- **Branch coverage** — control-flow branches traversed by ≥1 test ÷ total branches. More precise than code coverage; immune to line-count games.
- **Assertion-free testing** — tests with no assertions (or wrapped in try/catch). They pass always, score 100% coverage, and verify nothing. The extreme failure mode of coverage targets.
- **Domain model** — the part of the code base containing business logic. The primary target for unit testing effort (term from Evans, *Domain-Driven Design*).
- **Enterprise application** — software automating an organization's inner processes. Characterized by high business-logic complexity, long lifespan, moderate data volume, and low/moderate performance requirements. This book's primary context.

## Mental Models

- **Think of code — including test code — as a liability, not an asset.** More code means more surface area for bugs and higher upkeep. Always solve the problem with less code.
- **Use "good negative indicator, bad positive indicator" whenever a metric becomes a target.** It cleanly separates *diagnostic* from *goal*.
- **Think of a coverage number as a patient's temperature.** A high reading is useful information. Making "normal temperature" the target invites an air conditioner pointed at the patient — technically on-target, medically useless.
- **Recognizing a good test ≠ writing one.** Recognizing needs a frame of reference; writing additionally needs code-design skill. Like telling good music from composing it — asymmetric effort. This is why the book spends so much time on production-code design.

## Anti-patterns

- **Mandating a specific coverage number** (100%, 90%, even 70%): creates a perverse incentive. Developers optimize for the metric instead of testing what matters. *"It's good to have a high level of coverage in core parts of your system. It's bad to make this high level a requirement."*
- **Assertion-free tests**: 100% coverage, zero value, permanent maintenance cost.
- **Treating tests as a free addition to production code**: tests have a cost of ownership; ignoring it is how suites turn net-negative.
- **Throwing more tests at a struggling project**: quantity doesn't reach the goal; only high-quality tests do.
- **Spreading testing effort evenly across the code base**: infrastructure, glue code, and external dependencies rarely repay thorough unit testing. Focus on the domain model.

## Code Examples

Coverage is gameable — the same test, the same verified behavior, two different coverage numbers:

```csharp
// 5 lines (braces count); test executes 4 => 80% code coverage
public static bool IsStringLong(string input)
{
    if (input.Length > 5)
        return true;        // not covered

    return false;
}

// Same logic inlined: 3 lines, all executed => 100% code coverage
public static bool IsStringLong(string input)
{
    return input.Length > 5 ? true : false;
}

public void Test()
{
    bool result = IsStringLong("abc");
    Assert.Equal(false, result);
}
```
- **What it demonstrates**: Refactoring changed coverage from 80% to 100% without improving the test suite at all. Branch coverage correctly reports 50% in *both* versions (one of two branches exercised).

Coverage can't see untested outcomes:

```csharp
public static bool WasLastStringLong { get; private set; }

public static bool IsStringLong(string input)
{
    bool result = input.Length > 5 ? true : false;
    WasLastStringLong = result;   // outcome 1 — implicit, never verified
    return result;                // outcome 2 — verified
}

public void Test()
{
    bool result = IsStringLong("abc");
    Assert.Equal(false, result);  // only checks outcome 2
}
```
- **What it demonstrates**: 100% code coverage / 50% branch coverage, yet an entire outcome goes unverified. Coverage proves code was *executed*, never that it was *tested*.

## Reference Tables

| Metric | Formula | Strength | Blind spot |
|---|---|---|---|
| Code coverage | lines executed ÷ total lines | Ubiquitous, cheap | Gamed by code compaction; ignores assertions |
| Branch coverage | branches traversed ÷ total branches | Immune to line-count games; path-aware | Still ignores assertions and outcomes |
| *Both* | — | Good negative indicator (low = trouble) | Can't see external-library code paths; can't tell you if you have *enough* tests |

## Worked Example

**Why no coverage metric can be trusted — the `int.Parse` case.**

```csharp
public static int Parse(string input)
{
    return int.Parse(input);
}

public void Test()
{
    int result = Parse("5");
    Assert.Equal(5, result);
}
```

Score it: branch coverage 100%. The method's outcome has exactly one component (the return value), and the test verifies it. By every metric this is a perfectly tested method.

It isn't. `int.Parse` contains many hidden code paths the metric cannot see. Each of these inputs takes a different one, and none is exercised:
- `null`
- `""` (empty string)
- `"Not an int"`
- a string too large to fit an `int`

Khorikov's conclusion is *not* that coverage metrics should account for external libraries — they shouldn't. It's that a metric which reports 100% on a demonstrably under-tested method cannot be used to judge suite quality. The only reliable method is to evaluate each test individually, by judgment, gradually. There is no automated substitute.

**A story from the trenches** (the chapter's cautionary tale): a company mandated 100% code coverage, with build systems rejecting any check-in that lowered it. Developers converged on the same workaround — wrap every test in `try`/`catch`, add no assertions, and it passes forever. The tests added zero value and drained real effort into upkeep. The mandate was walked back to 90%, then 80%, then retracted entirely.

## Key Takeaways

1. **The goal is sustainable growth**, not bug-finding and not better design (better design is a pleasant side effect of testability pressure, nothing more).
2. **Not all tests are created equal.** Weigh each test's value against its upkeep cost and delete the ones that lose.
3. **Both production code and test code are liabilities.** Solve problems with as little code as possible.
4. **Testability and coverage are good negative indicators and bad positive ones.** Use them to detect trouble, never as targets.
5. **Never mandate a coverage number.** High coverage in core areas is good; requiring it is corrosive.
6. **Concentrate testing on the domain model**, and structure the code so the domain model can be isolated from infrastructure and glue.
7. **There is no automated way to judge a test suite.** It requires per-test human judgment — which is exactly the frame of reference this book supplies.

## Connects To
- **Ch 4**: Delivers the promised frame of reference — the four pillars that let you evaluate any individual test.
- **Ch 2**: Defines what a "unit test" actually is, and why the definition drives everything else.
- **Ch 7**: Where "target the domain model" becomes actionable, via the Humble Object pattern and code quadrants.
- **Ch 11**: Anti-patterns analyzed using the Ch 4 attributes — the same evaluative lens applied to testing practices.
- **Domain-Driven Design (Evans, 2003)**: source of the *domain model* concept this book leans on throughout.
