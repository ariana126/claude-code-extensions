# Chapter 3: Functions

## Core Idea
Functions should be small, do one thing, and operate at exactly one level of abstraction — so that a source file reads as a top-down narrative of TO-paragraphs telling the story of the system.

## Frameworks Introduced
- **Small!** — "The first rule of functions is that they should be small. The second rule of functions is that they should be smaller than that."
  - When to use: Always; as the first thing you check after getting code working.
  - How: Functions should hardly ever be 20 lines long. Blocks within `if`, `else`, and `while` statements should be **one line long**, and that line should probably be a function call — which keeps the enclosing function small *and* adds documentary value via the called function's descriptive name. The **indent level of a function should not be greater than one or two**. Martin's ideal, from Kent Beck's `Sparkle` program: every function two, three, or four lines long, each transparently obvious, each telling a story, each leading to the next in a compelling order.
  - Why it works / failure mode: Small functions can be named precisely, which is where their documentary value comes from. Failure mode: extracting a function whose name merely restates its implementation (`includeSetupsAndTeardownsIfTestPage`) — that changes nothing because it doesn't change the level of abstraction.

- **Do One Thing** — "FUNCTIONS SHOULD DO ONE THING. THEY SHOULD DO IT WELL. THEY SHOULD DO IT ONLY."
  - When to use: Whenever you can't tell whether a function is too big.
  - How: Three concrete tests. (1) **The TO paragraph test** — can you describe the function as "TO <FunctionName>, we do X, then Y"? If the steps are all one level of abstraction *below* the function's name, it does one thing. (2) **The extraction test** — if you can extract another function from it with a name that is not merely a restatement of its implementation, it is doing more than one thing [G34]. (3) **The sections test** — functions that do one thing cannot be reasonably divided into sections like *declarations*, *initializations*, and *sieve*.
  - Why it works / failure mode: "One thing" is defined relative to the function's *name*, not to some absolute count of operations — which is why `renderPageWithSetupsAndTeardowns` doing three visible steps still does one thing.

- **One Level of Abstraction per Function**
  - When to use: Reviewing any function that mixes a domain call with a string manipulation.
  - How: Scan the statements and grade each one high / intermediate / low. Listing 3-1 mixes `getHtml()` (high), `PathParser.render(pagePath)` (intermediate), and `.append("\n")` (remarkably low). Push the low ones down into named helpers.
  - Why it works / failure mode: Readers can't tell whether an expression is an essential concept or a detail. Worse — like broken windows, once details are mixed with essential concepts, more and more details tend to accrete within the function.

- **The Stepdown Rule**
  - When to use: Ordering functions within a file.
  - How: Every function is followed by those at the next level of abstraction, so you can read the program descending one level at a time. Read the module as a set of TO paragraphs: *To include the setups and teardowns, we include setups, then the test page content, then the teardowns. To include the setups, we include the suite setup if this is a suite, then the regular setup. To include the suite setup, we search the parent hierarchy for the "SuiteSetUp" page and add an include statement with the path of that page. To search the parent…*
  - Why it works / failure mode: Making the code read like a top-down set of TO paragraphs is the effective technique for keeping abstraction level consistent — it is "the key to keeping functions short and making sure they do one thing." Martin notes it is very difficult for programmers to learn.

- **Command Query Separation**
  - When to use: Any function that both mutates and reports.
  - How: Functions should either do something or answer something, but not both. Split `public boolean set(String attribute, String value)` into `attributeExists(...)` and `setAttribute(...)`.
  - Why it works / failure mode: `if (set("username", "unclebob"))` is ambiguous because the reader can't tell whether `set` is a verb or an adjective. Renaming to `setAndCheckIfExists` doesn't help; only separation removes the ambiguity.

- **Error Handling Is One Thing**
  - When to use: Any function containing `try`.
  - How: If the keyword `try` exists in a function, it should be the **very first word in the function**, and there should be **nothing after the `catch`/`finally` blocks**. Extract the bodies of `try` and `catch` into their own functions.

## Key Concepts
- **TO paragraph**: A description of a function in the form "TO <name>, we do these steps" — the test for whether the steps sit one level below the name. (From LOGO, where `TO` played the role of `def`.)
- **Niladic / monadic / dyadic / triadic / polyadic**: Zero / one / two / three / more-than-three arguments.
- **Monadic forms**: The three legitimate uses of a single argument — asking a **question** about it (`boolean fileExists("MyFile")`), **transforming** it and returning the result (`InputStream fileOpen("MyFile")`), or an **event** (`void passwordAttemptFailedNtimes(int attempts)`).
- **Flag argument**: A boolean parameter — a signature-level confession that the function does one thing if true and another if false.
- **Keyword form of a function name**: Encoding the argument names into the function name (`assertExpectedEqualsActual(expected, actual)`) to defeat argument-order confusion.
- **Side effect**: A hidden action beyond what the name promises; produces temporal coupling and order dependencies. "Side effects are lies."
- **Temporal coupling**: A hidden constraint that a function can only be called at certain times — e.g. `checkPassword` calling `Session.initialize()`.
- **Dependency magnet**: A widely imported class or enum (like an `Error` enum) whose every change forces recompiling and redeploying its users, creating pressure to reuse old error codes instead of adding new ones.

## Mental Models
- **Think of a program as a domain-specific language you are designing.** Functions are the verbs, classes are the nouns. "The art of programming is, and has always been, the art of language design." Master programmers think of systems as stories to be told rather than programs to be written.
- **Write functions like prose: draft first, then massage.** Martin's own first drafts are long, deeply indented, badly named, and duplicated — but covered by unit tests. Then he splits functions, changes names, eliminates duplication, shrinks and reorders methods, sometimes breaking out whole classes, all while keeping the tests passing. "I don't write them that way to start. I don't think anyone could."
- **Use "anything that forces you to check the function signature" as a smell.** It is equivalent to a double-take — a cognitive break, and should be avoided. That's the real charge against output arguments and against dyads with no natural ordering.
- **When a switch is unavoidable, bury it in the basement.** Tolerate a `switch` only if it appears **once**, is used to create polymorphic objects, and is hidden behind an inheritance relationship so the rest of the system can't see it [G23].
- **Think of `this` as the output argument OO already gave you.** Prefer `report.appendFooter()` over `appendFooter(report)`; if a function must change state, have it change the state of its owning object.

## Anti-patterns
- **Switch statements in business logic**: Large; grows with new types; does N things by nature; violates SRP (more than one reason to change) and OCP (must change whenever a type is added). Worst of all, an unlimited number of *other* functions (`isPayday`, `deliverPay`) will replicate the same structure.
- **Flag arguments**: "Passing a boolean into a function is a truly terrible practice." `render(true)` is plain confusing; split into `renderForSuite()` and `renderForSingleTest()`.
- **Output arguments**: `appendFooter(s)` — is `s` the footer or the thing appended to? Resolving it costs a signature lookup.
- **Transformation via output argument**: `void transform(StringBuffer out)` — a transformation's result must appear as the return value; `StringBuffer transform(StringBuffer in)` is better even if the implementation just returns its input.
- **Returning error codes**: A subtle violation of Command Query Separation that promotes commands as `if` predicates, forces the caller to handle errors immediately, and produces deep nesting.
- **The `Error` enum**: A dependency magnet. Exceptions are *derivatives* of an exception class and can be added without forcing recompilation or redeployment (an application of OCP).
- **Duplication**: In Listing 3-1 one algorithm is repeated four times (SetUp, SuiteSetUp, TearDown, SuiteTearDown), intermixed and non-uniform so it's hard to spot — a fourfold modification cost and a fourfold opportunity for an error of omission. "Duplication may be the root of all evil in software."
- **Dogmatic single-entry/single-exit**: Dijkstra's structured-programming rules serve little benefit when functions are very small; occasional multiple `return`, `break`, or `continue` does no harm and is sometimes more expressive. `goto` only makes sense in large functions, so avoid it.

## Code Examples

Side effect — spot it:

```java
public class UserValidator {
  private Cryptographer cryptographer;

  public boolean checkPassword(String userName, String password) {
    User user = UserGateway.findByName(userName);
    if (user != User.NULL) {
      String codedPhrase = user.getPhraseEncodedByPassword();
      String phrase = cryptographer.decrypt(codedPhrase, password);
      if ("Valid Password".equals(phrase)) {
        Session.initialize();
        return true;
      }
    }
    return false;
  }
}
```
- **What it demonstrates**: `Session.initialize()` — a caller who believes the name risks erasing existing session data merely by validating a user. Renaming to `checkPasswordAndInitializeSession` would be honest but violates Do One Thing; the real fix is to remove the side effect.

Error codes vs. exceptions — before:

```java
if (deletePage(page) == E_OK) {
  if (registry.deleteReference(page.name) == E_OK) {
    if (configKeys.deleteKey(page.name.makeKey()) == E_OK){
      logger.log("page deleted");
    } else {
      logger.log("configKey not deleted");
    }
  } else {
    logger.log("deleteReference from registry failed");
  }
} else {
  logger.log("delete failed");
  return E_ERROR;
}
```

After — happy path separated from error processing, then extracted:

```java
public void delete(Page page) {
  try {
    deletePageAndAllReferences(page);
  }
  catch (Exception e) {
    logError(e);
  }
}

private void deletePageAndAllReferences(Page page) throws Exception {
  deletePage(page);
  registry.deleteReference(page.name);
  configKeys.deleteKey(page.name.makeKey());
}

private void logError(Exception e) {
  logger.log(e.getMessage());
}
```
- **What it demonstrates**: `delete` is all about error processing — easy to understand and then ignore. `deletePageAndAllReferences` is all about deleting a page — error handling can be ignored. Each does one thing.

Burying the switch in an Abstract Factory:

```java
public abstract class Employee {
  public abstract boolean isPayday();
  public abstract Money calculatePay();
  public abstract void deliverPay(Money pay);
}
-----------------
public interface EmployeeFactory {
  public Employee makeEmployee(EmployeeRecord r) throws InvalidEmployeeType;
}
-----------------
public class EmployeeFactoryImpl implements EmployeeFactory {
  public Employee makeEmployee(EmployeeRecord r) throws InvalidEmployeeType {
    switch (r.type) {
      case COMMISSIONED:
        return new CommissionedEmployee(r) ;
      case HOURLY:
        return new HourlyEmployee(r);
      case SALARIED:
        return new SalariedEmploye(r);
      default:
        throw new InvalidEmployeeType(r.type);
    }
  }
}
```
- **What it demonstrates**: One `switch`, used only to create polymorphic objects; `calculatePay`, `isPayday`, and `deliverPay` all dispatch through the `Employee` interface instead of re-implementing the type dispatch.

## Reference Tables

| Arity | Name | Verdict |
|---|---|---|
| 0 | Niladic | Ideal |
| 1 | Monadic | Next best — use only the question, transformation, or event form |
| 2 | Dyadic | Acceptable but costly; convert to monad where a mechanism exists |
| 3 | Triadic | Avoid where possible — think very carefully first |
| 4+ | Polyadic | Requires very special justification — and then shouldn't be used anyway |

Techniques for converting a dyad to a monad (`writeField(outputStream, name)`):
1. Make `writeField` a member of `outputStream` → `outputStream.writeField(name)`.
2. Make `outputStream` a member variable of the current class → `writeField(name)`.
3. Extract a new class `FieldWriter` taking `outputStream` in its constructor, with a `write` method.

When more than two or three arguments are needed, wrap them into an **argument object** — `makeCircle(Point center, double radius)` beats `makeCircle(double x, double y, double radius)`. Groups of variables passed together are likely part of a concept that deserves a name.

**Argument lists** (varargs) count as one argument if treated identically — `public String format(String format, Object... args)` is dyadic. So `void monad(Integer... args)`, `void dyad(String name, Integer... args)`, `void triad(String name, int count, Integer... args)` — and no further.

## Worked Example
**`testableHtml` → `SetupTeardownIncluder`, in three passes.**

Listing 3-1 is a ~60-line FitNesse function with doubly nested `if`s controlled by flags, arcane strings (`"!include -setup ."`, `"\n"`), three different abstraction levels, and one algorithm duplicated four times for SetUp / SuiteSetUp / TearDown / SuiteTearDown. Three minutes of study is not enough to understand it.

Pass 1 — extract methods, rename, restructure. Nine lines:

```java
public static String renderPageWithSetupsAndTeardowns(
  PageData pageData, boolean isSuite
) throws Exception {
  boolean isTestPage = pageData.hasAttribute("Test");
  if (isTestPage) {
    WikiPage testPage = pageData.getWikiPage();
    StringBuffer newPageContent = new StringBuffer();
    includeSetupPages(testPage, newPageContent, isSuite);
    newPageContent.append(pageData.getContent());
    includeTeardownPages(testPage, newPageContent, isSuite);
    pageData.setContent(newPageContent.toString());
  }
  return pageData.getHtml();
}
```

You can now tell, without knowing FitNesse, that this includes setup and teardown pages into a test page and renders it as HTML. But it still holds two levels of abstraction, which is why it can shrink again.

Pass 2 — down to four lines:

```java
public static String renderPageWithSetupsAndTeardowns(
PageData pageData, boolean isSuite) throws Exception {
  if (isTestPage(pageData))
    includeSetupAndTeardownPages(pageData, isSuite);
  return pageData.getHtml();
}
```

TO RenderPageWithSetupsAndTeardowns, we check to see whether the page is a test page and if so, we include the setups and teardowns. In either case we render the page in HTML. Three visible steps, all one level below the name — therefore one thing.

Pass 3 — Listing 3-7, the whole module as a class. Note how the arguments disappear into fields (`pageData`, `isSuite`, `testPage`, `newPageContent`, `pageCrawler`), so that `includeSetupPage()` reads better than `includeSetupPageInto(newPageContent)`, and how the fourfold duplication collapses into a single `include(pageName, arg)` helper:

```java
public class SetupTeardownIncluder {
  private PageData pageData;
  private boolean isSuite;
  private WikiPage testPage;
  private StringBuffer newPageContent;
  private PageCrawler pageCrawler;

  public static String render(PageData pageData) throws Exception {
    return render(pageData, false);
  }

  public static String render(PageData pageData, boolean isSuite)
    throws Exception {
    return new SetupTeardownIncluder(pageData).render(isSuite);
  }

  private String render(boolean isSuite) throws Exception {
    this.isSuite = isSuite;
    if (isTestPage())
      includeSetupAndTeardownPages();
    return pageData.getHtml();
  }

  private boolean isTestPage() throws Exception {
    return pageData.hasAttribute("Test");
  }

  private void includeSetupAndTeardownPages() throws Exception {
    includeSetupPages();
    includePageContent();
    includeTeardownPages();
    updatePageContent();
  }

  private void includeSetupPages() throws Exception {
    if (isSuite)
      includeSuiteSetupPage();
    includeSetupPage();
  }

  private void includeSuiteSetupPage() throws Exception {
    include(SuiteResponder.SUITE_SETUP_NAME, "-setup");
  }

  private void includeSetupPage() throws Exception {
    include("SetUp", "-setup");
  }
  // ... includeTeardownPage(), includeSuiteTeardownPage(), include(), etc.
}
```

Naming discipline in the result: `includeSetupAndTeardownPages`, `includeSetupPages`, `includeSuiteSetupPage`, `includeSetupPage`. The similar phraseology lets the sequence tell a story — shown that list, you'd immediately ask "what happened to `includeTeardownPages`, `includeSuiteTeardownPage`, and `includeTeardownPage`?" That is Ward's principle in action: pretty much what you expected.

The one compromise Martin flags: `isSuite` remained a flag argument because callers were already passing it and he wanted to limit refactoring scope. Ideally it would be `renderForSuite()` and `renderForSingleTest()`.

## Key Takeaways
1. Keep functions well under 20 lines, with an indent level of no more than one or two; blocks inside `if`/`else`/`while` should be a single line that calls a well-named function.
2. Verify "one thing" with the TO-paragraph test, the extraction test, and the sections test — not by counting statements.
3. Order functions by the Stepdown Rule so the file reads top-down, one abstraction level at a time.
4. Drive argument count toward zero; convert dyads to monads via membership or an extracted class, and bundle 3+ arguments into an argument object.
5. Never pass a flag argument — split the function into two named functions instead.
6. Eliminate side effects; they create temporal couplings that the name conceals.
7. Separate commands from queries, and prefer exceptions to error codes; `try` should be the first word in a function and nothing should follow `catch`/`finally`.
8. Don't write clean functions in the first draft. Write it working with tests covering it, then massage: extract, rename, deduplicate, reorder.

## Connects To
- **Ch 2 (Meaningful Names)**: "Use Descriptive Names" — a long descriptive name beats a short enigmatic one *and* beats a long descriptive comment; the smaller the function, the easier to name. Hunting for a good name often produces a favorable restructuring.
- **Ch 4 (Comments)**: The `generatePrimes` sections example (Listing 4-7) is cited here as the sections-within-functions smell.
- **Ch 7 (Error Handling)**: Extract Try/Catch Blocks and Prefer Exceptions to Returning Error Codes are developed further.
- **Ch 10 (Classes)**: Breaking out a class (`SetupTeardownIncluder`, `FieldWriter`) is the standard escape hatch when argument counts or function counts grow.
- **Ch 17 [G23], [G34]**: The switch-statement rule and the extract-a-non-restating-function test.
- **SRP / OCP (PPP)**: Cited directly as what the payroll `switch` violates and what exception derivatives satisfy.
- **DRY (The Pragmatic Programmer)**: The named source of the duplication argument.
- **Abstract Factory (GoF)**: The pattern that buries the type-dispatch `switch`.
- **Dijkstra, structured programming**: Single-entry/single-exit, deliberately relaxed for small functions.
