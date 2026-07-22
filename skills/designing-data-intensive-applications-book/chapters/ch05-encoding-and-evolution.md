# Chapter 5: Encoding and Evolution

## Core Idea
Because rolling upgrades mean old and new code — and old and new data formats — coexist, every encoding you choose must provide **backward compatibility** (new code reads old data) and **forward compatibility** (old code reads new data); schema-driven binary formats give you those guarantees explicitly and cheaply.

## Frameworks Introduced

- **Backward vs. forward compatibility**: backward = newer code can read data written by older code; forward = older code can read data written by newer code.
  - When to use: any time code and data are versioned independently — rolling upgrades (staged rollouts), client apps users won't update, databases where "data outlives code".
  - How to reason about direction: for an **older client calling a newer service**, you need backward compatibility on the request and forward compatibility on the response. For a **newer client calling an older service**, forward compatibility on the request and backward on the response. For RPC generally you may assume servers are upgraded first and clients second — so backward compatibility on requests, forward on responses.
  - Why backward is easy, forward is hard: as author of new code you know the old format and can handle it explicitly; forward compatibility requires *old* code to ignore — and crucially preserve — additions it doesn't understand.
  - Failure mode: old code decodes a record into a model object that drops unknown fields, updates it, writes it back — **the new field is silently lost**.

- **Protocol Buffers schema evolution (field tags)**: each field carries a numeric **field tag** plus a datatype annotation; field names never appear in the encoded bytes.
  - How: (1) you may freely rename a field — names aren't encoded; (2) you may **never** change or reuse a tag number — reserve retired tags in the schema; (3) add a new field only with a new tag; old readers skip unknown tags using the type annotation to know how many bytes to skip (this is what preserves unknown fields); (4) new readers of old data fill missing fields with a type default (empty string, 0); (5) removing a field mirrors adding one, with the compatibility directions reversed.
  - Datatype changes (e.g. int32 → int64): forward-compatible reads risk **truncation** — new code reads old data fine by zero-filling, but old code reading a new 64-bit value into a 32-bit variable truncates it.

- **Avro writer's schema / reader's schema resolution**: encoded bytes contain *nothing* identifying fields or types — just concatenated values — so decoding requires both the exact writer's schema and the reader's schema.
  - How: Avro matches fields **by name**, so field order may differ. A field in the writer's schema but not the reader's is ignored. A field in the reader's schema but not the writer's is filled with the **default declared in the reader's schema**.
  - Evolution rule: you may only add or remove a field **that has a default value**. Adding a field with no default breaks backward compatibility; removing a field with no default breaks forward compatibility.
  - `null` is not a universal default — you must use a **union type** (`union { null, long, string }`), and `null` may only be the default if it is the *first* branch.
  - Renaming a field: use **aliases** in the reader's schema — backward compatible but not forward compatible. Adding a branch to a union: likewise backward-only.
  - Why it works for **dynamically generated schemas**: with no tag numbers, you can regenerate an Avro schema straight from a relational schema on every export and readers still match by name; Protocol Buffers would require a human (or a very careful generator) to assign and never reuse tags.

- **How the reader gets the writer's schema** (three contexts):
  - Large file of many records → write the schema once at the head of an Avro **object container file**.
  - Database of individually written records → prefix each record with a schema **version number** and keep a list of schema versions (Confluent Schema Registry for Kafka, LinkedIn's Espresso). Use an incrementing integer or a hash of the schema.
  - Bidirectional network connection → negotiate the schema version at connection setup and use it for the connection's lifetime (Avro RPC).

- **Durable execution / workflow engines**: a **workflow** is a graph of **tasks** (Temporal calls them *activities*; others say *durable functions*), run by a **workflow engine** composed of an **orchestrator** (schedules) and an **executor** (runs).
  - When to use: transactionality across service boundaries where a database transaction can't reach — e.g. charge a credit card *and* deposit to a bank account exactly once.
  - How it gives **exactly-once semantics**: the framework logs every RPC and state change to durable storage like a write-ahead log. On re-execution after failure it replays the task but *skips* already-successful calls, returning the previously logged result instead of making the call again.
  - Failure modes: external services must still expose **idempotent** APIs and you must pass unique IDs; replay assumes the same RPC calls in the same order, so reordering function calls introduces undefined behavior; nondeterminism (random numbers, system clocks) breaks replay. Deploy a *new version* of a workflow rather than editing the existing one, so in-flight invocations keep running old code.

## Key Concepts
- **Encoding (serialization/marshaling)**: translating in-memory objects into a self-contained byte sequence; **decoding** (parsing/deserialization) is the reverse. The book says "encoding" to avoid clashing with transaction *serializability*.
- **Schema evolution**: changing a schema over time while old and new readers/writers keep interoperating.
- **Rolling upgrade / staged rollout**: deploying a new version to a few nodes at a time, monitoring, then proceeding — enables zero-downtime, low-risk, frequent releases.
- **Data outlives code**: a deployment replaces all code in minutes, but five-year-old rows stay in their original encoding until explicitly rewritten.
- **Open vs. closed content model (JSON Schema)**: open (`additionalProperties: true`, the default) permits undefined fields of any type; closed permits only declared fields. Open models mean JSON Schema mostly defines what *isn't* permitted.
- **Zero-copy formats**: Cap'n Proto, FlatBuffers — usable at runtime and on disk/network with no explicit conversion step.
- **Web service**: a service reached over HTTP. **REST** is the dominant design philosophy — simple data formats, URLs as resource identifiers, HTTP features for caching, auth, content negotiation.
- **IDL (interface definition language)**: OpenAPI/Swagger for JSON web services; Protocol Buffers for gRPC. Drives code generation, docs, and compatibility checking.
- **Location transparency**: the RPC premise that a remote call should look like a local one — fundamentally flawed, but it works better in the actor model, which already assumes messages can be lost.
- **Service discovery**: how a client finds a service's address — static config, DNS, registries (etcd, ZooKeeper) with heartbeats, or a **service mesh** (Istio, Linkerd) using sidecar load balancers.
- **Message broker / event broker**: intermediary that stores messages temporarily; delivery is **asynchronous** — the sender doesn't wait.
- **Queue vs. topic**: a queue delivers each message to *one* consumer; a topic delivers to *all* subscribers.

## Mental Models
- **Think of writing to a database as sending a message to your future self.** Backward compatibility is mandatory. But because rolling upgrades mean an older instance may read a newer instance's write, forward compatibility is usually required too.
- **Use schemas as living documentation.** Since the schema is *required* to decode, it can't silently drift from reality the way hand-maintained docs do — and a schema registry lets you check compatibility before deploying.
- **Prefer explicitly modeling nullability over "everything is nullable".** Avro's union-type requirement is more verbose but prevents a whole class of bugs (Hoare's "billion dollar mistake").
- **Don't make a network call look like a function call.** Networks lose requests, time out ambiguously (you can't tell whether the request got through), have wildly variable latency, can't pass pointers, and must translate types across languages. REST's appeal is that it treats state transfer as visibly *not* a function call.
- **Use a message broker when you want buffering, redelivery, fan-out, and decoupling**; use RPC when you need a synchronous answer.

## Code Examples

```protobuf
syntax = "proto3";

message Person {
    string user_name = 1;
    int64 favorite_number = 2;
    repeated string interests = 3;
}
```
- **What it demonstrates**: field tags 1/2/3 are the encoded identity of each field; `repeated` means repeated occurrences of the same tag, not an array type.

```
record Person {
    string               userName;
    union { null, long } favoriteNumber = null;
    array<string>        interests;
}
```
```json
{
    "type": "record",
    "name": "Person",
    "fields": [
        {"name": "userName",       "type": "string"},
        {"name": "favoriteNumber", "type": ["null", "long"], "default": null},
        {"name": "interests",      "type": {"type": "array", "items": "string"}}
    ]
}
```
- **What it demonstrates**: Avro IDL and its JSON equivalent — no tag numbers anywhere, and nullability expressed as an explicit union with `null` first so it can be the default.

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "patternProperties": {
    "^[0-9]+$": {
      "type": "string"
    }
  },
  "additionalProperties": false
}
```
- **What it demonstrates**: JSON has no integer-keyed map type; `patternProperties` + `additionalProperties: false` simulates one — powerful, but illustrative of how unwieldy JSON Schema gets.

```python
@workflow.defn
class PaymentWorkflow:
    @workflow.run
    async def run(self, payment: PaymentRequest) -> PaymentResult:
        is_fraud = await workflow.execute_activity(
            check_fraud,
            payment,
            start_to_close_timeout=timedelta(seconds=15),
        )
        if is_fraud:
            return PaymentResultFraudulent
        credit_card_response = await workflow.execute_activity(
            debit_credit_card,
            payment,
            start_to_close_timeout=timedelta(seconds=15),
        )
        # ...
```
- **What it demonstrates**: a Temporal workflow — ordinary-looking control flow whose every activity call is logged so it can be replayed without re-invoking already-completed steps.

## Reference Tables

### Encoding formats compared (record `{"userName":"Martin","favoriteNumber":1337,"interests":["daydreaming","hacking"]}`)
| Format | Size | Schema | Compatibility mechanism | Notes |
|---|---|---|---|---|
| JSON (whitespace removed) | 81 bytes | Optional (JSON Schema) | By convention | No int/float distinction, no binary strings, no precision spec |
| MessagePack (binary JSON) | 66 bytes | None | By convention | Must still embed every field name |
| Protocol Buffers / Thrift | 33 bytes | Required | Field tag numbers + type annotations | Varints; –64..63 in 1 byte, –8192..8191 in 2 |
| Avro | 32 bytes | Required (writer's + reader's) | Field-name matching + defaults | Nothing in the bytes identifies fields or types |

### Where each compatibility direction is needed
| Dataflow | Backward needed | Forward needed |
|---|---|---|
| Database (write now, read later) | Always | Usually — an old instance may read a new instance's write during a rolling upgrade |
| RPC request (servers upgraded first) | Yes | No |
| RPC response | No | Yes |
| Public API across org boundaries | Yes, potentially indefinitely | Yes — you can't force clients to upgrade; you often run multiple API versions side by side |
| Message broker / actors | Yes | Yes — and consumers republishing must preserve unknown fields |

### Load balancing and service discovery options
| Option | Mechanism | Trade-off |
|---|---|---|
| Hardware load balancer | Datacenter appliance; single host:port front | Specialized equipment |
| Software LB (NGINX, HAProxy) | Same behavior on commodity machines | Best for simpler deployments |
| DNS | Multiple IPs per domain name | Slow propagation and caching → stale IPs in dynamic environments |
| Service registry (etcd, ZooKeeper) | Instances register host/port + metadata, send heartbeats; clients query then connect directly | Handles frequent churn; richer metadata for smarter balancing |
| Service mesh (Istio, Linkerd) | Sidecar/in-process LBs on both ends | Complex, but centralizes TLS and gives deep observability |

## Worked Example
**The lost-field scenario (Figure 5-1).** New code adds a field to a record schema, writes a record containing that field, and stores it in the database. An older instance — still running during the rolling upgrade, and unaware of the new field — reads the record, updates one unrelated attribute, and writes it back. The desirable behavior is for the old code to keep the unknown field intact. But if the old code decodes into a model object that doesn't explicitly retain unknown fields, the new field is dropped on the write-back and the data is **silently lost**.

Protocol Buffers solves this structurally: because every field carries a tag *and* a type annotation, an old parser encountering tag 7 that it doesn't recognize knows exactly how many bytes it spans, so it can skip and re-emit the raw bytes rather than discarding them. Avro solves it by requiring the writer's schema at decode time. Hand-rolled JSON model objects solve it only if you deliberately keep an "unknown fields" bag.

## Key Takeaways
1. Assume old and new code run simultaneously; design every format so both directions of compatibility hold, and verify compatibility in a schema registry *before* deploying.
2. Never reuse or change a Protocol Buffers field tag — reserve retired tags. Never add or remove an Avro field without a default value.
3. Don't use your language's built-in serialization (`java.io.Serializable`, `pickle`, `Marshal`) for anything beyond transient purposes: language lock-in, arbitrary-class instantiation as an RCE vector, no versioning story, and poor efficiency.
4. Be careful with JSON numbers: integers above 2^53 lose precision in IEEE 754 doubles — X returns post IDs twice, as a number *and* a decimal string, to work around it. Base64 for binary inflates size ~33%.
5. Migrations are deferred, not immediate: LSM compaction rewrites into the latest format lazily, and relational `ADD COLUMN ... DEFAULT NULL` doesn't rewrite existing rows — the database *presents* one schema over many historical encodings.
6. Write archival dumps in the latest schema, in one immutable go — Avro object container files, or Parquet if the destination is analytics.
7. In durable execution, treat workflow code as append-only: deploy new versions rather than editing, keep it deterministic, and rely on framework-provided clock/random implementations.
8. Keep the number of concurrent schema formats to a minimum — operational simplicity beats format optimality.

## Anti-patterns
- **Language-built-in serialization for persisted or transmitted data**: commits you to one language, enables deserialization-of-untrusted-data RCE (CWE-502), and ignores versioning and efficiency.
- **Decoding into model objects that discard unknown fields**: breaks forward compatibility and silently destroys data on read-modify-write.
- **Making RPC look exactly like a local call**: hides timeouts, partial failure, retries requiring idempotence, variable latency, and cross-language type mismatches. CORBA, DCOM, EJB/RMI, and SOAP/WS-* all foundered here.
- **Retrying a network request without idempotence/deduplication**: the first request may have succeeded with only the response lost, so the action executes twice.
- **Reordering or editing an in-flight durable-execution workflow's code**: replay expects the same RPC calls in the same order; nondeterminism and reordering yield undefined behavior.
- **Relying on CSV for evolving data**: no schema, vague escaping rules (RFC 4180 exists but parsers disagree), and any added row or column must be handled by hand.
- **ASN.1 for new applications**: it does support tag-number evolution, but it's very complex and badly documented.

## Connects To
- **Ch 2 (Evolvability)**: this chapter is the concrete mechanism behind "making change easy"; rolling upgrades are what compatibility exists to serve.
- **Ch 3 (Data Models)**: schema-on-read document databases get flexibility by deferring the schema; schema evolution gets the same flexibility *plus* guarantees and tooling.
- **Ch 4 (Storage and Retrieval)**: LSM compaction is where deferred schema migration actually happens; Parquet columnar files are the archival encoding of choice.
- **Ch 8 (Transactions)**: "serialization" collides with serializability — and durable execution exists precisely because you can't wrap cross-service steps in a database transaction.
- **Ch 9 (Distributed Systems Trouble)**: timeouts and determinism.
- **Ch 12 (Stream Processing)**: idempotence, message brokers, and event sourcing (which needs a broker configured to retain messages indefinitely).
- **Kleppmann, "Schema Evolution in Avro, Protocol Buffers and Thrift" (2012)**: the long-form version of this chapter's comparison.
