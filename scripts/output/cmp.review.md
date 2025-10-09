# Review: moonbitlang/core/cmp

**File:** `cmp/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:19.673Z  
**Status:** ✓ Success

---

**API Notes**

- Public functions cover both direct comparisons and key-based comparisons for min/max, which is a clean surface; tuple result from `minmax` variants is intuitive, but the ordering (min first vs max first) should be documented somewhere user-facing to avoid ambiguity.  
- Key-based overloads require both operands plus a key function; consider clarifying tie-breaking behavior when keys compare equal.

**Issues / Inconsistencies**

- `Reverse::inner` remains exposed (though deprecated); having a deprecated accessor without pointing to the preferred replacement can confuse users relying on the generated interface alone.  
- `Reverse[T]` wraps a value but gives no hint about its construction or intended usage in the public surface—if users are meant to construct it manually, a constructor (even implicit) should be evident, or otherwise mark the struct as opaque.

**Suggestions**

1. Add doc comments (or complementary docs) clarifying tuple ordering and tie resolution for the `minmax*` functions.  
2. Either remove the deprecated `Reverse::inner` from the interface once callers have migrated, or document the alternative explicitly; if the type should remain transparent, provide a non-deprecated accessor.  
3. Consider exposing an obvious constructor/helper for `Reverse[T]` so users don’t rely on struct internals, or make the struct opaque if manual construction is discouraged.
