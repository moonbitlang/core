# Review: moonbitlang/core/string/regex/internal/unicode

**File:** `string/regex/internal/unicode/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:34.628Z  
**Status:** ✓ Success

---

**Findings**
- string/regex/internal/unicode/pkg.generated.mbti:9 High – `general_category_property_value_alises` is misspelled (`alises` vs `aliases`), so downstream users must rely on an incorrect identifier.
- string/regex/internal/unicode/pkg.generated.mbti:7 Medium – `case_folding : Map[Char, Char]` only supports single-codepoint folds; Unicode simple folds are fine, but full case folding and Turkic special cases need multi-codepoint targets, so the type may be too restrictive if broader folding is ever required.

**Assessment**
- Surface is minimal and consistent with an internal lookup module, exposing constants and lookup tables only. Using `Map` and `Array` keeps the interface simple but leaks implementation choices (e.g., arrays for ranges rather than structured pairs).

**Suggestions**
1. Rename `general_category_property_value_alises` to `general_category_property_value_aliases` and regenerate the interface.
2. If full Unicode support is a goal, consider changing `case_folding` to map to a sequence type (`String` or `Array[Char]`) and documenting whether only simple folds are provided.
