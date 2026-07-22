# Chapter 27: The Laws of Software Architecture, Revisited

## Core Idea
**The real job of software architecture is analyzing trade-offs** — not finding silver bullets. The three laws, revisited with worked trade-off analyses, plus the two corollaries and the antipattern that ruins otherwise-correct analysis.

## The Three Laws

1. **Everything in software architecture is a trade-off.**
2. **Why is more important than how.**
3. **Most architecture decisions aren't binary but rather exist on a spectrum between extremes.**

*"When we wrote the first edition, we hoped to find numerous things that seemed universally true and codify them as laws. To our surprise, we ended up identifying just two, then uncovered one more while writing the second."*

## Frameworks Introduced

- **Be an objective arbiter, not an evangelist.** *"Many people think that the job of a software architect is to find silver bullet solutions to sticky problems and become a hero, but that rarely happens. (**Architects rarely get credit for good decisions, but always get blamed for bad ones.**)"* Two reasons to build a reputation for objectivity instead:
  1. **Evangelism is dangerous long-term, because yesterday's best practice tends to become tomorrow's antipattern.** Decisions are made with incomplete knowledge, and the ecosystem's constant evolution slowly changes the circumstances that justified them. *"If the architect has invested social capital in evangelizing for that solution, their reputation may suffer when that decision must change later. **Always stay clear-eyed and objective about technology choices to avoid attaching your credibility to a decision that didn't age well.**"*
  2. **Decision makers aren't looking for enthusiastic advocacy so much as sober objectivity.** *"An architect who develops a reputation as the go-to person for an objective trade-off analysis becomes a valuable asset. When the decision is critical, decision makers want someone whose judgment they can trust; **that should be you.**"*

- **The trade-off analysis method** — the pattern demonstrated twice in this chapter:
  1. **Determine all the contextualized factors that make a difference for this solution.** *"This list will be highly specific to both the organization and the solution, so you'll need to rely on your knowledge of the organization, technology landscape, team capabilities, budgets, and everything else."*
  2. **Build a matrix** comparing how well each option does on each factor.
  3. **Weight the factors against the actual organizational goals** — the step whose omission is the Out of Context antipattern.

- **First Corollary: Missing Trade-Offs.** *"If you think you've discovered something that **isn't** a trade-off, more likely you just haven't **identified** the trade-off…yet."* **The advice when a decision seems to have no trade-offs: keep looking.**

- **Second Corollary: You Can't Do It Just Once.** *"It would be nice if an architect could just perform one trade-off analysis — just think **really hard** and decide once and for all to use choreography for all workflows."* Two problems:
  1. *"There are often dozens or even hundreds of variables (technical and otherwise) that contribute to the decision: complexity, team experience, budget, team topology, schedule pressure… the list is endless. **Subtle differences in those variables can push a particular analysis in one direction or another**, making this an ongoing exercise."*
  2. *"**It's dangerous for architects to make sweeping, semipermanent decisions based on assumptions that might not be valid for future applications of this solution.**"*
  - *"Think of this corollary as **job security for architects.** We have to keep doing trade-off analysis over and over, even for seemingly similar situations."*

- **The Out of Context antipattern** — *"occurs when the architect understands the trade-offs but not how to **weight** all of them based on the current context."*
  - **Applied to the shared library/service analysis**: taken objectively, the shared library wins on raw count. **But do all the criteria have equal weight?** *"Imagine that a team has code in several platforms. They aren't overly concerned with performance or scale, but want a clean way to manage shared behavior. **In this case, the first two trade-off criteria carry a much higher priority, which should lead them to choose the shared service.** As a bonus, the team has already figured out what issues they will have to mitigate."*
  - **The rule**: *"Architects rely on experience to build trade-off criteria, but must also **weigh** those criteria to find the correct fit. **Generic trade-off analysis isn't very useful — it only becomes valuable when applied in a specific context.**"*

- **The Second Law in practice** — why diagrams alone aren't enough. *"As experienced architects, we can look at an existing system and tell someone **how** it works. However, there will be some decisions where it isn't clear **why** the previous architect chose this option, because they didn't record the decision criteria with their ultimate solution."*
  - **The prescription**: use **both architecture diagrams *and* ADRs** (Ch 21). *"Every trade-off analysis generates a tremendous amount of context that doesn't appear in the solution. It's critical to document that analysis (**along with the known compromises and limitations**) to prevent future architects (who might be you) from having to redo the analysis just to understand **why**."*

- **The Third Law's practical definition** — *"It would be nice to live in a world with nice, clean, binary decisions — but software architecture doesn't exist in that world. People often observe how difficult it is to come up with comprehensive definitions of important concepts: architecture versus design, orchestration versus choreography, topics versus queues. **The underlying reason is that the decision criteria aren't binary; they lie along a rather messy spectrum.**"*
  - **The derived test for what counts as architecture**:
    > **"A software architecture decision is one where each of the options has significant trade-offs."**
    > *"If everything in software architecture is a trade-off, then an architectural decision must involve trade-offs for each option."*
  - *"As an architect, **don't try to reduce every decision to a binary** — few of those exist in our world. That's one of the reasons that every answer in software architecture is 'it depends' — **it depends on where on the spectrum of possible solutions the criterion in question falls.**"*
  - *"As architects, we make our decisions in a **swamp of uncertainty**. Accommodating this is annoying, but necessary. Not only do we sometimes have to base important decisions on incomplete information, but often the decision wouldn't be clear-cut, even if we had the full scoop, because it resides somewhere on a spectrum between two extremes. **Welcome to software architecture!**"*

## Worked Examples

**Trade-off analysis 1 — shared library vs. shared service.** A common conundrum for shared behavior in distributed architectures: a **library compiled into each service at build time**, or a **service other services call at runtime**?

**The seven contextualized factors:**

| Factor | Reasoning |
|---|---|
| **Heterogeneous code** | With multiple platforms, **the service is easier** — callers access it via the network, making the implementation platform irrelevant. **The library needs a version for each technology stack, kept in sync**, greatly adding complexity |
| **High code volatility** (churn) | **The service is better** — callers access new functionality as soon as the updated service deploys. **The library requires recompiling and deploying every service** |
| **Ability to version changes** | **The library is much easier** — version differences resolve at compile time. **For the service, version information must be determined at runtime**, complicating the interaction |
| **Overall change risk** | **The library is better** — once changed and successfully compiled in, you can have high confidence it works. **The service may change with no compile-time verification, raising the likelihood of a runtime fault at invocation** |
| **Performance** | **The library clearly wins** — in-process calls versus network calls with latency |
| **Fault tolerance** | **The library is better** — runtime access to services always suffers potential network issues (Ch 9). Once compiled, tested, and deployed, you can have high confidence it's stable |
| **Scalability** | **The library is better** — calls between services suffer latency, which diminishes scalability |

**Table 27-1. Trade-offs between shared service and shared library**

| Factor | Shared library | Shared service |
|---|---|---|
| Heterogeneous code | − | **+** |
| High code volatility | − | **+** |
| Ability to version changes | **+** | − |
| Overall change risk | **+** | − |
| Performance | **+** | − |
| Fault tolerance | **+** | − |
| Scalability | **+** | − |

*"The accumulation of positives for the shared library makes it the winner… **at least, for these factors and in this context.** It may or may not be the solution to the problem at hand — you may need to apply additional weighting — but now you and your team have a good idea of the forces at play."*

---

**Trade-off analysis 2 — queue vs. topic.** The `Trading` service must send trade information to both `Notification` and `Analytics`.

**Queue (point-to-point)**: *"the publisher knows who is receiving the message. To reach multiple consumers, the publisher needs to send a message to one queue for each consumer."*

**Table 27-2. Trade-offs when using a queue**

| Advantage | Disadvantage |
|---|---|
| Supports **heterogeneous messages** for different consumers | Higher degree of coupling |
| Allows **independent monitoring of queue depth** | `Trading` service must connect to multiple queues |
| **More secure** | Requires additional infrastructure |
| | **Less extensible** — must add queues for more consumers |

- *"The `Trading` service is aware of every system it communicates with, which makes it **harder for another (potentially rogue) service to 'listen in.'** That's especially beneficial if security is high on the priority list."* And **because each queue is independent, you can monitor them separately and even scale them independently.** But *"if you need to send messages to the `Compliance` service, you'll have to **rework the `Trading` service** to start sending to a third queue."*

**Topic (broadcast)**: *"the publisher of the message doesn't know (or care) who the consumers are — in fact, **the team can add new consumers anytime without changing the other consumers or the producer.**"*

**Table 27-3. Trade-offs when using a topic**

| Advantage | Disadvantage |
|---|---|
| **Low coupling** | **Homogeneous message** for each consumer |
| `Trading` service generates just **one message** | Can't monitor or scale individual consumers |
| **More extensible/evolvable** | **Less secure** |
| | Less scalability options |

- The extensibility advantage has downsides: *"each consumer must consume the same message from the topic, which can lead to **stamp coupling**. And, because every consumer can read the entire message, there are security concerns: **should** everyone be able to read the entire message?"*

**The decision**: *"Now that you've done the trade-off analysis, **return to the organizational goals** and see which option is the better fit. **If security is more important, you should probably select queues. If the organization is growing rapidly and has other services interested in trades, then extensibility might be a priority, which would lead you to use topics.**"*

---

**The First Corollary applied — the hidden trade-off in code reuse.**

*"Consider code reuse. Surely this is a purely beneficial practice, right? The more code the organization can reuse, the less code it must write, saving time and duplication."*

**Two factors dictate how effective code reuse will be — architects often discover the first but miss the second:**
1. **Abstraction** — *"if you can abstract this code and use it from multiple call points, it's a good candidate for reuse."*
2. **Low volatility** — **the missed one.** *"When a team reuses a module of code that's **always changing**, this creates churn in the entire system. Every time the shared code changes, all callers must coordinate around that change. **Even if it isn't a breaking change, the team must still verify that the change hasn't broken anything.** When architectures reuse code inappropriately, teams end up chasing breaking changes all over the architecture."*

**The historical evidence**: this was a key lesson from orchestration-driven SOA (Ch 17), one of whose underlying philosophies was to reuse as much code as possible. *"From a practical standpoint, teams working in those architectures were **swimming through quicksand**: every change had the potential to send unpredictable side effects rippling out."*

**The consequence for what you should reuse**: *"the most successful reuse targets in architecture are **'plumbing'**: technology frameworks, libraries, platforms. **The portion of most applications that changes the fastest is the domain** (the motivation for writing the software in the first place), **so domain concepts are terrible candidates for reuse.**"*
- *"(Notice that this underlies the DDD principle of bounded context — no bounded contexts can reuse any of the implementation details of another bounded context.)"*

**Why we can't have nice things.** Clients regularly ask for both: *"We like microservices and distributed architectures that feature high degrees of decoupling because they allow high agility and fast deployment. **However, we also want a high degree of institutional reuse** so that teams aren't constantly rewriting code."*

> *"We have to be the bearers of bad news here: **you cannot have both these things, because the way a system implements reuse is via coupling. No organization can have both decoupling and a high degree of reuse. The two things are fundamentally incompatible.**"*

## Key Takeaways
1. The job is **trade-off analysis**, not silver bullets. Build a reputation as an objective arbiter, not an evangelist — evangelism attaches your credibility to decisions that will age badly.
2. Run the method: enumerate **contextualized** factors → build the matrix → **weight against organizational goals.**
3. Never stop at the raw count of plusses. Skipping the weighting step is the **Out of Context antipattern**, and it turns correct analysis into wrong decisions.
4. When something looks like it has no trade-off, **keep looking.**
5. Reuse requires **abstraction *and* low volatility.** Reuse plumbing; never reuse the domain.
6. You cannot have both decoupling and high reuse. **Reuse is implemented via coupling.**
7. Redo the analysis every time. Dozens of variables shift between seemingly similar situations, and semipermanent decisions built on stale assumptions are dangerous.
8. Record the *why* — the trade-off analysis, the known compromises, the limitations — in ADRs alongside the diagrams. Otherwise the next architect redoes your work to understand you.
9. Stop forcing decisions into binaries. **An architecture decision is one where *every* option carries significant trade-offs.**
10. Accept the swamp of uncertainty. Even complete information often wouldn't produce a clear-cut answer.

## Parting Words

> *"How do we get great designers? Great designers design, of course."* — **Fred Brooks**
>
> *"So how are we supposed to get great architects, if they only get the chance to architect fewer than a half-dozen times in their career?"* — **Ted Neward**

**Practice via architecture katas** (companion website). *"People who use our katas often ask: is there an answer guide somewhere? Unfortunately, no."*

> *"There are no right or wrong answers in architecture — only **trade-offs**."* — Neal Ford

**Why the authors abandoned building an answer repository**: they initially kept the drawings students produced in live training, *"but we quickly gave up, because we realized that these were **incomplete artifacts**. The teams had captured **how** they implemented their solutions with drawings of topologies. **The why was much more interesting** — but while they explained the trade-offs they considered in class, they didn't have time to create architecture decision records. **Keeping just the how meant we had only half of the story.**"*

> **"Always learn, always practice, and go do some architecture!"**

## Connects To
- **Ch 1**: where the three laws and both corollaries are first stated.
- **Ch 2**: the architecture/design spectrum — the Third Law's original illustration; the queue/topic analysis first appears there.
- **Ch 5**: architecture katas.
- **Ch 9**: the fallacies behind the shared-service fault-tolerance and scalability penalties; stamp coupling.
- **Ch 17**: orchestration-driven SOA — the empirical proof of the reuse/coupling trade-off.
- **Ch 18**: bounded context as the DDD expression of "don't reuse the domain."
- **Ch 21**: ADRs — the Second Law's practical instrument.
