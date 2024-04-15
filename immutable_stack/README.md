# Moonbit/Core ImmutableStack

## Overview

ImmutableStack is a last in first out (LIFO) data structure similar to stack but immutable. All operations return a new ImmutableStack.

## Usage

### Create

The stack can be created with the `new` function, or by using the function with prefix `from` to create a stack from an existing collection. For instance, `from_array` creates a stack from an array.

```moonbit
let st = ImmutableStack::new()
let st2 = ImmutableStack::from_array([1, 2, 3]) // ImmutableStack::[1, 2, 3]
let st3 = ImmutableStack::[1, 2, 3] // ImmutableStack::[1, 2, 3]
```

### Length

Use `length` to get the number of elements in the stack. The `is_empty` method can be used to check if the stack is empty.

```moonbit
let st = ImmutableStack::[1, 2, 3]
st.length() // 3
st.is_empty() // false
```

### Pop and Push

To add elements to the stack, use the `push` method, and to remove them, use the `pop` method. 
Note that the `pop` method will return a pair includes the popped element (or `None` if the stack is empty) and the new stack.

```moonbit
let st = ImmutableStack::new()
st.push(1)
st.push(2)
st.pop() // (Some(2), ImmutableStack::[1])
```

The unsafe version of `pop` is `pop_exn`, which will panic if the stack is empty.

```moonbit
let st = ImmutableStack::new()
st.push(1)
st.pop_exn() // (1, ImmutableStack::[])
st.pop_exn() // panic
```

If you don't want to remove the element, you can use the `peek` method and the unsafe version `peek_exn`.

```moonbit
let st = ImmutableStack::[1, 2, 3]
st.peek() // Some(1)
st.peek_exn() // 1
```

If the result of `pop` is not needed, you can use the `drop` method. The `drop_exn` method will panic if the stack is empty.

```moonbit
let st = ImmutableStack::[1, 2, 3]
st.drop() // ImmutableStack::[2, 3]
st.drop_exn() // ImmutableStack::[3]
```

### Traverse

To traverse the immutable stack, use the `iter` method.

```moonbit
let st = ImmutableStack::[1, 2, 3]
let mut sum = 0
st.iter(fn(x) { sum += x }) // sum = 6
```

### Conversion

You can convert the stack to an array / list by using the `to_array` / `to_list` method.

```moonbit
let st = ImmutableStack::[1, 2, 3]
st.to_array() // [1, 2, 3]
st.to_list() // List::[1, 2, 3]
```
