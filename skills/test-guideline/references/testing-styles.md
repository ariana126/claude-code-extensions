# Testing Styles and Functional Architecture

Read this when deciding how to restructure production code so that better tests
become possible — especially when a test needs elaborate mock setup and you
suspect the code, not the test, is at fault.

## The Three Styles

A single test may use one, two, or all three. They differ in what counts as the
outcome being verified.

**Output-based.** Feed an input to the SUT, check what comes back. Applicable
only to code that changes no state.

```
sut = PriceEngine()
discount = sut.calculateDiscount(handWash, shampoo)
assert discount == 0.02
```

**State-based.** Perform an operation, then verify the resulting state — of the
SUT itself, of a collaborator, or of an out-of-process dependency.

```
sut = Order()
sut.addProduct(handWash)
assert sut.products == [handWash]
```

**Communication-based.** Substitute collaborators with mocks and verify the SUT
called them correctly.

```
emailGateway = mock()
sut = Controller(emailGateway)
sut.greetUser("user@email.com")
assert emailGateway.received(sendGreeting, "user@email.com")
```

The classical school prefers state-based, the London school
communication-based; both use output-based where they can.

## Why the Ranking

| | Output-based | State-based | Communication-based |
|---|---|---|---|
| Effort to stay resistant to refactoring | Low | Medium | Medium |
| Maintainability cost | Low | Medium | High |

Protection against regressions and speed are **roughly equal across all three**.
Protection depends on how much significant code runs, not on style. Speed
differs only negligibly — mocks add a little runtime overhead, irrelevant below
tens of thousands of tests. So the ranking is decided entirely by the other two
pillars.

The refactoring-resistance ordering has a structural explanation. An
output-based test couples to nothing but the method's signature; the only way it
can break spuriously is if the method itself turns out to be an implementation
detail. A state-based test additionally touches the class's state — a larger API
surface, so more chances of catching a leaked internal. A communication-based
test is the most exposed: it is *always* wrong when applied to stubs, and right
for mocks only across the application boundary.

Maintainability follows the same shape. Output-based assertions are one line.
State-based assertions grow with the shape of the state. Communication-based
tests accumulate mock setup, and in the worst case **mock chains** — a mock
returning a mock returning a mock — which is the single largest driver of
unmaintainable test suites.

### Shrinking a bloated state-based assertion

When a state-based test needs four assertions to check one conceptual outcome,
there are two mitigations, both narrow:

- **Helper methods** that bundle the assertions. Only worth writing if reused
  across many tests; they are real code with real maintenance cost.
- **Turn the thing being asserted on into a value object**, so a single equality
  check covers it. This only applies when the class genuinely *is* a value.
  Converting a non-value into one to make a test shorter is code pollution.

Even after mitigation, state-based tests stay larger than output-based ones.

## What Makes Output-Based Testing Possible

Output-based testing works only on **mathematical functions** — methods with no
hidden inputs or outputs, where everything is expressed in the signature. Given
the same input they produce the same output, however many times you call them.

There are exactly three kinds of hidden input/output to hunt for:

1. **Side effects** — an output not in the signature: mutating the instance's
   state, writing a file, sending a request.
2. **Exceptions** — a path that bypasses the contract the signature establishes,
   catchable anywhere up the stack. An additional output the signature doesn't
   convey.
3. **References to internal or external state** — `Date.now()`, a database query,
   a mutable private field read during the call. Hidden *inputs*.

### The purity test: referential transparency

Can you replace a call to the method with its return value without changing the
program's behavior?

```
y = increment(4)      ≡   y = 5        → pure
```

```
counter.incrementAndGet()   // returns 5, but also mutated the counter
```

The second cannot be substituted, because the mutation is a hidden output. That
is the whole test, and it is quick enough to apply mentally to any method.

### Collaborator or value?

This distinction decides purity, and it is subtler than "is it passed in?"

A `maxEntriesPerFile` number taken in the constructor *looks* like a dependency
but is a **value**: it is immutable between construction and the call, and
derivable from the signature. A database handle taken in the constructor is a
**collaborator**: a proxy to data that is not yet in memory, so its contents
cannot be known from the signature.

The rule that falls out: **a class in the functional core should work not with a
collaborator, but with the product of its work — a value.** Don't pass the
database; pass the rows.

## Functional Architecture

Functional architecture maximizes the code written in a purely functional way
while minimizing the code that deals with side effects. The goal is **not to
eliminate side effects** — a program with no side effects does nothing useful —
but to **push them to the edges of a business operation**.

Two categories of code:

- **Code that makes a decision.** No side effects needed, so it can be written as
  mathematical functions. This is the **functional core** (or immutable core).
- **Code that acts on that decision.** Converts decisions into visible effects:
  database writes, messages, files. This is the **mutable shell**.

The cooperation loop is **read → decide → act**:

1. The shell gathers all inputs.
2. The core takes those inputs and returns decisions.
3. The shell converts the decisions into side effects.

### The critical discipline

**The decisions must contain enough information for the shell to act without
making any further decisions.** The shell should be as dumb as possible — ideally
with no branching at all. Every `if` in the shell is complexity in a place you
have chosen not to unit test.

The payoff is a core covered extensively by cheap output-based tests, and a
shell so thin that a handful of integration tests suffice.

### Relationship to hexagonal architecture

Both separate concerns and enforce one-way dependency flow — the core never
depends on the shell. **The difference is the treatment of side effects.**

Hexagonal architecture is fine with the domain layer producing side effects as
long as they stay *within* that layer: a domain object mutates itself, and an
application service picks that up and persists it. Functional architecture
pushes side effects out of the core entirely; the core returns instructions and
touches nothing.

Functional architecture is hexagonal architecture taken to an extreme.

### A design rule for the boundary

Keep the data structures crossing the boundary as close as possible to what the
platform's primitives already give you, and do all parsing **inside the core**.
If the runtime hands you a raw string, put the string in the input structure and
parse it in the core — don't parse it in the shell to produce something tidier.
Parsing is decision-making, and decision-making belongs where the tests are.

## When Not to Apply This

The costs are real and worth stating plainly:

- **Performance.** The shell must gather all inputs up front, which means
  querying for data the operation may turn out not to need.
- **Initial code size.** You are trading a larger codebase for a more
  maintainable one.

In a simple codebase, or one whose logic carries little business importance, the
investment never pays back. Apply functional architecture strategically, based
on the complexity and significance of the system.

And more generally: **don't chase purity.** In an object-oriented language you
will end up with a mixture of all three styles, and that is the correct outcome.
The goal is to move as many tests toward output-based as is reasonable — not to
convert them all.

## When the Core Needs Data It Cannot Have Up Front

The common breaking case: the core needs to consult an external system, but only
sometimes, and only partway through its reasoning. You cannot pass the database
in — that reintroduces a hidden input and the method stops being a mathematical
function. Two escape hatches:

**Gather it unconditionally.** Fetch the extra data in the shell alongside
everything else, whether or not it turns out to be needed.
*Cost:* performance — a query you often don't use.
*Benefit:* separation stays fully intact; all decision-making remains in the core.

**Expose a question the shell can ask first.** Add something like
`isAccessCheckRequired()` to the core; the shell calls it and only fetches the
extra data when the answer is yes.
*Cost:* a degree of separation — the decision to call the database now lives in
the shell.
*Benefit:* no wasted queries.

Both are legitimate. Pick based on whether the wasted query or the leaked
decision costs you more in your particular case.
