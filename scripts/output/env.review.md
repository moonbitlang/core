# Review: moonbitlang/core/env

**File:** `env/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:54.830Z  
**Status:** ✓ Success

---

**Findings**
- Major — `env/pkg.generated.mbti:9` — `now()` exposes raw `UInt64` without documenting epoch/units; callers must infer semantics and risk misinterpreting wall-clock vs monotonic time.
- Minor — `env/pkg.generated.mbti:7` — `current_dir()` returns `String?`, but no hint of failure modes or how to detect/diagnose errors; a `Result[String, Error]` (or documented `None` cases) would be clearer.

**Assessment**
- Very small surface; names are intuitive, but the lack of type safety or documentation around environment-dependent behavior makes the API easy to misuse.

**Suggestions**
- Document observable behavior (arg ordering, inclusion of program name, guarantees for absence of CWD, timestamp origin).
- Prefer stronger typing: introduce a `Timestamp` alias/struct (with epoch/unit info) and consider `Result`-style errors instead of bare optionals where diagnostics matter.
