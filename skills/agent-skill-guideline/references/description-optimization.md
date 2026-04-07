# Description Optimization Reference

Detailed guidance for writing and refining the `description` field in SKILL.md
frontmatter. The description is the primary mechanism by which agents decide
whether to activate a skill.

## How triggering works

At startup, agents load only the `name` and `description` of each available
skill. When a user's request arrives, the agent scans descriptions to decide
which skill(s) to activate. Only then does the full SKILL.md body load into
context.

Key insight: agents only consult skills for tasks they can't easily handle on
their own. Simple, one-step queries may not trigger a skill even if the
description matches perfectly. Tasks that involve specialized knowledge — an
unfamiliar API, a domain-specific workflow, or an uncommon format — are where
a well-written description makes the difference.

## Writing effective descriptions

### Use imperative phrasing

Frame the description as an instruction to the agent: "Use this skill when…"
rather than "This skill does…" The agent is deciding whether to act, so tell
it when to act.

### Focus on user intent, not implementation

Describe what the user is trying to achieve, not the skill's internal
mechanics. The agent matches against what the user asked for.

### Include both WHAT and WHEN

```yaml
# Poor — only says what
description: Processes PDF files.

# Good — says what and when
description: >
  Extract text and tables from PDFs, fill PDF forms, merge multiple PDFs.
  Use when the user needs to work with PDF documents, mentions .pdf files,
  asks about form filling, or needs document extraction.
```

### Use concrete trigger keywords

List the specific words and phrases users are likely to say:

```yaml
description: >
  Create, read, edit, and format Word documents (.docx files). Use when the
  user mentions 'Word doc', '.docx', 'word document', or asks for reports,
  memos, letters, or templates as Word files.
```

### Be slightly pushy

Agents tend to under-trigger. Explicitly state contexts where the skill
should activate, even if they seem obvious:

```yaml
description: >
  Build dashboards to display data. Use this skill whenever the user
  mentions dashboards, data visualization, charts, metrics display, or
  wants to present any kind of structured data visually — even if they
  don't explicitly ask for a "dashboard."
```

### Stay within 1024 characters

The spec limits descriptions to 1024 characters. Be concise but thorough.
Descriptions tend to grow during optimization — check the limit after each
revision.

## Designing trigger eval queries

To test triggering, you need a set of eval queries — realistic user prompts
labeled with whether they should or shouldn't trigger your skill. Aim for
about 20 queries: 8–10 that should trigger and 8–10 that should not.

```json
[
  { "query": "I've got a spreadsheet in ~/data/q4_results.xlsx with revenue in col C...", "should_trigger": true },
  { "query": "whats the quickest way to convert this json file to yaml", "should_trigger": false }
]
```

### Should-trigger queries

Vary them along several axes:

- **Phrasing**: some formal, some casual, some with typos or abbreviations
- **Explicitness**: some name the domain directly ("analyze this CSV"),
  others describe the need without naming it ("my boss wants a chart from
  this data file")
- **Detail**: mix terse prompts with context-heavy ones that include file
  paths, column names, and backstory
- **Complexity**: single-step tasks alongside multi-step workflows

The most useful should-trigger queries are ones where the skill would help
but the connection isn't obvious from the query alone.

### Should-not-trigger queries

Focus on **near-misses** — queries that share keywords or concepts with your
skill but actually need something different. These test precision, not just
breadth.

Weak negatives (test nothing):
- `"Write a fibonacci function"` — obviously irrelevant
- `"What's the weather today?"` — no keyword overlap

Strong negatives:
- `"I need to update the formulas in my Excel budget spreadsheet"` — shares
  "spreadsheet" and "data" concepts, but needs Excel editing, not CSV analysis
- `"can you write a python script that reads a csv and uploads each row to
  our postgres database"` — involves CSV, but the task is database ETL

### Tips for realism

Real user prompts contain context that generic test queries lack. Include:

- File paths (`~/Downloads/report_final_v2.xlsx`)
- Personal context (`"my manager asked me to..."`)
- Specific details (column names, company names, data values)
- Casual language, abbreviations, and occasional typos

## Testing and measuring

Run each query through your agent with the skill installed. A query "passes"
if: `should_trigger` is true and the skill was invoked, or `should_trigger`
is false and the skill was not invoked.

### Running multiple times

Model behavior is nondeterministic. Run each query 3+ times and compute a
**trigger rate**. A should-trigger query passes if its trigger rate is above
0.5. A should-not-trigger query passes if its rate is below 0.5.

### Avoiding overfitting with train/validation splits

Split your query set:

- **Train set (~60%)**: queries used to identify failures and guide improvements
- **Validation set (~40%)**: queries set aside to check whether improvements
  generalize

Make sure both sets have a proportional mix of should-trigger and
should-not-trigger queries. Keep the split fixed across iterations.

## The optimization loop

1. **Evaluate** the current description on both train and validation sets.
2. **Identify failures** in the *train set only*: which should-trigger queries
   didn't trigger? Which should-not-trigger queries did?
3. **Revise the description**:
   - If should-trigger queries fail → description may be too narrow. Broaden
     scope or add context about when the skill is useful.
   - If should-not-trigger queries false-trigger → description may be too broad.
     Add specificity about what the skill does *not* do.
   - Generalize from failures — don't add specific keywords from failed queries
     (that's overfitting). Find the general category those queries represent.
   - If stuck after several iterations, try a structurally different approach
     to the description rather than incremental tweaks.
4. **Repeat** until all train set queries pass or improvement plateaus.
5. **Select the best iteration** by its *validation* pass rate. The best
   description may not be the last one — earlier iterations might score higher
   on validation than later ones that overfit to the train set.

Five iterations is usually enough. If performance isn't improving, the issue
may be with the queries themselves (too easy, too hard, or poorly labeled).

## Applying the result

Once you've selected the best description:

1. Update the `description` field in your `SKILL.md` frontmatter.
2. Verify it's under the 1024-character limit.
3. Write 5–10 fresh queries (never seen during optimization) and test as a
   final sanity check.

Before and after example:

```yaml
# Before
description: Process CSV files.

# After
description: >
  Analyze CSV and tabular data files — compute summary statistics,
  add derived columns, generate charts, and clean messy data. Use this
  skill when the user has a CSV, TSV, or Excel file and wants to
  explore, transform, or visualize the data, even if they don't
  explicitly mention "CSV" or "analysis."
```

## Common failure modes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Never triggers | Description too vague | Add specific keywords and trigger phrases |
| Triggers on everything | Description too broad | Narrow scope, add "do NOT use for" exclusions |
| Misses indirect requests | Only covers literal terms | Add synonyms and alternative phrasings |
| Triggers for simple tasks | Agent handles them without help | Make test prompts more complex |
| Validation score drops while train improves | Overfitting | Revert to best validation-scoring iteration |
| Stuck after several iterations | Incremental tweaks exhausted | Try structurally different description framing |
