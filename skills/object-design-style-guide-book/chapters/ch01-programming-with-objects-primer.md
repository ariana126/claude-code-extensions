# Chapter 1: Programming with Objects — A Primer

## Core Idea
Establishes the shared vocabulary the rest of the book's rules are written in: classes/objects, state, behavior, dependencies, inheritance, polymorphism, composition, exceptions, unit testing. Skip if fluent — but note the two opinions Noback plants here: **private is the default scope**, and **inheritance plays a small role in good design**.

## Key Concepts
- **Class vs. object**: A class is the definition; an object is an instance. Two instances of the same class are never "the same" (`object1 == object2` → false).
- **Object method vs. static method**: An object method requires an instance; a static method is called on the class itself.
- **Static factory method**: A `public static` method that returns a new instance (`Foo.create()`) — the seed of named constructors (Ch 3).
- **State**: The data held in an object's properties.
- **Scoping**: `private` (same class only), `protected` (subclasses too), `public` (any client). Scoping is *class-based*, not instance-based — any `Foo` can read another `Foo`'s private property.
- **Mutable vs. immutable**: Immutable means no property can change after instantiation **and** every object held in those properties is itself immutable. Modifiers on immutables return a new instance.
- **Dependency**: An object `Foo` needs to do part of its job.
- **Service location**: Fetching a dependency from a known global place (`ServiceLocator.getLogger()`). Contrast with…
- **Dependency injection**: Receiving dependencies as constructor arguments.
- **Polymorphism**: A parameter typed `Foo` accepts any instance of `Foo` — so behavior can change without changing the calling code. Prefer interface types over subclass types.
- **Object composition**: Assigning objects to another object's properties to build something more capable out of simpler parts.
- **Test double / stub / mock**: A stand-in for a real dependency. A mock additionally records that it was called.

## Mental Models
- **Think of an object as having a boundary.** Public methods are the only sanctioned doorways; private state stays inside. (Made explicit in Ch 6.)
- **Use polymorphism, not subclassing, to vary behavior.** Same interface, different runtime instance — no override needed. Ch 9 makes this a hard rule.
- **Prefer composition over inheritance from the start.** Noback uses inheritance in exactly two places: (1) defining interfaces for dependencies, (2) exception class hierarchies.
- **Immutability is transitive.** An object holding a mutable object is not immutable, regardless of its own `final` properties.

## Code Examples

Mutable vs. immutable — the distinction the whole book turns on:

```php
final class Mutable
{
    private int someNumber;

    public function __construct(int initialNumber)
    {
        this.someNumber = initialNumber;
    }

    public function increase(): void          // command: changes self, returns void
    {
        this.someNumber = this.someNumber + 1;
    }
}

final class Immutable
{
    private int someNumber;

    public function __construct(int initialNumber)
    {
        this.someNumber = initialNumber;
    }

    public function increase(): Immutable     // returns a modified copy
    {
        return new Immutable(someNumber + 1);
    }
}

object1 = new Mutable(10);
object1.increase();               // object1 is now 11

object2 = new Immutable(10);
object2 = object2.increase();     // must reassign — the original is untouched
```
- **What it demonstrates**: An immutable modifier's return value is the *only* evidence of the change. Forgetting to reassign is a no-op, not a bug in the object.

The three ways to get a dependency — only the third is acceptable:

```php
class Foo {                                    // 1. instantiate it (hidden, untestable)
    public function someMethod(): void {
        logger = new Logger();
        logger.debug('...');
    }
}

class Foo {                                    // 2. locate it (hidden dependency)
    public function someMethod(): void {
        logger = ServiceLocator.getLogger();
        logger.debug('...');
    }
}

class Foo {                                    // 3. inject it (explicit) — do this
    private Logger logger;
    public function __construct(Logger logger) { this.logger = logger; }
    public function someMethod(): void { this.logger.debug('...'); }
}
```
- **What it demonstrates**: Options 1 and 2 make the dependency invisible in the constructor signature. Ch 2 turns this into the rule "make all dependencies explicit."

## Reference Tables

| Scope | Accessible from | Overridable by subclass |
|---|---|---|
| `private` | Same class only (any instance) | No |
| `protected` | Same class + subclasses | Yes |
| `public` | Any client | Yes |

| Test double | Purpose | Used with |
|---|---|---|
| Stub | Returns canned answers | Query methods (Ch 6) |
| Mock | Records/verifies that a call happened | Command methods (Ch 7) |
| Dummy | Satisfies a signature, does nothing | Unused dependencies |
| Fake | Working in-memory implementation | Repositories, gateways |

## Worked Example

**Arrange-Act-Assert**, the test structure used throughout the book:

```php
final class Foo
{
    private int someNumber;

    public function __construct(int startWith)
    {
        if (startWith < 0) {
            throw new InvalidArgumentException(
                'A negative starting number is not allowed'
            );
        }
        this.someNumber = startWith;
    }

    public function increment(): void { this.someNumber++; }
    public function someNumber(): int { return this.someNumber; }
}

final class FooTest
{
    /** @test */
    public function you_can_increment_the_number(): void
    {
        foo = new Foo(10);                      // Arrange
        foo.increment();                        // Act
        assertEquals(11, foo.someNumber());     // Assert
    }

    /** @test */
    public function you_cannot_start_with_a_negative_number(): void
    {
        expectException(
            InvalidArgumentException.className,
            'negative',                          // expected message keyword
            function () { new Foo(-10); }
        );
    }
}
```

Note the failure test asserts on **the exception class plus a keyword from its message** — not on a custom exception type. Ch 3 turns this into a rule: don't create custom exception classes for invalid arguments; assert against the message instead.

## Key Takeaways
1. `private` is the default scope for properties and methods; widen only with a reason (formalized in §9.8).
2. Dependency injection via constructor is the only acceptable way to obtain a dependency — the other two hide it.
3. Immutability is transitive; a "final" object holding a mutable collaborator is still mutable.
4. Inheritance earns its place in only two situations: interfaces for dependencies, and exception hierarchies. Everything else is composition + polymorphism.
5. Throwing inside a constructor prevents the object from existing at all — this is how domain invariants get enforced (Ch 3).
6. Test doubles let you replace dependencies that would cause side effects; stubs answer, mocks verify.

## Connects To
- **Ch 2**: turns "inject dependencies" into a full set of construction rules for services
- **Ch 4**: expands mutable vs. immutable into entities vs. value objects
- **Ch 9**: converts "prefer composition" into `final` by default and "don't use inheritance to change behavior"
- **Dependency Inversion Principle**: the interface-typed parameter in §1.6 is DIP in miniature
