# Review: moonbitlang/core/rational

**File:** `rational/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:44.129Z  
**Status:** ✓ Success

---

- Heavily deprecated surface: Every exposed constructor and method in `rational/pkg.generated.mbti` is flagged `#deprecated`, so the public type `T` effectively lacks a stable way to be created or manipulated.
- Missing migration path: The interface doesn’t advertise replacement APIs, making it unclear how clients should build rationals or which new module supersedes this one.
- Mixed error conventions: `from_double` uses an error-raising result while `new` returns `T?`, hinting at inconsistent error-handling semantics that a replacement API should settle.

Suggestions:
1. Publish the intended replacement constructors/converters (e.g., `try_new`, `from_int`, `from_string`) and deprecate only after they land.
2. Document—or better, encode in types—the preferred error strategy so callers know whether to expect `raise` vs option.
3. If the package is truly retired, add a top-level note directing users to the successor module to prevent confusion.
