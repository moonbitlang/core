# Option

The `Option` type is a built-in type in MoonBit that represents an optional value. The type annotation `Option[A]` can also be written as `A?`.

It is an enum with two variants: `Some(T)`, which represents a value of type `T`, and `None`, representing no value.

Note that some methods of the Option are defined in the `core/builtin` package.

# Usage

## Create

You can create an `Option` value using the `Some` and `None` constructors, remember to give proper type annotations.

```moonbit
///|
test {
  let some : Int? = Some(42)
  let none : String? = None
  inspect(some, content="Some(42)")
  inspect(none, content="None")
}
```

## Extracting values

You can extract the value from an `Option` using the `match` expression (Pattern Matching).

```moonbit
///|
test {
  let i = Some(42)
  let j = match i {
    Some(value) => value
    None => abort("unreachable")
  }
  assert_eq(j, 42)
}
```

Or using the `unwrap` method, which will panic if the result is `None` and return the value if it is `Some`.

```moonbit
///|
test {
  let some : Int? = Some(42)
  let value = some.unwrap() // 42
  assert_eq(value, 42)
}
```

A safer alternative to `unwrap` is the `or` method, which returns the value if it is `Some`, otherwise, it returns the default value.

```moonbit
///|
test {
  let none : Int? = None
  let value = none.unwrap_or(0) // 0
  assert_eq(value, 0)
}
```

There is also the `or_else` method, which returns the value if it is `Some`, otherwise, it returns the result of the provided function.

```moonbit
///|
test {
  let none : Int? = None
  let value = none.unwrap_or_else(() => 0) // 0
  assert_eq(value, 0)
}
```

## Transforming values

You can transform the value of an `Option` using the `map` method. It applies the provided function to the value if it is `Some`, otherwise, it returns `None`.

```moonbit
///|
test {
  let some : Int? = Some(42)
  let new_some = some.map((value : Int) => value + 1) // Some(43)
  assert_eq(new_some, Some(43))
}
```

There is a `filter` method that applies a predicate to the value if it is `Some`, otherwise, it returns `None`.

```moonbit
///|
test {
  let some : Int? = Some(42)
  let new_some = some.filter((value : Int) => value > 40) // Some(42)
  let none = some.filter((value : Int) => value > 50) // None
  assert_eq(new_some, Some(42))
  assert_eq(none, None)
}
```

## Monadic operations

You can chain multiple operations that return `Option` using the `bind` method, which applies a function to the value if it is `Some`, otherwise, it returns `None`. Different from `map`, the function in argument returns an `Option`.

```moonbit
///|
test {
  let some : Int? = Some(42)
  let new_some = some.bind((value : Int) => Some(value + 1)) // Some(43)
  assert_eq(new_some, Some(43))
}
```

Sometimes we want to reduce the nested `Option` values into a single `Option`, you can use the `flatten` method to achieve this. It transforms `Some(Some(value))` into `Some(value)`, and `None` otherwise.

```moonbit
///|
test {
  let some : Int?? = Some(Some(42))
  let new_some = some.flatten() // Some(42)
  assert_eq(new_some, Some(42))
  let none : Int?? = Some(None)
  let new_none = none.flatten() // None
  assert_eq(new_none, None)
}
```
