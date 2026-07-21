# Chapter 29: Clean Embedded Architecture

*Guest chapter by James Grenning.*

## Core Idea
Although software does not wear out, it can be destroyed from within by unmanaged dependencies on firmware and hardware. Code is firmware not because of where it is stored but because of what it depends on and how hard it is to change as hardware evolves — so a clean embedded architecture is one whose software is testable off the target hardware and off the target OS.

## Frameworks Introduced
- **The Hardware Abstraction Layer (HAL)**: the named boundary between the software and the firmware.
  - When to use: in every embedded system, as soon as hardware knowledge starts appearing outside a handful of files.
  - How:
    1. Define the HAL's API in terms of what the *software above it* needs, not what the hardware below it offers.
    2. Express services at the product level, not the register level. Firmware (or a board support package) may offer `Led_TurnOn(5)`; the HAL should offer `Indicate_LowBattery()`.
    3. Hide the mechanism completely — the application stores and reads *name/value pairs* to "some persistence mechanism"; whether that is flash, a spinning disk, the cloud, or core memory is a detail. The firmware's byte-and-byte-array flash interface stays below the line.
    4. Keep GPIO bit assignments below the line as details.
    5. Allow layers within layers — this is a repeating fractal pattern, not a fixed set of predefined layers.
  - Why it works: a successful HAL provides the **seam** or set of substitution points that facilitate off-target testing, which is what eliminates the target-hardware bottleneck.
  - Failure mode: revealing hardware details to the user of the HAL. If the abstraction leaks, the substitution point is gone and testing returns to the target.

- **The Operating System Abstraction Layer (OSAL)**: the corresponding boundary that isolates software from the OS.
  - When to use: any system on an RTOS, embedded Linux, or embedded Windows. In bare-metal systems a HAL alone may be sufficient.
  - How:
    1. Treat the OS as a detail and route all OS access through the OSAL.
    2. Sometimes this is as simple as changing the name of a function; sometimes it means wrapping several functions together.
    3. Concentrate the duplication that surrounds OS usage into this one layer — that is what stops it from becoming code bloat.
    4. Use it to impose a common structure on applications — e.g., provide message passing mechanisms rather than letting every thread handcraft its concurrency model.
    5. Provide test points so the valuable application code in the software layer can be tested off-target and off-OS.
  - Why it works: porting to a new RTOS becomes *writing a new OSAL compatible with the old OSAL* — new code against a defined interface and behavior — rather than modifying a mass of complex existing code. The change would otherwise not just be syntactic; you would have to adapt semantically to the new OS's different capabilities and primitives.

- **The App-titude Test**: getting the app to work, and nothing more.
  - Kent Beck's three activities, with Grenning's commentary:
    1. "First make it work." *You are out of business if it doesn't work.*
    2. "Then make it right." *Refactor so you and others can understand it and evolve it as needs change or are better understood.*
    3. "Then make it fast." *Refactor for "needed" performance.*
  - Most embedded code in the wild stops at step 1, often with an obsession for step 3 pursued by micro-optimizations at every opportunity — skipping step 2 entirely. Fred Brooks's "plan to throw one away" in *The Mythical Man-Month* is the same advice as Kent's: learn what works, then make a better solution.
  - Passing the App-titude test and calling it done is a disservice to your product and your employer.

- **Programming to Interfaces and Substitutability**: apply separation of concerns inside each major layer (software, OS, firmware, hardware).
  - How:
    1. When one module interacts with another through an interface, you can substitute one service provider for another — e.g., your own small `printf` for the standard one, as long as the interface is identical.
    2. Use header files as interface definitions.
    3. Limit header contents to function declarations plus the constants and struct names *needed by the function*.
    4. Keep data structures, constants, and typedefs needed only by the implementation out of the interface header. The clutter is not merely cosmetic — it creates unwanted dependencies.
    5. Expect implementation details to change; the fewer places code knows the details, the fewer places to track down and modify.

- **DRY Conditional Compilation Directives**: stop repeating target identification through `#ifdef`.
  - How: put the hardware type below the HAL as a hidden detail. Given HAL interfaces, connect software to hardware with the linker or some form of runtime binding instead of conditional compilation.
  - Why: `#ifdef BOARD_V2` once is not a problem; Grenning recalls one telecom application where it appeared **several thousand times** — "six thousand times is an extreme problem" — a gross violation of the Don't Repeat Yourself (DRY) principle from Hunt and Thomas's *The Pragmatic Programmer*.

## Key Concepts
- **Firmware**: code that is firm because of what it depends on and how hard it is to change as hardware evolves — *not* because it lives in ROM, EPROM, or flash.
- **Software**: code with a potentially long useful life, kept that way by having no dependencies on hardware or OS.
- **The target-hardware bottleneck**: when code is structured without clean architecture principles, it can be tested only on the target — and the target is scarce, late, and defective, so development slows to its pace.
- **Hardware abstraction layer (HAL)**: the boundary between software and firmware; not a new idea — it has been in PCs since before Windows.
- **Operating system abstraction layer (OSAL)**: the boundary between software and the OS.
- **Processor abstraction layer (PAL)**: the firmware-internal layer isolating device access registers, so firmware above it can be tested off-target and becomes "a little less firm."
- **Seam / substitution point**: what a successful HAL, OSAL, or interface provides so that a real component can be replaced for off-target testing.
- **The hardware is a detail / the processor is a detail / the OS is a detail**: the three things a clean embedded architecture refuses to depend on.
- **Software and firmware intermingling**: the anti-pattern where the line between product code and hardware-interacting code is fuzzy to the point of nonexistence.

## Mental Models
- Think of "firmware" as a *dependency property*, not a storage location. Non-embedded developers write firmware too: whenever they bury SQL in their code, spread platform dependencies through it, or fail to separate business logic from the Android API.
- Use the four-layer stack — **software / OS (with OSAL) / firmware (with HAL) / hardware** — and ask of every module which layer it belongs to. If it needs two, split it.
- Think of layering as a repeating fractal pattern rather than a fixed set of predefined layers; a HAL can sit inside a HAL.
- Use "can I run this test without the board?" as the single measure of embedded architectural cleanliness. A clean embedded architecture's software is testable off the target hardware *and* off the target operating system.
- Think of the vendor's helpful C extensions as a business relationship: assume the silicon and tool provider is genuinely trying to help, then limit which files are allowed to know about the extensions so the help does not hurt later.

## Anti-patterns
- **Letting hardware knowledge pollute all the code**: with nothing constraining where things go or what one module may know about another, the code becomes hard to change — not only when the hardware changes, but when a user asks for a change or a bug needs fixing.
- **Software/firmware intermingling**: changes are resisted, dangerous, and prone to unintended consequences; minor changes demand full regression tests of the whole system, and without externally instrumented tests you get bored with manual testing and then get new bug reports.
- **The message processor in the UART file**: a message processor/dispatcher that knows message format, parses, and dispatches could have been long-lived software — but it lives in the same file as UART-interacting code and is polluted with UART details, so it is firmware.
- **Legacy code as the spec**: in the TDM-to-VOIP redesign, the systems engineer answered every behavioral question by reading the current product's code. With no separation between TDM and the business logic of making calls, the whole product had become firmware and could not be untangled.
- **Using `acmetypes.h` directly**: ties your code to one of the ACME DSPs, gives you the wrong integer sizes when testing off-target, and makes any future port far harder.
- **Using vendor C extensions outside the firmware**: keywords, and "global variables" mapping to processor registers, IO ports, clock timers, IO bits, and interrupt controllers make code that looks like C but is not C — it will not compile for another processor, or maybe even with a different compiler for the same processor.
- **Thousands of `#ifdef BOARD_V2`**: DRY violation that spreads target knowledge across the whole codebase.
- **Cluttered interface headers**: implementation-only structures and typedefs in a header create dependencies on details that are expected to change.

## Code Examples

The vendor header that should never be used directly:

```c
#ifndef _ACME_STD_TYPES
#define _ACME_STD_TYPES

#if defined(_ACME_X42)
    typedef unsigned int        Uint_32;
    typedef unsigned short      Uint_16;
    typedef unsigned char       Uint_8;

    typedef int                 Int_32;
    typedef short               Int_16;
    typedef char                Int_8;

#elif defined(_ACME_A42)
    typedef unsigned long       Uint_32;
    typedef unsigned int        Uint_16;
    typedef unsigned char       Uint_8;

    typedef long                Int_32;
    typedef int                 Int_16;
    typedef char                Int_8;
#else
    #error <acmetypes.h> is not supported for this environment
#endif

#endif
```
- **What it demonstrates**: depending on this header directly binds your code to one ACME DSP and gives wrong integer sizes off-target.

The portable indirection — write your own `stdint.h` if the target compiler does not supply one:

```c
#ifndef _STDINT_H_
#define _STDINT_H_

#include <acmetypes.h>

typedef Uint_32 uint32_t;
typedef Uint_16 uint16_t;
typedef Uint_8  uint8_t;

typedef Int_32  int32_t;
typedef Int_16  int16_t;
typedef Int_8   int8_t;

#endif
```
- **What it demonstrates**: exactly one file knows about ACME; all other code follows the standardized path and includes `stdint.h`, staying clean and portable.

Firmware that is not C, based on real code from the wild:

```c
void say_hi()
{
  IE = 0b11000000;
  SBUF0 = (0x68);
  while(TI_0 == 0);
  TI_0 = 0;
  SBUF0 = (0x69);
  while(TI_0 == 0);
  TI_0 = 0;
  SBUF0 = (0x0a);
  while(TI_0 == 0);
  TI_0 = 0;
  SBUF0 = (0x0d);
  while(TI_0 == 0);
  TI_0 = 0;
  IE = 0b11010000;
}
```
- **What it demonstrates**: `0b11000000` is not C, and `IE` (interrupt enable bits), `SBUF0` (serial output buffer), and `TI_0` (serial transmit buffer empty interrupt; 1 means empty) are micro-controller peripherals reached through compiler extensions — convenient, but binding this code to the silicon. Confine such device access registers to very few places, entirely within the firmware, behind a PAL.

## Reference Tables

| Layer | Contains | May depend on | Testable off-target? |
|---|---|---|---|
| Software | Domain/business logic, application policy | OSAL, HAL interfaces | Yes — always |
| Operating system | RTOS / embedded Linux or Windows services, reached via the **OSAL** | Firmware | Software above the OSAL: yes |
| Firmware | Device access registers, GPIO, flash driver, ISRs, tool-chain extensions; exposes the **HAL** upward, may use a **PAL** internally | Hardware | Above the PAL: yes; below: no |
| Hardware | Silicon, peripherals — evolves, becomes obsolete | — | No |

| Concern | Firmware-level call | HAL-level call |
|---|---|---|
| Indicator LED on a GPIO bit | `Led_TurnOn(5)` | `Indicate_LowBattery()` |
| Persistence | store bytes / arrays of bytes into flash | store and read name/value pairs |

## Worked Example
**The one-file embedded application that passes the App-titude test.**

These functions were found, in this order, in a single source file of a small embedded system:

```c
ISR(TIMER1_vect) { ... }
ISR(INT2_vect) { ... }
void btn_Handler(void) { ... }
float calc_RPM(void) { ... }
static char Read_RawData(void) { ... }
void Do_Average(void) { ... }
void Get_Next_Measurement(void) { ... }
void Zero_Sensor_1(void) { ... }
void Zero_Sensor_2(void) { ... }
void Dev_Control(char Activation) { ... }
char Load_FLASH_Setup(void) { ... }
void Save_FLASH_Setup(void) { ... }
void Store_DataSet(void) { ... }
float bytes2float(char bytes[4]) { ... }
void Recall_DataSet(void) { ... }
void Sensor_init(void) { ... }
void uC_Sleep(void) { ... }
```

Regrouped by concern, the design that was never drawn becomes visible:

| Concern | Functions |
|---|---|
| Domain logic | `calc_RPM`, `Do_Average`, `Get_Next_Measurement`, `Zero_Sensor_1`, `Zero_Sensor_2` |
| Hardware platform setup | `ISR(TIMER1_vect)`, `ISR(INT2_vect)`, `uC_Sleep` |
| On/off button reaction | `btn_Handler`, `Dev_Control` |
| A/D input reading | `Read_RawData` |
| Persistent storage | `Load_FLASH_Setup`, `Save_FLASH_Setup`, `Store_DataSet`, `bytes2float`, `Recall_DataSet` |
| Does not do what its name implies | `Sensor_init` |

The domain-logic group is real software with a potentially long life, but it is trapped in a file with ISRs and flash access. Other files showed the same pattern, plus a file structure implying the only way to test any of this code is in the embedded target, and virtually every bit of it uses "extended" C constructs tying it to a particular tool chain and microprocessor. The application works — the engineer passed the App-titude test — but the code has no chance of a long useful life unless the product never moves to different hardware.

## Key Takeaways
1. Judge code as firmware by its dependencies, not its storage. Anything that knows about device access registers is firmware and is bound to the silicon.
2. Write less firmware and more software. Non-embedded developers write firmware too — buried SQL, spread platform dependencies, business logic tangled with the Android API.
3. Eliminate the target-hardware bottleneck. If the target is the only place testing is possible, hardware scarcity and hardware defects set your development pace.
4. A clean embedded architecture is a testable embedded architecture: testable off the target hardware and off the target operating system.
5. Put a HAL between software and firmware, and design its API for the software's needs at the product level of abstraction — `Indicate_LowBattery()`, not `Led_TurnOn(5)`.
6. Treat the OS as a detail behind an OSAL, so an RTOS change means writing a new OSAL rather than modifying complex existing code.
7. Isolate vendor C extensions and processor headers to very few files; go through `stdint.h`, and write your own over `acmetypes.h` if the compiler does not supply one.
8. Use header files as interface definitions and keep implementation-only details out of them — clutter becomes dependency.
9. Replace repeated `#ifdef` target checks with HAL interfaces bound by the linker or at runtime.
10. Don't stop at "make it work." Make it right, then make it fast — in that order.

## Connects To
- **Ch 30 (The Database Is a Detail)** and **Ch 31 (The Web Is a Detail)**: the same move — "the hardware is a detail," "the processor is a detail," "the OS is a detail."
- **Ch 28 (The Test Boundary)**: the HAL and OSAL are the seams that make off-target testing possible; the target hardware plays the volatile role the GUI plays there.
- **Ch 11 (DIP)**: programming to interfaces and substitutability is the DIP applied with C header files.
- **Ch 22 (The Clean Architecture)**: the software/OS/firmware/hardware stack is the concentric-circle model in embedded form.
- **Ch 23 (Presenters and Humble Objects)**: the HAL splits testable behavior from the hard-to-test hardware edge.
- **Hardware Abstraction Layer in PCs**: predates Windows; this is not a new idea.
- **DRY (Hunt and Thomas, *The Pragmatic Programmer*)**: the argument against thousands of conditional compilation directives.
- **Kent Beck's "make it work, make it right, make it fast"** and **Brooks's "plan to throw one away"**: the discipline the App-titude test skips.
