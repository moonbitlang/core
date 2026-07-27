This is the standard library for [MoonBit](docs.moonbitlang.com).

# Refactoring tips

- MoonBit code is organized in block style, each block is separated by `///|`,
the order of each block is irrelevant. In some refactorings, you can process
block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt`  in each directory.

- `moon fmt` is used to format your code properly.

- `moon info` is used to update the generated interface of the package, each package
has a generated interface file `.mbti`, it is a brief formal description of the package. 
If nothing in `.mbti` changes, this means your change does not bring the visible changes to the external package users, 
it is typically a safe refactoring.

- So in the last step, you typically run `moon info && moon fmt` to update the interface and format the code. You also
check the diffs of `.mbti` file to see if the changes are expected.

- You should run `moon test` to check the test is passed. MoonBit supports snapshot testing, so in some cases,
your changes indeed change the behavior of the code, you should run `moon test --update` to update the snapshot.

- You can run `moon check` to check the code is linted correctly.

- MoonBit packages are organized per directory, for each directory, there is a `package.json` file listing its dependencies.
Each package has its files and blackbox test files (common, ending in `_test.mbt`) and whitebox test files (ending in `_wbtest.mbt`).

- In the toplevel directory, this is a `moon.mod.json` file listing about the module and some meta information.

- When writing tests, you are encouraged to use `inspect` and run `moon test --update` to update the snapshots, only use assertions
  like `assert_eq` when you are in some loops where each snapshot may vary. You can use `moon coverage analyze > uncovered.log` to see which parts of your code are not covered by tests.

- agent-todo.md has some small tasks that are easy for AI to pick up, agent is welcome to finish the tasks and check the box when you are done

# Trait-method promotion (`extend`)

When a type `impl`s a trait, the trait's methods can be *promoted* to inherent
methods (`x.method(..)`) via an explicit `pub extend` block in the package's
`extends.mbt`. The rule for what we promote vs. deprecate
(`#deprecated(.., skip_current_package=true)` + `#doc(hidden)`) is driven by
**where the trait lives** — because promoting a method couples the type's
package to the trait's package:

- **Traits whose home is `builtin`** (`Add`…`Sub`, `Compare`, `Eq`, `Hash`,
  `Show`, `Default`, `Logger`, `ToStringView`): every package already depends on
  `builtin`, so promoting them creates **no cycle** — safe on any type.
- **Traits whose home is a higher package** (`@json.FromJson`,
  `@quickcheck.Arbitrary`, `@debug.Debug`): promoting them on a lower-level type
  would form a cycle (`builtin → json` etc.), so they are **never promoted** —
  always use the free function (`@json.from_json`, `@quickcheck.…`,
  `@debug.Debug`).

This is about the trait's *logical* home, not the file it currently sits in:
**`ToJson` lives in `builtin` today only for bootstrapping but belongs in
`@json`**, so it is treated as a higher-package trait (not promoted) — promoting
it would have to be ripped out the day it moves.

Within the "safe to promote" set:

- **Operators** (`add`, `sub`, `mul`, `div`, `mod`, `neg`, `land`, `lor`, `lxor`,
  `shl`, `shr`): promoted on every type — the named method is a first-class value
  the operator syntax can't give you.
- **`Compare::compare`, `Eq::equal`, `Hash::hash`**: promoted **uniformly on
  every type** that impls them (they're all in `builtin`, no cycle, and it keeps
  the surface uniform). Exactly **one** method per trait is promoted — the
  user-facing primary one. Its *derivatives* stay deprecated:
  - `Compare::{op_lt, op_le, op_ge, op_gt}` → use `<` `<=` `>=` `>`
  - `Eq::not_equal` → use `!=`
  - `Hash::hash_combine` → implementer-facing, use it via the trait

  (`compare` and `equal` are still worth promoting even though `<` and `==`
  exist, because they're the *required* trait methods and the only way to pass
  the operation as a first-class value — e.g. `Int::equal` into a fold. The
  derivatives above are defaulted members that add nothing over the operator.)

  **Tuples** get the same promotions but with `#doc(hidden)` (the synthetic
  `Tuple(N)::…` names are ugly in the interface; the methods still work without
  a warning).
- **`Show::to_string`**: promoted only for types with a **canonical string
  representation** (scalars, strings). Collections deprecate it toward
  `@debug.Debug` (there's no single canonical `Show` for a collection).
  `Show::output` is never promoted (use `to_string` / `"\{x}"`).
- **`Default::default`**: **deprecated** — a literal (`0`, `[]`, `None`, `""`,
  `b'\x00'`) or `Default::default()` via the trait bound is clearer, and it keeps
  the interface lean. (Exception: `Byte::default()` is kept promoted **for now** —
  Moon's generated test drivers call `FixedArray::make(512, Byte::default())`, so
  deprecating it breaks `moon test --build-only --deny-warn`. moonbitlang/moon#1938
  removes that call; deprecate `Byte` like the rest once a moon release ships.)
- **`ToJson::to_json`**: **not promoted** — use **`Json(x)`**, the constructor of
  `Json` (re-exported by the prelude, so it needs no import and works from every
  package, `builtin` included). Between that and `Json`'s literal sugar
  (`([x, y] : Json)`, `({ "k": v } : Json)`) you rarely need `x.to_json()` at
  all, and serialization is cold, so nothing is lost by going through the
  constructor. Because `Json(x)` is spelled the same regardless of which package
  `Json` lives in, moving `Json`/`ToJson` to `@json` later would not churn call
  sites — exactly how `to_repr(x)` is spelled the same though `Debug`/`Repr` live
  in `@debug`.

This policy governs a package's own `extends.mbt` (its public API surface).

**Test fixtures should be `priv`.** A type declared in a `_test.mbt` file with no
visibility modifier is *abstract-public*, so `implicit_impl_as_method` fires for
its derived impls and you end up writing `pub extend` ceremony that has nothing
to do with the test. Declare such types `priv` instead — then they need no
`extend` at all. If a test needs to call a promoted method on one, use the trait
form (`ToJson::to_json(x)`, `Default::default()`).

After editing `extends.mbt`, run `moon info && moon fmt` and check the `.mbti`
diff. `#doc(hidden)` alone (no `#deprecated`) keeps a promotion working but hides
it from the generated interface — that's how tuples stay usable but tidy.
