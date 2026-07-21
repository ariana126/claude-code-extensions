# Appendix A: Architecture Archaeology

## Core Idea
A 45-year retrospective across roughly a dozen systems (1970–early 1990s) in which every principle in this book was first learned the expensive way — by shipping the mistake. The lessons, not the chronology, are the payload: boundaries pay, shortcuts compound, and great architecture that ignores the size of the problem fails just as hard as no architecture.

## Frameworks Introduced
*These are recurring lessons Martin extracts, not named patterns.*

- **Device Independence Pays, Every Time**: Applications must not know which device their output goes to.
  - Where it showed up: in the Union Accounting overlay system, applications simply passed strings to the supervisor, which loaded the buffers, dribbled characters out at 30 cps, and swapped applications in and out. The applications had no idea a 30-cps terminal existed. That character-output boundary was *dependency normal* — dependencies pointed with the flow of control. A second boundary was *dependency inverted*: the supervisor could start applications but had no compile-time dependency on them, because every application was started by jumping to the exact same memory address in the overlay area. That single fixed address was the polymorphic interface.
  - Why it works: two boundaries, two directions, both hiding what the other side does not need to know — object orientation and DIP discovered accidentally in assembler.

- **Independent Deployability, Invented Under Duress (Vectorization)**: When shipping a change costs too much, restructure until only the changed part ships.
  - The problem: the 4-TEL COLT ran a single 30K 8085 binary burned across 30 EPROM chips. Any change anywhere shifted every address, so all 30 chips had to be reburned, relabeled, shipped, and swapped by field engineers — who mislabeled chips, replaced the wrong ones, and snapped pins, and so had to carry spares of all 30.
  - How: (1) split the 30K program into 32 independently compilable source files under 1K each; (2) `ORG` each to its chip's address (e.g. `ORG C400`); (3) put a fixed 40-byte table of that chip's subroutine addresses at the start of each file — 20 addresses max, so no chip could hold more than 20 subroutines; (4) reserve a RAM vector area of 32 × 40 bytes; (5) change every call into an indirect call through the RAM vector; (6) on boot, scan each chip and load its table into the RAM vectors, then jump to main.
  - Result: "We had made the chips independently deployable. We had invented polymorphic dispatch. We had invented objects." Literally a plugin architecture — plug a chip into an open socket and the menu entry and binding appear automatically. Unexpected bonus: firmware could be patched over a dial-up connection by repointing a RAM vector at a hand-entered hex subroutine, eliminating emergency field visits.

- **The Boundary That Saved the Project (SAC/COLT split)**: Move the work to the side of the wire where it belongs.
  - Originally the COLTs (in the central office) did everything — console communication, menus, reports — and the SAC was a dumb multiplexor. At 30 cps testers watched characters trickle across the screen for a few bits of data they cared about, and M365 core memory was expensive.
  - The fix: separate dialing-and-measuring (stays in the COLT) from analysis-and-reporting (moves to the SAC). Screen updates became very fast, and the COLT's memory footprint shrank a lot. The boundary was clean and highly decoupled: very short packets in a simple DSL — `DIAL XXXX`, `MEASURE`.

- **Isolate Hardware from Business Rules**: The modem fiasco.
  - Modem control code was smeared bit-level throughout 60,000 lines of SAC assembler, as was terminal UI formatting. When the company designed its own modem, the software group begged the hardware engineer to keep the bit formats identical. The new control structure was entirely, completely different — and old and new modems had to coexist in the same systems.
  - There were hundreds of places to patch. Instead they hacked the one subroutine that wrote to the serial bus, making it recognize old-modem bit patterns and translate them, in sequence, into different IO addresses, timings, and bit positions. It worked, and it was the worst hack imaginable. That fiasco is where the value of isolating hardware from business rules and abstracting interfaces was learned.

- **Databases Are Details — Learned by Paying (VRS)**: Embedded SQL let you put SQL strings anywhere in C code, so they put them everywhere, along with vendor-specific UNIFY API calls. Then UNIFY was cancelled. After roughly three months trying to migrate to another vendor, they gave up: so coupled to UNIFY that restructuring was hopeless at any practical expense. They hired a third party to maintain the dead product under contract, at rates that rose year after year.

## Key Concepts
- **Officially rigid code**: The dispatch-determination module — brilliant, incomprehensible, written by someone who then quit; every attempt to change it broke it, so management ordered it locked down and never modified. Its economic importance made each new defect deeply embarrassing. This is where the value of good, clean code was impressed on Martin.
- **The Grand Redesign in the Sky**: The Tiger Team's total rewrite of the SAC in C on UNIX. The first attempt burned two or three man-years and delivered nothing. The second, started around 1982, took years, then more years; Martin left in 1988 and is not sure it was ever deployed. *It is very difficult for a redesign team to catch up with a large staff of programmers actively maintaining the old system.*
- **The fork that never came back**: U.K. developers forked the U.S. SAC code for European phone systems because networks couldn't move large codebases across the ocean. Bugs found on one side needed fixing on the other, but the modules had diverged. Reintegration failed the first, second, and third times it was tried — and the rewrite team then had to handle the same dichotomy.
- **The schedule trap**: CCU/CMU development was postponed repeatedly because customer schedules kept slipping and "we had plenty of time." Then a customer deployed a digital switch *next month*, against man-years of remaining work.
- **Over-architecture (ROSE)**: More layers than needed, each with its own communications overhead, significantly reducing team productivity. Plus an object-oriented database — "we wanted the magic, but what we got was a big, slow, intrusive, expensive third-party framework that made our lives hell." After many man-years and two tepid releases, the whole tool was scrapped and replaced by a cute little application written by a small team in Wisconsin.
- **Dependencies pointed the wrong way**: ROSE had a *strictly enforced* dependency rule — but pointed in the traditional direction of flow of control (GUI → representation → manipulation rules → database), not toward high-level policy. That failure to point dependencies at policy aided the product's demise.
- **Reusable ≠ usable**: Vignette Grande, built over a year, produced 45,000 lines of "reusable" framework and 6,000 lines of application. It did not fit the next applications — subtle frictions everywhere. Restarting with four vignettes developed *simultaneously* produced another 45,000-line framework plus four 3,000–6,000-line vignettes, after which applications did pop out every few weeks as promised. Cost of the lesson: nearly a year of schedule.
- **Architectures can differ wildly and both be right (DLU/DRU)**: Martin's DLU used a dataflow/pipes-and-filters model — small focused tasks passing output through queues, like an assembly line that sometimes splits and merges. Mike Carew's DRU used one large task per terminal doing the entire job, no queues, no data flow — many expert builders each building a whole product. Both worked quite well.
- **There is nothing new under the Sun**: CDS externalized its finite state machine into a text file, so the application flow changed without changing code (the Open–Closed Principle), services could be added independently and wired in by editing the file — even while the system was running (hot-swapping, an effective BPEL). Communication used the 3DBB shared-memory store, addressable by name but strings-only (MP/M memory partitions made pointers meaningless across processes), so Martin invented **FLD (Field Labeled Data)**: binary trees associating names with data in a recursive hierarchy, queryable by API, serializable to a string. Micro-services communicating through a shared-memory analog of sockets using an XML analog — in 1985.

## Mental Models
- Think of every hard-won boundary as insurance you are buying against a change you cannot yet see. The pCCU story is the counter-case: dialing and measurement lived in the same COLT device, and when digital switches forced them apart, "we could have saved ourselves a fortune had we recognized that obvious architectural boundary a few years earlier."
- Use the "we begged the hardware engineer" test: if your defense against a change is that someone else promises not to make it, you have no defense. Abstract the interface instead.
- Think of a shortcut's cost as compounding, not fixed. Embedded SQL everywhere cost three months of failed migration and then a perpetual, escalating maintenance contract.
- Use size as an architectural input: "great architectures sometimes lead to great failures. Architecture must be flexible enough to adapt to the size of the problem. Architecting for the enterprise, when all you really need is a cute little desktop tool, is a recipe for failure."
- Think of frameworks as reuse you have not yet earned: **you can't make a reusable framework until you first make a usable framework** — reusable frameworks require building them in concert with *several* reusing applications.

## Anti-patterns
- **Smearing a mechanism through the codebase**: Modem bit-twiddling, terminal formatting, and embedded SQL all "smeared everywhere" — each cost a fiasco. Gather mechanisms into modules and abstract the interface.
- **The grand rewrite**: Two Tiger Team attempts, one delivering nothing, the other possibly never deployed, while the old system kept moving.
- **Forking instead of parameterizing**: The U.K./U.S. SAC fork could not be reintegrated after three attempts; the differences should have been configuration.
- **Deferring known architectural work because the customer's schedule slipped**: The CCU/CMU schedule trap — man-years of work due in a month.
- **Over-architecture**: Too many layers, each with communications overhead, plus an intrusive third-party OO database. Scrapped entirely.
- **Pointing the dependency rule at flow of control instead of policy**: ROSE enforced its rule strictly and still failed, because the rule pointed the wrong way.
- **Speculative reuse**: Building a framework against one application and promising the rest will "just pop out."
- **No architecture because "this is a startup"**: At Clear Communications — 70–80 hour weeks, castles in the air, a full seven-layer ISO stack written from scratch down to the data link layer, and a personally authored 3,000-line C function named `gi()`. Three years of coding, one or two installations, and no sales.

## Worked Example
**Vectorization, the invention of objects in 8085 assembler.**

| Before | After |
|---|---|
| One 30K binary, split blindly into 30 × 1K chip images | 32 independently compilable source files, each < 1K, each `ORG`'d to its own chip address |
| Any change shifts every instruction and subroutine address | Addresses are resolved at boot through a RAM vector table |
| All 30 chips reburned, relabeled, shipped, hand-swapped | Recompile one or two chips; ship only those |
| Direct calls to fixed subroutine addresses | Indirect calls through the RAM vector — polymorphic dispatch |
| Bug fix = urgent field service call | Bug fix = dial in, repoint the vector at hand-entered hex, install the chip at the next scheduled visit |
| New feature = full rebuild | New feature = plug a chip into an open socket; menu control and binding appear automatically |

Three months of work. Independent deployability, polymorphism, objects, and a plugin architecture — arrived at with no knowledge of object-oriented principles and no notion of separating UI from business rules. "But the rudiments were there, and they were very powerful."

## Key Takeaways
1. Find the boundary *before* the market forces it on you. The pCCU/CCU-CMU split was obvious years earlier and would have saved a fortune.
2. Isolate hardware, devices, UI, and databases from business rules, and abstract the interfaces. Every system here that failed to do so paid for it — modems, terminals, embedded SQL.
3. Make deployment granular. Independent deployability turned a 30-chip logistics nightmare into a one-chip shipment and invented polymorphism along the way.
4. Point dependencies at high-level policy, not at the flow of control. ROSE enforced a dependency rule rigorously and still died, because the rule pointed the wrong way.
5. Size the architecture to the problem. Over-architecture is as fatal as none: many man-years and two releases lost to a tool a small team replaced with something cute and little.
6. You cannot make a reusable framework until you first make a usable one — build it in concert with several reusing applications, or pay a year.
7. Don't bet on a grand redesign catching up with a staffed, actively maintained system. It usually doesn't, and the fork you took meanwhile makes it worse.
8. Clean code is an economic asset. Code nobody understands becomes officially rigid — frozen by management decree, with every defect a public embarrassment.
9. Wildly different architectures can both be effective (DLU dataflow vs. DRU task-per-terminal). Rigor about boundaries matters more than picking the "right" style.
10. Almost nothing is new. Micro-services, externalized state machines, hot-swapping, and JSON-like structured data all existed in 1985 under other names.

## The Closing Arguments

- **"… By Any Other Name"**: The SOLID principles were not derived in a seminar. They were laid down in two years of Netnews and Usenet debates about C++, OO, language features, and design principles, conducted to relieve the frustration of a failing startup — after reading Stroustrup, Wirfs-Brock, Coad, Goldberg, Coplien, and above all Booch. The name "Uncle Bob" came from a colleague, Billy Vogel, wore thin, was missed once it stopped, and was then deliberately adopted as a brand. The point: the discipline in this book is the residue of arguing in public about real failures, not an abstraction handed down.
- **Architects Registry Exam (ETS/NCARB)**: Building architects must pass a registration exam — solve a set of design problems for a public library, a restaurant, a church, and draw the appropriate diagrams — historically scored by expensive, ambiguous, delayed juries of senior architects. ETS automated it as 18 CAD-like GUI vignettes plus 18 scoring applications. Notably, the relationship between the GUI applications and the framework followed the Dependency Rule: all high-level GUI policy in the framework, vignette code as glue, vignettes as plugins. For scoring, the polarity reversed — high-level scoring policy in the vignette, the scoring framework plugged into it. Both were statically linked C++ with no notion of "plugin" in anyone's mind, and yet the dependencies ran consistently with the Dependency Rule. The rule is discoverable from the problem, not from the tooling.

## Connects To
- **Ch 30 (The Database Is a Detail)**: VRS is the case study — embedded SQL everywhere, vendor cancelled, migration abandoned, perpetual maintenance contract.
- **Ch 32 (Frameworks Are Details)**: The ROSE object-oriented database and UNIFY are asymmetric marriages that ended badly.
- **Ch 5 (Object-Oriented Programming)**: Vectorization is polymorphic dispatch and plugin architecture invented from first principles in assembler.
- **Ch 11 (DIP) / Ch 12 (Components)**: The dependency-inverted supervisor boundary and independently deployable EPROM chips.
- **Ch 8 (OCP)**: CDS's externalized state machine changed application flow without changing code.
- **Ch 2 (A Tale of Two Values)**: The SAC rewrite and the officially rigid dispatch module are what happens when structure is sacrificed to behavior.
- **Ch 22 (The Clean Architecture)**: ROSE's inverted-in-the-wrong-direction layers are the counter-example the Dependency Rule exists to prevent.
