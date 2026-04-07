# Evaluation Guide

How to systematically test and improve an Agent Skill's quality using
eval-driven iteration.

## Why evaluate

The first draft of a skill usually needs refinement. Running structured
evaluations (evals) answers whether the skill works reliably, handles edge
cases, and performs better than no skill at all. Even a single pass of
execute-then-revise noticeably improves quality, and complex domains often
benefit from several iterations.

## Designing test cases

A test case has three parts: a prompt, an expected output description, and
optional input files. Store them in `evals/evals.json`:

```json
{
  "skill_name": "csv-analyzer",
  "evals": [
    {
      "id": 1,
      "prompt": "I have a CSV of monthly sales data in data/sales_2025.csv. Can you find the top 3 months by revenue and make a bar chart?",
      "expected_output": "A bar chart image showing the top 3 months by revenue, with labeled axes and values.",
      "files": ["evals/files/sales_2025.csv"]
    },
    {
      "id": 2,
      "prompt": "there's a csv in my downloads called customers.csv, some rows have missing emails — can you clean it up and tell me how many were missing?",
      "expected_output": "A cleaned CSV with missing emails handled, plus a count of how many were missing.",
      "files": ["evals/files/customers.csv"]
    }
  ]
}
```

### Tips for good test prompts

- **Start with 2–3 test cases.** Don't over-invest before you've seen your
  first results. Expand later.
- **Vary the prompts.** Different phrasings, levels of detail, and formality.
  Some casual ("hey can you clean up this csv"), others precise.
- **Cover edge cases.** At least one prompt that tests a boundary condition —
  a malformed input, an unusual request, or an ambiguous instruction.
- **Use realistic context.** Real users mention file paths, column names,
  and personal context. "Process this data" is too vague to test anything.

Don't define assertions yet — just prompts and expected outputs. You'll add
assertions after you see what the first run produces.

## Running evals

The core pattern: run each test case twice — once **with the skill** and once
**without it** (baseline). This gives you a comparison point.

### Workspace structure

```
csv-analyzer/
├── SKILL.md
└── evals/
    └── evals.json
csv-analyzer-workspace/
└── iteration-1/
    ├── eval-top-months-chart/
    │   ├── with_skill/
    │   │   ├── outputs/       # Files produced by the run
    │   │   ├── timing.json    # Tokens and duration
    │   │   └── grading.json   # Assertion results
    │   └── without_skill/
    │       ├── outputs/
    │       ├── timing.json
    │       └── grading.json
    ├── eval-clean-missing-emails/
    │   └── ...
    └── benchmark.json         # Aggregated statistics
```

The main file you author by hand is `evals/evals.json`. The other JSON files
are produced during the eval process.

### Isolation

Each eval run should start with a clean context — no leftover state from
previous runs or from skill development. In environments with subagents,
each child task starts fresh. Without subagents, use a separate session.

### Capturing timing data

Record token count and duration for each run:

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332
}
```

This lets you compare the cost/quality tradeoff — a skill that dramatically
improves quality but triples token usage is a different tradeoff than one that
is both better and cheaper.

### Comparing skill versions

When improving an existing skill, use the previous version as your baseline.
Snapshot it before editing, point baseline runs at the snapshot, and save to
`old_skill/outputs/` instead of `without_skill/outputs/`.

## Writing assertions

Add assertions after you see your first round of outputs — you often don't
know what "good" looks like until the skill has run.

Good assertions:
- `"The output file is valid JSON"` — programmatically verifiable
- `"The bar chart has labeled axes"` — specific and observable
- `"The report includes at least 3 recommendations"` — countable

Weak assertions:
- `"The output is good"` — too vague to grade
- `"The output uses exactly the phrase 'Total Revenue: $X'"` — too brittle

Not everything needs an assertion. Some qualities (writing style, visual
design, "feels right") are better caught during human review. Reserve
assertions for things that can be checked objectively.

Add assertions to each test case in `evals/evals.json`:

```json
{
  "id": 1,
  "prompt": "...",
  "expected_output": "...",
  "assertions": [
    "The output includes a bar chart image file",
    "The chart shows exactly 3 months",
    "Both axes are labeled",
    "The chart title or caption mentions revenue"
  ]
}
```

## Grading outputs

Grade each assertion as PASS or FAIL with specific evidence. The evidence
should quote or reference the output, not just state an opinion.

```json
{
  "assertion_results": [
    {
      "text": "The output includes a bar chart image file",
      "passed": true,
      "evidence": "Found chart.png (45KB) in outputs directory"
    },
    {
      "text": "Both axes are labeled",
      "passed": false,
      "evidence": "Y-axis is labeled 'Revenue ($)' but X-axis has no label"
    }
  ],
  "summary": {
    "passed": 3,
    "failed": 1,
    "total": 4,
    "pass_rate": 0.75
  }
}
```

### Grading principles

- **Require concrete evidence for a PASS.** Don't give the benefit of the
  doubt. If an assertion says "includes a summary" and the output has a
  section titled "Summary" with one vague sentence, that's a FAIL.
- **Review the assertions themselves.** While grading, notice when assertions
  are too easy (always pass), too hard (always fail even when output is good),
  or unverifiable (can't be checked from the output). Fix them for next round.
- For assertions that can be checked by code (valid JSON, correct row count,
  file dimensions), use a verification script — more reliable than LLM
  judgment and reusable across iterations.

### Blind comparison

For comparing two skill versions on holistic qualities: present both outputs
to an LLM judge without revealing which came from which version. The judge
scores organization, formatting, usability, and polish on its own rubric.
This complements assertion grading — two outputs might both pass all
assertions but differ significantly in overall quality.

## Aggregating results

Compute summary statistics per configuration and save to `benchmark.json`:

```json
{
  "run_summary": {
    "with_skill": {
      "pass_rate": { "mean": 0.83, "stddev": 0.06 },
      "time_seconds": { "mean": 45.0, "stddev": 12.0 },
      "tokens": { "mean": 3800, "stddev": 400 }
    },
    "without_skill": {
      "pass_rate": { "mean": 0.33, "stddev": 0.10 },
      "time_seconds": { "mean": 32.0, "stddev": 8.0 },
      "tokens": { "mean": 2100, "stddev": 300 }
    },
    "delta": {
      "pass_rate": 0.50,
      "time_seconds": 13.0,
      "tokens": 1700
    }
  }
}
```

The delta tells you what the skill costs (more time, more tokens) and what
it buys (higher pass rate). Standard deviation is only meaningful with
multiple runs per eval — in early iterations, focus on raw pass counts.

## Analyzing patterns

Aggregate statistics can hide important patterns. After computing benchmarks:

- **Remove assertions that always pass in both configurations.** They don't
  measure skill value — they inflate the with-skill rate without reflecting
  actual improvement.
- **Investigate assertions that always fail in both.** Either the assertion
  is broken, the test case is too hard, or it's checking the wrong thing.
- **Study assertions that pass with skill but fail without.** This is where
  the skill adds clear value — understand which instructions made the
  difference.
- **Tighten instructions when results are inconsistent.** High stddev may
  indicate the skill's instructions are ambiguous enough that the agent
  interprets them differently each run. Add examples or more specific
  guidance.
- **Check time and token outliers.** If one eval takes 3x longer, read its
  execution transcript to find the bottleneck.

## Reviewing results with a human

Assertion grading checks what you thought to write assertions for. A human
reviewer catches issues you didn't anticipate. For each test case, review the
actual outputs alongside the grades.

Record specific feedback:

```json
{
  "eval-top-months-chart": "The chart is missing axis labels and the months are in alphabetical order instead of chronological.",
  "eval-clean-missing-emails": ""
}
```

"The chart is missing axis labels" is actionable; "looks bad" is not. Empty
feedback means the output passed your review.

## Reading execution traces

Traces reveal more than final outputs. Look for:

- **Wasted steps**: Agent tries several approaches before succeeding →
  instructions are too vague
- **Irrelevant steps**: Agent follows instructions that don't apply to the
  current task → skill is too broad or lacks conditional guidance
- **Indecision**: Agent pauses at option lists → provide a default
- **Reinvented logic**: Agent writes the same boilerplate each run →
  bundle it as a script

## The improvement cycle

After grading and reviewing, you have three sources of signal: failed
assertions (specific gaps), human feedback (broader quality issues), and
execution transcripts (why things went wrong).

Give all three — along with the current SKILL.md — to an LLM and ask it to
propose changes. Follow these principles:

- **Generalize from feedback.** Fixes should address underlying issues
  broadly, not add narrow patches for specific test cases.
- **Keep the skill lean.** Fewer, better instructions often outperform
  exhaustive rules. If pass rates plateau despite adding more rules, try
  removing instructions.
- **Explain the why.** "Do X because Y tends to cause Z" works better than
  "ALWAYS do X, NEVER do Y."
- **Bundle repeated work.** If every run independently writes a similar
  helper script, bundle it in `scripts/`.

### The loop

1. Propose improvements based on eval signals and current SKILL.md
2. Review and apply changes
3. Rerun all test cases in a new `iteration-<N+1>/` directory
4. Grade and aggregate new results
5. Review with a human. Repeat.

### When to stop

A skill is ready when:
- All core test cases pass reliably (>90% across multiple runs)
- Execution traces show no wasted or irrelevant steps
- A domain expert approves the outputs
- Adding more instructions doesn't improve results (diminishing returns)
- Human feedback is consistently empty

## Variance analysis

Agent outputs are non-deterministic. To distinguish real improvements from
noise:
- Run each test case 3–5 times per skill version
- Compare median scores, not single runs
- A change is meaningful if median score improves AND worst-case doesn't
  regress significantly
