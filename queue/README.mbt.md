# Queue

Queue is a first in first out (FIFO) data structure, allowing to process their elements in the order they come.

# Usage

## Create and Clear
You can create a queue manually by using the `new` or construct it using the `from_array`.
```moonbit
///|
test {
  let _queue : @queue.Queue[Int] = @queue.new()
  let _queue1 = @queue.of([1, 2, 3])

}
```

To clear the queue, you can use the `clear` method.
```moonbit
///|
test {
  let queue = @queue.of([1, 2, 3])
  queue.clear()
}
```

## Length
You can get the length of the queue by using the `length` method. The `is_empty` method can be used to check if the queue is empty.
```moonbit
///|
test {
  let queue = @queue.of([1, 2, 3])
  assert_eq(queue.length(), 3)
  assert_eq(queue.is_empty(), false)
}
```

## Pop and Push
You can add elements to the queue using the `push` method and remove them using the `pop` method.
```moonbit
///|
test {
  let queue = @queue.new()
  queue.push(1)
  queue.push(2)
  assert_eq(queue.pop(), Some(1))
  assert_eq(queue.pop(), Some(2))
}
```

## Peek
You can get the first element of the queue without removing it using the `peek` method.
```moonbit
///|
test {
  let queue = @queue.of([1, 2, 3])
  assert_eq(queue.peek(), Some(1))
}
```

## Traverse

You can traverse the queue using the `each` method.

```moonbit
///|
test {
  let queue = @queue.of([1, 2, 3])
  let mut sum = 0
  queue.each(x => sum += x)
  assert_eq(sum, 6)
}
```

You can fold the queue using the `fold` method.
```moonbit
///|
test {
  let queue = @queue.of([1, 2, 3])
  let sum = queue.fold(init=0, (acc, x) => acc + x)
  assert_eq(sum, 6)
}
```

## Copy and Transfer
You can copy a queue using the `copy` method.
```moonbit
///|
test {
  let queue = @queue.of([1, 2, 3])
  let _queue2 = queue.copy()

}
```

Transfer the elements from one queue to another using the `transfer` method.
```moonbit
///|
test {
  let dst : @queue.Queue[Int] = @queue.new()
  let src : @queue.Queue[Int] = @queue.of([5, 6, 7, 8])
  src.transfer(dst)
}
```