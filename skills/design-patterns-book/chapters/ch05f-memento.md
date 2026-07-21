# Memento
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Without violating encapsulation, capture and externalize an object's internal state so that the object can be restored to this state later.

## Also Known As
Token

## Core Idea
Hand the state out as an **opaque object** that only its creator can read. The originator packages its own snapshot; everyone else may hold and pass the memento but never inspect it — so you get checkpointing without cracking encapsulation open.

## Applicability
Use Memento when:
- A snapshot of (some portion of) an object's state must be saved so the object can be restored to that state later — checkpoints, undo, error recovery.
- **And** a direct interface to obtaining that state would expose implementation details and break the object's encapsulation.

## Structure
- **Memento** (SolverState): stores as much or as little of the Originator's internal state as the Originator chooses; protects that state from access by anyone else. Two interfaces — a **narrow** one for the Caretaker (pass it around, nothing more) and a **wide** one for the Originator (full access to everything needed to restore).
- **Originator** (ConstraintSolver): creates a memento holding a snapshot of its current internal state; uses a memento to restore that state.
- **Caretaker** (the undo mechanism): keeps the memento safe and never operates on or examines its contents.

Collaboration: the caretaker requests a memento from the originator, holds it for a while, and later passes it back. Mementos are **passive** — only the originator that created one ever assigns or retrieves its state. Sometimes the memento is never passed back at all.

## How
1. Decide what slice of Originator state actually needs capturing — full state or just the delta.
2. Define a Memento class whose *wide* interface (the real accessors/mutators) is private and whose *narrow* public interface is essentially empty.
3. Grant the Originator privileged access — in C++, make Originator a `friend` of Memento.
4. Add `CreateMemento()` and `SetMemento(Memento*)` to the Originator.
5. Give the Caretaker (typically a Command in a history list) a member holding the memento; it stores on `Execute`, restores on `Unexecute`.
6. Make the Caretaker responsible for deleting mementos it no longer needs.

## Consequences
**Benefits**
- **Preserving encapsulation boundaries.** State that only the originator should manage still gets stored outside it, without exposing complex internals.
- **It simplifies Originator.** Alternative encapsulation-preserving designs make the Originator keep every version clients asked for, putting all storage management on it — and forcing clients to notify it when they're done. Letting clients hold what they asked for removes both burdens.

**Liabilities**
- **Using mementos might be expensive.** If the Originator must copy large amounts of information, or clients checkpoint often, overhead dominates. Unless capture and restore are cheap, the pattern may not be appropriate — reach for incremental mementos.
- **Defining narrow and wide interfaces** is hard or impossible in languages without two levels of static protection.
- **Hidden costs in caring for mementos.** The Caretaker must delete them but has no idea how much state each holds — an otherwise lightweight caretaker can silently accumulate enormous storage.

## Implementation Notes
- **Language support for the two interfaces.** In C++, make `Originator` a `friend` of `Memento`, declare the wide interface (`SetState`/`GetState`) `private`, and leave only the narrow interface public. Without such support, you rely on convention and hope.
- **Storing incremental changes.** When mementos are created and returned in a *predictable sequence*, a memento need only record the **incremental change** rather than the whole state. Undoable commands in a history list (see Command) give exactly such an order, so each memento stores only what its command touched. The constraint solver stores only the internal structures that changed to keep the connecting line, not the absolute positions of every object.
- **Incremental mementos constrain ordering.** QOCA's mementos hold only the constraint variables that changed since the last solution — enough to step back one solution, so reverting further requires restoring every intervening memento in order. You cannot set incremental mementos in arbitrary order; a history mechanism is mandatory.
- **Mementos need not be a snapshot of everything.** The Originator picks the granularity — the memento may capture one subsystem's variables and ignore the rest.

## Worked Example
Unidraw's connectivity support: a graphical editor where rectangles stay connected by a stretching line. A `ConstraintSolver` (a Singleton) records connections, generates equations, and rearranges graphics in `Solve()`. Simply moving a shape back by the negated delta does *not* restore the diagram, because slack in the constraints makes the reverse move ambiguous — so `MoveCommand` checkpoints the solver itself.

```cpp
class ConstraintSolver {
public:
    static ConstraintSolver* Instance();
    void Solve();
    void AddConstraint(Graphic* startConnection, Graphic* endConnection);
    void RemoveConstraint(Graphic* startConnection, Graphic* endConnection);
    ConstraintSolverMemento* CreateMemento();
    void SetMemento(ConstraintSolverMemento*);
private:
    // nontrivial state and operations for enforcing connectivity semantics
};

class MoveCommand {
public:
    MoveCommand(Graphic* target, const Point& delta);
    void Execute();
    void Unexecute();
private:
    ConstraintSolverMemento* _state;   // the memento — held, never inspected
    Point _delta;
    Graphic* _target;
};

void MoveCommand::Execute () {
    ConstraintSolver* solver = ConstraintSolver::Instance();
    _state = solver->CreateMemento();      // checkpoint BEFORE moving
    _target->Move(_delta);
    solver->Solve();
}

void MoveCommand::Unexecute () {
    ConstraintSolver* solver = ConstraintSolver::Instance();
    _target->Move(-_delta);
    solver->SetMemento(_state);            // roll the solver back
    solver->Solve();
}
```

It demonstrates the Caretaker (`MoveCommand`) holding `_state` purely as an opaque token: it never reads a field of the memento, and only `ConstraintSolver` can.

Dylan's collections show the same shape used for iteration: `CreateInitialState` returns an `IterationState` memento; `Next`, `IsDone`, `CurrentItem`, and `Copy` operate on it. Two benefits fall out — more than one state can iterate the same collection at once, and iteration needs no encapsulation break. The friendship is *reversed* versus a conventional Iterator: `Collection` is a friend of `IterationState`, not the other way round.

## Anti-patterns & Smells
- **Public getters on the memento**: if the caretaker can read the state, you have a data-transfer object, not a Memento, and encapsulation is already gone.
- **Full snapshots of huge state on every operation**: the pattern's cost dominates; use incremental mementos or reconsider undo entirely.
- **Undo by inverse arithmetic**: "move back by −delta" fails whenever a solver, layout engine, or constraint has slack; capture the collaborator's state instead.
- **Restoring incremental mementos out of order**: valid only for full mementos; incremental ones require a history that replays intervening steps.
- **Caretaker that never frees mementos**: an unbounded history list is an unbounded memory leak whose size the caretaker cannot even measure.

## Known Uses
- **Unidraw** — the `CSolver` class supports connectivity exactly as in the sample code.
- **Dylan** collections — the "state" object in the iteration protocol is a memento that hides each collection's representation.
- **QOCA** constraint-solving toolkit — incremental mementos storing only the constraint variables that changed since the last solution.

## Related Patterns
- **Command**: commands use mementos to hold the state needed to undo their operations; the history list supplies the predictable ordering that makes incremental mementos safe.
- **Iterator**: mementos can implement iteration (Dylan-style), giving multiple simultaneous traversals without making the iterator a friend of the collection.
- **Singleton**: the Originator is often a Singleton (the `ConstraintSolver`) — one global engine whose state you must nonetheless version.
- **Objects as arguments** (Ch. 5 discussion): both Command and Memento are "magic tokens" passed around and invoked later. The difference is polymorphism — executing a Command is a polymorphic operation, whereas a Memento's interface is so narrow it typically presents *no* polymorphic operations to clients and is passed purely as a value.

## Key Takeaways
1. Reach for Memento only when a public accessor for the state would leak implementation — otherwise just save the state directly.
2. Enforce the wide/narrow split with the language (C++ `friend` + private wide interface); convention alone will erode.
3. Make mementos incremental when a history list gives you a predictable undo order — but accept that ordering then becomes mandatory.
4. Budget for the storage: the caretaker owns deletion but cannot see the cost it is carrying.
