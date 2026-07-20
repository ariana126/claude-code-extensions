# Chapter 4: Speculate — From Business Goals to Prioritized Features

## Core Idea
Treat every feature as a **bet**, not a requirement: express it as a falsifiable hypothesis tied to a metric, derive it from a measurable business goal via Impact Mapping or Pirate Canvases, and be willing to abandon it when the metric says no.

## Frameworks Introduced

- **The Value Hierarchy** (figure 4.3) — everything you build must trace upward:
  | Level | Definition | Flying High example |
  |---|---|---|
  | **Vision** | Short statement giving high-level guiding direction | "Build a loyal base of customers who actively prefer to fly with us" |
  | **Business goal** | Executive-level; increases revenue, protects revenue, or reduces costs | "Earn more ticket sales revenue through repeat business from Frequent Flyer members" |
  | **Capability** | Ability to achieve a goal, *regardless of implementation* | "To be able to cumulate benefits when they fly with us" |
  | **Feature** | Deliverable software functionality that provides a capability | "Book flights online using Frequent Flyer points" |
  | **User Story** | A slice of a feature, deliverable in one go | (see ch 5) |
  - **Liz Keogh's capability test**: if you can prefix it with *"to be able to"*, it's a capability. Capabilities don't imply an implementation and needn't even be software — "the ability to book a flight" works online or over the phone.

- **Hypothesis-Driven Development** (Jeffery L. Taylor, 2011) — the template:
  ```
  We believe <some capability>
  will result in <some outcome>.
  We will know this to be true when <some measurable result is observed>.
  ```
  - When to use: for every proposed feature, in the Speculate phase.
  - How: state belief → predicted outcome → the metric that would falsify it. Then find the *simplest* way to prove or disprove it. Collect the metric in the Validate phase; feed it back into the next Speculate phase (figure 4.2).
  - Example: "We believe that if we show products related to a customer's previous purchases on the home page, we will increase engagement and sales. We will know this to be true when we see a 5% increase in sales of related products." — testable cheaply by just showing other books from authors the customer already bought.
  - Outcomes: continue developing, adjust with another experiment, or **abandon the feature entirely**.

- **Moore's Vision Statement Template** (Geoffrey A. Moore, *Crossing the Chasm*):
  ```
  FOR         <target customer>
  WHO         <needs something>
  THE         <product name> IS A <product category>
  THAT        <key benefit, compelling reason to buy>
  UNLIKE      <primary competitive alternative>
  OUR PRODUCT <statement of primary differentiation>
  ```
  - Technique: **think of it as designing a product flyer**. What are its three or four principal selling points? For large teams, split into cross-functional groups, compare results, refine until everyone agrees.

- **SMART business goals**: Specific, Measurable, Achievable, Relevant, Time-bound.
  - Measurable = quantity + time. "Increase sales by 200% in six months" is a wholly different proposition from "5% over the next year" — and the number tells you whether it's achievable at all.
  - **Relevance is the most important attribute**: a goal is relevant if it makes a positive contribution in the *current* context within the specified timeframe and aligns with organizational strategy.

- **The Four Categories of Business Goal** — every commercial goal reduces to one of:
  1. **Increasing revenue** ("Increase ticket sales revenue by 5%")
  2. **Reducing costs** ("Reduce hotline costs by enabling online point redemption")
  3. **Protecting revenue** ("Avoid losing existing customers to the rival Hot Shots program")
  4. **Avoiding future costs** (compliance reports that dodge next year's fines — no direct value, but avoids penalties)
  - Nonprofit/government variant: **Improving service**, **Reducing costs**, **Avoiding future costs**.

- **Popping the "Why Stack"** — repeatedly ask *why* until you reach a viable business goal. Rule of thumb: **five why-style questions** usually suffice.
  - When to use: any time a stakeholder arrives with a feature request rather than a problem.
  - Why it matters (two reasons, the second more important):
    1. Requesters aren't versed in the delivery technology, UX, or cost trade-offs — the team has a professional responsibility to propose the best solution, and can't without knowing the goal.
    2. **If you don't know why a feature is needed, you can't tell whether it's still relevant when circumstances change.** A requirement expressed as a detailed technical solution is "embedded in a fabric of assumptions" — some will be wrong, and you won't know which.

- **Impact Mapping** (Gojko Adzic) — five questions building a mind map:
  | Question | Asks |
  |---|---|
  | **Pain point** | Why are we doing this? What problem, and how can we measure it? |
  | **Goal** | What are we going to do about it? Improve what, by how much? |
  | **Actor** | Who interacts with the system, and whose behavior could help *or hinder* our goals? |
  | **Impact** | How can we help, encourage, or empower these actors? What behavior change do we want? |
  | **Deliverables** | What features might support that behavior change? |
  - Key discipline: **actors include anyone who could prevent the goal** — regulators, security, sysadmins, people with veto power.
  - Impact Maps are **not plans** — they're iterative living documents that surface assumptions and let you attach validation metrics to each.

- **Reverse Impact Mapping** — for when you already have a backlog and competing stakeholders each certain "their" feature comes first.
  - How: get stakeholders together, put the requested features on a whiteboard, identify who they benefit and how, then work *backward* to the underlying business goals.
  - Result: a graph showing which features map to which goals — an objective basis for prioritization.

- **Pirate Metrics — AARRR** (Dave McClure, 2007). Each stage is a potential **bottleneck**; optimize only one at a time.
  | Metric | Question | Frequent Flyer measure |
  |---|---|---|
  | **Acquisition** | How do we pull actors into our ecosystem? | Visitors to the Frequent Flyer website |
  | **Activation** | How do we get them to engage / see value? | Users who sign up for the Frequent Flyer card |
  | **Retention** | How do we get them coming back? | Members returning to check special deals |
  | **Referral** | How do they bring others in? | Social likes/shares, positive reviews |
  | **Return** | What tangible benefit do we get? | Ticket sales from Frequent Flyer members |
  - Diagnostic value: if users can't find the site → Acquisition bottleneck (marketing helps). If they arrive but see no value → Activation bottleneck (**more marketing spend is waste**). If they register but never return → Retention bottleneck.

- **Pirate Canvas** (Peter Merel) — Pirate Metrics + Impact Mapping + Goldratt's Theory of Constraints, run breadth-first.
  - **Top half**: for each of the five metrics, ask *"What sucks?"* and use five whys to reach root causes; attach a measure to each.
  - **Bottom half**: convert each pain point into Why (measurable goal) → Who (actor) → How (behavior change) → What (deliverable). Discuss many candidates, **keep only the most valuable** — a forest of deliverables defeats a breadth-first tool.
  - Output: the **Epic Landscape** — a broad picture of the capabilities to deliver, framed by the bottlenecks they remove.
  - **Ecosystem Thinking**: consider all actors, not just users. A cafe needs coffee lovers *and* suppliers *and* baristas; a bank needs customers *and* investors *and* regulators. Deliverables need not be software at all.

## Key Concepts

- **Speculate phase** — named for the fact that the value of any new feature is not guaranteed; it is a bet.
- **Strategic Planning** — transforming business opportunities/challenges into a prioritized collection of deliverable features; happens repeatedly, not once.
- **Product Backlog Refinement** — where high-level features are refined and prioritized for teams to pick up.
- **Epic Landscape** — breadth-first vision of the epics to deliver, in the context of the business problems being solved.
- **Vanity metric** — a measure that looks like progress but doesn't track the thing you care about (site visits vs. community sign-ups).
- **Riskiest assumption** — the belief whose failure would most invalidate the plan; the one to test first.
- **Business agility** (Agile Business Consortium) — adapt quickly to market change, respond rapidly to customer demands, lead change cost-effectively without compromising quality, continuously stay at competitive advantage.

## Mental Models

- **Think of a feature as a wager, not a requirement.** "We are wagering development time and effort, in the hope that the feature will be worth building."
- **The key to better outcomes is faster learning, not faster coding.** "Smaller feedback cycles are the lifeblood of agility, both at a team and at an organizational level."
- **Use the power drill analogy for missing context.** Asked to buy a drill, you can't succeed without knowing the job — assembling a bed needs a cordless screwdriver; brick garage shelves need a hammer drill, masonry bits, anchors, and cordless if there's no outlet. Same request, opposite answers.
- **Detailed planning has a ~3-month horizon.** Beyond that, detailed specs just buy you rework. Build deep business context instead so you can react.
- **Patton's rule for objective-driven management**: "I never tell people how to do things. I tell them what to do but not how. If you give people responsibility, they will surprise you with their ingenuity and reliability."
- **Ask the broader question to get broader thinking.** Carrie chose "What sucks about business travel?" over "What sucks about business travel *with Flying High*?" — broader questions surface innovative, differentiating solutions.
- **Users' wants may not touch your business goal at all.** A Frequent Flyer member has no reason to want Flying High's ticket sales to rise. Design features that *change behavior* toward the goal, not features that merely please.
- **Expect individually negative impacts inside a net-positive project.** Extra mortgage-application steps annoy both banker and client, but reduce bad-loan risk enough to be worth it. Be aware of these and minimize them.

## Worked Example

**Popping the why stack — Bianca and Sam, five questions deep.**

Sam (sales manager) arrives with a request: *"We need to integrate our Frequent Flyer with an affiliate program with major credit card vendors."*

> **Bianca:** Sure. Can you walk me through this feature? Why is this something our users or stakeholders would value?
> **Sam:** We've made a deal with a credit card company and propose a special Flying High credit card to our members, and they earn points when they spend money. We just need to make sure the points get credited to their account.
> **Bianca:** Can you spell out for me how this will benefit our users or stakeholders?
> **Sam:** Well, our members will appreciate that they get benefits not just when they fly, but also when they shop.
> **Bianca:** So, if I understand correctly, we want to increase the number of Frequent Flyer members by giving them rewards and privileges, and this will hopefully increase the sale of tickets?
> **Sam:** *Not exactly.* We sell Frequent Flyer points **in bulk to the banks** that issue the credit cards. The banks want people to spend money with their cards, so they can earn a commission. Card holders also get benefits like extra checked baggage, and we charge the bank for this too.
> **Bianca:** Gotcha. So the main business benefit here is from the sale of Frequent Flyer points, not from ticket sales. And how will this feature help us realize that benefit?
> **Sam:** We've negotiated a deal with our banking partner, but we can't issue the cards or sell any Frequent Flyer points until our software integrates with theirs.

The stated feature ("credit card affiliate integration") pointed at member perks. The *actual* goal was **B2B revenue from selling points to banks** — a completely different value model, with different metrics and different priorities. Bianca's third question surfaced an explicit "not exactly" that would otherwise have gone unchallenged.

**The Pirate Canvas that invented a business.**

Flying High wants more of the business travel market. Carrie facilitates, drawing five columns.

*Acquisition — what sucks?*
> **Sam:** Only 5% of booking inquiries come from business users.
> **Carrie:** Why do you think that is?
> **Mark:** We're better known as a low-cost airline for tourist destinations.
> **Sam:** Business travelers don't really want to go to any travel site. They don't even want to travel. **Travel time is considered waste** for most business travelers.
> **Carrie:** If they don't want to travel, what do they want?
> **Sam:** They want to be able to do deals. What they'd really like is more time and opportunities to do business.
> **Carrie:** Aha — so what sucks is that business travelers can't do business on their flights?

*Activation:* travelers might know who else is on the flight, but it's impractical to talk to anyone beyond the person next to you.
*Retention:* it takes more than one conversation to make a sale, and there's no way to reconnect afterward.
*Referral:* no incentive for business flyers to invite their contacts.
*Return:* Mike proposes a **start-up accelerator** — start-ups give Flying High equity in exchange for discounted business flights, gaining both travel and seatmates worth meeting.

Then the bottom half. Carrie starts on Acquisition: Why = increase site visits from business travelers 300%; Who = business travelers. Mark jumps to "a big 'fly business with us' marketing campaign" — Carrie cuts him off:

> **Carrie:** Let's not worry about *what* just yet. **How should their behavior change?** We need that nailed down before we can worry about what we should do to make it happen.

The team lands on: *How* = they come looking for business opportunities on our flights. *What* = an online community showing which potential customers or partners are on your flight.

Then Dave and Sam attack the assumptions:

> **Dave:** You're making a pretty big assumption in the *how*. How do we know that's something business travelers would really want?
> **Sam:** We could test that with a survey. But that's not the riskiest assumption. That *why* feels like a **vanity metric**. Are site visits really the best way to measure acquisition? Wouldn't it be more accurate to measure the number of people who **join the business flyers community**?

Goal revised to "acquire 1,000 business flyers within three months." Then the riskiest assumption — that business flyers produce more bookings — gets its own cheap experiment:

> **Sam:** Before we build a new social network for business travelers, let's test our theory. Why don't we try it out on **our own sales staff**? Propose an internal service where a few willing executives share their flight plans. We can see if people adjust travel plans to get time with executives they're trying to influence. **We can trial the concept without having to write any software at all.**

Final canvas entries (abbreviated):
| Metric | Why (goal) | Who | How (behavior) | What (deliverable) |
|---|---|---|---|---|
| Acquisition | 1,000 business flyers in 3 months | Business travelers | Come looking for business opportunities on our flights | Business Flyer community; *first, a no-software internal trial* |
| Activation | 30% of bookings lead to productive conversations | Business flyers | Engage easily with potential clients/partners | Conversation-friendly cabin, mini-conferences in the lounge |
| Retention | 80% rebook within 3 months | Business flyers | Follow up with new contacts, coordinate later flights | Points for highly rated conversations; social media app |
| Referral | — | Business flyers | Invite their own contacts | Social platform integration; address-book invites with bonus points for both |
| Return | Market value of equity acquired | Start-ups | Trade equity for discounted business flights | Start-up accelerator program |

Note how many deliverables **aren't software**: cabin layout, lobby name tags, lounge mini-conferences, an equity-for-flights program. The Pirate Canvas turned "we want more business travelers" into a candidate new line of business.

## Anti-patterns

- **Treating requirements as rigid dictates set in stone**: "We tend to assume that business folk know what they want, and that what they ask for is indeed what they need. But often we assume too much."
- **12-month to 5-year detailed plans**: beyond ~3 months, detail is rework waiting to happen.
- **Strategic planning without delivery-team members**: teams inherit a backlog with no context, can't judge feasibility, and can't propose better alternatives.
- **Vision statements locked in a PMO document**: "How can a shared vision be useful if not everyone can see it?"
- **Vision statements that specify technology, timeframe, or platform**: a vision states objectives, not delivery mechanics.
- **Dissuasive change-control processes**: they cause stakeholders to front-load every feature they can imagine "in case it comes in handy," inflating scope permanently.
- **Vanity metrics**: site visits when what you care about is community membership.
- **Jumping to "what" before nailing "how"** in Impact Mapping or a Pirate Canvas — the marketing campaign reflex.
- **Building the full solution before testing the riskiest assumption**: the internal executive flight-sharing trial cost zero software.
- **Optimizing multiple Pirate Metrics at once**: "in general we should try to focus on optimizing only one of them at a time." Spending on marketing when the real bottleneck is Activation is pure waste.
- **Features with no traceable value** (figure 4.7): "The ultimate purpose of any new feature is to deliver value to the organization. If it's not doing this in some way, it is probably waste."

## Key Takeaways
1. Phrase every feature as a hypothesis with a falsifying metric, then find the cheapest experiment that could disprove it — often with no software at all.
2. Make business goals SMART, and classify them: increase revenue, reduce costs, protect revenue, or avoid future costs. If it fits none, question it.
3. Pop the why stack (≈5 questions) on every feature request; expect the real value model to differ from the stated one.
4. Use Impact Mapping (Pain point → Goal → Actor → Impact → Deliverable) forward for discovery, and in reverse to prioritize an existing backlog objectively.
5. Include actors who could *block* the goal — regulators, security, sysadmins — not just beneficiaries.
6. Diagnose growth with AARRR and fix one bottleneck at a time; spending on the wrong stage is waste, not progress.
7. Nail *how behavior must change* before discussing *what to build* — this is where teams reflexively skip to solutions.
8. Name your riskiest assumption explicitly and test it before building; challenge your own success metric for vanity.
9. Keep Impact Maps and Pirate Canvases as living documents, updated by production feedback — they are not plans.

## Connects To
- **Ch 1**: the Knowledge Constraint — why detailed long-range plans fail.
- **Ch 3**: the Speculate phase demonstrated end-to-end in the train timetable example.
- **Ch 5**: describing features and slicing them into User Stories (Product Backlog Refinement).
- **Ch 6**: Feature Mapping — sometimes used in Speculate, more commonly in Illustrate.
- **Ch 16**: the Validate phase, where hypothesis metrics are actually collected.
- **Impact Mapping (Gojko Adzic)**, **Crossing the Chasm (Geoffrey Moore)**, **Theory of Constraints (Goldratt)**, **Pirate Metrics (Dave McClure)**, **Hypothesis-Driven Development (Jeffery L. Taylor)**, **SAFe PI planning**, **XSCALE**: the external sources this chapter draws on.
