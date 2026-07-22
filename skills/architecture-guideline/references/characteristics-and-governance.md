# Characteristics and Governance — Full Reference

Read this when eliciting architecture characteristics from stakeholders, defining
a measurement for one, writing an ADR, designing fitness functions, assessing
risk, or preparing to defend a decision you expect to be challenged.

## Contents

1. [What a Characteristic Is](#1-what-a-characteristic-is)
2. [Eliciting the Driving Characteristics](#2-eliciting-the-driving-characteristics)
3. [Making Them Measurable](#3-making-them-measurable)
4. [Fitness Functions](#4-fitness-functions)
5. [Architecture Decision Records](#5-architecture-decision-records)
6. [Trade-Off Analysis](#6-trade-off-analysis)
7. [Risk Assessment and Risk Storming](#7-risk-assessment-and-risk-storming)
8. [Negotiating and Defending Decisions](#8-negotiating-and-defending-decisions)
9. [How Involved Should the Architect Be?](#9-how-involved-should-the-architect-be)

---

## 1. What a Characteristic Is

An architecture characteristic is a **capability** of the system, as opposed to
the domain's **behavior**. "Place an order" is behavior. "Place an order within
200ms during a Black Friday spike" adds two characteristics.

Three qualifying conditions: it specifies a non-domain design consideration, it
influences some structural aspect of the design, and it is critical or important
to the system's success. If a candidate fails the third, it is desirable rather
than driving, and it belongs in "others considered".

The legacy term "non-functional requirements" is rejected deliberately — it is
self-denigrating, and it invites people to treat these as optional. Use
"architecture characteristics", or "the -ilities" informally.

### Explicit versus implicit

**Explicit** characteristics appear in the requirements document. **Implicit**
ones never do, but everybody assumes them: availability, security,
maintainability, feasibility (cost and time), and above all **modularity**.

Modularity deserves special attention because it is the implicit characteristic
most systems live or die by, and nobody ever writes it down. It is also the one
that decays silently — nothing breaks the day a module boundary is violated.

### Composite characteristics

Some have no single objective definition and decompose into measurable parts.
**Agility = deployability + modularity + testability.** You cannot measure agility
directly; you measure the three parts. When a stakeholder asks for a composite,
decompose it in front of them — the decomposition usually reveals that they cared
about only one of the parts.

### The distinctions people conflate

| Term | Means |
|---|---|
| **Scalability** | Handling *growing* concurrent users over time |
| **Elasticity** | Withstanding *bursts* — sudden spikes |
| **Performance** | How fast a single operation completes |
| **Responsiveness** | How fast the user perceives a result |
| **Availability** | Proportion of time the system is up |
| **Reliability** | Whether it produces correct results when up |

A stakeholder saying "it needs to be fast" may mean any of performance,
responsiveness, or scalability, and the three lead to different architectures.
Ask which one before designing.

---

## 2. Eliciting the Driving Characteristics

### The worksheet

An architect-facilitated session with stakeholders. Seven slots for candidate
characteristics, a second column of implicit ones you can pull in, and an "others
considered" area for displaced items. The final step is that stakeholders
collaboratively pick the **top three, in any order**.

The unordered top three is the point. Asking for a full ranking is a fool's
errand — stakeholders never agree on every priority, and the attempt produces
either deadlock or the answer "all of them". The worksheet is downloadable from
`developertoarchitect.com/resources.html`.

### The elimination test

After a first-pass list, ask: **"If I had to eliminate one of these, which would
it be?"** Cull **explicit** characteristics first — implicit ones tend to support
general success and survive elimination naturally.

The test measures *critical necessity*, not desirability. Everything on the list
is desirable; only some of it is load-bearing.

### Reading between the lines

Requirements rarely name characteristics directly. Translate:

| Requirement says | Characteristic |
|---|---|
| "Must handle Black Friday" | Elasticity (not scalability) |
| "Users in twelve countries" | Internationalisation, availability, possibly data residency |
| "We ship weekly and want daily" | Deployability, testability — i.e. agility |
| "Regulators audit us" | Auditability, traceability, data integrity |
| "Each client wants it slightly different" | Customisability → microkernel |
| "All of them" | You asked for a ranking instead of a top three |

Domain concerns map to characteristics too. Mergers and acquisitions imply
interoperability and adaptability. Time to market implies agility. User
satisfaction is a composite of performance, availability, and reliability — pin
down which.

### Architecture katas

The way to build this skill without waiting for real projects. A timeboxed team
exercise with four sections — description, users, requirements, additional context.
Teams produce a characteristics analysis and diagrams, then share and vote, and an
experienced architect critiques the trade-off analysis. There is no answer key,
only trade-offs. Site: `fundamentalsofsoftwarearchitecture.com`.

---

## 3. Making Them Measurable

**A characteristic you cannot measure is a wish.** It cannot be governed, cannot
be verified, and cannot be defended in a negotiation.

| Characteristic | A workable objective measure |
|---|---|
| Performance | p95 / p99 latency per named endpoint, under a defined load |
| Scalability | Concurrent users at which p99 crosses a stated ceiling |
| Elasticity | Time to absorb an N× spike without shedding requests |
| Availability | Downtime seconds per year (see the table below) |
| Modularity | Cyclomatic complexity, cycle count, coupling caps per module |
| Testability | Coverage of the core plus the ratio of unit to end-to-end tests |
| Deployability | Lead time from merge to production; rollback duration |
| Security | Time to patch a CVE; count of dependencies past EOL |

Cyclomatic complexity has a specific threshold worth remembering: `CC = E − N + 2P`,
with the industry threshold at <10 and the authors preferring **<5**. Above **50**
a module is unrecoverable by test coverage alone.

### Availability: say seconds, not nines

| Uptime | Downtime per year (per day) |
|---|---|
| 99.0% | 87 hrs 46 min (14 min) |
| **99.9%** | **8 hrs 46 min (86 sec)** |
| 99.99% | 52 min 33 sec (7 sec) |
| **99.999%** | **5 min 35 sec (1 sec)** |

Always translate before negotiating. "Five nines" is an identity claim; "5 minutes
35 seconds per year, and our current deploy takes four minutes" is arithmetic.
People concede to arithmetic.

Related distinction worth making explicit in writing: an **SLA** is usually
legally binding, an **SLO** usually is not. Do not let one become the other by
accident in a document.

---

## 4. Fitness Functions

A fitness function is **any mechanism that provides an objective integrity
assessment of an architecture characteristic**. It is not a specific technology —
metrics, monitors, unit tests, and chaos engineering all qualify.

### Where they run

- **In the continuous build** — ArchUnit (Java), NetArchTest / ArchUnitNet (.NET),
  PyTestArch (Python), TSArch (TypeScript), deptrac (PHP), JDepend. This is where
  layer rules, forbidden dependencies, cycle detection, complexity caps, and
  coupling limits belong.
- **In production** — Netflix's Conformity, Security, and Janitor Monkeys are the
  canonical examples. Chaos engineering is a fitness function for fault tolerance.

### What to govern with them

Govern the **important but not urgent**: the things that decay silently because
nothing breaks the day they're violated. Layer rules, module boundaries, cycles,
complexity, coupling caps, the k-weight budget on a web page, licence compliance.

### The rule that makes them work

**Explain every fitness function before imposing it.** A rule the team doesn't
understand produces workarounds, not compliance — that's the ivory-tower failure
mode. Some fitness functions require new stories to become checkable at all (for
instance, adding a `@SharedService` annotation so a rule can see intent); budget
for that rather than skipping the function.

### Examples worth stealing

| Rule | Fitness function |
|---|---|
| Domain must not import infrastructure | ArchUnit / deptrac layer rule in CI |
| No cycles between components | JDepend or ArchUnit cycle check |
| No module exceeds 5 coupling points | Custom metric over afferent + efferent coupling |
| Every service starts in under 30s | Timed smoke test in the deploy pipeline |
| Elasticity survives a 10× spike | Scheduled load test with a hard threshold |
| No dependency past end-of-life | Dependency audit gate |

---

## 5. Architecture Decision Records

Write an ADR for **every architecture decision, however obvious** — and
retroactively for the decisions an existing system already embodies.

### Structure

| Section | Content |
|---|---|
| **Title** | Numbered, short, descriptive |
| **Status** | Proposed / Accepted / Superseded. Add *RFC* with an explicit deadline when you want comment |
| **Context** | The forces at play *and the alternatives considered* |
| **Decision** | Affirmative, commanding voice — "We will…" — **with the full justification** |
| **Consequences** | Including the trade-off analysis, good and bad |
| **Compliance** | How the decision will be measured and enforced (often: which fitness function) |
| **Notes** | Author, dates, versions |

Store them in a dedicated repository or wiki, organised as `application/common`,
`application/<app>`, `integration`, and `enterprise`.

### The rules that matter

- **The justification is the point.** A decision recorded without its *why* gets
  re-litigated forever — that's Groundhog Day, and no amount of restating the
  *what* fixes it.
- **Superseded ADRs keep bidirectional links** to their replacement. Never delete;
  the historical trail is half the value.
- **Status "Superseded" always implies the prior status was "Accepted."**
- **ADRs work for standards too.** If you cannot write the justification for a
  standard, the standard probably shouldn't exist.
- Decisions communicated only by email are lost, forgotten, or never received —
  the Email-Driven Architecture antipattern. The ADR repository is the record.

---

## 6. Trade-Off Analysis

Three steps, and skipping the third is the most common failure:

1. **Enumerate contextualised factors** — specific to *this* organisation and
   *this* solution, not generic pros and cons copied from a blog post.
2. **Build a plus/minus matrix** per option.
3. **Weight the factors against actual organisational goals.**

Skipping step 3 is the **Out of Context antipattern**: counting plusses and
declaring a winner. The raw count is never the answer, because the factors are not
equally important to this business.

Redo the analysis every time the question comes up. Subtle differences in context
flip outcomes, and a conclusion inherited from a previous project is exactly the
kind of stale expertise that produces bad architecture.

Two supporting rules:

- **An architecture decision is one where every option carries significant
  trade-offs.** If one option is simply better, it isn't an architecture decision.
- **Use an LLM to enumerate trade-offs, never to choose.** Knowledge is not
  wisdom; the weighting in step 3 requires organisational context the model
  doesn't have.

---

## 7. Risk Assessment and Risk Storming

### The risk matrix

Impact × likelihood, each scored **1–3**. Resulting bands: **1–2 low, 3–4 medium,
6–9 high**.

Two scoring rules:

- **Consider impact first**, and default unknown likelihood to **3**.
- **Rate any unknown technology 9.** The risk matrix quantifies uncertainty about
  known things; it does not apply to ignorance, so assume the worst.

Build risk assessments with **critical characteristics as the criteria** and
**domains as the context**. Services are too fine-grained a context — they miss
inter-service coordination risk, which is where distributed systems actually fail.
Add **direction arrows** from fitness-function trends so a stakeholder can see
whether a risk is improving or worsening, and filter to high-risk items only when
presenting.

### Risk storming

Run it after any major feature, or at the end of each iteration. Three phases,
one criterion or context per session:

1. **Identification — individual.** Everyone identifies risks alone, on sticky
   notes. Individual first is deliberate: it prevents the loudest voice from
   anchoring the room, and it surfaces pluralistic ignorance.
2. **Consensus — collaborative.** Post the notes on a shared architecture diagram
   and reach agreement on the ratings.
3. **Mitigation — with business stakeholders present.** This is where the money
   gets discussed.

**Bring a cheaper alternative to phase 3.** Mitigation costs money, and an
architect who arrives with only the expensive option gets overruled.

---

## 8. Negotiating and Defending Decisions

### With business stakeholders

1. **Read the buzzwords for the real characteristic.** "We need it web-scale" is
   a request for scalability or elasticity; find out which.
2. **Gather information first.** Never negotiate before you know the current
   numbers.
3. **Translate abstractions into concrete units** — 86 seconds a day, not "three
   nines". This is the single highest-leverage move available.
4. **Divide and conquer the requirement.** "Five nines" often applies to one
   critical path, not the whole system. Scope it down and the cost collapses.
5. **Qualified cost and time come last.** Leading with cost poisons the
   negotiation — it reads as refusal rather than analysis.

### With other architects

**Demonstration defeats discussion.** Build the spike, run the load test, show the
numbers. An argument between two architects about which is faster is unresolvable;
a benchmark resolves it in an afternoon.

### With developers

- **Give the justification *before* the demand.** People stop listening the moment
  they disagree, so the reason must arrive first.
- Say **"this means"**, not "you must".
- Ask **"have you considered…"**, not "what you need to do is…".
- **Let them prove themselves right.** A developer who runs the experiment and
  discovers the constraint themselves will defend the decision afterwards.
- **Turn requests into favours.** It costs nothing and changes the dynamic.

### On third-party libraries and frameworks

Require two answers before adoption: what does it **overlap** with that already
exists, and what is the **technical *and* business** justification? Then:

| Kind | Who decides |
|---|---|
| Special-purpose library | Developers decide |
| General-purpose library | Developers recommend, architect approves |
| Framework | Architect only |

Requiring a *business* justification changes how developers evaluate options —
that's the actual purpose of the question.

---

## 9. How Involved Should the Architect Be?

Elastic leadership: score each factor at ±20 and total them.

| Factor | +20 (more involvement) | −20 (less) |
|---|---|---|
| Team familiarity | New members | They know each other |
| Team size | >12 | ≤5 |
| Experience | Mostly junior | Mostly senior |
| Complexity | High | Simple |
| **Duration** | **Long (~2 yrs)** | **Short (~2 mo)** |

Duration is the counterintuitive one: *short* projects need *more* involvement,
because there is no time to recover from a wrong turn.

A negative total means facilitate and stay out of the way. A positive total means
mentor and coach — without disrupting the team's flow, which is a real cost.

Two architect failure modes bracket this: the **control-freak architect** draws
boundaries too tight, and the **armchair architect** — who hasn't coded in years —
draws them too loose. Related: the **Bottleneck Trap**, where the architect owns
critical-path code and blocks everyone, and the **Ivory Tower**, where decisions
are made in isolation from the people implementing them.

Team-level tells worth watching for: frequent merge conflicts indicate **process
loss** from a team that has grown too large; silent nods in a large meeting
indicate **pluralistic ignorance**; dropped work with unclear ownership indicates
**diffusion of responsibility**. All three are architecture problems, because
Conway's Law means the team structure will end up in the system.
