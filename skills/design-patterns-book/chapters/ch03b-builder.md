# Builder
**Classification**: Object Creational | **Chapter**: 3

## Intent
Separate the construction of a complex object from its representation so that the same construction process can create different representations.

## Core Idea
Split "the algorithm that decides what parts to build, in what order" (the director) from "what a part actually is and how it's assembled" (the builder). Reuse the first, swap the second.

## Applicability
Use Builder when:
- The algorithm for creating a complex object should be independent of the parts that make up the object and how they're assembled.
- The construction process must allow different representations for the object being constructed.

## Structure
- **Builder** (TextConverter, MazeBuilder): abstract interface for creating parts of a Product.
- **ConcreteBuilder** (ASCIIConverter, TeXConverter, TextWidgetConverter, StandardMazeBuilder): implements the Builder interface to construct and assemble parts; keeps track of the representation it creates; provides an interface for *retrieving* the product (`GetASCIIText`, `GetMaze`).
- **Director** (RTFReader, MazeGame::CreateMaze): constructs the object using only the Builder interface.
- **Product** (ASCIIText, TeXText, TextWidget, Maze): the complex object under construction, plus the classes defining its constituent parts.

Collaboration: the client creates the Director and configures it with the desired Builder. The Director notifies the builder each time a part should be built; the builder handles the request and adds the part to the product. When construction finishes, **the client — not the director — retrieves the product from the builder.**

## How
1. Identify the construction *algorithm* (parsing, walking a plan, reading a file) and isolate it in the Director.
2. Define the Builder interface with one operation per part the director may request. Give them empty default bodies — not pure virtual — so subclasses override only what they care about.
3. Add a product-retrieval operation to each ConcreteBuilder (its return type is builder-specific; there is usually no abstract Product class).
4. Write ConcreteBuilders: each owns its own product representation and knows how parts are appended or wired together.
5. Client: instantiate a ConcreteBuilder, hand it to the Director, run the director, then ask the builder for the product.

## Consequences
**Benefits**
- **It lets you vary a product's internal representation.** The builder hides both the product's structure and how it's assembled; a new representation is just a new builder.
- **It isolates code for construction and representation.** Clients need know nothing about the product's internal classes; those classes never appear in the Builder interface. Different Directors reuse the same builders — an `SGMLReader` can drive the same TextConverters as `RTFReader`.
- **It gives you finer control over the construction process.** Unlike creational patterns that build in one shot, Builder constructs step by step under the director's control, and the product is retrieved only when finished.

**Liabilities**
- The Builder interface must be general enough for *all* concrete builders, which pulls it toward a lowest common denominator.
- Products from different concrete builders usually share no common base class, so clients must know which concrete builder is in play to use the result.

## Implementation Notes
- **Assembly and construction interface.** Appending results to the product is usually enough (the RTF builder converts and appends the next token). But sometimes the director needs parts built earlier — `MazeBuilder` lets you add a door *between existing rooms*, identified by number. For bottom-up tree building (parse trees), the builder returns child nodes to the director, which passes them back in to build parents.
- **Why no abstract class for products?** Products from different builders typically differ so much in representation that a common parent buys nothing — `ASCIIText` and `TextWidget` share no useful interface. Since the client configures the director with the builder, the client already knows which product type it will get.
- **Empty methods as default in Builder.** In C++ the build methods are deliberately *not* pure virtual; they're empty, so a concrete builder overrides only the operations it's interested in (see `CountingMazeBuilder`).

## Worked Example
`MazeBuilder` declares the vocabulary of maze construction — build a maze, build a numbered room, build a door between two numbered rooms — with empty defaults:

```cpp
class MazeBuilder {
public:
    virtual void BuildMaze()                     { }
    virtual void BuildRoom(int room)             { }
    virtual void BuildDoor(int roomFrom, int roomTo) { }
    virtual Maze* GetMaze()                      { return 0; }
protected:
    MazeBuilder();
};

Maze* MazeGame::CreateMaze(MazeBuilder& builder) {
    builder.BuildMaze();
    builder.BuildRoom(1);
    builder.BuildRoom(2);
    builder.BuildDoor(1, 2);
    return builder.GetMaze();
}
```

`StandardMazeBuilder` holds `_currentMaze`; `BuildRoom` creates a `Room`, walls it on all four sides, and adds it; `BuildDoor` looks both rooms up in the maze, finds their `CommonWall`, and replaces it with a `Door`. `CountingMazeBuilder` builds nothing at all — it just increments `_rooms` and `_doors` and answers `GetCounts`, so the same `CreateMaze` algorithm becomes a maze *analyzer*.

```cpp
void StandardMazeBuilder::BuildRoom(int n) {
    if (!_currentMaze->RoomNo(n)) {
        Room* room = new Room(n);
        _currentMaze->AddRoom(room);
        room->SetSide(North, new Wall);
        room->SetSide(South, new Wall);
        room->SetSide(East,  new Wall);
        room->SetSide(West,  new Wall);
    }
}
```

What it demonstrates: compared with the Abstract Factory version, `CreateMaze` no longer mentions walls at all — there is not even a hint that a `Wall` class exists. The builder owns the representation, so the maze's internal structure can change without touching any client.

## Anti-patterns & Smells
- **Confusing Builder with a fluent setter chain**: a chain of setters on one class is a convenience idiom, not this pattern. Builder requires a director whose *algorithm* is reused across different representations.
- **Putting the build operations on the Product itself**: you could have let `Maze` build itself, but then you get one representation forever. Separating `StandardMazeBuilder` from `Maze` is what enables a variety of builders.
- **Making the build methods pure virtual**: forces every concrete builder to implement operations it doesn't care about; `CountingMazeBuilder` would become noise.
- **Having the director return the product**: the client retrieves it from the builder, because only the builder knows the concrete product type.

## Known Uses
- **ET++**: the RTF converter application; its text building block uses a builder to process RTF-stored text.
- **Smalltalk-80**: `Parser` is a Director driving a `ProgramNodeBuilder` to produce a parse tree; `ClassBuilder` is used by classes to create their own subclasses (a `Class` is both Director and Product); `ByteCodeStream` builds a compiled method as a byte array.
- **ACE Service Configurator**: an LALR(1) parser is the Director; its semantic actions drive a builder that constructs network service components linked into a server at run-time.

## Related Patterns
- **Abstract Factory**: also constructs complex objects, but emphasizes *families* of products and returns each product immediately; Builder constructs one product step by step and returns it as the final step.
- **Composite**: what the builder often builds.
- **Factory Method**: a Builder can use factory methods internally to decide which component classes to instantiate.
- **Singleton**: builders and the factories they use are often singletons.

## Key Takeaways
1. Reach for Builder when the *construction algorithm* is worth reusing across different output representations — that's the axis of variation it serves, and it is what distinguishes it from Abstract Factory.
2. Builder is the object-composition route to parameterizing creation: a factory object that assembles a complex product incrementally through a correspondingly complex protocol. Like Abstract Factory and Prototype, it's more flexible than Factory Method and more complex.
3. Give build operations empty defaults, keep the product retrieval on the concrete builder, and resist inventing an abstract Product class you don't need.
