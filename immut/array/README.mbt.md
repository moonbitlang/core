# Immutable Array

Immutable array is a persistent data structure that provides random access and update operations. Based on Clojure's [persistent vector](https://hypirion.com/musings/understanding-persistent-vector-pt-1).

# Usage

## Create

You can create an empty array using `new()` or construct it using `of()`, or use `from_iter()` to construct it from an iterator.

```moonbit
test {
  let _arr1 = @array.of([1, 2, 3, 4, 5])    
  let _arr2 : @array.T[Int] = @array.new()
  let _arr3 = @array.from_iter((1).until(5))
  let _arr4 = @array.from_array([1, 2, 3])
}
```

Or use `make()`, `makei()` to create an array with some elements.

```moonbit
test {
  let arr1 = @array.make(5, 1)
  assert_eq!(arr1.to_array(), [1, 1, 1, 1, 1])
  let arr2 = @array.makei(5, fn(i){i + 1})
  assert_eq!(arr2.to_array(), [1, 2, 3, 4, 5])
}
```

## Update 

Since the array is immutable, the `set()`, `push()` operation is not in-place. It returns a new array with the updated value.

```moonbit
test {
  let arr1 = @array.of([1, 2, 3, 4, 5])
  let arr2 = arr1.set(2, 10).push(6)
  assert_eq!(arr1.to_array(), [1, 2, 3, 4, 5])
  assert_eq!(arr2.to_array(), [1, 2, 10, 4, 5, 6])
}
```

## Concatenation

You can use `concat()` to concatenate two arrays.

```moonbit
test {
  let arr1 = @array.of([1, 2, 3])
  let arr2 = @array.of([4, 5, 6])
  let arr3 = arr1.concat(arr2)
  assert_eq!(arr3.to_array(), [1, 2, 3, 4, 5, 6])
}
```

## Query

You can use `op_get()` to get the value at the index, or `length()` to get the length of the array, or `is_empty()` to check whether the array is empty.

```moonbit
test {
  let arr = @array.of([1, 2, 3, 4, 5])
  assert_eq!(arr[2], 3)
  assert_eq!(arr.length(), 5)
  assert_eq!(arr.is_empty(), false)
}
```

## Iteration

You can use `iter()` to get an iterator of the array, or use `each()` to iterate over the array.

```moonbit
test {
  let arr = @array.of([1, 2, 3, 4, 5])
  inspect!(arr.iter(), content="[1, 2, 3, 4, 5]")
  let val = []
  arr.each(fn(v) { val.push(v) })
  assert_eq!(val, [1, 2, 3, 4, 5])
  let vali = []
  arr.eachi(fn(i, v) { vali.push((i, v)) })
  assert_eq!(vali, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)])
}
```

# TODO

- [] Add `split` and other operations that can be derived from `split` and `concat` like `insert` and `delete`.
- [] Add an algorithm description in README, since this algorithm does not use the invariant in the ICFP paper. Instead, it uses the "search step invariant" in Hypirion's thesis.
- [] Add a benchmark to compare the performance with the previous version.
- [] Optimizations such as tail.
