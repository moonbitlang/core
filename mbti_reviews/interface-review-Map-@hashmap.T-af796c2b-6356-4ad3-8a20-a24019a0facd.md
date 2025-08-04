---
time : 2025-08-04T06:41:16.518Z
model : anthropic/claude-sonnet-4
---
## Review of Map and HashMap Interfaces

### Overall Assessment

The interfaces show good consistency between the builtin `Map` and `@hashmap.T` types, which is excellent for API coherence. However, there are several areas for improvement in terms of completeness, naming conventions, and functionality gaps.

### Strengths

- **Consistent API Design**: Both interfaces share nearly identical method signatures, making them interchangeable in most contexts
- **Good Type Safety**: Proper use of trait bounds (`Hash + Eq`, `Eq`) ensures type safety
- **Iterator Support**: Multiple iterator variants (`iter`, `iter2`, `keys`, `values`) provide flexibility
- **Standard Operations**: Core operations like `get`, `set`, `remove`, `contains` are well-covered

### Areas for Improvement

#### 1. **Missing Constructor Methods in HashMap**

**Issue**: `@hashmap.T` lacks essential constructor methods that `Map` provides:
- `T::new(capacity~ : Int = ..)` - Missing
- `T::from_array(Array[(K, V)])` - Missing  
- `T::from_iter(Iter[(K, V)])` - Missing
- `T::of(FixedArray[(K, V)])` - Missing

**Recommendation**: Add these constructors to `@hashmap.T` for API consistency and usability.

#### 2. **Missing Utility Methods in HashMap**

**Issue**: `@hashmap.T` is missing several utility methods:
- `T::copy(Self[K, V]) -> Self[K, V]` - Important for creating independent copies
- `T::map(Self[K, V], (K, V) -> V2) -> Self[K, V2]` - Essential functional programming operation
- `T::keys(Self[K, V]) -> Iter[K]` - Convenient key iteration
- `T::values(Self[K, V]) -> Iter[V]` - Convenient value iteration

**Recommendation**: Add these methods to maintain feature parity with the builtin `Map`.

#### 3. **Exception Handling Inconsistency**

**Issue**: `Map::each` and `Map::eachi` support `raise?` for exception propagation, but `T::each` and `T::eachi` do not:
```moonbit
// Map (builtin)
fn each(Self[K, V], (K, V) -> Unit raise?) -> Unit raise?

// HashMap
fn each(Self[K, V], (K, V) -> Unit) -> Unit
```

**Recommendation**: Align exception handling capabilities between both interfaces.

#### 4. **Missing Trait Implementations**

**Issue**: `@hashmap.T` lacks the `Default` trait implementation that `Map` provides:
```moonbit
impl[K, V] Default for Map[K, V]        // Present in Map
// Missing in @hashmap.T
```

**Recommendation**: Add `Default` implementation for `@hashmap.T` to enable default construction.

#### 5. **Deprecated Method Handling**

**Issue**: Both interfaces have deprecated `op_get` methods, but the deprecation strategy isn't clear.

**Recommendation**: 
- Clearly document the migration path from `op_get` to the preferred method
- Consider removing deprecated methods in a future version

#### 6. **Missing Standard Operations**

**Issue**: Both interfaces lack several common map operations found in other languages:

**Missing Methods**:
- `insert_or_update(key, value, update_fn)` - Insert or update with custom logic
- `entry(key)` - Entry API for efficient conditional operations
- `retain(predicate)` - Remove elements not matching predicate
- `extend(other_map)` - Merge another map into this one
- `is_disjoint(other_map)` - Check if maps have no common keys
- `len()` as alias for `size()` - More familiar to developers from other languages

#### 7. **JSON Support Inconsistency**

**Issue**: JSON support differs between the interfaces:
```moonbit
// Map has both directions
impl[K : Show, V : ToJson] ToJson for Map[K, V]
impl[V : FromJson] FromJson for Map[String, V]

// HashMap only has ToJson
impl[K : Show, V : ToJson] ToJson for T[K, V]
// Missing FromJson
```

**Recommendation**: Add `FromJson` implementation for `@hashmap.T` to match `Map`.

### Specific API Suggestions

#### 1. **Add Entry API Pattern**
```moonbit
fn entry(Self[K, V], K) -> Entry[K, V]
// Where Entry provides methods like or_insert, or_insert_with, etc.
```

#### 2. **Add Bulk Operations**
```moonbit
fn extend(Self[K, V], Iter[(K, V)]) -> Unit
fn retain(Self[K, V], (K, V) -> Bool) -> Unit
```

#### 3. **Add Convenience Aliases**
```moonbit
fn len(Self[K, V]) -> Int  // Alias for size()
```

### Consistency Recommendations

1. **Standardize Exception Handling**: Decide whether iteration methods should support exception propagation and apply consistently
2. **Complete Feature Parity**: Ensure both `Map` and `@hashmap.T` provide identical functionality
3. **Unified Documentation**: Clearly document the relationship and intended use cases for each type
4. **Migration Path**: If one type is preferred over the other, provide clear migration guidance

### Priority Improvements

**High Priority**:
- Add missing constructors to `@hashmap.T`
- Add `copy` method to `@hashmap.T`
- Standardize exception handling in iteration methods

**Medium Priority**:
- Add missing utility methods (`map`, `keys`, `values`)
- Add `Default` trait implementation
- Add entry API for efficient conditional operations

**Low Priority**:
- Add convenience aliases and bulk operations
- Enhance JSON support consistency

The interfaces are well-designed overall but would benefit from completing the feature parity between the two implementations and adding some commonly expected map operations.