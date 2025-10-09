# Review: moonbitlang/core/strconv

**File:** `strconv/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:16.819Z  
**Status:** ✓ Success

---

**API Review**
- Balanced surface: covers primitives plus a generic `parse` (`strconv/pkg.generated.mbti:5`); `StrConvError` is coherently exposed with `Show`.
- Deprecated Decimal block is still exposed but every constructor/helper is deprecated (`strconv/pkg.generated.mbti:21`), leaving an odd partially supported type.

Potential issues & inconsistencies
- Mixed input types: most `parse_*` take `StringView`, but `parse` and `FromStr::from_string` use `String`, which may force unnecessary allocations or conversions (`strconv/pkg.generated.mbti:5`, `strconv/pkg.generated.mbti:36`).
- `Decimal` itself isn’t marked `#deprecated` even though every associated function is, so consumers may not realize the whole type is legacy (`strconv/pkg.generated.mbti:21`).
- `Decimal::shift(Self, Int) -> Unit` suggests mutation on a value parameter; without a reference type this likely discards the updated value, making the API hard to use (`strconv/pkg.generated.mbti:27`).

Suggestions
- 1) Align string inputs on either `StringView` or `String` (ideally `StringView`) across the API, including `FromStr::from_string`.
- 2) Deprecate the `Decimal` type itself or provide a non-deprecated alternative, clarifying migration paths.
- 3) Revisit `Decimal::shift`; return the shifted `Decimal` (or mutate via `&mut`-style API if available) to avoid no-op semantics.
