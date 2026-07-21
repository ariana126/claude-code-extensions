# Chapter 3: Paradigm Overview

## Core Idea
There are exactly three programming paradigms — structured, object-oriented, and functional — and each one *removes* a capability rather than adding one: they take away `goto`, function pointers, and assignment respectively. This is a short framing chapter; its density is in the three one-line definitions and the "nothing left to take away" argument.

## Frameworks Introduced
- **The Three Paradigms as Disciplines**
  - When to use: whenever you need to explain *why* a language restriction exists, or to justify an architectural constraint by analogy.
  - How: memorize the three summary sentences verbatim and apply them as tests.
    - "Structured programming imposes discipline on direct transfer of control." (Dijkstra, 1968 — unrestrained jumps replaced by `if/then/else` and `do/while/until`.)
    - "Object-oriented programming imposes discipline on indirect transfer of control." (Dahl and Nygaard, 1966 — the ALGOL function call stack frame moved to the heap; the function became a constructor, local variables became instance variables, nested functions became methods, leading to polymorphism through disciplined use of function pointers.)
    - "Functional programming imposes discipline upon assignment." (Church's λ-calculus, 1936; LISP, McCarthy, 1958 — immutability means symbol values do not change, so a functional language has no assignment statement, though most provide some means to alter a variable under very strict discipline.)
  - Why it works / failure mode: the paradigms tell us what **not** to do more than what to do; each is *negative* in intent. Failure mode: treating a paradigm as a feature set to adopt ("we use classes, therefore we do OO") rather than as a restriction to obey.
- **The "Nothing Left to Take Away" Argument**
  - When to use: when someone announces a fourth paradigm.
  - How: check whether it removes a capability. The three paradigms together remove `goto` statements, function pointers, and assignment — there is probably nothing left to take away. Supporting evidence: all three were discovered within the ten years between **1958 and 1968**, and in the many decades since, no new paradigms have been added.

## Key Concepts
- **Paradigm**: a way of programming, relatively unrelated to languages, that tells you which programming structures to use and when to use them.
- **Structured programming**: discipline on direct transfer of control; discovered by Edsger Wybe Dijkstra in 1968 — first adopted, though not first invented.
- **Object-oriented programming**: discipline on indirect transfer of control; discovered by Ole Johan Dahl and Kristen Nygaard in 1966.
- **Functional programming**: discipline upon assignment; last adopted but first invented, from Alonzo Church's λ-calculus (1936).
- **Direct transfer of control**: `goto` and its restricted successors — where control goes next by explicit jump.
- **Indirect transfer of control**: dispatch through function pointers — the mechanism polymorphism is built on.
- **Immutability**: the foundational λ-calculus notion that the values of symbols do not change.
- **Negative discipline**: a restriction that removes capability from the programmer and adds none — the shared shape of all three paradigms.

## Mental Models
- Think of a paradigm as a subtraction, not an addition. If a proposed "new paradigm" adds power, it isn't one.
- Use the removal test to place any language feature: what does this discipline forbid, and what class of bug does that forbidding make impossible?
- Think of the three paradigms as mapping one-to-one onto the three big concerns of architecture — function, separation of components, and data management.
- Turing's 1938–1945 insight that programs are simply data is the floor everything sits on; loops, branches, assignment, subroutines, and stacks were all present in binary from the start. The revolutions since have been in restriction, not capability.

## Anti-patterns
- **Confusing language revolutions with paradigm revolutions**: the flood of languages (Fortran 1953, COBOL, PL/1, SNOBOL, C, Pascal, C++, Java, ad infinitum) is the less significant revolution; paradigms are relatively unrelated to languages.
- **Claiming a paradigm because you use its syntax**: OO is not "having classes"; it is the discipline imposed on indirect transfer of control.
- **Expecting a fourth paradigm**: the capabilities left to remove are exhausted, and nothing has appeared since 1968.

## Reference Tables

| Paradigm | Discovered | By | Removes | Discipline imposed on |
|---|---|---|---|---|
| Structured | 1968 | Edsger Wybe Dijkstra | `goto` (unrestrained jumps) | direct transfer of control |
| Object-oriented | 1966 | Ole Johan Dahl, Kristen Nygaard | function pointers | indirect transfer of control |
| Functional | 1936 (λ-calculus) / adopted last | Alonzo Church; LISP by John McCarthy, 1958 | assignment | variable assignment |

| Paradigm | Architectural use | Concern of architecture |
|---|---|---|
| Structured | algorithmic foundation of our modules | function |
| Object-oriented | the mechanism to cross architectural boundaries | separation of components |
| Functional | discipline on the location of and access to data | data management |

## Worked Example
The OO origin story is the compact example: Dahl and Nygaard noticed that the function call stack frame in ALGOL could be moved to a heap, letting local variables declared by a function exist long after that function returned. Everything OO follows mechanically from that one relocation — the function becomes a constructor for a class, the local variables become instance variables, and the nested functions become methods. Polymorphism then arrives inevitably, through the disciplined use of function pointers. No new capability was invented; a lifetime was extended and a discipline was imposed on the resulting dispatch.

## Key Takeaways
1. Learn the three summary sentences exactly — they are the vocabulary the rest of the book reasons in.
2. A paradigm removes a capability; it never adds one. Judge candidates by what they forbid.
3. Structured, OO, and functional remove `goto`, function pointers, and assignment. That is the whole inventory.
4. All three were discovered between 1958 and 1968 and none has been added since — expect no fourth.
5. Map paradigms onto architectural concerns: polymorphism crosses boundaries, functional discipline governs data, structured programming underpins module algorithms.

## Connects To
- **Ch 4**: the full case for structured programming, Dijkstra's proofs, and falsifiability.
- **Ch 5**: what indirect transfer of control buys the architect — dependency inversion and plugin architecture.
- **Ch 6**: immutability, segregation of mutability, and event sourcing as the practical form of "discipline upon assignment."
- **Ch 22 (The Clean Architecture)**: boundary crossing via polymorphism is the direct application of the OO line here.
- **Böhm–Jacopini theorem**: the sequence/selection/iteration result that makes the structured restriction sufficient (developed in Ch 4).
