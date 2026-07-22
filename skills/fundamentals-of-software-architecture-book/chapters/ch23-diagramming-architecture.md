# Chapter 23: Diagramming Architecture

## Core Idea
**No matter how brilliant your technical ideas, if you can't convince managers to fund them and developers to build them, your brilliance will never manifest.** Diagramming is a critical communication skill — and the governing discipline is **representational consistency**: always show where a part sits in the whole before zooming in.

## Frameworks Introduced

- **Representational consistency** — *the practice of always showing the relationships between parts of an architecture before changing views.* Equally important in diagrams and in presentations.
  - **Why**: *"showing a portion without indicating its place within the overall architecture will confuse viewers."*
  - **How**: to describe how plug-ins relate to one another in Silicon Sandwiches, start with a diagram of the **entire topology**, then the **relationship between it and the plug-in structure**, and only then the plug-in structure itself.
  - *"Use representational consistency carefully to ensure that viewers understand the scope of the items being presented and eliminate a common source of confusion."*

- **Three tool features to look for**:

  | Feature | What it does | Why it matters |
  |---|---|---|
  | **Layers** | Link groups of items together logically and **show or hide them as needed** | Build a comprehensive diagram for a presentation but **hide overwhelming details when not directly discussing them**; also a good way to present pictures that **build incrementally** |
  | **Stencils/templates** | Amass a library of common visual components, including composites of basic shapes | **Creates consistency across an organization's architecture diagrams and makes building new diagrams faster.** The book's microservice icons exist as single items in the authors' stencil tool |
  | **Magnets** | The places on shapes where lines snap to connect automatically | Provides alignment and visual niceties. Some tools let users add their own |

- **Use layers *semantically*, not decoratively** — in ways that **contribute meaning to the overall image**:
  - **Base layer** = the **topology** of the architecture: containers, databases, dependencies, brokers, core elements. **Focus on architecture rather than implementation** — specify *"synchronous communication"* rather than naming a specific protocol.
  - **Next layer** = **implementation details**: what type of database, which communication protocols.
  - **The payoff**: *"Using layers in this manner makes diagrams extensible: it's possible to add other contextualized layers to present domain-driven design boundaries, transactional scope, or any other meta-information the architect wants to contrast against the topology."*

- **Three diagramming standards**:

  | Standard | Origin | Verdict |
  |---|---|---|
  | **UML** | Grady Booch, Ivar Jacobson, Jim Rumbaugh, 1980s, to unify their competing design philosophies | *"Supposed to be the best of all worlds, but, like many things designed by committee, failed to create much impact outside organizations that mandated its use."* **Class and sequence diagrams are still used to communicate structure and workflow; most other UML diagram types have fallen into disuse** |
  | **C4** | Simon Brown, 2006–2011, to address UML's deficiencies and modernize the approach | **A good alternative for any company seeking to standardize.** Its creators have been active for years with a huge following, and **critically, it has kept up with changes in the software development ecosystem.** Many diagramming tools contain C4 templates; the ecosystem provides tools and frameworks. Defines standards for components, lines, containers, databases, and other common artifacts |
  | **ArchiMate** | The Open Group; a portmanteau of *architecture* and *animate* | An **open source enterprise-architecture modeling language** for describing, analyzing, and visualizing architectures **within and across business domains**. A **lighter-weight** modeling language for enterprise ecosystems whose goal is to be **"as small as possible," not to cover every edge case.** A popular choice among architects |

- **The four Cs of C4**:

  | C | Contents | Audience |
  |---|---|---|
  | **Context** | The entire context of the system, **including the roles of users and external dependencies** | Everyone |
  | **Container** | The **physical (and often logical) deployment boundaries** and containers within the architecture | *"A good meeting point for operations teams and architects"* |
  | **Component** | The component view of the system | *"Most neatly aligns with an architect's view of the system"* |
  | **Class** | **Uses the same style of class diagrams as UML**, which are effective, *"so there is no need to replace them"* | Developers |

- **Diagram guidelines** — *"Every architect should build their own diagramming style, whether they use their own modeling language or one of the formal ones. It's OK to borrow from representations you think are particularly effective."*

  | Element | Guidance |
  |---|---|
  | **Titles** | Title every element **unless it's very well known to the audience**. Use **rotation and other effects** to make titles "stick" to the right thing and use space efficiently |
  | **Lines** | **Thick enough to be clearly visible.** Use arrows for directional or two-way traffic; different arrowheads may carry different semantics — **just be consistent.** **The one near-universal standard: solid lines almost always indicate synchronous communication, dotted lines asynchronous** |
  | **Shapes** | **No pervasive standard set exists** across the software development world; most architects make their own, sometimes adopted organization-wide as a standard language. *(The authors use three-dimensional boxes for deployable artifacts, rectangles for containers, and cylinders for databases — "we don't have any particular key beyond that")* |
  | **Labels** | Label every item, **especially if there is any chance of ambiguity** |
  | **Color** | *"Architects often don't use color enough"* — books were long printed in black and white, so people became accustomed to monochrome. Use it when it distinguishes artifacts. **But be careful using color to indicate critical differences: people who are colorblind or have other visual disabilities won't see the distinction. Use unique iconography *in addition to* color — just as street-crossing lights use green for go and red for stop but also show unique figures for each** |
  | **Keys** | Include one whenever shapes are ambiguous for any reason. **"An easily misinterpreted diagram is worse than no diagram at all."** |

## Anti-patterns

- **Irrational Artifact Attachment** — *"the proportional relationship between a person's irrational attachment to some artifact and how long it took the person to produce that artifact."* Spend four hours on a beautiful Visio diagram and you'll be **more** irrationally attached than if you'd invested two.
  - **The cure**: build **very ephemeral design artifacts early**, so you can throw away what's wrong. *"One benefit of the Agile approach is creating 'just-in-time' artifacts with as little ceremony and ritual as possible. This is one reason so many Agilists love index cards and sticky notes: using low-tech tools lets people throw away what's not right, freeing them to experiment and **allow the true nature of the artifact to emerge through revision, collaboration, and discussion.**"*
  - **The classic ephemeral artifact**: a cell-phone photo of a whiteboard diagram — *along with the inevitable "Do Not Erase!"*
- **Heavyweight CASE-tool thinking** — *"In the past, when heavyweight computer-assisted software engineering (CASE) tools were the norm, architects had to build elaborate models to represent simple things. They were often forced to include many useless details that were merely noise in that specific context."*

## Worked Example

**Why the tablet replaced the whiteboard** — four concrete advantages the authors list:

1. **Unlimited canvas** — it can fit as many drawings as the team might need.
2. **Copy/paste "what if" scenarios** — *"which would obscure the original if done on a whiteboard."*
3. **Already digitized** — no *"inevitable glare of whiteboard photos."*
4. **Remote work** — electronic images make it *"much easier and more collaborative."*

**The sequencing rule this illustrates**: *"Eventually, you'll need to create nice diagrams in a fancy tool, but **before you invest that time, make sure the team has iterated on the design sufficiently.**"* Low fidelity early, high fidelity late — because the cost of the artifact determines how hard it is to abandon.

*(The authors drew the original versions of every diagram in this book in **OmniGraffle**, later refined by O'Reilly illustrators — while explicitly not advocating one tool over another.)*

## Key Takeaways
1. Never show a detail view without first establishing where it sits in the whole. Representational consistency is the single most common fix for audience confusion.
2. Keep artifacts cheap and disposable early; attachment grows with the hours invested, and attachment kills objectivity.
3. Learn your tool deeply — especially layers, stencils, and magnets.
4. Layer semantically: topology on the base layer (architecture-level vocabulary only), implementation details above it, meta-information (DDD boundaries, transactional scope) above that.
5. Adopt C4 if you want a living standard; ArchiMate if you need enterprise-scale and deliberately minimal; UML only for class and sequence diagrams.
6. Honor the one real convention: **solid = synchronous, dotted = asynchronous.**
7. Never rely on color alone — pair it with iconography.
8. Include a key whenever shapes could be misread. A misinterpretable diagram is worse than none.
9. *"We encourage organizations to establish standards but allow reasonable exceptions"* — architects frequently break the rules, **especially when the standard doesn't offer a good way to represent the design.**

## Connects To
- **Ch 5**: the Silicon Sandwiches example used to demonstrate representational consistency.
- **Ch 19**: the microservices quantum diagram reproduced here to illustrate color usage.
- **Ch 21**: C4 and ArchiMate as *diagramming* standards, contrasted with ADRs as *documentation*.
- **Ch 22**: risk storming — every phase depends on a comprehensive or contextual architecture diagram.
- **Ch 25**: communication and negotiation — diagramming is one half of the architect's communication toolkit.
