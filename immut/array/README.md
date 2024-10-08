# Immutable Array

Immutable array is a persistent data structure that provides random access and update operations. Based on Clojure's [persistent vector](https://hypirion.com/musings/understanding-persistent-vector-pt-1).

# Usage

## Create

You can create an empty array using `new()` or construct it using `of()`, or use `from_iter()` to construct it from an iterator.

```moonbit
let arr2 = @immut/array.new()
let arr1 = @immut/array.of([1, 2, 3, 4, 5])    
let arr3 = @immut/array.from_iter((1).upto(5))
let arr4 = @immut/array.from_array([1, 2, 3])
```

Or use `make()`, `makei()` to create an array with some elements.

```moonbit
let arr1 = @immut/array.make(5, 1)
let arr2 = @immut/array.makei(5, fn(i){i + 1})
println(arr1) // of([1, 1, 1, 1, 1])
println(arr2) // of([1, 2, 3, 4, 5])
```

## Update 

Since the array is immutable, the `set()`, `push()` operation is not in-place. It returns a new array with the updated value.

```moonbit
let arr1 = @immut/array.of([1, 2, 3, 4, 5])
let arr2 = arr1.set(2, 10).push(6)
println(arr1) // of([1, 2, 3, 4, 5])
println(arr2) // of([1, 2, 10, 4, 5, 6])
```

## Query

You can use `op_get()` to get the value at the index, or `length()` to get the length of the array, or `is_empty()` to check whether the array is empty.

```moonbit
let arr = @immut/array.of([1, 2, 3, 4, 5])
println(arr[2]) // 3
println(arr.length()) // 5
println(arr.is_empty()) // false
```

## Iteration

You can use `iter()` to get an iterator of the array, or use `each()` to iterate over the array.

```moonbit
let arr = @immut/array.of([1, 2, 3, 4, 5])
println("iterator: \{arr.iter()}")
println(arr.each(fn(v) { println("element \{v}") }))
println(arr.eachi(fn(i, v) { println("index: \{i}, element: \{v}") }))
```


