# Moonbit/Core Stack

## Overview

Stack is a last in first out (LIFO) data structure, allowing to process their elements in the reverse order they come.

## Usage

### Create and Clear

The stack can be created with the `new` function, or by using the function with prefix `from` to create a stack from an existing collection.
For instance, `from_array` creates a stack from an array.

```moonbit
let st = Stack::new()
let st2 = Stack::from_array([1, 2, 3]) // Stack::[1, 2, 3]
let st3 = Stack::[1, 2, 3] // Stack::[1, 2, 3]
```

To clear the elements of the stack, use the `clear` method.

```moonbit
st.clear()
```

### Length

Use `length` to get the number of elements in the stack. The `is_empty` method can be used to check if the stack is empty.

```moonbit
let st = Stack::[1, 2, 3]
st.length() // 3
st.is_empty() // false
```

### Pop and Push

To add elements to the stack, use the `push` method, and to remove them, use the `pop` method.

```moonbit
let st = Stack::new()
st.push(1)
st.push(2)
st.pop() // Some(2)
```

The unsafe version of `pop` is `pop_exn`, which will panic if the stack is empty.

```moonbit
let st = Stack::new()
st.push(1)
st.pop_exn() // 1
st.pop_exn() // panic
```

If you don't want to remove the element, you can use the `peek` method and the unsafe version `peek_exn`.

```moonbit
let st = Stack::[1, 2, 3]
st.peek() // Some(1)
st.peek_exn() // 1
```

If the result of `pop` is not needed, you can use the `drop` method.

```moonbit
let st = Stack::[1, 2, 3]
st.drop()
// st = [2, 3]
```

### Traverse

To traverse the stack, use the `iter` method.

```moonbit
let st = Stack::[1, 2, 3]
let mut sum = 0
st.iter(fn(x) { sum += x }) // sum = 6
```

### Conversion

You can convert the stack to an array using the `to_array` method.

```moonbit
let st = Stack::[1, 2, 3]
st.to_array() // [1, 2, 3]
```
