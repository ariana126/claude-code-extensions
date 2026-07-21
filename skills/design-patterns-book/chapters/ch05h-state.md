# State
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Allow an object to alter its behavior when its internal state changes. The object will appear to change its class.

## Also Known As
Objects for States

## Core Idea
Promote each execution state to a **full object** and have the Context delegate every state-dependent request to the one it currently holds. Changing state means rebinding a single pointer — so the object appears to change class.

## Applicability
Use State when:
- An object's behavior depends on its state, and it must change that behavior at run-time depending on the state.
- Operations have large, multipart conditional statements that depend on the object's state — usually represented by enumerated constants — and several operations repeat the *same* conditional structure. State puts each branch of the conditional in its own class, so the state becomes an object that can vary independently.

## Structure
- **Context** (TCPConnection): defines the interface of interest to clients; maintains an instance of a ConcreteState subclass defining the current state.
- **State** (TCPState): declares an interface encapsulating the behavior associated with a particular state of the Context.
- **ConcreteState subclasses** (TCPEstablished, TCPListen, TCPClosed): each implements the behavior for one state.

Collaboration: Context delegates state-specific requests to the current ConcreteState object, often passing **itself** as an argument so the State can read Context data and change its state. Context is the primary interface for clients — clients configure a Context with State objects up front and thereafter never touch State objects. **Either Context or the ConcreteState subclasses** can decide which state succeeds another and under what circumstances.

## How
1. Identify the operations whose behavior varies with state; that set becomes the `State` interface, mirroring Context's state-dependent interface.
2. Give each `State` operation a `Context*` parameter so states can read Context data and trigger transitions.
3. Implement **default behavior** for every request in the abstract `State` — usually "error" or no-op — so ConcreteStates only override what's legal in that state.
4. Add a `ChangeState(State*)` operation to Context; make `State` a `friend` of Context so only states can call it.
5. Write one ConcreteState per state; after doing the state-specific work, call `ChangeState` to advance.
6. Initialize Context to its starting state in the constructor.
7. If ConcreteStates have no instance variables, expose each via a static `Instance()` and share it.

## Consequences
**Benefits**
- **It localizes state-specific behavior and partitions behavior for different states.** All behavior for a state lives in one object, so new states and transitions arrive as new subclasses. The alternative — data values plus explicit checks — scatters look-alike conditionals through Context, so adding a state means editing several operations.
- **Transition logic stops being monolithic.** Large conditionals, like long procedures, are monolithic and inexplicit. Encapsulating each transition and action in a class elevates execution state to full object status, imposing structure and clarifying intent.
- **It makes state transitions explicit.** With data values, transitions exist only as variable assignments. With State objects they're visible — and **atomic** from the Context's perspective, since a transition rebinds *one* variable rather than several, protecting Context from inconsistent internal states.
- **State objects can be shared.** If a State has no instance variables — the state it represents is encoded entirely in its type — contexts can share it.

**Liabilities**
- Behavior for different states is **distributed across several subclasses**, increasing the class count and being less compact than a single class. This is a good trade only when there are many states; with two or three, the conditionals may genuinely be simpler.
- With decentralized transitions, State subclasses gain knowledge of each other.

## Implementation Notes
- **Who defines the state transitions?** The pattern doesn't say. If the criteria are *fixed*, implement them entirely in the **Context**. It is generally more flexible to let the **State subclasses** specify their own successor and when to transition — which requires adding an interface to Context (`ChangeState`) letting States set the current state explicitly. Decentralizing makes the logic easy to extend by adding subclasses; the cost is that each State subclass then knows of at least one other, introducing implementation dependencies between subclasses.
- **State objects as Singletons and Flyweights.** Stateless ConcreteStates need only one instance each, obtained through a static `Instance()` operation — making each subclass a **Singleton**. Viewed the other way, shared states with no intrinsic state and only behavior are **Flyweights**.
- **Creating and destroying State objects.** Either (1) create states on demand and destroy them after, or (2) create all of them up front and never destroy them. Choose (1) when the states to be entered aren't known at run-time *and* transitions are infrequent — it avoids allocating unused objects, which matters if states store a lot of information. Choose (2) when state changes are rapid: instantiation cost is paid once, there is no destruction cost, but Context must hold references to every state it might enter.
- **A table-based alternative.** Cargill's approach maps inputs to succeeding states in a per-state table, converting conditionals (and virtual calls) into a look-up. Its advantage is regularity — change transitions by editing data, not code. Its costs: table look-up is often less efficient than a virtual call; a uniform tabular format makes the criteria less explicit and harder to understand; and it's hard to attach *actions* to transitions. The essential difference: **the State pattern models state-specific behavior, whereas the table-driven approach focuses on defining state transitions.**
- **Using dynamic inheritance.** Changing the object's class at run-time would do the job directly, but most OO languages disallow it. Self and other delegation-based languages let an object change its delegation target at run-time, effectively changing its inheritance structure — direct language support for State.

## Worked Example
A simplified TCP connection. `TCPConnection` holds a `TCPState*` and forwards everything to it; `TCPState` mirrors that interface, taking the connection as a parameter.

```cpp
class TCPConnection {
public:
    TCPConnection();
    void ActiveOpen();
    void PassiveOpen();
    void Close();
    void Send();
    void Acknowledge();
    void Synchronize();
private:
    friend class TCPState;              // lets states call ChangeState
    void ChangeState(TCPState*);
    TCPState* _state;
};

TCPConnection::TCPConnection () {
    _state = TCPClosed::Instance();     // start Closed
}

void TCPConnection::ChangeState (TCPState* s) { _state = s; }

void TCPConnection::ActiveOpen ()  { _state->ActiveOpen(this); }
void TCPConnection::Close ()       { _state->Close(this); }
void TCPConnection::Acknowledge () { _state->Acknowledge(this); }

class TCPState {
public:
    virtual void Transmit(TCPConnection*, TCPOctetStream*);
    virtual void ActiveOpen(TCPConnection*);
    virtual void PassiveOpen(TCPConnection*);
    virtual void Close(TCPConnection*);
    virtual void Synchronize(TCPConnection*);
    virtual void Acknowledge(TCPConnection*);
protected:
    void ChangeState(TCPConnection*, TCPState*);   // default: error/no-op bodies
};

class TCPEstablished : public TCPState {
public:
    static TCPState* Instance();        // Singleton — no instance variables
    virtual void Transmit(TCPConnection*, TCPOctetStream*);
    virtual void Close(TCPConnection*);
};

void TCPEstablished::Close (TCPConnection* t) {
    // send FIN, receive ACK of FIN
    ChangeState(t, TCPListen::Instance());
}

void TCPClosed::ActiveOpen (TCPConnection* t) {
    // send SYN, receive SYN, ACK, etc.
    ChangeState(t, TCPEstablished::Instance());
}

void TCPListen::Send (TCPConnection* t) {
    // send SYN, receive SYN, ACK, etc.
    ChangeState(t, TCPEstablished::Instance());
}
```

It demonstrates the decentralized-transition choice: `TCPConnection` knows nothing about the TCP protocol — the `TCPState` subclasses define every transition and action — and each state is a shared Singleton because it carries no local data.

## Anti-patterns & Smells
- **The same `switch (state)` in five operations**: the exact smell State exists to remove. One new state should not mean editing five methods.
- **Putting instance data in a shared State**: the moment a Singleton state grows a member, contexts start corrupting each other. Keep residual data in the Context.
- **Transitions split across both Context and States**: pick one owner. Half-and-half makes the state machine unreadable.
- **State classes for two states**: the class explosion isn't worth it; a boolean and an `if` is honest.
- **Confusing State with Strategy**: if the object never transitions itself and a client picks the behavior once, you wanted Strategy.
- **Leaking State objects to clients**: clients configure the Context, then should deal only with it.

## Known Uses
- **Johnson and Zweig** characterize the pattern and its application to TCP connection protocols.
- **HotDraw** — a drawing editor whose behavior changes with the currently selected tool; `DrawingController` forwards requests to the current `Tool` object.
- **Unidraw** — same technique, with `Viewer` and `Tool` as the corresponding classes. Users think of "picking up a tool," but really the editor's behavior changes with the current tool; new tools are added by subclassing.
- **Coplien's Envelope-Letter idiom** — a general technique for changing an object's class at run-time; State is the more specific case focused on state-dependent behavior.

## Related Patterns
- **Strategy**: structurally near-identical (a Context delegating to a swappable object), but the *intent* differs sharply. A **State** object encapsulates state-dependent behavior, and the object **transitions between States** — usually the States themselves decide the successor, and the Context appears to change class as it moves through them. A **Strategy** is a *chosen algorithm*: the client picks one, it's typically installed once, and strategies neither know about nor replace each other. If your delegate reassigns the Context's delegate, you have State; if a client chooses among alternatives that do the same job differently, you have Strategy.
- **Flyweight**: explains when and how State objects can be shared — a stateless State is a flyweight with only behavior and no intrinsic state.
- **Singleton**: State objects are often Singletons, one instance per state class.
- **Interpreter**: can use State to define parsing contexts.
- **Composite**: a component can use State to change its behavior as its state changes.
- **Encapsulating variation** (Ch. 5 discussion): like Strategy, Mediator, and Iterator, State names itself after the object that encapsulates the varying aspect — code that would otherwise be wired directly into the Context.

## Key Takeaways
1. Reach for State when the same state-based conditional appears in several operations — one branch per class, one class per state.
2. Prefer letting State subclasses choose their successors; accept the inter-subclass dependency in exchange for extensibility.
3. Make stateless States Singletons/Flyweights and keep all mutable data in the Context.
4. Create states eagerly when transitions are rapid, lazily when they're rare and states are heavy.
5. State is about behavior that follows an object's *internal* state and transitions itself; Strategy is about a client *choosing* an algorithm.
