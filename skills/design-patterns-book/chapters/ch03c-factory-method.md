# Factory Method
**Classification**: Class Creational | **Chapter**: 3

## Intent
Define an interface for creating an object, but let subclasses decide which class to instantiate. Factory Method lets a class defer instantiation to subclasses.

## Also Known As
Virtual Constructor

## Core Idea
Replace a constructor call with a call to an overridable operation. The class then knows *when* to create an object without knowing *what kind* — subclasses supply that.

## Applicability
Use Factory Method when:
- A class can't anticipate the class of objects it must create.
- A class wants its subclasses to specify the objects it creates.
- Classes delegate responsibility to one of several helper subclasses, and you want to localize the knowledge of which helper is the delegate.

## Structure
- **Product** (Document): defines the interface of objects the factory method creates.
- **ConcreteProduct** (MyDocument): implements the Product interface.
- **Creator** (Application): declares the factory method returning a Product; may supply a default implementation returning a default ConcreteProduct; typically calls the factory method itself.
- **ConcreteCreator** (MyApplication): overrides the factory method to return a ConcreteProduct instance.

Collaboration: Creator relies on its subclasses to define the factory method so that it returns an instance of the appropriate ConcreteProduct. The Creator's own code manipulates the result only through the Product interface.

## How
1. Find the place in the framework/base class where a concrete class name is hard-coded into a `new`.
2. Declare a factory operation on the Creator returning the abstract Product type (`virtual Document* CreateDocument()`).
3. Replace the `new` with a call to that operation.
4. Either leave it abstract (subclasses *must* supply a product) or give it a sensible default (subclasses override for flexibility).
5. Write ConcreteCreator subclasses overriding the factory method.
6. Adopt a naming convention that flags the mechanism — MacApp uses `Class* DoMakeClass()`.

## Consequences
**Benefits**
- Eliminates the need to bind application-specific classes into framework code; the framework deals only with the Product interface and works with any user-defined ConcreteProduct.
- **Provides hooks for subclasses.** Creating an object inside a factory method is always more flexible than creating it directly — e.g. `Document::CreateFileDialog` gives subclasses a hook for an application-specific dialog while keeping a reasonable default.
- **Connects parallel class hierarchies.** When a class delegates responsibility to a separate class, the factory method localizes which classes belong together — `Figure::CreateManipulator` is overridden by each Figure subclass to return the right Manipulator subclass. Hierarchies may be only *partially* parallel, since subclasses can inherit a default.

**Liabilities**
- Clients may have to subclass Creator *just* to create a particular ConcreteProduct. Fine when they'd subclass anyway; otherwise it's an extra point of evolution and a proliferation of thin subclasses.

## Implementation Notes
- **Two major varieties.** (1) Creator is abstract and gives no implementation — forces subclasses to decide, and solves the "framework must instantiate unforeseeable classes" dilemma. (2) Creator is concrete with a default implementation — used purely for flexibility, following the rule "create objects in a separate operation so subclasses can override the way they're created."
- **Parameterized factory methods.** Let one factory method create multiple product kinds by taking an identifier argument; all products share the Product interface. Unidraw's `Creator::Create(classId)` reconstructs objects from disk: it writes the class identifier first, then on load calls `Create` with it, looks up the constructor, and calls the object's `Read`. Overriding a parameterized factory method lets a subclass swap which product an existing identifier maps to, add new identifiers, and delegate everything else back to the parent:

```cpp
Product* MyCreator::Create (ProductId id) {
    if (id == YOURS) return new MyProduct;
    if (id == MINE)  return new YourProduct;   // swapped
    if (id == THEIRS) return new TheirProduct; // new
    return Creator::Create(id);                // defer the rest
}
```
- **Language-specific variants.** Smalltalk commonly returns the *class* to instantiate rather than the instance: `Application>>documentClass` is the real factory method, and `MyApplication` answers `MyDocument`. Storing that class in a class variable removes the need to subclass at all. In C++, factory methods are virtual and often pure virtual — **never call one from the Creator's constructor**, since the ConcreteCreator's override isn't available yet. Use lazy initialization in an accessor instead: initialize the member to 0 and have the accessor create the product on demand.
- **Using templates to avoid subclassing.** In C++, a template subclass of Creator parameterized by the Product class lets the client supply just the product type — no Creator subclass required.

## Worked Example
`MazeGame` declares a factory method per component, each with a default implementation, and `CreateMaze` calls them instead of constructors:

```cpp
class MazeGame {
public:
    Maze* CreateMaze();
    // factory methods
    virtual Maze* MakeMaze() const          { return new Maze; }
    virtual Room* MakeRoom(int n) const     { return new Room(n); }
    virtual Wall* MakeWall() const          { return new Wall; }
    virtual Door* MakeDoor(Room* r1, Room* r2) const
                                            { return new Door(r1, r2); }
};

Maze* MazeGame::CreateMaze () {
    Maze* aMaze = MakeMaze();
    Room* r1 = MakeRoom(1);
    Room* r2 = MakeRoom(2);
    Door* aDoor = MakeDoor(r1, r2);
    aMaze->AddRoom(r1);
    aMaze->AddRoom(r2);
    r1->SetSide(North, MakeWall());
    r1->SetSide(East,  aDoor);
    r2->SetSide(West,  aDoor);
    r2->SetSide(South, MakeWall());
    return aMaze;
}

class BombedMazeGame : public MazeGame {
public:
    virtual Wall* MakeWall() const      { return new BombedWall; }
    virtual Room* MakeRoom(int n) const { return new RoomWithABomb(n); }
};
```

What it demonstrates: the variation point is a *subclass of the creator*, not a parameter. `EnchantedMazeGame` overrides `MakeRoom` and `MakeDoor` the same way. Compare directly with the Abstract Factory version, where the identical `CreateMaze` body instead calls operations on a `MazeFactory` passed in as an argument — the difference is inheritance versus composition.

## Anti-patterns & Smells
- **Calling a factory method from the Creator's constructor**: the subclass override is not yet installed, so you silently get the base class product.
- **A ConcreteCreator subclass that overrides nothing but one `new`**: the classic proliferation smell. Use a C++ template Creator, a Smalltalk class variable, or Prototype instead.
- **Using Factory Method reflexively**: it isn't needed when the instantiated class never changes, or when instantiation already happens in an operation subclasses can easily override (an initialization operation).
- **Mistaking any static "create" helper for Factory Method**: without the polymorphic override point there is no pattern. In Smalltalk-80's MVC, `View>>defaultController` looks like the factory method but `defaultControllerClass` is the one subclasses actually override.

## Known Uses
- **MacApp and ET++**: the Application/Document example is a typical framework use; MacApp's `DoMakeClass()` naming convention.
- **Unidraw**: the Figure/Manipulator parallel hierarchies, and `Creator::Create(classId)` for reconstructing saved objects.
- **Smalltalk-80**: `View`'s `defaultControllerClass` in MVC; `Behavior>>parserClass`, which lets a class supply a customized parser (e.g. an `SQLParser` for classes with embedded SQL).
- **Orbix ORB (IONA)**: generates the appropriate type of Proxy when an object requests a reference to a remote object, making it easy to substitute a client-side-caching proxy.

## Related Patterns
- **Abstract Factory**: often implemented with factory methods — one per product in the family.
- **Template Method**: factory methods are usually called from within template methods (`NewDocument` in the Document example).
- **Prototype**: an alternative that doesn't require subclassing the Creator, but usually requires an `Initialize` operation on the Product so the Creator can set up the clone. Factory Method needs no such operation.

## Key Takeaways
1. Factory Method is the *inheritance* answer to parameterizing a system by the classes it creates: subclass the creator. Its main drawback is that changing the product class requires a new subclass, and such changes cascade — if the creator is itself produced by a factory method, you must override that creator too.
2. It is the cheapest of the creational patterns: other patterns require new classes, Factory Method only requires a new *operation*. It makes a design more customizable and only a little more complicated.
3. Designs often start with Factory Method and evolve toward Abstract Factory, Builder, or Prototype as more flexibility proves necessary — those are more flexible but also more complex. Don't pay the complexity until the need shows up.
