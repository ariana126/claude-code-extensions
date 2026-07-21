# Template Method
**Classification**: Class Behavioral | **Chapter**: 5

## Intent
Define the skeleton of an algorithm in an operation, deferring some steps to subclasses. Template Method lets subclasses redefine certain steps of an algorithm without changing the algorithm's structure.

## Core Idea
Write the algorithm **once** in the parent class as a sequence of calls to **primitive operations**, and let subclasses fill in only the steps that vary. The parent fixes the ordering; subclasses supply the content.

## Applicability
Use Template Method:
- To implement the invariant parts of an algorithm once, leaving subclasses to implement the behavior that can vary.
- When common behavior among subclasses should be factored and localized in a common class to avoid duplication — "refactoring to generalize": identify the differences in existing code, separate the differences into new operations, then replace the differing code with a template method that calls them.
- To **control subclass extensions**: define a template method that calls **hook** operations at specific points, permitting extension only at those points.

## Structure
- **AbstractClass** (Application): defines the abstract **primitive operations** that concrete subclasses implement, and implements the template method defining the algorithm's skeleton. The template method calls primitive operations plus operations defined in AbstractClass or on other objects.
- **ConcreteClass** (MyApplication, DrawApplication): implements the primitive operations to carry out subclass-specific steps.

Collaboration: ConcreteClass relies on AbstractClass to implement the invariant steps. Control flows **down** — this is a class-scoped pattern using inheritance, not object composition.

## How
1. Write the algorithm as a single operation in the abstract class, expressed entirely as calls to named steps.
2. Classify each step: **concrete operation** (already implemented, invariant), **abstract/primitive operation** (subclass *must* override — declare pure virtual), **hook operation** (subclass *may* override — supply a default, often empty), or **factory method** (subclass decides which object to create).
3. Declare primitive operations `protected` so only the template method — not clients — can call them.
4. Make the template method itself **nonvirtual** so subclasses cannot replace the skeleton.
5. Name overridable operations by convention (`Do-` prefix) so subclass authors can see them.
6. Minimize the number of primitive operations a subclass must fill in.

## Consequences
**Benefits**
- Template methods are a **fundamental technique for code reuse**, especially in class libraries, because they are the means for factoring common behavior into library classes.
- They give the parent class control over **how** subclasses extend behavior. Rather than trusting a subclass to remember `ParentClass::Operation()` when overriding, the parent calls a hook from within a template method — extension becomes structurally guaranteed rather than conventional.
- Extension points are explicit and bounded: subclasses can only vary the algorithm where the parent invited them to.

**Liabilities**
- The inverted control structure — **"the Hollywood principle": "Don't call us, we'll call you"** — means the parent class calls the subclass's operations, not the other way around. Debugging and reading the code requires holding both halves in your head.
- Too many primitive operations makes the abstract class tedious and error-prone to subclass.
- Behavior is spread across an inheritance hierarchy; you cannot vary the algorithm at run-time (that's Strategy).

## Implementation Notes
- **Hook operations vs. abstract operations.** A **hook** provides default behavior that subclasses *may* extend — it often does nothing by default. An **abstract (primitive) operation** *must* be overridden. It is essential that a template method document which is which: to reuse an abstract class effectively, subclass writers must know which operations are designed for overriding. In C++, express the distinction in the code — pure virtual for "must", virtual with a default body for "may".
- **Converting an extension point into a hook.** A subclass can extend a parent operation by overriding it and calling the parent explicitly — but it's easy to forget the call:

  ```cpp
  void DerivedClass::Operation () {
      ParentClass::Operation();      // easy to omit — and then everything breaks
      // DerivedClass extended behavior
  }
  ```

  Transform it into a template method so the parent controls the extension:

  ```cpp
  void ParentClass::Operation () {
      // ParentClass behavior
      HookOperation();               // subclass hook, called by the parent
  }
  void ParentClass::HookOperation () { }   // does nothing by default

  void DerivedClass::HookOperation () {
      // derived class extension
  }
  ```
- **Using C++ access control.** Declare primitive operations `protected` so only the template method can call them; declare operations that *must* be overridden pure virtual; make the template method **nonvirtual** so it cannot be overridden.
- **Minimizing primitive operations.** A key design goal: minimize the number of primitive operations a subclass must override to flesh out the algorithm. The more operations that need overriding, the more tedious things get for clients. Fold invariant work into concrete AbstractClass operations and prefer hooks with sensible defaults over more pure virtuals.
- **Naming conventions.** Identify overridable operations with a name prefix — MacApp prefixes template-method-called operations with "Do-": `DoCreateDocument`, `DoRead`.
- **What template methods call.** Concrete operations (on the ConcreteClass or on client classes); concrete AbstractClass operations generally useful to subclasses; primitive (abstract) operations; **factory methods**; and hook operations.

## Worked Example
Two canonical skeletons.

**1. Framework document opening (MacApp-style).** `Application::OpenDocument` fixes the order: check, notify, create, register, read.

```cpp
void Application::OpenDocument (const char* name) {
    if (!CanOpenDocument(name)) {        // primitive — subclass must decide
        return;
    }
    Document* doc = DoCreateDocument();  // factory method — subclass supplies type
    if (doc) {
        _docs->AddDocument(doc);
        AboutToOpenDocument(doc);        // hook — "in case they care"
        doc->Open();
        doc->DoRead();                   // primitive on Document
    }
}
```

A `DrawApplication` returns a `DrawDocument` from `DoCreateDocument`; a `SpreadsheetApplication` returns a `SpreadsheetDocument`. Neither can reorder the steps.

**2. Enforcing an invariant (NeXT AppKit's `View`).** Subclasses may draw only after the view becomes the "focus," which requires drawing state (colors, fonts) to be set up.

```cpp
void View::Display () {                  // nonvirtual template method
    SetFocus();                          // concrete: set up drawing state
    DoDisplay();                         // hook: subclass drawing
    ResetFocus();                        // concrete: release drawing state
}

void View::DoDisplay () { }              // does nothing by default

void MyView::DoDisplay () {
    // render the view's contents
}
```

Clients always call `Display`; subclasses always override `DoDisplay`. It demonstrates the Hollywood principle enforcing an invariant that no subclass can accidentally break — the setup/teardown pair cannot be forgotten because the subclass never controls it.

## Anti-patterns & Smells
- **A virtual template method**: if subclasses can override the skeleton, the invariant it enforces is worthless.
- **Public primitive operations**: clients calling `DoDisplay` directly bypass `SetFocus` and violate the very invariant the pattern exists to hold. Make them `protected`.
- **Twelve pure virtuals to subclass anything**: the abstract class is unusable. Convert most to hooks with defaults.
- **Undocumented hook vs. abstract distinction**: subclass writers guess, override the wrong things, and skip required ones.
- **"Remember to call `super`"**: any design relying on that convention should become a hook called from a parent template method.
- **Overriding an inherited operation whose parent version notifies observers**: see Observer — route notification through a template method with `Notify` last.

## Known Uses
- Template methods are so fundamental that they can be found in **almost every abstract class**. Wirfs-Brock et al. provide a good overview and discussion.
- **MacApp** — the "Do-" naming convention for overridable steps (`DoCreateDocument`, `DoRead`).
- **NeXT AppKit** — `View::Display` with `SetFocus`/`DoDisplay`/`ResetFocus`.
- Any application framework's `Application`/`Document` opening and saving protocols.

## Related Patterns
- **Factory Method**: often called *by* template methods — `DoCreateDocument` is the factory method invoked from the `OpenDocument` template method, letting subclasses choose the product type without touching the skeleton.
- **Strategy**: Template Methods use **inheritance** to vary *part* of an algorithm; Strategies use **delegation** to vary the *entire* algorithm — and can swap it at run-time.
- **Chain of Responsibility**: a handler in a chain will probably include at least one template method, using primitive operations to decide whether to handle the request and whom to forward to.
- **Observer**: send notifications from a template method in the abstract Subject, with `Notify` last, so subject state is self-consistent when observers query it.
- **Encapsulating variation** (Ch. 5 discussion): Template Method is the *class-scoped* counterpart — the varying aspect is encapsulated in an overridable operation rather than in a separate object.

## Key Takeaways
1. Put the invariant algorithm in a nonvirtual parent operation and express every varying step as a named call.
2. Say explicitly, in code and in docs, which operations are hooks (may override) and which are abstract (must override).
3. Turn every "remember to call the inherited version" into a hook invoked from a parent template method.
4. Minimize the primitive operations a subclass must implement — each one is a tax on every subclass author.
5. Use Template Method when the variation is known at compile time and structural; use Strategy when it must vary at run-time.
