# Chapter 11: Applying Analysis Patterns

## Core Idea
Analysis patterns are documented experience — *"groups of concepts that represent a common construction in business modeling"* (Fowler 1997). They are not off-the-shelf solutions; they are **starting points that carry other people's trial and error**, including the implementation consequences that would otherwise cost you a maintenance cycle to discover.

## Frameworks Introduced

- **Analysis Pattern** (Fowler 1997, p. 8):
  > Analysis patterns are groups of concepts that represent a common construction in business modeling. It may be relevant to only one domain or it may span many domains.
  - When to use: at the start of an iterative cycle on a challenging domain, to skip expensive trial and error and begin with a model that is already expressive, implementable, and aware of subtleties.
  - **What the name obscures**: there is significant discussion of *implementation* in these patterns, including code. That matters — "To discuss model ideas out of that context makes them harder to apply and **risks opening the deadly divide between analysis and design**, which is antithetical to MODEL-DRIVEN DESIGN."
  - What the best of them carry: model insight **plus** discussion of design directions **plus** implementation consequences — including long-term maintenance implications. Fowler's example: *"When we build a new [accounting] practice, we create a network of new instances of the posting rule. We can do this without any recompilation or rebuilding of the system, while it is still up and running."*
  - **The one change to avoid**: when you use a term from a well-known analysis pattern, **keep the basic concept it designates intact**, however much the superficial form changes. Two reasons: (1) the pattern may embed understanding that helps you avoid problems; (2) more important, **your UBIQUITOUS LANGUAGE is enhanced by terms that are widely understood or well explained.** If model definitions genuinely change through evolution, *change the names too.*

- **The Accounting analysis patterns** used as examples (Fowler 1997, Ch 6, "Inventory and Accounting"):
  - **Account + Entry**: value is added by inserting an `Entry`, removed by inserting a *negative* `Entry`. **Entries are never removed, so the whole history is retained.** The balance is the combined effect of all Entries — computed on demand or cached, an implementation decision encapsulated by the `Account` interface.
  - **Transaction (double-entry bookkeeping)**: the principle of **conservation** — money doesn't appear from nowhere or vanish; it only moves from one Account to another. Every credit has a matching debit. Like other conservation principles, **it applies only to a closed system, one that includes all sources and sinks.** Many simple applications do not require this rigor.
  - **Posting Rule**: makes cross-account dependency explicit. Triggered by a new `Entry` in its *input* Account, it derives a new Entry (via its own calculation `Method`) and inserts it into its *output* Account. E.g. an Entry in a salary Account triggers a rule computing 30% estimated income tax and inserting it into the tax-withholding Account. *"The first step toward taming the tangle of dependencies is to make these rules explicit by introducing a new object."*

- **The three firing modes for Posting Rules** — Evans stresses that **adding these three names to the UBIQUITOUS LANGUAGE is as important to the pattern's success as the model objects themselves**, because they eliminate ambiguity and guide decision making to a clearly defined set of choices:

  | Mode | Who initiates | Behavior |
  |---|---|---|
  | **Eager firing** | The Entry insertion itself | Most obvious, typically least practical. Inserting an Entry immediately triggers the Posting Rules; all updates happen immediately. |
  | **Account-based firing** | A message to an `Account` | Deferred. The Account triggers its Posting Rules to process all Entries inserted since its last firing. |
  | **Posting-Rule-based firing** | An external agent | The agent tells the Posting Rule to fire; the rule looks up all Entries made to its input Accounts since it last fired. |

  Modes can be mixed in a system, but **each particular set of rules needs one clearly defined point of initiation and responsibility for identifying input Account Entries.**

## Key Concepts
- **Analysis pattern** — a reusable group of business-modeling concepts, with design and implementation consequences attached.
- **Account / Entry** — value held, and the immutable record of each change to it.
- **Conservation / double-entry bookkeeping** — every credit has a matching debit, within a closed system.
- **Posting Rule** — an explicit object encoding a derived cross-account posting.
- **Accrual** — *(the term the domain expert supplied)* accounting for an expense or income **at the time it is incurred, never mind when money actually changes hands.**
- **Firing mode** — eager / Account-based / Posting-Rule-based.

## Mental Models
- **Treat an analysis pattern as a lead, not an answer.** "When you are lucky enough to have an analysis pattern, it hardly ever is the answer to your particular needs. Yet it offers valuable leads in your investigation, and it provides cleanly abstracted vocabulary."
- **Expect the result to diverge.** "The result often resembles the form documented in the analysis pattern, but adapted to circumstances. Sometimes the result doesn't even obviously relate to the analysis pattern itself, yet was stimulated by the insights from the pattern."
- **Use analysis patterns to find blind spots.** "Sometimes there are parts of our programs that we don't even suspect have the potential to benefit from a domain model. They may have started very simply and evolved mechanistically. They seem like complicated application code, rather than domain logic."
- **Analysis patterns ≠ code reuse.** "A model, even a generalized framework, is a complete working whole, while an analysis is **a kit of model fragments**. Analysis patterns focus on the most critical and difficult decisions and illuminate alternatives and choices. They anticipate downstream consequences that are expensive if you have to discover them for yourself."

## Worked Example — Earning Interest with Accounts

*(Same starting point as the Ch 9/10 examples: an interest-and-fee tracking application whose nightly batch posts to a legacy accounting system. It works, but is awkward to use, tricky to change, and communicates poorly.)*

Developer 1 reads *Analysis Patterns* Ch 6, sketches a model using `Account`, `Entry`, and `Transaction` with Developer 2, and takes it to the domain expert.

> **Developer 1:** With this new model, we make an `Entry` into the `Interest Account` for the interest earned, rather than just adjusting the `interestDueAmount`. Then, another Entry for the payment balances it out.
> **Expert:** So now we'd be able to see a history of all the interest accruals as well as the payment history? That's something we've been wanting.
> **Developer 2:** I'm not sure we've used "Transaction" quite right. The definition talks about moving money from one Account to another, not two entries that balance each other in the same Account.
> **Developer 1:** …the book seems to make quite a point about the transaction being created all at once. The interest payments can be several days late.
> **Expert:** Those payments aren't necessarily late. There is a lot of flexibility in when they pay.
> **Expert:** Why do we need to tie together the accrual to the payment? They are separate postings in the accounting system. The balance on the Account is the main thing.
> **Developer 2:** It could actually simplify a lot of things to stop worrying about that connection.
> **Developer 1:** By the way, you used the word *accruals* a few times. Could you clarify what it means?
> **Expert:** Sure. An accrual is just when you account for an expense or income at the time it is incurred, never mind when money actually changes hands. So, we accrue interest every day, but at the end of the month (for example) we receive a payment against it.
> **Developer 1:** Yes, we really needed a word like that.

Then the crucial correction — the developers had proposed dropping `Account`:

> **Expert:** So we're not going to have the `Account` object? I was looking forward to being able to see everything together there, with the accruals and the payments and a balance.
> **Developer 1:** Really?! Well in that case, maybe *this* would work.
> **Expert:** That actually looks pretty good!

**Outcome — `Account` kept, `Transaction` dropped, `accrual` adopted.** Note what each pattern element earned: `Account`/`Entry` fit and were kept; `Transaction` was tried, tested against the domain, and **correctly rejected** because the closed-system assumption didn't hold for this application's flexible payment timing.

**Refinements that came from the code, not the diagram:**
- `Entry` was subclassed into `Payment` and `Accrual` — closer inspection revealed slightly different application responsibilities, *and both were important domain concepts.*
- There was **no** conceptual or behavioral distinction between Entries from fees vs. interest; they simply appeared in the appropriate `Account`.

**The compromise Evans deliberately includes:** the project standard required relational tables be interpretable without running the program, so fee and interest entries had to live in separate tables. With their object-relational mapping framework, the only way was concrete subclasses (`Fee Payments`, `Interest Payments`, …) — **giving up the abstraction they had just earned.**

> I threw this twist into this largely fictitious story to represent the rub of reality that we encounter all the time. **We have to make calculated compromises and then move on without letting it throw us off our MODEL-DRIVEN DESIGN.**

The new design was much easier to analyze and test because the most complex functionality sits in SIDE-EFFECT-FREE FUNCTIONS; the remaining command is simple (it calls FUNCTIONS) and is characterized by ASSERTIONS.

## Worked Example — Insight into the Nightly Batch

Weeks later, the clarity of the new design made another problem visible. Developer 2, adapting the batch, recognized `Posting Rules` in what he'd been treating as non-domain code.

> **Developer 2:** At some point, the nightly batch started being a place where we swept stuff under the rug. There is domain logic implicit in what the script does, and it's been getting more and more complicated. For a long time I've wanted to do a model-driven design for the batch… But I could never figure out what that domain model would be like. It seemed like maybe it was just some procedures that didn't really make sense as objects.

The firing-mode decision, made in conversation:

> **Developer 1:** Which firing style do you plan to use?
> **Developer 2:** I hadn't really gotten that far.
> **Developer 1:** *Eager Firing* would work for `Accruals`, since the batch actually tells the `Asset` to insert them, but it wouldn't work for `Payments`, which get entered during the day.
> **Developer 2:** I don't think we would want to couple the calculation method that tightly to the batch anyway. If we ever decided to trigger interest calculations at a different time, it would mess things up.
> **Developer 1:** It sounds like *Posting-Rule-based firing*. The batch tells each Posting Rule to execute, and the rule goes and looks for appropriate new Entries and then does its thing.
> **Developer 2:** So then we avoid creating a lot of dependencies on the batch design, and the batch keeps control.

The `Method` correction:

> **Developer 1:** I don't think that we're using "Method" right. I think the concept is that the Method *computes the amount* to be posted — like a 20 percent tax withholding on income. But in our case that's simple: it's always the full amount. I think the Posting Rule itself is supposed to know which Account to post to, which corresponds to our "ledger name."
> **Developer 2:** Oh. So if the Posting Rule is responsible for knowing the correct ledger name, we probably don't need `Method` at all. Actually, this whole business of choosing the right ledger name is getting more and more complicated. It is already a combination of the type of income (fee or interest) with the "asset class"… That is one place I'm hoping this new model will help.

**Outcome**: the batch became a simple loop iterating `Asset`s, sending a few self-explanatory messages and committing database transactions. **The complexity shifted into the domain layer, where an object model made it both more explicit and more abstract.**

**The pragmatic deviation they consciously recorded:** the book's models link `Account` directly to `Posting Rule`. That would have required collaborating with the `Asset` object on every instantiation (every batch run), because `Asset` is what knows the nature of each Account (fee or interest) and is the batch's natural access point. Instead, `Asset` looks up the two relevant rules via SINGLETON access and passes them the appropriate `Account`.

> They both felt that conceptually it would have been better to associate `Posting Rules` only with `Accounts`, while keeping the `Asset` focused on its job of generating `Accruals`. **They hoped that subsequent refactorings and deeper insight would bring them back to this** and show them a way to make this clean division without losing the obviousness of the code.

Also note: `Posting Service` was a **FACADE** exposing the legacy accounting API as a SERVICE — built earlier to simplify the batch code, and doubling as an INTENTION-REVEALING INTERFACE for posting.

## Anti-patterns
- **Treating an analysis pattern as a specification to conform to** — the developers correctly abandoned `Transaction` when the expert showed the concept didn't fit, and correctly dropped `Method` when it added nothing.
- **Analysis without thought for practical design** — the deadly divide again; Fowler avoids it by discussing implementation, and Evans warns that stripping the implementation context makes patterns harder to apply.
- **Keeping a pattern's *name* while changing its concept** — corrupts both the embedded understanding and the UBIQUITOUS LANGUAGE.
- **Treating a batch script as non-domain code** — it becomes "a place where we swept stuff under the rug," accumulating implicit domain logic.
- **Expecting reuse like a framework or component library** — analysis is a kit of fragments, not a working whole.

## Key Takeaways
1. Use analysis patterns as leads into knowledge crunching, not as answers; expect and welcome divergence from the published form.
2. Value the *implementation discussion* in a pattern as much as the model — it carries downstream consequences you'd otherwise pay to discover.
3. Test every borrowed element against the domain expert; drop the ones that don't fit (`Transaction`, `Method`) as decisively as you keep the ones that do (`Account`, `Entry`).
4. Harvest the pattern's *vocabulary* — "accrual" and the three firing modes did as much work as any class in these examples.
5. Preserve a borrowed term's concept, or rename; the UBIQUITOUS LANGUAGE depends on widely understood words meaning what they say.
6. Record consciously-made compromises (relational subclassing, `Asset` looking up rules) as things to revisit — and then move on without derailing MODEL-DRIVEN DESIGN.
7. Look at "mechanistic" code — batch scripts, glue, reporting — with analysis patterns in hand; that's where blind spots hide.

## Connects To
- **Ch 7 (Extended Example)**: ENTERPRISE SEGMENT, another analysis pattern borrowed from Fowler 1997.
- **Ch 9 (Making Implicit Concepts Explicit)**: this is the "read the book" strategy, played out in full; the same interest/accrual example appears there in two other variants.
- **Ch 10 (Supple Design)**: the resulting design's testability comes from SIDE-EFFECT-FREE FUNCTIONS and ASSERTIONS; and "draw on established formalisms" — accounting is Evans' first named example.
- **Ch 12 (Relating Design Patterns to the Model)**: the parallel chapter for *technical* patterns used as domain patterns.
- **Ch 13 (Refactoring Toward Deeper Insight)**: "Prior Art" — analysis patterns feed the knowledge-crunching process.
- **Fowler 1997** (*Analysis Patterns: Reusable Object Models*), **Gamma et al. 1995** (FACADE, SINGLETON).
