# Command
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Encapsulate a request as an object, thereby letting you parameterize clients with different requests, queue or log requests, and support undoable operations.

## Also Known As
Action, Transaction

## Core Idea
Turn "call this operation on that object" into a first-class object holding a **receiver–action binding**. Once the request is an object it can be stored, passed, queued, logged, composed, and reversed.

## Applicability
Use Command when you want to:
- **Parameterize objects by an action** to perform — Commands are the object-oriented replacement for callbacks.
- **Specify, queue, and execute requests at different times.** A command's lifetime is independent of the original request; if the receiver is addressable in an address-space-independent way, the command can be shipped to another process and fulfilled there.
- **Support undo.** Add `Unexecute` to the interface; store executed commands on a **history list** and traverse it backward/forward for unlimited-level undo and redo.
- **Support logging** so changes can be reapplied after a crash — add load/store operations and keep a persistent command log; recovery reloads and re-executes.
- **Structure a system around high-level operations built on primitives**, as with transactions in information systems: a uniform invocation interface plus easy extension by new transaction types.

## Structure
- **Command**: declares the interface for executing an operation (`Execute`, optionally `Unexecute`).
- **ConcreteCommand** (PasteCommand, OpenCommand): binds a Receiver to an action; implements `Execute` by invoking operation(s) on the Receiver.
- **Client** (Application): creates the ConcreteCommand and sets its receiver.
- **Invoker** (MenuItem): stores the command and asks it to carry out the request.
- **Receiver** (Document, Application): knows how to perform the work. Any class may serve as a Receiver.

Collaboration: Client creates ConcreteCommand with a receiver → Invoker stores it → Invoker calls `Execute` → command invokes operations on Receiver. When undoable, the command captures reversal state *before* invoking Execute.

## How
1. Declare an abstract `Command` with `Execute` (and `Unexecute` if undo is wanted); make the destructor virtual.
2. Write one ConcreteCommand per receiver–action pair, storing the receiver (and any arguments) in the constructor.
3. Give the Invoker a `Command*` it triggers blindly — the menu item, button, or gesture never learns the receiver's type.
4. For undo, snapshot prior receiver state in the command; push executed commands onto a history list with an index for the undo/redo cursor.
5. Compose sequences with a MacroCommand; share one command instance between multiple invokers (menu + toolbar button) to unify a feature's entry points.

## Consequences
**Benefits**
- Decouples the object that invokes an operation from the one that knows how to perform it.
- Commands are first-class objects — manipulable and extensible like any other.
- Commands assemble into composite commands (MacroCommand), an instance of Composite.
- New commands are easy to add: no existing class changes.

**Liabilities**
- A class per action can proliferate; commands that need undo state can grow large.
- **Hysteresis**: repeated execute/unexecute/re-execute cycles let errors accumulate until application state diverges from the original.

## Implementation Notes
- **How intelligent should a command be?** A spectrum: at one end a pure binding between receiver and action; at the other a command that does everything itself with no receiver — useful when no suitable receiver exists, when the command knows its receiver implicitly, or when the command must be independent of existing classes. In between sit commands that locate their receiver dynamically.
- **Supporting undo/redo**: a ConcreteCommand may need to store the receiver, the arguments to the operation, and any original receiver values the request will overwrite (the receiver must offer operations to restore them). One level of undo needs only the last command; multiple levels need a history list whose maximum length sets the number of levels.
- **Copying before the history list**: the command instance owned by a MenuItem will be invoked again later, so different invocations must be distinguished when the command's state varies. A `DeleteCommand` stores a different selection each time, so it must be **copied after execution and the copy placed on the history list**. If a command's state never changes on execution, a reference suffices. Commands that must be copied this way act as **Prototypes**.
- **Avoiding error accumulation**: store enough information to restore exact original state; apply **Memento** to give the command that information without exposing other objects' internals.
- **C++ templates**: for commands that are neither undoable nor argument-bearing, a `SimpleCommand<Receiver>` template parameterized by receiver type and a pointer-to-member action avoids writing a subclass per action.

## Worked Example
A menu system. `Application` creates menus; each `MenuItem` holds a `Command`. `PasteCommand` takes a `Document` receiver; `OpenCommand` prompts for a name, creates a Document, adds it to the Application, and opens it. `MacroCommand` sequences subcommands and has no receiver of its own.

```cpp
class Command {
public:
    virtual ~Command();
    virtual void Execute() = 0;
protected:
    Command();
};

class PasteCommand : public Command {
public:
    PasteCommand(Document* doc) : _document(doc) { }
    virtual void Execute() { _document->Paste(); }
private:
    Document* _document;
};

template <class Receiver>
class SimpleCommand : public Command {
public:
    typedef void (Receiver::* Action)();
    SimpleCommand(Receiver* r, Action a) : _receiver(r), _action(a) { }
    virtual void Execute() { (_receiver->*_action)(); }
private:
    Receiver* _receiver;
    Action _action;
};

class MacroCommand : public Command {
public:
    virtual void Add(Command*);
    virtual void Remove(Command*);
    virtual void Execute() {
        ListIterator<Command*> i(_cmds);
        for (i.First(); !i.IsDone(); i.Next()) i.CurrentItem()->Execute();
    }
private:
    List<Command*>* _cmds;
};
```

Demonstrates the receiver–action binding, the template shortcut for trivial commands, and composite execution. Note: a `MacroCommand::Unexecute` must unexecute subcommands in **reverse** order, and the MacroCommand owns and deletes its subcommands.

## Anti-patterns & Smells
- **Putting one shared command instance on the history list** when its state varies per invocation — undo then reverses the wrong data. Copy it (Prototype) first.
- **Undo by re-deriving state** instead of storing it: hysteresis makes the document drift; capture originals or use a Memento.
- **Fat commands that reimplement receiver logic** — the receiver stops being the authority on its own behavior.
- **Invoker inspecting the concrete command type** to decide what to do, which reintroduces the coupling the pattern removes.

## Known Uses
- **MacApp** popularized commands for undoable operations; **ET++**, **InterViews** (`Action` abstract class plus an `ActionCallback` template), and **Unidraw** all define Command classes.
- **THINK class library** calls them "Tasks", passed along a Chain of Responsibility for consumption.
- **Unidraw** commands behave like messages: the receiver is *computed* rather than stored, with interpretation delegated up the parent chain using run-time type information.
- Lieberman's 1985 paper is the earliest published example.

## Related Patterns
- **Composite**: implements MacroCommand.
- **Memento**: holds the state a command needs to undo its effect without exposing receiver internals.
- **Prototype**: a command that must be copied before going on the history list acts as a prototype.
- **Chain of Responsibility**: commands-as-requests can be forwarded along a chain until an object interprets them (Unidraw, THINK).
- Distinct from C++ **functors**, which maintain a function; Command maintains a *binding between* a receiver and an action.

## Key Takeaways
1. Reach for Command when the invoker must stay ignorant of the receiver, or when requests need a life beyond the moment of invocation.
2. Undo is a history list of commands plus a cursor — but copy stateful commands onto the list.
3. Use MacroCommand for scripting and batch operations; unexecute in reverse order.
4. Use templates or lightweight bindings for trivial, non-undoable commands to avoid class explosion.
