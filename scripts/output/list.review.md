# Review: moonbitlang/core/list

**File:** `list/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:07.495Z  
**Status:** ✓ Success

---

**Assessment**
- Coverage is broad: predicates, folds, zips, (un)folds, and trait impls give a complete immutable list API.
- Naming mostly matches community expectations (`map`, `filter`, `fold`, etc.), and `#as_free_fn` helpers support both static and functional styles.
- Deprecations are clearly tagged, signalling safer alternatives (`tail`, `rev_fold*`, `construct`).

**Issues**
- `List::findi` receives parameters as `(A, Int)` while every other indexed callback (`eachi`, `mapi`, `foldi`) uses `(Int, A)`; this inconsistency is surprising and error-prone (`list/pkg.generated.mbti:34`).
- `List::prepend` takes `(Self[A], A)` but is aliased as `add`, whereas `List::cons` (and the deprecated `construct`) take `(A, Self[A])`; conflicting argument order for the same concept invites mistakes (`list/pkg.generated.mbti:24`, `list/pkg.generated.mbti:70`).

**Suggestions**
- Flip `List::findi`’s callback signature to `(Int, A)` (or add an overload) so index-first conventions stay uniform across the API.
- Align head-insertion helpers: either deprecate `prepend` in favor of `cons`, or rename/reshape it so both functions share the same argument order and semantics.
