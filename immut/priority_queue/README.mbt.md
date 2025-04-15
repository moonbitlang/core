# Immutable Priority Queue

A priority queue is a data structure capable of maintaining maximum/minimum values at the front of the queue, which may have other names in other programming languages (C++ std::priority_queue / Rust BinaryHeap). The priority queue here is implemented as a pairing heap and has excellent performance.

# Usage

## Create

You can use `new()` or `of()` to create an immutable priority queue.

```moonbit
test {
  let _queue1 : @priority_queue.T[Int] = @priority_queue.new()
  let _queue2 = @priority_queue.of([1, 2, 3])

}
```

Note, however, that the default immutable priority queue created is greater-first; if you need to create a less-first queue, you can write a struct belongs to Compare trait to implement it.

## Length & Empty

You can use the `length` to get the length of the immutable priority queue.

```moonbit
test {
  let pq = @priority_queue.new()
  assert_eq!(pq.length(), 0)
  assert_eq!(pq.push(1).length(), 1)
}
```

You can use the `is_empty` to determine whether the immutable priority queue is empty.

```moonbit
test {
  let pq : @priority_queue.T[Int] = @priority_queue.new()
  assert_eq!(pq.is_empty(), true)
}
```

## Peek & Push & Pop

You can use `peek()` to look at the head element of a queue, which must be either the maximum or minimum value of an element in the queue, depending on the nature of the specification. The return value of `peek()` is an Option, which means that the result will be `None` when the queue is empty.

```moonbit
test {
  let pq = @priority_queue.of([1, 2, 3, 4, 5])
  assert_eq!(pq.peek(), Some(5))
  // @json.inspect!(pq)
  // we have to add `@json` package in test-import
  // it's reported unused package currently
}
```

You can use `push()` to add elements to the immutable priority queue and get a new queue.

```moonbit
test {
  let pq : @priority_queue.T[Int] = @priority_queue.new()
  assert_eq!(pq.push(1).peek(), Some(1))
}
```

You can use `pop()` to remove the element at the front of the priority queue and get a new immutable priority queue wrapped with Option. If the immutable priority queue is empty, then it will return None.

```moonbit
test {
  let pq = @priority_queue.of([5, 4, 3, 2, 1])
  let val = match pq.pop() {
    Some(q) => q.peek()
    None => None
  }
  assert_eq!(val, Some(4))
}
```
