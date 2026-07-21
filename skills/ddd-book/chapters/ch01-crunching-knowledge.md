# Chapter 1: Crunching Knowledge

## Core Idea
A domain model is not extracted from experts in a one-way handoff — it is *crunched* out of them through iterative, collaborative experimentation between developers and domain experts, with code as the feedback loop. The model that survives this process contains business knowledge, not just data structure.

## Frameworks Introduced

- **Knowledge Crunching**: Developers and domain experts jointly digest a torrent of raw domain information into a small set of abstractions that make sense of the mass. Named by analogy to financial analysts "crunching numbers."
  - When to use: continuously, from day one of any non-trivial domain project — not as an up-front analysis phase.
  - How:
    1. Sit with domain experts and walk through concrete scenarios, not feature lists.
    2. Sketch objects/interactions live; let experts correct your vocabulary out loud.
    3. When the objects can't carry a scenario, brainstorm new ones or reshape old ones.
    4. Write a thin prototype (no persistence, no UI, driven by tests) to make the model concrete.
    5. Show experts the running behavior; harvest their reaction; repeat.
  - Why it works: the *spoken sentence* is a fast viability test — awkward phrasing signals a bad model before you've written code. The prototype closes the loop so experts critique reality, not diagrams.
  - Failure mode: crunching done only among programmers yields naive concepts; done only with analysts (waterfall) yields no feedback and knowledge that never accumulates.

- **The Five Ingredients of Effective Modeling**: the checklist Evans distills from the PCB project.
  - When to use: as a self-audit when modeling feels unproductive.
  - How — verify all five are present:
    1. **Binding the model and the implementation** — forged early via crude prototype, maintained through every iteration.
    2. **Cultivating a language based on the model** — anyone can speak model terms in sentences and be understood without translation.
    3. **Developing a knowledge-rich model** — objects have behavior and enforce rules; not a data schema.
    4. **Distilling the model** — concepts are *dropped* as aggressively as they are added.
    5. **Brainstorming and experimenting** — discussions become laboratories running hundreds of model variations.

- **Deep Model**: an abstraction that expresses the domain expert's real concerns, reached only after superficial model elements are discarded or reframed.
  - When to use: when experts keep saying "yes, but…" about a model that seems technically fine.
  - How: keep crunching past the obvious nouns; watch for a shift in *what the business is actually about* (in the shipping example: from "moving containers place to place" to "transferring responsibility for cargo between parties").

## Key Concepts
- **Knowledge crunching** — collaborative distillation of domain information into abstractions that carry the business's principles.
- **Deep model** — a model that pierces to the heart of the domain, usually not visible at the outset.
- **Continuous learning** — the deliberate practice of growing domain and modeling knowledge over the life of a project (Kerievsky 2003).
- **Knowledge-rich design** — design where business rules and activities are first-class model elements, not guard clauses.
- **Knowledge leak** — loss of hard-won understanding when people move on and neither code nor documents express it.
- **Policy** — a domain-meaningful name for the STRATEGY pattern, used when the *meaning* (not substitutability) is the motivation.
- **Distillation** — dropping concepts that don't prove central, and reshaping models so unneeded concepts can be dropped.

## Mental Models
- **Think of modeling discussions as a laboratory**, not a requirements meeting: the goal is to run and reject many model variants cheaply.
- **Use your ear as a model test.** If a proposed model makes scenario sentences awkward to say, the model is wrong.
- **Treat "find the nouns" as the starting line, not the finish.** Business activities and rules are as central to a domain as entities.
- **Assume you don't know enough.** Domains that look technically simple are the most deceiving — the ignorance is invisible, so it becomes false assumptions.

## Anti-patterns
- **Waterfall handoff (experts → analysts → programmers)**: knowledge trickles one direction and never accumulates; analysts never learn from programmers or from running software.
- **Iterative without abstraction**: build-what-they-asked, ask-what's-next. Refactoring keeps it clean, but you learn only *what* the app should do, never the *principles* behind it — so powerful features never unfold as corollaries of older ones.
- **Asking experts to specify the software**: PCB designers asked for "read an ASCII file, sort it, annotate, report." Experts are expert in the domain, not in what software can do.
- **Business rule as a guard clause**: an important policy buried in an application method is invisible to business experts, disconnected from the requirements text, and un-verifiable by the people who own the rule.
- **Modeling only entities and values**: skips the inconsistent, gap-filled business rules that experts navigate unconsciously and software cannot.

## Code Examples

Rule hidden in an application method — the anti-pattern:

```java
public int makeBooking(Cargo cargo, Voyage voyage) {
   double maxBooking = voyage.capacity() * 1.1;
   if ((voyage.bookedCargoSize() + cargo.size()) > maxBooking)
      return -1;
   int confirmation = orderConfirmationSequence.next();
   voyage.addCargo(cargo, confirmation);
   return confirmation;
}
```

Rule made explicit as a named domain concept:

```java
public int makeBooking(Cargo cargo, Voyage voyage) {
   if (!overbookingPolicy.isAllowed(cargo, voyage)) return -1;
   int confirmation = orderConfirmationSequence.next();
   voyage.addCargo(cargo, confirmation);
   return confirmation;
}

// Overbooking Policy
public boolean isAllowed(Cargo cargo, Voyage voyage) {
   return (cargo.size() + voyage.bookedCargoSize()) <=
          (voyage.capacity() * 1.1);
}
```

- **What it demonstrates**: extracting a hidden concept. The requirement line "Allow 10% overbooking" becomes a named class a business expert can be walked through, closing the feedback loop.

## Worked Example — Extracting a Hidden Concept

1. **Starting model**: `Cargo` — `Voyage`. The booking application's job is to associate each Cargo with a Voyage and record the relationship.
2. **New requirement arrives**: "Allow 10% overbooking." (Standard shipping practice — vessels accept more cargo than capacity because of last-minute cancellations. Real rules can be far more complex, favoring major customers or cargo types.)
3. **Naive implementation**: multiply capacity by 1.1 inline, guard-clause the booking method. Works, ships, passes tests.
4. **Diagnosis**: no business expert could read this code and verify the rule, even with a developer guiding them. Nothing connects the requirement sentence to the code. If the rule grew complex, the risk compounds.
5. **Reframe**: overbooking is a *policy*. Policy is the domain-meaningful name for STRATEGY (Gamma et al. 1995). Note the motivation is **meaning**, not substitutability — nobody needs to swap implementations here.
6. **Result**: an `Overbooking Policy` class. Everyone involved now understands overbooking as a distinct, important business rule rather than an obscure calculation; and programmers can show experts an artifact the experts can validate.
7. **Caveat Evans attaches**: *do not* apply this elaborate treatment to every detail of the domain — see Distillation (Ch 15) for choosing where to spend it.

## Key Takeaways
1. Model with domain experts by walking concrete scenarios and sketching live — do not ask them to specify the software.
2. Build a crude, infrastructure-free prototype early; the binding between model and code is what makes all later feedback real.
3. When a business rule hides inside a method, name it as a domain concept so experts can verify it.
4. Drop concepts as deliberately as you add them; a concept that isn't earning its place distorts the model.
5. The model you need is usually not the first one — expect a profound reframing of what the business is about after months of crunching.
6. Knowledge leaks constantly (people leave, teams reorganize, work is outsourced). Only code and language that express the knowledge retain it.
7. Judge candidate models by whether scenario sentences come out clear and easy to say.

## Connects To
- **Ch 2 (Ubiquitous Language)**: "cultivating a language based on the model" is the ingredient this chapter names and Ch 2 develops.
- **Ch 3 (Model-Driven Design)**: "binding the model and the implementation" becomes the formal principle.
- **Ch 4 (Layered Architecture)**: where the extracted Overbooking Policy properly belongs.
- **Ch 12 (Relating Design Patterns to the Model)**: STRATEGY-as-Policy — using a design pattern for its domain meaning.
- **Ch 15 (Distillation)**: how to decide which parts of the domain deserve this level of care; also the stable core team idea.
- **Ch 8/9 (Breakthrough, Making Implicit Concepts Explicit)**: the deep-model shift previewed here.
