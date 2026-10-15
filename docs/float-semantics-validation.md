# Validation of lawful floating comparisons

The implementation requires the paired compiler and core. Tests were run on
macOS 15.7.9 / arm64 using a compiler built from the companion change.
Fresh target directories avoid reusing outputs from earlier compiler builds
that had the same development version string.

## Automated checks

- Full core debug suite on Wasm, Wasm GC, JS, and native: the only failures were
  the same 13 debug-formatting snapshots on each backend. All 13 also reproduce
  on unchanged core with this compiler checkout; they are not accepted snapshot
  changes in this PR.
- Focused release suite (`builtin`, `float`, `math`, `range`, `v128`,
  `sorted_map`, `list`): 3931/3931 Wasm, 3925/3925 Wasm GC, 3889/3889 JS,
  3881/3881 native passed before the final added first-class-call and native
  trigonometric probe. Those additions and the reviewed numerical
  fixes then passed a targeted release rerun: 441/441 Wasm, 441/441 Wasm GC,
  437/437 JS, 435/435 native (including the temporary native probe).
- Final targeted debug rerun after the review fixes: 441/441 Wasm,
  441/441 Wasm GC, 437/437 JS, and 434/434 native passed. The temporary
  architecture-specific probe is excluded from the committed test suite.
- `moon check --target all` completed with zero errors; `moon info` and
  `moon fmt` completed. Existing deprecation warnings remain.
- Compiler: full `dune build`, floating-semantics unit tests, Wasm GC backend
  suite, OCaml formatting, and Semgrep (35 rules, zero findings).
- Core interfaces add only the six explicit IEEE predicates per width.

The public PR's stable-toolchain CI uses compiler `943464bfa`, which lacks the
companion change and rejects the binary32 comparison constant regression.
That CI requires the paired compiler before it can validate this core. Its
first run also exposed a deprecated inspection helper in the new sorted-map
assertion; that assertion now inspects the retrieved scalar value.

Tests cover both widths, quiet/signaling and signed NaN encodings, signed zeros,
subnormals, finite extremes, infinities, deterministic random bit patterns,
Eq/Compare/Hash laws, direct/generic/derived/first-class calls, constants,
patterns, sorting/searching, and floating map keys. Numerical and SIMD tests
verify that unordered IEEE operations remain available and are used where
required by the existing algorithms.

## Independent review

A fresh Codex CLI `gpt-6-astra` session at `ultra` reviewed both repositories.
The review identified additional numerical NaN paths, late constant-pattern
folding, a mistaken payload expectation, mixed-toolchain documentation, and
missing successful-equality benchmark inputs. These were corrected. A focused
follow-up reported no remaining actionable correctness issue in the fixes.
The reviews inspected source; execution validation was performed separately as
listed above. Benchmark output is retained in [the performance report](float-semantics-benchmarks.md).

## Existing limitations observed during this work

The unchanged native release compiler also folds `(1.0 / -0.0).is_neg_inf()`
incorrectly in the baseline probe. This PR does not change arithmetic or fix
that separate issue; its signed-zero arithmetic regression uses runtime values.
Float pattern analysis also has a pre-existing distinction between unrounded
literal spellings that round to the same binary32 value. Neither issue should
be confused with the intended NaN equality/ordering change.

NaN payload propagation through arithmetic is backend-specific. A temporary
native `asin`/`acos` probe recorded unchanged-core results on this host and
confirmed that the corrected implementation preserves them. The host-specific
bit snapshots are not imposed on other native architectures by the test suite
and do not establish a portable NaN-payload guarantee.
