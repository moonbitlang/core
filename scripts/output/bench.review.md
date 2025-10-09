# Review: moonbitlang/core/bench

**File:** `bench/pkg.generated.mbti`  
**Date:** 2025-10-09T09:56:45.314Z  
**Status:** ✓ Success

---

**API Design**
- The surface centers on a mutable runner `T` with helper free functions, giving a simple entry point for ad‑hoc (`single_bench`) and aggregated (`T::bench`) runs (`bench/pkg.generated.mbti:5`, `bench/pkg.generated.mbti:11`).

**Issues**
- `monotonic_clock_start()` returns `Timestamp`, but `monotonic_clock_end(Timestamp) -> Double` leaks a bare floating-point duration, which is type inconsistent and risks precision/units confusion (`bench/pkg.generated.mbti:5`).
- `Summary` is exposed yet only convertible to JSON, while `T::dump_summaries()` yields a `String`; callers must parse JSON despite `Summary` existing (`bench/pkg.generated.mbti:13`, `bench/pkg.generated.mbti:17`).
- `T::keep(Self, Any) -> Unit` is effectively untyped and hides what can be stored, making misuse easy and hampering discoverability (`bench/pkg.generated.mbti:18`).

**Suggestions**
- Return a dedicated duration type (or at least `Timestamp`) from `monotonic_clock_end`, or supply helpers that wrap both start/end and surface a strongly-typed duration (`bench/pkg.generated.mbti:5`).
- Let `T::dump_summaries()` return structured data—e.g., `[Summary]`—and/or add accessor methods on `Summary` so JSON parsing is optional (`bench/pkg.generated.mbti:13`, `bench/pkg.generated.mbti:17`).
- Replace `T::keep(Self, Any)` with a typed alternative (perhaps `Summary` or a generic parameter) to convey intent and improve safety (`bench/pkg.generated.mbti:18`).
