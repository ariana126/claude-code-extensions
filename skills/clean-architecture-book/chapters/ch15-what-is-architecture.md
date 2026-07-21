# Chapter 15: What Is Architecture?

## Core Idea
The architecture of a system is the shape given to it by those who build it — the division into components, their arrangement, and how they communicate — and its purpose is to facilitate development, deployment, operation, and maintenance. The strategy behind that facilitation is to *leave as many options open as possible, for as long as possible*.

## Frameworks Introduced

- **The Four Things Architecture Supports (Development, Deployment, Operation, Maintenance)**: architecture has very little bearing on whether a system *works*; plenty of terribly architected systems work fine. Judge an architecture by its effect on the system's life cycle, not its behavior.
  - When to use: whenever evaluating or defending an architectural decision — ask which of the four it serves and which it damages.
  - How:
    1. **Development** — match the structure to the team structure. Five developers can build a monolith with no defined components and be fast; five teams of seven cannot make progress unless the system is split into well-defined components with reliably stable interfaces. Such a group will gravitate toward one component per team.
    2. **Deployment** — target deployment *with a single action*. Deployment is seldom considered during initial development, which is how you get systems that are easy to develop and miserable to deploy (e.g. adopting micro-services early because boundaries are firm, then drowning in service count, connection configuration, and start-up ordering).
    3. **Operation** — the least dramatic of the four. Almost any operational difficulty can be resolved by throwing hardware at it; hardware is cheap and people are expensive. Architecture's real operational job is to *communicate* operational needs — to elevate use cases, features, and required behaviors into first-class, visible landmarks.
    4. **Maintenance** — the most costly aspect of any system. Its cost is *spelunking* plus *risk*. Components isolated behind stable interfaces illuminate the pathways for new features and reduce inadvertent breakage.
  - Why it works: development-, deployment- and maintenance-impeding architectures cost human time, which is the expensive resource; operation-impeding ones cost hardware, which is not.

- **Keeping Options Open (policy vs. details)**: decompose every system into two elements — **policy** (all business rules and procedures, where the true value lives) and **details** (IO devices, databases, web systems, servers, frameworks, communication protocols — everything needed to talk *to* the policy that does not affect the policy's behavior).
  - When to use: at the start of every project, and every time a vendor/framework/infrastructure decision is pushed at you.
  - How: shape the system so policy is essential and details are *irrelevant* to it; then delay and defer each detail decision. Concretely, you do not need to choose early: a database (relational, distributed, hierarchical or flat files should be invisible to policy); a web server (policy should not know HTML, AJAX, JSP, JSF — or even that delivery is over the web at all); REST, a micro-services framework, or SOA; a dependency injection framework.
  - Why it works: the longer you wait, the more information you have to decide properly, and the more experiments you can run — swap in several databases and measure applicability and performance while policy stays untouched.

- **A good architect maximizes the number of decisions not made.**
  - When to use: continuously, including when the decision has apparently already been made for you.
  - How: if the company has committed to a certain database, web server, or framework, *pretend the decision has not been made* and shape the system so it can still be deferred or reversed for as long as possible.

## Key Concepts
- **Architecture**: the shape of a system — its division into components, their arrangement, and their means of communication.
- **Policy**: the element embodying all business rules and procedures; where the system's true value lives.
- **Details**: everything necessary for humans, other systems, and programmers to communicate with the policy, but which does not impact the policy's behavior.
- **Spelunking**: the cost of digging through existing software to find the best place and strategy to add a feature or repair a defect — the primary cost of maintenance, alongside risk.
- **Device independence**: abstracting IO devices behind operating-system services over abstract unit-record devices, so the same program reads and writes cards or tape *without any change*. The Open–Closed Principle, born but not yet named.
- **Device dependence**: binding code directly to IO instructions for a specific device — the 1960s mistake that forced wholesale rewrites when cards gave way to magnetic tape.
- **Relative addressing**: treating a disk as one huge linear array of sequentially numbered sectors, with a single conversion routine translating to physical geometry, instead of hard-wiring cylinder/head/sector everywhere.
- **Behavioral options**: there are few, if any, options about *behavior* that architecture can leave open — architecture's role in correct behavior is passive and cosmetic, not active or essential.

## Mental Models
- **Think of the architect as the best programmer on the team, not someone above the code.** Architects continue to take programming tasks; they cannot do the job properly if they are not experiencing the problems they are creating for everyone else.
- **Use "which decision am I being forced to make today?" as the design trigger.** If the answer is a detail, the shape is wrong — find the interface that lets you postpone it.
- **Think of every framework, database, and protocol as a device you might swap tomorrow.** Device independence in the 1960s and database independence today are the same move at different scales.
- **Use team topology as a predictor, not a goal.** Five teams will produce five components if driven by schedule alone; know that this is likely wrong for deployment, operation, and maintenance and decide deliberately.

## Code Examples

```asm
PRTCHR, 0
        TSF
        JMP .-1
        TLS
        JMP I PRTCHR
```
- **What it demonstrates**: device-*dependent* code — a PDP-8 subroutine printing one character on a teleprinter by spinning on `TSF` (skip if ready) and sending the `A` register with `TLS`. The policy is welded to one physical device, so a change of device means a rewrite.

## Worked Example

**Junk mail, late 1960s.** Clients sent magnetic tapes of customer names and addresses plus 500-pound rolls of pre-printed form letters; programs extracted the fields and printed them exactly into place on the forms.

- Initially an IBM 360 printed on its sole line printer — a few thousand letters per shift, tying up a machine that rented for tens of thousands of dollars per month.
- Because the programs used the operating system's IO abstractions rather than device instructions, the operators simply told the OS to write to magnetic tape instead. The programs did not care and were not changed.
- The 360 filled a tape in about 10 minutes; tapes moved to five offline printers running 24/7, producing hundreds of thousands of pieces of mail per week.
- The shape is the lesson: **policy** = formatting the name-and-address records; **detail** = the device. The device decision was deferred, and the same programs could be tested on the local line printer and run in production against tape.

**Physical addressing, early 1970s.** A truckers-union accounting system on a 25MB drive formatted its first cylinders to fit `Agent` records, the next to fit `Employer` records, the last to fit `Member` records. The code knew the drive had 200 cylinders and 10 heads; indices stored cylinder/head/sector triples, and `Member` records formed a doubly linked list of physical addresses. Upgrading the drive meant a translation program *and* changes to hard-wiring that was everywhere — all the business rules knew the geometry. The fix an experienced colleague prescribed: treat the disk as one linear array of sequentially numbered sectors and confine geometry to one conversion routine. High-level policy became agnostic about physical disk structure.

## Key Takeaways
1. Architecture's purpose is to facilitate development, deployment, operation, and maintenance — its job is to minimize the lifetime cost of the system and maximize programmer productivity, not to make it work.
2. Leave as many options open as possible, for as long as possible; the options you leave open are *the details that don't matter*.
3. Separate policy from details, then decouple them so thoroughly that policy has no knowledge of and no dependency on the details.
4. Defer database, web server, REST/SOA, and DI-framework decisions — every month of deferral buys information and the ability to run experiments.
5. If someone else already made the decision, pretend they didn't and keep the system reversible.
6. Aim for deployment with a single action, and consider deployment *during* initial development, not after.
7. Optimize for people, not machines: operational shortfalls can be bought off with hardware; development and maintenance shortfalls cannot.

## Connects To
- **Ch 16 (Independence)**: expands the same four concerns into use cases, operation, development, and deployment, and adds the decoupling modes.
- **Ch 17 (Boundaries: Drawing Lines)**: the mechanism for deferral — the boundary line between business rules and the database is what makes "pretend the decision hasn't been made" achievable.
- **Ch 19 (Policy and Level)**: formalizes the policy/detail split into a definition of *level* as distance from the inputs and outputs.
- **Open–Closed Principle**: device independence is OCP applied to hardware before OCP had a name.
- **Chapter on behavior vs. structure**: structure is the greater of software's two values because it is what makes software *soft*.
