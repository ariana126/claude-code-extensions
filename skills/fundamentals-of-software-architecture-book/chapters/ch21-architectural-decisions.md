# Chapter 21: Architectural Decisions

## Core Idea
A good architectural decision **guides development teams toward the right technical choices** — which requires gathering enough information, **justifying** it (technically *and* in business terms), **documenting** it as an ADR, and **communicating** it to the right stakeholders. The three decision antipatterns form a progression: escaping each one lands you in the next.

## Frameworks Introduced

- **The Three Decision Antipatterns** — *"these three antipatterns usually follow a progressive flow: overcoming Covering Your Assets leads to Groundhog Day, and overcoming that leads to Email-Driven Architecture."*

  | Antipattern | Cause | Cure |
  |---|---|---|
  | **Covering Your Assets** | The architect **avoids or defers a decision out of fear of making the wrong choice** | Decide at the **last responsible moment**; **collaborate with development teams** to validate feasibility |
  | **Groundhog Day** | People **don't know *why* a decision was made**, so they discuss it over and over, never reaching resolution. *(Named for the 1993 Bill Murray film in which he relives February 2 endlessly.)* | Provide **both technical and business justification** |
  | **Email-Driven Architecture** | People **lose, forget, or never learn** a decision was made, and therefore can't implement it | Communicate to a **single system of record**; never put the decision in the email body |

- **The Last Responsible Moment** — decide when there's enough information to justify and validate the decision, **but not so long that it holds up development teams or lands you in Analysis Paralysis**.
  - **The test**: *when does the **cost of deferring** the decision exceed the **risk** associated with deciding?*
  - **The dynamics**: early on, **cost is low** (little time spent) but **risk is high** (less known about the problem or solution). Deferring increases cost but reduces risk through fuller analysis of alternatives. **The moment to decide is where the two curves intersect — where the cost increase exceeds the reduced risk.**

- **The Email-Driven Architecture cure, precisely** — do **not** put the decision in the email body. Doing so:
  - Creates **multiple systems of record** (every email carries a copy).
  - **Omits important details, including the justification** — recreating Groundhog Day.
  - Makes it impossible to know whether everyone received a revision when the decision is superseded.
  - **Instead**: mention only the nature and context in the body, plus a **link** to the single system of record.
  - **The model email**: *"Hi, Sandra, I've made an important decision regarding communication between services that directly impacts you. Please see the decision using the following link…."*
    - Note the construction: **the context** ("communication between services") without the decision itself; **"that directly impacts you"** — *"if an architectural decision doesn't directly impact the person, then why bother that person with it? This is a great litmus test for determining which stakeholders should be notified directly."*

- **Architectural Significance** (Michael Nygard, author of *Release It!* 2nd Ed.) — **many architects believe a decision involving a specific technology is merely technical, not architectural. Not always true.** If a technology is chosen **because it directly supports a particular architecture characteristic**, it's an architectural decision.
  - Nygard's criteria — architecturally significant decisions **affect a system's**:

    | Dimension | Meaning | Example |
    |---|---|---|
    | **Structure** | The architecture patterns or styles being used | Deciding to share code between microservices impacts the bounded context, and thus the structure |
    | **Non-functional characteristics** | The architecture characteristics important to the system | If a technology choice affects performance and performance matters, that choice is architectural **even though it names a specific product or framework** |
    | **Dependencies** | Coupling points between components and services | Affects scalability, modularity, agility, testability, reliability |
    | **Interfaces** | How services and components are accessed and orchestrated — gateway, integration hub, service bus, adapter, API proxy | Involves **defining contracts, including versioning and deprecation strategies** |
    | **Construction techniques** | Platforms, frameworks, tools, and even **processes** that, though technical, might impact some aspect of the architecture | — |

- **Architectural Decision Records (ADRs)** — evangelized by Michael Nygard in a 2011 blog post; recommended for widespread adoption by the **Thoughtworks Technology Radar in 2017**. A short text file, **usually one to two pages**, describing a specific architectural decision. Written in plain text, a wiki template, or a document format like **AsciiDoc** or **Markdown**. Tooling: **ADR Tools** by Nat Pryce (coauthor of *Growing Object-Oriented Software, Guided by Tests*) — a CLI managing numbering schemes, locations, and superseded logic.

  **Seven sections** — five standard plus two the authors strongly recommend:

  | Section | Contents |
  |---|---|
  | **Title** | Sequentially numbered, short but descriptive enough to remove ambiguity: *"42. Use of Asynchronous Messaging Between Order and Payment Services"* |
  | **Status** | `Proposed` · `Accepted` · `Superseded` |
  | **Context** | The forces at play — *"What situation is forcing me to make this decision?"* Also concisely names the alternatives, and **by describing the context, the architect is also describing the architecture** |
  | **Decision** | The decision **plus a full justification** |
  | **Consequences** | The overall impact, good and bad — **and the trade-off analysis performed** |
  | **Compliance** *(added)* | How the decision will be **measured and governed** — manually, or via a fitness function |
  | **Notes** *(added)* | Metadata: original author, approval date, approved by, superseded date, last modified date, modified by, last modification |

  - **Extend the structure freely** — an **Alternatives** section analyzing all other possible solutions is a good addition. **Just keep the template consistent and concise.**

- **The Status section's three states and their power**:
  - **Proposed** — must be approved by a higher-level decision maker or governance body (an architecture review board).
  - **Accepted** — approved and ready for implementation.
  - **Superseded** — changed and replaced by another ADR. **Always assumes the prior status was Accepted**; a Proposed ADR would never be superseded — it would be modified until Accepted.
  - **The historical-record mechanism**: when superseded, mark the ADR with the number that superseded it, and mark the superseding ADR with the number it replaced:
    ```
    ADR 42. Use of Asynchronous Messaging Between Order and Payment Services
    Status: Superseded by 68

    ADR 68. Use of REST Between Order and Payment Services
    Status: Accepted, supersedes 42
    ```
    *"The link and history trail between ADRs 42 and 68 lets you avoid the inevitable 'what about using messaging?' question regarding ADR 68."*
  - **RFC status** — an effective way to engage developers and initiate collaboration. Send a draft ADR out for comments with a deadline; when the date arrives, analyze the comments, adjust, decide, and set the status to Proposed (or Accepted, if you have authority):
    ```
    STATUS
    Request For Comments, Deadline 09 JAN 2026
    ```
  - **The hidden benefit of the Status section**: *"it forces the architect and their boss or lead architect to discuss the criteria for approving an architectural decision"* — can the architect approve it alone, or must it go to a higher-level architect or review board?
    - **Three good starting places for that conversation**: **cost**, **cross-team impact**, and **security**.
    - **Estimating cost**: software purchase or licensing fees + additional hardware + overall level of effort. **Multiply the estimated implementation hours by the company's standard full-time equivalency (FTE) rate** — the project owner or manager usually has that figure.
    - **Then document the agreed thresholds** ("costs exceeding $5,000 must be approved by the architecture review board") **so all architects know when they can and cannot approve their own decisions.**

- **Voice matters in the Decision section** — Nygard recommends stating decisions in an **affirmative, commanding voice**: *"**We will use** asynchronous messaging between services"* — not *"I think asynchronous messaging would be the best choice,"* which doesn't make clear what the decision is, or **whether a decision has even been made** — only the architect's opinion.

- **Business justification is mandatory** — the Groundhog Day cure. *"Providing the business value is vitally important when justifying an architectural decision. **It is also a good litmus test for determining whether the architectural decision should be made in the first place. If it doesn't provide any business value, perhaps the architect should reconsider the decision.**"*
  - **The four most common business justifications**: **cost, time to market, user satisfaction, and strategic positioning.**
  - **Match the justification to the audience**: *"Justifying a particular decision based on cost savings alone might not be the right call if the business stakeholders are more concerned about time to market."*

## Worked Examples

**Why collaboration cures Covering Your Assets.** The architect decides all product-related reference data (description, weight, dimensions) will be cached in every service instance needing it, using a **read-only replicated cache** with the primary cache owned by the `Catalog` service. The justification: **reduce coupling between services and share data effectively without interservice calls.**

But the development teams implementing it discover that **due to some services' scalability requirements, this would require more in-process memory than is available.** Because the architect collaborates closely, **they learn of the issue quickly and adjust the decision.**

*"No architect can possibly know every single detail about any issue associated with a particular technology."*

---

**Why the *why* matters more than the *how*.** The architect chooses **gRPC** between two services to reduce network latency, because responsiveness needs are very high. **Several years later**, a new architect decides to use REST instead — to make communication between services more consistent.

**Because the new architect doesn't understand *why* gRPC was chosen, their decision has a significant impact on latency, causing timeouts in upstream systems.** With an ADR, they'd have known the original decision traded **tight service coupling for reduced latency** — and prevented the problem.

---

**Why Consequences prevents disagreement.** The architect chooses asynchronous fire-and-forget messaging for posting website reviews, improving responsiveness **from 3,100 ms down to 25 ms** because users only wait for the message to reach a queue.

A developer objects: *"What happens if someone posts a review with some bad words?"* — citing the complexity of asynchronous error handling. **What the developer doesn't know is that the architect already discussed exactly that problem with business stakeholders and other architects, and they decided together that improving responsiveness and dealing with complex error handling beat increasing wait time to provide success/failure feedback.** Documented in the Consequences section, the disagreement never happens.

---

**A complete ADR — GGG auction system:**

> **ADR 76. Separate Queues for Bid Streamer and Bidder Tracker Services**
>
> **STATUS** — Accepted
>
> **CONTEXT** — The `Bid Capture` service, upon receiving a bid, must forward that bid to the `Bid Streamer` service and the `Bidder Tracker` service. This could be done using a single topic (pub/sub), separate queues (point-to-point) for each service, or REST via the Online Auction API layer.
>
> **DECISION** — We will use separate queues for the `Bid Streamer` and `Bidder Tracker` services.
> - `Bid Capture` needs no information back from either service — **communication is only one-way**.
> - `Bid Streamer` must receive bids **in the exact order accepted** by `Bid Capture`. Messaging and queues **automatically guarantee bid order by leveraging FIFO queues**.
> - **Multiple bids come in for the same amount** ("Do I hear a hundred?"). `Bid Streamer` only needs the *first* bid at that amount; `Bidder Tracker` needs all of them. **A topic would force `Bid Streamer` to ignore duplicate amounts, requiring it to store shared state between instances.**
> - `Bid Streamer` stores bids in an in-memory cache; `Bidder Tracker` stores them in a database and **will therefore be slower and might require backpressure. A dedicated queue provides that backpressure point.**
>
> **CONSEQUENCES**
> - We will require clustering and high availability of the message queues.
> - `Bid Capture` must send the same information to multiple queues.
> - **Internal bid events will bypass security checks done in the API layer.**
> - *UPDATE: Upon review at the January 14, 2025, ARB meeting, the ARB decided that this was an acceptable trade-off and that no additional security checks are needed for bid events between these services.*
>
> **COMPLIANCE** — We will use periodic manual code reviews to ensure asynchronous messaging is used between `Bid Capture`, `Bid Streamer`, and `Bidder Tracker`.
>
> **NOTES** — Author: Subashini Nadella · Approved: ARB Meeting Members, 14 JAN 2025 · Last Updated: 14 JAN 2025

**Note the craft**: four independent justifications in the Decision section, three honest consequences including a security concession, and an inline UPDATE recording the governing body's ruling on that concession.

---

**An automated Compliance section.** In a traditional n-tiered layered architecture, the decision is that **all shared objects used by Business layer objects must reside in the Shared Services layer**, to isolate and contain shared functionality. With ArchUnit:
```java
@Test
public void shared_services_should_reside_in_services_layer() {
    classes().that().areAnnotatedWith(SharedService.class)
        .should().resideInAPackage("..services..")
        .check(myClasses);
}
```
**Note the practical implication**: this fitness function **requires writing new stories** to create a `@SharedService` Java annotation and apply it to all shared classes. Governance has a cost. (NetArchTest is the C# equivalent.)

## Storing ADRs
Each decision gets **its own file or wiki page**. Some architects keep ADRs in the same Git repository as the source code, versioning them like code — **but the authors caution against this in larger organizations** for two reasons:
1. **Everyone who needs to see the decision might not have access** to that Git repository.
2. **The application's repository is a poor place for decisions with context outside it** — integration decisions, enterprise decisions, or decisions common to every application.

**Recommended**: a **dedicated ADR Git repository everyone can access**, a **wiki** with a template, or a shared directory on a file server accessible by wiki or document-rendering software.

**Recommended structure** (names are examples — *"choose whatever names fit the company's situation, as long as those names are consistent across teams"*):

| Directory | Contents | Example decision |
|---|---|---|
| `application/common` | Decisions applying to **all** applications | "All framework-related classes will contain an annotation (`@Framework` in Java) or attribute (`[Framework]` in C#) identifying the class as belonging to the underlying framework code" |
| `application/app1`, `application/app2` | Decisions specific to that application or system | — |
| `integration` | Decisions involving communication **between** applications, systems, or services | — |
| `enterprise` | **Global** decisions impacting all systems and applications | "All access to a system database will only be from the owning system" — preventing databases from being shared across systems |

## ADRs as Documentation
*"Documenting software architecture has always been difficult. While some standards are emerging for **diagramming** architecture (Simon Brown's **C4 Model**, The Open Group's **ArchiMate**), no agreed-upon standard exists for **documenting** software architecture. That's where ADRs come in."*
- **Context** describes the specific area of the system requiring a decision, plus the alternatives.
- **Decision** describes *why* — *"by far the best form of architectural documentation."*
- **Consequences** adds the trade-off analysis — e.g. the reasons and trade-offs for choosing performance over scalability.

## ADRs for Standards
*"Very few developers like standards. Unfortunately, standards are sometimes more about control rather than providing a useful purpose. Using ADRs for standards can change this bad practice."*
- **Context** describes the situation forcing the organization to adopt the standard.
- **Decision** states not only *what* the standard is but **why it needs to exist** — *"a great way to qualify whether a particular standard should even exist in the first place. **If an architect can't justify it, then perhaps it isn't a good standard to set and enforce.**"*
- **The compliance payoff**: *"the more developers understand **why** a particular standard exists, the more likely they are to follow it (and, correspondingly, not challenge it)."*
- **Consequences** forces the architect to think about the standard's implications and whether it should be implemented at all.

## ADRs for Existing Systems
Many architects question their usefulness once decisions are made and the system is in production. **They do serve a purpose** — *"ADRs are more than just documentation — they help architects and developers understand **why** a decision was made and if it was the most appropriate one."*
- **Start by writing ADRs for the more significant decisions already made, and question whether they were right.** A group of services shares a single database — **why? Is there a good reason? Should the data be broken apart?**
- **When the original decision-maker has left the company** and nobody knows the answer, **it's up to the architect to identify and analyze the alternatives and trade-offs and attempt to validate (or invalidate) the existing decision.**
- Either way, this **builds up the justifications, rationales, and brain trust for the system, and helps identify architectural inefficiencies and incorrect system design.**

## Generative AI and LLMs in Architectural Decisions
Can AI help make and validate decisions — messaging vs. streaming vs. event sourcing? Monolithic database vs. domain databases? One `Payment Processing` service or one per payment type?

**Most architects already know the answer: it depends.** Back to the First Law — everything is a trade-off. **Decisions depend on the specific context in which they're applied. Every situation and environment is different, which is why there are no "best practices" for these sorts of structural questions.**

**The core problem**: *"Most LLMs base their results largely on probability… what is the most probable answer given the context of the prompt, and what is the 'best practice' for this problem? However, **probability and 'best practices' have no place in making architectural decisions.**"*

**What decisions actually require**: translating **business concerns** (time to market, sustained growth) into **architecture characteristics** (maintainability, testability, deployability). *"This translation is not always obvious, and getting it right requires years of experience. Once completed, it serves as a basis for trade-off analysis."*
- **Worked through**: one payment service or one per payment type reduces to a trade-off between **maintainability and performance** — a single service performs better, multiple services are more maintainable. **If the business is primarily concerned with time to market, maintainability far outweighs performance, so separate services are appropriate *for this specific context*.**

**The verdict**: *"The best-case scenario, based on recent experiments your authors have done, is to have a generative AI tool **outline the possible trade-offs** of a decision, to assist in identifying any missed trade-offs. While generative AI tools have plenty of **knowledge**, they lack the **wisdom** required to make the most appropriate architectural decision."*

## Key Takeaways
1. Decide at the last responsible moment — the point where deferral cost exceeds decision risk — and collaborate with implementers to validate feasibility.
2. Always supply a **business** justification alongside the technical one; if you can't find one, reconsider the decision.
3. Match the justification to what stakeholders actually care about: cost, time to market, user satisfaction, or strategic positioning.
4. Never put a decision in an email body. Send context + a link to the single system of record, and only to people the decision directly impacts.
5. Use Nygard's five significance criteria to settle "is this architectural or just technical?" — technology choices that serve a characteristic *are* architectural.
6. Write ADRs in commanding voice: "We will use X."
7. Preserve superseded ADRs with bidirectional number links — that's what stops old debates from restarting.
8. Add **Compliance** and **Notes** sections; the Compliance section forces you to decide whether governance is manual or automated, and to budget for it.
9. Store ADRs outside the application repo — in a dedicated repo or wiki — so integration and enterprise decisions have a home and everyone has access.
10. Write ADRs for existing systems; investigating "why?" for legacy decisions surfaces architectural inefficiencies.
11. Use an LLM to enumerate trade-offs you might have missed — never to make the decision. **Knowledge is not wisdom.**

## Connects To
- **Ch 1**: architecture decisions as the fourth dimension; guide vs. specify; the First Law behind "it depends."
- **Ch 2**: architectural thinking and trade-off analysis; the Frozen Caveman antipattern's cousin.
- **Ch 6**: fitness functions — the automated form of the Compliance section.
- **Ch 15**: the responsiveness example (3,100 ms → 25 ms) comes from EDA's asynchronous capabilities.
- **Ch 19**: ADRs as one of the three outputs of choosing a style.
- **Ch 20**: the critique of "best practices."
- **Ch 23**: diagramming architecture — C4 and ArchiMate.
- **Ch 25**: negotiation — how you get a Proposed ADR to Accepted.
