# Chapter 9: Unit Tests

## Core Idea
Test code is just as important as production code — it is not a second-class citizen. Tests are what keep production code flexible, maintainable, and reusable, because tests enable change; if you let the tests rot, your code will rot too.

## Frameworks Introduced

- **The Three Laws of TDD**
  - **First Law**: You may not write production code until you have written a failing unit test.
  - **Second Law**: You may not write more of a unit test than is sufficient to fail, and not compiling is failing.
  - **Third Law**: You may not write more production code than is sufficient to pass the currently failing test.
  - When to use: As the default discipline for all production code.
  - How: Alternate between the three laws in a cycle **perhaps thirty seconds long**. Tests and production code are written *together*, with the tests just a few seconds ahead.
  - Why it works / failure mode: Working this way yields dozens of tests a day, hundreds a month, thousands a year, covering virtually all production code. Failure mode: the sheer bulk of tests — which can rival the size of the production code itself — becomes a daunting management problem unless the tests are kept clean.

- **F.I.R.S.T.** — five rules clean tests follow (Object Mentor training materials):
  - **Fast**: Tests should run quickly. Slow tests won't be run frequently; problems won't be found early enough to fix easily; you won't feel free to clean up the code; eventually the code rots.
  - **Independent**: Tests should not depend on each other. One test should not set up conditions for the next; you should be able to run each independently and in any order. When tests depend on each other, the first failure causes a cascade of downstream failures, making diagnosis difficult and hiding downstream defects.
  - **Repeatable**: Tests should be repeatable in any environment — production, QA, and on your laptop riding home on the train with no network. Otherwise you'll always have an excuse for failures and can't run tests when the environment is unavailable.
  - **Self-Validating**: Tests should have a boolean output — they pass or fail. No reading log files, no manually diffing text files. Otherwise failure becomes subjective and evaluation becomes a long manual chore.
  - **Timely**: Tests must be written in a timely fashion — unit tests written **just before** the production code that makes them pass. Write tests after the production code and you may find the code hard to test, decide some of it is too hard to test, or fail to design it to be testable.
  - When to use: As the checklist for reviewing any test suite.

- **BUILD-OPERATE-CHECK**
  - When to use: Structuring every test function.
  - How: Split the test into three visually obvious parts — (1) build up the test data, (2) operate on that test data, (3) check that the operation yielded the expected results. Optionally name the helpers with the **given-when-then** convention [RSpec] to make the structure explicit in the names.
  - Why it works: The reader works out what a test does very quickly, without being misled or overwhelmed by details.

- **Domain-Specific Testing Language**
  - When to use: Whenever tests are cluttered with API mechanics irrelevant to the assertion.
  - How: Rather than using the APIs programmers use to manipulate the system, build up a set of functions and utilities that wrap those APIs (`makePages`, `submitRequest`, `assertResponseIsXML`). This testing API is **not designed up front**; it evolves from continued refactoring of test code that has gotten too tainted by obfuscating detail.
  - Why it works: Density of expression — you say a lot with as few expressions as possible, and the tests become readable to whoever must maintain them later.

- **A Dual Standard**
  - When to use: Judging test-code quality against production-code quality.
  - How: Test code must still be simple, succinct, and expressive, but it need **not be as efficient** as production code — it runs in a test environment with different needs (e.g. string concatenation instead of `StringBuffer` in an embedded system's mock). The dual standard covers issues of memory or CPU efficiency but **never** issues of cleanliness.

- **One Assert per Test / Single Concept per Test**
  - How: Treat "one and only one assert statement per test function" as a **good guideline**, not a law — Martin usually builds a domain-specific testing language that supports it, but is not afraid to put more than one assert in a test. Where splitting causes duplication, factor the given/when into a TEMPLATE METHOD base class or a `@Before`, though that can be "too much mechanism for such a minor issue."
  - The better rule: **test a single concept in each test function**. "You should minimize the number of asserts per concept and test just one concept per test function."

## Key Concepts
- **Clean test**: One whose defining quality is "readability, readability, and readability" — clarity, simplicity, and density of expression.
- **Tests enable the -ilities**: Unit tests keep code flexible, maintainable, and reusable, because with tests you do not fear making changes; the higher your coverage, the less your fear.
- **Dirty tests**: Tests written "quick and dirty"; equivalent to, if not worse than, having no tests — they become an ever-increasing liability and eventually get discarded.
- **Testing API**: The evolved set of test-only functions and utilities forming a specialized language for the tests.
- **given-when-then**: A naming convention [RSpec] that makes BUILD-OPERATE-CHECK structure visible in function names.
- **Mental mapping**: Requiring readers to translate encoded values in their heads; normally avoided, but occasionally warranted (the `"HBchL"` state string).

## Mental Models
- Think of **test code as production code** — it requires thought, design, and care, and must be kept as clean as what it tests.
- Use **"tests enable change"** as the argument for cleanliness: no matter how nicely partitioned your design, without tests you won't dare improve it.
- Think of the **dirty-test death spiral**: dirty tests → expensive to change → discarded → defects rise → fear of change → production code rots.
- Use a **domain-specific testing language** when your eye has to bounce between mechanics and meaning; refactor detail out until the assertion is the sentence.

## Anti-patterns
- **Deciding test code needn't meet production standards**: The team Martin coached let variables go unnamed and test functions grow long; maintenance cost rose release over release, developers blamed the tests, and the suite was discarded entirely.
- **Duplicate setup code in tests**: Repeated `addPage`/`assertSubString` calls swamp intent [G5].
- **Irrelevant detail in tests**: `PathParser` calls, responder construction, and response casting obfuscate what is being tested; "this code was not designed to be read."
- **Assert-name/sense ping-pong**: `assertTrue(hw.heaterState()); assertFalse(hw.coolerState());` forces the eye to track left and right — tedious and unreliable.
- **Miscellaneous multi-concept tests**: `testAddMonths` tests three independent things at once, forcing the reader to figure out why each section is there — and hiding the general rule (and a missing Feb 28 → Mar 28 test).
- **Writing tests after the production code**: Yields untestable designs.

## Code Examples

Before — detail-swamped test [Listing 9-1]:

```java
public void testGetPageHieratchyAsXml() throws Exception
{
  crawler.addPage(root, PathParser.parse("PageOne"));
  crawler.addPage(root, PathParser.parse("PageOne.ChildOne"));
  crawler.addPage(root, PathParser.parse("PageTwo"));

  request.setResource("root");
  request.addInput("type", "pages");
  Responder responder = new SerializedPageResponder();
  SimpleResponse response =
    (SimpleResponse) responder.makeResponse(
       new FitNesseContext(root), request);
  String xml = response.getContent();

  assertEquals("text/xml", response.getContentType());
  assertSubString("<name>PageOne</name>", xml);
  assertSubString("<name>PageTwo</name>", xml);
  assertSubString("<name>ChildOne</name>", xml);
}
```

After — BUILD-OPERATE-CHECK made obvious [Listing 9-2]:

```java
public void testGetPageHierarchyAsXml() throws Exception {
  makePages("PageOne", "PageOne.ChildOne", "PageTwo");

  submitRequest("root", "type:pages");

  assertResponseIsXML();
  assertResponseContains(
    "<name>PageOne</name>", "<name>PageTwo</name>", "<name>ChildOne</name>"
  );
}
```

- **What it demonstrates**: Same behavior, but only the data types and functions the test truly needs remain; the three-part structure is visible at a glance.

Single-assert split with given-when-then naming [Listing 9-7]:

```java
public void testGetPageHierarchyAsXml() throws Exception {
    givenPages("PageOne", "PageOne.ChildOne", "PageTwo");

    whenRequestIsIssued("root", "type:pages");

    thenResponseShouldBeXML();
}
public void testGetPageHierarchyHasRightTags() throws Exception {
    givenPages("PageOne", "PageOne.ChildOne", "PageTwo");

    whenRequestIsIssued("root", "type:pages");

    thenResponseShouldContain(
      "<name>PageOne</name>", "<name>PageTwo</name>", "<name>ChildOne</name>"
    );
}
```

- **What it demonstrates**: The single-assert rule is achievable — but at the cost of duplication, which is why Martin ultimately prefers the multiple asserts of Listing 9-2.

## Reference Tables

| F.I.R.S.T. | Rule | Cost of violating |
|---|---|---|
| **F**ast | Tests run quickly | Run infrequently → problems found late → code rots |
| **I**ndependent | No test sets up another; any order | Cascading failures hide downstream defects |
| **R**epeatable | Run in prod, QA, laptop, offline | Always an excuse for failures; can't run without the environment |
| **S**elf-Validating | Boolean pass/fail output | Failure becomes subjective; long manual evaluation |
| **T**imely | Written just before the production code | Production code turns out hard or impossible to test |

## Worked Example

**The environment controller: refactoring toward a testing language.**

Original — readable but tedious, the eye bouncing between state name and assert sense [Listing 9-3]:

```java
@Test
  public void turnOnLoTempAlarmAtThreashold() throws Exception {
    hw.setTemp(WAY_TOO_COLD);
    controller.tic();
    assertTrue(hw.heaterState());
    assertTrue(hw.blowerState());
    assertFalse(hw.coolerState());
    assertFalse(hw.hiTempAlarm());
    assertTrue(hw.loTempAlarm());
  }
```

Refactored — `tic` hidden behind `wayTooCold()`, and the whole end state encoded in one string [Listing 9-4/9-5]. Upper case means "on," lower case means "off," letters always ordered `{heater, blower, cooler, hi-temp-alarm, lo-temp-alarm}`:

```java
@Test
public void turnOnCoolerAndBlowerIfTooHot() throws Exception {
  tooHot();
  assertEquals("hBChl", hw.getState());
}

@Test
public void turnOnHeaterAndBlowerIfTooCold() throws Exception {
  tooCold();
  assertEquals("HBchl", hw.getState());
}

@Test
public void turnOnHiTempAlarmAtThreshold() throws Exception {
  wayTooHot();
  assertEquals("hBCHl", hw.getState());
}
@Test
public void turnOnLoTempAlarmAtThreshold() throws Exception {
  wayTooCold();
  assertEquals("HBchL", hw.getState());
}
```

The mock's encoder is deliberately inefficient — the dual standard at work:

```java
public String getState() {
  String state = "";
  state += heater ? "H" : "h";
  state += blower ? "B" : "b";
  state += cooler ? "C" : "c";
  state += hiTempAlarm ? "H" : "h";
  state += loTempAlarm ? "L" : "l";
  return state;
}
```

A `StringBuffer` would be faster and matters in an embedded real-time system with constrained memory — but the test environment is not constrained, so the cleaner, slower code wins. This is close to violating the "avoid mental mapping" rule, yet is appropriate here: once you know the meaning, your eyes glide across the string.

**Single concept per test: SerialDate.** This test [Listing 9-8] mixes three independent concepts:

```java
public void testAddMonths() {
    SerialDate d1 = SerialDate.createInstance(31, 5, 2004);

    SerialDate d2 = SerialDate.addMonths(1, d1);
    assertEquals(30, d2.getDayOfMonth());
    assertEquals(6, d2.getMonth());
    assertEquals(2004, d2.getYYYY());

    SerialDate d3 = SerialDate.addMonths(2, d1);
    …
    SerialDate d4 = SerialDate.addMonths(1, SerialDate.addMonths(1, d1));
    …
}
```

Restated as three separate given-when-then tests:
- Given the last day of a 31-day month (May): when you add one month whose last day is the 30th (June), then the date should be the 30th, not the 31st.
- Given the same: when you add two months, and the final month has 31 days, then the date should be the 31st.
- Given the last day of a 30-day month (June): when you add one month whose last day is the 31st, then the date should be the 30th, not the 31st.

Stated this way, the hidden general rule appears — when you increment the month, the date can be no greater than the last day of that month — which implies incrementing February 28th should yield March 28th. **That test is missing** and would be useful to write. It's not the multiple asserts per section that causes the problem; it's testing more than one concept.

## Key Takeaways
1. Follow the Three Laws of TDD; the cycle is about thirty seconds long, with tests just seconds ahead of production code.
2. Hold test code to production standards of cleanliness — dirty tests are equivalent to, if not worse than, no tests.
3. Structure every test as BUILD-OPERATE-CHECK, optionally named given-when-then.
4. Grow a domain-specific testing language by refactoring detail out of tests; never design it up front.
5. Apply the dual standard: tests may be inefficient, but never unclean.
6. Treat one assert per test as an aspiration; the firm rule is one concept per test, minimizing asserts per concept.
7. Check every test against F.I.R.S.T. — Fast, Independent, Repeatable, Self-Validating, Timely.

## Connects To
- **Ch 3 (Functions)**: Test functions obey the same rules — short, descriptive, one level of abstraction.
- **Ch 2 (Meaningful Names)**: "Avoid Mental Mapping" (p. 25) is the rule the `"HBchL"` encoding deliberately bends.
- **Ch 8 (Boundaries)**: Learning tests and boundary tests are unit tests and must meet these standards.
- **Ch 10 (Classes)**: The `Portfolio`/`StockExchange` example shows how testability drives class design (DIP); tests are why encapsulation is loosened to protected/package scope.
- **Ch 17 (Smells and Heuristics)**: G5 (Duplication) drives the Listing 9-1 → 9-2 refactoring.
- **TEMPLATE METHOD [GOF]**: The pattern for removing duplication when splitting tests to one assert each.
- **[RSpec]**: Source of the given-when-then convention.
