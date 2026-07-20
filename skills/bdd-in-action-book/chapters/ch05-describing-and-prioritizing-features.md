# Chapter 5: Describing and Prioritizing Features

## Core Idea
Features deliver capabilities; User Stories are *disposable planning artifacts* for building them. Decompose by business task rather than by imagined solution, and use Real Options + Deliberate Discovery to decide *when* to commit — not too early (you'll lock in ignorance), not too late (the option expires).

## Frameworks Introduced

- **The Four-Term Vocabulary** — the book's deliberate simplification of Agile's terminology mess:
  | Term | Definition | Test |
  |---|---|---|
  | **Capability** | The ability to realize a goal or perform a task, independent of implementation | Prefix with "to be able to" |
  | **Feature** | Software functionality built to support a capability | Could you deploy it alone and still deliver business value? Would it get its own user-manual section, or appear on the software box? |
  | **User Story** | A planning chunk that breaks a feature into deliverable-in-one-iteration pieces | Small enough for one iteration; needn't be independently deployable |
  | **Example** | A concrete illustration used to understand a feature or story | (see ch 6) |
  - On **Epics**: the book explicitly refuses to litigate this. Some teams use "Epic" for what it calls features; others treat an Epic as containing many features. "And this is fine too."

- **Product Feature vs. Release Feature** — a subtle distinction with real consequences for how you organize specs:
  | | Product feature | Release feature |
  |---|---|---|
  | Describes | System behavior in absolute terms | New or modified functionality being released |
  | Analogy | A chapter in the user manual | A bullet in the release notes |
  | Scope | Coherent, well-contained functionality | Smallest slice deliverable in isolation with tangible benefit |
  | Example | "Direct debits" | "Direct debit for Euro accounts", "Direct debit for USD accounts" |
  - **Why it matters**: a product feature *improves over time* as release features land. In Cucumber, **all direct debit scenarios belong in a single feature file**, even though they arrived across several releases. Organize specs by product feature, plan by release feature.
  - Used this way by XSCALE, LeSS, and SAFe.

- **Two Decomposition Strategies** — one safe, one dangerous:
  | | **Business-task decomposition** (recommended) | **Solution-first decomposition** (risky) |
  |---|---|---|
  | How | Break into smaller business processes/tasks ("Renew by credit card", "Pay with MasterCard") | Design the screens/solution, then write stories for each screen |
  | Commits to | Nothing implementation-specific | A particular technical solution, early |
  | Risk | Low | Loses focus on business goals; forecloses better options |
  | Real failure shown | — | Excitement around a PayPal solution caused the team to **forget renewal-by-Frequent-Flyer-points entirely** |

- **Real Options** (Chris Matts, mid-2000s) — three principles:
  1. **Options have value.** The less you know about the optimal solution, the more value in keeping options open. Value is *inversely proportional to knowledge*.
  2. **Options expire.** An option expires when you no longer have time to implement it before the delivery date. Unlike financial options, **you can sometimes push the expiry date back** by making the integration faster.
  3. **Never commit early unless you know why.**
  - **Critical nuance most people get wrong**: the aim is *not* to systematically delay to the last possible moment. "With Real Options, you only delay until you have enough information to act. When you have enough information, you implement your chosen solution **as quickly as possible**."
  - Options have a **price** in software: discussing options up front, adding abstraction layers, making parts configurable.

- **Deliberate Discovery** (Dan North, 2010; developed by Liz Keogh and the London BDD community) — the flip side of Real Options.
  - Core claim: **ignorance is the constraint.** "You know a lot more about the best way to build a particular solution after you've finished building it, but by then it's too late."
  - Real Options keeps options open until you have information; **Deliberate Discovery is how you go get that information faster.**
  - **The scheduling rule this produces**: the natural tendency is to implement the simplest stories first. Instead, **identify the stories with the most uncertainty and tackle those first**, then re-review the remaining stories in light of what you learned.

- **The Planning Cascade** (figure 5.14) — which artifact is produced where:
  | Phase | Activity | Produces | Goes into |
  |---|---|---|---|
  | **Speculate** — Strategic Planning | Impact Mapping, Pirate Canvases | Hypotheses + Epics / Product Backlog items | Product Backlog |
  | **Speculate** — Product Backlog Refinement | Break Epics into features, estimate, order | Features | Individual team backlogs |
  | **Illustrate** | Identify functional + nonfunctional acceptance criteria (scenarios); slice into stories | Scenarios + User Stories | Sprint work |
  | **Formulate** | Turn scenarios into executable specifications | Executable specs | Development work each sprint |
  - Not a rigid process: "Feedback cycles exist at all levels" — an invalidated hypothesis during Backlog Refinement lets teams correct goals and priorities immediately.

## Key Concepts

- **Product Backlog Refinement** (Scrum) — "the act of adding detail, estimates, and order to items in the Product Backlog… an ongoing process in which the Product Owner and the Development Team collaborate."
- **Last responsible moment** — the point past which you no longer have time to talk to stakeholders and understand requirements before the feature is due.
- **Story card** — front: the story in "in order to / as a / I want" form plus priority and estimate (hours or story points). Back: an initial bullet list of acceptance criteria.
- **YAGNI** ("you ain't gonna need it") — build nothing for scale until scale arrives; one of three valid postures on the scalability question.
- **Tags** — the escape hatch for requirements that don't fit a hierarchy (a story serving two features).
- **Cross-functional feature** — a feature like "keep client data safe" that cuts across the main hierarchy, usually owned by a non-business stakeholder (security, compliance, legal, operations).

## Mental Models

- **Think of a User Story as scaffolding, not architecture.** "Once the feature has been implemented, the User Stories can be discarded." End users don't care how you organized the work; future developers want to know what the application *does*, not how you built it.
- **Use the plane-ticket calculation to price flexibility.** A $600 nonrefundable ticket vs. an $800 ticket with a $25 cancellation fee: the option costs $200. If you're likely to travel, that's too much. If there's a 50% chance you can't fly, it's cheap — cancelling costs $225 instead of $600. Do this arithmetic on architectural decisions.
- **Ask "who really wants this?" — often it isn't the user.** "In order to renew my membership more easily / As a Frequent Flyer member" reframed as "In order to reduce lost sales from lapsing memberships / As Flying High sales manager" reveals that **members may not be motivated to renew at all** — which changes the feature from a convenience to an enticement problem.
- **Value-first vs. actor-first framing**: `In order to… / As a… / I want…` keeps beginners focused on business goals. `As a… / I want… / So that…` is equally valid. "Experienced practitioners will be able to produce high-quality and meaningful definitions in both formats." Don't burn hours on the terminology debate.
- **Acceptance criteria on a story card are a starting point, not a contract.** "It's unreasonable to expect the product owner or stakeholders to think of a definitive list… You just want enough information to be able to move forward."
- **The feature/story boundary is context-dependent, not absolute.** "Pay renewal fees with Visa" is a story at an airline. At a FinTech start-up where each card integration is major work, it's a feature you might ship in its own release.

## Worked Example

**Feature descriptions at three altitudes, for the same functionality.**

Flying High has high lapse rates on Frequent Flyer memberships — members must call or mail a paper form to renew. Capability identified: *"Enable members to renew their membership more easily."*

*User-centric framing:*
```
Feature: Online membership renewal
In order to renew my membership more easily     ← capability / goal supported
As a Frequent Flyer member                      ← who benefits
I want to be able to renew my membership online ← what it does
```

*Business-centric framing — the same feature, and arguably the truer one:*
```
Feature: Online membership renewal
In order to reduce lost sales from lapsing memberships  ← the business's goal, not the member's
As Flying High sales manager                            ← who actually wants it
I want members to be able to renew their membership online
```

*Traditional actor-first framing:*
```
Feature: Online membership renewal
As a Frequent Flyer member
I want to be able to renew my membership online
So that I renew my membership more easily
```

The second framing exposes something the first hides: the sales manager is the stakeholder to satisfy, and members may need *enticing*, not just enabling.

**Deferred detail paying off — the feedback conversation that found a missing story.**

The "Email notification of lapsing membership" feature was sliced into three stories:
1. Send notification emails to members whose membership will finish within a month
2. Configure notification message texts
3. Open a renewal page from the notification email

The team builds story 1 and demos it:

> **You:** And this is how the email notification works. When their membership is about to expire, they receive an email that looks like this.
> **John (sales manager):** Looks good. And what about the follow-up email?
> **You:** Is there a follow-up email?
> **John:** Of course. Bill from marketing wants a follow-up email that will include a discount offer of some kind to encourage ex-members to come back.
> **You:** And is the discount always the same?
> **John:** No, Bill needs to be able to change it depending on his latest marketing strategy. We talked about configuring the messages last time.

Two outcomes from one demo:
1. **A completely new story discovered**: "Send follow-up notification emails to ex-members whose membership has just lapsed."
2. **Story 2 was fundamentally misunderstood.** It had been conceived as a template the *development team* would change and ship in the next release. Marketing needs to change it *at any time*. Rewritten:

```
Story: Include a configurable incentive in the follow-up notifications
In order to increase retention rates for our Frequent Flyer program
As a sales manager
I want to be able to include a configurable text describing incentives to rejoin,
such as discount offers or bonus points, in the notification message
```

The book's point: **had the team specified "Configure notification message texts" in detail first, they'd have built a low-value dev-only template that "wouldn't correspond to the stakeholders' expectations at all."** Deferring detail wasn't laziness — it was what let the requirement be correct.

**Real Options applied to a scalability decision.**

A start-up's founders expect small initial volume but "millions by the end of the year." Three postures:

| Option | Cost if traffic stays low | Cost if traffic explodes |
|---|---|---|
| **YAGNI** — ignore scalability, refactor if needed | Zero | Extensive refactoring |
| **Build scalable architecture now** | Wasted effort | Zero rework |
| **Buy the option** — spend a little time up front designing *what would be needed* to scale later | Small upfront design time only | Scaling available at reduced cost |

The third is the Real Options play: you pay a small premium to keep the door open, and you exercise it only when the traffic data tells you to.

**Options expiring** (figure 5.13): you're choosing between solution A (10 days to integrate) and solution B (5 days). You add a layer of code so either can be swapped in. Option A therefore expires **10 days before delivery**; option B expires **5 days before**. If A is being built by another team and it slips past its expiry, A leaves the choice set. But if you can find a way to integrate A faster, you push its expiry date back and buy yourself more time to decide.

## Anti-patterns

- **Debating terminology instead of building**: "many teams still waste long hours debating what terminology they should use or whether a particular requirement should be called a story, a feature, an Epic, or something else entirely."
- **Decomposing a feature into stories based on an imagined screen sequence**: commits to a solution, loses the goal, and silently drops alternatives (the forgotten Frequent-Flyer-points renewal path).
- **Specifying story details too early**: you build the wrong thing, because the fact that would have corrected you arrives later.
- **Procrastinating past the last responsible moment**: no time left to talk to stakeholders before the feature is due.
- **Delaying decisions on principle once you have enough information**: Real Options says act as fast as you can once you know why — deferral is not a virtue in itself.
- **Doing the easy stories first**: comfortable, but leaves your ignorance intact where it's most expensive. Attack the uncertain stories first.
- **Forcing everything into a strict hierarchy**: "providing a secure password when registering" belongs to both "Join the Frequent Flyer program online" and "Keep client data safe." Use tags, keep the parent–child view for the main structure.
- **Treating User Stories as the documentation of what the system does**: they're planning artifacts. Feature descriptions, examples, and automated acceptance criteria are what document behavior.
- **Splitting one product feature's scenarios across feature files by release**: direct-debit-for-Euro and direct-debit-for-USD are separate release features but one product feature — one Cucumber feature file.

## Key Takeaways
1. Test a candidate feature by asking: could you deploy it alone and still deliver business value? If not, it's a User Story.
2. Decompose by business task, never by imagined screens or solutions — solution-first decomposition silently deletes alternatives.
3. Write features from the perspective of whoever actually wants the outcome; that's often the business, not the user, and it changes the design.
4. Keep acceptance criteria on story cards deliberately incomplete — enough to move forward, refined during Illustrate.
5. Organize executable specs by **product** feature (one feature file per coherent capability) while planning by **release** feature.
6. Price your options explicitly: what does the flexibility cost, and what's the probability you'll need it?
7. Delay commitment only until you have enough information — then move immediately. Track when each option expires, and push expiry dates back where you can.
8. Sequence stories by uncertainty, not by ease. Your ignorance is the project's biggest risk.
9. Discard User Stories once the feature ships; keep the feature description, examples, and automated criteria.

## Connects To
- **Ch 4**: Impact Mapping and Pirate Canvases produce the Epics this chapter refines.
- **Ch 6**: Example Mapping and Feature Mapping — the Illustrate-phase techniques that produce scenarios.
- **Ch 7**: turning those scenarios into executable specifications (Formulate).
- **Ch 16**: tags and living documentation — how cross-cutting relationships are surfaced in reports.
- **Real Options (Chris Matts & Olav Maassen)**, **Deliberate Discovery (Dan North, Liz Keogh)**, **Scrum Guide**, **XSCALE / LeSS / SAFe**: the external sources behind this chapter's models.
