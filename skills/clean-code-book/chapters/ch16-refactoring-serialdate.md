# Chapter 16: Refactoring SerialDate

## Core Idea
A full professional code review of `org.jfree.date.SerialDate` (JCommon, by David Gilbert): first make it *work* by building the tests it lacks and fixing the bugs they expose, then make it *right* by walking the class top to bottom applying named heuristics. Critique is a professional duty, not an insult — doctors, pilots and lawyers do it.

## Frameworks Introduced
- **First, Make It Work — Then Make It Right**: Two strictly ordered phases.
  - When to use: any legacy module you intend to restructure.
  - How: (1) run the existing tests; (2) measure coverage with a tool (Martin used Clover); (3) write your *own* independent suite, leaving failing-but-should-pass tests commented out as a to-do list; (4) fix the bugs those tests expose; (5) only then refactor structure, running all tests after every change.
  - Why it works: refactoring without coverage is guessing. Failure mode: skipping phase 1 and "improving" code whose behavior you cannot verify.

- **Commented-out test as an executable question**: A test you believe *should* pass but doesn't is a recorded intent, not dead code.
  - When to use: when the existing behavior is obviously wrong `[G2]` or the requirement is ambiguous `[T4]`.
  - How: write the test, comment it or `@Ignore` it, then uncomment as you fix each one.

- **The pattern-of-failure read** `[T7]`: Which tests fail tells you *where* the algorithm is wrong.
  - How: make test cases exhaustive and order them meaningfully; then look at the shape of the red. In `getNearestDayOfWeek` the red band was "nearest day is in the future" — a boundary error `[T5]`.

- **Coverage-pattern read** `[T8]`: A line that never executes is a proof about the code. Line 719 never ran ⇒ its `if` was always false ⇒ `adjust` was always negative ⇒ the algorithm was simply wrong.

- **ABSTRACT FACTORY to break base→derivative dependency** `[G7]`: Introduce `DayDateFactory` so `DayDate` never names `SpreadsheetDate`, and push implementation limits (`MINIMUM_YEAR_SUPPORTED`) down into the derivative.

- **Enum-absorption refactoring**: Move `int`-code constants and their converter functions into a real enum, then delete the validation and switch code they made necessary.
  - How: (1) create the enum with an `index` field and `fromInt`; (2) move the `xxxToString` / `stringToXxx` functions in as `toString` / `parse`; (3) delete `isValidXxxCode` and every error check `[G5]`; (4) when the enum grows big, move it to its own file `[G13]`.

## Key Concepts
- **SerialDate → DayDate**: The rename. "Serial" leaks the implementation (days since 30 Dec 1899) `[N2]` and is not even accurate — "ordinal" is the right word `[N1]`.
- **Logical vs physical dependency** `[G22]`: `getDayOfWeek` had no compilable dependency on `SpreadsheetDate` but implicitly depended on the day-of-week of ordinal zero. Fix: make the logical dependency physical via an abstract `getDayOfWeekForOrdinalZero()`.
- **Feature Envy** `[G14]`: `monthCodeToQuarter` wanted to live on `Month`; `getEndOfCurrentMonth(DayDate)` envied its own class.
- **Explaining temporary variables** `[G19]`: named intermediates (`offsetToTarget`, `offsetToFutureTarget`) that turn an opaque algorithm transparent.
- **Inappropriate static** `[G18]`: `addDays`/`addMonths` operated on instance state — make them instance methods.

## Mental Models
- **Use "does the name imply an implementation?" as a class-naming test.** An abstract class named for its representation is at the wrong level of abstraction `[N2]`.
- **Think of a flag-taking twin pair as two functions in disguise.** `monthCodeToString(month, shortened)` became `toString()` and `toShortString()` `[G15]`.
- **When you make a static into an instance method, re-read the call site as prose.** `date.addDays(7)` reads like mutation; `date.plusDays(7)` reads like a value returned `[G20]`, `[N4]`.
- **Refactor to delete.** The `weekInMonthToString` chain — move to enum, rename to `toString`, make non-static, then delete entirely — ended with deleting the tests too, because nothing but the tests called it `[F4]`.

## Anti-patterns
- **Change history in a source comment** `[C1]`: a leftover from the 1960s; source control does this.
- **Inheriting an interface for its constants** `[J2]`: `Employee implements PayrollConstants` — cheating the scoping rules. Use a static import or an enum.
- **Manual `serialVersionUID`** `[G4]`: an overridden safety; forgetting to update it fails silently, whereas letting the compiler generate it fails loudly with `InvalidClassException`.
- **Javadoc that repeats the signature** `[C3]`, `[G12]`: clutter, and it goes stale `[C2]` the moment behavior changes.
- **`final` sprinkled on every argument and local** `[G12]`: clutter; Martin explicitly disagrees with the "spread final all over your code" advice.
- **Duplicate `if` bodies in a loop** `[G5]`: collapse with `||`.
- **A pair of `getMonths` methods where one only calls the other** `[G9]`, `[F4]`: collapse and rename.
- **Boundary-condition off-by-one in date arithmetic** `[G3]`, `[T5]`: `getFollowingDayOfWeek` returned Dec 25 as the Saturday following Dec 25.

## Code Examples

Bug fix — the boundary condition `[T5]`, `[G3]`:
```java
685     if (baseDOW >= targetWeekday) {
```

The wrong algorithm replaced (`getNearestDayOfWeek`), then made consistent with its siblings using explaining variables `[G19]`, `[G11]`:
```java
public DayDate getNearestDayOfWeek(final Day targetDay) {
  int offsetToThisWeeksTarget = targetDay.index - getDayOfWeek().index;
  int offsetToFutureTarget = (offsetToThisWeeksTarget + 7) % 7;
  int offsetToPreviousTarget = offsetToFutureTarget - 7;
  if (offsetToFutureTarget > 3)
    return plusDays(offsetToPreviousTarget);
  else
    return plusDays(offsetToFutureTarget);
}
```
- **What it demonstrates**: three sibling algorithms (`getPrevious`, `getFollowing`, `getNearest`) rewritten to one consistent shape.

Breaking the base→derivative dependency `[G7]` with ABSTRACT FACTORY + SINGLETON:
```java
public abstract class DayDateFactory {
  private static DayDateFactory factory = new SpreadsheetDateFactory();
  public static void setInstance(DayDateFactory factory) {
    DayDateFactory.factory = factory;
  }
  protected abstract DayDate _makeDate(int ordinal);
  protected abstract int _getMinimumYear();
  public static DayDate makeDate(int ordinal) { return factory._makeDate(ordinal); }
  public static int getMinimumYear() { return factory._getMinimumYear(); }
}
```
- **What it demonstrates**: `createInstance` → `makeDate` `[N1]`, and implementation limits move down into `SpreadsheetDate` `[G6]`.

Replacing a `switch` with enum polymorphism `[G23]`:
```java
public enum DateInterval {
  OPEN         { public boolean isIn(int d, int l, int r) { return d >  l && d <  r; } },
  CLOSED_LEFT  { public boolean isIn(int d, int l, int r) { return d >= l && d <  r; } },
  CLOSED_RIGHT { public boolean isIn(int d, int l, int r) { return d >  l && d <= r; } },
  CLOSED       { public boolean isIn(int d, int l, int r) { return d >= l && d <= r; } };
  public abstract boolean isIn(int d, int left, int right);
}
```
- **What it demonstrates**: the ONE SWITCH rule — cases become polymorphic objects.

Making a logical dependency physical `[G22]`, `[G6]`:
```java
public Day getDayOfWeek() {
  Day startingDay = getDayOfWeekForOrdinalZero();
  int startingOffset = startingDay.index - Day.SUNDAY.index;
  return Day.make((getOrdinalDay() + startingOffset) % 7 + 1);
}
```

## Reference Tables

| Target in SerialDate | Critique | Action |
|---|---|---|
| Change history header | C1 | Delete |
| Long import list | J1 | `java.util.*`, `java.text.*` |
| Javadoc with 4 languages | G1 | Wrap in `<pre>` |
| Class name `SerialDate` | N1, N2 | → `DayDate` |
| `implements MonthConstants` | J2 | → `Month` enum |
| `serialVersionUID` | G4 | Delete; let compiler generate |
| `EARLIEST/LATEST_DATE_ORDINAL` | G6 | Push down to `SpreadsheetDate` |
| `MIN/MAX_YEAR_SUPPORTED` | G6, G7 | Push down; expose via `DayDateFactory` |
| `createInstance` in base class | G7 | ABSTRACT FACTORY |
| Day int constants | J3 | `Day` enum in its own file `[G13]` |
| `stringToWeekdayCode` | C3, G12, G5, G14 | → `Day.parse` |
| `weekdayCodeToString` | G14 | → `Day.toString` |
| `getMonths` twins | G9, G12, F4 | Collapse → `getMonthNames` |
| `isValidMonthCode` | G9 | Delete (enum makes it moot) |
| `monthCodeToQuarter` | G14 | → `Month.quarter()` |
| `monthCodeToString(m, flag)` | G15 | → `toString` / `toShortString` |
| `isLeapYear` | G16 | Named booleans: fourth / hundredth / fourHundredth |
| `leapYearCount` | G6 | Push down to `SpreadsheetDate` |
| `LAST_DAY_OF_MONTH` array | G17 | Move into `Month` |
| `addDays`, `addMonths`, `addYears` | G18, G19, G20, N4 | Instance methods, renamed `plusDays`/`plusMonths`/`plusYears` |
| `getPrevious/Following/NearestDayOfWeek` | G21, G19, G18, G5, G11 | Simplify + unify |
| `getEndOfCurrentMonth(DayDate)` | G14 | → `getEndOfMonth()` |
| `weekInMonthToString`, `relativeToString` | F4 | Delete (with their tests) |
| `toSerial` | N1 | → `getOrdinalDay` |
| `toDate`, `getDayOfWeek`, `compare` | G6, G22 | Pull up into `DayDate` |
| `compare` | N1 | → `daysSince` |
| `isInRange` switch | G23 | → `DateInterval` enum |
| `dateFormatSymbols`, `isLeapYear`, `lastDayOfMonth` | G6 | Extract `DateUtil` |
| `Month.make` | N1 | → `Month.fromInt` / `toInt()` |
| `plusYears` / `plusMonths` duplication | G5 | Extract `correctLastDayOfMonth` |
| Literal `1` for January/Sunday | G25 | `Month.JANUARY.toInt()` |

## Worked Example
**Coverage → bug → fix, for `getNearestDayOfWeek`.** Existing tests covered 91 of 185 statements (~50%) `[T2]`. Martin wrote an independent suite reaching 92%. `testGetNearestDayOfWeek` failed for a band of inputs; the commented-out cases showed the failures were exactly those where the nearest day lay in the *future* `[T7]` — a boundary error `[T5]`. Clover then showed line 719 never executed `[T8]`: `adjust` was always negative, so `adjust >= 4` could never be true. The algorithm was replaced with:
```java
int delta = targetDOW - base.getDayOfWeek();
int positiveDelta = delta + 7;
int adjust = positiveDelta % 7;
if (adjust > 3)
  adjust -= 7;
return SerialDate.addDays(adjust, base);
```
and later restated as an instance method with explaining variables. Final result: coverage *dropped* to 84.9% (45 of 53 statements) — not because less was tested, but because the class shrank from 185 executable statements to 53, so a handful of trivial uncovered lines weighed more.

## Key Takeaways
1. Never refactor without coverage — measure it, then write your own independent suite before touching structure.
2. Write tests for behavior you believe *should* exist and leave them commented; they become your refactoring backlog.
3. Read the *pattern* of failing tests and the *pattern* of uncovered lines — both localize the defect.
4. Bugs congregate `[T6]`: a change-history entry saying a function was already patched is a signal to test it exhaustively.
5. Base classes must not know their derivatives — reach for ABSTRACT FACTORY when they do.
6. Constants-in-an-interface plus int codes is a smell whose cure is an enum; the enum then absorbs the parse/format/validate functions and lets you delete them.
7. Make logical dependencies physical, or they will surprise the next person who "pulls the method up."
8. Shrinking a class can lower its coverage percentage — judge coverage by uncovered *lines*, not the ratio.

## Connects To
- **Ch 9 (Unit Tests)** and **Ch 17 T1–T9**: the entire "First, Make It Work" phase.
- **Ch 15 (JUnit Internals)**: same heuristic-cited method, applied to already-clean code.
- **Ch 17 (Smells and Heuristics)**: every bracketed code here.
- **Ch 6 (Objects and Data Structures)** / **Ch 10 (Classes)**: G6 wrong level of abstraction, G7 base-on-derivative.
- **GOF**: ABSTRACT FACTORY, SINGLETON, DECORATOR combination in `DayDateFactory`.
- **Fowler, _Refactoring_**: Feature Envy, Move Method, Replace Type Code with Class.
