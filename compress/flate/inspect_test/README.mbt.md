# Compression integration tests

`moonbitlang/core/compress/flate/inspect_test` is a test-only package for the public
compression APIs. Its `_test.mbt` files exercise `compress/flate`. Keeping these
tests in a separate package checks the APIs as a caller sees them, including
method visibility and passing methods as function values. Tests that need codec
internals live alongside the implementations in `_wbtest.mbt` files.

This package has no production code or exported API. Its test dependencies are
listed in the `for "test"` imports in `moon.pkg`. The empty
`pkg.generated.mbti` is therefore intentional: `moon info` describes the
package's exported interface, not its tests. Applications should import the
codec packages they use, rather than this package. See the
[flate README](../README.mbt.md) for usage examples.

The tests cover:

- Known DEFLATE vectors, malformed and truncated input, decoded-size limits,
  and cancellation.
- Whole-buffer, streaming, and caller-owned output APIs; byte counts,
  backpressure, flushing, and finalization.
- Preset dictionaries, sliding-window boundaries, workspace reuse, and reset.
- Compression round trips, split and optimal parsing, and fast-store behavior.

Run this package from the repository root:

```sh
moon test compress/flate/inspect_test --target all --deny-warn
```
