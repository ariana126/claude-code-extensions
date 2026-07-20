# Chapter 2: The domain model

## Core Idea
Replace scattered SQL with an **Entity** that guarantees its own consistency and a **Repository** that hides how it's stored — and give the entity its identity at construction time, not after the database assigns one.

## Frameworks Introduced

- **Entity** — a stateful object that guarantees its own consistency and is going to be persisted. Entities by definition have an **identity** used to save and reconstitute them.
  - When to use: whenever data must be complete and correct before it reaches the database, and other modules (payment, fulfillment) will depend on it being valid.
  - How: make the constructor demand every required value at once, then run assertions on each before assigning. A client cannot produce a half-built or nonsensical entity.
  - Why it works: constructor arguments make the required data *unavoidable*; assertions make the invalid data *impossible*. Together they mean "if this object exists, it is valid."

- **Repository** — the object-saver. "Repository is the name of a design pattern which provides a solution to a common problem: the need to save a domain object, and later reconstitute it."
  - When to use: any time core code needs to persist or retrieve an entity.
  - How: define an interface taking/returning the entity type — `save(Order $order): void` and its symmetrical counterpart `getById(OrderId $id): Order`. Put the SQL in an implementation class. `getById()` throws a custom exception (e.g. `CouldNotFindOrder extends RuntimeException`) when nothing matches.

- **The "act as if it already exists" trick** — a design technique for discovering the interface you need.
  - When to use: you know what you want to do but not what object should do it.
  - How: write the call site as though the collaborator already existed (`$orderSaver->save($order);`), then read off the interface it implies. Name it after the pattern it turns out to be (`OrderSaver` → `OrderRepository`).

- **`nextIdentity()`** — the repository generates the ID, so the entity has one from birth.
  - When to use: always, in preference to auto-increment columns.
  - How: add `nextIdentity(): OrderId` to the repository interface. The client calls it *before* `new Order(...)` and passes the result as the first constructor argument. `save()` then returns `void`.
  - Why it works: an entity without an ID "isn't consistent until the database has finished saving it" — which contradicts the entity's whole purpose. It also frees you from persistence mechanisms that can't synchronously return a generated identifier.

- **Value object for the identifier** — wrap the ID's raw type so it becomes an internal detail.
  - When to use: as soon as an ID has a concrete type (`int`, `UuidInterface`) visible in signatures.
  - How: `OrderId` with a private constructor and a named static factory (`fromUuid()`, `fromString()`), plus `asString()` for serialization boundaries like the session.

- **The four ORM rules** — when using Doctrine or similar is acceptable.
  1. Only simple mapping configuration; no table inheritance, embeddables, or custom types.
  2. Stick to one-to-many associations.
  3. Reference entities by their ID.
  4. Don't jump from entity to entity using association fields.
  - "It's not a coincidence that these rules have much in common with the rules for effective aggregate design as described by Vaughn Vernon."

- **The four Active Record mitigation rules** — if AR is entrenched and the team is effective with it.
  1. Design AR entities like real entities.
  2. Don't use the same AR entity for changing state and retrieving state — separate write and read models.
  3. Don't navigate from one AR entity to another; fetch by ID from the repository.
  4. Ignore that the AR entity offers `save()`/`delete()`; go through a repository using **double dispatch**.

## Key Concepts
- **Entity** — stateful, has identity, guarantees its own consistency, gets persisted.
- **Value object** — immutable, no identity, defined by its value; `OrderId` is one.
- **Repository** — abstraction for saving and reconstituting entities.
- **Table Data Gateway** — one interface per database table hiding SQL; an intermediate step that only solves half the problem.
- **Data Mapper** — the entity is passive; a repository extracts its data and stores it.
- **Active Record** — the entity loads, saves, and deletes itself, usually by extending a framework base class.
- **Internal consistency** — the guarantee that an object's data is complete and meaningful.
- **Assertions** — guard functions (`Assertion::email()`, `Assertion::greaterThan()`) an object uses to protect *itself*; **not** for validating user input.
- **Double dispatch** — the repository delegates to the AR entity's own `save()`, keeping the call site clean.
- **`nextIdentity()`** — repository method returning the next available identifier.

## Mental Models
- **Think of the entity as the gatekeeper, not the data bag.** "When an object gets created, it can accept data as constructor arguments, analyze that data, and throw exceptions when any part of it doesn't look right."
- **Use "would I have to email the customer to fix this?" as the consistency bar.** If bad data could reach the database, the entity isn't protecting enough.
- **Assertions protect objects; validation talks to users.** These are different jobs with different mechanisms — `Assertion::email()` throwing an exception produces "Oops, an error occurred", not a friendly message next to the form field. (Ch 8 covers the alternatives.)
- **Prefer keeping the mapping inside the entity.** Both manual-mapping options have a downside; Noback picks the lesser one: "the ability to freely change the internal structure of an object is what enables you to improve its design." Exposing private property names to the repository is too high a price.
- **Column names in an entity do not make it infrastructure code.** Re-check the two rules: `mappedData()` needs no external system and no special context. Same for Doctrine annotations. You'll still have to edit it when switching databases — that's a known, accepted cost, not a rule violation.

## Anti-patterns
- **SQL statements in the controller**: obscures the scenario, mixes high-level steps with low-level details, and couples the use case to the storage technology.
- **Stopping at a Table Data Gateway**: table names and SQL are hidden, but column names and types stay in the controller. Still table-oriented, still stuck on a relational database, and still no protection of internal consistency.
- **Generic table-oriented interfaces**: `insert(string $tableName, array $data)` on something called `OrderRepository` — the name says domain, the signature says database. Nothing stops a garbage string landing in the `email` column.
- **Letting the database assign the ID**: `save()` returning `int` leaks that you use an auto-incrementing column, and leaves the entity inconsistent until after persistence.
- **Naive `nextIdentity()`** (`SELECT MAX(id) + 1`): fine under low concurrency, but two concurrent clients will collide. Escalate to a database sequence or a sequence table in a transaction.
- **Active Record for domain modelling**: inherits infrastructure and destroys unit-test isolation; requires framework-specific code inside the domain model; exposes far more operations to clients than they should have.

## Code Examples

The starting point — everything mixed together:

```php
public function orderEbookAction(Request $request): Response
{
    $connection = $this->container->get('connection');

    $ebookPrice = $connection->execute(
        'SELECT price FROM ebooks WHERE id = :id',
        ['id' => $request->request->get('ebook_id')]
    )->fetchColumn(0);

    $orderAmount = (int)$request->get('quantity') * (int)$ebookPrice;

    $record = [
        'email' => $request->get('email_address'),
        'quantity' => (int)$request->get('quantity'),
        'amount' => $orderAmount,
    ];
    // ... hand-built INSERT, then SELECT LAST_INSERT_ID()
}
```

The entity protecting itself:

```php
use Assert\Assertion;

final class Order
{
    public function __construct(
        int $ebookId,
        string $emailAddress,
        int $quantityOrdered,
        int $pricePerUnitInCents,
        int $orderAmountInCents
    ) {
        Assertion::greaterThan($ebookId, 0);
        Assertion::email($emailAddress);
        Assertion::greaterThan($quantityOrdered, 0);
        Assertion::greaterThan($pricePerUnitInCents, 0);
        Assertion::greaterThan($orderAmountInCents, 0);

        $this->ebookId = $ebookId;
        // ...
    }
}
```

The identifier as a value object:

```php
final class OrderId
{
    private UuidInterface $id;

    private function __construct(UuidInterface $id)
    {
        $this->id = $id;
    }

    public static function fromUuid(UuidInterface $id): self
    {
        return new self($id);
    }

    public function asString(): string
    {
        return $this->id->toString();
    }
}

final class SqlOrderRepository implements OrderRepository
{
    public function nextIdentity(): OrderId
    {
        return OrderId::fromUuid(Uuid::uuid4());
    }
}
```

- **What it demonstrates**: `Order`'s constructor takes an `OrderId`. Whether that's backed by an int, a UUID, or a ULID is now the repository's business alone.

A concurrency-safe `nextIdentity()` using a sequence table:

```php
public function nextIdentity(): int
{
    return $this->connection->transactional(function () {
        $nextId = (int)$this->connection->execute(
            'SELECT last_id FROM order_id_sequence'
        )->fetchColumn(0) + 1;

        $this->connection->execute(
            'UPDATE order_id_sequence SET last_id = :last_id',
            ['last_id' => $nextId]
        );

        return $nextId;
    });
}
```

## Reference Tables

**Data Mapper vs. Active Record**

| | Data Mapper (Entity + Repository) | Active Record |
|---|---|---|
| Who saves the entity | Repository | The entity itself |
| Unit-testable in isolation | Yes | No — inherits infrastructure |
| Framework coupling in domain | Minimal (mapping details only) | Direct; entity only works with the framework present |
| Client capability | Only what the entity exposes | "Many more things than they most likely should be allowed to do" |
| Extra elements | Repository interface + ≥1 implementation | None |
| Open design decision | Mapping inside or outside the entity | — |
| Core/infrastructure separation | Better | Worse |

**Where to put the mapping code**

| Option | Mechanism | Downside |
|---|---|---|
| Entity maps itself *(Noback's choice)* | `Order::mappedData(): array` | Entity knows column names; renaming a column edits the entity |
| Repository maps | `Order::internalData()` via `get_object_vars()` | Breaks encapsulation; repository knows every private property name and type |
| ORM maps | Doctrine annotations + reflection | "Magic"; hard to debug; problems surface in production |

## Worked Example

**The refactoring, end to end.** The chapter is one continuous transformation of `orderEbookAction()`. Following the sequence is the point.

**Step 0 — the mess.** ~30 lines: fetch the price with raw SQL, compute the amount, hand-build an `INSERT` from a `columns => values` array, then `SELECT LAST_INSERT_ID()` and stash it in the session. Three problems: the scenario is unreadable; implementation details bury the high-level steps; the use case is welded to both MySQL and the web form.

**Step 1 — table gateway (a half-measure).** Replace raw SQL with `$ordersGateway->insert([...])`. Shorter, no context-switching into SQL. But the column names and types are still in the controller, so you're still relational-database-shaped — and nothing prevents inserting a non-email into the `email` column. Noback keeps this step in the book specifically to show that hiding SQL is not the same as decoupling.

**Step 2 — the entity.** Introduce `Order` with a constructor demanding all five values, then assertions on each. Now bad data cannot exist. But this immediately *breaks* the gateway: the gateway wants `columns => values`, and the controller no longer has that array. **The two are incompatible** — and that incompatibility is the signal that the gateway was the wrong abstraction.

**Step 3 — imagine the repository.** Apply the trick: write `$lastInsertedId = $orderSaver->save($order);` as if it existed. Read off the interface. Recognize it as the Repository pattern and rename accordingly.

**Step 4 — one leak remains.** `save(Order $order): int` still announces "we use an auto-incrementing integer column." Worse, `Order` has no ID until after saving, so it's inconsistent at birth.

**Step 5 — invert it.** Add `nextIdentity()` to the repository. The controller now reads:

```php
$orderId = $orderRepository->nextIdentity();
$order = new Order($orderId, /* ... */);
$orderRepository->save($order);
```

`save()` drops to `void` — "as a bonus, this will make the `save()` method conform to the Command Query Separation principle."

**Step 6 — hide the ID's type.** Wrap the UUID in an `OrderId` value object. One thing breaks: the session can only store serializable values. Fix with `asString()` at that boundary — not by weakening `OrderId`.

**Result.** Every step of the scenario is visible, and none of it is tied to the database. The chapter's own checklist: (1) neither `Order` nor `OrderRepository` reveals anything about the calling client; (2) `OrderRepository` is an abstraction other core code can run against without a database; (3) `Order` is a plain PHP class runnable with no special setup. That's core code.

Two problems remain, deferred to Ch 4: the scenario steps are still mixed with low-level details, and the action only works in a web application driven by a form.

## Key Takeaways
1. A Table Data Gateway is not decoupling. It hides SQL while leaving column names, types, and relational thinking in your regular code — and it protects nothing.
2. Constructor arguments plus assertions are how an entity guarantees consistency. If the object exists, it's valid.
3. Assertions are self-protection, never user-input validation. Wiring `Assertion::email()` to a form field produces a generic error page (see Ch 8).
4. Generate identity **before** instantiating. Three independent reasons: the entity is incomplete without it; other processes might otherwise take the same identity; and relying on the database to generate it assumes a capability alternative persistence mechanisms may lack.
5. Wrap the ID in a value object so its underlying type stays an implementation detail of the repository.
6. `save()` should return `void` — this follows from generating identity upfront, and satisfies Command Query Separation for free.
7. Column names and ORM annotations inside an entity do **not** violate the two rules. Re-check them rather than reasoning from vibes. You'll pay to change them when switching databases; that's an accepted cost.
8. Prefer Data Mapper. If Active Record is entrenched and the team is effective with it, apply the four mitigation rules rather than fighting the framework — and read Ch 15 on over-engineering before deciding.

## Connects To
- **Ch 1**: the two rules are applied here to prove the refactored `Order` is core code.
- **Ch 3**: read models — the counterpart to this write-side model; also the fix for AR rule #2.
- **Ch 4**: application services — extracts the remaining scenario steps out of the controller.
- **Ch 8**: validation — the right way to talk back to users, as opposed to assertions.
- **Ch 11**: the design-pattern catalog, with entity and value object treated in depth (§11.2).
- **Ch 15**: over-engineering — when this whole approach is not worth it for your situation.
- **Effective Aggregate Design (Vaughn Vernon)**: the source of the ORM rules' underlying logic.
- **Command Query Separation**: satisfied by `save(): void`.
