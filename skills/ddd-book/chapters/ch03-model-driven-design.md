# Chapter 3: Binding Model and Implementation

## Core Idea
A model that isn't literally reflected in the code is worthless — the analysis-model / design-model split guarantees the model degrades into a data structure. Demand *one* model that serves analysis and design equally well, and require everyone who shapes it to touch the code.

## Frameworks Introduced

- **MODEL-DRIVEN DESIGN**:
  > Design a portion of the software system to reflect the domain model in a very literal way, so that mapping is obvious. Revisit the model and modify it to be implemented more naturally in software, even as you seek to make it reflect deeper insight into the domain. Demand a single model that serves both purposes well, in addition to supporting a robust UBIQUITOUS LANGUAGE.
  >
  > Draw from the model the terminology used in the design and the basic assignment of responsibilities. The code becomes an expression of the model, so **a change to the code may be a change to the model**. Its effect must ripple through the rest of the project's activities accordingly.
  - When to use: whenever domain complexity is the dominant problem and you have a modeling-paradigm language (OO, or logic à la Prolog).
  - How:
    1. Reject any model that isn't practical to implement — search for a new one.
    2. Reject any model that doesn't faithfully express the key domain concepts — search for a new one.
    3. Iterate: modeling, design, and coding become a **single iterative loop**, not phases.
    4. Keep exactly one model per part of the system, applying from code through requirements analysis.
  - Why it works: there are always many valid abstractions of a domain and many valid designs for a problem. That surplus is what makes binding the two feasible — the extra criterion ("must work as both") narrows the space to the *relevant* models.
  - Failure mode: binding at the cost of a weakened analysis (technically compromised) or a clumsy design (domain-faithful but eschewing software design principles). Both objectives must survive.

- **HANDS-ON MODELERS**:
  > Any technical person contributing to the model must spend some time touching the code, whatever primary role he or she plays on the project. Anyone responsible for changing code must learn to express a model through the code. Every developer must be involved in some level of discussion about the model and have contact with domain experts. Those who contribute in different ways must consciously engage those who touch the code in a dynamic exchange of model ideas through the UBIQUITOUS LANGUAGE.
  - When to use: always; specialized roles are fine, but never split *modeling* from *implementation*.
  - Why it works: model intent lives in details that don't survive a UML handoff, and feedback about implementation constraints (e.g., an abstraction that's ruinously inefficient on your platform) must reach the modeler in days, not months.
  - Key line: **"Programmers are modelers, whether anyone likes it or not."** So set the project up so programmers do good modeling work.

- **Letting the Bones Show** (models matter to users): expose the design model to the user rather than layering an illusory second model in the UI. An imperfect illusion causes confusion at best, bugs at worst.
  - When to use: any time UI concepts diverge from domain concepts.
  - How: either reveal the real model (and let users leverage what they already know about it), or change the underlying model so it obeys the rules the user expects. Never maintain both.

## Key Concepts
- **MODEL-DRIVEN DESIGN** — a single model that literally drives both analysis and implementation.
- **Analysis model** — a model built to understand the business with no consideration of its role in software; Evans' primary target of criticism.
- **The deadly divide** — the gap between analysis and design where insight gained in each fails to feed the other.
- **HANDS-ON MODELERS** — the pattern requiring model contributors to write code.
- **Modeling paradigm** — a language/tool substrate whose constructs are direct analogs of model concepts (objects, logic rules). Required for MODEL-DRIVEN DESIGN to pay off.
- **Navigation map** — the diagram of a pattern language showing how the patterns of Part II relate.
- **Astrolabe** — Evans' emblem for the chapter: a *mechanical implementation of an object-oriented model of the sky*.

## Mental Models
- **Think of the code as an expression of the model, not a translation of it.** If the mapping isn't obvious to a reader, the binding has failed.
- **Use "can I implement it?" as a modeling criterion, and "does it express the domain?" as a design criterion.** Neither gets to win alone.
- **Treat a refactoring as a model change.** Developers who don't realize this weaken the model with every cleanup.
- **Prefer a language whose runtime constructs *are* your model constructs.** C and procedural languages have no corresponding paradigm — the program becomes technical manipulations of data linked by anticipated execution paths, not conceptual connections.

## Anti-patterns
- **The wall-sized class diagram**: months of expert collaboration produced a model "true to the domain" — a web of associations with no natural borders that didn't translate into storable, retrievable units with transactional integrity (*on an object database* — mapping wasn't the issue). Developers concluded conceptual objects couldn't found a design and built an ad-hoc one instead. End state was indistinguishable from a hacked-together C++ app with no modeling at all: functional, bloated, unmaintainable, opaque.
- **Separate analysis model and design model**: knowledge crunched during analysis is lost when coding forces new abstractions; complex model↔design mappings are impossible to maintain as the design changes. The pure analysis model even *fails at understanding*, because crucial discoveries only emerge during implementation, so the up-front model goes deep on irrelevancies and misses what matters.
- **The ivory-tower architect**: Evans' own project, where management forbade the modeler to code. The model was never put to work — intent was lost in handoff, and platform-efficiency feedback took months. Developers rationally shipped without it, reducing the model to a data structure.
- **The manufacturing metaphor** (skilled engineers design, less-skilled laborers assemble) — "software development is *all* design."
- **Superimposed user model**: IE's "Favorites" — the user thinks it's a persisted list of site names; the implementation is a file whose *filename* is the title. Typing "Laziness: The Secret to Happiness" yields "A filename cannot contain any of the following characters: \ / : * ? " < > |" — *what* filename? And if the page title already contains an illegal character, IE silently strips it. **Quietly changing data is completely unacceptable in most applications.**

## Worked Example — From Procedural to Model-Driven (PCB bus rules)

**The gap:** A PCB layout tool assigns layout rules to *nets* (tens of thousands of them). Engineers think in **buses** — groups of 8/16/256 nets that should share rules. The tool has no concept of a bus.

**Mechanistic design (scripts).** Engineers hand-name nets so an alphabetical sort clusters each bus, then scripts rewrite the tool's data files:

```
Net Name    Component.Pin        Net Name  Rule Type      Parameters
--------    -------------        --------  ---------      ----------
Xyz0        A.0, B.0             Xyz1      min_linewidth  5
Xyz1        A.1, B.1             Xyz1      max_delay      15
Xyz2        A.2, B.2             Xyz2      min_linewidth  5
```

Procedure: sort net list by name → scan for lines matching the bus-name pattern → parse each net name → append net + rule to the rules file → repeat until the prefix stops matching. Input `Xyz max_vias 3` produces `Xyz0/Xyz1/Xyz2 max_vias 3`.

**Diagnosis:** the bus's existence is *inferred* through sorts and string matches; the concept is never dealt with explicitly. One script was reasonable; there are now dozens. A different file format means starting over. Richer functionality or interactivity must be paid for inch by inch. The only possible test is end-to-end file-in/file-out comparison.

**Model-driven design.** Make `Bus` and `Net` real, under an `Abstract Net`:

```java
abstract class AbstractNet {
    private Set rules;
    void assignRule(LayoutRule rule) {
        rules.add(rule);
    }
    Set assignedRules() {
        return rules;
    }
}

class Net extends AbstractNet {
    private Bus bus;
    Set assignedRules() {
        Set result = new HashSet();
        result.addAll(super.assignedRules());
        result.addAll(bus.assignedRules());
        return result;
    }
}
```

File handling becomes small, replaceable services and utilities:

| Element | Responsibility |
|---|---|
| Net List import (Service) | Reads Net List file, creates a `Net` per entry |
| Net Rule export (Service) | Given a collection of `Net`s, writes all attached rules to the Rules file |
| Net Repository | Provides access to `Net`s by name |
| Inferred Bus Factory | Given `Net`s, uses naming conventions to infer `Bus`es and create instances |
| Bus Repository | Provides access to `Bus`es by name |

Startup is just populating the repositories:

```java
Collection nets = NetListImportService.read(aFile);
NetRepository.addAll(nets);
Collection buses = InferredBusFactory.groupIntoBuses(nets);
BusRepository.addAll(buses);
```

The core domain logic is now unit-testable in isolation:

```java
public void testBusRuleAssignment() {
    Net a0 = new Net("a0");
    Net a1 = new Net("a1");
    Bus a = new Bus("a"); //Bus is not conceptually dependent
    a.addNet(a0);         //on name-based recognition, and so
    a.addNet(a1);         //its tests should not be either.
    NetRule minWidth4 = NetRule.create(MIN_WIDTH, 4);
    a.assignRule(minWidth4);
    assertTrue(a0.assignedRules().contains(minWidth4));
    assertEquals(minWidth4, a0.getRule(MIN_WIDTH));
    assertEquals(minWidth4, a1.getRule(MIN_WIDTH));
}
```

A façade serves both an interactive UI and the legacy rules file:

```java
public void assignBusRule(String busName, String ruleType, double parameter) {
   Bus bus = BusRepository.getByName(busName);
   bus.assignRule(NetRule.create(ruleType, parameter));
}
```

**Payoff:** with one operation the script would have been fine — but there were 20+. The model-driven design scales, accommodates constraints on rule combination, and has well-defined interfaces that can be unit-tested. Note the comment in the test: `Bus` is deliberately *not* dependent on the naming convention that discovers it; that inference is isolated in the factory. And Evans' caveat: **such a design does not emerge in a single step** — it takes several iterations of refactoring and knowledge crunching.

## Key Takeaways
1. Demand one model for analysis and design; when either objective fails, find a new model rather than bridging with a mapping.
2. If the mapping from model to code isn't literal and obvious, the model will drift into irrelevance and eventually into a mere data structure.
3. Anyone contributing to the model must touch code; anyone changing code must learn to express the model in it.
4. Modeling, design, and coding are one iterative loop — treat "analysis phase" as a warning sign.
5. Replace inferred, implicit concepts (a bus recognized by string sorting) with explicit objects; this is what makes behavior testable and extensible.
6. Don't fake a second model in the UI. Reveal the real one, or change the real one to match user expectations.
7. MODEL-DRIVEN DESIGN needs a modeling paradigm with tool support; in purely procedural languages it has limited applicability.

## Connects To
- **Ch 1 (Knowledge Crunching)**: "binding the model and the implementation" — this chapter formalizes that ingredient.
- **Ch 2 (Ubiquitous Language)**: the LANGUAGE is the channel through which model information flows between developers, experts, and software.
- **Part II (Ch 4–7)**: the building blocks — Layered Architecture, Entities, Value Objects, Services, Aggregates, Factories, Repositories — that make code express a model effectively.
- **Part III (Ch 8–13)**: refining model, design, and code as a single activity.
- **Ch 14 (Bounded Context)**: "one model" holds *within a single context*; different subsystems may have different models.
- **Part IV (Strategic Design)**: a more productive definition of high-level technical roles than the ivory-tower architect.
- **Responsibility-driven design** (Wirfs-Brock 1990/2003) and **design by contract** (Meyer 1988) — the design traditions Part II builds on.
