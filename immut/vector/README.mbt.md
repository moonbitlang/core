# Immutable Vector

Immutable vector is a persistent data structure that provides random access and update operations. Based on Clojure's [persistent vector](https://hypirion.com/musings/understanding-persistent-vector-pt-1).

# Usage

## Create

You can create an empty vector using `new()` or construct it using `of()`, or use `from_iter()` to construct it from an iterator.

```mbt check
///|
test {
  let _arr1 = @vector.from_array([1, 2, 3, 4, 5])
  let _arr2 : @vector.T[Int] = @vector.new()
  let _arr3 = @vector.from_iter((1).until(5))
  let _arr4 = @vector.from_array([1, 2, 3])
}
```

Or use `make()`, `makei()` to create a vector with some elements.

```mbt check
///|
test {
  let arr1 = @vector.make(5, 1)
  assert_eq(arr1.to_array(), [1, 1, 1, 1, 1])
  let arr2 = @vector.makei(5, i => i + 1)
  assert_eq(arr2.to_array(), [1, 2, 3, 4, 5])
}
```

## Update 

Since the vector is immutable, the `set()`, `push()`, `pop()` operations are not in-place. They return a new vector with the updated value.

```mbt check
///|
test {
  let arr1 = @vector.from_array([1, 2, 3, 4, 5])
  let arr2 = arr1.set(2, 10).push(6).pop().unwrap()
  assert_eq(arr1.to_array(), [1, 2, 3, 4, 5])
  assert_eq(arr2.to_array(), [1, 2, 10, 4, 5])
}
```

## Concatenation

You can use `concat()` to concatenate two vectors.

```mbt check
///|
test {
  let arr1 = @vector.from_array([1, 2, 3])
  let arr2 = @vector.from_array([4, 5, 6])
  let arr3 = arr1.concat(arr2)
  assert_eq(arr3.to_array(), [1, 2, 3, 4, 5, 6])
}
```

## Range Operations

You can use `split()`, `take()`, `drop()`, and `slice()` to work with subranges without flattening the whole tree.

```mbt check
///|
test {
  let arr = @vector.from_iter((0).until(10))
  let (left, right) = arr.split(4)
  assert_eq(left.to_array(), [0, 1, 2, 3])
  assert_eq(right.to_array(), [4, 5, 6, 7, 8, 9])
  assert_eq(arr.take(3).to_array(), [0, 1, 2])
  assert_eq(arr.drop(7).to_array(), [7, 8, 9])
  assert_eq(arr.slice(2, 6).to_array(), [2, 3, 4, 5])
}
```

## Query

You can use `get()` to get the value at the index, `peek()` to read the last element, `length()` to get the length of the vector, or `is_empty()` to check whether the vector is empty.

```mbt check
///|
test {
  let arr = @vector.from_array([1, 2, 3, 4, 5])
  assert_eq(arr[2], 3)
  assert_eq(arr.peek(), Some(5))
  assert_eq(arr.length(), 5)
  assert_eq(arr.is_empty(), false)
}
```

## Iteration

You can use `iter()` to get an iterator of the vector, or use `each()` to iterate over the vector.

```mbt check
///|
test {
  let arr = @vector.from_array([1, 2, 3, 4, 5])
  inspect(arr.iter(), content="[1, 2, 3, 4, 5]")
  let val = []
  arr.each(v => val.push(v))
  assert_eq(val, [1, 2, 3, 4, 5])
  let vali = []
  arr.eachi((i, v) => vali.push((i, v)))
  assert_eq(vali, [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)])
}
```

# TODO

- [] Add operations that can be derived from `split` and `concat` like `insert` and `delete`.
- [] Add an algorithm description in README, since this algorithm does not use the invariant in the ICFP paper. Instead, it uses the "search step invariant" in Hypirion's thesis.
- [] Add a benchmark to compare the performance with the previous version.
- [] Add more dedicated APIs derived from the tail-backed layout.
