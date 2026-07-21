# Chapter 17: Bringing the Strategy Together

## Core Idea
The three principles of strategic design — **context, distillation, and large-scale structure** — are not substitutes for each other; they are complementary and interact in many ways. This chapter shows how they compose, how to assess a project before choosing, and — most importantly — **who gets to set the strategy and how**.

## Frameworks Introduced

- **Combining large-scale structure and BOUNDED CONTEXTS** — four configurations:
  1. **Structure within one BOUNDED CONTEXT.** The easiest to explain and a common use. Layer names and model element names are restricted to that CONTEXT. Useful in a very complicated but unified model, **"raising the complexity ceiling on how much can be maintained in a single BOUNDED CONTEXT."**
  2. **Structure organizing the CONTEXT MAP.** On many projects the greater challenge is understanding how disparate parts fit together — *what part does each play in the whole, and how do the parts relate?* Here the structure's terminology applies to the whole project (or a clearly bounded part of it).
  3. **Structure accommodating a nonconforming legacy.** *"Do you have to give up your LAYERS? No, but you have to acknowledge the actual place the legacy has within the structure."* In fact **it may help to characterize the legacy** — the SERVICES it provides may be confined to only a few layers, and *"to be able to say that the legacy system fits within particular RESPONSIBILITY LAYERS concisely describes a key aspect of its scope and role."* If accessed through a FACADE, you may be able to design each offered SERVICE to fit within one layer.
  4. **The same structure applied both within a CONTEXT and across the CONTEXT MAP.** A team on a project with a well-established map-spanning structure could choose to order their own model by the same familiar layers.
  - **The caution**: because each BOUNDED CONTEXT is its own name space, you *could* use one structure inside one context, another in a neighboring context, and a third to organize the map. **"However, going too far down that path can erode the value of the large-scale structure as a unifying set of concepts for the project."**

- **Combining large-scale structure and distillation** — two directions:
  - The structure **explains the distillation**: it clarifies the relationships within the CORE DOMAIN and between GENERIC SUBDOMAINS.
  - **The structure itself may be an important part of the CORE DOMAIN.** *"Distinguishing the layering of potential, operations, policy, and decision support distills an insight that is fundamental to the business problem addressed by the software."* This is **especially useful when a project is carved into many BOUNDED CONTEXTS, so that the model objects of the CORE DOMAIN don't have meaning over much of the project** — the structure carries the core insight where the objects can't.

- **Assessment First — six questions to start from:**
  1. **Draw a CONTEXT MAP.** Can you draw a consistent one, or are there ambiguous situations?
  2. **Attend to the use of language on the project.** Is there a UBIQUITOUS LANGUAGE? Is it rich enough to help development?
  3. **Understand what is important.** Is the CORE DOMAIN identified? Is there a DOMAIN VISION STATEMENT? **Can you write one?**
  4. **Does the technology of the project work for or against a MODEL-DRIVEN DESIGN?**
  5. **Do the developers on the team have the necessary technical skills?**
  6. **Are the developers knowledgeable about the domain? Are they *interested* in the domain?**
  - *"You won't find perfect answers, of course. **You know less about this project right now than you ever will in the future.**"* But by the time you have specific initial answers, you'll have insight into what most urgently needs doing — and the CONTEXT MAP, DOMAIN VISION STATEMENT, and other artifacts get refined as situations change.

- **Two workable styles for setting strategy** (explicitly "ignoring the old 'wisdom-from-on-high' style"):

  | Style | How it works | When it works |
  |---|---|---|
  | **Emergent Structure from Application Development** | A self-disciplined team of very good communicators operating without central authority, following EVOLVING ORDER so **"order grows organically, not by fiat."** In practice, an individual or subset with some oversight responsibility helps keep the structure unified — **best when that informal leader is a hands-on developer, "an arbiter and communicator, and not the sole source of ideas."** On XP teams Evans has seen, such leadership emerged spontaneously, often in the coach. | Requires that **the development team include at least a few people of the caliber to make design decisions affecting the whole project.** Across multiple teams: an informal committee of representatives discusses options — adopt, modify, or leave on the table. Works when there are relatively few teams, all committed to coordinating, with **comparable design capabilities** and **structural needs similar enough to be met by a single structure.** |
  | **A Customer-Focused Architecture Team** | An architecture team acting **as a peer with various application teams**, helping coordinate and harmonize large-scale structures, BOUNDED CONTEXT boundaries, and other cross-team technical issues. *"On an organization chart, this team may look just like the traditional architecture team, but it is actually different in every activity. Team members are true collaborators with development, discovering patterns along with the developers, experimenting with various teams to reach distillations, and **getting their hands dirty.**"* | Requires **a mind set that emphasizes application development.** Evans has seen it work when a project ends up with a lead architect who does most of the six essentials below. |

- **The Six Essentials for Strategic Design Decision Making:**
  1. **Decisions must reach the entire team.** *"Obviously, if everyone doesn't know the strategy and follow it, it is irrelevant."* This requirement drives people toward centralized teams with official authority — **and ironically, ivory tower architects are often ignored or bypassed**, because their lack of feedback from hands-on application of their own rules yields impractical schemes. On a project with very good communication, a strategy emerging from the application team may reach everyone more effectively, and *"it will have the authority that attaches to intelligent community decisions."* **"Be less concerned with the authority bestowed by management than with the actual relationship the developers have with the strategy."**
  2. **The decision process must absorb feedback.** Creating an organizing principle or distillation of such subtlety requires deep understanding of the project's needs and the domain's concepts — **and "the only people who have that depth of knowledge are the members of the application development team. This explains why application architectures created by architecture teams are so seldom helpful, despite the undeniable talent of many of the architects."** Strategic design doesn't itself involve writing much code, but it requires *involvement* with application teams. Evans' example: one technical architecture team **circulated its own members through the application teams using its framework** — pulling hands-on experience of developers' challenges into the architecture team while simultaneously transferring knowledge of the framework's subtleties.
  3. **The plan must allow for evolution.** *"When the highest level of decisions is set in stone, the team has fewer options when it must respond to change."* EVOLVING ORDER avoids this by emphasizing ongoing change in response to deepening insight. A harmonizing principle must grow with the project **"and it must not take too much power away from the application developers, whose job is hard enough as it is."** With strong feedback, innovations emerge as obstacles are encountered and unexpected opportunities discovered.
  4. **Architecture teams must not siphon off all the best and brightest.** Managers move the most technically talented developers to architecture and infrastructure teams to leverage their skills; developers are attracted by broader impact, "more interesting" problems, and the prestige of an elite team. **"These forces often leave behind only the least technically sophisticated developers to actually build applications. But building good applications takes design skill; this is a setup for failure. Even if a strategy team creates a great strategic design, the application team won't have the design sophistication to follow it."** Conversely, such teams **almost never include the developer with weaker design skills but the most extensive domain experience** — and strategic design is not a purely technical task. Remedies: hire more advanced designers; keep architecture teams part-time. *"Any effective strategy team has to have as a partner an effective application team."*
  5. **Strategic design requires minimalism and humility.** *"Even the slightest ill fit has a terrible potential for getting in the way."* Separate architecture teams must be especially careful — they have less feel for the obstacles they place in front of application teams, **while their enthusiasm for their primary responsibility makes them more likely to get carried away.** ("I've seen this phenomenon many times, and I've even done it. One good idea leads to another, and we end up with an overbuilt architecture that is counterproductive.") Produce organizing principles and core models *"pared down to contain nothing that does not significantly improve the clarity of the design. The truth is, **almost everything gets in the way of something**, so each element had better be worth it. **Realizing that your best idea is likely to get in somebody's way takes humility.**"*
  6. **Objects are specialists; developers are generalists.** *"The essence of good object design is to give each object a clear and narrow responsibility and to reduce interdependence to an absolute minimum. Sometimes we try to make interactions on teams as tidy as they should be in our software. **A good project has lots of people sticking their nose in other people's business.** Developers play with frameworks. Architects write application code. Everyone talks to everyone. It is efficiently chaotic. Make the objects into specialists; let the developers be generalists."*
     - **Two kinds of design activity does not mean two kinds of people.** Supple design based on a deep model is advanced work whose details are so important it must be done by someone working with the code; strategic design emerges out of application design yet needs a big-picture view possibly spanning teams. *"People love to find ways to chop up tasks so that design experts don't have to know the business and domain experts don't have to understand technology. There is a limit to how much an individual can learn, but **overspecialization takes the steam out of domain-driven design.**"*

- **The same goes for technical frameworks.** They can greatly accelerate development — freeing the application from basic services and helping isolate the domain — **but "there is a risk that an architecture can interfere with expressive implementations of the domain model and easy change. This can happen even when the framework designers had no intention of venturing into the domain or application layers."** The same biases apply: **evolution, minimalism, and involvement with the application team.** Architectures that don't follow this path *"will either stifle the creativity of application development or will find their architecture circumvented, leaving application development, for practical purposes, with no architecture at all."*

- **"Don't write frameworks for dummies."** *"Team divisions that assume some developers are not smart enough to design are likely to fail because they underestimate the difficulty of application development. **If those people are not smart enough to design, they shouldn't be assigned to develop software. If they are smart enough, then the attempts to coddle them will only put up barriers between them and the tools they need.**"* It also poisons the relationship between teams. (Evans: "I've ended up on arrogant teams like this and found myself apologizing to developers in every conversation, embarrassed by my association. I've never managed to change such a team, I'm afraid.")
  - **The distinction that matters**: *encapsulating irrelevant technical detail* is completely different from prepackaging. "A framework can place powerful abstractions and tools in developers' hands and free them from drudgery."
  - **The diagnostic test**: *"Ask the framework designers what they expect of the person who will be using the tool/framework/components. **If the designers seem to have a high level of respect for the user of the framework, then they are probably on the right track.**"*

## Key Concepts
- **Emergent structure** — strategy arising from the application team under EVOLVING ORDER, with an informal hands-on leader.
- **Customer-focused architecture team** — architects as peers and collaborators of application teams, not authorities above them.
- **Master plan** — the failure mode Alexander diagnoses; see below.
- **Organic order** — coherence emerging from shared principles applied to each act of piecemeal growth.

## Mental Models
- **Judge a strategy by the developers' relationship to it, not by its management mandate.** The authority that matters attaches to intelligent community decisions.
- **Characterize a legacy by which layers it occupies.** Rather than treating it as an exception to the structure, use the structure to describe its scope and role concisely.
- **Expect your best idea to get in somebody's way.** That expectation is what produces minimal structures.
- **Ask what a framework's designers expect of its users.** Respect for the user predicts a good framework; contempt predicts a bad one.
- **Efficient chaos beats tidy team boundaries.** Objects should be specialists; people should not.

## Worked Example — Beware the Master Plan (Alexander et al., *The Oregon Experiment*)

A group of architects — of physical buildings — led by Christopher Alexander advocated **piecemeal growth** in architecture and city planning, and explained very nicely why master plans fail:

> Without a planning process of some kind, there is not a chance in the world that the University of Oregon will ever come to possess an order anywhere near as deep and harmonious as the order that underlies the University of Cambridge.
>
> The master plan has been the conventional way of approaching this difficulty. The master plan attempts to set down enough guidelines to provide for coherence in the environment as a whole — and still leave freedom for individual buildings and open spaces to adapt to local needs. …and all the various parts of this future university will form a coherent whole, because they were simply plugged into the slots of the design.
>
> …in practice **master plans fail — because they create totalitarian order, not organic order.** They are too rigid; they cannot easily adapt to the natural and unpredictable changes that inevitably arise in the life of a community. As these changes occur… the master plan becomes obsolete, and is no longer followed. And **even to the extent that master plans *are* followed**… they do not specify enough about connections between buildings, human scale, balanced function, etc. to help each local act of building and design become well-related to the environment as a whole.
>
> …The attempt to steer such a course is rather like filling in the colors in a child's coloring book…. **At best, the order which results from such a process is banal.**
>
> …Thus, as a source of organic order, **a master plan is both too precise, and not precise enough. The totality is too precise: the details are not precise enough.**
>
> …the existence of a master plan **alienates the users** [because, by definition] the members of the community can have little impact on the future shape of their community because most of the important decisions have already been made.
>
> — *The Oregon Experiment*, pp. 16–28 (Alexander et al. 1975)

**Their alternative**: not a plan but **a set of principles for all community members to apply to every act of piecemeal growth**, so that "organic order" emerges, well adapted to circumstances.

This is the closing argument of Part IV: a large-scale structure is a *set of principles applied to each act of growth*, not a master plan.

## Anti-patterns
- **Wisdom-from-on-high architecture** — handed down before application development begins by a team with more organizational power. *"But it doesn't have to be that way. That way doesn't usually work very well."*
- **The ivory tower architect** — bypassed in practice because impractical schemes result from no feedback loop.
- **Architecture teams absorbing the best designers** — leaves the least sophisticated developers building the applications, guaranteeing the strategy can't be followed even if it's good.
- **Architecture teams excluding deep domain experience** — strategic design isn't purely technical.
- **Overbuilt architecture from enthusiasm** — one good idea leading to another until it's counterproductive.
- **Frameworks written for dummies** — underestimates application development, poisons inter-team relationships, and puts barriers between capable developers and their tools.
- **Overspecialization** — design experts who don't know the business, domain experts who don't understand technology.
- **Using different large-scale structures at every level** — erodes the structure's value as a unifying set of concepts.
- **Master plans** — too precise in the totality, not precise enough in the details, and alienating to the people who must live in them.

## Key Takeaways
1. Compose the three strategic principles rather than choosing among them — a large-scale structure can live inside one context, span the CONTEXT MAP, or do both.
2. Use the structure to describe a nonconforming legacy's role rather than exempting it; naming which layers it occupies is real information.
3. Recognize that the structure itself may *be* part of the CORE DOMAIN — especially when the CORE's model objects have no meaning across most of the project.
4. Assess before designing: map the contexts, test the language, identify the CORE, and honestly evaluate the technology, the team's skills, and their interest in the domain.
5. Prefer strategy that emerges from the application team; if you centralize, make the architects peers who write code and rotate through the teams.
6. Make sure decisions reach everyone, absorb feedback, and can evolve — and measure success by developers' actual relationship to the strategy.
7. Keep strong designers *and* domain knowledge on application teams; an effective strategy team requires an effective application team as its partner.
8. Be minimal and humble — almost everything gets in the way of something, so every element of a structure must earn its place.
9. Let objects specialize and developers generalize; "efficiently chaotic" beats tidy role boundaries.
10. Hold technical frameworks to the same standard: evolution, minimalism, application-team involvement, and respect for the developers who will use them.
11. Replace master plans with principles applied at every act of growth — organic order, not totalitarian order.

## Connects To
- **Ch 14 (Maintaining Model Integrity)**: CONTEXT MAP as the first assessment artifact; FACADE for a legacy subsystem; the political reality of strategic decisions.
- **Ch 15 (Distillation)**: CORE DOMAIN, DOMAIN VISION STATEMENT, GENERIC SUBDOMAINS — clarified by the structure and, in turn, lightening its cost.
- **Ch 16 (Large-Scale Structure)**: EVOLVING ORDER, RESPONSIBILITY LAYERS — the mechanisms this chapter assembles and governs.
- **Ch 3 (Model-Driven Design)**: HANDS-ON MODELERS — the same argument, now at the strategic scale.
- **Ch 4 (Isolating the Domain)**: architectural frameworks that constrain domain design.
- **Alexander et al. 1975** (*The Oregon Experiment*), **Extreme Programming** (the coach as emergent strategic leader).
