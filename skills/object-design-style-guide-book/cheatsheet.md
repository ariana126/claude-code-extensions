# Cheatsheet — Object Design Style Guide

## Read the signature, know the object

| Signature | Verdict |
|---|---|
| `setPassword(string): void` | Mutable. Command method. ✓ |
| `withPassword(string): User` | Immutable. Modified copy. ✓ |
| `withPassword(string): void` | Mutable, **badly named** — declarative name, void return |
| `setPrice(Money): Product` | **Confused** — imperative name, non-void return. Which is it? |
| `increment(): int` | **CQS violation** — changes state *and* returns |
| `isValid(string): string\|bool` | **Mixed return type** — pick one |
| `findOneBy(type): Page?` | Nullable — prefer throw, null object, or empty value |

## Where does this argument go?

- Collaborating service → **constructor** (required, no default)
- Configuration value → **constructor** (required, no default)
- Task data → **method**
- Anything called "the current X" → **method**. The word **"current"** is the tell.

**Batch test**: *"Could I run this service in a batch without reinstantiating it?"* If no, the argument belongs on the method.

## Which exception?

**One question: could you know it's wrong by looking only at the value provided?**

- Yes → `InvalidArgumentException` / `LogicException`. Programming mistake. Fail hard, don't catch. Name it **"Invalid…"**. No custom subclass.
- No → `RuntimeException`. External condition. Recoverable. Name it by finishing **"Sorry, I …"** → **"CouldNot…"**.

Custom exception class only if: you'll catch it specifically **or** there are multiple ways to fail **or** you want named constructors. Drop the "Exception" suffix.

## Which test double?

| The dependency method is a… | Use | Assert on calls? |
|---|---|---|
| **Command** (`save()`, `dispatch()`) | mock, spy | **Yes** — at least once, not more |
| **Query** (`getById()`, `exchangeRateFor()`) | dummy, stub, fake | **Never** |

Write stubs and fakes by hand. Mocking tools at most for dummies.

## Mutability decision tree

- Is it a **service**? → immutable. Always.
- Is it an **entity**? → mutable. That's its job.
- Is it a **DTO**? → mutable, public properties, few rules.
- Anything else → **immutable**.

Immutability is **transitive** — a getter returning a mutable collection undoes it.

## Changing behavior: climb in this order

1. Constructor argument → configurable value
2. Constructor argument → replaceable dependency (extract an abstraction)
3. Composition — combine implementations
4. Decoration — layer behavior on any implementation
5. Event listener / notification object — let others respond

**Never**: inheritance. Template method converts to #2 in one step — promote the `abstract protected` method to `public` on an injected object.

## Is this an abstraction? (both required)

1. An interface, not a class
2. A name with **no implementation details**

`HttpClient` → fails #2. `ExchangeRates`, `FileLoader`, `Queue`, `Clock` → pass.

**Abstract early. Generalize after ~3 similar cases.**

## Escalation before creating a class

Better variable name → extract a private method → **new class only if** it's too large, needs separate testing, or crosses a system boundary.

## Is this method too big? (3 yeses = split it)

1. Does the name have — or want — an "and" in it?
2. Do all lines contribute to the **main** job?
3. Could part of it run in a background process?

## Service statelessness

**Reinstantiation test**: *"Could I reinstantiate this before every call and get the same behavior?"*
If no → don't add a flag. **Move the invariant into a value object.**

## Read models: pick your build strategy

| From | Runtime | Maintenance | Use when |
|---|---|---|---|
| Write model | High | Low | Stopgap only — client still sees the write model |
| **Data source (SQL)** | Low | **Low** | **Default** |
| Domain events | Lowest | High | Write model changes often, raw data needs interpretation, or recomputation is too costly |

## Method skeleton

```
preconditions → failure scenarios → happy path → postconditions → return
```
Failure checks at the top. Return early. Eliminate `else`. Strong types delete preconditions; tests delete postconditions.

## Constructor rules (services)

Do exactly two things: **validate, then assign.**
Tell that you broke it: **reordering the assignments changes the behavior.**

## Testing tells

- Adding a getter so a test can see inside → use **recorded domain events** instead
- Asserting on query-method calls → couples the test to the implementation
- Test doubles for things that *don't* cross a system boundary → you're class-testing, not object-testing
- Test passes but the code is wrong → **the test suite is what's incomplete**

**The governing rule**: write tests so that as many implementation details as possible could change before the test must.

## Defaults

`final` on every class. `private` on every property and method. Once classes are `final`, `protected` has no purpose.

Only exception to `final`: a genuine type hierarchy where the subclass is a *special case* of the parent.

## Layers — dependencies point inward only

```
Infrastructure  controllers, repository IMPLEMENTATIONS
Application     application services, command objects, read models,
                read model repository INTERFACES, event listeners
Domain          entities, value objects, write model repository INTERFACES
```

Gets an interface: repositories and anything crossing a system boundary.
Does **not**: controllers, application services, entities, value objects, read models.

Put layer names in namespaces.
