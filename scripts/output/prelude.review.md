# Review: moonbitlang/core/prelude

**File:** `prelude/pkg.generated.mbti`  
**Date:** 2025-10-09T10:00:42.411Z  
**Status:** ✓ Success

---

**API Assessment**
- `prelude/pkg.generated.mbti` offers a concise grab bag of control helpers (`abort`, `panic`, `fail`, `assert_*`) and re-exports that make the rest of the standard library easier to consume.
- The fluent helpers (`tap`, `then`, `ignore`) at `prelude/pkg.generated.mbti:47` feel coherent with functional chaining patterns already present elsewhere.
- Re-exporting builtin aliases keeps client code short and mirrors the expectations of a “prelude” layer.

**Issues**
- `prelude/pkg.generated.mbti:39` (`panic`) returns `T` without any `raise` annotation or payload, so effect tracking tools can’t distinguish it from a pure value-returning function and callers get no diagnostic context.
- `prelude/pkg.generated.mbti:9`, `:27`, and `:39` expose three failure-oriented APIs (`abort`, `fail`, `panic`) whose semantics are hard to differentiate from the signatures alone; only `fail` communicates its failure mode.
- `prelude/pkg.generated.mbti:33` takes `&@builtin.Show`, whereas the neighbouring `println`/`repr` use a typeclass constraint; mixing explicit trait objects with implicit constraints in a tiny surface stands out as an inconsistency.
- `prelude/pkg.generated.mbti:41` exports `physical_equal` for all `T`, but value semantics for many `T` make physical identity undefined; without documentation or a trait bound it invites misuse.

**Suggestions**
- Make `panic` explicit—either drop the return value or mark it `-> T raise @builtin.Failure` (or whatever it actually raises) and consider an optional message parameter.
- Clarify or consolidate the failure helpers: document each via naming (`panic_with` vs `abort_process`) or reduce to one primary entry point with variants for message/location.
- Align `inspect` with the rest of the API by switching to a typeclass constraint (`T : Show`) and leveraging implicit evidence, or otherwise document why a by-ref trait object is required.
