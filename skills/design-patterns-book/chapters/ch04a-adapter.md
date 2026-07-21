# Adapter
**Classification**: Class, Object Structural | **Chapter**: 4

## Intent
Convert the interface of a class into another interface clients expect. Adapter lets classes work together that couldn't otherwise because of incompatible interfaces.

## Also Known As
Wrapper

## Core Idea
Wrap an existing class whose interface is wrong for you, and re-express its
services in the interface your client already speaks. You change the *interface*
of an existing object without touching its code.

## Applicability
Use Adapter when:
- You want to use an existing class and its interface does not match the one you need.
- You want to build a reusable class that must cooperate with unrelated or unforeseen classes — classes whose interfaces you cannot predict.
- *(object adapter only)* You need to use several existing subclasses but adapting each one by subclassing is impractical. An object adapter adapts the interface of the parent class and therefore all its subclasses at once.

## Structure
- **Target** (Shape): the domain-specific interface the Client actually uses.
- **Client** (DrawingEditor): works only with objects conforming to Target.
- **Adaptee** (TextView): the existing class with the wrong interface.
- **Adapter** (TextShape): adapts Adaptee's interface to Target's.

Collaboration: the client calls an operation on the Adapter; the Adapter
translates and calls one or more Adaptee operations that do the real work.

Two forms. A **class adapter** uses multiple inheritance: inherit the Target
interface publicly and the Adaptee implementation privately. An **object
adapter** holds a pointer to an Adaptee instance and delegates.

## How
1. Identify the Target interface the client depends on and the Adaptee you want to reuse.
2. Find the *narrow interface* — the smallest subset of Adaptee operations that lets you do the adaptation. Narrow interfaces are far easier to adapt than dozens of operations.
3. Decide class vs. object adapter: class if you need to override Adaptee behavior and commit to one concrete Adaptee; object if you must work with the Adaptee *and* its subclasses.
4. Implement each Target operation either by forwarding, by converting representations (Shape's `BoundingBox` corners ← TextView's origin/height/width), or from scratch where the Adaptee has no equivalent.
5. Add whatever the Adaptee lacks but the Target requires — e.g. `CreateManipulator`, itself a Factory Method.

## Consequences
**Benefits**
- Reuses a class that was otherwise unusable, without source access or modification.
- The Adapter can supply functionality the Adaptee lacks entirely.
- Object adapter: one Adapter serves an Adaptee *and* all its subclasses, and can add functionality to all of them at once.
- Class adapter: one object only, no extra pointer indirection; Adapter can override Adaptee behavior because it is a subclass.

**Liabilities**
- Class adapter commits to a concrete Adaptee class, so it won't work for a class *and* all its subclasses.
- Object adapter makes overriding Adaptee behavior harder — you must subclass Adaptee and point the Adapter at the subclass.
- Adapters aren't transparent to all clients: an adapted object no longer conforms to the Adaptee interface, so it can't be used where an Adaptee is expected (unless you build a two-way adapter).

## Implementation Notes
- **Class adapters in C++**: inherit publicly from Target, privately from Adaptee. Adapter becomes a subtype of Target but not of Adaptee.
- **How much adapting?** A spectrum: from renaming operations to supporting an entirely different operation set. The work scales with the distance between the two interfaces.
- **Pluggable adapters**: build interface adaptation *into* the reusable class so clients aren't forced to inherit from your abstract class. Three implementations, all starting from a narrow interface: (a) *abstract operations* declared in the widget and overridden by a subclass (DirectoryTreeDisplay); (b) *delegate objects* — the widget forwards narrow-interface requests to a registered delegate (NeXTSTEP's dominant technique for avoiding subclassing; in C++ you declare an explicit `TreeAccessorDelegate` and mix it in); (c) *parameterized adapters* — pass in Smalltalk blocks, one per adapted request, so no subclass is needed at all.
- **Two-way adapters for transparency**: when two clients must view one object differently, use a class adapter that inherits from both adapted classes. `ConstraintStateVariable` subclasses Unidraw's `StateVariable` and QOCA's `ConstraintVariable`, so it works in both systems.

## Worked Example
A drawing editor's key abstraction is `Shape`, with a `TextShape` subclass. Text
editing is hard, but the toolkit already has a `TextView`. `TextShape` adapts
`TextView` to `Shape` — the object-adapter form:

```cpp
class TextShape : public Shape {
public:
    TextShape(TextView* t) : _text(t) { }

    void BoundingBox(Point& bottomLeft, Point& topRight) const {
        Coord bottom, left, width, height;
        _text->GetOrigin(bottom, left);
        _text->GetExtent(width, height);
        bottomLeft = Point(bottom, left);
        topRight   = Point(bottom + height, left + width);
    }

    bool IsEmpty() const { return _text->IsEmpty(); }   // pure forwarding

    Manipulator* CreateManipulator() const {            // from scratch
        return new TextManipulator(this);
    }
private:
    TextView* _text;
};
```

What it demonstrates: the three kinds of Adapter operation side by side —
representation conversion (`BoundingBox`), pure forwarding (`IsEmpty`), and
functionality invented by the Adapter because the Adaptee lacks it
(`CreateManipulator`). Swap the pointer for `private` inheritance from
`TextView` and you have the class-adapter version — less code, but it no longer
works with `TextView` subclasses.

## Anti-patterns & Smells
- **Modifying the toolkit class to fit your domain**: a general-purpose toolkit should not absorb one application's domain-specific interface; and you usually lack the source anyway.
- **Adapting a wide interface wholesale**: skipping the narrow-interface step produces a huge, brittle adapter. Find the two or three operations that actually matter.
- **Assuming adapters are transparent**: an adapted object can no longer stand in for an Adaptee. Reach for a two-way adapter only when two clients genuinely need both views.
- **Using Adapter where Bridge belongs**: if you *know* up front an abstraction will have several implementations, an adapter retrofitted afterward is the wrong shape.

## Known Uses
- **ET++Draw** — `TextShape` adapts ET++ text-editing classes into the drawing app (the Motivation example).
- **InterViews 2.6** — `GraphicBlock`, an Interactor subclass containing a `Graphic`, adapts structured graphics into the Interactor hierarchy so they can be displayed, scrolled, and zoomed.
- **ObjectWorks\Smalltalk** — `PluggableAdaptor` adapts arbitrary objects to `ValueModel`'s `value`/`value:` protocol via blocks or selectors; `TableAdaptor` adapts a sequence of objects to a tabular presentation.
- **NeXT AppKit** — `NXBrowser` uses a delegate object to access and adapt hierarchical data.
- **Meyer's "Marriage of Convenience"** — `FixedStack` adapts `Array`'s implementation to `Stack`'s interface: a class adapter.

## Related Patterns
- **Bridge**: structurally similar to an object adapter but opposite in intent and timing. Adapter resolves an *unforeseen* incompatibility between two existing interfaces — it makes things work **after** they're designed. Bridge is chosen **up front**, when you already know an abstraction will have several implementations that must evolve independently.
- **Decorator**: enhances an object without changing its interface, so it is more transparent than an adapter and supports recursive composition — which pure adapters do not.
- **Proxy**: also defines a surrogate, but keeps the subject's interface identical rather than changing it. A protection proxy may effectively expose a *subset* of that interface.
- **Facade**: often described as "an adapter to a set of objects," but that misses the point — a facade defines a **new** interface, whereas an adapter reuses an **existing** one.
- **Factory Method**: adapters commonly implement missing Target operations (like `CreateManipulator`) as factory methods.

## Key Takeaways
1. Reach for Adapter when you discover, late, that two independently designed classes must cooperate — retrofit, not architecture.
2. Prefer the object adapter by default: it works with the Adaptee and all its subclasses. Choose the class adapter only when you must override Adaptee behavior and one concrete Adaptee suffices.
3. Before writing an adapter, define the narrow interface — the smallest set of adaptee operations that gets the job done.
4. If you're building a *reusable* class, build the adaptation in (pluggable adapter) rather than forcing clients to inherit from your abstract class.
