Moonbit/Core ImmutablePriorityQueue

## Overview

A priority queue is a data structure capable of maintaining maximum/minimum values at the front of the queue, which may have other names in other programming languages (C++ std::priority_queue / Rust BinaryHeap). The priority queue here is implemented as a pairing heap and has excellent performance.

This library implements an Immutable version of PriorityQueue that has no side effects for each operation.

## Usage

### Create

You can use `new()` or `from_array()` to create an immutable priority queue.

```moonbit
let queue1 : ImmutablePriorityQueue[Int] = new()
let queue2 = ImmutablePriorityQueue::[1, 2, 3]
```

Note, however, that the default immutable priority queue created is greater-first; if you need to create a less-first queue, you can write a struct belongs to Compare trait to implement it.

### Empty

You can use the `is_empty` to determine whether the immutable priority queue is empty.

```moonbit
let pq : ImmutablePrioriryQueue[Int] = ImmutablePrioriryQueue::new()
pq.is_empty() // true
```

### Peek

You can use `peek()` to look at the head element of a queue, which must be either the maximum or minimum value of an element in the queue, depending on the nature of the specification. The return value of `peek()` is an Option, which means that the result will be `None` when the queue is empty.

```moonbit
let pq = ImmutablePriorityQueue::[1, 2, 3, 4, 5]
pq.peek() // Some(5)
```

### Push

You can use `push()` to add elements to the immutable priority queue and get a new queue.

```moonbit
let pq : ImmutablePriorityQueue[Int] = ImmutablePriorityQueue::new()
pq.push(1).peek() // Some(!)
```

### Pop

You can use `pop()` to remove the element at the front of the priority queue and get a new immutable priority queue wrapped with Option. If the immutable priority queue is empty, then it will return None.

```moonbit
let pq = ImmutablePriorityQueue::[5, 4, 3, 2, 1]
match pq.pop(){
    Some(q) => q.peek()
    None => None
}// Some(5)
```

If you only want to pop an element without Option, you can use `pop_exn()`.
This function will panic if the priority queue is empty.

```moonbit
let pq = ImmutablePriorityQueue::[5, 4, 3, 2, 1]
pq.pop_exn().peek() // Some(5)
```
