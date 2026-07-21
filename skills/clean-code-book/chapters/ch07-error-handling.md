# Chapter 7: Error Handling

*by Michael Feathers*

## Core Idea
Error handling is a separate concern from the main algorithm: if it obscures logic, it's wrong. Use exceptions (not return codes), define try-catch scopes first, and eliminate `null` from your interfaces so the bulk of your code reads as a clean unadorned algorithm.

## Frameworks Introduced

- **Use Exceptions Rather Than Return Codes**
  - When to use: Any method that can detect an error condition.
  - How: Throw from the detecting method instead of returning a flag/code. In the caller, wrap the happy-path algorithm in a single `try`, extract the algorithm into its own method (e.g. `tryToShutDown()`), and let the `catch` do only error handling.
  - Why it works / failure mode: Return codes clutter the caller — the caller must check immediately after the call, and it's easy to forget. Extracting separates two tangled concerns (the shutdown algorithm and error handling) so each can be understood independently.

- **Write Your Try-Catch-Finally Statement First**
  - When to use: Whenever writing code that could throw — especially under TDD.
  - How:
    1. Write a test that expects the exception, e.g. `@Test(expected = StorageException.class)`.
    2. Write a stub; watch the test fail because nothing throws.
    3. Add the operation that actually throws, wrap in `try`/`catch(Exception)`, rethrow your own exception type — test passes.
    4. Refactor: narrow the caught type to what is actually thrown (`FileNotFoundException`).
    5. Build the rest of the logic inside the now-defined `try` scope with TDD; that logic can pretend nothing goes wrong.
  - Why it works / failure mode: `try` blocks are like transactions — exceptions *define a scope*, and your `catch` must leave the program in a consistent state no matter what happens in the `try`. Defining the scope first forces you to state what the caller should expect. Failure mode: adding error handling last means the transaction boundary is retrofitted around code that already assumes success.

- **Use Unchecked Exceptions**
  - When to use: General application development (Java). Checked exceptions can be useful when writing a **critical library** where callers must catch.
  - How: Prefer unchecked exception types; don't add `throws` clauses to propagate low-level failures upward.
  - Why it works / failure mode: The price of checked exceptions is an **Open/Closed Principle** violation. If you throw a checked exception and the `catch` is three levels above, you must declare it in every signature between — a cascade of changes from the lowest levels to the highest, forcing rebuilds and redeploys of modules that don't care. Encapsulation is broken because every function in the path of a throw must know about the low-level exception. Evidence: C#, C++, Python, and Ruby have no checked exceptions and robust software is written in all of them.

- **Define Exception Classes in Terms of a Caller's Needs**
  - When to use: Designing exception hierarchies, especially around third-party APIs.
  - How: Classify by **how they will be caught**, not by source or type. Wrap the third-party API in your own class that catches its many exception types and rethrows one common type. Often a single exception class is fine for a particular area of code — the information sent with the exception distinguishes the errors. Use different classes only when you want to catch one and let the other pass through.
  - Why it works: Most exception handling work is the same regardless of cause (record the error, make sure you can proceed), so multiple catch clauses are pure duplication.

- **Special Case Pattern** [Fowler]
  - When to use: When a "failure" is really a known alternative business outcome, not an abort.
  - How: Create a class or configure an object that handles the special case, so the client never sees exceptional behavior. Return it instead of throwing or returning `null`.

## Key Concepts
- **Wrapping a third-party API**: A best practice — minimizes dependency, allows switching libraries later, makes third-party calls easy to mock, and frees you from a vendor's API design choices.
- **Transaction scope of a `try`**: The region in which execution can abort at any point and resume at the `catch`; the `catch` must restore consistency.
- **Context with exceptions**: Informative error messages passed with the exception naming the operation that failed and the type of failure — a stack trace can't tell you the *intent* of the failed operation.
- **Special Case object**: An object encapsulating exceptional behavior so client code stays on one path (`PerDiemMealExpenses`).
- **`Collections.emptyList()`**: A predefined immutable list to return instead of `null` from collection-returning methods.
- **Defining the normal flow**: Pushing error detection to the edges of the program so the core reads as a clean algorithm.

## Mental Models
- Think of a `try` block as a **transaction**: whatever happens inside, the `catch` leaves the program consistent.
- Use **"error handling is one thing"**: a function that handles errors should do nothing else.
- Think of `null` as a **contagion you emit**: returning it creates work for yourself and foists problems on every caller; one missing check sends the app spinning out of control.
- Use a **wrapper at every boundary** so that "how this library fails" is knowledge held in exactly one class.

## Anti-patterns
- **Returning null**: Invites errors and litters callers with checks. The problem with null-checking code isn't a missing check — it's that there are *too many* checks. Prefer an exception or a Special Case object.
- **Passing null**: Worse than returning it. In most languages there is no good way to handle a null passed accidentally; neither `InvalidArgumentException` (what would the handler do?) nor `assert` solves the runtime failure. The rational approach is to **forbid passing null by default**.
- **Catching NullPointerException at the top level (or not)**: Either way it's bad — there's no sensible response to an NPE from the depths of the application.
- **Duplicated catch blocks per third-party exception type**: Signals that a wrapper with a single exception type is missing.
- **Nested null-guard pyramids**: Obscure logic and still miss cases (e.g. an unguarded `persistentStore`).

## Code Examples

Before — nested error checking dominates the logic:

```java
public class DeviceController {
  …
  public void sendShutDown() {
    DeviceHandle handle = getHandle(DEV1);
    // Check the state of the device
    if (handle != DeviceHandle.INVALID) {
      // Save the device status to the record field
      retrieveDeviceRecord(handle);
      // If not suspended, shut down
      if (record.getStatus() != DEVICE_SUSPENDED) {
        pauseDevice(handle);
        clearDeviceWorkQueue(handle);
        closeDevice(handle);
      } else {
        logger.log("Device suspended.  Unable to shut down");
      }
    } else {
      logger.log("Invalid handle for: " + DEV1.toString());
    }
  }
  …
}
```

After — algorithm and error handling separated:

```java
public class DeviceController {
  …
  public void sendShutDown() {
    try {
      tryToShutDown();
    } catch (DeviceShutDownError e) {
      logger.log(e);
    }
  }

  private void tryToShutDown() throws DeviceShutDownError {
    DeviceHandle handle = getHandle(DEV1);
    DeviceRecord record = retrieveDeviceRecord(handle);

    pauseDevice(handle);
    clearDeviceWorkQueue(handle);
    closeDevice(handle);
  }

  private DeviceHandle getHandle(DeviceID id) {
    …
    throw new DeviceShutDownError("Invalid handle for: " + id.toString());
    …
  }
  …
}
```

- **What it demonstrates**: Two tangled concerns — the device shutdown algorithm and error handling — become independently readable.

Eliminating a null return:

```java
List<Employee> employees = getEmployees();
for(Employee e : employees) {
  totalPay += e.getPay();
}
```

```java
public List<Employee> getEmployees() {
  if( .. there are no employees .. )
    return Collections.emptyList();
}
```

- **What it demonstrates**: Returning an empty collection instead of `null` deletes the caller's guard entirely.

## Worked Example

**Wrapping ACMEPort → one exception type.**

The unwrapped call requires three near-identical catch clauses:

```java
ACMEPort port = new ACMEPort(12);

try {
  port.open();
} catch (DeviceResponseException e) {
  reportPortError(e);
  logger.log("Device response exception", e);
} catch (ATM1212UnlockedException e) {
  reportPortError(e);
  logger.log("Unlock exception", e);
} catch (GMXError e) {
  reportPortError(e);
  logger.log("Device response exception");
} finally {
  …
}
```

Because the work is roughly the same regardless of cause, wrap the API and return a common exception type:

```java
public class LocalPort {
  private ACMEPort innerPort;

  public LocalPort(int portNumber) {
    innerPort = new ACMEPort(portNumber);
  }

  public void open() {
    try {
      innerPort.open();
    } catch (DeviceResponseException e) {
      throw new PortDeviceFailure(e);
    } catch (ATM1212UnlockedException e) {
      throw new PortDeviceFailure(e);
    } catch (GMXError e) {
      throw new PortDeviceFailure(e);
    }
  }
  …
}
```

The call site collapses:

```java
LocalPort port = new LocalPort(12);
try {
  port.open();
} catch (PortDeviceFailure e) {
  reportError(e);
  logger.log(e.getMessage(), e);
} finally {
  …
}
```

**Special Case Pattern: meal expenses.** Awkward version, where the exception *is* the business rule:

```java
try {
  MealExpenses expenses = expenseReportDAO.getMeals(employee.getID());
  m_total += expenses.getTotal();
} catch(MealExpensesNotFound e) {
  m_total += getMealPerDiem();
}
```

Change `ExpenseReportDAO` to always return a `MealExpenses` object; when there are none, return one whose total is the per diem:

```java
public class PerDiemMealExpenses implements MealExpenses {
  public int getTotal() {
    // return the per diem default
  }
}
```

The client reduces to two unconditional lines:

```java
MealExpenses expenses = expenseReportDAO.getMeals(employee.getID());
m_total += expenses.getTotal();
```

## Key Takeaways
1. Throw exceptions instead of returning error codes, and extract the happy path into its own method so the `try` body reads as an algorithm.
2. Write the try-catch-finally first; drive it with a test that forces the exception, then narrow the caught type.
3. Prefer unchecked exceptions in application code — checked exceptions violate the Open/Closed Principle and break encapsulation across the call stack.
4. Give every exception enough context to identify the operation that failed and the type of failure.
5. Define exception classes by how they'll be caught; one class per area of code is usually enough.
6. Wrap third-party APIs — it minimizes dependency, eases mocking, and lets you design the API you want.
7. Don't return null (use exceptions, Special Case objects, or `Collections.emptyList()`); don't pass null — forbid it by default.

## Connects To
- **Ch 3 (Functions)**: "Error handling is one thing" — a function that handles errors should do nothing else; `sendShutDown` is that rule applied.
- **Ch 8 (Boundaries)**: Wrapping the third-party API here is the same boundary-management technique applied to exceptions.
- **Ch 10 (Classes)**: The Open/Closed Principle cited against checked exceptions is developed there.
- **Special Case Pattern [Refactoring, Fowler]** and the **Null Object pattern**: the external names for the technique.
- **Agile Software Development: Principles, Patterns, and Practices, Robert C. Martin**: source of the OCP argument.
