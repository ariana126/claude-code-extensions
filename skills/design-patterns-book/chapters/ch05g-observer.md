# Observer
**Classification**: Object Behavioral | **Chapter**: 5

## Intent
Define a one-to-many dependency between objects so that when one object changes state, all its dependents are notified and updated automatically.

## Also Known As
Dependents, Publish-Subscribe

## Core Idea
Split an abstraction into a **subject** that owns the state and any number of **observers** that depend on it. The subject broadcasts "something changed" over an abstract interface without knowing who — or how many — are listening.

## Applicability
Use Observer when:
- An abstraction has two aspects, one dependent on the other, and encapsulating them in separate objects lets you vary and reuse them independently.
- A change to one object requires changing others, and you don't know how many objects need changing.
- An object should notify other objects without making assumptions about who they are — you don't want them tightly coupled.

## Structure
- **Subject**: knows its observers (any number) and provides `Attach`/`Detach`.
- **Observer**: defines the updating interface (`Update`) for objects to be notified of subject changes.
- **ConcreteSubject** (ClockTimer): stores the state of interest; calls `Notify` when that state changes.
- **ConcreteObserver** (DigitalClock, AnalogClock): holds a reference to its ConcreteSubject, stores state that must stay consistent with the subject's, and implements `Update` to reconcile.

Collaboration: ConcreteSubject notifies its observers whenever a change could make their state inconsistent with its own; each ConcreteObserver then queries the subject for what it needs. Note that the observer that *initiated* a change postpones its own update until the notification arrives — and `Notify` is not always called by the subject; an observer or a third party may call it.

## How
1. Define abstract `Subject` with `Attach(Observer*)`, `Detach(Observer*)`, and a protected `Notify()` that walks the observer list calling `Update(this)`.
2. Define abstract `Observer` with `virtual void Update(Subject* changedSubject) = 0;` — pass the subject so one observer can watch several.
3. In ConcreteSubject, add the real state plus accessors; decide whether setters call `Notify` themselves or clients do.
4. In ConcreteObserver, store the subject reference, implement `Update` to check *which* subject notified, then re-read and redisplay.
5. Attach observers at construction/configuration time; detach in the observer's destructor.
6. If dependencies get complex, hand mapping and update strategy to a ChangeManager instead of putting the list in Subject.

## Consequences
**Benefits**
- **Abstract coupling between Subject and Observer.** The subject knows only that it holds a list of objects conforming to the simple Observer interface — never their concrete classes. Because coupling is minimal, subject and observer can sit in **different layers of abstraction**: a lower-level subject can inform a higher-level observer without violating layering. Fusing them would force the merged object to span two layers or compromise one.
- **Support for broadcast communication.** Notification specifies no receiver; it goes to everyone subscribed. The subject's only responsibility is to notify — observers may handle or ignore, and can be added and removed at any time.

**Liabilities**
- **Unexpected updates.** Observers are blind to each other, so a seemingly innocuous operation on the subject can cascade through observers and their dependents. Poorly defined dependency criteria produce spurious updates that are painful to track down.
- Aggravating this, the bare update protocol says **nothing about what changed**. Without extra protocol, observers must work hard to deduce the delta.

## Implementation Notes
- **Push vs. pull models.** In the **push model** the subject sends observers detailed change information whether they want it or not; in the **pull model** it sends the most minimal notification and observers ask for details afterwards. Pull emphasizes the subject's ignorance of its observers; push assumes the subject knows something about observers' needs. Push can make observers **less reusable** (Subject classes bake in assumptions that may not hold); pull can be **inefficient** (observers must ascertain what changed unaided). Most real designs sit somewhere in between.
- **Specifying modifications of interest explicitly.** Extend the registration interface so observers register only for events they care about — the notion of **aspects**. Attach as `void Subject::Attach(Observer*, Aspect& interest);` and notify as `void Observer::Update(Subject*, Aspect& interest);`. At notification time the subject supplies the changed aspect as a parameter, and informs only observers registered for it. This is the cheapest fix for cascade and spurious-update problems.
- **Encapsulating complex update semantics: the ChangeManager.** When subject↔observer dependencies get complex, introduce a **ChangeManager** with three responsibilities: (a) map subjects to observers and maintain that mapping — eliminating the need for subjects to hold observer references or vice versa; (b) define an update *strategy*; (c) update all dependent observers on request from a subject. `SimpleChangeManager` naively updates every observer of each subject. **`DAGChangeManager`** handles directed-acyclic graphs of dependencies: when an observer observes several subjects and a single operation changes two or more of them, the DAG manager collapses the redundant notifications into **exactly one update**. ChangeManager is an instance of **Mediator**, and since there is normally one known globally, it is a natural **Singleton**.
- **Dangling references to deleted subjects.** Deleting a subject must not leave dangling references in its observers. Have the subject **notify its observers as it is deleted** so they reset their references. Simply deleting the observers is generally *not* an option — other objects may reference them, and they may be observing other subjects too.
- **Who triggers the update?** Either (a) state-setting operations on Subject call `Notify` themselves — clients can't forget, but *n* consecutive setters cause *n* updates; or (b) clients call `Notify` after a batch of changes — efficient, but clients can forget. Document which Subject operations trigger notifications either way.
- **Self-consistency before notification.** Observers query the subject during `Update`, so the subject must be self-consistent when `Notify` fires. This is easy to break when a subclass operation calls the inherited one, which notifies mid-way. The fix: send notifications from a **Template Method** in the abstract Subject, with `Notify` as the *last* call and a primitive operation for subclasses to override.
- **Mapping subjects to observers.** Explicit references in the subject are simplest but costly with many subjects and few observers; an associative lookup (hash table) trades access time for space so observer-less subjects cost nothing.
- **Observing more than one subject** requires the subject to pass itself to `Update`.
- **Combining Subject and Observer.** Languages without multiple inheritance (Smalltalk) merge both interfaces into one class — in Smalltalk they live in class `Object`, so any object can be both.

## Worked Example
A `ClockTimer` subject with `DigitalClock` and `AnalogClock` observers, both mixing the Observer interface into a toolkit `Widget`.

```cpp
class Observer {
public:
    virtual ~Observer();
    virtual void Update(Subject* theChangedSubject) = 0;
protected:
    Observer();
};

class Subject {
public:
    virtual ~Subject();
    virtual void Attach(Observer*);
    virtual void Detach(Observer*);
    virtual void Notify();
protected:
    Subject();
private:
    List<Observer*>* _observers;
};

void Subject::Notify () {
    ListIterator<Observer*> i(_observers);
    for (i.First(); !i.IsDone(); i.Next()) {
        i.CurrentItem()->Update(this);   // subject passes itself
    }
}

void ClockTimer::Tick () {
    // update internal time-keeping state
    Notify();                            // last thing: state is consistent
}

class DigitalClock : public Widget, public Observer {
public:
    DigitalClock(ClockTimer*);
    virtual ~DigitalClock();
    virtual void Update(Subject*);
    virtual void Draw();
private:
    ClockTimer* _subject;
};

DigitalClock::DigitalClock (ClockTimer* s) { _subject = s; _subject->Attach(this); }
DigitalClock::~DigitalClock ()             { _subject->Detach(this); }

void DigitalClock::Update (Subject* theChangedSubject) {
    if (theChangedSubject == _subject) {   // guard: which subject?
        Draw();
    }
}

void DigitalClock::Draw () {
    int hour = _subject->GetHour();        // pull model: ask for details
    int minute = _subject->GetMinute();
    // ... draw the digital clock face
}
```

Wiring it up:

```cpp
ClockTimer* timer = new ClockTimer;
AnalogClock* analogClock = new AnalogClock(timer);
DigitalClock* digitalClock = new DigitalClock(timer);
```

Every tick redisplays both clocks. It demonstrates the pull model (`Update` carries only the subject; `Draw` fetches hour and minute), the multi-subject guard, and `Notify` fired last from `Tick`.

## Anti-patterns & Smells
- **Notifying from an inconsistent state**: a subclass operation calls the inherited setter, which notifies before the subclass finishes its own work — observers read half-updated data. Route notification through a template method whose last step is `Notify`.
- **Dangling observer references**: deleting a subject without telling its observers. Notify on destruction; never "just delete the observers."
- **Forgetting to detach** in the observer's destructor — the subject keeps calling `Update` on freed memory.
- **Update storms**: fine-grained setters each calling `Notify` during a bulk edit. Batch the changes and notify once, or register aspects of interest.
- **Push model overreach**: shipping observer-specific payloads in `Update` welds the subject to observers it was supposed to know nothing about.
- **Redundant updates in a diamond**: one observer on two subjects changed by one operation gets notified twice. That's precisely what `DAGChangeManager` exists to prevent.
- **Undocumented notification points**: if it isn't written down which operations notify, nobody can reason about the cascade.

## Known Uses
- **Smalltalk MVC** — the first and best-known example. `Model` plays Subject, `View` is the base class for observers; the general dependency mechanism lives in the root class `Object`, so any object can be a subject or observer. A spreadsheet view and a bar-chart view over one model stay in sync without knowing about each other.
- **ET++** and the **THINK class library** — likewise put Subject and Observer interfaces in the universal parent class.
- **InterViews** — defines `Observer` and `Observable` (for subjects) explicitly.
- **Andrew Toolkit** — calls them "view" and "data object"; **Unidraw** splits graphical editor objects into View (observer) and Subject parts.

## Related Patterns
- **Mediator**: by encapsulating complex update semantics, the ChangeManager acts as mediator between subjects and observers. More broadly, Observer and Mediator are **competing patterns** — Observer *distributes* communication across Subject and Observer objects, whereas Mediator *encapsulates* it in one place. No single object in Observer holds the constraint; subject and observers cooperate to maintain it. Reusable Observers and Subjects are easier to build than reusable Mediators (finer-grained classes, looser coupling), but the flow of communication is easier to *understand* in Mediator, since observer/subject connections are made just after creation and are hard to see later. In Smalltalk, observers can be parameterized with the message used to access subject state, making them more reusable still — so a Smalltalk programmer often uses Observer where a C++ programmer would use Mediator.
- **Singleton**: the ChangeManager is normally unique and globally accessible.
- **Template Method**: use one in the abstract Subject so `Notify` fires last and state is self-consistent.
- **Command**: also decouples sender from receiver, but through an object that binds *one* sender to *one* receiver with a polymorphic `Execute`. Observer's binding is looser — a subject may have many observers, varying at run-time — and its interfaces are designed specifically for **communicating changes**, so Observer is the right choice when the relationship is a *data dependency*.
- **Chain of Responsibility**: another sender/receiver decoupler, but the request travels a chain looking for one handler rather than broadcasting to all.

## Key Takeaways
1. Default to the pull model; adopt push only where you can prove the efficiency matters and can accept observers becoming less reusable.
2. Register **aspects** of interest as soon as observers start ignoring most notifications — it is the cheapest cure for update storms.
3. Introduce a **ChangeManager** (a Mediator, usually a Singleton) once dependencies form a graph; use `DAGChangeManager` so an observer of several subjects gets exactly one update.
4. Make subject deletion notify observers, and make observer deletion detach — dangling references are this pattern's signature bug.
5. Always leave the subject self-consistent before `Notify`, ideally by making `Notify` the last step of a Template Method.
