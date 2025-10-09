# Review: moonbitlang/core/immut/internal/path

**File:** `immut/internal/path/pkg.generated.mbti`  
**Date:** 2025-10-09T09:58:43.201Z  
**Status:** ✓ Success

---

**Findings**
- immut/internal/path/pkg.generated.mbti:11 – `Path::idx` exposes the index as `Int` even though the underlying storage is `UInt`; the implicit narrowing risks overflow/negative values and makes the API inconsistent.
- immut/internal/path/pkg.generated.mbti:16 – `Path::push` accepts `Int` while the path state is `UInt`; the mismatch invites accidental negative inputs and suggests callers convert manually.
- immut/internal/path/pkg.generated.mbti:12 – `Path::inner` remains publicly accessible despite being deprecated, but there is no visible replacement, so external callers may keep relying on it.

**Assessment**
- API surface is very small and focused, but several signatures expose inconsistent integer types and the deprecation lacks a clear migration path.

**Open Questions**
- Should `Path` indexes always be non-negative/fit in `UInt`, or is `Int` truly required for external interoperability?

**Suggestions**
1. Align index-related parameters/returns (`idx`, `push`) with `UInt` (or introduce explicit conversion helpers) so callers don’t juggle signed/unsigned mismatches.
2. Provide a non-deprecated accessor or constructor that replaces `inner`, or fully gate it behind internal visibility to discourage continued external use.
