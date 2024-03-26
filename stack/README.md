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
let stack = stack::[1,2,3]
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
stack.pop() // 3
stack.pop() // 2
stack.pop_option() // Some(1)
stack.pop_option() // None
stack.pop() // abort
```

### Top
You can get the first element of the stack without removing it using the `top` method.
```moonbit
let stack = stack::[1,2,3]
stack.top() // 3
```
The safe version of the `top` method is the `top_option`, which will return `None` if the stack is empty.

### Drop
You can remove the top element of the stack using the `drop` method. If the stack is empty, calling `drop` does nothing.
```moonbit
let stack = stack::[1,2,3]
stack.drop() // returns Unit type
stack.top() // 2
```
The safe version of the `drop` method is the `drop_option`, which will return `Ok(())` when successful, and when it fails, it returns `Err(())`.
