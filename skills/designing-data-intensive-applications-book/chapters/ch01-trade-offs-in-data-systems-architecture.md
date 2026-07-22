# Chapter 1: Trade-Offs in Data Systems Architecture

## Core Idea
There are no universally best data systems, only trade-offs; the job is to learn the right questions
(operational vs. analytical, cloud vs. self-hosted, distributed vs. single-node, business needs vs.
user rights) so you can evaluate and combine systems for *your* particular application.

## Frameworks Introduced

- **Operational (OLTP) vs. Analytical (OLAP) split**: Operational systems are the backend services
  and data infrastructure where data is *created*; analytical systems hold a read-only copy optimized
  for analysis.
  - When to use: whenever analysts/data scientists want to query data that production services own.
  - How: keep them separate because (1) data of interest is spread across multiple operational
    systems — *data silos*; (2) OLTP schemas/layouts are poorly suited to analytics; (3) analytical
    queries are expensive and would degrade OLTP performance for users; (4) OLTP systems may sit in a
    network users are not allowed to access for security/compliance reasons.
  - Why it works: the access patterns genuinely differ — point queries vs. aggregations over huge
    scans — and the greater the scale, the more specialized systems must become ("one size fits all"
    is an idea whose time has come and gone).
  - Failure mode: HTAP promises to erase the split, but most HTAP systems are internally an OLTP
    system coupled to a separate analytical system behind one interface. HTAP does *not* replace the
    data warehouse: each operational service should own its own database (hundreds of them), while
    the enterprise wants *one* warehouse so analysts can join across systems.

- **ETL / ELT into a data warehouse**: Extract from OLTP databases (periodic dump or continuous
  stream of updates) → Transform into an analysis-friendly schema and clean → Load into the warehouse.
  - When to use: analysts need to combine data across many operational systems.
  - How: swap the order to *ELT* when you want to load raw and transform inside the warehouse. For
    external SaaS sources you only reach via a vendor API, use connector services (Fivetran, Singer,
    Airbyte). Generalize ETL jobs into *data pipelines*; feed results back with *reverse ETL* when an
    analytical output (e.g. a trained recommendation model) must be served operationally.

- **Systems of record vs. derived data systems**: A *system of record* (source of truth) holds the
  authoritative, canonical, normally normalized version — each fact represented exactly once; on any
  discrepancy the system of record is by definition correct. *Derived data* is the result of
  transforming data from another system and can be re-created if lost.
  - When to use: any time you are untangling a confusing architecture.
  - How: label every dataset. Caches, indexes, materialized views, denormalized values, transformed
    representations, and trained ML models are all derived. Analytical systems are almost always
    derived. Then define, for each derived dataset, the process that updates it when the system of
    record changes.
  - Why it works: derived data is technically redundant but essential for read performance; naming
    the direction of derivation makes the dataflow — and the repair procedure — explicit.

- **Build vs. buy / cloud vs. self-host spectrum**: bespoke in-house software → off-the-shelf
  software you self-host (on premises or on IaaS VMs) → fully managed cloud service / SaaS.
  - When to use: at every "should we run this ourselves?" decision.
  - How: apply the rule of thumb that core competencies and competitive advantages stay in-house,
    while non-core, routine, commonplace work goes to a vendor. Self-host when you already have the
    operational skills *and* load is predictable — then buying your own machines is often cheaper.
    Buy the cloud service when you don't know how to operate the system, or when load is highly
    variable (analytics especially: a big query needs massive parallel resources, then they sit idle).

- **Cloud native architecture**: build higher-level services on lower-level cloud services rather
  than only on OS-managed CPU/RAM/filesystem/IP.
  - How: treat instance-local disks as an ephemeral cache, not durable storage. Avoid virtual block
    devices (EBS-style, 4 KiB blocks) where possible — every I/O is a network call, so the app becomes
    very sensitive to network glitches. Instead disaggregate storage and compute: put large blocks
    containing many values in an object store (S3/Blob/R2), manage the small individual values in a
    separate service. Expect multitenancy.

## Key Concepts
- **Data-intensive application**: an application where data management — volume, change, consistency
  under failure/concurrency, availability — is the primary challenge, as opposed to compute-intensive.
- **Point query**: fetching a small number of records by key; the characteristic OLTP read.
- **Data warehouse**: a separate database holding a read-only copy of data from all the company's
  OLTP systems, which analysts can query without affecting operations.
- **Data lake**: a centralized repository holding a copy of any potentially useful data as *files*,
  imposing no file format, data model, or schema — cheaper (object storage) and friendlier to data
  scientists doing feature engineering, NLP, or computer vision.
- **Sushi principle**: "raw data is better" — keep data in the lake in the raw form the operational
  systems produced so each consumer can transform it to suit their own needs.
- **HTAP (hybrid transactional/analytical processing)**: a single system serving both low-latency
  record reads/updates and large scans, useful for workloads like fraud detection.
- **Reverse ETL**: pushing outputs of analytical systems back into operational systems (TFX,
  Kubeflow, MLflow).
- **Disaggregation / separation of storage and compute**: storage and computation live in different
  services rather than on the same machine.
- **Multitenant**: several customers' data and computation share the same hardware and service.
- **Serverless / FaaS**: the provider allocates and frees hardware per request; metered billing for
  code execution instead of provisioned instances. Comes with execution time limits, restricted
  runtimes, and cold-start latency.
- **Observability**: collecting execution data and making it queryable at both metric and individual
  event level; tracing via OpenTelemetry, Zipkin, Jaeger.
- **Data minimization (Datensparsamkeit)**: deliberately not collecting or storing data whose risk
  outweighs its value; the opposite of speculative "big data" hoarding.

## Mental Models
- **Think of the operational/analytical divide as a people divide, not just a technical one.**
  Backend engineers, business analysts, data scientists, data engineers (who integrate the two
  sides), and analytics engineers (who model and transform data for analysts) have different,
  often unarticulated goals over the *same* dataset.
- **Use "is this data a system of record or derived?" as your first architecture question.** Most
  databases are neither inherently; the distinction is about how *you* use the tool.
- **Treat microservices as a technical solution to a people problem**: they let teams progress
  without coordinating. In a small company with few teams they are unnecessary overhead — build the
  simplest thing.
- **Capacity planning becomes financial planning; performance optimization becomes cost
  optimization.** Metered billing removes disk-space planning but you still must know what you're
  spending on, and cloud quotas still need planning for.
- **Higher-level abstractions are more use-case-specific.** If your needs match what a high-level
  service was designed for, use it. Build from lower-level components only when nothing fits.

## Anti-patterns
- **Letting analysts run ad-hoc SQL against OLTP databases**: risks exposing data they lack
  permission for, and one expensive query degrades performance for real users.
- **Sharing a database between microservices**: the schema becomes part of the service's API and thus
  undeployable-to-change, and one service's queries hurt another's performance.
- **Rushing to a distributed system**: network calls are vastly slower than in-process calls, every
  call must handle timeouts where you cannot know if the request was received, retries may be unsafe,
  and troubleshooting is hard. A single-threaded program on one computer can beat a cluster of 100+
  CPU cores. Modern hardware plus DuckDB/SQLite/KùzuDB handles many workloads on one node.
- **Distributed transactions across microservices**: rarely usable — they run counter to service
  independence and many databases don't support them.
- **Assuming the cloud is always cheaper**: with predictable load and existing operational skill,
  owning machines is often cheaper.
- **Ignoring vendor lock-in**: with no standard APIs you cannot implement a missing feature, cannot
  debug internals, cannot stay on an old version, and can be cut off by sanctions.
- **Storing data speculatively "in case it's useful"**: the cost is not just the S3 bill — add breach
  liability, reputational damage, fines, and real user safety risk when governments compel disclosure
  of criminalized behavior (e.g. location data revealing a clinic visit).

## Reference Tables

Table 1-1. Comparing characteristics of operational and analytical systems

| Property | Operational systems (OLTP) | Analytical systems (OLAP) |
|---|---|---|
| Main read pattern | Point queries (fetch individual records by key) | Aggregate over large number of records |
| Main write pattern | Create, update, and delete individual records | Bulk import (ETL) or event stream |
| Human user example | End user of web/mobile application | Internal analyst, for decision support |
| Machine use example | Checking if an action is authorized | Detecting fraud/abuse patterns |
| Type of queries | Fixed, predefined by application | Arbitrary, ad-hoc exploration by analysts |
| Query volume | Lots of small queries | Few queries, each is complex |
| Data represents | Latest state of data (current point in time) | History of events that happened over time |
| Dataset size | Gigabytes to terabytes | Terabytes to petabytes |

Table 1-2. Examples of self-hosted and cloud native database systems

| Category | Self-hosted systems | Cloud native systems |
|---|---|---|
| Operational/OLTP | MySQL, PostgreSQL, MongoDB | AWS Aurora, Azure SQL DB Hyperscale, Google Cloud Spanner |
| Analytical/OLAP | Teradata, ClickHouse, Spark | Snowflake, Google BigQuery, Azure Synapse Analytics |

Cloud computing vs. supercomputing (HPC)

| Dimension | Cloud computing | Supercomputing (HPC) |
|---|---|---|
| Workload | Online services, business data systems, high availability | Weather forecasting, climate modeling, molecular dynamics, PDEs |
| Failure handling | Cannot stop the cluster; must keep serving users | Stop cluster, repair node, restart from last checkpoint |
| Communication | IP/Ethernet, Clos topologies for high bisection bandwidth | Shared memory and RDMA; meshes and toruses |
| Trust model | Mutually untrusting tenants → VMs, encryption, authentication | High trust among users |
| Geography | Nodes across multiple regions | All nodes close together |

## Worked Example
**Why a supermarket chain separates OLTP from the warehouse.** A large enterprise runs dozens or
hundreds of OLTP systems: the customer-facing website, point-of-sale checkout terminals, warehouse
inventory, vehicle route planning, supplier management, HR. Each is complex, each has its own team,
each operates mostly independently. Now a business analyst wants to answer: "What was the total
revenue of each of our stores in January?", "How many more bananas than usual did we sell during our
latest promotion?", "Which brand of baby food is most often purchased together with brand X
diapers?" Those answers require joining POS, inventory, and promotion data — spread across silos,
stored in schemas tuned for point queries, and scanning enough rows to hurt checkout latency if run
in place. So the data is extracted (dump or update stream), transformed into an analysis-friendly
schema, cleaned, and loaded into one warehouse, where the analyst may write arbitrary SQL by hand or
via Tableau/Looker/Power BI. If a data scientist then needs to do feature engineering or NLP on
review text, SQL is a poor fit, so the same raw extracts also land as Avro/Parquet files in a data
lake for Pandas, scikit-learn, R, or Spark.

## Key Takeaways
1. Recognize which side of the operational/analytical divide you are on, and don't paper over it —
   the access patterns and the audiences are genuinely different.
2. Label every dataset as system of record or derived, and define the update process for each derived
   dataset. Clarity about derivation direction is the cheapest architectural win available.
3. Choose cloud vs. self-hosting on *your* skills and load variability, not on ideology; cloud wins
   hardest for spiky workloads like interactive analytics, self-hosting for predictable load with
   in-house expertise.
4. Cloud native does not just mean "hosted": it means ephemeral local disks, disaggregated
   storage/compute over object storage, and multitenancy — which yields better performance on the
   same hardware, faster failure recovery, and elastic scaling.
5. Stay on a single node as long as you can. Go distributed for a concrete reason: inherent
   distribution, cross-service requests, fault tolerance, scalability, latency to global users,
   elasticity, specialized hardware, legal data residency, or sustainability.
6. Operations does not disappear in the cloud; it shifts to service selection, integration, migration,
   cost control, quota planning, security, and observability.
7. Include legal and ethical cost in the store/don't-store calculation. GDPR's right to erasure
   collides with append-only immutable logs and with data already baked into derived datasets like ML
   training sets — that is a design constraint, not an afterthought.

## Connects To
- **Ch 2**: turns these architectural choices into nonfunctional requirements — reliability,
  scalability, maintainability — that let you judge them.
- **Ch 3**: the relational model and SQL that data warehouses use, plus normalization, which defines
  what a system of record's canonical representation looks like.
- **Ch 4**: why operational and analytical systems use very different internal storage layouts, and
  how cloud databases split values between an object store and a separate service.
- **Ch 5**: encoding (Avro, Parquet) and API evolution (OpenAPI, gRPC), the hard part of microservices.
- **Ch 8, 9**: transactions, distributed transactions, and the failure modes that make distribution
  costly.
- **Ch 11, 12**: data pipelines as data integration; event streams as the modern alternative to
  batch ETL.
- **Ch 14**: ethics, bias, discrimination, and legal compliance in depth.
- **External**: Stonebraker & Çetintemel, "'One Size Fits All': An Idea Whose Time Has Come and
  Gone"; McSherry et al., "Scalability! But at What COST?"; Google's SRE book; the DataOps Manifesto;
  Amazon Aurora and Snowflake papers on disaggregated storage.
