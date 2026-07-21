# Chapter 13: Refactoring Toward Deeper Insight

## Core Idea
Part III's expanded refactoring, summarized. Three things to focus on:
1. **Live in the domain.**
2. **Keep looking at things a different way.**
3. **Maintain an unbroken dialog with domain experts.**

## Frameworks Introduced

- **Initiation — the four triggers for a deep refactoring** (note that only the first matches conventional refactoring):
  1. A problem in the code — complexity or awkwardness — where instead of applying a standard transformation, the developers **sense the root of the problem is in the domain model**: a concept is missing, or a relationship is wrong.
  2. **The code looks tidy, but the language of the model seems disconnected from the domain experts.**
  3. New requirements are not fitting in naturally.
  4. Learning — a developer who has gained deeper understanding sees an opportunity for a more lucid or useful model.
  - **"Seeing the trouble spot is often the hardest and most uncertain part."** After that, developers can systematically seek elements of a new model: brainstorm with colleagues and domain experts, draw on analysis patterns or design patterns.

- **Exploration Teams** — the working format for a model search that's bigger than a few hours:
  - **Who**: the initiators pick a couple of other developers who are good at thinking through that kind of problem, who know that area of the domain, or who have strong modeling skills. **If there are subtleties, make sure a domain expert is involved.** Four or five people total.
  - **How**: go to a conference room or coffee shop and brainstorm for **half an hour to an hour and a half**. Sketch UML diagrams; walk through scenarios using the objects. **Make sure the subject matter expert understands the model and finds it useful.** When happy, go code it — or decide to mull it over for a few days and work on something else, reconvening later with more confidence.
  - **Three keys to keeping it productive:**
    1. **Self-determination** — a small team assembled on the fly, operating for a few days, then disbanding. *"There is no need for long-term, elaborate organizational structures."*
    2. **Scope and sleep** — two or three short meetings spaced over a few days should produce a design worth trying. **"Dragging it out doesn't help. If you get stuck, you may be taking on too much at once. Pick a smaller aspect of the design and focus on that."**
    3. **Exercising the UBIQUITOUS LANGUAGE** — involving other team members, particularly the subject matter expert, creates an opportunity to exercise and refine the LANGUAGE. **"The end result of the effort is a refinement of that LANGUAGE which the original developer(s) will take back and formalize in code."**

- **Prior Art — four sources to feed the crunching**, in ascending specificity:
  1. **Books and knowledge about the domain itself.** Practitioners may not have built a model suitable for running software, but they've often organized the concepts and found useful abstractions. This "leads to richer, quicker results that also will probably seem more familiar to domain experts."
  2. **Analysis patterns** — like reading about the domain, but geared to software development and based directly on implementation experience in your domain. They give subtle concepts and help avoid mistakes, **but "they don't give you a cookbook recipe. They feed the knowledge-crunching process."**
  3. **Design patterns** — employable in the domain layer when they fit *both* an implementation need and the model concept.
  4. **Established formalisms** — arithmetic, predicate logic. "When a common formalism fits some part of a domain, you can factor that part out and adapt the rules of the formal system. This provides very tight and readily understood models."
  - The crucial property: the brainstorming process "has a great capacity to absorb ideas from any source, combine them with local knowledge, and continue crunching."

- **A Design for Developers** — what supple design does, restated compactly:
  - Communicates its intent.
  - Makes it easy to anticipate the effect of running code — **and therefore easy to anticipate the consequences of changing it.**
  - Limits mental overload, primarily by reducing dependencies and side effects.
  - Is based on a deep model that is **fine-grained only where most critical to the users** — "flexibility where change is most common, and simplicity elsewhere."
  - Refactoring toward deeper insight **both leads to and benefits from** supple design.

- **Timing — when to refactor:**
  > **If you wait until you can make a complete justification for a change, you've waited too long.** Your project is already incurring heavy costs, and the postponed changes will be harder to make because the target code will have been more elaborated and more embedded in other code.
  - The asymmetry that causes the delay: teams see the risk of changing code and the cost of developer time; **what's harder to see is the risk of keeping an awkward design and the cost of working around it.**
  - **On demanding justification**: "Although this seems reasonable, it makes an already difficult thing impossibly difficult, and tends to squelch refactoring (or drive it underground). Software development is not such a predictable process that the benefits of a change or the costs of not making a change can be accurately calculated."
  - **Refactor when:**
    1. The design does not express the team's current understanding of the domain;
    2. Important concepts are implicit in the design (**and you see a way to make them explicit**); or
    3. You see an opportunity to make some important part of the design suppler.
  - **The limits on that aggression:**
    - Don't refactor the day before a release.
    - Don't introduce "supple designs" that are just demonstrations of technical virtuosity but fail to cut to the core of the domain.
    - Don't introduce a "deeper model" that **you couldn't convince a domain expert to use**, no matter how elegant it seems.
    - "Don't be absolute about things, but **push beyond the comfort zone in the direction of favoring refactoring.**"

- **Crisis as Opportunity** — the punctuated-equilibrium model of design change:
  - For a century after Darwin, the standard model of evolution was gradual, steady change. In the 1970s it was displaced by **punctuated equilibrium**: long periods of gradual change or stability interrupted by relatively short bursts of rapid change, then a new equilibrium. Software development has intentional direction that evolution lacks, "although it may not be evident on some projects" — but it follows the same rhythm.
  - "Classical descriptions of refactoring sound very steady. Refactoring toward deeper insight usually isn't."
  - **The breakthrough disguises itself as a crisis**: "Suddenly there is some obvious inadequacy in the model. There is a gaping hole in what it can express, or some critical area where it is opaque. Maybe it makes statements that are just wrong."
  - **The reframe**: *"This means the team has reached a new level of understanding. From their now-elevated viewpoint, the old model looks poor. From that viewpoint, they can conceive a far better one."*

## Key Concepts
- **Exploration team** — an ad-hoc 4–5 person group formed to search for a model, disbanded after a few days.
- **Prior art** — domain literature, analysis patterns, design patterns, formalisms.
- **Punctuated equilibrium** — long stability interrupted by short bursts of rapid change; the actual rhythm of model refinement.
- **Supple design** — see Ch 10; here restated as a design *for developers*.

## Mental Models
- **Treat "the code is tidy but the language feels off" as a refactoring trigger.** This is the departure from conventional refactoring practice that most teams miss.
- **Scope a modeling problem to fit two or three short meetings.** Getting stuck means the scope is too big, not that the problem is hard.
- **Read a crisis of model inadequacy as evidence you just got smarter**, not as evidence you were wrong before.
- **Never demand ROI calculations for a refactoring** — the calculation is not available, and requiring it drives refactoring underground.
- **Use the domain expert as the veto on elegance.** A model they wouldn't use isn't deeper, however beautiful.

## Anti-patterns
- **Waiting for a complete justification** — by then the cost is already incurred and the change is harder.
- **Requiring developers to justify each refactoring decision** — squelches it or drives it underground.
- **Refactoring the day before a release.**
- **Technical virtuosity mistaken for suppleness** — a "supple design" that doesn't cut to the core of the domain.
- **Elegance the experts won't adopt** — a "deep model" you couldn't convince a domain expert to use.
- **Dragging out an exploration** — a sign the scope is too large.

## Key Takeaways
1. Live in the domain, keep re-viewing it, and never break the dialog with experts — these are the preconditions for everything else in Part III.
2. Let disconnection between the model's language and the experts' language trigger refactoring even when the code looks fine.
3. Form small, self-organizing exploration teams for a few days, always including a domain expert when subtleties are involved.
4. Timebox exploration to two or three short meetings, sleeping between them; shrink scope rather than extending time.
5. Treat the exploration's real output as a refined UBIQUITOUS LANGUAGE, which then gets formalized in code.
6. Feed the process with domain literature, analysis patterns, design patterns, and formalisms — none of which are recipes.
7. Refactor when the design lags your understanding, when concepts are implicit and you see how to surface them, or when suppleness is within reach — and refactor before you can prove you should.
8. Expect punctuated equilibrium; the crisis where the model suddenly looks wrong is the moment you can conceive a far better one.

## Connects To
- **Ch 8 (Breakthrough)**: the punctuated-equilibrium rhythm and the crisis-as-opportunity reframe.
- **Ch 9 (Making Implicit Concepts Explicit)**: the "important concepts are implicit" refactoring trigger; the dialogs throughout Part III are exploration teams in miniature.
- **Ch 10 (Supple Design)**: "a design for developers"; "draw on established formalisms."
- **Ch 11 / Ch 12 (Analysis Patterns / Design Patterns)**: prior art that feeds knowledge crunching.
- **Ch 2 (Ubiquitous Language)**: the exploration team's real deliverable.
- **Part IV (Strategic Design)**: what to do when the model and system are too large for this process alone.
