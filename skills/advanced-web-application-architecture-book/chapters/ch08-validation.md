# Chapter 8: Validation

## Core Idea
Split validation in two. **Domain objects protect themselves** by throwing exceptions the moment invalid data arrives — that's *protection*, not validation. **Controllers collect user-facing errors** by reusing that same domain logic in a `try`/`catch`. And do everything you can so no well-behaving user ever triggers either one.

## Frameworks Introduced

- **Protection vs. validation** — the chapter's foundational distinction.
  > "You could say that this isn't validation, it's more like **protection**. We don't assign a value to a property, then validate it; we protect the object from ending up in an incorrect state."
  - When to use protection: inside entities and value objects — every constructor and every method that assigns to a property.
  - When to use validation: in the controller, where you know who the user is and how to talk to them.

- **The three failure modes an object must prevent** — what "protect its own state" concretely means:
  - **Incomplete** — data is missing that must be there for even the most basic task (an amount with no currency).
  - **Invalid** — right type, wrong value (a currency `string` that isn't a known currency).
  - **Inconsistent** — two pieces of data that can't co-exist (marked for bank transfer, yet has a credit card holder).
  - Plus a fourth responsibility: **prevent bad state transitions.** "If an order has been paid and delivered, it can't be cancelled anymore."

- **The two-part split of validation across the core/infrastructure line:**

  | Concern | Where | Mechanism |
  |---|---|---|
  | Data must never be invalid, whoever sent it | Entities, value objects (core) | Throw exceptions |
  | Relation to another entity actually exists | Application service (core) | Fetch from the (read model) repository |
  | Business rule needing outside state | Application service (core) | Throw a `UserErrorMessage` |
  | Friendly, translated, per-field error list | Controller (infrastructure) | Collect into `$formErrors` |

- **`UserErrorMessage`** — the mechanism for talking back to the user from core code.
  - When to use: a rule the entity can't check alone, where the user genuinely can be helped ("insufficient stock").
  - How: an interface `UserErrorMessage extends Throwable` with `translationKey()`, a `BaseUserErrorMessage` to kill boilerplate, and custom exceptions with intention-revealing named constructors (`CouldNotOrderPhysicalBook::becauseInsufficientStockLevels()`). The controller catches `UserErrorMessage` and maps `translationKey()` to a form error.
  - Not every domain exception should be one. Ask: *what could cause this?* If the only answers are "a programming mistake" or "a malicious user", it shouldn't be user-facing.

- **The pure-function rule for validation** — the chapter's sharpest and least obvious rule:
  > "When validating input data, only use pure functions."
  - Why: `numberOfAvailableBooks()` is impure — not referentially transparent. Between the check and the save, another customer's order may take the last copy. "The answer it gave is always the correct answer *at the moment it calculates the answer*. It's just that the answer changes all the time."
  - Consequence: "validation itself, if seen as a function, becomes a pure function itself. If you validate the data now and it's valid, it should still be valid when you validate it again."
  - When it doesn't hold, choose a different design (see the alternatives table below) — or stick with validation "and remain conscious of the fact that it's not ideal."

- **Command object as a shape for request data** — four concrete advantages over reading the `Request` key by key:
  1. It provides a complete list of available keys; a `Request` "just does a lookup in the request data for any key you provide."
  2. A potential client can see what data it needs to provide — impossible from a request body, which "may be incomplete, or contain more fields than necessary."
  3. It carries explicit types and nullability; request values "are either of type `string` or undefined (`null`)."
  4. It can define defaults for missing data via default property values.
  - Also a **Data Transfer Object (DTO)**: it transfers data from controller to application service.

## Key Concepts
- **Self-validating entity** — every method that assigns values validates first; no external validator required.
- **Value object** — wraps one or more values and validates in its constructor; "in the context of validation, value objects are useful because they'll never need to be validated."
- **Always-valid entity** — the guarantee that follows from protection.
- **Command object / DTO** — a shaped, typed holder for input data.
- **`UserErrorMessage`** — an exception explicitly intended to reach the user, carrying a translation key.
- **Translation key** — `'create_order.invalid_email_address'` rather than literal text, so messages can be localized later.
- **Impure / not referentially transparent** — a function that can give different answers on repeated calls.
- **Frontend validation and assistance** — the first and best line of defense; "the best way to communicate with the user."

## Mental Models
- **Run the CLI thought experiment on validation itself.** Would input still need validating in a CLI app? Obviously. Would the *error presentation* change? Completely — first error only, or machine-readable JSON codes instead of translated messages. That split *is* the chapter: same rules in the core, different presentation per delivery mechanism.
- **A validator that must run before an entity is a coupling problem.** "Coupling isn't bad per se, but when there is a rule that one object (the validator) has to be used *before* the other one (the entity) can be used, it's a problem. In this case it means the entity isn't safe to use at all, because who knows if it has been validated."
- **Aim for zero validation errors reaching real users.** "We should do everything we can to ensure that no well-behaving user would ever see a validation error." Warn while they type; disable submit until the field is valid. Then "only a malevolent user who manually forges a `POST` request could submit invalid data. At that point… a simple `400 Bad Request` status message would suffice."
- **Treat entity-level exceptions in production logs as a signal, not noise.** They mean either (1) someone is abusing your application, or (2) the UI lets users make a mistake it shouldn't. "Most users are good people, so we can assume most of the times it's just an issue with the user interface. Take action to make sure the exception never shows up again."
- **"Exceptions only for exceptional situations" is not useful advice.** You'd have to define "exceptional." `CouldNotOrderPhysicalBook` genuinely is rare. And "if it turns out that an exception is no longer exceptional, that is, it gets thrown a lot, this is a strong sign that we need to improve the user experience somehow." Meanwhile: "Preventing bad things from happening to our domain objects is a great reason for throwing exceptions."
- **Sometimes recovery beats prevention.** "Your strategy could be that instead of preventing certain situations, you aim to recover from them." Accept the order, tell the customer it's provisional, offer a discount or an alternative if it falls through. "It's better to be friendly and helpful towards your users than to throw errors when the user wasn't expecting them."

## Anti-patterns
- **Populate-then-validate**: `new Order()`, a series of setters, then `$validator->validate($order)`. If anyone forgets the validator call, invalid data reaches the database. The entity is never trustworthy.
- **An external validator reaching into an entity**: needs getters that exist only for it (Ch 3's smell), and duplicates all the entity's knowledge. Validator-library *configuration* is no better: "it's so easy to make a mistake in validator configuration which would let bad data go through."
- **Setters that only type-check**: "the setter doesn't look any closer at the value provided; it doesn't validate the value, it doesn't throw an exception if somebody provides a bad email address."
- **Duplicating validation logic in the controller**: the same `filter_var(..., FILTER_VALIDATE_EMAIL)` in three places. Reuse the value object instead.
- **Validating everything twice**: even after removing duplication, "we still duplicate the *effort*. Everything gets checked twice."
- **Validating data the user couldn't have gotten wrong**: an e-book ID comes from a `<select>` or a hidden field. "If the value that ends up being submitted is incorrect, it's not the user's fault… No validation error can help the user then."
- **Passing an entire entity to another object**: "Relations should be established by ID, not by object reference. Sharing an entity exposes all the entity's modifier methods to clients that don't intend to make changes to it." (Passing a *read model* is fine — see the worked example.)
- **Returning a result object instead of throwing**: "object-oriented languages aren't generally suited for that. The traditional way to indicate that a method was successful is to return nothing… and to throw an exception when something goes wrong."
- **Exact comparison against an impure query**: `if ($quantityAvailable < $quantity)` is a race by construction.

## Code Examples

The anti-pattern — populate, then hope someone validates:

```php
$order = new Order();
$order->setEmailAddress($request->get('email'));

$line = new Line();
$line->setEbookId($request->get('ebook_id'));
$line->setQuantity($request->get('quantity'));

$errors = $this->validator->validate($order);
if (count($errors) === 0) {
    $this->orderRepository->save($order);
}
```

Protection instead — value objects hold the rules:

```php
final class EmailAddress
{
    private string $emailAddress;

    public function __construct(string $emailAddress)
    {
        if (!filter_var($emailAddress, FILTER_VALIDATE_EMAIL)) {
            // We don't return an error, but throw an exception
            throw new InvalidArgumentException('Invalid email address: ' . $emailAddress);
        }

        $this->emailAddress = $emailAddress;
    }
}

final class Quantity
{
    public function __construct(int $quantity)
    {
        if ($quantity <= 0) {
            throw new InvalidArgumentException('Line quantity should be at least 1');
        }

        $this->quantity = $quantity;
    }
}
```

…which collapses the entity to almost nothing:

```php
final class Order
{
    private EmailAddress $emailAddress;
    private array $lines;

    public function __construct(EmailAddress $emailAddress)
    {
        $this->emailAddress = $emailAddress;
    }

    public function addLine(EbookId $ebookId, Quantity $quantity): void
    {
        $this->lines[] = new Line($ebookId, $quantity);
    }
}
```

- **What it demonstrates**: "whenever a method argument is of type `EmailAddress` or `Quantity`, you know that the value inside has been validated already. There is no need to validate the value again."

Reusing the value object for form validation — no duplicated rules:

```php
public function createOrderAction(Request $request): Response
{
    $formErrors = [];

    try {
        new EmailAddress($request->get('email'));
    } catch (InvalidArgumentException $exception) {
        $formErrors['email'][] = 'create_order.invalid_email_address';
    }

    try {
        $this->ebookRepository->getById(
            EbookId::fromString($request->get('ebook_id'))
        );
    } catch (CouldNotFindEbook $exception) {
        $formErrors['ebook_id'][] = 'create_order.could_not_find_ebook';
    }
    // ...
}
```

`UserErrorMessage` — core code talking to the user without knowing who they are:

```php
interface UserErrorMessage extends Throwable
{
    public function translationKey(): string;
}

abstract class BaseUserErrorMessage extends RuntimeException implements UserErrorMessage
{
    private string $translationKey;

    public function __construct(string $translationKey)
    {
        $this->translationKey = $translationKey;
        parent::__construct($translationKey);
    }

    public function translationKey(): string
    {
        return $this->translationKey;
    }
}

final class CouldNotOrderPhysicalBook extends BaseUserErrorMessage
{
    public static function becauseInsufficientStockLevels(): self
    {
        return new self('create_order.insufficient_quantity_in_stock');
    }
}

// In the controller — the only place that knows who the user is:
try {
    $this->orderPhysicalBook->order($request->get('book_id'), $request->get('quantity'));
} catch (UserErrorMessage $exception) {
    $formErrors['general'][] = $exception->translationKey();
}
```

The command object taming shapeless request data:

```php
trait Mapping
{
    private static function getString(array $data, string $key): string
    {
        return isset($data[$key]) ? (string)$data[$key] : '';
    }

    private static function getInt(array $data, string $key): int
    {
        return isset($data[$key]) ? (int)$data[$key] : 0;
    }

    private static function getNonEmptyStringOrNull(array $data, string $key): ?string
    {
        if (!isset($data[$key]) || $data[$key] === '') {
            return null;
        }

        return (string)$data[$key];
    }
}

final class OrderEbook
{
    use Mapping;

    public static function fromRequestData(array $data): self
    {
        return new self(
            self::getString($data, 'email'),
            self::getInt($data, 'ebook_id'),
            self::getInt($data, 'quantity'),
            self::getNonEmptyStringOrNull($data, 'buyer_name')
        );
    }
}
```

- **What it demonstrates**: the command object is deliberately permissive — an empty string or `0` is fine. "Down the stream there will always be some domain object that looks inside the variable and validates it. At least we won't get generic type errors anymore; we'll get proper exceptions which indicate a specific problem."
- **On testing it**: don't unit-test `fromRequestData()` — one execution path. *Do* unit-test the `Mapping` helpers: "because many classes are going to rely on these helper functions, they should be safe to use and work in all possible cases."

Validating the command object rather than the raw request:

```php
final class OrderEbookValidator
{
    public function validate(OrderEbook $command): array
    {
        $formErrors = [];

        try {
            EmailAddress::fromString($command->emailAddress());
        } catch (InvalidArgumentException $exception) {
            $formErrors['email'][] = 'invalid_email_address';
        }
        // ...

        return $formErrors;
    }
}
```

## Reference Tables

**Who may throw on invalid input?**

| Object type | May throw? |
|---|---|
| Value objects | **Yes** |
| Entities | **Yes** |
| Application services | **Yes** (incl. `UserErrorMessage`) |
| Controllers | No — collect form errors |
| Validators | No — collect form errors |

**Should this exception be a `UserErrorMessage`?**

| Cause | User-facing? | Action |
|---|---|---|
| Race on stock levels between selection and submit | **Yes** | Throw `UserErrorMessage`; catch in controller |
| Malformed hidden field / tampered request | No | Generic error page; log it |
| Programming mistake (bad `<select>` rendering) | No | Log, fix before release |
| Missing `stock_levels` record | No | "We should be notified about the problem, and fix it" |

**When an impure query blocks validation — alternatives**

| Option | Trade-off |
|---|---|
| Exact comparison anyway | Fine if the race is rare; "remain conscious of the fact that it's not ideal" |
| Fuzzy comparison | Don't assume the query gives an exact answer |
| Accept and process later | User gets a preliminary "please wait for the definitive answer" |
| Always say yes, recover on failure | Best UX; needs a human process (discount, alternative product) |

## Worked Example

**The e-book ID: validated three times, then not at all.**

Follow one rule — "the provided e-book IDs should refer to e-books that are actually available in our catalog" — through the whole chapter.

**Attempt 1 — the external validator.** `OrderValidator::validate(Order $order)` loops the lines, calls `$this->ebookRepository->getById($line->getEbookId())`, catches `CouldNotFindEbook`, appends an error. It works, but: it needs getters on `Order` that exist only for the validator, and it must run *before* the entity is trusted. The entity is never safe on its own.

**Attempt 2 — let the entity protect itself.** Move the checks inside. But `addLine(EbookId $ebookId, ...)` hits a wall: "There's no way to verify that the provided ID refers to an actual e-book from our catalog." `EbookId` can confirm the string is a UUID — nothing more. **An entity "can't look beyond itself and the data provided to it."**

**Attempt 3 — the application service, via the repository.** The service fetches the read model:

```php
$ebook = $this->ebookRepository->getById(EbookId::fromString($ebookId));
$order->addLine($ebook->ebookId(), $quantity, $ebook->price());
```

Existence is proven as a side effect of needing the data anyway — `getById()` throws `CouldNotFindEbook` if it's missing. And since we need the price regardless, no extra query.

**Attempt 3b — pass the read model itself.** `$order->addLine($ebook, $quantity)`. Two gains: "this ensures that the price and the `EbookId` on the line actually belong to the same e-book," and the code shows the values come from one source.

With a caveat: this may "let `Order` in on too many details about `Ebook`s." Safe if the read model was designed for this use case only (Ch 3's rule); risky if shared. "The fewer methods you expose to a client, the more flexible your design will be."

And a hard line: read model, yes — **entity, never**. "Relations should be established by ID, not by object reference."

**Attempt 4 — also check it in the controller?** Add a `try`/`catch` around `getById()` to build a form error. Noback raises two objections: it clutters the controller, and "we still duplicate the *effort*. Everything gets checked twice."

**The resolution — don't validate it at all.** Where does an e-book ID come from? A `<select>`, or a button populating a hidden field. If the submitted value is wrong, "it's not the user's fault. It could be a programming mistake… No validation error can help the user then." Or it's a malicious user, "but they still don't need a friendly validation error."

> "Simply assume that the user has used the user interface in the correct way, and didn't tamper with the request data. If they did, everything should go fine once the data is being used to instantiate and manipulate domain objects. If they didn't, we still have our entity-level protection in place, and we simply show the generic error page."

The same reasoning removes the email check from the controller — frontend validation should catch it while the user types.

**What survives: the entity-level protection, as a tripwire.** It never fires for a well-behaved user. When it does fire, the log entry tells you either someone is abusing the application or your UI needs fixing. "Take action to make sure the exception never shows up again."

**And the case that genuinely needs a user message.** Stock levels can't be checked by the entity (it can't see outside itself) and can't be prevented by the frontend (the answer changes between page load and submit). So the application service throws `CouldNotOrderPhysicalBook::becauseInsufficientStockLevels()`, and the controller catches `UserErrorMessage`.

Then §8.5 undercuts even that: `numberOfAvailableBooks()` is impure. Another customer may take the last copy between the check and the save. The check isn't wrong — "the answer it gave is always the correct answer *at the moment it calculates the answer*" — it's just already stale. Which yields the rule: **when validating input data, only use pure functions.** Where you can't, redesign — fuzzy comparison, deferred processing, or accept-and-recover.

## Key Takeaways
1. Protection ≠ validation. Objects protect themselves by throwing on assignment; controllers validate to collect friendly errors. Both exist; neither replaces the other.
2. Never populate-then-validate. A validator that must run before an entity means the entity is never safe to use.
3. Push each rule into a value object. Then a typed parameter *is* the proof that validation happened.
4. Objects must prevent incomplete, invalid, and inconsistent state — plus illegal state transitions.
5. An entity can't validate relations; it can't see beyond itself. Do that in the application service by fetching from the repository. Pass a read model, never an entity.
6. Reuse the same value objects and repository calls for form validation — one place holds the rules.
7. Prefer not validating at all where a well-behaved user cannot be wrong. Rely on frontend assistance plus entity-level protection, and return `400 Bad Request` to anyone forging requests.
8. Treat entity-level exceptions in logs as a UX backlog: abuse, or a UI that permits mistakes.
9. Use `UserErrorMessage` only when the user can actually act on it — not for programming mistakes or tampering.
10. Only validate with pure functions. Against impure state (stock levels), prefer fuzzy comparison, deferred processing, or recovery over prevention.
11. Command objects give request data shape, types, nullability, and defaults. Keep them permissive — empty strings and zeros are fine; the domain objects do the real checking.
12. Don't unit-test `fromRequestData()`; do unit-test the mapping helpers everything depends on.

## Connects To
- **Ch 2**: assertions inside entities, and the sidebar promising this chapter would cover talking back to users.
- **Ch 3**: getters-on-entities as a smell; read models designed for one use case; passing the read model to `addLine()`.
- **Ch 4 (§4.4)**: the command object, introduced there as a parameter object and given a second role here.
- **Ch 6**: `CouldNotFindEbook`-style custom exceptions as part of an interface's contract.
- **Ch 11**: entities, value objects, and application services in the pattern catalog.
- **Ch 12/13**: why the controller is the only place that knows who the user is.
- **Object Design Style Guide (Noback, Manning 2019)**: the full treatment of objects protecting their own state.
- **Symfony Validator / Form components**: a pragmatic alternative — accepting some "impure" setters if the time-to-value trade is worth it.
