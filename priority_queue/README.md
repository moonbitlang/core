# Moonbit/Core PriorityQueue

## Overview

A priority queue is a data structure capable of maintaining maximum/minimum values at front of the queue, which may have other names in other programming languages (C++ std::priority_queue / Rust BinaryHeap ). The priority queue here is implemented as a pairing heap and has excellent performance.

## Usage

### Create

You can use `new()` or `from_array()` to create a priority queue.

```moonbit
let queue1 : PriorityQueue[Int] = new()
let queue2 = PriorityQueue::[1, 2, 3]
```

Note, however, that the default priority queue created is greater-first; if you need to create a less-first queue, you can write a struct belongs to Compare trait to implement it.

### Length

You can use `length()` to get the number of elements in the current priority queue.

```moonbit
let pq = PriorityQueue::[1, 2, 3, 4, 5]
pq.length() // 5
```

Similarly, you can use the `is_empty` to determine whether the priority queue is empty.

```moonbit
let pq : PrioriryQueue[Int] = PrioriryQueue::new()
pq.is_empty() // true
```

### Peek

You can use `peek()` to look at the head element of a queue, which must be either the maximum or minimum value of an element in the queue, depending on the nature of the specification. The return value of `peek()` is an Option, which means that the result will be `None` when the queue is empty.

```moonbit
let pq = PriorityQueue::[1, 2, 3, 4, 5]
pq.peek() // Some(5)
```

### Push

You can use `push()` to add elements to the priority queue.

```moonbit
let pq : PriorityQueue[Int] = PriorityQueue::new()
pq.push(1)
pq.push(2)
pq.peek() // Some(2)
```

### Pop

You can use `pop()` to pop the element at the front of the priority queue, respectively, and like [Peek](#Peek), its return values are `Option`, loaded with the value of the element being popped.

```moonbit
let pq = PriorityQueue::[5, 4, 3, 2, 1]
pq.pop() // Some(5)
```

If you only want to pop an element without getting the return value, you can use `pop_exn()`.
This function will panic if the priority queue is empty.

```moonbit
let pq = PriorityQueue::[5, 4, 3, 2, 1]
pq.pop_exn()
pq.length() // 4
```

### Clear

You can use `clear` to clear a priority queue.

```moonbit
let pq = PriorityQueue::[1, 2, 3, 4, 5]
pq.clear()
pq.is_empty() // true
```

### Copy and Transfer

You can copy a priority queue using the `copy` method.

```moonbit
let pq = PriorityQueue::[1, 2, 3]
let pq2 = pq.copy()
```