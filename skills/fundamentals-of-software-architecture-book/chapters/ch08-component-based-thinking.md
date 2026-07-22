# Chapter 8: Component-Based Thinking

## Core Idea
Architects see systems at the **logical component** level, not the class level; components are discovered iteratively (Workflow or Actor/Action, never entities), refined by analyzing roles, responsibilities, and architecture characteristics, and decoupled by limiting each component's *knowledge*.

## Frameworks Introduced

- **The Component Identification and Refactoring Cycle** — a feedback loop that never stops:
  1. **Identify initial core components** (best guess).
  2. **Assign user stories or requirements** to them.
  3. **Analyze roles and responsibilities** — do the assigned stories belong here? Is the component doing too much?
  4. **Analyze architecture characteristics** — does any characteristic require splitting or combining?
  5. **Refactor components** (optional) and loop.
  - When to use: greenfield systems *and* any time a feature is added or changed. Adding in-store pickup to an order system means new scheduling code plus changes to ordering — which may require new components, changes to existing ones, or both.
  - Why it works: it's virtually impossible to anticipate every discovery and edge case; understanding of where behaviors belong deepens as the team builds.

- **The Workflow approach** — derive components from major happy-path (nonerror) workflows or the main request-processing workflow. Model the *major* workflows only; the rest evolve.
- **The Actor/Action approach** — identify the major actions each actor can perform. **The system itself is always an actor**, performing automated functions like billing and replenishing stock. Particularly useful with multiple actors; generally generates *more* components than the Workflow approach.
  - Both approaches let the architect identify initial components and their communication **before receiving detailed requirements**.
  - Neither maps 1:1 — several workflow steps or actions can land on the same component (e.g. both "email order details" and "email shipped" → `Customer Notification`).

- **Logical vs. Physical Architecture**:
  | | Logical architecture | Physical architecture |
  |---|---|---|
  | Shows | Logical components, their interactions, actors, optionally a repository (not a database) | Services, user interfaces, databases, deployment artifacts |
  | Omits | UI, databases, services, physical artifacts | Where functionality lives conceptually |
  | Maps to | Directory structures and namespaces in the code | One or more architecture styles from Part II |
  - **Do not skip straight to physical.** A physical architecture doesn't show where functionality lives or how it fits together — payment processing may be smeared across multiple services. It also gives development teams no guidance on organizing code, producing unstructured architectures that are hard to maintain, test, and deploy.
  - Logical architecture is generally **independent** of physical: you can design it before deciding monolith vs. distributed, or which style to use.

- **The Law of Demeter (Principle of Least Knowledge)**: *a component or service should have limited knowledge of other components or services.*
  - Mythological source: Demeter produced all the grain for the world but had no idea what people did with it — she was decoupled from the rest of the world.
  - How to apply: find the **knowledge** a component holds that isn't its **responsibility**, and defer that knowledge to a downstream component.
  - **Critical caveat**: applying the Law of Demeter does **not** necessarily reduce system-wide coupling — it usually **redistributes** it to different parts of the system.

## Key Concepts

- **Logical component** — a building block implementing a business function; manifested as a namespace or directory. The **leaf nodes** of the directory/namespace tree are the components; higher-level nodes are domains and subdomains (`order_entry/ordering/payment` → the `Payment Processing` component).
- **Static coupling** — components communicating synchronously.
  - **Afferent coupling (CA)** — incoming / fan-in: how many components depend on this one.
  - **Efferent coupling (CE)** — outgoing / fan-out: how many components this one depends on.
- **Temporal coupling** — nonstatic dependencies based on timing or transactions (a single unit of work). `Order Placement` must run before `Order Shipment`. **Hard to detect with current tooling** — usually found via design documents or error conditions.
- **Cohesion** (component level) — how, and how much, a component's operations interrelate. Components can grow too big *even when* all operations interrelate.

## Mental Models

- **A house floor plan.** Rooms — kitchen, bedrooms, bathrooms, living room, office — each serve a distinct purpose and together make up the house. The major functions a system performs are its components.
- **Components start as empty buckets.** The name states the *proposed* role and responsibility; the component is a placeholder until you fill it with user stories.
- **Best guess, then iterate.** A common mistake is spending too much effort trying to get the initial components perfect — precisely when you know the least about the system.
- **The conjunction test.** Write the component's role and responsibility as a *statement*. If it needs *and*, *also*, *in addition*, *as well as*, or lots of commas, the component is doing too much.
- **The directory test.** All the source code for a component lives in one directory (`com/app/order/placement`). If that's too much code for one directory, the component is too big.
- **Knowledge is coupling.** A component can be tightly coupled without having the *responsibility* — merely *knowing* that four other things must happen is enough.
- **Don't obsess over the one true design.** Few software systems can be implemented only one way. Assess trade-offs as objectively as possible and pick the "least worst" set.

## Worked Example

**Refining `Order Placement` by role and responsibility.** The architect has assigned eight requirements to `Order Placement`:

1. Validate the order (all fields entered and correct)
2. Display the shopping cart with descriptions, quantities, prices
3. Determine the correct shipping address
4. Collect payment information
5. Generate a unique order ID
6. Apply payment for the order
7. Adjust inventory counts for the items ordered
8. Email the customer an order summary

**The role-and-responsibility statement** reads:

> "This component is responsible for validating the order **and** displaying the valid shopping cart, complete with the item picture, description, quantity, and price. This component is **also** responsible for determining the correct shipping address for the order, **as well as** collecting all the payment information from the customer. **In addition**, it's **also** responsible for applying the payment, adjusting inventory, and emailing the customer the order summary."

Four conjunctive phrases and heavy comma use — the tell. All eight operations *are* about placing an order, but items 6–8 don't belong.

**After splitting:**

| Component | Responsibilities |
|---|---|
| `Order Placement` | Validate order · display cart · determine shipping address · collect payment info · generate order ID |
| `Payment Processing` | Apply payment |
| `Inventory Management` | Adjust inventory counts |
| `Customer Notification` | Email order summary |

**Why a new `Customer Notification` component was needed.** The user story *"as a customer, I want an email each time the order status changes"* looks like it belongs to `Order Placement`, `Order Fulfillment`, **and** `Order Shipment`. But a user story is implemented as source code that must live in one directory or namespace — and replicating that code across three components is a bad idea. So the architect creates a fourth component and has the other three communicate with it.

**Applying the Law of Demeter to the same system.** `Order Placement` initially knows that: inventory must be decremented; if stock goes low, more must be ordered from the supplier; the item price may need adjusting for limited supply; and the customer must be emailed. That is a lot of knowledge.

- The knowledge that *inventory must be decremented* **cannot** be deferred — inserting a component between `Order Placement` and `Inventory Management` leaves the efferent coupling level unchanged. Leave that coupling point as is.
- The knowledge that *more stock must be ordered* and *the price must be adjusted* **can** be deferred to `Inventory Management`.
- Result: `Order Placement` is less coupled — but `Inventory Management` is now *more* coupled. The coupling moved; it didn't vanish.

**Case study — Going, Going, Gone (GGG), via Actor/Action.** Three roles: **bidder**, **auctioneer**, **system**.

| Actor | Actions | Components |
|---|---|---|
| Bidder | View live video stream · view live bid stream · place a bid | `Video Streamer`, `Bid Streamer`, `Bid Capture` |
| Auctioneer | Enter live bids · receive online bids · mark item sold | `Bid Capture`, `Bid Tracker` |
| System | Start auction · make payment · track bidder activity | `Auction Session`, `Payment`, `Bid Tracker` |

Initial components: `Video Streamer` (streams a live auction) · `Bid Streamer` (streams bids as they occur; with Video Streamer gives bidders a read-only view) · `Bid Capture` (captures bids from auctioneer and bidders) · `Bid Tracker` (system of record) · `Auction Session` (starts an auction; on win triggers payment and resolution, notifies bidders of the next item) · `Payment` (third-party credit-card processor).

**Then the characteristics analysis changes the design.** Functionally, one `Bid Capture` for everyone makes sense — bids from anyone are handled identically. But:
- The auctioneer does **not** need the scalability or elasticity that potentially thousands of bidders need.
- The auctioneer needs **more** reliability (connections mustn't drop) and availability. A bidder losing a connection is bad for business; the *auctioneer* losing one is disastrous.

→ Split `Bid Capture` into `Bid Capture` and `Auctioneer Capture`, with new links from `Auctioneer Capture` to `Bid Streamer` (to show online bidders the live bids) and `Bid Tracker`. `Bid Tracker` now unifies two very different streams: the auctioneer's single stream and the bidders' many.

This is still not the final design — account registration and payment administration remain undiscovered — but it's a good starting point.

## Anti-patterns

- **The Entity Trap** — deriving components from entities (`Customer` → `Customer Manager`, `Order` → `Order Manager`). Three failures:
  1. **Ambiguous names.** "What does `Order Manager` do?" → "It manages orders." Useless. Compare `Validate Order`. **Tell**: suffixes like *Manager*, *Supervisor*, *Controller*, *Handler*, *Engine*, or *Processor*.
  2. **Dumping grounds.** Every scrap of order functionality — validation, placement, history, fulfillment, shipping, tracking — lands in one component. It becomes the "kitchen sink" utility class every developer has written once.
  3. **Too coarse-grained.** The component does too much and loses its purpose; hard to maintain, test, and deploy, and therefore unreliable.
  - **Exception**: if the system truly is entity-based CRUD, it doesn't need an architecture — it needs a CRUD framework or a no-code/low-code environment.
- **Skipping the logical architecture** and starting with physical.
- **Chasing perfect initial components** instead of iterating.

## Key Takeaways
1. See the system at the component level; that is where the architect works.
2. Build a logical architecture *before* a physical one — it tells developers how to organize code.
3. Start components with a best guess from workflows or actor/actions, then iterate through the refactoring cycle forever.
4. Never derive components from entities; watch for *Manager*/*Handler*/*Processor* suffixes.
5. Write each component's role and responsibility as a sentence, and split it when conjunctions pile up.
6. Let architecture characteristics split components — different scalability or reliability needs for the same function justify two components (`Bid Capture` / `Auctioneer Capture`).
7. Reduce coupling by deferring **knowledge**, not just responsibility — but know that Demeter redistributes coupling rather than eliminating it.
8. Watch temporal coupling explicitly; no tool will find it for you.

## Connects To
- **Ch 2**: component-based thinking is a facet of architectural thinking.
- **Ch 3**: modules, cohesion, and afferent/efferent coupling at the code level.
- **Ch 5**: the characteristics that drive component splits; the GGG kata's sibling, Going Green.
- **Ch 7**: architecture quantum — the next level of abstraction above components.
- **Ch 9**: how top-level partitioning (technical vs. domain) organizes these components.
- **Ch 18**: microservices granularity — where component sizing becomes service sizing.
