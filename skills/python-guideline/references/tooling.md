# Tooling & Project Configuration Reference

Detailed guidance on setting up modern Python tooling. Read this when
configuring a new project or when the user asks about linting, formatting,
dependency management, or CI setup.

## Table of Contents

1. [pyproject.toml](#pyprojecttoml)
2. [Linting and Formatting](#linting-and-formatting)
3. [Type Checking](#type-checking)
4. [Pre-commit Hooks](#pre-commit-hooks)
5. [Virtual Environments](#virtual-environments)
6. [Dependency Management](#dependency-management)

---

## pyproject.toml

Use `pyproject.toml` as the single source of truth for project metadata, build
configuration, and tool settings. It replaces the old combination of
`setup.py`, `setup.cfg`, `requirements.txt`, and tool-specific config files.

### Minimal example for a library/package

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-project"
version = "1.0.0"
description = "A clear, one-line description"
readme = "README.md"
requires-python = ">=3.10"
license = "MIT"
authors = [
    { name = "Your Name", email = "you@example.com" },
]
dependencies = [
    "httpx>=0.27",
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "mypy>=1.10",
    "ruff>=0.5",
    "pre-commit>=3.7",
]

[project.scripts]
my-cli = "my_project.cli:main"
```

### Minimal example for an application (not published to PyPI)

Applications that aren't distributed as packages can use a simpler config.
Many teams use `uv` or `pip-tools` for dependency locking:

```toml
[project]
name = "my-app"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = [
    "fastapi>=0.110",
    "uvicorn>=0.29",
    "sqlalchemy>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "ruff>=0.5",
    "mypy>=1.10",
]
```

### Tool configuration sections

All tool configs go under `[tool.<name>]` in the same file:

```toml
[tool.ruff]
target-version = "py310"
line-length = 88

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "N",    # pep8-naming
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "SIM",  # flake8-simplify
    "TCH",  # flake8-type-checking
    "RUF",  # ruff-specific rules
]

[tool.ruff.lint.isort]
known-first-party = ["my_project"]

[tool.mypy]
python_version = "3.10"
strict = true
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra --strict-markers --strict-config"
```

---

## Linting and Formatting

Use **ruff** as the default linter and formatter. It replaces flake8, isort,
pycodestyle, pyflakes, and many flake8 plugins — and it's 10–100x faster
because it's written in Rust.

### Quick setup

```bash
# Install
pip install ruff

# Lint (check)
ruff check .

# Lint (fix auto-fixable issues)
ruff check --fix .

# Format (replaces black)
ruff format .
```

### Why ruff over black + flake8 + isort

Ruff combines linting and formatting in a single tool with a single config
section. This means fewer dependencies, faster CI runs, and less configuration
to maintain. For new projects in 2025+, ruff is the standard choice.

If you're on an existing project that uses black + flake8 + isort, there's no
urgent need to migrate, but ruff is a drop-in replacement with a migration
guide.

---

## Type Checking

Use **mypy** for static type checking. For new projects, enable strict mode:

```toml
[tool.mypy]
python_version = "3.10"
strict = true
```

Run it as part of CI:

```bash
mypy src/
```

**pyright** is a good alternative, especially if your team uses VS Code (it
powers Pylance). Either is fine — pick one and use it consistently.

### Common mypy configuration tips

- Use `--strict` on new code. For legacy codebases, enable strictness
  incrementally with per-module overrides.
- Set `warn_return_any = true` to catch functions that accidentally return
  `Any`.
- Use `# type: ignore[specific-error]` with the specific error code rather
  than a blanket `# type: ignore`.

---

## Pre-commit Hooks

Pre-commit hooks catch issues before code reaches the repository. Use the
`pre-commit` framework:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-added-large-files
      - id: detect-private-key

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.5.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

Install with:

```bash
pip install pre-commit
pre-commit install
```

---

## Virtual Environments

Always work inside a virtual environment to isolate project dependencies.

### Using venv (built-in)

```bash
python -m venv .venv
source .venv/bin/activate    # Linux/macOS
.venv\Scripts\activate       # Windows
```

### Using uv (recommended for speed)

`uv` is an extremely fast Python package installer and resolver written in
Rust. It's becoming the preferred tool for environment and dependency
management:

```bash
# Create a venv
uv venv

# Install dependencies from pyproject.toml
uv pip install -e ".[dev]"

# Compile a lockfile
uv pip compile pyproject.toml -o requirements.lock
```

---

## Dependency Management

### Pinning strategy

- **Libraries**: Use lower-bound constraints (`>=2.0`) so downstream users
  have flexibility.
- **Applications**: Pin exact versions or use a lockfile for reproducible
  deployments.

### Lockfiles

Use `uv pip compile` or `pip-tools` to generate a lockfile from your
`pyproject.toml`:

```bash
uv pip compile pyproject.toml -o requirements.lock
uv pip compile pyproject.toml --extra dev -o requirements-dev.lock
```

### Security auditing

Regularly audit dependencies for known vulnerabilities:

```bash
pip install pip-audit
pip-audit
```
