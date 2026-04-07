---
name: agent-skill-guideline
description: >
  Guide for creating, structuring, and optimizing Agent Skills that follow the
  open agentskills.io standard. Use this skill whenever the user wants to create
  a new agent skill, write a SKILL.md file, structure a skill directory, improve
  an existing skill's instructions or description, understand the Agent Skills
  specification, or package a skill for distribution. Also trigger when the user
  mentions "agent skill", "SKILL.md", "skill folder", "skill description", "skill
  frontmatter", or asks how to give an agent new capabilities via the skills format.
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
  sources: 
   - https://agentskills.io
---

# Agent Skill Guideline

A skill for creating well-structured, effective Agent Skills that follow the
open [agentskills.io](https://agentskills.io) standard.

## What is an Agent Skill?

An Agent Skill is a folder of instructions, scripts, and resources that agents
can discover and load on demand. The format is portable across compatible agent
products (Claude Code, GitHub Copilot, Codex, Gemini CLI, and others).

## Directory structure

Every skill is a directory containing at minimum a `SKILL.md` file:

```
skill-name/
├── SKILL.md          # Required: YAML frontmatter + Markdown instructions
├── scripts/          # Optional: executable code the agent can run
├── references/       # Optional: supplementary docs loaded on demand
├── assets/           # Optional: templates, schemas, static resources
└── ...               # Any additional files
```

### Where skills live

Agents typically scan for skills in two scopes:

- **Project-level**: `<project>/.agents/skills/` (or `<project>/.<client>/skills/`)
- **User-level**: `~/.agents/skills/` (or `~/.<client>/skills/`)

Project-level skills override user-level skills when names collide. The
`.agents/skills/` convention enables cross-client interoperability — a skill
installed by one compatible agent is automatically visible to others.

## Writing the SKILL.md

### Frontmatter (required)

The file must begin with YAML frontmatter containing at least `name` and
`description`:

```yaml
---
name: my-skill-name
description: >
  What this skill does and when to use it. Include specific trigger
  keywords so agents can match tasks accurately.
---
```

**`name` rules:**
- 1–64 characters, lowercase alphanumeric and hyphens only
- No leading, trailing, or consecutive hyphens
- Must match the parent directory name

**`description` rules:**
- 1–1024 characters
- Use imperative phrasing: "Use this skill when…" not "This skill does…"
- Focus on user intent, not implementation details
- Include concrete trigger keywords and phrases
- Lean slightly "pushy" — agents tend to under-trigger, so be explicit about
  the contexts where the skill applies, including cases where the user doesn't
  name the domain directly

**Optional frontmatter fields:**

| Field           | Purpose |
|-----------------|---------|
| `license`       | License name or reference to a bundled LICENSE file |
| `compatibility` | Environment requirements — only include if the skill has specific needs (e.g., `Requires Python 3.14+ and uv`, `Requires git, docker, jq, and access to the internet`). Most skills don't need this. |
| `metadata`      | Arbitrary key-value pairs (author, version, etc.) |
| `allowed-tools` | Space-delimited pre-approved tool list (experimental) |

### Body content

The Markdown body after the frontmatter is the skill's instructions. There are
no format restrictions — write whatever helps an agent perform the task. Keep
the body under **500 lines / ~5,000 tokens**. Move detailed reference material
into `references/` files and tell the agent *when* to load each one.

### File references

When referencing other files, use relative paths from the skill root directory:

```markdown
See [the reference guide](references/REFERENCE.md) for details.
Run the extraction script: `scripts/extract.py`
```

Keep file references one level deep from `SKILL.md`. Avoid deeply nested
reference chains.

## Core principles

### 1. Ground skills in real expertise

Do not generate instructions from general knowledge alone. Effective skills
come from:

- **Extracting from a real task**: Complete a task with an agent, note
  corrections and context you provided, then distill the reusable pattern.
  Pay attention to: steps that worked, corrections you made, input/output
  formats, and context you had to provide.
- **Synthesizing from project artifacts**: Feed internal docs, runbooks,
  schemas, code review comments, incident reports, and version control
  history (especially patches and fixes) into the creation process.

### 2. Add what the agent lacks, omit what it knows

Every token competes for the agent's attention. Focus on project-specific
conventions, non-obvious edge cases, and particular tools or APIs. Do not
explain general concepts the agent already understands (what a PDF is, how
HTTP works, etc.). Test by asking: "Would the agent get this wrong without
this instruction?" If no, cut it. If unsure, test it.

### 3. Provide defaults, not menus

When multiple tools or approaches work, pick one default and mention
alternatives briefly as an escape hatch:

```markdown
<!-- Too many options -->
You can use pypdf, pdfplumber, PyMuPDF, or pdf2image...

<!-- Clear default with escape hatch -->
Use pdfplumber for text extraction. For scanned PDFs requiring OCR,
use pdf2image with pytesseract instead.
```

### 4. Favor procedures over declarations

Teach *how to approach* a class of problems, not the answer to one specific
instance. The approach should generalize; individual details (output templates,
constraints) can be specific.

### 5. Match specificity to fragility

- **Flexible tasks** (multiple valid approaches): describe *what* and *why*,
  let the agent decide *how*.
- **Fragile tasks** (exact sequence matters): be fully prescriptive with
  exact commands and "do not modify" guardrails.

Most skills have a mix — calibrate each part independently.

### 6. Explain the why

Reasoning-based instructions ("Do X because Y tends to cause Z") work better
than rigid directives ("ALWAYS do X, NEVER do Y"). An agent that understands
the purpose behind an instruction makes better context-dependent decisions.

### 7. Use progressive disclosure

Skills load in three stages:
1. **Metadata** (~100 tokens): `name` + `description`, always in context
2. **Instructions** (<5,000 tokens): full `SKILL.md` body, loaded on activation
3. **Resources** (as needed): files from `scripts/`, `references/`, `assets/`

Tell the agent *when* to load each referenced file ("Read `references/api-errors.md`
if the API returns a non-200 status code"), not just that references exist.

### 8. Design coherent units

A skill should encapsulate a coherent unit of work — like choosing what a
function should do. Skills scoped too narrowly force multiple skills to load
for a single task. Skills scoped too broadly become hard to activate precisely
and may inject irrelevant instructions.

## Effective instruction patterns

### Gotchas sections

List environment-specific facts that defy reasonable assumptions. These are
often the highest-value content in a skill. Keep them in `SKILL.md` where the
agent reads them *before* encountering the situation:

```markdown
## Gotchas
- The `users` table uses soft deletes — always include `WHERE deleted_at IS NULL`.
- User ID is `user_id` in the DB, `uid` in auth, `accountId` in billing.
- `/health` returns 200 even if the DB is down — use `/ready` instead.
```

When an agent makes a mistake you have to correct, add the correction to the
gotchas section. This is one of the most direct ways to improve a skill.

### Output templates

Provide concrete templates for required output formats. Agents pattern-match
well against structure. Short templates live inline; longer ones go in `assets/`:

```markdown
## Report format

# [Title]
## Executive summary
[One paragraph of key findings]
## Recommendations
1. [Actionable item]
```

### Checklists for multi-step workflows

Explicit checklists help agents track progress and avoid skipping steps:

```markdown
## Workflow
- [ ] Step 1: Analyze input (`scripts/analyze.py`)
- [ ] Step 2: Create mapping (`fields.json`)
- [ ] Step 3: Validate (`scripts/validate.py`)
- [ ] Step 4: Execute (`scripts/run.py`)
- [ ] Step 5: Verify output (`scripts/verify.py`)
```

### Validation loops

Instruct the agent to validate its own work before proceeding:

```markdown
1. Make edits
2. Run `python scripts/validate.py output/`
3. If validation fails → fix issues → re-validate
4. Only proceed when validation passes
```

### Plan-validate-execute

For batch or destructive operations, create an intermediate plan, validate it
against a source of truth, then execute. The key ingredient is a validation
script that checks the plan against reality and gives the agent enough
information to self-correct:

```markdown
1. Extract fields → `form_fields.json`
2. Create values → `field_values.json`
3. Validate: `scripts/validate_fields.py form_fields.json field_values.json`
4. Fix and re-validate if needed
5. Execute: `scripts/fill_form.py input.pdf field_values.json output.pdf`
```

## Bundling scripts

When the agent independently reinvents the same logic across runs (chart
building, data parsing, output validation), write a tested script and bundle
it in `scripts/`.

### One-off commands vs bundled scripts

When an existing package already does what you need, reference it directly in
your instructions using auto-resolving runners without a `scripts/` directory.
Pin versions for reproducibility:

- **Python**: `uvx ruff@0.8.0 check .` or `pipx run 'black==24.10.0' .`
- **Node.js**: `npx eslint@9 --fix .`
- **Bun**: `bunx eslint@9 --fix .`
- **Deno**: `deno run npm:create-vite@6 my-app`
- **Go**: `go run golang.org/x/tools/cmd/goimports@v0.28.0 .`

State prerequisites in `SKILL.md` or the `compatibility` frontmatter field.
When a command grows complex enough that it's hard to get right on the first
try, a tested script in `scripts/` is more reliable.

### Self-contained scripts

Use inline dependency declarations so scripts run with a single command
and no separate install step:

- **Python** (PEP 723): `# /// script` block, run with `uv run scripts/extract.py`
- **Deno**: `npm:` / `jsr:` import specifiers
- **Bun**: auto-install from versioned imports
- **Ruby**: `bundler/inline`

### Designing scripts for agentic use

Scripts run by agents must work in non-interactive shells. See
`references/script-design.md` for the full guide. Key rules:

1. **No interactive prompts** — accept all input via flags, env vars, or stdin.
   A script that blocks on TTY input will hang indefinitely.
2. **Document usage with `--help`** — this is how agents learn the interface.
   Include a description, available flags, and usage examples. Keep it concise.
3. **Write helpful error messages** — say what went wrong, what was expected,
   and what to try. Opaque errors waste agent turns.
4. **Use structured output** — prefer JSON/CSV/TSV over free-form text. Send
   data to stdout, diagnostics to stderr.
5. **Make scripts idempotent** — agents may retry. "Create if not exists" is
   safer than "create and fail on duplicate."
6. **Support `--dry-run`** for destructive operations.
7. **Use meaningful exit codes** — distinct codes for different failure types.
8. **Control output size** — default to summaries. Support `--offset` or
   `--output FILE` for large results, since agent harnesses may truncate
   output beyond 10–30K characters.

## Optimizing the description

The `description` field is the primary triggering mechanism. To optimize it:

1. Write a diverse set of 20+ test prompts (10 that should trigger, 10 that
   should not). For negative cases, focus on **near-misses** — queries that
   share keywords but need something different — not obviously unrelated prompts.
2. Split into 60% train / 40% validation to avoid overfitting.
3. Test whether the agent activates the skill (run each prompt 3x for reliability).
4. Revise based on train-set failures. Generalize — don't add specific keywords
   from failed queries; address the category they represent.
5. Select the description with the best *validation* score, not train score.

See `references/description-optimization.md` for full methodology.

## Evaluating skill quality

Structured evaluation turns guesswork into a feedback loop:

1. Write test cases with prompts, expected outputs, and optional input files.
   Start with 2–3 cases, expand later.
2. Run each test case twice: with the skill and without it (baseline).
3. Write assertions after seeing first outputs — you often don't know what
   "good" looks like until the skill has run.
4. Grade assertions with concrete evidence, not opinions.
5. Review outputs with a human for issues assertions don't cover.
6. Iterate: diagnose failures, revise SKILL.md, re-run, confirm improvements.

See `references/evaluation-guide.md` for the full methodology including
workspace structure, assertion design, grading principles, benchmarking,
and pattern analysis.

## Iterating on a skill

1. Run the skill against real tasks
2. Read agent execution traces, not just final outputs
3. Look for: wasted steps (vague instructions), irrelevant steps (instructions
   that don't apply), indecision (too many options without defaults),
   reinvented logic (same boilerplate each run)
4. Add corrections to the gotchas section
5. Keep the skill lean — fewer, better instructions often outperform
   exhaustive rules. If pass rates plateau despite adding more rules, try
   *removing* instructions
6. Repeat — even one pass of execute-then-revise noticeably improves quality

## Quick-start checklist

- [ ] Create `skill-name/SKILL.md` with valid frontmatter
- [ ] Write a rich `description` with imperative phrasing and trigger keywords
- [ ] Add step-by-step instructions in the body
- [ ] Include a gotchas section for non-obvious facts
- [ ] Add output templates if format matters
- [ ] Move large reference material to `references/`
- [ ] Bundle reusable logic in `scripts/` (design for agentic use)
- [ ] Test against real tasks and iterate
- [ ] Run description optimization with train/validation split
- [ ] Validate with `skills-ref validate ./skill-name`
