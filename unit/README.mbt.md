# `unit`

The `unit` package provides functionality for working with the singleton type `Unit`, which represents computations that produce side effects but return no meaningful value. This is a fundamental type in functional programming for operations like I/O, logging, and state modifications.

## Understanding Unit Type

The `Unit` type has exactly one value: `()`. This might seem trivial, but it serves important purposes in type systems:

- **Side Effect Indication**: Functions returning `Unit` signal they're called for side effects
- **Placeholder Type**: Used when a type parameter is needed but no meaningful value exists
- **Functional Programming**: Represents "no useful return value" without using `null` or exceptions
- **Interface Consistency**: Maintains uniform function signatures in generic contexts

## Unit Value Creation

The unit value can be created in multiple ways:

```moonbit
///|
test "unit construction" {
  // Direct literal syntax
  let u1 = ()

  // Via default constructor
  let u2 = @unit.default()
  fn println(_ : String) {

  }
  // All unit values are identical
  inspect(u1 == u2, content="true")

  // Common pattern: functions that return unit
  fn log_message(msg : String) -> Unit {
    // In real code, this would write to a log
    println(msg)
    () // Explicit unit return
  }

  let result = log_message("Hello, world!")
  inspect(result, content="()")
}
```

## Working with Side-Effect Functions

Functions that return `Unit` are typically called for their side effects:

```moonbit
///|
test "side effect patterns" {
  let numbers = [1, 2, 3, 4, 5]
  fn println(_ : Int) {

  }
  // Processing for side effects (printing, logging, etc.)
  let processing_result = numbers.fold(init=(), fn(_acc, n) {
    // Simulated side effect
    if n % 2 == 0 {
      // Would print or log in real code
      println(n)
    }
    () // Return unit to continue fold
  })
  inspect(processing_result, content="()")

  // Using each for side effects (more idiomatic)
  numbers.each(fn(n) { if n % 2 == 0 { println(n) } })
}
```

## String Representation and Debugging

Unit values have a standard string representation for debugging:

```moonbit
///|
test "unit string conversion" {
  let u = ()
  inspect(u.to_string(), content="()")

  // Useful for debugging function results
  fn perform_operation() -> Unit {
    // Some side effect operation
    ()
  }

  let result = perform_operation()
  let debug_msg = "Operation completed: \{result}"
  inspect(debug_msg, content="Operation completed: ()")
}
```

## Generic Programming with Unit

Unit is particularly useful in generic contexts where you need to represent "no meaningful value":

```moonbit
///|
test "generic unit usage" {
  // Simulating a function that processes data and optionally returns a result
  let items = [1, 2, 3, 4, 5]

  // Process for side effects only
  items.each(fn(x) {
    // Side effect: processing each item
    let processed = x * 2
    assert_true(processed > 0) // Simulated processing validation
  })

  // Unit represents successful completion without meaningful return value
  let completion_status = ()
  inspect(completion_status, content="()")

  // Unit is useful in Result types for operations that succeed but return nothing
  let operation_result : Result[Unit, String] = Ok(())
  inspect(operation_result, content="Ok(())")
}
```

## Built-in Trait Implementations

Unit implements essential traits for seamless integration with MoonBit's type system:

```moonbit
///|
test "unit trait implementations" {
  let u1 = ()
  let u2 = ()

  // Equality: all unit values are equal
  inspect(u1 == u2, content="true")

  // Comparison: all unit values compare as equal
  inspect(u1.compare(u2), content="0")

  // Hashing: consistent hash values
  let h1 = u1.hash()
  let h2 = u2.hash()
  inspect(h1 == h2, content="true")

  // Default instance
  let u3 = Unit::default()
  inspect(u3 == u1, content="true")
}
```

## Practical Use Cases

### Result Accumulation

```moonbit
///|
test "result accumulation" {
  // Accumulating side effects without meaningful return values
  let operations = [
    fn() { () }, // Operation 1
    fn() { () }, // Operation 2
    fn() { () },
  ] // Operation 3
  let final_result = operations.fold(init=(), fn(acc, operation) {
    operation() // Execute the operation
    acc // Accumulate unit values
  })
  inspect(final_result, content="()")
}
```

### Builder Pattern Termination

```moonbit
///|
test "builder pattern" {
  // Simulating a builder pattern where build() returns Unit
  let settings = ["debug=true", "timeout=30"]

  // Build operation returns Unit after applying configuration
  fn apply_config(config_list : Array[String]) -> Unit {
    // In real code: apply configuration settings
    let _has_settings = config_list.length() > 0
    () // Unit indicates successful completion
  }

  let result = apply_config(settings)
  inspect(result, content="()")
}
```

The `Unit` type provides essential functionality for representing "no meaningful return value" in a type-safe way, enabling clean functional programming patterns and consistent interfaces across MoonBit code.
