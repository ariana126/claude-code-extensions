# Chapter 12: Emergence

## Core Idea
Good design *emerges* from following Kent Beck's four rules of Simple Design — runs all the tests, contains no duplication, expresses the intent of the programmer, minimizes the number of classes and methods — applied in that order of importance, continuously, as you write code.

## Frameworks Introduced

- **Four Rules of Simple Design** (Kent Beck): A design is "simple" if it
  1. **Runs all the tests**
  2. **Contains no duplication**
  3. **Expresses the intent of the programmer**
  4. **Minimizes the number of classes and methods**

  The rules are given **in order of importance**.
  - When to use: Continuously, at the granularity of "each few lines of code we add."
  - How:
    1. Write the code and the tests that verify it. A comprehensively tested system that passes all its tests all of the time is a *testable* system; a system that cannot be verified should never be deployed.
    2. Stop. Pause and reflect on the new design: *did we just degrade it?*
    3. If so, refactor — incrementally. Increase cohesion, decrease coupling, separate concerns, modularize system concerns, shrink functions and classes, choose better names.
    4. Run the tests to demonstrate you haven't broken anything.
    5. Apply rules 2–4 during this refactoring step; when they conflict, the earlier rule wins.
  - Why it works / failure mode: Rule 1 is not just a correctness check — it is a *design force*. Making a system testable pushes classes toward small and single-purpose (easier to test SRP-conforming classes), and tight coupling makes tests hard to write, so writing more tests drives you toward DIP, dependency injection, interfaces, and abstraction. Following an obvious rule about running tests yields low coupling and high cohesion, the primary OO goals. Writing tests leads to better designs.

- **Simple Design Rules 2–4: Refactoring**: Once tests exist, you are *empowered* to keep code clean, because the tests eliminate the fear that cleaning up will break something.
  - When to use: Immediately after every small increment of working code.
  - How: In the refactoring step, apply anything from the entire body of knowledge about good software design; specifically eliminate duplication, ensure expressiveness, minimize class and method counts.

- **TEMPLATE METHOD (for higher-level duplication)**: Common technique for removing duplication of *algorithm structure* rather than of lines.
  - When to use: When two or more methods share the same sequence of steps and differ only in one or two steps.
  - How: Pull the shared sequence into a single method on an abstract base class; make the varying step(s) `abstract protected`; let subclasses fill in the "hole," supplying the only bits of information that are not duplicated.

## Key Concepts
- **Emergent design**: Good design arising as a byproduct of following simple rules continuously, rather than being specified in advance.
- **Testable system**: One that is comprehensively tested and passes all its tests all of the time; untestable systems are unverifiable.
- **Duplication of implementation**: Two methods computing the same fact independently (e.g. `isEmpty()` tracking a boolean while `size()` tracks a counter) — duplication even though no lines look alike.
- **Reuse in the small**: Extracting commonality at a tiny scale, which raises the extracted method's visibility so others can abstract and reuse it — understanding this is essential to achieving reuse in the large.
- **Expressiveness**: Code that clearly states the intent of its author, so maintainers spend less time understanding it.
- **Standard nomenclature**: Using pattern names such as COMMAND or VISITOR in class names to communicate design succinctly.
- **Documentation by example**: A primary goal of well-written unit tests — a reader should get a quick understanding of what a class is all about.
- **Pointless dogmatism**: Rules like "an interface for every class" or "always separate data classes from behavior classes" that inflate class and method counts for no benefit.

## Mental Models
- Use **"did I just degrade the design?"** as the checkpoint after every few lines — not after every few weeks.
- Think of **tests as permission**: they are what converts refactoring from a gamble into a routine.
- Think of **duplication as the primary enemy** of a well-designed system: additional work, additional risk, additional unnecessary complexity.
- Use **"massage similar lines to look even more alike"** as a preparatory move — near-duplicates become extractable once they are made identical.
- Think of the **most likely next reader of your code as yourself**; write for that person.

## Anti-patterns
- **Untestable design**: A perfect design on paper is questionable if there is no simple way to verify the system works as intended.
- **Independent implementations of derivable facts**: `isEmpty()` tracking its own boolean instead of deriving from `size()` — two sources of truth that can disagree.
- **Tolerating "just a few lines" of duplication**: Creating a clean system requires the will to eliminate duplication even at the tiniest scale; small tolerated duplication is where SRP violations hide.
- **Convoluted code you understand today**: Easy to write while deep in the problem; maintainers will not have that depth, and most of a project's cost is long-term maintenance.
- **Getting code working and moving on**: The most important way to be expressive is to *try* — skipping that step is the default failure.
- **Over-applying rules 2 and 3**: Elimination of duplication, expressiveness, and SRP taken too far produce a swarm of tiny classes and methods; rule 4 exists to counterweight — but it is the *lowest* priority, so never sacrifice tests, duplication removal, or expressiveness for a lower class count.

## Code Examples

Duplication of implementation — before and after:

```java
   int size() {}
   boolean isEmpty() {}
```

```java
   boolean isEmpty() {
      return 0 == size();
   }
```

Small-scale duplication — before:

```java
   public void scaleToOneDimension(
        float desiredDimension, float imageDimension) {
     if (Math.abs(desiredDimension - imageDimension) < errorThreshold)
        return;
     float scalingFactor = desiredDimension / imageDimension;
     scalingFactor = (float)(Math.floor(scalingFactor * 100) * 0.01f);

     RenderedOp newImage = ImageUtilities.getScaledImage(
        image, scalingFactor, scalingFactor);
     image.dispose();
     System.gc();
     image = newImage;
   }

   public synchronized void rotate(int degrees) {
      RenderedOp newImage = ImageUtilities.getRotatedImage(
         image, degrees);
      image.dispose();
      System.gc();
      image = newImage;
   }
```

After — the common tail extracted:

```java
   public void scaleToOneDimension(
        float desiredDimension, float imageDimension) {
     if (Math.abs(desiredDimension - imageDimension) < errorThreshold)
        return;
     float scalingFactor = desiredDimension / imageDimension;
     scalingFactor = (float)(Math.floor(scalingFactor * 100) * 0.01f);

     replaceImage(ImageUtilities.getScaledImage(
        image, scalingFactor, scalingFactor));
   }

   public synchronized void rotate(int degrees) {
      replaceImage(ImageUtilities.getRotatedImage(image, degrees));
   }

   private void replaceImage(RenderedOp newImage) {
      image.dispose();
      System.gc();
      image = newImage;
   }
```

- **What it demonstrates**: Extracting commonality at a very tiny level is how you *start to recognize* violations of SRP — the extracted `replaceImage` may then move to another class entirely.

## Worked Example

**TEMPLATE METHOD applied to vacation accrual.**

Before — two methods that are largely the same, differing only in the legal-minimums step:

```java
   public class VacationPolicy {
      public void accrueUSDivisionVacation() {
         // code to calculate vacation based on hours worked to date
         // …
         // code to ensure vacation meets US minimums
         // …
         // code to apply vaction to payroll record
         // …
      }

      public void accrueEUDivisionVacation() {
         // code to calculate vacation based on hours worked to date
         // …
         // code to ensure vacation meets EU minimums
         // …
         // code to apply vaction to payroll record
         // …
      }
   }
```

After — the algorithm lives once; subclasses fill the hole:

```java
   abstract public class VacationPolicy {
      public void accrueVacation() {
         calculateBaseVacationHours();
         alterForLegalMinimums();
         applyToPayroll();
      }

      private void calculateBaseVacationHours() { /* … */ };
      abstract protected void alterForLegalMinimums();
      private void applyToPayroll() { /* … */ };
   }

   public class USVacationPolicy extends VacationPolicy {
      @Override protected void alterForLegalMinimums() {
          // US specific logic
      }
   }

   public class EUVacationPolicy extends VacationPolicy {
      @Override protected void alterForLegalMinimums() {
          // EU specific logic
      }
   }
```

The varying step is the only thing each subclass supplies; every other line exists exactly once. Adding a third division adds one subclass, not a third copy of the algorithm.

## Key Takeaways
1. Apply the Four Rules of Simple Design in Beck's priority order — tests first, duplication second, expressiveness third, minimal class/method count last.
2. Write and run tests continuously; testability is a design force that produces low coupling and high cohesion for free.
3. Refactor in the gap after every few lines of new code, not as a scheduled phase; the tests are what make this fearless.
4. Hunt duplication in all its forms — identical lines, near-identical lines (massage them alike first), and duplicated implementations of the same fact.
5. Use TEMPLATE METHOD to remove higher-level duplication where an algorithm's shape repeats and only a step varies.
6. Express intent with good names, small functions and classes, standard pattern nomenclature, and expressive unit tests — and above all, by *trying*.
7. Keep overall class and method counts low, but never at the cost of the three higher-priority rules; resist dogma like "an interface for every class."

## Connects To
- **Ch 2 (Meaningful Names) & Ch 3 (Functions)**: The concrete tactics behind rule 3, expressiveness.
- **Ch 9 (Unit Tests)**: Rule 1 depends entirely on clean, fast, expressive tests.
- **Ch 10 (Classes)**: Rule 2's small extractions are how SRP violations get discovered.
- **Ch 11 (Systems)**: Dependency injection and abstraction are what tests push you toward; the same emergent-design argument scaled to architecture.
- **Ch 14 (Successive Refinement)**: The Args case study is these four rules run end-to-end on a real module.
- **DRY / SRP / DIP**: The rules are a practical route to principles that otherwise take years to internalize.
