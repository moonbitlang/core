# Review: moonbitlang/core/string/regex

**File:** `string/regex/pkg.generated.mbti`  
**Date:** 2025-10-09T10:01:37.257Z  
**Status:** ✓ Success

---

API feels intentionally minimal: `compile` produces a reusable `Regex`, and `MatchResult` exposes the matched slice plus surrounding context and capture lookups. That should cover the common “compile once, execute many times” workflow.

Potential issues:
- `MatchResult::named_group(Self, String)` accepts `String` while every other argument is a `StringView`. That mismatch could lead to needless allocations or call-site friction.
- `compile` is marked `raise`, but the interface doesn’t clarify what error type(s) appear. Consumers can’t pattern-match specific failures.
- Only a single-match `Regex::execute` is exposed; if multi-match iteration exists elsewhere, it isn’t visible here.

Improvements to consider:
1. Align argument types (`StringView` vs `String`) across the API to avoid surprises.
2. Document or expose a concrete error type for `compile`, or return a `Result` so callers can handle failures predictably.
3. If supported, expose an iterator-style search (e.g., `find_all` or `next_match`) so users don’t have to re-slice strings manually.
