# Chapter 5: Formatting

## Core Idea
Code formatting is about communication, the professional developer's first order of business — and because your style and discipline survive long after your code has been changed beyond recognition, the team must agree on one set of rules and encode them in the IDE.

## Frameworks Introduced
- **The Newspaper Metaphor**
  - When to use: Deciding the top-to-bottom order of everything in a source file.
  - How: Read a source file like a newspaper article. (1) The **name** is the headline — simple but explanatory, and by itself sufficient to tell you whether you're in the right module. (2) The **topmost parts** give the high-level concepts and algorithms, the synopsis with details hidden. (3) **Detail increases as you move downward**, until at the end you find the lowest-level functions and details. (4) A newspaper is many small articles, most very small, very few filling a page — so keep files small.
  - Why it works / failure mode: It lets a reader skim the first few functions and get the gist without immersing in details. Failure mode: a file that is "just one long story containing a disorganized agglomeration of facts, dates, and names" — which nobody reads.

- **Vertical Openness Between Concepts**
  - When to use: Between every group of lines that forms a complete thought.
  - How: Separate the package declaration, the imports, and each function with blank lines. Each group of lines is a complete thought; each blank line is a visual cue identifying a new and separate concept.
  - Why it works / failure mode: As you scan down, your eye is drawn to the first line that follows a blank line. Unfocus your eyes on an open listing and the groupings pop out; on a dense one it's a muddle.

- **Vertical Density**
  - When to use: Immediately after applying openness — the two are a matched pair.
  - How: If openness separates concepts, density implies close association, so lines of code that are tightly related should appear vertically dense. Strip anything (especially useless comments) that breaks the association between related declarations, so the class fits in "an eye-full" — seen without moving your head or eyes much.

- **Vertical Distance** [G10]
  - When to use: Placing declarations and ordering methods.
  - How, by kind:
    - **Variable declarations** — as close to their usage as possible. Because functions are very short, local variables appear at the top of each function.
    - **Loop control variables** — usually declared within the loop statement itself.
    - **Instance variables** — at the top of the class (the Java convention; C++ had the "scissors rule" putting them at the bottom). The important thing is one well-known place everybody knows to look. Martin's counter-example is JUnit 4.3.1's `TestSuite`, which hides two instance variables halfway down the class — "it would be hard to hide them in a better place."
    - **Dependent functions** — vertically close, with **the caller above the callee**. Then readers can trust that a function's definition follows shortly after its use.
    - **Conceptual affinity** — the stronger the affinity, the less vertical distance. Affinity can come from direct dependence (one function calling another, or using a variable) *or* from a shared naming scheme and a common basic task, as with JUnit's `assertTrue`/`assertFalse` family. "Even if they didn't [call each other], they would still want to be close together."
  - Why it works / failure mode: Otherwise you spend your time and mental energy figuring out *where* the pieces are instead of *what* the system does. This is also one of the reasons protected variables should be avoided — they scatter closely related concepts across files.

- **Vertical Ordering**
  - When to use: Arranging a module's call graph.
  - How: Function call dependencies point downward — the called function sits **below** the calling function. Most important concepts first, expressed with the least polluting detail; low-level details last. (Note this is the exact opposite of Pascal, C, and C++, which force functions to be defined or declared *before* use.)

- **Team Rules** — "Every programmer has his own favorite formatting rules, but if he works in a team, then the team rules."
  - When to use: Day one of a project.
  - How: Sit down as a team and decide brace placement, indent size, and naming for classes, variables, and methods. Martin did this for FitNesse in about **10 minutes** in 2002, encoded the rules into the IDE's code formatter, and the team stuck with them ever since — including rules that were not his own preference.
  - Why it works / failure mode: A good software system is a set of documents that read nicely; a reader must be able to trust that a formatting gesture means the same thing in every file. Failure mode: a codebase that appears to have been written by a bunch of disagreeing individuals.

## Key Concepts
- **The purpose of formatting**: Communication — "too important to ignore and too important to treat religiously."
- **Vertical openness**: Blank lines separating distinct thoughts.
- **Vertical density**: Adjacency implying close association.
- **Vertical distance**: Separation as a measure of how important each concept is to understanding the other.
- **Conceptual affinity**: The pull that makes certain bits of code *want* to be near other bits — dependence, or a shared naming scheme and similar operation.
- **Horizontal openness and density**: White space used to associate strongly related things and disassociate weakly related ones.
- **Horizontal alignment**: Lining up variable names or rvalues in columns — a practice Martin explicitly abandoned.
- **Breaking indentation**: Collapsing scopes onto one line for short `if`s, `while`s, or functions — a temptation Martin says he has always had to undo.
- **Dummy scope**: A `while`/`for` whose body is an empty statement.
- **Scissors rule**: The old C++ convention of putting instance variables at the bottom of the class.

## Mental Models
- **Think of the reader looking under the hood of a car.** You want them struck by neatness, consistency, and attention to detail — to perceive that professionals have been at work. Code that looks "like it was written by a bevy of drunken sailors" invites the conclusion that the same inattention pervades every other aspect of the project.
- **Use "your style and discipline survives, even though your code does not."** Functionality has a good chance of changing next release; the readability precedent affects every change ever made afterward.
- **Use white space to encode operator precedence.** Factors get no space because they are high precedence; terms get space because addition and subtraction are lower. `return (-b + Math.sqrt(determinant)) / (2*a);` and `return b*b - 4*a*c;` read like equations. Caveat: most reformatting tools are blind to precedence and impose uniform spacing, so these subtleties tend to get lost.
- **When you need horizontal alignment, the problem is the length of the list, not the lack of alignment.** A long aligned declaration block (as in `FitNesseExpediter`) is telling you the class should be split up.
- **Think of code as the best coding standard document.** Martin presents `CodeAnalyzer.java` (Listing 5-6) as the illustration of his own rules rather than writing them out.

## Anti-patterns
- **Removing blank lines** (Listing 5-2): Has "a remarkably obscuring effect on readability"; the file becomes a muddle.
- **Noise comments between related declarations** (Listing 5-3): Javadocs on `m_className` and `m_properties` break their close association and force much more eye and head motion for the same comprehension.
- **Hiding instance variables mid-class**: JUnit's `TestSuite` — someone reading the code would have to stumble across the declarations by accident.
- **Callee above caller / scattered dependent functions**: Destroys the natural downward flow and makes readers hunt.
- **Horizontal alignment of declarations and assignments**: Emphasizes the wrong things — you're tempted to read down the list of variable names without looking at their types, or down the list of rvalues without ever seeing the assignment operator. Automatic reformatting tools usually eliminate it anyway.
- **Lines beyond ~120 characters**: "Beyond that is probably just careless." Shrinking the font to fit 200 characters across the screen — "Don't do that."
- **Breaking indentation / collapsing scopes to one line**: `public CommentWidget(ParentWidget parent, String text){super(parent, text);}` — always went back and put the indentation back in.
- **Unindented dummy scopes**: `while (dis.read(buf, 0, readBufferSize) != -1)     ;` — a semicolon silently sitting at the end of a `while` on the same line has fooled Martin countless times. If unavoidable, put the dummy body on its own indented line and surround it with braces.
- **Burying a well-known constant in a low-level function** [G35]: `"FrontPage"` belongs where it makes sense to know it, passed down to the place that actually uses it — not hidden inside `getPageNameOrDefault`.

## Code Examples

Vertical openness — with blank lines (Listing 5-1):

```java
package fitnesse.wikitext.widgets;

import java.util.regex.*;

public class BoldWidget extends ParentWidget {
  public static final String REGEXP = "'''.+?'''";
  private static final Pattern pattern = Pattern.compile("'''(.+?)'''",
    Pattern.MULTILINE + Pattern.DOTALL
  );

  public BoldWidget(ParentWidget parent, String text) throws Exception {
    super(parent);
    Matcher match = pattern.matcher(text);
    match.find();
    addChildWidgets(match.group(1));
  }

  public String render() throws Exception {
    StringBuffer html = new StringBuffer("<b>");
    html.append(childHtml()).append("</b>");
    return html.toString();
  }
}
```

Same code, blank lines removed (Listing 5-2):

```java
package fitnesse.wikitext.widgets;
import java.util.regex.*;
public class BoldWidget extends ParentWidget {
  public static final String REGEXP = "'''.+?'''";
  private static final Pattern pattern = Pattern.compile("'''(.+?)'''",
    Pattern.MULTILINE + Pattern.DOTALL);
  public BoldWidget(ParentWidget parent, String text) throws Exception {
    super(parent);
    Matcher match = pattern.matcher(text);
    match.find();
    addChildWidgets(match.group(1));}
  public String render() throws Exception {
    StringBuffer html = new StringBuffer("<b>");
    html.append(childHtml()).append("</b>");
    return html.toString();
  }
}
```
- **What it demonstrates**: The only difference is vertical openness, and it decides whether the groupings pop out or the file reads as a muddle.

Horizontal alignment — abandoned:

```java
public class FitNesseExpediter implements ResponseSender
{
  private   Socket           socket;
  private   InputStream     input;
  private   OutputStream     output;
  private   Request         request;
  ...
  public FitNesseExpediter(Socket          s,
                           FitNesseContext context) throws Exception
  {
    this.context =            context;
    socket =                  s;
    input =                   s.getInputStream();
    output =                  s.getOutputStream();
    requestParsingTimeLimit = 10000;
  }
```

Preferred — unaligned, so the length of the list becomes visible as the real problem:

```java
public class FitNesseExpediter implements ResponseSender
{
  private Socket socket;
  private InputStream input;
  private OutputStream output;
  private Request request;
  private Response response;
  private FitNesseContext context;
  protected long requestParsingTimeLimit;
  private long requestProgress;
  private long requestParsingDeadline;
  private boolean hasError;

  public FitNesseExpediter(Socket s, FitNesseContext context) throws Exception
  {
    this.context = context;
    socket = s;
    input = s.getInputStream();
    output = s.getOutputStream();
    requestParsingTimeLimit = 10000;
  }
```
- **What it demonstrates**: Alignment hides a design smell; without it, the declaration list's length shouts that this class should be split up.

Horizontal openness — spacing that encodes precedence:

```java
public class Quadratic {
  public static double root1(double a, double b, double c) {
    double determinant = determinant(a, b, c);
    return (-b + Math.sqrt(determinant)) / (2*a);
  }

  private static double determinant(double a, double b, double c) {
    return b*b - 4*a*c;
  }
}
```
- **What it demonstrates**: Space around assignment operators separates left side from right; no space between a function name and its opening paren (closely related), space after commas (arguments are separate); factors tight, terms spaced.

Breaking indentation vs. expanding scopes:

```java
public class CommentWidget extends TextWidget
{
  public static final String REGEXP = "^#[^\r\n]*(?:(?:\r\n)|\n|\r)?";
  public CommentWidget(ParentWidget parent, String text){super(parent, text);}
  public String render() throws Exception {return ""; }
}
```

```java
public class CommentWidget extends TextWidget {
  public static final String REGEXP = "^#[^\r\n]*(?:(?:\r\n)|\n|\r)?"
  public CommentWidget(ParentWidget parent, String text) {
    super(parent, text);
  }
  public String render() throws Exception {
    return "";
  }
}
```
- **What it demonstrates**: Indentation makes the hierarchy of scopes visible; collapsing it saves nothing worth having.

## Reference Tables

| Dimension | Martin's number |
|---|---|
| Typical source file length | ~200 lines |
| Upper limit on file length | 500 lines ("should not be a hard and fast rule, but should be considered very desirable") |
| FitNesse average file size | ~65 lines; ~1/3 of files between 40 and 100+ lines; largest ~400, smallest 6 |
| FitNesse total system size | ~50,000 lines — built entirely from files of that size |
| Line width, old convention | The Hollerith limit of 80 ("a bit arbitrary") |
| Line width, Martin's tolerance | Not opposed to 100 or even 120 |
| Martin's personal limit | 120 |
| Max function indent level | One or two (Ch 3) |
| Time to agree team formatting rules | ~10 minutes |

Project file-size profiles (Figure 5-1, log scale): JUnit, FitNesse, and Time and Money are composed of relatively small files — none over 500 lines, most under 200. Tomcat and Ant have files several thousand lines long, with close to half over 200.

Line width distribution (Figure 5-2, all seven projects): remarkably regular around 45 characters; every size from 20 to 60 is about 1 percent of total lines — 40 percent in that band; perhaps another 30 percent under 10 characters wide. On a log scale the drop-off above 80 characters is very significant. **Programmers clearly prefer short lines.**

## Worked Example
**`WikiPageResponder.java` (Listing 5-5) — the newspaper metaphor made concrete.**

```java
public class WikiPageResponder implements SecureResponder {
  protected WikiPage page;
  protected PageData pageData;
  protected String pageTitle;
  protected Request request;
  protected PageCrawler crawler;

  public Response makeResponse(FitNesseContext context, Request request)
    throws Exception {
    String pageName = getPageNameOrDefault(request, "FrontPage");
    loadPage(pageName, context);
    if (page == null)
      return notFoundResponse(context, request);
    else
      return makePageResponse(context);
  }

  private String getPageNameOrDefault(Request request, String defaultPageName)
  {
    String pageName = request.getResource();
    if (StringUtil.isBlank(pageName))
      pageName = defaultPageName;
    return pageName;
  }

  protected void loadPage(String resource, FitNesseContext context)
    throws Exception {
    WikiPagePath path = PathParser.parse(resource);
    crawler = context.root.getPageCrawler();
    crawler.setDeadEndStrategy(new VirtualEnabledPageCrawler());
    page = crawler.getPage(context.root, path);
    if (page != null)
      pageData = page.getData();
  }

  private Response notFoundResponse(FitNesseContext context, Request request)
    throws Exception {
    return new NotFoundResponder().makeResponse(context, request);
  }

  private SimpleResponse makePageResponse(FitNesseContext context)
    throws Exception {
    pageTitle = PathParser.render(crawler.getFullPath(page));
    String html = makeHtml(context);
    SimpleResponse response = new SimpleResponse();
    response.setMaxAge(0);
    response.setContent(html);
    return response;
  }
```

Read it as a newspaper: **instance variables at the top** in one well-known place; **`makeResponse` is the headline paragraph**, a four-line synopsis naming everything the class does; then each function it calls appears *below* it, in call order, and those in turn call functions below them. Blank lines separate every thought. You can get the gist from the first function alone and stop reading — or descend for detail.

Martin's aside on this listing: `"FrontPage"` is passed *into* `getPageNameOrDefault` rather than buried inside it. Burying it would have hidden a well-known and expected constant in an inappropriately low-level function; it is better to pass the constant down from the place where it makes sense to know it to the place that actually uses it [G35].

Contrast with an unindented file, which is "virtually impenetrable without intense study" — while in the indented version "you can almost instantly spot the variables, constructors, accessors, and methods. It takes just a few seconds to realize that this is some kind of simple front end to a socket, with a time-out."

## Key Takeaways
1. Target files of about 200 lines with an upper limit of 500 — FitNesse's ~50,000 lines are built from files averaging ~65 lines.
2. Keep lines short; Martin personally caps at 120, tolerates 100, and treats anything beyond as careless.
3. Separate every complete thought with a blank line, and keep tightly related lines vertically dense.
4. Declare locals at the top of their function, loop controls inside the loop statement, and instance variables at the top of the class — one well-known place.
5. Put the caller above the callee and let call dependencies point downward, so the file reads high-level to low-level like a newspaper article.
6. Keep conceptually affine functions close even when they don't call each other.
7. Abandon horizontal alignment; if a list is long enough to need it, split the class instead.
8. Never break indentation or collapse scopes to one line; make dummy loop bodies visible on their own indented line inside braces.
9. Agree team formatting rules once (10 minutes is enough), encode them in the IDE formatter, and follow them even where they aren't your preference.

## Connects To
- **Ch 3 (Functions)**: Vertical ordering *is* the Stepdown Rule made physical; `SetupTeardownIncluder` (Listing 3-7) is cited here as a model of high-to-low ordering, and the max-indent-of-one-or-two rule comes from there.
- **Ch 4 (Comments)**: Listing 5-3 shows noise comments destroying vertical density — a formatting cost of bad commenting.
- **Ch 10 (Classes)**: A too-long declaration list is a signal to split the class; instance-variable placement is a class-design decision.
- **Ch 15 (JUnit Internals)**: Listing 15-5 is cited as an even better example of high-to-low vertical ordering.
- **Ch 17 [G10], [G35]**: "Vertical separation" and "keep configurable data at high levels / constants at the appropriate level."
- **Automated formatters**: Encode team rules in the IDE; note they are blind to operator precedence and will erase deliberate spacing subtleties and alignment.
