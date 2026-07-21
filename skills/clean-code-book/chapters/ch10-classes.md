# Chapter 10: Classes

*with Jeff Langr*

## Core Idea
Classes should be small — measured not in lines but in **responsibilities**. We want systems composed of many small classes, not a few large ones; each small class encapsulates a single responsibility, has a single reason to change, and collaborates with a few others to achieve system behavior.

## Frameworks Introduced

- **Single Responsibility Principle (SRP)**: A class or module should have one, and only one, **reason to change**. This gives both a definition of responsibility and a guideline for class size.
  - When to use: Any time you find yourself opening a class to modify it — "the primary spur for taking action should be system change itself."
  - How:
    1. Enumerate the class's *reasons to change*, not its methods. (`SuperDashboard` tracks version info **and** manages Swing components — two reasons.)
    2. Try to name the class by what responsibilities it fulfills. If you cannot derive a concise name, it's likely too large.
    3. Apply the **25-word test**: write a brief description of the class in about 25 words without using "if," "and," "or," or "but." The first "and" is a hint of too many responsibilities.
    4. Watch for **weasel words** in class names — `Processor`, `Manager`, `Super` — which often hint at unfortunate aggregation of responsibilities.
    5. Look for private methods that apply only to a small subset of the class (e.g. `selectWithCriteria` relating only to `select`) — a useful heuristic for spotting potential areas for improvement.
    6. Extract the separable responsibility into its own class (`Version`), which often has high reuse potential.
  - Why it works / failure mode: Trying to identify responsibilities helps you recognize and create better abstractions. Failure mode: SRP is "often the most abused class design principle" — because getting software to work and making software clean are two very different activities, and too many of us think we're done once the program works, never switching to the concern of organization and cleanliness. The common objection — that many small classes make the big picture harder to see — is false: a system with many small classes has no more moving parts than one with a few large ones; there is just as much to learn either way.

- **Cohesion**
  - When to use: Judging whether a class is one class or several trying to escape.
  - How: Classes should have a small number of instance variables, and each method should manipulate one or more of them. The more variables a method manipulates, the more cohesive that method is to its class. A class in which **each variable is used by each method is maximally cohesive** — neither advisable nor generally possible, but keep cohesion high. When the strategy of keeping functions small and parameter lists short leads to a proliferation of instance variables used by only a subset of methods, it almost always means at least one other class is trying to get out. **When classes lose cohesion, split them.**
  - Why it works: If a few functions want to share certain variables, that makes them a class in their own right. So breaking a large function into many smaller functions often gives you the opportunity to split several smaller classes out as well — better organization, more transparent structure.

- **Open-Closed Principle (OCP)**: Classes should be open for extension but closed for modification.
  - When to use: When adding a new *kind* of the thing a class produces (a new SQL statement type).
  - How: Make the base class abstract with a single generating operation; refactor each public interface method out to its own derivative; move private methods directly to where they are needed; isolate common private behavior into utility classes. Then new features arrive as new subclasses and no existing class changes.
  - Why it works: The risk that one function breaks another becomes vanishingly small, comprehension time per class drops to almost nothing, and each class is isolated for testing. "In an ideal system, we incorporate new features by extending the system, not by making modifications to existing code."

- **Dependency Inversion Principle (DIP)**: Classes should depend upon abstractions, not on concrete details.
  - When to use: Whenever a class depends on volatile, slow, or external concrete details (`TokyoStockExchange`).
  - How: Extract the needed capability into a minimal interface (`StockExchange` with one method), have the concrete class implement it, and inject the interface through the constructor. Tests then supply a stub that fixes values.
  - Why it works: A system decoupled enough to be tested this way is also more flexible and promotes more reuse; the isolation makes each element easier to understand.

## Key Concepts
- **Responsibility**: A reason to change; the unit in which class size is measured.
- **God class**: A class exposing an enormous surface (`SuperDashboard`'s ~70 public methods) doing far too many things.
- **Weasel words**: Class-name components like `Processor`, `Manager`, `Super` that signal aggregated responsibilities.
- **The 25-word test**: Describing a class in ~25 words without "if," "and," "or," or "but."
- **Cohesion**: The degree to which a class's methods and variables are co-dependent and hang together as a logical whole.
- **Class organization**: Public static constants, then private static variables, then private instance variables, then public functions, with each private utility placed right after the public function that calls it — the stepdown rule; the program reads like a newspaper article.
- **Encapsulation as last resort**: Keep variables and utilities private, but "for us, tests rule" — if a test in the same package needs access, make it protected or package scope, after first looking for a way to maintain privacy.
- **Isolating from change**: Introducing interfaces and abstract classes so a client class isn't at risk when concrete details change.

## Mental Models
- Think of class design as **toolbox organization**: many small, well-labeled drawers, each with well-defined components — versus a few drawers you toss everything into.
- Use the **25-word description** as an instant SRP smoke test; the first conjunction is the seam.
- Think of **the primary goal as organizing complexity**, not eliminating it: every sizable system has a large amount of logic; you organize so a developer knows where to look and need only understand the directly affected complexity at any moment.
- Use **"can I name it concisely?"** as the first sizing question — ambiguous names track with excess responsibility.
- Think of **hard-to-test as a design verdict**: if `Portfolio` can't be tested without the real exchange, the dependency, not the test, is wrong.

## Anti-patterns
- **Counting methods instead of responsibilities**: `SuperDashboard` reduced to five methods is still wrong — it tracks version information *and* manages Swing components.
- **God classes / weasel-word names**: `Processor`, `Manager`, `Super` classes that aggregate unrelated reasons to change.
- **Stopping when the code works**: Failing to switch from "getting it to work" to organization and cleanliness, then moving on rather than breaking overstuffed classes into decoupled units.
- **Promoting locals to instance variables just to ease extraction**: It makes extraction easy but destroys cohesion — variables that exist solely to let a few functions share them. Split the class instead.
- **Public variables**: "There is seldom a good reason to have a public variable."
- **Depending on concrete external services**: `Portfolio` → `TokyoStockExchange` makes tests impossible when you get a different answer every five minutes.
- **Opening a class for every new feature type**: Any modification risks breaking other code in the class and forces full retest.

## Code Examples

A cohesive class — of the three methods only `size()` fails to use both variables:

```java
public class Stack {
  private int topOfStack = 0;
  List<Integer> elements = new LinkedList<Integer>();

  public int size() {
    return topOfStack;
  }

  public void push(int element) {
    topOfStack++;
    elements.add(element);
  }

  public int pop() throws PoppedWhenEmpty {
    if (topOfStack == 0)
      throw new PoppedWhenEmpty();
    int element = elements.get(--topOfStack);
    elements.remove(topOfStack);
    return element;
  }
}
```

- **What it demonstrates**: High cohesion — methods and variables hang together as a logical whole.

DIP in practice — the abstraction, the injection, and the resulting test:

```java
public interface StockExchange {
   Money currentPrice(String symbol);
}
```

```java
public Portfolio {
   private StockExchange exchange;
   public Portfolio(StockExchange exchange) {
      this.exchange = exchange;
   }
// …
}
```

```java
public class PortfolioTest {
   private FixedStockExchangeStub exchange;
   private Portfolio portfolio;

   @Before
   protected void setUp() throws Exception {
     exchange = new FixedStockExchangeStub();
     exchange.fix("MSFT", 100);
     portfolio = new Portfolio(exchange);
   }

   @Test
   public void GivenFiveMSFTTotalShouldBe500() throws Exception {
     portfolio.add(5, "MSFT");
     Assert.assertEquals(500, portfolio.value());
   }
}
```

- **What it demonstrates**: Depending on the `StockExchange` abstraction instead of `TokyoStockExchange` makes the test a simple fixed table lookup, and makes the system more flexible and reusable.

SRP extraction — five methods, two reasons to change, one class pulled out:

```java
public class SuperDashboard extends JFrame implements MetaDataUser
    public Component getLastFocusedComponent()
    public void setLastFocused(Component lastFocused)
    public int getMajorVersionNumber()
    public int getMinorVersionNumber()
    public int getBuildNumber()
}
```

```java
public class Version {
    public int getMajorVersionNumber()
    public int getMinorVersionNumber()
    public int getBuildNumber()
}
```

- **What it demonstrates**: Small ≠ single-responsibility; the extracted `Version` class has high reuse potential in other applications.

## Worked Example

**Splitting `Sql` by SRP and OCP.**

The starting class generates SQL strings from metadata, and doesn't yet support `update`:

```java
public class Sql {
   public Sql(String table, Column[] columns)
   public String create()
   public String insert(Object[] fields)
   public String selectAll()
   public String findByKey(String keyColumn, String keyValue)
   public String select(Column column, String pattern)
   public String select(Criteria criteria)
   public String preparedInsert()
   private String columnList(Column[] columns)
   private String valuesList(Object[] fields, final Column[] columns)
   private String selectWithCriteria(String criteria)
   private String placeholderList(Column[] columns)
}
```

It has **two reasons to change**: adding a new statement type, and altering the details of a single statement type (e.g. supporting subselects in `select`). That is an SRP violation, spottable organizationally: private methods like `selectWithCriteria` relate only to `select`.

Caveat Martin insists on: if `Sql` is deemed logically complete and `update` isn't needed for the foreseeable future, **leave it alone**. But as soon as you find yourself opening a class, consider fixing the design.

The refactoring gives each public method its own derivative; private methods move where they're needed; common private behavior is isolated into utility classes `Where` and `ColumnList`:

```java
abstract public class Sql {
   public Sql(String table, Column[] columns)
   abstract public String generate();
}

public class CreateSql extends Sql {
   public CreateSql(String table, Column[] columns)
   @Override public String generate()
}

public class InsertSql extends Sql {
   public InsertSql(String table, Column[] columns, Object[] fields)
   @Override public String generate()
   private String valuesList(Object[] fields, final Column[] columns)
}

public class SelectWithCriteriaSql extends Sql {
   public SelectWithCriteriaSql(
   String table, Column[] columns, Criteria criteria)
   @Override public String generate()
}

public class Where {
   public Where(String criteria)
   public String generate()
}

public class ColumnList {
   public ColumnList(Column[] columns)
   public String generate()
}
```

Result: each class is excruciatingly simple, comprehension time drops to almost nothing, cross-function breakage risk becomes vanishingly small, and each bit of logic is isolated for testing. When `update` arrives, **no existing class changes** — you drop in `UpdateSql`. SRP plus OCP.

**Knuth's `PrintPrimes` → three classes.** A single `main` with `M, RR, CC, WW, ORDMAX, P[], PAGENUMBER, PAGEOFFSET, ROWOFFSET, C, J, K, JPRIME, ORD, SQUARE, N, MULT[]`, deeply indented and tightly coupled, becomes three classes with three responsibilities:

- `PrimePrinter` — holds `main`; responsible for the execution environment. Changes if the method of invocation changes (e.g. conversion to a SOAP service).
- `RowColumnPagePrinter` — knows how to format a list of numbers into pages of a given rows × columns. Changes if output formatting changes.
- `PrimeGenerator` — knows how to generate primes; not meant to be instantiated, just a useful scope in which its variables are declared and kept hidden. Changes if the prime algorithm changes.

The program got **longer** — a little over one page to nearly three — for three reasons: longer, more descriptive variable names; function and class declarations used as a way to add commentary; and whitespace/formatting for readability. Critically, **this was not a rewrite**: the same algorithm and mechanics remain. The change was made by writing a test suite that verified the *precise* behavior of the first program, then making a myriad of tiny changes one at a time, executing after each to ensure behavior had not changed.

## Key Takeaways
1. Measure class size in responsibilities (reasons to change), not lines or method counts.
2. Name the class first — if you can't derive a concise name, or the 25-word description needs "and"/"or"/"if"/"but", it has too many responsibilities.
3. Keep instance variables few and used by many methods; when cohesion drops, split the class.
4. Breaking a large function into small ones usually reveals several smaller classes waiting to be extracted.
5. Let system change be the spur: don't preemptively split a logically complete class, but fix the design as soon as you must open one.
6. Structure so new features arrive as new subclasses/implementations (OCP) and clients depend on abstractions (DIP).
7. Refactor behind a test suite that verifies precise existing behavior, in a myriad of tiny verified steps — never a rewrite.
8. Organize class internals top-down: constants, statics, instance variables, then public functions each followed by its private utilities (stepdown rule).

## Connects To
- **Ch 3 (Functions)**: "Smaller is the primary rule" applies to both; extracting small functions is what surfaces the hidden classes.
- **Ch 4 (Comments)** / **Ch 5 (Formatting)**: Class and function declarations used as commentary; the stepdown rule and newspaper metaphor.
- **Ch 6 (Objects and Data Structures)**: Encapsulation and abstraction are the substrate SRP and cohesion operate on.
- **Ch 9 (Unit Tests)**: Tests drive encapsulation decisions ("tests rule") and testability is the practical test for DIP.
- **Ch 11 (Systems)** / **Ch 12 (Emergence)**: Scaling these principles from classes to system architecture.
- **SOLID principles [PPP, Agile Software Development: Principles, Patterns, and Practices, Robert C. Martin]**: SRP, OCP, and DIP are named and developed there.
- **[RDD, Object Design: Roles, Responsibilities, and Collaborations, Wirfs-Brock et al.]**: source of measuring classes by responsibilities.
- **[Knuth92, Literate Programming]**: source of the `PrintPrimes` example.
