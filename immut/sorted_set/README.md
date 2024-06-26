# Moonbit/Core ImmutableSet

## Overview

ImmutableSet is an immutable, persistent implementation of the set structure (each operation returns a new ImmutableSet), implemented here using a balance tree.

## Usage

### Create

Since set is based on comparison, the type used to construct ImmutableSet needs to implement Compare trait.

You can create an empty ImmutableSet with a value separately through the following methods, or create it directly from the Array.

```moonbit
let set1 : ImmutableSet[Int] = ImmutableSet::new()
let set2 = ImmutableSet::singleton(1)
let set4 = ImmutableSet::from_array([1])
let set5= of([1])
```

### Convert

Instead, you can convert an ImmutableSet to a Array/Vec, which will be sorted.

```moonbit
let set = of([3, 2, 1])
set.to_array() // [1, 2, 3]
set.to_vec() // of([1, 2, 3])
```

### Add & Remove

You can use `add` to add an element to the ImmutableSet.

```moonbit
let set = of([1, 2, 3, 4])
set.add(5) // of([1, 2, 3, 4, 5])
```

You can use `remove` to remove a specific value or use `remove_min` to remove the minimum value in the set.

```moonbit
(of([3, 8, 1]).remove(8) // of([1, 3]))
(of([3, 4, 5]).remove_min() // of([4, 5]))
```

### Max & Min & Contains

You can use `contains` to query whether an element is in the set.

```moonbit
let set = ImmutableSet::from_array([1, 2, 3, 4])
set.contains(1) // true
set.contains(5) // false
```

You can also use `min` and `max` to obtain the minimum or maximum value in the set. When the set is empty, an error will be reported, and they have corresponding Option versions to handle this.

```moonbit
let set = ImmutableSet::from_array([1, 2, 3, 4])
set.min() // 1
set.max() // 4
set.min_option() // Some(1)
set.max_option() // Some(4)
```

### Split & Union & Inter & Diff & Filter

You can provide an intermediate value to divide a set into two sets by `split`, and whether the intermediate value is in the set will also be returned as the return value.

```moonbit
let (left, present, right) = of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(5)
/// present // true
/// left // of([1, 2, 3, 4])
/// right // of([6, 7, 8, 9])
```

At the same time, you can use union and inter to take the union or intersection of two sets.

```moonbit
let set1 = of([3, 4, 5])
let set2 = of([4, 5, 6])
set1.union(set2) // of([3, 4, 5, 6])
set1.inter(set2) // of([4, 5])
```

You can also use the `diff` function to obtain the difference between two sets.

```moonbit
of([1, 2, 3].diff(of([4, 5, 1])) // of([2, 3]))
```

You can use `filter` to filter the elements in the set.

```moonbit
of([1, 2, 3, 4, 5, 6].filter(fn(v) { v % 2 == 0}) // of([2, 4, 6]))
```

### Subset & Disjoint

You can use `subsets` and `disjoint` to determine the inclusion and separation relationship between two sets

```moonbit
of([1, 2, 3]).subset(of([7, 2, 9, 4, 5, 6, 3, 8, 1])) // true
of([1, 2, 3]).disjoint(of([4, 5, 6])) // true
```

### Iter & Fold & Map

Like other sequential containers, set also has iterative methods such as `iter`, `fold`, and `map`, and their order is based on the comparison being less than the order.

```moonbit
of([7, 2, 9, 4, 5, 6, 3, 8, 1]).iter(print)// output: 123456789
of([1, 2, 3, 4, 5]).fold(0, fn(acc, x) { acc + x }) // 15
of([1, 2, 3].map(fn(x){ x * 2}) // of([2, 4, 6]))
```

### All & Any

`all` and `any` can detect whether all elements in the set match or if there are elements that match.

```moonbit
of([2, 4, 6]).all(fn(v) { v % 2 == 0}) // true
of([1, 4, 3]).any(fn(v) { v % 2 == 0}) // true
```

### Stringify

ImmutableSet implements to_string (i.e. Show trait), which allows you to directly output it.

```moonbit
println(of([1, 2, 3]) // output of([1, 2, 3]))
of([1, 2, 3]).to_string() // "of([1, 2, 3])"
```

### Empty

`is_empty` can determine whether a set is empty.

```moonbit
of([]).is_empty() // true
of([1]).is_empty() // false
```
