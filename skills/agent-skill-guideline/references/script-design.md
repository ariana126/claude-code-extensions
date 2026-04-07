# Script Design for Agentic Use

How to design scripts that agents can run effectively. When an agent runs your
script, it reads stdout and stderr to decide what to do next. A few design
choices make scripts dramatically easier for agents to use.

## Hard requirement: no interactive prompts

Agents operate in non-interactive shells — they cannot respond to TTY prompts,
password dialogs, or confirmation menus. A script that blocks on interactive
input will hang indefinitely.

Accept all input via command-line flags, environment variables, or stdin:

```
# Bad: hangs waiting for input
$ python scripts/deploy.py
Target environment: _

# Good: clear error with guidance
$ python scripts/deploy.py
Error: --env is required. Options: development, staging, production.
Usage: python scripts/deploy.py --env staging --tag v1.2.3
```

## Document usage with --help

`--help` output is the primary way an agent learns your script's interface.
Include a brief description, available flags, and usage examples:

```
Usage: scripts/process.py [OPTIONS] INPUT_FILE

Process input data and produce a summary report.

Options:
  --format FORMAT    Output format: json, csv, table (default: json)
  --output FILE      Write output to FILE instead of stdout
  --verbose          Print progress to stderr

Examples:
  scripts/process.py data.csv
  scripts/process.py --format csv --output report.csv data.csv
```

Keep it concise — the output enters the agent's context window alongside
everything else it's working with.

## Write helpful error messages

When an agent gets an error, the message directly shapes its next attempt.
Say what went wrong, what was expected, and what to try:

```
Error: --format must be one of: json, csv, table.
       Received: "xml"
```

An opaque "Error: invalid input" wastes a turn.

## Use structured output

Prefer JSON, CSV, or TSV over free-form text. Structured formats can be
consumed by both the agent and standard tools (jq, cut, awk), making your
script composable in pipelines.

```
# Hard to parse programmatically
NAME          STATUS    CREATED
my-service    running   2025-01-15

# Unambiguous field boundaries
{"name": "my-service", "status": "running", "created": "2025-01-15"}
```

**Separate data from diagnostics**: send structured data to stdout and
progress messages, warnings, and other diagnostics to stderr. This lets the
agent capture clean, parseable output while still having access to diagnostic
information when needed.

## Idempotency

Agents may retry commands. Design for repeated execution:

- "Create if not exists" is safer than "create and fail on duplicate"
- Update operations should produce the same result when run twice
- Avoid side effects that compound on retry

## Input constraints

Reject ambiguous input with a clear error rather than guessing. Use enums
and closed sets where possible:

```
Error: --region must be one of: us-east-1, us-west-2, eu-west-1.
       Received: "US East"
```

## Dry-run support

For destructive or stateful operations, a `--dry-run` flag lets the agent
preview what will happen before committing:

```
$ python scripts/migrate.py --dry-run
Would rename 47 files matching pattern *.log → *.log.bak
Would delete 12 empty directories
No changes made (dry run).
```

## Meaningful exit codes

Use distinct exit codes for different failure types and document them in your
`--help` output:

```
Exit codes:
  0  Success
  1  Invalid arguments
  2  File not found
  3  Authentication failure
  4  Network error
```

This lets agents handle different failures differently.

## Safe defaults

Consider whether destructive operations should require explicit confirmation
flags (`--confirm`, `--force`) or other safeguards appropriate to the risk
level. An agent that accidentally runs a destructive operation without
safeguards could cause data loss.

## Predictable output size

Many agent harnesses automatically truncate tool output beyond a threshold
(typically 10–30K characters), potentially losing critical information.

Design for this:

- Default to a summary or a reasonable limit
- Support `--offset` or pagination flags so the agent can request more when
  needed
- For large output not amenable to pagination, require an `--output FILE`
  flag to write to disk instead of stdout
- When stdout is used, consider adding a footer like "Showing 50 of 1,247
  results. Use --offset 50 to see more."

## Self-contained dependencies

Use inline dependency declarations so scripts run with a single command and
no separate install step:

### Python (PEP 723)

```python
# /// script
# dependencies = [
#   "beautifulsoup4>=4.12,<5",
# ]
# ///

from bs4 import BeautifulSoup
# ...
```

Run with: `uv run scripts/extract.py`

Pin versions with PEP 508 specifiers. Use `requires-python` to constrain the
Python version. Use `uv lock --script` for full reproducibility.

### Deno

```typescript
import * as cheerio from "npm:cheerio@1.0.0";
```

Run with: `deno run scripts/extract.ts`

Use `npm:` for npm packages, `jsr:` for Deno-native packages. Note that
packages with native addons (node-gyp) may not work.

### Bun

```typescript
import * as cheerio from "cheerio@1.0.0";
```

Run with: `bun run scripts/extract.ts`

Auto-installs missing packages at runtime when no `node_modules` directory is
found. If a `node_modules` directory exists anywhere up the directory tree,
auto-install is disabled.

### Ruby

```ruby
require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'nokogiri', '~> 1.16'
end
```

Run with: `ruby scripts/extract.rb`

## One-off commands vs bundled scripts

When an existing package already does what you need, reference it directly
in SKILL.md using auto-resolving runners. Pin versions for reproducibility:

| Runner | Example |
|--------|---------|
| `uvx`  | `uvx ruff@0.8.0 check .` |
| `pipx` | `pipx run 'black==24.10.0' .` |
| `npx`  | `npx eslint@9 --fix .` |
| `bunx` | `bunx eslint@9 --fix .` |
| `deno run` | `deno run npm:create-vite@6 my-app` |
| `go run` | `go run golang.org/x/tools/cmd/goimports@v0.28.0 .` |

When a command grows complex enough that it's hard to get right on the first
try, a tested script in `scripts/` is more reliable.

## When to bundle a script

Compare execution traces across test cases. If the agent independently
reinvents the same logic each run — building charts, parsing a specific
format, validating output — that's a signal to write a tested script once
and bundle it in `scripts/`.
