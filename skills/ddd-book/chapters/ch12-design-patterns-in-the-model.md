# Chapter 12: Relating Design Patterns to the Model

## Core Idea
A subset of the classic technical design patterns can also serve as **domain patterns** — but only when the pattern says something about the *conceptual domain*, not just about the code. Using one in the domain layer means viewing it on two levels simultaneously: a technical design pattern in the code, and a conceptual pattern in the model.

## The Test for a Domain Pattern

Evans quotes the *Design Patterns* authors on their own scope:

> Point of view affects one's interpretation of what is and isn't a pattern. One person's pattern can be another person's primitive building block… The design patterns in this book are descriptions of communicating objects and classes that are customized to solve a general design problem in a particular context. [Gamma et al. 1995, p. 3]

Their motivations are presented **in purely technical terms**. A subset applies more broadly *because they correspond to general concepts that emerge in many domains*.

> **The only requirement is that the pattern should say something about the conceptual domain, not just be a technical solution to a technical problem.**

Evans deliberately refuses to enumerate which patterns qualify: *"Although I can't think of an example of using an interpreter as a domain pattern, I'm not prepared to say that there is no conception of any domain that would fit."*

## Frameworks Introduced

- **STRATEGY (a.k.a. POLICY)** as a domain pattern:
  > *[Design Patterns definition]* Define a family of algorithms, encapsulate each one, and make them interchangeable. STRATEGY lets the algorithm vary independently from clients that use it.
  >
  > *[Evans' domain restatement]* Factor the varying part of a process into a separate "strategy" object in the model. **Factor apart a rule and the behavior it governs.** Implement the rule or substitutable process following the STRATEGY design pattern. Multiple versions of the strategy object represent different ways the process can be done.
  - When to use: when a domain process has more than one legitimate way of being done, and describing the options is making the process definition "clumsy and complicated," with the real behavioral alternatives obscured by being mixed in with the rest of the behavior.
  - **The shift in emphasis**: "Whereas the conventional view of STRATEGY as a design pattern focuses on the ability to **substitute different algorithms**, its use as a domain pattern focuses on its ability to **express a concept**, usually a process or a policy rule."
  - **The design pattern's consequences still fully apply**, because you are still using a STRATEGY:
    - *Modeling concern* (per Gamma et al.): clients must be aware of the different STRATEGIES.
    - *Pure implementation concern*: STRATEGIES can increase object count — reduce overhead by implementing them as **stateless objects that contexts can share**.
    - "The extensive discussion of implementation approaches in *Design Patterns* all applies here. Our motivations are partially different, which will affect some choices, but the experience embedded in the design pattern is at our disposal."

- **COMPOSITE** as a domain pattern:
  > *[Design Patterns definition]* Compose objects into tree structures to represent part-whole hierarchies. COMPOSITE lets clients treat individual objects and compositions of objects uniformly.
  >
  > *[Evans' domain restatement]* Define an abstract type that encompasses all members of the COMPOSITE. Methods that return information are implemented on containers to return aggregated information about their contents. "Leaf" nodes implement those methods based on their own values. Clients deal with the abstract type and have no need to distinguish leaves from containers.
  - When to use: when an important object is composed of parts made of parts — occasionally nesting to arbitrary depth — **and there is a sense in which the parts are the same kind of thing as the whole, only smaller.** (In some domains each level is genuinely conceptually distinct; then COMPOSITE does not apply.)
  - **The qualifying questions, asked before applying any design pattern in the domain**: *"Is the pattern idea really a good fit for the domain concept? It might be convenient to move recursively through some associated objects, but **is there a true whole-part hierarchy? Have you found an abstraction under which all the parts truly are the same conceptual type?**"*
  - Costs of *not* having it, when the relatedness is real: common behavior duplicated at each level; rigid nesting (containers can't contain containers at their own level; the number of levels is fixed); clients dealing with different levels through different interfaces despite caring about no conceptual difference; and very complicated recursion to aggregate information.
  - **The part designers usually skip**: "This is a relatively obvious pattern on the structural level, but designers often do not push themselves to flesh out the **operational** level of the pattern. The COMPOSITE offers the same behavior at every structural level, and meaningful questions can be asked of small or large parts that transparently reflect their makeup. **That rigorous symmetry is the key to the power of the pattern.**"

- **FLYWEIGHT as the counterexample** — a design pattern with **no correspondence** to the domain model.
  - When a limited set of VALUE OBJECTS is used many times (electrical outlets in a house plan, Ch 5), implementing them as FLYWEIGHTS may make sense. That is an **implementation option available for VALUE OBJECTS and not for ENTITIES** — nothing more.
  - Contrast with COMPOSITE, "in which conceptual objects are composed of other conceptual objects. In that case, the pattern applies to **both model and implementation, which is an essential trait of a domain pattern.**"

## Key Concepts
- **Design pattern vs. domain pattern** — the same pattern viewed technically vs. as a statement about the domain.
- **STRATEGY / POLICY** — a factored-out varying process or rule, named for the business concept it expresses.
- **COMPOSITE** — a uniform whole-part hierarchy where parts and wholes share a conceptual type.
- **FLYWEIGHT** — a purely implementational sharing optimization for VALUE OBJECTS.

## Mental Models
- **Read a design pattern twice**: once as code structure, once as a claim about the domain. Only if the second reading holds does it belong in the model.
- **"Factor apart a rule and the behavior it governs."** The most compact statement of STRATEGY-as-domain-pattern.
- **Apply a design pattern only when it is needed.** "Before we needed those route segments and distinct door legs, we were doing just fine without COMPOSITE."
- **A static class diagram is not the model.** After introducing COMPOSITE, the class diagram said *less* about how door legs and segments fit together — "But the model is more than a static class diagram. We'll convey assembly information through other diagrams and through the (now much simpler) code."

## Worked Example — Route-Finding Policies (STRATEGY)

**Setting**: a `Route Specification` is passed to a `Routing Service` that constructs a detailed `Itinerary` satisfying it. The SERVICE is an optimization engine tunable to find either the **fastest** or the **cheapest** route.

**The problem with a tuning flag**: "a detailed look at the routing code would reveal conditionals in every computation, making the decision between fastest or cheapest appear all over the place. More trouble will come when new criteria are added."

**The move**: separate the tuning parameters into STRATEGIES — a `Leg Magnitude Policy` passed into the `Routing Service` as a parameter. The service now handles **all requests in the same, unconditional way**, looking for a sequence of `Legs` with a low magnitude as computed by the policy.

**What this buys, at two levels:**
- *Application versatility (the classic STRATEGY benefit)*: behavior can be controlled and extended by installing a different policy. Fastest and cheapest are only the obvious ones — combinations balancing speed and cost are likely, and there may be entirely different factors, such as **a bias toward booking cargo on the company's own transports rather than subcontracting to other shipping companies.** These could have been done without STRATEGIES, "but the logic would have wound through the internals of the Routing Service and bloated its interface."
- *Domain expression (the reason it's a domain pattern)*: "A fundamentally important rule in the domain — the basis of choosing one `Leg` over another when building an `Itinerary` — is now explicit and distinct. It conveys the knowledge that a specific attribute (potentially derived) of an individual leg, **boiled down to a single number**, is the basis for routing."

And it yields a sentence in the UBIQUITOUS LANGUAGE that defines the service's behavior:

> **The `Routing Service` chooses an `Itinerary` with a minimum total magnitude of the `Legs` based on the chosen STRATEGY.**

**Evans' own note on the limits of the illustration**: this discussion implies the `Routing Service` actually evaluates Legs as it searches. That is conceptually straightforward and would make a reasonable prototype, but is **probably unacceptably inefficient**. Ch 14 reuses the same interface with a completely different implementation.

## Worked Example — Shipment Routes Made of Routes (COMPOSITE)

**The initial model**: a `Route` is an arbitrary, undifferentiated string of `Legs`. The team builds Routes from booking requests and processes the Legs into an operational plan for step-by-step cargo handling. It works.

**The discovery**: the domain experts see a route as **a sequence of five logical segments**, not an undifferentiated string. These subroutes "may be planned at different times by different people, so they have to be viewed as distinct." And on closer inspection **the "door legs" are quite different** — locally hired trucks or even customer haulage, versus the elaborately scheduled rail and ship transports.

**The cost of modeling the distinctions naively**: "Structurally the model isn't so bad, but **the uniformity of processing the operational plan is lost**, so the code, or even a description of behavior, becomes much more complicated." Any traversal of a route now involves multiple collections of different types of objects.

**Enter COMPOSITE** — and note that Evans validates the *concept* before adopting the pattern: *"Conceptually this view is sound. **Every level of `Route` is a movement of a container from one point to another, all the way down to an individual leg.**"*

**What it restores and what it adds:**
- Generating the operational plan is simple again, as are other route-traversing operations.
- "With a route made of other routes, pieced together end to end to get from one place to another, you can have route implementations of varying detail. You can **chop off the end of a route and splice on a new ending**, you can have **arbitrary nesting of detail**, and you can exploit all sorts of possibly useful options."
- **"Of course, we don't yet need such options."** — the honest closing note: a design pattern should be applied only when it is needed.

## Anti-patterns
- **Conditionals for tuning a domain process** — decision logic smeared across every computation, worsening with each new criterion.
- **Applying COMPOSITE for traversal convenience alone** — without a true whole-part hierarchy and a genuine shared conceptual type.
- **Stopping at COMPOSITE's structure** — implementing the tree without the uniform behavior at every level, which is where the power actually is.
- **Mistaking an implementation optimization for a domain pattern** — FLYWEIGHT is the named example.
- **Applying a pattern before it's needed** — both examples end with this caution.

## Key Takeaways
1. A design pattern earns a place in the domain layer only if it expresses a domain concept; otherwise it belongs to implementation.
2. Use STRATEGY to factor apart a rule from the behavior it governs, and name the strategy for the business policy it represents.
3. When STRATEGY is a domain pattern, judge it by expressiveness first and substitutability second — but keep all the pattern's technical consequences in view.
4. Before applying COMPOSITE, prove there is a genuine whole-part hierarchy whose parts share a conceptual type with the whole.
5. Push COMPOSITE to its operational level — the same meaningful questions answerable at every level is what makes it powerful.
6. Accept that a class diagram may say *less* after a good refactoring; the model lives in diagrams, code, and language together.
7. Don't apply a pattern until the domain demands it.

## Connects To
- **Ch 1 (Knowledge Crunching)**: the Overbooking **Policy** — STRATEGY adopted for its *meaning* rather than for substitutability, the same move made here.
- **Ch 5 (Model Expressed in Software)**: ENTITY vs. VALUE OBJECT determines whether FLYWEIGHT is even available; SERVICE is the `Routing Service`.
- **Ch 7 (Extended Example)**: `Route Specification`, `Itinerary`, and the deferred question of who derives `Enterprise Segment` — resolved with a STRATEGY object.
- **Ch 9 (Making Implicit Concepts Explicit)**: "processes as domain objects" — STRATEGY is the named technique when there's more than one way to carry a process out.
- **Ch 10 (Supple Design)**: COMPOSITE SPECIFICATION, and CLOSURE OF OPERATIONS in the composite Route.
- **Ch 11 (Applying Analysis Patterns)**: the companion chapter for conceptual, rather than technical, published patterns.
- **Ch 14 (Maintaining Model Integrity)**: the same `Routing Service` interface with a completely different implementation.
- **Gamma et al. 1995** (STRATEGY, COMPOSITE, FLYWEIGHT).
