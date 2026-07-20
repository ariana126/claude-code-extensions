# Chapter 2: Creating Services

## Core Idea
A service is a do-er with a trivial lifecycle: construct it once with everything it needs, then reuse it forever. Every rule in this chapter exists to guarantee that a service is **complete and immutable the instant `new` returns** — no setters, no optional arguments, no work in the constructor, no hidden dependencies.

## Frameworks Introduced

- **The Two Types of Objects**: Every object is either (a) a **service** — performs a task or returns information, created once, never changed; or (b) an **other object** (material) — holds data, may be manipulated, has a richer lifecycle.
  - When to use: Deciding which ruleset applies. Ch 2 governs services; Ch 3 governs everything else.
  - How: Services are named for what they *do* — `EventDispatcher`, `UserRepository`, `TemplateRenderer`, `DiscountCalculator`. Materials are named for what they *are* — `User`, `Product`, `Route`, `Credentials`.

- **Inject what you need, not where you can get it from**: Declare the actual collaborator as a constructor argument; never inject a service locator, container, manager, or registry you'd fetch from.
  - When to use: Whenever a constructor argument is something you call `.get()` / `.getRepository()` on.
  - How: Ask the exercise question — *does the service use this dependency directly, or does it retrieve the real dependency from it?* If the latter, inject the real thing. Iterate: `ServiceLocator` → `EntityManager` → `UserRepository`.
  - Why it works: The constructor signature becomes an honest inventory of what the class actually depends on. A locator hides three dependencies behind one and removes all design pressure to notice you have too many.

- **There's no such thing as an optional dependency**: You either need it or you don't. Optional constructor arguments, default values, and setter injection are all banned.
  - When to use: Any time you're tempted to write `Logger? logger = null`.
  - How: Promote to required, then give clients an easy way to satisfy it — a **null object** (`NullLogger`, `EventDispatcherDummy`) for services, a **named default factory** (`Configuration.createDefault()`) for configuration values.
  - Failure mode it prevents: `if (this.logger instanceof Logger)` guards scattered through every method.

- **Make all dependencies explicit** (three sub-moves): Even with everything injected, dependencies can still hide.
  1. **Turn static dependencies into object dependencies** — `Cache.get(...)` becomes an injected `Cache`.
  2. **Turn complicated functions into object dependencies** — `json_encode(...)` becomes an injected `JsonEncoder`.
  3. **Make system calls explicit** — `new DateTime()`, `time()`, `file_get_contents()` become an injected `Clock` / gateway, *or* get passed as a method argument.

- **The "batch test" for constructor vs. method argument**: Ask *"Could I run this service in a batch, without reinstantiating it?"* If no, the argument is task data and belongs on the method.
  - Tell: the word **"current"**. "The current time", "the currently logged-in user", "the current request", "the current locale" — all contextual, all method arguments.

## Key Concepts
- **Service**: An object that performs a task or returns information; immutable after construction; reused many times.
- **Service locator**: A service you retrieve other services from, keyed by identifier. Legitimate at the framework's entry point; illegitimate as a constructor argument.
- **Hidden dependency**: A dependency invisible in the constructor signature — static accessors, standard-library functions, system calls.
- **Null object / dummy**: A harmless implementation that does nothing, used to satisfy a now-required dependency.
- **Immutable object graph**: The whole application's services, constructed once, with controllers as the only public entry points.

## Mental Models
- **Think of a service as a little machine.** Bolt everything on at build time; then it runs forever, identically, for everyone.
- **The constructor signature is documentation.** If you can't tell what a service does and how it's configured by reading its `__construct`, something is hidden.
- **Assignment order is a smell detector.** If reordering property assignments in a constructor breaks it, you're *doing something* in the constructor, not just assigning.
- **Push setup outward, not inward.** When a constructor wants to do work, the answer is usually a factory or the application's bootstrap phase — not a lazy private method deeper in the class.

## Anti-patterns
- **Injecting the whole configuration object** (`AppConfig`): inject only the values needed (`string cacheDirectory`). Exception: values with natural cohesion (username + password) belong together in a dedicated `Credentials` object.
- **Injecting a service locator/container/manager**: obscures real dependencies and removes pressure to improve the design.
- **Optional constructor arguments / default values**: you can no longer tell how an object is configured by reading the call site; the default becomes a silently-changeable implementation detail.
- **Setter injection** (`setLogger()`): creates objects in an incomplete state and makes services mutable.
- **Behavior-changing setters** (`ignoreErrors()`, `addListener()`/`removeListener()`): the service takes different execution paths depending on who called what first.
- **Doing work in a constructor** (`mkdir`, `touch`, connecting, calling a dependency): instantiating leaves side effects even if the object is never used.
- **Injecting `Request`, `Session`, or an entity**: locks the service to one job or one context; it can't be batched.

## Code Examples

Making a system call explicit with a `Clock` — and the test payoff:

```php
interface Clock {
    public function currentTime(): DateTime;
}

final class SystemClock implements Clock {
    public function currentTime(): DateTime { return new DateTime(); }
}

final class FixedClock implements Clock {        // for tests
    private DateTime now;
    public function __construct(DateTime now) { this.now = now; }
    public function currentTime(): DateTime { return this.now; }
}

final class MeetupRepository {
    private Clock clock;
    public function __construct(Clock clock, /* ... */) { this.clock = clock; }

    public function findUpcomingMeetups(string area): array {
        now = this.clock.currentTime();
        // ...
    }
}

// In a test — fully deterministic:
new MeetupRepository(new FixedClock(new DateTime('2018-12-24 11:16:05')));
```
- **What it demonstrates**: Without this, the test's result depends on the day it runs, and will eventually fail on its own. Note Noback's own revision at the end of §2.7.3 — passing `DateTime now` as a *method* argument is often better still, since "the current time" is contextual.

Validate, then assign — nothing else in a constructor:

```php
final class Alerting {
    private int minimumLevel;

    public function __construct(int minimumLevel) {
        if (minimumLevel <= 0) {
            throw new InvalidArgumentException(
                'Minimum alerting level should be greater than 0'
            );
        }
        this.minimumLevel = minimumLevel;
    }
}
```
- **What it demonstrates**: Throwing in the constructor prevents an invalid object from ever existing. The type system catches `Logger` vs `bool`; only you can catch `-99999999`.

## Reference Tables

| Argument is… | Goes where | Example |
|---|---|---|
| A collaborating service | Constructor | `Formatter`, `UserRepository` |
| A configuration value | Constructor (required, no default) | `logFilePath`, `minimumLevel` |
| Task data | Method | `entity` in `save(entity)` |
| Contextual info ("the current X") | Method | `userId`, `now`, `locale` |

**Should this function become an object dependency?** Mostly-yes on these three → extract:
| Question | |
|---|---|
| Will you want to replace or enhance this behavior later? | |
| Is it complex enough that you couldn't inline it in a few lines? | |
| Does it deal with objects rather than just primitives? | |

`array_keys()`, `strpos()` → no. `json_encode()`, `simplexml_load_file()` → yes.

## Worked Example

**Refactoring `HomepageController`, in three passes** — the chapter's spine:

```php
// Pass 0 — one "dependency" that is really three, all hidden
final class HomepageController {
    private ServiceLocator locator;
    public function __construct(ServiceLocator locator) { this.locator = locator; }

    public function execute(Request request): Response {
        user = this.locator.get(EntityManager.className)
            .getRepository(User.className)
            .getById(request.get('userId'));
        return this.locator.get(ResponseFactory.className)
            .create()
            .withContent(
                this.locator.get(TemplateRenderer.className)
                    .render('homepage.html.twig', ['user' => user]),
                'text/html'
            );
    }
}

// Pass 1 — inject the actual dependencies. The signature is now honest.
final class HomepageController {
    public function __construct(
        EntityManager entityManager,
        ResponseFactory responseFactory,
        TemplateRenderer templateRenderer
    ) { /* assign */ }
    // ...
}

// Pass 2 — EntityManager was itself only a source of the real dependency
final class HomepageController {
    private UserRepository userRepository;
    public function __construct(UserRepository userRepository, /* ... */) {
        this.userRepository = userRepository;
    }
    public function execute(Request request): Response {
        user = this.userRepository.getById(request.get('userId'));
        // ...
    }
}
```

**The follow-on problem Noback raises himself**: if you needed `entityManager.flush()` to persist, injecting `UserRepository` seems to *add* a dependency rather than remove one. His answer is not to give up but to **redistribute responsibility** — the object that can fetch a `User` should also be able to save one. That's the Repository pattern:

```php
user = this.userRepository.getById(request.get('userId'));
user.changePassword(newPassword);
this.userRepository.save(user);
```

**Closing the loop** — services form one immutable graph whose only public doors are controllers:

```php
final class ServiceContainer {
    public function homepageController(): HomepageController {   // entry point: public
        return new HomepageController(
            this.userRepository(), this.responseFactory(), this.templateRenderer()
        );
    }
    private function userRepository(): UserRepository { /* ... */ }   // dependency: private
    private function responseFactory(): ResponseFactory { /* ... */ }
    private function templateRenderer(): TemplateRenderer { /* ... */ }
}
```

## Key Takeaways
1. All dependencies and configuration values are **required constructor arguments**. No optionals, no defaults, no setters.
2. Inject the dependency you *use*, never the thing you'd *fetch it from*.
3. A constructor may do exactly two things: validate arguments and assign properties. If the assignment order matters, you've broken this rule.
4. Task data and anything called "the current X" are method arguments — otherwise the service can't be reused or batched.
5. Once constructed, a service must be impossible to reconfigure. No `setLogger()`, no `ignoreErrors()`, no `addListener()`.
6. Replace an optional dependency with a null object; replace an optional config value with a `createDefault()` factory.
7. Validate constructor arguments that the type system can't — but only where an invalid value would actually break behavior (`Router` tolerates an empty controllers array; it does not tolerate non-string keys).
8. Controllers are the entry points of the application object graph; every other service stays private in the container.

## Connects To
- **Ch 3**: the mirror-image rules for the *other* type of object
- **Ch 9**: §2.9's "don't change behavior after instantiation" becomes the constructor-argument techniques for configurable/replaceable behavior
- **Ch 10**: `ServiceContainer` entry points reappear as the controller/application-service layering
- **Dependency Inversion Principle & Hexagonal Architecture**: `Clock` and `JsonEncoder` are ports; `SystemClock` and `FixedClock` are adapters
