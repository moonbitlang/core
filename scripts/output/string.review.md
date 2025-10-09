# Review: moonbitlang/core/string

**File:** `string/pkg.generated.mbti`  
**Date:** 2025-10-09T10:02:22.765Z  
**Status:** ✓ Success

---

**Findings**
- `string/pkg.generated.mbti:26-27` + `string/pkg.generated.mbti:80-81`: Exposing both `get` (returning `Int?`) and `get_char` (returning `Char?`) on `String`/`StringView` without clear naming makes it hard to tell when callers receive a Unicode scalar code vs. an actual `Char`. The overlap invites misuse; consider renaming (`get_charcode`) or clarifying docs.
- `string/pkg.generated.mbti:57-62`: All `String::trim*` helpers yield `StringView`, whereas most other transforming APIs on `String` (e.g., `replace`, `pad_*`, `repeat`) return an owned `String`. The mixed ownership story is surprising and can lead to accidental borrowing of short-lived temporaries unless the view semantics are very prominent.
- `string/pkg.generated.mbti:95`: `StringView::repeat` returns `Self`, while other allocating operations on `StringView` (`pad_*`, `replace`, etc.) return `String`. If `repeat` allocates, returning a view is inconsistent; if it doesn’t allocate, it’s unclear how the repetition is represented. The contract needs clarification or alignment.

**Assessment**
- Broad, coherent coverage of searching, iteration, slicing, and mutation-like helpers across both `String` and `StringView`.
- Alias annotations and the `ToStringView` trait make migration paths and conversions discoverable.

**Suggestions**
1. Harmonize the char-access APIs—either collapse to one canonical name or document the differing return types explicitly.
2. Consider offering owned variants (`trim_owned`) or tightening docs so developers know `trim*` keeps borrowing the original storage.
3. Align `StringView::repeat`’s return type with other allocating helpers (most likely `String`) or document how it safely returns a view.
