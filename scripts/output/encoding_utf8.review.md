# Review: moonbitlang/core/encoding/utf8

**File:** `encoding/utf8/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:43.757Z  
**Status:** ✓ Success

---

**API Review**
- decode/decode_lossy/encode cover the minimal UTF-8 roundtrip; explicit `ignore_bom?`/`bom?` flags give callers control over BOM handling while keeping defaults straightforward.
- Exposing a dedicated `Malformed BytesView` error type is clear and keeps malformed input diagnostics specific to UTF-8.

**Potential Issues**
- `decode` raises `Malformed` but the signature does not indicate what part of decoding failed—consider surfacing offset information or clarifying error semantics in docs (`encoding/utf8/pkg.generated.mbti`).
- `decode_lossy` silently drops errors; if it substitutes replacement characters, that policy should be documented or surfaced via an enum/strategy parameter.

**Suggestions**
- Document default behavior of the optional BOM flags and whether BOMs are stripped by default.
- Evaluate whether `Malformed` should expose more context (e.g., byte index) or whether additional helper APIs (peek BOM, validate only) would improve usability.
