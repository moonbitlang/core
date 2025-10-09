# Review: moonbitlang/core/builtin

**File:** `builtin/pkg.generated.mbti`  
**Date:** 2025-10-09T09:59:18.924Z  
**Status:** ✓ Success

---

**Assessment**
- Interface offers comprehensive core facilities (errors, collections, numerics, traits) and keeps deprecation markers visible, giving consumers a clear view of the stable vs. legacy surface.

**Issues**
- `ArgsLoc::to_json` returns `String` rather than `Json`, which breaks the convention established by every other `*_::to_json` helper and risks confusion with the `ToJson` trait (`builtin/pkg.generated.mbti:68`).
- `Default` trait impls cover `Bool`, integral types, `Double`, and `FixedArray`, but skip peers such as `Float` and `UInt`, creating an inconsistent numeric story (contrast `builtin/pkg.generated.mbti:819-826`).

**Suggestions**
- Adjust `ArgsLoc::to_json` to return `Json` (or rename it to clarify it produces a textual representation) so the helper aligns with the rest of the package.
- Either add `Default` impls for `Float`/`UInt` (and other obvious types) or document why they are intentionally missing to avoid surprises for users expecting parity with `Double` and signed integers.
