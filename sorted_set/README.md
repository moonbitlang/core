# Sorted Set

A mutable set backed by a red-black tree.

# Usage

## Create

You can create an empty MutableSet or a MutableSet from other containers.

```moonbit
let set1 : @sorted_set.T[Int] = @sorted_set.new()
let set2 = @sorted_set.singleton(1)
let set5 = @sorted_set.of([1])
let set4 = @sorted_set.from_array([1])
```
### Container Operations

Add an element to the MutableSet in place.

```moonbit
let set = @sorted_set.of([1, 2, 3, 4])
set.add(5) // ()
set.to_string() // of([1, 2, 3, 4, 5])
```

Remove an element from the MutableSet in place.

```moonbit
let set = @sorted_set.of([3, 8, 1]) 
set.remove(8) // () 
set.to_string() // of([1, 3])
```

Whether an element is in the set.

```moonbit
let set = @sorted_set.of([1, 2, 3, 4])
set.contains(1) // true
set.contains(5) // false
```

Iterates over the elements in the set.

```moonbit
@sorted_set.of([1, 2, 3, 4]).each(print) // output: 1234
```

Delete all elements of the set that filter returns false. It is done in place.

```moonbit
let set = @sorted_set.of([1, 2, 3, 4, 5, 6])
set.filter(fn(v) { v % 2 == 0}) // ()
set.to_string() // of([2, 4, 6])
```

Get the size of the set.

```moonbit
@sorted_set.of([1, 2, 3, 4]).size() // 4
```

Whether the set is empty.

```moonbit
@sorted_set.new().is_empty() // true
```

### Set Operations

Union, intersection and difference of two sets. They return a new set that does not overlap with the original sets in memory.

```moonbit
let set1 = @sorted_set.of([3, 4, 5])
let set2 = @sorted_set.of([4, 5, 6])
set1.union(set2) // of([3, 4, 5, 6])
set1.inter(set2) // of([4, 5])
set1.diff(set2) // of([3])
```

Determine the inclusion and separation relationship between two sets.

```moonbit
@sorted_set.of([1, 2, 3]).subset(of([7, 2, 9, 4, 5, 6, 3, 8, 1])) // true
@sorted_set.of([1, 2, 3]).disjoint(of([4, 5, 6])) // true
```

### Stringify

MutableSet implements to_string (i.e. Show trait), which allows you to directly output it.

```moonbit
println(@sorted_set.of([1, 2, 3])) // output of([1, 2, 3]))
@sorted_set.of([1, 2, 3]).to_string() // "MutableSet::[1, 2, 3]"
```

