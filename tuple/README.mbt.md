# Tuple

Tuple is a fixed-size collection of elements of different types. It is a lightweight data structure that can be used to store multiple values in a single variable. This sub-package introduces utils for binary tuples.

# Usage

## Create

Create a new tuple using the tuple literal syntax.

```moonbit
///|
test {
  let tuple2 = (1, 2)
  let tuple3 = (1, 2, 3)
  inspect((tuple2, tuple3), content="((1, 2), (1, 2, 3))")
}
```

## Access

You can access the elements of the tuple using pattern match or  dot access.

```moonbit
///|
test {
  let tuple = (1, 2)
  assert_eq(tuple.0, 1)
  assert_eq(tuple.1, 2)
  let (a, b) = tuple
  assert_eq(a, 1)
  assert_eq(b, 2)
}
```

## Transformation

You can transform the tuple using the matrix functions combined with `then`.

```moonbit  
///|
test {
  let tuple = (1, 2)
  let tuple2 = ((pair : (Int, Int)) => (pair.0 + 1, pair.1))(tuple)
  inspect(tuple2, content="(2, 2)")
  let tuple3 = tuple |> then(pair => (pair.0, pair.1 + 1))
  inspect(tuple3, content="(1, 3)")
  let mapped = tuple |> then(pair => (pair.0 + 1, pair.1 - 1))
  inspect(mapped, content="(2, 1)")
}
```





