# Chapter 15: Event-Driven Architecture Style

## Core Idea
A distributed, asynchronous style of **decoupled event processors** that react to things that *have already happened* — buying enormous performance, scalability, fault tolerance, and evolvability at the cost of determinism, testability, and error handling.

The authors insist EDA is an architecture **style**, not merely a pattern: they have built entire systems relying solely on it. It can also embed within other styles (event-driven microservices).

## Topology

**Four primary components**: an **initiating event**, an **event broker**, an **event processor** (usually just called a *service*), and a **derived event**.

- The **initiating event** starts the entire event flow — simple (placing a bid) or complex (updating a health-benefits system when an employee marries). It goes to an event channel in the broker.
- A single **event processor** accepts the initiating event, performs its specific task, then **asynchronously advertises what it did** by triggering a **derived event**. Other processors respond, do their work, and advertise via new derived events — **continuing until all event processors are idle and all derived events have been processed**.
- The **event broker** is usually **federated** — multiple domain-based clustered instances, each containing all the event channels (queues, topics) used in that domain's **event flow** (the entire workflow for processing the event). Because of the decoupled, asynchronous, fire-and-forget broadcast nature, the broker topology uses **topics**, **topic exchanges** (AMQP), or **streams** with publish-and-subscribe.

**The relay race model**: runners hold a baton, run their leg, and hand off. Once a runner hands off the baton, **that runner is done and can move on to other things**. Same with event processors — after handing off an event they are no longer involved and are free to react to other events. Each can also **scale independently** to handle varying load or backups.

- **Partitioning**: primarily **technically partitioned** — any domain is spread across multiple event processors and tied together through brokers, contracts, and topics. Changes to a domain usually impact multiple processors and messaging artifacts.
- **Quanta**: **one to many**. Even with asynchronous communication, event processors sharing a single database instance are in the same quantum; **request-reply processing also merges quanta**, because if processor A must wait for an order ID from processor B, and B is down, A cannot continue.

## Frameworks Introduced

- **Request-based vs. Event-based models**:
  - **Request-based**: a **request orchestrator** (typically a UI, but also an API layer, orchestration services, event hubs, an event bus, or an integration hub) directs requests **deterministically and synchronously** to **request processors**. "Show me my order history for the past six months" is a data-driven, deterministic request within a specific context.
  - **Event-based**: reacts to an event by taking action. Submitting an auction bid isn't a *request*; it's an **event that happened** after the current asking price was announced, and the system must respond by comparing it against simultaneous bids to determine the highest bidder.
  - **Choose request-based** for well-structured, data-driven requests where **certainty and control over the workflow** are the priority. **Choose event-based** for flexible, action-based events needing high responsiveness and scale with complex, dynamic user processing.

- **Events vs. Messages** — four distinguishing dimensions:

  | | **Event** | **Message** |
  |---|---|---|
  | Semantics | Something that **has already happened** ("I just placed an order") | A **command or query** — something that **needs to be done** ("apply the payment for this order") |
  | Response | Typically requires **no response** | Usually requires one |
  | Targeting | Broadcast to **multiple** processors | Almost always directed to **one** |
  | Channel | **Topic**, **stream**, or notification service (publish-subscribe, one-to-many) | **Queue** or messaging service (point-to-point, one-to-one) |

  **Test yourself**:
  - *"Adventurous Air Flight 6557, turn left, heading 230 degrees."* → **Message** — a command, directed at one target (the pilot), even though other pilots may hear it.
  - *"In other news, a cold front has moved into the area."* → **Event** — broadcast, already happened, no reply expected.
  - *"OK, class, turn to page 145 in your workbooks."* → **Message** — this is the tricky one. It's broadcast to many students, but it is a **command**, not something that has happened. **Broadcasting a command through a publish-and-subscribe channel does not turn it into an event.**
  - *"Hi, everyone! Sorry I'm late for the meeting."* → **Event** — already happened, broadcast, no response expected.

- **Extensible derived events** — it's good practice for **each event processor to advertise what it has done, regardless of whether anyone cares.** When nobody listens, the event still provides **architectural extensibility**: a built-in hook. The `Notification` processor emits `email sent` that nobody consumes; if the business later decides to analyze all customer emails, an `Email Analyzer` processor is added **with minimal effort and no changes to other event processors** — the data is already flowing.

- **Event Payload — two types on a spectrum**:

  **Table 15-1. Data-based versus key-based event payloads**

  | Criteria | Data-based payloads | Key-based payloads |
  |---|---|---|
  | Performance and scalability | **Good** | Bad |
  | Contract management | Bad | **Good** |
  | Stamp coupling | Bad | **Good** |
  | Bandwidth utilization | Bad | **Good** |
  | Restricted database access | **Good** | Bad |
  | Overall system fragility | Bad | **Good** |

  - **Data-based** — sends all information needed for processing. `order_placed` carries all 45 order attributes (500 KB). Downstream processors never query the database, which is the biggest advantage: *the less an event processor queries the database, the better its performance, responsiveness, and scalability.* Also guarantees every responder has what it needs — critical since the producer often doesn't know who is responding, and responders may not even have database access under strict bounded contexts.
    - *Disadvantages*: **multiple systems of record** make data consistency hard. If a customer orders 100 items, immediately corrects it to 1, the database (the single system of record) has the correct value but in-flight events carry the old one — **and EDA makes event timing very difficult to control, so newer values may be processed before older ones**, overlaying correct data with stale data. Plus **contract management and versioning** (JSON or XML? strict schema or loose name-value pairs? vendor MIME types in headers for versioning?) — all of which form tight *static* coupling and require strong governance.
  - **Key-based** — contains only a key identifying the context: `{ "order_id": "123" }`. Responders must query the database.
    - *Advantages*: **single system of record** → better data consistency and integrity; handles mid-processing data changes far better. The contract is so simple and rarely changes that loose schema-less JSON/XML suffices — no versioning, communication, or deprecation problems. **No stamp coupling and no bandwidth issues**; contracts are small and perform faster from a network and broker perspective.
    - *Disadvantages*: every responder queries the database, which **can overwhelm it in a highly parallel asynchronous architecture**, and fails outright when the data lies in another processor's bounded context.
  - **The trade-off in one line**: *scalability and performance versus contract management and bandwidth utilization.* It is **not all-or-nothing — each event type can use a different payload type.**

- **Anemic events** — a derived event whose payload lacks the information needed for the processor to make decisions or provide context for downstream processing.
  - Example: a customer updates their profile; `Customer Profile` triggers `profile_updated` with only the customer ID. `Service 1` has no idea *what* changed (name? address? something critical?) — **and querying the database can't answer that**. `Service 2` doesn't know if it needs to act. `Service 3` doesn't know the **prior values** and therefore can't process at all.
  - **The fix**: include the updated customer information **as well as the prior values**, since most databases don't retain them.
  - This sits between the extremes: key-only on the far left (fine for creating or deleting an order, poor for updates), all-data on the far right (where stamp coupling appears).

- **Stamp coupling** — several event processors share a common data structure but each uses only parts of it. `Order Placement` sends 45 attributes at 500 KB; `Inventory` needs only `item_id` and `quantity` — **30 bytes**. Removing an address-line attribute affects `Inventory` **even though it doesn't care about that field**.
  - **The bandwidth cost is the overlooked one** (Fallacy #3, and in most cloud environments bandwidth is what costs so much): at 500 orders/second, a 500 KB event uses **250,000 KB/s**; sending only the 30 bytes needed uses **15 KB/s**.
  - **Consumer-driven contracts** (each consumer has its own contract with only the data it needs) would help — but **EDA's broadcast nature means the system can't always know which processors will respond**, making them difficult to use here.

- **The Workflow Event pattern** (reactive architecture) — the answer to asynchronous error handling, addressing **both resiliency and responsiveness**. It leverages **delegation, containment, and repair** via a **workflow delegate**:
  1. The event consumer hits an error and **immediately delegates it to the `Workflow Processor` service, then moves to the next message.** *This is the key move* — if the consumer spent time diagnosing, it would delay not just the next message but every message waiting in the queue.
  2. The workflow processor inspects the message — looking for a static deterministic error, or analyzing it with machine-learning/AI algorithms for anomalies — and **programmatically (without human intervention)** repairs the data, then sends it back to the originating queue. The consumer sees it as a new message and retries.
  3. When it *can't* determine the problem, it sends the message to another queue feeding a **dashboard on a knowledgeable person's desktop**, who applies manual fixes and resubmits to the original queue (usually via a `reply-to` message header).
  - **Consequence**: repaired messages are **processed out of sequence** (see worked example for the mitigation).

- **Preventing data loss** — three failure points and their fixes:

  | Where loss occurs | Fix |
  |---|---|
  | Processor A crashes before the broker acknowledges, or the broker acknowledges then crashes before another processor accepts | **Persistent message queues** (guaranteed delivery — the broker stores the event in memory *and* persists it to a filesystem or database) + **synchronous send** (a blocking wait that stops the processor from triggering the event until the broker acknowledges persistence) |
  | Processor B accepts the event, then crashes before processing it | **Client acknowledge mode**. By default (**auto acknowledge**) an event is removed from the queue the moment it's read. Client acknowledge keeps it in the queue and attaches the client ID so no other consumer can read it |
  | Processor B can't persist to the database due to a data error | **ACID transactions via database commit**, plus **last participant support (LPS)**, which removes the event from the persisted queue only by acknowledging that all processing completed and the event was persisted |

  - **Channel implementations**: **AMQP** (Amazon SNS, RabbitMQ, Solace, Azure Event Hubs) — events published to an **exchange**, which uses consumer binding rules to forward to a queue per subscriber. **Jakarta Messaging** (formerly JMS) — uses **topics** rather than the two-step forwarding, and can still use the **Event Forwarding** pattern provided responders are configured as **durable subscribers** (guaranteed to receive an event; if down, the topic stores it until they return). **Kafka** event streaming uses very different techniques.

- **Request-Reply Processing** (a.k.a. **pseudosynchronous communications**) — for when a processor needs information back immediately. Each event channel consists of **two queues**: a request queue and a reply queue.

  | Technique | How it works | Verdict |
  |---|---|---|
  | **Correlation ID (CID)** | Producer sends to the request queue and records the message ID (124), CID `null`. Producer does a blocking wait on the reply queue with a **message selector** (`CID == 124`) — messages 855/CID 120 and 856/CID 122 are ignored. Consumer processes, creates a reply with `CID = 124`, sends as message 857. Producer receives it because the CID matches | **Recommended** |
  | **Temporary queue** | Producer creates a temporary queue (or the broker does) and passes its name in the `reply-to` header. Blocking wait with **no message selector needed** — any message there belongs solely to that producer. Consumer replies to the named queue; producer receives and **deletes the temporary queue** | Much simpler, **but** the broker must create and immediately delete a queue per request, which **significantly slows the broker** and hurts performance and responsiveness at large message volumes and high concurrency |

- **Mediated (orchestrated) EDA — the mediator topology.** Everything above is **choreographed** EDA. When the architect wants more control:
  - **Components**: an initiating event, an event queue, an **event mediator**, event channels, and event processors.
  - **It typically uses *messages*, not events** — commands like `ship_order` rather than facts like `order_shipped`.
  - The mediator accepts the initiating event, **knows the steps involved**, generates derived messages, and sends them to dedicated channels (usually queues) **point-to-point**. Processors respond to the mediator when done, and **do not advertise their work to the rest of the system.**
  - **Use multiple mediators**, each associated with a domain or grouping of events — this **avoids a single point of failure** and increases throughput and performance (a customer mediator for registrations and profile updates, an order mediator for cart and checkout).
  - **Choosing a mediator implementation**:

    | Complexity | Tool | Notes |
    |---|---|---|
    | Simple error handling and orchestration | **Apache Camel**, **Mule ESB**, **Spring Integration** | Flows and routes custom-written in Java or C# |
    | Lots of conditional processing, multiple dynamic paths, complex error handling | **Apache ODE**, **Oracle BPEL Process Manager** | Based on **BPEL** — an XML-like structure describing processing steps, with structured elements for error handling, redirection, multicasting. Powerful but complex to learn; architects usually use the GUI tools in the BPEL engine suite |
    | Long-running transactions requiring **human intervention** | **BPM engine** (e.g. **jBPM**) | BPEL does *not* work well here — e.g. a `place_trade` event that must halt, notify a senior trader for manual approval over a share threshold, and wait |

  - **The mediator delegation model**: classify events as **simple, hard, or complex** and send *every* event through a simple mediator (Camel, Mule). It either handles the event itself or forwards it to a more complex mediator (BPEL, BPM) based on classification. *Using Camel for complex long-running human-interaction events would be extremely difficult to maintain; using a BPM engine for simple flows would waste months on something Camel does in days.*
  - **Mediator advantages**: knowledge of and control over the workflow; maintains event state; manages error handling, recoverability, and restart. If payment fails on an expired card, the mediator knows order fulfillment (step 3) can't proceed, **stops the workflow, records state in its own persistent datastore, and restarts from step 3 once payment is applied.**
  - **Mediator disadvantages**: it is **very difficult to declaratively model dynamic processing** in a complex event flow — so many implementations use a **hybrid** of mediator and choreographed topologies for the dynamic parts (out-of-stock conditions, atypical errors). **The mediator must scale too**, occasionally becoming a bottleneck. Processors are **less decoupled** than in choreography, and **performance is lower**.
  - **The trade-off in one line**: *workflow control and error handling capability versus high performance and scalability.*

## Reference Tables

**Characteristics ratings**

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Evolvability** | ★★★★★ | Adding features via new or existing processors is straightforward; derived events provide hooks, so no infrastructure or existing-processor changes are needed |
| **Performance** | ★★★★ | Asynchronous communication combined with highly parallel processing |
| **Scalability** | ★★★★ | Programmatic load balancing of event processors (**competing consumers**, **consumer groups**) — add processors as load increases. Four rather than five **because of the database** (see space-based, Ch 16, for the five-star version) |
| **Fault tolerance** | ★★★★ | Decoupled asynchronous processors give eventual consistency; if downstream processors are unavailable and no immediate response is needed, the event is processed later |
| **Simplicity** | ★★ | Nondeterministic, dynamic event flows |
| **Testability** | ★★ | Same — see below |

**Table 15-2. Trade-offs of the event-driven model**

| Advantages over request-based | Trade-offs |
|---|---|
| Better response to dynamic user content | Only supports eventual consistency |
| Better scalability and elasticity | Less control over processing flow |
| Better agility and change management | Less certainty over outcome of event flow |
| Better adaptability and extensibility | Difficult to test and debug |
| Better responsiveness and performance | |
| Better real-time decision making | |
| Better reaction to situational awareness | |

**Database topologies**

| Topology | How | Advantages | Disadvantages |
|---|---|---|---|
| **Monolithic** | All data in one central database, available to all processors | **Any processor queries directly without synchronously communicating with other processors** — a significant advantage in a style built on decoupling | Fault tolerance (database down = all processors unavailable) · scalability (the *database* must scale to meet all processors' concurrent load, which many can't at high concurrency) · change control (a dropped column forces multiple processors to coordinate) · **necessarily a single architecture quantum** |
| **Domain** | Processors grouped into domains, each domain owning a database | Better fault tolerance, scalability, and change control from domain partitioning. If the order-processing database dies, order placement still accepts orders — **the event channel acts as a backpressure point, queuing events until the database returns** | Cross-domain data requires **synchronous** calls (Order Placement can query its own domain for inventory but must synchronously call Order Shipping for shipping options) |
| **Dedicated** (database-per-service) | Each processor owns its own database in a tightly formed bounded context | **Highest** fault tolerance, scalability, and change control. An outage is isolated to one processor; databases scale for one processor; schema changes touch one processor | Can be **very expensive** depending on the technology stack. **Biggest disadvantage: synchronous dynamic coupling** — Order Placement must synchronously call *both* Inventory *and* Order Shipment, forming tight coupling points throughout |

- **Rule for domain/dedicated**: identify all data-related requirements in each processor *before* selecting. If processors communicate too much, **move toward domain or even monolithic** to improve performance and scalability — unless frequent structural database changes justify the trade.

## Worked Example

**Retail order entry — the choreographed flow.**

1. `Order Placement` receives the initiating event **place order**, inserts the order, returns an order ID to the customer, and advertises **order placed**.
2. **Three processors respond to `order placed` in parallel**: `Notification`, `Payment`, `Inventory`.
3. `Notification` emails the customer and triggers **email sent** — **which nobody listens to.** *This is typical in EDA and illustrates architectural extensibility.*
4. `Inventory` adjusts stock and triggers **inventory updated** → `Warehouse` manages inventory across warehouses, reordering when supplies run low → triggers **stock replenished** → `Inventory` adjusts current inventory.
   - **`Inventory` must NOT trigger an `inventory adjusted` event here.** Doing so creates a **poison event** — an event that keeps looping forever between services. *These happen frequently in EDA; be careful to avoid them.*
5. `Payment` charges the card and triggers **one of two** derived events: **payment applied** or **payment denied**. `Notification` listens for `payment denied` to tell the customer to update their card or choose another method.
6. `Order Fulfillment` listens for `payment applied`, runs picking-and-packing automation (telling the worker where to find the item and what box size to use), triggers **order fulfilled**.
7. Both `Notification` and `Shipping` respond concurrently: `Notification` tells the customer it's ready for shipment; `Shipping` selects a method, ships, and triggers **order shipped** — which `Notification` also consumes to tell the customer it's on its way.

---

**Asynchronous responsiveness — posting a product review.** The comment service takes **3,000 ms** to validate and post: an unacceptable-words check, an abusive-text check (e.g. "slow thinker", "unable to think clearly"), and a context check that the comment is about the product and not a political rant.

| Path | Breakdown | User-perceived time |
|---|---|---|
| **Synchronous REST** | 50 ms latency in + 3,000 ms processing + 50 ms latency out | **3,100 ms** |
| **Asynchronous messaging** | 25 ms to receive (system still spends 3,000 ms posting, total 3,025 ms) | **25 ms** |

- **The caveat**: the synchronous path *guarantees* the comment was posted; the async path only *acknowledges* with a future promise. If the comment contains profanity and is rejected, there's no way to notify the user — **unless** registration is required, in which case the system can message them about the problem and how to fix it.
- **The distinction this teaches**: **responsiveness** is the time to get information back to the user; **performance** is the time to insert the comment into the database. *When the user doesn't need anything back beyond an acknowledgment, why make them wait?* The async path optimized **responsiveness** without touching the comment service. Running the parsing engines in parallel with caching while staying synchronous would instead have addressed **performance**.

---

**Dynamic Quantum Entanglement — the stock trade.** `Portfolio Management` creates a trade order and **synchronously** sends it to `Trade Order`, which performs compliance checks and creates the order. Because the call is synchronous, `Portfolio Management` must **block and wait** for a trade confirmation number.

- **The two systems are now entangled into a single architecture quantum**, which means the architecture characteristics live *between* them:
  - If `Trade Order` is unavailable, `Portfolio Management` **cannot submit trade orders at all**.
  - If `Trade Order` is slow, `Portfolio Management` is slow.
  - If `Portfolio Management` needs to scale, `Trade Order` must scale too — **or `Portfolio Management` can't scale at all**.
- **The detangling move**: send the trade order through a queue, and have `Trade Order` return the confirmation number over a **separate asynchronous channel**. Now they are **two separate quanta**, and `Portfolio Management` can keep issuing trade orders even when `Trade Order` is down, knowing they'll eventually be created and confirmed.

---

**The Workflow Event pattern in action — a trade basket.** A trading advisor batches trade orders into a *basket* and sends them asynchronously to a broker across the country. The contract is:

```
ACCOUNT(String),SIDE(String),SYMBOL(String),SHARES(Long)
```

The received basket:
```
12654A87FR4,BUY,AAPL,1254
87R54E3068U,BUY,AAPL,3122
6R4NB7609JJ,BUY,AAPL,5433
2WE35HF6DHF,BUY,AAPL,8756 SHARES
764980974R2,BUY,AAPL,1211
1533G658HD8,BUY,AAPL,2654
```

The fourth line has the word `SHARES` appended. Without error handling:
```
Exception in thread "main" java.lang.NumberFormatException:
	For input string: "8756 SHARES"
	at java.lang.Long.parseLong(Long.java:589)
	at trading.TradePlacement.execute(TradePlacement.java:23)
```
**Because this was asynchronous, there is no user to respond to and fix the error.** `TradePlacement` can do nothing but log it.

With the Workflow Event pattern — and note the firm has **no control over the trading advisor or the data it sends**, so it must repair the error itself:
```
Trade Placed: 12654A87FR4,BUY,AAPL,1254
Trade Placed: 87R54E3068U,BUY,AAPL,3122
Trade Placed: 6R4NB7609JJ,BUY,AAPL,5433
Error Placing Trade: "2WE35HF6DHF,BUY,AAPL,8756 SHARES"
Sending to trade error processor <-- delegate the error fixing and move on
Trade Placed: 764980974R2,BUY,AAPL,1211
```
The `Trade Placement Error` service, acting as workflow delegate, inspects the exception:
```
Received Trade Order Error: 2WE35HF6DHF,BUY,AAPL,8756 SHARES
Trade fixed: 2WE35HF6DHF,BUY,AAPL,8756
Resubmitting Trade For Re-Processing
```
And the trade completes — **out of order**:
```
trade placed: 1533G658HD8,BUY,AAPL,2654
trade placed: 2WE35HF6DHF,BUY,AAPL,8756 <-- this was the original trade in error
```

**The ordering problem and its fix**: order matters here — a `SELL` for IBM must occur before a `BUY` for AAPL **within the same brokerage account**. Maintaining order within a context is complex but not impossible: have `TradePlacement` **queue and store the brokerage account number of the erroneous trade**; any subsequent trade for that same account goes to a temporary FIFO queue. Once the erroneous trade is fixed and processed, `TradePlacement` de-queues the remaining trades for that account and processes them in order.

---

**The mediator topology on the same order system.** Steps 2, 3, and 4 are concurrent *within* a step but **serial between steps** — step 3 (fulfill order) must complete and be acknowledged before step 4 (ship order).

| Step | Mediator generates | Processors |
|---|---|---|
| 1 | `create order` → order placement queue | `Order Placement` validates, creates, returns an acknowledgment **and the order ID** |
| 2 | `email customer`, `apply payment`, `adjust inventory` — **all three at once** | Three processors act and acknowledge. **The mediator waits for all three** before step 3 |
| 3 | `fulfill order`, `order stock` — simultaneous | `Order Fulfillment`, `Warehouse` |
| 4 | `ship order`, `email customer` (ready to ship) | `Shipping`, `Notification` |
| 5 | `email customer` (order shipped) | `Notification`. **The mediator marks the flow complete and removes all state.** |

## Anti-patterns / Common Risks

- **Poison event** — a derived event that keeps getting triggered and responded to in a continuous loop between services. *These can happen frequently in EDA.*
- **The Swarm of Gnats antipattern** — too many fine-grained derived events triggered from one processor. (*Anemic events* concern the granularity of the **payload**; Swarm of Gnats concerns the granularity of the **events themselves**.)
  - **Too coarse-grained** is also wrong: a single `fraud_checked` event forces `Credit Card Locking`, `Customer Notify`, *and* `Purchase Profile` to all receive it, inspect the payload, and decide whether to act — wasting bandwidth and processing when only one needed to act. **Better: two separate derived events (`fraud_detected` and `no_fraud_detected`), providing context *outside* the payload so each processor decides whether to respond without parsing it.**
  - **Too fine-grained** is the antipattern: a customer who moved updates their bill-to address, ship-to address, and phone number; `Customer Profile` triggers a **separate event for each update**. This saturates the system with derived events all about one thing, **proliferates further small derived events from other processors, and eventually makes the overall event flows impossible for anyone to understand.**
  - **The fix**: bundle the individual updates into a single `profile_updated` derived event for the complete action, containing the **before and after data of all updated fields**.
  - **The rule**: *focus on the **outcome** of the processing or state change* to find the right granularity.
- **Dynamic Quantum Entanglement** — two architecture quanta communicating synchronously become one.
- **Nondeterministic side effects** — processors unexpectedly triggering derived events, or failing to respond when they should. Event workflows get very complex and it is often **difficult to know exactly what will happen when an event is triggered.**
- **Too much static coupling** via event payload contracts. EDA is highly *dynamically* decoupled, but contracts create tight *static* coupling — and **architects don't always know which processors respond to an event**, so a contract change can hit several unexpectedly.
- **Too much synchronous communication between processors** — "EDA gets its superpowers from its highly dynamically decoupled event processors. If event processors keep needing to communicate synchronously, it's a good sign that EDA is not the most appropriate architectural style."
- **Unmanageable state** — because processing is nondeterministic, asynchronous, and parallel, **it's difficult to know when an initiating event has been fully processed, or even its current state.** Occasionally you can identify a final endpoint and have the initiating processor subscribe to that "ending" event, but usually you can't.
- **Silent failure** — with no mediator, if the `Payment` processor crashes mid-task, no other service knows. `Inventory` still adjusts stock and everything downstream proceeds **as though everything is fine**, while the business process is stuck until automated or manual intervention.
- **Poor recoverability** — because other actions have already been taken asynchronously, **resubmitting the initiating event is often simply not feasible.**

## Governance
Mostly **nonstructural**, requiring **observability via logs as part of an overall governance mesh**; some metrics may need manual collection. Two focus areas, **both considered structural decay in EDA**:
- **Static coupling** — govern the **rate of change of event payload contracts** and **overall stamp coupling**. Changing a contract (especially one with no schema) can break a downstream processor, and this is a particular risk here **because nondeterministic end-to-end event flows are so difficult to test**. Govern stamp coupling by **continually recording and observing which fields in an event contract go unused by responders** — this trims contract size, reduces bandwidth, and prevents unnecessary changes to processors.
- **Dynamic coupling** — write automated fitness functions to observe and track synchronous communication between processors via logs, source-code annotations, or standard synchronous custom-identifier libraries. **Any synchronous communication in an EDA should be tracked and discussed to confirm it's necessary**, particularly with domain or dedicated database topologies.

## Cloud Considerations
Works well, primarily due to the highly decoupled nature. EDA easily leverages cloud vendors' asynchronous services, and **the elastic nature of cloud infrastructure matches its shape.**

## Team Topology Considerations
Technically partitioned (multiple event processors, channels, brokers, and possibly databases per domain), though it can work when teams align by domain.
- **Stream-aligned**: may **struggle**. Domains are implemented across multiple processors and derived events, so understanding all the moving parts is hard — adding a step to order placement can require changing multiple processors *and* restructuring how and when existing derived events fire. **The larger and more complex the EDA, the less effective stream-aligned teams will be.**
- **Enabling**: **don't work well here.** Experimentation *within* a stream can disrupt a stream-aligned team's understanding and management of the overall event flow, and usually requires too much coordination.
- **Complicated-subsystem**: **work well** — complex processing is easily isolated in separate processors, and because processors are highly dynamically decoupled, stream-aligned teams only need to coordinate on **static event-payload contracts and derived events**.
- **Platform**: benefit from the technical partitioning, especially if the infrastructure parts (message brokers, event hubs, event buses, event-channel artifacts) are treated as platform-related.

## Examples and Use Cases
Any business problem focused on **responding to things happening** — internal or external. Systems requiring high responsiveness, performance, scalability, fault tolerance, and elasticity.

**Going, Going, Gone auction system** — the number of bidders is usually unknown, demanding scalability and elasticity, particularly when a timed auction closes, plus high responsiveness. **The best reason it fits: EDA regards placing a bid not as a *request made to the system* but as an *event that has happened*.**
- `Bid Capture` receives the initiating event, determines whether the bid is higher than the prior one, triggers **bid placed**.
- `Auctioneer` responds by updating the website with the new bid price.
- `Bid Streamer` simultaneously streams the bid to the website bid history or individual bidders.
- `Bidder Tracker` persists the bidder and bid for tracking and auditing.

**The closing advice**: *"Closely analyze the workflows and processing needed for the business problem to determine if dealing with EDA's complexity is worthwhile given its superpowers. If a majority of the processing needed is request based, consider the microservices architectural style instead."*

## Key Takeaways
1. Distinguish events from messages by four tests — semantics, response, targeting, channel. Broadcasting a command doesn't make it an event.
2. Advertise every action as a derived event, even when nobody listens; that's how you buy architectural extensibility for free.
3. Choose payload type **per event**, not per system: data-based for extreme scale, key-based for frequently changing data.
4. Avoid both extremes — anemic events (too little context, and the database can't supply it) and Swarm of Gnats (too many fine-grained events). **Focus on the *outcome* of the state change.**
5. Include **prior values** in update events; databases rarely keep them.
6. Delegate errors immediately and repair them out-of-band — never let one bad message stall the queue.
7. Use persistent queues + synchronous send + client acknowledge + LPS to close all three data-loss windows.
8. Prefer the correlation ID technique over temporary queues for request-reply.
9. Reach for the mediator topology when you need workflow control, state, and restart — and accept lower performance and decoupling for it. Use multiple domain mediators, and delegate by event complexity.
10. Treat every synchronous call in an EDA as a defect to be justified; each one silently merges two quanta.

## Connects To
- **Ch 2**: the topics-vs-queues trade-off analysis, which is the same decision at a smaller scale.
- **Ch 7**: architecture quantum; dynamic coupling — this chapter is the detailed treatment.
- **Ch 9**: the fallacies, especially bandwidth (#3) and compensating updates (#10); stamp coupling.
- **Ch 12**: pipeline — the style to *not* use for nondeterministic workflows.
- **Ch 16**: space-based architecture — the five-star version of performance, scalability, and elasticity.
- **Ch 18**: microservices — the alternative when processing is mostly request-based; choreography vs. orchestration; database-per-service.
- **Ch 20**: architectural patterns.
