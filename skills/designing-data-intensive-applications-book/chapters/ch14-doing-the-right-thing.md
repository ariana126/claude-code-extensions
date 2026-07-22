# Chapter 14: Doing the Right Thing

## Core Idea
Every data system is built for a purpose and has unintended consequences; engineers carry the responsibility for them. Treat personal data not as an asset to be maximized but as a hazardous material — minimize collection, purge what you no longer need, and preserve each person's control over their own data.

## Frameworks Introduced

- **Ethics as a participatory and iterative process**: "Ethics is not going through a checklist to confirm you comply; it's a participatory and iterative process of reflection, in dialog with the people involved, with accountability for the results."
  - When to use: any product decision that touches people's behavior, identity, or life chances.
  - How: reflect on intended *and* unintended consequences; involve the affected people rather than deciding for them; iterate as the system and its uses change; accept accountability for outcomes. Guidelines like the ACM Code of Ethics and Professional Conduct exist but are rarely discussed, applied, or enforced.
  - Why it works / failure mode: unlike most of computing, the concepts at the heart of ethics are not fixed or determinate — they require subjective interpretation. Treating ethics as a compliance gate produces a signed checklist and no reflection.

- **The surveillance thought experiment**: Replace the word *data* with *surveillance* and see whether the sentence still sounds good — "In our surveillance-driven organization we collect real-time surveillance streams and store them in our surveillance warehouse. Our surveillance scientists use advanced analytics and surveillance processing in order to derive new insights."
  - When to use: reviewing a data collection proposal, a pitch deck, or your own architecture diagram.
  - How: apply it to the actual dataflow you are building. Not all collection is surveillance, but framing it that way exposes the relationship between collector and collected.
  - Why it works: it names the asymmetry that neutral vocabulary hides. Data collected as a side effect of other activity serves the funder (usually advertisers), not the user.

- **Systems thinking about feedback loops**: Reason about the whole system — the computerized parts *and* the people interacting with it — to predict self-reinforcing loops.
  - When to use: before shipping any ranking, scoring, pricing, or recommendation system.
  - How: ask whether the system reinforces and amplifies existing differences between people (making the rich richer, the poor poorer) or combats injustice; trace what happens to someone the model scores badly; look for loops where the output changes the input.

- **Data minimization (GDPR principle)**: Personal data must be "collected for specified, explicit and legitimate purposes and not further processed in a manner that is incompatible with those purposes" and be "adequate, relevant and limited to what is necessary in relation to the purposes for which [it is] processed."
  - When to use: as the default posture for any personal data pipeline.
  - How: minimize what you collect; purge as soon as it is no longer needed; do not retain forever. "Data you don't have is data that can't be leaked, stolen, or compelled by governments to be handed over."
  - Failure mode: it runs *directly counter* to the philosophy of big data — maximize collection, combine datasets, explore for new insights. Exploration means unforeseen purposes, the opposite of "specified and explicit." GDPR has affected online advertising somewhat but has been weakly enforced and has not changed industry culture.

## Key Concepts
- **Algorithmic prison**: Being systematically excluded — from jobs, air travel, insurance, rental, financial services — by automated "no" decisions, without proof of guilt and with little chance of appeal.
- **Proxy discrimination**: Using unprotected features that correlate with protected traits; in segregated neighborhoods a postal code or even an IP address is a strong predictor of race. Satirized as "machine learning is like money laundering for bias."
- **Credit score vs. predictive analytics**: A credit score answers "How did *you* behave in the past?" from relevant, correctable facts; predictive analytics answers "Who is similar to you, and how did people *like you* behave?" — i.e. stereotyping, with almost no recourse when the data is wrong.
- **Surveillance**: Tracking that primarily serves the advertisers funding a service rather than the person being tracked.
- **Privacy as a decision right**: Not keeping everything secret, but the freedom to choose what to reveal to whom, what to make public, and what to keep secret — an aspect of autonomy.
- **Transfer of privacy rights**: Surveillance doesn't erode privacy rights so much as move them from the individual to the company, which then exercises them to maximize profit.
- **Freely given consent (GDPR)**: Consent must be "freely given, specific, informed, and unambiguous," withdrawable "without detriment," in "clear and plain language"; silence, pre-ticked boxes, and inactivity are not consent. Other lawful bases exist (legal compliance, protecting life, legitimate interest such as fraud prevention).
- **Effectively mandatory service**: A service "regarded by most people as essential for basic social participation" — opting out carries a social cost, so declining is not a free choice.
- **Data exhaust vs. labor**: Behavioral data framed as worthless waste to be "recycled"; more accurately, if targeted advertising pays for the service, the user activity generating that data is a form of labor.
- **Toxic asset / hazardous material / "the new uranium"**: Personal data as something whose risk of falling into the wrong hands must be balanced against its benefit, not merely an asset to accumulate.
- **Statistical vs. individual truth**: A correct probability distribution says little about any one person — if average life expectancy is 80, nobody is expected to drop dead on their 80th birthday. Predictions are probabilistic and may be wrong in individual cases.

## Mental Models
- Think of personal data as **pollution**, and privacy protection as the environmental challenge of the information age (Schneier). The Industrial Revolution raised living standards *and* produced foul air, unsanitary housing, and child labor; safeguards took a long time and raised costs, but few would return to the time before. Our grandchildren will judge us on how we handled data collection and misuse.
- Use **"all possible future governments"** as the threat model, not today's. Data outlives regimes, survives bankruptcy as a saleable asset, and leaks. "It is poor civic hygiene to install technologies that could someday facilitate a police state."
- Treat individual control over one's data like **a national park**: unless explicitly protected and cared for it will be destroyed — a tragedy of the commons. Ubiquitous surveillance is not inevitable; we are still able to stop it.
- When a system's inputs carry systematic bias, expect the model to **learn and amplify** it. Predictive analytics extrapolate from the past; if the future is to be better than the past, moral imagination is required, and only humans can supply it. Data and models should be our tools, not our masters.

## Reference Tables

| | Data as service to the user | Data as surveillance |
|---|---|---|
| Origin | Explicitly entered by the user, for the user's purpose | Logged as a side effect of other activity |
| Who is the customer | The user | The advertiser funding the service |
| Retention | As long as the user wants the feature | Long, to build detailed profiles |
| Example benefits | Click-through data improving search ranking; "people who liked X also liked Y"; A/B tests | Ad targeting, profile building for marketing |
| Relationship | Reciprocal | One-way extraction; asymmetric, terms set by the service |

| Concern | Human decision-maker | Algorithmic decision-maker |
|---|---|---|
| Bias | Present, sometimes institutionalized | Learned from data and amplified; opaque, correlation without known cause |
| Accountability | The person can be held accountable | Unclear who answers — self-driving car crash, discriminatory credit scoring |
| Appeal | Possible | Little recourse, especially if inputs were erroneous |
| Explainability | Can be asked to explain | Often cannot be explained to a judge |

## Worked Example
**The credit-score hiring feedback loop.** Employers use credit scores to evaluate potential hires. You are a good worker with a good score, then hit financial difficulty through misfortune outside your control. You miss payments, so your score drops. The lower score makes you less likely to be hired. Joblessness pushes you toward poverty, which worsens your score further, which makes employment harder still. The chapter's verdict: "a downward spiral due to poisonous assumptions, hidden behind a camouflage of mathematical rigor and data." Nothing in the loop is a bug — each component behaves as designed, and only whole-system reasoning exposes the trap.

A second, non-human instance the authors cite: when German gas stations adopted algorithmic pricing, economists found competition *decreased* and consumer prices rose, because the pricing algorithms learned to collude.

## Anti-patterns
- **"I just built the algorithm, the outcome isn't my responsibility"**: people should not be able to
  evade responsibility by blaming an algorithm. The system's consequences are the builder's concern.
- **Dropping protected attributes and declaring the model fair**: correlated proxies — postal code, IP
  address, purchase history — reintroduce them. Biased input yields biased output; "machine learning
  is like money laundering for bias."
- **Treating a model's output as objective because it is quantitative**: mathematical rigor is
  camouflage, not evidence. A prediction inherits every assumption of its training data.
- **Automated decisions with no explanation and no appeal path**: creates an "algorithmic prison"
  where people are systematically excluded from jobs, credit, insurance, or travel with no way to
  contest and no proof of wrongdoing.
- **Treating collected data purely as an asset**: personal data is also a liability with breach,
  regulatory, and reputational risk — a toxic asset, "the new uranium," not just fuel.
- **Collect-everything-now, find-a-use-later**: violates data minimization and purpose limitation, and
  guarantees you hold data you cannot justify when it leaks.
- **Consent obtained by burying terms in a click-through for an effectively mandatory service**: not
  freely given. Silence, inactivity, and pre-ticked boxes are not consent under GDPR.
- **Reasoning only about the software components**: feedback loops live in the interaction between the
  system and the people using it, so only systems thinking — modeling the humans too — reveals them.

## Key Takeaways
1. You are responsible for the consequences of what you build. "People should not be able to evade their responsibility by blaming an algorithm."
2. Predictive analytics that touch loans, jobs, insurance, housing, or justice affect individual lives directly — hold them to a higher bar than weather or disease forecasting, and build an appeal path.
3. Removing protected traits from the inputs does not make a model fair; correlated proxies (postal code, IP address) reintroduce them. Biased input yields biased output.
4. Before shipping a scoring or recommendation system, trace its feedback loops through the humans in the loop, and ask whether it amplifies existing inequality or combats it.
5. Consent obtained via an unreadable privacy policy for an effectively mandatory service is not meaningful consent — especially since one user's data reveals things about non-users who agreed to nothing, and derived datasets are precisely what users cannot understand.
6. Minimize collection and purge aggressively. Balance the value of data against the risk of criminals, hostile intelligence services, insider leaks, acquisition by management that doesn't share your values, bankruptcy sales, and future regimes.
7. Expect data to be wrong, undesirable, or inappropriate — something factually correct can still trigger painful memories — and build mechanisms to handle those failures. Algorithms are oblivious to such notions unless you explicitly program them to respect human needs.
8. Self-regulate and educate users rather than waiting for enforcement; the culture shift needed is to stop treating users as metrics to be optimized.

## Connects To
- **Ch 13**: Derived datasets combining the whole user base with behavioral tracking and external sources are exactly the data users cannot meaningfully consent to; the auditability and provenance tooling from Ch 13 is what makes accountability technically possible.
- **Ch 1**: Returns to balancing the needs of the business against the needs of users.
- **Ch 5 / Ch 12**: Retention and deletion cut across encoding, event logs, and immutable-event architectures — append-only logs make purging personal data genuinely hard.
- **GDPR** (data minimization, purpose limitation, freely given consent, right to explanation); **ACM Code of Ethics and Professional Conduct**.
- **Weapons of Math Destruction** (Cathy O'Neil); Bruce Schneier on data as pollution and the "toxic asset"; Maciej Cegłowski, "The Moral Economy of Tech."
