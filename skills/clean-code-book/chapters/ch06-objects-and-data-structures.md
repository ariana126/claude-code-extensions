# Chapter 6: Objects and Data Structures

## Core Idea
Objects hide their data behind abstractions and expose functions that operate on that data; data structures expose their data and have no meaningful functions. These are virtual opposites, and choosing the wrong one — or blending them — is what makes designs rigid.

## Frameworks Introduced

- **Data/Object Anti-Symmetry**: "Procedural code (code using data structures) makes it easy to add new functions without changing the existing data structures. OO code, on the other hand, makes it easy to add new classes without changing existing functions." The complement is also true: procedural code makes it hard to add new data structures; OO code makes it hard to add new functions.
  - When to use: Whenever you are deciding between a polymorphic class hierarchy and a set of plain records plus procedures. Ask which axis will grow — new *types* or new *operations*.
  - How:
    1. List the axes of expected change: will you add shapes, or add operations on shapes?
    2. If new **types** dominate → objects, polymorphism, hidden data.
    3. If new **functions/operations** dominate → data structures with public fields plus procedural modules operating on them.
    4. Do not force one style everywhere. Different subsystems legitimately choose differently.
    5. Never mix the two in one class (see Hybrids).
  - Why it works / failure mode: Each style makes one axis of change free and the other expensive; picking the axis you will actually travel makes change cheap. Failure mode: the myth that "everything is an object" — mature programmers know sometimes you really do want simple data structures with procedures operating on them. (Visitor / dual-dispatch works around the OO side, but carries costs and generally returns the structure to that of a procedural program.)

- **The Law of Demeter**: A module should not know about the innards of the objects it manipulates. Precisely: a method `f` of a class `C` should only call the methods of:
  - `C`
  - an object created by `f`
  - an object passed as an argument to `f`
  - an object held in an instance variable of `C`
  - When to use: Reviewing any chained call expression on objects (not data structures).
  - How: The method should **not** invoke methods on objects returned by any of the allowed functions. "Talk to friends, not to strangers." When you find a chain, ask *why* you wanted the inner value, then push that intent into a method on the outermost object.
  - Why it works / failure mode: Chains encode knowledge of a navigation path; every intermediate type becomes a dependency that can break you. Failure mode / important caveat: Demeter applies **only to objects**. If `ctxt`, `Options`, and `ScratchDir` are just data structures with no behavior, they naturally expose their internal structure and Demeter does not apply. Accessor functions (bean conventions) confuse the issue by making data structures *look* like objects.

- **Data Abstraction**: Hiding implementation is not putting a layer of functions between the variables — it is about abstractions. A class exposes abstract interfaces that let users manipulate the *essence* of the data without knowing its implementation.
  - When to use: Every time you're about to reflexively add getters and setters.
  - How: Ask what operation the client actually needs (percent fuel remaining), not what fields you happen to store (tank capacity in gallons + gallons of gasoline). Prefer interfaces that enforce an access policy — e.g. read coordinates independently, but set them together as an atomic operation.

## Key Concepts
- **Object**: A thing that hides its data behind abstractions and exposes functions that operate on that data.
- **Data structure**: A thing that exposes its data and has no meaningful functions.
- **Train wreck**: A chain of calls like `a.getB().getC().getD()` that looks like a bunch of coupled train cars; sloppy style, generally to be avoided [G36].
- **Hybrid**: A structure half object and half data structure — significant functions *plus* public variables or public accessors/mutators; the worst of both worlds.
- **Feature Envy**: The Refactoring smell where external functions use another object's exposed variables the way a procedural program uses a data structure.
- **Data Transfer Object (DTO)**: The quintessential data structure — a class with public variables and no functions; useful for database communication and socket message parsing.
- **Bean**: A DTO variant with private variables manipulated by getters and setters; the quasi-encapsulation "usually provides no other benefit."
- **Active Record**: A special DTO with public/bean-accessed variables plus navigational methods like `save` and `find`, typically a direct translation of a database table.

## Mental Models
- Think of objects and data structures as **diametrically opposed**: what is hard for OO is easy for procedures, and vice versa. Design decisions become "which direction will this grow?"
- Use **"tell, don't ask"** when the target is an object: if `ctxt` is an object, tell it to *do something*; don't ask it about its internals.
- Think of a **getter/setter pair as a public variable in disguise** — it exposes implementation even when the field is private.
- When a train wreck tempts you, ask **"what was I going to do with the value?"** — that question names the method that belongs on the outer object.

## Anti-patterns
- **Blithely adding getters and setters**: "The worst option." It exposes implementation and defeats abstraction without buying encapsulation.
- **Hybrids (half object, half data structure)**: Hard to add new functions *and* hard to add new data structures — indicative of a muddled design whose authors are unsure whether they need protection from functions or from types.
- **Business rules in Active Records**: Creates a hybrid. Treat the Active Record as a data structure and put business rules in separate objects that hide their internal data.
- **Method explosion from over-eager hiding**: `ctxt.getAbsolutePathOfScratchDirectoryOption()` — hiding structure by naming every path leads to an explosion of methods; find the real operation instead.
- **Mixing levels of detail**: dots, slashes, file extensions, and `File` objects carelessly mixed with enclosing code [G34][G6].

## Code Examples

Concrete vs. abstract representation of the same data:

```java
public class Point {
  public double x;
  public double y;
}
```

```java
public interface Point {
  double getX();
  double getY();
  void setCartesian(double x, double y);
  double getR();
  double getTheta();
  void setPolar(double r, double theta);
}
```

- **What it demonstrates**: The abstract version hides whether coordinates are rectangular or polar, and its methods enforce an access policy — read independently, set atomically.

```java
public interface Vehicle {
  double getFuelTankCapacityInGallons();
  double getGallonsOfGasoline();
}
```

```java
public interface Vehicle {
  double getPercentFuelRemaining();
}
```

- **What it demonstrates**: In the concrete case you can be sure these are just variable accessors; in the abstract case you have no clue about the form of the data.

## Reference Tables

| | Add a new **type** (shape) | Add a new **function** (perimeter) |
|---|---|---|
| **Procedural / data structures** | Hard — every function must change | Easy — no data structure changes |
| **OO / polymorphic objects** | Easy — no existing function changes | Hard — every class must change |

## Worked Example

**Geometry: procedural vs. polymorphic.**

Procedural — dumb data structures, all behavior in one class:

```java
public class Square {
  public Point topLeft;
  public double side;
}

public class Geometry {
  public final double PI = 3.141592653589793;

  public double area(Object shape) throws NoSuchShapeException
  {
    if (shape instanceof Square) {
      Square s = (Square)shape;
      return s.side * s.side;
    }
    else if (shape instanceof Rectangle) {
      Rectangle r = (Rectangle)shape;
      return r.height * r.width;
    }
    else if (shape instanceof Circle) {
      Circle c = (Circle)shape;
      return PI * c.radius * c.radius;
    }
    throw new NoSuchShapeException();
  }
}
```

Add `perimeter()` to `Geometry` and the shape classes — and everything depending on them — are unaffected. Add a new shape and every function in `Geometry` must change.

Polymorphic — no `Geometry` class needed:

```java
public class Square implements Shape {
  private Point topLeft;
  private double side;

  public double area() {
    return side*side;
  }
}
```

Add a new shape and no existing function is affected; add a new function and all the shapes must change. Diametrically opposed.

**The train wreck.** Found in the apache framework:

```java
final String outputDir = ctxt.getOptions().getScratchDir().getAbsolutePath();
```

Splitting it up is better style but does not resolve the Demeter question:

```java
Options opts = ctxt.getOptions();
File scratchDir = opts.getScratchDir();
final String outputDir = scratchDir.getAbsolutePath();
```

Whether this violates Demeter depends on whether `ctxt`, `Options`, and `ScratchDir` are objects or data structures. Now look at why the path was wanted — many lines further down:

```java
String outFile = outputDir + "/" + className.replace('.', '/') + ".class";
FileOutputStream fout = new FileOutputStream(outFile);
BufferedOutputStream bos = new BufferedOutputStream(fout);
```

The intent was to create a scratch file of a given name. So tell `ctxt` to do that:

```java
BufferedOutputStream bos = ctxt.createScratchFileStream(classFileName);
```

`ctxt` keeps its internals hidden and the caller no longer navigates objects it shouldn't know about.

## Key Takeaways
1. Decide per subsystem whether you need protection from new *functions* or new *types*, then commit to data structures or objects accordingly.
2. Do not push variables out through getters and setters — expose abstractions that express the essence of the data (percent fuel remaining, not gallons).
3. Apply the Law of Demeter to objects only; data structures with public fields legitimately expose their structure.
4. Fix a train wreck by asking what the retrieved value was for, then giving the outermost object a method that does that.
5. Never build hybrids — they are the worst of both worlds and signal muddled design.
6. Treat Active Records as data structures; put business rules in separate objects that hold them.
7. "Everything is an object" is a myth; good developers choose without prejudice.

## Connects To
- **Ch 10 (Classes)**: SRP and cohesion decide how responsibilities split once you've chosen objects; the Sql refactoring is Data/Object Anti-Symmetry applied at class scale.
- **Ch 8 (Boundaries)**: Wrapping a `Map` in a `Sensors` class is data abstraction applied to third-party interfaces.
- **Ch 17 (Smells and Heuristics)**: G36 (Avoid Transitive Navigation), G34 (Functions Should Descend Only One Level of Abstraction), G6 (Code at Wrong Level of Abstraction).
- **Visitor / dual dispatch [GOF]**: The known workaround for the OO side of the anti-symmetry, at the cost of returning to procedural structure.
- **Feature Envy [Refactoring, Fowler]**: The named smell behind hybrid structures.
