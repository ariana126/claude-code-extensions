# Chapter 10: Supple Design

## Core Idea
Software must serve developers before it can serve users. A **supple design** is one that reveals a deep model, is predictable to use, and bends at the joints where change actually comes. It is not flexibility bought with layers of abstraction — "Look at the design of software that really empowers the people who handle it; you will usually see something simple. **Simple is not easy.**"

## The Two Roles a Design Must Serve
- **The client developer** — weaves domain objects into application or other domain code. A supple design reveals the deep model so a minimal set of loosely coupled concepts can express a range of scenarios, fitting together predictably, clearly characterized, robustly.
- **The developer changing it** — needs the design to be easy to understand, revealing that *same* underlying model, following the contours of a deep model so **most changes bend the design at flexible points**, with transparently obvious effects so consequences are easy to anticipate.

Evans' honest caveat: *"Early versions of a design are usually stiff. Many never acquire any suppleness in the time frame or budget of the project. I've never seen a large program that had this quality throughout."* The payoff is honing the **most crucial, intricate parts** — that's the difference between legacy maintenance and punching through the complexity ceiling.

## Frameworks Introduced

- **INTENTION-REVEALING INTERFACES** (building on Kent Beck's INTENTION-REVEALING SELECTOR, Beck 1997):
  > Name classes and operations to describe their effect and purpose, without reference to the means by which they do what they promise. This relieves the client developer of the need to understand the internals. These names should conform to the UBIQUITOUS LANGUAGE so that team members can quickly infer their meaning. **Write a test for a behavior before creating it, to force your thinking into client developer mode.**
  - The rule for public interfaces of the domain: *"state relationships and rules, but not how they are enforced; describe events and actions, but not how they are carried out; formulate the equation but not the numerical method to solve it. **Pose the question, but don't present the means by which the answer shall be found.**"*
  - Why it matters beyond convenience: if a new developer must infer purpose from implementation, they may infer a purpose the operation fulfills **only by chance** — the code works for the moment, but the conceptual basis of the design is corrupted and two developers work at cross-purposes.

- **SIDE-EFFECT-FREE FUNCTIONS**:
  > Place as much of the logic of the program as possible into functions, operations that return results with no observable side effects. Strictly segregate commands (methods that result in modifications to observable state) into very simple operations that do not return domain information. Further control side effects by moving complex logic into VALUE OBJECTS when a concept fitting the responsibility presents itself.
  - Two mitigations: (1) keep commands and queries strictly segregated, ensuring change-causing methods return no domain data (Meyer 1988); (2) find models where nothing existing needs modifying — return a **new VALUE OBJECT** representing the result.
  - The two-step refactoring: first separate modification from querying (Fowler 1999, p. 279) — *this only applies to ENTITIES* — then consider moving the complex calculation into a VALUE OBJECT. "The side effect often can be completely eliminated by deriving a VALUE OBJECT instead of changing existing state, or by moving the entire responsibility into a VALUE OBJECT."
  - Why "side effect" is the right term even for intentional changes: with arbitrarily deep nesting of operations, the client developer never intended the second- and third-tier effects — *"they've become side effects in every sense of the phrase."*
  - VALUE OBJECTS are immutable, so apart from initializers, **all** their operations are functions.

- **ASSERTIONS** (design by contract, Meyer 1988):
  > State post-conditions of operations and invariants of classes and AGGREGATES. If ASSERTIONS cannot be coded directly in your programming language, write automated unit tests for them. Write them into documentation or diagrams where it fits the style of the project's development process.
  >
  > Seek models with coherent sets of concepts, which lead a developer to infer the intended ASSERTIONS, accelerating the learning curve and reducing the risk of contradictory code.
  - Vocabulary: **post-conditions** describe guaranteed outcomes; **preconditions** are "the fine print on the contract" — what must hold for the guarantee to apply; **class invariants** assert object state at the end of any operation, and can be declared for entire AGGREGATES, rigorously defining integrity rules.
  - Why they work: **all assertions describe state, not procedures**, so they're easier to analyze *and* easy to test (setup establishes preconditions; post-execution checks post-conditions).
  - Why they're necessary: object interfaces don't restrict side effects, so two subclasses implementing the same interface can have different ones. Without ASSERTIONS, "the only way to understand a program is to trace execution through branching paths. The value of encapsulation is lost. The necessity of tracing concrete execution defeats abstraction."
  - The human constraint: *"humans don't just compile predicates in their heads. They will be extrapolating and interpolating the concepts of the model"* — so any noncontradictory assertion set would work in theory, but only ones that make sense to people work in practice.

- **CONCEPTUAL CONTOURS**:
  > Decompose design elements (operations, interfaces, classes, and AGGREGATES) into cohesive units, taking into consideration your intuition of the important divisions in the domain. **Observe the axes of change and stability through successive refactorings and look for the underlying CONCEPTUAL CONTOURS that explain these shearing patterns.** Align the model with the consistent aspects of the domain that make it a viable area of knowledge in the first place.
  - The three oversimplified rules it replaces: chop fine for flexible combination; lump large to encapsulate complexity; seek consistent granularity across all classes. *"Cookbook rules don't work."*
  - **"Half of a uranium atom is not uranium."** And: "it isn't just grain size that counts, but just where the grain runs."
  - The test question for each decision: *"Is this an expedient based on a particular set of relationships in the current model and code, or does it echo some contour of the underlying domain?"*
  - **Fit indicator**: when successive refactoring tends to be **localized**, not shaking multiple broad concepts, the model fits. A requirement forcing extensive changes to the breakdown of objects and methods is *a message* — the domain understanding needs refinement.
  - Also: clump what users don't dissect. Paint-mixing users combine complete paints, not individual pigments. A paint chemist would need a far finer model — "but it is simply irrelevant to anyone involved in the paint mixing application project."

- **STANDALONE CLASSES**:
  - Every association is a dependency; so is the type of every argument and every return value. "With three dependencies… it snowballs."
  - **Implicit concepts count as much as explicit references.** You can ignore a dependency on `int`, but not on *what it represents* — three public ints for red/yellow/blue carried the color concept invisibly. Creating `Pigment Color` did **not** increase the concept count; it made an existing one explicit. Conversely `Collection.size()` returning an `int` implies no new concept — it's just a count.
  - **"Every dependency is suspect until proven basic to the concept behind the object."**
  - The goal is *not* eliminating all dependencies but all **nonessential** ones. Dependencies within the same MODULE are less harmful than external ones; and when two objects are naturally tightly coupled, multiple operations on the same pair can actually clarify the relationship.
  - Technique: **factor the most intricate computations into STANDALONE CLASSES, perhaps by modeling VALUE OBJECTS held by the more connected classes.**

- **CLOSURE OF OPERATIONS**:
  > Where it fits, define an operation whose return type is the same as the type of its argument(s). If the implementer has state that is used in the computation, then the implementer is effectively an argument of the operation, so the argument(s) and return value should be of the same type as the implementer. Such an operation is closed under the set of instances of that type. **A closed operation provides a high-level interface without introducing any dependency on other concepts.**
  - Mostly applies to **VALUE OBJECTS** — an ENTITY's life cycle has domain significance, so you can't conjure one up to answer a question. (Closed operations on ENTITIES exist — `anEmployee.supervisor()` returns an `Employee` — but ENTITIES aren't usually the result of a computation.)
  - Can be closed under an **abstract** type, so concrete arguments differ — "after all, addition is closed under real numbers, which can be either rational or irrational."
  - **Half-closure still helps**: when the extra type is a primitive or basic library class, "it frees the mind almost as much as CLOSURE."

- **Two Angles of Attack** — you can't look at an enormous system and say "let's make this supple":
  1. **Carve off subdomains.** Pick away. See a part that's specialized math — separate it. Complex rules restricting state changes — pull them into a separate model or small framework you can declare rules in. With each step, the new module is clean **and the part left behind is smaller and clearer**, and partly written in a declarative style. *"It is more useful to make a big impact on one area… than to spread your efforts thin."*
  2. **Draw on established formalisms when you can.** Creating a tight conceptual framework from scratch is not an everyday achievement. Accounting supplies a well-developed set of ENTITIES and rules. Evans' personal favorite is **math**: "Many domains include math somewhere. Look for it. Dig it out. Specialized math is clean, combinable by clear rules, and people find it easy to understand."

- **Declarative Design** — writing part of a program as an executable specification, where a precise description of properties actually controls the software (via reflection or compile-time code generation). *"This approach allows another developer to take the declaration at face value. It is an absolute guarantee."*
  - **Two recurring pitfalls Evans has hit more than once:**
    1. A declaration language not expressive enough to do everything needed, plus a framework that makes it very difficult to extend beyond the automated portion.
    2. Code-generation that cripples the iterative cycle by merging generated code into handwritten code so that regeneration is very destructive.
  - The unintended consequence: **dumbing-down of the model and application**, as developers trapped by framework limits "enact design triage in order to get *something* delivered."
  - Rules engines are declarative *in principle*, but most systems add **control predicates** for performance tuning — which introduce side effects, so behavior is no longer dictated by the declared rules, and adding/removing/reordering rules can cause unexpected incorrect results.
  - Any declarative approach can be corrupted if developers bypass it — likely when the system is difficult to use or overly restrictive. **Everyone has to follow the framework's rules to get the benefits.**
  - **Where the value actually lands**: "a narrowly scoped framework [that] automates a particularly tedious and error-prone aspect of the design, such as persistence and object-relational mapping. The best of these unburden developers of drudge work while leaving them complete freedom to design."
  - **Domain-specific languages**: extremely expressive, strongest connection to the UBIQUITOUS LANGUAGE — but refining the model means modifying grammar declarations and class libraries; you lose the seamlessness of app and model in one language; and refactoring client code to a revised DSL is hard. Assess the team's *and future maintainers'* skills soberly. Functional languages (Scheme) get this without bifurcating the system.
  - **A declarative *style*** is the achievable version: once you have INTENTION-REVEALING INTERFACES, SIDE-EFFECT-FREE FUNCTIONS, and ASSERTIONS, you have combinable elements that communicate their meaning and have characterized or no observable effects — most of the benefit, none of the framework risk.

## Key Concepts
- **Supple design** — a design that is a pleasure to work with and inviting to change.
- **Command vs. query** — modifiers vs. information-obtaining operations; "side effect" narrowed to *any change in system state that will affect future operations*.
- **Function** — an operation returning a result with no side effects; callable repeatedly with the same value; nestable without worry; easy to test; **lowers risk**.
- **Post-condition / precondition / class invariant** — the assertion vocabulary.
- **CONCEPTUAL CONTOUR** — the underlying division in a domain that explains where a design shears under change.
- **STANDALONE CLASS** — a class understandable entirely alone, apart from primitives and basic library concepts; the extreme of low coupling.
- **CLOSURE OF OPERATIONS** — an operation whose return type matches its argument/implementer type.
- **Subsumption** — one SPECIFICATION being strictly more stringent than another; equivalent to logical implication.
- **Declarative design / domain-specific language** — see above.

## Code Examples

**Command/query separation, then move the calculation into a VALUE OBJECT:**

```java
// Before: mixIn does everything, color logic buried in Paint
public void mixIn(Paint other) {
   volume = volume.plus(other.getVolume());
   // Many lines of complicated color-mixing logic
   // ending with the assignment of new red, blue, and yellow values.
}

// After: PigmentColor is an immutable VALUE OBJECT with a
// SIDE-EFFECT-FREE FUNCTION
public class PigmentColor {
   public PigmentColor mixedWith(PigmentColor other, double ratio) {
      // ...complicated color-mixing logic, returning a NEW PigmentColor
   }
}

public class Paint {
   public void mixIn(Paint other) {
      volume = volume + other.getVolume();
      double ratio = other.getVolume() / volume;
      pigmentColor = pigmentColor.mixedWith(other.pigmentColor(), ratio);
   }
}
```

- **What it demonstrates**: the modification code in `Paint` is now as simple as possible; the complex color logic is *truly* encapsulated — safe, easy to understand, **easy to test**, and safe to combine, so developers never need to read the implementation.

**Note on naming**: "Color" was the first name that came to mind, but earlier knowledge crunching had established that **color mixing for paint differs from RGB light display** — so the name had to reflect that. `Pigment Color`.

**CLOSURE OF OPERATIONS, and how half-closure still frees the mind:**

```java
// Java: the Iterator is an extra concept with mechanical complexity
Set employees = (some Set of Employee objects);
Set lowPaidEmployees = new HashSet();
Iterator it = employees.iterator();
while (it.hasNext()) {
   Employee anEmployee = it.next();
   if (anEmployee.salary() < 40000)
      lowPaidEmployees.add(anEmployee);
}
```

```smalltalk
"Smalltalk: select returns a Collection; blocks are a basic library type"
employees := (some Set of Employee objects).
lowPaidEmployees := employees select:
         [:anEmployee | anEmployee salary < 40000].
```

- **What it demonstrates**: *"Conceptually, I've selected a subset of a set. What do I need with this extra concept, `Iterator`, and all its mechanical complexity?"* The Smalltalk operations are **not** closed (they take a block), but blocks add nothing to mental load, and because the return matches the implementer they string together like a series of filters.

**Composable SPECIFICATIONS (extending Ch 9 declaratively):**

```java
public interface Specification {
   boolean isSatisfiedBy(Object candidate);
   Specification and(Specification other);
   Specification or(Specification other);
   Specification not();
}

public abstract class AbstractSpecification implements Specification {
   public Specification and(Specification other) {
      return new AndSpecification(this, other);
   }
   public Specification or(Specification other) {
      return new OrSpecification(this, other);
   }
   public Specification not() {
      return new NotSpecification(this);
   }
}

public class AndSpecification extends AbstractSpecification {
   Specification one, other;
   public boolean isSatisfiedBy(Object candidate) {
      return one.isSatisfiedBy(candidate) && other.isSatisfiedBy(candidate);
   }
}
// OrSpecification, NotSpecification analogous
```

Client usage reads declaratively:

```java
Specification ventilated = new ContainerSpecification(VENTILATED);
Specification armored    = new ContainerSpecification(ARMORED);
Specification both       = ventilated.and(armored);

Specification either = ventilatedType1.or(ventilatedType2);
Specification cheap  = (ventilated.not()).and(armored.not());
```

That last line "would have prevented some of the suboptimal behavior of the prototype warehouse packer discussed in Chapter 9."

**Evans' practical advice**: AND is used far more than the others and creates less implementation complexity. **"Don't be afraid to implement only AND, if that is all you need."** And more generally: *"Using a pattern doesn't mean building features you don't need. They can be added later, as long as the concepts don't get muddled."*

**Subsumption** — comparing two SPECIFICATIONS directly, equivalent to logical implication (`New Spec ⇒ Old Spec`):

```java
public class MinimumAgeSpecification {
   int threshold;
   public boolean isSatisfiedBy(Person candidate) {
      return candidate.getAge() >= threshold;
   }
   public boolean subsumes(MinimumAgeSpecification other) {
      return threshold >= other.getThreshold();
   }
}

drivingAge = new MinimumAgeSpecification(16);
votingAge  = new MinimumAgeSpecification(18);
assertTrue(votingAge.subsumes(drivingAge));
```

With only AND, proving implication is simple (`A AND B ⇒ A`), so a Composite Specification need only check that the subsuming spec's leaves are a **superset** of the subsumed one's. Evans' warning: **when OR and NOT are included, these proofs become much more involved** — in most situations, forgo some operators or forgo subsumption; if you need both, "consider carefully if the benefit is great enough to justify the difficulty."

## Reference — Alternative COMPOSITE SPECIFICATION implementation

Evans reports a real mistake: on a project with an object database that assigned an object ID to every object and tracked it, the fine-grained composite implementation produced **millions of very fine grained objects that contributed to bogging the system down.** The alternative encodes the logical expression as a string or array interpreted at runtime — e.g. a stack yielding `and(not(armored), not(ventilated))`.

| | Fine-grained composite | Encoded expression |
|---|---|---|
| Object count | High | **Low** |
| Memory | Heavy in constrained environments | **Efficient** |
| Developer sophistication needed | Low | **Higher** |

**"The same pattern and model can underlie very different implementations."** And: *"The important thing is a model that captures the key concepts of the domain, along with an implementation that is faithful to that model. That leaves a lot of room to solve performance problems."*

## Worked Example — Paint Mixing and the Assertion That Didn't Fit

Stating the post-condition of `mixIn()` **as it actually was**:

> After `p1.mixIn(p2)`:
> - `p1.volume` is increased by amount of `p2.volume`.
> - `p2.volume` is unchanged.

This doesn't match physical intuition — mixing should deplete the other paint to zero. The obvious fix (modify the argument) is a *particularly risky* kind of side effect, but would be easy and intuitive, giving the clean invariant *"Total volume of paint is unchanged by mixing."*

**Then the discovery:** the original designers had a compelling reason. At the end, the program **reports the list of unmixed paints that were added** — because the ultimate purpose of the application is to help a user figure out which paints to *put into* a mixture.

So making the volume model logically consistent would make it **unsuitable for its application requirements**. Are we stuck documenting a weird post-condition? *"Not everything in this world is intuitive, and sometimes that is the best answer. But in this case, the awkwardness seems to point to missing concepts."*

**The resolution — split `Paint`'s two responsibilities** into `StockPaint` and `MixedPaint`. Now there is exactly **one command, `mixIn()`, which merely adds an object to a collection** — an effect apparent from an intuitive understanding of the model. Every other operation is a SIDE-EFFECT-FREE FUNCTION.

```java
public void testMixingVolume {
   PigmentColor yellow = new PigmentColor(0, 50, 0);
   PigmentColor blue = new PigmentColor(0, 0, 50);
   StockPaint paint1 = new StockPaint(1.0, yellow);
   StockPaint paint2 = new StockPaint(1.5, blue);
   MixedPaint mix = new MixedPaint();
   mix.mixIn(paint1);
   mix.mixIn(paint2);
   assertEquals(2.5, mix.getVolume(), 0.01);
}
```

*"This model captures and communicates more of the domain. The invariants and post-conditions make common sense, which will make them easier to maintain and use."*

## Worked Example — The Contours of Accruals (an unanticipated change)

The Ch 9 loan-tracking refactoring added **only one more object** than the old model, yet greatly changed the partitioning of responsibility:
- Schedules, previously case logic inside `Calculator` classes, were **exploded** into discrete classes per fee/interest type.
- Payments of fees and interest, previously kept separate, were **lumped together**.

The developer believed the resonance of the newly explicit concepts and the cohesion of the `Accrual Schedule` hierarchy meant the model followed real CONCEPTUAL CONTOURS. She could confidently predict one change — new `Accrual Schedule`s were already waiting in the wings — so she chose a model that made those easy. *"But had she found a CONCEPTUAL CONTOUR that will help the domain design change and grow as the application and the business evolve? There can be no guarantees… but she thought it had improved the odds."*

**The unanticipated change**: detailed rules for handling early and late payments. Studying it, she found **virtually the same rules applied to interest payments and fee payments** — so the new elements connected naturally to the single `Payment` class. The old design would have forced duplication between two `Payment History` classes.

> This ease of extension did not come because she anticipated the change. Nor did it come because she made a design so versatile it could accommodate any conceivable change. **It happened because in the previous refactoring, the design was aligned with underlying concepts of the domain.**

## Worked Example — Integrating the Patterns: Shares Math

*(The design behind the Ch 8 syndicated-loan breakthrough.)* Requirement: when the borrower makes a principal payment, the money is by default prorated according to lenders' shares in the loan.

**Step 0 — the starting point.** `Loan.distributePrincipalPayment(double)` iterated the shares map, computed each payment share, built new `Share` objects, mutated the loan's share map, and returned the payment shares. It already had INTENTION-REVEALING INTERFACES — but it **calculated and modified in one method**.

**Step 1 — separate command from query.**

```java
Map distribution = aLoan.calculatePrincipalPaymentShares(paymentAmount);
aLoan.applyPrincipalPaymentShares(distribution);
```

Better — but *"the code does begin to multiply some when we add `applyDrawdown()`, `calculateFeePaymentShares()`, and so on. Each extension complicates the code and weighs it down."* The conventional response is to break the calculation into subroutines; that could be a good step along the way, **but the goal is to see the underlying conceptual boundaries and deepen the model.**

**Step 2 — make the implicit concept explicit.** The `Share` objects are passive and manipulated in complex, low-level ways, *because most rules and calculations about shares don't apply to a single share but to groups of them.* The missing concept: **shares are related to each other as parts making up a whole** → `Share Pie`, initially an ENTITY whose identity is local within the `Loan` AGGREGATE.

```java
public class Loan {
   private SharePie shares;
   public Map calculatePrincipalPaymentDistribution(double paymentAmount) {
      return getShares().prorated(paymentAmount);
   }
   public void applyPrincipalPayment(Map paymentShares) {
      shares.decrease(paymentShares);
   }
}
```

Simpler — *"Still, the calculations haven't really become more versatile or easier to use."*

**Step 3 — cascade of insight: make `Share Pie` a VALUE OBJECT.** *"Often, the hands-on experience of implementing a new design will trigger a new insight into the model itself."* The tight coupling of `Loan` and `Share Pie` was obscuring the relationship of `Share Pie` and `Share`.

Immutability forbids `increase()`/`decrease()`. Go all the way to CLOSURE OF OPERATIONS: instead of adding Shares to a Pie, **add two Share Pies together**. Rename `prorate()` to `prorated()` to emphasize its lack of side effects. "Shares Math" takes shape with four operations, each carrying a plain-language ASSERTION:

| Operation | Assertion |
|---|---|
| `getAmount()` | The whole is equal to the sum of its parts. |
| `minus(SharePie)` | The difference between two Pies is the difference between each owner's share. |
| `plus(SharePie)` | The combination of two Pies is the combination of each owner's share. |
| `prorated(double)` | An amount can be divided proportionately among all shareholders. |

**The result — `Loan` reads like a definition of the business transaction, not a calculation:**

```java
public class Loan {
   private SharePie shares;
   public SharePie calculatePrincipalPaymentDistribution(double paymentAmount) {
      return shares.prorated(paymentAmount);
   }
   public void applyPrincipalPayment(SharePie paymentShares) {
      setShares(shares.minus(paymentShares));
   }
}

public class Facility {
   private SharePie shares;
   public SharePie calculateDrawdownDefaultDistribution(double drawdownAmount) {
      return shares.prorated(drawdownAmount);
   }
}

public class Loan {
   public void applyDrawdown(SharePie drawdownShares) {
      setShares(shares.plus(drawdownShares));
   }
}
```

Transaction types "too complicated to list before" are now one line each. And a genuinely new question becomes trivial — each lender's deviation from its agreed contribution:

```java
SharePie originalAgreement = aFacility.getShares().prorated(aLoan.getAmount());
SharePie actual            = aLoan.getShares();
SharePie deviation         = actual.minus(originalAgreement);
```

**Why this design recombines so freely — the four properties:**
1. **Complex logic is encapsulated in specialized VALUE OBJECTS with SIDE-EFFECT-FREE FUNCTIONS.** Because Share Pies are VALUES, math operations create new instances freely replacing outdated ones. No method changes any existing object, so `plus()`, `minus()`, and `prorated()` can be used in intermediate calculations — **and analytical features can be built on the same methods. Before, they could be called only when an actual distribution was made, because the data would change after each call.**
2. **State-modifying operations are simple and characterized with ASSERTIONS**, letting transaction invariants be written concisely and declaratively.
3. **Model concepts are decoupled.** `plus`/`minus` exhibit CLOSURE; others take or return simple amounts and add little conceptual load. `Share Pie` interacts closely with only `Share` — so it is self-contained, easily understood, easily tested, easily combined. *"These properties were inherited from the math formalism."*
4. **Familiar formalism makes the protocol easy to grasp.** A wholly original protocol in financial terminology could in principle have been made supple — but it would have had to be **invented** (difficult and uncertain) and then **learned** by everyone who touched it. *"People who see Shares Math recognize a system they already know, and because the design has been kept carefully consistent with the rules of arithmetic, those people are not misled."*

## Anti-patterns
- **Overengineering justified as flexibility** — "more often than not, excessive layers of abstraction and indirection get in the way."
- **Duplication from fear** — "Duplication starts to appear as soon as a developer isn't confident of predicting the full implications of a computation." And it is *forced* when design elements are monolithic so parts can't be recombined.
- **Breaking classes and methods down for reuse without conceptual grounding** — "it gets hard to keep track of what all the little parts do," and a concept can be lost completely.
- **Operations that mix calculation with state change** — the original `distributePrincipalPayment()`.
- **Modifying arguments** — a particularly risky kind of side effect.
- **Reducing everything to primitives to eliminate dependencies** — "Eliminating dependencies should not mean dumbing down the model." Stripping interfaces to primitives impoverishes them.
- **Framework-driven design triage** — the characteristic failure of declarative approaches.
- **Fine-grained COMPOSITE objects in an environment hostile to them** — Evans' own million-object mistake.

## Key Takeaways
1. Write the test first in the shape you *wish* the API had; refactor until it compiles and passes — that is the mechanism of INTENTION-REVEALING INTERFACES, not just a testing habit.
2. Name for effect and purpose, never for means, and conform names to the UBIQUITOUS LANGUAGE.
3. Segregate commands from queries; then push complex calculation into an immutable VALUE OBJECT so the command becomes trivial.
4. State post-conditions and invariants; if the language won't hold them, put them in unit tests or documentation — and prefer models whose assertions a developer can *infer*.
5. When the honest assertion is counterintuitive, treat it as a signal of a missing concept — but check first whether the odd behavior is serving a real requirement.
6. Decompose along conceptual contours discovered through refactoring, not by uniform granularity; localized refactorings mean the model fits, sweeping ones mean it doesn't.
7. Treat every dependency as suspect until proven essential, counting implicit concepts carried in primitives.
8. Prefer operations closed under their own type; even partial closure with a primitive frees the mind almost as much.
9. Get most of declarative design's benefit through a declarative *style* — combinable elements with communicated meaning and characterized effects — rather than betting on a framework or DSL.
10. Attack suppleness by carving off one subdomain at a time, and reach for established formalisms (accounting, math) instead of inventing conceptual frameworks.

## Connects To
- **Ch 5 (Model Expressed in Software)**: ENTITY vs. VALUE OBJECT is what makes SIDE-EFFECT-FREE FUNCTIONS and CLOSURE possible; WHOLE VALUE (Ward Cunningham) recurs as a CONCEPTUAL CONTOURS heuristic.
- **Ch 6 (Life Cycle)**: AGGREGATE invariants as ASSERTIONS; MODULES and AGGREGATES as the coarse tools for limiting interdependency that STANDALONE CLASSES refines.
- **Ch 8 (Breakthrough)**: this chapter is the detailed design behind the Share Pie story.
- **Ch 9 (Making Implicit Concepts Explicit)**: SPECIFICATION is extended here with logical operators and subsumption; the Accruals model is re-examined for its contours; the warehouse packer's `cheap` container constraint is finally expressible.
- **Ch 15 (Distillation)**: COHESIVE MECHANISMS, GENERIC SUBDOMAINS, and CORE DOMAIN — where "carve off subdomains" is developed strategically.
- **Ch 16 (Large-Scale Structure)**: cohesion and coupling at the largest scale.
- **Beck 1997** (INTENTION-REVEALING SELECTOR), **Meyer 1988** (design by contract, command-query separation), **Fowler 1999** (separate query from modifier), **Ward Cunningham** (WHOLE VALUE).
