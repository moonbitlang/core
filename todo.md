# Deprecated Items Refactoring TODO

This document tracks the refactoring of deprecated items across all packages in the MoonBit standard library.

## Packages to Refactor

### array
- [x] Move deprecated items from `view.mbt` to `deprecated.mbt` ✅ COMPLETED

### builtin  
- [ ] Move deprecated items from `arrayview.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `int64_js.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `int64_nonjs.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `intrinsics.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `iter.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `operators.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `string.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `traits.mbt` to `deprecated.mbt`

### deque
- [x] Move deprecated items from `types.mbt` to `deprecated.mbt` ✅ COMPLETED

### hashmap
- [x] Move deprecated items from `types.mbt` to `deprecated.mbt` ✅ COMPLETED

### hashset
- [x] Move deprecated items from `types.mbt` to `deprecated.mbt` ✅ COMPLETED

### immut/array
- [ ] Move deprecated items from `array.mbt` to `deprecated.mbt`

### immut/hashmap
- [ ] Move deprecated items from `HAMT.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `types.mbt` to `deprecated.mbt`

### immut/hashset
- [ ] Move deprecated items from `types.mbt` to `deprecated.mbt`

### immut/list
- [ ] Move deprecated items from `list.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `types.mbt` to `deprecated.mbt`

### immut/priority_queue
- [ ] Move deprecated items from `types.mbt` to `deprecated.mbt`

### immut/sorted_map
- [ ] Move deprecated items from `map.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `types.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `utils.mbt` to `deprecated.mbt`

### immut/sorted_set
- [ ] Move deprecated items from `immutable_set.mbt` to `deprecated.mbt`
- [ ] Move deprecated items from `types.mbt` to `deprecated.mbt`

### list
- [x] Move deprecated items from `types.mbt` to `deprecated.mbt` ✅ COMPLETED

### math
- [ ] Move deprecated items from `algebraic.mbt` to `deprecated.mbt`

### queue
- [x] Move deprecated items from `types.mbt` to `deprecated.mbt` ✅ COMPLETED

### random
- [ ] Move deprecated items from `random.mbt` to `deprecated.mbt`

### rational
- [ ] Move deprecated items from `rational.mbt` to `deprecated.mbt`

### result
- [ ] Move deprecated items from `result.mbt` to `deprecated.mbt`

### sorted_map
- [x] Move deprecated items from `types.mbt` to `deprecated.mbt` ✅ COMPLETED

### sorted_set
- [x] Move deprecated items from `types.mbt` to `deprecated.mbt` ✅ COMPLETED

## Final Steps
- [ ] Run `moon fmt` to format all files
- [ ] Run `moon info` to update interface files
- [ ] Run `moon test` to ensure all tests pass
- [ ] Review `.mbti` diffs to ensure no unexpected interface changes
