# Chapter 34: The Missing Chapter

*Guest chapter by Simon Brown.*

## Core Idea
Good design intentions are destroyed in a flash if you get the implementation details wrong: how you map the design onto packages, and which access modifiers and decoupling modes you apply, determines whether your architecture actually exists. **The devil is in the implementation details.**

## Frameworks Introduced
- **Package by Component**: Bundle all the responsibilities related to a single coarse-grained component — the "business logic" *and* its persistence — into a single Java package, behind one clean interface.
  - When to use: monolithic applications where you want the compiler, not discipline, enforcing architectural rules; also as a stepping stone toward micro-services.
  - How: (1) create one package per coarse-grained component, e.g. `com.mycompany.myapp.orders`; (2) expose exactly one `public` type — the component interface, e.g. `OrdersComponent`; (3) make everything else package protected: `OrdersComponentImpl`, `OrdersRepository`, `JdbcOrdersRepository`; (4) keep the UI (`OrdersController`) outside the component, in its own package, depending only on the component interface; (5) maintain separation of concerns *inside* the component — business logic still separate from persistence — as an implementation detail consumers never see; (6) in .NET, use `internal`, which requires a separate assembly per component.
  - Why it works: with `OrdersRepository` package protected there is literally no way (short of reflection) for code outside the package to reach persistence directly, so the "web controllers should never access repositories directly" rule becomes compiler-enforced rather than review-enforced. Failure mode: mark the internals `public` and the whole scheme collapses into a horizontal layered architecture wearing a different package name.
- **Organization versus Encapsulation**: If every type is `public`, packages are only an *organization* mechanism (a grouping, like folders), not an *encapsulation* mechanism.
  - When to use: as the diagnostic you run on any codebase claiming an architectural style.
  - How: grey out every type whose access modifier could be made more restrictive. What remains `public` is your real, compiler-enforced boundary. If nothing greys out, you have no boundary.
  - Why it works: `public` types can be used from anywhere, so packages provide no real value and can be ignored — and once you ignore the packages, all four architectural approaches become *syntactically identical* regardless of how different they are conceptually. Arguably, all four then reduce to four ways of describing a traditional horizontally layered architecture.
- **Ports and Adapters**: Keep domain-focused code independent of technical implementation details (frameworks, databases) by splitting the codebase into an "inside" (domain) and an "outside" (infrastructure).
  - When to use: whenever business rules must survive technology churn.
  - How: put domain concepts in `…domain` (`OrdersService`, `OrdersServiceImpl`, and — named in the ubiquitous domain language — `Orders`, not `OrdersRepository`); put UI, database, and third-party integration in outside packages; enforce that the outside depends on the inside and never the reverse.

## Key Concepts
- **Package by Layer**: Horizontal slicing by technical function — a package for web, one for "business logic," one for persistence. Dependencies point downward; in a *strict* layered architecture each layer depends only on the next adjacent lower layer.
- **Package by Feature**: Vertical slicing by feature, domain concept, or aggregate root — all the types for orders in one package, so the top-level organization screams the business domain rather than "web, services, repositories."
- **Relaxed layered architecture**: A layered architecture where layers are permitted to skip their adjacent neighbours — e.g. `OrdersController` calling `OrdersRepository` directly, bypassing `OrdersService`. Still an acyclic graph, still all arrows downward, and still usually wrong (except deliberately, e.g. under CQRS).
- **Component (Brown's definition)**: "A grouping of related functionality behind a nice clean interface, which resides inside an execution environment like an application." Distinct from Uncle Bob's "units of deployment … in Java, jar files" — whether each component resides in a separate jar is an orthogonal concern.
- **C4 model**: Brown's hierarchical model of static structure — a software system is made of containers (web apps, mobile apps, databases, file systems), each containing components, each implemented by classes/code.
- **Published versus public**: The distinction module systems (OSGi, Java 9 modules) enable — a module may mark many types `public` but *publish* only a small subset for external consumption.
- **Périphérique anti-pattern of ports and adapters**: With only two source trees (domain and infrastructure), infrastructure code can call other infrastructure code — web controller straight to database repository — circumnavigating the domain the way Paris's ring road circumnavigates the city.
- **Ubiquitous domain language**: DDD's rule that everything on the "inside" be named in domain terms — hence `Orders`, because you discuss "orders," not "the orders repository."

## Mental Models
- Think of your compiler as your architecture enforcement tool. Prefer it over discipline and code reviews (which fail when budgets and deadlines loom) and over post-compilation static analysis (NDepend, Structure101, Checkstyle — crude, fallible, and with a longer feedback loop than it should be).
- Use the "new hire test": give an enthusiastic newcomer an orders-related use case and a few minutes with a coffee. If they can dependency-inject `OrdersRepository` straight into `OrdersController` and ship a working page, your architecture is a diagram, not a structure.
- Think of the fewer-public-types rule as arithmetic: the fewer `public` types you have, the smaller the number of potential dependencies.
- Use "one place to go": if you're writing code that does something with orders, the win of package by component is that there is exactly one destination — `OrdersComponent`.

## Code Examples
```java
// package by component — com.mycompany.myapp.orders
package com.mycompany.myapp.orders;

public interface OrdersComponent {          // the sole public entry point
    OrderStatus getOrderStatus(String id);
}

class OrdersComponentImpl implements OrdersComponent { … }   // package protected
interface OrdersRepository { … }                             // package protected
class JdbcOrdersRepository implements OrdersRepository { … } // package protected
```
```java
// package by layer — the interfaces are forced public by cross-package dependencies
package com.mycompany.myapp.web;
public class OrdersController { … }         // depends on OrdersService

package com.mycompany.myapp.service;
public interface OrdersService { … }        // must be public
class OrdersServiceImpl implements OrdersService { … }   // can be restricted

package com.mycompany.myapp.data;
public interface OrdersRepository { … }     // must be public
class JdbcOrdersRepository implements OrdersRepository { … } // can be restricted
```
- **What it demonstrates**: In package by layer, `OrdersService` and `OrdersRepository` are forced `public` because they have inbound dependencies from other packages — so nothing stops a controller reaching the repository. In package by component, only `OrdersComponent` is `public`, and the compiler makes the violation impossible.

## Reference Tables

The same "view orders" use case under all four strategies:

| Strategy | Slicing | Package layout | Types forced `public` | Types that can be package protected | What the top level screams | Main weakness |
|---|---|---|---|---|---|---|
| **Package by Layer** | Horizontal, by technical function | `web`, `service`, `data` | `OrdersService`, `OrdersRepository` | `OrdersServiceImpl`, `JdbcOrdersRepository` | Web, services, repositories — nothing about the domain | Three big buckets don't scale; controller can bypass the service (relaxed layering) |
| **Package by Feature** | Vertical, by feature / domain concept / aggregate root | one package, e.g. `orders` | `OrdersController` only (sole entry point) | everything else | Orders — the business domain | Nothing outside the package can touch orders except through the controller; may or may not be desirable |
| **Ports and Adapters** | Inside (domain) vs. outside (infrastructure) | `domain` + `web`, `data`, … | `OrdersService`, `Orders` | `OrdersServiceImpl`, `JdbcOrdersRepository` (DI'd at runtime) | Domain independence from technology | Périphérique anti-pattern: infrastructure calling infrastructure around the domain |
| **Package by Component** | Coarse-grained component, business logic + persistence together | `orders` (component) + `web` (UI outside) | `OrdersComponent` only | `OrdersComponentImpl`, `OrdersRepository`, `JdbcOrdersRepository` | Components / services | Coarse granularity; needs a separate assembly per component in .NET |

Decoupling modes, weakest to strongest:

| Mode | Mechanism | Trade-off |
|---|---|---|
| Discipline + code review | "We trust our developers" | Fails when budgets and deadlines loom |
| Static analysis at build time | NDepend, Structure101, Checkstyle; wildcard rules like "types in `**/web` should not access types in `**/data`" | Crude, fallible, feedback loop longer than it should be |
| Access modifiers | `public` vs. package protected (Java), `internal` (.NET) | Compiler-enforced; Java can't restrict by package/subpackage hierarchy |
| Module system | OSGi, Java 9 modules — `public` vs. *published* | Extra machinery; newer tooling |
| Separate source trees | One module/project per component in Maven, Gradle, MSBuild | Idealistic; real performance, complexity, and maintenance costs |

## Worked Example
The relaxed-layering slide, step by step:

1. You have a package-by-layer codebase. `OrdersController` (web) → `OrdersService` (service) → `OrdersRepository` (data). Strict layering; arrows all point down; the dependency graph is clean and acyclic.
2. Because those packages are separate, `OrdersService` and `OrdersRepository` must be `public` for the layer above to see them.
3. A new hire is given an orders-related use case and wants to make a big impression fast. They find `OrdersController` and add the new page there. They need order data. They spot the already-`public` `OrdersRepository` interface and dependency-inject the implementation straight into the controller.
4. Minutes later the page works. The dependency arrows still point downward. The graph is still acyclic. Nothing is flagged. But the controller now bypasses `OrdersService` — and with it any authorization-per-record logic living in the business layer. This is a *relaxed layered architecture*, and teams usually discover it only the first time they visualize what their codebase really looks like.
5. Fixes that don't work reliably: an architectural guideline ("web controllers should never access repositories directly") enforced by discipline and code review; or a post-compilation wildcard rule in a static analysis tool.
6. The fix that does: package by component. `OrdersRepository` is package protected inside `com.mycompany.myapp.orders`. The new hire's shortcut does not compile.

## Key Takeaways
1. Architecture that isn't enforced by the compiler isn't enforced. Discipline, code review, and post-build static analysis are all fallible with feedback loops that are too long.
2. Marking all types `public` means you're not using the encapsulation your language provides — and it makes package by layer, package by feature, ports and adapters, and package by component syntactically identical.
3. The fewer `public` types you have, the smaller the number of potential dependencies. Grey-out every type whose access modifier can be tightened, and tighten it.
4. Package by layer doesn't scale past three big buckets and screams nothing about the business domain. Package by feature fixes the screaming but is still suboptimal.
5. Package by component puts business logic and persistence behind one public interface per component — one place to go for anything orders-related, with internals invisible.
6. Well-defined components in a monolith are a stepping stone to micro-services; the key difference is only the decoupling mode.
7. Be pragmatic. Weigh team size, skill level, solution complexity, and time and budget constraints; leave options open where applicable; and watch for coupling in other areas, such as data models.

## Connects To
- **Ch 12 (Components)**: Uncle Bob's component = unit of deployment (jar); Brown's = related functionality behind a clean interface inside an execution environment. Deliberately different definitions.
- **Ch 13–14 (REP, CCP, CRP, ADP)**: Brown agrees with the cohesion and coupling principles but reaches a different conclusion about code organization.
- **Ch 22 (The Clean Architecture)**: Ports and adapters is the "inside/outside" formulation of the same circles.
- **Ch 32 (Frameworks Are Details)**: Package protected internals are how you actually stop framework types escaping the outer package.
- **Hexagonal Architecture / DDD**: The ubiquitous domain language explains naming `Orders` rather than `OrdersRepository`.
- **Micro-services / SOA**: Package by component takes a service-centric view of a monolith; the components are the future service boundaries.
- **CQRS**: The one case where bypassing the business logic layer is the intended outcome.
- **Martin Fowler, "Presentation Domain Data Layering"**: Layering is a good way to *get started*, and insufficient once scale and complexity arrive.
