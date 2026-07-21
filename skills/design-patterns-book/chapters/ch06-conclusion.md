# Chapter 6: Conclusion

## Core Idea
Patterns pay off less as code to copy than as a **shared vocabulary** and a set of
**refactoring targets**: they raise the level at which you discuss design, and they name
the structures that a maturing system tends to converge on anyway.

## Frameworks Introduced

- **A Common Design Vocabulary**: name the pattern instead of describing the mechanism.
  - When to use: every design discussion, code review, and ADR.
  - How: say "let's use an Observer here" or "make a Strategy out of these classes" —
    the pattern name carries the intent, participants, and consequences with it. A reader
    who doesn't know the pattern looks it up; that's still cheaper than reverse-engineering
    the design from the code.
  - Why it works: expert knowledge is organized around conceptual chunks (algorithms,
    data structures, idioms, plans), not syntax. Patterns give the chunks names.

- **Patterns as Documentation & Learning Aid**: describe an existing system as the
  sequence of patterns it applies.
  - When to use: onboarding, documenting a legacy framework, teaching OO design.
  - How: annotate the design with pattern names; use pattern names when naming classes
    (`WindowImp`, `MazeFactory`, `GlyphIterator`). "Convoluted inheritance" and
    "unfollowable control flow" are usually just unrecognized patterns.

- **The Software Lifecycle: Prototyping → Expansionary → Consolidating** (Foote).
  - When to use: to decide *when* a redesign is due and what kind.
  - How: recognize which phase you're in — see the Reference Table below. The cycle
    repeats: expansion as new requirements land, consolidation as the software is made
    general again.

- **Patterns as Targets for Refactoring**: the endpoint of a refactoring, chosen in advance.
  - When to use: when a class hierarchy no longer matches any single problem domain and
    classes have accumulated unrelated operations and instance variables.
  - How: identify the pattern the code is groping toward, then refactor to it deliberately
    — tear classes into special- and general-purpose components, move operations up or down
    the hierarchy, rationalize interfaces, replace inheritance with composition. Applying the
    pattern *early* prevents the refactoring; recognizing it *late* still tells you what to do.

- **Patterns as an Adjunct to Design Methods** (not a replacement).
  - When to use: bridging analysis models to implementation models.
  - How: methods give notation and rules; patterns supply the missing "why". Read a
    pattern's **Applicability**, **Consequences**, and **Implementation** sections as the
    decision-support layer your method lacks. Expect a flexible design to contain objects
    that appear nowhere in the analysis model — that gap is exactly what design patterns fill.

## Key Concepts

- **Refactoring** — reorganizing a design without changing what it does; the consolidation
  phase in which frameworks emerge.
- **White-box reuse** — reuse by inheritance; dominant in the prototyping phase.
- **Black-box reuse** — reuse by object composition; replaces white-box reuse during
  consolidation.
- **Pattern language (Alexander)** — an ordered, generative set of patterns claimed to
  produce a complete building. This catalog is explicitly *not* one.
- **Forces** — the competing pressures a pattern balances; the Alexandrian idea that pushed
  the authors to write serious Applicability and Consequences sections.
- **Analysis pattern / UI pattern / performance-tuning pattern** — the other pattern
  categories a full method would need; design patterns are only one part.

## Mental Models

- **Think of a pattern name as a compression codec for design intent.** "Decorator" transmits
  structure, collaboration, benefits, and liabilities in one word.
- **Use the phase model as a diagnostic**: if inheritance is doing all the reuse work and
  the hierarchy mirrors the problem domain, you're pre-consolidation; the arthritis is coming.
- **Treat the "why" as the pattern's identity, not the "how".** Spotting a pattern is easy;
  characterizing the *problem it solves* is the hard and valuable part — and it's what lets
  you choose between two patterns with similar structure (Composite vs. Decorator vs. Proxy).
- **A catalog is a collection, not an algorithm.** There is no prescribed order to apply
  these patterns, unlike Alexander's pattern language.

## Anti-patterns

- **Treating the catalog as a pattern language**: expecting that applying patterns in
  sequence will generate a complete program. It won't — the authors explicitly disclaim this.
- **Applying patterns for their own sake**: patterns are solutions to problems; without the
  problem, you've added indirection and paid the flexibility tax for nothing.
- **Deferring all refactoring**: the expansionary phase can't run forever. Class hierarchies
  stop matching *any* problem domain and classes collect unrelated operations and state.
- **Being an uncritical consumer**: patterns make trade-offs explicit precisely so you can
  argue with them. Take the argument.
- **Cataloging without practical experience**: finding relevant patterns is nearly impossible
  without having built the systems they come from.

## Reference Tables

### The three lifecycle phases (Foote)

| Phase | What's happening | Dominant reuse | Exit signal |
|---|---|---|---|
| **Prototyping** | Rapid prototyping and incremental change until an initial requirement set is met; hierarchies closely mirror the problem domain | White-box (inheritance) | Software reaches "adolescence" and enters service |
| **Expansionary** | New requirements add classes, operations, whole hierarchies | White-box, growing | Design becomes "inflexible and arthritic"; hierarchies reflect many problem domains; classes hold unrelated operations and instance variables |
| **Consolidating** | Refactoring: split classes into special- and general-purpose parts, move operations up/down, rationalize interfaces, decompose objects | Black-box (composition) | Frameworks emerge; cycle restarts |

### GoF catalog vs. Alexander's pattern languages

| Dimension | Alexander | This catalog |
|---|---|---|
| Source material | Millennia of buildings; many classics | Short history of software; few classics |
| Ordering | Patterns given in an order of application | No prescribed order |
| Emphasis | The problem addressed | The solution, described in more detail |
| Claim | Patterns generate complete buildings | Patterns do **not** generate complete programs |
| Shared | Observation of existing systems, a description template, natural language + examples, explicit rationale | Same |

### Patterns renamed during development

| Working name | Published name |
|---|---|
| Wrapper | **Decorator** |
| Glue | **Facade** |
| Solitaire | **Singleton** |
| Walker | **Visitor** |

## Worked Example

The authors' own process is the worked example of how a pattern gets written:

1. **Spot it.** The catalog began in Erich Gamma's PhD thesis (~half the current patterns).
   Spotting patterns is easy once you've looked at enough systems.
2. **Discover the description is the hard part.** Early drafts were understandable only to
   people who *already used* the patterns — useless for the book's main purpose, teaching
   new designers.
3. **Expand for teachability.** Average pattern length went from **under 2 pages to over 10**
   by adding a detailed motivating example and sample code.
4. **Add the trade-offs.** Examine the alternative implementations and their consequences —
   the Implementation and Consequences sections.
5. **Lead with the problem.** The last major shift: characterize the problem and the context
   in which this is the *best* solution, not just the technique. "It's easier to see *what*
   someone is doing than to know *why*, and the 'why' for a pattern is the problem it solves."
6. **Get it beaten into shape.** Dozens of reviewers; a 90-page ECOOP '93 submission was
   cut to a summary before it was accepted.

**What it demonstrates**: if you write your own patterns, budget most of the effort for
steps 2–5, not step 1 — and don't do it alone.

## Key Takeaways

1. The highest-return use of this book is **vocabulary**, not code — start saying "Observer"
   and "Strategy" in design conversations.
2. **Patterns are refactoring targets.** Applying one early avoids a refactoring; recognizing
   one late tells you exactly what the refactoring should produce.
3. **Expansion → consolidation is a cycle, not a failure.** Plan for the consolidation phase
   where composition replaces inheritance.
4. A design's robustness comes from anticipating *which* requirements will change — do the
   requirements analysis that surfaces them, then choose patterns against that list.
5. **Judge a pattern by its Applicability and Consequences**, not its Structure diagram.
   Similar structures solve different problems.
6. This is a **catalog, not a pattern language** — there is no completeness claim and no
   prescribed order of application.
7. **The best designs use many patterns that dovetail and intertwine**; density of overlapping
   patterns in one space is what makes a design profound rather than merely assembled.

## Connects To
- **Ch 1**: "designing for change" — Ch 6 supplies the lifecycle model explaining *when* that
  change pressure arrives and forces refactoring.
- **Ch 2 (Lexi)**: the case study is the worked demonstration of patterns "dovetailing and
  intertwining" that this chapter's closing Alexander quote calls for.
- **Refactoring (Fowler)**: this chapter is the direct ancestor of pattern-directed refactoring.
- **Christopher Alexander, *A Pattern Language***: the origin of the pattern concept, the
  notion of design "forces", and the closing quotation on density.
- **Coplien, *Advanced C++: Programming Styles and Idioms***: lower-level, C++-specific
  companion patterns.
