# Chapter 9: Making Implicit Concepts Explicit

## Core Idea
Deep models start with recognizing a concept that was hinted at in discussion or implicit in the design, and giving it explicit form as an object or relationship. Learn to hear those hints — and learn to model three categories that don't come naturally in an object language: **constraints**, **processes**, and **specifications**.

## Frameworks Introduced

- **Four ways to dig out concepts:**
  1. **Listen to Language.** Are there terms that succinctly state something complicated? Are experts correcting your word choice (perhaps diplomatically)? Do puzzled looks go away when you use a particular phrase?
     - **This is not the old "nouns are objects" notion.** A new word is a *lead*, followed up with conversation and knowledge crunching to carve out a clean, useful concept.
     - **Warning sign**: experts using vocabulary nowhere in the design. **Doubly strong warning**: developers *and* experts both using terms that aren't in the design.
  2. **Scrutinize Awkwardness.** Dig in "the most awkward part of your design. The place where procedures are doing complicated things that are hard to explain. The place where every new requirement seems to add complexity." Actively engage the domain experts — if they enjoy playing with ideas, brainstorm; if not, generate ideas yourself and **use the expert as a validator, watching for discomfort or recognition on their face.**
  3. **Contemplate Contradictions.** Different experts see things differently; the same person is often logically inconsistent under analysis. Some contradictions are terminology or misunderstanding, but there's a residue where two factual statements genuinely conflict — and **contemplating how both could apply to the same external reality can be revealing**, even when you leave the contradiction in place.
  4. **Read the Book.** Many fields have books explaining fundamental concepts and conventional wisdom. You still distill with your own experts, but you can start from a coherent, deeply considered view. Also read what software professionals have written about the domain (e.g. Fowler's *Analysis Patterns*).

- **Explicit Constraints** — factor a constraint into its own intention-revealing method or object.
  - **Four warning signs that a constraint is distorting its host object:**
    1. Evaluating the constraint requires data that does not otherwise fit the object's definition.
    2. Related rules appear in multiple objects, forcing duplication or inheritance between objects that are not otherwise a family.
    3. A lot of design and requirements conversation revolves around the constraints, but in the implementation they are hidden away in procedural code.
    4. (Implied by the above) The constraint is prominent in the domain yet not prominent in the model.
  - Why the separate method helps even when the rule is simple: it gives the constraint **a name you can discuss**, and it gives it **room to grow** — a complex rule may produce a method longer than its caller, while the caller stays simple and focused.

- **Processes as Domain Objects** — with a caveat up front: *"we do **not** want to make procedures a prominent aspect of our model."* Objects encapsulate procedures so we can think in goals and intentions.
  - Express a business-meaningful process as a **SERVICE** (encapsulating a complex algorithm), or — when there is more than one way to carry it out — make the algorithm itself an object, so choosing a process becomes choosing between **STRATEGY** objects (Ch 12).
  - **The discriminator**: *Is this something the domain experts talk about, or is it just part of the mechanism of the computer program?*

- **SPECIFICATION** (developed with Martin Fowler; Evans and Fowler 1997):
  > Create explicit predicate-like VALUE OBJECTS for specialized purposes. A SPECIFICATION is a predicate that determines if an object does or does not satisfy some criteria.
  - **The problem**: boolean test methods start simple (`anInvoice.isOverdue()`) but grow into rules that depend on account status, grace-period policy, payment history, product-line policy — until "the clarity of `Invoice` as a request for payment will soon be lost in the sheer mass of rule evaluation code," and `Invoice` accumulates dependencies unrelated to its basic meaning.
  - **The wrong fix**: moving rule evaluation into the application layer. That leaves behind "a dead data object that does not express the rules inherent in the business model."
  - **The borrowed idea**: logic programming's **predicates** — functions evaluating to true/false, combinable with AND/OR. Full implementation of logic in objects is a major undertaking (logic programming is a whole paradigm), and *so general that it doesn't communicate intent as much as more specialized designs.* But most rules fall into a few special cases, so specialized boolean-evaluating VALUE OBJECTS get most of the benefit.
  - **Three uses, one concept**: **validation** (does this object fulfill some need / is it ready for some purpose), **selection** (query a collection), **building to order** (specify the creation of a new object). *"Without a pattern such as SPECIFICATION, the same rule may show up in different guises, and possibly contradictory forms. The conceptual unity can be lost."*
  - **Advantages of a generator defined by SPECIFICATION rather than by procedure:**
    1. Implementation is decoupled from interface — the SPEC declares requirements for the output without defining how the result is reached.
    2. Rules are communicated explicitly; developers know what to expect without understanding operation details. *"The only way to predict the behavior of a procedurally defined generator is to run cases or to understand every line of code."*
    3. More flexible — the statement of the request is in the client's hands; the generator need only fulfill the letter of the SPEC.
    4. **Easier to test — the same SPECIFICATION passed in to constrain creation can be used in its validation role to confirm the created object is correct.** (An ASSERTION, Ch 10.)

- **Clearing Development Logjams with Working Prototypes** — when one team waits on another's code, and both wait on integration, a **MODEL-DRIVEN prototype of a key component** (even one that doesn't satisfy all requirements) unblocks everyone. When implementation is decoupled from interface, *any* working implementation lets project work go in parallel; the prototype is replaced later, and meanwhile all other parts of the system have something to interact with.

## Key Concepts
- **SPECIFICATION** — a predicate-like VALUE OBJECT stating a constraint on the state of another object.
- **Predicate** — a logic-programming function evaluating to true/false, combinable with logical operators.
- **Validation / Selection / Building to order** — the three uses of SPECIFICATION.
- **Accrual basis accounting** — recognizing income when earned even if unpaid, and expenses when incurred whether paid or billed later.
- **ASSERTION** — a stated post-condition on an interface (Ch 10).
- **ENTERPRISE SEGMENT / analysis pattern** — published domain models as starting points (Ch 11).

## Mental Models
- **Treat a term absent from the design as an opportunity, not just a gap.** The UBIQUITOUS LANGUAGE is the vocabulary pervading speech, documents, diagrams, *and code* — a missing term is an invitation to improve both.
- **Galileo's ball**: the senses say the Earth is stationary; Copernicus says it moves fast. Galileo asked where a ball dropped from a running horse would land — by the horse's feet, as if it were standing still — deducing inertial frames of reference. *"Our contradictions are usually not so interesting, nor the implications so profound. Even so, this same pattern of thought often helps pierce the superficial layers of a problem domain."*
- **The Pentagon's fighter jet**: a spec requiring Mach 2, 1800-mile range, under $50 million is not a design, much less a plane. Competing companies produce different designs, all satisfying it. That is the relationship between a SPECIFICATION and a generator.
- **A modeler/designer cannot afford to get attached to his own ideas.** Evans reports following half a dozen conversational leads before finding one clear enough to try, then replacing it at least once later.
- **Changes of direction are not thrashing.** Each embeds deeper insight and leaves the design suppler — ready to bend where it turns out to need to bend. *"Trying to avoid missteps in design will result in a lower quality result because it will be based on less experience. And it can easily take longer than a series of quick experiments."*
- **A pattern is not a cookbook.** It lets you start from a base of experience and gives you language to talk about what you're doing.

## Code Examples

Constraint buried in case logic (works, but the rule is easy to lose in a bigger class):

```java
class Bucket {
   private float capacity;
   private float contents;
   public void pourIn(float addedVolume) {
      if (contents + addedVolume > capacity) {
         contents = capacity;
      } else {
         contents = contents + addedVolume;
      }
   }
}
```

Same constraint, factored into an intention-revealing method:

```java
class Bucket {
   private float capacity;
   private float contents;
   public void pourIn(float addedVolume) {
      float volumePresent = contents + addedVolume;
      contents = constrainedToCapacity(volumePresent);
   }
   private float constrainedToCapacity(float volumePlacedIn) {
      if (volumePlacedIn > capacity) return capacity;
      return volumePlacedIn;
   }
}
```

- **What it demonstrates**: both enforce the constraint; the second has an obvious relationship to the model — *the basic requirement of MODEL-DRIVEN DESIGN.*

SPECIFICATION for validation:

```java
class DelinquentInvoiceSpecification extends InvoiceSpecification {
   private Date currentDate;
   // An instance is used and discarded on a single date
   public DelinquentInvoiceSpecification(Date currentDate) {
      this.currentDate = currentDate;
   }
   public boolean isSatisfiedBy(Invoice candidate) {
      int gracePeriod = candidate.customer().getPaymentGracePeriod();
      Date firmDeadline =
         DateUtility.addDaysToDate(candidate.dueDate(), gracePeriod);
      return currentDate.after(firmDeadline);
   }
}
```

Generic selection on a REPOSITORY:

```java
public Set selectSatisfying(InvoiceSpecification spec) {
   Set results = new HashSet();
   Iterator it = invoices.iterator();
   while (it.hasNext()) {
      Invoice candidate = (Invoice) it.next();
      if (spec.isSatisfiedBy(candidate)) results.add(candidate);
   }
   return results;
}

// client:
Set delinquentInvoices = invoiceRepository.selectSatisfying(
   new DelinquentInvoiceSpecification(currentDate));
```

Double dispatch, keeping SQL in the REPOSITORY while the SPECIFICATION decides *which* query expresses the rule:

```java
public class InvoiceRepository {
   public Set selectWhereGracePeriodPast(Date aDate){
      //This is not a rule, just a specialized query
      String sql = whereGracePeriodPast_SQL(aDate);
      ResultSet queryResultSet =
         SQLDatabaseInterface.instance().executeQuery(sql);
      return buildInvoicesFromResultSet(queryResultSet);
   }
   public Set selectSatisfying(InvoiceSpecification spec) {
      return spec.satisfyingElementsFrom(this);
   }
}

public class DelinquentInvoiceSpecification {
   public Set satisfyingElementsFrom(InvoiceRepository repository) {
      //Delinquency rule is defined as:
      //   "grace period past as of current date"
      return repository.selectWhereGracePeriodPast(currentDate);
   }
}
```

## Reference — Implementing SPECIFICATION against a database

| Approach | Where the rule lives | Trade-off |
|---|---|---|
| `isSatisfiedBy()` in memory | Fully in the SPECIFICATION | Cleanest; only viable for small collections |
| `asSQL()` on the SPECIFICATION | Fully in the SPECIFICATION | **Table structure leaks into the domain layer**; mapping info duplicated, hurting modifiability of `Invoice`/`Customer` |
| O/R mapping framework expressing the query in model terms | SPECIFICATION, SQL generated in infrastructure | "Would let us have our cake and eat it too" |
| Double dispatch to a *specialized* repository query | Declaration of the rule in the SPEC, SQL in the REPOSITORY | Repository gains a very specialized query used only here — acceptable |
| Double dispatch to a *generic* repository query, filtered in memory | SPECIFICATION stays self-explanatory | Performance hit: pulls more Invoices then filters. "Whether this is an acceptable cost for the better factoring of responsibility depends entirely on circumstances." |
| Stored procedure | SPEC carries only the allowed parameters | For performance or security; **no difference in the model** — the price is cumbersome query writing and maintenance |

## Worked Example — Hearing a Missing Concept in the Shipping Model

The booking application's routing engine wrote each leg of a journey into a database row: vessel voyage ID, loading port, unloading port. An "operations support" application was starting.

> **Developer:** I want to make sure the "cargo bookings" table has all the data the operations application will need.
> **Expert:** They're going to need the whole **itinerary** for the Cargo…
> **Expert:** What about the date? Operations will need to contract handling work based on the expected times.
> **Developer:** Well, that can be derived from the schedule of the vessel voyage. The table data is normalized.
> **Expert:** Yes, it is normal to need the date. Operations people use these kinds of **itineraries** to plan for upcoming handling work.
> **Developer:** …the whole loading and unloading sequence, with the date of each handling operation. The "**itinerary**," I guess you would say.
> **Expert:** Good. The itinerary is the main thing they'll need. Actually, the booking application has a menu item that will print an itinerary or e-mail it to the customer. Can you use that somehow?
> **Developer:** That's just a report… *[looks thoughtful, then excited]* So, this **itinerary** is really the link between booking and operations.

Note how many times the expert says "itinerary" before the developer hears it. The data was already being collected and the behavior was already implicit *in the itinerary report* — but making `Itinerary` an explicit model object opened up:

- Defining the `Routing Service` interface more expressively (it now returns an `Itinerary` instead of writing database rows — so the routing engine no longer needs to know about the tables)
- Decoupling the Routing Service from the booking database tables
- Clarifying the relationship between booking and operations (they share the `Itinerary` object)
- Reducing duplication — `Itinerary` derives loading/unloading times for both consumers
- Removing domain logic from the booking report into the isolated domain layer
- Expanding the UBIQUITOUS LANGUAGE

Refactored in two or three steps within a week.

## Worked Example — Earning Interest the Hard Way (scrutinizing awkwardness)

A nightly batch script iterated `Asset`s, calling `calculateInterestForDate()`, then posted each return value to a named ledger via a SERVICE wrapping the accounting software; then repeated the whole process for fees into a different ledger. The `Interest Calculator` was "getting out of hand," especially around "special cases when they don't pay the interest on schedule."

> **Expert:** Those really aren't special cases. There's a lot of flexibility in when people pay.
> **Developer:** …we're tracking the interest due but unpaid within an accounting period. Do you have a name for that?
> **Expert:** Well, we don't really do it like that. The interest earned and the payment are quite separate postings.
> **Developer:** OK, so if the payment and interest are separate, maybe we should model them that way.
> **Expert:** It makes sense, I guess. But you just moved it from one place to another.
> **Expert:** …when I saw interest and Payment History separated like that, I thought you were breaking up the interest to organize it more like the Payment History. **Do you know anything about accrual basis accounting?**
> **Expert:** Each day, or whenever the schedule calls for, we have an interest **accrual** that gets posted to a ledger. The payments are posted a different way. This aggregate you have here is a little awkward.
> **Developer:** You're saying that if we keep a list of "accruals," they could be aggregated or… "posted" as needed.
> **Expert:** Probably posted on the accrual date, but yes, aggregated anytime. Fees work the same way, posted to a different ledger, of course.
> **Expert (later):** Yes, the calculation was correct before, but **I can see everything now.**

Result: the batch script now tells each `Asset` to `calculateAccrualsThroughDate()` and posts each returned `Accrual` to its indicated ledger. The change:
- Enriches the UBIQUITOUS LANGUAGE with **"accrual"**
- Decouples accrual from payment
- Moves domain knowledge (*which ledger to post to*) out of the script and into the domain layer
- Brings fees and interest together in a way that fits the business, eliminating duplication in the `Fee Calculator`
- Provides a straightforward path for adding new variations as `Accrual Schedule`s

Because the `Calculator` classes hadn't been directly coupled to other parts of the design, this was a fairly easy refactoring: unit tests rewritten in the new language in a few hours, new design working late the next day. Evans notes the developer was **lucky to have an intelligent and motivated partner** — with a more passive source of expertise, there would have been more false starts and more dependence on other developers as brainstorming partners. "Progress would have been slower, but still possible."

## Worked Example — Earning Interest by the Book (the alternative path)

Same starting point, but the domain expert's responsibilities lie elsewhere and he isn't interested in the project. So the developer went to a bookstore, skimmed an introductory accounting book, and found a whole system of well-defined concepts — including:

> **Accrual Basis Accounting.** This method recognizes income when it is earned, even if it is not paid. *All* expenses also show when they are incurred whether they have been paid for or billed to be paid at a later date. Any obligation due, including taxes, will be shown as expense.
> — Suzanne Caplan, *Finance and Accounting: How to Keep Your Books and Manage Your Finances Without an MBA, a CPA or a Ph.D.* (Adams Media, 2000)

The resulting model was **less deep** than the collaborative one: she lacked the insight that Assets are income generators, so the `Calculator`s remained, and ledger knowledge stayed in the application rather than the domain layer. **But** she separated payment from accrual — the most problematic area — and introduced "accrual" into the model and the LANGUAGE. Further refinement could come later.

**The second-order payoff:** when she finally did talk to the expert, he was surprised — *"It was the first time a programmer had shown a glimmer of interest in what he did."* Her better questions earned his careful listening and prompt answers from then on.

**Not an either-or**: even with ample expert support, read the literature for the theory of the field. Most businesses lack models as refined as accounting or finance, but many have thinkers who organized and abstracted common practice.

## Worked Example — Chemical Warehouse Packer (building to order)

**Domain**: chemicals stored in stacked containers. Inert chemicals go anywhere; volatile ones need ventilated containers; explosives need armored containers; and there are rules about allowed combinations.

**The move that makes it tractable**: don't start by writing the packing procedure. **Start with the validation problem** — it forces the rules to be explicit and yields a test for the final implementation.

| Chemical | Container Specification |
|---|---|
| TNT | Armored container |
| Sand | *(none)* |
| Biological Samples | Must not share container with explosives |
| Ammonia | Ventilated container |

```java
public class ContainerSpecification {
   private ContainerFeature requiredFeature;
   public ContainerSpecification(ContainerFeature required) {
      requiredFeature = required;
   }
   boolean isSatisfiedBy(Container aContainer){
      return aContainer.getFeatures().contains(requiredFeature);
   }
}

// client:
tnt.setContainerSpecification(new ContainerSpecification(ARMORED));

// on Container:
boolean isSafelyPacked(){
   Iterator it = contents.iterator();
   while (it.hasNext()) {
      Drum drum = (Drum) it.next();
      if (!drum.containerSpecification().isSatisfiedBy(this))
         return false;
   }
   return true;
}
```

*(An aside worth noticing: this already yields a free monitoring application that scans the inventory database for unsafe situations — "It would be good to let the business people know about the opportunity, but we have been charged with designing a packer.")*

The SPECIFICATION-based understanding now makes a clean SERVICE interface possible, **with the SPEC restated as an ASSERTION**:

```java
public interface WarehousePacker {
   public void pack(Collection containersToFill,
      Collection drumsToPack) throws NoAnswerFoundException;
      /* ASSERTION: At end of pack(), the ContainerSpecification
      of each Drum shall be satisfied by its Container.
      If no complete solution can be found, an exception shall
      be thrown. */
}
```

Designing an optimized constraint solver is now **decoupled** from the rest of the application, and its mechanisms won't clutter the model-expressing design — *yet the rules governing packing have not been pulled out of the domain objects.*

**The prototype that clears the logjam.** The optimization team hasn't begun coding; the application team can only mock a UI and write database integration, so neither can close a feedback loop. With the domain objects and SERVICE interface in place, a `PrototypePacker` in **a couple dozen lines of easily understood code** unblocks everything:

```java
public class PrototypePacker implements WarehousePacker {
   public void pack(Collection containers, Collection drums)
                                throws NoAnswerFoundException {
      /* This method fulfills the ASSERTION as written. However,
         when an exception is thrown, Containers' contents may
         have changed. Rollback must be handled at a higher level. */
      Iterator it = drums.iterator();
      while (it.hasNext()) {
         Drum drum = (Drum) it.next();
         Container container = findContainerFor(containers, drum);
         container.add(drum);
      }
   }
   public Container findContainerFor(Collection containers, Drum drum)
                 throws NoAnswerFoundException {
      Iterator it = containers.iterator();
      while (it.hasNext()) {
         Container container = (Container) it.next();
         if (container.canAccommodate(drum)) return container;
      }
      throw new NoAnswerFoundException();
   }
}
```

It may pack sand into specialty containers and run out of room for hazardous chemicals; it certainly doesn't optimize revenue. **But it follows every rule stated so far** — and "a lot of optimization problems are never solved perfectly anyway."

Consequences: application developers move at full speed including external integrations; the Packer team gets feedback as domain experts interact with the prototype, clarifying requirements and priorities; the Packer team takes the prototype over to test ideas and keeps the interface current, forcing refactoring and surfacing integration problems early. When the real Packer arrives months later, **integration is a breeze because it was written to the same interface and ASSERTIONS.**

> Here we have an example of a "simplest thing that could possibly work" that actually becomes possible **because of a more sophisticated model.** A less MODEL-DRIVEN approach would be harder to understand, harder to upgrade (the Packer would be more coupled to the rest of the design), and would likely take longer to prototype.

## Anti-patterns
- **Hearing a term repeatedly and treating it as "just a report"** — the itinerary was mentioned four times before the developer registered it as a concept.
- **Rescuing an ENTITY by pushing its rules into the application layer** — leaves a dead data object and removes the rules from the domain layer entirely.
- **Evaluating methods swollen with conditional code** — the rule becomes unreadable even where it lives.
- **Attempting full logic programming in objects** — "Some such attempts were very sophisticated, others naive… A few attempts were allowed to derail their projects."
- **Leaking table structure into the domain layer via `asSQL()`** — duplicates mapping information, so any mapping change must be tracked in more than one place.
- **Making procedures a prominent aspect of the model** — only model a process explicitly when the domain experts talk about it.

## Key Takeaways
1. Listen for terms the experts use that don't appear in your design — and be alarmed when *both* sides use a term the design lacks.
2. Dig where the design is most awkward; the missing concept is usually under the code that every new requirement makes worse.
3. Use domain experts as validators when they won't brainstorm — watch their faces for discomfort or recognition.
4. Read the domain's literature; even a shallower model built from a book buys you a shared vocabulary and better questions.
5. Give a constraint its own named method or object when it needs foreign data, duplicates across unrelated objects, or dominates conversation while hiding in procedural code.
6. Model a process explicitly only if the domain experts talk about it; use a SERVICE, or STRATEGY objects when there are competing algorithms.
7. Use SPECIFICATION to keep a rule in the domain layer as a first-class object, unifying validation, selection, and building-to-order under one concept.
8. Define generators by SPECIFICATION rather than procedure — you get decoupling, explicit rules, client-side flexibility, and a built-in test.
9. Choose the SPECIFICATION/REPOSITORY implementation from the trade-off table; the model doesn't change, only the price of writing and maintaining queries.
10. Ship a model-driven prototype behind a well-characterized interface to unblock parallel work and close the feedback loop early.

## Connects To
- **Ch 1 (Knowledge Crunching)**: the Overbooking Policy example is revisited here as an explicit constraint.
- **Ch 5 (Model Expressed in Software)**: SERVICE, VALUE OBJECT — SPECIFICATIONS are VALUE OBJECTS.
- **Ch 6 (Life Cycle)**: REPOSITORY, and SPECIFICATION-based queries; FACTORIES configuring a SPECIFICATION from external sources.
- **Ch 10 (Supple Design)**: combining SPECIFICATIONS with logical operators; ASSERTIONS; declarative style of design; intention-revealing interfaces.
- **Ch 11 (Applying Analysis Patterns)**: published models as starting points — *Analysis Patterns* Ch 6 would have sent this developer in a different, not necessarily better or worse, direction.
- **Ch 12 (Relating Design Patterns to the Model)**: STRATEGY in the domain.
- **Ch 15 (Distillation)**: COHESIVE MECHANISM — where the optimized constraint solver belongs.
- **Warmer and Kleppe 1999** (*The Object Constraint Language*), **Evans and Fowler 1997** (SPECIFICATION), **Fowler 2002** (Mee and Hieatt on REPOSITORY + SPECIFICATION).
