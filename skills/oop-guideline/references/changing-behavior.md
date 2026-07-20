# Changing Behavior — Full Reference

Read this when the task is "make this configurable", "add logging / caching /
retries to this service", "we need a second variant of this", or any time
subclassing is on the table.

The governing idea: **replace parts, don't change them.** Modify the structure
of the object graph rather than the code inside a class. Changing code risks
breaking it; swapping a dependency doesn't.

## Contents

1. [The Escalation Ladder](#1-the-escalation-ladder)
2. [Rung 1 — Configurable Value](#2-rung-1--configurable-value)
3. [Rung 2 — Replaceable Dependency](#3-rung-2--replaceable-dependency)
4. [Rung 3 — Composition](#4-rung-3--composition)
5. [Rung 4 — Decoration](#5-rung-4--decoration)
6. [Rung 5 — Notification Objects and Event Listeners](#6-rung-5--notification-objects-and-event-listeners)
7. [Why Inheritance Isn't on the Ladder](#7-why-inheritance-isnt-on-the-ladder)
8. [Template Method → Composition](#8-template-method--composition)
9. [final and private by Default](#9-final-and-private-by-default)
10. [Traits for Entities and Value Objects](#10-traits-for-entities-and-value-objects)

---

## 1. The Escalation Ladder

Try these in order and stop at the first rung that solves the problem:

| Want to change…                                | Use                              |
|------------------------------------------------|----------------------------------|
| A value                                        | Constructor argument             |
| A chunk of logic                               | Injected abstraction             |
| Behavior combining several implementations     | Composition                      |
| Behavior layered on any implementation         | Decoration                       |
| Behavior in *other* services                   | Event listener / notification    |
| **Behavior by overriding a method**            | **Nothing — don't**              |

Climbing in order matters because each rung costs more structure than the last.
Reaching for a decorator when a constructor argument would do is the same
mistake as reaching for inheritance, just less damaging.

## 2. Rung 1 — Configurable Value

Promote a hardcoded value to a constructor argument:
`new FileLogger('/var/log/app.log')`.

Two things to avoid here:

- **Injecting a generic `Config` object** to make one base URL configurable.
  Inject the specific value.
- **Passing configuration as a method argument.** That forces every client to
  know and supply a value they shouldn't care about. Configuration is
  constructor data; task data is method data.

## 3. Rung 2 — Replaceable Dependency

Extract an abstraction for the varying part and inject it. Remember the
abstraction is two things — an interface *and* a name free of implementation
details.

```
// Before — JSON decoding is welded into ParameterLoader
class ParameterLoader {
  load(filePath) {
    const raw = jsonDecode(readFile(filePath))
    ...
  }
}

// After — "loading a file" is the abstract concept behind "decoding a JSON file"
interface FileLoader {
  loadFile(filePath: string): array     // throws CouldNotLoadFile
}

class JsonFileLoader implements FileLoader {
  loadFile(filePath: string): array {
    assertIsFile(filePath)
    const result = jsonDecode(readFile(filePath))
    if (!isArray(result)) throw new RuntimeException(`Decoding "${filePath}" did not produce an array`)
    return result
  }
}

class ParameterLoader {
  constructor(private fileLoader: FileLoader) {}
  load(filePath) { const raw = this.fileLoader.loadFile(filePath); ... }
}

new ParameterLoader(new JsonFileLoader())
new ParameterLoader(new XmlFileLoader())     // swap without touching ParameterLoader
```

Worth noticing: **extracting the interface was also the moment proper pre- and
postcondition checks became possible.** The abstraction gave the JSON-specific
behavior somewhere to live, and that somewhere had a natural place for its own
guards.

## 4. Rung 3 — Composition

An object built from other objects satisfying the same interface. Use it to
build richer behavior out of several implementations:

```
class MultipleLoaders implements FileLoader {
  constructor(private loaders: Map<string, FileLoader>) {
    assertAllInstanceOf(loaders.values(), FileLoader)
  }
  loadFile(filePath: string): array {
    const extension = extensionOf(filePath)
    const loader = this.loaders.get(extension)
    if (!loader) throw new CouldNotLoadFile(`No loader for extension "${extension}"`)
    return loader.loadFile(filePath)
  }
}
```

**Abstraction is smart; generalization before it's needed is not.** Introducing
`FileLoader` at the first implementation is right. Writing JSON, XML *and* YAML
loaders before anyone asks is generalization before it's needed — introduce the
abstraction early, add implementations on demand.

## 5. Rung 4 — Decoration

A class implementing the same interface it wraps, adding behavior before or
after delegating. Use it for cross-cutting concerns: caching, logging, retries,
value substitution.

```
class CachedFileLoader implements FileLoader {
  private cache = new Map()
  constructor(private realLoader: FileLoader) {}
  loadFile(filePath: string): array {
    if (this.cache.has(filePath)) return this.cache.get(filePath)
    const result = this.realLoader.loadFile(filePath)
    this.cache.set(filePath, result)
    return result
  }
}

// The whole graph, assembled at the composition root
const parameterLoader = new ParameterLoader(
  new ReplaceParametersWithEnvironmentVariables(
    new MultipleLoaders({ json: new JsonFileLoader(), xml: new XmlFileLoader() }),
    { APP_ENV: 'dev' }
  )
)
```

`ParameterLoader` has no idea any of this is happening. Every layer is
independently testable and independently changeable, and the cross-cutting logic
isn't duplicated across implementations or coupled to any particular one.

**You can only decorate at an interface boundary.** This is the constraint that
bites in practice. To move logging out of a per-line loop, you must first
*extract* a `LineImporter` object — there's nothing to wrap otherwise:

```
interface LineImporter { import(lineNumber: int, line: string): void }

class LoggingLineImporter implements LineImporter {
  constructor(private actual: LineImporter, private logger: Logger) {}
  import(lineNumber, line) {
    this.logger.log(`Importing line: ${lineNumber}`)
    this.actual.import(lineNumber, line)
    this.logger.log(`Imported line: ${lineNumber}`)
  }
}

const importer = new LoggingFileImporter(
  new CsvFileImporter(new LoggingLineImporter(new DefaultLineImporter(), logger)),
  logger
)
```

**Noback's own caveat, worth repeating to anyone considering this**: that's a lot
of code to delete a few log statements. When hooking before and after existing
calls is the *only* goal, aspect-oriented tooling is the pragmatic alternative.
He doesn't pretend composition is free.

## 6. Rung 5 — Notification Objects and Event Listeners

Use these to add behavior to *other* services without modifying the original.
Two shapes, with a real trade-off between them:

| Mechanism                       | Cost                                                                 |
|---------------------------------|----------------------------------------------------------------------|
| Generic `EventDispatcher`       | Anyone can add a listener later without touching the service — but `dispatch()` is an opaque name and listeners are hard to trace |
| Named notification interface    | Explicit and greppable — but adding a notification means changing the interface |

The named version replaces the dispatcher with your own domain-language
interface — `ImportNotifications` with `whenHeaderImported()`,
`whenLineImported()`, `whenFileImported()` — and eliminates the event classes,
listener classes, and registration wiring entirely. It's the better choice when
every event has essentially one listener doing the same kind of work.

Either way, **dispatch explicitly**, so the effect stays discoverable.

**Events notify others so they can act. They are not a mechanism for changing
the dispatching service's own behavior.** If you find yourself dispatching an
event so a listener can alter what the service does next, you wanted rung 2.

## 7. Why Inheritance Isn't on the Ladder

**Inheritance ties the subclass to the parent's internals.** Renaming a
`protected` method, or adding a required parameter to it, silently breaks every
subclass — including ones in other people's code that you'll never see fail.

**Third-party extension points are a trap.** Many frameworks explicitly invite
you to extend their base classes. Refrain. Use only `public` methods that are
part of the published API — class internals are far more likely to change
between versions than the supported surface.

| Reuse mechanism | Enters the type hierarchy? | Use for                          |
|-----------------|----------------------------|-----------------------------------|
| Composition     | N/A                        | Services — the default            |
| Trait           | **No** (compiler copy/paste)| Entities/value objects (no DI)   |
| Inheritance     | Yes                        | Genuine type hierarchies only     |

A "genuine type hierarchy" means the subclass is a *special case* of the parent —
`Paragraph extends ContentBlock`. That's a statement about what things *are*, not
a technique for varying behavior.

## 8. Template Method → Composition

Template method is better than raw subclassing — internals stay private and only
one hook is exposed — but it's strictly weaker than composition. Everything it
does, composition does, plus composability and decoration.

The conversion is one mechanical step: **promote the `abstract protected` method
to a regular `public` method on an injected object, then mark the class `final`
again.**

```
// State 1 — subclassing. The subclass depends on the parent's protected internals.
class ParameterLoader {
  protected loadFile(filePath): array { return jsonDecode(...) }
}
class XmlFileParameterLoader extends ParameterLoader {
  protected loadFile(filePath): array { /* XML */ }
}

// State 2 — template method. Better, but still inheritance.
abstract class ParameterLoader {
  final load(filePath): array { ... this.loadFile(filePath) ... }
  protected abstract loadFile(filePath): array
}

// State 3 — composition. The hook became a collaborator.
final class ParameterLoader {
  constructor(private fileLoader: FileLoader) {}
  load(filePath): array { ... this.fileLoader.loadFile(filePath) ... }
}
```

## 9. `final` and `private` by Default

Mark **every class `final`** — services, entities, value objects alike — and
**every property and method `private`** unless it's part of the published
interface.

The one exception is the genuine type hierarchy described above.

A consequence people miss: **once classes are `final`, `protected` has no
purpose left.** A `protected` property on a class nobody extends exposes
internals for no benefit whatsoever.

The reason to default this way rather than the other way round is asymmetry of
regret. Making something extensible later is easy and safe. Discovering that
three subclasses depend on an internal you needed to change is neither.

In languages without `final` (Python, JavaScript), the intent still carries:
prefix internals conventionally, don't document extension points you don't
intend to support, and treat "someone subclassed this" as a design problem
rather than a compliment.

## 10. Traits for Entities and Value Objects

Entities and value objects can't use dependency injection — they hold values,
not collaborators — so composition isn't available for sharing implementation
between them. Traits (or mixins) fill that gap:

```
interface RecordsEvents { recordedEvents(): array; clearEvents(): void }
trait EventRecordingCapabilities { /* the shared implementation */ }
```

The point is that a **trait is compiler-level copy/paste**. The trait's name
never enters the type hierarchy, so none of the coupling problems in section 7
apply. That's precisely why it's acceptable here and inheritance isn't.
