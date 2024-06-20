# Moonbit/Core MutableSet

## Overview

A mutable set backed by a red-black tree.

## Usage

### Create

You can create an empty MutableSet or a MutableSet from other containers.

```moonbit
let set1 : MutableSet[Int] = MutableSet::new()
let set2 = MutableSet::singleton(1)
let set4 = MutableSet::from_array([1])
let set5= MutableSet::[1]
```
### Container Operations

Add an element to the MutableSet in place.

```moonbit
let set = MutableSet::[1, 2, 3, 4]
set.add(5) // ()
set.to_string() // MutableSet::[1, 2, 3, 4, 5]
```

Remove an element from the MutableSet in place.

```moonbit
let set = MutableSet::[3, 8, 1] 
set.remove(8) // () 
set.to_string() // MutableSet::[1, 3]
```

Whether an element is in the set.

```moonbit
let set = MutableSet::from_array([1, 2, 3, 4])
set.contains(1) // true
set.contains(5) // false
```

Iterates over the elements in the set.

```moonbit
MutableSet::[1, 2, 3, 4].iter(print) // output: 1234
```

Delete all elements of the set that filter returns false. It is done in place.

```moonbit
let set = MutableSet::[1, 2, 3, 4, 5, 6]
set.filter(fn(v) { v % 2 == 0}) // ()
set.to_string() // MutableSet::[2, 4, 6]
```

Get the size of the set.

```moonbit
MutableSet::[1, 2, 3, 4].size() // 4
```

Whether the set is empty.

```moonbit
MutableSet::new().is_empty() // true
```

### Set Operations

Union, intersection and difference of two sets. They return a new set that does not overlap with the original sets in memory.

```moonbit
let set1 = MutableSet::[3, 4, 5]
let set2 = MutableSet::[4, 5, 6]
set1.union(set2) // MutableSet::[3, 4, 5, 6]
set1.inter(set2) // MutableSet::[4, 5]
set1.diff(set2) // MutableSet::[3]
```

Determine the inclusion and separation relationship between two sets.

```moonbit
MutableSet::[1, 2, 3].subset(MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1]) // true
MutableSet::[1, 2, 3].disjoint(MutableSet::[4, 5, 6]) // true
```

### Stringify

MutableSet implements to_string (i.e. Show trait), which allows you to directly output it.

```moonbit
println(MutableSet::[1, 2, 3]) // output MutableSet::[1, 2, 3]
MutableSet::[1, 2, 3].to_string() // "MutableSet::[1, 2, 3]"
```

### TODO
- `deep_clone_tree` only clones the tree structure, not the elements. It is not a deep clone in the strict sense. To fix this, we need a `Clone` trait for the elements, which we don't have yet. 