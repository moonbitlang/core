# Review: moonbitlang/core/deque

**File:** `deque/pkg.generated.mbti`  
**Date:** 2025-10-09T09:57:39.922Z  
**Status:** ✓ Success

---

**Findings**
- `deque/pkg.generated.mbti:14` – `Deque::append(Self[A], Self[A]) -> Unit` takes two `Self` parameters and returns `Unit`, so it is unclear which deque is mutated. A signature like `(Self[A], Self[A]) -> Self[A]` or naming the receiver explicitly would make the mutation semantics obvious.
- `deque/pkg.generated.mbti:20` – `Deque::binary_search_by(Self[A], (A) -> Int)` uses a predicate returning `Int`. Most comparison callbacks in the ecosystem return an `Ordering`/`Compare` result; using raw `Int` encourages ad‑hoc conventions and risks misuse.
- `deque/pkg.generated.mbti:51` & `deque/pkg.generated.mbti:52` – `unsafe_pop_back` and `unsafe_pop_front` return `Unit`, unlike the safe `pop_*` variants that return the removed element. That forces callers to pair them with an extra lookup, defeating the point of an “unsafe but fast” API.

**Suggestions**
- Clarify the receiver on mutating helpers like `append`, or return the mutated deque to mirror other builders.
- Change `binary_search_by`’s callback to return the standard ordering type (or document the expected `Int` contract) to keep the API predictable.
- Consider having the `unsafe_pop_*` methods return the removed element; otherwise rename them to emphasize they only drop elements so users don’t assume they yield a value.
