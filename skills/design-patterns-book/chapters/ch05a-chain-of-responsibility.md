# Chain of Responsibility
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Avoid coupling the sender of a request to its receiver by giving more than one object a chance to handle the request. Chain the receiving objects and pass the request along the chain until an object handles it.

## Core Idea
Give the request an **implicit receiver**: the sender knows only the first candidate, and each candidate either handles the request or forwards it to its **successor**. Responsibility is distributed along a link, not resolved by the caller.

## Applicability
Use Chain of Responsibility when:
- More than one object may handle a request and the handler isn't known *a priori* — it should be determined automatically at run-time.
- You want to issue a request to one of several objects without naming the receiver explicitly.
- The set of objects that can handle a request should be specified dynamically.

## Structure
- **Handler** (HelpHandler): defines the interface for handling requests; optionally implements the successor link and a default "forward to successor" implementation.
- **ConcreteHandler** (PrintButton, PrintDialog, Application): handles requests it is responsible for, can access its successor, and forwards anything it doesn't handle.
- **Client**: initiates the request on some ConcreteHandler on the chain.

Collaboration: the client fires the request at the head of the chain; it propagates handler to successor until one takes responsibility — or falls off the end.

## How
1. Define an abstract Handler with the request operation plus `SetSuccessor`/`GetSuccessor`.
2. Give Handler a default implementation of the request operation that forwards to the successor (or does nothing at the end of the chain).
3. Subclass per candidate receiver; override the operation only where the handler can actually respond, and call the inherited version to forward otherwise.
4. Decide the chain topology: new explicit links, or reuse existing structural links (parent pointers in a Composite widget hierarchy).
5. Wire the chain at configuration time; rewire dynamically when responsibility should shift.

## Consequences
**Benefits**
- **Reduced coupling.** Neither sender nor receiver knows the other; a handler knows only "the request will be handled appropriately" and keeps just one successor reference instead of references to every candidate.
- **Added flexibility in assigning responsibilities.** Responsibilities can be added, removed, or reordered by changing the chain at run-time; combine with subclassing to specialize handlers statically.

**Liabilities**
- **Receipt isn't guaranteed.** With no explicit receiver, a request can fall off the end of a chain unhandled — or go unhandled because the chain was misconfigured. Debugging is harder because control flow is not visible in the code.

## Implementation Notes
- **Implementing the successor chain**: either define new links (usually in Handler) or use existing links. Parent references in a part-whole hierarchy (see Composite) often already form exactly the chain you want; reusing them saves space, but if the structure doesn't match the responsibility chain you need, you must define redundant links.
- **Connecting successors**: putting the successor in Handler lets the base class supply an unconditional forwarding default, so uninterested subclasses need no code at all.
- **Representing requests**: three options, in increasing flexibility and decreasing safety/convenience — (a) a hard-coded operation per request kind (type-safe, closed set); (b) one handler function taking a request code, which needs a conditional dispatch and manual parameter packing; (c) **request objects** that bundle parameters, with new kinds added by subclassing `Request` and identified via a `GetKind` accessor or RTTI. With (c), a subclass overrides `HandleRequest` to catch only the kinds it wants and delegates the rest to the parent class — subclasses thus *extend* rather than replace the dispatch.
- **Automatic forwarding in Smalltalk**: override `doesNotUnderstand:` to forward unrecognized messages to the successor, so no forwarding code is written by hand.

## Worked Example
Context-sensitive help in a GUI. `HelpHandler` holds a help topic (empty by default) and a successor; `Widget` derives from it, and `Button` and `Dialog` derive from `Widget`, using the existing enclosing-widget references as successor links. `Application` is not a widget, so it subclasses `HelpHandler` directly and terminates the chain.

```cpp
class HelpHandler {
public:
    HelpHandler(HelpHandler* s = 0, Topic t = NO_HELP_TOPIC)
        : _successor(s), _topic(t) { }
    virtual bool HasHelp() { return _topic != NO_HELP_TOPIC; }
    virtual void SetHandler(HelpHandler*, Topic);
    virtual void HandleHelp() {
        if (_successor != 0) _successor->HandleHelp();
    }
private:
    HelpHandler* _successor;
    Topic _topic;
};

void Button::HandleHelp () {
    if (HasHelp()) {
        // offer help on the button
    } else {
        HelpHandler::HandleHelp();   // forward to the dialog
    }
}
```

Calling `button->HandleHelp()` on a "Print" button walks button → PrintDialog → Application until something has a topic. It demonstrates the default-forwarding base implementation plus per-level override.

## Anti-patterns & Smells
- **No terminal handler**: leaving the chain's tail with nothing that unconditionally handles or logs the request means silent drops. Give the last link a catch-all.
- **Chain reused as dispatch table**: a giant request-code `switch` in every handler recreates the coupling the pattern removes; use request objects instead.
- **Forcing an existing hierarchy to be the chain** when its shape doesn't match the responsibility order — you end up with redundant links and confusing traversal.
- **Order-dependent handlers**: if correctness depends on a subtle chain ordering that nothing documents, reconfiguration will break it.

## Known Uses
- **MacApp** and **ET++** ("EventHandler"), Symantec's **TCL** ("Bureaucrat"), and NeXT's **AppKit** ("Responder") all pass user events along a chain.
- **Unidraw** forwards Command interpretation from a Component or Component View to its parent — the "requests as objects" variant.
- **ET++** graphical update: `InvalidateRect` forwards outward through Scrollers and Zoomers until a Window instance, by which point the rectangle is correctly transformed.

## Related Patterns
- **Composite**: frequently the substrate — a component's parent acts as its successor, so the chain costs no extra links.
- **Command**: requests represented as objects (Unidraw) makes the chain open-ended and parameter-safe.
- **Mediator**: also decouples colleagues, but centralizes control in one object rather than distributing it along a chain.

## Key Takeaways
1. Use it when the handler must be chosen at run-time and the sender must not know who responds.
2. Put the successor link and the forwarding default in the abstract Handler so uninterested subclasses stay empty.
3. Reuse existing parent links (Composite) when they match the responsibility order; otherwise define explicit ones.
4. Always plan for the unhandled request — receipt is never guaranteed.
