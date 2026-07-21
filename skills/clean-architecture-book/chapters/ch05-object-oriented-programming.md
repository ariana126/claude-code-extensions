# Chapter 5: Object-Oriented Programming

## Core Idea
OO is not encapsulation, inheritance, and polymorphism as a feature bundle — C had all three, and better encapsulation than C++. To the architect, **OO is the ability, through the use of polymorphism, to gain absolute control over every source code dependency in the system**, which is what makes a plugin architecture possible anywhere, for anything.

## Frameworks Introduced
- **The Architect's Definition of OO**
  - When to use: whenever you must justify a boundary, a plugin seam, or an interface that seems to add indirection for no local benefit.
  - How: identify a source code dependency that runs the wrong way; insert an interface between the two modules; make the low-level module inherit from (implement) the interface owned by the high-level side. The runtime flow of control still goes high-level → low-level, but the source code dependency now points against it.
  - Why it works / failure mode: at runtime the interface doesn't exist — HL1 simply calls `F()` within ML1. The interface is "a source code contrivance," which is exactly why it costs nothing at runtime and buys everything at compile/deploy time. Failure mode: doing this with raw function pointers instead of language-level polymorphism reintroduces the danger the discipline was meant to remove.
- **Dependency Inversion**
  - When to use: any time source code dependencies inexorably follow the flow of control (main → high-level → mid-level → low-level, each caller forced to `#include` / `import` / `using` the callee's module).
  - How: recognize that "any source code dependency, no matter where it is, can be inverted." Systematically point dependencies so that the database and the UI depend on the business rules, not the reverse. The source of the business rules then never mentions the UI or the database.
  - Why it works / failure mode: it yields three separate deployment units (jar files, DLLs, Gem files) with the same dependencies as the source, so the business-rules component doesn't depend on the UI or database components. Failure mode: leaving one stray `import` from policy to detail collapses the whole separation — the dependency graph is only as inverted as its worst edge.
- **Plugin Architecture**
  - When to use: whenever a category of detail (device, UI, database) may be swapped or added later.
  - How: define a fixed set of operations the detail must supply (UNIX requires every IO device driver to provide five standard functions — `open`, `close`, `read`, `write`, `seek` — with signatures identical for every driver), then depend only on that. New devices require no changes to the calling program and no recompilation.

## Key Concepts
- **Indirect transfer of control**: dispatch through pointers to functions; OO imposes discipline on it.
- **Encapsulation (no point awarded)**: C had *perfect* encapsulation via forward-declared structs in headers; C++ broke it because the compiler needs the size of each class instance, forcing member variables into the header — `public`/`private`/`protected` are a *hack* repairing that. Java and C# abolished the header/implementation split, weakening it further.
- **Inheritance (half a point)**: the redeclaration of a group of variables and functions within an enclosing scope — achievable in C by ordering a superset struct's first fields identically, which is how C++ implements single inheritance.
- **Polymorphism (no new capability, but made safe)**: an application of pointers to functions, used since Von Neumann architectures were first implemented in the late 1940s; OO's contribution is eliminating the manual conventions and therefore the danger.
- **vtable**: the table holding a pointer for every virtual function in a C++ class; derived constructors load their versions into the vtable of the object being created.
- **Device independence**: the 1950s lesson — programs should work interchangeably with cards or tape — that motivated plugins.
- **Independent deployability**: when source in a component changes, only that component needs redeployment.
- **Independent developability**: modules deployable independently can be developed independently by different teams.

## Mental Models
- Think of `o.f()` versus `f(o)` as identical; any definition of OO that rests on that distinction is absurd — programmers passed data structures into functions long before 1966.
- Use the flow-of-control/dependency split as your diagnostic: draw the calling tree, then draw the source dependencies. Every place they coincide is a place you have no architectural freedom.
- Think of the UI and the database as *plugins to the business rules* — details relegated to modules that can be deployed and developed independently of high-level policy.
- Score the three "magic words" honestly: no point for encapsulation, half a point for inheritance, and for polymorphism a change in *safety and convenience* rather than capability. That's what's left, and it's enough.

## Anti-patterns
- **"OO is the combination of data and function"**: implies `o.f()` differs from `f(o)`; it doesn't.
- **"OO is a way to model the real world"**: evasive at best — it never says what OO *is*.
- **Hand-rolled function pointers for polymorphism**: dangerous, driven by manual conventions — you must remember to initialize the pointers and to call through them; forget once and the bug is devilishly hard to track down. This is exactly why most programmers never extended the plugin idea to their own programs.
- **Letting source dependencies follow flow of control**: leaves the architect with few, if any, options; the behavior of the system then dictates your structure.
- **Casting up manually across a fake hierarchy**: in `main.c` the `NamedPoint` arguments must be explicitly cast to `Point`; in a real OO language such upcasting would be implicit — the manual version is the trick, not the discipline.

## Code Examples

Perfect encapsulation in C — clients of `point.h` have no access whatsoever to the members of `struct Point`:

```c
// point.h
struct Point;
struct Point* makePoint(double x, double y);
double distance (struct Point *p1, struct Point *p2);
```

```c
// point.c
#include "point.h"
#include <stdlib.h>
#include <math.h>

struct Point {
  double x,y;
};

struct Point* makepoint(double x, double y) {
  struct Point* p = malloc(sizeof(struct Point));
  p->x = x;
  p->y = y;
  return p;
}

double distance(struct Point* p1, struct Point* p2) {
  double dx = p1->x - p2->x;
  double dy = p1->y - p2->y;
  return sqrt(dx*dx+dy*dy);
}
```

Inheritance by struct-layout trickery — `NamedPoint` is a pure superset of `Point` and preserves the ordering of the corresponding members, so it can masquerade as `Point`:

```c
// namedPoint.h
struct NamedPoint;

struct NamedPoint* makeNamedPoint(double x, double y, char* name);
void setName(struct NamedPoint* np, char* name);
char* getName(struct NamedPoint* np);
```

```c
// namedPoint.c
#include "namedPoint.h"
#include <stdlib.h>

struct NamedPoint {
  double x,y;
  char* name;
};

struct NamedPoint* makeNamedPoint(double x, double y, char* name) {
  struct NamedPoint* p = malloc(sizeof(struct NamedPoint));
  p->x = x;
  p->y = y;
  p->name = name;
  return p;
}

void setName(struct NamedPoint* np, char* name) {
  np->name = name;
}

char* getName(struct NamedPoint* np) {
  return np->name;
}
```

```c
// main.c
#include "point.h"
#include "namedPoint.h"
#include <stdio.h>

int main(int ac, char** av) {
  struct NamedPoint* origin = makeNamedPoint(0.0, 0.0, "origin");
  struct NamedPoint* upperRight = makeNamedPoint (1.0, 1.0, "upperRight");
  printf("distance=%f\n",
    distance(
             (struct Point*) origin,
             (struct Point*) upperRight));
}
```

Polymorphism before OO — the `copy` program plus the `FILE` table of function pointers that dispatches it:

```c
#include <stdio.h>

void copy() {
  int c;
  while ((c=getchar()) != EOF)
    putchar(c);
}
```

```c
struct FILE {
  void (*open)(char* name, int mode);
  void (*close)();
  int (*read)();
  void (*write)(char);
  void (*seek)(long index, int mode);
};
```

```c
#include "file.h"

void open(char* name, int mode) {/*...*/}
void close() {/*...*/};
int read() {int c;/*...*/ return c;}
void write(char c) {/*...*/}
void seek(long index, int mode) {/*...*/}

struct FILE console = {open, close, read, write, seek};
```

```c
extern struct FILE* STDIN;

int getchar() {
  return STDIN->read();
}
```

- **What it demonstrates**: encapsulation, inheritance, and polymorphism all predate OO languages; `getchar()` simply calls the function pointed to by the `read` pointer of the `FILE` structure pointed to by `STDIN` — the simple trick that is the basis for all polymorphism in OO, including the C++ vtable.

## Reference Tables

| "Magic word" | Score for OO | Why |
|---|---|---|
| Encapsulation | no point | C had perfect encapsulation; C++ broke it, Java/C# weakened it further |
| Inheritance | half a point | achievable by struct-ordering trickery; OO made masquerading significantly more convenient (and multiple inheritance far harder without it) |
| Polymorphism | nothing new, but decisive | pointers to functions since the late 1940s; OO made it *safe* and *convenient*, which is what unlocks plugins everywhere |

## Worked Example
The `copy` program. It reads with `getchar()` and writes with `putchar()` — but which device is `STDIN`? Which is `STDOUT`? The functions are polymorphic: their behavior depends on the type of `STDIN` and `STDOUT`, as though those were Java-style interfaces with an implementation per device. There are no interfaces in the C program, so the mechanism is UNIX's requirement that every IO driver supply the same five functions and a `FILE` struct holding five function pointers. The console driver defines the five and loads their addresses into a `FILE`; `STDIN` points at it; `getchar()` calls through `STDIN->read()`.

Now add a new device — copy from a handwriting recognition device to a speech synthesizer. How much of `copy` changes? Nothing at all, and it doesn't even need recompiling, because the source code of `copy` does not depend on the source code of the IO drivers. The IO devices have become plugins. That was invented for device independence after the industry wrote card-reading programs and then got handed reels of magnetic tape. The generalization is the whole chapter: OO makes this pattern safe enough to use anywhere — put the database and the UI on the plugin side of the business rules, and policy stops depending on detail.

## Key Takeaways
1. Define OO as absolute control over source code dependencies via polymorphism — not as encapsulation + inheritance + polymorphism.
2. Any source code dependency, anywhere, can be inverted by inserting an interface. That freedom is the architect's core power.
3. Separate flow of control from source dependency deliberately; never let the calling direction dictate the compile-time direction.
4. Make details — UI, database, devices — plugins to high-level policy, so policy never mentions them.
5. Independent deployability follows from inverted dependencies, and independent developability follows from independent deployability.
6. Language-level polymorphism matters because it removes the manual conventions that made function-pointer polymorphism too dangerous to use widely.

## Connects To
- **Ch 3**: "Object-oriented programming imposes discipline on indirect transfer of control" — proved here.
- **Ch 11 (DIP)**: the principle-level statement of the inversion demonstrated in this chapter.
- **Ch 22 (The Clean Architecture) / Ch 17 (Boundaries)**: polymorphism is the mechanism used to cross architectural boundaries.
- **Ch 4**: structured programming disciplines direct transfer of control; this is its counterpart.
- **Hexagonal Architecture (Ports and Adapters)**: the same plugin-to-policy topology under different names.
- **Strategy / Template Method patterns**: the small-scale form of the interface-insertion move.
