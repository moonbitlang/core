# Review: moonbitlang/core/set

**File:** `set/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:27.579Z  
**Status:** ✓ Success

---

**Assessment**
- Method set in `set/pkg.generated.mbti:9-41` looks cohesive: it covers core mutating and set-algebra operations plus conversions, mirroring what users expect from a standard set.
- Free-function constructors (`from_array`, `from_iter`, `new`, `of`) at `set/pkg.generated.mbti:19-36` give flexible creation paths without overloading the main type.
- Trait impl coverage at `set/pkg.generated.mbti:42-49` is rich (bitwise ops, `Eq`, `Show`, `Default`, `ToJson`), so the type composes well with the wider ecosystem.

**Issues**
- `Set::eachi` at `set/pkg.generated.mbti:18` exposes an index even though set iteration is typically unordered; without a documented ordering guarantee the index may mislead users into assuming determinism.
- The alias annotation `#alias(size, deprecated)` on `Set::length` at `set/pkg.generated.mbti:31-32` surfaces only the deprecated name to interface consumers, which makes it unclear whether `length` or `size` is the preferred, non-deprecated entry point.

**Suggestions**
- Consider clarifying `Set::eachi`’s index semantics (e.g., document that the index is arbitrary or remove the index if it has no semantic meaning).
- Adjust the alias so that the non-deprecated `length` name is the primary symbol exposed in the generated interface, leaving `size` as the hidden deprecated alias.
