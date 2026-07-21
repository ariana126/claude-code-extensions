# Chapter 20: Business Rules

## Core Idea
Business rules come in two kinds: **Critical Business Rules** (which make or save the business money whether or not a computer exists) bound to **Critical Business Data** inside **Entities**, and **application-specific** rules that exist only because the system is automated, held in **use cases**. Use cases depend on Entities; Entities know nothing of use cases.

## Frameworks Introduced

- **Entities (Critical Business Rules + Critical Business Data)**: an object within the system that embodies a small set of Critical Business Rules operating on Critical Business Data.
  - When to use: for any rule that would still make or save money if executed manually by a clerk with an abacus — e.g. the bank charging *N*% interest on a loan.
  - How:
    1. Identify the rules critical to the business itself, which would exist even with no system to automate them.
    2. Identify the data those rules require — the data that would exist even if the system were not automated (for a loan: loan balance, interest rate, payment schedule).
    3. Bind them together: the Entity either contains the Critical Business Data or has very easy access to it, and its **interface consists of the functions that implement the Critical Business Rules operating on that data**.
    4. Keep it unsullied — no databases, no user interfaces, no third-party frameworks. It must be able to serve the business in any system, regardless of presentation, storage, or machine arrangement.
  - Why it works: gathering the software implementing a business-critical concept and separating it from every other concern makes it the most independent and reusable code in the system. Note that you do **not** need an object-oriented language — all that is required is binding the Critical Business Data and Critical Business Rules into a single, separate software module.

- **Use Cases (application-specific business rules)**: a description of the way an automated system is used.
  - When to use: for rules that make or save money by defining and constraining how an *automated* system operates — rules that would make no sense in a manual environment.
  - How: specify the input to be provided by the user, the output to be returned to the user, and the processing steps that produce that output. A use case is an object with one or more functions implementing the application-specific rules, plus data elements: the input data, the output data, and references to the Entities it interacts with.
  - Critical constraint: **the use case does not describe the user interface**, other than informally specifying the data coming in and going out. From the use case it must be impossible to tell whether the application is delivered on the web, on a thick client, on a console, or as a pure service. Use cases describe the application-specific rules governing interaction between users and Entities — *how the data gets in and out of the system is irrelevant to the use cases*.

- **Request and Response Models**: the use case class accepts simple request data structures for input and returns simple response data structures as output.
  - When to use: at every use case's boundary.
  - How: these structures depend on nothing. They do not derive from framework interfaces such as `HttpRequest` and `HttpResponse`; they know nothing of the web or of any UI trappings. The use case code must not know about HTML or SQL.
  - Failure mode: **do not let request/response models hold references to Entity objects**, however much data they share. Their purposes are very different and they will change for very different reasons, so coupling them violates the Common Closure and Single Responsibility Principles — the result is lots of tramp data and lots of conditionals. And if the models are not independent, the use cases depending on them are indirectly bound to whatever dependencies those models carry.

## Key Concepts
- **Business rules**: rules or procedures that make or save the business money — strictly, ones that would do so even if executed manually.
- **Critical Business Rules**: rules critical to the business itself, which would exist even if there were no system to automate them.
- **Critical Business Data**: the data those rules require, which would exist even if the system were not automated.
- **Entity**: an object binding Critical Business Data and Critical Business Rules into a single separate module; pure business and nothing else.
- **Use case**: a description of the way an automated system is used, specifying inputs, outputs, and processing steps; holds application-specific business rules.
- **Application-specific rules**: rules that make sense only as part of an automated system, as opposed to the Critical Business Rules inside Entities.
- **Request model / response model**: simple, dependency-free input and output data structures at the use case boundary.
- **Tramp data**: data passed through code that has no use for it — a symptom of tying request/response models to Entities.

## Mental Models
- **Use the abacus test to find Entities.** If a clerk with an abacus could execute the rule and it would still make or save money, it is a Critical Business Rule and belongs in an Entity.
- **Think of use cases as controlling "the dance of the Entities."** Use cases contain the rules specifying how and when the Critical Business Rules inside Entities are invoked.
- **Think of Entities as higher level than use cases, counter-intuitively.** Use cases are specific to a single application and therefore closer to the inputs and outputs; Entities are generalizations usable in many applications and therefore farther from IO. Use cases depend on Entities; Entities do not depend on use cases.
- **Use "could I tell from this use case whether it's a web app?" as an acceptance check.** If yes, UI has leaked into the business rules.
- **Treat business rules as the family jewels.** They are the reason the software system exists and the code that makes or saves money.

## Reference Tables

| | **Entity** | **Use Case** |
|---|---|---|
| Holds | Critical Business Rules + Critical Business Data | Application-specific business rules |
| Would exist without automation? | Yes | No |
| Scope | Reusable across many applications | Specific to a single application |
| Level | Higher — farther from inputs and outputs | Lower — closer to inputs and outputs |
| Knows about the other? | No | Yes (holds references to Entities) |
| Knows the UI? | No | No — only the data in and the data out |
| Example | `Loan`: balance, rate, schedule + the rules on them | Create a new loan: gather and validate contact info, confirm credit score ≥ 500, then estimate payments |

## Worked Example

**The bank loan.**

*Entity (Figure 20.1).* The `Loan` entity holds three pieces of Critical Business Data — loan balance, interest rate, payment schedule — and presents three related Critical Business Rules at its interface. The rule "the bank charges *N*% interest for a loan" makes the bank money whether a program computes it or a clerk does. `Loan` stands alone as a representative of the business: no database, no UI, no framework. It would serve the bank in any system, however presented, however stored, however the computers are arranged.

*Use case (Figure 20.2).* Bank officers create new loans through an application. The bank decides that loan officers must not be offered payment estimates until contact information has been gathered and validated and the candidate's credit score confirmed to be **500 or higher**. So the system will not proceed to the payment estimation screen until the contact information screen has been filled out and verified and the credit score confirmed above the cutoff. That constraint is meaningless in a manual environment — it exists only because the system is automated — so it is a use case, not a Critical Business Rule. Its final line references the **Customer** entity, which holds the Critical Business Rules governing the relationship between the bank and its customers.

*Boundary.* The use case receives a simple request structure carrying name, address, phone, and credit score — not an `HttpRequest`, not an Entity reference — and returns a simple response structure with the estimate. Nothing in the use case class knows HTML or SQL, so the same use case serves a web front end, a thick client, a console, or a pure service unchanged.

## Key Takeaways
1. Separate Critical Business Rules (Entities) from application-specific rules (use cases) — the abacus test tells you which is which.
2. Bind Critical Business Data to Critical Business Rules in one module; an OO language is convenient, not required.
3. Keep Entities free of databases, user interfaces, and third-party frameworks — pure business and nothing else.
4. Write use cases so the delivery mechanism is undetectable from them; how data gets in and out is irrelevant.
5. Use simple, dependency-free request and response data structures; never derive them from `HttpRequest`/`HttpResponse`.
6. Never put Entity references inside request/response models — they change for different reasons, and coupling them yields tramp data and conditionals.
7. Entities are higher level than use cases because they are farther from inputs and outputs; dependencies run use case → Entity, following the Dependency Inversion Principle.
8. Business rules should be the heart of the system, with lesser concerns plugged into them — the most independent and reusable code you own.

## Connects To
- **Ch 17 (Boundaries: Drawing Lines)**: this chapter defines the core that plugins plug into.
- **Ch 19 (Policy and Level)**: supplies the "distance from inputs and outputs" definition that ranks Entities above use cases.
- **Ch 22 (The Clean Architecture)**: Entities and use cases become the two innermost rings.
- **Dependency Inversion Principle**: lower-level use cases know about higher-level Entities, never the reverse.
- **Common Closure Principle / Single Responsibility Principle**: the reason request/response models and Entities must stay separate.
- **Ivar Jacobson's Object Oriented Software Engineering (1992)**: the origin of both "Entity" and "use case."
