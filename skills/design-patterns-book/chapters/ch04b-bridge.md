# Bridge
**Classification**: Object Structural | **Chapter**: 4

## Intent
Decouple an abstraction from its implementation so that the two can vary independently.

## Also Known As
Handle/Body

## Core Idea
Split one class hierarchy into two — an Abstraction hierarchy and an Implementor
hierarchy — and connect them with a reference instead of inheritance. Adding a
platform no longer multiplies your classes; it adds one.

## Applicability
Use Bridge when:
- You want to avoid a permanent binding between an abstraction and its implementation — for example, when the implementation must be selected or switched at run-time.
- Both the abstractions and their implementations should be extensible by subclassing, independently.
- Changes to the implementation must not force clients to recompile.
- *(C++)* You want to hide an abstraction's implementation completely from clients, since C++ exposes a class's representation in its interface.
- You have a proliferation of classes — Rumbaugh's "nested generalizations" (XWindow, PMWindow, XIconWindow, PMIconWindow…). That shape signals an object that wants to be split in two.
- You want to share an implementation among multiple objects (perhaps via reference counting) and hide that fact from the client — as in Coplien's `String`/`StringRep`.

## Structure
- **Abstraction** (Window): defines the abstraction's interface; maintains a reference to an Implementor.
- **RefinedAbstraction** (IconWindow, TransientWindow): extends the interface Abstraction defines.
- **Implementor** (WindowImp): declares the interface for implementation classes. It need not mirror Abstraction's interface at all — typically it offers only *primitive* operations, on which Abstraction builds higher-level ones.
- **ConcreteImplementor** (XWindowImp, PMWindowImp): implements the Implementor interface for one platform.

Collaboration: Abstraction forwards client requests to its Implementor object.

## How
1. Identify the two dimensions that are being crossed by subclassing (kind-of-window × window-system).
2. Put the client-facing dimension in the Abstraction hierarchy.
3. Define an Implementor interface of *primitive* operations only — the smallest platform-level vocabulary that Abstraction's operations can be written against.
4. Implement every Abstraction operation purely in terms of Implementor primitives.
5. Decide who supplies the ConcreteImplementor and when (see below); an Abstract Factory is the usual answer.

## Consequences
**Benefits**
- **Decoupling interface and implementation.** The implementation is configurable at run-time and an object can even change its implementation while running. Compile-time dependencies vanish — changing an implementation class doesn't force recompiling Abstraction or its clients, which is essential for binary compatibility across library versions. It also encourages layering: the high-level system knows only Abstraction and Implementor.
- **Improved extensibility.** Extend the Abstraction and Implementor hierarchies independently; adding a platform costs one class, not one per window kind.
- **Hiding implementation details from clients.** Sharing of implementor objects and any reference-count mechanism stays invisible.

**Liabilities**
- Extra indirection on every operation, and an extra object per abstraction instance.
- Someone must decide which ConcreteImplementor to create — a decision that tends to pull in a factory and thus more machinery.
- Degenerate cases (one implementor) buy only recompilation independence, which may not justify the split.

## Implementation Notes
- **Only one Implementor.** With a single implementation you can skip the abstract Implementor class — a degenerate Bridge. Still worth doing when clients must relink rather than recompile. Carolan calls this separation the **"Cheshire Cat"**: put the Implementor's class interface in a private header clients never see, hiding the implementation entirely.
- **Creating the right Implementor object.** Options: (a) Abstraction's constructor picks one from parameters — e.g. a collection choosing a linked list for small sizes and a hash table for large; (b) start with a default and *switch at run-time* as usage changes (collection outgrows the threshold); (c) delegate the decision to an **Abstract Factory** that encapsulates platform specifics, which keeps Abstraction uncoupled from every ConcreteImplementor.
- **Sharing implementors.** Coplien's Handle/Body idiom: the Body stores a reference count that the Handle increments and decrements on assignment — several handles share one body.
- **Multiple inheritance won't do it.** Inheriting publicly from Abstraction and privately from a ConcreteImplementor binds the implementation permanently because inheritance is static. You cannot write a true Bridge with multiple inheritance in C++.

## Worked Example
A portable `Window` for both X and Presentation Manager. Without Bridge you need
`XIconWindow`, `PMIconWindow`, `XTransientWindow`… — two classes per window kind
per platform. With Bridge:

```cpp
class Window {
public:
    virtual void DrawContents() = 0;
    void DrawRect(const Point& p1, const Point& p2) {
        WindowImp* imp = GetWindowImp();
        imp->DeviceRect(p1.X(), p1.Y(), p2.X(), p2.Y());   // primitive only
    }
protected:
    WindowImp* GetWindowImp() {
        if (_imp == 0) {
            _imp = WindowSystemFactory::Instance()->MakeWindowImp();
        }
        return _imp;
    }
private:
    WindowImp* _imp;
};

class IconWindow : public Window {                 // RefinedAbstraction
public:
    void DrawContents() { GetWindowImp()->DeviceBitmap(_bitmapName, 0.0, 0.0); }
private:
    const char* _bitmapName;
};

class XWindowImp : public WindowImp {              // ConcreteImplementor
public:
    void DeviceRect(Coord x0, Coord y0, Coord x1, Coord y1) {
        XDrawRectangle(_dpy, _winid, _gc, /* … converted coords … */);
    }
};
```

What it demonstrates: every `Window` operation is written against `WindowImp`
primitives, so new window kinds and new window systems extend two hierarchies
that never multiply against each other. `WindowSystemFactory::Instance()` is a
Singleton Abstract Factory that hides all window-system specifics.

## Anti-patterns & Smells
- **Nested generalizations**: a hierarchy whose class names are the cross product of two concepts (`PMIconWindow`) is the classic smell that a Bridge is missing.
- **Making Implementor mirror Abstraction**: if the two interfaces are the same operation-for-operation, you've built a pointless forwarding layer. Implementor should be primitive; Abstraction should be higher-level.
- **Letting Abstraction `new` concrete implementors everywhere**: this reintroduces the platform coupling Bridge exists to remove. Route it through a factory.
- **Trying to Bridge with multiple inheritance**: static binding defeats the whole purpose.

## Known Uses
- **ET++** — Window/WindowPort, with XWindowPort and SunWindowPort; the `WindowSystem` abstract factory creates platform-specific fonts, cursors, and bitmaps. ET++ extends the pattern: WindowPort keeps a back-reference to Window to notify it of input events and resizes.
- **libg++** — `Set` as abstraction with `LinkedList` and `HashTable` as implementors, bridged by `LinkedSet` and `HashSet`. A degenerate Bridge: no abstract Implementor class.
- **NeXT AppKit** — `NXImage`/`NXImageRep` (`NXEPSImageRep`, `NXCachedImageRep`, `NXBitMapImageRep`). NXImage may hold *several* implementations at once and picks the best for the current display device, converting between them if needed.
- **Coplien and Stroustrup** — Handle classes for shared string representations and variable-sized objects.

## Related Patterns
- **Adapter**: structurally similar (both forward requests through an indirection), opposite in intent and timing. Adapter reconciles two *existing*, independently designed interfaces after the fact; Bridge is designed in up front, knowing abstraction and implementation must evolve separately. Adapter makes things work **after** they're designed; Bridge makes them work **before**.
- **Abstract Factory**: creates and configures a particular Bridge — the standard answer to "which ConcreteImplementor?"
- **Singleton**: the window-system factory is typically a Singleton.

## Key Takeaways
1. When class names start reading as a cross product of two ideas, split the hierarchy in two and bridge them.
2. Keep Implementor primitive and Abstraction high-level — if the two interfaces match one-for-one you have indirection without benefit.
3. Delegate the choice of ConcreteImplementor to an Abstract Factory so the Abstraction never names a platform.
4. Even a one-implementor "Cheshire Cat" Bridge is worth it when clients must relink instead of recompile.
