# Chapter 11: The Modular Monolith Architecture Style

## Core Idea
A single deployment unit with functionality grouped by **domain** rather than technical capability — the monolith's simplicity and low cost combined with domain partitioning, at the price of strict governance to stop module boundaries from dissolving.

*(New in the 2nd edition, added because DDD adoption and the focus on domain partitioning made this style far more popular since 2020.)*

## Topology

- **Isomorphic shape**: *a single deployment unit with functionality grouped by domain area.* Deployed as one artifact — a WAR file, a single .NET assembly, a Java EAR file.
- **The namespace tell** — compare the same customer-profile component:
  - Layered (technical): `com.app.presentation.customer.profile` — the third node is a **technical** concern.
  - Modular monolith (domain): `com.app.customer.profile` — the third node is a **domain** concern. If the component is complex, technical concerns may nest *after* the domain: `com.app.customer.profile.presentation`, `com.app.customer.profile.business`.
- **Partitioning**: domain-partitioned. **Architecture quantum**: typically 1.
- A **module** is a domain or subdomain, made up of one to many **components** (Ch 8).

## Frameworks Introduced

- **Two structural options for organizing modules**:

  | | **Monolithic structure** | **Modular structure** |
  |---|---|---|
  | Form | All modules in a single source-code repository; each module is a separate high-level directory | Each module is an independent, self-contained artifact (JAR, DLL), combined into one deployment unit at deploy time |
  | Advantages | Simplest; all source in one place, more easily maintained, tested, and deployed | Teams can work on separate modules, often in their own dedicated repositories. Works well when modules are largely independent, and for larger/more complex systems where each module needs different expertise or business knowledge. Produces **cleaner boundaries** and better separation of concerns |
  | Risks | Developers reuse too much code across modules and let modules communicate too much — turning a well-architected modular monolith into a Big Ball of Mud. **Requires strict governance** | Loses effectiveness when dependent modules need to communicate — the monolithic structure is more effective there |
  | Governance | Automated namespace checks work well | Challenging — code may not be in the same repository, so **each module must be tested separately** |

- **Two options for module communication** (communication between modules "is never a good thing in this architectural style, but in many cases it's necessary"):
  - **Peer-to-peer** — a class in one module instantiates a class in another and invokes its methods.
    - *Monolithic structure problem*: it is **too convenient** to instantiate any class in another module — the fast road to Big Ball of Mud.
    - *Modular structure problem*: the classes live in separate external artifacts, so the calling module won't compile without the class references — forcing a **compile-time dependency**. The usual response is a **shared interface class** in a separately shared JAR/DLL so each module compiles independently. Either way, too much cross-module communication produces the **DLL Hell** (or **JAR Hell**) antipattern.
  - **Mediator** — a mediator component forms an abstraction layer between modules, acting as an **orchestrator** that accepts requests and delivers them to the appropriate modules.
    - *Honest caveat*: this doesn't remove all coupling — every module is now coupled **to the mediator**. But it simplifies the architecture and keeps modules independent of each other.
    - Note: it is the **mediator**, not the dependent modules, that needs the API or interface to invoke functionality in other modules.

- **The "too big" warning signs** — the primary risk of any monolith is growing past maintainability. What "too big" means varies, but the tells are:
  - Changes take too long to make.
  - When one area is changed, other areas unexpectedly break.
  - Team members get in each other's way when applying changes.
  - It takes too long for the system to start up.

## Reference Tables

**Characteristics ratings**

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Cost** | ★★★★★ | Primary strength — no distributed-architecture complexity |
| **Simplicity** | ★★★★★ | Primary strength — simpler and easier to understand |
| **Modularity** | ★★★★ | Primary strength — separation of concerns between modules representing domains and subdomains |
| **Deployability** | ★★ | Slightly higher than layered thanks to modularity, but still a monolith: ceremony, risk, deployment frequency drag it down |
| **Testability** | ★★ | Same reasoning — completeness of testing is limited by the monolithic unit |
| **Elasticity** | ★ | Monolithic deployment; scaling individual functions needs multithreading/internal messaging/parallel processing this style isn't suited to |
| **Scalability** | ★ | Same |
| **Fault tolerance** | ★ | One out-of-memory condition crashes the entire application unit |
| **Availability** | ★ | High MTTR; startup times measured in minutes |

## Code Examples

**Governing module boundaries (Example 11-1)** — ensure all source falls under a defined module namespace:
```
# The following namespaces represent the modules in the system
LIST module_list = {
   com.orderentry.orderplacement,
   com.orderentry.inventorymanagement,
   com.orderentry.paymentprocessing,
   com.orderentry.notification,
   com.orderentry.fulfillment,
   com.orderentry.shipping
   }

# Get the list of namespaces in the system
LIST namespace_list = get_all_namespaces(root_directory)

# Make sure all the namespaces start with one of the listed modules
FOREACH namespace IN namespace_list {
   IF NOT namespace.starts_with(module_list) {
      send_alert(namespace)
   }
}
```
- **What it demonstrates**: any developer creating a high-level namespace or directory outside the defined modules gets an alert. Works well with the *monolithic* structure; with the *modular* structure each module must be validated separately against its own single namespace prefix (Example 11-2).

**Limiting total interdependency to five coupling points (Example 11-3)**:
```
MAP module_source_file_map
FOREACH module IN module_list {
  LIST source_file_list = get_source_files(module)
  ADD module, source_file_list TO module_source_file_map
}

FOREACH module, source_file_list IN module_source_file_map {
  FOREACH source_file IN source_file_list {
    incoming_count = used_by_other_module(source_file, module_source_file_map)
    outgoing_count = uses_other_module(source_file)
    total_count = incoming_count + outgoing_count
  }
  IF total_count > 5 {
    send_alert(module, total_count)
  }
}
```
- **What it demonstrates**: "too much" communication is highly subjective and varies by system — so pick a number and enforce it. Afferent + efferent coupling per module against a threshold.

**Forbidding a specific module dependency with ArchUnit (Example 11-4)**:
```java
public void order_placement_cannot_access_shipping() {
   noClasses().that()
   .resideInAPackage("..com.orderentry.orderplacement..")
   .should().accessClassesThat()
   .resideInAPackage("..com.orderentry.shipping..")
   .check(myClasses);
}
```
- **What it demonstrates**: `OrderPlacement` has no business talking to `Shipping`; encode that intent rather than documenting it.

**Governance tooling by platform**: ArchUnit (Java) · ArchUnitNet and NetArchTest (.NET) · PyTestArch (Python) · TSArch (TypeScript/JavaScript).

## Worked Example

**EasyMeals** — a new delivery-based neighborhood restaurant for working people who lack time to cook. Customers order dinner online and receive it within an hour. As a small local restaurant they have **no high scalability or responsiveness needs** and a **limited budget** — the shape of the business problem makes modular monolith a good fit.

**Modules:**
```
com.easymeals.placeorder
com.easymeals.payment
com.easymeals.prepareorder
com.easymeals.delivery
com.easymeals.recipes
com.easymeals.inventory
```

**`PlaceOrder`** — view the menu, select items, add name/address/payment info, submit. Its *components*:
```
com.easymeals.placeorder.menu
com.easymeals.placeorder.shoppingcart
com.easymeals.placeorder.customerdata
com.easymeals.placeorder.paymentdata
com.easymeals.placeorder.checkout
```

**`PaymentProcessing`** — applies payment. Credit cards, debit cards, PayPal; the modularity makes adding a type (loyalty points) easy:
```
com.easymeals.payment.creditcard
com.easymeals.payment.debitcard
com.easymeals.payment.paypal
```

**`PrepareOrder`** — displays the order to kitchen staff, who mark it ready:
```
com.easymeals.prepareorder.displayorder
com.easymeals.prepareorder.ready
```

**`Delivery`** — assigns a delivery person, records the address, allows marking delivered (ending the order's lifecycle) and recording issues (aggressive dog at the gate, customer not home):
```
com.easymeals.delivery.assign
com.easymeals.delivery.issues
com.easymeals.delivery.complete
```

**`Recipes`** — cooks and management add menu items and maintain ingredients and measurements:
```
com.easymeals.recipes.view
com.easymeals.recipes.maintenance
```

**`IngredientsInventory`** — the most complex module; includes a **sophisticated AI component that forecasts sales volume** to automate weekly ingredient procurement:
```
com.easymeals.inventory.maintenance
com.easymeals.inventory.forecasting
com.easymeals.inventory.ordering
com.easymeals.inventory.suppliers
com.easymeals.inventory.invoices
```

**Flow**: customers reach `PlaceOrder` and `PaymentProcessing` through a dedicated UI; once paid, `PlaceOrder` communicates with `PrepareOrder`; the kitchen marks it ready and it moves to `Delivery`.

**The lesson**: the module structure *is* the map. Locating the code for a bug fix or a new feature is a matter of reading the domain name — which is the whole point of domain partitioning.

## Anti-patterns

- **Unstructured monolith** — the risk of too much code reuse. Reuse and sharing are necessary parts of software development, but here **too much reuse blurs module boundaries**, producing a monolith with such highly interdependent code that it cannot be unraveled.
- **Big Ball of Mud** — reached via convenient cross-module instantiation in the monolithic structure.
- **DLL Hell / JAR Hell** — reached via excessive compile-time dependencies in the modular structure.
- **Excessive intermodule communication** — modules should ideally be independent and self-contained. Some communication is normal and sometimes necessary within a complex workflow, but **too much intercommunication is a good indication the domains were ill-defined in the first place.** The fix is to redefine the domains to accommodate the workflows and interdependencies, not to add more plumbing.

## When to Use
- Tight budget and time constraints (simplicity, low cost).
- **Starting a new system when the architectural direction is unclear.** It is often more effective to begin with a modular monolith and later move to a distributed style (service-based, Ch 14; microservices, Ch 18) than to jump straight into the distributed architecture.
- **Domain-focused teams** — cross-functional teams with specialization, each owning a module end to end with minimal coordination.
- When the **majority of changes are domain based** (e.g. adding expiration dates to wishlist items).
- Teams engaging in **DDD**.

## When Not to Use
- When high operational characteristics are required: scalability, elasticity, availability, fault tolerance, responsiveness, performance.
- When the **majority of changes are technically oriented** — continuously replacing the UI or database technology. Because the architecture is domain partitioned, such changes hit **every module** and require significant communication and coordination between domain teams. **Use layered architecture (Ch 10) instead.**

## Cloud Considerations
Deployable in the cloud, especially small systems, but **not generally well suited** — the monolithic nature can't take advantage of on-demand provisioning. Smaller systems in this style can still leverage cloud services for file storage, databases, and messaging.

## Data Topologies
Usually a **monolithic database**, which helps reduce intermodule communication because data is shared. However, if modules are independent and perform specific functions, **each can have its own database** containing contextual data — even though the architecture itself remains monolithic.

## Team Topology Considerations
Works best when **teams are aligned by domain area** (cross-functional teams with specialization). A domain-based requirement is handled by one team from presentation logic all the way to the database. **Teams organized by technical category (UI, backend, database) do not work well here** — assigning domain-based requirements to technically organized teams requires a lot of communication and collaboration that often proves difficult.
- **Stream-aligned**: teams own the flow end to end, matching the monolithic, self-contained shape.
- **Enabling**: specialists can experiment by introducing additional modules with minimal impact on existing ones.
- **Complicated-subsystem**: each module has a specific domain role (e.g. `PaymentProcessing`), so members can focus on complicated domain processing independently of other modules.
- **Platform**: high modularity lets developers leverage common tools, services, APIs, and tasks.

## Key Takeaways
1. Put the domain in the third namespace node, not the technical concern — that single change is the style.
2. Choose the monolithic structure for simplicity and dependent modules; choose the modular structure for independence, separate teams, and cleaner boundaries.
3. Automate module-boundary governance from day one; without it, this style degrades into a Big Ball of Mud faster than layered does.
4. Set and enforce a numeric cap on intermodule coupling points.
5. Treat heavy intermodule chatter as a **domain modeling** defect, not a communication problem.
6. Use it as the deliberate first step before distributing — this is the cheapest way to learn the domain boundaries you'll later need.
7. Watch the four "too big" signals; they are your migration trigger.
8. Don't choose it when your changes are technical rather than domain-shaped.

## Connects To
- **Ch 8**: modules are made of components.
- **Ch 9**: domain top-level partitioning; the Big Ball of Mud it degrades into.
- **Ch 10**: layered architecture — the technical-partitioning counterpart, and the better choice for technically-driven change.
- **Ch 14 / Ch 18**: service-based and microservices — where this style migrates when it outgrows itself.
- **Ch 19**: choosing the appropriate architecture style.
