# Priority Queue

A priority queue is a data structure capable of maintaining maximum/minimum values at front of the queue, which may have other names in other programming languages (C++ std::priority_queue / Rust BinaryHeap ). The priority queue here is implemented as a pairing heap and has excellent performance.

# Usage

## Create

You can use `new()` or `of()` to create a priority queue.

```moonbit
///|
test {
  let queue1 : @priority_queue.T[Int] = @priority_queue.new()
  let queue2 = @priority_queue.of([1, 2, 3])
  @json.inspect(queue1, content=[])
  @json.inspect(queue2, content=[3, 2, 1])
}
```

Note, however, that the default priority queue created is greater-first; if you need to create a less-first queue, you can write a struct belongs to Compare trait to implement it.

## Length

You can use `length()` to get the number of elements in the current priority queue.

```moonbit
///|
test {
  let pq = @priority_queue.of([1, 2, 3, 4, 5])
  assert_eq(pq.length(), 5)
}
```

Similarly, you can use the `is_empty` to determine whether the priority queue is empty.

```moonbit
///|
test {
  let pq : @priority_queue.T[Int] = @priority_queue.new()
  assert_eq(pq.is_empty(), true)
}
```

## Peek

You can use `peek()` to look at the head element of a queue, which must be either the maximum or minimum value of an element in the queue, depending on the nature of the specification. The return value of `peek()` is an Option, which means that the result will be `None` when the queue is empty.

```moonbit
///|
test {
  let pq = @priority_queue.of([1, 2, 3, 4, 5])
  assert_eq(pq.peek(), Some(5))
}
```

## Push

You can use `push()` to add elements to the priority queue.

```moonbit
///|
test {
  let pq : @priority_queue.T[Int] = @priority_queue.new()
  pq.push(1)
  pq.push(2)
  assert_eq(pq.peek(), Some(2))
}
```

## Pop

You can use `pop()` to pop the element at the front of the priority queue, respectively, and like [Peek](#Peek), its return values are `Option`, loaded with the value of the element being popped.

```moonbit
///|
test {
  let pq = @priority_queue.of([5, 4, 3, 2, 1])
  assert_eq(pq.pop(), Some(5))
}
```

```moonbit
///|
test {
  let pq = @priority_queue.of([5, 4, 3, 2, 1])
  assert_eq(pq.length(), 5)
}
```

## Clear

You can use `clear` to clear a priority queue.

```moonbit
///|
test {
  let pq = @priority_queue.of([1, 2, 3, 4, 5])
  pq.clear()
  assert_eq(pq.is_empty(), true)
}
```

## Copy and Transfer

You can copy a priority queue using the `copy` method.

```moonbit
///|
test {
  let pq = @priority_queue.of([1, 2, 3])
  let _pq2 = pq.copy()

}
```
