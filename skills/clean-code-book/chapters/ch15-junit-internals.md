# Chapter 15: JUnit Internals

## Core Idea
Take a module that is already good — JUnit's `ComparisonCompactor` — and improve it anyway, applying the Boy Scout Rule one named heuristic at a time. Refactoring is iterative, exploratory, and sometimes undoes its own earlier steps.

## Frameworks Introduced
- **The Boy Scout Rule applied to a clean module**: "Leave the code a little better than you found it" — even when the original authors did an excellent job. No module is immune from improvement.
  - When to use: every time you open a file for any reason, not just when it smells.
  - How: read the module top to bottom; at each discomfort, name the heuristic you are reacting to (e.g. `[N6]`, `[G28]`), apply the smallest change that fixes it, run the tests, continue.
  - Why it works: the critiques are principled and citable, so the change is defensible rather than a matter of taste. Failure mode: refactoring without a green test suite between steps.

- **Heuristic-cited refactoring**: Annotate every change with the smell code from Ch17 that justifies it.
  - When to use: code review, pairing, or teaching — anywhere you must explain *why*, not just *what*.
  - How: `f`-prefix → `[N6] Avoid Encodings`; naked boolean expression → `[G28] Encapsulate Conditionals`; `!` in a condition → `[G29] Avoid Negative Conditionals`; a function doing format + compact → `[G30] Functions Should Do One Thing`.

- **Analysis/Synthesis separation with topological ordering**: Split a module into functions that *analyze* inputs and functions that *synthesize* output, then order definitions so each appears just after its first use.
  - When to use: any module that computes intermediate state and then formats a result.

## Key Concepts
- **ComparisonCompactor**: JUnit's helper that turns two differing strings into a compact diff message like `<...B[X]D...>`.
- **Defactored code**: Martin's term for a deliberately worsened version, shown to prove the original was already good.
- **Hidden temporal coupling**: `findCommonSuffix` silently depending on `findCommonPrefix` having already run.
- **Bucket brigade**: Structuring calls so each function's output feeds the next, making ordering physically enforced.
- **Boy Scout Rule**: Check the module in cleaner than you checked it out.

## Mental Models
- **Use the tests as the spec.** Martin presents `ComparisonCompactorTest` before the implementation: if you cannot understand the requirements from the tests, the tests are the first thing to fix.
- **Think of "index" vs "length" as a bug detector.** Off-by-one clutter (`+1` scattered through the code) is a symptom that a variable is named for the wrong concept. Renaming `suffixIndex` → `suffixLength` made the `+1`s vanish *and* exposed a latent dead `if`.
- **Treat a suddenly-sensible operator as a bug report.** When fixing the base of an index made `>` want to become `>=`, that meant the old condition never made sense — i.e. it was dead code `[G9]`.
- **Refactoring converges, it does not march.** Expect to inline methods you extracted and re-invert conditionals you inverted.

## Anti-patterns
- **Scope-encoding prefixes (`fExpected`, `fActual`)** `[N6]`: modern IDEs supply scope; the prefix is noise.
- **Unencapsulated compound conditional** `[G28]`: `if (expected == null || actual == null || areStringsEqual())` states mechanism, not intent.
- **Negative conditionals** `[G29]`: `shouldNotCompact()` costs a mental inversion at every call site.
- **Names that hide side effects** `[N7]`: `compact()` also formatted the message and might not compact at all — the real name is `formatCompactedComparison`.
- **Local variables shadowing member variables** `[N4]`: `String expected = compactString(this.expected)` forces `this.` noise and ambiguity.
- **Inconsistent conventions inside one function** `[G11]`: two calls that mutate fields followed by two that return values.
- **Passing an argument purely to force call order** `[G32]`: it is arbitrary; another programmer will delete it.

## Code Examples

Before — mechanism exposed, negative sense, misleading name:
```java
public String compact(String message) {
  if (expected == null || actual == null || areStringsEqual())
    return Assert.format(message, expected, actual);
  findCommonPrefix();
  findCommonSuffix();
  String expected = compactString(this.expected);
  String actual = compactString(this.actual);
  return Assert.format(message, expected, actual);
}
```

After — intent named, condition positive, one responsibility:
```java
public String formatCompactedComparison(String message) {
  String compactExpected = expected;
  String compactActual = actual;
  if (shouldBeCompacted()) {
    findCommonPrefixAndSuffix();
    compactExpected = compact(expected);
    compactActual = compact(actual);
  }
  return Assert.format(message, compactExpected, compactActual);
}
```
- **What it demonstrates**: `[G28]`+`[G29]`+`[G30]`+`[N4]`+`[N7]` applied to a single six-line function.

Exposing temporal coupling by composition rather than by argument:
```java
private void findCommonPrefixAndSuffix() {
  findCommonPrefix();
  suffixLength = 0;
  for (; !suffixOverlapsPrefix(); suffixLength++) {
    if (charFromEnd(expected, suffixLength) !=
        charFromEnd(actual, suffixLength))
      break;
  }
}
```
- **What it demonstrates**: `[G31]` — merging the two functions and calling the prerequisite first is more dramatic than threading `prefixIndex` through as a parameter `[G32]`.

Dead-code discovery via clean-up:
```java
private String compactString(String source) {
  return
    computeCommonPrefix() +
    DELTA_START +
    source.substring(prefixLength, source.length() - suffixLength) +
    DELTA_END +
    computeCommonSuffix();
}
```
- **What it demonstrates**: `[G9]` — both guarding `if` statements turned out to be nonfunctional; commenting them out kept the tests green, so they were deleted.

## Reference Tables

| Order | Critique | Heuristic | Change made |
|---|---|---|---|
| 1 | `f` prefixes on members | N6 Avoid Encodings | `fExpected` → `expected` |
| 2 | Naked compound condition | G28 Encapsulate Conditionals | extract `shouldNotCompact()` |
| 3 | Locals shadow members | N4 Unambiguous Names | `compactExpected` / `compactActual` |
| 4 | Negative sense | G29 Avoid Negative Conditionals | invert to `canBeCompacted()` |
| 5 | Name hides side effect | N7 Names Should Describe Side-Effects | → `formatCompactedComparison` |
| 6 | Format + compact in one fn | G30 Functions Should Do One Thing | extract `compactExpectedAndActual()` |
| 7 | Mixed set-vs-return style | G11 Inconsistency | make finders return values |
| 8 | Vague names | N1 Choose Descriptive Names | `prefix` → `prefixIndex` |
| 9 | Order dependency hidden | G31 Hidden Temporal Couplings | merge into `findCommonPrefixAndSuffix()` |
| 10 | Ordering arg is arbitrary | G32 Don't Be Arbitrary | revert the parameter; compose instead |
| 11 | `+1`s everywhere | G33 Encapsulate Boundary Conditions | `suffixIndex` → zero-based `suffixLength` |
| 12 | Guards never fire | G9 Dead Code | delete both `if`s in `compactString` |

## Worked Example
`new ComparisonCompactor(1, "abcde", "abfde").compact(null)` must yield `expected:<...b[c]d...> but was:<...b[f]d...>`. The final design reaches this by splitting the work in two: **analysis** (`findCommonPrefix`, `findCommonPrefixAndSuffix`, `charFromEnd`, `suffixOverlapsPrefix`) computes `prefixLength` and `suffixLength`; **synthesis** (`compact`, `startingEllipsis`, `startingContext`, `delta`, `endingContext`, `endingEllipsis`) assembles the string via a `StringBuilder` chain that reads exactly like the output format. Every off-by-one that used to litter the module now lives in exactly two places: `charFromEnd`'s `- i - 1` and `suffixOverlapsPrefix`'s two `<=` operators — both places where it makes obvious sense.

## Key Takeaways
1. Cite a heuristic for every refactoring; an uncited change is an opinion, a cited one is a critique.
2. Run the full test suite after each individual change — the chapter's whole method depends on it.
3. Expect to reverse earlier decisions; refactoring is trial and error converging on something professional.
4. Scattered `+1`/`-1` means a variable is named for the wrong concept — fix the concept, not the arithmetic.
5. When a boundary fix makes an old comparison suddenly meaningful, you have found dead or buggy code.
6. Expose temporal coupling by composing functions, not by threading arguments that look optional.
7. Order definitions topologically — each function just after its first use, analysis before synthesis.

## Connects To
- **Ch 2 (Meaningful Names)**: N1/N4/N6/N7 all fire in this chapter.
- **Ch 3 (Functions)**: G30/G34 — do one thing, one level of abstraction.
- **Ch 9 (Unit Tests)**: the test suite is what makes this aggressive refactoring safe.
- **Ch 16 (Refactoring SerialDate)**: same method applied to code that is *not* already clean.
- **Ch 17 (Smells and Heuristics)**: the vocabulary used throughout.
- **Fowler, _Refactoring_**: Extract Method, Rename, Inline Method as the mechanical moves.
