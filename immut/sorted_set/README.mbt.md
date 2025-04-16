# Immutable Set

ImmutableSet is an immutable, persistent implementation of the set structure (each operation returns a new ImmutableSet), implemented here using a balance tree.

# Usage

## Create

Since set is based on comparison, the type used to construct ImmutableSet needs to implement Compare trait.

You can create an empty ImmutableSet with a value separately through the following methods, or create it directly from the Array.

```moonbit
test {
    let _set1 : @sorted_set.T[Int] = @sorted_set.new()
    let _set2 = @sorted_set.singleton(1)
    let _set4 = @sorted_set.from_array([1])
    let _set5= @sorted_set.of([1])
}
```

## Conversion

You can convert an immutable set to an array, which will be sorted.

```moonbit
test {
    let set = @sorted_set.of([3, 2, 1])
    assert_eq!(set.to_array(), [1, 2, 3])
}
```

## Add & Remove

You can use `add` to add an element to the ImmutableSet.

```moonbit
test {
    let set = @sorted_set.of([1, 2, 3, 4])
    assert_eq!(set.add(5).to_array(), [1, 2, 3, 4, 5])
}
```

You can use `remove` to remove a specific value.

```moonbit
test {
    let set = @sorted_set.of([3, 8, 1])
    assert_eq!(set.remove(8).to_array(), [1, 3])
}
```

## Max & Min & Contains

You can use `contains` to query whether an element is in the set.

```moonbit
test {
    let set = @sorted_set.of([1, 2, 3, 4])
    assert_eq!(set.contains(1), true)
    assert_eq!(set.contains(5), false)
}
```

You can also use `min` and `max` to obtain the minimum or maximum value in the set. When the set is empty, an error will be reported, and they have corresponding Option versions to handle this.

```moonbit
test {
    let set = @sorted_set.of([1, 2, 3, 4])
    assert_eq!(set.min(), 1)
    assert_eq!(set.max(), 4)
    assert_eq!(set.min_option(), Some(1))
    assert_eq!(set.max_option(), Some(4))
}
```

## Split & Union & Inter & Diff & Filter

You can provide an intermediate value to divide a set into two sets by `split`, and whether the intermediate value is in the set will also be returned as the return value.

```moonbit
test {
    let (left, present, right) = @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(5)
    assert_eq!(present, true)
    assert_eq!(left.to_array(), [1, 2, 3, 4])
    assert_eq!(right.to_array(), [6, 7, 8, 9])
}
```

At the same time, you can use union and inter to take the union or intersection of two sets.

```moonbit
test {
    let set1 = @sorted_set.of([3, 4, 5])
    let set2 = @sorted_set.of([4, 5, 6])
    assert_eq!(set1.union(set2).to_array(), [3, 4, 5, 6])
    assert_eq!(set1.intersection(set2).to_array(), [4, 5])
}
```

You can also use the `diff` function to obtain the difference between two sets.

```moonbit
test {
    let set1 = @sorted_set.of([1, 2, 3])
    let set2 = @sorted_set.of([4, 5, 1])
    assert_eq!(set1.difference(set2).to_array(), [2, 3])
}
```

You can use `filter` to filter the elements in the set.

```moonbit
test {
    let set = @sorted_set.of([1, 2, 3, 4, 5, 6])
    assert_eq!(set.filter(fn(v) { v % 2 == 0}).to_array(), [2, 4, 6])
}
```

## Subset & Disjoint

You can use `subsets` and `disjoint` to determine the inclusion and separation relationship between two sets

```moonbit
test {
    assert_eq!(@sorted_set.of([1, 2, 3]).subset(@sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1])), true)
    assert_eq!(@sorted_set.of([1, 2, 3]).disjoint(@sorted_set.of([4, 5, 6])), true)
}
```

## Iter & Fold & Map

Like other sequential containers, set also has iterative methods such as `iter`, `fold`, and `map`, and their order is based on the comparison being less than the order.

```moonbit
test {
    let arr = []
    @sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(fn(v) { arr.push(v) })
    assert_eq!(arr, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    let val = @sorted_set.of([1, 2, 3, 4, 5]).fold(init=0, fn(acc, x) { acc + x })
    assert_eq!(val, 15)
    let set = @sorted_set.of([1, 2, 3])
    assert_eq!(set.map(fn(x){ x * 2}).to_array(), [2, 4, 6])
}
```

## All & Any

`all` and `any` can detect whether all elements in the set match or if there are elements that match.

```moonbit
test {
    assert_eq!(@sorted_set.of([2, 4, 6]).all(fn(v) { v % 2 == 0}), true)
    assert_eq!(@sorted_set.of([1, 4, 3]).any(fn(v) { v % 2 == 0}), true)
}
```

## Empty

`is_empty` can determine whether a set is empty.

```moonbit
test {
    let set1 : @sorted_set.T[Int] = @sorted_set.of([])
    assert_eq!(set1.is_empty(), true)
    let set2 = @sorted_set.of([1])
    assert_eq!(set2.is_empty(), false)
}
```
