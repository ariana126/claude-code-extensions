# Iterator
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Provide a way to access the elements of an aggregate object sequentially without exposing its underlying representation.

## Also Known As
Cursor

## Core Idea
Move responsibility for access and traversal out of the aggregate and into a separate **iterator** object that tracks the current element. The aggregate keeps its interface small; traversal policies multiply freely as iterator subclasses.

## Applicability
Use Iterator:
- To access an aggregate's contents without exposing its internal representation.
- To support multiple, simultaneous traversals of an aggregate.
- To provide a uniform interface for traversing different aggregate structures — **polymorphic iteration**.

## Structure
- **Iterator**: defines the interface for accessing and traversing elements — minimally `First`, `Next`, `IsDone`, `CurrentItem`.
- **ConcreteIterator** (ListIterator, ReverseListIterator, SkipListIterator): implements that interface and keeps the current position.
- **Aggregate** (AbstractList): defines `CreateIterator`, the interface for creating an Iterator.
- **ConcreteAggregate** (List, SkipList): returns the proper ConcreteIterator.

Collaboration: the client asks the aggregate for an iterator, then drives `First`/`Next`/`IsDone`/`CurrentItem`; the ConcreteIterator knows how to compute the successor. `CreateIterator` is a **Factory Method** connecting the two parallel hierarchies.

## How
1. Define an abstract `Iterator` with the four-operation traversal interface (add `Previous` for ordered aggregates, `SkipTo` for sorted/indexed ones).
2. Write a ConcreteIterator per aggregate implementation and per traversal order.
3. Add `CreateIterator` to the abstract Aggregate; each ConcreteAggregate overrides it to return its matching iterator. (A `Traversable` mixin defining `CreateIterator` is an alternative to a common base class.)
4. Write client algorithms against `Iterator&`, not concrete types, so they work over List, SkipList, or anything else.
5. In C++, wrap heap-allocated polymorphic iterators in a stack-allocated `IteratorPtr` proxy so they are always deleted.

## Consequences
**Benefits**
- **Supports variations in traversal.** Parse trees can be walked inorder or preorder for code generation; swap the iterator instance or subclass Iterator for a new order.
- **Simplifies the Aggregate interface** — traversal operations don't have to be enumerated on the collection.
- **More than one traversal can be pending** at once, since each iterator owns its state.

**Liabilities**
- Polymorphic iterators must be heap-allocated via a factory method, costing an allocation and creating a deletion obligation.
- Naive iterators break when the aggregate is modified mid-traversal; robustness costs coupling.
- An iterator that needs the aggregate's private data either violates encapsulation or forces friend/protected access hooks.

## Implementation Notes
- **Who controls the iteration?** With an **external iterator** the client advances and requests each element; with an **internal iterator** the client hands over an operation and the iterator applies it to every element. (Booch calls these active and passive.) External iterators are more flexible — comparing two collections for equality is easy with them and practically impossible with internal ones — and internal iterators are weak in C++, which lacks anonymous functions, closures, and continuations. Internal iterators are easier to use because they own the loop logic.
- **Who defines the traversal algorithm?** If the *aggregate* defines it and the iterator merely stores position, the iterator is a **cursor**: the client calls `Next` on the aggregate passing the cursor. Cursors are a simple form of **Memento**. Putting the algorithm in the iterator makes multiple algorithms and reuse across aggregates easy, but may require access to the aggregate's private variables.
- **How robust is the iterator?** Inserting or deleting during traversal can make you visit an element twice or skip it. Copying the aggregate works but is too expensive in general. A **robust iterator** guarantees insertions and removals don't disturb traversal without copying — typically by registering the iterator with the aggregate, which then adjusts outstanding iterators' state (or keeps enough bookkeeping) on every mutation. See ET++ and the USL StandardComponents List.
- **Polymorphic iterators in C++ and the leak risk.** Use them only when polymorphism is genuinely needed; otherwise use concrete iterators allocated on the stack. The client must delete a polymorphic iterator, which is easy to forget with multiple exit points — and impossible to get right if an exception is thrown. Remedy: a stack-allocated **Proxy**, `IteratorPtr`, that deletes the real iterator in its destructor and overloads `operator->` and `operator*` so it reads like an iterator pointer. This is "resource allocation is initialization"; declaring `new`/`delete` private forces stack allocation at compile time.
- **Privileged access**: making the iterator a `friend` of the aggregate avoids public operations that exist only for traversal, but each new traversal then edits the aggregate. Better: give `Iterator` **protected** accessors that only its subclasses may use.
- **Iterators for Composites**: an external iterator over a recursive structure must store a *path* through the Composite, since a position spans nested levels. An internal iterator can just recurse, storing the path implicitly in the call stack. If Composite nodes expose sibling/parent/child navigation, a cursor-based iterator needs only the current node. Support preorder, postorder, inorder, and breadth-first with distinct iterator classes.
- **NullIterator**: a degenerate iterator whose `IsDone` is always true. Leaves in a Composite return a NullIterator from `CreateIterator` while internal nodes return a real one, so traversal code handles the whole structure uniformly with no leaf special-casing.

## Worked Example
A foundation-library `List<Item>` with `ListIterator` (front-to-back) and `ReverseListIterator` (identical except `First` goes to the end and `Next` decrements). Both derive from abstract `Iterator<Item>`; neither is a friend of `List`, because List's public interface is efficient enough.

```cpp
template <class Item>
class ListIterator : public Iterator<Item> {
public:
    ListIterator(const List<Item>* aList) : _list(aList), _current(0) { }
    virtual void First()          { _current = 0; }
    virtual void Next()           { _current++; }
    virtual bool IsDone() const   { return _current >= _list->Count(); }
    virtual Item CurrentItem() const {
        if (IsDone()) throw IteratorOutOfBounds;
        return _list->Get(_current);
    }
private:
    const List<Item>* _list;
    long _current;
};

// Client code depends only on the abstract Iterator.
void PrintEmployees (Iterator<Employee*>& i) {
    for (i.First(); !i.IsDone(); i.Next())
        i.CurrentItem()->Print();
}
```

`AbstractList` declares `virtual Iterator<Item>* CreateIterator() const;` and `List` overrides it to return `new ListIterator<Item>(this)`, so `PrintEmployees` works over a `SkipList` unchanged. The cleanup proxy:

```cpp
template <class Item>
class IteratorPtr {
public:
    IteratorPtr(Iterator<Item>* i) : _i(i) { }
    ~IteratorPtr() { delete _i; }
    Iterator<Item>* operator->() { return _i; }
    Iterator<Item>& operator*()  { return *_i; }
private:
    IteratorPtr(const IteratorPtr&);            // disallowed
    IteratorPtr& operator=(const IteratorPtr&); // disallowed
    Iterator<Item>* _i;
};

IteratorPtr<Employee*> iterator(employees->CreateIterator());
PrintEmployees(*iterator);
```

**Internal iterator**: `ListTraverser` takes a List, uses an external `ListIterator` internally, and `Traverse` calls `ProcessItem` on each element — returning `false` from `ProcessItem` terminates early, and `Traverse` reports whether it ended prematurely. A `PrintNEmployees` subclass overrides `ProcessItem` and accumulates a `_count` instance variable to stop after 10. `FilteringListTraverser` adds a `TestItem` hook so only passing items are processed. `Traverse` here is a **Template Method** with primitive operations `TestItem` and `ProcessItem`.

Demonstrates: the client never writes the loop with an internal iterator (reuse of iteration logic, at the cost of a class per traversal); with C++, subclassing beats function pointers because state accumulates naturally in instance variables rather than statics.

## Anti-patterns & Smells
- **Leaking polymorphic iterators**: `CreateIterator` returns owned memory; every early return or exception without `IteratorPtr` is a leak.
- **Mutating the aggregate mid-traversal** with a non-robust iterator — double-visits and skipped elements, often intermittent.
- **Bloating the aggregate with a traversal method per order** (`ForEachInorder`, `ForEachReverse`) — that's the interface the pattern exists to prevent.
- **Client code typed to `ListIterator`** instead of `Iterator&`, which recommits it to the concrete aggregate.
- **Special-casing leaves** in Composite traversal rather than returning a NullIterator.

## Known Uses
- **Booch components**: bounded and unbounded queue implementations share one iterator written against the abstract `Queue` interface — no factory method needed, but the abstract interface must be strong enough to iterate efficiently.
- **Smalltalk-80**: collections define the internal iterator `do:` taking a block; `ReadStream` acts as an external iterator for sequential collections (there are no standard external iterators for `Set` or `Dictionary`).
- **ET++** container classes provide polymorphic iterators and the cleanup Proxy.
- **Unidraw** uses cursor-based iterators; **ObjectWindows 2.0** offers an iterator class hierarchy driven by an overloaded postincrement `++`.

## Related Patterns
- **Composite**: iterators are frequently applied to recursive structures; NullIterator and cursors make that traversal uniform.
- **Factory Method**: polymorphic iterators depend on it to instantiate the right Iterator subclass.
- **Memento**: an iterator can store a memento capturing iteration state; cursors are a simple case of Memento.
- **Proxy**: `IteratorPtr` is a stack-allocated proxy guaranteeing iterator deletion.
- **Template Method**: internal iterators' `Traverse` is one, with `ProcessItem`/`TestItem` as primitives.

## Key Takeaways
1. External iterators when the client needs control (comparison, interleaved traversal); internal when you want the loop written once.
2. Program clients against the abstract Iterator plus `CreateIterator`, and the aggregate implementation becomes swappable.
3. Never hand a raw polymorphic iterator to a client in C++ — wrap it in an `IteratorPtr` proxy.
4. If the aggregate can change during traversal, you need a robust iterator registered with the aggregate, not a copy.
5. For Composites, use a path-storing external iterator, a cursor, or recursion — and return NullIterator from leaves.
