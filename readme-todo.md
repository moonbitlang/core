# README.mbt.md Documentation To-Do List

This document tracks which packages in the MoonBit core library are missing README.mbt.md documentation files.

## Packages Missing README.mbt.md

### Core Packages
- [ ] `abort` - Abort/panic functionality package
- [ ] `bench` - Benchmarking utilities package
- [x] `bigint` - Big integer implementation package ✅
- [x] `builtin` - Built-in types and functions package ✅
- [ ] `coverage` - Code coverage utilities package
- [ ] `env` - Environment variables and system interaction package
- [x] `error` - Error handling utilities package ✅
- [ ] `prelude` - Prelude/standard imports package
- [x] `set` - Set data structure package (note: sorted_set has README, but set doesn't) ✅
- [x] `string` - String manipulation utilities package ✅
- [x] `test` - Testing framework utilities package ✅

### Internal Packages - COMPLETED ✅
- [x] `double/internal/ryu` - Internal Ryu algorithm implementation for double formatting ✅
- [x] `immut/hashset` - Immutable hashset implementation (note: immut/hashmap has README) ✅
- [x] `immut/internal/path` - Internal path utilities for immutable data structures ✅
- [x] `immut/internal/sparse_array` - Internal sparse array implementation for immutable data structures ✅
- [x] `quickcheck/splitmix` - SplitMix random number generator for QuickCheck ✅
- [x] `random/internal/random_source` - Internal random source implementation ✅

## Summary

**Total packages with moon.pkg.json**: 57
**Packages with README.mbt.md**: 57 (40 original + 17 newly created)
**Packages missing README.mbt.md**: 0 - ALL COMPLETED! ✅

## Priority Recommendations

### High Priority (Core user-facing packages) - COMPLETED ✅
1. ~~`string` - Essential for string operations~~ ✅
2. ~~`error` - Critical for error handling~~ ✅
3. ~~`builtin` - Core language features~~ ✅
4. ~~`bigint` - Important numeric type~~ ✅
5. ~~`set` - Common data structure~~ ✅
6. ~~`test` - Testing framework~~ ✅

### Medium Priority (Supporting packages) - COMPLETED ✅
1. ~~`abort` - Panic/abort functionality~~ ✅
2. ~~`bench` - Benchmarking tools~~ ✅
3. ~~`env` - Environment interaction~~ ✅
4. ~~`prelude` - Standard imports~~ ✅
5. ~~`coverage` - Code coverage~~ ✅

### Low Priority (Internal packages) - COMPLETED ✅
1. ~~`double/internal/ryu` - Internal implementation~~ ✅
2. ~~`immut/internal/path` - Internal utility~~ ✅
3. ~~`immut/internal/sparse_array` - Internal data structure~~ ✅
4. ~~`quickcheck/splitmix` - Specialized RNG~~ ✅
5. ~~`random/internal/random_source` - Internal implementation~~ ✅
6. ~~`immut/hashset` - May be redundant with immut/hashmap~~ ✅

## Notes

- Some internal packages (those in `*/internal/*` directories) may not need public-facing README documentation
- The `immut/hashset` package might be using shared documentation with `immut/hashmap`
- Consider whether all packages need the same level of documentation based on their visibility and usage
