# Chapter 13: Microkernel Architecture Style

## Core Idea
Also called the **plug-in architecture**: a stable **core system** holding the happy path, with all volatility and cyclomatic complexity pushed out into independent **plug-in components** — the structural answer to customization, which turns out to come up a lot in software.

## Topology

- **Two components only**: a **core system** and **plug-ins**. Application logic is divided between them; the core isolates application features and the plug-ins provide extensibility, adaptability, and custom processing logic.
- **Partitioning**: **the only architecture style that can be both domain partitioned *and* technically partitioned.** Most microkernels are technically partitioned; the domain-partitioning aspect comes from a strong domain-to-architecture isomorphism (problems requiring different configurations per location or client).
- **Architecture quantum**: always **1** — every request must go through the core system to reach a plug-in, even when plug-ins are remote services.
- **Natural fit**: product-based applications (packaged, downloaded, installed as a single monolithic deployment on the customer's site as a third-party product) *and* custom business applications in domains requiring customization — a US insurer with unique rules per state, an international shipper facing legal and logistical variations.

## Frameworks Introduced

- **Core System — two definitions**:
  1. **The minimal functionality required to run the system.** Eclipse's core is just a basic text editor: open a file, change some text, save. It isn't a usable product until you add plug-ins.
  2. **The happy path** — a general processing flow involving little or no custom processing. *A microkernel architecture takes the cyclomatic complexity of the application, removes it from the core system, and places it into separate plug-in components*, buying extensibility, maintainability, and testability.
  - **Core system implementations**: layered architecture, modular monolith, or even separately deployed **domain services**, each containing the plug-ins specific to its domain.
  - **Presentation layer variants**: embedded within the core, or a separate UI with the core providing backend services. *The separate UI can itself be a microkernel architecture.*

- **Plug-in Components** — standalone, independent components containing specialized processing, additional features, and custom code that enhance or extend the core. They **isolate highly volatile code**, improving maintainability and testability. **Ideally plug-ins have no dependencies between them.**
  - **Compile-based vs. runtime-based**:
    - **Runtime** plug-ins can be added or removed at runtime without redeploying the core or other plug-ins. Managed by frameworks like **OSGi (Java)**, **Penrose (Java)**, **Jigsaw (Java)**, or **Prism (.NET)**.
    - **Compile-based** plug-ins are much simpler to manage, but modifying, removing, or adding one requires redeploying the entire monolithic application.
  - **Point-to-point implementations**: shared libraries (JAR, DLL, Gem), Java package names, or C# namespaces.
  - **Recommended namespace semantics**: `app.plug-in.<domain>.<context>` — e.g. `app.plug-in.assessment.iphone6s`. The second node (`plug-in`) makes clear this is a plug-in and must obey the rules (self-contained, separate from other plug-ins). The third node (`assessment`) is the domain, grouping plug-ins by common purpose. The fourth (`iphone6s`) is the specific context, making the plug-in easy to locate for modification or testing.

- **Remote plug-in access** (REST or messaging, each plug-in a standalone service or containerized microservice):
  | Benefits | Trade-offs |
  |---|---|
  | Better component decoupling | Turns a monolithic architecture into a **distributed** one — difficult to implement and deploy for third-party on-prem products |
  | Better scalability and throughput | More overall complexity and cost; complicates the deployment topology |
  | Runtime changes **without** special frameworks (OSGi, Jigsaw, Prism) | If a plug-in becomes unresponsive or stops running — particularly over REST — **the request cannot be completed**. Not the case with a monolithic deployment |
  | Asynchronous communication to plug-ins, which can significantly improve user responsiveness | Still a **single architecture quantum**, so it doesn't buy independent scaling of the whole |
  - *Asynchronous example*: rather than waiting for a device assessment, the core makes an asynchronous request to kick it off; when it completes, the plug-in notifies the core over another asynchronous channel, which notifies the user.

- **The Spectrum of "Microkern-ality"** — *not all systems that support plug-ins are microkernels, but all microkernels support plug-ins.* The degree depends on how much standalone functionality exists in the core.
  - **"Pure" microkernel end**: Eclipse IDE, linter tools. A linter parses source code and delivers the abstract syntax tree so developers can write rules about language use — until someone writes a plug-in, the core is of little use.
  - **Plug-in-supporting end**: a **web browser** — supports plug-ins but is perfectly functional without them.
  - **The deciding question**: *determining the volatility of the core* goes a long way toward choosing between a system that merely supports plug-ins and a more "pure" microkernel.

- **The Registry** — the core must know which plug-in modules are available and how to reach them. A registry entry contains the plug-in's name, data contract, and remote access protocol details. (Tax software flagging high-risk audit items might register the service name `AuditChecker`, the data contract as input/output data, and the contract format as XML.)
  - Implementation ranges from a simple internal map owned by the core, to a registry-and-discovery tool embedded in the core or deployed externally (**Apache ZooKeeper**, **Consul**).

- **Contracts** — usually standard across a *domain* of plug-ins, covering behavior, input data, and output data. **Custom contracts** appear when plug-ins are built by a third party and the architect doesn't control the contract; in that case **create an adapter** between the plug-in contract and your standard contract so the core needs no specialized code per plug-in. Implementable in XML, JSON, or objects.

## Code Examples

**Before — cyclomatic complexity in the core** (Going Green device assessment):
```java
public void assessDevice(String deviceID) {
   if (deviceID.equals("iPhone6s")) {
      assessiPhone6s();
   } else if (deviceID.equals("iPad1")) {
      assessiPad1();
   } else if (deviceID.equals("Galaxy5")) {
      assessGalaxy5();
   } else ...
      ...
   }
}
```

**After — the core only locates and invokes**:
```java
public void assessDevice(String deviceID) {
	String plugin = pluginRegistry.get(deviceID);
	Class<?> theClass = Class.forName(plugin);
	Constructor<?> constructor = theClass.getConstructor();
	DevicePlugin devicePlugin = (DevicePlugin)constructor.newInstance();
	devicePlugin.assess();
}
```
- **What it demonstrates**: all the complex rules for assessing a device are self-contained in a standalone plug-in, generically executed from the core. **Adding a new device is a matter of adding a plug-in and updating the registry** — the core never changes.

**A simple in-core registry** showing three access styles for one device:
```java
Map<String, String> registry = new HashMap<String, String>();
static {
  //point-to-point access example
  registry.put("iPhone6s", "Iphone6sPlugin");

  //messaging example
  registry.put("iPhone6s", "iphone6s.queue");

  //restful example
  registry.put("iPhone6s", "https://atlas:443/assess/iphone6s");
}
```

**A plug-in contract**:
```java
public interface AssessmentPlugin {
	public AssessmentOutput assess();
	public String register();
	public String deregister();
}

public class AssessmentOutput {
	public String assessmentReport;
	public Boolean resell;
	public Double value;
	public Double resellPrice;
}
```
- The plug-in returns a formatted report string, a **resell flag** (can this be resold on a third-party market, or safely disposed of), and if resellable, its calculated value and recommended resell price.
- **Note the roles-and-responsibilities model**, especially for `assessmentReport`: **it is not the core's responsibility to format or understand the report** — only to print or display it.

## Reference Tables

**Characteristics ratings**

| Characteristic | Rating | Reasoning |
|---|---|---|
| **Simplicity** | ★★★★★ | Main strength, like layered |
| **Cost** | ★★★★★ | Main strength |
| **Testability** | ★★★ | Functionality isolated to independent plug-ins reduces the testing scope of a change |
| **Deployability** | ★★★ | Reduced deployment risk, particularly with runtime-based plug-ins |
| **Reliability** | ★★★ | Same isolation benefit |
| **Modularity** | ★★★ | Functionality added, removed, and changed through self-contained plug-ins |
| **Evolvability** | ★★★ | Relatively easy to extend and enhance; teams respond to change much faster |
| **Responsiveness** | ★★★ | Microkernel apps are generally small and don't grow as big as layered ones; they don't suffer as much from the Architecture Sinkhole; **and can be streamlined by unplugging unneeded functionality** |
| **Scalability** | ★ | Monolithic deployment; quantum is always 1 |
| **Fault tolerance** | ★ | Monolithic deployment |
| **Elasticity** | ★ | Monolithic deployment |

*Responsiveness example*: **WildFly** (formerly the JBoss Application Server) — unplugging unnecessary functionality like clustering, caching, and messaging makes the application server perform much faster.

## Worked Example

**Tax-preparation software** — the canonical case of microkernel applied to a large business application, not a developer tool.

The US IRS has a basic two-page **1040 form** containing a summary of all information needed to calculate a person's tax liability. **Each line on the 1040 is a single number** (gross income, for instance), and arriving at each of those numbers requires many other forms and worksheets.

- **Core system** = the 1040 summary form — the driver, and something that does not change often.
- **Plug-ins** = each additional form and worksheet.
- **Payoff**: US tax law changes constantly. A new required tax form becomes a new plug-in added to the application with little effort. A form or worksheet no longer needed is simply removed. **Changes to tax law are isolated to an independent plug-in component, making change easier and less risky.**

**Insurance claims processing** — the same shape against a harder domain. Each jurisdiction has different rules for what an insurance claim may contain: some US states require insurers to provide free windshield replacement for rock damage, others don't. This creates an almost infinite set of conditions on a standard claims process.

- Most claims applications use large, complex **rules engines** — a framework or library letting developers or end users declaratively define rules or steps as a workflow, via visual tools or a DSL.
- **The failure mode**: these rules engines grow into a **Big Ball of Mud**, where a simple rule change requires an army of analysts, developers, and testers to make sure nothing breaks.
- **The microkernel fix**: the claims rules for each jurisdiction go in a separate standalone plug-in — implemented as source code, or as a specific rules-engine instance accessed by the plug-in. Rules can be added, removed, or changed for one jurisdiction without affecting anything else, and entire jurisdictions can be added or removed the same way. The core system is the standard process for filing and processing a claim.

**The general lesson**: an architecture structure (core + plug-ins) matches a common domain problem (customization). *Once you've seen this style, you start noticing it everywhere.*

## Common Risks

- **Volatile core** — the core is supposed to be as stable as possible after initial development; isolating change to plug-ins is the whole benefit. Building a core that undergoes constant change undermines the philosophy, and **it's a common mistake**, usually the result of architects misjudging the core's volatility. The remedy is refactoring that volatility out.
- **Plug-in dependencies** — microkernels work best when plug-ins communicate **only with the core**, never with each other. Most plug-in systems that aren't microkernels use **dependency-free plug-ins** (no dependencies other than the core). Complex microkernels like the Eclipse IDE do build dependencies between components, forcing the core to resolve **transitive dependency conflicts**. *What happens if two plug-ins depend on different versions of the same core library?* The core must resolve them and facilitate communication between the versions. **Avoid dependencies between plug-ins whenever possible.**

## Governance
Governance here means checking how well architects are honoring the style's philosophy. Common checks:
- **Volatility checks for the core** — fitness functions wired into **version-control churn**, not a code check.
- **Rate of change in the core.**
- **Contract tests**, especially when plug-ins support different versions due to gradual evolution.
- Other structural verifications for the topology.

## Data Topologies
Generally monolithic with a single (typically relational) database. **It is uncommon for plug-ins to connect directly to a centrally shared database** — the core takes that responsibility and passes the needed data to each plug-in. **The reason is decoupling**: a database change should affect only the core, not the plug-ins.

That said, a plug-in **can** own a separate data store accessible only to itself — e.g. each device assessment plug-in with its own small database or rules engine holding that product's assessment rules. The store can be external, or embedded in the plug-in or the monolithic deployment (in-memory or embedded database).

## Cloud Considerations
Three coarse-grained options:
1. Deploy the entire application on the cloud, using cloud facilities or containers.
2. Put just the **data** in the cloud, running the microkernel on-premises.
3. Keep the **core on-premises** and put the **plug-ins in the cloud**. *This looks good from a modularity standpoint but has challenging responsiveness implications*: plug-in calls happen frequently and each passes a fair amount of information, because key workflows are implemented as plug-ins. **The latency of separating core and plug-ins may lead to undesirable overhead.**

## Team Topology Considerations
The obvious split mirrors the topology: **core vs. plug-ins**.
- **Stream-aligned**: the core is the sweet spot — these teams build the core functionality. Plug-ins may also fall to them depending on the application type.
- **Enabling**: **extremely well suited** — segregating behavior in plug-ins enables A/B testing and other experiments.
- **Complicated-subsystem**: also well suited, because specialized behavior is deferred to plug-ins. Specialized processing like analytics can be isolated in a plug-in, letting the stream-aligned team work on core behavior and call out for specialized behavior.
- **Platform**: mostly concerned with operational details, as with other monolithic architectures.

## Examples and Use Cases
- **Development and release tools**: Eclipse IDE, PMD, Jira, Jenkins.
- **Web browsers**: Chrome, Firefox — viewers and plug-ins add capabilities absent from the basic browser (the core).
- **Large business applications**: tax-preparation software, insurance claims processing (both above).

## Key Takeaways
1. Locate the cyclomatic complexity and move it out of the core into plug-ins — that single move *is* the style.
2. Judge the core's **volatility** honestly; a volatile core defeats the architecture and is the most common misapplication.
3. Keep plug-ins dependency-free; transitive dependency conflicts are the headache that scales worst.
4. Choose runtime plug-ins when you need hot changes and can afford OSGi/Jigsaw/Prism; compile-based when simplicity matters more than redeployment cost.
5. Route database access through the core, not the plug-ins — that's what keeps a schema change from touching every plug-in.
6. Adapt third-party plug-in contracts rather than special-casing them in the core.
7. Govern with version-control churn metrics on the core, plus contract tests.
8. Remember the quantum stays 1 even with remote plug-ins — remote access buys decoupling and throughput, not independent scalability of the whole.

## Connects To
- **Ch 5**: microkernel as the structural answer to the Silicon Sandwiches customizability requirement.
- **Ch 7**: Going Green — the recycling application used as the running example.
- **Ch 9**: Big Ball of Mud, which rules engines degenerate into without this structure.
- **Ch 10**: layered architecture as a core system implementation; the Architecture Sinkhole comparison.
- **Ch 11**: modular monolith as a core system implementation.
- **Ch 12**: pipeline — the other modular monolithic style.
- **Ch 20**: architectural patterns.
