# Chapter 24: Making Teams Effective

## Core Idea
The architect's job is to build a **"room"** — constraints neither too tight nor too loose — for the development team to work in, and to calibrate their own involvement to five measurable factors. **Making teams productive is one of the ways successful architects differentiate themselves.**

## Frameworks Introduced

- **Collaboration over handoff.** Traditionally, architects analyze business requirements to extract characteristics, select styles, and create logical components; developers then create class diagrams, build UI screens, and write and test code. **The problem is the unidirectional arrow through the virtual and physical barrier between them**: *"Architects' decisions don't always make it to the development team, and when development teams change the architecture, it rarely gets back to the architect. In this model, because the architect is so disconnected, the architecture rarely accomplishes its goals."*
  - **The fix**: architect and development team on **the same virtual team**, with **strong bidirectional communication** — which also lets the architect **mentor and coach**.
  - **Why it's non-negotiable now**: *"Unlike with the static, rigid old-school waterfall approaches, today's software architectures change and evolve with nearly every iteration."*

- **Constraints and Boundaries — the "room" metaphor.** One of the architect's roles is to **create and communicate the constraints within which developers implement the architecture.**

  | Room size | Cause | Consequence |
  |---|---|---|
  | **Too small** | Too many constraints | Developers can't access many of the tools, libraries, and practices they need. **Causes frustration, and usually results in developers leaving the project for happier and healthier environments** |
  | **Too big** | Constraints too loose, or none at all | Too many choices, **forcing the development team to essentially take on the architect's role** and make all the important architectural decisions. Lacking guidance they perform too many proofs of concept, struggle over design decisions, and become **unproductive, confused, and frustrated** |
  | **Appropriate** | The effective architect | The team has everything it needs |

- **The Three Architect Personalities**:

  | Personality | Boundaries | Behavior |
  |---|---|---|
  | **Control-freak architect** | Too tight | Tries to control **every detail**; decisions are too fine-grained and low-level |
  | **Armchair architect** | Too loose | Hasn't coded in a very long time (if ever), **doesn't account for implementation details**, is disconnected and rarely around — *"simply moving on to the next project after completing the initial architecture diagrams"* |
  | **Effective architect** | Appropriate | Creates appropriate constraints, ensures team members work well together, provides the right guidance, makes sure the team has the correct tools and technologies, and **removes roadblocks** |

  - **The control freak in detail**: might restrict downloading useful or necessary open source libraries, place tight restrictions on naming conventions, class designs, and method lengths, or **write pseudocode for developers to implement — "essentially stealing the art of programming away from the developers. Developers find this frustrating and often lose respect for the architect."**
    - **Why it's an easy trap, especially for new architects**: the architect's role is to create the **logical components** and determine how they interact; **the developers' role is to determine how best to implement them, using class diagrams and design patterns.** New architects, accustomed to creating class diagrams and selecting patterns *as developers*, find the temptation hard to resist.
    - **The `Reference Manager` example**: the architect's job is to identify the logical component, determine its core operations (`GetData`, `SetData`, `ReloadCache`, `NotifyOnUpdate`), and identify which components interact with it. **A control-freak architect might additionally decide it should use a parallel loader pattern with an internal cache of a particular data structure. That might be an effective design — "but it's not the only design, and, more importantly, it's not the architect's job."**
    - **The caveat**: *"sometimes architects need to play the role of control freak, depending on the complexity of the project and the team's skill level."*
  - **The armchair architect in detail**: some are *"simply in way over their heads."* The diagnosis is brutal: *"What do developers do? They write source code. **Writing source code is really hard to fake; either you can write source code or you can't.** What does an architect do? No one knows! Draw lots of lines and boxes? **It's all too easy to fake it as an architect.**"*
    - **The two-box diagram**: an armchair architect designing a stock-trading system produces a diagram with one box for the trading system and one for the trade compliance engine. *"There's nothing **wrong** with this architecture — it's just too high-level to be of any use to anyone."*
    - **Three indicators**: (1) not fully understanding the business domain, business problem, or technology being used; (2) not enough hands-on experience developing software; (3) not considering the implications of a given implementation — complexity, maintenance, testing.
    - **The warning sign**: *"When an architect finds that they don't have time for the development teams implementing the architecture (or simply chooses not to spend time with them)."*
    - **Few architects intend it** — *"it just 'happens' when they get spread too thin between projects or teams and lose touch with the technology or the business domain."* The cure: get more involved in the project's technologies and build a stronger understanding of the business domain.

- **Elastic Leadership — the Five Involvement Factors.** *(Concept widely evangelized by Roy Osherove; the authors adapt it for architecture.)* Each factor scores **+20 (more involvement, toward control freak) or −20 (less, toward armchair)**:

  | Factor | More involvement (+20) | Less involvement (−20) |
  |---|---|---|
  | **Team familiarity** | New team members — the architect must **facilitate collaboration and reduce cliques** | Members know each other well and can **self-organize** |
  | **Team size** | Large (>12 developers) | Small (≤5) |
  | **Overall experience** | Mostly junior — requires **mentoring** | Mostly senior — the architect becomes **a facilitator rather than a mentor** |
  | **Project complexity** | Highly complex — the architect must be available to assist | Relatively simple and straightforward |
  | **Project duration** | Long (2 years) | Short (2 months) |

  - **Assess technology experience separately from business-domain experience** if the domain is particularly complex.
  - **The counterintuitive one — project duration.** For a **two-month** project: *"Two months is not a lot of time to qualify requirements, experiment, develop code, test every scenario, and release. The architect should act more like an armchair architect; **the development team already has a keen sense of urgency, and a control-freak architect would just get in the way and delay the project.**"* For a **two-year** project: *"the developers are more relaxed, not feeling a sense of urgency. They're likely to be planning vacations and taking long lunches. Thus the architect is needed to ensure the project moves along on schedule and that **the team accomplishes the most complex tasks first**."*
  - **Reassess continually.** Architects use these at the start to plan, *"but as the project progresses, their level of involvement usually changes."*
  - **The scale is not exact**, and some factors may carry more weight than others — *"the metrics can easily be weighted or modified to suit a particular situation."*

- **The Three Team Warning Signs** — how to tell a team is too large:

  | Sign | Definition | How the architect detects and responds |
  |---|---|---|
  | **Process loss** (**Brooks's Law**, Fred Brooks, *The Mythical Man-Month*) | *"The more people you add to a project, the more time the project will take."* **Group potential** is the collective effort of everyone; **actual productivity is always less than potential** — the difference is process loss | **Detect**: frequent **merge conflicts** when pushing code, indicating people are working on the same code and getting in each other's way. **Respond**: look for **areas of parallelism** and put people on separate services or areas. **Anytime a project manager proposes adding a team member, look for opportunities to create parallel work streams — if you find none, notify the manager that the addition could have a negative impact** |
  | **Pluralistic ignorance** | *"When everyone privately rejects a norm, but agrees to it because they think they are missing something obvious."* **The larger the group, the less willing people are to confront others** | **Detect**: during meetings, **observe facial expressions and body language** for masked skepticism. **Respond**: act as facilitator — **interrupt to ask a skeptic what they think, and support them when they speak up, even if the person is wrong. "The point is to make sure everyone feels it is a safe enough environment to speak up"** |
  | **Diffusion of responsibility** | As teams grow, growth negatively impacts communication | **Detect**: **team members are confused about who is responsible for what, and things are getting dropped** |

  - **The pluralistic ignorance example**: most of a large team agrees messaging is the best solution between two remote services. One person thinks it's silly **because of a secure firewall between them** — but publicly agrees, **afraid they're missing something obvious.** *"On a smaller team, they might have spoken up, prompting the team to land on another protocol (such as REST) for a better solution."*
    - **The folk source**: Hans Christian Andersen's *"The Emperor's New Clothes"* — con artists convince the king his invisible clothes are visible only to the worthy; the king struts nude and his subjects, **afraid of being considered unworthy**, praise them, until a child calls out the truth.
  - **The diffusion-of-responsibility image**: someone stranded beside a broken-down car. **On a small country road in a small community, maybe everyone who passes stops.** On a busy highway in a large city, **thousands of cars drive by** — everyone assumes the motorist has already called for help or that someone else in the crowd will help. *"However, in most of these cases, help is not on the way, and the motorist is stuck with a dead or forgotten cell phone."*

- **Checklists** — *"Airline pilots use checklists on every flight. Even the most experienced veterans have checklists for takeoff, landing, and thousands of other situations… because one missed setting (such as forgetting to set the flaps to 10 degrees before takeoff) can mean the difference between a safe flight and a disaster."*
  - **The evidence**: Atul Gawande, *The Checklist Manifesto* — alarmed at high staph infection rates, he created surgical checklists. **Infection rates in hospitals using them fell to near zero, while rates in control hospitals continued to rise.**
  - **When NOT to use a checklist**:
    - **Processes with a procedural flow of dependent tasks.** Creating a database table is a *sequence* — the table can't be verified before the form is submitted. That's a procedure, not a checklist.
    - **Simple, familiar processes executed frequently without error.**
  - **Good candidates**: processes **without a set procedural order or dependent tasks**, and those where **people frequently skip steps or make errors**.
  - **The Law of Diminishing Returns**: *"Architects often go overboard once they find checklists make teams more effective. **The more checklists the architect creates, the less likely developers are to use them.**"* Keep each as small as possible while capturing all necessary steps — **developers generally will not follow overly long checklists.** *"If any of the tasks can be automated, automate them and remove them from the checklist."*
  - **Note: "Don't worry about stating the obvious in a checklist. The obvious stuff is what usually gets missed."**

- **The Three Recommended Checklists**:

  | Checklist | Purpose | Contents |
  |---|---|---|
  | **Developer code-completion** | Establishes the **"definition of done"** — *"if everything in the checklist is complete, the developer can say they are actually done"* | Coding and formatting standards not covered by automated tools · frequently overlooked items (such as **absorbed exceptions**) · project-specific standards · special team instructions or procedures |
  | **Unit and functional testing** | *"Perhaps one of the best checklists."* Covers the **unusual and edge cases developers tend to forget.** Its purpose: when the developer finishes it, **the code is essentially production ready** | Special characters in text and numeric fields · minimum and maximum value ranges · unusual and extreme test cases · missing fields. **Whenever QA finds a code issue based on a particular test case, add that test case to this checklist** |
  | **Software release** | *"Releasing software into production is perhaps one of the most error-prone points in the software development lifecycle."* Avoids failed builds and deployments, significantly reducing release risk. **The most volatile of the three** | Configuration changes in servers or external configuration servers · third-party libraries added (JAR, DLL) · database updates and migration scripts. **Anytime a build or deployment fails, analyze the root cause and add a corresponding entry — so it's verified next time and the problem never recurs** |

  - **On the testing checklist's organizational value**: *"Developers sometimes don't know where to start when writing unit tests or how many they should write."* In organizations where testing and development are separate teams, **it bridges the gap** — the more complete the developers' testing, the more it **frees testing teams to focus on business scenarios not covered in the checklists.**

- **The Hawthorne Effect** — *"the tendency for people who know they are being observed or monitored to change their behavior, generally to do the right thing."* **The effect doesn't require actual monitoring so much as a perception** — *"many employers mount non-functioning cameras in highly visible areas, while others install website monitoring software that they rarely check."*
  - **The hardest part of introducing checklists is getting developers to actually use them.** *"It's all too common for some developers to run out of time and simply check off all the items without actually performing the tasks."*
  - **First, try the honest routes**: talk with the team about the difference checklists make, have them read *The Checklist Manifesto*, ensure everyone understands the reasoning behind each checklist, and **have them decide collaboratively what should and shouldn't be on a checklist — creating a sense of ownership.**
  - **When all else fails**: tell the team that because checklists are critical to productivity, **all checklists will be verified.** *"In reality, occasional spot-checks are all that's needed; developers will be much less likely to skip items or falsely mark them as completed."*

- **Providing Guidance through design principles — the layered stack.** Teams have lots of questions about the **layered stack** (the collection of third-party libraries making up the application): which libraries are OK, which aren't, and **whether or when they can decide for themselves.**
  - **Two questions to require of any proposed library**:
    1. **Are there any overlaps between the proposed library and the system's existing functionality?** — guides developers to check whether existing functionality already covers it. *"When developers ignore this activity (which sometimes happens), they can end up creating lots of duplicate functionality, particularly in large projects and teams."*
    2. **What is the justification for using the proposed library?** — ask for **both a technical and a business justification**, *"in part because this technique helps make developers aware of the need to provide business justifications."*
  - **Three library categories and who decides**:

    | Category | Examples | Decision authority |
    |---|---|---|
    | **Special purpose** | Rendering PDFs, scanning barcodes — *"circumstances that do not warrant writing custom software"* | **Developers decide without consulting the architect** |
    | **General purpose** | Wrappers on top of the language API — Apache Commons, Guava for Java | **Developers analyze overlap, provide justification, and recommend — but the architect approves** |
    | **Framework** | Persistence (Hibernate), inversion of control (Spring) — *"they make up an entire layer or structure of the application and are **highly invasive**"* | **Entirely the architect's responsibility — development teams shouldn't even perform analysis** |

## Worked Examples

**Scenario 1 — an experienced small team on a short simple project:**

| Factor | Value | Rating |
|---|---|---|
| Team familiarity | New team members | **+20** |
| Team size | Small (4 members) | −20 |
| Overall experience | All experienced | −20 |
| Project complexity | Relatively simple | −20 |
| Project duration | 2 months | −20 |
| **Accumulated** | | **−60 → armchair** |

**Interpretation**: limit involvement in daily interactions, **facilitating but staying out of the team's way.** Be there to answer questions and make sure the team is on track, *"but for the most part be largely hands-off and let the experienced team do what they do best — develop software quickly."*

**Scenario 2 — a large junior team on a complex six-month project:**

| Factor | Value | Rating |
|---|---|---|
| Team familiarity | Know each other well | −20 |
| Team size | Large (12 members) | **+20** |
| Overall experience | Mostly junior | **+20** |
| Project complexity | High complexity | **+20** |
| Project duration | 6 months | −20 |
| **Accumulated** | | **+20 → control freak side** |

**Interpretation**: take on a **mentoring and coaching role**, fairly involved in day-to-day activities — **but not so much as to disrupt the team.**

---

**The impact of business justifications — the Scala story.** One of the authors led a complex Java project with a large team. One member was **obsessed with Scala** and desperately wanted to use it. *"Their desire to use Scala ended up becoming so disruptive that **two key team members declared their intention to leave the project for other, 'less toxic' environments.**"*

The author convinced them to hold off, then told the Scala enthusiast **he would support using Scala *if* the enthusiast provided a business justification for the costs of the training and rewriting involved.** The enthusiast was ecstatic and left the meeting yelling, *"Thank you — you're the best!"*

**The next day** the enthusiast came in *"completely transformed"* and began by humbly saying **"Thank you."** They had come up with **every technical reason in the world to use Scala — and none of those technical advantages had any business value in terms of cost, budget, and timeline.** They realized two things: **the increase in cost, budget, and timeline would provide no benefit whatsoever**, and **they'd been disrupting the team.**

**Outcome**: the enthusiast *"transformed into one of its best and most helpful members. Being asked to provide a business justification for something they wanted increased their awareness of the business's needs, making them a better software developer and making the team stronger and healthier. **The two key developers who'd been planning on leaving stayed on the team.**"*

**Why this worked**: the architect didn't refuse, didn't argue technically, and didn't pull rank. **He set a condition the developer could evaluate honestly for themselves** — and the developer's own analysis produced the answer, along with self-awareness the architect could never have imposed.

## Key Takeaways
1. Break the barrier between architect and development team; a unidirectional handoff is why architectures fail to accomplish their goals.
2. Size the "room" deliberately. Too tight and developers leave; too loose and they become accidental architects.
3. Score the five involvement factors at project start and **reassess continually** — your correct level of involvement changes.
4. Remember the counterintuitive one: **short projects need *less* architect involvement, long ones need more.**
5. Define components and their operations; let developers own the internal design. That boundary is what separates effective from control-freak.
6. Watch for the three team-size warning signs — merge conflicts (process loss), masked skepticism (pluralistic ignorance), and dropped work with unclear ownership (diffusion of responsibility).
7. Actively invite the skeptic to speak, and back them even when they're wrong. Safety is what makes dissent available.
8. Checklist only what has no dependency order and is frequently gotten wrong. Automate what you can and delete it from the checklist.
9. State the obvious in checklists — the obvious is what gets missed.
10. Build checklist compliance through ownership first, spot-checks (the Hawthorne effect) second.
11. Require **business** justifications from developers, not just technical ones. It changes how they think.
12. Publish who decides what: special-purpose libraries to developers, general-purpose to the architect for approval, frameworks entirely to the architect.
13. *"Some question architects' role in such activities, insisting this work should be assigned to the development or project manager. **We strongly disagree.**"*

## Connects To
- **Ch 2**: the Bottleneck Trap and staying hands-on — the antidote to becoming an armchair architect.
- **Ch 6**: *The Checklist Manifesto* is also the framing for fitness functions.
- **Ch 9**: Conway's Law and Team Topologies — the organizational counterpart to this chapter.
- **Ch 21**: business justification as the cure for the Groundhog Day antipattern — the same principle applied upward instead of downward.
- **Ch 25**: negotiation and leadership skills in depth.
