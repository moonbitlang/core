# Code Coverage Analysis and Testing TODO

## Top 10 Most Important Uncovered Lines

Based on the coverage analysis, here are the most critical uncovered lines that should be prioritized for testing:

### 1. **Error Handling in String Parsing** - `strconv/double.mbt:84`
- **Function**: `parse_double` - syntax error when parsing infinity/NaN with extra characters
- **Priority**: HIGH - Critical error handling path
- **Impact**: Security/robustness for number parsing

### 2. **Iterator Early Termination** - `immut/sorted_set.mbt:381,431,435`
- **Function**: `iter` and `range` methods - IterEnd branches in tree traversal
- **Priority**: HIGH - Core data structure functionality
- **Impact**: Iterator correctness and memory safety

### 3. **Decimal Overflow Handling** - `strconv/decimal.mbt:252`
- **Function**: `rounded_integer` - overflow return path
- **Priority**: HIGH - Numeric overflow safety
- **Impact**: Prevents incorrect calculations with large numbers

### 4. **String Replacement Edge Cases** - `string/methods.mbt:1141,1187`
- **Function**: `replace_all` - boundary check when replacement reaches end
- **Priority**: MEDIUM - String manipulation correctness
- **Impact**: Prevents buffer overruns in string operations

### 5. **Decimal Truncation Logic** - `strconv/decimal.mbt:282,359,483,497,506`
- **Function**: Multiple decimal operations - truncation and rounding edge cases
- **Priority**: MEDIUM - Numeric precision handling
- **Impact**: Floating-point accuracy in edge cases

### 6. **Base Prefix Parsing** - `strconv/int.mbt:47`
- **Function**: `check_and_consume_base` - octal prefix handling
- **Priority**: MEDIUM - Number parsing completeness
- **Impact**: Support for all numeric bases

### 7. **Scientific Notation Edge Cases** - `strconv/number.mbt:47,57,145,159,163`
- **Function**: Scientific notation parsing - underscore handling and digit parsing
- **Priority**: MEDIUM - Numeric parsing robustness
- **Impact**: Complete scientific notation support

### 8. **String Iterator Early Exit** - `string/string.mbt:154,160,224`
- **Function**: `iter2` and offset calculation - early termination and error cases
- **Priority**: MEDIUM - String iteration correctness
- **Impact**: Unicode handling and bounds checking

### 9. **Tuple Default Implementations** - `tuple/tuple_default.mbt:22,32,66,86,108,132,158,186,216,248,282,318`
- **Function**: Default trait implementations for tuples (3-15 elements)
- **Priority**: LOW - Completeness for generic programming
- **Impact**: Support for default values in tuple types

### 10. **String View Stepping** - `strconv/string_view.mbt:30`
- **Function**: `step` method - None return path
- **Priority**: LOW - String view navigation
- **Impact**: Proper handling of invalid step operations

## Testing TODO Checklist

### High Priority Functions (Critical for Correctness)

#### String Conversion (`strconv/`)
- [ ] **`parse_double`** - Test parsing infinity/NaN with trailing characters
- [ ] **`rounded_integer`** - Test decimal overflow scenarios (values > 20 digits)
- [ ] **`should_round_up`** - Test truncated decimal rounding edge cases
- [ ] **`right_shift`** - Test shift operations with truncation
- [ ] **`left_shift`** - Test shift operations with digit overflow
- [ ] **`check_and_consume_base`** - Test octal prefix parsing (`0o`, `0O`)
- [ ] **`parse_scientific`** - Test empty exponent and underscore handling
- [ ] **`parse_number`** - Test many-digit number parsing edge cases
- [ ] **`step`** - Test string view stepping beyond bounds

#### Data Structures (`immut/sorted_set`)
- [ ] **`iter`** - Test iterator early termination (IterEnd scenarios)
- [ ] **`range`** - Test range iteration with early termination
- [ ] **`Default::default`** - Test default sorted set creation

### Medium Priority Functions (Robustness)

#### String Operations (`string/`)
- [ ] **`replace_all` (String)** - Test replacement at string boundaries
- [ ] **`replace_all` (View)** - Test view replacement at boundaries  
- [ ] **`to_lower`** - Test strings with no uppercase characters
- [ ] **`iter2`** - Test iterator early termination with surrogate pairs
- [ ] **`offset_of_nth_char_forward`** - Test invalid start index handling

### Low Priority Functions (Completeness)

#### Tuple Defaults (`tuple/`)
- [ ] **3-tuple default** - Test `Default::default()` for 3-element tuples
- [ ] **4-tuple default** - Test `Default::default()` for 4-element tuples
- [ ] **5-tuple default** - Test `Default::default()` for 5-element tuples
- [ ] **6-tuple default** - Test `Default::default()` for 6-element tuples
- [ ] **7-tuple default** - Test `Default::default()` for 7-element tuples
- [ ] **8-tuple default** - Test `Default::default()` for 8-element tuples
- [ ] **9-tuple default** - Test `Default::default()` for 9-element tuples
- [ ] **10-tuple default** - Test `Default::default()` for 10-element tuples
- [ ] **11-tuple default** - Test `Default::default()` for 11-element tuples
- [ ] **12-tuple default** - Test `Default::default()` for 12-element tuples
- [ ] **13-tuple default** - Test `Default::default()` for 13-element tuples
- [ ] **14-tuple default** - Test `Default::default()` for 14-element tuples
- [ ] **15-tuple default** - Test `Default::default()` for 15-element tuples

## Testing Strategy

### Recommended Approach:
1. **Start with High Priority** - Focus on error handling and core data structure functionality
2. **Use Property-Based Testing** - Leverage `@quickcheck` for edge case discovery
3. **Add Snapshot Tests** - Use `inspect` and `moon test --update` for regression testing
4. **Edge Case Focus** - Target boundary conditions, overflow scenarios, and early termination paths
5. **Error Path Testing** - Ensure all error handling branches are exercised

### Test Implementation Tips:
- Use `inspect` for snapshot testing where behavior verification is needed
- Use `assert_eq` only in loops where snapshots would be too variable
- Run `moon test --update` to update snapshots when behavior changes are intentional
- Use `moon coverage analyze > uncovered.log` to track progress

## Coverage Improvement Goals:
- **Current**: 771 uncovered lines across 99 files
- **Target**: Reduce by 50% focusing on high-priority functions first
- **Success Metrics**: All error handling paths tested, core data structure operations covered
