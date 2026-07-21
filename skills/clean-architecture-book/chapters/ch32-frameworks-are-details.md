# Chapter 32: Frameworks Are Details

## Core Idea
Frameworks are not architectures, though some try to be. The framework author's agenda is their own problems, not yours — so use the framework, but do not couple to it: keep it in an outer circle, behind an architectural boundary, for as long as possible.

## Frameworks Introduced
- **The Asymmetric Marriage**: The relationship between you and the framework author is extraordinarily asymmetric — you make a huge, long-term commitment to the framework; the author makes no commitment to you whatsoever.
  - When to use: at every framework adoption decision, and whenever framework documentation tells you to derive your business objects from its base classes.
  - How to reason it through: (1) note what the documentation actually asks — wrap your architecture around the framework, derive from its base classes, import its facilities into your business objects, couple as tightly as possible; (2) note that coupling is *free* for the author, who has absolute control over the framework, and *permanent* for you; (3) note there is no corresponding commitment back — no promise of direction, no promise of continuity; (4) conclude that the risk is entirely yours and price the decision accordingly.
  - Why it works: making the asymmetry explicit converts an unexamined default ("everyone uses it, so import it everywhere") into a decision with a visible cost. Failure mode: once the framework is inherited into your Entities, it isn't coming back out — the wedding ring is on your finger and it's going to stay there.
- **Don't Marry the Framework**: Use it; don't couple to it. Keep it at arm's length as a detail in one of the outer circles.
  - When to use: default posture for every third-party framework.
  - How: (1) if the framework wants you to derive your business objects from its base classes, say **no**; (2) derive **proxies** instead; (3) keep those proxies in components that are *plugins* to your business rules; (4) integrate the framework into components that plug into your core code, following the Dependency Rule; (5) delay the commitment — date the framework before taking the plunge; (6) find a way to get the milk without buying the cow.
  - Why it works: the framework stays replaceable and your business rules stay testable and portable. Failure mode: the "just this one annotation" concession — e.g. `@Autowired` sprinkled through business objects — which is coupling in the innermost circle wearing a small disguise.

## Key Concepts
- **Framework author's agenda**: Authors know their own problems and those of their coworkers and friends, and write frameworks to solve *those* problems — not yours. The overlap with your problems is why frameworks are useful at all.
- **Asymmetric marriage**: One-directional commitment — you take on all the risk and burden; the framework author takes on nothing.
- **Proxy**: A class you write that derives from the framework's base class on your behalf, so your business object doesn't have to.
- **Plugin component**: The outer-circle component where framework-derived code lives, plugged into the business rules per the Dependency Rule.
- **Main**: The dirtiest, lowest-level component in the architecture — the one place it's acceptable to know about a DI framework like Spring.
- **Frameworks you must marry**: The unavoidable ones — STL if you're using C++, the standard library if you're using Java. Normal, but still a *decision*.

## Mental Models
- Think of framework adoption as marriage: for better or worse, in sickness and in health, for richer, for poorer, forsaking all others — for the entire life cycle of the application. Not a commitment to enter lightly.
- Use "date it before you marry it": run the framework at arm's length behind a boundary long enough to learn whether it fits, and delay the irreversible commitment as long as possible.
- Think of every framework as a *detail* in the same category as the database and the web — a mechanism in an outer circle, never an organizing principle.
- Use the Entity test: if framework types, base classes, or annotations appear in your Entities, the framework is inside the innermost circle and the decision has already been made for you.

## Anti-patterns
- **Deriving business objects from framework base classes**: Frameworks tend to violate the Dependency Rule by asking to be inherited into your Entities — the innermost circle. Once in, it never leaves.
- **Sprinkling framework annotations through business objects**: `@Autowired` throughout your domain couples business rules to Spring. Use Spring to inject dependencies into `Main` instead; your business objects should not know about Spring.
- **Assuming the framework will grow the way you need**: It may evolve in a direction you don't find helpful; you may be forced into upgrades that don't help you, and find features you relied on disappearing or changing in ways hard to keep up with.
- **Outgrowing the framework while wearing the ring**: A framework that helps with early features can fight you more and more as the product matures.
- **Marrying immediately on adoption**: A new and better framework may come along that you wish you could switch to — and you can't.

## Reference Tables

| Risk | What it looks like | Countermeasure |
|---|---|---|
| Unclean framework architecture | Framework asks you to inherit its code into your Entities; violates the Dependency Rule | Derive proxies, keep them in plugin components |
| Product outgrows the framework | Early features easy, later features fight the framework | Boundary lets you extend past it or replace it |
| Framework evolves wrongly | Forced upgrades, features removed or changed | Only the plugin component tracks the framework's API |
| Better framework appears | You wish you could switch, and can't | Swap the plugin, leave the core untouched |

## Key Takeaways
1. Frameworks are not architectures. Treat every one as a detail belonging in an outer circle.
2. The marriage is asymmetric: your commitment is total, the author's is zero. Decide with that asymmetry in view.
3. When a framework asks you to derive your business objects from its base classes, say no — derive proxies and put them in plugin components.
4. Keep frameworks out of your Entities. No framework types, no framework annotations, no framework base classes in the innermost circle.
5. Use Spring for DI if you like — but wire it in `Main`, the dirtiest, lowest-level component, not throughout your business objects.
6. Some frameworks you must marry (STL, the Java standard library). That's normal, but make it an explicit decision, not a default.
7. Date before you marry: keep the framework behind an architectural boundary if at all possible, for as long as possible.

## Connects To
- **Ch 30 & 31 (Database / Web are Details)**: The same argument applied to the third category of mechanism; all three belong outside the boundary.
- **Ch 22 (The Clean Architecture) / The Dependency Rule**: Frameworks violate it by design; proxies and plugin components restore it.
- **Ch 26 (The Main Component)**: `Main` is the designated dirty component where framework knowledge is permitted.
- **Ch 11 (DIP)**: Proxying a framework base class is DIP applied to third-party code.
- **Ch 34 (The Missing Chapter)**: Compiler-enforced package boundaries are how you actually prevent framework types leaking into the core.
- **Appendix A (VRS)**: Embedded SQL and vendor-specific UNIFY calls smeared through C code — an asymmetric marriage that ended in a permanent maintenance contract.
