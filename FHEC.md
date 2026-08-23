# fhec fork of solar

This is [toml01/solar](https://github.com/toml01/solar), a thin fork of
[paradigmxyz/solar](https://github.com/paradigmxyz/solar) used by
[fhec](https://github.com/toml01/fhec).

- **Base:** tag `v0.2.0` (`a1f81d071a85b2f6c36cd67fb2fd9d4503477169`)
- **Branch:** `fhec` (default)
- **Compare:** https://github.com/paradigmxyz/solar/compare/v0.2.0...toml01:solar:fhec

## Delta

One dialect extension (`.fsol` spec §2.3): optional `in` before a parameter type
(`in euint32 amount`) is parsed and recorded as `VariableDefinition.in_sugar`.
Legality is checked by fhec, not this parser. `in` is a reserved Solidity
keyword, so plain Solidity is unchanged.

Touched files:

- `crates/ast/src/ast/item.rs`
- `crates/ast/src/ast/mod.rs`
- `crates/ast/src/visit.rs`
- `crates/parse/src/parser/item.rs`

## Syncing upstream

```console
git fetch origin
git merge vX.Y.Z
# resolve the four files above if needed
```

Then bump the `rev` pins in [toml01/fhec](https://github.com/toml01/fhec).
