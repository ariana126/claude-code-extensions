# Visitor
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Represent an operation to be performed on the elements of an object structure. Visitor lets you define a new operation without changing the classes of the elements on which it operates.

## Core Idea
Move the operation out of the element classes into a separate **Visitor** hierarchy, and let each element **accept** the visitor by calling back the `Visit` method named for its own class. Two hierarchies, two dispatches — new operations become new visitor subclasses.

## Applicability
Use Visitor when:
- An object structure contains many classes of objects with **differing interfaces**, and you want to perform operations that depend on their concrete classes.
- Many distinct and unrelated operations need to be performed on the objects, and you want to avoid "polluting" their classes. Visitor keeps related operations together in one class — and when the structure is shared by many applications, it puts operations only in the applications that need them.
- The **classes defining the object structure rarely change**, but you often define new operations over it. Changing the structure's classes requires redefining the interface to all visitors, which is potentially costly; if the element classes change often, define the operations in those classes instead.

## Structure
- **Visitor** (NodeVisitor, EquipmentVisitor): declares a `Visit` operation for each ConcreteElement class. The operation's name and signature identify the class that sent the request, letting the visitor determine the element's concrete class and then access it through its particular interface.
- **ConcreteVisitor** (TypeCheckingVisitor, PricingVisitor, InventoryVisitor): implements each `Visit` operation — a fragment of the algorithm for that element class. It provides the algorithm's context and stores its local state, which often **accumulates results** during traversal.
- **Element** (Node, Equipment): defines `Accept(Visitor&)`.
- **ConcreteElement** (AssignmentNode, VariableRefNode, FloppyDisk, Chassis): implements `Accept` by calling the matching `Visit` on the visitor.
- **ObjectStructure** (Program): can enumerate its elements and may provide a high-level interface for visiting them; it may be a **Composite** or a plain collection such as a list or set.

Collaboration: a client creates a ConcreteVisitor and traverses the structure, visiting each element with it. When visited, an element calls the `Visit` operation corresponding to *its own class*, supplying **itself** as the argument so the visitor can reach its state.

## How
1. Confirm the element hierarchy is stable and the operation set is not — otherwise stop.
2. Declare an abstract `Visitor` with one `VisitConcreteElement(ConcreteElement*)` per element class, each with an empty default body.
3. Add `virtual void Accept(Visitor&)` to the abstract Element.
4. In every ConcreteElement, implement `Accept` as exactly one line: `v.VisitXxx(this)`.
5. Decide who traverses: the object structure (composites recurse in `Accept`), an external/internal Iterator, or the visitor itself.
6. Write one ConcreteVisitor per operation, holding accumulator state as members.

## Consequences
**Benefits**
- **Visitor makes adding new operations easy.** A new operation over the whole structure is one new visitor subclass; spreading functionality over element classes would mean editing every one of them.
- **A visitor gathers related operations and separates unrelated ones.** Related behavior is localized in one visitor rather than smeared across element classes; unrelated behaviors go in different visitor subclasses. Both the element classes and the algorithms get simpler, and algorithm-specific data structures hide inside the visitor.
- **Visiting across class hierarchies.** An Iterator can only visit elements sharing a common parent class (`Item`). Visitor has no such restriction — a Visitor interface may declare `VisitMyType(MyType*)` and `VisitYourType(YourType*)` where `MyType` and `YourType` are unrelated by inheritance.
- **Accumulating state.** Visitors accumulate state as they visit. Without a visitor, that state would be passed as extra arguments through the traversal operations, or would live in global variables.

**Liabilities**
- **Adding new ConcreteElement classes is hard.** Each new element class gives rise to a new abstract operation on Visitor and a corresponding implementation in *every* ConcreteVisitor. A default implementation in Visitor sometimes helps, but that's the exception rather than the rule. So the key consideration is: **are you more likely to change the algorithms applied over the structure, or the classes making up the structure?** If elements change frequently, define operations on the elements. If the element hierarchy is stable but operations keep arriving, Visitor manages the change.
- **Breaking encapsulation.** Visitor assumes the ConcreteElement interface is powerful enough for visitors to do their job, so the pattern often forces you to expose public operations that reveal an element's internal state.

## Implementation Notes
- **Double dispatch — the key to the pattern.** In single-dispatch languages (C++, Smalltalk), two criteria determine which operation runs: the name of the request and the type of the receiver — `GenerateCode` on a `VariableRefNode` calls `VariableRefNode::GenerateCode`. **Double dispatch** means the operation executed depends on the request *and the types of two receivers*. `Accept` is a double-dispatch operation: its meaning depends on both the Visitor's type and the Element's type. Instead of binding operations statically into the Element interface, you consolidate them in a Visitor and use `Accept` to bind at run-time — so extending the Element interface means one new Visitor subclass rather than many new Element subclasses. Double dispatch is a special case of multiple dispatch; languages that support it directly (CLOS) lessen the need for Visitor entirely.
- **Accept/Visit is mechanical and must not be "smart."** Every ConcreteElement's `Accept` is a single call to the `Visit` method named for its own class. You *may* overload all of them to the name `Visit`, since the parameter type already differentiates them — this reinforces that the same analysis is being applied to different arguments, but makes the call site less obvious to a reader.
- **Who is responsible for traversing the object structure?** Three choices. (1) **The object structure** — most common: a collection iterates its elements calling `Accept`; a **Composite** traverses itself by having each `Accept` recurse into children before or after calling `Visit`. (2) **A separate iterator object** — internal or external in C++, `do:` with a block in Smalltalk. An *internal* iterator behaves much like structure-owned iteration, with one important difference: it will **not cause double-dispatching**, because it calls an operation on the *visitor* with an *element* as the argument, rather than an operation on the element with the visitor as the argument. You can still use Visitor with an internal iterator if the visitor's operation simply calls the element's operation without recursing. (3) **The visitor itself** — you then duplicate traversal code in each ConcreteVisitor for each aggregate ConcreteElement. The main reason to do it is a **particularly complex traversal whose path depends on the results of operations on the structure**, e.g. a regular-expression matcher where a `RepeatExpression` must traverse its component repeatedly.

## Worked Example
The `Equipment` composite from Composite, with visitors computing price and inventory.

```cpp
class Equipment {
public:
    virtual ~Equipment();
    const char* Name() { return _name; }
    virtual Watt Power();
    virtual Currency NetPrice();
    virtual Currency DiscountPrice();
    virtual void Accept(EquipmentVisitor&);
protected:
    Equipment(const char*);
};

class EquipmentVisitor {                       // all defaults do nothing
public:
    virtual ~EquipmentVisitor();
    virtual void VisitFloppyDisk(FloppyDisk*) { }
    virtual void VisitCard(Card*)             { }
    virtual void VisitChassis(Chassis*)       { }
    virtual void VisitBus(Bus*)               { }
protected:
    EquipmentVisitor();
};

void FloppyDisk::Accept (EquipmentVisitor& visitor) {
    visitor.VisitFloppyDisk(this);             // second dispatch, on element type
}

void Chassis::Accept (EquipmentVisitor& visitor) {
    for (ListIterator<Equipment*> i(_parts); !i.IsDone(); i.Next()) {
        i.CurrentItem()->Accept(visitor);      // composite traverses itself
    }
    visitor.VisitChassis(this);
}

class PricingVisitor : public EquipmentVisitor {
public:
    Currency& GetTotalPrice() { return _total; }
    virtual void VisitFloppyDisk(FloppyDisk* e) { _total += e->NetPrice(); }
    virtual void VisitChassis(Chassis* e)       { _total += e->DiscountPrice(); }
private:
    Currency _total;                           // accumulated state
};
```

Used as:

```cpp
Equipment* component;
InventoryVisitor visitor;
component->Accept(visitor);
cout << "Inventory " << component->Name() << visitor.GetInventory();
```

It demonstrates double dispatch (`Accept` → `VisitChassis`), traversal owned by the composite, accumulated visitor state, and the fact that changing the *pricing policy* means changing only `PricingVisitor` — no equipment class is touched. Note that simple equipment uses `NetPrice` while composites use `DiscountPrice`: the visitor selects the policy by dispatching to the right member function.

The Smalltalk regular-expression example inverts traversal responsibility: `REMatchingVisitor` owns the traversal because it is irregular — a `RepeatExpression` repeatedly traverses its component.

```smalltalk
accept: aVisitor
    ^ aVisitor visitSequence: self
```

## Anti-patterns & Smells
- **Applying Visitor to a churning element hierarchy**: every new element class forces an edit to the abstract Visitor and to every ConcreteVisitor. If elements change more than operations do, put the operations in the elements.
- **Logic in `Accept`**: `Accept` must be one line. Any conditional there defeats double dispatch and reintroduces the coupling.
- **Type-testing inside a single `Visit`** (`dynamic_cast` chains): you have written a switch statement wearing a visitor's clothes.
- **Widening element interfaces for the visitor's benefit**: convenient at first, and the direct cause of the "breaking encapsulation" liability — every new visitor pries the element open further.
- **Expecting double dispatch from an internal iterator**: it calls the visitor with the element, not the element with the visitor, so the element's type is not dispatched on.
- **Duplicating traversal in every ConcreteVisitor** when the structure could traverse itself — justified only for genuinely result-dependent traversals.

## Known Uses
- **Smalltalk-80 compiler** — `ProgramNodeEnumerator`, a Visitor used mainly for source-code analysis (though it could serve code generation and pretty-printing).
- **IRIS Inventor** — a 3-D graphics toolkit representing a scene as a node hierarchy; visitors are called "actions," with separate ones for rendering, event handling, searching, filing, and bounding-box computation. To make adding nodes easier, Inventor implements double dispatch via RTTI plus a 2-D table whose rows are visitors and columns are node classes, each cell holding a function pointer.
- **Fresco Application Toolkit** (X Consortium) — Mark Linton coined the term "Visitor" in its specification.
- Compilers generally — one visitor per compilation phase (type-checking, optimization, flow analysis, pretty-printing, metrics) over a stable abstract-syntax-tree grammar.

## Related Patterns
- **Composite**: Visitors apply operations over object structures defined by Composite; the composite's `Accept` typically drives the traversal by recursing into children.
- **Interpreter**: Visitor may be applied to do the interpretation — replacing the `Interpret` methods spread across expression classes with one visitor per interpretation.
- **Iterator**: an alternative traversal owner. An Iterator can call operations on elements as it goes, but only across a hierarchy with a common parent class; Visitor works across unrelated types. Use an Iterator *with* Visitor when you want the traversal reusable and separate — remembering an internal iterator won't produce double dispatch.
- **Objects as arguments** (Ch. 5 discussion): Visitor is the pattern whose object is *always* used as an argument — passed to a polymorphic `Accept` and never considered part of the objects it visits, even though the conventional alternative distributes visitor code across the structure's classes. Contrast **Command** and **Memento**, whose objects are "magic tokens" passed around to be invoked later.
- **Summary** (Ch. 5 discussion): an iterator can traverse an aggregate while a visitor applies an operation to each element; a Composite-based system commonly combines Visitor for operations, Chain of Responsibility for parent-accessed global properties, Decorator for local overrides, Observer to tie structures together, and State for per-component behavior change.

## Key Takeaways
1. Choose Visitor only when the element hierarchy is stable and the operation set is not — the trade is explicit and irreversible in practice.
2. Keep `Accept` a single dispatching line; all intelligence belongs in the ConcreteVisitor.
3. Decide traversal ownership deliberately: object structure by default, an iterator for reuse, the visitor only when the path depends on results.
4. Use visitor members to accumulate results instead of threading extra arguments through the traversal or reaching for globals.
5. Watch the encapsulation cost — each new visitor tempts you to widen the element interface a little further.
