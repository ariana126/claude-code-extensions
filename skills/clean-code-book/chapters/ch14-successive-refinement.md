# Chapter 14: Successive Refinement

## Core Idea
Clean code is not written clean — "to write clean code, you must first write dirty code *and then clean it*." The chapter is a case study of the `Args` command-line parser: a module that started well, stopped scaling, and was recovered not by a rewrite but by a long series of very tiny, test-protected transformations.

## Frameworks Introduced

- **Successive Refinement**: Treat code like a composition — rough draft, second draft, subsequent drafts, final version.
  - When to use: Every module. It is not a special activity; it is how programs get written.
  - How:
    1. Write a first version that works. Don't expect elegance in one pass — programming is a craft more than a science.
    2. Watch for the moment when adding the *next* feature would make the mess unrecoverable.
    3. Stop adding features. Refactor toward the concept the code is asking for.
    4. Resume adding features once the structure supports them.
  - Why it works / failure mode: The failure mode is the freshman/most-programmers pattern — the primary goal is to get the program working, and once it "works" you move on, leaving it in whatever state it happened to reach. Martin calls that professional suicide.

- **On Incrementalism**: "One of the best ways to ruin a program is to make massive changes to its structure in the name of improvement." Some programs never recover, because it is very hard to get the program working the same way it worked before the "improvement."
  - When to use: Any nontrivial restructuring.
  - How: Use the discipline of **Test-Driven Development**. Its central doctrine here: **keep the system running at all times** — you are not allowed to make a change that breaks the system; every change must keep it working as it worked before. This requires a suite of automated tests runnable on a whim. Then make a large number of very tiny changes, each moving the structure toward the target concept, each keeping the system working.
  - Why it works / failure mode: For `Args`, the suite was unit tests in Java under JUnit plus acceptance tests written as wiki pages in FitNesse — built *while* the festering pile was being built. Without that safety net, incrementalism is unavailable and only the ruinous big-bang restructuring remains.

- **Stop-and-Clean trigger ("So I Stopped")**: The explicit decision rule for when refactoring outranks features.
  - When to use: When you can *tell* the next feature will make things much worse — when you could bulldoze forward and get it to work but would leave behind a mess too large to fix.
  - How: Name the smell precisely. In `Args`, each new argument type required new code in **three** major places: (1) parsing its schema element to select the `HashMap` for that type, (2) parsing it in the command-line strings and converting it to its true type, (3) a `getXXX` method to return it as its true type. "Many different types, all with similar methods — that sounds like a class to me." And so the `ArgumentMarshaler` concept was born.
  - Why it works / failure mode: The mess built *gradually*; adding just two argument types (String and integer) to the Boolean-only version had a massively negative impact. If the structure was ever going to be maintainable, now was the time.

- **Partitioning as design**: "Much of good software design is simply about partitioning — creating appropriate places to put different kinds of code." The majority of the changes to `Args` were **deletions**: code moved out of `Args` into `ArgsException`, and each `ArgumentMarshaler` moved into its own file.

## Key Concepts
- **Rough draft**: A working but messy first version; the kindest description of code you would be embarrassed to leave behind.
- **Festering pile**: Martin's name for the draft — daunting instance-variable count, odd sentinel strings like `"TILT"`, parallel `HashSets`/`TreeSets`, empty `try-catch-catch` blocks.
- **ArgumentMarshaler**: The extracted abstraction — one interface, `void set(Iterator<String> currentArgument)`, with a derivative per argument type holding its own typed value and a static `getValue(ArgumentMarshaler)`.
- **Schema string**: `"l,p#,d*"` — the format defining a boolean (`l`), integer (`p#`), and string (`d*`) argument; later `##` for double and `[*]` for string array.
- **Keeping the system running**: TDD's constraint that no change may break the system, even mid-refactoring.
- **Code rot**: As code rots, modules insinuate themselves into each other, creating hidden and tangled dependencies; finding and breaking them is long and arduous.
- **Compromise (in design)**: Putting error-message formatting in `ArgsException` rather than `Args` is knowingly imperfect — users who dislike the canned messages must write their own — but the convenience is not insignificant.

## Mental Models
- Think of code as **a school composition**: nobody hands in the first draft; successive refinement is the process, not a remediation.
- Use **"how many places must change to add one more of these?"** as the extract-a-class trigger. Three places in `Args` meant a missing type.
- Use **"if I made a mess five minutes ago, it's very easy to clean it up right now"** as the scheduling rule — cost of cleanup grows superlinearly with delay.
- Think of a refactor as **many tiny green-to-green steps**, never one large brown-field jump; if you cannot get back to green in a minute, the step was too big.
- Think of a **compile error as a to-do list**: change one type (`Map<Character, Boolean>` → `Map<Character, ArgumentMarshaler>`), let the compiler enumerate the breakage, fix each quickly.

## Anti-patterns
- **"It works, ship it"**: Programmers who satisfy themselves with merely working code are behaving unprofessionally; working code is often badly broken.
- **Massive restructuring in the name of improvement**: Ruins programs, because restoring prior behavior is very hard.
- **Bulldozing through the smell**: You'll probably get the feature working — and leave a mess too large to fix.
- **Parallel typed maps** (`booleanArgs`, `stringArgs`, `intArgs`) plus parallel parse/get methods: the duplication that signals a missing polymorphic type.
- **Sentinel/error state smeared across the class**: `valid`, `unexpectedArguments`, `errorArgumentId`, `errorParameter = "TILT"`, `errorCode` all living in `Args` — an SRP violation; error formatting belongs elsewhere.
- **Swallowed exceptions**: `try { parseArguments(); } catch (ArgsException e) { }` — hides failure and makes `valid` the only signal.
- **"No time to improve the structure"**: Bad schedules can be redone, bad requirements redefined, bad team dynamics repaired — but bad code rots and ferments into an inexorable weight that drags the team down.

## Code Examples

**Client's view — this never changes across the refinement:**

```java
   public static void main(String[] args)   {
     try {
       Args arg = new Args("l,p#,d*", args);
       boolean logging = arg.getBoolean('l');
       int port = arg.getInt('p');
       String directory = arg.getString('d');
       executeApplication(logging, port, directory);
     }  catch (ArgsException e) {
         System.out.printf("Argument error: %s\n", e.errorMessage());
     }
   }
```

**Before — `Args.java` (first draft), field block only:**

```java
public class Args {
  private String schema;
  private String[] args;
  private boolean valid = true;
  private Set<Character> unexpectedArguments = new TreeSet<Character>();
  private Map<Character, Boolean> booleanArgs =
    new HashMap<Character, Boolean>();
  private Map<Character, String> stringArgs = new HashMap<Character, String>();
  private Map<Character, Integer> intArgs = new HashMap<Character, Integer>();
  private Set<Character> argsFound = new HashSet<Character>();
  private int currentArgument;
  private char errorArgumentId = '\0';
  private String errorParameter = "TILT";
  private ErrorCode errorCode = ErrorCode.OK;

  private enum ErrorCode {
    OK, MISSING_STRING, MISSING_INTEGER, INVALID_INTEGER, UNEXPECTED_ARGUMENT}

  public Args(String schema, String[] args) throws ParseException {
    this.schema = schema;
    this.args = args;
    valid = parse();
  }

  private boolean parse() throws ParseException {
    if (schema.length() == 0 && args.length == 0)
      return true;
    parseSchema();
    try {
      parseArguments();
    } catch (ArgsException e) {
    }
    return valid;
  }
```

**After — final `Args`, three fields and a readable top-to-bottom narrative:**

```java
   public class Args {
     private Map<Character, ArgumentMarshaler> marshalers;
     private Set<Character> argsFound;
     private ListIterator<String> currentArgument;

     public Args(String schema, String[] args) throws ArgsException {
       marshalers = new HashMap<Character, ArgumentMarshaler>();
       argsFound = new HashSet<Character>();

       parseSchema(schema);
       parseArgumentStrings(Arrays.asList(args));
     }

     private void parseSchemaElement(String element) throws ArgsException {
       char elementId = element.charAt(0);
       String elementTail = element.substring(1);
       validateSchemaElementId(elementId);
       if (elementTail.length() == 0)
         marshalers.put(elementId, new BooleanArgumentMarshaler());
       else if (elementTail.equals("*"))
         marshalers.put(elementId, new StringArgumentMarshaler());
       else if (elementTail.equals("#"))
         marshalers.put(elementId, new IntegerArgumentMarshaler());
       else if (elementTail.equals("##"))
         marshalers.put(elementId, new DoubleArgumentMarshaler());
       else if (elementTail.equals("[*]"))
         marshalers.put(elementId, new StringArrayArgumentMarshaler());
       else
         throw new ArgsException(INVALID_ARGUMENT_FORMAT, elementId, elementTail);
     }
   }
```

**The extracted abstraction and one derivative:**

```java
   public interface ArgumentMarshaler {
     void set(Iterator<String> currentArgument) throws ArgsException;
   }
```

```java
   public class IntegerArgumentMarshaler implements ArgumentMarshaler {
     private int intValue = 0;

     public void set(Iterator<String> currentArgument) throws ArgsException {
       String parameter = null;
       try {
         parameter = currentArgument.next();
         intValue = Integer.parseInt(parameter);
       } catch (NoSuchElementException e) {
         throw new ArgsException(MISSING_INTEGER);
       } catch (NumberFormatException e) {
         throw new ArgsException(INVALID_INTEGER, parameter);
       }
     }

     public static int getValue(ArgumentMarshaler am) {
       if (am != null && am instanceof IntegerArgumentMarshaler)
         return ((IntegerArgumentMarshaler) am).intValue;
       else
         return 0;
     }
   }
```

- **What it demonstrates**: The final `Args` reads top to bottom without jumping around or looking ahead; adding a new argument type (date, complex number) is a trivial amount of effort — one new `ArgumentMarshaler` derivative, one new `getXXX` function, one new case in `parseSchemaElement`, plus an `ArgsException.ErrorCode` and message.

## Worked Example

**The `Args` refinement arc, end to end.**

1. **Boolean only.** An earlier version handled only boolean arguments and was reasonably maintainable.
2. **+ String.** Added incrementally; still tolerable.
3. **+ integer → the festering pile.** Just two more argument types converted something maintainable into something Martin expected to become riddled with bugs and warts: eleven instance fields, parallel `booleanArgs`/`stringArgs`/`intArgs` maps, `TreeSet`/`HashSet`, a `"TILT"` sentinel, a swallowed `catch`, and a parallel set of `parseXxxSchemaElement`/`getXxx` methods.
4. **The stop.** Two more argument types remained. Martin saw each type demanded changes in three places, named the missing abstraction (`ArgumentMarshaler`), and stopped adding features.
5. **The safety net.** Unit tests in JUnit plus FitNesse acceptance wiki pages, written *during* the messy phase, could be run on a whim to prove behavior unchanged.
6. **The tiny steps.** First: append an empty `ArgumentMarshaler` skeleton with empty `Boolean`/`String`/`Integer` subclasses to the end of the pile — clearly this breaks nothing.

```java
   private class ArgumentMarshaler {
       private boolean booleanValue = false;

       public void setBoolean(boolean value) {
         booleanValue = value;
       }
       public boolean getBoolean() {return booleanValue;}
     }

     private class BooleanArgumentMarshaler extends ArgumentMarshaler {
     }
     private class StringArgumentMarshaler extends ArgumentMarshaler {
     }
     private class IntegerArgumentMarshaler extends ArgumentMarshaler {
     }
```

   Then change one map's value type and let the compiler point at the breakage:

```java
   private Map<Character, ArgumentMarshaler> booleanArgs =
     new HashMap<Character, ArgumentMarshaler>();
```

   "This broke a few statements, which I quickly fixed." Then the same pattern for String and integer; move the value into the derivatives; push parsing into `set`; delete the now-redundant typed maps; migrate error state and message formatting out to `ArgsException`; move each marshaler to its own file.
7. **Proof the design took.** Adding `double` afterward was "pretty painless": a `DoubleArgumentMarshaler`, two new codes (`MISSING_DOUBLE`, `INVALID_DOUBLE`), and a `getDouble`, with a test asserting the error message `"Argument -x expects a double but was 'Forty two'."` — all tests passed.
8. **The compromise.** Error-message formatting in `Args` was clearly an SRP violation, so it moved to `ArgsException` — not obviously its home either, but a deliberate trade for the convenience of canned messages.

## Key Takeaways
1. Write dirty code, then clean it — expecting a clean first pass is the wrong standard for yourself and others.
2. Refactor by many very tiny changes, never a massive restructuring; TDD's rule is that the system keeps working after every single one.
3. Build the test suite *while* writing the messy version — it is what makes the later cleanup possible at all.
4. Use "this feature will require changes in three places" as the signal that a class is missing.
5. Stop adding features the moment you can see the next one will leave a mess too large to fix; that is the cheapest possible moment to fix it.
6. Most of a good refactor is deletion and relocation — partitioning code into appropriate places is most of good design.
7. Judge the result by the cost of the *next* change: if adding a new type is one derivative plus one case, the structure took.
8. Never let the rot get started; keeping code clean is relatively easy, and cleanup cost grows with every hour of delay.

## Connects To
- **Ch 12 (Emergence)**: This chapter *is* the Four Rules of Simple Design executed on a real module — tests first, duplication removed, intent expressed.
- **Ch 3 (Functions) & Ch 10 (Classes)**: The final `Args` is small functions, top-to-bottom narrative, and SRP-partitioned classes.
- **Ch 7 (Error Handling)**: Moving error state and formatting into `ArgsException`; replacing swallowed catches and a `valid` flag with thrown exceptions.
- **Ch 17 (Smells and Heuristics)**: The draft is a catalogue of them — too many fields, sentinel strings, parallel structures, empty catch.
- **TDD / Refactoring (Fowler)**: Red-green-refactor and behavior-preserving transformation are the machinery underneath the whole case study.
- **The Boy Scout Rule**: "If you made a mess five minutes ago, it's very easy to clean it up right now."
