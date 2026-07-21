# Chapter 9: LSP: The Liskov Substitution Principle

## Core Idea
Subtypes must be substitutable for their base types from the point of view of every user of that base type — and this applies far beyond inheritance, to any interface with multiple implementations. A single violation of substitutability forces the architecture to grow significant extra mechanism just to cope.

## Frameworks Introduced
- **The Liskov Substitution Principle (LSP)** — Barbara Liskov, 1988, as a definition of subtypes: *"If for each object o1 of type S there is an object o2 of type T such that for all programs P defined in terms of T, the behavior of P is unchanged when o1 is substituted for o2, then S is a subtype of T."*
  - When to use: designing any inheritance hierarchy, any Java-style interface with several implementers, any set of Ruby classes sharing method signatures, and any set of services responding to the same REST interface.
  - How to test a candidate subtype:
    1. Enumerate the programs P written against the base type T — the *users*, not the subtypes.
    2. Ask whether the observable behavior of each P is unchanged when the subtype is swapped in.
    3. Check the base type's implicit contract, including invariants users rely on (e.g. "height and width are independently mutable").
    4. If any user needs an `if` to detect which subtype it actually has, substitutability has already failed.
  - Why it works: users depend on well-defined interfaces *and* on the substitutability of the implementations behind them. Substitutability is what lets a user be written once and reused across every implementation.
  - Failure mode: the only defense against a violation is to add detection mechanisms (an `if`) into the *user*. Since the user's behavior now depends on the types it uses, those types are by definition not substitutable — the fix confirms the disease.

- **LSP extended to architecture**: the principle "morphed" from an inheritance guide into a broad design principle about interfaces and implementations of any form.
  - Diagnostic: look at what happens to a system's architecture when substitutability is violated — you get special-case branches, then configuration-driven machinery to contain those branches.
  - Containment technique (when you cannot fix the offending implementation): replace hard-coded special cases with a **command-creation module driven by a configuration database keyed by the dispatch URI**.

## Key Concepts
- **Substitution property**: the behavior of programs written against T is unchanged when an S is substituted.
- **Subtype**: S is a subtype of T only if the substitution property holds for all users of T.
- **User**: the program written in terms of the base type; the LSP is judged from the user's perspective, never the subtype's.
- **Interface (broad sense)**: a Java interface, a shared set of Ruby method signatures, or a common REST interface — LSP applies to all of them.
- **Conforming hierarchy**: `License` with `calcFee()`, subtyped by `PersonalLicense` and `BusinessLicense` — different algorithms, identical contract, so `Billing` never knows the difference.
- **Independently mutable properties**: `Rectangle`'s height and width; `Square` cannot honor this, which is why it is not a subtype.
- **Extra mechanism**: the architectural cost of a violation — special cases, config tables, dispatch modules.

## Mental Models
- Think of a subtype as a **promise to the user, not a relationship to the parent**. "Is-a" in English is irrelevant; only "behaves-as, from the caller's seat" counts.
- Use "does any caller need to ask what type this really is?" as the LSP smoke test. An `if` on type or on a URL prefix is the violation made visible.
- Think of REST endpoints, message formats, and plugin APIs as **types**: an abbreviated field name (`dest` instead of `destination`) is an LSP violation in exactly the sense Liskov meant.
- Treat a growing configuration table of per-vendor quirks as **the price tag of a substitutability failure**, not as flexible design.

## Code Examples
```java
Rectangle r = …
r.setW(5);
r.setH(2);
assert(r.area() == 10);
```
- **What it demonstrates**: if `…` produced a `Square`, the assertion fails — the `User` believed it held a `Rectangle` whose height and width are independently mutable, so `Square` is not a proper subtype.

```java
if (driver.getDispatchUri().startsWith("acme.com"))…
```
- **What it demonstrates**: the tempting one-line fix for a non-substitutable REST implementation; putting "acme" in the code invites horrible and mysterious errors and security breaches.

## Reference Tables

Configuration data replacing the hard-coded special case in the taxi aggregator:

| URI | Dispatch Format |
|---|---|
| `Acme.com` | `/pickupAddress/%s/pickupTime/%s/dest/%s` |
| `*.*` | `/pickupAddress/%s/pickupTime/%s/destination/%s` |

## Worked Example
**The taxi dispatch aggregator.**

We build an aggregator over many taxi dispatch services. Customers use our website to find the most appropriate taxi regardless of company; once they choose, our system dispatches that taxi through a restful service. The dispatch URI lives in the driver database, so after selecting a driver we read the URI from the driver record and use it.

Driver Bob's URI is `purplecab.com/driver/Bob`. We append the dispatch information and send it with a PUT:

```
purplecab.com/driver/Bob
       /pickupAddress/24 Maple St.
       /pickupTime/153
       /destination/ORD
```

This only works if every company's dispatch service conforms to the same REST interface and treats `pickupAddress`, `pickupTime`, and `destination` identically.

Then Acme — the largest taxi company in our area, whose CEO's ex-wife is our CEO's new wife — hires programmers who don't read the spec carefully and abbreviate the destination field to `dest`. The obvious patch is `if (driver.getDispatchUri().startsWith("acme.com"))…`, which no architect worth their salt would allow: hard-coding "acme" invites mysterious errors and security breaches. And the special cases multiply — if Acme buys Purple Taxi and unifies the systems while keeping separate brands and websites, do we add another `if` for "purple"?

The architect must instead build a dispatch-command creation module driven by a configuration database keyed by the dispatch URI (see table above). One company's careless field name has forced a significant and complex mechanism into the architecture.

## Key Takeaways
1. Judge subtypes from the user's side: behavior of programs written in terms of T must be unchanged.
2. `Square` is not a subtype of `Rectangle` because `Rectangle`'s height and width are independently mutable and `Square`'s must change together.
3. Any `if` in a user that detects the real type is proof of a violation, not a fix.
4. The LSP governs REST interfaces, duck-typed classes, and service contracts — not just inheritance.
5. A single non-substitutable implementation pollutes the architecture with extra mechanism; the configuration-table workaround is the cost you pay.
6. Never encode a vendor's name in policy code; drive variance from data keyed by the endpoint.

## Connects To
- **Ch 8 (OCP)**: substitutable implementations behind an interface are what make extension-without-modification possible.
- **Ch 11 (DIP)**: depending on abstractions is only safe if every implementation of the abstraction is substitutable.
- **Ch 10 (ISP)**: both are about what users may safely assume about the things they depend on.
- **Design by Contract (Meyer)**: preconditions may not be strengthened nor postconditions weakened in a subtype — the formal statement of this chapter's test.
- **Ch 25 / plugin architectures**: plugins are only pluggable while they remain substitutable.
