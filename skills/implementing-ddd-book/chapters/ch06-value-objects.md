# Chapter 6: Value Objects

## Core Idea
Favor Value Objects over Entities wherever the concept *measures, quantifies, or describes* a thing rather than *is* a thing — immutable, replaceable, side-effect-free Values are cheaper to develop, test, and maintain, and they shrink the responsibility you take on when integrating with other Bounded Contexts.

## Frameworks Introduced
- **Value Characteristics checklist**: a concept should be modeled as a Value Object if it possesses *most* of these six characteristics (the overarching precondition is that it expresses the Ubiquitous Language):
  - **Measures, Quantifies, or Describes**: it is not a thing in the domain; it measures/quantifies/describes a thing (age measures years lived; name describes what a person is called).
  - **Immutable**: unchangeable after construction. Only the primary constructor may self-delegate to setters; all setters are private; no other method mutates state.
  - **Conceptual Whole** (Cunningham's *Whole Value*): related attributes compose one integral unit. `{50,000,000 dollars}` is one Value, not `amount` + `currency` attributes. The Whole Value must be initialized atomically in one constructor call — never built up piece by piece.
  - **Replaceability**: when the measurement/description changes, replace the entire Value rather than mutate it (`total = 4`, `name = name.withMiddleInitial("L")`).
  - **Value Equality**: equality compares type plus all attributes; equal Values are interchangeable when assigned to an Entity property. Requires matching `hashCode()`.
  - **Side-Effect-Free Behavior** (Evans; Meyer's *Query* half of CQS): every method is a function — produces output, modifies nothing.
  - When to use: any time you are about to add an attribute (or a cluster of weakly related attributes) to an Entity, or about to use a `String`/`int`/`Double` for a domain concept.
  - How: (1) ask whether the concept describes or *is*; (2) name it from the Ubiquitous Language of its Bounded Context; (3) give it a full-state constructor plus a copy constructor; (4) make every setter private and every query method side-effect free; (5) implement `equals()`/`hashCode()`/`toString()`; (6) pass only Values (never Entities) as parameters to its methods.
  - Why it works: immutability plus Value equality means instances are freely shareable, trivially testable, and cannot drift into an invalid state. Failure mode: overuse — a Boolean or a self-contained number that needs no behavior and relates to nothing else is already a meaningful whole; wrapping it buys nothing.

- **Challenge Your Assumptions** (recurring test): before creating an Entity because "the attributes must change," ask whether replacement would work; before mutating, ask whether a Side-Effect-Free Function returning a new Value would work; before claiming unique identity is needed, ask whether Value equality suffices.

- **Integrate with Minimalism**: model concepts flowing in from an upstream Context as Value Objects in the downstream Context.
  - When to use: any integration where the downstream Context needs only a fraction of an upstream Aggregate's state.
  - How: (1) query the upstream Open Host Service through your Anticorruption Layer; (2) create a statically created Value naming the *role* the upstream object plays (e.g. `Moderator`); (3) retain only the few attributes your Language needs; (4) explicitly decide the quality-of-service contract — usually "no synchronization with the remote Context."
  - Why it works: immutable Values mean you assume less responsibility. Use an Aggregate downstream only when you genuinely need a thread of continuity of change (eventual consistency with remote state).

- **Standard Types expressed as Values**: descriptive objects that indicate the *type* of a thing (aka type code, lookup) — `Home`/`Mobile`/`Work` phone, `AUD`/`CAD`/`USD` currency, `IV`/`Oral`/`Topical` administration route.
  - How: (1) prefer a Java `enum` — finite, lightweight, side-effect free by convention; (2) let the enum double as an elegant `State` object by declaring default behaviors at the bottom and overriding per constant; (3) skip textual descriptions — those are usually localized User Interface Layer concerns; (4) if there are many instances, code-generate the enum from the system-of-record store; (5) alternatively supply shared immutable Values via a Domain Service or Factory per type category, which enables safe caching.

- **Reject Undue Influence of Data Model Leakage** — four questions to keep the domain perspective when the data model forces entity-like storage:
  1. Is the concept a thing, or does it measure/quantify/describe a thing?
  2. Does it possess all or most of the Value characteristics?
  3. Am I considering an Entity *only* because the data model must store it as a database entity?
  4. Am I using an Entity because the domain requires unique identity and continuity of change?
  - Answers "Describes, Yes, Yes, No" ⇒ Value Object. **Design your data model for the sake of your domain model, not your domain model for the sake of your data model.**

## Key Concepts
- **Whole Value**: a Value whose attributes only convey meaning together, as a single integral measure or description.
- **Property vs. attribute**: the containing object holds a *property* referencing a Value; the Value itself has *attributes*.
- **Side-Effect-Free Function**: an operation producing output without modifying its own state — the Query half of Command-Query Separation.
- **Replacement**: assigning a whole new Value instance instead of mutating the existing one.
- **Copy constructor**: a shallow-copy constructor used chiefly to prove immutability in tests.
- **Standard Type**: a descriptive Value distinguishing types of a thing; often native Entities in a separate Context, consumed as Values.
- **Self-delegation / self-encapsulation**: constructors and methods go through private accessors, which can host Assertions (guards) and derived attributes.
- **Guard**: an Assertion in a setter/method that rejects obviously invalid parameters at the boundary.
- **Layer Supertype (`IdentifiedDomainObject`/`IdentifiedValueObject`)**: abstract bases hiding an ORM surrogate primary key from model clients.

## Mental Models
- Think of a Value as an *adjective phrase about a thing*, not the thing — if you can say "the X measures/describes Y," it's a Value.
- Use replacement when you catch yourself writing a mutator: `name = name.withMiddleInitial("L")` expresses the same change as a setter but keeps the Whole Value intact.
- Think of a `String`/`Double` attribute as a leak in progress: the domain logic for that concept is escaping into client code (capitalizing a name, converting a currency). Wrap it and pull the logic back in.
- Treat the persistence model as a projection you control: an entity-shaped table row does not make the concept an Entity.

## Anti-patterns
- **Attribute soup on an Entity** (`name`, `amount`, `currency` as three loose fields): clients must know when and how to combine them; no conceptual whole.
- **Primitive obsession / patching the language type** (adding `convertToCurrency()` to `Double`): domain behavior is lost in general-purpose responsibilities, the type says nothing about your domain, and the Ubiquitous Language is abandoned.
- **Passing Entities into Value methods** (`businessPriority.priorityOf(product)`): the Value must understand the Entity's shape, the code hides which parts are used, and you cannot prove the method is side-effect free. Pass a Value the Entity derives instead.
- **Building a Value up piece by piece** after construction: destroys atomic wholeness and immutability.
- **Full JavaBean Values with public setters**: violates the essential immutability characteristic even if tooling wants getters.
- **Letting the data model drive the domain model**: your model degrades into a projection of normalized tables.

## Code Examples
```java
public FullName withMiddleInitial(String aMiddleNameOrInitial) {
    if (aMiddleNameOrInitial == null) {
        throw new IllegalArgumentException(
                "Must provide a middle name or initial.");
    }
    String middle = aMiddleNameOrInitial.trim();
    if (middle.isEmpty()) {
        throw new IllegalArgumentException(
                "Must provide a middle name or initial.");
    }
    return new FullName(
            this.firstName(),
            middle.substring(0, 1).toUpperCase(),
            this.lastName());
}
```
- **What it demonstrates**: Side-Effect-Free Behavior producing Whole Value replacement — the naming/formatting logic stays inside the model instead of leaking to clients, and the original instance is untouched.

## Reference Tables

### ORM persistence strategies for Value Objects
| Strategy | Hibernate mechanism | Use when | Trade-offs |
|---|---|---|---|
| **Single Value Object** | `<component>` (nestable), columns named by navigation path (`business_priority_ratings_benefit`) | One Value instance held by a parent Entity | Denormalized into the parent row — optimal, no joins, fully queryable in HQL. The default and best case. |
| **Many Values serialized into one column** | Custom user type serializing the whole collection to text | Small, bounded collections whose attributes never need SQL querying | Risk of column-width/row-size overflow (MySQL InnoDB 65,535 bytes/row; Oracle `VARCHAR2` 4,000); attributes are not queryable; requires a custom user type (one generic implementation can serve all Value types). |
| **Many Values backed by a database entity** | `<set cascade="all,delete-orphan">` + `<one-to-many>`, surrogate key via `IdentifiedValueObject` Layer Supertype | The general-purpose choice for Value collections | Requires a hidden surrogate primary key and a join, but no constraints on nulls or nested collections. Vernon's preferred approach. Call `clear()` before whole-collection replacement to avoid orphans. |
| **Many Values backed by a join table** | `<composite-element>` | Value type has no nulls, holds no collection, and you refuse a surrogate key | No surrogate identity needed; but still requires a join; for a `Set` **no attribute may be null** (all attributes form the composite delete key); the Value may not itself contain a collection. Limiting enough to deserve general avoidance. |
| **Enum-as-State** | Custom user type (e.g. `GroupMemberTypeUserType`) storing the text representation | Standard Types / State objects modeled as Java enums | Hibernate has no out-of-the-box enum property type; you must supply a custom user type (parameterized variants avoid one class per enum). Column sized to the widest constant name. |

### Model/Persistence perspective decision
| Question | Value Object answer |
|---|---|
| Thing or description? | Describes |
| Possesses most Value characteristics? | Yes |
| Choosing Entity only because the data model stores it as an entity? | Yes (⇒ ignore the data model) |
| Need unique identity + continuity of change? | No |

## Worked Example
**`BusinessPriority` in the Agile Project Management Context, driven out test-first.** Domain experts speak of "the business priority of backlog items," so the team models `BusinessPriority` holding one property `ratings` of type `BusinessPriorityRatings` (benefit, cost, penalty, risk).

Each test follows the same shape, which is simultaneously a *specification of immutability*:

```java
public void testCostPercentageCalculation() throws Exception {
    BusinessPriority businessPriority =
        new BusinessPriority(new BusinessPriorityRatings(2, 4, 1, 1));
    BusinessPriority businessPriorityCopy =
        new BusinessPriority(businessPriority);   // copy constructor
    assertEquals(businessPriority, businessPriorityCopy);

    BusinessPriorityTotals totals =
        new BusinessPriorityTotals(53, 49, 53 + 49, 37, 33);

    float cost = businessPriority.costPercentage(totals);
    assertEquals(this.oneDecimal().format(cost), "2.7");

    assertEquals(businessPriority, businessPriorityCopy); // still equal ⇒ side-effect free
}
```

Steps: create the Value; copy it with the copy constructor; assert equality; exercise the behavior; assert the manually calculated result; assert equality *again* to prove no mutation occurred. The same pattern covers `priority()` (1.03), `totalValue()` (6.0), and `valuePercentage()` (5.9).

Design outcomes the tests forced: calculation methods take a `BusinessPriorityTotals` **Value** (not the `Product` Entity); query methods are named fluently (`valuePercentage()`, not `getValuePercentage()`) to stay faithful to the Ubiquitous Language; the calculations form a **Strategy/Policy** — with only one implementation today, no Separated Interface is created yet. A protected zero-argument constructor exists solely for Hibernate; the `setRatings()` guard throws `IllegalArgumentException` on null. Nontechnical domain experts could read these tests and confirm the model matched their Language.

The follow-on insight: `Product` should not calculate business priority totals at all — that becomes a Domain Service (ch07).

## Key Takeaways
1. Run every candidate concept through the six Value characteristics before reaching for an Entity; you will use Values far more often than you expected.
2. Model the Whole Value — group related attributes into a named type and initialize it atomically in one constructor.
3. Replace, don't mutate; express replacement through Side-Effect-Free Functions that return a new instance built from the old one's parts.
4. Pass only Values as parameters to Value methods so that side-effect freedom is provable and testable.
5. Use Values to model concepts imported from upstream Bounded Contexts — integrate with minimalism and assume less responsibility.
6. Prefer Java enums for Standard Types (and as a clutter-free State pattern); reach for a Service/Factory-provided shared Value only when the type set lives in a standards database.
7. Choose the ORM strategy that fits the collection, but never let the resulting database entity shape turn a Value into an Entity in the model.

## Connects To
- **ch05**: Entities are the alternative — use one only when unique identity and continuity of change over a life cycle are genuinely required.
- **ch02**: Bounded Context and Ubiquitous Language determine the *names* of Value types and their properties; downstream Contexts model upstream concepts as Values.
- **ch03**: Anticorruption Layer / Open Host Service are how the upstream state arrives before you model it as a Value (e.g. `Moderator`).
- **ch07**: Domain Services provide Standard Types from a store, and take over calculations that don't belong on a Value or Entity.
- **ch10**: Aggregate unique identity is itself a Value — needing Value equality, immutability, and conceptual wholeness, but not replaceability.
- **ch11 / ch12**: Factories create Standard Type Values; Repositories persist Values behind their parent Aggregate (key-value stores persist Aggregates especially well).
- **ch14**: Textual descriptions of Standard Types belong in the User Interface Layer; Presentation Model or DTO adapts fluent Values for EL/OGNL views.
- **Whole Value [Cunningham] / Side-Effect-Free Function [Evans] / CQS [Meyer, Fowler] / Layer Supertype & Separated Interface [Fowler, P of EAA] / State & Strategy [Gamma et al.]**: the external patterns Vernon composes into the Value Object pattern.
