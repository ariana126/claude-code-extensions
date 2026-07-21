# Prototype
**Classification**: Object Creational | **Chapter**: 3

## Intent
Specify the kinds of objects to create using a prototypical instance, and create new objects by copying this prototype.

## Core Idea
Instead of naming a class to instantiate, hold an *instance* and clone it. The prototype object is both the specification of the product and the factory that produces it.

## Applicability
Use Prototype when a system should be independent of how its products are created, composed, and represented; **and**
- The classes to instantiate are specified at run-time — for example, by dynamic loading; **or**
- You want to avoid building a class hierarchy of factories that parallels the class hierarchy of products; **or**
- Instances of a class can have only a few different combinations of state — installing that many prototypes and cloning them beats instantiating the class by hand with the right state each time.

## Structure
- **Prototype** (Graphic): declares an interface for cloning itself.
- **ConcretePrototype** (Staff, WholeNote, HalfNote): implements the clone operation.
- **Client** (GraphicTool): creates a new object by asking a prototype to clone itself.

Collaboration: a client — often parameterized with one prototype at construction time — simply asks that prototype to clone itself, then optionally initializes the clone. That's the whole protocol.

## How
1. Declare `Clone()` on the abstract product class, returning the *abstract* type.
2. Implement `Clone()` in each concrete product, typically via a copy constructor: `Wall* Wall::Clone() const { return new Wall(*this); }`.
3. Decide, per class, shallow versus deep copy — cloning forces you to decide what, if anything, is shared.
4. Add an `Initialize(...)` operation where a bare copy isn't enough, so clients can set the clone's state after cloning.
5. Parameterize the client with prototype instances instead of subclassing it.
6. If the prototype set is dynamic, add a prototype manager (registry) that maps keys to prototypes.

## Consequences
Prototype shares Abstract Factory's and Builder's benefits: it hides the concrete product classes from the client, reduces the number of names clients must know, and lets clients work with application-specific classes without modification. Additionally:

**Benefits**
- **Adding and removing products at run-time.** Register a prototypical instance and a new concrete product class is in the system; clients can install and remove prototypes while running. More flexible than the other creational patterns on this axis.
- **Specifying new objects by varying values.** Define new kinds of object by instantiating existing classes with different state and registering them as prototypes — users define new "classes" without programming. One `GraphicTool` class can create a limitless variety of music objects.
- **Specifying new objects by varying structure.** A user-assembled subcircuit can itself be added to the palette as a prototype, provided the composite implements `Clone` as a **deep** copy.
- **Reduced subclassing.** Factory Method breeds a Creator hierarchy paralleling the product hierarchy; cloning a prototype removes the need for a Creator hierarchy at all. This matters most in C++; in Smalltalk and Objective C class objects already act like prototypes.
- **Configuring an application with classes dynamically.** For dynamically loaded classes whose constructors can't be referenced statically, the runtime instantiates each class as it loads and registers it with a prototype manager; the application then asks the manager for instances of classes that were never linked in. ET++ works this way.

**Liabilities**
- **Every subclass of Prototype must implement `Clone`**, which can be hard — especially for classes that already exist, or whose internals contain objects that don't support copying or that have circular references.

## Implementation Notes
- **Using a prototype manager.** When the set of prototypes isn't fixed, keep a registry: an associative store keyed by name, with register/unregister operations. Clients ask the registry for a prototype before cloning. Clients can browse and extend the system at run-time without writing code.
- **Implementing the Clone operation.** The hardest part, and trickiest with circular references. Language facilities don't solve the shallow-versus-deep-copy problem: Smalltalk's inherited `copy` is shallow, and C++'s default copy constructor is memberwise, so pointers are *shared* between clone and original. Complex prototypes usually need a deep copy so clone and original are independent. If objects support `Save`/`Load`, you get a free default `Clone` by saving to a memory buffer and immediately loading it back.
- **Initializing clones.** You generally can't pass initialization values through `Clone` — the number varies per prototype class, and doing so precludes a uniform cloning interface. Use existing state-setting operations, or introduce an `Initialize` operation. Beware deep-copying clones: the copies may need to be deleted (explicitly or inside `Initialize`) before you reinitialize them.
- **Language fit.** Prototype matters most in static languages like C++ where classes aren't objects and little run-time type information exists. It's built into prototype-based languages like Self, where *all* object creation is cloning.

## Worked Example
`MazePrototypeFactory` subclasses `MazeFactory` but is *initialized with prototypes* rather than subclassed per product family:

```cpp
class MazePrototypeFactory : public MazeFactory {
public:
    MazePrototypeFactory(Maze*, Wall*, Room*, Door*);
    virtual Maze* MakeMaze() const;
    virtual Room* MakeRoom(int) const;
    virtual Wall* MakeWall() const;
    virtual Door* MakeDoor(Room*, Room*) const;
private:
    Maze* _prototypeMaze;
    Room* _prototypeRoom;
    Wall* _prototypeWall;
    Door* _prototypeDoor;
};

Wall* MazePrototypeFactory::MakeWall () const {
    return _prototypeWall->Clone();
}

Door* MazePrototypeFactory::MakeDoor (Room* r1, Room* r2) const {
    Door* door = _prototypeDoor->Clone();
    door->Initialize(r1, r2);
    return door;
}
```

A default maze comes from `MazePrototypeFactory simpleMazeFactory(new Maze, new Wall, new Room, new Door);` — and a bombed maze from `MazePrototypeFactory bombedMazeFactory(new Maze, new BombedWall, new RoomWithABomb, new Door);`. No new factory class either time. `BombedWall` overrides `Clone` and supplies a copy constructor:

```cpp
Wall* BombedWall::Clone () const { return new BombedWall(*this); }
```

Note the return type is `Wall*` even though a `BombedWall*` comes back — declaring `Clone` this way in the base class means clients never downcast the result. In Smalltalk the inherited `Object>>copy` clones any `MapSite`, and `MazeFactory`'s dictionary maps names like `#room` to prototypes.

What it demonstrates: `MakeDoor` is the pattern in miniature — clone, then `Initialize`. The whole product family is chosen by the four constructor arguments, at run-time, with zero subclassing.

## Anti-patterns & Smells
- **Shallow `Clone` on a composite prototype**: clone and original silently share sub-objects; edit one, corrupt the other. Composite prototypes require deep copy.
- **Parameterizing `Clone`**: passing initialization arguments through `Clone` breaks the uniform cloning interface. Clone, then `Initialize`.
- **Retrofitting `Clone` onto an existing hierarchy**: the pattern's main liability. Classes holding uncopyable resources or circular references make this genuinely hard — decide before you commit.
- **Downcasting the result of `Clone`**: declare `Clone` to return the abstract type in the base class so clients never need to know concrete subclasses.
- **Forgetting to delete the deep-copied parts before reinitializing** a clone: a leak hiding inside `Initialize`.

## Known Uses
- **Sketchpad** (Ivan Sutherland, 1963): perhaps the first example of the pattern.
- **ThingLab**: users form a composite object and promote it to a prototype by installing it in a library of reusable objects. Coplien gives the fullest description of the related C++ idioms.
- **etgdb** (ET++-based debugger front-end): reads the adaptor name from an environment variable, finds the matching prototype in a global table, and clones it — new debuggers are added just by linking in a `DebuggerAdaptor`.
- **Mode Composer**: its "interaction technique library" stores prototypes; any technique it creates can become a prototype, supporting an unlimited set.
- **Unidraw**: the music-editor / `GraphicTool` motivating example.

## Related Patterns
- **Abstract Factory**: a competing pattern in some ways, but they combine well — an Abstract Factory can store a set of prototypes and clone them to return products.
- **Factory Method**: Prototype does not require subclassing the Creator, but it does require `Clone` on every product and usually an `Initialize` operation. Factory Method needs neither, but does need a new subclass per product.
- **Composite** and **Decorator**: designs that lean on them often benefit from Prototype, since a user-assembled structure can be promoted to a prototype.
- **Singleton**: a prototype manager is typically implemented as one.

## Key Takeaways
1. Prototype is the object-composition route to parameterizing creation where the "factory object" and the prototype are the *same object* — the prototype is responsible for returning the product.
2. It trades a Creator class hierarchy for a `Clone` implementation on each product plus (usually) an `Initialize`. When the products already exist and cloning is cheap, that's the better bargain — and `Clone` earns its keep elsewhere too, e.g. for a Duplicate menu command.
3. Use it whenever product classes must be added, removed, or configured at run-time — dynamic loading, user-defined "classes" by varying values, or a registry a user can browse. That flexibility is unavailable to Factory Method and Abstract Factory.
