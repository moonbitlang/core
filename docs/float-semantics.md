# Lawful floating-point equality, ordering, and hashing

## Contract

`Float` and `Double` keep their binary32/binary64 representation and arithmetic.
Their `Eq`, `Compare`, relational operators, and `Hash` use these rules:

| Values | Equality | Ordering | Hash input |
| --- | --- | --- | --- |
| Ordinary numbers and infinities | Numerical equality | Numerical order | Original bits |
| `-0` and `+0` | Equal | Same position | Positive-zero bits |
| Any two NaNs | Equal, regardless of sign/payload | Same position, after positive infinity | One quiet-NaN bit pattern per width |

For all values, `a == b` iff `a.compare(b) == 0`; each relational operator
agrees with the sign of `compare`; equal values hash equally. This applies to
direct calls, generic calls, first-class methods, and derived traits.

This is a total order on equality classes, not IEEE `totalOrder`, which can
distinguish signed zeros and NaN encodings. The underlying bits are not
canonicalized: reinterpretation, FFI, arithmetic, rounding, infinities,
underflow, and signed-zero results retain their existing behavior. Equality
does not imply that replacing one operand with another preserves arithmetic
bits: `1 / +0` and `1 / -0` still have different signs.

## Implementation and rollout

1. **Compiler prerequisite.** Stop hardcoding raw Float/Double comparison
   primitives at operator call sites. Resolve their trait implementations,
   as generic and first-class calls already do. Keep arithmetic specialization
   unchanged. Fold raw Double predicates with IEEE comparisons, not the host
   language's total-order comparison. Evaluate built-in comparison `const`
   expressions with the language order, rounding Float operands to binary32
   first. Make NaN constant patterns match all NaN encodings at runtime and
   during constant folding. The complete semantics require the matching core:
   old core retains raw runtime trait bodies, which would disagree with the
   compiler's new constant-expression and constant-pattern policy.
2. **Explicit numerical predicates.** Add `ieee_equal`, `ieee_not_equal`,
   `ieee_lt`, `ieee_le`, `ieee_gt`, and `ieee_ge` to both types. They preserve
   unordered NaN semantics and lower to the existing backend instructions.
3. **Core policy.** Build lawful `Eq` and `Compare` bodies from those predicates
   and NaN classification. Normalize only the hash input, never the value.
   Existing numerical values retain their hash input; NaNs now share one.
4. **Numerical migration.** Make `is_nan` independent of `!=`; retain numerical
   behavior in infinity classification, signum, clamp, approximate equality,
   saturating conversions, rounding, JSON, and floating ranges. Explicit SIMD
   comparisons and pseudo-min/max remain IEEE operations, with scalar fallback
   implementations and reference tests using the new predicates.
5. **Validation.** Test binary32 and binary64 payload/sign variants, signaling
   NaNs, zeros, subnormals, finite extremes, infinities, and deterministic random
   bits. Check reflexivity, transitivity, antisymmetry, all operators, derived
   traits, hash consistency, containers, constant folding, and arithmetic bits.
   Run debug and release tests across Wasm, Wasm GC, JS, and native.
6. **Release together.** Land the compiler prerequisite first, then distribute
   the compiler and this core as one toolchain release. Rebuild core artifacts
   and dependent modules with the matching toolchain. An older compiler can
   bypass the new trait bodies, and the new compiler with older core disagrees
   on constant comparisons, so either mixed combination is unsupported.
   No arithmetic/backend primitive format or ABI change is required.

## Source compatibility

This intentionally changes program behavior for NaN comparisons and container
keys. Replace `x != x` NaN checks with `x.is_nan()`. Use explicit IEEE predicates
when an algorithm needs unordered comparisons. Sorted collections now put NaNs
last and retain them as a distinct key; hash collections recognize all NaN
payloads as the same key. Sorting, searching, and derived tuple/struct comparisons
now agree with equality.

`min`, `max`, `clamp`, and `is_close` keep their numerical contracts rather than
being redefined as generic ordering utilities. `physical_equal` remains an
optimization hint with backend-dependent behavior, not an alternative `Eq`.
Custom `Eq`/`Compare` implementations remain responsible for their own laws.

## Performance evaluation

The benchmark source is `builtin/float_order_bench_test.mbt`. Each kernel
processes 4096 values, with finite-only and 1-in-16 NaN inputs. It measures
equality, less-than, comparison, and hashing at both widths, plus finite Double
sorting and map lookup. An arithmetic-only loop is a control.
Additional equality kernels cover equal finite values, paired NaNs, and mixed
successful/unsuccessful comparisons.

Run with `moon bench builtin/float_order_bench_test.mbt --target native --release`
(also `wasm-gc` and `js`). Compare the unchanged core and this branch with the
same patched compiler and identical harness. Alternate baseline/candidate order
between repetitions, avoid concurrent CPU-heavy work, retain raw output, and
report per-workload measurements rather than a universal slowdown. NaN-heavy
collection timings are deliberately omitted because the old and new contracts
produce different key sets and ordering. Results and environment are recorded
in `float-semantics-benchmarks.md`.
