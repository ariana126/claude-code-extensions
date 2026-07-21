# Abstract Factory
**Classification**: Object Creational | **Chapter**: 3

## Intent
Provide an interface for creating families of related or dependent objects without specifying their concrete classes.

## Also Known As
Kit

## Core Idea
Push the knowledge of *which* concrete classes to instantiate into a single factory object, and pass that object around as a parameter. Swapping one factory object for another swaps an entire product family at once.

## Applicability
Use Abstract Factory when:
- A system should be independent of how its products are created, composed, and represented.
- A system should be configured with one of multiple families of products.
- A family of related product objects is designed to be used together, and you need to enforce that constraint.
- You want to ship a class library of products revealing only their interfaces, not their implementations.

## Structure
- **AbstractFactory** (WidgetFactory, MazeFactory): declares an interface for operations that create abstract product objects.
- **ConcreteFactory** (MotifWidgetFactory, PMWidgetFactory, EnchantedMazeFactory): implements those operations to create concrete product objects.
- **AbstractProduct** (Window, ScrollBar, Room): declares the interface for one type of product.
- **ConcreteProduct** (MotifWindow, MotifScrollBar, EnchantedRoom): defines the product created by the corresponding concrete factory; implements the AbstractProduct interface.
- **Client**: uses only the AbstractFactory and AbstractProduct interfaces.

Collaboration: normally one instance of a ConcreteFactory is created at run-time and handed to clients; clients call its create operations and manipulate the returned products only through abstract interfaces. AbstractFactory defers actual creation to its ConcreteFactory subclass.

## How
1. Enumerate the product kinds that vary together — that's your family (scroll bar + window + button; room + wall + door).
2. Declare an AbstractProduct class per product kind.
3. Declare AbstractFactory with one create operation per product kind (`MakeWall`, `MakeRoom`, `MakeDoor`).
4. Write one ConcreteFactory per family, each overriding every create operation to return its family's ConcreteProducts.
5. Instantiate the concrete factory once, at the single place in the application that decides the family; pass it as a parameter everywhere else.
6. Keep clients typed against AbstractProduct — no concrete product name may appear in client code.

## Consequences
**Benefits**
- **Isolates concrete classes.** Product class names appear only inside the concrete factory, never in client code.
- **Makes exchanging product families easy.** The concrete factory's class name appears exactly once — where it's instantiated — so the whole family changes with one edit.
- **Promotes consistency among products.** Using one factory mechanically guarantees you never mix a Motif scroll bar with a PM button.

**Liabilities**
- **Supporting new *kinds* of products is difficult.** The AbstractFactory interface fixes the set of products. Adding a new kind means changing AbstractFactory and every subclass.

## Implementation Notes
- **Factories as singletons.** You typically need one ConcreteFactory instance per family, so implement it as a Singleton.
- **Creating the products.** The usual implementation is a Factory Method per product; simple, but it needs a new ConcreteFactory subclass per family even when families barely differ.
- **Factories as prototypes.** If many families are possible, implement the concrete factory with Prototype: initialize it with a prototypical instance of each product and have it clone. This eliminates the per-family subclass entirely. In Smalltalk the prototypes live in a `partCatalog` dictionary and `make:` retrieves and copies.
- **Classes as degenerate factories.** In Smalltalk or Objective C, store *classes* rather than prototypes in `partCatalog`; a new factory is then just a differently initialized instance, no subclassing. Language-dependent, unlike the prototype version.
- **Defining extensible factories.** Collapse the interface to a single `Make(kind)` operation parameterized by a class identifier, integer, or symbol. More flexible, less type-safe: all products come back with the same abstract return type, and recovering subclass-specific operations requires a downcast (`dynamic_cast`) that can fail. This is the classic flexibility/safety trade-off.

## Worked Example
`MazeFactory` creates the components of a maze — rooms, walls, and doors. `CreateMaze` takes the factory as a parameter instead of naming classes:

```cpp
class MazeFactory {
public:
    MazeFactory();
    virtual Maze* MakeMaze() const          { return new Maze; }
    virtual Wall* MakeWall() const          { return new Wall; }
    virtual Room* MakeRoom(int n) const     { return new Room(n); }
    virtual Door* MakeDoor(Room* r1, Room* r2) const
                                            { return new Door(r1, r2); }
};

Maze* MazeGame::CreateMaze(MazeFactory& factory) {
    Maze* aMaze = factory.MakeMaze();
    Room* r1 = factory.MakeRoom(1);
    Room* r2 = factory.MakeRoom(2);
    Door* theDoor = factory.MakeDoor(r1, r2);

    aMaze->AddRoom(r1);
    aMaze->AddRoom(r2);
    r1->SetSide(North, factory.MakeWall());
    r1->SetSide(East,  theDoor);
    r2->SetSide(West,  theDoor);
    r2->SetSide(South, factory.MakeWall());
    return aMaze;
}
```

`BombedMazeFactory` overrides only `MakeWall` (returning `BombedWall`) and `MakeRoom` (returning `RoomWithABomb`); `EnchantedMazeFactory` overrides `MakeRoom` and `MakeDoor`. Calling `CreateMaze(bombedFactory)` yields a bombed maze with no change to `CreateMaze`.

What it demonstrates: the same construction code produces entirely different product families purely by substituting the factory argument. Note that `MazeFactory` here is concrete — it plays both AbstractFactory and ConcreteFactory, a common simplification. Also note it is nothing but a collection of factory methods.

## Anti-patterns & Smells
- **A "factory" that creates one product**: that's a Factory Method (or just a constructor). Abstract Factory earns its complexity only when a *family* must stay consistent.
- **Adding product kinds after the fact**: each new kind ripples through AbstractFactory and every ConcreteFactory. If the product set is still churning, prefer Prototype or a parameterized `Make(kind)`.
- **Leaking concrete product names into clients**: downcasting the result of a create operation defeats the isolation the pattern buys. Safe only when the factory guarantees the family (e.g. `Wall*` → `BombedWall*` when everything came from `BombedMazeFactory`).
- **A factory hierarchy that parallels the product hierarchy one-to-one**: you have gained nothing over Factory Method; Prototype is usually the better answer.

## Known Uses
- **InterViews**: uses the "Kit" suffix — `WidgetKit` and `DialogKit` produce look-and-feel-specific UI objects; `LayoutKit` produces different composition objects depending on document orientation.
- **ET++**: the `WindowSystem` abstract base class (`MakeWindow`, `MakeFont`, `MakeColor`) achieves portability across X Windows and SunView; a concrete subclass instance is created at run-time.

## Related Patterns
- **Factory Method**: AbstractFactory operations are usually implemented as factory methods — one per product.
- **Prototype**: an alternative implementation; the concrete factory stores prototypes and clones them, removing the need for a factory subclass per family. Prototype and Abstract Factory are competitors as well as collaborators.
- **Singleton**: a concrete factory is often a singleton.
- **Builder**: also builds complex objects, but step by step under a director's control and returns the product last; Abstract Factory emphasizes families and returns products immediately.

## Key Takeaways
1. Use Abstract Factory when products must vary *together*; the guarantee of family consistency is the real payoff, not merely hiding `new`.
2. This is the "define an object that knows the product classes and make it a system parameter" route — as opposed to Factory Method's "subclass the creator." It's more flexible than Factory Method but more complex, and unlike Factory Method it costs you a whole class rather than a single new operation.
3. Design the product *set* carefully up front: adding a family is cheap, adding a new kind of product is expensive. When new kinds are likely, back the factory with Prototype or a parameterized `Make(kind)` and accept the loss of static type safety.
