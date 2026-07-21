# Singleton
**Classification**: Object Creational | **Chapter**: 3

## Intent
Ensure a class only has one instance, and provide a global point of access to it.

## Core Idea
Make the class itself responsible for tracking its sole instance: hide the constructor so nobody else can create one, and expose a class operation that returns (and lazily creates) the instance.

## Applicability
Use Singleton when:
- There must be exactly one instance of a class, and it must be accessible to clients from a well-known access point.
- The sole instance should be extensible by subclassing, and clients should be able to use the extended instance without modifying their code.

## Structure
- **Singleton**: defines an `Instance` operation that lets clients access its unique instance. `Instance` is a *class operation* — a static member function in C++, a class method in Smalltalk. The class may also be responsible for creating its own unique instance.

Collaboration: clients access the singleton solely through `Instance`. There is no other participant — the pattern's entire structure is one class.

## How
1. Declare a static member `_instance` holding a pointer to the sole instance, initialized to 0.
2. Declare a static member function `Instance()` that returns it, creating it if null (lazy initialization).
3. Make the constructor **protected** (not private, if you want subclasses) so direct instantiation is a compile-time error.
4. If subclasses exist, decide inside `Instance` which one to build — from an environment variable, from link-time substitution, or from a registry.
5. Clients call `Singleton::Instance()->Operation()` and never `new`.

## Consequences
**Benefits**
1. **Controlled access to sole instance.** The class encapsulates its instance, so it has strict control over how and when clients get at it.
2. **Reduced name space.** An improvement over global variables — no namespace pollution.
3. **Permits refinement of operations and representation.** The class can be subclassed and the application configured with an instance of the extended class at run-time.
4. **Permits a variable number of instances.** Changing your mind and allowing N instances requires changing only the access operation. The same approach controls the number of instances generally.
5. **More flexible than class operations.** Packaging the functionality as static member functions or class methods makes it hard to relax the "one instance" rule later; worse, C++ static member functions are never virtual, so subclasses can't override them polymorphically.

**Liabilities**
- The pattern is unavoidably a global access point; overuse reproduces the coupling problems of global variables under a better name.
- Subclass selection logic inside `Instance` must change every time a new subclass appears (the motivation for the registry approach).

## Implementation Notes
- **Ensuring a unique instance.** Hide creation behind a class operation that guarantees the variable is initialized before it's returned. Because `_instance` is a *pointer to Singleton*, `Instance` can assign a pointer to a **subclass** — that's what makes benefit 3 possible.
- **Why not just a global or static object in C++?** Three reasons: (a) you can't guarantee only one static object is ever declared; (b) you might lack the information to construct it at static-initialization time — a singleton may need values computed later; (c) C++ doesn't define the order in which constructors for global objects run across translation units, so no dependencies between singletons can be safe. A smaller liability: static objects force all singletons to be created whether used or not. A static member function avoids all of this.
- **Smalltalk.** Implement the accessor as a class method and override `new` so only one instance is created, storing it in a class variable (`SoleInstance`) used nowhere else.
- **Subclassing the Singleton class.** The hard part is not defining the subclass but installing *its* instance. Options: decide inside `Instance` (simplest, but `Instance` must change per subclass); move `Instance`'s implementation out of the parent into the subclass and choose at **link-time** (hidden from clients, but fixed at link-time); or use conditionals (flexible but hard-wires the possible classes).
- **Registry of singletons.** The most flexible option. Singleton classes register their instance by name in a well-known registry (`Register(name, singleton)` / `Lookup(name)`, storing `NameSingletonPair` entries); `Instance` consults the registry — typically with a name from an environment variable — and so needs no knowledge of the possible subclasses. Classes usually register in their constructor, which raises the bootstrap problem: the constructor only runs if someone instantiates the class. In C++ you define `static MySingleton theSingleton;` in the implementation file. The Singleton class is then no longer responsible for *creating* the singleton — only for making the singleton of choice accessible. Drawback: instances of every possible subclass get created, or they never register.

## Worked Example
The maze application needs exactly one `MazeFactory`, reachable from any code that builds part of the maze — without a global variable.

```cpp
class MazeFactory {
public:
    static MazeFactory* Instance();
    // ... factory operations: MakeMaze, MakeWall, MakeRoom, MakeDoor
protected:
    MazeFactory();
private:
    static MazeFactory* _instance;
};

MazeFactory* MazeFactory::_instance = 0;

MazeFactory* MazeFactory::Instance () {
    if (_instance == 0) {
        _instance = new MazeFactory;
    }
    return _instance;
}
```

With subclasses in play, `Instance` picks the kind of maze from an environment variable:

```cpp
MazeFactory* MazeFactory::Instance () {
    if (_instance == 0) {
        const char* mazeStyle = getenv("MAZESTYLE");
        if (strcmp(mazeStyle, "bombed") == 0) {
            _instance = new BombedMazeFactory;
        } else if (strcmp(mazeStyle, "enchanted") == 0) {
            _instance = new EnchantedMazeFactory;
        } else {
            _instance = new MazeFactory;     // default
        }
    }
    return _instance;
}
```

What it demonstrates: the singleton makes the Abstract Factory globally reachable *and* becomes the place where the product family is chosen. The catch is stated plainly: `Instance` must be modified whenever you define a new `MazeFactory` subclass — tolerable in one application, a problem for an abstract factory defined in a framework. The registry approach, plus dynamic linking so unused subclasses never load, is the way out.

## Anti-patterns & Smells
- **Singleton as a global variable with manners**: the pattern controls *access*, it doesn't make widely shared mutable state a good design. If clients don't need one instance, they need a parameter.
- **Global/static object instead of a static accessor in C++**: falls to the static-initialization-order problem across translation units and to singletons needing run-time values.
- **Packaging the behavior as class/static operations**: locks out subclass polymorphism (C++ statics are never virtual) and forecloses ever allowing more than one instance.
- **A private constructor when you intend to subclass**: the constructor must be `protected` for benefit 3 to work.
- **A growing `if/else` chain of subclass names inside `Instance`**: a framework-scale smell — switch to the registry.

## Known Uses
- **Smalltalk-80**: the set of changes to the code, `ChangeSet current`. More subtly, the relationship between classes and their **metaclasses** — each metaclass has exactly one instance, keeps track of it, and won't normally create another.
- **InterViews**: the unique instances of `Session` (the main event dispatch loop, the user's style preferences database, display connections) and `WidgetKit`. `WidgetKit::instance()` picks the concrete `WidgetKit` subclass based on an environment variable defined by `Session` — a real instance of the environment-variable subclass-selection technique.

## Related Patterns
- **Abstract Factory**: a concrete factory is typically a Singleton, since one instance per product family suffices.
- **Builder**: builders and the directors that drive them are often singletons.
- **Prototype**: the prototype manager (registry of prototypes) is typically a Singleton.
- **Facade**: usually implemented as a Singleton too. In general, many patterns are implemented using Singleton.

## Key Takeaways
1. Reach for Singleton to control access and preserve the option of subclassing or of relaxing "exactly one" later — not merely to make something reachable. That option value is precisely what static/class operations throw away.
2. In C++, always use a static accessor with a protected constructor and lazy initialization; never rely on a global or static object's automatic initialization.
3. Singleton is the natural companion to the object-composition creational patterns — the "object that knows the product classes" (Abstract Factory, Builder, Prototype's prototype manager) is exactly the thing you want exactly one of, and its `Instance` operation is the natural place to decide *which* family the system uses. When that decision starts hard-wiring subclass names, move it to a registry.
