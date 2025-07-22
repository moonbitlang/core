# Bug Report for MoonBit Standard Library

## 1. Non-standard Compare Implementation for Arrays

### Description
The `Compare` implementation for `Array`, `FixedArray`, and immutable arrays compares lengths first before comparing elements. This is not the standard lexicographic ordering used in most programming languages.

### Current Behavior
```moonbit
[1, 2, 3].compare([1, 2]) // returns 1 (positive)
```

### Expected Behavior (Standard Lexicographic)
```moonbit
[1, 2, 3].compare([1, 2]) // should return 1 (positive) because [1, 2] is a prefix
[1, 2].compare([1, 3]) // should return -1 (negative) because 2 < 3
```

### Affected Files
- `builtin/array.mbt` (line 270-281)
- `array/fixedarray.mbt` (line 1016-1028)
- `immut/array/array.mbt` (line 446-457)

### Impact
This non-standard behavior could cause confusion for developers expecting standard lexicographic ordering, especially when porting code from other languages or using arrays as keys in sorted data structures.

## 2. Missing Test Coverage for Error Cases

### Description
Several error handling paths in the codebase lack test coverage, particularly for edge cases that trigger aborts.

### Uncovered Error Cases

#### BigInt Division by Zero
- `bigint/bigint_nonjs.mbt` line 446: `abort("division by zero")` in `op_div`
- `bigint/bigint_nonjs.mbt` line 487: `abort("division by zero")` in `op_mod`

#### BigInt Negative Shift Count
- `bigint/bigint_nonjs.mbt` line 670: `abort("negative shift count")` in `op_shl`
- `bigint/bigint_nonjs.mbt` line 727: `abort("negative shift count")` in `op_shr`

#### BigInt Empty String Parsing
- `bigint/bigint_nonjs.mbt` line 989: `abort("empty string")` in `from_string`

### Recommendation
Add test cases for these error conditions to ensure they behave as expected and to improve code coverage.

## 3. Potential Issues (Need Further Investigation)

### FixedArray Compare Implementation
The implementation has no test coverage (lines 1018-1026), which could hide bugs in the comparison logic.

### String Methods Edge Cases
Several string methods have uncovered edge cases:
- Empty needle handling in `find` (line 65)
- Empty needle handling in `rfind` (line 199)
- These seem to be handled correctly but lack test coverage.

## Recommendations

1. **Fix Array Compare Implementation**: Consider changing to standard lexicographic ordering or clearly document the current behavior as intentional.

2. **Add Error Case Tests**: Create test cases for all abort/panic conditions to ensure proper error handling.

3. **Improve Test Coverage**: Focus on uncovered lines in critical functions to catch potential bugs.

4. **Documentation**: If the current Compare behavior is intentional, update documentation to clearly explain the rationale.
