# Stack

`stack` provides a simple last in first out (LIFO) data structure.

```moonbit
test {
  let s : @stack.T[Int] = @stack.new()
  s.push(1)
  s.push(2)
  inspect(s.pop(), content="Some(2)")
}
```
