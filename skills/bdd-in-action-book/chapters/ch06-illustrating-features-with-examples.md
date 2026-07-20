# Chapter 6: Illustrating Features with Examples

## Core Idea
Four facilitation techniques — tables, Example Mapping, Feature Mapping, and OOPSI — that turn the vague instruction "have a conversation about examples" into a bounded, productive workshop. Each probes a different shape of requirement; pick by the *shape of the uncertainty*, not by habit.

## Frameworks Introduced

- **The Three Amigos** — a developer, a tester, and a business analyst or product owner meet to discuss a feature and draw examples *before* implementation starts.
  - Requirement: all three must be reasonably familiar with the problem space.
  - Why the specific mix works — each role contributes a distinct failure-detection capability:
    | Role | Contributes |
    |---|---|
    | **Tester** | Attention to detail, focus on validation — proposes obscure edge cases and scenarios others missed |
    | **Developer** | Technical considerations and feasibility; *and* progressively builds deep business domain understanding |
    | **BA / Product Owner** | Judges relevance and relative value of the different scenarios |

- **Kolb's Experiential Learning Cycle applied to BDD** (David Kolb, 1984):
  1. **Experience** — concrete real-world situations (the examples)
  2. **Reflection** — observe and think about the experience
  3. **Conceptualize** — generalize into a mental model of the problem space
  4. **Test** — check the model against further real-world experiences
  - BDD's version: discuss concrete examples → reflect to build shared understanding → look for additional examples to confirm or extend it.

- **The Jigsaw Model of asking for examples**: think of the problem space as a jigsaw puzzle. Asking for an example is picking up a piece and placing it where you think it goes.
  - **If it fits** → you've confirmed your understanding and expanded your mental model.
  - **If it doesn't** → you've flushed out an incorrect assumption and can move forward on solid ground.
  - Either outcome is a win. This is why "wrong" examples are as valuable as right ones.

- **Example Mapping** (Matt Wynne) — breadth-first, four card colors:
  | Card | Represents | Color |
  |---|---|---|
  | User Story | The feature or story under discussion (top of board) | **Yellow** |
  | Business rule | Constraints or known acceptance criteria | **Blue** |
  | Example | Concrete examples *and counterexamples* of the rule | **Green** |
  | Question | Uncertainty that can't be resolved in the session | **Pink** |
  - **The "Friends episode notation"** (Daniel Terhorst-North): name examples "The one where…". The original was *"the one where Joey gets his head stuck in a turkey."*
  - **Facilitation rules**: timebox to **25–30 minutes**; have a dedicated facilitator (it's easy to get caught in conversation and forget to record); at the end of the timebox, **vote** on whether the team understands enough to start work or needs another session.
  - **The pink card discipline**: "If you come across something you don't know, don't get bogged down discussing it; simply note down the question and move on!"
  - Probing questions: *"What if…?"*, *"Is this always the case?"*, *"Are there any examples where this rule does not apply?"*
  - Side benefit: newly discovered rules that fall outside the story clarify scope and **suggest where to slice**.

- **Feature Mapping** — like Example Mapping, but examples decompose into steps and consequences. Adds two card types:
  | Card | Represents | Color |
  |---|---|---|
  | **Step** | Preconditions, input values, user actions, or points in a workflow | Yellow |
  | **Consequence** | Expected outcome(s); marked with an arrow at the top | Mauve |
  - **Every example leads to at least one consequence** — and may lead to several.
  - Two entry points: (a) list known business rules then find examples for each (Example-Mapping style), or (b) **start from one concrete end-to-end example** and use its steps to discover rules. Option (b) works better for user journeys — it keeps people on the big picture.
  - **The step-interrogation questions**: "What else could happen here? Why is this detail significant? What other outcomes might we expect?"
  - Notation: an **arrow in a row** means "the steps here are the same as the row above." **Underlined blue rule cards** title a group of related rules.
  - Works at any altitude: front-end (how users interact), back-end (how data flows, what inputs to cater to), or high-level epics where each card hides rules to explore later.
  - **Feature Maps convert directly into readable acceptance criteria** — the book's recommendation for teams new to BDD or entering a complex domain.

- **OOPSI** (Jenny Martin & Pete Buckney) — **O**utcome, **O**utputs, **P**rocess, **S**cenarios, **I**nputs. The mirror image of Feature Mapping: start from the highest-value outcomes and work *backward*.
  | Step | What it captures |
  |---|---|
  | **Outcome** | The problem to solve — usually the feature or User Story |
  | **Outputs** | Concrete things the feature produces — *including what happens when things go wrong* |
  | **Process** | The steps that lead to those outputs (start with the most important output) |
  | **Scenarios** | Business rules/constraints *and* edge cases — the flows the simple process left out |
  | **Inputs** | Concrete example data illustrating the scenarios, usually as tables |

## Key Concepts

- **Illustrate phase** — where these techniques live; the second half of requirements discovery, after Speculate.
- **Consequence** — Feature Mapping's term for an expected outcome at the end of a flow.
- **Counterexample** — an example where the rule does *not* apply; the primary tool for finding hidden rules.
- **Breadth-first discovery** — cover many rules superficially rather than a few exhaustively; details come in Formulate.

## Mental Models

- **Executable specifications are an *output* of conversations, not an input.** The book explicitly warns against the BA writing scenarios alone and handing them to developers: "Experienced practitioners generally don't recommend this approach, as it fails to build a shared understanding as effectively."
- **Don't write Gherkin in the discovery session.** Writing Given/When/Then live "can be time-consuming and distract team members from the bigger picture." Use breadth-first mapping in Illustrate; leave Given/When/Then to a smaller group in Formulate. (Exception: mature teams fluent in both Gherkin and the domain can draft together at a computer.)
- **Treat stated acceptance criteria as a *solution*, not the requirement.** The password story's rules turned out to be one possible implementation of "ensure users have strong passwords." Working examples revealed the real requirement was less clear-cut than the rules implied.
- **Business rules obvious to the business are invisible to the team.** "Flying High flights have a flight number that starts with FH" was news to everyone. Expect this every session.
- **Pick your technique by requirement shape:**
  | Requirement shape | Technique |
  |---|---|
  | Clear inputs → outputs, data transformation | **Tables** |
  | Many business rules to enumerate quickly | **Example Mapping** |
  | Workflows, user journeys, alternate flows | **Feature Mapping** |
  | Value defined by what the system produces | **OOPSI** |
- **Large workshops trade cost for shared understanding.** Whole-team early workshops build alignment and high-quality examples but "are hard to organize and are expensive in terms of people's hours." Backlog Refinement/Sprint Planning gives scope overview but often lacks time for depth.

## Worked Example

**The secure password conversation — where the acceptance criteria dissolved.**

The story:
```
Story: Providing a secure password when registering for the Frequent Flyer program
In order to avoid hackers compromising member accounts
As the systems administrator
I want new members to provide a secure password when they register
```

Bianca (BA) arrives with four acceptance criteria: at least eight characters; at least one digit; at least one punctuation mark; a helpful error message. She probes each with Sid, the systems administrator:

> **Bianca:** A password should be rejected if it has less than eight characters?
> **Sid:** Yes — at least eight, to make it harder for hacking algorithms to guess.
> **Bianca:** So "secret" would be rejected — only six characters?
> **Sid:** Correct.
> **Bianca:** What about "password"? Acceptable?
> **Sid:** No, we also said at least one digit.
> **Bianca:** So "password1" would be OK?
> **Sid:** No — that's still really easy to hack. It's a dictionary word; the digit at the end wouldn't slow a hacking algorithm down for long.
> **Bianca:** OK, so "password1!"? It has a number, an exclamation mark, and more than eight characters.
> **Sid:** No. Using dictionary words like "password" is really bad. Even with numbers and punctuation, a hacking algorithm would solve that instantaneously.

**New rule discovered: no dictionary words.** Bianca pushes on:

> **Bianca:** How about "SeagullHedgehog"?
> **Sid:** That would be better.
> **Bianca:** But there are no numbers or punctuation in it.
> **Sid:** Sure, that would make it better. But it's still a random sequence of words, which would be pretty hard to crack.
> **Bianca:** "SeagullHedgehogCatapult"?
> **Sid:** Pretty much uncrackable.

Note that "SeagullHedgehog" **violates two of the four stated criteria and is still acceptable**. Bianca continues:

> **Bianca:** How about "aBcdEfg1"?
> **Sid:** Pretty easy for a machine to crack — alphabetically ordered letters and a number. Sequences are easy, and one number at the end doesn't add much.
> **Bianca:** What about "qwertY12"?
> **Sid:** That's just a sequence of keys on the keyboard. Most hacking algorithms know that trick.
> **Bianca:** OK, "dJeZDip1"?
> **Sid:** A bit short, but OK.

Then the developer notices the real shape of the problem:

> **David:** Sid, rather than just saying if a password is secure or not, you seem to be **grading** them by how hard they are to hack — is that intentional?
> **Sid:** I wasn't thinking of it like that, but yes. The whole point of a secure password is that it doesn't get hacked… we need passwords to be of at least **medium strength**.

Bianca's conclusion:

> **Bianca:** I think we've been focusing on the detailed rules too much. The rules are less clear-cut than we thought, and they focus on one particular *solution*. The real value comes from ensuring users have a strong password, not enforcing a particular set of rules.

Rewritten acceptance criteria:
- The password should be at least of medium strength to be accepted.
- I should be informed of the strength of my proposed password.
- If the password is too weak, I should be informed why.

And the Real Options move — Bianca refuses to commit:

> **Bianca:** Let's keep our options open; we don't know enough to commit to a particular solution. We'll find a good existing library and experiment, but integrate it so we can easily switch to another library or our own custom solution later.

The resulting example table (which becomes the acceptance criteria basis):

| Password | Strength | Acceptable |
|---|---|---|
| secret | Weak | No |
| password | Weak | No |
| password1 | Weak | No |
| aBcdEfg1 | Weak | No |
| qwertY12 | Weak | No |
| dJeZDip1 | Medium | Yes |
| SeagullHedgehog | Strong | Yes |
| SeagullHedgehogCatapult | Very strong | Yes |

**Progressive table refinement — the eligible-flights rule.**

Story: new Frequent Flyer members get credit for flights completed in the past 90 days. Bianca starts with two rows:

| Flight Date | Eligible |
|---|---|
| 60 days ago | Yes |
| 100 days ago | No |

*(Note added below the table: the 90-day period starts at midnight — captured so the knowledge isn't lost.)*

> **Terri:** Are *all* flights in the past 90 days eligible? Are there never any exceptions?
> **Fred:** Sure, plenty. Only Flying High flights are eligible, not partner or codeshare flights.
> **David:** And how do we distinguish them?
> **Fred:** Flying High flights have a flight number that starts with "FH."

A new column is required to express the new rule:

| Flight Number | Flight Date | Eligible | Reason |
|---|---|---|---|
| FH-99 | 60 days ago | Yes | |
| FH-87 | 100 days ago | No | Too old |
| OH-101 | 60 days ago | No | Not a Flying High flight |

> **Terri:** OK, let's focus on Flying High flights. Are there any that aren't eligible even in the correct time period?
> **Fred:** Well, if the flight was cancelled, it wouldn't count.
> **Bianca:** What about flights booked but not yet flown?
> **Fred:** No, you need to have *completed* a flight for it to count.

Another column, two more rows:

| Flight Number | Flight Date | Status | Eligible | Reason |
|---|---|---|---|---|
| FH-99 | 60 days ago | COMPLETED | Yes | |
| FH-87 | 100 days ago | COMPLETED | No | Too old |
| OH-101 | 60 days ago | COMPLETED | No | Not a Flying High flight |
| FH-99 | 60 days ago | CANCELLED | No | Must be completed |
| FH-99 | In 5 days time | CONFIRMED | No | Must have taken place |

**Pattern to steal**: each newly discovered rule adds a *column*; each example adds a *row*; the `Reason` column keeps the rule visible next to the data.

**An Example Map, built live.**

Yellow card (top): *Earning Frequent Flyer points.* Product owner's pre-written criteria become blue rule cards:
- Flights within Europe earn 100 points.
- Flights outside Europe earn 1 point per 10 km flown.
- Business flights earn an extra 50%.

Green example cards, in Friends notation:
- "The one where Tara flies economy from Paris to Berlin" → 100 points
- "The one where Tara flies economy from London to New York"
- "The one where Betty flies business class from Paris to Hong Kong" (probing whether business always means +50%)

Questioning surfaces a **rule the product owner had forgotten**: Silver Frequent Flyer members earn 25% more points → new blue card + green example. The team decides Frequent Flyer *status* belongs in a separate story and scopes this one to regular customers — **the map sliced the story for them.**

Pink cards (unresolved):
- Does "flights within Europe" mean the EU only, or also EEA countries like Norway, or something else?
- Members can buy flights with points — should those flights *earn* points? (Product owner must check with marketing.)

**A Feature Map for "modify an existing booking."**

The product owner opens with a concrete story — deliberately non-exhaustive, to provoke questions:

> Tara has booked a flight from London to New York leaving Monday. Something has come up and she has to push her trip back a couple of days. She views her booking online and modifies it to fly the following Wednesday. The ticket is in the same price category so there is no extra charge.

That example breaks into four **steps** (yellow) leading to one **consequence** (mauve): *Tara's booking is updated to the new date at no additional cost.*

Then the team interrogates each step:

| Variation found | New rule | Consequence |
|---|---|---|
| What if the new flight is more expensive? | Traveler pays the price difference | Booking updated, traveler charged difference |
| What if it's cheaper? | — | Booking updated **+ refund issued** (a *second* consequence) |
| What if no seats are available and Tara isn't a member? | Refund offered | Refund issued |
| What if no seats are available and Fiona *is* a member? | Refund **or** equivalent Frequent Flyer points credit | Choice offered |

Note the second variation demonstrates **one example, two consequences**, and the last two introduce a **new persona (Fiona)** to make the member/non-member distinction concrete. The completed map groups these under two underlined blue headers: *traveler successfully modifies booking* and *no seats available → refund*.

**An OOPSI model, worked backward.**

*Outcome:* Frequent Flyer members can book flights with their points.

*Outputs* (note the failure output sits alongside the success outputs):
- The new ticket should be issued.
- A "ticket purchased" message is published.
- A confirmation email is sent to the frequent flyer.
- The frequent flyer's point balance is updated.
- If the frequent flyer doesn't have enough points, an appropriate error message is displayed.

*Process:* the steps leading to those outputs.

*Scenarios:* what the simple process omitted — e.g. only a limited number of seats per flight can be bought with points, so seat availability must be checked. This was *implicit* in the process diagram; writing it as a scenario forces the team to decide what happens when it fails.

*Inputs* — the business rule "flights can be purchased at 10 Frequent Flyer points per dollar", made concrete:

| Point Balance | Flight | Cost | Available FF Seats | Purchase successful | Cost in Points | New Point Balance |
|---|---|---|---|---|---|---|
| 5,000 | London to Paris | $450 | Yes | Yes | 4,500 | 500 |
| 5,000 | London to Athens | $650 | Yes | No | — | 5,000 |
| 5,000 | London to Paris | $450 | No | No | — | 5,000 |

Row 2 is the insufficient-points counterexample; row 3 is the no-eligible-seats counterexample. Both leave the balance untouched — an outcome worth pinning down explicitly.

## Anti-patterns

- **The BA writing scenarios alone and passing them to developers**: fails to build shared understanding; specs become an input rather than an output of conversation.
- **Writing Given/When/Then during the discovery workshop**: time-consuming, distracts from the bigger picture.
- **Getting bogged down on an unanswerable question**: write a pink card and move on.
- **Treating the product owner's stated acceptance criteria as the requirement**: they're often one solution among several, as the password rules proved.
- **Running Example Mapping without a facilitator**: teams get absorbed in conversation and forget to record rules and examples.
- **Untimeboxed sessions**: they "drag on without seeming to go anywhere." 25–30 minutes, then vote.
- **Exhaustive opening stories in Feature Mapping**: the story should be *deliberately* incomplete — its job is to provoke "what if?" questions.
- **Enumerating only happy-path outputs in OOPSI**: the error case ("not enough points") is a first-class output.
- **Assuming rules that seem obvious to the business are known to the team**: the "FH" prefix rule was invisible until a tester asked about exceptions.

## Key Takeaways
1. Get a developer, tester, and BA/PO in the room before implementation — each catches a class of problem the others don't.
2. Ask for an example specifically to *test an assumption*; a rejected example is as valuable as an accepted one.
3. When examples keep contradicting your rules, suspect the rules encode one solution rather than the real requirement — and reframe (rules → "medium strength").
4. Build tables incrementally: a new rule adds a column, a new case adds a row, and a `Reason` column keeps the rule attached to the data.
5. Name examples "The one where…" — it forces specificity and makes the map skimmable.
6. Timebox Example Mapping to 25–30 minutes, facilitate it, and vote on readiness at the end.
7. Write every unresolved uncertainty on a pink card immediately rather than debating it.
8. Use Feature Mapping when flows and journeys matter; interrogate every step with "what else could happen here?"; expect examples with multiple consequences.
9. Use OOPSI when the feature is best understood by what it produces — and list failure outputs alongside success outputs.
10. Let newly discovered out-of-scope rules tell you where to slice the story.

## Connects To
- **Ch 3**: the first, brief introduction of Example Mapping in the whirlwind tour.
- **Ch 5**: Real Options and Deliberate Discovery — visible in Bianca's refusal to commit to a password-strength library.
- **Ch 7**: turning these maps and tables into Given/When/Then executable specifications (Formulate); Feature Maps convert especially cleanly.
- **Ch 9**: writing solid acceptance tests from these criteria.
- **Kolb's Experiential Learning (1984)**, **Example Mapping (Matt Wynne)**, **Friends notation (Daniel Terhorst-North)**, **OOPSI (Jenny Martin & Pete Buckney)**, **zxcvbn password strength (Dan Wheeler)**: external sources referenced.
