# Chapter 9: Changing the Behavior of Services

## Core Idea
**Replace parts, don't change them.** When behavior must change, modify the structure of the object graph rather than the code inside a class. There's an escalation ladder — configurable value → replaceable dependency → composition → decoration → notification — and inheritance is not on it.

## Frameworks Introduced

- **The escalation ladder for changing behavior** (try in order):
  1. **Constructor argument to make behavior configurable** — promote a hardcoded value (`'/var/log/app.log'`) to a constructor argument.
  2. **Constructor argument to make behavior replaceable** — extract an abstraction (interface + higher-level name) for the varying part, inject it.
  3. **Compose abstractions** — build more complicated behavior by wrapping several implementations (`MultipleLoaders`).
  4. **Decorate** — add behavior on top of any existing implementation (`CachedFileLoader`, `ReplaceParametersWithEnvironmentVariables`).
  5. **Notification objects / event listeners** — let other services respond without the original knowing.

- **Decoration**: A class implementing the same interface it wraps, adding behavior before/after delegating.
  - When to use: cross-cutting concerns — caching, logging, retries, value substitution.
  - Why it works: the logic isn't duplicated across implementations, is agnostic to which implementation is wrapped, and can be tested and evolved on its own.

- **Notification object as an alternative to a generic event dispatcher**: When every event has essentially one listener doing the same kind of work, replace the dispatcher with your own named interface.
  - The trade-off Noback states: an `EventDispatcher` lets you add behavior without touching the service, but `dispatch()` is a generic name — it's unclear what happens behind it and hard to find which listeners respond. A domain-named `ImportNotifications` interface with `whenHeaderImported()` / `whenLineImported()` / `whenFileImported()` methods is explicit and eliminates the event classes, listener classes, and registration wiring.

- **Everything the template method pattern does, composition does better**: The mechanical conversion is one step — **promote the `abstract protected` method to a regular `public` method on an injected object**, then mark the class `final` again.

- **`final` by default, `private` by default**: Every class — services, entities, value objects — should be `final`. Every property and method `private` unless part of the published interface.
  - The one exception: declaring a genuine hierarchy of types, where a subclass is a *special case* of the parent (`Paragraph extends ContentBlock`).
  - Consequence: once classes are `final`, `protected` has no purpose left.

## Key Concepts
- **Abstraction**: A higher-level concept plus an interface — the same two-part definition as Ch 6.
- **Concretion**: A concrete implementation of an abstraction.
- **Composition**: An object built from other objects satisfying the same interface.
- **Decoration**: Composition where the wrapper implements the same interface as what it wraps.
- **Generalization**: Making an interface more generic after several similar cases — deliberately *later* than abstraction.
- **Trait**: Compiler-level code reuse. **Not inheritance** — the trait name never enters the class hierarchy.

## Mental Models
- **Modify the object graph, not the class.** Changing code risks breaking it; swapping a dependency doesn't.
- **Abstraction is smart; generalization before it's needed is not.** Introducing `FileLoader` is right. Writing JSON, XML, *and* YAML loaders before anyone asks is "generalization before it's needed."
- **Inheritance ties subclass to parent's internals.** Renaming a `protected` method, or adding a required parameter to it, silently breaks every subclass — including ones in other people's code.
- **Third-party extension points are a trap.** Many frameworks invite you to extend their classes. Refrain. Use only `public` methods that are part of the published interface — class internals are far more likely to change than the supported API.

## Anti-patterns
- **Injecting a generic `Config` object** to make a base URL configurable: inject the specific value (Ch 2 §2.2).
- **Passing configuration as a method argument** when it belongs in the constructor: forces every client to know and supply a value they shouldn't care about.
- **Subclassing to override a `protected` method** (`XmlFileParameterLoader extends ParameterLoader`): you get none of composition's flexibility and all of inheritance's coupling.
- **The template method pattern**: better than raw subclassing, but strictly weaker than composition.
- **Using events to change a service's own behavior**: an event is a *notification* letting others take further action — not a mechanism for altering the dispatching service.
- **`protected` properties on classes nobody extends**: exposes internals for no benefit.

## Code Examples

Extracting an abstraction to make behavior replaceable:

```php
// Before — the JSON-decoding is welded into ParameterLoader
final class ParameterLoader {
    public function load(filePath): array {
        rawParameters = json_decode(file_get_contents(filePath), true);
        // ...
    }
}

// After — "loading a file" is the abstract concept behind "decoding a JSON file"
interface FileLoader {
    /** @throws CouldNotLoadFile */
    public function loadFile(string filePath): array;
}

final class JsonFileLoader implements FileLoader {
    public function loadFile(string filePath): array {
        Assertion.isFile(filePath);
        result = json_decode(file_get_contents(filePath), true);
        if (!is_array(result)) {
            throw new RuntimeException('Decoding "{filePath}" did not result in an array');
        }
        return result;
    }
}

final class ParameterLoader {
    private FileLoader fileLoader;
    public function __construct(FileLoader fileLoader) { this.fileLoader = fileLoader; }

    final public function load(filePath): array {
        rawParameters = this.fileLoader.loadFile(filePath);
        // ...
    }
}

new ParameterLoader(new JsonFileLoader());
new ParameterLoader(new XmlFileLoader());     // swap without touching ParameterLoader
```
- **What it demonstrates**: Extracting the interface was also the moment to add proper pre/postcondition checks — the abstraction gave the JSON-specific behavior a place to live.

Composition and decoration stacked on the same interface:

```php
// Composition — a FileLoader made of FileLoaders, keyed by extension
final class MultipleLoaders implements FileLoader {
    private array loaders;
    public function __construct(array loaders) {
        Assertion.allIsInstanceOf(loaders, FileLoader.className);
        Assertion.allIsString(array_keys(loaders));
        this.loaders = loaders;
    }
    public function loadFile(string filePath): array {
        extension = pathinfo(filePath, PATHINFO_EXTENSION);
        if (!isset(this.loaders[extension])) {
            throw new CouldNotLoadFile('There is no loader for file extension "{extension}"');
        }
        return this.loaders[extension].loadFile(filePath);
    }
}

// Decoration — behavior added on top, agnostic to what it wraps
final class CachedFileLoader implements FileLoader {
    private FileLoader realLoader;
    private array cache = [];
    public function __construct(FileLoader realLoader) { this.realLoader = realLoader; }

    public function loadFile(string filePath): array {
        if (isset(this.cache[filePath])) { return this.cache[filePath]; }
        result = this.realLoader.loadFile(filePath);
        this.cache[filePath] = result;
        return result;
    }
}

// The whole graph, assembled at the composition root
parameterLoader = new ParameterLoader(
    new ReplaceParametersWithEnvironmentVariables(
        new MultipleLoaders([
            'json' => new JsonFileLoader(),
            'xml'  => new XmlFileLoader()
        ]),
        ['APP_ENV' => 'dev']
    )
);
```
- **What it demonstrates**: `ParameterLoader` has no idea any of this is happening. Every layer is independently testable and independently changeable.

## Reference Tables

| Want to change… | Use | Example |
|---|---|---|
| A value | Constructor argument | `new FileLogger('/var/log/app.log')` |
| A chunk of logic | Injected abstraction | `new ParameterLoader(new XmlFileLoader())` |
| Behavior combining several implementations | Composition | `MultipleLoaders` |
| Behavior layered on any implementation | Decoration | `CachedFileLoader` |
| Behavior in *other* services | Event listener / notification object | `ImportNotifications` |
| **Behavior by overriding a method** | **Nothing — don't** | ✗ |

| Mechanism | Cost |
|---|---|
| `EventDispatcher` | Add listeners without touching the service; but `dispatch()` is opaque and listeners are hard to trace |
| Named notification interface | Explicit and greppable; but adding a notification means changing the interface |

| Reuse mechanism | Enters the type hierarchy? | Use for |
|---|---|---|
| Composition | N/A | Services — the default |
| Trait | **No** — compiler-level copy/paste | Entities/value objects, which can't use DI |
| Inheritance | Yes | Genuine type hierarchies only |

## Worked Example

**Removing logging noise with decoration** — the chapter's hardest exercise, and its best argument for composition.

```php
// Before — the log() calls drown out what the class is actually for
final class CsvFileImporter {
    private Logger logger;
    public function __construct(Logger logger) { this.logger = logger; }

    public function import(string csvFile): void {
        this.logger.log('Importing file: ' . csvFile);
        foreach (linesIn(csvFile) as lineNumber => line) {
            this.logger.log('Importing line: ' . lineNumber);
            fields = fieldsIn(line);
            // ...
            this.logger.log('Imported line: ' . lineNumber);
        }
        this.logger.log('Finished importing');
    }
}

// After — two interfaces create two decoration points.
// Note the key insight: you must EXTRACT an object for importing a single line,
// because you can only decorate at an interface boundary.
interface LineImporter { public function import(int lineNumber, string line): void; }

final class DefaultLineImporter implements LineImporter {
    public function import(int lineNumber, string line): void {
        fields = fieldsIn(line);
        // ...
    }
}

final class LoggingLineImporter implements LineImporter {
    private LineImporter actualLineImporter;
    private Logger logger;
    public function __construct(LineImporter actual, Logger logger) {
        this.actualLineImporter = actual;
        this.logger = logger;
    }
    public function import(int lineNumber, string line): void {
        this.logger.log('Importing line: ' . lineNumber);
        this.actualLineImporter.import(lineNumber, line);
        this.logger.log('Imported line: ' . lineNumber);
    }
}

interface FileImporter { public function import(string file): void; }

final class CsvFileImporter implements FileImporter {
    private LineImporter lineImporter;
    public function __construct(LineImporter lineImporter) { this.lineImporter = lineImporter; }
    public function import(string file): void {
        foreach (linesIn(file) as lineNumber => line) {
            this.lineImporter.import(lineNumber, line);      // no logging left
        }
    }
}

final class LoggingFileImporter implements FileImporter {
    private FileImporter actualFileImporter;
    private Logger logger;
    public function __construct(FileImporter actual, Logger logger) {
        this.actualFileImporter = actual;
        this.logger = logger;
    }
    public function import(string csvFile): void {
        this.logger.log('Importing file: ' . csvFile);
        this.actualFileImporter.import(csvFile);
        this.logger.log('Finished importing');
    }
}

// Assembly — nested decorators; usage is unchanged
importer = new LoggingFileImporter(
    new CsvFileImporter(
        new LoggingLineImporter(new DefaultLineImporter(), logger)
    ),
    logger
);
importer.import(/* ... */);
```

**Noback's own caveat**: this is *a lot* of code to delete a few log statements. He points to aspect-oriented programming (AOP) tooling as the pragmatic alternative when the only goal is hooking before/after existing calls. Worth noting — he doesn't pretend composition is free.

**And the inheritance-to-composition conversion**, in three states:

```php
// State 1 — subclassing. Subclass depends on the parent's protected internals.
class ParameterLoader {
    protected function loadFile(string filePath): array { return json_decode(...); }
}
final class XmlFileParameterLoader extends ParameterLoader {
    protected function loadFile(string filePath): array { /* XML */ }
}

// State 2 — template method. Better: internals stay private, only one hook exposed.
abstract class ParameterLoader {
    final public function load(filePath): array { /* ... this.loadFile(filePath) ... */ }
    abstract protected function loadFile(string filePath): array;
}

// State 3 — composition. Promote the abstract protected method to a public method
// on an injected object; the class becomes final again.
final class ParameterLoader {
    private FileLoader fileLoader;
    public function __construct(FileLoader fileLoader) { this.fileLoader = fileLoader; }
    final public function load(filePath): array { /* ... this.fileLoader.loadFile(...) ... */ }
}
```

## Key Takeaways
1. Prefer changing the object graph's structure over changing a class's code.
2. Climb the ladder in order: configurable value → replaceable dependency → composition → decoration → notification.
3. Abstract early (interface + higher-level name); generalize late (~three similar cases).
4. Decoration keeps cross-cutting concerns out of every implementation and lets them be tested separately.
5. Never use inheritance to change behavior. Template method is an improvement over subclassing but still strictly weaker than composition — and converts to it in one mechanical step.
6. Don't extend third-party classes even when invited to. Internals change; published APIs don't.
7. Mark every class `final` and every property/method `private` by default. The lone exception is a real type hierarchy.
8. Use traits, not inheritance, for code reuse in entities and value objects — a trait is copy/paste, not a hierarchy.
9. Events notify others so they can act; they are not a way to change the dispatching service's own behavior.

## Connects To
- **Ch 1 §1.5**: "inheritance plays a small role" is cashed out here as a hard rule
- **Ch 2**: constructor injection is what makes every technique in this chapter possible
- **Ch 6 §6.5 / Ch 7 §7.6**: the same two-part definition of abstraction, applied to internal behavior rather than system boundaries
- **Ch 7 §7.2**: event listeners for secondary tasks; here they add behavior to existing services
- **Open/Closed Principle & Liskov Substitution**: §9.1–9.5 are OCP via composition; §9.6 is why LSP is easier to satisfy when you never subclass
- **Decorator pattern** (GoF), **Template Method** (GoF, rejected in favor of composition)
