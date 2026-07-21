# Chapter 4: Structured Programming

## Core Idea
Structured programming's lasting value is not the elimination of `goto` for its own sake — it is that restricting direct transfer of control makes programs recursively decomposable into small **provable** (that is, falsifiable) units, and software, like science, advances by failing to prove things incorrect.

## Frameworks Introduced
- **Structured Programming as Restricted Direct Transfer of Control**
  - When to use: at every level, from the smallest function to the largest component.
  - How: build all control flow from exactly three structures — **sequence, selection, and iteration** — which Böhm and Jacopini proved (two years before Dijkstra's letter) are sufficient to construct all programs. Dijkstra's contribution was noticing that these same structures are precisely the ones that make a module recursively subdividable into provable units: certain uses of `goto` prevent recursive decomposition into smaller and smaller units and thereby block the divide-and-conquer approach necessary for reasonable proofs, while the "good" uses of `goto` correspond exactly to `if/then/else` and `do/while`.
  - Why it works / failure mode: the minimum set of control structures from which all programs can be built is the *same* set that makes modules provable — that coincidence is what makes the restriction cost-free. Failure mode: a program that is not provable, due to unrestrained use of `goto` for example, cannot be deemed correct no matter how many tests are applied to it.
- **Functional Decomposition**
  - When to use: at the architectural level as much as the code level — this is why it remains one of our best practices.
  - How: take a large-scale problem statement and decompose it into high-level functions; decompose each of those into lower-level functions, ad infinitum; represent each decomposed function using only the restricted control structures. This is what structured analysis and structured design (Ed Yourdon, Larry Constantine, Tom DeMarco, Meilir Page-Jones, late 1970s–1980s) systematized.
- **Falsifiability as the Test Discipline**
  - When to use: instead of formal proof — the Euclidean hierarchy of theorems was never built and few of today's programmers believe formal proofs are an appropriate way to produce high-quality software.
  - How: decompose recursively into small provable functions, then use tests to try to prove those functions *incorrect*. If tests fail to prove incorrectness after sufficient effort, deem the functions correct enough for your purposes. Architects apply the same move at higher levels: define modules, components, and services that are easily falsifiable (testable) by employing restrictive disciplines similar to structured programming.

## Key Concepts
- **Direct transfer of control**: control flow by explicit jump; structured programming imposes discipline on it.
- **Sequence, selection, iteration**: the Böhm–Jacopini minimum set from which all programs can be constructed.
- **Provable unit**: a module small enough and control-restricted enough to be subdivided and reasoned about — Dijkstra proved sequence by simple enumeration (tracing inputs to outputs), selection by reapplication of enumeration over each path, and iteration by **induction** (case 1 by enumeration, then N ⇒ N+1, plus starting and ending criteria by enumeration).
- **"Go To Statement Considered Harmful"**: Dijkstra's March 1968 letter to the editor of *CACM*; the ensuing battle lasted about a decade and Dijkstra won — the `goto` statement moved ever rearward until it all but disappeared.
- **Falsifiable but not provable**: the nature of scientific theories and laws; mathematics proves provable statements *true*, science proves provable statements *false*.
- **"Testing shows the presence, not the absence, of bugs"** (Dijkstra): a program can be proven incorrect by a test, but never proven correct.
- **Correct enough for our purposes**: the achievable standard — what remains after sufficient testing fails to demonstrate incorrectness.
- **Structured analysis / structured design**: the 1970s–80s disciplines built on functional decomposition.

## Mental Models
- Think of software as a science, not a mathematics: you show correctness by failing to prove incorrectness, despite your best efforts. You bet your life daily on *F* = *ma* and *F* = *Gm*₁*m*₂/*r*², neither of which is provable.
- Use provability as your unit-size criterion: decompose until each unit is small enough that a test could falsify it. If you cannot write a test that could fail meaningfully, the unit is too tangled.
- Think of unrestrained control transfer as destroying testability, not just readability — untestable is the operative harm.
- Apply the structured restriction fractally: architects impose restrictive disciplines similar to structured programming, albeit at a much higher level.

## Anti-patterns
- **Unrestrained direct transfer of control**: prevents recursive decomposition, so no amount of testing can deem the program correct. (Named `break`s in Java and exceptions are *not* `goto` analogs — they are not utterly unrestricted transfers of control like older Fortran or COBOL had; even surviving `goto` keywords typically restrict the target to within the scope of the current function.)
- **Waiting for formal proofs**: the proofs never came; the Euclidean hierarchy was never built; Dijkstra's dream faded and died. Don't gate quality on it.
- **Claiming tests prove correctness**: they cannot. They only fail to prove incorrectness.
- **Components too coarse to falsify**: a service you cannot try to prove wrong is a service you cannot deem right.

## Reference Tables

| Structure | Proof technique | Method |
|---|---|---|
| Sequence | Enumeration | Trace the inputs of the sequence to its outputs |
| Selection | Reapplication of enumeration | Enumerate each path; both must produce appropriate results |
| Iteration | Induction | Prove case 1 by enumeration; prove N ⇒ N+1 by enumeration; prove start/end criteria by enumeration |

| Discipline | Proves statements... | Yields |
|---|---|---|
| Mathematics | provable statements **true** | proof |
| Science | provable statements **false** | theories deemed true enough for our purposes |
| Software | — | falsifiable units; correctness by failure to falsify |

## Worked Example
Dijkstra's problem, stated concretely: programming is *hard*, and programmers don't do it very well — a program of any complexity contains too many details for a human brain to manage without help, and overlooking one small detail yields programs that *seem* to work but fail in surprising ways. His answer was to apply the mathematical discipline of proof, building a Euclidean hierarchy of postulates, theorems, corollaries and lemmas that programmers could use the way mathematicians do: use proven structures, tie them together with your own code, prove that correct.

Demonstrating the technique on simple algorithms turned out to be the hard part, and in the attempt he found the real result. Some uses of `goto` blocked recursive subdivision; the ones that did not corresponded to `if/then/else` and `do/while` — exactly the Böhm–Jacopini set. So the control structures that make a module provable are the same minimum set from which all programs can be built. Structured programming was born from that coincidence.

The proofs themselves were laborious but real, and they never scaled to practice. What survived is the decomposition, and the substitute for proof is the scientific method: decompose into small provable functions, attack each with tests trying to show it wrong, and accept what survives. Note the residual honesty — not all statements are provable at all; "This is a lie" is neither true nor false.

## Key Takeaways
1. Restrict control flow to sequence, selection, and iteration — that restriction is what buys you decomposable, testable units.
2. Decompose recursively until every unit is falsifiable; that is the working definition of "small enough."
3. Tests can only show the presence of bugs, never their absence. Design so that tests have the best possible chance of finding them.
4. A program that isn't provable can't be certified correct by any quantity of tests — testability is a structural property, not a testing-effort property.
5. Formal proof failed as a practice; falsifiability replaced it. Architect for falsifiability at the module, component, and service level.
6. Functional decomposition survives as an architectural best practice precisely because of falsifiability, not tradition.

## Connects To
- **Ch 3**: this is the full case for "structured programming imposes discipline on direct transfer of control."
- **Ch 5**: OO does the analogous thing for *indirect* transfer of control.
- **Ch 6**: functional programming applies the same negative discipline to assignment.
- **Ch 28 (The Test Boundary) and the Humble Object Pattern**: designing for falsifiability at the architectural boundary.
- **Popper's falsifiability**: the direct philosophical source of the science analogy.
- **TDD**: the operational form of "try to prove each small unit incorrect."
