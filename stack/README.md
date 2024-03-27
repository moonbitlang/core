# Moonbit/Core Stack
## Overview
Stack is a last in first out (LIFO) data structure, allowing to process their elements in the reverse order they come.

## Usage
### Create and Clear
You can create an empty stack manually by using the `new` or construct it using the `from_array`.
```moonbit
let stack = Stack::new()
let stack2 = Stack::[1,2,3]
let stack3 = Stack::[1,1,4]
println(stack3.top()) // 4
```

To clear the stack, you can use the `clear` method.
```moonbit
let stack = Stack::[1,2,3]
Stack.clear()
```

### Length
You can get the length of the stack by using the `length` method. The `is_empty` method can be used to check if the stack is empty.
```moonbit
let stack = Stack::[1,2,3]
stack.length() // 3
stack.is_empty() // false
```

### Pop and Push
You can add elements to the stack using the `push` method and remove them using the `pop` method. If the stack is empty, using `pop` will abort. The safe version of `pop` is `pop_option`, which will return `None` if the stack is empty.
```moonbit
let stack = stack::new()
stack.push(1)
stack.push(2)
stack.push(3)
stack.pop_exn() // 3
stack.pop_exn() // 2
stack.pop() // Some(1)
stack.pop() // None
stack.pop_exn() // abort
```

### Peek
You can get the first element of the stack without removing it using the `peek` method.
```moonbit
let stack = Stack::[1,2,3]
stack.peek() // Some(3)
```
The unsafe version of `peek` is `peek_exn`, which will panic if the stack is empty.

### Drop
You can remove the top element of the stack using the `drop` method. If the stack is empty, calling `drop` does nothing.
```moonbit
let stack = Stack::[1,2,3]
stack.drop() // returns Unit type
stack.peek() // Some(2)
```
Another version of the `drop` method is `drop_resut`, which will return `Ok(())` when successful, and when it fails, it returns `Err(())`.

### Traverse
You can traverse the stack using the `iter` method. The `iter` method returns an iterator that allows you to traverse the stack from the top to the bottom.
```moonbit
let stack = Stack::[1,2,3]
let mut sum = 0
stack.iter(fn(x) { sum += x }) // sum = 6
```
You can fold the queue using the `fold` method.
```moonbit
let stack = Stack::[1,2,3]
let sum = stack.fold(0, fn(acc, x) { acc + x }) // sum = 6
```