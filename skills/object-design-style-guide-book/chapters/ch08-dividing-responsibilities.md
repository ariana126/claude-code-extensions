# Chapter 8: Dividing Responsibilities

## Core Idea
**Never hand an entity that can be modified to a client that shouldn't modify it.** Split each entity into a write model (commands only) and one or more read models purpose-built for specific use cases — then choose how to build those read models based on cost, not fashion.

## Frameworks Introduced

- **Separate write models from read models**: The write model keeps `place()`, `markAsReceived()`; the read model exposes only the data a specific client needs.
  - When to use: whenever some clients only *read* an entity while others *change* it.
  - Why it works: "Even if the client doesn't modify it today, one day it might, and then it will be hard to find out what happened."
  - Success signal: after extracting the read model, you can **delete the getters** from the write model and no write-model client breaks.
  - **Important qualification**: query methods are *not* forbidden on write models. A client that modifies an entity may legitimately need to read from it first to make a decision or validate. The rule targets clients that *only* read.

- **Create read models specific to their use cases**: One entity → many read models, each shaped for one screen or report.
  - The name carries the purpose: `PurchaseOrderForStockReport`, then `StockReport` itself. Other read models for the same entity might expose only ID + date for a listing, or just the fields a form needs.
  - Test of a good read model: **the client stops transforming it.** If the controller still loops and reshapes, the read model isn't matched to the use case yet.

- **Three ways to build a read model** (Noback presents these as a cost ladder, not a ranking):
  1. **From the write model** — the entity offers `forStockReport()`. Quick, but the client still touches the write model, so the original goal isn't met.
  2. **Directly from the data source** — one SQL query against `purchase_orders`. Efficient at runtime *and* in development/maintenance cost. **The default.**
  3. **From domain events** — a listener maintains its own `stock_report` table incrementally. Fastest queries, most expensive to build and operate.

## Key Concepts
- **Write model**: An entity exposing command methods; state changes go through it.
- **Read model**: A dedicated object exposing only information, built for one use case.
- **Read model repository**: Retrieves read models; separate from the write model's repository.
- **Domain event**: Recorded inside an entity on state change, dispatched after saving.
- **Event sourcing**: Reconstructing the *write* model from events too. Noback is explicit that it's **not required** — you can get the entire benefit of this chapter without it.

## Mental Models
- **"Sit next to the user with a piece of paper."** Noback's framing for event-driven read models: instead of re-summing every purchase order on each request, write down each receipt as it happens and keep a running total per product. Same answer, arrived at incrementally.
- **Repositories are the natural exception to CQS at the object level.** Save and retrieve are inverse operations, so one object holding both is fine. Most other services aren't like that.
- **Read models can be trivially reshaped; write models cannot.** That asymmetry is why you multiply read models freely and guard the write model jealously.

## Anti-patterns
- **Passing an entity to a template renderer or serializer**: it may be a write model today only by accident; the view can call anything on it.
- **A controller that loads all entities and reduces them in a loop**: both a design problem (write model exposed) and a performance one (loop over all purchase orders of all time).
- **Read models that clients still have to transform**: means the read model was shaped for the entity, not for the use case.
- **Reaching for event-sourced read models by default**: more moving parts, harder domain-event evolution, and failed listeners need tooling and re-running. Use option 2 unless you have a measured reason.

## Code Examples

The read model built directly from the data source — the recommended default:

```php
final class StockReportSqlRepository implements StockReportRepository
{
    public function getStockReport(): StockReport
    {
        result = this.connection.execute(
            'SELECT ' .
            '  product_id, ' .
            '  SUM(ordered_quantity) as quantity_in_stock ' .
            'FROM purchase_orders ' .
            'WHERE was_received = 1 ' .
            'GROUP BY product_id'
        );
        return new StockReport(result.fetchAll());
    }
}

final class StockReportController
{
    private StockReportRepository repository;
    public function __construct(StockReportRepository repository) {
        this.repository = repository;                 // no PurchaseOrderRepository anywhere
    }

    public function execute(Request request): Response {
        stockReport = this.repository.getStockReport();
        return new JsonResponse(stockReport.asArray());
    }
}
```
- **What it demonstrates**: The controller no longer knows the write model exists. No loop, no transformation, no `findAll()`.

The write model after extraction — notice how little is left:

```php
final class PurchaseOrder
{
    private int purchaseOrderId;
    private int productId;
    private int orderedQuantity;
    private bool wasReceived;

    private function __construct() {}

    public static function place(
        int purchaseOrderId, int productId, int orderedQuantity
    ): PurchaseOrder {
        purchaseOrder = new PurchaseOrder();
        purchaseOrder.productId = productId;
        purchaseOrder.orderedQuantity = orderedQuantity;
        return purchaseOrder;
    }

    public function markAsReceived(): void { this.wasReceived = true; }
    // productId(), orderedQuantity(), wasReceived() — all deleted
}
```

## Reference Tables

**Choosing how to build a read model:**

| Approach | Runtime cost | Dev/maintenance cost | Use when |
|---|---|---|---|
| From the write model (`forStockReport()`) | High — loads all entities | Low | A stopgap; client still sees the write model |
| **Direct from the data source (SQL)** | Low | **Low** | **Default.** Write model is stable and raw data is usable as-is |
| From domain events | Lowest — precomputed | High | Recomputation is genuinely too expensive |

Option 2 gets worse when the write model **changes often**, or the raw data **needs interpretation before use** — those are the conditions that push you to option 3.

| Object in a client | Which model? |
|---|---|
| `salesInvoice.wasCancelled()` then `salesInvoice.finalize()` | **Write** — it modifies, even though it also reads |
| `meetup` passed to a template renderer | **Read** — in theory it could be a write model, but it really shouldn't be |

## Worked Example

**The stock report, four stages** — the chapter in one arc.

```php
// Stage 0 — controller loads every entity and reduces in a loop.
// Write model fully exposed; O(all purchase orders ever) per request.
public function execute(Request request): Response
{
    allPurchaseOrders = this.repository.findAll();
    stockReport = [];
    foreach (allPurchaseOrders as purchaseOrder) {
        if (!purchaseOrder.wasReceived()) { continue; }
        if (!isset(stockReport[purchaseOrder.productId()])) {
            stockReport[purchaseOrder.productId()] = 0;
        }
        stockReport[purchaseOrder.productId()] += purchaseOrder.orderedQuantity();
    }
    return new JsonResponse(stockReport);
}

// Stage 1 — extract a read model. The entity's getters can now be deleted,
// but the controller still loads write models and maps over them.
final class PurchaseOrderForStockReport {
    public function __construct(int productId, int orderedQuantity, bool wasReceived) { /* ... */ }
    public function productId(): ProductId { return this.productId; }
    public function orderedQuantity(): int { return this.orderedQuantity; }
    public function wasReceived(): bool { return this.wasReceived; }
}

// Stage 2 — a read model shaped for the USE CASE, with its own repository.
// See the StockReportSqlRepository above. Controller is three lines.

// Stage 3 — build it from events instead of recomputing per request.
final class PurchaseOrderReceived {
    public function __construct(int purchaseOrderId, int productId, int receivedQuantity) { /* ... */ }
    public function productId(): int { return this.productId; }
    public function receivedQuantity(): int { return this.receivedQuantity; }
}

final class PurchaseOrder {
    private array events = [];
    public function markAsReceived(): void {
        this.wasReceived = true;
        this.events[] = new PurchaseOrderReceived(
            this.purchaseOrderId, this.productId, this.orderedQuantity
        );
    }
    public function recordedEvents(): array { return this.events; }
}

final class ReceiveItems {
    public function receiveItems(int purchaseOrderId): void {
        // ...
        this.repository.save(purchaseOrder);
        this.eventDispatcher.dispatchAll(purchaseOrder.recordedEvents());
    }
}

final class UpdateStockReport {
    public function whenPurchaseOrderReceived(PurchaseOrderReceived event): void {
        // SELECT ... FOR UPDATE, then UPDATE stock_report SET quantity_in_stock =
        // quantity_in_stock + :quantityReceived, or INSERT if no row exists.
    }
}

// The query collapses to:
'SELECT * FROM stock_report'
```

**The reasoning behind stage 3**, worked as a table transformation:

| product_id | ordered_quantity (raw rows) | | product_id | received (running total) |
|---|---|---|---|---|
| 123 | 2 | | 123 | 2 + 8 = 10 |
| 124 | 4 | → | 124 | 4 + 1 = 5 |
| 124 | 1 | | | |
| 123 | 8 | | | |

Same numbers as `SUM(...) GROUP BY product_id` — but computed once at write time instead of on every read.

## Key Takeaways
1. Never give a modifiable entity to a client that only reads. Extract a read model.
2. After extraction, delete the write model's getters — if nothing breaks, the split was correct.
3. Query methods on write models remain fine; the rule is about read-*only* clients.
4. Build one read model per use case, named for that use case. If the client still reshapes it, it isn't done.
5. Default to building read models directly from the data source — cheapest in both runtime and maintenance.
6. Escalate to event-built read models only when the write model changes often, the raw data needs interpretation, or recomputation is genuinely too expensive.
7. Event sourcing is a separate, larger commitment. You get all of this chapter's benefits without it.
8. Name domain events in the domain's language, and don't create redundant ones — `CartWasCreated` is already implied by `ProductWasAddedToCart`.

## Connects To
- **Ch 4 §4.12**: internally recorded events, introduced for testing, become the read-model mechanism here
- **Ch 6**: read models are the structural answer to "avoid query methods that expose internal state"
- **Ch 7 §7.2**: event dispatching as the decoupling mechanism
- **Ch 10**: read models and read model repositories get their place in the object field guide
- **CQRS**: this chapter is CQRS at the object level, deliberately without event sourcing
