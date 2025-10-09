# Review: moonbitlang/core/char

**File:** `char/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:23.686Z  
**Status:** ✓ Success

---

**API Review**
- The surface mirrors familiar `Char` classification helpers (ASCII filters, Unicode-aware checks, hash/show/json impls), so discoverability should be good for users coming from Rust-like ecosystems.

**Findings**
- char/pkg.generated.mbti: `Char::utf16_len` returns `Int`, even though the result is logically bounded to 1 or 2; using a signed type is slightly inconsistent with the rest of the API and invites negative values in user code.

**Suggestions**
- 1. Consider switching `utf16_len` to return an unsigned width (`UInt`) or a dedicated enum to emphasize the constrained range.
- 2. If broader Unicode casing is supported elsewhere, exposing `to_lowercase`/`to_uppercase` counterparts (even if they return sequences) would round out the API; otherwise document that only ASCII case conversions are offered.
