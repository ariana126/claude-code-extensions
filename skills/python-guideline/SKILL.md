---
name: python-guideline
description: >
  Python 3.10+ coding guidelines, best practices, and standards for writing
  clean, maintainable, production-ready Python code. Use this skill whenever the
  user asks about Python coding standards, style guides, best practices, code
  quality, project structure, type hints, error handling, testing patterns, or
  how to write idiomatic ("Pythonic") code. Also trigger when the user is writing
  Python code and you notice anti-patterns, poor structure, missing type hints,
  bad naming, or other quality issues — even if they don't explicitly ask for
  guidance. Trigger for questions about Python project setup, pyproject.toml
  configuration, linting, formatting, or tooling choices. This skill covers
  Python 3.10+ features including structural pattern matching, union type syntax,
  dataclasses, and modern packaging.
license: MIT
metadata:
  version: "1.0"
  author: ariana.maghsoudi82@gmail.com
  sources:
    - https://peps.python.org/pep-0008
    - http://docs.python.org/3.10/whatsnew/3.10.html
    - https://packaging.python.org/en/latest/guides/writing-pyproject-toml
---

# Python 3.10+ Coding Guidelines

A comprehensive set of coding standards and best practices for writing clean,
maintainable, production-ready Python 3.10+ code. These guidelines synthesize
PEP 8, PEP 257, the Zen of Python, and modern community conventions.

## Philosophy

Python's guiding principle is that **code is read far more often than it is
written**. Every decision — naming, structure, formatting — should optimize
for the reader, not the writer. When in doubt, favor explicitness over
cleverness, and simplicity over sophistication.

The Zen of Python (`import this`) captures this well: beautiful is better than
ugly, explicit is better than implicit, simple is better than complex, and
readability counts.

## Code Style & Formatting

### Indentation and line length

Use **4 spaces** per indentation level — never tabs. Limit lines to **88
characters** (the `black` default, a pragmatic relaxation of PEP 8's 79). For
docstrings and comments, keep to 72 characters.

### Naming conventions

Use these naming patterns consistently:

```python
# Modules and packages: short, lowercase, underscores if needed
import data_loader

# Functions and variables: snake_case, descriptive verbs for functions
def calculate_total_price(items: list[Item]) -> Decimal:
    base_price = sum(item.price for item in items)
    ...

# Classes: PascalCase, noun phrases
class OrderProcessor:
    ...

# Constants: UPPER_SNAKE_CASE, defined at module level
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT_SECONDS = 30

# Private: single leading underscore
def _validate_input(data: dict) -> bool:
    ...

# "Dunder" methods: double underscores (only for Python protocols)
def __repr__(self) -> str:
    ...
```

Avoid single-letter variable names except in very short comprehensions or
lambdas where the meaning is immediately clear (e.g., `[x * 2 for x in
numbers]`). Never use `l`, `O`, or `I` as single-letter names because they're
visually ambiguous.

Avoid redundant labeling — don't prefix class attributes with the class name
(e.g., use `User.name`, not `User.user_name`).

### Imports

Organize imports into three groups separated by blank lines, in this order:
standard library, third-party packages, local/project modules. Import entire
modules rather than individual symbols to make origins clear and avoid circular
imports:

```python
import os
import sys
from pathlib import Path

import httpx
from pydantic import BaseModel

from myproject.core import services
from myproject.models import User
```

Never use wildcard imports (`from module import *`) — they pollute the namespace
and make it impossible to trace where names come from. Use `__all__` in your
modules to declare the public API explicitly.

### Whitespace and blank lines

Surround top-level function and class definitions with **two** blank lines.
Surround method definitions inside a class with **one** blank line. Use blank
lines sparingly within functions to separate logical sections.

Don't use spaces around `=` in keyword arguments or default parameter values:

```python
# Correct
def connect(host: str, port: int = 8080, timeout: float = 30.0) -> None:
    ...

# Wrong
def connect(host: str, port: int = 8080, timeout: float = 30.0) -> None:
    ...
```

### String formatting

Use **f-strings** for string interpolation — they're the most readable and
performant option in modern Python:

```python
greeting = f"Hello, {user.name}! You have {count} new messages."
```

For complex expressions inside f-strings, extract to a variable first to keep
the f-string readable.

## Type Hints

Type hints are not optional in modern Python — they make code easier to read,
debug, and maintain. Use them consistently on all function signatures, and on
variables where the type isn't obvious from the assignment.

### Python 3.10+ union syntax

Use the `X | Y` syntax instead of `typing.Union[X, Y]`:

```python
# Python 3.10+ — use this
def process(value: int | str) -> str:
    ...

def find_user(user_id: int) -> User | None:
    ...

# Don't use the old style
from typing import Union, Optional
def process(value: Union[int, str]) -> str:  # avoid
    ...
```

### Common type hint patterns

```python
from collections.abc import Sequence, Mapping, Callable, Iterator

# Use built-in generics (Python 3.9+)
def filter_items(items: list[str], predicate: Callable[[str], bool]) -> list[str]:
    ...

# Use collections.abc for read-only input parameters
def summarize(data: Sequence[float]) -> float:
    ...

# TypeAlias for complex types (Python 3.10+)
from typing import TypeAlias
Coordinate: TypeAlias = tuple[float, float]
Grid: TypeAlias = list[list[Coordinate]]
```

Use `mypy` (or `pyright`) to statically check your type annotations. Configure
it in `pyproject.toml` with strict mode enabled for new projects.

## Structural Pattern Matching

Python 3.10 introduced `match`/`case` statements — use them when you need to
branch based on the **structure** of data, not just simple value equality. Don't
use them as a glorified `switch` — a dictionary lookup is better for simple
value-to-action mappings.

### When to use pattern matching

Pattern matching shines when you need to destructure data and branch on its
shape simultaneously:

```python
from dataclasses import dataclass

@dataclass
class Point:
    x: float
    y: float

def describe_point(point: Point) -> str:
    match point:
        case Point(x=0, y=0):
            return "origin"
        case Point(x=0, y=y):
            return f"on y-axis at {y}"
        case Point(x=x, y=0):
            return f"on x-axis at {x}"
        case Point(x=x, y=y) if x == y:
            return f"on diagonal at {x}"
        case Point(x=x, y=y):
            return f"at ({x}, {y})"
```

### Guidelines for match/case

- Place the most **specific** patterns first, most general last.
- Always include a wildcard `case _:` or a catch-all to handle unexpected data
  explicitly — raise an error or log a warning rather than silently passing.
- Use guard clauses (`if` after the pattern) for conditions that can't be
  expressed in the pattern itself.
- Don't use `match` for simple value checks — `if/elif` or a dictionary is
  clearer for that.

## Data Classes and Modern Class Design

Prefer `dataclasses` over manually writing `__init__`, `__repr__`, `__eq__`,
etc. They reduce boilerplate and make data structures self-documenting:

```python
from dataclasses import dataclass, field

@dataclass(frozen=True, slots=True)
class Config:
    host: str
    port: int = 8080
    tags: list[str] = field(default_factory=list)
```

- Use `frozen=True` when instances should be immutable (the common case).
- Use `slots=True` (Python 3.10+) for memory efficiency and faster attribute
  access.
- Use `field(default_factory=...)` for mutable defaults — never use a mutable
  default directly.

For data that needs validation, serialization, or schema enforcement, use
**Pydantic** `BaseModel` instead of plain dataclasses.

## Error Handling

### Use specific exceptions

Catch the most specific exception possible. Never use bare `except:` — it
catches `SystemExit`, `KeyboardInterrupt`, and other things you shouldn't
suppress:

```python
# Good — specific and informative
try:
    user = db.get_user(user_id)
except UserNotFoundError:
    logger.warning("User %s not found", user_id)
    return None
except DatabaseConnectionError as exc:
    logger.error("DB connection failed: %s", exc)
    raise ServiceUnavailableError("Database is unreachable") from exc

# Bad — swallows everything
try:
    user = db.get_user(user_id)
except:  # never do this
    pass   # especially not this
```

### Define custom exceptions

Create a hierarchy of project-specific exceptions that inherits from a common
base. This makes it easy for callers to catch broad or narrow categories:

```python
class AppError(Exception):
    """Base exception for this application."""

class ValidationError(AppError):
    """Raised when input validation fails."""

class NotFoundError(AppError):
    """Raised when a requested resource doesn't exist."""
```

### Context managers for resource cleanup

Use `with` statements for any resource that needs cleanup (files, connections,
locks). Python 3.10+ supports parenthesized context managers for multiple
resources:

```python
with (
    open("input.txt") as source,
    open("output.txt", "w") as dest,
):
    dest.write(source.read())
```

## Functions and Methods

### Keep functions small and focused

Each function should do one thing and do it well. If a function's docstring
requires "and" to describe what it does, consider splitting it.

### Use early returns to reduce nesting

```python
# Prefer this
def get_discount(user: User) -> Decimal:
    if not user.is_active:
        return Decimal("0")
    if user.is_premium:
        return Decimal("0.20")
    return Decimal("0.05")

# Over deeply nested alternatives
def get_discount(user: User) -> Decimal:
    if user.is_active:
        if user.is_premium:
            return Decimal("0.20")
        else:
            return Decimal("0.05")
    else:
        return Decimal("0")
```

### Prefer keyword arguments for clarity

When a function has more than two or three parameters, use keyword-only
arguments (after `*`) to force callers to be explicit:

```python
def send_email(
    *,
    to: str,
    subject: str,
    body: str,
    cc: list[str] | None = None,
    priority: str = "normal",
) -> None:
    ...
```

## Docstrings and Documentation

Follow PEP 257. Write docstrings for all public modules, classes, and
functions. Use imperative mood ("Return the user" not "Returns the user"):

```python
def calculate_tax(amount: Decimal, rate: float) -> Decimal:
    """Calculate tax for the given amount at the specified rate.

    Args:
        amount: The pre-tax amount.
        rate: The tax rate as a decimal (e.g., 0.21 for 21%).

    Returns:
        The calculated tax amount, rounded to 2 decimal places.

    Raises:
        ValueError: If rate is negative or greater than 1.
    """
    if not 0 <= rate <= 1:
        raise ValueError(f"Tax rate must be between 0 and 1, got {rate}")
    return (amount * Decimal(str(rate))).quantize(Decimal("0.01"))
```

For trivial functions where the name and signature tell the whole story, a
one-line docstring is enough: `"""Return the absolute value of x."""`

## Testing

Use **pytest** as the testing framework — it's the modern standard with the
best ecosystem.

### Test structure

Mirror your source tree in the `tests/` directory:

```
src/myproject/services/billing.py  →  tests/services/test_billing.py
```

### Test naming

Name tests as `test_<what>_<condition>_<expected>`:

```python
def test_calculate_tax_with_zero_rate_returns_zero():
    assert calculate_tax(Decimal("100"), 0.0) == Decimal("0.00")

def test_calculate_tax_with_negative_rate_raises_value_error():
    with pytest.raises(ValueError, match="between 0 and 1"):
        calculate_tax(Decimal("100"), -0.1)
```

### Test guidelines

- Each test should verify one behavior.
- Use fixtures for shared setup; avoid inheritance-based test classes.
- Prefer `assert` over `self.assertEqual` — pytest's introspection gives you
  better error messages automatically.
- Use `pytest.raises` for exception testing, `pytest.approx` for floats.

## Project Structure

Use the `src` layout for packages. It prevents accidental imports from your
working directory and clearly separates source from project root:

```
my-project/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── core/
│       ├── models/
│       ├── services/
│       └── utils/
├── tests/
│   ├── conftest.py
│   └── ...
├── pyproject.toml
├── README.md
├── .gitignore
└── .pre-commit-config.yaml
```

For detailed guidance on `pyproject.toml` configuration, tooling setup, and
pre-commit hooks, see [references/tooling.md](references/tooling.md).

## Gotchas

- **Mutable default arguments** are shared across calls. Always use `None` as
  the default and create the mutable inside the function:
  ```python
  def add_item(item: str, items: list[str] | None = None) -> list[str]:
      if items is None:
          items = []
      items.append(item)
      return items
  ```
- **`is` vs `==`**: Use `is` only for `None`, `True`, `False` comparisons. For
  value equality, always use `==`.
- **Bare `except:`**: Never use it. At minimum, catch `Exception`.
- **String concatenation in loops**: Use `"".join(parts)` instead of `+=` in a
  loop — it's O(n) vs O(n²).
- **Late binding closures**: Variables in closures are looked up at call time,
  not definition time. This bites people in loops:
  ```python
  # Bug: all functions return 4
  funcs = [lambda: i for i in range(5)]
  # Fix: capture with default argument
  funcs = [lambda i=i: i for i in range(5)]
  ```
- **`datetime.now()` without timezone**: Always use `datetime.now(tz=UTC)` from
  `datetime` — naive datetimes cause subtle bugs in any multi-timezone system.
- **Forgetting `from __future__ import annotations`**: If you need to support
  Python 3.9 alongside 3.10+, this import enables the `X | Y` union syntax and
  postponed evaluation of annotations.
