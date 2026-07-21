# Decorator
**Classification**: Object Structural | **Chapter**: 4

## Intent
Attach additional responsibilities to an object dynamically. Decorators provide a flexible alternative to subclassing for extending functionality.

## Also Known As
Wrapper

## Core Idea
Enclose an object in another object that conforms to the same interface,
forwards requests to it, and does extra work before or after forwarding.
Because the enclosure is transparent, you can nest decorators recursively for
an unlimited number of added responsibilities.

## Applicability
Use Decorator:
- To add responsibilities to *individual* objects dynamically and transparently — without affecting other objects of the same class.
- For responsibilities that can be **withdrawn** again.
- When extension by subclassing is impractical: a large number of independent extensions would explode into a subclass per combination, or the class definition is hidden/unavailable for subclassing.

## Structure
- **Component** (VisualComponent): the interface for objects that can have responsibilities added dynamically.
- **ConcreteComponent** (TextView): the object being decorated.
- **Decorator**: holds a reference to a Component and defines an interface conforming to Component's.
- **ConcreteDecorator** (BorderDecorator, ScrollDecorator, DropShadowDecorator): adds the actual responsibility.

Collaboration: Decorator forwards each request to its Component, optionally
performing additional operations before and after forwarding.

## How
1. Define a lightweight Component interface that both real components and decorators implement.
2. Write `Decorator` as a Component subclass holding a `Component*`, with a default implementation of every Component operation that simply forwards.
3. Subclass Decorator per responsibility; override only the operations you embellish, calling the inherited forwarding version at the right point.
4. Compose at run-time: wrap the concrete component, then wrap the wrapper.
5. Keep a direct reference to the ConcreteComponent if you need to call operations outside the Component interface.

## Consequences
**Benefits**
- **More flexibility than static inheritance.** Responsibilities attach and detach at run-time. Inheritance would require a class per combination (`BorderedScrollableTextView`, `BorderedTextView`). You can also apply a property *twice* — two `BorderDecorator`s give a double border, whereas inheriting from `Border` twice is error-prone at best.
- **Avoids feature-laden classes high in the hierarchy.** Pay-as-you-go: start with a simple class and add functionality incrementally, so an application doesn't pay for features it doesn't use. New decorators can be defined independently, even for unforeseen extensions.

**Liabilities**
- **A decorator and its component aren't identical.** The enclosure is transparent behaviorally but not by object identity — never rely on identity tests with decorators in play.
- **Lots of little objects.** Systems end up composed of many similar-looking objects that differ only in how they're wired together. Easy to customize if you understand it; hard to learn and debug otherwise.

## Implementation Notes
- **Interface conformance.** A decorator's interface must conform to the component's, so (at least in C++) ConcreteDecorators must inherit from a common class.
- **Omitting the abstract Decorator class.** With only one responsibility to add — common when retrofitting an existing hierarchy — merge the forwarding responsibility into the ConcreteDecorator and skip the abstract class.
- **Keeping Component classes lightweight.** The shared base should define an *interface*, not store data; defer representation to subclasses. A heavy Component makes decorators too expensive to use in quantity and forces concrete subclasses to pay for features they don't need.
- **Changing the skin of an object versus changing its guts.** A decorator is a skin over an object; **Strategy** changes the guts. Strategy is the better choice when the Component class is intrinsically heavyweight — MacApp 3.0 and Bedrock attach "adorner" objects (borders) and "behavior" objects (event interception) to views precisely because a full `View` is too expensive to instantiate just to draw a border. With Decorator the component knows nothing about its decorators; with Strategy the component must reference and maintain its strategies, so new extensions may require modifying it. But a strategy can have its own specialized, narrow interface (`DrawBorder`, `GetWidth`), so it stays lightweight even when the Component is heavy.

## Worked Example
Give a `TextView` a border and scroll bars without a `BorderedScrollableTextView` class:

```cpp
class Decorator : public VisualComponent {
public:
    Decorator(VisualComponent* c) : _component(c) { }
    virtual void Draw()              { _component->Draw(); }
    virtual void Resize(Rect& r)     { _component->Resize(r); }
private:
    VisualComponent* _component;
};

class BorderDecorator : public Decorator {
public:
    BorderDecorator(VisualComponent* c, int borderWidth)
        : Decorator(c), _width(borderWidth) { }
    virtual void Draw() {
        Decorator::Draw();          // forward first
        DrawBorder(_width);         // then embellish
    }
private:
    void DrawBorder(int);
    int _width;
};

// Compose at run time:
VisualComponent* textView = new TextView;
window->SetContents(
    new BorderDecorator(new ScrollDecorator(textView), 1)
);
```

What it demonstrates: `Window` accesses its contents only through
`VisualComponent`, so it is unaware of the decorators entirely — yet you still
hold `textView` directly for operations outside the `VisualComponent` interface.

The book's non-GUI example is ET++'s stream classes: `Stream` buffers data and
calls `HandleBufferFull`; `StreamDecorator` forwards to a component stream, and
`CompressingStream` and `ASCII7Stream` override `HandleBufferFull` to compress
or re-encode before delegating. Wrapping a `FileStream` in both yields
compressed, 7-bit-ASCII file output with no new Stream subclass per combination.

## Anti-patterns & Smells
- **Combinatorial subclasses**: `BorderedScrollableZoomableTextView` — the smell Decorator exists to eliminate.
- **Relying on object identity**: `decorated == original` is false. Any client that depends on the component's identity must hold the component directly.
- **A fat Component base class**: storing data and behavior in Component makes every decorator heavyweight and pushes you toward Strategy instead.
- **Calling decorator-specific operations blindly**: `ScrollDecorator::ScrollTo` only works if the caller knows a ScrollDecorator is actually in the chain — that knowledge is a dependency on the decoration.
- **Using Decorator to change an interface**: that's Adapter's job.

## Known Uses
- **InterViews** and **ET++**, **ObjectWorks\Smalltalk** — graphical embellishments on widgets.
- **InterViews `DebuggingGlyph`** — prints trace information before and after forwarding a layout request, for debugging layout in complex compositions.
- **ParcPlace Smalltalk `PassivityWrapper`** — enables/disables user interaction with the component.
- **ET++ streaming classes** — `StreamDecorator` with `CompressingStream` and `ASCII7Stream`.
- **MacApp 3.0 / Bedrock** — "adorners" and "behaviors"; a Strategy-style alternative adopted because `View` is heavyweight.

## Related Patterns
- **Adapter**: a decorator changes an object's *responsibilities* but not its interface; an adapter gives an object a completely **new** interface.
- **Composite**: a decorator can be viewed as a degenerate composite with one component — but that misses the intent. Composite's focus is **representation and aggregation** (treating many objects as one); Decorator's focus is **embellishment** (open-ended added responsibilities). They're complementary and often used together: from Decorator's view a composite is a ConcreteComponent; from Composite's view a decorator is a Leaf. When combined, decorators must support `Add`/`Remove`/`GetChild`.
- **Proxy**: similar implementation — same interface, holds a reference, forwards — but Proxy provides **controlled access** to a subject that already defines the key functionality, and isn't designed for recursive composition. In Decorator, the component provides only *part* of the functionality and the decorators furnish the rest; that open-endedness is why recursion is essential.
- **Strategy**: **a decorator lets you change the skin of an object; a strategy lets you change its guts.** Two alternative ways of changing an object — prefer Strategy when the Component is heavyweight, Decorator when the component must stay ignorant of its extensions.

## Key Takeaways
1. Use Decorator when responsibilities must be added per-object, at run-time, and removable — not when they belong to a whole class.
2. Keep the Component base class lightweight; a fat Component is the signal to use Strategy instead.
3. Never rely on object identity once decorators are in play; hold the concrete component directly if you need it.
4. Skin (Decorator) vs. guts (Strategy): the component is ignorant of its decorators, but must know about its strategies.
