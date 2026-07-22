# Chapter 12: Pipeline Architecture Style

## Core Idea
Also called **pipes and filters**: a single deployment unit whose functionality lives in stateless, single-purpose **filters** connected by **unidirectional pipes** — the compositional abstraction behind Unix shells, MapReduce, and ETL.

## Topology

- **Isomorphic shape**: *a single deployment unit, with functionality contained within filters connected by unidirectional pipes.*
- **Two component types only**: filters (system functionality) and pipes (data transfer). Pipes form one-way, usually point-to-point communication between filters.
- **Partitioning**: technically partitioned (application logic separated into filter *types*). **Architecture quantum**: always 1.
- Most implementations are monolithic, but each filter (or a set of filters) *can* be deployed as a service, creating a distributed architecture with synchronous or asynchronous remote calls.

## Frameworks Introduced

- **The Four Filter Types** — filters are self-contained, independent, generally **stateless**, and **should perform one task only**. Composite tasks are handled by a *sequence* of filters, never a single one. A filter may be implemented by more than one class file, so it is a **component** (Ch 8) — and even a single-class filter is still a component.

  | Type | Role | Functional analogue |
  |---|---|---|
  | **Producer** (a.k.a. **source**) | The starting point; outbound only. A user interface or an external request | — |
  | **Transformer** | Accepts input, optionally transforms some or all of the data, forwards it. Enhances data, transforms data, performs calculations | `map` |
  | **Tester** | Accepts input, tests it against criteria, optionally produces output. Validates data, or acts as a switch ("don't forward if the order amount is under five dollars") | `reduce` |
  | **Consumer** | The termination point; persists the final result to a database or displays it on a UI screen | — |

- **Pipes** — the communication channel. Typically unidirectional and point-to-point, accepting input from one source and directing output to another. Payload can be any data format, but **architects typically favor smaller payloads for performance**. In distributed deployments a pipe is a unidirectional remote call (REST, messaging, streaming). Pipes can be synchronous or asynchronous in either topology; in monolithic deployments, asynchrony is achieved with threads or embedded messaging.

- **Governance via tags** — it is difficult to write an automated fitness function that verifies a producer filter really is the starting point, or that a tester filter really performs a conditional check. Instead, use **tags** (Java **annotations**, C# **custom attributes**): they perform no function but supply metadata about the component, telling developers what kind of filter they are creating or modifying and discouraging them from overloading it.

## Code Examples

**McIlroy's shell pipeline** — from the blog *"More Shell, Less Egg."* Donald Knuth was asked to read a file of text, determine the *n* most frequently used words, and print them sorted by frequency. He wrote **over 10 pages of Pascal**, designing and documenting a new algorithm along the way. Doug McIlroy answered with a shell script short enough to fit in a social media post:
```bash
tr -cs A-Za-z '\n' |
tr A-Z a-z |
sort |
uniq -c |
sort -rn |
sed ${1}q
```
- **What it demonstrates**: the unidirectional simplicity of pipes and filters encourages compositional reuse. *Even the designers of Unix shells are often surprised at the inventive uses developers find for their simple but powerful composite abstractions.*

**AWS Step Function deployment** — the fitness-function pipeline as a cloud workflow, each filter a separate lambda:
```json
{
  "Comment": "Measure and analyze scalability trends.",
  "StartAt": "Capture Raw Data",
  "States": {
    "Capture Raw Data": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:region:account_id:function:raw_data_capture",
    "Next": "Time Series Selector"
   },
    "Time Series Selector": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:region:account_id:function:time_series_selector",
    "Next": "Trend Analyzer"
   },
    "Trend Analyzer": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:region:account_id:function:trend_analyzer",
    "Next": "Graphing Tool"
    },
    "Graphing Tool": {
    "Type": "Task",
    "Resource": "arn:aws:lambda:region:account_id:function:graphing_tool",
    "End": true
    }
  }
}
```
- **AWS Step Functions offer two workflows**: **Standard** (each step executed exactly once) and **Express** (each step can execute more than once). The pipeline style works with both.

**Filter type tags (Java)**:
```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface Filter {
   public FilterType[] value();

   public enum FilterType {
      PRODUCER,
      TESTER,
      TRANSFORMER,
      CONSUMER
   }
}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface FilterEntrypoint {}
```
Applied to the entry-point class of a multi-class filter:
```java
@FilterEntrypoint
@Filter(FilterType.TRANSFORMER)
public class TrendAnalyzerFilter {
   ...
}
```
**C# equivalent**:
```csharp
[System.AttributeUsage(System.AttributeTargets.Class)]
class Filter : System.Attribute {
   public FilterType[] filterType;
   public enum FilterType { PRODUCER, TESTER, TRANSFORMER, CONSUMER };
}

[FilterEntrypoint]
[Filter(FilterType.TRANSFORMER)]
class TrendAnalyzerFilter { ... }
```
- **Honest limitation**: *"While this technique might not stop every developer from making a transformer filter type perform testing logic, at least it provides additional context."*

## Reference Tables

**Characteristics ratings**

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Cost** | ★★★★★ | Primary strength — no distributed complexity |
| **Simplicity** | ★★★★★ | Primary strength — simple and easy to understand |
| **Modularity** | ★★★★ | Separation of concerns between filter types; **any filter can be modified or replaced without affecting the others** |
| **Deployability** | ★★★ | Slightly higher than layered thanks to filter modularity, but still monolithic: ceremony, risk, deployment frequency |
| **Testability** | ★★★ | Same reasoning |
| **Elasticity** | ★ | Monolithic deployment |
| **Scalability** | ★ | Monolithic deployment |
| **Fault tolerance** | ★ | One out-of-memory condition crashes the whole unit |
| **Availability** | ★ | High MTTR; startup measured in minutes |

**The escape hatch**: most of the low operational scores can be raised by implementing this as a **distributed** architecture with **asynchronous** communication — each filter a separate deployment unit, each pipe a remote call. The price is simplicity and cost. *A classic trade-off of software architecture.*

## Worked Example

**Service telemetry processing via Kafka.** Service telemetry is streamed to Apache Kafka; the pipeline consumes and processes it:

1. **`Service Info Capture`** (*producer*) — subscribes to the Kafka topic and receives service information. It is concerned **only** with connecting to a Kafka topic and receiving streaming data.
2. **`Duration`** (*tester*) — determines whether the data relates to the duration (in ms) of a service request. It is concerned **only** with qualifying the data and deciding whether to route it onward.
   - If yes → `Duration Calculator`.
   - If no → `Uptime` tester.
3. **`Duration Calculator`** (*transformer*) — computes the duration metric.
4. **`Uptime`** (*tester*) — checks whether the data relates to uptime metrics. **If not, the pipeline simply ends** — the data is of no interest to this flow.
5. **`Uptime Calculator`** (*transformer*) — calculates uptime metrics and passes the modified data on.
6. **`Database Output`** (*consumer*) — persists the result in a MongoDB database.

**Why this shape works**: note the separation of concerns at every hop — no filter knows anything about the filter before or after it beyond the pipe contract. **Extensibility**: adding a new metric (say, database connection wait time) means adding one new tester filter after `Uptime`. Nothing else changes.

**Data topology note**: this style is *usually* one monolithic database, but need not be. In a related continuous-fitness-function pipeline, `Capture Raw Data` loads its own raw-data database, `Time Series Selector` reads configuration (e.g. the period being analyzed) from a *separate* database, `Trend Analyzer` stores analytics in a *third*, and `Graphing Tool` ends the pipeline by generating a graphical report. **Database topology can vary from a single database to one database per filter.**

## Anti-patterns / Common Risks

- **Overloading filters with too much responsibility** — the primary risk. Each filter performs *one* specific action on the data. Left unchecked, the pipeline becomes an unstructured monolith. Mitigate with tag-based governance.
- **Bidirectional communication between filters** — pipes are **unidirectional only**, which is what gives the clear separation of concerns and prevents collaboration between filters. If bidirectional communication turns out to be necessary, that is *a good indication that pipeline is the wrong style, or that the filters are too complex and functionality isn't demarcated correctly.*
- **Unplanned error handling** — if an error occurs mid-pipeline, it is often difficult to determine how to exit and recover once the pipeline has started. **Architects must determine possible fatal error conditions before defining the architecture.**
- **Uncontrolled contract change** — each pipe carries a contract representing the data (and possibly the types) sent to the next filter. Changing it requires strict governance and testing so downstream filters don't break.

## When to Use
- Systems of **any** complexity with **distinct, ordered, and deterministic one-way processing steps**.
- Tight time frames and budget constraints (simplicity).

## When Not to Use
- Systems needing high scalability, elasticity, and fault tolerance — unless you take the distributed variant.
- **Back-and-forth communication between filters** — pipes are unidirectional.
- **Nondeterministic workflows.** It is *possible* to force this with lots of tester filters throughout the pipeline, but the authors **don't recommend it**: it overcomplicates a relatively simple style and hurts maintainability, testability, deployability, and therefore reliability. **Event-driven architecture (Ch 15) is much better suited.**

## Cloud Considerations
Well suited to cloud deployment thanks to high modularity and separate filter types. Because most pipelines aren't overly complex or extensive, they work well deployed monolithically with all filters in one unit. Filters also work well as **distributed functions** — AWS Step Functions with each filter a lambda, serverless functions, containerized functions, or a single service containing all filter components.

## Team Topology Considerations
Generally **independent of team topology** — works with any configuration.
- **Stream-aligned**: the pipeline is typically small, self-contained, and represents a single journey through the system; teams own the flow beginning to end.
- **Enabling**: specialists can experiment by **introducing additional filters without affecting the rest of the flow** — e.g. adding a transformation filter after `Time Series Selector` to do alternative trend analysis, using the same data as the existing `Trend Analyzer` without disrupting the normal flow.
- **Complicated-subsystem**: each filter performs a very specific task, and **the unidirectional handoffs let members focus narrowly on the complexity inside their own filter.**
- **Platform**: leverage high modularity through common tools, services, APIs, and tasks.

## Examples and Use Cases
- **Unix terminal shells** (Bash, Zsh) — the canonical implementation.
- **MapReduce** tools follow this basic topology.
- **EDI tools** — building transformations from one document type to another using pipes and filters.
- **Database ETL tools** — modifying data and flowing it from one database or data source to another.
- **Orchestrators and mediators** such as **Apache Camel** — passing information from one step in a business process to another.

## Key Takeaways
1. One filter, one task. Composite work is a *sequence* of filters, never a bigger filter.
2. Keep pipes unidirectional; needing bidirectional flow is a signal to change styles, not to bend the pipes.
3. Tag filters with their type — you can't easily write a fitness function for filter semantics, but you can supply context at the point of temptation.
4. Design the error-exit strategy *before* defining the architecture; mid-pipeline recovery is genuinely hard.
5. Keep pipe payloads small for performance, and govern contract changes strictly.
6. Reach for the distributed/async variant only when you need the operational characteristics enough to pay in simplicity and cost.
7. Use event-driven architecture instead for nondeterministic workflows.

## Connects To
- **Ch 8**: filters are components.
- **Ch 6**: the continuous fitness function example is itself implemented as a pipeline.
- **Ch 10**: the Architecture Sinkhole antipattern; the layered comparison for deployability/testability.
- **Ch 13**: microkernel — the other modular monolithic style.
- **Ch 15**: event-driven architecture — the right answer for nondeterministic workflows.
