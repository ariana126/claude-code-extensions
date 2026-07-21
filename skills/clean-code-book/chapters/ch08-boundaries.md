# Chapter 8: Boundaries

*by James Grenning*

## Core Idea
Code at the boundary between your system and code you don't control needs clear separation and tests that define expectations — depend on something *you* control, lest what you don't control ends up controlling you.

## Frameworks Introduced

- **Wrapping (encapsulating a boundary interface)**
  - When to use: Any third-party or boundary interface — `Map`, a vendor SDK, an open-source library — that would otherwise be passed around your system.
  - How:
    1. Identify the boundary type you are tempted to pass around (`Map<Sensor>`).
    2. Create an application-specific class (`Sensors`) that holds the boundary type as a **private** field.
    3. Expose only the operations your application actually needs (`getById`), tailored and constrained.
    4. Keep casting, generics, and type management inside the wrapper.
    5. Avoid returning the boundary interface from, or accepting it as an argument to, public APIs.
  - Why it works / failure mode: Boundary interfaces are designed for broad applicability; you want an interface focused on your particular needs. Confining it to one class or close family of classes means a change to the boundary (like Java 5 generics) touches one place, not hundreds. The wrapper is also where you enforce design and business rules — a raw `Map` cannot stop anyone from calling `clear()` or storing the wrong type. Failure mode: over-application — the advice is *not* that every use of `Map` be encapsulated, only that you not pass it around.

- **Learning Tests** (Jim Newkirk's term; [BeckTDD] pp. 136–137)
  - When to use: Before integrating an unfamiliar third-party package, and on every new release of it.
  - How:
    1. Read just enough documentation to write one small test calling the API the way you expect to use it in your application.
    2. Run it; let the failure teach you the next thing (`Logger` needs an `Appender`).
    3. Iterate — add the next piece, run, observe surprising behavior, google, adjust.
    4. Keep the accumulated tests as an encoded record of what you learned.
    5. Re-run them against each new release of the package.
  - Why it works / failure mode: You had to learn the API anyway, so the tests **cost nothing** and have a positive return on investment — they are precise, isolated, controlled experiments focused on what *you* want out of the API, and they surface behavioral differences in new releases immediately. Failure mode: learning inside production code means long debugging sessions where you can't tell whether the bug is yours or theirs — learning the code is hard, integrating it is hard, doing both at once is doubly hard.

- **The interface we wish we had** (with the ADAPTER pattern [GOF])
  - When to use: Depending on code that does not yet exist — an undefined API owned by another team.
  - How: Decide what you *want* to say across the boundary, define your own interface expressing exactly that (`Transmitter.transmit(frequency, stream)`), code your side against it, and once the real API arrives write an ADAPTER (`TransmitterAdapter`) to bridge the gap. The adapter encapsulates interaction with the API and provides a single place to change as the API evolves.
  - Why it works: You are not blocked, the interface is under your control, client code stays readable and focused on what it is trying to accomplish, and you get a convenient **seam** [WELC] for testing with a `FakeTransmitter`.

## Key Concepts
- **Boundary**: The place where code you control meets code you don't — third-party packages, open source, other teams' subsystems, or the not-yet-known.
- **Provider/user tension**: Providers strive for broad applicability across many environments; users want an interface focused on their particular needs.
- **Learning test**: A test that calls a third-party API as you expect to use it, written to check your understanding rather than to test their code.
- **Boundary test**: An outbound test exercising the boundary interface the same way production code does — eases version migration.
- **ADAPTER**: A class converting from your perfect interface to the provided one, isolating API evolution to one place.
- **Seam**: A place in the code where behavior can be substituted for testing (here, injecting a `FakeTransmitter`).

## Mental Models
- Use **"it's not your job to test third-party code, but it may be in your best interest"** — write the tests that verify your assumptions, not their correctness.
- Think of a boundary interface as **radioactive**: safe inside a lead-lined class, dangerous the moment it leaks into public signatures.
- Use **"write the interface you wish you had"** when the far side of a boundary is unknown or unpleasant — then adapt.
- Think of learning tests as **free plus interest**: the learning is the price you'd pay anyway; the regression coverage against future releases is the return.

## Anti-patterns
- **Passing boundary interfaces around the system**: `Map<Sensor>` in public signatures means many places to fix when the interface changes — exactly what blocked systems from adopting generics.
- **Clients casting out of a raw collection**: `Sensor s = (Sensor)sensors.get(sensorId);` repeated everywhere puts the burden of type management on every caller and doesn't tell its story.
- **Experimenting in production code**: Learning and integrating simultaneously leads to long debugging sessions where the bug's origin is unclear.
- **Blocking on an undefined API**: Waiting for another team instead of defining and adapting to your own interface.
- **Letting too much of your code know third-party particulars**: Multiplies maintenance points when the third-party code changes.

## Code Examples

Before — the boundary leaks, and every client casts:

```java
Map sensors = new HashMap();
…
Sensor s = (Sensor)sensors.get(sensorId );
```

Generics improve readability but don't fix the excess capability:

```java
Map<Sensor> sensors = new HashMap<Sensor>();
…
Sensor s = sensors.get(sensorId );
```

After — the boundary is hidden inside a tailored class:

```java
public class Sensors {
  private Map sensors = new HashMap();

  public Sensor getById(String id) {
    return (Sensor) sensors.get(id);
  }

  //snip
}
```

- **What it demonstrates**: Whether generics are used becomes an implementation detail; `Map` can evolve with little impact; the interface is constrained to what the application needs, so it's easier to understand and harder to misuse.

## Worked Example

**Learning log4j.** Goal: replace a custom logger with apache `log4j`. Read little, write a test, let failures teach.

Step 1 — expect "hello" on the console:

```java
@Test
public void testLogCreate() {
  Logger logger = Logger.getLogger("MyLogger");
  logger.info("hello");
}
```

Error: it needs something called an `Appender`. Step 2 — add a `ConsoleAppender`:

```java
@Test
public void testLogAddAppender() {
  Logger logger = Logger.getLogger("MyLogger");
  ConsoleAppender appender = new ConsoleAppender();
  logger.addAppender(appender);
  logger.info("hello");
}
```

Now the `Appender` has no output stream — odd. After googling:

```java
@Test
public void testLogAddAppender() {
  Logger logger = Logger.getLogger("MyLogger");
  logger.removeAllAppenders();
  logger.addAppender(new ConsoleAppender(
       new PatternLayout("%p %t %m%n"),
       ConsoleAppender.SYSTEM_OUT));
  logger.info("hello");
}
```

That works. Probing further: removing `ConsoleAppender.SystemOut` still prints; removing `PatternLayout` reintroduces the output-stream complaint. The docs reveal the default `ConsoleAppender` constructor is "unconfigured" — which feels like a bug or inconsistency in log4j. The knowledge is then encoded permanently:

```java
public class LogTest {
    private Logger logger;

    @Before
    public void initialize() {
        logger = Logger.getLogger("logger");
        logger.removeAllAppenders();
        Logger.getRootLogger().removeAllAppenders();
    }
    @Test
    public void basicLogger() {
        BasicConfigurator.configure();
        logger.info("basicLogger");
    }
    @Test
    public void addAppenderWithStream() {
    logger.addAppender(new ConsoleAppender(
        new PatternLayout("%p %t %m%n"),
        ConsoleAppender.SYSTEM_OUT));
       logger.info("addAppenderWithStream");
}
       @Test
       public void addAppenderWithoutStream() {
        logger.addAppender(new ConsoleAppender(
             new PatternLayout("%p %t %m%n")));
           logger.info("addAppenderWithoutStream");
        }
}
```

That knowledge is then encapsulated into an application logger class so the rest of the system is isolated from the log4j boundary interface.

**The Transmitter that didn't exist.** On a radio communications system, the "Transmitter" subsystem's owners hadn't defined their interface. Rather than block, the team wrote down what they *wanted* to say — "key the transmitter on the provided frequency and emit an analog representation of the data coming from this stream" — and defined their own `Transmitter` interface with a `transmit(frequency, stream)` method. `CommunicationsController` was coded against it and stayed clean and expressive. When the real API arrived, a `TransmitterAdapter` bridged the gap; a `FakeTransmitter` made the controller testable, and boundary tests confirmed correct use of the real API.

## Key Takeaways
1. Don't pass boundary interfaces around your system — keep them inside the class or close family of classes where they're used, and out of public API signatures.
2. Wrap boundary types in application-specific classes that expose only the operations you need and can enforce design and business rules.
3. Write learning tests to explore an unfamiliar third-party API instead of experimenting in production code.
4. Re-run learning tests on every new release of the package — they detect incompatible behavior changes immediately.
5. Support every clean boundary with outbound boundary tests that exercise the interface the way production code does; without them you'll stay on the old version too long.
6. When the far side of a boundary doesn't exist yet, define the interface you wish you had and connect it later with an ADAPTER.
7. Manage third-party boundaries by having very few places in the code that refer to them.

## Connects To
- **Ch 6 (Objects and Data Structures)**: `Sensors` hiding `Map` is data abstraction — exposing the essence, hiding the implementation.
- **Ch 7 (Error Handling)**: The `LocalPort` wrapper around `ACMEPort` is the same wrapping technique applied to exception types.
- **Ch 9 (Unit Tests)**: Learning tests and boundary tests must obey the same cleanliness and F.I.R.S.T. standards as any other test.
- **ADAPTER [GOF, Design Patterns]**: The named pattern for bridging your interface to a provided one.
- **Seams [WELC, Working Effectively with Legacy Code]**: The testing concept the adapter boundary creates.
- **[BeckTDD, Test Driven Development, Kent Beck]**: Origin of learning tests, pp. 136–137.
