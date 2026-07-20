# Chapter 3: Read models and view models

## Core Idea
Never load an entity just to read data from it. Introduce a **read model** — a dedicated, immutable object shaped around one client's question — and when that data is destined for a user or external system, a **view model** that returns only formatted primitives.

## Frameworks Introduced

- **Write model / read model separation** — "A client that needs an object for getting information from (reading) should not retrieve the same object as clients that want to make changes to it (writing)."
  - When to use: any time you catch yourself calling `getById()` with no intention of changing or saving the result.
  - How: leave the entity untouched, create a new immutable class (often with the same name in a different namespace) exposing only what this client needs.
  - Why it works: reusing an entity for queries hands the client every state-changing method it has (`changePrice()`, `hide()`), and pulls the entity toward serving too many roles — which is exactly how legacy code is created.

- **The three elements of a decoupled query** — the structural pattern that emerges every time.
  1. An **interface** representing the question.
  2. A **class** representing the answer.
  3. An **implementation** of the interface that can run in production.
  - When to use: whenever you decouple a query from its infrastructure.

- **The CLI thought experiment** — Noback's test for whether something *deserves* to be core code.
  - When to use: deciding whether a controller's functionality needs decoupling at all.
  - How: "What if we would still be running the same business… except from now on people will have to use the command-line?" **Should the application still provide this functionality?**
    - **No** → the functionality was justifiably tied to the infrastructure. Leave it.
    - **Yes** → it must be decoupled and represented in core code.
  - Worked on "list available e-books": of course a CLI shopper still needs to see what's for sale. So listing e-books "deserves to be more than just a controller with a database query."

- **Designing a read model** — "You frame the question in such a way that it's easy for you to ask, and you design the type of answer you want to retrieve."
  - Two modeling options:
    - **Pseudo-entity + repository** (`EbookRepository::getById(): Ebook`) — use when you need more than one piece of information, or expect to soon.
    - **Direct query method** (`GetPrice::ofEbook(EbookId): int`) — use when you need exactly one piece of information. Reads more naturally at the call site.

- **View model** — a read model whose data crosses the application boundary to users or external systems.
  - When to use: rendering templates, JSON APIs, CLI output, SOAP responses.
  - How: derive the getters **from the template that consumes them**. Return only **primitive types** — mostly `string`, since "rendering the template itself is basically an exercise in string concatenation."
  - Do the formatting (currency signs, decimal precision) *inside* the view model, not in the template — otherwise the logic can't be reused by a CLI or API client.

- **The four ways to limit class proliferation** (with their costs):
  1. Only introduce an interface for objects that actually talk to something outside the application. → *Cost: harder to substitute a test double; usually easy to re-introduce the interface later.*
  2. Combine multiple methods in a single interface. → *Cost: clients gain access to unrelated methods, blurring their purpose and adding dependencies.*
  3. Let one class implement multiple interfaces. → *Cost: unrelated dependencies and knowledge get entangled. Mitigate by only combining truly related interfaces.*
  4. Reuse the "answer" class across queries. → *Cost: more clients means harder to change safely.*

## Key Concepts
- **Read model** — an immutable object specialized in providing information; comes with its own repository interface and implementation.
- **Internal read model** — data used only by the application itself, never shown to a user (e.g. the price used to compute an order amount).
- **View model** — a read model whose data travels across application boundaries to actual users or external systems.
- **Domain event** — an object recorded by an entity when its state changes in a way others may care about (`PriceChanged`).
- **Immutable object** — read-only; clients cannot accidentally change its state.
- **Design tension** — the strain that appears when one object serves two clients with different needs; watch for it and split.
- **Resistant to change** — an object with so many roles and clients that nobody can safely modify it. A bad quality.
- **Value object in a read model** — hides the underlying primitive type so clients don't break when it changes.

## Mental Models
- **A getter on an entity is a smell, not a sin.** "Adding a getter to an entity is often a sign that you've loaded the entity just to get data from it." Consider a read model first — but getters "certainly aren't forbidden." You'll usually need one for the ID and one for recorded events.
- **Updating a read model is *reflecting* a change, not making one.** "The change on the entity is the real change." The read model merely mirrors it.
- **The read model repository interface says: "I have a particular need, but I don't care how you'll fulfill it."** Whether the implementation reads the write model's table, subscribes to events, or queries Elasticsearch is invisible to core code.
- **Design the read model backwards, from its client.** For the internal read model, look at how the price gets used (multiplied by quantity → give `Price` a `multipliedBy()` method). For the view model, look at the Twig template (`{{ ebook.price }}` → `price(): string`, pre-formatted).
- **Reuse is unavoidable; unexamined reuse is the problem.** "Without any reuse, it would be really hard to accomplish anything at all… But at least keep track of the intended use of objects, and watch for tension in the design."

## Anti-patterns
- **Reusing the write-model entity to answer queries**: exposes every state-changing method to a client that only wanted one field, and drags the entity toward too many roles.
- **Adding a getter to an entity to make it queryable**: the tell that a read model is missing. (Alternative shown in the chapter: pass the collaborator *into* the entity method — `$vatReturn->rollBack($bookingPeriods)` — instead of exposing internal state to the caller.)
- **Sharing a data source without shared interpretation**: if the write model switches `price` from cents-as-int to decimal, a read model casting to `int` turns €1.50 into 1 cent. Mitigate with integration tests, or by having one class implement both repository interfaces so column meaning lives in one place.
- **Formatting in the template**: `{{ ebook.price|number_format }}` makes the view model non-portable. A CLI client can't reuse HTML template logic.
- **Leaking domain objects into templates**: "Templates in particular shouldn't need to know anything about the domain objects that our application uses internally." Return primitives only.
- **A value object that only wraps and unwraps**: "If we don't even validate the raw value, we might as well not use a value object in the first place." Give it behavior.
- **Building JSON by hand in the controller**: loop-and-map boilerplate. Make the view model serializable in one step instead.

## Code Examples

Two ways to model the same question:

```php
// Option A — pseudo-entity + repository (use when you need several fields)
interface EbookRepository
{
    /** @throws CouldNotFindEbook */
    public function getById(EbookId $ebookId): Ebook;
}

// Option B — direct query method (use when you need exactly one thing)
interface GetPrice
{
    /** @throws CouldNotFindEbook */
    public function ofEbook(EbookId $ebookId): int;
}

$ebookPrice = $this->getPrice->ofEbook(
    EbookId::fromString($request->request->get('ebook_id'))
);
```

Keeping the read model in sync via domain events:

```php
final class Ebook   // the entity
{
    private array $events;

    public function changePrice(int $newPrice): void
    {
        $this->price = $newPrice;
        // When state changes, we additionally "record" a domain event
        $this->events[] = new PriceChanged($this->ebookId, $newPrice);
    }

    public function recordedEvents(): array
    {
        return $this->events;
    }
}

$ebook->changePrice(150);
$this->ebookRepository->save($ebook);
$this->eventDispatcher->dispatchAll($ebook->recordedEvents());

final class UpdateEbookReadModel
{
    public function whenPriceChanged(PriceChanged $event): void
    {
        $readModel = $this->readModelRepository->getById($event->ebookId());
        $readModel->setPrice($event->newPrice());
        $this->readModelRepository->save($readModel);
    }
}
```

A value object earning its keep — behavior, not just wrapping:

```php
final class Price
{
    private int $priceInCents;

    private function __construct(int $priceInCents)
    {
        $this->priceInCents = $priceInCents;
    }

    public static function fromInt(int $priceInCents): self
    {
        return new self($priceInCents);
    }

    public function multipliedBy(int $quantity): int
    {
        return $this->priceInCents * $quantity;
    }
}

// Client no longer unwraps the primitive:
$orderAmountInCents = $ebook->price()->multipliedBy(
    (int)$request->get('quantity')
);
```

- **What it demonstrates**: the first version forced `$ebook->price()->asInt()` at the call site. Adding `multipliedBy()` moves the arithmetic inside, so clients never touch the raw integer — and a change of underlying type breaks nothing.

The view model, shaped by its template and hiding formatting:

```php
final class Ebook   // the view model — not the entity, not the read model
{
    private int $price;

    public function ebookId(): string { /* ... */ }
    public function title(): string { /* ... */ }
    public function numberOfTimesSold(): int { /* ... */ }

    public function price(): string
    {
        // Price is used as an internal implementation detail; it never escapes
        return Price::fromInt($this->price)->asFormattedAmount();
    }
}
```

## Reference Tables

**The three models compared**

| | Entity (write model) | Read model (internal) | View model |
|---|---|---|---|
| Purpose | Change state | Provide information to the app | Show information to users/systems |
| Mutable | Yes | No (immutable) | No (immutable) |
| Returns value objects | Yes | Yes | **No** — primitives only |
| Crosses app boundary | No | No | Yes |
| Shaped by | The domain | The calling code's use case | The template / API response |
| Has identity | Yes | — | — |

**Keeping read and write models in sync**

| Approach | How | Risk |
|---|---|---|
| Shared data source | Read model repository queries the same table | The two may interpret columns differently (cents vs. decimal). Mitigate: integration tests, or one class implementing both interfaces |
| Domain events | Entity records events; a subscriber updates the read model | More moving parts; synchronization "can be a complicated business" |

**Making a view model API-serializable**

| Option | Mechanism | Note |
|---|---|---|
| Build arrays in the controller | Manual `foreach` | Most work for the client; avoid |
| `asArray()` on the view model | `json_encode(array_map(...))` | Good middle ground |
| Public properties | `json_encode($viewModels)` directly | Simplest; PHP can't enforce immutability at runtime — use a static analyzer like Psalm |

## Worked Example

**Two refactorings in one chapter, and they end differently.**

**Refactoring 1 — the internal read model.** One SQL query remains in `orderEbookAction()`: fetch an e-book's price.

The obvious fix is to reuse the existing `Ebook` entity — just add `getPrice()`. It works, and it's tempting. Noback rejects it on two grounds. First, the controller now holds an object carrying `changePrice()` and `hide()` when it only wanted a number: "It's generally a smart idea to limit the number of methods that a client of an object has access to." Second, and more corrosive: an object serving two clients accumulates methods for both, grows, entangles, and becomes *resistant to change* — "you probably recognize this chain of events: it's how legacy code is created."

So: leave the entity alone, build a separate immutable `Ebook` read model in its own namespace, with only `price()`.

Then design *for the client*. The controller does `price * quantity`, assuming an int in cents — an assumption that shatters if the column becomes a decimal. Wrap it in a `Price` value object. But a wrapper with just `fromInt()`/`asInt()` is pointless. Give it `multipliedBy()` so the caller never handles the primitive at all.

**Refactoring 2 — the view model.** `listEbooksAction()` has a heredoc SQL query with a correlated subquery for `number_of_times_sold`, feeding records straight into a Twig template.

First run the CLI thought experiment: *would a command-line e-book shop still need to list available e-books?* Obviously yes — "how would they figure out which e-book to buy if they don't even know which e-books we sell?" So it must be decoupled.

Apply the three-element pattern: interface `Ebooks::listAvailableEbooks(): array`, answer class `Ebook` (a *third* class of that name — entity, read model, view model), implementation `EbooksUsingSql` reusing the existing query.

Now the key design decision. Read the Twig template to derive the getters: `ebook.title`, `ebook.numberOfTimesSold`, `ebook.price`, `ebook.ebookId`. Note `price()` returns **`string`**, not the `Price` value object from refactoring 1 — a pre-formatted amount with currency sign and decimal precision.

Why the inconsistency? Because a CLI shop "would still want to show the e-book's price, and we wouldn't want to rewrite the logic for price formatting in a place where we can't use HTML templates." Formatting in the template makes it unportable. So `Price` still appears — but only *inside* `price()`, as an intermediate type that "will never escape the view model object, so it remains an implementation detail."

**The rule that falls out**: read models return value objects; view models return primitives. Same underlying data, different contracts, because they have different clients.

## Key Takeaways
1. A getter appearing on an entity is the signal to introduce a read model — you loaded the entity only to read from it.
2. Every decoupled query yields three elements: a query interface, an answer class, and an implementation. Expect the class count to grow; that's the cost of decoupling.
3. Use the CLI thought experiment to decide whether something belongs in core code. If a command-line version of the business still needs it, decouple it.
4. Design read models **backwards from their client** — the calling code for internal read models, the template or API response for view models.
5. Read models return value objects. View models return primitives (mostly `string`), with all formatting done inside them so any client can reuse it.
6. Sharing a data source between write and read models is convenient but risks divergent interpretation of columns. Integration tests, or one class implementing both interfaces, reduce that risk.
7. The event-based approach needs three things: an entity, a domain event per relevant state change, and a subscriber that updates the read model. Note that syncing via events is genuinely hard — see Vernon's "Integrating bounded contexts" and Udi Dahan.
8. When trimming class count, know which cost you're accepting. Every one of the four reduction techniques trades something away.
9. A read model must "support the use case of its clients instead of serving some generic purpose." That, not the sync mechanism, is the real requirement.

## Connects To
- **Ch 2**: the entity/repository refactoring this chapter deliberately does *not* repeat; also the source of the value-object trick (§2.7) reused here for `Price`.
- **Ch 2 (§2.8)**: read models are the fix for Active Record mitigation rule #2 — never use one AR entity for both reading and writing.
- **Ch 4**: application services — removes the remaining orchestration from the controller.
- **Ch 11 (§11.5)**: event dispatching and subscribing, deferred from §3.3.2.
- **CQRS**: this chapter is the pattern's practical core; see Greg Young's "CQRS Documents".
- **Mathias Verraes, "Patterns for Decoupling in Distributed Systems: Summary Event"**: the event-sync approach.
- **Vaughn Vernon, "Implementing Domain-Driven Design"**: "Integrating bounded contexts" for write/read synchronization.
