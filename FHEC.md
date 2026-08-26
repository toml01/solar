# fhec fork of solar

This is [toml01/solar](https://github.com/toml01/solar), a thin fork of
[paradigmxyz/solar](https://github.com/paradigmxyz/solar) used by
[fhec](https://github.com/toml01/fhec).

- **Base:** tag `v0.2.0` (`a1f81d071a85b2f6c36cd67fb2fd9d4503477169`)
- **Branch:** `fhec` (default)
- **Compare:** https://github.com/paradigmxyz/solar/compare/v0.2.0...toml01:solar:fhec

## Delta

Two dialect extensions. In both, this parser only recognizes and records the
construct; legality is checked by fhec, not here.

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
