# Chapter 22: Analyzing Architecture Risk

## Core Idea
Risk assessment is **subjective by default** — the risk matrix makes it numerical, the risk assessment makes it comparable across contexts and criteria, and **risk storming** makes it collaborative, because no architect can singlehandedly determine a system's risk.

## Frameworks Introduced

- **The Risk Matrix** — two dimensions, each rated **low (1), medium (2), or high (3)**, multiplied at the intersection:

  | | Likelihood: Low (1) | Likelihood: Medium (2) | Likelihood: High (3) |
  |---|---|---|---|
  | **Impact: Low (1)** | 1 — low | 2 — low | 3 — medium |
  | **Impact: Medium (2)** | 2 — low | 4 — medium | 6 — high |
  | **Impact: High (3)** | 3 — medium | 6 — high | 9 — high |

  - **Bands**: 1–2 low (green) · 3–4 medium (yellow) · 6–9 high (red). *Use shading as well as color for grayscale rendering and for people unable to distinguish colors.*
  - **Tip: consider impact first and likelihood second. If you are unsure of the likelihood, use a high (3) rating until you can confirm.**
  - **Worked**: concern about the primary central database's availability. *Impact* if it goes down: **high (3)**. But the database sits on highly available servers in a clustered configuration, so *likelihood*: **low (1)**. → **3, medium risk.**
  - *"We italicize **opinion** here to emphasize the subjectivity of assessing risk."* The matrix is what converts opinion into something more objective.

- **Risk Assessments** — a summarized report of overall architecture risk, with criteria down the left and **context** across the top.
  - **Use architecture characteristics as the risk-assessment criteria.** *"Why spend time analyzing performance risk when the system's critical architectural characteristics are scalability, elasticity, and data integrity?"* **Tip: the architectural characteristics most critical for the architecture to support make great risk-assessment criteria.**
  - **Use domains or subdomains as the context** — *"analyzing risk at the level of services is usually too fine-grained and doesn't account for risk involving communication or coordination between multiple services."*
  - **Read it in two directions.** In an ecommerce ordering example with five criteria and four domain contexts (customer registration, catalog checkout, order fulfillment, order shipping): **data integrity accumulates 17, the highest risk *criterion*; availability accumulates only 10, the lowest.** Meanwhile **customer registration is the highest-risk *context* and order fulfillment the lowest.** *"This is useful information when determining priorities and where to put additional effort into reducing risk."*
  - **Filter for the audience.** Presenting to stakeholders about high-risk areas, **filter out the low- and medium-risk cells (the noise) to highlight the high-risk ones (the signal)**. Improving the signal-to-noise ratio delivers a more effective, less distracting message.
  - **Add the third dimension: direction of risk.** A static assessment is only a snapshot; it can't show whether things are improving. **Determine direction using continuous measurements through fitness functions (Ch 6)**, then annotate:

    | Symbol | Meaning |
    |---|---|
    | ▲ right-side-up triangle | Risk is **getting worse** — the tip points up, toward a *higher* number |
    | ▼ upside-down triangle | Risk is **lessening** — the tip points down, toward a *lower* number |
    | ● circle | Risk is **not moving** |

    *"This can get confusing, so we always recommend including a key when using any sort of symbol to represent direction."*
  - **What direction reveals**: in the revised assessment, **data integrity is worsening across catalog checkout, order fulfillment, and order shipping — which could indicate a database issue**, while **security and availability are improving for customer registration and catalog checkout.** The directional version *"tells a different story than the original."*

- **Risk Storming** — a collaborative exercise to determine architectural risk **within a specific dimension** (context or criteria).
  - **Why it's necessary**: (1) an architect working alone might miss or overlook a risk area; (2) **very few architects have full knowledge of *every* part of the system.**
  - **Who participates**: multiple architects, and *"we strongly recommend including senior developers and tech leads as well. Not only will they provide an implementation perspective on architectural risk, but **involving them helps them better understand the architecture**."*
  - **All three phases use a comprehensive or contextual architecture diagram** (Ch 23), which the **facilitator** sends to all participants beforehand.

  **Phase 1 — Identification (individual):**
  1. The facilitator sends an invitation containing **the architecture diagram (or where to find it), the risk criteria and context to be analyzed, and the date, time, and location**, plus logistics.
  2. Participants analyze risks **individually** using the risk matrix.
  3. Participants classify each risk as low (1–2), medium (3–4), or high (6–9), writing the numbers on **small green, yellow, or red sticky notes**.
  - **Why individually is essential**: *"so that participants don't influence other participants or direct people's attention away from particular areas of the architecture."* Each participant records their **unbiased** view.
  - **Tip: whenever possible, restrict risk-storming efforts to a single criterion or context.** This lets participants focus and avoids confusion about what the actual risk is. If staffing or timing forces multiple dimensions, **participants write the specific criterion next to the risk number** — e.g. three participants all rate a central database 6, but one sees it as an *availability* risk and two as a *performance* risk. **Those two criteria should be discussed separately.**

  **Phase 2 — Consensus (collaborative):** the facilitator posts a large printed diagram on the wall (or displays an electronic version), participants place their sticky notes on the relevant areas, and the team analyzes the risk areas together to reach consensus.
  - **Areas where everyone agrees need no further discussion.** The work is in the **discrepancies** — where ratings differ, or where only one participant flagged something.
  - **Tip: always assign unproven or unknown technologies the highest risk rating (9), since the risk matrix cannot be used for this criterion or context.**

  **Phase 3 — Risk Mitigation (collaborative):** seek ways to reduce or eliminate the agreed risks. *"Mitigating risk usually involves changing certain areas of the architecture that otherwise might have been deemed perfect the way they were."* Changes range from a complete redesign to straightforward architectural refactoring — **such as adding a queue for backpressure to reduce a throughput bottleneck.**
  - **Include key business stakeholders with authority**, because mitigation *"usually incurs additional costs"* and someone must decide whether the cost outweighs the risk.

- **User-Story Risk Analysis** — risk storming applies beyond architecture. A development team can use the **same risk matrix during story grooming** to assess a user story: **impact if the story is not completed within the iteration × likelihood that it won't be.** They can then identify high-risk stories, **track them carefully, and better prioritize them** — producing an overall risk assessment for the iteration.

## Worked Examples

**Phase 2 in action — three kinds of disagreement.** The example architecture: an Elastic Load Balancer forwards requests to EC2 instances containing Nginx web servers and application services, which call a MySQL database, a Redis cache, and a MongoDB database for logging, and also call Push Expansion Servers that interface with the same three.

Initial sticky notes: **Elastic Load Balancer — two at medium (3), one at high (6)** · **Push Expansion Servers — one at high (9)** · **MySQL — three at medium (3)** · **Redis cache — one at high (9)** · **MongoDB logging — three at low (2)** · nothing anywhere else.

MySQL and MongoDB need no discussion — unanimous. The other three are the point of the exercise:

| Case | What happened | The lesson |
|---|---|---|
| **Elastic Load Balancer** — split rating | Austen and Logan (3) ask Addison (6) why. Addison: **if the ELB goes down, the entire system becomes inaccessible** — which correctly brings *impact* to high. But the other two **convince Addison the *likelihood* is low due to clustering.** Consensus: **medium (3)** | *"This could have gone a different way. If Austen and Logan missed a particular aspect of risk that Addison saw, Addison might have convinced them to classify it as high instead. **That's why the collaboration phase of risk storming is so important.**"* |
| **Push Expansion Servers** — one lone high (9) | The participant explains they've had **bad experiences with Push Expansion Servers continually crashing under high loads similar to this architecture's** | *"Without that participant's involvement, no one would have seen the high risk until well into production."* |
| **Redis cache** — one lone high (9) | Asked for their rationale, Devon (a developer) responds: **"What's a Redis cache?"** | **Whenever a participant identifies a technology as unknown to them, that area automatically gets a 9.** This is *"why it's important to bring developers into risk-storming sessions. The fact that this participant didn't know a given technology is valuable information for the architect about overall risk. The architect might decide to change the technology or incur training costs to bring the development team up to speed."* |

---

**Phase 3 in action — negotiating mitigation cost.** The team identifies the central database as medium risk (4) for overall availability, and agrees that **clustering the database and breaking it into separate physical databases** would mitigate it — at a cost of **$50,000**.

The facilitating architect meets with the business owner to discuss the trade-off of availability risk versus cost. **The owner decides the price tag is too high — the cost doesn't outweigh the risk.**

The architect then proposes a different approach: **split the database into two separate domain-based databases** for **$16,000**, still reducing availability risk. **The stakeholders agree to this compromise.**

*"This scenario shows how risk storming shapes not only the overall architecture, but also the **negotiations between architects and business stakeholders**."*

---

**Full use case: a nurse call-center diagnostics system.**

*Requirements*: a third-party **diagnostics engine handles ~500 requests/second** and guides nurses and patients through medical issues. Patients either call in to speak to a nurse or use a **self-service website accessing the same engine directly**. The system must support **250 concurrent nurses** and **up to hundreds of thousands of concurrent self-service patients** nationwide. **Nurses can access patients' medical records; patients cannot.** The system must be **HIPAA compliant** — only nurses may access medical records, and **the self-service option cannot guarantee HIPAA compliance**. It must handle **high volume during cold, flu, and COVID outbreaks**, and route calls to nurses **based on skill profile** (languages spoken, medical specializations).

*Logan's initial architecture*: three web UIs (self-service, nurses, admin), a `Call Accepter` and a `Call Router` service (which reads nurse profiles from the central database), and a **central diagnostics-system API Gateway** performing security checks and routing to four services — `Case Management`, `Nurse Profile Management`, `Medical Records Interface`, and the external `Diagnostics Engine Interface`. All REST except proprietary protocols to external and call-center systems. Driving characteristics: **availability, elasticity, security.**

*"After many reviews, Logan believes the architecture is ready for implementation. However, being a responsible and effective architect, Logan decides to hold a risk-storming exercise."*

**Session 1 — Availability:**

| Area | Rating | Reasoning |
|---|---|---|
| Central database | **6 (high)** | High impact (3) × medium likelihood (2) |
| `Diagnostics Engine` | **9 (high)** | High impact (3) × **unknown** likelihood (3) |
| `Medical Records Interface` | **2 (low)** | Not required to determine a medical outcome |
| Everything else | none | Multiple instances of each service; the API Gateway is clustered |

- **Mitigation for the database**: all participants agree that if it went down, **nurses could write case notes manually, but the call router could not function.** So they **split the single physical database into two**: a **clustered** database for nurse-profile information, and a **single-instance** database for case notes. *"Not only does this architecture change address the database availability concerns, it also helps secure the case notes."*
- **Mitigation for external systems** — much harder, since a third party controls them. The team researches whether **published SLAs or SLOs** exist. *(An **SLA** is usually a legally binding contractual agreement; an **SLO** is usually not legally binding.)* They find SLAs for both: the **`Diagnostics Engine` guarantees 99.99% availability — 52.60 minutes of downtime per year**; the **`Medical Records Interface` guarantees 99.90% — 8.77 hours per year.** **This was enough to remove the identified risk**, and the SLAs were added to the architecture diagram.

**Session 2 — Elasticity:** although only 250 nurses exist, **the self-service portion also hits the `Diagnostics Engine`**, hugely increasing request volume — and flu season and COVID outbreaks will spike it further. **Participants unanimously rate the `Diagnostics Engine` interface high risk (9)**: at only 500 requests/second, it correctly calculates as unable to keep up with anticipated throughput, **particularly with REST as its interface protocol.**

Mitigation proceeded in three rounds, each insufficient alone:
1. **Asynchronous queues (messaging) between the API Gateway and the `Diagnostics Engine` interface**, providing a **backpressure point** if calls back up. *"While this is a good practice, it still doesn't quite mitigate all the risk: nurses and self-service patients will still be waiting too long for responses, and their requests will likely time out."*
2. **The Ambulance pattern** — separate the requests into **two message channels instead of one**, letting the system **prioritize nurses' requests over self-service requests.** Helps, **but still doesn't address wait times.**
3. **A new `Diagnostics Outbreak Cache Server`** handling all requests related to a particular outbreak or flu question, **so they never reach the `Diagnostics Engine` interface** — reducing calls to the engine and freeing capacity for other symptoms.

*"Without the risk-storming effort, this risk might not have been identified until flu season."*

**Session 3 — Security:** Due to HIPAA, only nurses may reach the `Medical Records Interface`. **The architect believed the API Gateway's authentication and authorization checks neutralized this risk, rating it low (2).**

**All participants rated the API Gateway a high security risk (6)** — high impact (3) if admin staff or self-service patients access medical records, medium likelihood (2). Their argument: **per-call security checks help, but all calls — self-service, admin, and nurses — still go through the same API Gateway.** *"They eventually convince the facilitator… that the risk is in fact high and needs to be mitigated."*

**Mitigation**: **separate API Gateways for each type of user** (admin staff, self-service, nurses), so **non-nurse calls can never reach the `Medical Records Interface`.**

**Result**: the original architecture was *significantly changed* by risk storming, addressing availability, elasticity, and security — *"making this architecture more effective and more likely to succeed."* **Note that the facilitating architect was overruled on security by their own participants.**

## Key Takeaways
1. Convert risk opinions into numbers with the matrix: **impact × likelihood**, impact first, and default unknown likelihood to high.
2. Use your **critical architecture characteristics** as risk criteria and **domains/subdomains** as context — services are too fine-grained.
3. Read the assessment in both directions: which criterion is riskiest overall, and which context is riskiest overall.
4. Filter to high-risk cells when presenting to stakeholders; improve the signal-to-noise ratio.
5. Add **direction** via continuous fitness-function measurement — a snapshot can't tell you whether you're winning.
6. Run identification **individually first**; collaborative-only sessions get anchored by whoever speaks first.
7. Restrict each session to one criterion or context.
8. **Rate any unknown or unproven technology 9 automatically** — and treat "what is that?" from a developer as genuine risk data, not ignorance.
9. Bring developers and tech leads in; they surface both implementation risk and their own knowledge gaps.
10. Bring business stakeholders to mitigation — **mitigation costs money, and the risk/cost trade-off is theirs to make.** Come with a cheaper second option.
11. Reuse the matrix for user-story completion risk during grooming.
12. **Risk storming is not a one-time process.** Run it after adding a major feature or at the end of every iteration; frequency depends on rate of change, architecture-refactoring efforts, and incremental development.

## Connects To
- **Ch 4**: architecture characteristics — the source of good risk criteria.
- **Ch 6**: fitness functions — how you obtain the direction of risk.
- **Ch 9**: the fallacies underlying many availability and throughput risks.
- **Ch 15**: backpressure via queues, used in the elasticity mitigation.
- **Ch 21**: ADRs — where mitigation decisions get recorded and justified.
- **Ch 23**: diagramming — every risk-storming phase depends on a good architecture diagram.
- **Ch 25**: negotiation — the $50,000 → $16,000 mitigation conversation.
