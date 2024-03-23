# Moonbit/Core Deque

## Overview

Deque is a double-ended queue implemented as a round-robin queue, supporting O(1) head or tail insertion and querying, just like double-ended queues in other languages(C++ std::deque / Rust VecDeque), here deque also supports random access.

## Usage

### Create

You can create a deque manually via the `new()` or construct it using the `from_array()`.

```moonbit
let dq : Deque[Int] = Deque::new()
let dq = Deque::[1, 2, 3, 4, 5]
```

If you want to set the length at creation time to minimize expansion consumption, you can use `with_capacity()`.

```moonbit
let dq = Deque::with_capacity(100);
```

### Length & Capacity

A deque is an indefinite-length, auto-expandable datatype. You can use `length()` to get the number of elements in the current queue, or `capacity()` to get the current capacity.

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq.length() // 5
dq.capacity() // 5
```

Similarly, you can use the `is_empty` to determine whether the queue is empty.

```moonbit
let dq : Deque[Int] = Deque::new()
dq.is_empty() // true
```

### Front & Back & Get

You can use `front()` and `back()` to get the head and tail elements of the queue, respectively. Since the queue may be empty, their return values are both `Option`, or `None` if the queue is empty.

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq.front() // Some(1)
dq.back() // Some(5)
```

You can also use `op_get` to access elements of the queue directly, but be careful not to cross the boundaries!

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq[0] // 1
dq[4] // 5
```

### Push & Set

Since the queue is bi-directional, you can use `push_front()` and `push_back()` to add values to the head or tail of the queue, respectively.

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq.push_front(6)
dq.push_front(7)
dq.push_back(8)
dq.push_back(9)
//now: 6 7 1 2 3 4 5 8 9
```

You can also use `op_set` to set elements of the queue directly, but be careful not to cross the boundaries!

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq[0] = 5
dq[0] // 5
```

### Pop

You can use `pop_front()` and `pop_back()` to pop the element at the head or tail of the queue, respectively, and like [Front & Back](#Front & Back & Get), their return values are `Option`, loaded with the value of the element being popped.

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
let back = dq.pop_back() // Some(5)
dq.back() // Some(4)
let front = dq.pop_front() //Some(1)
dq.front() // Some(2)
dq.length() // 3
```

If you only want to pop an element without getting the return value, you can use `pop_front_exn()` with `pop_back_exn()`.
These two functions will panic if the queue is empty.

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq.pop_front_exn()
dq.front() // Some(2)
dq.pop_back_exn()
dq.back() // Some(3)
```

### Clear

You can use `clear` to clear a deque. But note that the memory it already occupies does not change.

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq.clear()
dq.is_empty() // true
```

### Equal

deque supports comparing them directly using `op_equal`.

```moonbit
let dqa = Deque::[1, 2, 3, 4, 5]
let dqb = Deque::[1, 2, 3, 4, 5]
dqa == dqb // true
```

### Iter & Map

deque supports vector-like `iter/iteri/map/mapi` functions and their inverse forms.

```moonbit
 let dq = Deque::[1, 2, 3, 4, 5]
 dq.iter(fn(elem) { print(elem) })
 dq.iteri(fn(i, _elem) { print(i) })
 dq.map(fn(elem) { elem + 1 })
 dq.mapi(fn(i, elem) { elem + i })
```

### Search & Contains

You can use `contains()` to find out if a value is in the deque, or `search()` to find its index in the deque.

```moonbit
let dq = Deque::[1, 2, 3, 4, 5]
dq.contains(1) // true
dq.contains(6) // false
dq.search(1) // Some(0)
dq.search(6) // None
```
