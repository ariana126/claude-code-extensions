# Strategy
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Define a family of algorithms, encapsulate each one, and make them interchangeable. Strategy lets the algorithm vary independently from clients that use it.

## Also Known As
Policy

## Core Idea
Pull an algorithm out of the class that uses it and give it its own object behind a common interface. The **Context** delegates to whichever ConcreteStrategy it was configured with — so algorithms swap without the Context changing.

## Applicability
Use Strategy when:
- Many related classes differ only in their behavior — Strategy configures one class with one of many behaviors.
- You need different variants of an algorithm (e.g. reflecting different space/time trade-offs) implemented as a class hierarchy of algorithms.
- An algorithm uses data that clients shouldn't know about — Strategy avoids exposing complex, algorithm-specific data structures.
- A class defines many behaviors that appear as multiple conditional statements in its operations; move each related group of branches into its own Strategy class.

## Structure
- **Strategy** (Compositor): declares an interface common to all supported algorithms; Context calls the algorithm through it.
- **ConcreteStrategy** (SimpleCompositor, TeXCompositor, ArrayCompositor): implements the algorithm using the Strategy interface.
- **Context** (Composition): is configured with a ConcreteStrategy object, maintains a reference to it, and may define an interface letting the Strategy access its data.

Collaboration: a Context may pass all data the algorithm needs as parameters, or pass **itself** so the strategy can call back for what it wants. Context forwards client requests to its strategy; clients typically create and install a ConcreteStrategy and thereafter interact only with the Context.

## How
1. Identify the varying algorithm and the exact data it consumes.
2. Define the abstract `Strategy` interface — usually one operation — designed to serve *every* variant you anticipate, since changing it later breaks all existing subclasses.
3. Choose the data-passing scheme: parameters (decoupled) or `Context*` (precise).
4. Implement each variant as a ConcreteStrategy subclass.
5. Give Context a `Strategy*` member, set through its constructor or a setter, and forward the relevant request to it.
6. Optionally allow a null Strategy and have Context fall back to default behavior.

## Consequences
**Benefits**
- **Families of related algorithms.** Strategy hierarchies define families that contexts reuse; inheritance factors out functionality common to the algorithms.
- **An alternative to subclassing.** Subclassing the Context hard-wires the behavior into it, mixes algorithm with Context implementation, prevents varying the algorithm dynamically, and yields many related classes differing only in behavior. Encapsulating the algorithm separately lets you vary it independently, making it easier to switch, understand, and extend.
- **Strategies eliminate conditional statements.** When behaviors are lumped into one class, conditionals selecting the right one are almost unavoidable. Encapsulation removes them: *code containing many conditional statements often indicates the need to apply Strategy.*
- **A choice of implementations.** Strategies can provide different implementations of the *same* behavior, letting clients trade time against space.

**Liabilities**
- **Clients must be aware of different Strategies.** A client must understand how strategies differ before choosing, which exposes implementation issues. Use Strategy only when the variation in behavior is relevant to clients.
- **Communication overhead between Strategy and Context.** One interface serves trivial and complex algorithms alike, so some ConcreteStrategies won't use all the information passed — simple ones may use *none* of it. The Context creates and initializes parameters that never get used; fixing that requires tighter coupling.
- **Increased number of objects.** Reduce the overhead by making strategies **stateless** and shared, with residual state kept in the Context and passed in on each request. Shared strategies must not maintain state across invocations (see Flyweight).

## Implementation Notes
- **Defining the Strategy and Context interfaces — the data-passing problem.** Both interfaces must give a ConcreteStrategy efficient access to the data it needs, and vice versa. Option one: Context **passes data in parameters** — "take the data to the strategy." This keeps Strategy and Context decoupled, but Context may pass data the Strategy doesn't need. Option two: Context **passes itself**, and the strategy requests exactly what it wants; or the strategy stores a reference to its context, so nothing need be passed at all. Now the strategy asks for precisely what it needs, but Context must define a more elaborate interface to its data, coupling the two more closely. The algorithm's data requirements decide which is best.
- **Strategies as template parameters.** In C++, configure a class with a strategy at compile time when (1) the Strategy can be selected at compile time and (2) it need not change at run time:

  ```cpp
  template <class AStrategy>
  class Context {
      void Operation() { theStrategy.DoAlgorithm(); }
      // ...
  private:
      AStrategy theStrategy;
  };

  class MyStrategy {
  public:
      void DoAlgorithm();
  };

  Context<MyStrategy> aContext;
  ```

  With templates there's **no need for an abstract Strategy class** at all, and the static binding can increase efficiency — at the cost of run-time swappability.
- **Making Strategy objects optional.** If it's meaningful *not* to have a Strategy, Context checks for one and carries out default behavior when absent. Clients then never deal with Strategy objects unless they dislike the default — as with ObjectWindows' optional field `Validator`s.

## Worked Example
InterViews' text layout. A `Composition` holds `Component` instances (text and graphics) and delegates linebreaking to a `Compositor`.

Without Strategy, the layout code degenerates into a case statement:

```cpp
void Composition::Repair () {
    switch (_breakingStrategy) {
    case SimpleStrategy: ComposeWithSimpleCompositor(); break;
    case TeXStrategy:    ComposeWithTeXCompositor();    break;
    // ...
    }
    // merge results with existing composition, lay it out
}
```

With Strategy the switch disappears:

```cpp
class Compositor {                       // abstract Strategy
public:
    virtual int Compose(
        Coord natural[], Coord stretch[], Coord shrink[],
        int componentCount, Coord lineWidth, int breaks[]
    ) = 0;
protected:
    Compositor();
};

class Composition {                      // Context
public:
    Composition(Compositor*);
    void Repair();
private:
    Compositor* _compositor;
    Component* _components;              // the list of components
    int _componentCount;
    Coord _lineWidth;
    int* _lineBreaks;                    // where the breaks go
    int _lineCount;
};

void Composition::Repair () {
    Coord natural[100], stretchability[100], shrinkability[100];
    int componentCount, breaks[100];

    // prepare the arrays with the desired component sizes
    // ...

    int breakCount = _compositor->Compose(          // take the data to the strategy
        natural, stretchability, shrinkability,
        componentCount, _lineWidth, breaks
    );

    // lay out components according to breaks
}
```

`SimpleCompositor` breaks a line at a time (ignoring stretchability), `TeXCompositor` optimizes a whole paragraph and uses every argument, and `ArrayCompositor` puts a fixed number of items per row and **ignores everything passed to it** — the communication-overhead liability made concrete. Instantiate with `Composition* quick = new Composition(new SimpleCompositor);`.

It demonstrates "taking the data to the strategy," and why `Compositor`'s interface must be designed up front to serve every subclass: changing it later forces changes to all existing ones.

## Anti-patterns & Smells
- **A `switch` on an algorithm-selector enum** repeated across operations: the canonical signal to extract strategies.
- **A Strategy interface designed for one algorithm**: the second variant needs a different signature, and now every existing ConcreteStrategy must change. Design the interface for the family, not the first member.
- **Stateful shared strategies**: strategies shared as flyweights that keep state across invocations corrupt each other's contexts.
- **Exposing strategy choice to clients who can't evaluate it**: if clients can't tell the variants apart meaningfully, hide the choice behind a Context default.
- **Templated strategies where run-time swapping is needed**: static binding buys efficiency and forfeits the pattern's main flexibility.

## Known Uses
- **ET++** and **InterViews** — linebreaking algorithms encapsulated exactly as described.
- **RTL System** for compiler code optimization — strategies for register allocation (`RegisterAllocator`) and instruction scheduling (`RISCscheduler`, `CISCscheduler`), so the optimizer can be retargeted to different architectures.
- **ET++SwapsManager** — `Instrument` and `YieldCurve` delegate to a family of ConcreteStrategies for generating cash flows, valuing swaps, and calculating discount factors; new calculation engines come from mixing and matching.
- **Booch components** — strategies as **template arguments**: managed (pool), controlled (lock-protected), and unmanaged memory allocation, e.g. `UnboundedCollection<MyItemType*, Unmanaged>`.
- **RApp** (integrated circuit layout) — routing algorithms as subclasses of an abstract `Router` Strategy.
- **Borland ObjectWindows** — `Validator` objects encapsulate data-entry validation; fields attach one *optionally*.

## Related Patterns
- **Flyweight**: Strategy objects often make good flyweights — make them stateless and share them to control object count.
- **State**: same shape, different intent. A Strategy is an algorithm the *client chooses*, generally installed once; a State encapsulates behavior tied to the Context's internal state and typically transitions itself to the next State.
- **Template Method**: varies part of an algorithm using **inheritance**, with the skeleton fixed in the parent. Strategy varies the **entire** algorithm using **delegation** — and can do it at run-time.
- **Decorator**: changes the skin of an object; Strategy changes its guts.
- **Bridge**: also separates a varying part from its user, but at the level of an abstraction and its implementation rather than one algorithm.
- **Encapsulating variation** (Ch. 5 discussion): Strategy is the archetype — the encapsulated aspect (the algorithm) would otherwise be wired directly into the Context, and the pattern takes its name from the object that encapsulates it.

## Key Takeaways
1. Many conditionals selecting behavior are a direct signal to extract Strategy classes.
2. Design the Strategy interface for the whole anticipated family; it is the hardest part to change later.
3. Choose deliberately between passing data as parameters (decoupled, possibly wasteful) and passing the Context (precise, more coupled).
4. Use template parameters when the strategy is fixed at compile time and you want the speed — accept losing run-time swapping.
5. Make strategies optional with a Context default so clients only engage with them when they need to.
