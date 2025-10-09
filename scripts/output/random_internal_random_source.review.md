# Review: moonbitlang/core/random/internal/random_source

**File:** `random/internal/random_source/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:48.506Z  
**Status:** ✓ Success

---

**Findings**
- random/internal/random_source/pkg.generated.mbti:9 — `ChaCha8::next(Self) -> UInt64?` signals exhaustion via `None`, yet the only recovery hook is the separate `refill` method; the contract between these two calls remains opaque to API users, making misuse (e.g., ignoring `None` or redundant `refill` calls) likely.
- random/internal/random_source/pkg.generated.mbti:10 — `ChaCha8::refill(Self) -> Unit` is exposed publicly but looks like an implementation detail; surfacing it without documentation or trait integration encourages leaking internal buffering mechanics into callers.

**Assessment**
- Minimal surface: a single RNG type with manual replenishment.
- Lacks seeding clarity; `ChaCha8::new(Bytes)` leaves required length/entropy unspecified, so type safety around keys/nonces is weak.

**Suggestions**
- Document or encode the seed requirements (e.g., dedicated seed type or length-checked constructor).
- Either hide `refill` or wrap it so `next` transparently handles buffering; alternatively expose a trait-based interface (e.g., `RandomSource::next_u64`) to simplify usage expectations.
