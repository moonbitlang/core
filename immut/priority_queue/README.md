# Immutable Priority Queue

A priority queue is a data structure capable of maintaining maximum/minimum values at the front of the queue, which may have other names in other programming languages (C++ std::priority_queue / Rust BinaryHeap). The priority queue here is implemented as a pairing heap and has excellent performance.

# Usage

## Create

You can use `new()` or `of()` to create an immutable priority queue.

```moonbit
let queue1 : @immut/priority_queue.T[Int] = @immut/priority_queue.new()
let queue2 = @immut/priority_queue.of([1, 2, 3])
```

Note, however, that the default immutable priority queue created is greater-first; if you need to create a less-first queue, you can write a struct belongs to Compare trait to implement it.

## Length & Empty

You can use the `length` to get the length of the immutable priority queue.

```moonbit
let pq = @immut/priority_queue.new()
println(pq.length()) // 0
println(pq.push(1).length()) // 1
```

You can use the `is_empty` to determine whether the immutable priority queue is empty.

```moonbit
let pq = @immut/priority_queue.new()
println(pq.is_empty()) // true
```

## Peek & Push & Pop

You can use `peek()` to look at the head element of a queue, which must be either the maximum or minimum value of an element in the queue, depending on the nature of the specification. The return value of `peek()` is an Option, which means that the result will be `None` when the queue is empty.

```moonbit
let pq = @immut/priority_queue.of([1, 2, 3, 4, 5])
println(pq.peek()) // Some(5)
```

You can use `push()` to add elements to the immutable priority queue and get a new queue.

```moonbit
let pq : @immut/priority_queue.new()
println(pq.push(1).peek()) // Some(1)
```

You can use `pop()` to remove the element at the front of the priority queue and get a new immutable priority queue wrapped with Option. If the immutable priority queue is empty, then it will return None.

```moonbit
let pq = @immut/priority_queue.of([5, 4, 3, 2, 1])
match pq.pop(){
    Some(q) => q.peek()
    None => None
}// Some(5)
```
