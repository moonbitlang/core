# Option

The `Option` type is a built-in type in MoonBit that represents an optional value. The type annotation `Option[A]` can also be written as `A?`.

It is an enum with two variants: `Some(T)`, which represents a value of type `T`, and `None`, representing no value.

Note that some methods of the Option are defined in the `core/builtin` package.

# Usage

## Create
You can create an `Option` value using the `Some` and `None` constructors, remember to give proper type annotations.

```moonbit
let some: Int? = Some(42)
let none: String? = None
```

For conditional expressions, you can use the `when` function, which returns `Some` if the condition is true, otherwise `None`. Note that the value is lazily evaluated.

```moonbit
let some = @option.when(1 > 0, fn () { 42 }) // Some(42)
let none = @option.when(1 < 0, fn () { 42 }) // None
```

The dual version of `when` is the `unless` function, which returns `Some` if the condition is false, otherwise `None`.

```moonbit
let some = @option.unless(1 < 0, fn () { 42 }) // Some(42)
let none = @option.unless(1 > 0, fn () { 42 }) // None
```

## Extracting values

You can extract the value from an `Option` using the `match` expression (Pattern Matching).

```moonbit
match some {
    Some(value) => print(value)
    None => print("None")
}
```

Or using the `unwrap` method, which will panic if the result is `None` and return the value if it is `Some`.

```moonbit
let some: Int? = Some(42)
let value = some.unwrap() // 42
```

A safer alternative to `unwrap` is the `or` method, which returns the value if it is `Some`, otherwise, it returns the default value.

```moonbit
let none: Int? = None
let value = none.or(0) // 0
```

There is also the `or_else` method, which returns the value if it is `Some`, otherwise, it returns the result of the provided function.

```moonbit
let none: Int? = None
let value = none.or_else(fn() -> Int { 0 }) // 0
```

## Transforming values

You can transform the value of an `Option` using the `map` method. It applies the provided function to the value if it is `Some`, otherwise, it returns `None`.

```moonbit
let some: Int? = Some(42)
let new_some = some.map(fn(value: Int) { value + 1 }) // Some(43)
```

There is a `filter` method that applies a predicate to the value if it is `Some`, otherwise, it returns `None`.

```moonbit
let some: Int? = Some(42)
let new_some = some.filter(fn(value: Int) { value > 40 }) // Some(42)
let none = some.filter(fn(value: Int) { value > 50 }) // None
```

## Monadic operations
You can chain multiple operations that return `Option` using the `bind` method, which applies a function to the value if it is `Some`, otherwise, it returns `None`. Different from `map`, the function in argument returns an `Option`.

```moonbit
let some: Int? = Some(42)
let new_some = some.bind(fn(value: Int) -> Int? { Some(value + 1) }) // Some(43)
```

Sometimes we want to reduce the nested `Option` values into a single `Option`, you can use the `flatten` method to achieve this. It transforms `Some(Some(value))` into `Some(value)`, and `None` otherwise.

```moonbit
let some: Option[Option[Int]] = Some(Some(42))
let new_some = some.flatten() // Some(42)
let none: Int?? = Some(None)
let new_none = none.flatten() // None
```
