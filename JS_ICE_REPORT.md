# JS Coverage ICE Repro Report

## Summary
Running JS tests with coverage enabled triggers a compiler ICE during `moonc link-core`.
The same JS tests pass without coverage.

## Environment
- OS: macOS 15.6.1 (24G90), arm64 (Darwin 24.6.0)
- Repo: moonbitlang/core @ `4f1cba646aa8b16f776c92913e8a351dd53715fb` (origin/main)
- Branch: `js-ice-report`
- moon: `moon 0.1.20251227 (eee7d0a 2025-12-27)`
  - Feature flags enabled: `rupes_recta`
- moonc: `v0.6.37+0b3e4ae80 (2025-12-29)`

## Reproduction Steps
1. `git clone https://github.com/moonbitlang/core.git`
2. `cd core`
3. `git checkout 4f1cba646aa8b16f776c92913e8a351dd53715fb`
4. `moon test --target js --enable-coverage`

## Expected Result
`moon test --target js --enable-coverage` completes without crashing.

## Actual Result
The compiler crashes with an assertion failure in `moonc.ml` during `link-core`.
The failure occurs repeatedly for multiple test packages.

Excerpt (first failure):
```
failed: /Users/dii/.moon/bin/moonc link-core /Users/dii/git/100_coverrage/target/js/debug/test/abort/abort.core /Users/dii/git/100_coverrage/target/js/debug/test/builtin/builtin.whitebox_test.core -main moonbitlang/core/builtin -o /Users/dii/git/100_coverrage/target/js/debug/test/builtin/builtin.whitebox_test.js -test-mode -pkg-config-path /Users/dii/git/100_coverrage/builtin/moon.pkg.json -pkg-sources moonbitlang/core/abort:/Users/dii/git/100_coverrage/abort -pkg-sources moonbitlang/core/builtin:/Users/dii/git/100_coverrage/builtin -exported_functions moonbit_test_driver_internal_execute,moonbit_test_driver_finish -js-format cjs -no-dts -target js -g -O0 -source-map
Oops, the compiler has encountered an unexpected situation.
This is a bug in the compiler.
Error: File "moonc.ml", line 233940, characters 11-17: Assertion failed
Compiler args: /Users/dii/.moon/bin/moonc link-core /Users/dii/git/100_coverrage/target/js/debug/test/abort/abort.core /Users/dii/git/100_coverrage/target/js/debug/test/builtin/builtin.whitebox_test.core -main moonbitlang/core/builtin -o /Users/dii/git/100_coverrage/target/js/debug/test/builtin/builtin.whitebox_test.js -test-mode -pkg-config-path /Users/dii/git/100_coverrage/builtin/moon.pkg.json -pkg-sources moonbitlang/core/abort:/Users/dii/git/100_coverrage/abort -pkg-sources moonbitlang/core/builtin:/Users/dii/git/100_coverrage/builtin -exported_functions moonbit_test_driver_internal_execute,moonbit_test_driver_finish -js-format cjs -no-dts -target js -g -O0 -source-map
moonc version: v0.6.37+0b3e4ae80
```

## Control Case
`moon test --target js` (without coverage) succeeds locally.
