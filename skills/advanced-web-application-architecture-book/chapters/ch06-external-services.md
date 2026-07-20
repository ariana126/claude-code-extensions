# Chapter 6: External services

## Core Idea
Wrapping an external API in a class is not abstraction. Define an interface phrased in **your own domain's terms** (`VatRateProvider::vatRateForSellingEbooksInCountry()`), and let its implementation own both the vendor's vocabulary and the network call.

## Frameworks Introduced

- **The two-layer structure for any external service** — the chapter's central shape.
  1. **Façade / API client** (`VatApi`) — an object-oriented wrapper over the remote API. Method names mirror endpoints (`vatRateCheck()` ↔ `/vat-rate-check`); query parameters become method parameters; the API key is a **constructor** argument because it's a configuration value (Ch 5).
  2. **Abstraction** (`VatRateProvider` interface + `VatRateProviderUsingVatApiDotCom`) — phrased entirely in your domain's language. The implementation consumes the façade.
  - Why both: the façade tames procedural `curl_*` code; the interface makes the vendor replaceable. Neither alone is enough.

- **The abstraction test** — how to tell whether you've reached the right level of abstraction.
  > **"It's a good abstraction if it is still useful when the implementation details change radically."**
  - Explicitly **not** "it's a good abstraction if you can create a test double for it" — the chapter's exercise offers that as a wrong answer. A test double can be made for any interface, including a bad one.
  - How to apply: "Consider if the interface would still be useful if you switch to a different web service, or when you'd start using a database table instead of a remote service."

- **The "imagine the object" technique** (reprised from Ch 2) — how to *find* the right abstraction.
  - How: write the call you wish you could make, then read off the interface.
    ```php
    $vatRate = $this->vatRateProvider->vatRateForSellingEbooksInCountry('NL');
    ```
  - "By imagining the object and the exact behavior we want from it, we've reached the right level of abstraction… It shows what this service needs, in its own terms, nothing more, and nothing less."

- **The return type is the tell.** `VatApi::vatRateCheck()` returns `VatRateCheckResult` — vendor vocabulary. `VatRateProvider::vatRateForSellingEbooksInCountry()` returns `VatRate` — your domain. "It has always been an object of type `VatRate` that we were really looking for, and so far, we were only able to create it after jumping through many hoops."

- **The three-level testing split** — which test goes where.

  | Class | Test type | What it proves |
  |---|---|---|
  | `EbookOrderService` | Unit (test double for `VatRateProvider`) | The use case orchestrates correctly |
  | `VatRateProviderUsingVatApiDotCom` | Integration | (1) correct and complete implementation of the interface, (2) correct integration with the external service |
  | `VatApi` | Integration (if warranted) | Edge cases: bad country codes, bad API key, fallback logic, connection failure |
  | `VatRateCheckResult` | **Unit** | Response-interpretation branches — no network needed |

- **When to write a separate integration test for the façade** — two interrelated criteria:
  1. Whether `VatApi` will be used by other clients too.
  2. Whether it has methods or execution paths "that are troublesome to test only indirectly."
  - "If `VatApi` is more like a library class, used by different clients, it will have other behaviors that should not only be tested through `VatRateProviderUsingVatApiDotCom`."

## Key Concepts
- **Façade** — Gang of Four: "defines a higher-level interface that makes the subsystem easier to use." Often shipped by vendors as an **SDK**.
- **Level of abstraction** — whether an interface speaks your domain's language or the vendor's.
- **Leaky abstraction** — an interface with vendor-specific details baked in (a `$filter` parameter that only `vatapi.com` understands).
- **Primitive obsession** — passing bare strings where clients "would have to guess what a valid value could be."
- **Named constructors as an enum** — `RateType::goods()` / `RateType::tbe()` with a private constructor.
- **Integration test** — a test that uses IO (network, database, file system) to verify real cooperation with an external system.
- **Spiking** — fiddling with code and design until you know what to do. Acceptable temporarily; not acceptable to leave behind.
- **Deterministic** — core code only manipulates data in memory, so its tests "won't fail for weird reasons, like concurrency problems, or a remote service that is down."

## Mental Models
- **Outsourcing a hard domain is a legitimate architectural move.** VAT is "a huge topic, with lots of rules, and lots of exceptions." Options: reduce scope, or use an existing service. Building it yourself is not automatically the answer.
- **Abstractions are an architectural tool for buying time.** "You can build in flexibility for years to come. You can start with a cheap-to-implement solution, whether that be an external service that does the trick for now, or a locally stored JSON file. You can always 'upgrade' when the time is there."
- **Foreign vocabulary in your service is a design smell.** After introducing the façade, `vatRateCheck()`, `rateCheckResult`, and the string `'electronics'` still appear in `EbookOrderService` — "words which are alien to our own business domain."
- **Specificity in an interface can be a feature, not a limitation.** `vatRateForSellingEbooksInCountry()` looks less reusable than `vatRateForCountry($countryCode, $filter)`. But the generic version drags a `vatapi.com`-specific `$filter` along. "The e-book-specificness was a benefit of the interface, since it encoded the filtering aspect in the method name itself."
- **Always look for logic you can pull out of infrastructure code and unit-test.** `VatRateCheckResult`'s branch logic needs no network. "Make sure to always look for opportunities like this."
- **Fine-grained unit tests, coarse-grained integration tests.** Integration tests cover "one or two of the most common execution paths. The details will be verified in a unit test."

## Anti-patterns
- **Pasting the vendor's PHP example into your application service**: fine while spiking, "really bad for the long term maintainability." It buries the high-level step and destroys testability.
- **Extracting an interface from the façade class**: `interface VatApi { vatRateCheck(string, string, ?string): VatRateCheckResult }` — "In fact, *nothing* would change about the `EbookOrderService`." The signature is still the vendor's.
- **Returning raw arrays from an API client**: "The problem with arrays is that their shape is undefined." Nothing guarantees `$responseData['filter_match']` exists; PHP errors follow.
- **Primitive obsession in the façade signature**: clients must guess valid values for `$rateType`, `$countryCode`, `$filter`, `$fallbackType`.
- **Leaky interface parameters**: any parameter that only makes sense for the current vendor will be dead weight after a switch.
- **Depending directly on a concrete API client class**: "Directly depending on a class endangers the future of the service, but also degrades its testability."
- **Testing response-parsing logic through the network**: "You don't need a network connection to verify that this logic works."
- **Leaving the implementation untested after introducing the abstraction**: the mock makes `EbookOrderService` green while `VatApi` is entirely unverified — "a bad situation, because we can no longer be sure that the code is correct."

## Code Examples

The abstraction and its implementation — the chapter's payoff:

```php
interface VatRateProvider
{
    public function vatRateForSellingEbooksInCountry(string $countryCode): VatRate;
}

final class VatRateProviderUsingVatApiDotCom implements VatRateProvider
{
    private VatApi $vatApi;

    public function __construct(VatApi $vatApi)
    {
        $this->vatApi = $vatApi;
    }

    public function vatRateForSellingEbooksInCountry(string $countryCode): VatRate
    {
        $rateCheckResult = $this->vatApi->vatRateCheck(
            RateType::tbe(),
            $countryCode,
            'ebooks'
        );

        return VatRate::fromInt($rateCheckResult->rate('electronics'));
    }
}
```

The call site — one line, entirely in domain terms:

```php
$vatRate = $this->vatRateProvider->vatRateForSellingEbooksInCountry('NL');
```

Switching vendors touches nothing in the core:

```php
final class VatRateProviderUsingTaxToolsIO implements VatRateProvider
{
    private TaxTools $taxTools;

    public function vatRateForSellingEbooksInCountry(string $countryCode): VatRate
    {
        return $this->taxTools->rates($countryCode)->rateFor('ebooks');
    }
}
```

An enum-like value object replacing a bare string:

```php
final class RateType
{
    private const GOODS = 'GOODS';
    private const TBE = 'TBE';

    private string $rateType;

    private function __construct(string $rateType)
    {
        $this->rateType = $rateType;
    }

    public static function goods(): self
    {
        return new self(self::GOODS);
    }

    /** TBE stands for "Telecommunications, broadcasting, and electronic services" */
    public static function tbe(): self
    {
        return new self(self::TBE);
    }
}
```

- **What it demonstrates**: named constructors make valid values discoverable via autocomplete, and the docblock puts the vendor's acronym where a reader will actually find it.

The **leaky** alternative interface — rejected:

```php
interface VatRateProvider
{
    public function vatRateForCountry(
        string $countryCode,
        string $filter        // ← only meaningful to vatapi.com
    ): VatRate;
}
```

Separating the test suites:

```xml
<phpunit>
    <testsuites>
        <testsuite name="Unit tests">
            <directory>./test/unit</directory>
        </testsuite>
        <testsuite name="Integration tests">
            <directory>./test/integration</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

The unit test that needs no network, covering both branches:

```php
final class VatRateCheckResultTest extends TestCase
{
    /** @test */
    public function it_uses_the_filter_rate(): void
    {
        $result = new VatRateCheckResult([
            'filter_match' => true,
            'rate' => 21.0,
            'rates' => ['telecom' => ['rate' => 6.0]]
        ]);

        self::assertEquals(21.0, $result->rate('telecom'));
    }

    /** @test */
    public function it_uses_the_fallback(): void
    {
        $result = new VatRateCheckResult([
            'filter_match' => false,
            'rates' => ['telecom' => ['rate' => 6.0]]
        ]);

        self::assertEquals(6.0, $result->rate('telecom'));
    }
}
```

## Reference Tables

**The four stages, and what each one actually fixed**

| Stage | Code in `EbookOrderService` | Testable in isolation? | Vendor swappable? |
|---|---|---|---|
| 1. Inline `curl_*` | ~50 lines of HTTP + JSON | No | No |
| 2. `VatApi` façade | `$this->vatApi->vatRateCheck('TBE', 'NL', 'ebooks')` | No | No |
| 3. Interface extracted from `VatApi` | *unchanged* | No | No |
| 4. `VatRateProvider` abstraction | `$this->vatRateProvider->vatRateForSellingEbooksInCountry('NL')` | **Yes** | **Yes** |

**Do you need your own integration test for third-party client code?**

| Situation | Write your own test? |
|---|---|
| Vendor SDK, well written and well tested | No |
| Vendor SDK with no tests | Yes — "verify your assumptions about their code" |
| You rely on special cases their tests don't cover | Yes |
| **Any implementation of your own abstraction** | **Always** |

## Worked Example

**The chapter's most important move is the one it makes and then rejects.**

**Stage 1 — copy the vendor's example.** Paste `vatapi.com`'s PHP snippet straight into `EbookOrderService::create()`. Roughly fifty lines: `curl_init`, `curl_setopt_array` with eight options, `curl_exec`, error check, `json_decode`, status check, then a nested conditional choosing between `$responseData['rate']` and `$responseData['rates']['electronic']['rate']`.

"It's a lot of code, and the code itself doesn't look great, but it works. This is fine, as long as you're just *spiking*." Two things are now broken: the service that was supposed to show the use case's high-level steps "is now mostly about connecting to an external service", and `EbookOrderService` can no longer be tested in isolation at all.

**Stage 2 — build a façade.** Move the HTTP work into `VatApi`, with `vatRateCheck()` mirroring the endpoint and the API key as a constructor argument. Then improve it twice: return a `VatRateCheckResult` object instead of a raw array ("objects are easier to use than an array of data because they have a predefined set of methods that can be used without fear"), and replace bare strings with value objects like `RateType`.

Then Noback stops: "before we accidentally develop an entire SDK for `vatapi.com`, we should take a step back."

**Stage 3 — the trap.** The obvious next move is to extract an interface from `VatApi` so the dependency is on an abstraction. He writes it out — `interface VatApi` with `ActualVatApi` implementing it — and then delivers the verdict:

> "In fact, **nothing** would change about the `EbookOrderService` and how it uses the injected `VatApi` instance."

The call site is byte-for-byte identical. You now depend on an interface and have gained nothing, because the interface inherited the vendor's method name, the vendor's parameters, and the vendor's return type. **This is the chapter's real lesson**: "these objects don't have the proper *level of abstraction*, making it impossible to switch implementations, whether that be for testing purposes, or when you actually want to switch to a different remote API."

**Stage 4 — rephrase the need.** Don't extract the interface from the implementation. Ask what you actually want and write that call:

```php
$vatRate = $this->vatRateProvider->vatRateForSellingEbooksInCountry('NL');
```

Every vendor word is gone. The return type is `VatRate` — your domain object — not `VatRateCheckResult`. `EbookOrderService` "only cares about 'what' it needs, not about 'how' the real dependency gets it."

**The sidebar that sharpens it.** Noback considers a more "reusable" interface — `vatRateForCountry($countryCode, $filter)` — and rejects it. The `$filter` parameter is `vatapi.com`'s concept and "will have no use once we move away." His conclusion inverts the usual instinct: the e-book-specific name was *better*, because encoding the filter in the method name lets the implementation handle filtering "without the client having to worry about it."

**Then he closes the testing hole he opened.** Mocking `VatRateProvider` makes `EbookOrderService` unit-testable again — but now `VatRateProviderUsingVatApiDotCom` and `VatApi` are entirely untested. So: an integration test for the implementation (proving both interface conformance and real-API integration), a separate more elaborate integration test for `VatApi`'s edge cases, and a plain **unit** test for `VatRateCheckResult`'s two branches, which need no network at all.

On brittleness, he's candid: integration tests "fail for reasons that are beyond your control." Mitigations: a local look-alike service, automatic retries, or letting them fail without failing the build — but "make sure the code itself gives detailed reports about the failures, so you won't accidentally ignore important issues, like when an external service has introduced a breaking change."

## Key Takeaways
1. Wrapping the vendor's API in a class is step one, not the destination. An interface extracted from that class changes nothing.
2. Find the abstraction by writing the call you wish existed, in your own domain's words — not by generalizing the vendor's API.
3. The abstraction test is "would this interface still be useful if the implementation changed radically?" — **not** "can I mock it?"
4. Check the return type. If the method returns a vendor-shaped object, the abstraction is at the wrong level.
5. A parameter that only makes sense for the current vendor makes the interface leaky. Encode that concern in the method name and let the implementation handle it.
6. Never return raw arrays from an API client. Undefined shape means clients guess, and PHP errors follow.
7. Every implementation of *your own* abstraction always needs an integration test proving both interface conformance and real integration. Third-party clients need one only if they're untested or you depend on uncovered cases.
8. Extract the pure-logic parts of infrastructure code (response interpretation, parsing, mapping) and unit-test them. Keep integration tests to one or two happy paths.
9. Abstractions buy architectural optionality: start with a cheap external service or a JSON file, upgrade later, without touching core code.
10. Spiking directly against the vendor's example is a legitimate way to start — as long as you don't ship it.

## Connects To
- **Ch 1**: the two-step abstraction recipe (introduce an interface, then communicate purpose) is exactly what stage 3 → stage 4 demonstrates.
- **Ch 2**: the "act as if it already exists" technique, reused to discover `VatRateProvider`; also value objects for hiding primitive types.
- **Ch 4**: `EbookOrderService` — this chapter restores the isolation that the inline `curl` code destroyed.
- **Ch 5**: the API key as a constructor argument (configuration value), the country code as a method argument; also the "two islands" strategy realized here.
- **Ch 7**: the same treatment for the clock and randomness.
- **Ch 13/14**: ports and adapters, and the full testing strategy — `VatRateProvider` is an outgoing port, `VatRateProviderUsingVatApiDotCom` its adapter, and this integration test is an adapter test.
- **Gang of Four, Façade pattern**: `VatApi`.
- **Gerard Meszaros, "xUnit Test Patterns"**: suggestions for improving unreliable tests.
