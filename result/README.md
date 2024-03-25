# Moonbit/Core Result

## Overview
`Result[T,E]` is a type used for handling computation results and errors in an explicit and declarative manner, similar to Rust (`Result<T,E>`) and OCaml (`('a, 'e) result`). 
It is an enum with two variants: `Ok(T)`, which represents success and contains a value of type `T`, and `Err(E)`, representing error and containing an error value of type `E`. 
```moonbit
enum Result[T, E] {
    Ok(T)
    Err(E)
}
```

## Usage
### Constructing Result
You can create a `Result` value using the `Ok` and `Err` constructors, remember to give proper type annotations.
```moonbit
let result: Result[Int, String] = Ok(42)
let error: Result[Int, String] = Err("Error message")
```

Or use the `ok` and `err` functions to create a `Result` value.
```moonbit
let result : Result[String, Unit] = ok("yes")
let error : Result[Int, String] = err("error")
```

### The question mark operator 
Moonbit provides a way to handle `Result` values in a concise manner using the `?` operator when writing a sequence of computations that may return a `Result`, which hides the boilerplate code of unwrapping the `Result` and propagating the error. 

```moonbit
fn may_fail() -> Result[Int, String] {
    Ok(42)
}

fn print_ok() -> Result[Unit, String] {
    let result = may_fail()
    match result {
        Ok(value) => {
            print(value)
            Ok(())
        }
        Err(error) => Err(error)
    }
}
// The above code can be written as:
fn print_ok() -> Result[Unit, String] {
    let value = may_fail()?
    print(value)
    Ok(())
}
```
Ending expression with `?` will automatically unwrap the `Result`, if the result is `Err`, it will returned early from the function with the error value.

### Querying variant
You can check the variant of a `Result` using the `is_ok` and `is_err` methods.
```moonbit
let result: Result[Int, String] = Ok(42)
let is_ok = result.is_ok() // true
let is_err = result.is_err() // false
```

### Extracting values
You can extract the value from a `Result` using the `match` expression (Pattern Matching).
```moonbit
match result {
    Ok(value) => print(value)
    Err(error) => ()
}
```

Or using the `unwrap` method, which will panic if the result is `Err` and return the value if it is `Ok`.
```moonbit
let result: Result[Int, String] = Ok(42)
let value = result.unwrap() // 42
```

A safe alternative is the `or` method, which returns the value if the result is `Ok` or a default value if it is `Err`.
```moonbit
let result: Result[Int, String] = Err("error")
let value = result.or(0) // 0
```

There is a lazy version of `or` called `or_else`, which takes a function that returns a default value.
```moonbit
let result: Result[Int, String] = Err("error")
let value = result.or_else(fn() { 0 }) // 0
```

### Transforming values
To transform values inside a `Result`, you can use the `map` method, which applies a function to the value if the result is `Ok`,
and remains unchanged if it is `Err`.
```moonbit
let result: Result[Int, String] = Ok(42)
let new_result = result.map(fn(x) { x + 1 }) // Ok(43)
```

A dual method to `map` is `map_err`, which applies a function to the error value if the result is `Err`, and remains unchanged if it is `Ok`.
```moonbit
let result: Result[Int, String] = Err("error")
let new_result = result.map_err(fn(x) { x + "!" }) // Err("error!")
```

You can turn a `Result[T, E]` into a `Option[T]` by using the method `to_option`, which returns `Some(value)` if the result is `Ok`, and `None` if it is `Err`.
```moonbit
let result: Result[Int, String] = Ok(42)
let option = result.to_option() // Some(42)
let result1: Result[Int, String] = Err("error")
let option1 = result1.to_option() // None
```

### Monadic operations
Moonbit provides monadic operations for `Result`, such as `flatten` and `bind`, which allow chaining of computations that return `Result`.
```moonbit
let result: Result[Result[Int, String], String] = Ok(Ok(42))
let flattened = result.flatten() // Ok(42)
```

The `bind` method is similar to `map`, but the function passed to it should return a `Result` value. 
```moonbit
let result: Result[Int, String] = Ok(42)
let new_result = result.bind(fn(x) { Ok(x + 1) }) // Ok(43)
```
