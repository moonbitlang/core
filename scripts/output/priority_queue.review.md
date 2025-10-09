# Review: moonbitlang/core/priority_queue

**File:** `priority_queue/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:25.583Z  
**Status:** ✓ Success

---

- `priority_queue/pkg.generated.mbti:23` `T::unsafe_pop(Self[A]) -> Unit` suggests it removes the top element without returning it, but the name implies a non-checked variant of `pop` that yields the element. Either return `A` or rename (e.g. `discard_top`) to avoid misuse.
- `priority_queue/pkg.generated.mbti:18` `T::iter(Self[A]) -> Iter[A]` is gated by `Compare`, yet iteration does not appear to need ordering; likewise `to_array` (line 21). Removing those bounds would make read-only access usable for types that implement `Equal`/`Show` but not `Compare`.
- `priority_queue/pkg.generated.mbti:17` `T::from_iter(Iter[K]) -> Self[K]` uses a different type parameter name from the rest of the API; harmless but mildly inconsistent with `A` elsewhere.

Overall the API exposes the expected heap capabilities (construction from various containers, peek/pop/push, iteration, conversions) and derives helpful traits (`Default`, `Show`, `ToJson`, QuickCheck support). Tidying the points above would improve clarity and ergonomics without altering behavior.
