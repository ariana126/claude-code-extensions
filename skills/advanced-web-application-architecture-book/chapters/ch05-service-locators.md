# Chapter 5: Service locators

## Core Idea
Never let an object fetch its own dependencies, configuration, or contextual data from global helpers. Inject dependencies and configuration as **constructor arguments**, pass contextual and job-specific data as **method arguments**, and restrict the service container to the role of **composition root** near the entry point.

## Frameworks Introduced

- **The three input categories, and where each one goes** — the chapter's central classification.

  | Category | How it's provided | Examples |
  |---|---|---|
  | **Dependency** (a service) | Constructor argument | `Mailer`, `Translator`, `EbookRepository`, `EventDispatcher` |
  | **Configuration value** | Constructor argument | default sender email address |
  | **Contextual information** | Method argument | current user, client IP, request time, locale, terminal size, color support |
  | **Job-specific data** | Method argument | `EbookId`, a `CreateOrder` command object |

  - How to tell contextual data: "The use of the word 'current' hints at the fact that we're talking about contextual data. This data is different for every request."

- **The definition of unit-testable code** — Noback's formulation, stated as a property to design toward:
  > "The result of calling a method on an object should be determined by its own implementation logic, and optionally by the behavior of one of its constructor arguments, or the method arguments provided to it; and nothing more."
  - When to use: as the acceptance test for whether a refactoring actually worked.
  - Applied to the original service: it has no constructor and no method arguments, so its own implementation should explain its behavior. It doesn't — the behavior lives in static helpers it calls. Both halves fail.

- **The compiler-assisted setup process** — the practical payoff of explicit dependencies.
  - When to use: writing a test, or judging a design.
  - How: instantiate the service with no arguments and follow the errors. Each one tells you exactly what's missing, including assertion failures on bad configuration values. "When the compiler says you're done, you will actually be done."
  - The inverse is the tell for a bad design: if instantiation is trivially easy but *calling a method* explodes with "No logged in user" / "Undefined config key", the prerequisites are disconnected from the class's structure.

- **Composition root** (Mark Seemann) — resolves the apparent paradox of "never use the container as a locator" versus "something has to make the first object."
  > "A Composition Root is a (preferably) unique location in an application where modules are composed together."
  > "A Composition Root is located at, or near, the entry point. An entry point is where user code is first executed by a framework."
  - How: fetching a service from the container **inside a controller** is fine — that's the composition root. "Once *inside* that service though, the use of the service container is no longer allowed."
  - If your framework supports controllers-as-services, you can push the composition root one level further up. "Note that this last step isn't required. The big win is that we're not using a service locator anywhere in our code other than near the entry points."

- **The locator/injector rule** — "never use the service container as a *locator*, only as an *injector*, sometimes called an *inversion of control container*."
  - The difference: locating means the class asks where its dependencies come from; injecting means the class merely "declares a number of required constructor arguments and their types."

- **The two islands** — the strategy for a testable codebase.
  - Separate logic from infrastructural concerns and you get two islands: one you write unit tests for, one you write integration tests for. "The bigger the first island is, the better."
  - Corollary: "not to write a unit test for every single class. Unit tests only fit a certain type of objects. Mailer services, controllers, repositories, they all need integration tests."

## Key Concepts
- **Service locator** — any global mechanism for fetching a service on demand: `$container->get()`, `resolve()`, `sfContext`, `Zend_Registry::get()`.
- **Dependency injection** — dependencies supplied from outside, as constructor arguments.
- **Inversion of control** — the class stops deciding where its dependencies come from and merely declares what it needs.
- **Composition root** — the single place where the object graph is assembled.
- **Entry point** — "the user code that the framework calls first" — typically the controller the framework routes to.
- **User code** — code written by you or your team, not part of the framework.
- **Contextual data** — information that differs per request; the giveaway word is "current".
- **Temporal dependency** — the requirement that a framework has been booted and configured *before* this code can run.
- **Pure service** — one whose behavior is fully determined by its own implementation plus its constructor and method arguments.
- **Unit test** — "a test that doesn't use any IO… and usually but not necessarily covers a smaller unit of code, like a single class."

## Mental Models
- **Read a constructor as a sentence describing what the service needs.** "The `SendIpConfirmationEmail` service needs the `Mailer` service and a default sender address to send an IP confirmation email to the currently logged in user." Compare that to "having to read the entire method just to find out which dependencies will be fetched at runtime."
- **Injecting the container is barely better than a global.** It doesn't break Rule 1 (no runtime external system), but it conflicts with Rule 2: "By injecting the generic `ContainerInterface` we now require a special context for our service to run in."
- **A method signature with no arguments that produces user-visible effects is a warning.** `send(): void` "leaves the client of the method with absolutely no control over the outcome."
- **Treat the unit as a black box.** "What goes on inside should not be a concern of the unit test." A test that has to mirror the internals is "too close to the production code" and will break every time you add a setup step.
- **Framework coupling matters even in non-reusable application code.** Three reasons: helpers and syntactic sugar "are subject to fashion"; the code stays easier to test even after a framework migration; and if you depend on framework classes everywhere, "you will have to make changes everywhere" to migrate.
- **Add an assertion on injected configuration.** `Assertion::email($defaultSender)` — "one day that will save us some debugging time."

## Anti-patterns
- **Injecting the service container** (`ContainerInterface $container`): moves the locator inside rather than removing it. The container "has to know about all the dependencies that the application service might need."
- **Global helper functions**: `resolve(Mailer::class)`, `config('mail.default_sender')`, `Auth::user()`, `request()->ip()`, `trans(...)`. Each is a hidden dependency the signature never mentions.
- **Static registries**: `Zend_Registry::get()`, `sfContext` — "you could basically send emails from your domain model if you wanted." Noback: "my team and I had a lot of trouble getting rid of `Zend_Registry`… just don't start using anything like it."
- **Implicitly-configured globals**: `trans()` silently uses the locale set by `App::setLocale()`. "The code in `send()` doesn't reveal this information; you have to *know it*."
- **A unit test that isn't one**: because the class can `resolve()` anything, "we can't guarantee that this test is a unit test, or remains a unit test." Forget one test double and it may send real email.
- **Unit-testing everything**: mailers, controllers, and repositories need integration tests. "Testing this kind of code as a unit test doesn't prove anything about its effectiveness."
- **Tests that mirror production code**: "After a few of these tests you will be tempted to stop writing tests at all."

## Code Examples

Before — every dependency, config value, and piece of context fetched from global state:

```php
final class SendIpConfirmationEmail
{
    public function send(): void
    {
        $message = EmailMessage::create()
            ->to(Auth::user()->email())
            ->from(config('mail.default_sender'))
            ->text(
                trans('Add your :ip to the whitelist', ['ip' => request()->ip()])
            );

        resolve(Mailer::class)->send($message);
    }
}
```

After — dependencies and config in the constructor, context in the method:

```php
use Assert\Assertion;

final class SendIpConfirmationEmail
{
    private Mailer $mailer;
    private string $defaultSender;
    private Translator $translator;

    public function __construct(
        Mailer $mailer,
        string $defaultSender,
        Translator $translator
    ) {
        Assertion::email($defaultSender);

        $this->mailer = $mailer;
        $this->defaultSender = $defaultSender;
        $this->translator = $translator;
    }

    public function send(User $user, string $ipAddress): void
    {
        $message = EmailMessage::create()
            ->to($user->email())
            ->from($this->defaultSender)
            ->text(
                $this->translator->trans(
                    'Add your :ip to the whitelist',
                    ['ip' => $ipAddress],
                    $user->locale()      // locale passed explicitly, not ambient
                )
            );

        $this->mailer->send($message);
    }
}
```

- **What it demonstrates**: five hidden dependencies became three constructor arguments and two method arguments. Note the locale: it was never *fetched* from the request, only *assumed* to have been configured — the subtlest of the five.

Reuse the refactored service in a context that has no session at all:

```php
final class SupportController
{
    public function sendIpConfirmationEmail(Request $request): Response
    {
        $user = $this->userRepository->getById(
            $request->request->get('user_id')   // from the form, not the session
        );

        $this->confirmationEmail->send(
            $user,
            $request->request->get('ip')        // from the form, not the request
        );
        // ...
    }
}
```

The compiler walking you through setup:

```php
new SendIpConfirmationEmail();
// Error: Missing constructor argument of type `Mailer`
$mailer = $this->createMock(Mailer::class);

new SendIpConfirmationEmail($mailer);
// Error: Missing constructor argument of type `string`
$sender = 'a string';

new SendIpConfirmationEmail($mailer, $sender);
// Error: Missing constructor argument of type `Translator`
$translator = $this->createMock(Translator::class);

$service = new SendIpConfirmationEmail($mailer, $sender, $translator);
// Error: Value "a string" was expected to be a valid e-mail address.
$sender = 'info@matthiasnoback.nl';

$service = new SendIpConfirmationEmail($mailer, $sender, $translator);  // OK
$service->send();
// Error: Missing method argument of type `User`
$user = new User(/* ... */);

$service->send($user);
// Error: Missing method argument of type `string`
$ip = '127.0.0.1';

$service->send($user, $ip);   // OK
```

Versus the original, where instantiation succeeds and *usage* fails:

```php
new SendIpConfirmationEmail();   // OK
$service->send();
// Error: No logged in user
// Or maybe: Fatal error: Call to a member function email() on null
// Or maybe: Error: Undefined config key "mail.default_sender"
```

## Reference Tables

**Framework-specific tooling the original test needed — and the refactored test doesn't**

| Call | What it faked |
|---|---|
| `Auth::shouldReceive('user')` | Logged-in user |
| `Container::getInstance()->instance(...)` | The `Mailer` service |
| `App::setLocale(...)` | Locale for `trans()` |
| `Config::set('mail.default_sender', ...)` | Configuration value |
| `Request::shouldReceive('ip')` | Current HTTP request |

"This means that the unit test itself would survive a framework migration, just like the service itself."

**Is fetching from the container allowed here?**

| Location | Allowed | Role the container plays |
|---|---|---|
| Controller (the entry point) | Yes | Composition root |
| Controller defined as a service | Yes — and better | Composition root moves one level up |
| Inside an application service | **No** | Would be a service locator |
| Inside a domain object | **No** | Would be a service locator |

## Worked Example

**Two tests of the same behavior, and what the diff between them proves.**

The chapter's decisive move isn't the refactoring — it's writing the unit test **both ways** and comparing.

**Test for the original service.** Before you can call `send()` with no arguments, you must: fake the logged-in user via `Auth::shouldReceive('user')`; set the locale via `App::setLocale()` so `trans()` behaves; set `mail.default_sender` via `Config::set()`; fake the request IP via `Request::shouldReceive('ip')`; mock `Mailer` and register it via `Container::getInstance()->instance()`. Then, finally, `new SendIpConfirmationEmail()` and `$service->send()`.

**Test for the refactored service.** Mock `Mailer`. Mock `Translator`. Construct with `($mailer, $sender, $translator)`. Call `send($user, $ip)`.

**The line counts are roughly equal.** Noback says so explicitly — and this is why the comparison is convincing rather than rhetorical. The win isn't brevity.

The wins are:

1. **The test survives a framework migration.** Five framework-specific static calls disappear. The remaining test is plain PHPUnit.
2. **No global state to prepare.** "You can test various branches of the code by introducing a bit of variation to the constructor or method arguments. There are no other, hidden ways in which the behavior of the code may change."
3. **It isn't guaranteed to be a unit test in the first version.** Miss one test double and it may send real email — and since the class can `resolve()` anything, any resolved service might do IO. The refactored version cannot.
4. **You know when you're finished.** With explicit arguments, setup is compiler-assisted and terminates. With implicit ones, "you won't even know when you're done. Even if you look carefully through the code to find out what it needs, there's still a chance that you missed something."

The `trans()` locale is the proof of point 4. It's not fetched from anywhere in `send()` — it silently depends on `App::setLocale()` having been called earlier. Reading the method carefully would not reveal it. **You have to already know.**

**The objection Noback raises against himself.** "Dependency injection, passing contextual information; seems like a lot of work!" He concedes there are more symbols, then rejects his own first answer ("just never start using global helpers") as circular reasoning: *"You should do A now, because if you did B and you want to go to A, that'll be a lot of work!" So why not stay at B if you're happy there?*

The honest answer is empirical: "if your application lives longer than 2 or 3 years, you still want to go to A." The evidence is anecdotal — his team's struggle to remove `Zend_Registry` — and he says so.

## Key Takeaways
1. Dependencies and configuration values → constructor arguments. Contextual information and job-specific data → method arguments. Learn the four-way split.
2. Injecting `ContainerInterface` is not dependency injection. It passes Rule 1 but conflicts with Rule 2 — the service still needs a specially prepared context.
3. The word "current" in a description ("the current user", "the current request's IP") means you're looking at contextual data that belongs in a method argument.
4. Design toward the unit-testability property: behavior determined by own logic plus constructor arguments plus method arguments, **and nothing more**.
5. Easy instantiation plus explosive method calls is the signature of hidden dependencies. Easy-to-follow compiler errors is the signature of explicit ones.
6. Use the container as an **injector**, never a **locator** — except at or near the entry point, where it plays the different role of composition root.
7. Inside a controller, `$container->get()` is fine. Inside the service it calls, it is not.
8. Don't unit-test everything. Mailers, controllers, and repositories need integration tests. Grow the unit-testable island instead of forcing unit tests onto infrastructure.
9. Add assertions to injected configuration values — they pay for themselves in saved debugging.
10. Framework coupling hurts application code too, not just published libraries: fashion churn, test brittleness, and migration cost.

## Connects To
- **Ch 1**: Rule 2 (no special context) is what service locators violate; this chapter is the systematic fix.
- **Ch 4**: constructor injection was previewed there; the `$this->container->get(...)` calls left in those listings are cleaned up here.
- **Ch 6**: an example of effectively separating logic from infrastructural concerns — the "two islands."
- **Ch 7**: the same treatment applied to time and randomness, two more sources of ambient context.
- **Ch 14**: which kinds of code get unit tests versus integration tests, expanded into a full strategy.
- **Mark Seemann, "Dependency Injection in .NET"**: the composition root and entry point concepts.
- **Inversion of Control / Dependency Inversion Principle**: the general form of this chapter's argument.
