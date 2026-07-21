# Composite
**Classification**: Object Structural | **Chapter**: 4

## Intent
Compose objects into tree structures to represent part-whole hierarchies. Composite lets clients treat individual objects and compositions of objects uniformly.

## Also Known As
*(none given)*

## Core Idea
Define one abstract class that stands for **both** primitives and their
containers, so recursive composition works and client code never has to ask
"leaf or container?"

## Applicability
Use Composite when:
- You want to represent part-whole hierarchies of objects.
- You want clients to be able to ignore the difference between a composition of objects and an individual object — treating everything in the structure uniformly.

## Structure
- **Component** (Graphic): declares the interface for all objects in the composition; implements default behavior common to all classes where appropriate; declares the child access/management interface; optionally declares (and implements) access to a component's parent.
- **Leaf** (Rectangle, Line, Text): a component with no children; defines primitive behavior.
- **Composite** (Picture): defines behavior for components having children, stores them, and implements the child-related operations from Component.
- **Client**: manipulates the structure only through the Component interface.

Collaboration: a client sends a request through the Component interface. A Leaf
handles it directly; a Composite usually forwards it to its children, possibly
doing extra work before and/or after forwarding.

## How
1. Declare Component with the domain operations (`Draw`, `NetPrice`) *plus* the child-management operations (`Add`, `Remove`, `GetChild`/`CreateIterator`).
2. Give Component sensible defaults so Leaf classes need not implement child operations — e.g. `CreateIterator` returns a `NullIterator`.
3. Implement Leaf classes with the primitive behavior only.
4. Implement Composite: store children in a suitable data structure, implement `Add`/`Remove`, and implement each domain operation by iterating children and aggregating.
5. Decide the transparency/safety trade-off (below), and decide who deletes children.

## Consequences
**Benefits**
- Defines hierarchies of primitive and composite objects that nest arbitrarily; wherever client code expects a primitive, it can take a composite instead.
- **Makes the client simple** — no tag-and-case-statement code over the classes in the composition.
- Makes it easy to add new components: new Leaf or Composite subclasses work automatically with existing structures and existing client code.

**Liabilities**
- **Can make your design overly general.** It becomes hard to restrict *which* components a composite may contain. The type system can't enforce such constraints; you fall back on run-time checks.
- Transparency (child ops on Component) costs safety: clients can try to `Add` to a leaf.

## Implementation Notes
- **Explicit parent references.** Storing a child→parent link (defined in Component, inherited by Leaf and Composite) simplifies traversal and deletion and supports **Chain of Responsibility**. Maintain the invariant — change a component's parent *only* in `Add` and `Remove`, implemented once in Composite.
- **Declaring the child management operations — transparency vs. safety.** Declaring `Add`/`Remove` in Component gives *transparency* (uniform treatment) at the cost of *safety* (meaningless calls on leaves); declaring them only in Composite gives compile-time safety at the cost of transparency. **The pattern emphasizes transparency.** If you choose safety, avoid unsafe casts by declaring `Composite* GetComposite()` on Component returning null by default and `this` in Composite (or use `dynamic_cast`) — but you've then reverted to type testing. With transparency, make `Component::Add`/`Remove` *fail by default* (raise an exception); doing nothing hides what is probably a bug, and deleting the argument surprises clients.
- **Maximizing the Component interface.** Push as many operations as possible up to Component with defaults. Some apparently composite-only operations generalize: view a Leaf as a Component that *never* has children, and child access can return an empty result for every Leaf.
- **Sharing components.** Sharing saves storage but conflicts with single-parent links. Multiple parents create ambiguity when requests propagate upward; **Flyweight** shows how to avoid storing parents at all by externalizing state.
- **Should Component store the child list?** Putting the child pointer in the base class costs space in every leaf — worth it only when the structure has relatively few children.
- **Child ordering, caching, deletion, data structure.** Order often matters (front-to-back z-order, parse-tree statement order) — design the access interface with **Iterator** in mind. Composites can cache traversal results (e.g. a `Picture` caching its children's bounding box to skip drawing offscreen), which requires an interface for invalidating parents' caches. Without GC, a Composite should delete its children, except when leaves are immutable and shared. Children can live in lists, trees, arrays, hash tables — or even one instance variable per child (see **Interpreter**).

## Worked Example
Computer equipment forms a natural part-whole hierarchy: a cabinet contains a
chassis, which contains a bus, which contains cards.

```cpp
class Equipment {                                   // Component
public:
    virtual const char* Name() { return _name; }
    virtual Watt   Power();
    virtual Currency NetPrice();
    virtual Currency DiscountPrice();
    virtual void Add(Equipment*);
    virtual void Remove(Equipment*);
    virtual Iterator<Equipment*>* CreateIterator() {
        return new NullIterator<Equipment*>;         // default for leaves
    }
protected:
    Equipment(const char*);
private:
    const char* _name;
};

class FloppyDisk : public Equipment { /* Leaf: Power, NetPrice, … */ };

class CompositeEquipment : public Equipment {
public:
    void Add(Equipment* e)    { _equipment.Append(e); }
    void Remove(Equipment* e) { _equipment.Remove(e); }
    Iterator<Equipment*>* CreateIterator() {
        return new ListIterator<Equipment*>(&_equipment);
    }
    Currency NetPrice() {                            // aggregate over children
        Iterator<Equipment*>* i = CreateIterator();
        Currency total = 0;
        for (i->First(); !i->IsDone(); i->Next()) {
            total += i->CurrentItem()->NetPrice();
        }
        delete i;                                    // easy to forget
        return total;
    }
private:
    List<Equipment*> _equipment;
};

class Chassis : public CompositeEquipment { /* inherits child ops */ };
```

What it demonstrates: `NetPrice` is written once against the Component
interface and works identically whether the receiver is a `FloppyDisk` or a
`Cabinet` holding a `Chassis` holding a `Bus` holding cards. Note the default
`NullIterator` that lets leaves ignore child management entirely.

## Anti-patterns & Smells
- **Type-testing clients**: `if (isContainer) … else …` scattered through client code is exactly the complexity Composite removes.
- **Silent no-op `Component::Add`**: an add to a leaf almost always signals a bug; swallowing it produces garbage. Fail loudly.
- **Composites that must restrict their children**: Composite can't express that constraint in the type system. If constraints are central to your domain, accept run-time checks or reconsider the pattern.
- **Parent pointers plus sharing**: shared components with multiple parents make upward request propagation ambiguous. Externalize state (Flyweight) instead.
- **Leaking iterators**: it's easy to forget to delete the iterator returned by `CreateIterator`.

## Known Uses
- **Smalltalk MVC** — the original `View` had subviews, so View was both Component and Composite. Smalltalk-80 release 4.0 refactored this into `VisualComponent` with `View` and `CompositeView` subclasses.
- **ET++** (VObjects) and **InterViews** (Styles, Graphics, Glyphs) — nearly every UI toolkit follows.
- **RTL Smalltalk compiler framework** — `RTLExpression` as Component for parse trees with `BinaryExpression` composites; `RegisterTransfer` as Component for SSA form with `RegisterTransferSet` as its Composite.
- **Financial domain** — a portfolio Composite that conforms to the interface of an individual asset, allowing arbitrary aggregation.
- **Command** — `MacroCommand` is a Composite of Command objects.

## Related Patterns
- **Decorator**: shares Composite's recursive-composition structure but not its intent. Composite is about **representation** — treating many related objects uniformly, aggregation. Decorator is about **embellishment** — adding responsibilities without subclassing. Used together they share a common parent class, so decorators must support `Add`, `Remove`, `GetChild`; from Decorator's viewpoint a composite is a ConcreteComponent, and from Composite's viewpoint a decorator is a Leaf.
- **Proxy**: a third recursive-composition look-alike, but a proxy provides **controlled access** to one subject; it isn't designed for recursive composition and its single proxy-subject relationship is static.
- **Chain of Responsibility**: frequently uses the component-parent link.
- **Flyweight**: lets you share components — at the price that they can no longer refer to their parents.
- **Iterator**: traverses composites; also guides the design of ordered child access.
- **Visitor**: localizes operations that would otherwise be smeared across all the Composite and Leaf classes.
- **Interpreter**: an abstract syntax tree is a Composite, sometimes with one variable per child.

## Key Takeaways
1. If client code branches on "is this one thing or many?", give both a common Component interface.
2. Choose transparency over safety by default — declare child management on Component — and make illegal operations fail loudly rather than silently.
3. Push operations up to Component with defaults (`NullIterator`, empty child access) so leaves stay trivial.
4. Add parent pointers when you need upward traversal, cache invalidation, or Chain of Responsibility — but they rule out sharing.
