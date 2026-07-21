# Interpreter
**Classification**: Class Behavioral | **Chapter**: 5

## Intent
Given a language, define a representation for its grammar along with an interpreter that uses the representation to interpret sentences in the language.

## Core Idea
Map **one class per grammar rule**, make the right-hand-side symbols instance variables of that class, and represent each sentence as an **abstract syntax tree** of those instances. Interpretation is then a recursive `Interpret` walk over the tree.

## Applicability
Use Interpreter when there is a language to interpret and you can represent its statements as abstract syntax trees. It works best when:
- **The grammar is simple.** Complex grammars produce a large, unmanageable class hierarchy; parser generators are the better alternative there — they can interpret expressions without building an AST at all, saving space and possibly time.
- **Efficiency is not critical.** The fastest interpreters translate parse trees into another form first (regular expressions become state machines) — though that *translator* can itself be built with Interpreter, so the pattern still applies.

## Structure
- **AbstractExpression** (RegularExpression, BooleanExp): declares the `Interpret` operation common to all AST nodes.
- **TerminalExpression** (LiteralExpression, Constant, VariableExp): implements `Interpret` for terminal symbols; one instance is needed for every terminal occurrence in a sentence.
- **NonterminalExpression** (AlternationExpression, SequenceExpression, RepetitionExpression, AndExp): one class per rule `R ::= R1 R2 ... Rn`, holding an AbstractExpression variable per symbol `R1..Rn`; `Interpret` typically recurses on each.
- **Context**: information global to the interpreter (the input string and how much has matched; or a variable→value binding).
- **Client**: builds or is handed the AST for a sentence, initializes the Context, and invokes `Interpret`.

Collaboration: Client assembles the tree → initializes Context → calls `Interpret` at the root; nonterminals recurse, terminals form the base case, and every node reads/writes interpreter state through the Context.

## How
1. Write the grammar in BNF; the start symbol becomes the root expression type.
2. Define AbstractExpression with `Interpret(Context&)`.
3. Add one NonterminalExpression subclass per production rule, with a member per right-hand-side symbol; add one TerminalExpression subclass per terminal.
4. Define Context to carry global interpretation state (input position, variable bindings).
5. Build the AST — by hand, by a recursive descent parser, or by a table-driven parser — then call `Interpret` on the root.

## Consequences
**Benefits**
- **Easy to change and extend the grammar**: rules are classes, so inheritance modifies existing expressions incrementally and defines new ones as variations of old.
- **Implementing the grammar is easy**: node classes have similar, near-boilerplate implementations, and their generation is often automatable by a compiler or parser generator.
- **New ways to interpret an expression** are easy to add — pretty-printing, type-checking — by defining a new operation on the expression classes.

**Liabilities**
- **Complex grammars are hard to maintain.** At least one class per rule (BNF rules may need several); many rules become unmanageable. When the grammar is very complex, use a parser or compiler generator instead.
- Direct tree interpretation is rarely the fastest execution strategy.

## Implementation Notes
- **Creating the abstract syntax tree**: the pattern does *not* address parsing. The AST can come from a table-driven parser, a hand-written recursive-descent parser, or be built directly by the client.
- **Defining the Interpret operation**: it need not live in the expression classes. If new interpreters are added often — type-checking, optimization, code generation on a programming-language grammar — put `Interpret` in a **Visitor** instead so grammar classes stay untouched.
- **Sharing terminal symbols with Flyweight**: sentences often repeat a terminal many times (every occurrence of a program variable, every `dog` literal). Terminal nodes don't store their position in the tree — parents pass whatever context is needed — so the shared/intrinsic vs. passed-in/extrinsic split of **Flyweight** applies directly.
- Interpreter shares most implementation issues with **Composite**, since the AST *is* a Composite.

## Worked Example
**Regular expression matcher (Smalltalk).** Grammar: `expression ::= literal | alternation | sequence | repetition | '(' expression ')'`. Five classes — `RegularExpression` plus `LiteralExpression`, `AlternationExpression` (two alternatives), `SequenceExpression` (two children), `RepetitionExpression` (one child). The AST for `raining & (dogs | cats) *` is built from these instances.

`match: inputState` takes the current matching state — a *set* of input streams representing every prefix the expression could have accepted so far, roughly the set of states an equivalent finite automaton would occupy. `SequenceExpression` matches subexpressions in order (usually shrinking the set); `AlternationExpression` returns the union of both alternatives' states; `RepetitionExpression` grows the set to cover one, two, or many repeats, letting later elements pick the viable stream; `LiteralExpression` is the only one that advances the stream, and it returns a *copy* so each alternation branch sees an identical stream.

```smalltalk
AlternationExpression>>match: inputState
    ^ (alternative1 match: inputState) addAll: (alternative2 match: inputState); yourself

RepetitionExpression>>match: inputState
    | aState |
    aState := inputState.
    [aState isEmpty] whileFalse: [
        aState := repetition match: aState.
        inputState addAll: aState].
    ^ inputState
```

Rather than write a parser, define `&`, `|`, and `repeat` as operations on `RegularExpression` (and `asRExp` on `String`), so evaluating the Smalltalk expression `('dog ' | 'cat ') repeat & 'weather'` *is* the AST construction — the Smalltalk compiler serves as the parser.

**Boolean expressions (C++).** `BooleanExp` declares `Evaluate(Context&)`, `Replace(const char*, BooleanExp&)`, and `Copy()`. `VariableExp` is terminal; `AndExp`, `OrExp`, `NotExp` are nonterminal.

```cpp
bool AndExp::Evaluate (Context& aContext) {
    return _operand1->Evaluate(aContext) && _operand2->Evaluate(aContext);
}

BooleanExp* AndExp::Replace (const char* name, BooleanExp& exp) {
    return new AndExp(_operand1->Replace(name, exp),
                      _operand2->Replace(name, exp));
}
```

The key lesson: `Evaluate`, `Replace`, and even `Copy` are all interpreters — `Replace`'s "context" is the variable name plus its replacement, and its result is a new expression. What makes a Composite hierarchy an *Interpreter* is perspective: you must think of the hierarchy as representing a language. Nobody calls `Weight` on an automotive-parts Composite an interpreter — until someone publishes a grammar of automotive parts.

## Anti-patterns & Smells
- **Using Interpreter for a large grammar**: dozens of node classes that a parser generator would have produced automatically. Switch tools.
- **Interpreting the tree directly in a hot path** where a compiled form (state machine, bytecode) is called for.
- **Piling new operations onto grammar classes** every time a new pass is added — refactor to Visitor before the classes become dumping grounds.
- **Confusing parsing with interpreting**: the pattern says nothing about how to build the AST; a missing parser strategy is a real design gap.
- **Instantiating a fresh terminal node per occurrence** in a large sentence, when Flyweight sharing would collapse them.

## Known Uses
- Compilers written in object-oriented languages, notably the **Smalltalk compilers**.
- **SPECTalk** interprets descriptions of input file formats.
- **QOCA** constraint-solving toolkit evaluates constraints with it.
- Nearly every use of **Composite** contains Interpreter in its most general form — but reserve the name for hierarchies you genuinely think of as a language.

## Related Patterns
- **Composite**: the abstract syntax tree is an instance of Composite.
- **Flyweight**: shares terminal symbols within the AST.
- **Iterator**: the interpreter can use one to traverse the structure.
- **Visitor**: keeps the behavior for every node type in one class, avoiding edits to grammar classes when new interpretations are added.

## Key Takeaways
1. One class per grammar rule, right-hand-side symbols as members — that's the whole mapping.
2. Keep it for small, stable grammars; reach for a parser generator once rule count climbs.
3. Put shared interpreter state in a Context object, not in the nodes.
4. If you keep adding interpretations, move `Interpret` into a Visitor; if terminals repeat, make them Flyweights.
