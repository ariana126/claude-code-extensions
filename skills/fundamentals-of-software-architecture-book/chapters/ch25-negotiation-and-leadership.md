# Chapter 25: Negotiation and Leadership Skills

## Core Idea
**Almost every decision an architect makes will be challenged** — by developers who think they know more, by architects who think they have a better idea, and by stakeholders who think it's too expensive or slow. **About 50% of being an effective software architect is people skills.** The techniques here are how you win those challenges without spending your credibility.

## Frameworks Introduced

- **Negotiating with business stakeholders — four techniques, in order of use**:

  | Technique | Detail |
  |---|---|
  | **Read the buzzwords** | *"Pay attention to the buzzwords and jargon people use, even if they seem meaningless. They often contain clues."* "I needed it yesterday" → **time to market matters**. "This system must be lightning fast" → **performance**. "Zero downtime" → **availability**. *"Effective architects read between the lines of such exaggerated statements to identify the stakeholder's real concerns."* |
  | **Gather information first** | *"Gather as much information as possible **before** entering into a negotiation"* — including whether the stakeholder actually understands what they're asking for |
  | **Divide and conquer** | Sun Tzu, *The Art of War*: *"If his forces are united, separate them."* **Qualify the requirement down to the specific areas that genuinely need it.** This reduces the scope of the difficult, costly requirement — and the scope of the negotiation |
  | **Qualified cost and time — last resort** | *"We've seen too many negotiations start off on the wrong foot due to opening statements like 'That's going to cost a lot of money' or 'We don't have time for that.'"* Money and time matter, **but try other justifications and rationalizations that matter more before you bring them up** |

- **Table 25-1. The nines of availability** — the single most useful table in stakeholder negotiation:

  | Percentage uptime | Downtime per year (per day) |
  |---|---|
  | 90.0% (one nine) | 36 days 12 hrs (2.4 hrs) |
  | 99.0% (two nines) | 87 hrs 46 min (14 min) |
  | 99.9% (three nines) | 8 hrs 46 min (86 sec) |
  | 99.99% (four nines) | 52 min 33 sec (7 sec) |
  | 99.999% (five nines) | 5 min 35 sec (1 sec) |
  | 99.9999% (six nines) | 31.5 sec (86 ms) |

  - **Why the table wins the argument**: *"Stating these goals in hours and minutes (or, in this case, seconds) is a much better way to have the conversation than sticking with the 'nines' vernacular, because it brings some actual metrics and quantified numbers into the discussion."*

- **Negotiating with other architects**:
  - **Demonstration defeats discussion.** *"Rather than arguing over REST versus messaging, **demonstrate** why messaging would be better in this specific environment. Because every environment is different, simply Googling it rarely yields the correct answer. But if you compare the two options in a production-like environment and show them the results, you might be able to avoid an argument entirely."*
  - **Avoid being overly argumentative or letting things get personal.** *"Calm leadership, combined with clear and concise reasoning, will almost always win a negotiation."* **Once things get personal or heated, stop the negotiation and re-engage later when both parties have calmed down.** *"Architects argue from time to time, but if you stay calm and project leadership, the other person will usually back down."*

- **Negotiating with developers — three techniques**:
  1. **Provide justification rather than dictating from on high** (the cure for the **Ivory Tower** antipattern, where architects give orders without regard for the team's opinions or concerns — *"this usually leads to the team losing respect for the architect and can eventually cause the team's dynamics to break down altogether"*).
     - **State the reason FIRST.** *"Most people tend to stop listening as soon as they hear something they disagree with. Stating the reason before the demand ensures that the developer will hear the architect's justification."*
     - **Depersonalize the demand**: say **"this means"** rather than **"you must"** — turning a demand into a simple statement of fact.
  2. **Have the developer arrive at the solution on their own** — see the worked example.
  3. **Turn a request into a favor** — *"In general, human beings dislike being told what to do, but want to help others."*

- **The 4 Cs of architecture leadership**: **communication, collaboration, clear, concise.** *(Not to be confused with the four Cs of the C4 diagramming model.)* Focusing on these *"helps an architect gain the team's respect and helps make them the go-to person on the project for questions, advice, mentoring, coaching, and leadership."*
  - **Their purpose is to prevent accidental complexity.** **Essential complexity** = *"we have a hard problem"* (six nines of availability really is 86 ms of unplanned downtime a day). **Accidental complexity** = *"we have made a problem hard."*
  - > *"Developers are drawn to complexity like moths to a flame — frequently with the same result."* — Neal Ford
  - **Why architects add it**: *"sometimes to prove their worth when things seem too simple, or to guarantee that they are always kept in the loop on decisions, or even to maintain job security. Whatever the reason, **introducing accidental complexity into something that does not have to be complex is one of the best ways to lose respect and become an ineffective leader and architect.**"*

- **Be pragmatic, yet visionary** — *"it takes a fairly high level of maturity and significant practice to accomplish."*
  - **Visionary** = thinking about or planning the future with imagination or wisdom; applying **strategic thinking** so the architecture remains **vital** (valid and useful) for a long time. **The failure mode**: becoming too theoretical, *"creating solutions that are too difficult to implement — or even understand."*
  - **Pragmatic** = dealing with things sensibly and realistically based on **practical rather than theoretical** considerations. Being pragmatic means accounting for: **budget constraints and cost factors · time constraints · the development team's skill set and skill level · the trade-offs and implications of each decision · the technical limitations of any proposed design.**
  - **Why the balance earns respect**: *"Business stakeholders appreciate visionary solutions that fit within a set of constraints, and developers appreciate having a practical (rather than theoretical) solution to implement."*

- **Leading by example, not by title** — *"Bad software architects 'pull rank,' using their title to get people to do things."*
  - **The military story**: a captain, largely removed from the troops, commands them forward to take a difficult hill. **The soldiers, full of doubt, look for confirmation from the lower-ranking sergeant.** The sergeant nods slightly, and **the soldiers immediately move forward with confidence.** *"Rank and title mean very little when it comes to leading people."*
  - **Gerald Weinberg**: *"No matter what the problem is, it's a people problem."* *"Most people think that solving technical issues has nothing to do with people skills and everything to do with technical knowledge. While technical knowledge is certainly necessary, it's only a part of solving any problem."*
  - **How to shut down a whole team in one sentence**: a developer suggests something and the architect responds, *"Well, **that's** a dumb idea."* — *"Not only will that developer not make any more suggestions, but now none of the other developers dare to say anything. The architect has just shut down collaboration across the entire team."*

- **Language patterns that build or destroy collaboration**:

  | Destroys | Builds |
  |---|---|
  | "You must…" | "This means…" |
  | "What you need to do is…" | **"Have you considered…?"** |
  | "I'm going to need you to…" | "I'm in a real bind… is there any way you can…?" |
  | *(no name)* | **Use the person's name** |

  - **On "have you considered"**: *"turns the command into a question, placing control back in the developer's hands so that they can have a collaborative conversation with the architect. **How you use language is vitally important to building a collaborative environment.**"*
  - **On names**: *"Using a person's name and proper pronouns during conversations or negotiations can help build respect and healthy relationships. Not only do people like hearing their own names, but it creates a sense of familiarity."* **Practice remembering names by using them frequently. If a name is hard to pronounce, research the correct pronunciation and practice it until it is perfect** — *"we like to repeat it back and ask if we're pronouncing it correctly. If it's not correct, we repeat this process until we get it right."*
  - **Facilitate collaboration between others, not just with yourself**: *"If you witness a team member using demanding or condescending language, take them aside and coach them on using collaborative language."*

- **Physical professionalism**:
  - **Handshakes** — *"lets both people know they are friends, not foes, and forms a bond."* **Firm but not overpowering. Make eye contact — "looking away while shaking someone's hand is a sign of disrespect, and most people will notice." Two or three seconds, no longer. Don't go overboard** — shaking everyone's hand every morning *"is weird enough to make people uncomfortable."* **Be aware of culture**: acceptable in the US, UK, Europe, and Australia; other cultures greet differently (in Japan, *"it's about bowing and the timing of the bow"*).
  - **No hugging.** *"Hugging in a professional setting, regardless of the environment, can make people uncomfortable and could potentially even become a form of workplace harassment. The same holds true for general conduct in the workplace or when traveling with a coworker. Skip the hugs, adhere to commonsense professional conduct, and stick with handshakes."*

- **Becoming the "go-to person"**:
  - **Take initiative on technical struggles** — step in and offer help or guidance regardless of your title.
  - **And on nontechnical ones**: if a team member comes in looking depressed and bothered, *"Hey, Antonio, I'm heading over to get some coffee. Why don't we head over together?"* — then ask on the walk if everything is OK. This opens a more personal discussion and possibly a chance to mentor. **But "an effective leader will also pay attention to verbal and nonverbal signs (like facial expressions and body language) and recognize when it's time to back off."**
  - **Host periodic brown-bag "lunch and learn" sessions** on a technique or technology. *"If you are reading this book, you have some particular skill or knowledge that others don't have."* It's **not just about providing information or exhibiting technical prowess** — it's *"an opportunity to practice mentoring and public-speaking skills, and identifies you as a leader and mentor."*

- **Controlling the calendar** — two meeting types: those **imposed upon you** and those **you impose**.
  - **Meetings others call are hardest to control**, because architects must collaborate with many stakeholders and get invited to almost everything *"even if their presence isn't really needed."*
    - **Ask the organizer why you're needed.** *"If inviting you is just a way to keep you in the loop, **that's what meeting notes are for**."*
    - **Tip: ask for the meeting agenda ahead of time** to qualify whether you're needed. Also ask: **are you needed for the *whole* meeting, or just one agenda item — could you leave after it?**
    - *"Don't waste time in a meeting that you could be spending helping the development team solve problems."*
    - **Attend in place of developers or the tech lead** when both of you are invited, so the team stays focused. *"While deflecting meetings away from useful team members might increase the time **you** spend in meetings, it increases the development team's productivity and their respect for you."*
  - **Meetings you call**: keep them to an absolute minimum. **Set an agenda and stick to it; don't let an irrelevant issue disrupt it.** Ask whether the meeting is more important than the work it pulls the team away from — **could an email do?** If you must schedule one, **schedule it first thing in the morning, right after lunch, or toward the end of the day**, to minimize disruption during central work hours.
  - **Developer flow state** — *"a state of mind where the brain gets 100% engaged in a particular problem, allowing full attention and maximum creativity… hours can feel like minutes. **Pay close attention to your team's productivity flow and be sure not to disrupt it.**"* (See Mihaly Csikszentmihalyi, *Flow: The Psychology of Optimal Experience*.)

- **Physical presence**: *"Sitting in a cubicle away from the team sends the message **'I am special and should not be disturbed.'** Sitting alongside the team sends the message **'I'm an integral part of the team and available for questions or concerns.'**"* When you can't sit with them, **walk around and be seen** — *"an architect who's never visible, stuck on a different floor or always in their office, cannot possibly guide the team."* **Block off time in the morning, after lunch, or late in the day** to converse, help, answer questions, and coach. The same applies to other stakeholders — *"stopping in to say hi to the head of operations while on a coffee run is an excellent way to keep the lines of communication open."* (For remote teams: Jacqui Read, *Communication Patterns*, Part 4.)

## Worked Examples

**Scenario 1 — negotiating "five nines" down to three.** Parker, the SVP and product sponsor, insists the new global trading system must support **99.999%** availability. You know that **99.9%** suffices, because **there are two hours between global markets when trading doesn't occur.** The complication: *"Parker does not like to be wrong and doesn't respond well to being corrected, especially if they perceive it as condescending. Parker isn't technically knowledgeable, but thinks they are."*

**The sequence:**
1. **Validate the concern first** — *"I understand that availability is very important for this system."*
2. **Translate out of the "nines" vernacular into hours and minutes.** Five nines = **5 min 35 sec/year, about 1 second a day** of unplanned downtime. *"That's ambitious, costly, and, as it turns out, unnecessary."* Three nines = **86 seconds of unplanned downtime per day** — *"certainly a reasonable number, given the context of this global trading system."*
3. **If that doesn't land, divide and conquer**: does the **entire system** need five nines, or only specific areas? **This reduces the scope of the costly requirement and of the negotiation.**
4. **Only then**, qualified cost and time.

**Note what the architect never does**: correct Parker, contradict Parker, or claim expertise Parker lacks. The numbers do the arguing.

---

**Scenario 3 — the layered architecture query, two ways.**

*The failing version:*
> **Architect**: "You **must** go through the Business layer to make that call."
> **Developer**: "I disagree. It's much faster just to call the database directly."

*"Not only is this type of commanding voice demeaning, it's one of the worst ways to begin a negotiation."* Note that **the developer's response includes a reason and the architect's doesn't.**

*The working version:*
> **Architect**: "Since **change control is most important to us**, we have formed a closed-layered architecture. **This means** all calls to the database need to come from the Business layer."
> **Developer**: "OK, I get it — but in that case, how am I going to deal with these performance issues for simple queries?"

**Three things changed**: the justification came **first**, "you must" became **"this means"**, and — critically — **the developer's response shifted from disagreement to a collaborative question.** *"Now the two can engage in a collaborative conversation to find ways to make simple queries faster while still preserving the closed layers."*

---

**Letting the developer arrive at the solution — Framework X vs. Y.** You choose **Framework X** because **Framework Y doesn't satisfy the system's security requirements.** A developer strongly disagrees and insists Y is better.

Rather than argue, you tell them: **if they can show you how Framework Y addresses the security concerns, the team will use Framework Y.**

| Outcome | What happens | Why it's a win |
|---|---|---|
| **Option 1** | The developer tries and **fails** | *"In failing, they come to understand firsthand why the team can't use this framework. And because they arrive at the solution on their own, **you automatically get their buy-in** for the decision to use Framework X. You've essentially made it the developer's decision."* |
| **Option 2** | The developer **succeeds** and demonstrates it | *"You missed something in your assessment of Framework Y, and now you have a better solution to the problem (and the developer still feels involved in the decision)."* |

*"Developers are smart people with useful knowledge. Collaborating with the development team is how architects gain their respect — and their assistance in finding better solutions. **The more developers respect an architect, the easier it will be for the architect to negotiate with them.**"*

---

**Turning a request into a favor — splitting the payment service.**

*The failing version:*
> **Architect**: "**I'm going to need you** to split the payment service into five different services… That will provide better fault tolerance and scalability. It shouldn't take too long."
> **Developer**: "Sorry, I'm way too busy this iteration. I really can't do it."
> **Architect**: "Listen, this is important and it needs to be done this iteration."
> **Developer**: "Sorry, I can't. Maybe one of the other developers can do it."

*"The architect is **telling** the developer to do something they are simply too busy to do — and their demand doesn't even include the person's name!"* Note the justification was present and still failed.

*The working version:*
> **Architect**: "Hi, **Sridhar**. Listen, **I'm in a real bind**. I really need to have the payment service split into separate services for each payment type to get better fault tolerance and scalability, and **I waited too long to do it**. Is there any way you can squeeze this into this iteration? **It would really help me out**."
> **Developer** *(pausing)*: "I'm really busy this iteration, but I guess I'll see what I can do."
> **Architect**: "Thanks, Sridhar, I really appreciate the help. **I owe you one**."
> **Developer**: "No worries. I'll see that it gets done this iteration."

**Three moves**: the name (personal and familiar rather than an impersonal professional demand), the **admission of fault** ("I waited too long"), and the appeal to the **basic human urge to help others.** *"This doesn't always work, but it has a better probability of success than the first conversation."*

## Key Takeaways
1. Expect every decision to be challenged. Negotiation is not a supplement to the architect's job; it is the job.
2. Mine exaggerated buzzwords for the real underlying characteristic.
3. Translate abstract targets into concrete units — "86 seconds a day" wins arguments that "three nines" loses.
4. Save cost and time for last; leading with them poisons the negotiation.
5. Divide and conquer: qualify a costly requirement down to the parts that genuinely need it.
6. **Demonstration defeats discussion.** Build the comparison in a production-like environment.
7. Stop any negotiation that turns personal; re-engage calm. Calm leadership almost always wins.
8. Give the justification **before** the demand — people stop listening once they disagree.
9. Replace "you must" with "this means," and "what you need to do" with "have you considered."
10. When a developer disagrees, set the condition for them to prove themselves right. Both outcomes are wins.
11. Turn requests into favors, use people's names, and admit your own fault when it's real.
12. Never introduce accidental complexity to prove your worth — it's the fastest way to lose respect.
13. Balance visionary and pragmatic; stakeholders want the first, developers need the second.
14. Guard your calendar so you can guard the team's. Take the meetings so they don't have to.
15. Be physically present and visible; invisibility makes guidance impossible.

## Further Reading
- Tanya Reilly, *The Staff Engineer's Path: A Guide for Individual Contributors* (O'Reilly, 2022)
- Roger Fisher, William L. Ury & Bruce Patton, *Getting to Yes: Negotiating Agreement Without Giving In* (Penguin, 2011)
- Mihaly Csikszentmihalyi, *Flow: The Psychology of Optimal Experience* (Harper Perennial, 2008)
- Jacqui Read, *Communication Patterns* (O'Reilly, 2023) — Part 4 on remote teams

> *"The most important single ingredient in the formula of success is knowing how to get along with people."* — Theodore Roosevelt

## Connects To
- **Ch 1**: understanding and navigating organizational politics — the eighth expectation; "almost every decision an architect makes will be challenged."
- **Ch 3**: essential vs. accidental complexity.
- **Ch 5**: the Ivory Tower antipattern.
- **Ch 10**: the closed-layer justification used in the developer dialogue.
- **Ch 21**: justification as the cure for Groundhog Day — the same principle, aimed at stakeholders.
- **Ch 22**: the $50,000 → $16,000 mitigation negotiation.
- **Ch 24**: elastic leadership, checklists, and the Scala business-justification story.
