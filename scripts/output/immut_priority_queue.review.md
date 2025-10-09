# Review: moonbitlang/core/immut/priority_queue

**File:** `immut/priority_queue/pkg.generated.mbti`  
**Date:** 2025-10-09T09:59:05.818Z  
**Status:** ✓ Success

---

- In `immut/priority_queue/pkg.generated.mbti` the safe removal path splits responsibilities between `peek` (returns `A?`) and `pop` (returns `Self[A]?`). This forces callers to make two calls to obtain and remove the head element, which is awkward for a data structure that conceptually returns the removed element. Consider exposing a combined API (e.g. returning `(A, Self[A])?`) or clarifying/documenting the intended usage.
- Both `pop_exn` (deprecated) and `unsafe_pop` remove the head without returning it. Keeping two APIs with similar, failure-prone semantics is confusing; either retire `pop_exn` fully or ensure there is a clear behavioral difference.
- Several read-only operations (`iter`, `to_array`) require `Compare`, even though iteration or copying out likely doesn’t need to recompare elements. Relaxing these bounds would make the API friendlier for queues of types that only need `Compare` at construction time.
- Overall the surface is otherwise coherent: constructors cover arrays/iters, mutation returns new queues (consistent with immutability), and trait impls (`Compare`, `Eq`, `Hash`, `Show`, `ToJson`, QuickCheck) align with expectations.
