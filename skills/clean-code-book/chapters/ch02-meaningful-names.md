# Chapter 2: Meaningful Names

## Core Idea
A name must answer why the thing exists, what it does, and how it is used; if a name needs a comment to explain it, the name has failed and should be changed.

## Frameworks Introduced
- **Use Intention-Revealing Names**
  - When to use: On every variable, function, class, package, and file — especially any name you were about to annotate with a clarifying comment.
  - How: (1) Ask what is being measured and in what unit. (2) Name the concept, not the mechanism (`gameBoard`, not `theList`). (3) Replace magic subscripts and literals with named constants (`cell[STATUS_VALUE] == FLAGGED`). (4) When the constants keep recurring, promote the structure to a class with an intention-revealing predicate (`cell.isFlagged()`). (5) Re-read the code with each candidate name in place.
  - Why it works / failure mode: The problem with unclear code is rarely complexity, it's **implicity** — "the degree to which the context is not explicit in the code itself." Renaming adds no operators, constants, or nesting levels; it converts knowledge that lived in the author's head into text. Failure mode: naming the container's type or implementation instead of the concept, which re-hides the intent.

- **The Length of a Name Should Correspond to the Size of Its Scope** [N5]
  - When to use: Deciding between `i`, `sum`, and `WORK_DAYS_PER_WEEK`.
  - How: Single-letter names ONLY as local variables inside short methods; loop counters `i`, `j`, `k` (never `l`) are acceptable when the scope is very small and nothing conflicts. Anything visible or used in multiple places gets a search-friendly name. Longer names trump shorter names, and any searchable name trumps a constant in code.
  - Why it works / failure mode: You can grep `MAX_CLASSES_PER_STUDENT`; you cannot usefully grep `7` or `e`. A transposed digit in a long literal creates a bug that simultaneously evades your search.

- **Pick One Word per Concept**
  - When to use: Naming methods across a codebase or library surface.
  - How: Choose one word per abstract concept and stick with it — don't mix `fetch`, `retrieve`, and `get` as equivalent methods on different classes; don't have a `controller`, a `manager`, and a `driver` in the same code base. Build a consistent lexicon.

- **Don't Pun**: Never use the same word for two different ideas.
  - When to use: When "consistency" tempts you to reuse an existing verb.
  - How: If your other classes' `add` creates a new value by adding/concatenating two existing values, a method that puts a single parameter into a collection must be `insert` or `append`, not `add`.

## Key Concepts
- **Implicity**: The degree to which context is *not* explicit in the code itself (Ottinger's coinage) — the real reason simple-looking code is hard to read.
- **Disinformation**: Names whose entrenched meaning differs from the intended one (`hp`, `aix`, `sco`; `accountList` for a non-`List`); inconsistent spellings of similar concepts.
- **Noise words**: Meaningless distinguishers — `Info`, `Data`, `Object`, `variable`, `table`, and the articles `a`, `an`, `the` — that differ without meaning anything different.
- **Number-series naming**: `a1, a2, … aN` — the exact opposite of intentional naming; noninformative rather than disinformative.
- **Hungarian Notation (HN)**: Encoding type into the name; a crutch from untyped-compiler days that now impedes renaming and can itself lie (`PhoneNumber phoneString;`).
- **Mental mapping**: Forcing the reader to translate your name into a concept they already know — the sign of using neither problem-domain nor solution-domain terms.
- **Solution domain names**: CS terms, algorithm names, pattern names, math terms (`AccountVisitor`, `JobQueue`) — appropriate because your readers are programmers.
- **Problem domain names**: Names drawn from the business when there is no "programmer-eese"; at least a maintainer can ask a domain expert.
- **Gratuitous context**: Redundant prefixing (`GSDAccountAddress`) that defeats IDE completion and outlives its scope.

## Mental Models
- **Think of a name as a comment that cannot go stale.** If a name requires a comment, the name does not reveal its intent — so change the name and delete the comment.
- **Use pronounceability as a test, because programming is a social activity.** If you can't say it, you can't discuss it in a code review without sounding like an idiot (`genymdhms` → `generationTimestamp`).
- **Think of naming as writing for the paperback reader, not the academic.** The author is responsible for being clear; readers should be able to skim, not conduct an intense study.
- **Use "clarity is king" as the tiebreaker between clever and plain.** The difference between a smart programmer and a professional programmer is that the professional writes code others can understand.
- **When you can't name the context, you're missing a class.** Prefixes (`addrState`) are the last resort; an `Address` class is the real answer, and then even the compiler knows the variables belong to a bigger concept.

## Anti-patterns
- **`int d; // elapsed time in days`**: The name reveals nothing; the comment carries all the meaning and will drift.
- **Lowercase `l` and uppercase `O` as variable names**: They look like the constants one and zero. The "fix" of prescribing a different font becomes oral tradition passed to all future developers; renaming solves it with finality and creates no new work products.
- **`getActiveAccount()` / `getActiveAccounts()` / `getActiveAccountInfo()`**: Distinctions the compiler accepts but no reader can resolve — how is anyone supposed to know which to call?
- **`klass` because `class` was taken**: Misspelling to satisfy the compiler; correcting a spelling error then breaks the build.
- **`XYZControllerForEfficientHandlingOfStrings` vs `…ForEfficientStorageOfStrings`**: Names varying in small ways have frightfully similar shapes; with autocompletion the developer picks by name without ever reading your comments.
- **Member prefixes `m_`**: Readers learn to ignore prefixes; they become unseen clutter and a marker of older code. Your classes should be small enough not to need them.
- **`IShapeFactory`**: Leave interfaces unadorned — the leading `I` is a distraction at best and too much information at worst. If you must encode one side, encode the implementation (`ShapeFactoryImp`).
- **Cuteness**: `HolyHandGrenade` for `DeleteItems`, `whack()` for `kill()`, `eatMyShorts()` for `abort()` — memorable only to people who share the joke, and only while they remember it.

## Code Examples

Before — nothing about the domain is explicit:

```java
public List<int[]> getThem() {
  List<int[]> list1 = new ArrayList<int[]>();
  for (int[] x : theList)
    if (x[0] == 4)
      list1.add(x);
  return list1;
}
```

After step 1 — same operators, same constants, same nesting; only names changed:

```java
public List<int[]> getFlaggedCells() {
  List<int[]> flaggedCells = new ArrayList<int[]>();
  for (int[] cell : gameBoard)
   if (cell[STATUS_VALUE] == FLAGGED)
     flaggedCells.add(cell);
   return flaggedCells;
}
```

After step 2 — a `Cell` class hides the magic numbers behind an intention-revealing predicate:

```java
public List<Cell> getFlaggedCells() {
  List<Cell> flaggedCells = new ArrayList<Cell>();
  for (Cell cell : gameBoard)
    if (cell.isFlagged())
      flaggedCells.add(cell);
  return flaggedCells;
}
```
- **What it demonstrates**: Readability is bought entirely with naming, not with structural simplification — the code's complexity is unchanged at every step.

Searchable names — before and after:

```java
for (int j=0; j<34; j++) {
  s += (t[j]*4)/5;
}
```

```java
int realDaysPerIdealDay = 4;
const int WORK_DAYS_PER_WEEK = 5;
int sum = 0;
for (int j=0; j < NUMBER_OF_TASKS; j++) {
  int realTaskDays = taskEstimate[j] * realDaysPerIdealDay;
  int realTaskWeeks = (realdays / WORK_DAYS_PER_WEEK);
  sum += realTaskWeeks;
}
```
- **What it demonstrates**: Intentional naming makes the function longer but makes `WORK_DAYS_PER_WEEK` findable, where hunting every `5` and filtering for intent is hopeless. Even a weak name like `sum` beats `s` because it is searchable.

Pronounceability:

```java
class DtaRcrd102 {
  private Date genymdhms;
  private Date modymdhms;
  private final String pszqint = "102";
};
```

```java
class Customer {
  private Date generationTimestamp;
  private Date modificationTimestamp;
  private final String recordId = "102";
};
```
- **What it demonstrates**: Only the second version supports a sentence like "the generation timestamp is set to tomorrow's date — how can that be?"

## Reference Tables

| Kind | Rule | Examples |
|---|---|---|
| Classes / objects | Noun or noun phrase; never a verb; avoid `Manager`, `Processor`, `Data`, `Info` | `Customer`, `WikiPage`, `Account`, `AddressParser` |
| Methods | Verb or verb phrase | `postPayment`, `deletePage`, `save` |
| Accessors / mutators / predicates | Named for their value, prefixed `get` / `set` / `is` per the JavaBean standard | `employee.getName()`, `customer.setName("mike")`, `paycheck.isPosted()` |
| Overloaded constructors | Replace with static factory methods named for the arguments; consider making the constructors private to enforce it | `Complex.FromRealNumber(23.0)` over `new Complex(23.0)` |
| Interface vs. implementation | Leave the interface unadorned; encode the implementation if you must | `ShapeFactory` / `ShapeFactoryImp`, not `IShapeFactory` |

## Worked Example
**Adding meaningful context: `printGuessStatistics`.** Listing 2-1 has three variables — `number`, `verb`, `pluralModifier` — whose context must be *inferred* from reading the whole algorithm:

```java
private void printGuessStatistics(char candidate, int count) {
    String number;
    String verb;
    String pluralModifier;
    if (count == 0) {
      number = "no";   verb = "are"; pluralModifier = "s";
    } else if (count == 1) {
      number = "1";    verb = "is";  pluralModifier = "";
    } else {
      number = Integer.toString(count); verb = "are"; pluralModifier = "s";
    }
    String guessMessage = String.format(
      "There %s %s %s%s", verb, number, candidate, pluralModifier
    );
    print(guessMessage);
  }
```

The move is not to rename the three variables — it is to give them a home. Create a `GuessStatisticsMessage` class and make them fields. Now they are *definitively* part of the guess-statistics message, and because the context is carried by the class, the algorithm can be split into many tiny, self-describing functions:

```java
public class GuessStatisticsMessage {
  private String number;
  private String verb;
  private String pluralModifier;

  public String make(char candidate, int count) {
    createPluralDependentMessageParts(count);
     return String.format(
       "There %s %s %s%s", verb, number, candidate, pluralModifier );
  }

  private void createPluralDependentMessageParts(int count) {
    if (count == 0) {
      thereAreNoLetters();
    } else if (count == 1) {
      thereIsOneLetter();
    } else {
      thereAreManyLetters(count);
    }
  }

  private void thereAreManyLetters(int count) {
    number = Integer.toString(count);
    verb = "are";
    pluralModifier = "s";
  }

  private void thereIsOneLetter() {
    number = "1";
    verb = "is";
    pluralModifier = "";
  }

  private void thereAreNoLetters() {
    number = "no";
    verb = "are";
    pluralModifier = "s";
  }
}
```

Note the direction of causation: **improving context enables the decomposition**, not the other way around. But keep context minimal — `GSDAccountAddress` for a `MailingAddress` in "Gas Station Deluxe" wastes 10 of 17 characters, works against your IDE's completion, and reads wrong the moment you need the same class elsewhere.

## Key Takeaways
1. If a name requires a comment, the name doesn't reveal intent — rename it and delete the comment.
2. Match name length to scope size: single letters only inside short methods; anything with reach gets a searchable name.
3. Replace magic literals and array subscripts with named constants, then with intention-revealing predicates on a real class.
4. Distinctions must mean something — no number series, no `Info`/`Data`/`Object` noise, no `klass`-style misspellings.
5. Drop encodings: no Hungarian notation, no `m_` prefixes, no `I` on interfaces.
6. One word per concept, and never pun — reuse a verb only when the semantics are genuinely the same.
7. Use solution-domain names when a CS/pattern term exists; fall back to problem-domain names when it doesn't.
8. Don't fear renaming. Modern IDEs make it trivial; be grateful when names change for the better and don't let others' possible objections stop you.

## Connects To
- **Ch 1**: Expressiveness and reduced duplication are Jeffries' two pillars of clean code; renaming is the cheapest expressiveness lever.
- **Ch 3 (Functions)**: "Use Descriptive Names" — a long descriptive name beats a short enigmatic one and beats a long descriptive comment; the smaller and more focused a function, the easier it is to name.
- **Ch 4 (Comments)**: "Don't Use a Comment When You Can Use a Function or a Variable" — the direct corollary of intention-revealing names.
- **Ch 10 (Classes)**: When a name needs context, the answer is usually a new class; hunting for a good name routinely produces a favorable restructuring.
- **Ch 17 [N5]**: The heuristic "name length should correspond to scope size" is cataloged there.
- **JavaBean specification**: The source of the `get`/`set`/`is` accessor convention.
- **Abstract Factory / Visitor (GoF)**: Pattern names are the canonical solution-domain vocabulary.
