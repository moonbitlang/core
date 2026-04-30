# Queue

Queue is a first in first out (FIFO) data structure, allowing to process their elements in the order they come.

# Usage

## Create and Clear
You can create a queue manually by using the `new` or construct it using the `from_array`.
```mbt check
///|
test {
  let _queue : @queue.Queue[Int] = @queue.Queue([])
  let _queue1 = @queue.from_array([1, 2, 3])
}
```

To clear the queue, you can use the `clear` method.
```mbt check
///|
test {
  let queue = @queue.from_array([1, 2, 3])
  queue.clear()
}
```

## Length
You can get the length of the queue by using the `length` method. The `is_empty` method can be used to check if the queue is empty.
```mbt check
///|
test {
  let queue = @queue.from_array([1, 2, 3])
  assert_eq(queue.length(), 3)
  assert_eq(queue.is_empty(), false)
}
```

## Pop and Push
You can add elements to the queue using the `push` method and remove them using the `pop` method.
```mbt check
///|
test {
  let queue = @queue.Queue([])
  queue.push(1)
  queue.push(2)
  assert_eq(queue.pop(), Some(1))
  assert_eq(queue.pop(), Some(2))
}
```

## Peek
You can get the first element of the queue without removing it using the `peek` method.
```mbt check
///|
test {
  let queue = @queue.from_array([1, 2, 3])
  assert_eq(queue.peek(), Some(1))
}
```

## From Iterator

```mbt check
///|
test {
  let queue = @queue.from_iter([1, 2, 3].iter())
  assert_eq(queue.length(), 3)
}
```

## Traverse

`each()` iterates over elements in FIFO order. `eachi()` provides the index. `fold()` reduces the queue to a single value.

```mbt check
///|
test {
  let queue = @queue.from_array([1, 2, 3])
  // each
  let buf = []
  queue.each(fn(x) { buf.push(x) })
  assert_eq(buf, [1, 2, 3])
  // eachi
  let pairs = []
  queue.eachi(fn(i, x) { pairs.push((i, x)) })
  assert_eq(pairs, [(0, 1), (1, 2), (2, 3)])
  // fold
  let sum = queue.fold(init=0, fn(acc, x) { acc + x })
  assert_eq(sum, 6)
}
```

## Iterator

`iter()` returns an `Iter` over the queue's elements.

```mbt check
///|
test {
  let queue = @queue.from_array([1, 2, 3])
  inspect(queue.iter(), content="[1, 2, 3]")
}
```

## Copy and Transfer

`copy()` creates a shallow clone. `transfer()` moves all elements from one queue to the end of another, emptying the source.

```mbt check
///|
test {
  let queue = @queue.from_array([1, 2, 3])
  let cloned = queue.copy()
  assert_eq(cloned.pop(), Some(1))
  assert_eq(queue.length(), 3) // original unchanged
}
```

```mbt check
///|
test {
  let dst = @queue.from_array([1, 2])
  let src = @queue.from_array([3, 4])
  src.transfer(dst)
  assert_eq(src.is_empty(), true)
  assert_eq(dst.length(), 4)
  assert_eq(dst.pop(), Some(1))
}
```