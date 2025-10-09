# Review: moonbitlang/core/random

**File:** `random/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:44.720Z  
**Status:** ✓ Success

---

**API Assessment**
- `Rand` offers a reasonably complete RNG surface (ints, floats, bigint, shuffle) with a pluggable `Source`, which keeps the type reusable.
- Static factories (`Rand::chacha8`, `Rand::new`) plus the `Source` trait give users both high- and low-level control; optional arguments keep defaults handy.

**Potential Issues**
- Deprecated free functions `chacha8`/`new` still appear in the surface; unless there is a compatibility window, their presence may confuse users wondering which entrypoint to prefer.
- `Rand::chacha8` and the deprecated `chacha8` differ in return type (`Rand` vs `&Source`). If callers migrate naively, behaviour changes; worth calling out in docs or via naming.
- `Rand::shuffle(Self, Int, (Int, Int) -> Unit)` exposes a non-obvious callback signature; without docs it’s unclear how indices map to collection operations.

**Suggestions**
- Consider fully removing or hiding deprecated functions once migration is complete, or add doc comments in the interface clarifying the new factory to minimise ambiguity.
- If `shuffle` is kept, document the callback contract (e.g. expects a swap closure) or provide container-specific helpers so users don’t have to decode the callback shape.
