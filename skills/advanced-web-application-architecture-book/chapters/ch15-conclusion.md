# Chapter 15: Conclusion (Objections and trade-offs)

## Core Idea
Decoupled architecture is not for every project — but every reason people give for skipping it is weaker than it sounds. Noback answers five objections, then reframes the biggest one: what looks like over-engineering is **"just-right-engineering"**, and most web applications have been *under*-engineered.

## Frameworks Introduced

- **The five objections, and their answers:**

  | Objection | Verdict | The catch |
  |---|---|---|
  | "Not every project needs this" | **Valid** | True — but the exceptions are narrow |
  | "It won't live longer than two years" | **Conditionally valid** | "You can't always predict how long an application will live" |
  | "It's CRUD-only" | **Conditionally valid** | "Take a long and hard look before you decide" |
  | "It's a legacy application" | **Not a reason to skip** | Improve a little every day; don't ask permission for everything |
  | "I can never decouple the whole thing" | **Not a reason to skip** | "Trying to apply a good design idea everywhere is a waste of time, but not applying it anywhere is a wasted opportunity" |

- **The "no silver bullet" opening** — asked and answered honestly:
  > "Does something apply to all situations without any qualification? I think that question should always be answered with 'No'… Still, there are some practices that are demonstrably better than others."
  - His own counter-example: a single-job application that extracts URLs from the book's manuscript "really doesn't deserve to be decoupled. Maybe it's the fact that its work is purely related to infrastructure anyway. Maybe it's because it's too small to deserve the effort."

- **The short-lived-project trap** — the objection is valid only under a condition almost nobody meets.
  - "If you're **absolutely certain** the project will be discarded within a couple of years, I agree. But you can't always predict how long an application will live."
  - The failure sequence: "It may start as a so-called 'proof of concept'. Badly designed, programmed sloppily, just to help the project stakeholders prove some point. Then the business starts making money with it and the project has to survive a little longer. At some point, adding new functionality becomes really problematic."
  - **The line that isn't negotiable regardless**: "I think automated testing should never be considered 'optional'. What **is** up to you is which type of tests you'll create." Skip decoupling and you forfeit isolated testing — so write end-to-end tests instead.
  - But know what you've bought: end-to-end tests "are slow and fragile, and within a couple of years they will become a real maintenance burden."

- **The CRUD trap** — a precise definition and a precise warning.
  - Genuine CRUD: an application that "can be generated based on a configuration file which describes the models, their fields and types, and the form field types and validation rules that apply to them." Noback: "These applications exist. In fact, I've built many of them and I totally agree: they don't deserve a decoupled architecture."
  - What goes wrong when it isn't really CRUD: "CRUD models don't protect their domain invariants very well. They often don't have any kind of actions defined on them. They don't protect themselves against invalid state transitions, and they don't produce domain events."
  - The consequence: "domain and process logic still has to be implemented somewhere, so a lot of this logic ends up inside controllers and framework or ORM-specific event listeners. The project becomes a mess."

- **The legacy strategy** — five concrete moves, plus three constraints.
  - Moves: make it easier to write tests; make it easier to move and rename classes; add parameter and return types "to make your code more discoverable"; improve a little every day; pick the parts you actually work in.
  - Constraints: "**don't spend hours or days in a row**"; "**don't make too many changes at once**, breaking everything, and making everybody angry"; and accept that "your legacy application will never be fully decoupled, but it doesn't have to be either."
  - The targeting rule: "Many areas of an application remain untouched most of the time, so improving those parts and risking everything isn't even worth your time."
  - And the candid advice: "my secret suggestion for you is to **not ask permission for everything**. If it helps make your work more bearable, and if it helps you deliver better things faster, be sure to spend a little time improving some aspects of the code base you're working with."

- **"Just-right-engineering"** — the reframe of the over-engineering objection:
  > "The extra classes, interfaces, and tests deserve to be there. They are the result of making a distinction between core and infrastructure code. Keeping these separated requires extra elements in your software. **If you feel like core and infrastructure deserve to be apart, doing that extra work can't be considered over-engineering. It's rather *just-right-engineering*.**"
  - And the counter-charge: "since I believe that most web applications aren't short-lived projects, nor are they CRUD-only, I believe that we've been mostly **under-engineering** our web applications, and that it's time to start doing a better job."

## Key Concepts
- **Just-right-engineering** — extra elements justified by a distinction you've decided is worth making.
- **Under-engineering** — the actual default state of most web applications.
- **Proof of concept** — the project type most likely to outlive its design.
- **Brownfield project** — a legacy codebase you must work within.
- **The urge for consistency** — the desire to apply an improvement everywhere or not at all; "something that gets in the way a lot in software development teams."
- **CRUD-only** — generatable from a configuration file describing models, fields, types, and validation rules.

## Mental Models
- **Advice has to be evaluated in your own context.** "Any advice given to you requires careful analysis in your own context. The advice may sound intuitively right at first, but when considering the specifics of your own project, your own work situation, etc. the advice may be problematic."
- **Three fears block adoption, and they're worth naming.** "You may be worried that it's going to take a lot of effort to follow the advice. Maybe you know in advance that some team members will have trouble following it. And maybe you're afraid of 'doing it wrong' and this prevents you from finishing the project."
- **Don't drop a practice because you predict the project is short-lived.** "It's better not to let go of certain practices because you *think* that the type of project may not live long enough to deserve them."
- **Consistency is the enemy of getting started.** "Setting a coding standard, installing static analysis tools, these things get postponed forever because you fear that you'll never be able to apply them everywhere… Why not start today? Every improvement you can make, even if it's just in one module, can be the starting point of a better life for everyone on the team."
- **Legacy work is a daily habit, not a project.** "Improve your project just a little bit every day." Big-bang refactoring "breaks everything and makes everybody angry."
- **Effort and effect are not linear** — the book's closing diagram, which Noback labels "totally unscientific," shows developer effort against the effect it produces. The point survives the disclaimer: keeping software maintainable requires "every stakeholder… aware of the need to work hard, **and keep working hard**."
- **Start decoupling even years in.** "My advice is to start decoupling the application at some point, even if the business has been successfully running the software for a couple of years."

## Anti-patterns
- **Skipping automated tests because the project is short-lived**: testing is never optional; only the *type* is a choice.
- **Relying on end-to-end tests as your only safety net**: slow, fragile, and "within a couple of years they will become a real maintenance burden."
- **Declaring a project CRUD-only without scrutiny**: the domain logic doesn't disappear — it relocates into controllers and ORM event listeners.
- **Declaring legacy bankruptcy**: "The force that's pulling you down is just so very strong. It's hard to resist the claim for bankruptcy. At the same time, I know there's always room for improvement."
- **All-or-nothing improvement**: waiting for permission to apply a standard everywhere means applying it nowhere.
- **Marathon refactoring sessions**: hours or days in a row, or many simultaneous changes.
- **Dogmatism**: the book's final ask is explicitly against it.

## Reference Tables

**Should this project get a decoupled architecture?**

| Signal | Decouple? |
|---|---|
| Purely infrastructural, single-job script | No |
| Small enough that the effort dominates | No |
| Genuinely generatable from a config file (true CRUD) | No |
| **Absolutely certain** it dies within two years | Probably not — but still write tests |
| Might outlive its original purpose | **Yes** |
| Has actions, state transitions, or domain invariants | **Yes** |
| Legacy, actively worked in | **Partially** — incrementally, in the parts you touch |
| Legacy, rarely touched | Leave it alone |

**What you still owe a project you decided not to decouple**

| Obligation | Reason |
|---|---|
| Automated tests | "Should never be considered 'optional'" |
| End-to-end tests specifically | Without decoupling, there's nothing to test in isolation |
| Awareness of the end-to-end tax | Slow, fragile, a maintenance burden within a couple of years |
| A plan to start decoupling later | Applies even after years of successful operation |

## Worked Example

**The proof-of-concept lifecycle — the argument that undercuts three objections at once.**

Noback's strongest move in this chapter isn't defending decoupling. It's showing that the *conditions* under which the objections hold almost never obtain.

**Take "it won't live longer than two years."** He grants it immediately — "if you're absolutely certain the project will be discarded within a couple of years, I agree." Then he attacks the certainty:

> "It may start as a so-called 'proof of concept'. Badly designed, programmed sloppily, just to help the project stakeholders prove some point. Then the business starts making money with it and the project has to survive a little longer. At some point, adding new functionality becomes really problematic."

Nobody decides a POC becomes a production system. It happens by success. The design decision was made under an assumption that success invalidates — and by then the assumption is unrecoverable.

Conclusion: "it's better not to let go of certain practices because you **think** that the type of project may not live long enough to deserve them."

**The same shape for CRUD.** He concedes real CRUD applications exist and don't deserve decoupling — he built many. Then:

> "I've also seen several applications that started as pure CRUD applications, but very soon CRUD turned out to be a very limited way of modelling the application's business domain."

And the mechanism is specific. CRUD models lack four things: protected invariants, defined actions, guarded state transitions, and domain events. "But domain and process logic still has to be implemented somewhere, so a lot of this logic ends up inside controllers and framework or ORM-specific event listeners."

**Notice what this recovers.** That sentence is Ch 12's fat-controller diagram and Ch 8's anemic-model problem, arrived at from a completely different starting point. You didn't choose a bad architecture — you chose an adequate one for a domain that then grew past it, and the logic went somewhere.

**What he does *not* let you off the hook for.** Even granting the short-lived case: "I think automated testing should never be considered 'optional'. What **is** up to you is which type of tests you'll create."

And this has a real cost. Without a decoupled Domain and Application layer and clear ports and adapters, "you don't even have the possibility to test these elements in isolation." Your only option is end-to-end tests — "slow and fragile, and within a couple of years they will become a real maintenance burden."

Which closes the loop: skip decoupling to save effort, and if the project survives, you've bought a test suite that becomes a maintenance burden on roughly the same timeline you predicted the project would die on. Hence: "start decoupling the application at some point, even if the business has been successfully running the software for a couple of years."

**The legacy answer, which is the most practically useful part of the chapter.** Noback doesn't pretend brownfield work is tractable — "I sometimes find it hard to stay positive. The force that's pulling you down is just so very strong."

His advice is unusually concrete, and includes a piece most architecture books won't print: **"my secret suggestion for you is to not ask permission for everything."** Not a mandate to go rogue — it's bounded on both sides. Do it "if it helps make your work more bearable, and if it helps you deliver better things faster." And: "just don't spend hours or days in a row. Also, don't make too many changes at once, breaking everything, and making everybody angry."

The targeting rule is the sharpest bit: "Many areas of an application remain untouched most of the time, so improving those parts and risking everything isn't even worth your time." Improve where you work. Leave the rest.

**And the objection he treats as pure psychology.** "I can never make my entire application decoupled" isn't an architectural claim — it's the same instinct that kills coding standards and static analysis adoption. "The urge for consistency is something that gets in the way a lot in software development teams."

> "Trying to apply a good design idea everywhere is a waste of time, but not applying it anywhere is a wasted opportunity."

**The closing reframe.** The over-engineering charge gets answered by locating where the extra elements come from: "They are the result of making a distinction between core and infrastructure code. Keeping these separated requires extra elements in your software."

So the argument is conditional, and honestly so: **"If you feel like core and infrastructure deserve to be apart, doing that extra work can't be considered over-engineering. It's rather just-right-engineering."** If you don't think they deserve to be apart, the whole book doesn't apply — and Ch 1 through Ch 14 were the case for thinking they do.

Then the counter-charge: "since I believe that most web applications aren't short-lived projects, nor are they CRUD-only, I believe that we've been mostly **under-engineering** our web applications."

**The last words are about disposition, not technique**: "I hope that you'll be pragmatic in your work and stay away from dogmatism. I hope that you'll keep experimenting and won't be afraid to get it wrong."

## Key Takeaways
1. There's no silver bullet, and Noback names his own exception — small, purely infrastructural jobs don't deserve decoupling.
2. "Short-lived" only excuses you if you're *absolutely certain*. Proof-of-concept projects become production systems by succeeding, and nobody decides it.
3. Automated testing is never optional. Only the *type* of test is a choice. Skip decoupling and end-to-end tests become your only option — with their known cost.
4. Real CRUD applications exist and don't need this. Take a long, hard look before concluding yours is one.
5. When a "CRUD" app grows a domain, the logic goes into controllers and ORM event listeners — Ch 12's mess, reached by a different route.
6. Legacy: improve a little every day, in the areas you actually work in. Don't do marathon refactorings, don't break everything at once, and don't ask permission for every small improvement.
7. Rarely-touched code isn't worth the risk of improving.
8. The urge for consistency blocks adoption. One improved module beats a perfect plan you never start.
9. Extra classes, interfaces, and tests are the *consequence* of separating core from infrastructure. If that separation is worth making, they're just-right-engineering.
10. The prevailing failure mode isn't over-engineering — it's under-engineering.
11. Watch cost versus benefit, stay pragmatic, avoid dogmatism, and don't be afraid to get it wrong.

## Connects To
- **Ch 1**: the core/infrastructure distinction on which the just-right-engineering argument rests entirely.
- **Ch 2 (§2.8)**: the Active Record discussion that first pointed forward to this chapter's over-engineering treatment.
- **Ch 8**: anemic models that "don't protect their domain invariants" — the CRUD failure mode.
- **Ch 9**: domain knowledge outliving tool knowledge; the argument for long-lived core code.
- **Ch 12**: the fat-controller and manager-service diagrams that CRUD projects rediscover.
- **Ch 14**: the testing strategy, and why end-to-end-only is a real but costly fallback.
- **Accelerate / DORA research**: "we're lucky to have some research confirming that" some practices are demonstrably better.
