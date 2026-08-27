# fhec fork of solar

This is [toml01/solar](https://github.com/toml01/solar), a thin fork of
[paradigmxyz/solar](https://github.com/paradigmxyz/solar) used by
[fhec](https://github.com/toml01/fhec).

- **Base:** tag `v0.2.0` (`a1f81d071a85b2f6c36cd67fb2fd9d4503477169`)
- **Branch:** `fhec` (default)
- **Compare:** https://github.com/paradigmxyz/solar/compare/v0.2.0...toml01:solar:fhec

## Delta

Four dialect extensions. In all of them, this parser only recognizes and
records the construct; legality is checked by fhec, not here.

### `in` parameter sugar (`.fsol` spec §2.3)

An optional `in` before a parameter type (`in euint32 amount`) is parsed and
recorded as `VariableDefinition.in_sugar`. `in` is a reserved Solidity keyword,
so plain Solidity is unchanged.

Touched files:

- `crates/ast/src/ast/item.rs`
- `crates/ast/src/ast/mod.rs`
- `crates/ast/src/visit.rs`
- `crates/parse/src/parser/item.rs`
- `crates/sema/src/ast_lowering/lower.rs`

### `in(proof)` explicit proof binder

The `in` marker takes an optional parenthesized identifier that names the proof
parameter of the same list:

```text
in euint32 amount               // implicit: the binder is absent
in(inputProof) euint32 amount   // explicit: the binder is `inputProof`
```

`VariableDefinition.in_sugar` is `Option<InSugar>`:

```rust
pub struct InSugar {
    /// `in`, or `in` through the closing `)`.
    pub span: Span,
    /// The `in` keyword alone. Equal to `span` in the implicit form.
    pub kw_span: Span,
    /// The bound identifier, if the explicit form was used.
    pub proof: Option<Ident>,
}
```

A struct, not two flat fields, because the two spans and the binder are one
marker: `Some` means "sugared", and the binder can only exist inside it. The
fork's own code reads `in_sugar` in four places, all of which ignore it, so the
change costs nothing here. `InSugar::is_explicit()` is the presence test.

`VariableDefinition` grows from 88 to 104 bytes: `InSugar` is 28, and `Span` has
no niche, so `Option<InSugar>` costs 32 instead of the 16 of the old
`Option<Span>`. Both numbers are asserted in `crates/ast/src/ast/mod.rs`.

The marker ends before the type, so `var.span.with_hi(var.ty.span.lo())` is the
text fhec strips, the same shape the `precondition` marker uses.

The binder is parsed from tokens, so whitespace and comments are free:
`in (inputProof)` and `in /* p */ (inputProof)` are the same as `in(inputProof)`.
This is safe because no Solidity type starts with `(`, so the paren after `in`
has exactly one reading. Unlike `precondition`, there is nothing to be lenient
about: once the reserved `in` keyword is eaten, a `(` must be a binder. A
malformed binder (`in()`, `in(123)`, `in(a, b)`, an unterminated `in(a`) is a
hard parse error, not a silent fall back to the implicit form.

The parser accepts the binder wherever the `in` sugar is accepted, which is
function, error and event parameter lists (`VarFlags::IN_SUGAR`). Whether the
binder names a `bytes memory|calldata` parameter of the same list, and whether
the implicit and explicit forms are illegally mixed, is fhec's job. The AST
visitor deliberately does not visit the bound identifier: it is resolved by fhec
against the parameter list, not by this crate's name resolution.

Touched files:

- `crates/ast/src/ast/item.rs`
- `crates/ast/src/ast/mod.rs`
- `crates/ast/src/visit.rs`
- `crates/parse/src/parser/item.rs`
- `tests/ui/parser/in_sugar.sol`
- `tests/ui/stats/ast.stderr`

### `shared` boundary marker

The shared boundary has two forms, both of which mark a declaration:

```text
in shared euint64 amount            // form A, input side
shared(msg.sender) euint64          // form B, output side
```

Both are recorded on the same new field, `VariableDefinition.shared`:

```rust
pub struct Shared<'ast> {
    /// `shared`, or `shared` through the closing `)`.
    pub span: Span,
    /// The recipient expression, if form B was used.
    pub recipient: Option<Box<'ast, Expr<'ast>>>,
}
```

`recipient` tells the two forms apart; `Shared::has_recipient()` is the presence
test. Form A also sets `in_sugar`, since it can only follow `in`; form B does
not, since it carries no `in` keyword. The two compose: `in shared(a) euint64 x`
sets both, and fhec decides whether that is legal.

`shared` is a contextual keyword, not a reserved word, so it is only read as a
marker where plain Solidity has no other reading:

- Form A needs the reserved `in` in front of it. Nothing in plain Solidity may
  follow `in` in a declaration. Without `in`, a bare `shared` is left alone:
  `shared x;` stays a declaration of type `shared`.
- Form B needs the `(` right after it. `ident(...)` is never a `TypeName`, so a
  type position that starts with `shared(` has one reading.

Both checks peek with `Token::is_keyword`, which pushes no expectation, so parse
errors for plain Solidity are unchanged. `uint256 shared;`,
`function shared() {}`, `x.shared()` and a parameter named `shared` all parse as
before.

Once `shared(` is seen the construct is committed to, like the `in(proof)`
binder: exactly one recipient expression is required, and `shared()`,
`shared(a, b)` or an unterminated `shared(a` is a hard parse error. Any
expression is accepted as a recipient; which ones are valid is fhec's job.

Form A is gated by `VarFlags::IN_SUGAR`, so it parses wherever the `in` sugar
does. Form B is gated by a new `VarFlags::SHARED`, set on function, error and
event parameter lists (and therefore on `returns` lists, which share the flags)
and on state variable declarations.

Unlike the `in(proof)` binder, the AST visitor *does* walk the recipient: it is
an ordinary expression, not a name resolved against the parameter list.

`VariableDefinition` grows from 104 to 128 bytes. `Shared` is 16, and it spends
the box's niche on its own `Option`, so `Option<Shared>` costs 24. `ItemKind`
and `Item` grow with it, to 152 and 168. All are asserted in
`crates/ast/src/ast/mod.rs`.

Touched files:

- `crates/ast/src/ast/item.rs`
- `crates/ast/src/ast/mod.rs`
- `crates/ast/src/visit.rs`
- `crates/interface/src/symbol.rs`
- `crates/parse/src/parser/item.rs`
- `crates/sema/src/ast_lowering/lower.rs`
- `tests/ui/parser/shared.sol`
- `tests/ui/stats/ast.stderr`

### `precondition` block

`precondition { ... }` is parsed as `StmtKind::Precondition(Block)`. The
enclosing `Stmt.span` starts at the keyword; the inner `Block.span` covers only
`{ ... }`, so `stmt.span.with_hi(block.span.lo())` is the marker that fhec
strips.

`precondition` is a contextual keyword, not a reserved word: the parser only
recognizes it when the identifier is immediately followed by a `{` that opens a
block. It also pushes no parse expectation, so error messages for plain Solidity
are unchanged.

One plain Solidity statement does start with `identifier {`: a call with
options, `f{gas: g, value: v}(...)`. The parser looks past the `{` before it
commits to a block:

- `{ ident :` opens a call-options list. Solidity has no statement labels, so an
  identifier followed by `:` never starts a statement. This is the same
  lookahead that `parse_lhs_expr` uses for `expr{...}`.
- `{}` is ambiguous. `{}(` is read as a call with an empty options list, because
  a precondition block is never called. `solc` rejects empty call options, so
  `precondition{}()` gets the same error as `other{}()`. A `{}` that is not
  called is an empty precondition block.

Everything else is a block. When the lookahead declines, parsing falls through
to an ordinary expression statement, so `precondition` parses exactly like any
other identifier.

The parser accepts the block in every statement position. First-statement-only
and at-most-one-per-body rules are fhec's, not this parser's. Semantic analysis
lowers the block to an ordinary `hir::StmtKind::Block`.

Touched files:

- `crates/ast/src/ast/stmt.rs`
- `crates/ast/src/visit.rs`
- `crates/interface/src/symbol.rs`
- `crates/parse/src/parser/stmt.rs`
- `crates/sema/src/ast_lowering/resolve.rs`
- `crates/sema/src/stats/ast.rs`
- `tests/ui/parser/precondition.sol`

## Syncing upstream

```console
git fetch origin
git merge vX.Y.Z
# resolve the files listed above if needed
```

Then bump the `rev` pins in [toml01/fhec](https://github.com/toml01/fhec).
