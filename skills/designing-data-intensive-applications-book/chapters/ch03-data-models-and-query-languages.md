# Chapter 3: Data Models and Query Languages

## Core Idea
The data model you choose shapes not only how you write software but how you *think about the
problem*; pick relational, document, graph, event-sourced, or DataFrame based on the shape of your
relationships — one-to-many trees favor documents, many-to-many webs favor graphs, and everything
else usually favors relational.

## Frameworks Introduced

- **Relationship-shape → model selection**: classify your data's dominant relationship type.
  - *One-to-many / one-to-few* (a résumé's positions, education, contact info) → **document model**.
    The tree is explicit in the JSON; the relational alternative, *shredding* the document into
    multiple tables, leads to cumbersome schemas and complicated application code.
  - *Many-to-one* (many people live in one region) and *many-to-many* (people ↔ organizations) →
    **relational**, via an *associative table* / *join table*. These do not fit in one self-contained
    JSON document.
  - *Anything potentially related to everything, with multi-hop traversals* → **graph**.
  - Failure mode of documents: you cannot reference a nested item directly — you must say "the second
    item in the list of positions for user 251". If you need to reference nested items, use relational.
  - Where documents win outright: user-orderable lists (drag-and-drop to-dos, issue trackers) — just
    store the IDs in a JSON array. SQL has no standard way; tricks are an integer sort column
    (requiring renumbering on middle inserts), a linked list of IDs, or fractional indexing.

- **Normalization vs. denormalization**: store human-meaningful information once and reference it by
  an ID (normalized), or duplicate it in every record (denormalized).
  - When to normalize: OLTP systems where reads *and* updates must be fast; small-to-moderate scale
    where join cost is acceptable; anything fast-changing.
  - When to denormalize: analytics (updates are bulk, read performance dominates, data is a
    historical log that doesn't change); very large scale where join cost becomes problematic.
  - Why IDs: an ID has no meaning to humans so it never needs to change; anything meaningful to humans
    may change, and duplicated copies then need more code, more writes, more disk, and risk
    inconsistency. IDs also give consistent spelling, disambiguation ("Washington, DC" the city vs.
    the state), localization, and better search (the region list can encode that Washington is on the
    US East Coast).
  - Rule: **normalized is faster to write (one copy), slower to query (joins); denormalized is faster
    to read (fewer joins), more expensive to write.** Treat denormalization as *derived data* — you
    must build a process that updates the redundant copies, and consider consistency if that process
    crashes halfway (atomic transactions help, but not all databases offer atomicity across documents).

- **Schema-on-read vs. schema-on-write**: "schemaless" is misleading — the code reading the data
  assumes a structure, so there is an *implicit* schema, just not one enforced by the database.
  - Schema-on-read (document DBs, JSON columns) is like dynamic/runtime type checking;
    schema-on-write (relational) is like static/compile-time type checking.
  - Use schema-on-read when the collection is heterogeneous: many object types not practicably given
    their own table, or structure determined by an external system you don't control and that may
    change at any time.
  - Use schema-on-write when all records are expected to have the same structure — a schema is then a
    useful mechanism for documenting and enforcing that structure.

- **Event sourcing + CQRS**: write every state change as an immutable, past-tense event appended to a
  log (the source of truth); derive read-optimized *materialized views* (also called *projections* or
  *read models*) from it. CQRS = command query responsibility segregation.
  - How: a user request is a *command*; validate it first (e.g. enough seats available). Only once
    valid does it become a fact and get appended. **The log contains only valid events, and a
    consumer building a materialized view is not allowed to reject an event.** Name events in the past
    tense — even if a booking is later canceled, the fact that it was held remains true, and the
    cancellation is a separate later event.
  - Why it works: views are derived *reproducibly* — you must always be able to delete a view and
    recompute it by processing the same events in the same order with the same code. Buggy view code?
    Delete, fix, replay. You can maintain many views in different databases and data models, even
    in-memory, and add new views or new event types without touching old events. A mistaken event is
    reversed by a subsequent deletion event, which downstream views absorb automatically — reducing
    irreversible actions. The log doubles as an audit log and absorbs write bursts because of its
    sequential access pattern.
  - Failure modes: (1) **external information breaks determinism** — an exchange rate fetched while
    processing an event gives a different result on replay, so embed the rate in the event or query a
    historical rate by the event's timestamp; (2) **immutability collides with GDPR erasure** — delete
    a whole per-user log if you have one, otherwise keep personal data outside the event or use
    *crypto-shredding* (encrypt with a key you can later delete), both of which make recomputation
    harder; (3) **externally visible side effects on replay** — don't resend confirmation emails when
    rebuilding a view.
  - The only hard requirement on the storage system: **all materialized views must process events in
    exactly the same order as they appear in the log.**

## Key Concepts
- **Declarative query language** (SQL, Cypher, SPARQL, Datalog): you specify the pattern of the data
  you want, not how to get it, so the optimizer can pick indexes, join algorithms, order, and even
  parallelize across cores and machines — and the vendor can improve performance without query changes.
- **Impedance mismatch**: the awkward translation layer between objects in application code and the
  relational model of tables, rows, and columns (term borrowed from electronics).
- **N+1 query problem**: an ORM fetches N comments then issues one query per comment to look up its
  author, instead of one join — N+1 queries total.
- **Locality**: a document is stored as one continuous string (JSON/XML/BSON), so fetching the whole
  thing needs one lookup instead of several index lookups across tables.
- **Star schema**: a central *fact table* whose rows are individual events, with foreign keys into
  *dimension tables* representing the who/what/where/when/how/why. **Snowflake schema**: dimensions
  further broken into subdimensions (more normalized, but star is often preferred as simpler for
  analysts). **One big table (OBT)**: dimensions folded into denormalized fact-table columns —
  more storage, sometimes faster queries.
- **Property graph**: each vertex has a unique ID, a label, a set of outgoing edges, a set of incoming
  edges, and properties (key-value pairs); each edge has a unique ID, a tail vertex, a head vertex, a
  label, and properties.
- **Triple store**: everything is a (subject, predicate, object) statement. Subject = vertex; object =
  either a primitive value (so predicate+object are a property key+value) or another vertex (so the
  predicate is an edge label). Serialized as Turtle/N3 or RDF/XML.
- **Adjacency list vs. adjacency matrix**: list stores each vertex's neighbor IDs (good for
  traversals); matrix is a 2D array of 0/1 (good for machine learning).
- **Hydrating**: looking up human-readable information by ID — a join performed in application code.
- **DataFrame**: relational-like table manipulated by a series of commands rather than a declarative
  language, used to "wrangle" data toward a sparse matrix for ML (`join` is called `merge`).
- **One-hot encoding**: turn a small fixed set of values (movie genres) into one 0/1 column each.

## Mental Models
- **Think of every layer as a representation in terms of the next layer down**: real world → objects
  and APIs → general-purpose data model (JSON, tables, vertices/edges) → bytes on disk → electrical
  currents. Each layer hides the one below so different groups of people can work together.
- **Use "how often does this change, and what does a read cost?" to decide denormalization**, not
  dogma. Normalization and denormalization are neither good nor bad — they are read/write performance
  and effort trade-offs, and the most scalable design usually denormalizes some things and not others.
- **Think of a graph store as two relational tables** (vertices and edges) with indexes on both
  `tail_vertex` and `head_vertex`, so you can traverse forward *and* backward. The edges table is the
  many-to-many join table generalized to hold many relationship types at once.
- **Graphs are good for evolvability**: no schema restricts which vertices can connect, so you can
  extend the model as features are added (add allergen vertices and allergy edges, then query what is
  safe to eat).
- **Prefer combining relational and document in one database.** They have converged: relational DBs
  added JSON types, operators, and indexes on document properties; MongoDB, Couchbase, and RethinkDB
  added joins, secondary indexes, and declarative query languages. Codd's 1970 paper already allowed
  *nonsimple domains* — a nested relation as a value — 30+ years before SQL added JSON/XML.

## Anti-patterns
- **Embedding a genuinely large collection in one document**: thousands of comments on a celebrity's
  post do not belong inline. One-to-many really means one-to-*few*.
- **Frequent small updates to large documents**: the database typically loads the whole document to
  read, and rewrites the whole document on update. Keep documents fairly small.
- **Relying on the ORM's generated schema and default fetching**: it can produce awkward schemas,
  inefficient queries, and the N+1 problem; customizing it can negate the benefit of using the ORM.
- **Storing fast-changing data in a materialized view**: X's timelines store only post ID + sender ID
  precisely because like counts, usernames, and profile pictures change constantly.
- **Assuming read-time joins block scalability**: hydrating post and user IDs parallelizes well and
  its cost does not depend on how many accounts you follow or how many followers you have.
- **Running a big `UPDATE` migration on a large table** to backfill a new column: adding a column with
  a `NULL` default is fast, but rewriting every row is slow, and changing a column's datatype
  typically copies the whole table. Consider filling in at read time instead, as a document DB would.
- **Exposing recursive or arbitrary-search queries to untrusted clients**: this is why GraphQL forbids
  them — otherwise users could trigger a denial of service with expensive queries.

## Code Examples

```cypher
MATCH
  (person) -[:BORN_IN]->  () -[:WITHIN*0..]-> (:Location {name:'United States'}),
  (person) -[:LIVES_IN]-> () -[:WITHIN*0..]-> (:Location {name:'Europe'})
RETURN person.name
```
- **What it demonstrates**: `:WITHIN*0..` means "follow a WITHIN edge zero or more times", like `*` in
  a regular expression. This 4-line Cypher query requires **31 lines of SQL** using `WITH RECURSIVE`
  common table expressions — the clearest demonstration in the book that the right data model and
  query language matter.

```sparql
PREFIX : <urn:example:>
SELECT ?personName WHERE {
  ?person :name ?personName.
  ?person :bornIn  / :within* / :name "United States".
  ?person :livesIn / :within* / :name "Europe".
}
```
- **What it demonstrates**: Cypher's pattern matching is borrowed from SPARQL, which predates it —
  `(person) -[:BORN_IN]-> () -[:WITHIN*0..]-> (location)` ≡ `?person :bornIn / :within* ?location.`
  RDF uses predicates for both properties and edges, so one syntax matches both.

```prolog
within_recursive(LocID, PlaceName) :- location(LocID, PlaceName, _).   /* Rule 1 */
within_recursive(LocID, PlaceName) :- within(LocID, ViaID),            /* Rule 2 */
                                      within_recursive(ViaID, PlaceName).
migrated(PName, BornIn, LivingIn)  :- person(PersonID, PName),         /* Rule 3 */
                                      born_in(PersonID, BornID),
                                      within_recursive(BornID, BornIn),
                                      lives_in(PersonID, LivingID),
                                      within_recursive(LivingID, LivingIn).
us_to_europe(Person) :- migrated(Person, "United States", "Europe").   /* Rule 4 */
```
- **What it demonstrates**: Datalog (a subset of Prolog) builds complex queries rule by rule, like
  functions calling each other; rules can be recursive, which is what enables graph traversal. Derived
  tables behave like virtual SQL views.

```sql
CREATE TABLE vertices (
    vertex_id   integer PRIMARY KEY,
    label       text,
    properties  jsonb
);
CREATE TABLE edges (
    edge_id     integer PRIMARY KEY,
    tail_vertex integer REFERENCES vertices (vertex_id),
    head_vertex integer REFERENCES vertices (vertex_id),
    label       text,
    properties  jsonb
);
CREATE INDEX edges_tails ON edges (tail_vertex);
CREATE INDEX edges_heads ON edges (head_vertex);
```
- **What it demonstrates**: a property graph expressed relationally; the two indexes are what make
  bidirectional traversal efficient.

```javascript
db.observations.aggregate([
    { $match: { family: "Sharks" } },
    { $group: {
        _id: { year:  { $year:  "$observationTimestamp" },
               month: { $month: "$observationTimestamp" } },
        totalAnimals: { $sum: "$numAnimals" }
    } }
]);
```
- **What it demonstrates**: MongoDB's aggregation pipeline matches a subset of SQL in expressiveness
  (`SELECT date_trunc('month', ...), sum(num_animals) ... WHERE family='Sharks' GROUP BY ...`),
  differing mainly in JSON vs. English-sentence syntax. Its `$lookup` operator performs joins.

```graphql
query ChatApp {
  channels {
    name
    recentMessages(latest: 50) {
      timestamp
      content
      sender { fullName imageUrl }
      replyTo { content sender { fullName } }
    }
  }
}
```
- **What it demonstrates**: the response is a JSON document mirroring the query exactly — no more, no
  less — so the client can add `imageUrl` under `replyTo` with **no server-side change**. GraphQL
  deliberately accepts duplication (repeating sender name/image, inlining the replied-to content) to
  keep UI rendering simple; the server can store normalized data and join, but only joins declared in
  the GraphQL schema are requestable.

## Reference Tables

| Model | Best for | Query languages | Weakness |
|---|---|---|---|
| Relational | Regular structure; data warehousing and BI; many-to-one and many-to-many | SQL | Shredding document-like trees; clumsy recursive/graph queries; no standard ordered lists |
| Document | Self-contained JSON trees of one-to-many, loaded whole; heterogeneous data; ordered lists | MongoDB aggregation pipeline, XQuery/XPath, JSON Pointer, JSONPath | Weak joins; can't reference nested items directly; whole-document reads/rewrites |
| Property graph | Many-to-many, multi-hop traversal, heterogeneous entity types in one store | Cypher/openCypher, GQL (ISO 2024), PGQL, GSQL, Gremlin | An edge joins only two vertices (use an extra vertex per join-table row, or a hypergraph, for higher-degree relations) |
| Triple store / RDF | Same expressiveness as property graphs; internet-wide data exchange | SPARQL, Datalog | URI-heavy quirks inherited from the Semantic Web |
| Event log (event sourcing) | Complex business domains; auditability; write throughput | Derived views in any model | Determinism, GDPR erasure, replay side effects |
| DataFrame / array | Data science, ML feature prep, time series, scientific arrays | Command sequences (R, Pandas, Spark, Dask, ArcticDB); array DBs like TileDB | Not for OLTP |

Locality is not exclusive to documents: **Spanner** interleaves a table's rows within a parent table;
**Oracle** has multi-table index cluster tables; the **wide-column** model (Bigtable, HBase, Accumulo)
uses **column families** for the same purpose.

## Worked Example
**Denormalizing X's home timeline — and deliberately not denormalizing the rest.** The naive read is a
join of `posts` and `follows`, too expensive to run per view. The materialized timeline is a cache of
that join, and the fan-out process that inserts each new post into followers' timelines is what keeps
the denormalized copy consistent. But X's timeline entries store **only the post ID, the sender's user
ID, and a little extra data identifying reposts and replies** — i.e. the precomputed result of
`SELECT posts.id, posts.sender_id FROM posts JOIN follows ON posts.sender_id = follows.followee_id
WHERE follows.follower_id = current_user ORDER BY posts.timestamp DESC LIMIT 1000`. Reading a timeline
therefore still performs two joins in application code: fetch each post's content plus its like/reply
counts, and fetch each sender's profile. That is *hydrating*. The reason not to denormalize further:
like and reply counts change many times per second on a popular post, users change usernames and photos,
the timeline must show the latest values, and copying it all would blow up storage. Hydration scales
fine because it parallelizes and its cost is independent of follower/following counts. **Lesson: the
most scalable design denormalizes some things and leaves others normalized, based on how often each
piece of information changes.**

## Key Takeaways
1. Choose the model from the dominant relationship shape: trees → document, webs → graph, regular
   many-to-one/many-to-many → relational. Emulating one model in another works but is awkward.
2. Normalize by default in OLTP; denormalize in analytics, where the data is an unchanging historical
   log and consistency/write overheads are not pressing.
3. "Schemaless" is really schema-on-read. The schema still exists — decide whether you want it
   enforced on write or assumed on read, and accept that schema-on-read means every reader must handle
   every historical format forever.
4. Star schemas have very wide tables — fact tables often exceed a hundred columns, sometimes several
   hundred; dimension tables carry all analysis-relevant metadata. Even dates get a dimension table so
   queries can distinguish holidays.
5. Recursive/variable-length traversal is where graph query languages earn their keep: 4 lines of
   Cypher vs. 31 lines of SQL `WITH RECURSIVE`, before you even consider cycles and BFS/DFS choice.
6. Restrict query power at untrusted boundaries. GraphQL's deliberate limits (no recursion, no
   arbitrary search conditions unless explicitly offered) are a security feature, and its cost is
   tooling to translate to internal REST/gRPC plus authorization, rate limiting, and performance work.
7. With event sourcing, the discipline that pays off is reproducibility: views must be recomputable
   from the log with the same code in the same order, which forces you to keep event processing
   deterministic.

## Connects To
- **Ch 1**: derived data and systems of record (denormalization *is* derived data); data warehousing,
  which star/snowflake/OBT schemas serve.
- **Ch 2**: the social network case study whose materialized timelines this chapter re-analyzes as a
  denormalization decision; evolvability, which event sourcing improves by reducing irreversibility.
- **Ch 4**: storage engines — how these models are represented in bytes; secondary indexes that make
  many-to-many queryable in both directions; append-only logs; DataFrames/matrices/arrays.
- **Ch 5**: schemas and schema evolution in depth; problems with JSON as an encoding format; REST and
  gRPC behind GraphQL.
- **Ch 8**: atomicity, needed to keep denormalized copies consistent.
- **Ch 10, 12**: total order of the event log in a distributed system; Kafka as event storage and
  stream processors maintaining materialized views; state machine replication.
- **External**: Codd's 1970 relational model paper (and its *nonsimple domains*); Stonebraker &
  Hellerstein, "What Goes Around Comes Around"; Kimball & Ross on dimensional modeling; PageRank;
  Facebook's TAO social graph; the Semantic Web's surviving legacy (JSON-LD, Open Graph protocol,
  Wikidata, Schema.org, biomedical ontologies); specialist models this chapter does not cover —
  genome sequence similarity search (GenBank), double-entry ledgers (TigerBeetle, blockchains), and
  full-text search.
