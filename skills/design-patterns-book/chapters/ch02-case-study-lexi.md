# Chapter 2: A Case Study — Designing a Document Editor

## Core Idea
Design **Lexi**, a WYSIWYG document editor, by working seven concrete design problems.
Each problem is solved by the same move — *encapsulate the concept that varies* — and each
solution turns out to be a named pattern. Eight patterns fall out of one coherent design,
which is the point: patterns compose.

## Frameworks Introduced

**Recursive composition** — build complex elements from simpler ones: characters and
graphics tile into a Row, Rows stack into a Column, Columns into a page. Give *every*
element an object, including the invisible structural ones (Row, Column). Use when the
information is hierarchical and clients must treat leaves and composites uniformly.
Requires a common abstract base so the interfaces are compatible → **Glyph**.

**Transparent enclosure** — combine (1) single-child composition with (2) an interface
identical to the child's. Clients can't tell whether they hold the component or its
enclosure; the enclosure delegates everything, but may do work *before and/or after*
delegating, and may add state. Use for embellishments (border, scroller) so the rest of
the app never learns they exist. Keep enclosure separate from general composition — a
border wraps exactly one thing.

**Abstracting object creation** — replace `new ConcreteThing` with
`factory->CreateThing()`. Use whenever a whole *family* of related products (a widget
set) must be swapped together, and the specific family isn't known until run-time.

**Splitting an abstraction from its implementation** (Window / WindowImp) — use when you
cannot own both hierarchies: the abstraction's interface serves the application
programmer, the implementor's interface serves the platform, "warts and all". Neither
"intersection of functionality" (as weak as the poorest window system) nor "union of
functionality" (huge, unstable) is acceptable; land in between.

## Key Concepts
- **Glyph**: abstract class for everything that can appear in a document. Three
  responsibilities — know how to draw itself, what space it occupies, and its children
  and parent.
- **Composition / Compositor**: a Composition is a Glyph whose children are formatted by
  a Compositor; the Compositor iterates the children and *inserts* Row and Column glyphs
  per its linebreaking algorithm. `SetCompositor` swaps the algorithm at run-time.
- **MonoGlyph**: abstract base for embellishment glyphs; stores one component and
  forwards all requests to it. `Border`, `Scroller` are subclasses.
- **GUIFactory / widget glyphs**: `GUIFactory` declares `CreateScrollBar`,
  `CreateButton`, …; `MotifFactory`/`PMFactory` return `MotifScrollBar`, `PMButton`, etc.
  Products of one factory belong to one look-and-feel family.
- **Window / WindowImp**: Window is the application-facing abstraction (draw shapes,
  iconify, resize, redraw); WindowImp hides window-system-dependent code. Window holds
  `_imp`, initialized from a `WindowSystemFactory`.
- **Command / command history**: a Command object encapsulates a request behind
  `Execute`; `Unexecute` reverses it; `Reversible` reports at run-time whether undo is
  meaningful. The command history is a list with a "present" line that moves left on
  undo, right on redo — unlimited levels.
- **Iterator**: `First`, `Next`, `IsDone`, `CurrentItem`. `Glyph::CreateIterator` returns
  the right subclass (`ArrayIterator`, `ListIterator`, or `NullIterator` for leaves);
  `PreorderIterator` composes glyph-specific iterators on a stack.
- **Visitor / Accept**: `Glyph::Accept(Visitor&)` calls back `VisitCharacter`,
  `VisitRow`, … The double dispatch identifies the concrete glyph without type tests.
- **Discretionary**: a Glyph inserted by `HyphenationVisitor` at a hyphenation point;
  draws as a hyphen only when it is its Row's last child, otherwise draws nothing.

## Mental Models
- Use **Composite** when clients must not care whether an element is a single character
  or an intricate diagram — as long as it can draw itself and state its dimensions.
- Use **Strategy** when the trade-off itself is the variable: `SimpleCompositor` is a
  fast pass; `TeXCompositor` runs the full TeX algorithm and buys better "color" (even
  distribution of text and whitespace) with time.
- Think of **Decorator** as skin you can layer in either order: compose Composition in
  Scroller then in Border, or the reverse and the border scrolls with the text.
- Use **Abstract Factory** when you own the abstract product classes; use **Bridge** when
  you don't — vendor widget hierarchies won't share a `ScrollBar` base, so there is
  nothing for the `Create…` operations to return.
- Parameterize with an *object*, not a function pointer: a function can't hold state
  (which font?), can't be extended, and offers no place to put undo.
- Apply **Visitor** when the element hierarchy is stable and the set of operations is
  open-ended. Ask "which hierarchy changes more often?" Lexi gains new analyses far more
  often than new Glyph subclasses — so Visitor wins here.

## Anti-patterns
- **Subclass-per-embellishment**: `BorderedComposition`, `ScrollableComposition`,
  `BorderedScrollableComposition`… one class per combination. Unworkable, and inheritance
  precludes rearranging embellishments at run-time.
- **Constructor calls to look-and-feel classes scattered through the code**: a
  maintenance nightmare — miss one and you get a Motif menu in a Mac application.
- **A `Window` class per platform, or implementation-specific subclasses of every Window
  subclass**: subclass explosion again, plus you can't change window system after compile.
- **A MenuItem subclass per user operation**: couples the request to one user interface;
  the class count approaches (widget types × requests).
- **An integer index in the Glyph interface**: biases the abstraction toward arrays and
  leaks the child data structure. Replaced by `CreateIterator`.
- **Traversal enum baked into Glyph** (`CHILDREN`, `PREORDER`, `POSTORDER`, `INORDER`):
  a new traversal means editing declarations everywhere, no reuse on other structures,
  and only one traversal in progress at a time.
- **Type tests / downcasts in the analyzer**: `if (dynamic_cast<Character*>(g)) … else
  if (dynamic_cast<Row*>(g)) …` — exactly what OO languages were meant to eliminate, and
  it must be edited whenever the Glyph hierarchy changes.
- **Adding an analytical operation to Glyph per analysis**: Glyph's interface swells until
  its real purpose — appearance and structure — is lost in the noise.

## Code Examples

```cpp
class Glyph {
public:
    virtual ~Glyph();

    virtual void Draw(Window*);
    virtual void Bounds(Rect&);

    virtual bool Intersects(const Point&);

    virtual void Insert(Glyph*, int);
    virtual void Remove(Glyph*);
    virtual Glyph* Child(int);
    virtual Glyph* Parent();

protected:
    Glyph();
};
```
**What it demonstrates**: the basic glyph interface — draw, extent, hit detection, and
uniform child/parent access. Child access goes through `Child()` so changing an array to
a linked list doesn't break `Draw`.

```cpp
void Rectangle::Draw (Window* w) {
    w->DrawRect(_x0, _y0, _x1, _y1);
}

// MonoGlyph is transparent by default...
void MonoGlyph::Draw (Window* w) {
    _component->Draw(w);
}

// ...and Border EXTENDS rather than REPLACES the parent operation.
void Border::Draw (Window* w) {
    MonoGlyph::Draw(w);
    DrawBorder(w);
}
```
**What it demonstrates**: transparent enclosure. Calling the parent operation first is
what makes it a decoration rather than a replacement.

```cpp
// Bridge: Window forwards to its implementor, chosen at run-time.
void Window::DrawRect (Coord x0, Coord y0, Coord x1, Coord y1) {
    _imp->DeviceRect(x0, y0, x1, y1);
}

Window::Window () {
    _imp = windowSystemFactory->CreateWindowImp();
}
```
**What it demonstrates**: `XWindowImp::DeviceRect` computes lower-left corner, width and
height for `XDrawRectangle`; `PMWindowImp::DeviceRect` builds a *path* of vertices
because PM has no rectangle primitive. Window never learns the difference.

```cpp
// Iterator replaces indexed child access.
Glyph* g;
Iterator<Glyph*>* i = g->CreateIterator();

for (i->First(); !i->IsDone(); i->Next()) {
    Glyph* child = i->CurrentItem();
    // do something with child
}

Iterator<Glyph*>* Row::CreateIterator () {
    return new ListIterator<Glyph*>(_children);
}
```
**What it demonstrates**: traversal without knowing the representation; a leaf returns a
`NullIterator` whose `IsDone` is always true.

```cpp
// Visitor: double dispatch, no type tests.
void Character::Accept (Visitor& v) { v.VisitCharacter(this); }

void SpellingCheckingVisitor::VisitCharacter (Character* c) {
    char ch = c->GetCharCode();          // subclass-specific op, safely reached
    if (isalpha(ch)) {
        _currentWord += ch;
    } else if (_currentWord.length() > 0) {
        if (IsMisspelled(_currentWord)) _misspellings.Append(_currentWord);
        _currentWord = "";
    }
}
```
**What it demonstrates**: because `Accept` runs *inside* the concrete Glyph subclass, the
subclass is already known; the visitor can call `GetCharCode` — defined only on
`Character` — with no cast.

## Reference Table: problem → pattern

| # | Design problem | Key classes in Lexi | Pattern |
|---|---|---|---|
| 1 | Document structure | Glyph, Character, Row, Column | **Composite** |
| 2 | Formatting (linebreaking) | Composition, Compositor, SimpleCompositor, TeXCompositor | **Strategy** |
| 3 | Embellishing the user interface | MonoGlyph, Border, Scroller | **Decorator** |
| 4 | Multiple look-and-feel standards | GUIFactory, MotifFactory, PMFactory + product classes | **Abstract Factory** (with **Factory Method** for the `Create…` operations; `guiFactory` is often a **Singleton**) |
| 5 | Multiple window systems | Window, WindowImp, XWindowImp, PMWindowImp, WindowSystemFactory | **Bridge** |
| 6 | User operations, undo/redo | MenuItem, Command, PasteCommand, FontCommand, command history | **Command** |
| 7 | Spelling checking and hyphenation | Iterator, PreorderIterator; Visitor, SpellingCheckingVisitor, HyphenationVisitor, Discretionary | **Iterator** + **Visitor** |

## Worked Example: the Lexi walkthrough
1. **Represent the document.** Every character, image, Row and Column is a Glyph. Text
   and graphics are treated uniformly; a diagram is manipulable as a unit. → Composite.
2. **Format it.** A `Composition` is created holding only visible content glyphs. When it
   needs formatting it calls `_compositor->Compose()`; the compositor walks the children
   and *inserts* Row/Column glyphs per its algorithm. Adding `TeXCompositor` touches no
   glyph class; adding a Glyph subclass touches no compositor. → Strategy.
3. **Embellish it.** Wrap the Composition in a `Scroller`, wrap that in a `Border`. Both
   are MonoGlyphs, so clients keep calling `Draw` on a Glyph. Reversing the nesting makes
   the border scroll with the text — a one-line experiment. → Decorator.
4. **Port the look and feel.** Never `new MotifScrollBar`; always
   `guiFactory->CreateScrollBar()`. `guiFactory` is initialized once, after the desired
   look and feel is known and before any widget is created — optionally via a registry
   mapping strings to factories, so new factories link in without editing existing code.
   → Abstract Factory.
5. **Port the window system.** Vendor hierarchies aren't compatible, so Abstract Factory
   alone can't work at the product level. Split into Window (application view) and
   WindowImp (platform view); `Window::_imp` comes from a `WindowSystemFactory`. Each
   hierarchy evolves independently. → Bridge (configured by an Abstract Factory).
6. **Make operations uniform and undoable.** `MenuItem` holds a `Command` and calls
   `Execute`; buttons and page icons hold the same commands. `Unexecute` reverses,
   `Reversible` suppresses no-op undos (a spurious font change shouldn't cost an undo).
   The command history plus a "present" marker gives unlimited undo/redo. → Command.
7. **Analyze the text.** Traversal is encapsulated in Iterator (so the glyph interface
   sheds its integer index and multiple traversals can run at once); the *action* is
   encapsulated in Visitor (so new analyses — search, word count, grammar checking — add
   a subclass instead of touching Glyph). `HyphenationVisitor` inserts `Discretionary`
   glyphs at hyphenation points, which the formatting strategy treats like whitespace.
   → Iterator + Visitor.

## Key Takeaways
1. The recurring move is one sentence: **encapsulate the concept that varies** — the
   algorithm (Strategy), the embellishment (Decorator), the platform (Bridge/Abstract
   Factory), the request (Command), the traversal (Iterator), the analysis (Visitor).
2. Choose Composite when clients must treat leaves and composites uniformly; give even
   invisible structure (Row, Column) real objects.
3. Decorator requires the enclosure's interface to *match* the component's, and the
   subclass must call the parent operation to extend rather than replace it.
4. Abstract Factory needs abstract product classes you control; without them, reach for
   Bridge instead.
5. Parameterize with objects, not functions — that's where state, extension, and undo
   live.
6. Separate traversal from the action performed during traversal: one set of iterators
   then serves every analysis.
7. Before applying Visitor, ask which hierarchy changes more often. Visitor is cheap on
   new operations and expensive on new element classes.
8. None of this is document-editor-specific: Composite for investment portfolios,
   Strategy for a compiler's register allocation schemes, Decorator and Command in any
   GUI application.

## Connects To
- **Ch 1** — the principles this chapter exercises: program to an interface, favor
  composition over inheritance, encapsulate what varies.
- **Ch 3 (Creational)** — Abstract Factory, Factory Method, Singleton, Flyweight's
  relevance to sharing glyphs.
- **Ch 4 (Structural)** — Composite, Decorator, Bridge, Flyweight.
- **Ch 5 (Behavioral)** — Strategy, Command, Iterator, Visitor.
