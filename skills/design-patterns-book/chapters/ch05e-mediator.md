# Mediator
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Define an object that encapsulates how a set of objects interact. Mediator promotes loose coupling by keeping objects from referring to each other explicitly, and it lets you vary their interaction independently.

## Core Idea
Replace a mesh of peer-to-peer references with a hub: each **Colleague** talks only to the **Mediator**, and the mediator owns the interaction protocol. Many-to-many becomes one-to-many.

## Applicability
Use Mediator when:
- A set of objects communicate in well-defined but complex ways, and the resulting interdependencies are unstructured and hard to understand.
- Reusing an object is difficult because it refers to and communicates with many other objects.
- A behavior distributed across several classes should be customizable without a lot of subclassing.

## Structure
- **Mediator** (DialogDirector): defines the interface for communicating with Colleague objects.
- **ConcreteMediator** (FontDialogDirector): implements the cooperative behavior; knows and maintains its colleagues.
- **Colleague classes** (ListBox, EntryField, Button): each knows its Mediator and communicates with it whenever it would otherwise have talked to another colleague.

Collaboration: a colleague notifies the mediator of a significant event; the mediator queries and drives the other colleagues to propagate the effect. Colleagues never reference each other.

## How
1. Define an abstract Mediator with the notification operation (`WidgetChanged(Widget*)`) and any lifecycle hooks (`ShowDialog`, `CreateWidgets`).
2. Give every Colleague a back-pointer to its mediator and a `Changed()` helper that calls the mediator, passing `this` so the mediator can identify the sender.
3. Subclass Mediator per interaction protocol; override the creation hook to build and retain references to the colleagues.
4. Implement the notification handler as the single place encoding "when X changes, do Y to Z".
5. Strip all direct colleague-to-colleague references — a colleague that still names a peer is not yet mediated.

## Consequences
**Benefits**
- **Limits subclassing.** Behavior that would otherwise be spread across colleagues is localized; changing it means subclassing Mediator only, and Colleague classes are reused as is.
- **Decouples colleagues.** Colleague and Mediator classes vary and are reused independently.
- **Simplifies object protocols.** Many-to-many interactions become one-to-many between mediator and colleagues — easier to understand, maintain, and extend.
- **Abstracts how objects cooperate.** Mediation becomes a first-class concept, so you can reason about interaction separately from individual behavior.

**Liabilities**
- **Centralizes control.** You trade interaction complexity for mediator complexity. Because it encapsulates the whole protocol, the mediator can become more complex than any colleague — a monolith that's hard to maintain. Mediator complexity grows with the number of colleagues (a large dialog's `WidgetChanged` grows proportionally), which can erode the pattern's benefits.

## Implementation Notes
- **Omitting the abstract Mediator class**: unnecessary when colleagues only ever work with one mediator. The abstract class earns its keep when colleagues must work with different Mediator subclasses and vice versa.
- **Colleague–Mediator communication**, two approaches:
  - **Observer-based**: implement the Mediator as an **Observer**. Colleagues are Subjects that notify on state change; the mediator, as observer, propagates effects to other colleagues. Good when colleagues shouldn't know a mediator concept exists at all.
  - **Specialized notification interface**: the Mediator declares an explicit operation colleagues call directly. Smalltalk/V for Windows uses delegation — the colleague passes *itself* as an argument so the mediator can identify the sender. This is what the Sample Code does.
- Mediators are also the right home for **coordinating complex updates** — batching or suppressing redundant notifications rather than just routing them.

## Worked Example
A font dialog. `DialogDirector` declares `ShowDialog()`, pure virtual `CreateWidgets()`, and pure virtual `WidgetChanged(Widget*)`. `Widget` holds a `DialogDirector*` and offers `Changed()`.

```cpp
class DialogDirector {
public:
    virtual ~DialogDirector();
    virtual void ShowDialog();
    virtual void WidgetChanged(Widget*) = 0;
protected:
    DialogDirector();
    virtual void CreateWidgets() = 0;
};

class Widget {
public:
    Widget(DialogDirector* d) : _director(d) { }
    virtual void Changed() { _director->WidgetChanged(this); }
    virtual void HandleMouse(MouseEvent& event);
private:
    DialogDirector* _director;
};

void FontDialogDirector::WidgetChanged (Widget* theChangedWidget) {
    if (theChangedWidget == _fontList) {
        _fontName->SetText(_fontList->GetSelection());
    } else if (theChangedWidget == _ok) {
        // apply font change and dismiss dialog
    } else if (theChangedWidget == _cancel) {
        // dismiss dialog
    }
}
```

`FontDialogDirector::CreateWidgets` constructs the `ListBox`, `EntryField`, and `Button`s and stores references to them; `Button::HandleMouse` simply calls `Changed()`. The sequence when a selection changes: list box tells the director it changed → director reads `GetSelection()` from the list box → director calls `SetText` on the entry field → director enables the action buttons now that the field has text. Demonstrates sender identification by `this`-passing and the single-point protocol.

## Anti-patterns & Smells
- **The god mediator**: a `WidgetChanged` that has grown into a hundred-branch dispatch is the pattern's failure mode; split the mediator or reconsider the design.
- **Leftover direct colleague references** "just for this one case" — the mesh silently reforms and the mediator's protocol is no longer authoritative.
- **Mistaking a Facade for a Mediator**: if only the outer object calls inward and never the reverse, you built a Facade.
- **Mediator that carries domain state** rather than coordination logic — colleagues stop being reusable because the truth moved out of them.

## Known Uses
- **ET++** and the **THINK C** class library use director-like objects to mediate between widgets in dialogs.
- **Smalltalk/V for Windows**: an application is a Window containing predefined Panes (TextPane, ListBox, Button) used without subclassing; the developer subclasses only `ViewManager`, the Mediator that owns inter-pane coordination. Communication is event-based — a pane generates an event identified by a symbol (e.g. `#select`) and the view manager registers a method selector as its handler.
- **ChangeManager** in Observer mediates between subjects and observers to avoid redundant updates.
- **Unidraw**'s `CSolver` mediates between connectors, solving connectivity constraints and updating connector positions in diagram and circuit editors.

## Related Patterns
- **Facade**: abstracts a *subsystem* to give a more convenient interface, and its protocol is **unidirectional** — the facade calls into the subsystem, never the reverse. Mediator enables cooperative behavior colleagues can't provide themselves, and its protocol is **multidirectional**.
- **Observer**: colleagues can communicate with the mediator by acting as Subjects with the mediator as observer.
- **Chain of Responsibility**: the opposite trade — distributes responsibility along a chain rather than centralizing it in a hub.

## Key Takeaways
1. Reach for Mediator when the count of pairwise references between peers is the real problem, not any one object's behavior.
2. Put the whole interaction protocol in one ConcreteMediator so varying behavior means subclassing one class, not many.
3. Have colleagues pass themselves on notification — or wire them as Observers when they shouldn't know a mediator exists.
4. Watch the mediator's size: centralized control is the pattern's cost, and past a point it becomes the monolith you were avoiding.
5. Unidirectional and subsystem-facing means Facade; multidirectional and peer-coordinating means Mediator.
