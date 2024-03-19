# Moonbit/Core Queue
## Overview
Queue is a first in first out (FIFO) data structure, allowing to process their elements in the order they come.

## Usage
### Create and Clear
You can create a queue manually by using the `new` or construct it using the `from_array`.
```moonbit
let queue = Queue.new()
let queue2 = Queue.from_array([1, 2, 3])
let queue3 = Queue::[1,1,4]
```

To clear the queue, you can use the `clear` method.
```moonbit
let queue = Queue.from_array([1, 2, 3])
queue.clear()
```

### Length
You can get the length of the queue by using the `length` method. The `is_empty` method can be used to check if the queue is empty.
```moonbit
let queue = Queue.from_array([1, 2, 3])
queue.length() // 3
queue.is_empty() // false
```

### Pop and Push
You can add elements to the queue using the `push` method and remove them using the `pop` method.
Remind that the `pop` method will panic if the queue is empty, you can use the `pop_option` method to avoid this.
```moonbit
let queue = Queue.new()
queue.push(1)
queue.push(2)
queue.push(3)
queue.pop() // 1
queue.pop() // 2
queue.pop() // 3
```

### Peek
You can get the first element of the queue without removing it using the `peek` method.
Remind that the `peek` method will panic if the queue is empty, you can use the `peek_option` method to avoid this.
```moonbit
let queue = Queue.from_array([1, 2, 3])
queue.peek() // 1
```

### Traverse
You can traverse the queue using the `iter` method.
```moonbit
let queue = Queue.from_array([1, 2, 3])
let mut sum = 0
queue.iter(fn(x) { sum = sum + x }) // sum = 6
```

You can fold the queue using the `fold` method.
```moonbit
let queue = Queue.from_array([1, 2, 3])
let sum = queue.fold(0, fn(acc, x) { acc + x }) // sum = 6
```