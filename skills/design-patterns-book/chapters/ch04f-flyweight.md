# Flyweight
**Classification**: Object Structural | **Chapter**: 4

## Intent
Use sharing to support large numbers of fine-grained objects efficiently.

## Also Known As
*(none given)*

## Core Idea
Split an object's state into **intrinsic** (context-independent, stored in the
object, therefore sharable) and **extrinsic** (context-dependent, therefore
passed in by the client at call time). Once only intrinsic state remains, one
instance can serve every occurrence.

## Applicability
Apply Flyweight when **all** of the following are true:
- An application uses a large number of objects.
- Storage costs are high because of the sheer quantity of objects.
- Most object state can be made extrinsic.
- Many groups of objects can be replaced by relatively few shared objects once extrinsic state is removed.
- The application **doesn't depend on object identity** — identity tests on shared flyweights will return true for conceptually distinct objects.

## Structure
- **Flyweight** (Glyph): declares an interface through which flyweights can receive and act on extrinsic state (`Draw(GlyphContext&)`, `Intersects(...)`).
- **ConcreteFlyweight** (Character): implements Flyweight and stores intrinsic state, if any. It **must be sharable**: any state it holds must be independent of context.
- **UnsharedConcreteFlyweight** (Row, Column): not all Flyweight subclasses need be shared — the interface *enables* sharing, it doesn't enforce it. Unshared flyweights commonly have ConcreteFlyweights as children.
- **FlyweightFactory** (GlyphFactory): creates and manages flyweights, ensuring proper sharing — returns an existing instance or creates one if none exists.
- **Client**: keeps references to flyweights and computes or stores their extrinsic state.

Collaboration: all needed state is classified intrinsic or extrinsic; intrinsic
lives in the ConcreteFlyweight, extrinsic is stored or computed by clients and
passed on every call. **Clients must never instantiate ConcreteFlyweights
directly** — they obtain them exclusively from the FlyweightFactory.

## How
1. Enumerate the state of the fine-grained object and classify each field intrinsic vs. extrinsic.
2. Rewrite the Flyweight interface so every operation that needs context takes it as a parameter.
3. Move extrinsic state into a separate, compact structure the client owns (a context object, a run-based map).
4. Add a FlyweightFactory with an associative store keyed by the intrinsic state (e.g. character code) and route all creation through it.
5. Decide reclamation: reference counting or GC — unnecessary if the flyweight set is fixed and small (the ASCII table), where you simply keep them forever.

## Consequences
**Benefits**
- Dramatic storage savings, growing with the degree of sharing. Savings are a function of: the reduction in instance count from sharing, the amount of intrinsic state per object, and whether extrinsic state is computed rather than stored.
- The **greatest savings** occur when objects use substantial amounts of *both* intrinsic and extrinsic state and the extrinsic state can be **computed**: sharing removes the intrinsic cost and computation removes the extrinsic cost.
- Makes an object abstraction practical at granularities where it would otherwise be unaffordable (an object per character).

**Liabilities**
- Run-time costs for transferring, finding, and/or computing extrinsic state — especially state that used to be stored intrinsically. You are trading space for time.
- **Object identity becomes meaningless.** Conceptually distinct occurrences are the same instance.
- Combined with Composite, **flyweight leaf nodes cannot store a parent pointer** — the parent must be passed in as extrinsic state, which materially changes how objects in the hierarchy communicate.
- Clients get more complicated: they must own and manage the extrinsic state structure.

## Implementation Notes
- **Removing extrinsic state.** Applicability hinges on how easy this is. Removing extrinsic state gains nothing if there are as many *kinds* of extrinsic state as there were objects. Ideally the extrinsic state is computed from a separate, far smaller structure. In the document editor, typographic attributes live in a map of *runs* of characters sharing attributes; a character receives its font as a side effect of the draw traversal.
- **Managing shared objects.** Clients must not instantiate flyweights; the FlyweightFactory uses an associative store (a table indexed by character code) to look one up and create it lazily. Sharing implies reference counting or garbage collection to reclaim storage — unless the flyweight population is fixed and small, in which case keep them permanently.

## Worked Example
A document editor with one object per character. `Glyph` is the flyweight
interface; only `Character` is shared. Font is made extrinsic and stored in a
`GlyphContext`.

```cpp
class Glyph {                                  // Flyweight
public:
    virtual void Draw(Window*, GlyphContext&);
    virtual void SetFont(Font*, GlyphContext&);
    virtual Font* GetFont(GlyphContext&);
    virtual void First(GlyphContext&);
    virtual void Next(GlyphContext&);
    virtual bool IsDone(GlyphContext&);
};

class Character : public Glyph {               // ConcreteFlyweight
public:
    Character(char c) : _charcode(c) { }
    virtual void Draw(Window* w, GlyphContext& gc) {
        Font* f = gc.GetFont();                // extrinsic, supplied per context
        w->DrawCharacter(_charcode, f);
    }
private:
    char _charcode;                            // the only intrinsic state
};

class GlyphFactory {                           // FlyweightFactory
public:
    Character* CreateCharacter(char c) {
        if (_character[c] == 0) {
            _character[c] = new Character(c);  // create once, share forever
        }
        return _character[c];
    }
    Row*    CreateRow()    { return new Row; }     // unshared
    Column* CreateColumn() { return new Column; }
private:
    Character* _character[NCHARCODES];
};
```

What it demonstrates: a document of any length allocates roughly one `Character`
per distinct character code. `GlyphContext` holds the extrinsic font mapping in
a **BTree** whose interior nodes label index ranges and whose leaves point to
fonts; `GlyphContext::Next` advances `_index` as the traversal proceeds, and
composite glyphs (`Row`, `Column`) must call it at each step. Because font
changes are infrequent, the tree stays small relative to the glyph structure —
look-up time is proportional to font-change frequency, worst case one change per
character (rare in practice).

## Anti-patterns & Smells
- **Sharing objects that still hold context**: any context-dependent field left in a ConcreteFlyweight corrupts every other user of that instance.
- **Identity tests on flyweights**: `charA == charB` is true for two different occurrences. If your design depends on identity, Flyweight is disqualified outright.
- **Letting clients `new` a ConcreteFlyweight**: bypasses the factory and destroys sharing. Even for currently-unshared kinds, route creation through the factory so you can start sharing later without touching client code.
- **Extrinsic state as varied as the objects**: if you need a distinct context per occurrence, you've relocated the memory, not saved it.
- **Applying it without measuring**: the pattern's effectiveness "depends heavily on how and where it's used" — all five applicability conditions must hold.

## Known Uses
- **InterViews 3.0** — where flyweights were first described as a design technique; the **Doc** editor was the proof of concept. Doc builds one `Glyph` per character *per style*, so intrinsic state is the character code plus a style-table index, leaving only position extrinsic — which makes Doc fast. `Document` doubles as the FlyweightFactory. Measured result: a 180,000-character document needed only **480** character objects.
- **ET++** — look-and-feel independence. Each widget delegates layout and drawing to a `Layout` object (`ScrollbarLayout`, `MenubarLayout`); implemented naively this doubles the UI object count, so Layouts are flyweights — they are mostly behavior and need little extrinsic state. `Look` is an Abstract Factory (`MotifLook`, `OpenLook`) retrieving them via `GetButtonLayout`, `GetMenuBarLayout`. These Layout objects are essentially **strategies implemented as flyweights**.

## Related Patterns
- **Composite**: Flyweight is often combined with Composite to implement a logically hierarchical structure as a **directed acyclic graph with shared leaf nodes**. The price: a shared leaf cannot store a parent pointer — the parent travels as extrinsic state. Conversely, Composite's "sharing components" issue points at Flyweight as the way to rework the design so parents needn't be stored at all.
- **State** and **Strategy**: it's often best to implement State and Strategy objects as flyweights — they are mostly behavior with little intrinsic state. ET++'s Layout is exactly this.
- **Factory Method / Abstract Factory / Singleton**: the FlyweightFactory is typically a singleton factory; ET++'s `Look` is an Abstract Factory dispensing flyweights.

## Key Takeaways
1. The whole pattern is one distinction: intrinsic state stays in the object and is shared; extrinsic state moves to the client and is passed in.
2. Check all five applicability conditions — especially that the design doesn't depend on object identity — before sharing anything.
3. Always create flyweights through a FlyweightFactory, including kinds you don't currently share, so sharing can be introduced later without changing clients.
4. Biggest wins come when extrinsic state can be *computed* from a compact separate structure (a run map, a BTree) rather than stored per occurrence.
