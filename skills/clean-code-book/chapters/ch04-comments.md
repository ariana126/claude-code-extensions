# Chapter 4: Comments

## Core Idea
"Comments are always failures" — every comment is compensation for an inability to express intent in code, and because programmers can't realistically maintain them, comments drift into lies while the code remains the only source of truth.

## Frameworks Introduced
- **Explain Yourself in Code**
  - When to use: Every time you feel the urge to write a comment.
  - How: (1) Write the comment you want. (2) Ask whether a function name can say the same thing. (3) If not, whether an explanatory local variable can. (4) Only if both fail, keep the comment. In many cases it is simply a matter of creating a function that says the same thing as the comment. "Every time you express yourself in code, you should pat yourself on the back. Every time you write a comment, you should grimace and feel the failure of your ability of expression."
  - Why it works / failure mode: A function name is checked by the compiler and refactored by the IDE; a comment is checked by nobody. Failure mode: writing the comment first and then the code, and never going back to refactor the comment away.

- **The Good-Comment Taxonomy** — the only categories that earn their bits:
  - **Legal comments**: Copyright and authorship at the top of a source file. Keep them short; refer to a standard license or external document rather than embedding terms and conditions. Let the IDE auto-collapse them.
  - **Informative comments**: Explaining a return value or a regex's target format. Prefer renaming (`responderInstance` → `responderBeingTested`) or moving the code to a dedicated class, which usually makes the comment superfluous.
  - **Explanation of intent**: The *why* behind a decision you can't derive from the code ("we are greater because we are the right type"; "This is our best attempt to get a race condition by creating large number of threads"). You might disagree with the solution, but at least you know what the author was trying to do.
  - **Clarification**: Translating an obscure argument or return value — legitimate only when it's in a standard library or code you cannot alter. Substantial risk that the clarification is itself wrong; verify with extra care.
  - **Warning of consequences**: `//SimpleDateFormat is not thread safe, so we need to create each instance independently.` Prevents an overly eager programmer from "optimizing" with a static initializer.
  - **TODO comments**: Explain why a function has a degenerate implementation and what its future should be. TODOs are jobs the programmer thinks should be done but can't do now. Scan for them regularly and eliminate the ones you can.
  - **Amplification**: Marking something that looks inconsequential but isn't ("the trim is real important — it removes the starting spaces that could cause the item to be recognized as another list").
  - **Javadocs in Public APIs**: Write good javadocs for a public API — but they can be just as misleading, nonlocal, and dishonest as any other comment.

- **Don't Use a Comment When You Can Use a Function or a Variable**
  - When to use: Any condition or expression that needed narrating.
  - How: Extract the sub-expressions into named local variables until the predicate reads as English. The comment then has nothing left to say and is deleted.

## Key Concepts
- **Comments as necessary evil**: "The proper use of comments is to compensate for our failure to express ourself in code."
- **Comment rot**: The older a comment is and the farther away it is from the code it describes, the more likely it is to be plain wrong. Code moves; comments can't follow.
- **Orphaned blurb**: A comment separated from the code it described (e.g. new instance variables interposed between `HTTP_DATE_REGEXP` and its `// Example: "Tue, 02 Apr 2003 22:18:49 GMT"`).
- **Mumbling**: A comment written because the process required it, whose meaning does not survive the author's head.
- **Noise comment**: A comment that restates the obvious and provides no new information (`/** Default constructor. */`); readers learn to skip them, and then they begin to lie.
- **Mandated comment**: A rule that every function must have a javadoc or every variable a comment — produces clutter, lies, and confusion.
- **Journal comment**: An accumulating change log at the top of a module; obsoleted by source code control and should be completely removed.
- **Position marker / banner**: `// Actions //////////////////////////////` — startling and obvious only if rare; overuse turns them into background noise.
- **Nonlocal information**: A comment describing a distant part of the system (a default port a setter has no control over) with no guarantee it will be updated when that distant part changes.

## Mental Models
- **Think of the only truly good comment as the comment you found a way not to write.**
- **Use "truth can only be found in one place: the code."** Only the code can truly tell you what it does. Therefore inaccurate comments are far worse than no comments at all — they delude, mislead, set expectations that will never be fulfilled, and lay down old rules that should no longer be followed.
- **When you feel the urge to comment bad code, feel the urge to clean it instead.** "Don't comment bad code — rewrite it." (Kernighan & Plaugher.) Clear and expressive code with few comments is far superior to cluttered and complex code with lots of comments.
- **Use "does this comment force me to look in another module?" as a kill test.** Any comment that does has failed to communicate and is not worth the bits it consumes.
- **Treat the source control system as the right home for history.** Who added what and when, and old versions of code, belong in version control — not in bylines, journals, or commented-out blocks.

## Anti-patterns
- **Comments that make up for bad code**: "Ooh, I'd better comment that!" No — you'd better clean it.
- **Redundant comments**: Take longer to read than the code they describe and add nothing.
- **Misleading comments**: The `waitForClose` header says the method "returns when `this.closed` is true." It actually returns *if* `this.closed` is true; otherwise it waits for a blind time-out and throws. A caller trusting the comment lands in a debugging session wondering why the code is so slow. Subtle imprecision is the most dangerous kind.
- **Mandated javadocs**: Force abominations where `@param title The title of the CD` restates the parameter name — and mask a real bug (`cd.duration = duration;` should be `durationInMinutes`).
- **Journal comments**: Dozens of pages of dated entries preserved from before source control existed.
- **Noise / scary noise**: `/** The day of the month. */ private int dayOfMonth;` — and a real open-source library where `/** The version. */` is cut-pasted onto both `version` and `info`. If authors aren't paying attention when comments are written, why should readers profit from them?
- **Closing brace comments** (`} //while`, `} // try`, `} //main`): May make sense for long, deeply nested functions; they only clutter small encapsulated ones. If you want them, shorten your functions instead.
- **Attributions and bylines** (`/* Added by Rick */`): Source control remembers this; bylines stay around for years getting less accurate and relevant.
- **Commented-out code**: "Few practices are as odious." Others won't have the courage to delete it — they'll assume it's there for a reason — so it gathers like dregs at the bottom of a bad bottle of wine. Just delete it; version control will remember. "We won't lose it. Promise."
- **HTML in comments**: An abomination — it makes comments hard to read in the one place they should be easy to read, the editor/IDE. Adorning comments with HTML is the extraction tool's job, not the programmer's.
- **Too much information**: Pasting RFC 2045's base64 encoding prose into a test module; nobody reading the code needs it (the RFC number alone would do).
- **Inobvious connection**: `/* … an extra 200 bytes for header info */` above `new byte[((width + 1) * height * 3) + 200]` — what is a filter byte? does it relate to the `+1` or the `*3`? "It is a pity when a comment needs its own explanation."
- **Function headers on short functions**: A well-chosen name for a small function that does one thing is usually better than a comment header.
- **Javadocs in nonpublic code**: Anathema — the extra formality amounts to little more than cruft and distraction.

## Code Examples

Comment → function:

```java
// Check to see if the employee is eligible for full benefits
if ((employee.flags & HOURLY_FLAG) &&
    (employee.age > 65))
```

```java
if (employee.isEligibleForFullBenefits())
```
- **What it demonstrates**: A few seconds of thought converts a comment into a name that can never drift out of sync.

Comment → explanatory variables:

```java
// does the module from the global list <mod> depend on the
// subsystem we are part of?
if (smodule.getDependSubsystems().contains(subSysMod.getSubSystem()))
```

```java
ArrayList moduleDependees = smodule.getDependSubsystems();
String ourSubSystem = subSysMod.getSubSystem();
if (moduleDependees.contains(ourSubSystem))
```
- **What it demonstrates**: The author may have written the comment first and then the code to fulfill it — but should then have refactored so the comment could be removed.

A good comment (warning of consequences):

```java
public static SimpleDateFormat makeStandardHttpDateFormat()
{
  //SimpleDateFormat is not thread safe,
  //so we need to create each instance independently.
  SimpleDateFormat df = new SimpleDateFormat("EEE, dd MMM  yyyy HH:mm:ss z");
  df.setTimeZone(TimeZone.getTimeZone("GMT"));
  return df;
}
```
- **What it demonstrates**: There may be better solutions, but this comment is perfectly reasonable — it encodes a non-obvious constraint the code cannot state.

Mumbling — a comment that is an enigma:

```java
public void loadProperties()
{
  try
  {
   String propertiesPath = propertiesLocation + "/" + PROPERTIES_FILE;
   FileInputStream propertiesStream = new FileInputStream(propertiesPath);
   loadedProperties.load(propertiesStream);
  }
  catch(IOException e)
  {
    // No properties files means all defaults are loaded
  }
}
```
- **What it demonstrates**: Who loads the defaults? Before the call? Inside `load`? Or was the author reminding himself to come back and write that code? You have to read other modules to find out — which means the comment failed.

Closing brace comments cluttering a small program:

```java
      while ((line = in.readLine()) != null) {
        lineCount++;
        charCount += line.length();
        String words[] = line.split("\\W");
        wordCount += words.length;
      } //while
      System.out.println("wordCount = " + wordCount);
    } // try
    catch (IOException e) {
      System.err.println("Error:" + e.getMessage());
    } //catch
  } //main
```
- **What it demonstrates**: The urge to label braces is a signal to shorten the function, not to add labels.

## Reference Tables

| Good comments | Bad comments |
|---|---|
| Legal | Mumbling |
| Informative | Redundant |
| Explanation of intent | Misleading |
| Clarification | Mandated |
| Warning of consequences | Journal comments |
| TODO | Noise / Scary noise |
| Amplification | Position markers / banners |
| Javadocs in public APIs | Closing brace comments |
| | Attributions and bylines |
| | Commented-out code |
| | HTML comments |
| | Nonlocal information |
| | Too much information |
| | Inobvious connection |
| | Function headers (on short functions) |
| | Javadocs in nonpublic code |

## Worked Example
**`GeneratePrimes.java` (Listing 4-7) — code Martin wrote deliberately for the first *XP Immersion* as an example of bad commenting style, later refactored live by Kent Beck in front of several dozen students.** The header javadoc alone:

```java
/**
 * This class Generates prime numbers up to a user specified
 * maximum.  The algorithm used is the Sieve of Eratosthenes.
 * <p>
 * Eratosthenes of Cyrene, b. c. 276 BC, Cyrene, Libya --
 * d. c. 194, Alexandria.  The first man to calculate the
 * circumference of the Earth.  Also known for working on
 * calendars with leap years and ran the library at Alexandria.
 * <p>
 * The algorithm is quite simple.  Given an array of integers
 * starting at 2.  Cross out all multiples of 2.  Find the next
 * uncrossed integer, and cross out all of its multiples.
 * Repeat untilyou have passed the square root of the maximum
 * value.
 *
 * @author Alphonse
 * @version 13 Feb 2002 atp
 */
```

Count the failures in this single block:
- **Too much information** — Eratosthenes' biography (circumference of the Earth, leap-year calendars, the library at Alexandria) has nothing to do with the code.
- **HTML comments** — `<p>` tags degrading readability in the editor.
- **Attributions / journal** — `@author Alphonse`, `@version 13 Feb 2002 atp`, both source control's job.
- **Redundant** — the algorithm restated in prose because the body doesn't say it; the fix is to name the body's parts so it does.
- **Rot risk** — the typo `untilyou` shows nobody has re-read it since it was typed.

The body compounds this with **sections within a function** — `declarations`, `initializations`, `sieve` — which is itself the Ch 3 smell of doing more than one thing. Martin's point: "there was a time when many of us would have considered it *well documented*. Now we see it as a small mess." The refactoring answer is not to improve the comments but to name the sections into functions until the comments have nothing to say.

## Key Takeaways
1. Before writing any comment, try to express the same thing as a function name or an explanatory variable; treat the need for a comment as a failure of expression.
2. Never use comments to compensate for bad code — clean the code instead.
3. Restrict yourself to the eight good categories: legal, informative, intent, clarification, warning of consequences, TODO, amplification, public-API javadocs.
4. Comments that explain **why** survive; comments that explain **what** duplicate the code and rot.
5. Delete commented-out code, journal comments, bylines, and closing-brace comments on sight — source control remembers, and nobody else will have the courage to delete them.
6. Never mandate comments by policy; required javadocs on every function produce clutter and lies.
7. Keep a comment adjacent to and about the code it describes; nonlocal or inobvious comments are guaranteed to go stale.
8. Verify clarification comments with extra care — they're the good category most likely to be wrong.

## Connects To
- **Ch 2 (Meaningful Names)**: "If a name requires a comment, then the name does not reveal its intent" — the same rule seen from the naming side; renaming is the primary comment-removal tool.
- **Ch 3 (Functions)**: Small functions that do one thing rarely need headers; the `generatePrimes` sections example is cited in Ch 3 as evidence a function does more than one thing.
- **Ch 5 (Formatting)**: Listing 5-3 shows how noise comments break the vertical density of tightly related instance variables.
- **Ch 15 (JUnit Internals) / Ch 16 (Refactoring SerialDate)**: Where journal comments and redundant javadocs are stripped in practice.
- **Kernighan & Plaugher, *The Elements of Programming Style***: Source of the epigraph.
- **Source control / `@Ignore`**: Modern replacements for journals, bylines, commented-out code, and disabled-test comments.
