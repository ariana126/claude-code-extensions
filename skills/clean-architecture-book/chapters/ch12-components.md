# Chapter 12: Components

## Core Idea
Components are the units of deployment — the smallest entities that can be deployed as part of a system (jar, gem, DLL, shared library) — and well-designed components always retain the ability to be independently deployable and therefore independently developable.

## Frameworks Introduced
- **Components as the Granule of Deployment**: A component is the deployment granule in every language: jar files in Java, gem files in Ruby, DLLs in .Net, aggregations of binary files in compiled languages, aggregations of source files in interpreted languages.
  - When to use: whenever deciding how to package and ship a system, or whether a boundary is "real."
  - How: (1) identify the artifacts you can build and ship separately; (2) verify each can be released with its own version number; (3) verify that a change inside one does not force a rebuild of the others; (4) if any of those fail, the boundary is notional, not a component boundary.
  - Why it works: independent deployability forces the dependency structure to be explicit and managed. Failure mode: components that must always be rebuilt and shipped together are one component wearing three names, and you pay component overhead for no isolation benefit.
- **Component Plugin Architecture**: Dynamically linked files plugged together at runtime are the software components of our architectures.
  - When to use: whenever a part of the system is a detail that should be swappable (UI, database, third-party extension, mod).
  - How: define the interface in the stable component; ship the volatile implementation as a separately loaded `.jar`/DLL/shared library; let the loader link them at load time or runtime.
  - Why it works: fast machines made load-time linking cheap, so the plugin boundary now costs almost nothing to erect.

## Key Concepts
- **Component**: The smallest entity that can be deployed as part of a system; the granule of deployment in all languages.
- **Relocatable binary**: Compiled code instrumented with flags so a smart loader can load it at any chosen address, relocating memory references as it loads.
- **External reference**: A function name emitted as metadata by the compiler where a program *calls* a library function.
- **External definition**: A function name emitted as metadata where a program *defines* a library function; the loader links references to definitions.
- **Linking loader**: A loader that both relocates binaries and resolves external references to external definitions at load time.
- **Linker**: The slow linking phase split out into a separate application, whose output is a linked relocatable that a relocating loader can load very quickly.
- **Murphy's law of program size**: Programs will grow to fill all available compile and link time.
- **Moore's law**: Computer speed, memory, and density double every 18 months — the force that finally beat Murphy in the late 1980s and made load-time linking feasible again.

## Mental Models
- Think of a component as *a thing with a version number*. If it cannot be released independently with its own release number, it is not a component yet.
- Use the history as a cost curve, not trivia: the industry spent 50 years fighting turnaround time, and the plugin boundary was expensive the whole time. It is cheap now — so the question "should this be a plugin?" should default to yes far more often than instinct suggests.
- Think of the linker/loader story as the tug-of-war between Murphy (ambition inflates programs) and Moore (hardware deflates cost). Moore won in the mid-1990s; link time dropped to seconds and the component plugin architecture was born.

## Anti-patterns
- **Treating deployment packaging as an afterthought**: If component structure is decided only at ship time, the dependency graph has already hardened around whatever the code happened to do, and independent deployability is gone.
- **Components that are only nominally separate**: Splitting source into modules that still must all be rebuilt and redeployed together buys none of the isolation and all of the ceremony.
- **Assuming plugin architecture is a herculean effort**: It was, decades ago. Today it can be the casual default, and treating it as exotic leaves swappability on the table for no reason.

## Code Examples
```asm
*200
                TLS
     START,     CLA
                TAD BUFR
                JMS GETSTR
                CLA
                TAD BUFR
                JMS PUTSTR
                JMP START

 BUFR,      3000

GETSTR,    0
                DCA PTR
     NXTCH,     KSF
                JMP -1
                KRB
                DCA I PTR
                TAD I PTR
                AND K177
                ISZ PTR
                TAD MCR
                SZA
                JMP NXTCH

K177,      177
     MCR,       -15
```
- **What it demonstrates**: The `*200` origin statement tells the compiler to generate code loaded at address 200₈ — programs were not relocatable, so the programmer owned the memory layout, and library source had to be compiled in with the application.

## Worked Example
The memory-layout squeeze, compressed:

1. **Libraries in source.** Programmers pasted the library's source deck onto the end of their own. Compilers made several passes over slow devices; a large program could take hours to compile.
2. **Split the library out.** Compile the function library separately, load its binary at a known address (say 2000₈), compile the application against a symbol table. Application sits in 0000₈–1777₈.
3. **The application outgrows its slot.** It must be split into two address segments that jump *around* the library. Then the library outgrows its slot too, and gets relocated near 7000₈. Fragmentation grows with memory. Unsustainable.
4. **Relocatability.** The compiler emits relocatable binary plus external references/definitions; a smart loader is told where to put each piece and patches the addresses. The linking loader is born.
5. **Linking loaders get too slow.** By the late 1960s–70s, resolving hundreds of libraries off tape and slow disk took an hour. Split the slow part into a separate `linker` whose output loads fast.
6. **Murphy strikes again.** In the 1980s, C programs of hundreds of thousands of lines pushed compile-link turnaround back to an hour or more.
7. **Moore wins.** By the mid-1990s link time fell to seconds. Active-X, shared libraries, and `.jar` files arrive; linking at load time is feasible again — and the component plugin architecture is born.

Today: drop a custom `.jar` in a folder to mod Minecraft; drop the right DLLs in to plug Resharper into Visual Studio.

## Key Takeaways
1. A component is the granule of deployment — jar, gem, DLL, or an aggregation of binary or source files. Nothing smaller ships.
2. Regardless of how components are eventually deployed, keep them *independently deployable*, because that is what makes them independently developable.
3. Independent deployability is a design constraint you enforce continuously, not a packaging decision you make at the end.
4. Plugin architecture is now cheap enough to be the default, not a heroic special case — use it wherever you want a detail to stay swappable.
5. Expect Murphy's law of program size: whatever build speed you gain, ambition will consume. Manage the dependency structure rather than waiting for faster hardware.

## Connects To
- **Ch 13**: Which classes go into which component — the cohesion principles (REP, CCP, CRP) that decide component *contents*.
- **Ch 14**: The dependency relationships *between* components (ADP, SDP, SAP) — what makes independent deployability actually hold.
- **Ch 11 (DIP)**: Plugin architecture is DIP made physical; the interface lives in the stable component, the plugin implements it.
- **The Dependency Rule / Plugin Architecture (Part V–VI)**: The whole "database and UI are plugins to the business rules" stance rests on components being independently deployable units.
