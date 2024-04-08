# Moonbit/Core Queue
## Overview
Queue is a first in first out (FIFO) data structure, allowing to process their elements in the order they come.

## Usage
### Create and Clear
You can create a queue manually by using the `new` or construct it using the `from_array`.
```moonbit
let queue = Queue::new()
let queue2 = Queue::[1,2,3]
let queue3 = Queue::[1,1,4]
```

To clear the queue, you can use the `clear` method.
```moonbit
let queue = Queue::[1,2,3]
queue.clear()
```

### Length
You can get the length of the queue by using the `length` method. The `is_empty` method can be used to check if the queue is empty.
```moonbit
let queue = Queue::[1,2,3]
queue.length() // 3
queue.is_empty() // false
```

### Pop and Push
You can add elements to the queue using the `push` method and remove them using the `pop` method.
The unsafe version of `pop` is `pop_exn`, which will panic if the queue is empty.
```moonbit
let queue = Queue::new()
queue.push(1)
queue.push(2)
queue.push(3)
queue.pop_exn() // 1
queue.pop() // Some(2)
queue.pop() // Some(3)
```

### Peek
You can get the first element of the queue without removing it using the `peek` method.
```moonbit
let queue = Queue::[1,2,3]
queue.peek() // Some(1)
```
The unsafe version of the `peek` method is the `peek_exn` method, which will panic if the queue is empty.

### Traverse
You can traverse the queue using the `iter` method.
```moonbit
let queue = Queue::[1,2,3]
let mut sum = 0
queue.iter(fn(x) { sum += x }) // sum = 6
```

You can fold the queue using the `fold` method.
```moonbit
let queue = Queue::[1,2,3]
let sum = queue.fold(~init = 0, fn(acc, x) { acc + x }) // sum = 6
```

### Copy and Transfer
You can copy a queue using the `copy` method.
```moonbit
let queue = Queue::[1,2,3]
let queue2 = queue.copy()
```

Transfer the elements from one queue to another using the `transfer` method.
```moonbit
let queue = Queue::[1,2,3]
let queue2 = Queue::new()
```