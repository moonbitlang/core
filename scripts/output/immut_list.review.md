# Review: moonbitlang/core/immut/list

**File:** `immut/list/pkg.generated.mbti`  
**Date:** 2025-10-09T09:58:59.436Z  
**Status:** ✓ Success

---

Most of the exposed surface in `immut/list/pkg.generated.mbti:1` is marked `#deprecated`, including every constructor, constructor-like helper, and nearly all instance methods, yet they remain publicly exported. That sends a confusing signal to downstream users because there is no obvious non-deprecated replacement.

Potential issues or inconsistencies:
- `default`/`from_array`/`from_iter`/`from_json` appear twice (as free functions and as `T::…` methods), all deprecated; it isn’t clear which form (if any) should still be used.
- `T::to_json`/`T::from_json` stay deprecated while the type still implements `ToJson`/`@json.FromJson`, so users get mixed messages about serialization support.
- Keeping the entire legacy surface exported makes it hard to rely on the enum alone without accidentally touching deprecated APIs.

Suggestions:
1. Either undeprecate the constructors and core list operations or split them into a legacy module so the default interface isn’t wall-to-wall deprecations.
2. If the goal is to replace this API, surface the intended successors (e.g., new module or iterators) and document migration guidance; otherwise prune the deprecated entries from the generated interface.
3. Consider collapsing the redundant free-function vs. method duplicates to a single canonical shape once the deprecation story is settled.

Natural next steps, if you want to pursue them:
1. Decide which functions to keep and move any legacy helpers into `deprecated.mbt`.
2. Regenerate the interface with `moon info` once the public surface is clarified.
