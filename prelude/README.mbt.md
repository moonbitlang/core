# Prelude Package Documentation

This package provides the standard prelude for MoonBit programs, containing commonly used types, traits, and functions that are automatically available without explicit imports. It serves as the foundation for MoonBit programming by re-exporting essential functionality from core packages.

## Core Types

The prelude makes essential types available without qualification:

```moonbit
test "core types" {
  // Array type (from builtin)
  let numbers : Array[Int] = [1, 2, 3, 4, 5]
  inspect(numbers.length(), content="5")
  
  // Set type (from set package)
  let unique_numbers : Set[Int] = Set::from_array([1, 2, 2, 3, 3])
  inspect(unique_numbers.size(), content="3")
  
  // BigInt type (from bigint package)
  let big_number : BigInt = 12345678901234567890N
  inspect(big_number.to_string().length(), content="20")
  
  // StringBuilder for efficient string building
  let builder = StringBuilder::new()
  builder.write_string("Hello, ")
  builder.write_string("World!")
  inspect(builder.to_string(), content="Hello, World!")
}
```

## Essential Functions

Common functions available globally:

```moonbit
test "essential functions" {
  // Assertions for testing
  assert_eq(2 + 2, 4)
  assert_true(5 > 3)
  assert_false(1 > 2)
  assert_not_eq("hello", "world")
  
  // Inspection for debugging and testing
  let value = 42
  inspect(value, content="42")
  
  // Utility functions
  ignore(println("This output is ignored in tests"))
  
  // Boolean negation
  let result = not(false)
  inspect(result, content="true")
  
  // Physical equality testing
  let arr1 = [1, 2, 3]
  let arr2 = arr1
  inspect(physical_equal(arr1, arr2), content="true")
}
```

## Iterator Types

Work with lazy iteration:

```moonbit
test "iterators" {
  let numbers = [1, 2, 3, 4, 5]
  
  // Basic iteration
  let iter : Iter[Int] = numbers.iter()
  let collected = iter.collect()
  inspect(collected, content="[1, 2, 3, 4, 5]")
  
  // Iter2 for indexed iteration
  let mut sum = 0
  numbers.iter2().each(fn(index, value) {
    sum = sum + index + value
  })
  inspect(sum, content="25")  // Sum of indices (0+1+2+3+4) + values (1+2+3+4+5)
}
```

## Core Traits

Essential traits for type behavior:

```moonbit
test "core traits" {
  // Eq trait for equality
  struct Point { x: Int, y: Int } derive(Eq)
  let p1 = { x: 1, y: 2 }
  let p2 = { x: 1, y: 2 }
  inspect(p1 == p2, content="true")
  
  // Show trait for display
  struct Person { name: String, age: Int } derive(Show)
  let person = { name: "Alice", age: 30 }
  inspect(person.to_string().length() > 0, content="true")
  
  // Default trait for default values
  let default_array : Array[Int] = Array::default()
  inspect(default_array.length(), content="0")
}
```

## Functional Programming Utilities

The prelude provides functional programming helpers:

```moonbit
test "functional utilities" {
  // tap: Apply a function and return original value
  let value = 10
  let result = value |> tap(fn(x) { ignore(x * 2) })
  inspect(result, content="10")  // Original value returned
  
  // then: Apply a function and return the result (similar to map)
  let doubled = value |> then(fn(x) { x * 2 })
  inspect(doubled, content="20")
  
  // Chaining operations
  let processed = 5 
    |> then(fn(x) { x * 3 })      // 15
    |> tap(fn(x) { ignore(x) })    // Still 15, but side effect applied
    |> then(fn(x) { x + 10 })      // 25
  inspect(processed, content="25")
}
```

## JSON Support

JSON handling through the prelude:

```moonbit
test "json support" {
  // JSON null value
  let json_null : Json = null
  inspect(json_null, content="null")
  
  // Convert values to JSON
  let number_json = (42 : Int).to_json()
  inspect(number_json, content="42")
  
  let string_json = "hello".to_json()
  inspect(string_json, content="\"hello\"")
  
  let array_json = [1, 2, 3].to_json()
  inspect(array_json, content="Array([Number(1), Number(2), Number(3)])")
}
```

## Error Handling

Error handling utilities from the prelude:

```moonbit
test "error handling" {
  // Failure type for simple errors
  fn risky_operation(should_fail : Bool) -> Int raise Failure {
    if should_fail {
      fail("Operation failed")
    } else {
      42
    }
  }
  
  let success = try! risky_operation(false)
  inspect(success, content="42")
  
  let failure = try? risky_operation(true)
  match failure {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}
```

## Hash and Comparison

Built-in hash and comparison functionality:

```moonbit
test "hash and comparison" {
  // Hash trait for hash-based collections
  let hasher = Hasher::new()
  hasher.write_string("test")
  let hash_value = hasher.finalize()
  inspect(hash_value.to_string().length() > 0, content="true")
  
  // Compare trait for ordering
  struct Score { value: Int } derive(Eq, Compare)
  let score1 = { value: 85 }
  let score2 = { value: 92 }
  
  inspect(score1 < score2, content="true")
  inspect(score2 > score1, content="true")
  inspect(score1.compare(score2), content="-1")
}
```

## Arithmetic Operations

Standard arithmetic traits:

```moonbit
test "arithmetic operations" {
  // Basic arithmetic with integers
  let a = 10
  let b = 3
  
  inspect(a + b, content="13")  // Add trait
  inspect(a - b, content="7")   // Sub trait
  inspect(a * b, content="30")  // Mul trait
  inspect(a / b, content="3")   // Div trait
  inspect(a % b, content="1")   // Mod trait
  inspect(-a, content="-10")    // Neg trait
  
  // Bitwise operations
  inspect(a & b, content="2")   // BitAnd trait
  inspect(a | b, content="11")  // BitOr trait
  inspect(a ^ b, content="9")   // BitXOr trait
}
```

## What the Prelude Provides

The prelude automatically imports and re-exports:

### From `builtin` package:
- Core types: `Array`, `Iter`, `Iter2`, `Json`, `StringBuilder`
- Error types: `Failure`, `InspectError`, `SnapshotError`
- Functions: `assert_eq`, `inspect`, `println`, `panic`, `abort`, etc.
- Traits: `Eq`, `Show`, `Hash`, `Compare`, `ToJson`, `Default`
- Arithmetic traits: `Add`, `Sub`, `Mul`, `Div`, `Mod`, `Neg`
- Bitwise traits: `BitAnd`, `BitOr`, `BitXOr`, `Shl`, `Shr`

### From `set` package:
- `Set[T]` type for hash-based collections

### From `bigint` package:
- `BigInt` type for arbitrary-precision integers

### Prelude-specific functions:
- `tap`: Apply side effect and return original value
- `then`: Apply transformation and return result

## Usage Guidelines

### When to Import the Prelude

The prelude is typically imported automatically in most MoonBit files. You might need to explicitly import it in:

- Library code that wants to be explicit about dependencies
- Code that needs to avoid name conflicts
- Modules that define their own prelude

### Avoiding Name Conflicts

If you need to avoid conflicts with prelude names:

```moonbit
test "avoiding conflicts" {
  // Use qualified names when needed
  let builtin_array = @builtin.Array::new()
  let set_from_array = @set.Set::new()
  
  // Or create local aliases
  let MyArray = @builtin.Array
  let my_arr = MyArray::new()
  
  inspect(builtin_array.length(), content="0")
  inspect(my_arr.length(), content="0")
}
```

## Best Practices

1. **Rely on the prelude for common operations**: Don't reinvent basic functionality
2. **Use `tap` for debugging**: Insert debugging code without changing data flow
3. **Use `then` for transformations**: Clean functional-style transformations
4. **Leverage automatic imports**: Let the prelude handle common imports
5. **Be explicit when needed**: Use qualified names for clarity in complex code

## Performance Notes

- Prelude functions are typically zero-cost abstractions
- `tap` and `then` are inlined by the compiler
- Type aliases don't add runtime overhead
- Trait implementations use static dispatch when possible

The prelude package provides the foundation for idiomatic MoonBit programming by making essential functionality readily available.
