# Chapter 11: Systems

## Core Idea
Cleanliness at the system level comes from separating concerns: build the system's startup/wiring as its own modularized concern (via `main`, factories, or Dependency Injection), keep domain logic in POJOs, and weave cross-cutting concerns in noninvasively with aspects — so the architecture can be test-driven and grown incrementally instead of designed Big Design Up Front.

## Frameworks Introduced

- **Separate Constructing a System from Using It**: Software systems should separate the startup process, when application objects are constructed and dependencies are "wired" together, from the runtime logic that takes over after startup.
  - When to use: Always — the moment you see `new` or a lazy-init getter inside business logic.
  - How:
    1. Identify every construction idiom scattered through runtime code (`if (service == null) service = new MyServiceImpl(...)`).
    2. Move all construction to `main` or modules called by `main`; design the rest of the system assuming everything is already built and wired.
    3. Make dependency arrows cross the `main`/application barrier in one direction only — pointing *away* from `main`. The application must have no knowledge of `main` or of the construction process.
    4. Where the application must control *when* an object is created, use an ABSTRACT FACTORY: the application holds the factory interface, the implementation lives on the `main` side.
    5. Where possible, hand off wiring entirely to a DI container.
  - Why it works / failure mode: A single LAZY-INITIALIZATION is harmless; the failure mode is accumulation — many little setup idioms scatter the global setup *strategy* across the application with no modularity and significant duplication, so no consistent strategy for resolving major dependencies ever exists.

- **Dependency Injection (DI)**: The application of **Inversion of Control (IoC)** to dependency management. IoC moves secondary responsibilities from an object to other objects dedicated to that purpose, thereby supporting the Single Responsibility Principle.
  - When to use: Whenever an object would otherwise instantiate or look up its own dependencies.
  - How: The class takes **no direct steps** to resolve its dependencies; it is completely **passive**. It exposes setter methods and/or constructor arguments used to *inject* dependencies. An authoritative mechanism — `main` or a special-purpose container — instantiates the required objects (usually on demand) and wires them, driven by a configuration file or a programmatic construction module.
  - Why it works / failure mode: JNDI lookup (`jndiContext.lookup("NameOfMyService")`) is only a *partial* DI — the invoking object still actively resolves its own dependency, so the coupling and the SRP violation remain. True DI removes even that step.

- **Cross-Cutting Concerns / Aspect-Oriented Programming (AOP)**: Concerns like persistence, transactions, and security cut across natural object boundaries; AOP is a general-purpose approach to restoring modularity for them.
  - When to use: Whenever the same strategy (persistence, transactions, security, caching, failover) must apply consistently across many unrelated domain objects.
  - How: Declare in a modular construct (**aspect**) which points in the system — which objects and attributes, or *patterns* thereof — should have their behavior modified, then delegate to the framework. Behavior modifications are made **noninvasively** (no manual editing of target source). Three Java mechanisms: **Java Proxies** (JDK dynamic proxies work only with interfaces; use CGLIB/ASM/Javassist to proxy classes), **Pure Java AOP Frameworks** (Spring AOP, JBoss AOP — cover 80–90% of useful aspect cases), **AspectJ Aspects** (most full-featured; costs new tools and language constructs).

- **Test Drive the System Architecture**: Write domain logic as POJOs decoupled from architecture concerns, then evolve architecture from simple to sophisticated by adopting technologies on demand.
  - When to use: At project start, instead of BDUF.
  - How: Start with a "naively simple" but nicely decoupled architecture; deliver working user stories quickly; add infrastructure as you scale up; keep the ability to change course.

- **Optimize Decision Making**: Postpone decisions until the last possible moment, so choices are made with the most customer feedback, reflection, and implementation experience available.

- **Use Standards Wisely, When They Add Demonstrable Value**: Adopt a standard for reuse/recruiting/encapsulated ideas — not because it is a standard. Many teams used EJB2 purely because it was standard when lighter designs sufficed.

- **Systems Need Domain-Specific Languages (DSLs)**: Small scripting languages or APIs in standard languages that let code read like structured prose a domain expert might write; they minimize the communication gap between domain concept and implementing code, and allow all levels of abstraction and all domains to be expressed as POJOs.

## Key Concepts
- **Separation of Concerns**: One of the oldest and most important design techniques; keeping distinct system responsibilities in distinct modules.
- **Lazy Initialization/Evaluation**: Constructing an object only on first use — an *optimization*, and perhaps a premature one.
- **POJO (Plain-Old Java Object)**: A class purely focused on its domain, with no dependencies on enterprise frameworks or other domains.
- **Abstract Factory**: Pattern giving the application control of *when* an object is built while keeping *how* it is built on the `main` side of the line.
- **Aspect**: A modular construct specifying which points in the system get their behavior modified to support a particular concern.
- **Noninvasive**: Applied without manual editing of the target source code.
- **BDUF (Big Design Up Front)**: Designing everything up front before implementing anything at all — harmful, because it inhibits adapting to change.
- **Decorator "Russian doll"**: Nested wrapping of a POJO by DAO, data source, transaction, and caching proxies, so the client believes it calls the bare object.

## Mental Models
- Think of a system as **a city**: it works because separate teams own water, power, traffic, and building codes at appropriate levels of abstraction and modularity — no one understands the whole.
- Think of construction vs. use as **the hotel under construction vs. the finished hotel**: cranes, hard hats, and bolted-on elevators exist during startup and are entirely absent at runtime.
- Use **the direction of dependency arrows** as your test for correct separation: if any arrow points from the application back toward `main`, construction has leaked into use.
- Think of a good API as one that should **largely disappear from view** — if architectural constraints are visible in daily work, they are inhibiting delivery of value.

## Anti-patterns
- **Lazy-init getters scattered through runtime code**: Hard-codes a dependency on a specific implementation (can't compile without resolving it even if never used at runtime), forces test doubles to be assigned before the method is called, requires testing every execution path including the `null` branch, and breaks SRP in a small way.
- **Assuming one type is right for all contexts**: The class with the lazy-init getter must know the global context to pick the right implementation — it can't.
- **Invasive containers (EJB2 entity beans)**: Business logic tightly coupled to the container; you must subclass container types and supply many empty lifecycle methods; isolated unit testing requires mocking the container; reuse outside the architecture is effectively impossible; beans can't inherit from beans, forcing DTO "structs" and boilerplate copying.
- **Big Design Up Front**: Inhibits adaptation, both from psychological resistance to discarding prior effort and from the way early architecture choices frame all later thinking.
- **Adopting a standard for its own sake**: Standards can take too long to create and lose touch with adopters' real needs.

## Code Examples

Before — construction mixed into runtime logic:

```java
   public Service getService() {
     if (service == null)
       service = new MyServiceImpl(…); // Good enough default for most cases?
     return service;
   }
```

Partial DI (JNDI lookup) — the invoking object still resolves the dependency:

```java
   MyService myService = (MyService)(jndiContext.lookup("NameOfMyService"));
```

After — wiring declared outside the code, in a Spring configuration file:

```xml
   <beans>
     <bean id="appDataSource"
     class="org.apache.commons.dbcp.BasicDataSource"
     destroy-method="close"
     p:driverClassName="com.mysql.jdbc.Driver"
     p:url="jdbc:mysql://localhost:3306/mydb"
     p:username="me"/>

     <bean id="bankDataAccessObject"
     class="com.example.banking.persistence.BankDataAccessObject"
     p:dataSource-ref="appDataSource"/>

     <bean id="bank"
     class="com.example.banking.model.Bank"
     p:dataAccessObject-ref="bankDataAccessObject"/>
   </beans>
```

```java
   XmlBeanFactory bf =
     new XmlBeanFactory(new ClassPathResource("app.xml", getClass()));
   Bank bank = (Bank) bf.getBean("bank");
```

- **What it demonstrates**: Because so few lines of Spring-specific Java are required, the application is almost completely decoupled from Spring — eliminating the tight-coupling problems of EJB2.

## Worked Example

**The `Bank` system, three ways.**

1. *EJB2 entity bean.* A `BankLocal` interface extending `EJBLocalObject` with a dozen getters/setters each declaring `throws EJBException`; an abstract `Bank` class implementing `javax.ejb.EntityBean` with `ejbCreate`, `ejbPostCreate`, `setEntityContext`, `unsetEntityContext`, `ejbActivate`, `ejbPassivate`, `ejbLoad`, `ejbStore`, `ejbRemove` — most of them empty but mandatory; plus a `LocalHome` factory interface and XML deployment descriptors for O/R mapping, transactions, and security. `addAccount` does its own `InitialContext` JNDI lookup. Result: business logic welded to a heavyweight container, untestable in isolation, no bean-to-bean inheritance, DTO structs and copy boilerplate.

2. *What EJB2 got right.* Transactional, security, and some persistence behaviors are declared in deployment descriptors, independent of source — it "anticipated" AOP. Persistence is a genuine cross-cutting concern: you want one strategy (one DBMS, one naming convention, one transactional semantics) applied across all objects, yet in practice the same code gets spread across many objects. The problem is the fine-grained *intersection* of two individually modular domains.

3. *POJO + DI + aspects.* Write `Bank` as a POJO with zero framework dependencies. Declare infrastructure in `app.xml`. The DI container instantiates and wires the objects; the client thinks it is calling `getAccounts()` on a `Bank`, but is really talking to the outermost of a nested set of DECORATOR objects (JDBC data source → DAO → `Bank`). Adding transactions or caching means adding another decorator, not editing `Bank`.

**The recap Martin gives:** "An optimal system architecture consists of modularized domains of concern, each of which is implemented with Plain Old Java (or other) Objects. The different domains are integrated together with minimally invasive Aspects or Aspect-like tools. This architecture can be test-driven, just like the code."

## Key Takeaways
1. Move all construction and wiring into `main` or modules called by `main`; let dependency arrows point only away from `main`.
2. Prefer true Dependency Injection — a passive class with setters/constructor args — over lazy init, `new` in business logic, or even JNDI-style lookup.
3. Treat lazy initialization as an optimization, and suspect it of being premature.
4. Handle persistence, transactions, security, and caching as cross-cutting concerns via aspects or aspect-like proxies, never by hand-spreading the same code across domain objects.
5. Architectures *can* grow incrementally from simple to complex — but only if you maintain proper separation of concerns. Reject BDUF; implement today's stories, then refactor and expand.
6. Postpone decisions to the last possible moment; a premature decision is one made with suboptimal knowledge.
7. Build a DSL when domain experts and code should share vocabulary — it removes translation risk.
8. Whether designing systems or modules, use the simplest thing that can possibly work.

## Connects To
- **Ch 3 (Functions) & Ch 10 (Classes)**: SRP applied at the system level — IoC exists precisely to keep secondary responsibilities out of an object.
- **Ch 12 (Emergence)**: Test-driving the architecture is Simple Design Rule 1 ("runs all the tests") scaled up to the system.
- **Ch 13 (Concurrency)**: Same prescription — separate the framework concern (threading) from thread-ignorant POJOs.
- **Dependency Inversion Principle / Hollywood Principle**: "Don't call us, we'll call you" is IoC stated as a slogan.
- **GOF patterns**: ABSTRACT FACTORY and DECORATOR are the two structural workhorses of this chapter.
