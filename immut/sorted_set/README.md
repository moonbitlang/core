# Immutable Set

ImmutableSet is an immutable, persistent implementation of the set structure (each operation returns a new ImmutableSet), implemented here using a balance tree.

# Usage

## Create

Since set is based on comparison, the type used to construct ImmutableSet needs to implement Compare trait.

You can create an empty ImmutableSet with a value separately through the following methods, or create it directly from the Array.

```moonbit
let set1 : @immut/sorted_set.T[Int] = @immut/sorted_set.new()
let set2 = @immut/sorted_set.singleton(1)
let set4 = @immut/sorted_set.from_array([1])
let set5= @immut/sorted_set.of([1])
```

## Conversion

You can convert an immutable set to an array, which will be sorted.

```moonbit
let set = @immut/sorted_set.of([3, 2, 1])
println(set.to_array()) // [1, 2, 3]
```

## Add & Remove

You can use `add` to add an element to the ImmutableSet.

```moonbit
let set = @immut/sorted_set.of([1, 2, 3, 4])
println(set.add(5)) // of([1, 2, 3, 4, 5])
```

You can use `remove` to remove a specific value.

```moonbit
@immut/sorted_set.of([3, 8, 1]).remove(8) // of([1, 3]))
```

## Max & Min & Contains

You can use `contains` to query whether an element is in the set.

```moonbit
let set = @immut/sorted_set.of([1, 2, 3, 4])
println(set.contains(1)) // true
println(set.contains(5)) // false
```

You can also use `min` and `max` to obtain the minimum or maximum value in the set. When the set is empty, an error will be reported, and they have corresponding Option versions to handle this.

```moonbit
let set = @immut/sorted_set.of([1, 2, 3, 4])
println(set.min()) // 1
println(set.max()) // 4
println(set.min_option()) // Some(1)
println(set.max_option()) // Some(4)
```

## Split & Union & Inter & Diff & Filter

You can provide an intermediate value to divide a set into two sets by `split`, and whether the intermediate value is in the set will also be returned as the return value.

```moonbit
let (left, present, right) = @immut/sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).split(5)
/// present // true
/// left // of([1, 2, 3, 4])
/// right // of([6, 7, 8, 9])
```

At the same time, you can use union and inter to take the union or intersection of two sets.

```moonbit
let set1 = @immut/sorted_set.of([3, 4, 5])
let set2 = @immut/sorted_set.of([4, 5, 6])
println(set1.union(set2)) // of([3, 4, 5, 6])
println(set1.inter(set2)) // of([4, 5])
```

You can also use the `diff` function to obtain the difference between two sets.

```moonbit
let set1 = @immut/sorted_set.of([1, 2, 3])
let set2 = @immut/sorted_set.of([4, 5, 1])
println(set1.diff(set2)) // of([2, 3])
```

You can use `filter` to filter the elements in the set.

```moonbit
let set = @immut/sorted_set.of([1, 2, 3, 4, 5, 6])
println(set.filter(fn(v) { v % 2 == 0})) // of([2, 4, 6]))
```

## Subset & Disjoint

You can use `subsets` and `disjoint` to determine the inclusion and separation relationship between two sets

```moonbit
@immut/sorted_set.of([1, 2, 3]).subset(of(@immut/sorted_set.[7, 2, 9, 4, 5, 6, 3, 8, 1])) |> println // true
@immut/sorted_set.of([1, 2, 3]).disjoint(@immut/sorted_set.of([4, 5, 6])) |> println // true
```

## Iter & Fold & Map

Like other sequential containers, set also has iterative methods such as `iter`, `fold`, and `map`, and their order is based on the comparison being less than the order.

```moonbit
@immut/sorted_set.of([7, 2, 9, 4, 5, 6, 3, 8, 1]).each(println)
@immut/sorted_set.of([1, 2, 3, 4, 5]).fold(init=0, fn(acc, x) { acc + x }) // 15
@immut/sorted_set.of([1, 2, 3].map(fn(x){ x * 2})) |> println// of([2, 4, 6]))
```

## All & Any

`all` and `any` can detect whether all elements in the set match or if there are elements that match.

```moonbit
@immut/sorted_set.of([2, 4, 6]).all(fn(v) { v % 2 == 0}) |> println // true
@immut/sorted_set.of([1, 4, 3]).any(fn(v) { v % 2 == 0}) |> println // true
```

## Empty

`is_empty` can determine whether a set is empty.

```moonbit
@immut/sorted_set.of([]).is_empty() // true
@immut/sorted_set.of([1]).is_empty() // false
```
