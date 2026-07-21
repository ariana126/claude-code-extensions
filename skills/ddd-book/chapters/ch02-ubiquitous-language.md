# Chapter 2: Communication and the Use of Language

## Core Idea
The domain model must become the backbone of one shared language — spoken, written, diagrammed, and coded — used relentlessly by developers *and* domain experts. Translation between separate dialects is the tax that starves knowledge crunching and splinters the model.

## Frameworks Introduced

- **UBIQUITOUS LANGUAGE** (the pattern):
  > Use the model as the backbone of a language. Commit the team to exercising that language relentlessly in all communication within the team and in the code. Use the same language in diagrams, writing, and especially speech.
  >
  > Iron out difficulties by experimenting with alternative expressions, which reflect alternative models. Then refactor the code, renaming classes, methods, and modules to conform to the new model. Resolve confusion over terms in conversation, in just the way we come to agree on the meaning of ordinary words.
  >
  > **Recognize that a change in the UBIQUITOUS LANGUAGE is a change to the model.**
  - When to use: on every project where the model matters — always, and from the start, even when the model is too weak to carry it.
  - How:
    1. Draw the vocabulary from class names, prominent operations, explicitly modeled rules, applied patterns, and large-scale structure terms.
    2. Use it in developer↔developer talk, developer↔expert talk, and expert↔expert talk about requirements, planning, and features.
    3. When a phrase comes out awkward, treat it as a model defect — try alternative expressions (= alternative models).
    4. Push the winning expression back into diagrams and into the code (rename classes, methods, modules).
    5. Domain experts object to terms that don't convey domain understanding; developers watch for ambiguity/inconsistency that will trip up design.
  - Why it works: it is deliberately circular. You need a good model to have a good language, but *persistent use of the language forces the model's weaknesses into the open*. The language is the pressure that produces the model.
  - Failure mode: settling for "good enough to be understood." Not being satisfied until the language *flows* is the whole mechanism.

- **Modeling Out Loud** (addendum to UBIQUITOUS LANGUAGE):
  > Play with the model as you talk about the system. Describe scenarios out loud using the elements and interactions of the model, combining concepts in ways allowed by the model. Find easier ways to say what you need to say, and then take those new ideas back down to the diagrams and code.
  - When to use: in any design or requirements discussion; as the cheapest model-refinement technique available.
  - How: say the scenario aloud three or four different ways; the concise version names the objects that should exist.
  - Why it works: humans are specialized for spoken language (Pinker 1994). Rough edges in a model are *easy to hear* long before they're visible in a diagram. Groups without a common language spontaneously invent a pidgin — the same instinct, harnessed.

- **One Team, One Language**: no linguistic division between domain experts and developers. Multiplicity of languages may be necessary, but never along that fault line.
  - Rule: **"If sophisticated domain experts don't understand the model, there is something wrong with the model."**
  - Developers have technical jargon; users have domain jargon beyond the app's scope. Those are legitimate **extensions** to the language. They must not be *alternative vocabularies for the same domain reflecting distinct models*.
  - The UBIQUITOUS LANGUAGE is cultivated in the *intersection* of the two jargons.

- **Explanatory Model**: a separate, non-authoritative model used purely to teach the domain.
  - When to use: when the design model's class diagram is accurate but unilluminating to newcomers, or when context outside the software's scope aids understanding.
  - How: use pictures, metaphors, or the domain experts' own visual conventions. **Deliberately avoid UML** so nobody mistakes it for the design. Everyone must stay conscious of the distinction.
  - Why it works: the technical model is pared to the minimum needed to function; the explanatory model is free to add clarifying context and multiple diverse views.

## Key Concepts
- **UBIQUITOUS LANGUAGE** — the shared, model-based language used in all team communication and in the code.
- **Linguistic divide / fractured language** — experts speak jargon, developers speak design; the same person even differs in speech vs. writing.
- **Bilingual bottleneck** — the few team members who translate become chokepoints, and their translations are inexact.
- **Schism** — team members using the same term differently without realizing it; concealed by indirect communication.
- **Explanatory model** — a model used only to teach the domain, not to drive design.
- **Modeling out loud** — refining a model by speaking scenarios in it.
- **Executable bedrock** — code and tests as the least-lying document; behavior is unambiguous, but names and structure can still mislead.
- **Pidgin** — the ad-hoc shared language people invent for a task; the natural analogue of a UBIQUITOUS LANGUAGE.

## Mental Models
- **Think of a change in the language as a change to the model** — never as "just naming." Renaming propagates into diagrams, code, and sometimes behavior.
- **Use the ear as a design instrument.** Awkward-to-say ⇒ wrong model. Concise-to-say ⇒ the right objects exist.
- **Think of a diagram as an aid to a conversation, not as the model.** "The model is not the diagram."
- **Invert the usual document form**: write *a text document illustrated with selective, simplified diagrams* — not a diagram annotated with text.
- **Use the language's drift as a document health check**: if the terms in a document don't show up in speech and code, the document isn't working.

## Anti-patterns
- **"Shielding" business experts from the model** — justified with "too abstract for them," "they don't understand objects," "we collect requirements in their terminology." *Forget them.* If the abstraction can't be validated by experts, you don't know it's sound.
- **Comprehensive UML diagrams** — simultaneously too complete (every coded object, so you can't see the forest) and too incomplete (behavior, constraints, intent and meaning can't be *stated* in UML, only hinted at or shoved into bracketed text).
- **UML as programming language / code generation** — every attempt Evans saw was counterproductive; rules that don't fit a box-and-line diagram get dropped, and generators ignore textual annotations. If UML *is* your implementation, "model" loses its meaning and you still need another way to communicate the uncluttered model.
- **Documents that duplicate what code does well** — code is already an exact specification of behavior. Documents should illuminate meaning, large-scale structure, and design intent instead.
- **Documents kept alive by discipline alone** — if the language moved on and the document didn't, archive it as history; a stale active document creates confusion.
- **Separate models for implementation, design, and communication** — a hazard; one model should underlie all three.
- **Requirements written outside the model's language** — the objection "requirements should be independent of design" ignores that *all language is based on some model*; better to reframe requirements in the refined language as it evolves.

## Worked Example — Working Out a Cargo Router

Two dialogs, deliberately parallel. Watch whether the speakers discuss what the software *means to the business* or how it *works technically*.

**Scenario 1 — minimal abstraction of the domain**
> **User:** When we change the customs clearance point, we need to redo the whole routing plan.
> **Developer:** Right. We'll delete all the rows in the shipment table with that cargo id, then pass the origin, destination, and new customs clearance point into the `Routing Service`, and it'll re-populate the table. We'll need a Boolean in `Cargo` so we know there's data in the shipment table.
> **User:** Delete the rows? OK, whatever. …if we didn't have a customs clearance point before, we'll have to do the same thing.
> **User:** …but it's extra work to make supporting plans for a new itinerary, so we don't want to reroute unless the change necessitates it.
> **Developer:** *Ugh.* Then we'll have to query the table to find the old derived customs clearance point and compare it to the new one…

**Scenario 2 — domain model enriched to support discussion**
> **User:** When we change the customs clearance point, we need to redo the whole routing plan.
> **Developer:** Right. When you change any attribute in the `Route Specification`, we'll delete the old `Itinerary` and ask the `Routing Service` to generate a new one based on the new `Route Specification`.
> **User:** …we don't want to reroute unless the change necessitates it.
> **Developer:** Then we'll add functionality to the `Route Specification`. Whenever you change anything in the `Spec`, we'll see if the `Itinerary` still satisfies the `Specification`. If not, the `Routing Service` regenerates the `Itinerary`.

**What changed:** the user said "itinerary" in *both* dialogs — but in the second it is an object they can discuss precisely. "Route specification" is named explicitly instead of re-described each time as attributes and procedures. The awkward "Ugh" in Scenario 1 marks exactly the point where the missing concept (a Specification that an Itinerary can *satisfy*) should have been discovered. Realistically Scenario 1 would be far more verbose, bloated with feature explanations and miscommunication.

**Modeling out loud, three passes at the same sentence:**
1. "If we give the `Routing Service` an origin, destination, and arrival time, it can look up the stops the cargo will have to make and, well… stick them in the database." — *vague and technical*
2. "The origin, destination, and so on… it all feeds into the `Routing Service`, and we get back an `Itinerary` that has everything we need in it." — *more complete, but verbose*
3. "**A `Routing Service` finds an `Itinerary` that satisfies a `Route Specification`.**" — *concise*

Version 3 is not just better prose; it names three objects and one relationship. That sentence *is* the model.

## Key Takeaways
1. Commit the whole team to one model-based language and use it in speech above all — speech is where models are cheapest to test and where the best expressions usually die uncaptured.
2. Treat every awkward phrase as a model defect; experiment with alternative wordings, then refactor the code to match the winner.
3. A change in the UBIQUITOUS LANGUAGE *is* a change to the model — propagate it to diagrams and code.
4. Never split the language between developers and domain experts. Technical and domain jargon are permitted extensions, not rival vocabularies for the same concepts.
5. If sophisticated domain experts can't understand the model, the model is wrong — not the experts.
6. Keep diagrams minimal (3–5 objects, hand-drawn is fine); they anchor discussion, they are not the model. Put the vital detail in code.
7. Judge every document by whether its terms appear in current speech and code; if not, it is either wrong, too big, or unimportant.
8. Use explanatory models freely to teach the domain — but keep them visually distinct from the design model.

## Connects To
- **Ch 1 (Knowledge Crunching)**: "cultivating a language based on the model" is the ingredient this chapter fully develops; language use is what forces model weaknesses into the open.
- **Ch 3 (Model-Driven Design)**: the language must be embedded in the code for any of this to hold.
- **Ch 10 (Supple Design / declarative design)**: eliminating the discrepancy between what code says and what it does.
- **Ch 14 (Maintaining Model Integrity)**: this chapter assumes *one* model in play; Ch 14 handles coexisting models and LANGUAGES via BOUNDED CONTEXT and CONTEXT MAP.
- **Ch 16 (Large-Scale Structure)**: the LANGUAGE is the primary carrier of design aspects that don't appear in code.
- **Extreme Programming**: XP's "let the code speak for itself" is engaged here directly — code is closest to the ground, but names and organization can still mislead.
